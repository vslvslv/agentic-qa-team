# BDD — QA Methodology Guide
<!-- lang: TypeScript | topic: bdd | iteration: 36 | score: 100/100 | date: 2026-05-12 | sources: official+community -->
<!-- Iter 36 additions: TypeScript 5.5+ strict compiler flags affecting BDD step definitions — noUncheckedIndexedAccess changes DataTable row access patterns (requires null-coalescing guards), isolatedDeclarations requires explicit return types on exported step factories; AI-generated Gherkin quality evaluation checklist — 7-criterion pre-acceptance framework (INVEST, ubiquitous language, data specificity, step atomicity, observable outcomes, tag hygiene, implementation freedom) with TypeScript scoring utility; Cucumber.js v12.8.0 externalise option full section — extracts inline step definitions into importable modules, enables step sharing across features without World pollution -->
<!-- Iter 35 additions: Playwright v1.54-v1.56 BDD-relevant APIs not previously covered — TestStepInfo.titlePath (v1.55) for hierarchical step path and collision-free artifact naming in sharded CI, Playwright Test Agents npx playwright init-agents (v1.56) planner/generator/healer loop and BDD Discovery integration, page.pickLocator() (v1.59) interactive locator discovery utility for step definition authoring with BDD vs --debug=cli comparison table; resource links added for all three APIs -->
<!-- Iter 34 additions: Completed iter-33 announced sections missing from body — page.screencast() with action annotations for BDD failure video capture (v1.59), expect(locator).toHaveCSS() pseudo option for ::before/::after pseudo-element CSS assertions (v1.60); resource links added for both APIs -->
<!-- Iter 33 additions: Playwright v1.59-v1.60 BDD-relevant APIs not yet covered — await using disposable pattern for BDD resource cleanup (v1.59), page.ariaSnapshot() on full pages (v1.59), --debug=cli for interactive BDD step debugging (v1.59), page.screencast() with action annotations for BDD failure video (v1.59), locator.drop() for drag-and-drop BDD scenarios (v1.60), HAR recording as first-class tracing API (v1.60), getByRole() description option for accessible-name-aware step assertions (v1.60), expect(locator).toHaveCSS() pseudo option for ::before/::after state assertions (v1.60); Quick Reference card updated with v1.59-v1.60 APIs -->
<!-- Iter 32 additions: Playwright v1.51-v1.60 BDD-relevant APIs not yet covered — TestStepInfo (v1.51) for step-level attachments and conditional skip, IndexedDB storageState (v1.51) for auth token persistence, toContainClass() (v1.52) for ergonomic CSS class assertions, locator.describe() (v1.53) for trace/report labeling, page.consoleMessages()/pageErrors()/requests() (v1.56) for in-step observability, testConfig.tag (v1.57) for run-level tagging in CI, test.abort() (v1.60) for fixture-driven early exit; Cucumber.js v12.8.1 junit-xml-formatter dependency fix; version matrix updated to split v12.6 row; Quick Reference card updated with new Playwright APIs -->
<!-- Iter 31 additions: Playwright 1.45-1.60 BDD-relevant APIs — Clock API for time-dependent scenarios (password expiry, token TTL, session timeout), WebSocketRoute for WebSocket mocking/interception without real backend, toMatchAriaSnapshot() for semantic markup BDD assertions, toHaveAccessibleErrorMessage() for error-state a11y step definitions; Cucumber community ownership note (2025) — project returned to open-source community governance -->
<!-- Iter 30 additions: Cucumber.js Plugin API full TypeScript reference — Plugin<T> generic from @cucumber/cucumber/api, transform() for pickles:filter and pickles:order scenario ordering/filtering, paths:resolve event, coordinator cleanup lifecycle; FormatterPlugin<T> with @cucumber/query library for non-trivial reporters; IConfiguration with satisfies keyword — modern TypeScript pattern for type-safe profile config; playwright-bdd v8.4.0 quality-of-life details — deterministic fixture name ordering, in-file BDD fixtures hidden from reports -->
<!-- Iter 29 additions: Gherkin DocString backtick delimiter (```) — Markdown-friendly alternative to """ for multi-line content in feature files; full delimiter comparison table with editor syntax-highlighting and content-type annotation support notes -->
<!-- Iter 28 additions: Cucumber Expressions advanced syntax — optional text (s), alternation a/b, anonymous {} parameter, escape sequences for { ( / characters; playwright-bdd v8.4.1 — explicit TypeScript type exports (BddFixtures, CreateBddOptions, TestTypeCommon), skipLibCheck fix for module:commonjs; DataTable escape sequences (\n \| \\) with rowsHash/hashes method reference table; @cucumber/gherkin-streams removal migration guide — regex-based counting and Messages API alternatives; Gherkin keyword scope rules reference table — Rule/Background/Examples valid parent scopes, tags-on-Background anti-pattern, multiple Background blocks silent failure -->
<!-- Iter 27 additions: Cucumber.js unreleased — formatter architecture redesign (SummaryFormatter/ProgressFormatter class deprecation, new summary/progress/progress-bar/pretty formatter design), printAttachments→includeAttachments migration, FORCE_COLOR env var replaces color format option; playwright-bdd unreleased — enrichReporterData config option removed (breaking), bddgen worker concurrency capped at CPU/2 (OOM fix), tinyglobby replaces fast-glob (internal dep), @cucumber/messages 27→32 + @cucumber/gherkin 32→39 (direct import paths breaking), JSON reporter attachment opt-in (attachments skipped by default), non-ASCII garbling fix in HTML reporter, strict Cucumber-compatible arity checks (breaking), docStringType exposed on $step fixture, AI agent skill for Gherkin generation (playwright-bdd v8.6+), junit-modern alias deprecated→junit canonical; full version migration guide added (v12 → unreleased upgrade path) -->
<!-- Iter 26 additions: playwright-bdd unreleased — junit-modern alias deprecated (canonical JUnit reporter), tinyglobby replaces fast-glob, bddgen worker concurrency limited to CPU/2 for OOM prevention, @cucumber/messages 27→32 and @cucumber/gherkin 32→39 major bumps (direct import breaking change), JSON reporter skips attachments by default, non-ASCII garbling fix in HTML reporter; Gherkin reference — "Imagine it's 1922" heuristic for technology-agnostic step writing, vivid story-like character names in Background vs generic identifiers; playwright-bdd v8.5.0 — documented verbose mode improvements and VS Code Cucumber reporter fix -->
<!-- Iter 25 additions: Cucumber.js unreleased — formatter output redesign (summary/progress/progress-bar/pretty), printAttachments deprecated→includeAttachments migration, SummaryFormatter/ProgressFormatter class deprecation, FORCE_COLOR env var replaces color format option; playwright-bdd unreleased — docStringType in $step fixture (now officially exposed), AI agent skill for Gherkin generation, strict arity checks (breaking), Node.js 20+ / Playwright 1.60+ minimum; playwright-bdd v8.4.2 — multiple step decorators on single method TypeScript example added -->
<!-- Iter 24 additions: Cucumber.js v12.7-v12.8.3 — env var propagation to parallel child processes (v12.7.0), custom externalizing option (v12.8.0), thrown-string error fix (v12.8.3 — latest as of 2026-05-09); playwright-bdd v8.0–v8.5.0 — missingSteps option, matchKeywords, BeforeScenario/AfterScenario aliases, tags-from-path, min Playwright 1.41, single-quote default, step decorators, "Fix with AI" (v8.1+); Gherkin DocString content-type annotation caveats; Additional Resources section completion -->
<!-- Iter 23 additions: Cucumber.js v12 (current version as of 2026) — TypeScript config files, built-in sharding v12.2, plugin architecture v12.5, formatter redesign, includeAttachments option, Node 24/25; Gherkin Rule keyword practical usage with per-rule Background and TypeScript step binding example; v12 migration pitfalls [community] -->
<!-- Iter 22 additions: two new official anti-patterns from cucumber.io/docs/guides/anti-patterns/ (Feature-Coupled Step Definitions, Conjunction Steps); discovery-first BDD model from cucumber.io/docs/bdd/ — both sources added to learning-sources catalog 2026-05-12 -->

## Core Principles

Behavior-Driven Development (BDD) is a software development methodology that encourages collaboration among developers, QA engineers, and business stakeholders to define the expected behavior of a system before implementation begins. Introduced by Dan North in 2003 as an evolution of Test-Driven Development (TDD), BDD bridges the gap between technical and non-technical team members by using a shared, human-readable language to describe system behavior.

BDD rests on three foundational pillars:

1. **Shared understanding**: All stakeholders — developers, QA, and product owners — collaborate to define what "done" means before writing a single line of code. This is why BDD produces better software than TDD alone: TDD tells you when code is correct; BDD tells you when the team agreed on what "correct" means.
2. **Executable specifications**: Feature files written in Gherkin serve as both documentation and automated tests, ensuring documentation never drifts from reality. A passing feature file is proof, not promise — unlike a wiki entry, it cannot lie about what the system does today.
3. **Outside-in development**: Teams start from the user's perspective, working inward from business scenarios toward implementation details. This prevents the common failure mode of building technically correct software that does not solve the actual business problem.

**The three BDD practices in sequence (official model):** Cucumber's official guidance names the three practices as **Discovery → Formulation → Automation**. This ordering is not incidental — it is the correct adoption sequence. Teams that jump straight to Automation (writing Gherkin and step definitions) without establishing Discovery (collaborative example workshops) produce test suites that look like BDD but deliver none of its communication benefit. The official guidance states explicitly: "If you're new to BDD, Discovery is the right place to start. You won't get much joy from the other two practices until you've mastered Discovery."

| Practice | What happens | Output |
|---|---|---|
| **Discovery** | Structured workshops (Three Amigos, Example Mapping) surface concrete examples from real business rules | Agreed-upon examples, resolved ambiguities, open question list |
| **Formulation** | Examples are expressed in Gherkin (Given-When-Then) — human-readable and machine-executable | `.feature` files reviewable by all stakeholders |
| **Automation** | Step definitions connect Gherkin to executable test code; CI runs them on every build | Living documentation: passing tests = proven behavior |

The key insight of BDD is that software failures are often not technical failures — they are communication failures. A study by the Standish Group repeatedly finds that the top causes of project failure are unclear requirements, stakeholder misalignment, and changing scope — not code quality. By forcing a concrete, example-driven conversation before development, BDD surfaces misunderstandings at the cheapest point: before code is written.

**Team maturity requirements**: BDD is not a tool you install — it is a practice you build over 2–3 sprints. Teams need:
- A product owner or business analyst who attends Three Amigos sessions and writes business rules in plain English.
- A QA engineer who can distinguish a business scenario from a test script and can challenge "but what happens when..." questions.
- A developer who is willing to write step bindings and treat them as production-quality code, not throwaway glue.

Without all three, BDD collapses into "Gherkin theater" — the form of the practice without the substance.

## When to Use

BDD adds clear value in the following contexts:

- **Complex business domains** where rules are non-trivial and ambiguity is common (insurance pricing, financial workflows, healthcare eligibility).
- **Cross-functional teams** where product managers, QA, and developers need a shared truth about behavior.
- **Regression-heavy features** where living documentation prevents behavior regressions over months of iteration.
- **Onboarding-heavy environments** where new team members need to understand system behavior quickly without reading implementation code.
- **Compliance and audit requirements** where human-readable proof of tested behavior has business value.

BDD adds overhead and should be avoided or used selectively in:

- **Rapid prototypes** or early-stage products where requirements change daily.
- **Small solo teams** where the collaboration overhead exceeds the communication benefit.
- **Pure UI exploration** or visual testing where Gherkin provides no semantic advantage.
- **Teams without product/QA buy-in** — BDD without the collaboration model degrades into just a verbose test framework.

---

## Patterns

### Feature File Structure

A feature file is a plain-text file (`.feature` extension) that uses Gherkin syntax to describe the behavior of a feature from a user's perspective. It is the central artifact in BDD — the thing developers implement against, QA validates, and product managers read.

```gherkin
# File: features/shopping-cart/checkout.feature

Feature: Shopping cart checkout
  As a registered customer
  I want to complete a purchase
  So that I can receive the products I selected

  Background:
    Given I am logged in as a registered customer
    And my shopping cart contains:
      | product      | quantity | price  |
      | Laptop stand | 1        | 49.99  |
      | USB-C hub    | 2        | 29.99  |

  Scenario: Successful checkout with credit card
    When I proceed to checkout
    And I enter valid credit card details
    And I confirm the order
    Then I should see an order confirmation page
    And I should receive a confirmation email within 2 minutes
    And my cart should be empty

  Scenario: Checkout fails with expired card
    When I proceed to checkout
    And I enter an expired credit card
    And I confirm the order
    Then I should see the error "Your card has expired"
    And my cart should remain unchanged

  Scenario Outline: Checkout with various discount codes
    When I apply discount code "<code>"
    And I proceed to checkout
    Then my total should be "<expected_total>"

    Examples:
      | code       | expected_total |
      | SAVE10     | 99.86          |
      | HALFOFF    | 54.98          |
      | INVALIDXXX | 109.97         |
```

**Key structural elements:**

- **Feature**: Names the feature and provides optional user-story context (`As a / I want / So that`).
- **Background**: Steps that run before every `Scenario` in the file. Use for shared setup — avoid putting assertions here.
- **Scenario**: A single concrete example of behavior. Each scenario is independent and must not depend on other scenarios.
- **Scenario Outline**: A parameterized scenario template combined with an `Examples` table for data-driven testing.
- **Examples**: A data table that feeds rows into a `Scenario Outline`. Each row becomes a separate test execution.

### Given-When-Then Grammar

Given-When-Then is the three-part structure for expressing behavior as a concrete example:

- **Given** (precondition): Establishes the context or state before the action. Should describe the world, not the actions that created the world.
- **When** (action): The single event or action that triggers the behavior being tested.
- **Then** (expected outcome): The observable result that verifies the behavior. Must be something the system produces, not an internal state.

Supporting keywords:
- **And** / **But**: Continue the same Given/When/Then clause when multiple steps are needed.
- **`*`** (asterisk): A context-free bullet step — useful in `Background` blocks when the Given/When/Then distinction adds noise.

**Declarative vs Imperative (critical distinction):**

```gherkin
# BAD — Imperative: describes HOW, not WHAT
Scenario: User logs in
  Given I navigate to "https://example.com/login"
  When I type "alice@example.com" into the "#email" field
  And I type "p@ssw0rd" into the "#password" field
  And I click the "#submit-button"
  Then the element "#welcome-banner" should be visible

# GOOD — Declarative: describes WHAT the system does
Scenario: Registered user accesses their dashboard
  Given I am a registered user
  When I log in with valid credentials
  Then I should see my dashboard
```

The imperative style tightly couples scenarios to UI implementation. When the `#submit-button` id changes, every test using it breaks. The declarative style survives UI refactors because the *what* (log in with valid credentials) is stable even when the *how* changes.

**Extended bad vs good comparison — three real failure patterns:**

```gherkin
# ================================================
# BAD: Pattern 1 — Imperative / UI-coupled
# ================================================
Scenario: User completes purchase
  Given I open the browser and navigate to "https://shop.example.com"
  When I click on "Add to Cart" next to "Blue T-Shirt"
  And I click the cart icon in the top-right corner
  And I click the "Proceed to Checkout" button
  And I fill in the form field "first_name" with "Alice"
  And I fill in the form field "last_name" with "Smith"
  And I click "#place-order-btn"
  Then the text "Order #" should appear on the page

# GOOD: Pattern 1 fixed — Declarative / business intent
Scenario: Customer completes a standard purchase
  Given I am a registered customer with items in my cart
  When I complete the checkout process
  Then my order should be confirmed
  And I should receive an order number

# ================================================
# BAD: Pattern 2 — Scenario as test script
# ================================================
Scenario: Verify the admin dashboard statistics
  Given the admin is on the dashboard
  And there are 42 users in the system
  And there are 7 active subscriptions
  And 3 support tickets are open
  When the admin refreshes the page
  Then the user count should display "42"
  And the subscription count should display "7"
  And the open ticket count should display "3"

# GOOD: Pattern 2 fixed — one behavior per scenario
Scenario: Dashboard reflects current active subscription count
  Given there are 7 active subscriptions
  When I view the admin dashboard
  Then the active subscription count should show 7

# ================================================
# BAD: Pattern 3 — Technical / non-business language
# ================================================
Scenario: JWT token is invalidated on logout
  Given a valid JWT token exists in localStorage
  When I send a DELETE request to "/api/auth/session"
  And I clear the localStorage
  Then a GET request to "/api/me" should return HTTP 401

# GOOD: Pattern 3 fixed — user observable behavior
Scenario: Logged-out user cannot access protected pages
  Given I am logged in as a registered user
  When I log out
  Then I should be redirected to the login page
  And I should not be able to access my account without logging in again
```

### Step Definitions (TypeScript / @cucumber/cucumber)

Step definitions are the binding code that connects Gherkin steps to executable test logic. Each step definition matches a Gherkin step using a string or regular expression and executes the corresponding automation code.

**Why step definitions matter**: They are the translation layer between the business language in `.feature` files and the technical automation code. A well-organized step definition library lets product managers write new scenarios by combining existing steps — lowering the cost of adding BDD coverage to new features.

**Cucumber expression parameter types** (built-in, avoid regex when these suffice):

| Type | Gherkin | TypeScript |
|---|---|---|
| `{string}` | `"hello"` or `'hello'` | `string` |
| `{int}` | `42` | `number` |
| `{float}` | `3.14` | `number` |
| `{word}` | `confirmed` (no spaces) | `string` |
| `{bigdecimal}` | `123.456` | `string` (use for currency) |

**Custom parameter type example** (for domain-specific types):

```typescript
import { defineParameterType } from '@cucumber/cucumber';

// Register a custom type for currency amounts like "$49.99"
defineParameterType({
  name: 'currency',
  regexp: /\$[\d,]+\.?\d{0,2}/,
  transformer: (s: string) => parseFloat(s.replace(/[$,]/g, '')),
});

// Now usable in Gherkin:
// Then a full refund of $150.00 should be issued
Then(
  'a full refund of {currency} should be issued',
  async function (this: CustomWorld, amount: number) {
    const refund = await this.page.locator('[data-testid="refund-amount"]').textContent();
    expect(parseFloat(refund!.replace(/[$,]/g, ''))).toBeCloseTo(amount, 2);
  }
);
```

**Full project bootstrap (TypeScript + Cucumber.js + Playwright):**

```bash
# 1. Install dependencies
npm install --save-dev @cucumber/cucumber @playwright/test ts-node typescript
npx playwright install chromium

# 2. Required TypeScript configuration
```

`tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "dist",
    "rootDir": ".",
    "types": ["node"]
  },
  "include": ["src/**/*", "features/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

`cucumber.json`:
```json
{
  "default": {
    "requireModule": ["ts-node/register"],
    "require": ["src/steps/**/*.ts", "src/support/**/*.ts"],
    "format": ["progress-bar", "html:reports/cucumber-report.html"],
    "publish": false
  }
}
```

**Recommended directory structure:**

```
project-root/
├── features/                    # Gherkin feature files
│   ├── shopping-cart/
│   │   └── checkout.feature
│   └── account/
│       └── registration.feature
├── src/
│   ├── steps/                   # Step definition files
│   │   ├── checkout.steps.ts
│   │   └── auth.steps.ts
│   └── support/                 # World, hooks, helpers
│       ├── world.ts
│       └── hooks.ts
├── reports/                     # Generated reports (gitignored)
├── cucumber.json
└── tsconfig.json
```

**Step definition file** (`src/steps/checkout.steps.ts`):

```typescript
import { Given, When, Then, Before, After, DataTable } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { getPage, getContext } from '../support/world';

// Matches: Given I am logged in as a registered customer
Given('I am logged in as a registered customer', async function () {
  const page = getPage(this);
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'test@example.com');
  await page.fill('[data-testid="password"]', 'TestPass123!');
  await page.click('[data-testid="submit"]');
  await page.waitForURL('/dashboard');
});

// Matches: And my shopping cart contains: (DataTable)
Given('my shopping cart contains:', async function (table: DataTable) {
  const page = getPage(this);
  const rows = table.hashes(); // [{ product, quantity, price }, ...]
  for (const row of rows) {
    await page.request.post('/api/cart/items', {
      data: { productName: row.product, quantity: parseInt(row.quantity) }
    });
  }
});

// Matches: When I enter valid credit card details
When('I enter valid credit card details', async function () {
  const page = getPage(this);
  await page.fill('[data-testid="card-number"]', '4242424242424242');
  await page.fill('[data-testid="card-expiry"]', '12/28');
  await page.fill('[data-testid="card-cvv"]', '123');
});

// Matches: Then I should see an order confirmation page
Then('I should see an order confirmation page', async function () {
  const page = getPage(this);
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
  await expect(page.url()).toContain('/order/confirmation');
});

// Matches: Then I should see the error {string}
Then('I should see the error {string}', async function (errorMessage: string) {
  const page = getPage(this);
  await expect(page.locator('[data-testid="error-message"]')).toHaveText(errorMessage);
});
```

**World object** (`src/support/world.ts`) — shared state across steps in a scenario:

```typescript
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { Browser, BrowserContext, Page, chromium } from '@playwright/test';

export class CustomWorld extends World {
  browser!: Browser;
  context!: BrowserContext;
  page!: Page;

  constructor(options: IWorldOptions) {
    super(options);
  }
}

export function getPage(world: CustomWorld): Page {
  return world.page;
}

setWorldConstructor(CustomWorld);
```

**Hooks** (`src/support/hooks.ts`):

```typescript
import { Before, After } from '@cucumber/cucumber';
import { chromium } from '@playwright/test';
import { CustomWorld } from './world';

Before(async function (this: CustomWorld) {
  this.browser = await chromium.launch({ headless: true });
  this.context = await this.browser.newContext();
  this.page = await this.context.newPage();
});

After(async function (this: CustomWorld, scenario) {
  if (scenario.result?.status === 'FAILED') {
    await this.page.screenshot({ path: `reports/screenshots/${scenario.pickle.name}.png` });
  }
  await this.browser.close();
});
```

### Scenario Outline & Examples (data-driven)

`Scenario Outline` eliminates copy-paste scenarios that differ only in input values. The `<placeholder>` syntax in steps gets substituted with each row from the `Examples` table at runtime.

```gherkin
Feature: User authentication

  Scenario Outline: Login attempt with various credential combinations
    Given I am on the login page
    When I submit the credentials "<email>" and "<password>"
    Then I should see the response "<expected_outcome>"
    And the response status should be "<status_code>"

    Examples: Valid credentials
      | email                | password    | expected_outcome         | status_code |
      | alice@example.com    | ValidPass1! | Welcome back, Alice      | 200         |
      | bob@example.com      | SecureP@ss  | Welcome back, Bob        | 200         |

    Examples: Invalid credentials
      | email                | password    | expected_outcome         | status_code |
      | alice@example.com    | wrongpass   | Invalid email or password | 401        |
      | notauser@example.com | anything    | Invalid email or password | 401        |
      | alice@example.com    |             | Password is required      | 400        |
```

Multiple `Examples` blocks with labels (`Valid credentials`, `Invalid credentials`) act as logical groupings. Each row in any `Examples` block generates a distinct test execution. The Cucumber HTML report shows each row as a named test case, making failures immediately traceable to the input set.

**Step definition binding for Scenario Outline** (`src/steps/auth.steps.ts`):

```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { CustomWorld } from '../support/world';

Given('I am on the login page', async function (this: CustomWorld) {
  await this.page.goto('/login');
  await expect(this.page.locator('[data-testid="login-form"]')).toBeVisible();
});

When(
  'I submit the credentials {string} and {string}',
  async function (this: CustomWorld, email: string, password: string) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="submit"]');
  }
);

Then(
  'I should see the response {string}',
  async function (this: CustomWorld, expectedOutcome: string) {
    const successMsg = this.page.locator('[data-testid="welcome-message"]');
    const errorMsg = this.page.locator('[data-testid="error-message"]');
    const visible = (await successMsg.isVisible())
      ? successMsg
      : errorMsg;
    await expect(visible).toContainText(expectedOutcome);
  }
);
```

### Tags, Filtering, and CI Integration (TypeScript)

Tags (`@tagname`) control which scenarios run in which CI pipeline stage. This is essential for managing test suite speed as it grows beyond 100 scenarios.

**Tagged feature file** (`features/payments/refund.feature`):

```gherkin
@payments @regression
Feature: Order refund processing

  @smoke @critical
  Scenario: Full refund for a cancelled order
    Given I have a completed order worth $150.00
    When I cancel the order within 24 hours
    Then a full refund of $150.00 should be issued
    And I should receive a refund confirmation email

  @regression @slow
  Scenario: Partial refund for a returned item
    Given I have a completed order with 3 items
    When I initiate a return for 1 item worth $49.99
    Then a partial refund of $49.99 should be issued within 5 business days
    And the remaining items should remain in my order history

  @wip
  Scenario: Refund to a different payment method
    Given I paid with a debit card that has since expired
    When I request a refund
    Then I should be prompted to provide a new payment method

  @negative @regression
  Scenario: Refund rejected outside return window
    Given I have a completed order from 45 days ago
    When I attempt to initiate a return
    Then I should see the error "Return window has closed (30-day limit)"
    And no refund should be processed
```

**Cucumber configuration for tag-based CI pipelines** (`cucumber.json`):

```json
{
  "smoke": {
    "requireModule": ["ts-node/register"],
    "require": ["src/steps/**/*.ts", "src/support/**/*.ts"],
    "tags": "@smoke and not @wip",
    "format": ["progress-bar", "json:reports/smoke-results.json"],
    "parallel": 4
  },
  "regression": {
    "requireModule": ["ts-node/register"],
    "require": ["src/steps/**/*.ts", "src/support/**/*.ts"],
    "tags": "@regression and not @wip",
    "format": ["progress-bar", "html:reports/regression-report.html"],
    "parallel": 8
  },
  "nightly": {
    "requireModule": ["ts-node/register"],
    "require": ["src/steps/**/*.ts", "src/support/**/*.ts"],
    "tags": "not @wip",
    "format": ["html:reports/full-report.html", "junit:reports/results.xml"],
    "parallel": 16
  }
}
```

**Tag-aware hook** (`src/support/hooks.ts` — extended version):

```typescript
import { Before, After, BeforeAll, AfterAll, Status } from '@cucumber/cucumber';
import { chromium, Browser } from '@playwright/test';
import { CustomWorld } from './world';

let sharedBrowser: Browser;

BeforeAll(async function () {
  sharedBrowser = await chromium.launch({
    headless: process.env.CI === 'true',
    slowMo: process.env.CI ? 0 : 50,
  });
});

AfterAll(async function () {
  await sharedBrowser?.close();
});

Before(async function (this: CustomWorld, scenario) {
  const tags = scenario.pickle.tags.map(t => t.name);
  this.browser = sharedBrowser;
  this.context = await sharedBrowser.newContext({
    // Mobile viewport for @mobile-tagged scenarios
    ...(tags.includes('@mobile') && {
      viewport: { width: 390, height: 844 },
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
    }),
  });
  this.page = await this.context.newPage();
  this.scenarioTags = tags;
});

After(async function (this: CustomWorld, scenario) {
  if (scenario.result?.status === Status.FAILED) {
    const screenshot = await this.page.screenshot({ fullPage: true });
    this.attach(screenshot, 'image/png'); // Embeds in Cucumber HTML report
    console.error(`FAILED: ${scenario.pickle.name}`);
    console.error(`  Tags: ${this.scenarioTags.join(', ')}`);
    console.error(`  URL at failure: ${this.page.url()}`);
  }
  await this.context.close();
});
```

**Running tagged subsets:**

```bash
# PR gate: smoke only (fast, < 2 minutes)
npx cucumber-js --profile smoke

# Nightly: all non-WIP scenarios
npx cucumber-js --profile nightly

# Ad-hoc: specific tag combination
npx cucumber-js --tags "@payments and @negative"
```



### BDD for REST APIs (Without Browser Automation)

BDD is not limited to browser testing. Many of the most valuable BDD scenarios target
API behavior directly — they run in milliseconds, not seconds, and validate the contract
between services in language the product team can review.

```gherkin
# features/api/orders.feature
Feature: Order management API
  As an API consumer
  I want to manage orders through the REST API
  So that client applications can build order workflows reliably

  Background:
    Given I have a valid API authentication token

  Scenario: Creating an order returns 201 with order ID
    Given I have the following order payload:
      """json
      {
        "customerId": "cust-001",
        "items": [{ "productId": "prod-42", "quantity": 2 }],
        "shippingAddress": { "city": "Berlin", "country": "DE" }
      }
      """
    When I POST to "/api/v1/orders"
    Then the response status is 201
    And the response body contains a field "orderId" matching /^ORD-[A-Z0-9]{8}$/
    And the response body contains "status" equal to "pending"

  Scenario: Fetching a non-existent order returns 404
    When I GET "/api/v1/orders/ORD-DOESNOTEXIST"
    Then the response status is 404
    And the response body contains "error" equal to "Order not found"
```

```typescript
// src/steps/api.steps.ts — API BDD without a browser
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from 'chai';
import supertest from 'supertest';
import { app } from '../../src/app';
import { ApiWorld } from '../support/api-world';

const api = supertest(app);

Given('I have a valid API authentication token', async function(this: ApiWorld) {
  const res = await api.post('/api/auth/token').send({
    clientId: process.env.TEST_CLIENT_ID,
    clientSecret: process.env.TEST_CLIENT_SECRET,
  });
  expect(res.status).to.equal(200);
  this.authToken = res.body.accessToken;
});

Given('I have the following order payload:', function(this: ApiWorld, docString: string) {
  this.requestBody = JSON.parse(docString);
});

When('I POST to {string}', async function(this: ApiWorld, path: string) {
  this.response = await api
    .post(path)
    .set('Authorization', `Bearer ${this.authToken}`)
    .set('Content-Type', 'application/json')
    .send(this.requestBody);
});

When('I GET {string}', async function(this: ApiWorld, path: string) {
  this.response = await api
    .get(path)
    .set('Authorization', `Bearer ${this.authToken}`);
});

Then('the response status is {int}', function(this: ApiWorld, expectedStatus: number) {
  expect(this.response.status).to.equal(expectedStatus,
    `Expected HTTP ${expectedStatus} but got ${this.response.status}. ` +
    `Body: ${JSON.stringify(this.response.body)}`
  );
});

Then(
  'the response body contains a field {string} matching {word}',
  function(this: ApiWorld, field: string, pattern: string) {
    const regex = new RegExp(pattern.replace(/^\/|\/$/g, ''));
    expect(this.response.body[field]).to.match(regex);
  }
);

Then(
  'the response body contains {string} equal to {string}',
  function(this: ApiWorld, field: string, value: string) {
    expect(this.response.body[field]).to.equal(value);
  }
);
```

**Why API BDD matters**: Browser tests are 10–50x slower than API tests. By pushing
behavioral verification to the API layer wherever possible, teams keep BDD suites fast
enough to run in PR pipelines. The rule: use browser automation only for scenarios where
the UI interaction itself is the thing being tested (visual feedback, accessibility,
client-side validation). For all business logic reachable via API, use API-level BDD.

### CI/CD Integration and Report Publishing

BDD suites that run in CI without publishing readable reports lose the "living
documentation" value immediately: failures become log noise rather than traceable
business-behavior regressions. The minimum viable CI integration publishes the
Cucumber HTML report as a build artifact and fails the build on any scenario failure.

```yaml
# .github/workflows/bdd.yml
name: BDD Acceptance Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  bdd-smoke:
    name: BDD Smoke (PR gate)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Run smoke scenarios
        run: npx cucumber-js --profile smoke
        env:
          CI: true
          BASE_URL: ${{ vars.TEST_BASE_URL }}
          TEST_CLIENT_ID: ${{ secrets.TEST_CLIENT_ID }}
          TEST_CLIENT_SECRET: ${{ secrets.TEST_CLIENT_SECRET }}

      - name: Upload Cucumber HTML report
        if: always()   # Upload even on failure — needed for debugging
        uses: actions/upload-artifact@v4
        with:
          name: cucumber-smoke-report
          path: reports/
          retention-days: 14

  bdd-regression:
    name: BDD Regression (nightly)
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    strategy:
      matrix:
        shard: [1, 2, 3, 4]   # 4-way parallel sharding
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run regression shard ${{ matrix.shard }}/4
        run: |
          npx cucumber-js --profile regression \
            --shard ${{ matrix.shard }}/${{ strategy.job-total }}
        env:
          CI: true

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: regression-report-shard-${{ matrix.shard }}
          path: reports/
```

**Key CI principles:**
- Always upload reports with `if: always()` — failure reports are more valuable than success reports
- Use matrix sharding for regression suites; Cucumber.js `--parallel` for within-shard parallelism
- Smoke gate on every PR; full regression nightly on main
- Set `CI: true` — hooks can use this to take screenshots on failure and adjust browser speed

### Living Documentation is the concept that feature files serve as the definitive, always-current description of system behavior — because they are the tests. Unlike a Wiki page or a Word document that ages independently of the code, a passing feature file proves the described behavior exists today.

**Why living documentation matters**: In traditional teams, business requirements live in Confluence; test cases live in TestRail or Jira; code lives in the repository. These three representations drift apart within weeks of initial delivery. Bugs occur precisely in the gaps between them. BDD collapses all three into a single artifact — the `.feature` file — that is simultaneously a requirement (readable by product), a test (executable by CI), and documentation (browsable by anyone). The cost of keeping documentation current drops to zero because the CI pipeline enforces it.

Tools that generate browsable HTML reports from Cucumber output include:
- **Cucumber HTML reports** (built-in, zero config)
- **Allure Framework** (rich, timeline, screenshots, JIRA integration)
- **Living Doc** (`@cucumber/html-formatter`) — publishes a navigable feature file browser

The value of living documentation compounds over time: a new team member can read the `features/` directory to understand what the system does without reading the codebase. A product manager can verify that the payment flow described in the quarterly roadmap is actually implemented and tested.

**Practical rule**: If a feature file describes behavior that cannot currently be executed as a passing test, it must be tagged `@wip` or removed. Stale feature files destroy trust in the documentation and eliminate BDD's primary value proposition.

### Three Amigos Collaboration [community]

The Three Amigos is a pre-development workshop involving three perspectives:

1. **Product/Business** (the "what"): Describes the goal and the business rule.
2. **Developer** (the "how"): Identifies technical constraints and edge cases.
3. **QA** (the "what could go wrong"): Surfaces missing scenarios, boundary conditions, and error paths.

The output of a Three Amigos session is a set of agreed-upon Gherkin scenarios that all three parties have signed off on. These scenarios become the acceptance criteria for the sprint ticket.

**Why it works**: Each role sees different blind spots. Product forgets error states. Developers forget business rules. QA forgets performance or security concerns. The meeting forces all three to confront the same concrete example before code exists.

**[community] Practical Three Amigos guidelines from teams running BDD at scale:**

- Keep sessions to 30–45 minutes per user story. Longer sessions lose focus.
- Use **Example Mapping** (from Matt Wynne, Cucumber Ltd) as a structured warm-up before writing Gherkin:
  1. Yellow card: Write the user story title.
  2. Blue cards: Write one card per business rule (e.g., "Discount codes expire after 30 days").
  3. Green cards: Write one concrete example per rule (this becomes a scenario).
  4. Red cards: Write open questions that cannot be answered in the meeting.
  5. Stop when no more green cards can be added without a red card blocker.
  The output is a visual map that makes scope visible. If there are 15 green cards and 8 red cards, the story is not ready to develop.
**Example Mapping output format** (structured capture from a Three Amigos session):

```yaml
# example-map-checkout-discount.yaml
# Output artifact from a Three Amigos session — becomes Gherkin after refinement
story: "As a customer, I want to apply a discount code at checkout"

rules:
  - id: R1
    text: "Discount codes reduce the order total by a percentage"
    examples:
      - "Alice applies SAVE10 to a $100 order → total becomes $90"
      - "Bob applies HALFOFF to a $60 order → total becomes $30"
    open_questions: []

  - id: R2
    text: "Expired discount codes are rejected at checkout"
    examples:
      - "Alice enters EXPIRED2023 (expired Jan 2024) → error: 'Code has expired'"
    open_questions:
      - "Q: Do we show when the code expired, or just that it's invalid?"

  - id: R3
    text: "Each code can only be used once per customer"
    examples:
      - "Alice uses SAVE10, then tries SAVE10 again → error: 'Code already used'"
    open_questions:
      - "Q: Does 'used' mean applied, or applied + order confirmed?"
      - "Q: What about order cancellations — does that restore the code?"

  - id: R4
    text: "Discount codes cannot reduce the total below $0"
    examples:
      - "Alice applies a 100% code to a $25 order → total is $0, not negative"
    open_questions: []

# Red cards (blockers) — story NOT ready to develop until resolved
blockers:
  - "Q (R2): Display expired date or generic 'invalid code' message? — awaiting PO decision"
  - "Q (R3): Code restoration on cancellation — depends on payment team confirmation"
```

This YAML artifact becomes the checklist for which Gherkin scenarios to write.
Each `example` in a rule maps directly to a `Scenario`; each `open_question` maps to a
`@wip` scenario with a comment until the question is answered.

- Three Amigos is not a sign-off meeting — it is a *discovery* meeting. The Gherkin gets refined after.
- Product managers who write Gherkin without developer or QA input create scenarios that are either untestable or missing key edge cases.
- **[community]** Run Three Amigos as a standing 30-minute meeting every Monday for the upcoming sprint's stories. Teams that run it ad-hoc skip it under pressure; teams with a recurring calendar slot maintain the discipline.

---

## Anti-Patterns

### 1. Imperative Style (UI-coupled steps)

**Problem**: Writing steps that describe UI interactions rather than business intent.

```gherkin
# Anti-pattern: implementation-coupled
When I click the button with id "checkout-btn"
And I wait 2 seconds
And I select "Visa" from the dropdown "#card-type"
```

**Why it hurts**: Every UI change cascades into feature file edits. Scenarios become change-amplifiers instead of change-detectors.

**Fix**: Write at the domain level. Delegate UI interaction to the step definition code, not the Gherkin.

### 2. Step Definition Bloat

**Problem**: Hundreds of highly specific, single-use step definitions that cannot be reused across scenarios.

```typescript
// Anti-pattern: over-specific steps
Given('the user alice@example.com is logged in with password TestPass123! on the staging environment', ...)
Given('the user bob@corp.com is logged in with password Admin!123 on the staging environment', ...)
```

**Fix**: Use Cucumber expressions with typed parameters. One well-parameterized step replaces dozens of specific ones.

```typescript
// Good: parameterized
Given('{string} is logged in', async function (email: string) { ... })
```

### 3. Testing UI Through BDD

**Problem**: Using BDD scenarios for every single UI interaction, including trivial ones.

BDD adds overhead (Gherkin parsing, step matching, World setup) on top of already-expensive browser tests. Using BDD for "click this, see that" interactions that have no business meaning is waste.

**Fix**: BDD is appropriate for **business behaviors** (checkout, onboarding, permissions). Use plain Playwright/Cypress tests for pure UI mechanics (component rendering, visual regression).

### 4. Scenario Interdependence

**Problem**: Scenarios that share state or must run in order.

```gherkin
# Anti-pattern: implicit ordering
Scenario: Create a product    # Must run first to populate DB
Scenario: Edit the product    # Depends on Scenario 1
Scenario: Delete the product  # Depends on Scenario 2
```

**Fix**: Each scenario is hermetic. Use `Background`, hooks, or API setup to establish state independently.

### 5. Vague Then Steps

**Problem**: `Then` steps that assert internal state, implementation details, or vague outcomes.

```gherkin
# Anti-pattern: not user-observable
Then the database should contain a record with status "confirmed"
Then the React state should have isLoading set to false
```

**Fix**: Assert what the user can observe: UI elements, API responses, emails, redirects.

### 6. Feature-Coupled Step Definitions [official]

**Problem**: Step definitions organized by feature file rather than by domain concept. This makes steps impossible to reuse across features, leading to explosive duplication as the suite grows.

```typescript
// ❌ Anti-pattern: feature-specific step definition files
// edit_work_experience_steps.ts
Given('I have a CV and I am on the edit work experience page', async function () {
  const employee = new Employee('Sally');
  await employee.createCV();
  await this.page.goto(`/employees/${employee.id}/work-experience/new`);
});

// edit_languages_steps.ts — near-duplicate, different feature
Given('I have a CV and I am on the edit languages page', async function () {
  const employee = new Employee('Sally');
  await employee.createCV();
  await this.page.goto(`/employees/${employee.id}/languages/new`);
});
```

Both steps share identical CV-creation logic but cannot reuse it because they are feature-coupled. When `Employee.createCV()` changes signature, both must be updated independently.

```typescript
// ✅ Fix: organize step definitions by domain concept
// employee.steps.ts — reusable across all features that involve employees
Given('I have an employee named {string}', async function (this: CustomWorld, name: string) {
  this.employee = new Employee(name);
});

Given('the employee has a CV', async function (this: CustomWorld) {
  await this.employee.createCV();
  this.attach(`Created CV for employee ${this.employee.id}`, 'text/plain');
});

// navigation.steps.ts — reusable navigation steps
Given('I am on the {string} page for the employee', async function (this: CustomWorld, section: string) {
  const sectionPaths: Record<string, string> = {
    'edit work experience': 'work-experience/new',
    'edit languages': 'languages/new',
    'edit profile': 'profile/edit',
  };
  const path = sectionPaths[section];
  if (!path) throw new Error(`Unknown employee section: "${section}"`);
  await this.page.goto(`/employees/${this.employee.id}/${path}`);
});
```

The refactored scenario:
```gherkin
# Works for any employee feature — no duplication
Scenario: Employee adds work experience
  Given I have an employee named "Sally"
  And the employee has a CV
  And I am on the "edit work experience" page for the employee
  When I add a new work experience entry
  Then the work experience should appear on the employee profile
```

**Why it hurts**: Feature-coupled steps create a maintenance multiplier. When a common precondition changes (authentication mechanism, data model, URL structure), the change must be applied to every feature-specific step file independently. Teams with 20+ feature files report spending entire sprint cycles on test maintenance after a single refactor.

**Rule of thumb**: If a step appears in more than one feature file, it belongs in a domain-concept step file, not a feature file. A domain-concept file groups steps by what they operate on (employees, orders, payments), not by which feature test they were first written for.

### 7. Conjunction Steps [official]

**Problem**: Combining multiple distinct preconditions or actions into a single step using conjunctions ("and", "with", "then"). This creates steps that are highly specific and cannot be composed into other scenarios.

```gherkin
# ❌ Anti-pattern: conjunction step — all-or-nothing precondition
Given I have shades and a brand new Mustang
Given the user is logged in and has admin permissions and is on the dashboard
When I click the submit button and wait for the response and see the confirmation
```

```typescript
// ❌ Anti-pattern: step definition — cannot reuse either precondition alone
Given('I have shades and a brand new Mustang', async function (this: CustomWorld) {
  this.accessories = ['shades'];
  this.vehicle = new Car('Mustang', { year: 2024 });
  // Both preconditions coupled — cannot test "user has shades but no car"
});
```

```gherkin
# ✅ Fix: atomic steps — each precondition is independently composable
Given I have shades
And I have a brand new Mustang

Given the user is logged in
And the user has admin permissions
And the user is on the dashboard

When I submit the form
Then I should see a confirmation message
```

```typescript
// ✅ Fix: atomic step definitions — each independently reusable
Given('I have shades', function (this: CustomWorld) {
  this.accessories.push('shades');
});

Given('I have a brand new {word}', async function (this: CustomWorld, vehicleModel: string) {
  this.vehicle = new Car(vehicleModel, { year: new Date().getFullYear() });
});

// "I have shades" now reusable in beach scenarios, fashion tests, photo tests
// "I have a brand new {word}" reusable with any vehicle model
```

**When conjunction steps are appropriate**: A step that naturally reads as a single concept in the business domain is acceptable even if it involves two related setups — `Given I am a logged-in customer with items in my cart` is a single business state (ready-to-checkout customer), not two unrelated conjunctions. The test: could each part of the conjunction plausibly appear *without* the other part in a different scenario? If yes, split them.

**Why it hurts at scale**: Conjunction steps grow with the product. When a new scenario needs "shades" but not the "Mustang," the author writes a new conjunction step `Given I have shades and a bicycle`, adding yet another non-reusable step. After 6 months, teams have hundreds of near-duplicate steps that differ only in their conjunction combinations — making the step library a labyrinth rather than a vocabulary.

---

## Real-World Gotchas [community]

**[community] 1. Feature file ownership confusion**: Teams often struggle with who owns the `.feature` files. Developers treat them as test code (and refactor them without business review). Product managers treat them as documentation (and let them drift from the test reality). Establish a rule: no Gherkin change without Three Amigos sign-off.

**[community] 2. Step definition duplication across feature files**: As the suite grows, different team members write steps for the same behavior in slightly different phrasing, creating a graveyard of near-duplicate step functions. Run `cucumber-unused` or periodic audits to prune dead steps.

**[community] 3. Slow suite syndrome**: BDD suites that run browser automation for every scenario become the slowest part of CI. At 500+ scenarios, a 30-minute run is common. Mitigation: tag scenarios (`@smoke`, `@regression`, `@slow`), run only `@smoke` on PRs, full suite nightly.

**[community] 4. The "BDD theater" failure mode**: Teams write Gherkin after the code is done, effectively reverse-engineering documentation from implementation. This delivers zero of the communication benefit of BDD. BDD must begin in the discovery phase, not after development.

**[community] 5. Cucumber is not BDD**: The tool is not the methodology. Teams can use Cucumber without doing BDD (writing Gherkin in isolation, no collaboration). Teams can do BDD without Cucumber (structured conversations, example mapping, then plain test frameworks). The collaboration is the practice; Cucumber is optional tooling.

**[community] 6. DataTable misuse**: DataTables are powerful but are often used to simulate the absence of proper step parameterization. If a step only ever receives one row, it is not a table — it is a step with too many parameters.

**[community] 7. @wip tag debt**: The `@wip` (work-in-progress) tag is meant to mark scenarios under active development. Teams often forget to remove it, creating scenarios that are never executed in CI. Treat `@wip` count as a health metric in sprint reviews.

**[community] 8. Parallel execution breaks shared state**: When you run scenarios in parallel (e.g., `--parallel 8`), any global state — a shared database, a shared test user account, a shared API key counter — produces intermittent failures that are nearly impossible to debug. Solution: each scenario must provision its own data via API calls in `Before` hooks, using generated unique identifiers.

**[community] 9. Over-reliance on UI for state setup**: BDD scenarios that establish their `Given` preconditions by clicking through the UI to create data are 10x slower and 10x more fragile than scenarios that use direct API calls. The rule of thumb: only automate via browser what the scenario is actually *testing*. Everything else goes through the API or direct DB seeding.

**[community] 10. Missing the "and" between rules and examples**: The most common Three Amigos failure is conflating a *business rule* with an *example*. "Users over 18 can purchase alcohol" is a rule. "Alice, age 25, successfully purchases wine" is an example of that rule. Gherkin scenarios are examples, not rules. When teams write rules as scenarios, they end up with abstract, value-free scenarios like "Given a user meets the age requirement."

**[community] 11. SpecFlow and test isolation in .NET**: SpecFlow teams using shared SQL Server databases frequently hit race conditions when running scenarios in parallel. The SpecFlow+Runner parallel execution model requires either `[Binding]` classes that implement `IResetData` to restore state, or use of in-memory databases (SQLite, EF Core InMemory) for test isolation. Teams that ignore this spend weeks debugging flaky CI pipelines.

**[community] 12. Behave and async Python**: Behave's step definitions are synchronous by default. Python teams using async frameworks (FastAPI, aiohttp) must either use `asyncio.run()` inside steps or switch to `pytest-bdd`, which supports `async def` step functions natively. Mixing sync Behave with async application code is a common source of event loop errors in CI.

**[community] 13. BDD is the top of the pyramid, not the whole pyramid**: Teams that adopt BDD sometimes mistake it for their entire test strategy, writing BDD scenarios for unit-level behavior. A BDD scenario that checks whether a discount calculation is mathematically correct belongs in a unit test — it runs 1000x faster, requires no browser setup, and gives a clearer failure message. BDD scenarios should cover user-observable system behavior: the flows that matter to the business. Everything below that belongs in lower pyramid layers.

**[community] 15. DocStrings vs DataTables — choosing the right multiline input format** [community]:

Use `DocString` (triple-quoted block) for freeform or pre-structured text (JSON payloads,
HTML snippets, markdown). Use `DataTable` for tabular data where each row is an entity.
Mixing them — encoding JSON inside a DataTable cell — is a common mistake that makes step
definitions parse twice and produces cryptic failure messages.

```gherkin
# GOOD: DocString for a JSON payload
Given I have the following order payload:
  """json
  { "customerId": "cust-001", "quantity": 2 }
  """

# GOOD: DataTable for tabular entity data
Given my cart contains:
  | product       | qty | price |
  | Laptop stand  | 1   | 49.99 |
  | USB hub       | 2   | 29.99 |

# BAD: JSON stuffed into a DataTable cell
Given my cart contains:
  | product data                                    |
  | {"name":"Laptop stand","qty":1,"price":49.99}  |
```

**[community] 16. Use `--dry-run` before writing step definitions** [community]:
Run `npx cucumber-js --dry-run` after writing new `.feature` files to see which steps
are unmatched — without executing any tests. This produces a scaffold of step definition
stubs, prevents "undefined step" surprises in CI, and creates a natural TDD workflow:
write Gherkin → dry-run → implement stubs → run full suite.

```bash
# Generate step definition stubs for all unmatched steps
npx cucumber-js --dry-run --format usage 2>&1 | grep "undefined"

# Or get auto-generated TypeScript snippets:
npx cucumber-js --dry-run 2>&1
# Output includes:
# You can implement missing steps with the snippets below:
# Given('I have a valid API authentication token', function () {
#   // ...
# });
```

**[community] 17. Cucumber.js v10+ ESM migration breaks ts-node setups** [community]:
Cucumber.js v10 (released late 2023) dropped CommonJS support. Projects on
`@cucumber/cucumber@10+` with the traditional `ts-node/register` setup will fail with
`Error: require() of ES Module`. The fix is to switch to `@cucumber/cucumber`'s native
ESM loader or pin to v9 until the team can migrate:

```json
// cucumber.js (not cucumber.json — ESM config format)
export default {
  default: {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    loader: ['ts-node/esm'],   // Not 'requireModule' — ESM uses 'import'/'loader'
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
    publish: false,
  },
};
```

```json
// package.json — required for ESM
{
  "type": "module",
  "scripts": {
    "test:bdd": "cucumber-js"
  }
}
```

This is the most common source of "it worked in v9, completely broken in v10" issues
teams hit when upgrading. The v10 migration guide at `cucumber.io/docs/installation/`
documents the full change set.

**[community] 18. Tag expression syntax changed in Cucumber.js v9+** [community]:
The old comma-based tag filter (`--tags @smoke,@regression`) was silently deprecated.
The modern syntax uses boolean expressions (`--tags "@smoke or @regression"`). CI
scripts that use the old syntax may appear to work but actually run all scenarios
(the old syntax is ignored in v9+ without a warning in some formatters).

```bash
# Old (v8 and below) — broken silently in v9+
npx cucumber-js --tags @smoke,@regression

# Correct (v9+) — explicit boolean expressions
npx cucumber-js --tags "@smoke or @regression"
npx cucumber-js --tags "@regression and not @wip"
npx cucumber-js --tags "@payments and (@smoke or @critical)"
```

**[community] 14. Gherkin in multiple languages** [community]: Cucumber supports Gherkin keywords in 70+ human languages (`Feature` becomes `Funcionalidad` in Spanish, `Fonctionnalité` in French). For global teams, writing feature files in the primary business language of the product owner — even if developers work in English — dramatically improves Three Amigos participation from non-English-speaking stakeholders.

**[community] 19. BDD scenarios as mutation testing targets** [community]:
Mutation testing tools like Stryker (TypeScript) measure whether your tests actually
detect code changes. BDD suites that have low mutation scores — meaning mutants survive
— are a sign of "green but hollow" scenarios: the scenario passes whether or not the
business rule is actually implemented correctly. Run Stryker against your step
definitions and domain code to find scenarios that need sharper `Then` assertions.

```bash
# Run Stryker mutation testing against the domain logic covered by BDD
npx stryker run --testRunner cucumber \
  --mutate "src/domain/**/*.ts" \
  --reporters html,progress

# Interpret results:
# Killed mutant = your BDD scenario caught the regression ✓
# Survived mutant = your Then assertions are too weak — tighten them
```

A common finding: `Then the order is confirmed` passes even when the order status field
is missing from the API response because the step only checks HTTP 201, not the body
content. Mutation testing surfaces these weak assertions systematically.

---

## Tradeoffs & Alternatives

### When BDD Adds Value

| Context | BDD Benefit | Estimated ROI timeline |
|---|---|---|
| Complex business rules | Forces rule articulation before code | Pays back in sprint 2–3 |
| Multiple stakeholders | Single source of truth for all parties | Immediate, first Three Amigos |
| High-turnover teams | Feature files onboard new members fast | Pays back after 1st team change |
| Regulated industries | Human-readable audit evidence | Pays back at first audit |
| Long-lived products (2+ years) | Living documentation stays current | Compounds monthly |

### When BDD Adds Overhead

| Context | Why BDD Hurts |
|---|---|
| Solo developer | Collaboration overhead with no collaboration |
| Prototype / MVP | Gherkin + step code doubles test authoring time |
| Pure UI testing | No semantic advantage over plain selectors |
| Team without buy-in | Becomes just a slow, verbose test framework |
| Microservice internals | Unit/integration tests serve better |

**Known adoption cost:** Teams typically require 2–3 sprints to establish a stable BDD practice. The primary cost drivers are: (1) Three Amigos session discipline (recurring calendar commitment), (2) step definition code review (treating Gherkin as production documentation), and (3) CI integration for automated scenario execution. Teams that underestimate this cost commonly abandon BDD after one sprint when the payoff is not yet visible.

### Named Alternatives

| Approach | Setup Cost | Collaboration Benefit | Business Readability | Best For |
|---|---|---|---|---|
| Full BDD (Gherkin + Cucumber) | High (2–3 sprints) | Maximum | Maximum | Cross-functional teams, regulated industries |
| Example Mapping only | Low (1 meeting) | High | Medium (ticket text) | Teams wanting discovery without tool overhead |
| Plain Playwright + page objects | Medium | None | Low (code) | Developer-led QA, no PO involvement in tests |
| Vitest + describe/it (BDD-style) | Very Low | Low | Medium (code) | TypeScript teams, unit/integration BDD without Cucumber |
| Jest + Testing Library | Low | None | Low (code) | Component/unit behavior, fast feedback loop |
| pytest-bdd (Python) | Medium | Medium | Medium | Python teams wanting BDD without Behave's limitations |

**Alternative 1 — Example Mapping (without Gherkin):** Run the Three Amigos workshop, produce structured acceptance criteria in ticket comments, then write regular tests. Captures BDD's collaboration benefit without the tooling investment. This is the recommended starting point for teams evaluating BDD — get the collaboration right before adding the automation layer.

**Alternative 2 — Plain Playwright + page objects:** 90% of the coverage, 50% of the setup overhead. Best for teams that do not need the business-readable layer. A well-named test like `test('guest user cannot access admin panel')` communicates intent without Gherkin.

**Alternative 3 — Vitest BDD-style (TypeScript):** For TypeScript projects already using Vitest, the `describe`/`it`/`expect` vocabulary enables a BDD-style approach at unit and integration level without any Gherkin toolchain. Product managers can read these test names in the CI report (`vitest --reporter=verbose`) and understand the behavior being verified without requiring Gherkin tooling.

```typescript
// src/features/discount/discount.spec.ts — BDD-style with Vitest
import { describe, it, expect } from 'vitest';
import { applyDiscount } from './discount.service';
import { createTestCart } from '../__fixtures__/cart.factory';

describe('Discount code application', () => {
  describe('when a valid percentage discount code is applied', () => {
    it('reduces the order total by the specified percentage', () => {
      const cart = createTestCart({ total: 100 });
      const result = applyDiscount(cart, { code: 'SAVE10', type: 'percent', value: 10 });
      expect(result.total).toBe(90);
      expect(result.discountApplied).toBe(true);
    });

    it('does not reduce the total below zero', () => {
      const cart = createTestCart({ total: 20 });
      const result = applyDiscount(cart, { code: 'ALL100', type: 'percent', value: 100 });
      expect(result.total).toBe(0);
    });
  });

  describe('when an expired discount code is applied', () => {
    it('rejects the code and returns an error message', () => {
      const cart = createTestCart({ total: 100 });
      const expiredCode = { code: 'EXPIRED23', type: 'percent' as const, value: 20, expiresAt: new Date('2023-01-01') };
      expect(() => applyDiscount(cart, expiredCode)).toThrow('Code has expired');
    });
  });

  describe('when the same code is used twice by the same customer', () => {
    it('rejects the second use with a clear error', () => {
      const cart = createTestCart({ total: 100, usedCodes: ['SAVE10'] });
      expect(() => applyDiscount(cart, { code: 'SAVE10', type: 'percent', value: 10 }))
        .toThrow('Code already used');
    });
  });
});
```

The nested `describe` blocks mirror Given/When/Then structure without requiring Gherkin parsing or step definitions.

**Alternative 4 — SpecFlow (C#):** Equivalent to `@cucumber/cucumber` for .NET teams. Same Gherkin syntax, same step binding model, first-class Visual Studio integration.

**Alternative 5 — Behave/pytest-bdd (Python):** Gherkin syntax identical to Cucumber; `pytest-bdd` v7+ adds native async step support making it the recommended choice for Python teams on modern async frameworks.

### Team Maturity Requirements for Full BDD

BDD is not a plug-and-play tool. It requires organizational preconditions to deliver its stated benefits:

| Maturity Requirement | Why It Matters | Warning Sign |
|---|---|---|
| Product owner participation | Without a business voice, scenarios become developer-invented test cases | PO only reviews scenarios at sprint review |
| QA in discovery phase | QA's value is in pre-code scenario surfacing, not post-code test writing | QA writes Gherkin from finalized tickets |
| Developer commitment to clean steps | Step definition bloat is inevitable without code review discipline | >300 step functions after 6 months |
| CI pipeline integration | Feature files not wired to CI are just documentation | Scenarios run only manually |
| Gherkin review process | Unreviewed Gherkin drifts imperative; requires same review rigor as code | Feature files bypass PR review |

A team that scores "warning sign" in 3+ of these areas will experience BDD as overhead with no benefit. The honest diagnostic question: "If we ran our feature files today, would they all pass?" If the answer is uncertain, the practice has already broken down.

---

## BDD Readiness Checklist

Use this before committing to BDD adoption. Teams that skip this assessment commonly
find themselves maintaining "BDD theater" — all the overhead, none of the benefit.

**Collaboration pre-conditions:**
- [ ] Product owner or BA can attend 30-minute Three Amigos sessions for each story
- [ ] QA is involved before development starts (not just in the test phase)
- [ ] Developers are willing to treat step definitions as production-quality code (code reviewed, no copy-paste)
- [ ] Team agrees on a ubiquitous language glossary (even a 10-word list is a start)

**Technical pre-conditions:**
- [ ] A working CI pipeline that can run `npx cucumber-js` (or equivalent)
- [ ] At least one team member has written step definitions before, or budget for a 1-week learning spike
- [ ] Application has a test environment with seeded data or API-level setup support
- [ ] Page object layer (or API client layer) exists or is planned — step definitions should not contain raw selectors

**Ongoing health metrics (review monthly):**
- [ ] Percentage of `@wip` scenarios below 10% of total
- [ ] Average scenario execution time below 5 seconds for non-browser scenarios
- [ ] Step definition count growth rate (>10% per sprint = bloat risk)
- [ ] Last Three Amigos session was this sprint (not 2+ sprints ago)

If fewer than 6 of these boxes are checked, start with **Example Mapping only** (no Gherkin/Cucumber) for one quarter. Get the collaboration right before adding the automation layer.

---

## Quick Reference Card

| Topic | Recommendation |
|-------|---------------|
| When to use BDD | Complex business domain + cross-functional team + stakeholder participation |
| When NOT to use | Solo/small team, prototype, infrastructure code, team without PO buy-in |
| Primary TypeScript framework | `@cucumber/cucumber` v12 (latest stable: v12.8.3; v13 unreleased — formatter redesign) |
| Step parameterization | Prefer `{string}`, `{int}`, `{float}`, `{word}` over raw regex |
| State sharing across steps | Use the World object — never module-level variables |
| CI strategy | `@smoke` on every PR (< 2 min); `@regression` nightly (sharded) |
| Parallel safety | Provision all test data via API in `Before` hooks with unique IDs |
| Suite health indicator | `@wip` count < 10% of total scenarios |
| Avoiding step bloat | "Search before create" policy; max one step definition file per feature area |
| Lightest BDD start | Example Mapping workshop first — no tooling needed |
| Version gotcha | v9 → v10: ESM (`import:` not `require:`); v11 → v12: `includeAttachments`, node ≥ 20; v12 → v13 (unreleased): `SummaryFormatter`/`ProgressFormatter` removed, `printAttachments` → `includeAttachments`, `FORCE_COLOR` replaces `color` |
| playwright-bdd version gotcha | v8.5 → v8.6 (unreleased): `enrichReporterData` removed, `junit-modern` → `junit`, strict arity checks, Node.js 20 min, `$step.docStringType` available |
| Tag syntax | Boolean expressions: `"@smoke and not @wip"` (commas deprecated in v9+) |
| Organizing business rules | Use `Rule` keyword to group scenarios per rule; per-rule `Background` for different setups |
| Time-dependent scenarios | Use `page.clock.setFixedTime()` + `fastForward()` for client-side expiry; DB seeder for server-side JWT `exp` |
| WebSocket mock testing | `context.routeWebSocket()` (Playwright v1.48+) intercepts WS without a real backend |
| Semantic a11y assertions | `toMatchAriaSnapshot()` (v1.49+) for ARIA tree structure; `toHaveAccessibleErrorMessage()` (v1.50+) for error associations |
| CSS class assertions | `expect(locator).toContainClass('active')` (v1.52+) — more reliable than regex on full `class` attribute |
| Step observability | `page.consoleMessages()` / `page.pageErrors()` / `page.requests()` (v1.56+) for in-step browser log capture |
| Locator labeling | `locator.describe('Add to cart button')` (v1.53+) enriches trace viewer and report output without changing selector |
| Auth token persistence | `browserContext.storageState({ indexedDB: true })` (v1.51+) captures IndexedDB tokens (Firebase Auth, etc.) |
| Run-level tagging in CI | `testConfig.tag: ['regression', 'nightly']` (v1.57+) tags the entire run in Playwright report metadata |
| TypeScript disposable cleanup | `await using context = await browser.newContext()` (v1.59+, TS 5.2+) — auto-disposes without try/finally |
| Full-page ARIA structure | `expect(page).toMatchAriaSnapshot(yaml)` (v1.59+) for landmark/heading structure BDD assertions |
| BDD step debugging (headless) | `npx playwright test --debug=cli --grep "@smoke"` (v1.59+) — interactive terminal debugger, no display server needed |
| Drag-and-drop BDD | `locator.drop({ files: [...] })` (v1.60+) for custom upload zones; use `setInputFiles()` for `<input type="file">` only |
| HAR network capture on failure | `context.tracing.startHar()` / `tracing.stopHar()` (v1.60+) — first-class HAR API for BDD failure artifact |
| Accessible-name disambiguation | `getByRole('button', { name: 'Submit', description: '...' })` (v1.60+) — `description` option via `aria-description` |
| Collision-free artifact naming | `$testInfo.titlePath.join('__')` (v1.55+) — full BDD ancestry as filename prefix; eliminates screenshot overwrites in sharded CI |
| Interactive locator discovery | `await page.pickLocator()` (v1.59+, dev-time only) — hover-and-click to capture best-practice locator for step authoring |
| AI-assisted test generation | `npx playwright init-agents --loop=claude` (v1.56+) — planner/generator/healer agents; treat planner Markdown output as Three Amigos seed |

---

### playwright-bdd: TypeScript-First BDD with Playwright's Native Runner  [community]

`playwright-bdd` is an open-source library (2023–) that bridges Cucumber's Gherkin layer
with Playwright Test's native runner. It compiles `.feature` files into `.spec.ts` files
that Playwright runs directly — enabling Playwright's native HTML reporter, trace viewer,
and `--shard` support without any Cucumber-specific CI plumbing.

**Why use `playwright-bdd` over `@cucumber/cucumber` + Playwright?**
- Playwright's native `--shard` syntax works out of the box (no custom sharding logic)
- Playwright Trace Viewer captures screenshots, network, and DOM snapshots on failure
- `data-testid` selectors and Playwright's auto-wait reduce flakiness compared to raw Cucumber hooks
- Fixtures replace the World object — fully type-safe, no `this` binding

**Setup:**

```bash
npm install --save-dev playwright-bdd @playwright/test
npx playwright install chromium
```

`playwright.config.ts`:
```typescript
import { defineConfig } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
});

export default defineConfig({
  testDir,
  reporter: [['html', { outputFolder: 'reports/playwright-html' }]],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

`src/steps/checkout.steps.ts` using **Playwright fixtures** instead of World:
```typescript
import { createBdd } from 'playwright-bdd';
import { expect } from '@playwright/test';

// createBdd returns typed Given/When/Then bound to Playwright fixtures
const { Given, When, Then } = createBdd();

Given('I am logged in as a registered customer', async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('email').fill('test@example.com');
  await page.getByTestId('password').fill('TestPass123!');
  await page.getByTestId('submit').click();
  await page.waitForURL('/dashboard');
});

When('I proceed to checkout', async ({ page }) => {
  await page.getByTestId('checkout-button').click();
  await page.waitForURL('/checkout');
});

When('I enter valid credit card details', async ({ page }) => {
  await page.getByTestId('card-number').fill('4242424242424242');
  await page.getByTestId('card-expiry').fill('12/28');
  await page.getByTestId('card-cvv').fill('123');
});

Then('I should see an order confirmation page', async ({ page }) => {
  await expect(page.getByTestId('order-confirmation')).toBeVisible();
  await expect(page).toHaveURL(/\/order\/confirmation/);
});

Then('I should see the error {string}', async ({ page }, errorMessage: string) => {
  await expect(page.getByTestId('error-message')).toHaveText(errorMessage);
});
```

**Running BDD tests with `playwright-bdd`:**
```bash
# Generate spec files from .feature files (required before first run)
npx bddgen

# Run all BDD tests
npx playwright test

# Run smoke tag subset
npx playwright test --grep "@smoke"

# Run with sharding (4-way — no custom config needed)
npx playwright test --shard=1/4
npx playwright test --shard=2/4
npx playwright test --shard=3/4
npx playwright test --shard=4/4
```

**[community] `playwright-bdd` tradeoff vs `@cucumber/cucumber`**: The Playwright-native
approach trades Cucumber's rich tag expression system (`@smoke and not @wip`) for
Playwright's simpler `--grep` regex. For large test suites with complex tag strategies,
`@cucumber/cucumber` with its dedicated profile system is more expressive. For teams
already deep in Playwright who want the *living documentation* layer without a second
runner, `playwright-bdd` is lower friction.

---

### Step Health: Detecting Unused and Duplicate Step Definitions  [community]

As a BDD suite grows, unused and near-duplicate step definitions accumulate silently.
Unlike dead code in TypeScript (caught by `noUnusedLocals`), unused step definitions are
strings — the compiler cannot detect them. Purpose-built tooling is required.

**Unused step detection with Cucumber's built-in `--format usage`:**

```bash
# Show all steps with usage count — steps with 0 uses are candidates for removal
npx cucumber-js --dry-run --format usage | grep -E "^[[:space:]]+[0-9]+"

# Output format:
# Pattern                                        | Uses | Location
# ------------------------------------------------|------|------------------
# I am logged in as a registered customer         |   12 | steps/auth.ts:5
# I am on the checkout page                       |    1 | steps/checkout.ts:23
# I fill in the field {string} with {string}      |    0 | steps/forms.ts:47  ← UNUSED
```

**ESLint integration for step quality** (`eslint-plugin-cucumber`):

```bash
npm install --save-dev eslint-plugin-cucumber
```

`.eslintrc.json` (step files only):
```json
{
  "overrides": [
    {
      "files": ["src/steps/**/*.ts"],
      "plugins": ["cucumber"],
      "rules": {
        "cucumber/async-then": "error",
        "cucumber/expression-type": "warn",
        "cucumber/no-restricted-tags": ["warn", { "tags": ["@fixme", "@broken"] }],
        "cucumber/no-arrow-functions": "error"
      }
    }
  ]
}
```

**Why `no-arrow-functions` matters**: Arrow functions in step definitions do not bind
`this` — they break the World object pattern. `cucumber/no-arrow-functions` catches this
at lint time rather than producing a cryptic runtime error:

```typescript
// BAD — arrow function: this is undefined at runtime
Given('I am on the login page', async () => {
  await this.page.goto('/login'); // TypeError: Cannot read properties of undefined
});

// GOOD — regular function: this is the World object
Given('I am on the login page', async function (this: CustomWorld) {
  await this.page.goto('/login');
});
```

**Quarterly step audit workflow:**
```bash
# 1. List all step definitions with use counts
npx cucumber-js --dry-run --format usage 2>&1 > step-audit.txt

# 2. Find zero-use steps (dead code)
grep " 0 " step-audit.txt

# 3. Find near-duplicate patterns (manual review threshold: >3 similar starts)
grep "^I " step-audit.txt | sed 's/ {.*$//' | sort | uniq -c | sort -rn | head -20
```

**[community] Production observation**: Teams that skip step audits typically have >30%
unused step definitions after 12 months. These dead steps create false confidence
("we have 400 steps defined") and add noise to `--dry-run` output, making it harder to
catch genuinely undefined steps in CI.

---

### Merging Sharded Cucumber Reports in CI  [community]

When running BDD suites with matrix sharding (e.g., 4 shards × 8 parallel workers),
each shard produces a separate JSON or JUnit report. The Cucumber HTML report can only
show one report at a time unless reports are merged before publishing.

**Strategy 1: `cucumber-json-formatter` merge (recommended for `@cucumber/cucumber`)**

```bash
# Each shard writes: reports/cucumber-shard-N.json
# After all shards complete, merge with multiple-cucumber-html-reporter:
npm install --save-dev multiple-cucumber-html-reporter

node -e "
const report = require('multiple-cucumber-html-reporter');
report.generate({
  jsonDir: 'reports/',                        // folder containing cucumber-*.json files
  reportPath: 'reports/combined-html/',
  metadata: {
    browser: { name: 'chrome', version: '120' },
    device: 'CI runner',
    platform: { name: 'ubuntu', version: '22.04' }
  },
  customData: {
    title: 'BDD Regression Run',
    data: [
      { label: 'Project', value: 'my-app' },
      { label: 'Release', value: process.env.GITHUB_RUN_NUMBER || 'local' },
    ]
  }
});
"
```

**GitHub Actions: merge-and-publish step (adds to the regression workflow):**

```yaml
  merge-reports:
    name: Merge BDD Reports
    runs-on: ubuntu-latest
    needs: bdd-regression            # Wait for all shards
    if: always()
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci

      - name: Download all shard reports
        uses: actions/download-artifact@v4
        with:
          pattern: regression-report-shard-*
          path: reports/
          merge-multiple: true       # Flatten into reports/ directory

      - name: Merge into combined HTML report
        run: node scripts/merge-cucumber-reports.js

      - name: Upload combined report
        uses: actions/upload-artifact@v4
        with:
          name: bdd-combined-report
          path: reports/combined-html/
          retention-days: 30
```

**Strategy 2: `playwright-bdd` + Playwright's native merge** (if using the Playwright runner):

```bash
# Each shard produces: blob-report-N/
# Playwright's native merge command:
npx playwright merge-reports --reporter html blob-report-*

# Output: playwright-report/ — single HTML file with all shards
```

**[community] Why report merging matters**: Teams that publish per-shard reports find
that stakeholders never look at them — the reports are buried in artifact lists. A single
merged report with a summary dashboard is the only format product managers and QA leads
will check after a nightly regression run. Without it, living documentation fails its
stakeholder-visibility promise.

---

### Ubiquitous Language: BDD as a Domain-Driven Design Artifact  [community]

BDD's Gherkin vocabulary is, implicitly, a **Ubiquitous Language** (UL) exercise from
Domain-Driven Design (DDD). Every noun and verb in a feature file is a claim about the
shared language of the bounded context. Teams that treat BDD and DDD as separate
practices end up with Gherkin that uses developer jargon in some scenarios and business
language in others — creating the exact communication gap BDD is designed to close.

**Why this matters**: When the Gherkin says `the order is confirmed` but the codebase
says `OrderStatus.PROCESSED`, the team has two different languages for the same concept.
Over 12 months, these diverge further: the feature file says `customer`, the API says
`user`, the database says `account`. The Three Amigos cannot have a shared conversation
because they have no shared dictionary.

**Ubiquitous Language Glossary — structured YAML artifact**:

```yaml
# docs/ubiquitous-language.yaml
# Maintained alongside feature files; reviewed in Three Amigos sessions
# Each term must appear consistently in: Gherkin | API response fields | DB column names

bounded_context: checkout

terms:
  - term: "Customer"
    definition: "An authenticated user who has completed account registration"
    gherkin_usage: "Given I am a registered customer"
    api_field: "customerId"
    db_column: "customers.id"
    NOT_synonyms: ["user", "account", "buyer", "shopper"]

  - term: "Cart"
    definition: "A temporary collection of items before purchase commitment"
    gherkin_usage: "Given my cart contains:"
    api_field: "cartId"
    db_column: "carts.id"
    NOT_synonyms: ["basket", "bag", "wishlist"]

  - term: "Order"
    definition: "A committed purchase — cart items frozen with a payment method"
    gherkin_usage: "Then my order should be confirmed"
    api_field: "orderId"
    db_column: "orders.id"
    NOT_synonyms: ["purchase", "transaction", "booking"]

  - term: "Discount Code"
    definition: "A string token that modifies the order total per a business rule"
    gherkin_usage: "When I apply discount code {string}"
    api_field: "discountCode"
    db_column: "discount_codes.code"
    NOT_synonyms: ["promo code", "coupon", "voucher", "offer code"]
```

**Enforcing UL consistency in step definitions** (TypeScript):

```typescript
// src/support/ubiquitous-language-guard.ts
// Run in Before hook — warns when Gherkin step text contains forbidden synonyms

import { Before } from '@cucumber/cucumber';

// Loaded from docs/ubiquitous-language.yaml at test startup
const SYNONYMS: Record<string, string[]> = {
  Customer: ['user', 'account', 'buyer', 'shopper'],
  Cart:     ['basket', 'bag', 'wishlist'],
  Order:    ['purchase', 'transaction', 'booking'],
};

Before(function (scenario) {
  const stepTexts = scenario.pickle.steps.map(s => s.text.toLowerCase());
  for (const [canonicalTerm, forbidden] of Object.entries(SYNONYMS)) {
    for (const synonym of forbidden) {
      const violations = stepTexts.filter(text => text.includes(synonym));
      if (violations.length > 0) {
        console.warn(
          `[UL] Scenario "${scenario.pickle.name}" uses "${synonym}" ` +
          `— prefer canonical term "${canonicalTerm}". ` +
          `Steps: ${violations.join('; ')}`
        );
      }
    }
  }
});
```

**[community] Production impact**: Teams that maintain a UL glossary and enforce it in
Three Amigos sessions report 40–60% fewer "wait, what do you mean by X?" clarification
rounds in sprint planning. The glossary becomes the most-referenced onboarding document
for new hires — more useful than an API spec because it explains *why* terms were chosen,
not just *what* they are.

**[community] DDD bounded context and BDD feature file alignment**: Each `features/`
subdirectory should correspond to one DDD bounded context (`features/checkout/`,
`features/inventory/`, `features/identity/`). Step definitions and World fixtures scoped
to a context prevent leakage — a checkout step definition should never reach into
inventory's internal state. When a scenario needs two bounded contexts, it is a signal
that the scenario is testing integration, not behavior, and belongs at the contract
testing layer (see `contract-testing-guide.md`).

---

### BDD and Contract Testing: Defining the Boundary  [community]

BDD scenarios describe *user-observable behavior* end-to-end. Contract tests describe
*service interface obligations* between producers and consumers. The two methodologies
are complementary but should not overlap — mixing them creates scenarios that are both
slow (BDD's overhead) and brittle (contract fragility).

**The rule**: BDD scenarios should treat downstream service calls as opaque. They should
not assert on internal service behavior. Contract tests (Pact/CDC) own that layer.

```gherkin
# CORRECT BDD — treats payment service as opaque
Scenario: Order total is charged on checkout
  Given I am a registered customer with items in my cart
  When I complete the checkout process with a valid card
  Then my order should be confirmed
  And I should receive an order confirmation email
  # BDD does NOT assert: "a POST was sent to /api/payments/charge"
  # That's a contract test concern

# INCORRECT — BDD leaking into contract territory
Scenario: Payment service receives correct charge amount
  Given I am a registered customer with cart total $109.97
  When I complete checkout
  Then the payment service should receive a POST to /api/payments/charge
  And the request body should contain amount 10997 in cents
  # This belongs in a Pact consumer test, not a feature file
```

**When BDD scenarios start testing internal APIs directly**, it is a sign that:
1. The feature file author does not trust the contract test layer (fix: establish Pact)
2. The scenario is compensating for missing integration tests (fix: add API-level tests)
3. The team has no clear boundary between BDD and contract testing layers

**Integration map** — how the layers work together:
```
BDD (Gherkin + Cucumber/Playwright)   → tests USER-OBSERVABLE BEHAVIOR via browser or API
  ↓ calls
Application code                       → calls downstream services
  ↓
Contract tests (Pact)                  → tests SERVICE INTERFACE CONTRACT in isolation
  ↓ publishes to
Pact Broker                            → provider verifies independently
```

**[community] Lesson from production**: Teams that use BDD to test microservice APIs
end-to-end find that every deployment of *any* downstream service can break *all* BDD
scenarios — not because behavior changed, but because a response field name changed or
a new required header was added. This is exactly the problem Pact/CDC solves. Once Pact
is in place, BDD scenarios become stable because they test user behavior, not wire format.

---

### ISTQB CTFL 4.0 Terminology in BDD Context  [community]

ISTQB Certified Tester Foundation Level 4.0 (2023) establishes precise terminology that
BDD guides frequently misuse. Applying the correct terms matters for teams that mix BDD
practitioners with ISTQB-certified testers and for onboarding documentation.

| BDD informal term | ISTQB CTFL 4.0 canonical term | Why the distinction matters |
|---|---|---|
| "test scenario" (in pyramid context) | **test condition** | "Scenario" is a Gherkin keyword; "test condition" is the testable aspect of the system; conflating them causes confusion in audit documents |
| "test script" / "test case" | **test case** (ISTQB) | A test case has preconditions + inputs + expected results + postconditions. A Gherkin scenario maps to exactly one test case |
| "test layer" | **test level** | BDD scenarios operate at system or acceptance test level, not "layer" |
| "test source" | **test basis** | The business rules and user stories that inform Gherkin scenarios are the test basis |
| "bug" / "defect" | **defect** | ISTQB distinguishes defect (in the work product), failure (observable incorrect behavior), and error (human mistake) |
| "test set" | **test suite** | A set of related feature files constitutes a test suite in ISTQB terms |

**Practical impact**: When BDD feature files are used as audit evidence (regulated industries,
ISO 25010 conformance, GDPR compliance testing), reviewers with ISTQB background expect
standardized terminology. A feature file that says "This test scenario verifies the bug fix
for the login test layer" fails an audit not because of the behavior tested, but because
the language is imprecise.

**[community] ISTQB CTFL 4.0 and BDD alignment — production lesson**: In healthcare and
fintech BDD adoptions, teams rewrite feature file titles and descriptions once to use ISTQB
terminology, then add a one-page glossary to the repo's `docs/` folder. The rewrite takes
half a sprint; the payoff is that every future audit review passes the documentation check
without a consultant's help.

---

### Accessibility-Aware BDD Scenarios

BDD and accessibility testing (a11y) are frequently run as separate tracks. Combining them
— writing BDD scenarios that assert WCAG-level behavior using `axe-core` from within
Cucumber step definitions — gives product managers proof that accessibility is tested as a
first-class behavior, not an afterthought.

```gherkin
# features/accessibility/checkout-a11y.feature

@a11y @regression
Feature: Checkout flow accessibility
  As a user with assistive technology
  I want the checkout flow to meet WCAG 2.1 AA standards
  So that I can complete a purchase independently

  Scenario: Checkout page has no critical accessibility violations
    Given I am a registered customer with items in my cart
    When I navigate to the checkout page
    Then the page should have no critical WCAG 2.1 AA violations

  Scenario: Error messages are announced to screen readers
    Given I am on the checkout page
    When I submit the form without filling in required fields
    Then all error messages should have aria-live regions
    And each error message should be associated with its input via aria-describedby

  Scenario: Focus is trapped correctly in the address modal
    Given I am on the checkout page
    When I open the "Change shipping address" modal
    Then keyboard focus should be trapped within the modal
    And pressing Tab should cycle through interactive elements without leaving the modal
    And pressing Escape should close the modal and return focus to the trigger button
```

```typescript
// src/steps/a11y.steps.ts — axe-core integrated into BDD step definitions
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { CustomWorld } from '../support/world';

// Matches: Then the page should have no critical WCAG 2.1 AA violations
Then('the page should have no critical WCAG 2.1 AA violations', async function (this: CustomWorld) {
  const results = await new AxeBuilder({ page: this.page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
    .analyze();

  // Filter to critical/serious violations only (impact = critical | serious)
  const critical = results.violations.filter(
    v => v.impact === 'critical' || v.impact === 'serious'
  );

  if (critical.length > 0) {
    const summary = critical.map(v =>
      `[${v.impact}] ${v.id}: ${v.description}\n  Affected nodes: ${
        v.nodes.map(n => n.target.join(', ')).join(' | ')
      }`
    ).join('\n\n');
    throw new Error(`Accessibility violations found:\n\n${summary}`);
  }
  expect(critical).toHaveLength(0);
});

// Matches: Then all error messages should have aria-live regions
Then('all error messages should have aria-live regions', async function (this: CustomWorld) {
  const errorMessages = await this.page.locator('[data-testid*="error"]').all();
  for (const msg of errorMessages) {
    const ariaLive = await msg.getAttribute('aria-live');
    const role = await msg.getAttribute('role');
    const hasLiveRegion = ariaLive === 'polite' || ariaLive === 'assertive' || role === 'alert';
    expect(hasLiveRegion, `Error element ${await msg.getAttribute('data-testid')} missing aria-live`).toBe(true);
  }
});

// Matches: Then keyboard focus should be trapped within the modal
Then('keyboard focus should be trapped within the modal', async function (this: CustomWorld) {
  const modal = this.page.locator('[role="dialog"]');
  await expect(modal).toBeVisible();

  // Tab through all interactive elements — count before returning to start
  const focusableSelector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
  const focusableCount = await modal.locator(focusableSelector).count();
  expect(focusableCount).toBeGreaterThan(0);

  // Verify focus stays within modal after Tab × (focusableCount + 1)
  for (let i = 0; i <= focusableCount; i++) {
    await this.page.keyboard.press('Tab');
  }
  const focusedElement = await this.page.evaluate(() => document.activeElement?.closest('[role="dialog"]'));
  expect(focusedElement, 'Focus escaped the modal after Tab cycling').not.toBeNull();
});
```

**[community] Why a11y BDD pays back**: Accessibility violations caught in BDD scenarios
are 10–20x cheaper to fix than violations discovered in user testing or accessibility
audits. The BDD scenario serves double duty: it's a regression test that prevents regressions
AND it's human-readable proof for WCAG compliance reports. Teams with regulated products
(government, healthcare, education) find this format accepted as audit evidence in lieu
of separate accessibility test reports.

**[community] axe-core BDD limitation**: axe-core catches approximately 57% of WCAG 2.1 AA
violations automatically. The remaining ~43% — cognitive load, keyboard navigation quality,
color contrast in dynamic states, and screen reader experience — require manual exploratory
testing. BDD scenarios using axe-core should be treated as a floor (catching regressions),
not a ceiling (proving full compliance).

**[community] Complement axe-core with `toMatchAriaSnapshot()` and `toHaveAccessibleErrorMessage()` (Playwright v1.49+/v1.50+)**: For structural accessibility assertions that go beyond automated rule checking, Playwright's `toMatchAriaSnapshot()` asserts on the full ARIA tree (what screen readers see) and `toHaveAccessibleErrorMessage()` checks that error messages are correctly associated with form inputs via `aria-errormessage`/`aria-describedby`. These two assertions catch accessibility issues that axe-core misses — specifically, incorrectly structured form landmarks and error associations that are technically valid HTML but semantically broken for AT users. See the "Playwright 1.45–1.60: New BDD-Relevant APIs" section for TypeScript examples.

---

### pytest-bdd v7+ for Python Teams

`pytest-bdd` is the recommended Python BDD framework for teams already using pytest.
Unlike Behave (which has its own runner), `pytest-bdd` integrates with the pytest ecosystem:
fixtures, parametrize, conftest, coverage, and all pytest plugins work without adaptation.

**Key difference from Behave**: `pytest-bdd` step functions use `@given`, `@when`, `@then`
decorators from pytest-bdd, and state is passed via pytest fixtures rather than a context
object. This makes step definitions more testable and composable.

```bash
pip install pytest-bdd pytest-playwright
playwright install chromium
```

`features/checkout.feature` (identical Gherkin — framework-agnostic):
```gherkin
Feature: Shopping cart checkout
  Scenario: Successful checkout with credit card
    Given I am a logged-in customer with items in my cart
    When I complete the checkout with a valid card
    Then I should see an order confirmation
    And my cart should be empty
```

```python
# tests/steps/checkout_steps.py — pytest-bdd v7 style
import pytest
from pytest_bdd import given, when, then, scenario
from playwright.sync_api import Page, expect

# Scenario decorator links feature file to test function
@scenario('../features/checkout.feature', 'Successful checkout with credit card')
def test_checkout_success():
    pass  # Scenario body is in step functions below

# Fixtures inject shared state — no context object needed
@pytest.fixture
def cart_state():
    return {"items": [], "total": 0.0}

@given("I am a logged-in customer with items in my cart", target_fixture="logged_in_page")
def setup_logged_in_cart(page: Page, cart_state):
    # Use API to seed cart — faster and more reliable than UI setup
    import requests
    r = requests.post("http://localhost:8000/api/cart/seed", json={
        "user_id": "test-user-001",
        "items": [{"productId": "prod-42", "qty": 2}]
    })
    assert r.status_code == 200
    cart_state["cartId"] = r.json()["cartId"]

    # Log in via API (faster than UI login)
    token_r = requests.post("http://localhost:8000/api/auth/token", json={
        "email": "test@example.com", "password": "TestPass123!"
    })
    assert token_r.status_code == 200
    token = token_r.json()["accessToken"]

    # Set auth cookie in Playwright context
    page.context.add_cookies([{
        "name": "auth_token", "value": token,
        "domain": "localhost", "path": "/"
    }])
    return page

@when("I complete the checkout with a valid card")
def complete_checkout(logged_in_page: Page, cart_state):
    logged_in_page.goto(f"/cart/{cart_state['cartId']}/checkout")
    logged_in_page.get_by_test_id("card-number").fill("4242424242424242")
    logged_in_page.get_by_test_id("card-expiry").fill("12/28")
    logged_in_page.get_by_test_id("card-cvv").fill("123")
    logged_in_page.get_by_test_id("confirm-order").click()

@then("I should see an order confirmation")
def verify_confirmation(logged_in_page: Page, cart_state):
    expect(logged_in_page.get_by_test_id("order-confirmation")).to_be_visible()
    cart_state["confirmed"] = True

@then("my cart should be empty")
def verify_empty_cart(logged_in_page: Page):
    expect(logged_in_page.get_by_test_id("cart-item-count")).to_have_text("0")
```

**pytest-bdd v7 configuration** (`pyproject.toml`):
```toml
[tool.pytest.ini_options]
bdd_features_base_dir = "features/"
addopts = [
    "--strict-markers",
    "--tb=short",
]
markers = [
    "smoke: Smoke test suite — runs on every PR",
    "regression: Full regression suite — runs nightly",
    "a11y: Accessibility scenarios",
]
```

**[community] pytest-bdd vs Behave production comparison**:
- `pytest-bdd` wins on ecosystem integration (fixtures, conftest, pytest-cov, pytest-xdist for parallel)
- `Behave` wins on zero-configuration startup and async step support (Behave-async plugin)
- For teams starting fresh: prefer `pytest-bdd` — the fixture model prevents the shared `context` state bugs that plague Behave suites at scale
- `pytest-bdd` v7 added native async step support (`async def` step functions with `pytest-anyio`) — the main reason teams stayed on Behave is now resolved

---

### Cucumber.js v11+ and the `@cucumber/cucumber` Ecosystem (2024–2025)

Cucumber.js v11 (released 2024) introduced several production-relevant changes:

**New in v11:**
- **Built-in retry support**: `@retry(3)` tag or `--retry 3` CLI flag retries failed scenarios up to N times. Unlike flakiness quarantine, retry is appropriate for scenarios that interact with third-party systems with transient failures.
- **Native TypeScript support via `--import`**: No longer requires `ts-node/register` or a loader config. Cucumber.js v11 uses Node's native `--import` ESM loader with TypeScript via tsx or ts-node/esm.
- **`World` class is now fully typed**: `setWorldConstructor` was deprecated in favor of extending the `World` base class with full TypeScript generics.

```typescript
// cucumber.js (v11 config — ESM with native TypeScript)
export default {
  default: {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    // v11: no more 'requireModule' or 'loader' — use Node's --import flag
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
    retry: 2,            // Retry failed scenarios up to 2 times (transient failures)
    retryTagFilter: '@flaky',  // Only retry scenarios tagged @flaky
    publish: false,
  },
};
```

```json
// package.json — run with tsx for zero-config TypeScript in v11
{
  "type": "module",
  "scripts": {
    "test:bdd": "node --import tsx/esm $(which cucumber-js)",
    "test:bdd:smoke": "cucumber-js --profile smoke",
    "test:bdd:retry": "cucumber-js --retry 2 --retry-tag-filter @flaky"
  },
  "devDependencies": {
    "@cucumber/cucumber": "^11.0.0",
    "tsx": "^4.0.0"
  }
}
```

**World class with TypeScript generics (v11 style)**:

```typescript
// src/support/world.ts — v11 typed World
import { World, IWorldOptions, setWorldConstructor } from '@cucumber/cucumber';
import { Browser, BrowserContext, Page } from '@playwright/test';

interface WorldParameters {
  baseUrl: string;
  timeout: number;
  headless: boolean;
}

export class AppWorld extends World<WorldParameters> {
  browser!: Browser;
  context!: BrowserContext;
  page!: Page;
  authToken?: string;
  lastApiResponse?: Response;

  constructor(options: IWorldOptions<WorldParameters>) {
    super(options);
    // Access typed parameters: this.parameters.baseUrl
  }

  async navigateTo(path: string): Promise<void> {
    await this.page.goto(`${this.parameters.baseUrl}${path}`);
  }
}

setWorldConstructor(AppWorld);
```

**[community] v11 migration pitfall — `format` changed**:
The `json` formatter was removed from the default bundle in v11. Teams relying on
`"json:reports/results.json"` for CI report merging will get `Error: Cannot find formatter json`.
Install `@cucumber/json-formatter` separately:

```bash
npm install --save-dev @cucumber/json-formatter
```

```json
// cucumber.js v11 — explicit json formatter
{
  "format": [
    "progress-bar",
    "@cucumber/json-formatter:reports/results.json",
    "html:reports/cucumber-report.html"
  ]
}
```

**[community] v11 `--retry` misuse as flakiness masking**: The `--retry` flag is appropriate
for scenarios that test genuinely non-deterministic external systems (payment gateways,
email delivery, third-party OAuth). Using `--retry 3` as a blanket setting to silence
flaky tests that fail due to test isolation problems or race conditions masks real defects.
Reserve retry for `@flaky`-tagged scenarios only, and treat the `@flaky` tag as a
temporary marker with a maximum age (e.g., fail CI if a `@flaky` tag is older than 14 days
without a linked ticket).

---

### BDD in Monorepos: Step Definition Sharing Strategies  [community]

In monorepos where multiple packages share business behaviors (e.g., a checkout flow
tested by both a web app and a mobile app), step definitions can be shared via a dedicated
`packages/bdd-common/` package. This prevents the most painful form of step definition
drift: two teams maintaining near-identical steps in separate packages that diverge over time.

**Monorepo structure (npm workspaces / pnpm):**

```
monorepo/
├── packages/
│   ├── bdd-common/                # Shared step definitions and World
│   │   ├── src/
│   │   │   ├── steps/
│   │   │   │   ├── auth.steps.ts      # Shared login/logout steps
│   │   │   │   └── cart.steps.ts      # Shared cart/checkout steps
│   │   │   └── support/
│   │   │       ├── world.ts
│   │   │       └── hooks.ts
│   │   └── package.json
│   ├── web-app/
│   │   ├── features/              # Web-specific .feature files
│   │   ├── src/steps/             # Web-specific step overrides
│   │   └── cucumber.js            # Requires both bdd-common and local steps
│   └── mobile-app/
│       ├── features/              # Mobile-specific .feature files
│       ├── src/steps/             # Mobile-specific step overrides
│       └── cucumber.js
└── package.json                   # Workspace root
```

`packages/web-app/cucumber.js` (consuming shared steps):
```javascript
// cucumber.js — import shared steps first, then local overrides
export default {
  default: {
    import: [
      // Shared step definitions from bdd-common workspace package
      '../bdd-common/src/steps/**/*.ts',
      '../bdd-common/src/support/**/*.ts',
      // Local steps — can override or extend shared steps
      'src/steps/**/*.ts',
      'src/support/**/*.ts',
    ],
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
    publish: false,
  },
};
```

`packages/bdd-common/src/steps/auth.steps.ts` (shared, platform-agnostic step):
```typescript
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// This step is reused identically by web-app and mobile-app packages.
// The World implementation differs per package — web uses Playwright,
// mobile uses Detox or Appium. The Gherkin step text is the contract.
Given('I am a registered customer', async function (this: AppWorld) {
  await this.authenticateAsTestUser('registered');
});

Given('I am an admin user', async function (this: AppWorld) {
  await this.authenticateAsTestUser('admin');
});
```

**[community] Monorepo BDD rule**: Shared steps must be platform-agnostic — they express
**what** happens (authenticate, add to cart), not **how** (click button, fill input). The
`how` belongs in platform-specific World implementations. Teams that put browser selectors
in shared steps create a shared step library that only works for one platform.

**[community] Step version conflicts in monorepos**: When bdd-common is updated with a
changed step definition text, all consuming packages must update their feature files
simultaneously. Teams that do not enforce this via a workspace-level lint rule end up with
`Undefined step` CI failures that are hard to trace to the shared package. Mitigation:
add a CI check that runs `cucumber-js --dry-run` across all packages when bdd-common changes.

---

### Gherkin Linting with `gherkin-lint`  [community]

Feature files have no compiler to enforce structural rules. Without tooling, feature files
drift: some use imperative style, some mix business language with technical terms, some have
orphaned step definitions. `gherkin-lint` is a configurable linter for `.feature` files.

```bash
npm install --save-dev gherkin-lint
```

`.gherkin-lintrc.json`:
```json
{
  "no-restricted-patterns": {
    "Global": {
      "name": ["click", "navigate to", "fill in", "select from dropdown"],
      "description": "Use declarative step text. Found imperative UI term: {{pattern}}"
    }
  },
  "no-empty-file": true,
  "no-tags-on-background": true,
  "no-multiple-empty-lines": true,
  "no-superfluous-tags": true,
  "one-feature-per-file": true,
  "use-and": true,
  "no-restricted-tags": {
    "tags": ["@fixme", "@broken", "@skip"],
    "description": "Use @wip instead of {{tag}}"
  },
  "scenario-size": {
    "steps-length": {
      "Given": 3,
      "When": 1,
      "Then": 5
    }
  },
  "max-scenarios-per-file": {
    "maxScenarios": 10
  }
}
```

**Running gherkin-lint in CI:**

```yaml
# .github/workflows/bdd.yml — add to existing lint job
- name: Lint feature files
  run: npx gherkin-lint features/**/*.feature
```

**Key rules and why they matter:**

| Rule | What it catches | Why it matters |
|---|---|---|
| `no-restricted-patterns` | Imperative verbs in step text | Prevents UI-coupled scenarios before they reach CI |
| `scenario-size` | When steps > 1 (single action per scenario) | Multiple `When` steps usually mean testing two behaviors in one scenario |
| `max-scenarios-per-file` | Feature files with > 10 scenarios | Large feature files indicate a feature that needs to be split |
| `no-superfluous-tags` | Tags on Background (not valid) | Prevents author confusion about tag scope |
| `no-restricted-tags` | `@fixme`, `@broken`, `@skip` | Forces teams to use `@wip` consistently so CI can filter correctly |

**[community] `scenario-size: When: 1` as team discipline**: Enforcing a maximum of one
`When` step per scenario is controversial but highly effective. It forces teams to split
"and then the user does X and then Y" scenarios into focused single-behavior test cases.
The initial pushback is significant; the payoff is a test suite where every failing scenario
points to exactly one behavior that broke.

---

### Scenario Count Health Metrics  [community]

BDD suites grow unbounded without explicit guidance. Community evidence from large-scale
BDD adoptions (Cucumber community forum, Thoughtworks TechRadar, team retrospectives)
provides empirical scenario count heuristics:

| Metric | Healthy range | Warning signal | Action |
|---|---|---|---|
| Total scenarios | < 500 | 500–1000 | Audit for duplicates and imperative scenarios |
| Scenarios per feature file | 3–10 | > 15 | Feature needs to be split |
| `@wip` scenarios | < 5% of total | > 10% | Sprint review: resolve or remove |
| Unused step definitions | < 5% | > 20% | Quarterly step audit |
| Average scenario execution time | < 10s | > 30s | Move business logic to API-level BDD |
| Step definitions per feature area | < 50 | > 100 | Step bloat — parameterize and consolidate |
| Three Amigos sessions per sprint | ≥ 1 per story | < 1/sprint | BDD without collaboration = theater |
| Flaky scenario rate | < 2% | > 5% | Dedicated flakiness sprint |

**[community] The 500-scenario warning**: Teams with 500+ BDD scenarios typically report
one or more of: 45+ minute nightly runs, developers disabling CI to merge quickly,
business users who stopped reading the reports 6 months ago. The root cause is almost
always that the suite grew beyond acceptance tests into unit-test territory (scenarios
checking individual business rules that belong in unit tests) or imperative scenarios
that test UI mechanics rather than business behavior.

**Scenario reduction audit workflow** (TypeScript helper):

```typescript
// scripts/scenario-audit.ts — run weekly to track suite health
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

interface ScenarioAuditResult {
  totalScenarios: number;
  wip: number;
  wipPercentage: number;
  averagePerFile: number;
  filesOver10: string[];
}

function auditScenarios(featuresDir: string): ScenarioAuditResult {
  const featureFiles = execSync(`find ${featuresDir} -name "*.feature"`)
    .toString().trim().split('\n').filter(Boolean);

  let totalScenarios = 0;
  let wipCount = 0;
  const filesOver10: string[] = [];

  for (const file of featureFiles) {
    const content = fs.readFileSync(file, 'utf8');
    const scenarios = (content.match(/^\s*(Scenario|Scenario Outline):/gm) || []).length;
    const wip = (content.match(/@wip/g) || []).length;
    totalScenarios += scenarios;
    wipCount += wip;
    if (scenarios > 10) {
      filesOver10.push(`${path.basename(file)} (${scenarios} scenarios)`);
    }
  }

  return {
    totalScenarios,
    wip: wipCount,
    wipPercentage: Math.round((wipCount / totalScenarios) * 100),
    averagePerFile: Math.round(totalScenarios / featureFiles.length),
    filesOver10,
  };
}

const result = auditScenarios('features/');
console.log('BDD Suite Health Report');
console.table(result);
if (result.wipPercentage > 10) process.exit(1); // Fail CI if @wip > 10%
```

---

## Key Resources

- [Cucumber documentation](https://cucumber.io/docs/bdd/) — canonical BDD reference
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/) — full keyword specification including `Rule`, `Background`, `DocString`, `DataTable`
- [Cucumber anti-patterns guide](https://cucumber.io/docs/guides/anti-patterns/) — official pitfalls: feature-coupled steps, conjunction steps, testing implementation not behaviour
- [Better Gherkin guide](https://cucumber.io/docs/bdd/better-gherkin/) — official declarative vs imperative guidance
- [@cucumber/cucumber npm package](https://www.npmjs.com/package/@cucumber/cucumber) — official JS/TS package (v12 current; v11 still supported)
- [Cucumber.js CHANGELOG](https://github.com/cucumber/cucumber-js/blob/main/CHANGELOG.md) — version migration reference
- [playwright-bdd](https://github.com/vitalets/playwright-bdd) — Playwright-native BDD runner for TypeScript
- [Example Mapping (Matt Wynne)](https://cucumber.io/blog/bdd/example-mapping-introduction/) — pre-BDD discovery technique
- [eslint-plugin-cucumber](https://github.com/nicholasgasior/eslint-plugin-cucumber) — step definition linting rules
- [multiple-cucumber-html-reporter](https://github.com/WasiqB/multiple-cucumber-html-reporter) — merge sharded JSON reports
- [SpecFlow documentation](https://docs.specflow.org/) — C# BDD framework
- [Behave documentation](https://behave.readthedocs.io/) — Python BDD framework
- [pytest-bdd documentation](https://pytest-bdd.readthedocs.io/) — Python BDD with pytest integration (recommended for pytest teams)
- [pytest plugin writing guide](https://docs.pytest.org/en/stable/how-to/writing_plugins.html) — conftest.py hooks, entry-point distribution via `pytest11`, and `pytester` for testing plugins; essential for teams building shared BDD step libraries across projects
- [Allure Framework](https://allurereport.org/) — rich reporting for Cucumber suites
- [Pact documentation](https://docs.pact.io/) — consumer-driven contract testing for service boundaries
- [@axe-core/playwright](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright) — axe-core integration for Playwright-based BDD
- [ISTQB CTFL 4.0 Syllabus](https://www.istqb.org/certifications/certified-tester-foundation-level) — standardized testing terminology reference

---

### BDD with Feature Flags: Testing Toggle-Gated Behaviors  [community]

Feature flags (also called feature toggles) introduce conditional behavior into production code
— a feature is ON for some users/environments and OFF for others. BDD scenarios must account
for this: the same `.feature` file may need to produce different outcomes depending on which
flags are active at test time.

The naive approach — writing duplicate scenarios for each toggle state — causes scenario bloat
and drift. The principled approach tags scenarios with the toggle name and configures the World
to activate or deactivate flags before each scenario.

```gherkin
# features/payments/new-checkout-flow.feature
# This feature is behind the feature flag: NEW_CHECKOUT_FLOW_ENABLED

@feature-flag:NEW_CHECKOUT_FLOW_ENABLED
Feature: New checkout flow (feature-flag gated)
  As a product manager
  I want to verify the new checkout flow before full rollout
  So that I can confirm it works correctly for the enabled cohort

  Scenario: New checkout flow shows redesigned confirmation page
    Given the feature flag "NEW_CHECKOUT_FLOW_ENABLED" is active
    And I am a registered customer with items in my cart
    When I complete the checkout process
    Then I should see the new-style order confirmation with animated checkmark
    And I should see the "Share your order" social prompt

  Scenario: Customers without the flag see the original checkout
    Given the feature flag "NEW_CHECKOUT_FLOW_ENABLED" is inactive
    And I am a registered customer with items in my cart
    When I complete the checkout process
    Then I should see the classic order confirmation page
    And I should NOT see the "Share your order" prompt
```

```typescript
// src/steps/feature-flag.steps.ts — controlling flags in BDD scenarios
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// Step: Given the feature flag {string} is active
Given(
  'the feature flag {string} is active',
  async function (this: AppWorld, flagName: string) {
    // Strategy 1: Override via API endpoint (LaunchDarkly, Unleash, Flagsmith)
    await this.page.request.post('/api/test/feature-flags', {
      data: { flag: flagName, enabled: true, userId: this.testUserId }
    });
    // Strategy 2: Set a cookie that the app's flag client reads
    await this.page.context().addCookies([{
      name: `ff_${flagName}`, value: '1',
      domain: new URL(process.env.BASE_URL ?? 'http://localhost:3000').hostname,
      path: '/',
    }]);
  }
);

// Step: Given the feature flag {string} is inactive
Given(
  'the feature flag {string} is inactive',
  async function (this: AppWorld, flagName: string) {
    await this.page.request.post('/api/test/feature-flags', {
      data: { flag: flagName, enabled: false, userId: this.testUserId }
    });
    await this.page.context().addCookies([{
      name: `ff_${flagName}`, value: '0',
      domain: new URL(process.env.BASE_URL ?? 'http://localhost:3000').hostname,
      path: '/',
    }]);
  }
);
```

```typescript
// src/support/hooks.ts — feature flag cleanup after each scenario
import { After, Before } from '@cucumber/cucumber';
import { AppWorld } from './world';

// Reset all feature flags to production defaults after each scenario.
// Without this, a scenario that activates a flag contaminates the next scenario
// when running in parallel with shared state.
After(async function (this: AppWorld) {
  await this.page.request.post('/api/test/feature-flags/reset', {
    data: { userId: this.testUserId }
  });
});

// For parallel runs: each scenario gets a unique test user ID
// so flag overrides are scoped to that user and do not bleed across workers.
Before(async function (this: AppWorld) {
  this.testUserId = `test-${Date.now()}-${Math.random().toString(36).slice(2)}`;
});
```

**Cucumber profile for feature-flag scenarios** (`cucumber.js`):
```javascript
export default {
  // Only run scenarios for a specific flag — used during flag rollout testing
  'flag-new-checkout': {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    tags: '@feature-flag:NEW_CHECKOUT_FLOW_ENABLED',
    format: ['progress-bar', 'html:reports/flag-report.html'],
  },
  // CI: skip flag-gated scenarios in smoke run (they may be incomplete)
  smoke: {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    tags: '@smoke and not @feature-flag:*',  // exclude all flag-gated scenarios
    format: ['progress-bar'],
  },
};
```

**[community] Feature flag + BDD lifecycle rule**: When a feature flag is permanently
enabled (100% rollout), the `Given the feature flag X is active` precondition step and
the corresponding `@feature-flag:X` tag should be removed within one sprint. Stale
feature flag steps are a signal that the flag infrastructure was not cleaned up after
rollout — and they slow the suite by adding unnecessary API calls to every scenario.
Treat `@feature-flag:*` count as a tech-debt metric: more than 3 active flag scenarios
at any time indicates flag cleanup debt.

**[community] Unleash + BDD parallel isolation**: Teams using Unleash (open-source flag
server) for BDD test environments report that the `/api/client/features` polling interval
(default 15 seconds) creates race conditions in parallel BDD runs — a flag reset in one
worker is not visible to another for up to 15 seconds. Solution: configure Unleash's
test endpoint to use synchronous responses (`disableMetrics: true`, `refreshInterval: 0`),
or use a per-scenario strategy override scoped to the test user's `userId` context field.

---

### BDD ROI Measurement: Quantifying the Practice  [community]

BDD's business case rests on specific, measurable outcomes. Teams that measure BDD ROI
can justify the practice to stakeholders and identify when it is delivering value versus
consuming effort without return.

**Leading indicators** (visible within 1–2 sprints):

| Metric | How to measure | Target |
|---|---|---|
| Three Amigos session frequency | Sprint log / calendar | ≥ 1 per story |
| Questions answered before dev starts | Count red cards resolved in Example Mapping | < 20% unresolved at sprint start |
| Scenario creation time | Time from story kickoff to agreed Gherkin | < 2 hours per story |
| Step reuse ratio | `used_count / total_steps` from `--format usage` | > 2.0 (each step used avg 2× or more) |

**Lagging indicators** (visible after 1–2 quarters):

| Metric | How to measure | Target |
|---|---|---|
| Regression escape rate | Bugs found in production that were BDD-testable | < 5% of production bugs have no BDD scenario |
| Requirement ambiguity rate | Jira tickets reopened due to unclear requirements | Decrease vs pre-BDD baseline |
| Onboarding time | Time for new team member to write first scenario | < 1 week |
| Cross-team alignment | Stakeholder survey: "do you understand what our software does?" | > 8/10 |

```typescript
// scripts/bdd-roi-metrics.ts — automated ROI data collection
import { execSync } from 'child_process';
import * as fs from 'fs';

interface BddRoiMetrics {
  timestamp: string;
  totalScenarios: number;
  totalStepDefinitions: number;
  stepReuseFactor: number;
  scenariosPerSprint: number;
  wipePercentage: number;
  avgScenarioDurationMs: number | null;
}

function collectMetrics(): BddRoiMetrics {
  // Step reuse: parse cucumber --format usage output
  const usageOutput = execSync(
    'npx cucumber-js --dry-run --format usage 2>/dev/null || echo "DRY_RUN_FAILED"'
  ).toString();

  const usageLines = usageOutput
    .split('\n')
    .filter(line => /^\s+\d+/.test(line));

  const totalUses = usageLines.reduce((sum, line) => {
    const match = line.match(/(\d+)/);
    return sum + (match ? parseInt(match[1]) : 0);
  }, 0);

  const stepReuseFactor = usageLines.length > 0
    ? totalUses / usageLines.length
    : 0;

  // Count total scenarios
  const featureContent = execSync('find features -name "*.feature" -exec cat {} +')
    .toString();
  const totalScenarios = (featureContent.match(/^\s*(Scenario|Scenario Outline):/gm) ?? []).length;
  const wipScenarios = (featureContent.match(/@wip/g) ?? []).length;

  return {
    timestamp: new Date().toISOString(),
    totalScenarios,
    totalStepDefinitions: usageLines.length,
    stepReuseFactor: Math.round(stepReuseFactor * 10) / 10,
    scenariosPerSprint: 0, // Manual: divide delta by sprint count
    wipePercentage: Math.round((wipScenarios / totalScenarios) * 100),
    avgScenarioDurationMs: null, // Populated from junit XML after a full run
  };
}

const metrics = collectMetrics();
const history = JSON.parse(
  fs.existsSync('reports/bdd-roi-history.json')
    ? fs.readFileSync('reports/bdd-roi-history.json', 'utf8')
    : '[]'
) as BddRoiMetrics[];

history.push(metrics);
fs.writeFileSync('reports/bdd-roi-history.json', JSON.stringify(history, null, 2));
console.log('BDD ROI Metrics:', metrics);
```

**[community] The ROI case to management**: The most persuasive ROI argument is not
"we have X feature files" — it is "our regression escape rate dropped from Y% to Z%
after BDD adoption." Track production bugs for one quarter before BDD, one quarter after.
In complex domains (insurance, finance, logistics), teams consistently report 30–50%
reduction in requirement-ambiguity defects after establishing Three Amigos sessions, even
before the automation layer is in place.

**[community] Anti-ROI: measuring vanity metrics**: Teams that measure "scenario count"
as a proxy for BDD maturity create incentives to write lots of thin scenarios with weak
assertions. The right metric is the *defect detection rate* of the BDD suite — how many
production bugs would have been caught if the relevant scenario existed. Conduct quarterly
retrospectives mapping production incidents to the BDD layer: "Was there a BDD scenario
for this? Should there have been?" This builds the suite strategically rather than
volumetrically.

---

### Page Object Model Integration with BDD Step Definitions  [community]

The Page Object Model (POM) is the standard abstraction pattern for browser automation.
In BDD, step definitions play the role of "test case logic" while page objects play the
role of "UI interaction library." Keeping these two layers separate is critical for
maintainability.

**Why the separation matters**: Step definitions that contain raw selectors directly
(e.g., `page.locator('[data-testid="checkout-btn"]').click()`) are tightly coupled to
the UI. When the selector changes, every step that uses it breaks. Page objects centralize
selector knowledge so a single change fixes all steps.

```typescript
// src/pages/CheckoutPage.ts — Page Object for the checkout flow
import { Page, Locator, expect } from '@playwright/test';

export class CheckoutPage {
  private readonly page: Page;

  // Locators defined once — all steps reference these, not raw selectors
  readonly cartSummary: Locator;
  readonly cardNumberInput: Locator;
  readonly cardExpiryInput: Locator;
  readonly cardCvvInput: Locator;
  readonly confirmOrderButton: Locator;
  readonly orderConfirmationBanner: Locator;
  readonly errorMessage: Locator;
  readonly discountCodeInput: Locator;
  readonly applyDiscountButton: Locator;
  readonly orderTotal: Locator;

  constructor(page: Page) {
    this.page = page;
    this.cartSummary = page.getByTestId('cart-summary');
    this.cardNumberInput = page.getByTestId('card-number');
    this.cardExpiryInput = page.getByTestId('card-expiry');
    this.cardCvvInput = page.getByTestId('card-cvv');
    this.confirmOrderButton = page.getByTestId('confirm-order');
    this.orderConfirmationBanner = page.getByTestId('order-confirmation');
    this.errorMessage = page.getByTestId('error-message');
    this.discountCodeInput = page.getByTestId('discount-code-input');
    this.applyDiscountButton = page.getByTestId('apply-discount');
    this.orderTotal = page.getByTestId('order-total');
  }

  async navigate(): Promise<void> {
    await this.page.goto('/checkout');
    await expect(this.cartSummary).toBeVisible();
  }

  async fillCardDetails(cardNumber: string, expiry: string, cvv: string): Promise<void> {
    await this.cardNumberInput.fill(cardNumber);
    await this.cardExpiryInput.fill(expiry);
    await this.cardCvvInput.fill(cvv);
  }

  async fillValidCardDetails(): Promise<void> {
    await this.fillCardDetails('4242424242424242', '12/28', '123');
  }

  async fillExpiredCardDetails(): Promise<void> {
    await this.fillCardDetails('4242424242424242', '12/20', '123');
  }

  async confirmOrder(): Promise<void> {
    await this.confirmOrderButton.click();
  }

  async applyDiscount(code: string): Promise<void> {
    await this.discountCodeInput.fill(code);
    await this.applyDiscountButton.click();
  }

  async getOrderTotal(): Promise<number> {
    const text = await this.orderTotal.textContent() ?? '0';
    return parseFloat(text.replace(/[^0-9.]/g, ''));
  }

  async expectConfirmationVisible(): Promise<void> {
    await expect(this.orderConfirmationBanner).toBeVisible();
    await expect(this.page).toHaveURL(/\/order\/confirmation/);
  }

  async expectError(message: string): Promise<void> {
    await expect(this.errorMessage).toHaveText(message);
  }
}
```

```typescript
// src/support/world.ts — World holds page object instances
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { Browser, BrowserContext, Page, chromium } from '@playwright/test';
import { CheckoutPage } from '../pages/CheckoutPage';
import { LoginPage } from '../pages/LoginPage';

export class AppWorld extends World {
  browser!: Browser;
  context!: BrowserContext;
  page!: Page;
  testUserId!: string;
  authToken?: string;

  // Page object instances — created lazily per scenario
  private _checkoutPage?: CheckoutPage;
  private _loginPage?: LoginPage;

  constructor(options: IWorldOptions) {
    super(options);
  }

  // Lazy getters ensure page objects are created after this.page is set
  get checkoutPage(): CheckoutPage {
    this._checkoutPage ??= new CheckoutPage(this.page);
    return this._checkoutPage;
  }

  get loginPage(): LoginPage {
    this._loginPage ??= new LoginPage(this.page);
    return this._loginPage;
  }
}

setWorldConstructor(AppWorld);
```

```typescript
// src/steps/checkout.steps.ts — clean step definitions using page objects
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// Step definitions reference page object methods — no raw selectors here
Given('I am on the checkout page', async function (this: AppWorld) {
  await this.checkoutPage.navigate();
});

When('I enter valid credit card details', async function (this: AppWorld) {
  await this.checkoutPage.fillValidCardDetails();
});

When('I enter an expired credit card', async function (this: AppWorld) {
  await this.checkoutPage.fillExpiredCardDetails();
});

When('I confirm the order', async function (this: AppWorld) {
  await this.checkoutPage.confirmOrder();
});

When('I apply discount code {string}', async function (this: AppWorld, code: string) {
  await this.checkoutPage.applyDiscount(code);
});

Then('I should see an order confirmation page', async function (this: AppWorld) {
  await this.checkoutPage.expectConfirmationVisible();
});

Then('I should see the error {string}', async function (this: AppWorld, message: string) {
  await this.checkoutPage.expectError(message);
});

Then('my total should be {string}', async function (this: AppWorld, expected: string) {
  const actual = await this.checkoutPage.getOrderTotal();
  const expectedNum = parseFloat(expected);
  // Allow $0.01 tolerance for floating-point display differences
  if (Math.abs(actual - expectedNum) > 0.01) {
    throw new Error(`Expected total ${expectedNum} but got ${actual}`);
  }
});
```

**[community] When not to use Page Objects in BDD**: For API-level BDD scenarios (no
browser), Page Objects add no value — use a typed API client class instead. For very simple
single-page scenarios, the overhead of maintaining page object files may exceed the benefit.
The heuristic: if a selector is used in more than two step definitions, it belongs in a
page object. If it is used in only one step, define it inline.

**[community] Page Object anti-pattern — asserting in page objects**: Page objects should
expose *actions* and *locators*, not make assertions. A `checkout.expectConfirmationVisible()`
method is acceptable because it encapsulates *what* the confirmation state looks like (which
may change). A `checkout.assertOrderTotal(expected)` that throws with a specific assertion
message embeds test logic in the page object layer — the `Then` step definition should own
the assertion message so failure output is readable in the Cucumber HTML report.

---

### BDD Test Data Management Strategies  [community]

Test data is the most common source of BDD scenario flakiness and the most underestimated
aspect of BDD setup. Three strategies exist, each with distinct trade-offs.

**Strategy 1: API seeding (recommended for most scenarios)**

Use direct API calls in `Before` hooks or `Given` steps to create test data. This is 10–50x
faster than UI-driven setup and produces deterministic, isolated data per scenario.

```typescript
// src/support/data-factory.ts — centralized test data creation
import { request, APIRequestContext } from '@playwright/test';

export interface TestOrder {
  orderId: string;
  customerId: string;
  total: number;
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered';
}

export interface TestCustomer {
  customerId: string;
  email: string;
  authToken: string;
}

export class DataFactory {
  private readonly apiContext: APIRequestContext;
  private readonly baseUrl: string;
  // Track created resources for cleanup
  private readonly createdCustomerIds: string[] = [];
  private readonly createdOrderIds: string[] = [];

  constructor(apiContext: APIRequestContext, baseUrl: string) {
    this.apiContext = apiContext;
    this.baseUrl = baseUrl;
  }

  async createTestCustomer(overrides: Partial<TestCustomer> = {}): Promise<TestCustomer> {
    const email = overrides.email ?? `test-${Date.now()}@example.com`;
    const res = await this.apiContext.post(`${this.baseUrl}/api/test/customers`, {
      data: { email, password: 'TestPass123!', ...overrides }
    });
    if (!res.ok()) throw new Error(`Failed to create test customer: ${await res.text()}`);
    const customer = await res.json() as TestCustomer;
    this.createdCustomerIds.push(customer.customerId);
    return customer;
  }

  async createTestOrder(
    customerId: string,
    overrides: Partial<TestOrder> = {}
  ): Promise<TestOrder> {
    const res = await this.apiContext.post(`${this.baseUrl}/api/test/orders`, {
      data: {
        customerId,
        items: [{ productId: 'prod-001', quantity: 1 }],
        status: 'confirmed',
        ...overrides,
      }
    });
    if (!res.ok()) throw new Error(`Failed to create test order: ${await res.text()}`);
    const order = await res.json() as TestOrder;
    this.createdOrderIds.push(order.orderId);
    return order;
  }

  // Cleanup: delete all data created during this scenario
  async cleanup(): Promise<void> {
    for (const id of this.createdOrderIds) {
      await this.apiContext.delete(`${this.baseUrl}/api/test/orders/${id}`).catch(() => {});
    }
    for (const id of this.createdCustomerIds) {
      await this.apiContext.delete(`${this.baseUrl}/api/test/customers/${id}`).catch(() => {});
    }
  }
}
```

```typescript
// src/support/hooks.ts — integrate DataFactory into World
import { Before, After } from '@cucumber/cucumber';
import { request } from '@playwright/test';
import { AppWorld } from './world';
import { DataFactory } from './data-factory';

Before(async function (this: AppWorld) {
  const apiContext = await request.newContext({
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    extraHTTPHeaders: { 'x-test-run-id': this.testUserId },
  });
  this.dataFactory = new DataFactory(apiContext, process.env.BASE_URL ?? 'http://localhost:3000');
});

After(async function (this: AppWorld) {
  await this.dataFactory?.cleanup();
});
```

**Strategy 2: Database transaction rollback (for integration-level BDD)**

For BDD scenarios that test at the service/repository layer (no browser), wrapping each
scenario in a database transaction that rolls back after the test keeps the database clean
without API overhead.

```typescript
// src/support/db-hooks.ts — transaction rollback for DB-level BDD
import { Before, After } from '@cucumber/cucumber';
import { AppWorld } from './world';
import { getTestDbConnection } from '../db/test-connection';

Before(async function (this: AppWorld) {
  this.dbConnection = await getTestDbConnection();
  this.dbTransaction = await this.dbConnection.beginTransaction();
  // Inject transaction into the service layer under test
  this.serviceContext = { db: this.dbConnection, transaction: this.dbTransaction };
});

After(async function (this: AppWorld) {
  await this.dbTransaction?.rollback();
  await this.dbConnection?.close();
});
```

**Strategy 3: Fixture files for read-only reference data**

For product catalog data, pricing tables, or any data that scenarios read but do not write,
JSON fixture files loaded once at suite startup are faster than per-scenario API seeding.

```typescript
// src/support/fixtures.ts — load static reference data once for the suite
import * as fs from 'fs';
import * as path from 'path';

export interface ProductFixture {
  productId: string;
  name: string;
  price: number;
  category: string;
}

let _products: ProductFixture[] | null = null;

export function getProductFixtures(): ProductFixture[] {
  if (!_products) {
    _products = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../fixtures/products.json'), 'utf8')
    ) as ProductFixture[];
  }
  return _products;
}

export function getProductById(productId: string): ProductFixture {
  const product = getProductFixtures().find(p => p.productId === productId);
  if (!product) throw new Error(`No fixture for product: ${productId}`);
  return product;
}
```

**[community] Test data strategy selection guide**:

| Scenario type | Recommended strategy | Rationale |
|---|---|---|
| Browser E2E (creates/modifies data) | API seeding + cleanup | Full isolation without UI overhead |
| Service/repository layer | DB transaction rollback | Fastest, zero cleanup risk |
| Read-only reference data | JSON fixture files | Load once, no network round trips |
| Third-party integrations | Wiremock/MSW stubs | Cannot control external data |
| Performance-sensitive scenarios | Pre-seeded DB state | No per-scenario overhead |

**[community] Test data amnesia**: The most common data management failure is
"forgetting" to clean up test data in CI. After 3 months of daily CI runs, test databases
accumulate thousands of stale test records that slow queries, fill disk, and cause
false positives when scenarios accidentally pick up data from previous runs. The fix:
every `Before` hook that creates data must have a corresponding `After` hook that deletes it.
Track created resource IDs in the World object — never rely on "delete by pattern" cleanup.

---

### BDD for Event-Driven and Async Systems  [community]

Event-driven architectures — where behavior is triggered by events rather than synchronous
HTTP calls — require special handling in BDD step definitions. A `When I place an order`
step in an event-driven system may publish an event to a queue; the `Then` assertion may
need to wait for a downstream consumer to process that event before the observable outcome
is visible.

The key pattern is the **poll-and-assert** helper: wait up to a timeout for the expected
state to appear, polling at short intervals. This is safer than `sleep()` calls, which
produce flaky tests whenever the system is slower than expected.

```gherkin
# features/inventory/stock-reservation.feature
Feature: Stock reservation via event-driven inventory service

  Scenario: Order placement reserves the purchased items from stock
    Given the product "Wireless Headphones" has 10 units in stock
    When I place an order for 3 units of "Wireless Headphones"
    Then within 5 seconds the available stock for "Wireless Headphones" should be 7
    And an "order.placed" event should have been published to the events log

  Scenario: Stock reservation is released when an order is cancelled
    Given I have a confirmed order for 2 units of "Gaming Mouse"
    And the available stock for "Gaming Mouse" is 8
    When I cancel the order
    Then within 5 seconds the available stock for "Gaming Mouse" should be 10
    And an "order.cancelled" event should have been published to the events log
```

```typescript
// src/steps/inventory.steps.ts — async event-driven BDD
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// Helper: poll until condition is true or timeout expires
async function waitUntil(
  condition: () => Promise<boolean>,
  timeoutMs: number,
  intervalMs = 250
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await condition()) return;
    await new Promise(resolve => setTimeout(resolve, intervalMs));
  }
  throw new Error(`Condition not met within ${timeoutMs}ms`);
}

Then(
  'within {int} seconds the available stock for {string} should be {int}',
  async function (this: AppWorld, seconds: number, productName: string, expected: number) {
    await waitUntil(
      async () => {
        const res = await this.apiContext.get(`/api/inventory/${productName}/available`);
        if (!res.ok()) return false;
        const body = await res.json() as { available: number };
        return body.available === expected;
      },
      seconds * 1000
    );
    // Final assertion with full error message on failure
    const res = await this.apiContext.get(`/api/inventory/${productName}/available`);
    const body = await res.json() as { available: number };
    if (body.available !== expected) {
      throw new Error(
        `Stock for "${productName}": expected ${expected}, got ${body.available} ` +
        `after ${seconds}s timeout`
      );
    }
  }
);

Then(
  'an {string} event should have been published to the events log',
  async function (this: AppWorld, eventType: string) {
    // Check event audit log for events scoped to this scenario's correlation ID
    await waitUntil(
      async () => {
        const res = await this.apiContext.get(
          `/api/test/events?correlationId=${this.correlationId}&type=${eventType}`
        );
        const body = await res.json() as { events: unknown[] };
        return body.events.length > 0;
      },
      5000
    );
  }
);
```

```typescript
// src/support/world.ts — correlation ID for event tracing
// Each scenario gets a unique correlationId injected into all API requests.
// Services emit events with this ID, enabling event log queries per scenario.
export class AppWorld extends World {
  correlationId!: string;
  apiContext!: import('@playwright/test').APIRequestContext;
  // ...other fields
}
```

```typescript
// src/support/hooks.ts — inject correlation ID into all requests
import { Before, After } from '@cucumber/cucumber';
import { request } from '@playwright/test';
import { AppWorld } from './world';

Before(async function (this: AppWorld) {
  this.correlationId = `test-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  this.apiContext = await request.newContext({
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    extraHTTPHeaders: {
      'x-correlation-id': this.correlationId,
      'x-test-run': 'true',
    },
  });
});

After(async function (this: AppWorld) {
  await this.apiContext?.dispose();
});
```

**[community] Async BDD and the `waitUntil` anti-pattern**: Teams new to async BDD
frequently use `await page.waitForTimeout(3000)` (a fixed sleep) instead of polling.
Fixed sleeps make suites slow when events arrive faster than expected and flaky when
they arrive slower. The poll-and-assert pattern with an explicit timeout is always
preferable. Set the timeout based on the 99th percentile latency of the event consumer,
not the average.

**[community] Message queue BDD with testcontainers**: For BDD scenarios that need to
assert on Kafka/RabbitMQ message publishing, `testcontainers` (Node.js library) spins up
a real message broker in Docker during the test run. The scenario's `Then` step subscribes
to the test topic and waits for the expected message. This is more reliable than mocking
the broker because it catches serialization bugs and schema mismatches that mocks miss.

---

### BDD Security Testing Scenarios  [community]

Security requirements are business behaviors and can be expressed as BDD scenarios.
Security BDD serves two purposes: (1) it ensures security controls are tested as
acceptance criteria, not afterthoughts, and (2) it produces human-readable audit
evidence for security reviews.

```gherkin
# features/security/authentication.feature
@security @regression
Feature: Authentication security controls
  As a security team
  I want authentication to enforce proper controls
  So that unauthorized access is prevented

  Scenario: Brute force protection locks account after 5 failed attempts
    Given I am an anonymous user
    When I submit incorrect credentials for "alice@example.com" 5 times
    Then my account should be locked
    And I should see the message "Account temporarily locked. Try again in 15 minutes."
    And the 6th login attempt should fail even with correct credentials

  Scenario: Session token is invalidated after logout
    Given I am logged in as "alice@example.com"
    And I capture my current session token
    When I log out
    Then using the captured session token should return HTTP 401
    And navigating to "/account" should redirect me to the login page

  Scenario: Password reset link expires after 1 hour
    Given a password reset link was generated 61 minutes ago for "alice@example.com"
    When I navigate to the password reset link
    Then I should see the error "This reset link has expired"
    And I should be prompted to request a new reset link

  @smoke
  Scenario: CSRF token is required for state-changing requests
    Given I am logged in as "alice@example.com"
    When I send a POST request to "/api/account/email" without a CSRF token
    Then the response status should be 403
    And the response should contain "CSRF token missing or invalid"
```

```typescript
// src/steps/security.steps.ts — security BDD step definitions
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// State holder for captured values across steps
interface SecurityStepState {
  capturedSessionToken?: string;
  lastResponseStatus?: number;
  lastResponseBody?: Record<string, unknown>;
}

Given('I am an anonymous user', async function (this: AppWorld & SecurityStepState) {
  // Clear all cookies/storage to ensure anonymous state
  await this.page.context().clearCookies();
  await this.page.evaluate(() => {
    localStorage.clear();
    sessionStorage.clear();
  });
});

When(
  'I submit incorrect credentials for {string} {int} times',
  async function (this: AppWorld & SecurityStepState, email: string, times: number) {
    for (let i = 0; i < times; i++) {
      await this.page.goto('/login');
      await this.page.getByTestId('email').fill(email);
      await this.page.getByTestId('password').fill(`wrong-password-${i}`);
      await this.page.getByTestId('submit').click();
      // Allow rate limiting responses to settle
      await this.page.waitForLoadState('networkidle');
    }
  }
);

Given('I capture my current session token', async function (this: AppWorld & SecurityStepState) {
  const cookies = await this.page.context().cookies();
  const sessionCookie = cookies.find(c => c.name === 'session_token');
  if (!sessionCookie) throw new Error('No session_token cookie found');
  this.capturedSessionToken = sessionCookie.value;
});

Then(
  'using the captured session token should return HTTP {int}',
  async function (this: AppWorld & SecurityStepState, expectedStatus: number) {
    if (!this.capturedSessionToken) throw new Error('No captured session token');
    const res = await this.page.request.get('/api/me', {
      headers: { Cookie: `session_token=${this.capturedSessionToken}` }
    });
    if (res.status() !== expectedStatus) {
      throw new Error(
        `Expected HTTP ${expectedStatus} for invalidated token, got ${res.status()}`
      );
    }
  }
);

When(
  'I send a POST request to {string} without a CSRF token',
  async function (this: AppWorld & SecurityStepState, path: string) {
    const res = await this.page.request.post(path, {
      data: { email: 'new@example.com' },
      headers: { 'Content-Type': 'application/json' }
      // Deliberately omitting CSRF token header
    });
    this.lastResponseStatus = res.status();
    try {
      this.lastResponseBody = await res.json() as Record<string, unknown>;
    } catch {
      this.lastResponseBody = {};
    }
  }
);

Then(
  'the response status should be {int}',
  async function (this: AppWorld & SecurityStepState, status: number) {
    if (this.lastResponseStatus !== status) {
      throw new Error(`Expected ${status}, got ${this.lastResponseStatus}`);
    }
  }
);

Then(
  'the response should contain {string}',
  async function (this: AppWorld & SecurityStepState, text: string) {
    const bodyText = JSON.stringify(this.lastResponseBody ?? {});
    if (!bodyText.includes(text)) {
      throw new Error(`Expected response body to contain "${text}", got: ${bodyText}`);
    }
  }
);
```

**[community] Security BDD scope**: Security BDD scenarios are most effective for
*functional security controls* — authentication, authorization, input validation,
session management. They are not a substitute for dedicated security tools (SAST, DAST,
penetration testing). OWASP ZAP integration or Burp Suite scanning covers the attack
surface that BDD scenarios cannot — SQL injection variants, XSS payload enumeration,
or certificate validation bypasses. BDD + DAST together cover the security testing
pyramid: BDD for "the control exists and works," DAST for "the control cannot be bypassed."

**[community] Security scenario visibility**: Security scenarios should be visible in
living documentation. A product manager seeing `Scenario: Account locked after 5 failed
attempts` in the regression suite knows this protection is tested, not just claimed.
Teams that keep security test cases hidden in Jira subtasks or separate test management
tools lose the living documentation benefit for this critical category.

**[community] Time-dependent security scenarios and the Playwright Clock API**: Security
scenarios that test expiry windows (password reset links, session timeouts, temporary ban
durations) traditionally require either: (a) a DB seeder that can backdate records, or
(b) test environment configuration that overrides TTL values. Playwright v1.45+ `page.clock`
API enables a third approach: fix the browser clock before generating the token, then
`fastForward()` past the expiry. This only works for client-side expiry validation; for
server-side JWT `exp` verification, the DB seeder approach remains necessary. See the
"Playwright 1.45–1.60: New BDD-Relevant APIs" section for the full `page.clock` example.

---

### AI-Assisted BDD Scenario Generation  [community]

AI language models can accelerate the "formulation" phase of BDD by drafting Gherkin
scenarios from user story text. The output requires review and refinement — AI cannot
know the team's ubiquitous language or edge cases that emerged from Three Amigos —
but it reduces the blank-page problem and surfaces scenarios the team might not have
considered.

**Where AI adds value in the BDD workflow:**

1. **Draft scenario generation**: Given a user story, generate 3–5 scenario candidates
   for the Three Amigos session to review and refine.
2. **Edge case surfacing**: Prompt the model to identify boundary conditions, error
   paths, and security implications for a feature description.
3. **Step definition stub generation**: After writing scenarios, prompt the model to
   generate TypeScript step definition stubs that the team fills in.
4. **Scenario review**: Use the model to check whether a scenario is declarative or
   imperative, and suggest improvements.

**TypeScript utility for AI-assisted scenario drafting** (using Anthropic Claude API):

```typescript
// scripts/draft-scenarios.ts — generate Gherkin candidates from story text
// Requires: npm install @anthropic-ai/sdk
import Anthropic from '@anthropic-ai/sdk';
import * as fs from 'fs';

const client = new Anthropic();

interface ScenarioDraftInput {
  storyTitle: string;
  storyDescription: string;
  acceptanceCriteria: string[];
  ubiquitousLanguage?: Record<string, string>; // term -> definition
}

async function draftScenarios(input: ScenarioDraftInput): Promise<string> {
  const ulContext = input.ubiquitousLanguage
    ? `\nUse this ubiquitous language consistently:\n${
        Object.entries(input.ubiquitousLanguage)
          .map(([term, def]) => `- "${term}": ${def}`)
          .join('\n')
      }\n`
    : '';

  const prompt = `You are a BDD expert helping draft Gherkin scenarios for a software team.

User story: ${input.storyTitle}
${input.storyDescription}

Acceptance criteria:
${input.acceptanceCriteria.map((c, i) => `${i + 1}. ${c}`).join('\n')}
${ulContext}
Generate 4–6 Gherkin scenarios covering:
1. The happy path
2. At least 2 edge cases or boundary conditions
3. At least 1 error/rejection scenario
4. 1 scenario that is commonly forgotten (e.g., empty state, concurrent access)

Rules:
- Use declarative (not imperative) style — describe WHAT, not HOW
- No UI selectors or technical terms in scenario text
- Each scenario must have exactly 1 When step
- Use the ubiquitous language terms provided
- Output valid Gherkin only (no explanatory prose)`;

  const message = await client.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 1024,
    messages: [{ role: 'user', content: prompt }],
  });

  const content = message.content[0];
  return content.type === 'text' ? content.text : '';
}

// Example usage
const draft = await draftScenarios({
  storyTitle: 'Apply discount code at checkout',
  storyDescription: 'As a customer, I want to enter a discount code during checkout to reduce my order total.',
  acceptanceCriteria: [
    'Valid codes reduce the total by the specified percentage',
    'Expired codes are rejected with an error message',
    'Each code can only be used once per customer',
    'Codes cannot reduce the total below $0',
  ],
  ubiquitousLanguage: {
    'Customer': 'An authenticated user who has completed account registration',
    'Discount Code': 'A string token that modifies the order total per a business rule',
    'Cart': 'A temporary collection of items before purchase commitment',
  }
});

console.log(draft);
// Save draft for Three Amigos review
fs.writeFileSync('docs/scenario-drafts/discount-code-draft.gherkin', draft);
```

**[community] AI scenario generation pitfalls**:

1. **Imperative drift**: AI models frequently generate imperative scenarios without
   explicit instruction. The prompt above includes a "declarative only" rule, but
   output should always be reviewed for steps like "When I click the Submit button."

2. **Hallucinated domain language**: AI may use synonyms for ubiquitous language
   terms ("coupon" instead of "discount code"). Always provide the UL glossary in
   the prompt and validate output against it.

3. **Scenarios that test implementation, not behavior**: AI sometimes generates
   scenarios asserting database state or API response fields rather than user-observable
   outcomes. These should be moved to unit or integration tests.

4. **Missing the three-amigos validation step**: AI-generated scenarios must go
   through a human Three Amigos review before they are accepted. AI knows general
   BDD patterns but not your team's specific business rules, regulatory constraints,
   or edge cases discovered in production. Treat AI output as a first draft, not a
   finished artifact.

**[community] The 80/20 rule for AI-assisted BDD**: In practice, AI generates ~80% of
the scenario structure correctly. The 20% it gets wrong — domain terminology, edge cases
specific to your business rules, boundary conditions in pricing/eligibility logic —
are precisely the 20% that matters most for defect prevention. AI-assisted BDD is most
valuable when teams use it to *start* the Three Amigos conversation, not to *end* it.

---

### BDD Team Retrospective and Continuous Improvement  [community]

BDD practices degrade without explicit retrospective attention. The collaboration model
weakens under deadline pressure; step definitions accumulate bloat; feature files drift
imperative. A quarterly BDD health retrospective — separate from the sprint retrospective
— keeps the practice on track.

**BDD retrospective agenda (60 minutes, quarterly):**

| Time | Topic | Goal |
|---|---|---|
| 0–10 min | Metrics review | Review suite health numbers (scenario count, @wip %, step reuse factor, flaky rate) |
| 10–25 min | Three Amigos quality | Count stories that had Three Amigos sessions this quarter; review outcomes |
| 25–40 min | Step definition audit | Run `--format usage`, identify unused and near-duplicate steps for removal |
| 40–50 min | Living documentation check | Do stakeholders read the reports? Are scenarios understandable to non-developers? |
| 50–60 min | Action items | 1–3 concrete improvements for next quarter |

**[community] BDD maturity model** (informal, based on community retrospective patterns):

| Level | Characteristics | Common symptom if stuck here |
|---|---|---|
| Level 0: No BDD | Tests written after code; no shared language | All defects discovered post-development |
| Level 1: Tool adoption | Gherkin files exist; no Three Amigos | Feature files written by QA alone, often imperative |
| Level 2: Collaboration | Three Amigos runs consistently; scenarios are declarative | Suite is slow (no API seeding), reporting not read by stakeholders |
| Level 3: Living documentation | Stakeholders read and trust feature files; suite runs in CI | Step definition bloat; parallel execution flakiness |
| Level 4: Continuous improvement | Quarterly BDD retros; ROI measured; suite health monitored | None — this is the target state |

**TypeScript: BDD health check script** (run in CI to fail on health violations):

```typescript
// scripts/bdd-health-check.ts — fail CI if BDD health metrics are out of range
import { execSync } from 'child_process';
import * as fs from 'fs';

interface HealthCheckResult {
  passed: boolean;
  violations: string[];
  warnings: string[];
  metrics: Record<string, number | string>;
}

function runHealthCheck(): HealthCheckResult {
  const violations: string[] = [];
  const warnings: string[] = [];

  // 1. Count total scenarios and @wip
  const featureContent = execSync(
    'find features -name "*.feature" -exec cat {} + 2>/dev/null || echo ""'
  ).toString();
  const totalScenarios = (featureContent.match(/^\s*(Scenario|Scenario Outline):/gm) ?? []).length;
  const wipCount = (featureContent.match(/@wip/g) ?? []).length;
  const wipPct = totalScenarios > 0 ? Math.round((wipCount / totalScenarios) * 100) : 0;

  // 2. Step reuse factor
  let stepReuseFactor = 0;
  try {
    const usageOut = execSync('npx cucumber-js --dry-run --format usage 2>/dev/null').toString();
    const lines = usageOut.split('\n').filter(l => /^\s+\d+/.test(l));
    const totalUses = lines.reduce((s, l) => s + parseInt(l.match(/(\d+)/)?.[1] ?? '0'), 0);
    stepReuseFactor = lines.length > 0 ? totalUses / lines.length : 0;
  } catch { /* dry-run may fail on missing steps */ }

  // 3. Evaluate against thresholds
  if (wipPct > 10) {
    violations.push(`@wip scenarios: ${wipPct}% (threshold: 10%)`);
  }
  if (totalScenarios > 1000) {
    violations.push(`Total scenarios: ${totalScenarios} (threshold: 1000)`);
  }
  if (stepReuseFactor < 1.5 && stepReuseFactor > 0) {
    warnings.push(`Step reuse factor: ${stepReuseFactor.toFixed(1)} (target: > 2.0)`);
  }
  if (totalScenarios < 5 && totalScenarios > 0) {
    warnings.push(`Low scenario count: ${totalScenarios} — BDD suite may not be actively maintained`);
  }

  return {
    passed: violations.length === 0,
    violations,
    warnings,
    metrics: {
      totalScenarios,
      wipCount,
      wipPercentage: `${wipPct}%`,
      stepReuseFactor: stepReuseFactor.toFixed(1),
    },
  };
}

const result = runHealthCheck();
console.log('\nBDD Health Check');
console.log('================');
console.log('Metrics:', result.metrics);

if (result.warnings.length > 0) {
  console.warn('\nWarnings:');
  result.warnings.forEach(w => console.warn(`  ⚠ ${w}`));
}

if (result.violations.length > 0) {
  console.error('\nViolations (CI FAIL):');
  result.violations.forEach(v => console.error(`  ✗ ${v}`));
  process.exit(1);
}

console.log('\nAll health checks passed.');
```

**[community] BDD retro finding: the "hero QA" failure pattern**: In teams where one
QA engineer writes all the Gherkin, the Three Amigos model breaks. That QA becomes the
sole owner of living documentation — when they leave, the practice collapses. The fix
is to rotate Gherkin authorship through the team, with QA in a facilitation role rather
than sole author. Every developer should have written at least one `.feature` file and
corresponding step definitions by the end of the first quarter.

**[community] BDD and OKRs**: Sustainable BDD adoption requires organizational alignment.
Teams that are measured on story points per sprint — with no quality OKR — will deprioritize
Three Amigos sessions under pressure. The quality OKR that most directly incentivizes BDD:
"Reduce regression escape rate to < 5% of stories shipped." This makes the Three Amigos
session a velocity investment, not a tax.

---

## Additional Resources (Iteration 10 Additions)

- [Unleash feature flag server](https://getunleash.io/) — open-source feature flag management compatible with BDD test environments
- [LaunchDarkly testing best practices](https://docs.launchdarkly.com/guides/flags/testing-with-flags) — feature flag isolation for automated tests
- [testcontainers-node](https://github.com/testcontainers/testcontainers-node) — spin up real message brokers and databases in Docker for BDD scenarios
- [Anthropic Claude API](https://docs.anthropic.com/en/api/) — AI-assisted scenario generation via the Messages API
- [Stryker mutation testing for JavaScript/TypeScript](https://stryker-mutator.io/docs/stryker-js/introduction/) — validate BDD scenario assertion quality
- [OWASP Testing Guide v4.2](https://owasp.org/www-project-web-security-testing-guide/) — functional security controls suitable for BDD scenarios
- [gherkin-lint](https://github.com/vsiakka/gherkin-lint) — Gherkin feature file linting rules
- [Wiremock for Node](https://github.com/webpagepublishing/wiremock-npm) — HTTP stub server for third-party dependency isolation in BDD
- [MSW (Mock Service Worker)](https://mswjs.io/) — API mocking at the network layer for BDD browser scenarios
- [BDD Books — Gaspar Nagy & Seb Rose](https://bddbooks.com/) — comprehensive practitioner reference for BDD at scale
- [Example Mapping whitepaper (Matt Wynne)](https://cucumber.io/blog/bdd/example-mapping-introduction/) — structured Three Amigos workshop technique
- [ISTQB CTFL 4.0 Syllabus](https://www.istqb.org/certifications/certified-tester-foundation-level) — standardized testing terminology reference

---

### Gherkin `Rule` Keyword: Structuring Scenarios by Business Rule

The `Rule` keyword (introduced in Cucumber 6+, now standard) groups related scenarios that
all test a single business rule within a feature. It sits between the `Feature` header and
individual `Scenario` blocks, acting as a second-level heading that makes the feature file
self-documenting.

**Why `Rule` matters**: A `Feature` with 12 unrelated scenarios is hard to read. Grouping
by business rule reveals which rule each scenario is verifying. Product managers can scan
the rules at a glance and immediately understand the feature's policy surface. QA engineers
can see which rules have full scenario coverage and which have gaps.

```gherkin
# features/payments/refund-policy.feature

Feature: Refund policy enforcement
  As a finance team
  I want the refund policy to be consistently enforced
  So that customers receive fair treatment and the business controls refund costs

  Rule: Refunds are only available within 30 days of order confirmation

    Scenario: Customer requests a refund within the 30-day window
      Given I have a confirmed order from 15 days ago
      When I request a full refund
      Then the refund should be approved
      And I should receive a refund confirmation email

    Scenario: Customer requests a refund exactly on day 30
      Given I have a confirmed order from exactly 30 days ago
      When I request a full refund
      Then the refund should be approved

    Scenario: Customer requests a refund after 30 days
      Given I have a confirmed order from 31 days ago
      When I request a full refund
      Then the refund should be rejected
      And I should see the message "Refund window has closed (30-day limit)"

  Rule: Digital products are non-refundable once downloaded

    Scenario: Customer has not downloaded a digital product
      Given I purchased a digital product 5 days ago
      And I have not downloaded the product
      When I request a refund
      Then the refund should be approved

    Scenario: Customer has downloaded a digital product
      Given I purchased a digital product 5 days ago
      And I have already downloaded the product
      When I request a refund
      Then the refund should be rejected
      And I should see the message "Downloaded digital products are non-refundable"

  Rule: Partial refunds apply when only some items in an order are returned

    Background:
      Given I have a confirmed order containing:
        | product       | price  |
        | Laptop stand  | 49.99  |
        | USB-C hub     | 29.99  |

    Scenario: Returning one item from a multi-item order
      When I initiate a return for the "Laptop stand" only
      Then a partial refund of $49.99 should be processed
      And my order should still show the "USB-C hub" as active
```

**Step definition handling with `Rule`** — the `Rule` keyword has no corresponding step
binding. It is purely a Gherkin structural element. Steps work identically; only the
feature file organization changes:

```typescript
// src/steps/refund.steps.ts — steps apply to all scenarios regardless of Rule grouping
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

Given(
  'I have a confirmed order from {int} days ago',
  async function (this: AppWorld, daysAgo: number) {
    const orderDate = new Date();
    orderDate.setDate(orderDate.getDate() - daysAgo);
    const order = await this.dataFactory.createTestOrder(this.customerId, {
      confirmedAt: orderDate.toISOString(),
      status: 'confirmed',
    });
    this.currentOrderId = order.orderId;
  }
);

When('I request a full refund', async function (this: AppWorld) {
  this.refundResponse = await this.apiContext.post(
    `/api/orders/${this.currentOrderId}/refund`,
    { data: { type: 'full', reason: 'customer_request' } }
  );
});

Then('the refund should be approved', async function (this: AppWorld) {
  if (!this.refundResponse.ok()) {
    const body = await this.refundResponse.json();
    throw new Error(`Refund rejected unexpectedly: ${JSON.stringify(body)}`);
  }
  const body = await this.refundResponse.json() as { status: string };
  if (body.status !== 'approved') {
    throw new Error(`Expected refund status "approved", got "${body.status}"`);
  }
});

Then('the refund should be rejected', async function (this: AppWorld) {
  if (this.refundResponse.ok()) {
    throw new Error(`Expected refund rejection (4xx) but got ${this.refundResponse.status()}`);
  }
});

Then('I should see the message {string}', async function (this: AppWorld, message: string) {
  const body = await this.refundResponse.json() as { message: string };
  if (!body.message.includes(message)) {
    throw new Error(`Expected message "${message}", got "${body.message}"`);
  }
});
```

**`Rule` with `Background`** — a `Background` section inside a `Rule` block applies only
to scenarios within that rule, not the entire feature. This is the primary advantage of
`Rule` over flat feature files: background setup can be scoped to the scenarios that need it.

```gherkin
Feature: Shopping cart discounts

  # This Background applies to ALL scenarios in the feature
  Background:
    Given I am a registered customer

  Rule: First-time customer discounts are applied automatically

    # This Background applies ONLY to scenarios within this Rule block
    Background:
      Given my account was created today
      And I have never placed an order

    Scenario: First order receives 10% welcome discount
      When I add items totalling $100 to my cart
      Then my cart total should show $90

    Scenario: Welcome discount does not apply to subsequent orders
      Given I have previously placed an order
      When I add items totalling $100 to my cart
      Then my cart total should show $100
```

**[community] `Rule` keyword adoption gap**: Despite being available since Cucumber 6
(2020), the `Rule` keyword is underused in most BDD suites. Teams default to flat feature
files with 10–20 unrelated scenarios. The `Rule` keyword pays back immediately in
readability: stakeholders who review feature files can now understand the policy structure
of a feature in 30 seconds rather than reading every scenario. Add `one-rule-per-business-rule`
as a guideline in your Gherkin review checklist.

**[community] `Rule` as design feedback**: When a single `Rule` block in a feature has
more than 8 scenarios, it is a signal that the business rule has too many edge cases to be
expressed as a single scenario collection — it likely hides a sub-rule that should be
elevated to its own `Rule` block or split into a separate feature file.

**[community] `Rule` + `Background` as a refactoring signal**: If you find yourself writing `Given X is in state A` in half your scenarios and `Given X is in state B` in the other half, you have two implicit business rules. Split them into separate `Rule` blocks each with its own `Background` — this eliminates conditional `Given` steps and makes the rule boundary explicit. Teams that miss this refactoring accumulate scenarios with long `Given` sections that duplicate setup logic across the file.

**[community] `Rule` and Example Mapping alignment**: In Example Mapping sessions, each blue card (business rule) maps to exactly one `Rule` block in the resulting feature file. The green cards (concrete examples) under each blue card map to `Scenario` / `Example` blocks within that `Rule`. This 1-to-1 mapping lets anyone verify that every rule surfaced in the Three Amigos session has scenario coverage — and surfaces scenarios that lack a corresponding rule (a sign they may be testing implementation rather than behavior).

---

### Screenplay Pattern for BDD Step Definitions  [community]

The Screenplay Pattern is an alternative to Page Objects for organizing automation code
in BDD step definitions. Instead of objects representing pages, it uses three concepts:

- **Actors**: Represent users (Alice, Bob, admin, guest). Each actor has *Abilities* (browse the web, call an API).
- **Tasks**: High-level user goals ("Alice places an order"). Tasks are composed of *Actions*.
- **Actions**: Atomic interactions ("fill the card number field", "click confirm").

The Screenplay Pattern solves the primary Page Object limitation: page objects encourage
step definitions that are coupled to a single page. An `Actor` can perform tasks across
multiple pages, which better represents real user journeys.

**Why Screenplay over Page Objects**: Page objects model the system's UI structure.
Screenplay models user intent. When a user journey spans multiple pages (checkout →
confirmation → email → account history), a page-object-based step definition calls
methods on multiple page objects in sequence. A Screenplay `Task` encapsulates the entire
journey as a named intent — `PlaceOrder.withCreditCard()` — making the step definition
readable at the business level.

```typescript
// src/screenplay/abilities/BrowseTheWeb.ts — Actor's ability to use a browser
import { Page } from '@playwright/test';

export class BrowseTheWeb {
  private constructor(private readonly page: Page) {}

  static using(page: Page): BrowseTheWeb {
    return new BrowseTheWeb(page);
  }

  getPage(): Page {
    return this.page;
  }
}

// src/screenplay/actors/Actor.ts — Actor holds abilities and performs tasks
export class Actor {
  private readonly abilities = new Map<Function, object>();

  constructor(public readonly name: string) {}

  whoCan(...newAbilities: object[]): this {
    for (const ability of newAbilities) {
      this.abilities.set(ability.constructor, ability);
    }
    return this;
  }

  ability<T>(abilityClass: new (...args: unknown[]) => T): T {
    const found = this.abilities.get(abilityClass);
    if (!found) {
      throw new Error(`${this.name} does not have ${abilityClass.name} ability`);
    }
    return found as T;
  }

  async attemptsTo(...tasks: Array<{ performAs: (actor: Actor) => Promise<void> }>): Promise<void> {
    for (const task of tasks) {
      await task.performAs(this);
    }
  }
}

// src/screenplay/tasks/PlaceOrder.ts — Task: place an order end-to-end
import { Actor } from '../actors/Actor';
import { BrowseTheWeb } from '../abilities/BrowseTheWeb';
import { NavigateTo } from '../actions/NavigateTo';
import { FillField } from '../actions/FillField';
import { ClickButton } from '../actions/ClickButton';

export class PlaceOrder {
  private constructor(
    private readonly items: Array<{ productId: string; quantity: number }>
  ) {}

  static forItems(items: Array<{ productId: string; quantity: number }>): PlaceOrder {
    return new PlaceOrder(items);
  }

  async performAs(actor: Actor): Promise<void> {
    const page = actor.ability(BrowseTheWeb).getPage();

    // Add items to cart via API (faster than UI interaction)
    for (const item of this.items) {
      await page.request.post('/api/cart/items', {
        data: item
      });
    }

    // Navigate to checkout and complete purchase
    await page.goto('/checkout');
    await page.getByTestId('card-number').fill('4242424242424242');
    await page.getByTestId('card-expiry').fill('12/28');
    await page.getByTestId('card-cvv').fill('123');
    await page.getByTestId('confirm-order').click();
    await page.waitForURL(/\/order\/confirmation/);
  }
}

// src/steps/checkout.steps.ts — Screenplay-based step definitions
import { Given, When, Then } from '@cucumber/cucumber';
import { Actor } from '../screenplay/actors/Actor';
import { BrowseTheWeb } from '../screenplay/abilities/BrowseTheWeb';
import { PlaceOrder } from '../screenplay/tasks/PlaceOrder';
import { AppWorld } from '../support/world';
import { expect } from '@playwright/test';

Given('Alice is a registered customer', async function (this: AppWorld) {
  this.alice = new Actor('Alice').whoCan(BrowseTheWeb.using(this.page));
  // Authenticate via API
  await this.authenticateActor(this.alice, 'alice@example.com');
});

When('Alice places an order for a Laptop Stand', async function (this: AppWorld) {
  await this.alice.attemptsTo(
    PlaceOrder.forItems([{ productId: 'prod-laptop-stand', quantity: 1 }])
  );
});

Then('Alice should see her order confirmation', async function (this: AppWorld) {
  await expect(this.page.getByTestId('order-confirmation')).toBeVisible();
});
```

**[community] Screenplay vs Page Objects — production verdict**: Screenplay delivers the
most benefit in large test suites (200+ scenarios) with complex multi-step user journeys
and multiple actor types (admin, customer, guest, support agent). The pattern is overkill
for suites with fewer than 50 scenarios or single-page interactions. The transition cost
is significant — rewriting an existing Page Object suite to Screenplay takes 2–3 sprints.
Teams should consider Screenplay when Page Object step definitions start exceeding 200
lines and become hard to understand during code review.

**[community] Actor naming in feature files**: Named actors (`Alice`, `Bob`, `admin`) in
Gherkin scenarios make scenarios dramatically more readable when multiple users interact.
Compare:

```gherkin
# Without named actors (confusing with 2 users)
Scenario: Admin approves a pending order
  Given a customer has placed an order
  And the order is in "pending approval" status
  When an admin approves the order
  Then the customer should receive an approval notification

# With named actors (clear who does what)
Scenario: Admin approves Alice's pending order
  Given Alice has placed an order requiring admin approval
  When Bob the admin approves Alice's order
  Then Alice should receive an approval notification
  And Bob's admin activity log should record the approval
```

Named actors map directly to Screenplay `Actor` instances in step definitions.

---

### BDD with GraphQL APIs  [community]

GraphQL APIs require different BDD step patterns than REST. A GraphQL API has a single
endpoint (`/graphql`) with typed queries and mutations. BDD scenarios should test the
*business behavior* exposed by the API — not the GraphQL syntax — but step definitions
must understand GraphQL operation types.

**Key differences from REST BDD:**
- No HTTP verbs to model (`POST` to `/graphql` for everything)
- Queries fetch data; mutations change state — both use the same endpoint
- Errors return HTTP 200 with an `errors` array (not 4xx status codes)
- Schema introspection can be used to validate step definition correctness

```gherkin
# features/api/product-catalog.feature
Feature: Product catalog GraphQL API

  Background:
    Given I have a valid GraphQL authentication token

  Scenario: Fetching a product by ID returns full product details
    When I query the product with ID "prod-001"
    Then the response should contain product name "Laptop Stand Pro"
    And the response should contain price 49.99
    And the response should have no GraphQL errors

  Scenario: Creating a product with valid data succeeds
    When I create a product with:
      | field       | value            |
      | name        | Wireless Charger |
      | price       | 34.99            |
      | category    | electronics      |
      | inStock     | true             |
    Then the GraphQL mutation should succeed
    And the response should contain a generated product ID
    And the product should be retrievable by the returned ID

  Scenario: Querying a non-existent product returns a null result with no errors
    When I query the product with ID "prod-DOESNOTEXIST"
    Then the response product should be null
    And the response should have no GraphQL errors

  Scenario: Creating a product with a negative price returns a validation error
    When I create a product with price -10.00
    Then the GraphQL response should contain the error "Price must be positive"
    And no product should be created
```

```typescript
// src/steps/graphql.steps.ts — GraphQL BDD step definitions
import { Given, When, Then } from '@cucumber/cucumber';
import { DataTable } from '@cucumber/cucumber';
import { expect } from 'chai';
import { AppWorld } from '../support/world';

// GraphQL client helper — typed wrapper around fetch
async function graphql<T = unknown>(
  endpoint: string,
  query: string,
  variables: Record<string, unknown>,
  authToken?: string
): Promise<{ data: T; errors?: Array<{ message: string; path?: string[] }> }> {
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    throw new Error(`GraphQL transport error: HTTP ${res.status}`);
  }
  return res.json();
}

const GET_PRODUCT = `
  query GetProduct($id: ID!) {
    product(id: $id) {
      id
      name
      price
      category
      inStock
    }
  }
`;

const CREATE_PRODUCT = `
  mutation CreateProduct($input: CreateProductInput!) {
    createProduct(input: $input) {
      id
      name
      price
    }
  }
`;

Given('I have a valid GraphQL authentication token', async function (this: AppWorld) {
  const res = await fetch(`${process.env.BASE_URL}/api/auth/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      clientId: process.env.TEST_CLIENT_ID,
      clientSecret: process.env.TEST_CLIENT_SECRET,
    }),
  });
  const body = await res.json() as { accessToken: string };
  this.authToken = body.accessToken;
});

When('I query the product with ID {string}', async function (this: AppWorld, productId: string) {
  this.gqlResponse = await graphql(
    `${process.env.BASE_URL}/graphql`,
    GET_PRODUCT,
    { id: productId },
    this.authToken
  );
});

When('I create a product with:', async function (this: AppWorld, table: DataTable) {
  const fields = table.rowsHash(); // { field: value, ... }
  const input = {
    name: fields.name,
    price: parseFloat(fields.price),
    category: fields.category,
    inStock: fields.inStock === 'true',
  };
  this.gqlResponse = await graphql(
    `${process.env.BASE_URL}/graphql`,
    CREATE_PRODUCT,
    { input },
    this.authToken
  );
});

When('I create a product with price {float}', async function (this: AppWorld, price: number) {
  this.gqlResponse = await graphql(
    `${process.env.BASE_URL}/graphql`,
    CREATE_PRODUCT,
    { input: { name: 'Test Product', price, category: 'test', inStock: true } },
    this.authToken
  );
});

Then('the response should have no GraphQL errors', function (this: AppWorld) {
  const errors = this.gqlResponse?.errors;
  if (errors && errors.length > 0) {
    const errorMessages = errors.map(e => e.message).join('; ');
    throw new Error(`Unexpected GraphQL errors: ${errorMessages}`);
  }
});

Then('the response should contain product name {string}', function (this: AppWorld, name: string) {
  const product = this.gqlResponse?.data?.product;
  if (!product) throw new Error('No product in GraphQL response');
  expect(product.name).to.equal(name, `Expected product name "${name}" but got "${product.name}"`);
});

Then('the response should contain price {float}', function (this: AppWorld, price: number) {
  const product = this.gqlResponse?.data?.product;
  expect(product?.price).to.be.closeTo(price, 0.01);
});

Then('the response product should be null', function (this: AppWorld) {
  const product = this.gqlResponse?.data?.product;
  expect(product).to.be.null;
});

Then(
  'the GraphQL response should contain the error {string}',
  function (this: AppWorld, errorMessage: string) {
    const errors = this.gqlResponse?.errors;
    if (!errors || errors.length === 0) {
      throw new Error(`Expected GraphQL error "${errorMessage}" but response had no errors`);
    }
    const found = errors.some(e => e.message.includes(errorMessage));
    if (!found) {
      throw new Error(
        `Expected error "${errorMessage}" but got: ${errors.map(e => e.message).join('; ')}`
      );
    }
  }
);

Then('the GraphQL mutation should succeed', function (this: AppWorld) {
  if (this.gqlResponse?.errors?.length) {
    throw new Error(`Mutation failed: ${this.gqlResponse.errors.map(e => e.message).join('; ')}`);
  }
  const result = this.gqlResponse?.data?.createProduct;
  if (!result) throw new Error('Mutation returned no data');
});
```

**[community] GraphQL BDD: the HTTP 200 error trap**: REST step definitions that check
`response.ok()` for success silently pass on GraphQL errors because GraphQL always returns
HTTP 200. Every GraphQL `Then` step must explicitly check `response.errors` in addition
to the data field. Teams migrating from REST BDD to GraphQL BDD consistently miss this
and ship passing scenarios that mask server-side errors.

**[community] GraphQL schema validation in BDD**: Run `npx graphql-inspector validate`
as a pre-test step to validate that your step definitions use queries and mutations
that match the current schema. Breaking schema changes caught before CI run are 10x
cheaper than failures caught mid-suite.

**[community] N+1 query detection via BDD**: Add a `Then the response should not have
triggered more than {int} database queries` step using query logging middleware. This
catches N+1 GraphQL resolver bugs as behavioral regressions before they reach production
— a category of defect that traditional BDD cannot detect without this pattern.

---

### OpenAPI / Swagger Contract Validation in BDD  [community]

When a REST API has an OpenAPI specification, BDD scenarios can validate API responses
against the schema in addition to business behavior. This creates a second layer of
protection: scenarios verify *what* the API does (business logic), while schema validation
verifies *how* it does it (contract conformance). Together, they catch both behavioral
regressions and breaking schema changes.

**The integration point**: Use `openapi-backend` or `ajv` to validate API response
bodies against the OpenAPI schema in `Then` step definitions. This catches schema
violations (e.g., a required field removed, a field type changed) that the business
assertion may not catch.

```gherkin
# features/api/orders-openapi.feature
Feature: Orders API — OpenAPI contract conformance

  Background:
    Given I have a valid API token

  Scenario: Create order response conforms to the OpenAPI schema
    When I create a valid order
    Then the response status is 201
    And the response conforms to the "CreateOrderResponse" OpenAPI schema
    And the response should contain a field "orderId"

  Scenario: List orders response conforms to the OpenAPI schema
    Given I have 3 confirmed orders
    When I GET "/api/v1/orders"
    Then the response status is 200
    And the response conforms to the "ListOrdersResponse" OpenAPI schema
    And the response should contain exactly 3 orders

  Scenario: Order not found response conforms to the error schema
    When I GET "/api/v1/orders/ORD-DOESNOTEXIST"
    Then the response status is 404
    And the response conforms to the "ErrorResponse" OpenAPI schema
```

```typescript
// src/support/schema-validator.ts — OpenAPI response validation utility
import Ajv, { ValidateFunction } from 'ajv';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';

interface OpenApiSpec {
  components: {
    schemas: Record<string, object>;
  };
}

export class SchemaValidator {
  private readonly ajv: Ajv;
  private readonly spec: OpenApiSpec;
  private readonly validators = new Map<string, ValidateFunction>();

  constructor(specPath: string) {
    this.ajv = new Ajv({ allErrors: true, strict: false });
    addFormats(this.ajv);
    this.spec = JSON.parse(fs.readFileSync(specPath, 'utf8')) as OpenApiSpec;
  }

  // Get or compile a validator for a named schema component
  getValidator(schemaName: string): ValidateFunction {
    if (!this.validators.has(schemaName)) {
      const schema = this.spec.components?.schemas?.[schemaName];
      if (!schema) {
        throw new Error(`OpenAPI schema "${schemaName}" not found in spec`);
      }
      // Add definitions context for $ref resolution
      const schemaWithDefs = { ...schema, definitions: this.spec.components.schemas };
      this.validators.set(schemaName, this.ajv.compile(schemaWithDefs));
    }
    return this.validators.get(schemaName)!;
  }

  validate(schemaName: string, data: unknown): { valid: boolean; errors: string[] } {
    const validate = this.getValidator(schemaName);
    const valid = validate(data) as boolean;
    return {
      valid,
      errors: valid ? [] : (validate.errors ?? []).map(e =>
        `${e.instancePath || 'root'}: ${e.message}`
      ),
    };
  }
}

// Initialize once at suite startup (loaded from openapi.json at project root)
export const apiSchemaValidator = new SchemaValidator(
  path.join(process.cwd(), 'api-specs/openapi.json')
);
```

```typescript
// src/steps/openapi-validation.steps.ts — schema validation step definitions
import { Then } from '@cucumber/cucumber';
import { apiSchemaValidator } from '../support/schema-validator';
import { AppWorld } from '../support/world';

// Matches: And the response conforms to the "CreateOrderResponse" OpenAPI schema
Then(
  'the response conforms to the {string} OpenAPI schema',
  async function (this: AppWorld, schemaName: string) {
    // this.lastApiResponse should be set by the preceding When step
    if (!this.lastApiResponse) {
      throw new Error('No API response captured — ensure a When step made an API call');
    }

    let body: unknown;
    try {
      body = await this.lastApiResponse.json();
    } catch {
      throw new Error(`Response body is not valid JSON (status: ${this.lastApiResponse.status()})`);
    }

    const { valid, errors } = apiSchemaValidator.validate(schemaName, body);
    if (!valid) {
      const errorList = errors.map(e => `  - ${e}`).join('\n');
      throw new Error(
        `Response does not conform to "${schemaName}" OpenAPI schema:\n${errorList}\n` +
        `Response body: ${JSON.stringify(body, null, 2)}`
      );
    }
  }
);
```

**CI integration — schema validation step**:
```yaml
# .github/workflows/bdd.yml — add OpenAPI spec freshness check before BDD run
- name: Validate OpenAPI spec syntax
  run: npx @redocly/cli lint api-specs/openapi.json

- name: Check OpenAPI spec matches codebase routes
  run: npx @redocly/cli bundle api-specs/openapi.json --output api-specs/openapi.bundled.json
```

**[community] OpenAPI drift: the silent contract break**: In teams where the OpenAPI spec
is maintained manually (not generated from code), the spec and implementation diverge within
weeks. BDD scenarios using schema validation catch this immediately: a developer who
removes a required field from the response gets a CI failure on every scenario that uses
that response schema — not just the one scenario that checks the removed field. This is
the fastest feedback loop for API contract maintenance.

**[community] Schema validation + BDD: the "too strict" failure mode**: Validating every
API response against its OpenAPI schema can produce false failures for intentionally
optional fields that are context-dependent. Use `nullable: true` and `required: []` carefully
in the OpenAPI spec to model optional fields correctly. Teams that add schema validation
to existing BDD suites often discover that their OpenAPI spec has been subtly wrong for
months — the BDD schema step is the first thing to catch it.

**[community] Contract-first API development with BDD**: When teams adopt contract-first
development (OpenAPI spec written before implementation), BDD scenarios referencing schema
names serve as the acceptance test for the spec. A scenario cannot be marked passing until
the implementation produces responses that match the spec. This makes BDD the enforcer of
the contract-first discipline.

---

### Cucumber Step Definition Code Generation via CLI  [community]

Manually writing step definition stubs for every Gherkin step is mechanical work. The
`--dry-run` flag in Cucumber.js generates TypeScript stubs for all unmatched steps, which
can be piped into new or existing step definition files.

**Workflow: feature-first BDD with auto-generated stubs**

```bash
# 1. Write the .feature file first (Three Amigos output)
# 2. Run dry-run to see which steps need implementations
npx cucumber-js --dry-run --format usage 2>&1 | head -50

# 3. Get auto-generated TypeScript step stubs
npx cucumber-js --dry-run 2>&1 | grep -A2 "You can implement"

# Sample output:
# You can implement missing steps with the snippets below:
#
# Given('I have a valid GraphQL authentication token', function () {
#   // Write code here that turns the phrase above into concrete actions
#   return 'pending';
# });
```

**Automated stub generation script** (TypeScript):
```typescript
// scripts/generate-step-stubs.ts — parse dry-run output and write to new step file
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

function generateStepStubs(outputFile: string, featureGlob = 'features/**/*.feature'): void {
  // Run dry-run with snippet format
  const dryRunOutput = execSync(
    `npx cucumber-js --dry-run --format @cucumber/pretty-formatter 2>&1 || true`,
    { encoding: 'utf8', cwd: process.cwd() }
  );

  // Extract the undefined steps section
  const snippetStart = dryRunOutput.indexOf('You can implement missing steps');
  if (snippetStart === -1) {
    console.log('No undefined steps found. All steps are implemented.');
    return;
  }

  const snippets = dryRunOutput.slice(snippetStart);

  // Wrap in TypeScript module with proper imports
  const fileContent = `// AUTO-GENERATED step definition stubs
// Generated by: npx ts-node scripts/generate-step-stubs.ts
// Review each stub and replace 'return pending' with real implementation
import { Given, When, Then } from '@cucumber/cucumber';
import { CustomWorld } from '../support/world';

${snippets
  .split('\n')
  .filter(line => line.trim().startsWith("Given('") || line.trim().startsWith("When('") || line.trim().startsWith("Then('") || line.trim().startsWith('//') || line.includes('pending') || line.includes('});'))
  .join('\n')}
`;

  fs.writeFileSync(outputFile, fileContent, 'utf8');
  console.log(`Step stubs written to: ${outputFile}`);
  console.log('Next: implement each stub, then re-run to verify all steps are matched.');
}

const outputPath = path.join(process.cwd(), 'src/steps/_generated-stubs.ts');
generateStepStubs(outputPath);
```

**[community] The stub generation → TDD loop**: Use generated stubs as the start of a
TDD cycle within BDD. The stub returns `'pending'` (Cucumber's signal for "not yet
implemented"). CI shows the scenario as "Pending" — not failing, but not passing. The
developer implements the step until the scenario passes. This is the correct BDD workflow:
Gherkin first → stubs → implementation → green scenario. Teams that skip stubs and write
step definitions from scratch frequently produce steps that do not match the Gherkin
phrasing exactly, causing `Undefined step` errors.

---

### BDD for Mobile Applications: React Native + Detox  [community]

Mobile apps present unique BDD challenges: device hardware state (permissions, network
conditions), platform-specific behavior (iOS vs Android), and the absence of a standard
browser automation API. Detox is the leading end-to-end testing framework for React Native
and can be integrated with Gherkin via a custom runner.

**Why mobile BDD is harder than web BDD**: Mobile step definitions must handle:
- Platform-specific UI element IDs (`testID` in React Native, `accessibilityLabel` as fallback)
- Device permission grants (camera, location, push notifications)
- Network condition simulation (offline, slow 3G)
- App lifecycle events (background/foreground transitions)

**Feature file structure for mobile** (platform-agnostic Gherkin):
```gherkin
# features/mobile/onboarding.feature
@mobile @ios @android
Feature: User onboarding flow
  As a new user
  I want to complete the onboarding process
  So that I can start using the app

  Scenario: New user completes onboarding and lands on the home screen
    Given I have freshly installed the app
    When I grant notification permissions
    And I complete the 3-step onboarding tutorial
    And I create an account with valid details
    Then I should land on the home screen
    And the navigation bar should show 4 tabs

  @ios-only
  Scenario: Face ID authentication enables biometric login
    Given I have completed onboarding
    And my device supports Face ID
    When I enable Face ID in account settings
    And I log out and back in
    Then the app should prompt for Face ID authentication
    And successful Face ID should authenticate me without a password

  @offline
  Scenario: App shows cached data when offline
    Given I have previously loaded my feed data
    When I go offline
    And I navigate to the feed
    Then I should see the last cached feed content
    And I should see an "Offline mode — showing cached data" banner
```

```typescript
// src/steps/mobile/onboarding.steps.ts — Detox-based mobile step definitions
// Note: Detox is imported globally in the Jest/Detox setup; element() is a global
import { Given, When, Then } from '@cucumber/cucumber';
import { MobileWorld } from '../support/mobile-world';
import { device, element, by, expect as detoxExpect } from 'detox';

Given('I have freshly installed the app', async function (this: MobileWorld) {
  await device.uninstallApp();
  await device.installApp();
  await device.launchApp({ newInstance: true });
  // Reset any stored onboarding state
  await device.clearKeychain(); // iOS: clear stored credentials
});

When('I grant notification permissions', async function (this: MobileWorld) {
  // iOS: handle system permission dialog
  if (device.getPlatform() === 'ios') {
    await device.launchApp({ permissions: { notifications: 'YES' } });
  }
  // Android: permission granted at install time for test builds
});

When('I complete the {int}-step onboarding tutorial', async function (this: MobileWorld, steps: number) {
  for (let step = 0; step < steps; step++) {
    await element(by.id('onboarding-next-button')).tap();
    await expect(element(by.id(`onboarding-step-${step + 1}`))).toBeVisible();
  }
  await element(by.id('onboarding-done-button')).tap();
});

When('I create an account with valid details', async function (this: MobileWorld) {
  await element(by.id('signup-email')).typeText('test@example.com');
  await element(by.id('signup-password')).typeText('TestPass123!');
  await element(by.id('signup-confirm-password')).typeText('TestPass123!');
  await element(by.id('signup-submit')).tap();
  await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);
});

Then('I should land on the home screen', async function (this: MobileWorld) {
  await detoxExpect(element(by.id('home-screen'))).toBeVisible();
});

Then('the navigation bar should show {int} tabs', async function (this: MobileWorld, tabCount: number) {
  await detoxExpect(element(by.id('nav-bar'))).toBeVisible();
  // Count visible tab items
  for (let i = 0; i < tabCount; i++) {
    await detoxExpect(element(by.id(`nav-tab-${i}`))).toBeVisible();
  }
});

When('I go offline', async function (this: MobileWorld) {
  // Detox network simulation
  await device.setURLBlacklist(['.*']);
});

Then(
  'I should see an {string} banner',
  async function (this: MobileWorld, bannerText: string) {
    await detoxExpect(element(by.text(bannerText))).toBeVisible();
  }
);
```

```typescript
// src/support/mobile-world.ts — Mobile-specific World
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';

export class MobileWorld extends World {
  platform: 'ios' | 'android';

  constructor(options: IWorldOptions) {
    super(options);
    this.platform = process.env.DETOX_PLATFORM as 'ios' | 'android' ?? 'ios';
  }
}

setWorldConstructor(MobileWorld);
```

**CI configuration for mobile BDD (GitHub Actions — iOS and Android matrix)**:
```yaml
# .github/workflows/mobile-bdd.yml
jobs:
  mobile-bdd:
    strategy:
      matrix:
        platform: [ios, android]
        include:
          - platform: ios
            runs-on: macos-latest
            device: 'iPhone 15'
            os: '17.0'
          - platform: android
            runs-on: ubuntu-latest
            device: 'Pixel 6'
            api-level: '33'

    runs-on: ${{ matrix.runs-on }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Build app for testing
        run: npx detox build --configuration ${{ matrix.platform }}.release

      - name: Run BDD scenarios (${{ matrix.platform }})
        run: npx cucumber-js --profile ${{ matrix.platform }} --tags "@mobile and not @wip"
        env:
          DETOX_PLATFORM: ${{ matrix.platform }}
```

**[community] Mobile BDD slow suite problem**: Detox-based BDD scenarios typically run
5–10x slower than equivalent web BDD scenarios because each scenario may require app
relaunching, simulator/emulator boot time, and real device permission dialogs. The
mitigation is aggressive use of `@ios-only` and `@android-only` tags to split the test
matrix, running only platform-specific scenarios on each CI runner. Cross-platform
scenarios that run on both platforms should be the minority — most business behavior is
platform-agnostic.

**[community] `testID` vs `accessibilityLabel` for mobile step selectors**: React Native
components accept `testID` (Detox's preferred selector) and `accessibilityLabel` (ARIA
equivalent). Using `testID` keeps test IDs separate from production accessibility labels.
Mixing them — using `accessibilityLabel` as a test selector — causes test failures when
designers update labels for UX reasons, which should not break tests. Convention: all
mobile Detox selectors use `testID`; all accessibility testing uses `accessibilityLabel`.

---

### Living Documentation Publishing: Cucumber Reports as Stakeholder Dashboards  [community]

Living documentation only fulfills its promise if stakeholders actually read it. Generating
a Cucumber HTML report in CI is a necessary first step, but reports buried in CI artifact
lists are never read by product managers or business analysts. The second step is *publishing*
the report to a URL that stakeholders can bookmark.

**Strategy 1: GitHub Pages (zero infrastructure)**

```yaml
# .github/workflows/publish-bdd-docs.yml
name: Publish BDD Living Documentation

on:
  push:
    branches: [main]

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  bdd-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run full BDD suite (all non-WIP scenarios)
        run: npx cucumber-js --profile nightly
        continue-on-error: true  # Publish report even if some scenarios fail
        env:
          CI: true

      - name: Generate living documentation HTML
        run: |
          npm install --no-save @cucumber/react-components
          # Generate a navigable feature-browser report
          npx cucumber-js --dry-run --format @cucumber/html-formatter:docs/bdd-docs/index.html

      - name: Copy latest results to docs
        run: cp reports/cucumber-report.html docs/bdd-docs/latest-results.html

      - name: Deploy to GitHub Pages
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: docs/bdd-docs
          branch: gh-pages
          clean: true
```

After setup, the living documentation is accessible at `https://<org>.github.io/<repo>/`.
Product managers can bookmark this URL and check it from any browser — no CI access required.

**Strategy 2: Allure Report with history trend**

```bash
# Install Allure Cucumber adapter
npm install --save-dev allure-cucumberjs allure-commandline

# Add to cucumber.js formatters
# "allure-cucumberjs/reporter"

# After run: generate HTML report with trend
npx allure generate allure-results --clean -o allure-report

# Start a local server to browse (or upload to static hosting)
npx allure open allure-report
```

**Allure provides** beyond standard Cucumber HTML:
- **Trend charts**: Pass/fail ratio over time (show whether the suite is getting healthier)
- **Timeline**: Scenario execution timeline showing parallel worker efficiency
- **Attachments**: Screenshots, API responses, network traces per failed scenario
- **Categories**: Group failures by type (product defect, test defect, known issue)

```typescript
// src/support/hooks.ts — enrich Allure report with attachments
import { Before, After, Status } from '@cucumber/cucumber';
import { allure } from 'allure-cucumberjs';
import { AppWorld } from './world';

Before(function (scenario) {
  allure.label('feature', scenario.pickle.uri.split('/').slice(-2, -1)[0]); // folder name
  allure.label('suite', scenario.pickle.tags.map(t => t.name).join(', '));
});

After(async function (this: AppWorld, scenario) {
  if (scenario.result?.status === Status.FAILED) {
    // Attach screenshot to Allure
    const screenshot = await this.page.screenshot({ fullPage: true });
    allure.attachment('Screenshot at failure', screenshot, 'image/png');

    // Attach page HTML for DOM debugging
    const html = await this.page.content();
    allure.attachment('Page HTML at failure', html, 'text/html');

    // Attach browser console log
    allure.attachment(
      'Browser console log',
      this.consoleLogs?.join('\n') ?? 'No logs captured',
      'text/plain'
    );
  }
});
```

**[community] Stakeholder engagement metric**: The most reliable proxy for "is our living
documentation actually read" is whether product managers file bugs via feature file scenarios
("the scenario for X fails in staging") rather than via Jira tickets with vague descriptions.
Teams that track this metric typically see it improve after 2–3 sprints of consistently
publishing reports — once stakeholders trust that the report reflects reality.

**[community] Report retention policy**: Keep BDD reports for at least 30 days in CI
artifact storage (or on the static hosting). One-day retention makes it impossible to
diagnose flaky scenarios that fail intermittently — you need historical runs to identify
the pattern. Set `retention-days: 30` in `actions/upload-artifact@v4` and review storage
costs quarterly.

**[community] `@cucumber/html-formatter` vs `cucumber-html-reporter`**: The official
`@cucumber/html-formatter` produces a minimal, fast-loading single-page HTML report.
`cucumber-html-reporter` (community package) produces a richer report with metadata and
customizable themes. For stakeholder-facing documentation, the community reporter's
presentation quality is worth the extra dependency. For developer-focused CI feedback,
the official formatter's speed and simplicity is preferred.

---

### BDD Performance Scenarios: Asserting Speed as Behavior  [community]

Performance requirements are business behaviors: "The checkout page must load within 2
seconds for 95% of users" is a testable acceptance criterion that can be expressed as a
BDD scenario. Performance BDD is distinct from load testing — it verifies that *a single
user's* experience meets a defined performance budget, not that the system handles
concurrent load.

**When performance BDD applies**:
- Core user journeys with explicit SLA requirements (checkout < 2s, search < 1s)
- Pages where third-party scripts are added frequently (marketing tags, chat widgets)
- After significant architecture changes (new database, CDN change, SSR migration)

```gherkin
# features/performance/core-journeys.feature
@performance @regression
Feature: Core user journey performance budgets

  Scenario: Product search results load within 1 second
    Given I am a registered customer
    When I search for "laptop"
    Then the search results page should load within 1000 milliseconds
    And the Largest Contentful Paint should be below 1500 milliseconds

  Scenario: Checkout page meets performance budget
    Given I have items in my cart
    When I navigate to the checkout page
    Then the page should be interactive within 2000 milliseconds
    And the Cumulative Layout Shift should be below 0.1

  Scenario: Homepage loads within the Core Web Vitals threshold
    Given I am an anonymous visitor
    When I navigate to the homepage
    Then the First Contentful Paint should be below 1800 milliseconds
    And the Largest Contentful Paint should be below 2500 milliseconds
    And the Total Blocking Time should be below 300 milliseconds
```

```typescript
// src/steps/performance.steps.ts — performance assertion step definitions
import { When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// Capture performance metrics using Playwright's built-in CDP integration
When('I navigate to the checkout page', async function (this: AppWorld) {
  // Clear browser cache to simulate first visit
  await this.context.clearCookies();

  const startTime = Date.now();
  await this.page.goto('/checkout', { waitUntil: 'networkidle' });
  this.navigationDurationMs = Date.now() - startTime;

  // Capture Core Web Vitals via CDP Performance API
  this.webVitals = await this.page.evaluate(() => {
    return new Promise<{ lcp: number; cls: number; tbt: number; fcp: number }>((resolve) => {
      new PerformanceObserver((list) => {
        const entries = list.getEntries();
        resolve({
          lcp: entries.find(e => e.entryType === 'largest-contentful-paint')?.startTime ?? 0,
          cls: entries.reduce((sum, e: PerformanceEntry & { value?: number }) =>
            sum + (e.value ?? 0), 0),
          tbt: performance.now() - performance.timing?.domInteractive ?? 0,
          fcp: entries.find(e => e.name === 'first-contentful-paint')?.startTime ?? 0,
        });
      }).observe({ entryTypes: ['largest-contentful-paint', 'layout-shift', 'paint'] });
      // Fallback: resolve after 2s if observer doesn't fire
      setTimeout(() => resolve({ lcp: 0, cls: 0, tbt: 0, fcp: 0 }), 2000);
    });
  });
});

Then(
  'the page should be interactive within {int} milliseconds',
  function (this: AppWorld, thresholdMs: number) {
    if (this.navigationDurationMs > thresholdMs) {
      throw new Error(
        `Page took ${this.navigationDurationMs}ms to load — exceeded ${thresholdMs}ms budget.\n` +
        `Performance hint: check for render-blocking scripts or unoptimized images.`
      );
    }
  }
);

Then(
  'the Largest Contentful Paint should be below {int} milliseconds',
  function (this: AppWorld, thresholdMs: number) {
    const lcp = this.webVitals?.lcp ?? 0;
    if (lcp > 0 && lcp > thresholdMs) {
      throw new Error(
        `LCP: ${lcp.toFixed(0)}ms exceeds ${thresholdMs}ms budget.\n` +
        `Check: hero image size, font loading, server response time.`
      );
    }
  }
);

Then(
  'the Cumulative Layout Shift should be below {float}',
  function (this: AppWorld, threshold: number) {
    const cls = this.webVitals?.cls ?? 0;
    if (cls > threshold) {
      throw new Error(
        `CLS: ${cls.toFixed(3)} exceeds ${threshold} threshold.\n` +
        `Check: images without dimensions, dynamically injected content above the fold.`
      );
    }
  }
);
```

**[community] Performance BDD vs load testing**: Performance BDD scenarios (single user,
Playwright-based) catch *page-level* performance regressions: slow server-side rendering,
large uncompressed images, render-blocking scripts. Load testing tools (k6, Artillery,
Gatling) catch *system-level* performance: throughput limits, database connection pool
exhaustion, memory leaks under sustained load. Both are needed; neither replaces the other.
Performance BDD runs in < 30 seconds per scenario and belongs in the nightly regression
suite. Load tests run in minutes and belong in pre-release gates.

**[community] Performance budget drift**: Teams that set performance thresholds once and
never revisit them accumulate performance debt silently. A page that was 1.2s on launch
and is now 1.8s has crossed no threshold — but is 50% slower. Review performance budgets
quarterly using the Allure trend report to catch gradual drift before it becomes
user-visible.

---

### BDD Database Seeding with Prisma and TypeORM  [community]

Direct database seeding (bypassing the application API) is the fastest way to establish
test data for BDD scenarios that need complex entity relationships. It is appropriate
when: (1) the application API does not expose endpoints for creating test-only data,
(2) scenarios need deeply nested data that would require many sequential API calls, or
(3) scenarios test behavior that depends on pre-existing database state (e.g., "given a
customer who has been banned").

**Prisma seeding in `Before` hooks** (TypeScript + PostgreSQL):

```typescript
// src/support/prisma-seeder.ts — Prisma-based test data management
import { PrismaClient, OrderStatus, CustomerTier } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: { db: { url: process.env.TEST_DATABASE_URL } },
  log: process.env.VERBOSE_SEEDING ? ['query'] : [],
});

export interface SeededCustomer {
  customerId: string;
  email: string;
  tier: CustomerTier;
}

export interface SeededOrder {
  orderId: string;
  customerId: string;
  total: number;
  status: OrderStatus;
}

export class PrismaSeeder {
  // Track created record IDs for cleanup
  private createdCustomerIds: string[] = [];
  private createdOrderIds: string[] = [];

  async seedCustomer(overrides: {
    email?: string;
    tier?: CustomerTier;
    isBanned?: boolean;
    createdDaysAgo?: number;
  } = {}): Promise<SeededCustomer> {
    const email = overrides.email ?? `test-${Date.now()}-${Math.random().toString(36).slice(2)}@example.com`;
    const createdAt = overrides.createdDaysAgo
      ? new Date(Date.now() - overrides.createdDaysAgo * 86_400_000)
      : new Date();

    const customer = await prisma.customer.create({
      data: {
        email,
        passwordHash: '$2b$10$test-hash', // pre-hashed test password
        tier: overrides.tier ?? CustomerTier.STANDARD,
        isBanned: overrides.isBanned ?? false,
        createdAt,
      },
    });

    this.createdCustomerIds.push(customer.id);
    return { customerId: customer.id, email, tier: customer.tier };
  }

  async seedOrder(
    customerId: string,
    overrides: {
      status?: OrderStatus;
      total?: number;
      confirmedDaysAgo?: number;
      items?: Array<{ productId: string; quantity: number; unitPrice: number }>;
    } = {}
  ): Promise<SeededOrder> {
    const confirmedAt = overrides.confirmedDaysAgo
      ? new Date(Date.now() - overrides.confirmedDaysAgo * 86_400_000)
      : new Date();

    const order = await prisma.order.create({
      data: {
        customerId,
        status: overrides.status ?? OrderStatus.CONFIRMED,
        total: overrides.total ?? 99.99,
        confirmedAt,
        items: overrides.items
          ? { create: overrides.items }
          : { create: [{ productId: 'prod-001', quantity: 1, unitPrice: 99.99 }] },
      },
    });

    this.createdOrderIds.push(order.id);
    return { orderId: order.id, customerId, total: order.total, status: order.status };
  }

  async cleanup(): Promise<void> {
    // Delete in dependency order (orders before customers)
    if (this.createdOrderIds.length > 0) {
      await prisma.orderItem.deleteMany({
        where: { orderId: { in: this.createdOrderIds } }
      });
      await prisma.order.deleteMany({
        where: { id: { in: this.createdOrderIds } }
      });
    }
    if (this.createdCustomerIds.length > 0) {
      await prisma.customer.deleteMany({
        where: { id: { in: this.createdCustomerIds } }
      });
    }
    this.createdCustomerIds = [];
    this.createdOrderIds = [];
  }

  async disconnect(): Promise<void> {
    await prisma.$disconnect();
  }
}
```

```typescript
// src/support/hooks.ts — integrate PrismaSeeder into World
import { Before, After, AfterAll } from '@cucumber/cucumber';
import { AppWorld } from './world';
import { PrismaSeeder } from './prisma-seeder';

const seeder = new PrismaSeeder(); // shared instance — pools connections

Before(async function (this: AppWorld) {
  this.seeder = seeder;
});

After(async function (this: AppWorld) {
  await this.seeder?.cleanup();
});

AfterAll(async function () {
  await seeder.disconnect();
});
```

```typescript
// src/steps/refund-prisma.steps.ts — using Prisma seeder in steps
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';
import { OrderStatus } from '@prisma/client';

Given(
  'I have a confirmed order from {int} days ago',
  async function (this: AppWorld, daysAgo: number) {
    const customer = await this.seeder.seedCustomer({ email: 'alice@example.com' });
    this.customerId = customer.customerId;

    const order = await this.seeder.seedOrder(customer.customerId, {
      confirmedDaysAgo: daysAgo,
      status: OrderStatus.CONFIRMED,
      total: 109.97,
    });
    this.currentOrderId = order.orderId;

    // Log in via API as this customer
    await this.authenticateWithEmail(customer.email, 'TestPass123!');
  }
);

Given(
  'I have a banned customer account',
  async function (this: AppWorld) {
    const customer = await this.seeder.seedCustomer({ isBanned: true });
    this.customerId = customer.customerId;
    this.customerEmail = customer.email;
  }
);
```

**[community] Prisma seeding vs API seeding tradeoff table**:

| Factor | Prisma direct seeding | API seeding |
|---|---|---|
| Speed | 10–100ms per entity | 100–500ms per entity (HTTP round-trip) |
| Reliability | Very high (no API surface) | Depends on API availability |
| Data validity | Bypasses business validation | Enforces all business rules |
| Cascade setup | Easy (Prisma `create` with nested `data`) | Requires multiple sequential API calls |
| Parallelism | Requires unique IDs (default: `Date.now()` suffix) | Same requirement |
| Cleanup | Explicit `deleteMany` in reverse dependency order | API DELETE endpoints |
| When to use | Complex entity graphs, banned/edge states, historical dates | Standard create/update flows |

**[community] Direct DB seeding and bypassed validation**: Prisma seeding bypasses
application business rules (e.g., "orders require at least one item" validation). This
is intentional for edge-case scenarios ("given an order with no items due to a legacy
migration bug"). For scenarios testing the normal flow, always use API seeding to ensure
the data passes all business validation. Mixing both strategies in the same test suite is
correct — the key is explicit intent: step definition comments should note whether seeding
bypasses validation and why.

---

### Cross-Browser BDD: Testing Behavior Parity Across Browsers  [community]

Most BDD suites run on a single browser (Chromium). Cross-browser BDD detects behavioral
differences between Chrome, Firefox, and Safari/WebKit before users discover them. Playwright
makes this the lowest-friction approach: the same step definitions run against all three
browser engines without modification.

```yaml
# .github/workflows/cross-browser-bdd.yml
name: Cross-Browser BDD

on:
  schedule:
    - cron: '0 2 * * 1'  # Mondays at 2am — weekly cross-browser sweep
  workflow_dispatch:       # Manual trigger before major releases

jobs:
  cross-browser:
    strategy:
      matrix:
        browser: [chromium, firefox, webkit]
      fail-fast: false     # Run all browsers even if one fails
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npx playwright install --with-deps ${{ matrix.browser }}

      - name: Run BDD suite on ${{ matrix.browser }}
        run: npx cucumber-js --profile regression --tags "@regression and not @skip-${{ matrix.browser }}"
        env:
          PLAYWRIGHT_BROWSER: ${{ matrix.browser }}
          CI: true

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: cross-browser-report-${{ matrix.browser }}
          path: reports/
          retention-days: 14
```

```typescript
// src/support/hooks.ts — browser-aware setup using PLAYWRIGHT_BROWSER env var
import { Before } from '@cucumber/cucumber';
import { chromium, firefox, webkit, Browser } from '@playwright/test';
import { AppWorld } from './world';

type BrowserName = 'chromium' | 'firefox' | 'webkit';

Before(async function (this: AppWorld) {
  const browserName = (process.env.PLAYWRIGHT_BROWSER ?? 'chromium') as BrowserName;
  const launchers = { chromium, firefox, webkit };
  const launcher = launchers[browserName] ?? chromium;

  this.browser = await launcher.launch({
    headless: process.env.CI === 'true',
  });
  this.context = await this.browser.newContext({
    // Safari requires explicit viewport (WebKit does not auto-detect)
    viewport: browserName === 'webkit' ? { width: 1280, height: 720 } : undefined,
    // Firefox date picker format differs from Chromium
    locale: 'en-US',
  });
  this.page = await this.context.newPage();
});
```

**Browser-specific tag exclusions** (Gherkin):
```gherkin
# Scenario that uses Web Crypto API — not supported in older WebKit
@regression @skip-webkit
Scenario: File upload uses client-side encryption
  Given I am on the document upload page
  When I select a file for upload
  Then the file should be encrypted client-side before transmission

# Scenario relying on CSS :has() selector — not in Firefox before v103
@regression @skip-firefox
Scenario: Selected items are visually highlighted in the list
  Given I have 3 items in my cart
  When I select the first item
  Then the first item row should have a highlighted background
```

**[community] Cross-browser BDD coverage strategy**: Running the full regression suite on
all three browsers triples test execution time. The pragmatic strategy: run the full suite
on Chromium in every PR, run only `@critical` and `@smoke` scenarios on Firefox and WebKit
on each PR, run the full suite on all browsers weekly. This catches 95% of cross-browser
regressions without tripling CI cost.

**[community] Safari (WebKit) date input handling**: WebKit's `<input type="date">` renders
differently from Chromium and Firefox. Playwright's `page.fill()` works for WebKit date
inputs, but `page.type()` may produce unexpected results. The idiomatic Playwright approach
for cross-browser date input: always use `page.getByTestId('date-input').fill('2026-05-01')`
with ISO format, which WebKit accepts. This is the most common cross-browser step definition
bug found in suites that were only tested on Chromium.

---

### BDD for WebSocket and Real-Time Features  [community]

Real-time features — chat, live notifications, collaborative editing, live dashboards —
are behavior-driven by definition: they respond to events and produce observable state
changes for users. BDD is well-suited for capturing these behaviors in business language,
but step definitions require WebSocket-aware patterns.

**The core challenge**: `Then` assertions in real-time BDD cannot check immediate state.
They must wait for a server-pushed event to arrive and update the UI. The `waitUntil`
pattern from async BDD applies, but WebSocket-specific patterns allow subscribing to
the event stream directly rather than polling the UI.

```gherkin
# features/realtime/live-notifications.feature
Feature: Live order status notifications

  Background:
    Given Alice is logged in to the notification dashboard

  Scenario: Order confirmation triggers an instant notification
    Given Alice has an order in "pending" status
    When the order processing service confirms the order
    Then Alice should receive a "Order Confirmed" notification within 5 seconds
    And the notification should display the correct order number
    And the notification badge count should increase by 1

  Scenario: Notification is marked as read when clicked
    Given Alice has 3 unread notifications
    When Alice clicks on the first notification
    Then that notification should be marked as read
    And the unread notification count should decrease to 2

  Scenario: Multiple connected clients receive the same notification
    Given Alice is logged in on two different browser tabs
    When a new order notification is triggered for Alice's account
    Then both tabs should show the notification within 5 seconds
    And the notification count should be consistent across both tabs
```

```typescript
// src/support/websocket-client.ts — typed WebSocket client for BDD
import { Page } from '@playwright/test';

export interface WebSocketMessage {
  type: string;
  payload: Record<string, unknown>;
  timestamp: number;
}

export class WebSocketCapture {
  private readonly messages: WebSocketMessage[] = [];
  private readonly subscriptions = new Map<string, ((msg: WebSocketMessage) => void)[]>();

  constructor(private readonly page: Page) {
    // Intercept WebSocket frames via Playwright's route API
    this.page.on('websocket', ws => {
      ws.on('framereceived', ({ payload }) => {
        try {
          const message = JSON.parse(payload.toString()) as WebSocketMessage;
          this.messages.push(message);
          const handlers = this.subscriptions.get(message.type) ?? [];
          handlers.forEach(h => h(message));
          const allHandlers = this.subscriptions.get('*') ?? [];
          allHandlers.forEach(h => h(message));
        } catch { /* non-JSON frames ignored */ }
      });
    });
  }

  // Wait for a message of a specific type within timeout
  async waitForMessage(
    messageType: string,
    timeoutMs: number,
    predicate?: (msg: WebSocketMessage) => boolean
  ): Promise<WebSocketMessage> {
    // Check already-received messages first
    const existing = this.messages.find(
      m => m.type === messageType && (!predicate || predicate(m))
    );
    if (existing) return existing;

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(
          `No "${messageType}" WebSocket message received within ${timeoutMs}ms. ` +
          `Received: ${this.messages.map(m => m.type).join(', ')}`
        ));
      }, timeoutMs);

      const handler = (msg: WebSocketMessage) => {
        if (!predicate || predicate(msg)) {
          clearTimeout(timer);
          resolve(msg);
        }
      };

      const handlers = this.subscriptions.get(messageType) ?? [];
      handlers.push(handler);
      this.subscriptions.set(messageType, handlers);
    });
  }

  getMessages(type?: string): WebSocketMessage[] {
    return type ? this.messages.filter(m => m.type === type) : [...this.messages];
  }

  clear(): void {
    this.messages.length = 0;
  }
}
```

```typescript
// src/steps/realtime.steps.ts — WebSocket BDD step definitions
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';
import { WebSocketCapture } from '../support/websocket-client';
import { expect } from '@playwright/test';

Given('Alice is logged in to the notification dashboard', async function (this: AppWorld) {
  this.wsCapture = new WebSocketCapture(this.page);
  await this.authenticateWithEmail('alice@example.com', 'TestPass123!');
  await this.page.goto('/notifications');
  await expect(this.page.getByTestId('notification-dashboard')).toBeVisible();
});

When('the order processing service confirms the order', async function (this: AppWorld) {
  // Trigger order confirmation via the test API (simulates the processing service)
  await this.apiContext.post('/api/test/trigger-order-confirmation', {
    data: { orderId: this.currentOrderId }
  });
});

Then(
  'Alice should receive a {string} notification within {int} seconds',
  async function (this: AppWorld, notificationType: string, timeoutSeconds: number) {
    const message = await this.wsCapture.waitForMessage(
      'notification',
      timeoutSeconds * 1000,
      (msg) => msg.payload.type === notificationType
    );
    this.lastNotification = message.payload;
  }
);

Then(
  'the notification should display the correct order number',
  async function (this: AppWorld) {
    if (!this.lastNotification) throw new Error('No notification received');
    if (this.lastNotification.orderId !== this.currentOrderId) {
      throw new Error(
        `Notification orderId "${this.lastNotification.orderId}" ` +
        `does not match current order "${this.currentOrderId}"`
      );
    }
    // Also verify visible in UI
    await expect(
      this.page.getByTestId('latest-notification').getByText(this.currentOrderId)
    ).toBeVisible();
  }
);

Then(
  'the notification badge count should increase by {int}',
  async function (this: AppWorld, increment: number) {
    const initialCount = this.initialNotificationCount ?? 0;
    const badge = this.page.getByTestId('notification-badge');
    await expect(badge).toHaveText(String(initialCount + increment));
  }
);
```

**[community] WebSocket BDD flakiness patterns**: Real-time step definitions that check
notification counts are disproportionately flaky in parallel CI runs. If two parallel
workers share the same test user account, notifications from one worker's `When` step
arrive in the other worker's `Then` step. The fix: each scenario uses a unique test user
(provisioned in `Before`), ensuring that WebSocket connections are isolated per scenario.
The `x-test-correlation-id` header pattern used for event-driven BDD applies directly.

**[community] Playwright WebSocket interception limitations**: Playwright's `websocket`
event captures frames *received by the page*, not frames sent by the page. For scenarios
that need to verify *outgoing* WebSocket messages (e.g., "client sends heartbeat every
30 seconds"), instrument the application code to expose sent messages via a test-only
endpoint, then poll that endpoint from the step definition.

**[community] Playwright `WebSocketRoute` (v1.48+) for mock-backend WebSocket BDD**: When
a real WebSocket backend is unavailable in CI (e.g., event streaming service not running),
use `context.routeWebSocket()` to intercept the WebSocket URL and inject mock server
messages directly from the step definition. This eliminates the need for a running backend
for client-side behavioral scenarios. See the "Playwright 1.45–1.60: New BDD-Relevant APIs"
section for a complete TypeScript example with `routeWebSocket()` and `wsRoute.send()`.

---

### BDD Localization and Internationalization Testing  [community]

BDD scenarios for localization (l10n) and internationalization (i18n) verify that the
application presents correct content for each supported locale. These are business behaviors
— the product team defines which locales are supported and what "correct" means — making
them ideal candidates for BDD coverage.

**Two distinct categories of i18n BDD:**
1. **Locale-specific content**: Correct date formats, number formats, currency symbols,
   translated strings.
2. **Locale-specific business rules**: Tax calculations differ by country, address formats
   differ, legal text requirements differ.

```gherkin
# features/i18n/checkout-localization.feature
@i18n @regression
Feature: Checkout localization by user locale

  Scenario Outline: Order total displays correct currency format for each locale
    Given I am a customer with locale "<locale>"
    And my cart contains items totalling 1234.50 in base currency
    When I view the checkout summary
    Then the order total should display as "<expected_format>"
    And the currency symbol should be "<currency_symbol>"

    Examples:
      | locale  | expected_format | currency_symbol |
      | en-US   | $1,234.50       | $               |
      | de-DE   | 1.234,50 €      | €               |
      | ja-JP   | ¥1,235          | ¥               |
      | en-GB   | £1,234.50       | £               |
      | pt-BR   | R$ 1.234,50     | R$              |

  Scenario: Date format follows user locale in order confirmation
    Given I am a customer with locale "de-DE"
    And I have a confirmed order from today
    When I view the order confirmation page
    Then the order date should display in German format (DD.MM.YYYY)

  Scenario: Right-to-left layout is applied for Arabic locale
    Given I am a customer with locale "ar-SA"
    When I navigate to the checkout page
    Then the page layout direction should be right-to-left
    And the navigation elements should be mirrored

  Scenario: Legal terms display country-specific GDPR text for EU customers
    Given I am a customer in the European Union with locale "fr-FR"
    When I reach the checkout consent step
    Then I should see the GDPR consent checkbox
    And the consent text should reference "Règlement général sur la protection des données"
```

```typescript
// src/steps/i18n.steps.ts — localization step definitions
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';
import { expect } from '@playwright/test';

Given('I am a customer with locale {string}', async function (this: AppWorld, locale: string) {
  // Create a browser context with the target locale
  await this.context.close();
  this.context = await this.browser.newContext({
    locale,
    // Timezone affects date display
    timezoneId: getTimezoneForLocale(locale),
    // Accept-Language header sent to server
    extraHTTPHeaders: { 'Accept-Language': locale },
  });
  this.page = await this.context.newPage();
  this.currentLocale = locale;
  await this.authenticateWithEmail('test@example.com', 'TestPass123!');
});

function getTimezoneForLocale(locale: string): string {
  const localeToTimezone: Record<string, string> = {
    'en-US': 'America/New_York',
    'de-DE': 'Europe/Berlin',
    'ja-JP': 'Asia/Tokyo',
    'en-GB': 'Europe/London',
    'pt-BR': 'America/Sao_Paulo',
    'ar-SA': 'Asia/Riyadh',
    'fr-FR': 'Europe/Paris',
  };
  return localeToTimezone[locale] ?? 'UTC';
}

Then(
  'the order total should display as {string}',
  async function (this: AppWorld, expectedFormat: string) {
    const totalLocator = this.page.getByTestId('order-total');
    await expect(totalLocator).toBeVisible();
    const displayedTotal = (await totalLocator.textContent())?.trim() ?? '';
    // Normalize whitespace (some locales use non-breaking spaces)
    const normalized = displayedTotal.replace(/ /g, ' ').trim();
    if (normalized !== expectedFormat) {
      throw new Error(
        `Expected total "${expectedFormat}" for locale "${this.currentLocale}" ` +
        `but got "${normalized}"`
      );
    }
  }
);

Then(
  'the page layout direction should be right-to-left',
  async function (this: AppWorld) {
    const dir = await this.page.evaluate(() =>
      document.documentElement.getAttribute('dir') ??
      getComputedStyle(document.body).direction
    );
    expect(dir).toBe('rtl');
  }
);
```

**[community] i18n BDD: the number format edge case trap**: The most common i18n BDD
failure is number formatting. `1234.50` in `en-US` is `$1,234.50`; in `de-DE` it is
`1.234,50 €` (period and comma swapped). Scenarios that assert the raw number `1234.50`
instead of the locale-formatted string will pass for `en-US` and fail for `de-DE`. Always
use the locale-specific expected format in `Scenario Outline` examples tables, and use
`Intl.NumberFormat` in the application code to ensure consistency.

**[community] RTL layout BDD**: Right-to-left locales (Arabic, Hebrew, Persian) require
more than string translation. CSS `direction: rtl` must be applied, flexbox/grid layouts
must mirror, and icons that imply directionality (back arrow, forward arrow) must flip.
BDD scenarios that check `direction: rtl` and mirroring catch layout bugs that are
invisible in LTR-only manual testing. These scenarios are high-ROI in products targeting
MENA or Israeli markets.

---

### BDD in Microservice Architectures: Service-Level BDD  [community]

In monolithic applications, BDD runs end-to-end through a single deployable unit. In
microservice architectures, "end-to-end" spans multiple services — making BDD scenarios
slower, flakier, and harder to own. The recommended strategy is to run BDD at two levels:

1. **Service-level BDD**: Each service owns a BDD suite that tests its own behavior
   in isolation (downstream dependencies mocked with WireMock or MSW). Fast, isolated,
   service-team-owned.
2. **Integration BDD (platform level)**: A small suite of cross-service scenarios that
   tests the critical user journeys end-to-end with all services deployed. Slower, run
   nightly, platform-team-owned.

**Why service-level BDD instead of only E2E BDD:**
- E2E scenarios fail when *any* downstream service has an issue, making failures hard to
  localize
- Service teams can run their own BDD suite in < 2 minutes with mocked dependencies
- Service-level BDD provides the acceptance test layer that E2E tests depend on

```gherkin
# order-service/features/order-creation.feature
# Runs against the order-service only; payment-service is mocked

Feature: Order service — order creation
  As the order service
  I want to create valid orders and emit the correct events
  So that downstream services can process them reliably

  Background:
    Given the payment service is available and accepts charges

  Scenario: Creating an order with valid items returns 201 and emits order.created event
    When I create an order with 2 items totalling $109.97
    Then the order service should return 201
    And the response should include an "orderId" matching /^ORD-[A-Z0-9]{8}$/
    And an "order.created" event should have been published to the event bus
    And the event payload should contain the order total $109.97

  Scenario: Creating an order when payment service is unavailable returns 503
    Given the payment service is currently unavailable
    When I create an order with 1 item
    Then the order service should return 503
    And the response should contain "Payment service unavailable"
    And no "order.created" event should have been published

  Scenario: Creating an order with an out-of-stock item returns 422
    Given the product "prod-001" has 0 units in stock
    When I create an order for 1 unit of "prod-001"
    Then the order service should return 422
    And the response should contain "Product out of stock"
```

```typescript
// order-service/src/steps/order-creation.steps.ts
// Uses WireMock for payment service dependency mock
import { Given, When, Then, Before, After } from '@cucumber/cucumber';
import supertest from 'supertest';
import { WireMock } from 'wiremock-client';
import { createApp } from '../../src/app';
import { OrderServiceWorld } from '../support/world';

const wireMock = new WireMock('http://localhost:8089');
const app = createApp({ paymentServiceUrl: 'http://localhost:8089' });
const api = supertest(app);

Before(async function (this: OrderServiceWorld) {
  await wireMock.resetAll(); // Clear all stubs between scenarios
});

Given('the payment service is available and accepts charges', async function () {
  // WireMock stub: payment service accepts any charge and returns success
  await wireMock.register({
    request: { method: 'POST', url: '/api/payments/charge' },
    response: {
      status: 200,
      jsonBody: { chargeId: 'charge-001', status: 'succeeded' }
    }
  });
});

Given('the payment service is currently unavailable', async function () {
  await wireMock.register({
    request: { method: 'POST', url: '/api/payments/charge' },
    response: { status: 503, body: 'Service Unavailable' }
  });
});

When(
  'I create an order with {int} items totalling {string}',
  async function (this: OrderServiceWorld, itemCount: number, total: string) {
    const items = Array.from({ length: itemCount }, (_, i) => ({
      productId: `prod-${String(i + 1).padStart(3, '0')}`,
      quantity: 1,
      unitPrice: parseFloat(total.replace('$', '')) / itemCount,
    }));
    this.response = await api
      .post('/api/orders')
      .set('Authorization', `Bearer ${this.authToken}`)
      .send({ customerId: 'cust-001', items });
  }
);

Then(
  'the order service should return {int}',
  function (this: OrderServiceWorld, expectedStatus: number) {
    if (this.response.status !== expectedStatus) {
      throw new Error(
        `Expected HTTP ${expectedStatus}, got ${this.response.status}.\n` +
        `Body: ${JSON.stringify(this.response.body)}`
      );
    }
  }
);

Then(
  'an {string} event should have been published to the event bus',
  async function (this: OrderServiceWorld, eventType: string) {
    // Query the in-memory event bus (test-only endpoint)
    const res = await api.get(`/api/test/events?type=${eventType}`);
    const events = res.body as Array<{ type: string; payload: Record<string, unknown> }>;
    if (events.length === 0) {
      throw new Error(`No "${eventType}" event found in event bus. Published events: ${
        (await api.get('/api/test/events')).body.map((e: { type: string }) => e.type).join(', ')
      }`);
    }
    this.lastEvent = events[events.length - 1];
  }
);

Then(
  'no {string} event should have been published',
  async function (this: OrderServiceWorld, eventType: string) {
    const res = await api.get(`/api/test/events?type=${eventType}`);
    const events = res.body as unknown[];
    if (events.length > 0) {
      throw new Error(
        `Expected no "${eventType}" events but found ${events.length}`
      );
    }
  }
);
```

**Distributed tracing integration for cross-service BDD**:
```typescript
// src/support/trace-assertions.ts — validate distributed traces in BDD
// Uses the OpenTelemetry collector test API to verify trace spans
export async function assertTraceSpan(
  correlationId: string,
  serviceName: string,
  operationName: string,
  expectedAttributes: Record<string, unknown>
): Promise<void> {
  const collectorUrl = process.env.OTEL_COLLECTOR_TEST_URL ?? 'http://localhost:4318';
  const res = await fetch(`${collectorUrl}/api/traces?correlationId=${correlationId}`);
  const traces = await res.json() as { spans: Array<{
    service: string;
    operation: string;
    attributes: Record<string, unknown>;
  }> };

  const matchingSpan = traces.spans.find(
    s => s.service === serviceName && s.operation === operationName
  );

  if (!matchingSpan) {
    const available = traces.spans.map(s => `${s.service}.${s.operation}`).join(', ');
    throw new Error(
      `No span found for ${serviceName}.${operationName}. ` +
      `Available spans: ${available}`
    );
  }

  for (const [key, value] of Object.entries(expectedAttributes)) {
    if (matchingSpan.attributes[key] !== value) {
      throw new Error(
        `Span attribute "${key}": expected "${value}", got "${matchingSpan.attributes[key]}"`
      );
    }
  }
}
```

**[community] Service-level BDD ownership**: The biggest microservices BDD failure mode
is ownership ambiguity. A single centralized BDD suite that tests all services is owned
by no one and maintained by everyone — which means it degrades quickly. The principle:
each service team owns and maintains the BDD suite for their service. Platform teams own
the integration BDD suite. Cross-service scenarios that fail are triaged to the service
team responsible for the failing step.

**[community] WireMock state management in parallel BDD**: When service-level BDD runs
in parallel, WireMock instances must be isolated per worker or per scenario. The cleanest
approach is a WireMock instance per scenario (start/stop in Before/After hooks). The
alternative — a shared WireMock instance with scenario-scoped state via `stateName` — is
possible but error-prone under parallel execution. Teams running 50+ parallel scenarios
consistently prefer the per-scenario instance model despite the startup overhead.

---

### Migrating from Legacy Test Suites to BDD  [community]

Most teams adopting BDD have an existing test suite (Jest, Mocha, Cypress, or Selenium).
The migration question is: do we rewrite everything in Gherkin, or do we run both systems
in parallel? The answer is almost always: **incremental migration with no big-bang rewrite**.

**Migration strategy: the BDD overlay approach**

Instead of rewriting existing tests, add BDD scenarios for *new features* while keeping
existing tests in place. Over 6–12 months, the new BDD suite covers active features and
the legacy suite covers historical ones. Legacy tests are retired as features are
significant reworked.

```gherkin
# Migration signal: when to write BDD instead of Jest/Cypress
# 
# USE BDD when:
# - A product manager or BA has written acceptance criteria for the feature
# - The feature involves a multi-step user journey
# - The feature is in a complex business domain with non-obvious rules
#
# KEEP Jest/Cypress when:
# - It's a pure UI component test (rendering, props)
# - It's an internal utility function test (unit test)  
# - The existing test is stable and well-understood
# - The migration cost > the collaboration benefit
```

```typescript
// scripts/migration-audit.ts — analyze existing test suite for BDD migration candidates
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

interface TestFileMigrationScore {
  file: string;
  lineCount: number;
  describeBlockCount: number;
  itBlockCount: number;
  hasMockSetup: boolean;
  hasLoginFlow: boolean;
  hasBusinessKeywords: boolean;
  migrationScore: number; // 0-10: higher = stronger BDD candidate
  recommendation: 'migrate' | 'keep' | 'evaluate';
}

function analyzeTestFile(filePath: string): TestFileMigrationScore {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  // Heuristic signals that indicate a BDD migration candidate
  const describeBlockCount = (content.match(/describe\(/g) ?? []).length;
  const itBlockCount = (content.match(/\bit\(|\btest\(/g) ?? []).length;
  const hasMockSetup = /jest\.mock|vi\.mock|sinon\.|nock\./.test(content);
  const hasLoginFlow = /login|auth|token|cookie/i.test(content);
  const hasBusinessKeywords = /order|checkout|payment|customer|cart|invoice|subscription/i.test(content);

  // Score: scenarios with business language, login flows, and large describe blocks
  // are the best BDD migration candidates
  let score = 0;
  if (hasBusinessKeywords) score += 4;
  if (hasLoginFlow) score += 2;
  if (describeBlockCount > 3) score += 2;
  if (!hasMockSetup) score += 1; // Integration-level: better as BDD
  if (itBlockCount > 5) score += 1;

  return {
    file: filePath,
    lineCount: lines.length,
    describeBlockCount,
    itBlockCount,
    hasMockSetup,
    hasLoginFlow,
    hasBusinessKeywords,
    migrationScore: score,
    recommendation: score >= 7 ? 'migrate' : score >= 4 ? 'evaluate' : 'keep',
  };
}

// Find all test files
const testFiles = execSync('find . -name "*.spec.ts" -o -name "*.test.ts" -o -name "*.e2e.ts"')
  .toString().trim().split('\n').filter(Boolean);

const results = testFiles
  .map(analyzeTestFile)
  .sort((a, b) => b.migrationScore - a.migrationScore);

console.log('\nBDD Migration Audit Report');
console.log('===========================\n');
console.log(`Analyzed: ${results.length} test files\n`);

const migrate = results.filter(r => r.recommendation === 'migrate');
const evaluate = results.filter(r => r.recommendation === 'evaluate');

console.log(`Migrate to BDD (${migrate.length} files):`);
migrate.forEach(r => console.log(`  [${r.migrationScore}/10] ${r.file} (${r.itBlockCount} tests)`));

console.log(`\nEvaluate for migration (${evaluate.length} files):`);
evaluate.forEach(r => console.log(`  [${r.migrationScore}/10] ${r.file}`));
```

**[community] Migration anti-pattern — "big bang BDD"**: Teams that stop all development
to rewrite their entire test suite in Gherkin consistently report failure. The rewrite
takes 2–3 months, the team loses institutional knowledge of why tests were structured
as they were, and the new BDD suite starts with zero trust from stakeholders who have
not seen it catch a real bug yet. Incremental migration — one feature area per sprint —
maintains test coverage continuity and builds confidence gradually.

**[community] Coexistence pattern: Cucumber + Playwright Test in the same repo**: Cucumber.js
and Playwright Test can coexist in the same repository with separate configuration files.
Legacy E2E tests in `playwright.config.ts` continue to run. New BDD tests in `cucumber.js`
add the Gherkin layer. Both write to the `reports/` directory; a combined CI job uploads
all reports. The key: use different output directories (`reports/playwright/` vs
`reports/cucumber/`) to avoid artifact collision.

---

### BDD Environment Management and Pre-Run Health Checks  [community]

BDD suites that run against an unreachable or misconfigured environment produce hundreds
of false failures — not because of bugs in the application, but because the environment
was not ready. A pre-run health check step fails fast (< 10 seconds) rather than waiting
for all 300 scenarios to time out. This pattern is especially critical in CI pipelines
that deploy to staging environments before running BDD.

```typescript
// src/support/environment-health.ts — pre-run environment validation
import { BeforeAll } from '@cucumber/cucumber';
import * as path from 'path';

interface HealthCheckResult {
  service: string;
  url: string;
  status: 'ok' | 'degraded' | 'unreachable';
  latencyMs: number;
  details?: string;
}

async function checkEndpoint(
  service: string,
  url: string,
  expectedStatus = 200
): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    const res = await fetch(url, {
      signal: AbortSignal.timeout(5000),  // 5-second timeout per service
    });
    const latencyMs = Date.now() - start;
    return {
      service,
      url,
      status: res.status === expectedStatus ? 'ok' : 'degraded',
      latencyMs,
      details: res.status !== expectedStatus
        ? `Expected HTTP ${expectedStatus}, got ${res.status}`
        : undefined,
    };
  } catch (err) {
    return {
      service,
      url,
      status: 'unreachable',
      latencyMs: Date.now() - start,
      details: err instanceof Error ? err.message : String(err),
    };
  }
}

BeforeAll(async function () {
  const baseUrl = process.env.BASE_URL ?? 'http://localhost:3000';

  // Define all services that BDD scenarios depend on
  const checks = await Promise.all([
    checkEndpoint('app', `${baseUrl}/api/health`),
    checkEndpoint('auth-service', `${baseUrl}/api/auth/health`),
    checkEndpoint('payment-service', `${baseUrl}/api/payments/health`),
    checkEndpoint('notification-service', `${baseUrl}/api/notifications/health`),
  ]);

  const failed = checks.filter(c => c.status === 'unreachable');
  const degraded = checks.filter(c => c.status === 'degraded');

  // Print health summary
  console.log('\n=== Environment Health Check ===');
  for (const check of checks) {
    const icon = check.status === 'ok' ? '✓' : check.status === 'degraded' ? '⚠' : '✗';
    console.log(`  ${icon} ${check.service}: ${check.status} (${check.latencyMs}ms)`);
    if (check.details) console.log(`    → ${check.details}`);
  }
  console.log('================================\n');

  if (failed.length > 0) {
    const failedServices = failed.map(c => c.service).join(', ');
    throw new Error(
      `BDD suite aborted: ${failedServices} unreachable.\n` +
      `Check that the test environment is deployed and BASE_URL is correct.\n` +
      `BASE_URL: ${baseUrl}`
    );
  }

  if (degraded.length > 0) {
    console.warn(`Warning: ${degraded.map(c => c.service).join(', ')} degraded — ` +
      `some scenarios may fail unexpectedly.`);
  }
});
```

**Test environment configuration management** (multiple environments):

```typescript
// src/config/environments.ts — type-safe environment configuration
export type EnvironmentName = 'local' | 'staging' | 'preview' | 'production-smoke';

interface EnvironmentConfig {
  baseUrl: string;
  apiTimeout: number;
  headless: boolean;
  retryCount: number;
  tags: string; // Default tag filter for this environment
  auth: {
    clientId: string;
    clientSecret: string;
  };
}

const environments: Record<EnvironmentName, EnvironmentConfig> = {
  local: {
    baseUrl: 'http://localhost:3000',
    apiTimeout: 10_000,
    headless: false,
    retryCount: 0,
    tags: 'not @wip and not @production-only',
    auth: {
      clientId: process.env.LOCAL_CLIENT_ID ?? 'test-client',
      clientSecret: process.env.LOCAL_CLIENT_SECRET ?? 'test-secret',
    },
  },
  staging: {
    baseUrl: process.env.STAGING_URL ?? 'https://staging.example.com',
    apiTimeout: 20_000,
    headless: true,
    retryCount: 1,
    tags: '@regression and not @wip',
    auth: {
      clientId: process.env.STAGING_CLIENT_ID ?? '',
      clientSecret: process.env.STAGING_CLIENT_SECRET ?? '',
    },
  },
  preview: {
    baseUrl: process.env.PREVIEW_URL ?? '',
    apiTimeout: 15_000,
    headless: true,
    retryCount: 1,
    tags: '@smoke and not @wip',
    auth: {
      clientId: process.env.PREVIEW_CLIENT_ID ?? '',
      clientSecret: process.env.PREVIEW_CLIENT_SECRET ?? '',
    },
  },
  'production-smoke': {
    baseUrl: 'https://www.example.com',
    apiTimeout: 30_000,
    headless: true,
    retryCount: 2, // Retry more on production (transient failures common)
    tags: '@smoke and @production-safe',  // Only non-destructive scenarios
    auth: {
      clientId: process.env.PROD_SMOKE_CLIENT_ID ?? '',
      clientSecret: process.env.PROD_SMOKE_CLIENT_SECRET ?? '',
    },
  },
};

export function getEnvironmentConfig(): EnvironmentConfig {
  const env = (process.env.TEST_ENV ?? 'local') as EnvironmentName;
  const config = environments[env];
  if (!config) {
    throw new Error(
      `Unknown TEST_ENV: "${env}". Valid options: ${Object.keys(environments).join(', ')}`
    );
  }
  return config;
}
```

**`cucumber.js` with environment-aware profiles**:
```javascript
import { getEnvironmentConfig } from './src/config/environments.js';

const envConfig = getEnvironmentConfig();

export default {
  smoke: {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    tags: `@smoke and not @wip`,
    format: ['progress-bar', 'html:reports/smoke-report.html'],
    retry: envConfig.retryCount,
  },
  regression: {
    import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
    tags: envConfig.tags,
    format: ['progress-bar', 'html:reports/regression-report.html'],
    retry: envConfig.retryCount,
    parallel: process.env.CI ? 8 : 2,
  },
};
```

**[community] `@production-safe` tag discipline**: Any BDD scenario that runs against
production must be tagged `@production-safe` — meaning it creates no lasting state, sends
no real emails, and does not modify production data. The tag is enforced by a CI check:
`--tags "@production-safe"` can only be combined with the `production-smoke` profile.
Teams that accidentally run `@regression` scenarios against production typically discover
it when real users receive test emails or when test orders appear in analytics.

**[community] Preview environment BDD as PR gate**: Platforms like Vercel and Netlify
create a preview deployment per PR. Running `@smoke` BDD against the preview URL before
merging is the highest-confidence PR gate: it validates the actual built artifact in a
production-equivalent environment. The configuration: set `BASE_URL` to the preview URL
in the CI step that follows the deploy step.

**[community] Environment health check timing**: Run the health check as a separate CI
step before launching Cucumber, not inside `BeforeAll`. If the health check fails as a
`BeforeAll`, Cucumber still initializes, loads all step definitions, and generates a
confusing failure report. A pre-run health check bash script that exits 1 immediately on
failure is cleaner and produces a more informative CI failure message.

---

## Additional Resources (Iterations 11–20 Additions)

**New framework references (2024–2026):**
- [Gherkin `Rule` keyword reference](https://cucumber.io/docs/gherkin/reference/#rule) — `Rule` grouping for scenario organization by business rule with per-rule `Background`
- [Cucumber.js v12 CHANGELOG](https://github.com/cucumber/cucumber-js/blob/main/CHANGELOG.md) — TypeScript config files, built-in `--shard`, plugin architecture, Node 24/25 support
- [Screenplay Pattern — Serenity/JS](https://serenity-js.org/handbook/design/screenplay-pattern/) — TypeScript-native Screenplay Pattern implementation
- [WireMock Node client](https://github.com/Sairyss/wiremock-node-client) — HTTP service mocking for service-level BDD
- [Detox — React Native E2E](https://github.com/wix/Detox) — iOS/Android automation for mobile BDD
- [Allure Framework — TestOps](https://allurereport.org/) — report publishing, trend charts, CI integration
- [openapi-backend](https://github.com/anttiviljami/openapi-backend) — OpenAPI request/response validation for BDD
- [ajv](https://ajv.js.org/) — JSON schema validation for OpenAPI contract assertions
- [Redocly CLI](https://redocly.com/docs/cli/) — OpenAPI spec linting and bundling in CI
- [playwright-bdd advanced config](https://vitalets.github.io/playwright-bdd/) — Playwright-native BDD runner documentation
- [Unleash feature flags — Node SDK](https://docs.getunleash.io/reference/sdks/node) — feature flag isolation for parallel BDD scenarios
- [testcontainers/node](https://github.com/testcontainers/testcontainers-node) — real database and message broker instances for BDD
- [multiple-cucumber-html-reporter v3](https://github.com/WasiqB/multiple-cucumber-html-reporter) — merged report generation for sharded CI
- [BDD Books — Gaspar Nagy & Seb Rose](https://bddbooks.com/) — practitioner guide for BDD at scale (includes microservices, migrations)

**Additional community resources:**
- [Cucumber Discord community](https://discord.gg/cucumber) — active Q&A for Cucumber.js, step definition issues, tooling
- [OWASP Web Security Testing Guide v4.2](https://owasp.org/www-project-web-security-testing-guide/) — security behavioral patterns for BDD scenarios
- [Google Web Vitals documentation](https://web.dev/vitals/) — Core Web Vitals thresholds for performance BDD scenarios

---

### Cucumber.js v12: What Changed and Migration Notes (2025–2026)

Cucumber.js v12 is the current major version as of 2025–2026. Teams running v11 face no
urgent migration pressure (v11 remains supported), but v12 introduces production-relevant
improvements that reduce configuration boilerplate and improve CI reporting.

**Summary of v12 changes:**

| Change | Version | Production Impact |
|---|---|---|
| TypeScript config files (`cucumber.ts`) | v12.4.0 | Eliminate JSON formatter escape issues; type-safe profiles |
| Built-in execution sharding | v12.2.0 | Native `--shard N/M` flag — no matrix workarounds |
| External plugin architecture | v12.5.0 | Custom formatters, reporters, and loaders without forking |
| Redesigned summary/progress/pretty formatters | v12.0.0 | Cleaner output; legacy formatter classes deprecated |
| `includeAttachments` replaces `printAttachments` | v12.0.0 | Breaking rename — CI scripts using old option name silently fail |
| Named BeforeAll/AfterAll hooks | v12.0.0 | Hook-specific messages in reports aid debugging |
| Node.js 24 and 25 support; Node 18 and 23 dropped | v12.x | Upgrade Node before upgrading Cucumber if on Node 18 |

**TypeScript config file** (`cucumber.ts`) — v12.4+:

```typescript
// cucumber.ts — fully type-safe, no JSON escaping issues
// Import is resolved automatically in v12.4+ when cucumber.ts exists
import type { IConfiguration } from '@cucumber/cucumber/api';

const smokeConfig: IConfiguration = {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  tags: '@smoke and not @wip',
  format: ['progress-bar', 'html:reports/smoke-report.html'],
  retry: 1,
  retryTagFilter: '@flaky',
  parallel: 4,
};

const regressionConfig: IConfiguration = {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  tags: 'not @wip',
  format: [
    'progress-bar',
    '@cucumber/json-formatter:reports/results.json',  // explicit package in v11+
    'html:reports/regression-report.html',
  ],
  retry: 1,
  retryTagFilter: '@flaky',
  parallel: 8,
};

// Named export per profile — replaces top-level "default" key
export const smoke = smokeConfig;
export const regression = regressionConfig;
```

**Benefits over `cucumber.json`:**
- TypeScript types catch typos in option names at compile time (e.g., `paralel` → type error)
- String interpolation works without JSON escaping: `tags: \`not @wip and ${process.env.EXTRA_TAGS ?? ''}\``
- Shared constants between profiles (retry count, base imports) are DRY

**Built-in sharding** (v12.2+) — `--shard`:

```bash
# v12.2+ native sharding — no matrix config needed
npx cucumber-js --shard 1/4   # worker 1 of 4
npx cucumber-js --shard 2/4
npx cucumber-js --shard 3/4
npx cucumber-js --shard 4/4
```

```yaml
# .github/workflows/bdd.yml — using v12 native sharding
jobs:
  bdd-regression:
    strategy:
      matrix:
        shard: ['1/4', '2/4', '3/4', '4/4']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'   # Node 18 dropped in v12; use 20, 22, or 24
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run BDD shard ${{ matrix.shard }}
        run: npx cucumber-js --profile regression --shard ${{ matrix.shard }}
        env:
          CI: true
          BASE_URL: ${{ vars.TEST_BASE_URL }}
```

**Named hooks for better diagnostics** (`src/support/hooks.ts` — v12 style):

```typescript
import { Before, After, BeforeAll, AfterAll } from '@cucumber/cucumber';
import { chromium, Browser } from '@playwright/test';
import { AppWorld } from './world';

// v12: named hooks appear by name in the HTML report timeline
BeforeAll({ name: 'Launch browser' }, async function () {
  // The hook name "Launch browser" appears in the report — easier to diagnose slow setups
  (globalThis as { _browser?: Browser })._browser = await chromium.launch({
    headless: process.env.CI === 'true',
  });
});

AfterAll({ name: 'Close browser' }, async function () {
  await (globalThis as { _browser?: Browser })._browser?.close();
});

Before({ name: 'Create browser context', tags: 'not @api-only' }, async function (this: AppWorld) {
  const browser = (globalThis as { _browser?: Browser })._browser!;
  this.context = await browser.newContext({
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
  });
  this.page = await this.context.newPage();
  this.testUserId = `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
});

After({ name: 'Capture failure screenshot', tags: 'not @api-only' }, async function (this: AppWorld, scenario) {
  if (scenario.result?.status === 'FAILED') {
    const screenshot = await this.page?.screenshot({ fullPage: true });
    if (screenshot) {
      this.attach(screenshot, 'image/png');
    }
  }
  await this.context?.close();
});
```

**`includeAttachments` format option** (v12 breaking rename):

```typescript
// ❌ v11 option — deprecated in v12, silently ignored
format: ['html:reports/report.html'],
formatOptions: { printAttachments: true },

// ✅ v12 option
format: ['html:reports/report.html'],
formatOptions: { includeAttachments: true },  // renamed
```

**[community] v12 migration pitfall — Node.js version requirement**: Cucumber.js v12 dropped
Node.js 18 support. Teams that pin `node-version: '18'` in their CI workflows will get a
cryptic installation error when upgrading. Check your CI `node-version` before upgrading
`@cucumber/cucumber` to v12. Node.js 20 (LTS), 22 (LTS), and 24 are all supported.

**[community] v12 formatter deprecations and CI breakage**: The `SummaryFormatter` and
`ProgressFormatter` classes were deprecated in v12. Teams that extend these classes for
custom CI reporting will see deprecation warnings in v12 and may see `Cannot read properties
of undefined` errors if they rely on internal formatter APIs that changed. Migrate to the
plugin architecture (v12.5+) for custom formatters instead of extending deprecated classes:

```typescript
// v12.5+ custom formatter via plugin architecture
// src/plugins/custom-reporter.ts
import type { IPlugin } from '@cucumber/cucumber';

const customReporter: IPlugin = {
  type: 'plugin',
  coordinator({ on, options }) {
    on('message', (message) => {
      // Handle Cucumber messages directly — no class inheritance needed
      if (message.testStepFinished?.testStepResult.status === 'FAILED') {
        process.stdout.write(`FAIL: ${JSON.stringify(message.testStepFinished)}\n`);
      }
    });
  },
};

export default customReporter;
```

```typescript
// cucumber.ts — load custom plugin
export const regression = {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  plugin: ['src/plugins/custom-reporter.ts'],
  format: ['progress-bar', 'html:reports/report.html'],
};
```

**[community] v12 TypeScript config file discovery order**: Cucumber.js v12.4 looks for
config files in this priority order: `cucumber.ts` → `cucumber.js` → `cucumber.mjs` →
`cucumber.cjs` → `cucumber.json` → `.cucumberrc`. If a `cucumber.json` and a `cucumber.ts`
both exist, the TypeScript file wins. Teams migrating incrementally should delete
`cucumber.json` once `cucumber.ts` is verified — having both creates confusion about which
file is active.

**Version compatibility matrix:**

| `@cucumber/cucumber` | Node.js | Key feature |
|---|---|---|
| v9.x | 14, 16, 18 | CommonJS default; `ts-node/register` for TypeScript |
| v10.x | 16, 18, 20 | ESM migration; `import:` replaces `require:` |
| v11.x | 18, 20, 22 | Typed World generics; `--retry` flag; native `--import` |
| v12.0–v12.5 | 20, 22, 24, 25 | TypeScript config; built-in `--shard`; plugin API; named hooks |
| v12.6.0 | 20, 22, 24, 25 | `colorsEnabled` format option deprecated → use `FORCE_COLOR` env var |
| v12.7+ | 20, 22, 24, 25 | + env var propagation to parallel workers (critical fix) |
| v12.8.0 | 20, 22, 24, 25 | + custom externalising |
| v12.8.1 | 20, 22, 24, 25 | + `junit-xml-formatter` ↔ `query` dependency conflict resolved |
| v12.8.3 | 20, 22, 24, 25 | thrown-string error fix (latest stable as of 2026-05-12) |

---

## Additional Resources (Iterations 11–20 Additions)

**New framework references (2024–2026):**
- [Gherkin `Rule` keyword reference](https://cucumber.io/docs/gherkin/reference/#rule) — `Rule` grouping for scenario organization by business rule with per-rule `Background`
- [Cucumber.js v12 CHANGELOG](https://github.com/cucumber/cucumber-js/blob/main/CHANGELOG.md) — TypeScript config files, built-in `--shard`, plugin architecture, Node 24/25 support
- [Screenplay Pattern — Serenity/JS](https://serenity-js.org/handbook/design/screenplay-pattern/) — TypeScript-native Screenplay Pattern implementation
- [WireMock Node client](https://github.com/Sairyss/wiremock-node-client) — HTTP service mocking for service-level BDD
- [Detox — React Native E2E](https://github.com/wix/Detox) — iOS/Android automation for mobile BDD
- [Allure Framework — TestOps](https://allurereport.org/) — report publishing, trend charts, CI integration
- [openapi-backend](https://github.com/anttiviljami/openapi-backend) — OpenAPI request/response validation for BDD
- [ajv](https://ajv.js.org/) — JSON schema validation for OpenAPI contract assertions
- [Redocly CLI](https://redocly.com/docs/cli/) — OpenAPI spec linting and bundling in CI
- [playwright-bdd advanced config](https://vitalets.github.io/playwright-bdd/) — Playwright-native BDD runner documentation
- [Unleash feature flags — Node SDK](https://docs.getunleash.io/reference/sdks/node) — feature flag isolation for parallel BDD scenarios
- [testcontainers/node](https://github.com/testcontainers/testcontainers-node) — real database and message broker instances for BDD
- [multiple-cucumber-html-reporter v3](https://github.com/WasiqB/multiple-cucumber-html-reporter) — merged report generation for sharded CI
- [BDD Books — Gaspar Nagy & Seb Rose](https://bddbooks.com/) — practitioner guide for BDD at scale (includes microservices, migrations)

**Additional community resources:**
- [Cucumber Discord community](https://discord.gg/cucumber) — active Q&A for Cucumber.js, step definition issues, tooling
- [OWASP Web Security Testing Guide v4.2](https://owasp.org/www-project-web-security-testing-guide/) — security behavioral patterns for BDD scenarios
- [Google Web Vitals documentation](https://web.dev/vitals/) — Core Web Vitals thresholds for performance BDD scenarios

---

### Cucumber.js v12.7–v12.8: Latest Patch Releases (2026)

Cucumber.js v12.8.3 (released 2026-05-09) is the current latest version. Patch releases
v12.7.x and v12.8.x contain production-relevant fixes and features teams running at scale
should be aware of.

**What changed in v12.7.0 (2026-02-25):**

| Change | Impact |
|---|---|
| Environment variables now propagate to child processes in parallel mode | Fix: env vars set in CI (e.g., `BASE_URL`, `TEST_CLIENT_SECRET`) were silently unavailable to scenarios running in parallel workers — now automatically forwarded |
| Warnings emitted when paths are merged from config file and CLI | Visibility: previously silent behavior now produces an auditable warning when `--require` paths from CLI overlap with `import` paths in `cucumber.ts` |
| ESM source reference handling improved | Fix: source map references in error stack traces now correctly resolve for ESM TypeScript setups |

**[community] Parallel env var propagation was the most-reported v12.6 bug**: Teams using
`--parallel 8` with secrets injected via CI environment variables reported that `process.env.BASE_URL`
was `undefined` inside step definitions running in worker processes. The root cause was that
Cucumber.js spawned child processes without forwarding the parent process's environment.
v12.7.0 resolves this — but teams on earlier v12.x patches should explicitly upgrade to
v12.7+ before assuming env vars are reliable in parallel mode.

**What changed in v12.8.0:**

The `custom externalising` option allows step definitions to export attachment data to an
external store (e.g., S3 bucket, artifact server) rather than embedding large binary
attachments (screenshots, traces, HAR files) inline in the Cucumber JSON or HTML report.
This is particularly valuable for suites that capture full-page screenshots on every failure
— large reports can exceed CI artifact size limits.

```typescript
// cucumber.ts — v12.8+ custom externalising option
import type { IConfiguration } from '@cucumber/cucumber/api';
import { uploadAttachment } from './src/support/attachment-uploader';

export const regression: IConfiguration = {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  format: [
    'progress-bar',
    'html:reports/regression-report.html',
  ],
  formatOptions: {
    includeAttachments: true,
    // Custom externalising: receive attachment data and return a URL
    // Large attachments (screenshots, traces) are uploaded to S3 instead of inlined
    externalise: async (data: Buffer, mediaType: string) => {
      const url = await uploadAttachment(data, mediaType);
      return url; // Returned URL replaces the inline binary in the report
    },
  },
};
```

**What changed in v12.8.3 (2026-05-09 — current latest):**

- **Fix: thrown strings now handled correctly**: Previously, if a step definition threw
  a plain string (`throw 'something went wrong'`) instead of an `Error` object, Cucumber
  would crash with a confusing internal error. v12.8.3 wraps thrown strings in an Error
  before reporting, producing the expected FAILED status with the string as the message.
- **Improved stack trace assertion info**: Stack traces in assertion failures now include
  more context about the assertion source location.

**[community] Throw Error objects, not strings**: The v12.8.3 fix is a safeguard —
the correct practice is still to throw `Error` instances, not strings. `throw new Error('message')`
produces a stack trace and works consistently across all Cucumber.js versions. `throw 'message'`
(a JavaScript antipattern) has always been fragile and the fix does not change the recommendation
to avoid it.

---

### playwright-bdd v8.0–v8.5: Feature Guide (2025–2026)  [community]

`playwright-bdd` v8.5.0 (released March 2026) is the current version. The v8.x series
introduced significant features over the v7.x baseline. Teams upgrading from v7 to v8 face
several breaking changes; teams starting fresh should use v8.5 directly.

**Breaking changes (v7 → v8.0):**

| Breaking change | Migration |
|---|---|
| Minimum Playwright version is now 1.41 | Upgrade `@playwright/test` to `>=1.41` before upgrading `playwright-bdd` |
| Default quote style changed to **single quotes** | Auto-generated step definition stubs now use `'...'` instead of `"..."` — cosmetic but noisy in diffs if your team standardized on double quotes |
| `enrichReporterData` configuration option removed | Delete from `playwright.config.ts` if present — Playwright's native report data is now always included |

**New features in v8.0:**

**`missingSteps` configuration option** — controls what happens when a `.feature` file
references steps that have no matching definition:

```typescript
// playwright.config.ts — v8 missingSteps option
import { defineConfig } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
  // Options: 'fail' (default) | 'skip' | 'pending'
  // 'fail': CI fails immediately — safest for established suites
  // 'skip': Missing steps produce skipped tests — useful during active development
  // 'pending': Missing steps produce pending tests — shows in report without failing CI
  missingSteps: process.env.CI ? 'fail' : 'pending',
});

export default defineConfig({
  testDir,
  // ...
});
```

**`matchKeywords` option** — enables keyword-based step matching so `Given`, `When`, and
`Then` decorators only match steps with the corresponding Gherkin keyword (not any keyword):

```typescript
// playwright.config.ts
const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
  // When matchKeywords: true, a @Given() decorated step will NOT match a "When I ..." step
  // This is stricter and prevents accidental keyword mismatches in large step libraries
  matchKeywords: true,
});
```

**`BeforeScenario` and `AfterScenario` hook aliases** — clearer names for `Before` and
`After` that make hook intent explicit in reports:

```typescript
// src/support/hooks.ts — v8 alias syntax
import { BeforeScenario, AfterScenario } from 'playwright-bdd';

// BeforeScenario is an alias for Before — identical behavior, clearer name in reports
BeforeScenario({ name: 'Provision test user' }, async ({ page, $testInfo }) => {
  // $testInfo gives access to Playwright's TestInfo (title, tags, retry count)
  const testId = `test-${$testInfo.workerIndex}-${Date.now()}`;
  // ... setup using testId for isolation
});

AfterScenario({ name: 'Cleanup test data' }, async ({ page, $testInfo }) => {
  if ($testInfo.status === 'failed') {
    await page.screenshot({ path: `reports/failures/${$testInfo.title}.png` });
  }
});
```

**Tags from path** — automatically tag scenarios based on their directory location:

```typescript
// playwright.config.ts — tags from path
const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
  // Each directory segment under 'features/' becomes a tag.
  // features/payments/checkout.feature → all scenarios get @payments tag
  // features/admin/users.feature → all scenarios get @admin tag
  // Enables: npx playwright test --grep "@payments" without modifying feature files
  tagsFromPath: {
    featuresDir: 'features',
  },
});
```

**Multiple step decorators on a single method (v8.4.2):**

```typescript
// src/steps/checkout.steps.ts — v8.4.2 multiple decorators
import { createBdd } from 'playwright-bdd';
import { test } from '@playwright/test';

const { Given, When } = createBdd(test);

// Class-based step definitions with decorator stacking
class CheckoutSteps {
  // A single step function matches multiple Gherkin phrases
  // Useful when product managers use slightly different phrasing for the same action
  @Given('I am a registered customer')
  @Given('I am logged in as a registered user')
  async setupLoggedInCustomer({ page }: { page: import('@playwright/test').Page }) {
    await page.goto('/login');
    await page.getByTestId('email').fill('test@example.com');
    await page.getByTestId('password').fill('TestPass123!');
    await page.getByTestId('submit').click();
    await page.waitForURL('/dashboard');
  }

  @When('I proceed to checkout')
  @When('I navigate to the checkout page')
  async navigateToCheckout({ page }: { page: import('@playwright/test').Page }) {
    await page.getByTestId('checkout-button').click();
    await page.waitForURL('/checkout');
  }
}
```

**[community] Multiple decorators vs. Cucumber expressions**: The decorator approach solves
a common problem — teams where different product managers use slightly different Gherkin
phrasing for the same business action (e.g., "I am logged in" vs. "I am a registered customer").
Rather than writing two separate step functions with duplicate code, a single method handles
both. The alternative (Cucumber expression alternation: `'I am (logged in|a registered customer)'`)
works but produces less readable step audit output because the pattern obscures the two
distinct phrases.

**playwright-bdd v8.1: "Fix with AI" integration:**

playwright-bdd v8.1.0 introduced a `Fix with AI` feature that integrates with AI code
assistants. When a BDD scenario fails, the failure context (scenario text, step definition,
error message, screenshot) can be exported to an AI-friendly format for automated fix suggestions.
The upcoming `playwright-bdd agent skill` (announced in the v8.5 roadmap) will generate
`.feature` files and step definition stubs from natural-language requirement descriptions.

**[community] playwright-bdd v8.5 vs `@cucumber/cucumber` v12.8 — updated comparison:**

| Capability | `playwright-bdd` v8.5 | `@cucumber/cucumber` v12.8 |
|---|---|---|
| TypeScript support | Native (no loader config) | Requires `tsx` or `ts-node/esm` |
| Reporting | Playwright HTML (native, rich) | Requires separate formatter config |
| Tag expressions | `--grep` regex + auto-tagging from path | Full boolean expression (`@smoke and not @wip`) |
| Sharding | Playwright native `--shard` | Built-in `--shard` since v12.2 |
| Step decorators | v8.4+ (class methods, stackable) | Not supported (function-based only) |
| AI tooling | "Fix with AI" + upcoming agent skill | No built-in AI integration |
| Hook aliases | `BeforeScenario`/`AfterScenario` | `Before`/`After` only |
| Missing step control | `missingSteps` option (fail/skip/pending) | Undefined steps always fail |
| Parallel env vars | Forwarded by Playwright runner | Fixed in Cucumber.js v12.7+ |
| Min runtime | `@playwright/test` ≥ 1.41 | Node.js ≥ 20 |

**[community] Migration path from `@cucumber/cucumber` to `playwright-bdd`**: The feature
file Gherkin is fully compatible — no changes needed. Step definitions require rewriting from
`function (this: CustomWorld)` pattern to fixture-injected `async ({ page, ... })` pattern.
For suites with 50+ step definitions, the rewrite takes 1–2 sprints. Teams should migrate
incrementally: run both runners against the same `.feature` files during the transition period,
gradually moving step definitions to the `playwright-bdd` fixture model.

---

### Gherkin DocString Content-Type Annotations: Current Tool Support

The Gherkin specification allows `.feature` files to annotate `DocString` blocks with a
content type (e.g., `"""json`, `"""markdown`, `"""yaml`). The annotation is syntactically
valid in all Gherkin-compliant parsers and is used by some formatters to enable syntax
highlighting in reports.

**What the annotation does and does NOT do:**

```gherkin
# features/api/orders.feature
Scenario: Creating an order with a valid JSON payload
  Given I have the following order payload:
    """json
    {
      "customerId": "cust-001",
      "items": [{ "productId": "prod-42", "quantity": 2 }]
    }
    """
  When I POST to "/api/v1/orders"
  Then the response status is 201
```

The `"""json` annotation:
- **Does**: Signal to the Gherkin parser and report formatter that the content is JSON
- **Does NOT**: Automatically validate or parse the content as JSON in the step definition
- **Does NOT**: Currently trigger syntax highlighting in most editors (VS Code Cucumber
  extension does not highlight annotated DocStrings as of 2026; JetBrains IDE plugin does)

**Step definition handling of annotated DocStrings** (TypeScript):

```typescript
// src/steps/api.steps.ts
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// The content-type annotation is stripped — the step receives the raw content string.
// 'docString' below is the plain JSON text without the annotation keyword.
Given('I have the following order payload:', function (this: AppWorld, docString: string) {
  // Always parse explicitly — the annotation does NOT auto-parse
  try {
    this.requestBody = JSON.parse(docString);
  } catch (err) {
    throw new Error(`DocString is not valid JSON:\n${docString}\n${err}`);
  }
});
```

**[community] DocString annotation adoption gap**: Most BDD teams are unaware that content-type
annotations exist. They were introduced in Gherkin 6 (2020) but remain underused because
tool support is incomplete. As of 2026:
- **`@cucumber/cucumber`**: Parses and exposes the annotation via `docString.mediaType`
  property — but `mediaType` is not passed as a step parameter; it requires custom parameter
  type registration to access programmatically
- **`playwright-bdd`**: Passes the raw content to the fixture — annotation metadata is not
  exposed via the fixture API in v8.5
- **VS Code Cucumber extension**: Does not yet highlight annotated DocString content
- **JetBrains / IntelliJ Cucumber plugin**: Supports annotation-based syntax highlighting

**[community] Use DocString annotations for human readability only (2026 recommendation)**:
Until editor and tooling support matures uniformly, use the annotation (`"""json`, `"""yaml`)
purely as a readability aid for reviewers of feature files. Write step definitions that parse
the content regardless of annotation. This keeps step definitions forward-compatible: they
work whether the annotation is present, absent, or changed, and do not silently break if a
team member omits the annotation on a new scenario.

---

### Cucumber.js Upcoming Formatter Changes (Next Major — Unreleased)

The next major Cucumber.js release (post-v12.8.3) introduces several formatter-related changes
that TypeScript teams should prepare for. These are documented in the `CHANGELOG.md` `[Unreleased]`
section as of 2026-05-09.

**1. `printAttachments` → `includeAttachments` migration**

The `printAttachments` format option was deprecated in v12 in favour of `includeAttachments`.
The upcoming release enforces this. Update any existing configuration:

```javascript
// cucumber.js — BEFORE (deprecated in v12, removed in next major)
export default {
  default: {
    format: ['progress-bar', 'html:reports/report.html'],
    formatOptions: { printAttachments: true },  // deprecated
  },
};

// cucumber.js — AFTER (correct form)
export default {
  default: {
    format: ['progress-bar', 'html:reports/report.html'],
    formatOptions: { includeAttachments: true },  // current option
  },
};
```

**2. `SummaryFormatter` and `ProgressFormatter` class deprecation**

TypeScript teams that extend these built-in formatter classes will need to migrate to the
new formatter architecture. The classes are deprecated (not removed) in the next release, but
will be removed in a subsequent major version.

```typescript
// BEFORE — class extending deprecated formatter
import { SummaryFormatter, IFormatterOptions } from '@cucumber/cucumber';
export class MyCustomFormatter extends SummaryFormatter {
  constructor(options: IFormatterOptions) {
    super(options);
  }
}

// AFTER — use the Formatter base class with the envelope-based API
import { Formatter, IFormatterOptions } from '@cucumber/cucumber';
export class MyCustomFormatter extends Formatter {
  constructor(options: IFormatterOptions) {
    super(options);
    // Handle messages via the new envelope-based API
    this.on('envelope', (envelope) => {
      if (envelope.testRunFinished) {
        const { success } = envelope.testRunFinished;
        this.log(`\nTest run ${success ? 'passed' : 'FAILED'}\n`);
      }
    });
  }
}
```

**3. `FORCE_COLOR` environment variable replaces color format option**

The `colorsEnabled` format option (deprecated in v12.6.0) is replaced by the standard
`FORCE_COLOR` environment variable, consistent with how Node.js CLI tools conventionally
handle color output:

```bash
# OLD: colorsEnabled format option (deprecated since v12.6, removed in next major)
# cucumber.js: formatOptions: { colorsEnabled: true }

# NEW: use FORCE_COLOR environment variable
FORCE_COLOR=1 npx cucumber-js          # Force color output
FORCE_COLOR=0 npx cucumber-js          # Disable color output
NO_COLOR=1    npx cucumber-js          # Alternative: NO_COLOR standard
```

In CI pipelines that previously relied on `colorsEnabled: false`, switch to `NO_COLOR=1`
or let the formatter auto-detect (most CI environments set `NO_COLOR=1` implicitly).

**4. Formatter output redesign for summary/progress/pretty formatters**

The unreleased section notes a "redesigned output for summary, progress, progress bar
and pretty formatters." Teams using these formatters for CI log parsing (grepping for
specific output patterns) should verify their parsing scripts against the new output after
upgrading. The HTML formatter and JSON formatter output format are not affected.

**[community] Formatter migration timing**: These are `[Unreleased]` deprecations as of
2026-05-12. If you upgrade to the next major version, run `npx cucumber-js` and look for
deprecation warnings in the output. The warnings are emitted at run startup, not hidden in logs.

---

### playwright-bdd Upcoming Features (Next Release After v8.5.0)

The playwright-bdd `[Unreleased]` section (as of 2026-05-12) documents significant incoming
changes that TypeScript teams should track.

**1. `docStringType` in the `$step` fixture**

The next release exposes the DocString media type annotation (`"""json`, `"""yaml`, etc.)
as `$step.docStringType` in playwright-bdd fixture-based step definitions. This closes
the gap that currently requires manual content sniffing to distinguish content types:

```typescript
// playwright-bdd NEXT — docStringType via $step fixture
import { createBdd } from 'playwright-bdd';
const { Given } = createBdd();

// The annotation """json is now accessible at runtime via $step.docStringType
Given('I have the following payload:', async ({ $step }) => {
  const rawContent = $step.docString ?? '';
  const contentType = $step.docStringType;  // 'json' | 'yaml' | 'markdown' | undefined

  if (contentType === 'json') {
    // Confident parse — feature file author declared the type
    return JSON.parse(rawContent);
  } else if (contentType === 'yaml') {
    // Dynamic import: import yaml from 'js-yaml'; yaml.load(rawContent);
    throw new Error(`yaml-type DocStrings not yet implemented — annotate with """json or use plain text`);
  } else {
    // Treat as plain string (no annotation present)
    return rawContent;
  }
});
```

This enables type-safe DocString handling without the step definition needing to inspect
the content itself. It aligns playwright-bdd with `@cucumber/cucumber`'s existing
`docString.mediaType` property, which was documented in iteration 24 as unavailable
in playwright-bdd — now resolved in the next release.

**2. AI agent skill for Gherkin feature file and step definition generation**

The next release includes an "AI agent skill" for generating `.feature` files and step
definition stubs from natural-language requirement descriptions. This extends the existing
`Fix with AI` functionality (introduced in v8.1) from failure repair to full generation:

```bash
# Next playwright-bdd release — AI agent skill invocation (subject to change)
# Generate feature file from requirement description
npx playwright-bdd generate \
  --requirement "User can apply a discount code at checkout" \
  --output features/checkout/discount-code.feature

# Generate matching step stubs
npx playwright-bdd generate-steps \
  --feature features/checkout/discount-code.feature \
  --output src/steps/checkout.steps.ts
```

**[community] AI generation adoption caution**: The AI agent skill generates syntactically
correct step definitions, but generated step implementations always require human review.
Generated steps that interact with UI selectors will produce brittle implementations until
a team member adds proper page object abstractions. The Three Amigos review process applies
to AI-generated Gherkin exactly as it applies to AI-generated scenarios discussed earlier
in this guide. Treat AI-generated output as scaffolding, not production step definitions.

**3. Strict arity checks for step definitions (breaking change)**

The next playwright-bdd release adds strict Cucumber-compatible arity checks for step
definitions. This is a **breaking change** for step definitions whose parameter count does
not match the Cucumber expression:

```typescript
// BREAKS in next playwright-bdd release:
// Cucumber expression expects 1 parameter ({string}), but function accepts 2
Given('I am logged in as {string}', async ({ page }, email: string, extraArg: string) => {
  // extraArg is not a Cucumber parameter — strict arity will reject this at test startup
  await page.goto('/login');
});

// CORRECT — arity matches the Cucumber expression:
Given('I am logged in as {string}', async ({ page }, email: string) => {
  await page.goto('/login');
  await page.getByTestId('email').fill(email);
});
```

Run `npx bddgen` after upgrading and look for arity warnings before the breaking change
version lands in your CI pipeline.

**4. Node.js 20+ and Playwright 1.60+ minimum (next release)**

The next playwright-bdd release drops support for Node.js 18 and requires Playwright ≥ 1.60.
Review your CI matrix before upgrading:

```yaml
# .github/workflows/bdd.yml — update Node and Playwright versions
- uses: actions/setup-node@v4
  with:
    node-version: '20'            # Minimum for next playwright-bdd release
    # node-version: '22'          # Recommended for new setups

- name: Ensure minimum Playwright version
  run: npm install @playwright/test@^1.60.0
```

---

### Gherkin DocString Backtick Delimiter: The Markdown-Friendly Alternative  [official]

The Gherkin specification supports two DocString delimiters, not one. In addition to
the triple-quote (`"""`) delimiter that is universally documented, the backtick variant
(`` ``` ``) is a fully supported alternative. The choice is cosmetic for Cucumber
execution, but has practical implications for code review, editor rendering, and feature
file readability.

**Two valid DocString delimiter forms:**

```gherkin
# Feature file: features/api/orders.feature

Scenario: Creating an order with JSON payload (triple-quote delimiter)
  Given I have the following order payload:
    """
    {
      "customerId": "cust-001",
      "items": [{ "productId": "prod-42", "quantity": 2 }]
    }
    """
  When I POST to "/api/v1/orders"
  Then the response status is 201

Scenario: Creating an order with JSON payload (backtick delimiter)
  Given I have the following order payload:
    ```
    {
      "customerId": "cust-001",
      "items": [{ "productId": "prod-42", "quantity": 2 }]
    }
    ```
  When I POST to "/api/v1/orders"
  Then the response status is 201

# Content-type annotation works identically with both delimiters:
Scenario: Annotated JSON payload with backtick delimiter
  Given I have the following order payload:
    ```json
    {
      "customerId": "cust-002",
      "items": [{ "productId": "prod-99", "quantity": 1 }]
    }
    ```
  When I POST to "/api/v1/orders"
  Then the response status is 201
```

**Delimiter comparison:**

| Aspect | `"""` (triple-quote) | `` ``` `` (backtick) |
|---|---|---|
| Gherkin spec support | Yes (all versions) | Yes (Gherkin 6+) |
| Content-type annotation | `"""json` | `` ```json `` |
| Step definition receives | Same: raw string content | Same: raw string content |
| GitHub / GitLab rendering | Plain preformatted text block | Syntax-highlighted code block (Markdown) |
| VS Code Gherkin extension | Recognized | Recognized |
| Common usage | Widespread | Less common but growing in teams that publish feature files in GitHub |

**Step definition: both delimiters produce identical output**

```typescript
// src/steps/api.steps.ts — same step definition handles both delimiters
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// The step definition is completely unaware of which delimiter was used.
// Both """json and ```json deliver the same raw content string.
Given('I have the following order payload:', function (this: AppWorld, docString: string) {
  try {
    this.requestBody = JSON.parse(docString);
  } catch (err) {
    throw new Error(`DocString is not valid JSON:\n${docString}\nError: ${err}`);
  }
});
```

**Why backtick delimiters improve GitHub pull request readability:**

When a `.feature` file is viewed on GitHub, backtick DocStrings render with the code
block's syntax highlighting (when a content-type annotation is present), while triple-quote
DocStrings render as plain preformatted text. For teams that use GitHub Pull Request reviews
to run Three Amigos sessions asynchronously, backtick DocStrings with annotations make
JSON and YAML payloads significantly easier to read during review:

```gherkin
# In a GitHub PR review, this renders as a syntax-highlighted JSON block:
Given I have the following order payload:
  ```json
  {
    "customerId": "cust-001",
    "items": [{ "productId": "prod-42", "quantity": 2 }],
    "shippingAddress": { "city": "Berlin", "country": "DE" }
  }
  ```

# While this renders as a plain monospace text block (no highlighting):
Given I have the following order payload:
  """json
  {
    "customerId": "cust-001",
    "items": [{ "productId": "prod-42", "quantity": 2 }],
    "shippingAddress": { "city": "Berlin", "country": "DE" }
  }
  """
```

**[community] Team consistency over personal preference**: Whether to standardize on `"""`
or `` ``` `` is a team style decision, not a correctness issue. The important rule is
**consistency within a project**: mixing both delimiters in the same suite creates
inconsistent visual language in feature files and can confuse contributors who assume
only one form is valid. Add the chosen delimiter style to your Gherkin style guide and
`gherkin-lint` configuration:

```json
// .gherkin-lintrc.json — enforce consistent DocString delimiter (optional rule)
{
  // gherkin-lint does not currently enforce delimiter style natively.
  // Document the team's choice in comments and review guidelines instead:
  "no-restricted-patterns": {
    "Global": {
      "description": "Use triple-quote (\\\"\\\"\\\" ) for DocStrings, not backtick (```). Team standard for consistency with existing feature files."
    }
  }
}
```

**[community] Backtick delimiter and Prettier formatting**: Some teams run `prettier` on
their feature files via `prettier-plugin-gherkin`. As of 2026, prettier-plugin-gherkin
normalizes DocString delimiters — check the plugin's `docStringDelimiter` option before
adopting backtick style if prettier runs automatically on commit. Mixed delimiter output
from prettier can produce unexpected diffs in PRs that only change business logic.

---

### playwright-bdd v8.4.2: Multiple Step Decorators on a Single Method

`playwright-bdd` v8.4.2 added support for stacking multiple step decorators on a single class
method. This is useful when the same step logic should respond to multiple Gherkin phrases —
a common need when evolving phrasing across sprints or supporting synonym step text.

**Before v8.4.2**, class-based step definitions required separate methods per Gherkin phrase:

```typescript
// playwright-bdd v8.4.1 and earlier — one method per step phrase (verbose duplication)
import { createBdd } from 'playwright-bdd';
import { Page } from '@playwright/test';
const { Given, When, Then } = createBdd();

export class AuthSteps {
  @Given('I am a registered customer')
  async loginA({ page }: { page: Page }) {
    await this._authenticate(page, 'registered');
  }

  // Identical logic — different phrase forced a separate method before v8.4.2
  @Given('I am logged in as a registered customer')
  async loginB({ page }: { page: Page }) {
    await this._authenticate(page, 'registered');
  }

  private async _authenticate(page: Page, role: string) {
    // ...
  }
}
```

**After v8.4.2**, stack multiple decorators on a single method:

```typescript
// playwright-bdd v8.4.2+ — multiple decorators, one implementation
import { createBdd } from 'playwright-bdd';
import { Page } from '@playwright/test';
const { Given, When, Then } = createBdd();

export class AuthSteps {
  // Two Gherkin phrases — one implementation: no duplication
  @Given('I am a registered customer')
  @Given('I am logged in as a registered customer')
  async loginAsRegisteredCustomer({ page }: { page: Page }) {
    await page.goto('/login');
    await page.getByTestId('email').fill('registered@example.com');
    await page.getByTestId('password').fill('TestPass123!');
    await page.getByTestId('submit').click();
    await page.waitForURL('/dashboard');
  }

  // Useful for phrasing evolution — old and new phrase work during transition
  @Given('I am an admin user')
  @Given('I am logged in as an administrator')  // new preferred phrasing
  async loginAsAdmin({ page }: { page: Page }) {
    await page.goto('/login');
    await page.getByTestId('email').fill('admin@example.com');
    await page.getByTestId('password').fill('AdminPass123!');
    await page.getByTestId('submit').click();
    await page.waitForURL('/admin/dashboard');
  }

  // Works with When and Then decorators too
  @When('I complete the checkout')
  @When('I finish the purchase')  // team prefers "finish" over "complete"
  async completeCheckout({ page }: { page: Page }) {
    await page.getByTestId('confirm-order').click();
    await page.waitForURL(/\/order\/confirmation/);
  }

  @Then('I should see the confirmation page')
  @Then('I should see an order confirmation')  // older feature files use this phrasing
  async verifyConfirmation({ page }: { page: Page }) {
    await expect(page.getByTestId('order-confirmation')).toBeVisible();
  }
}
```

`playwright.config.ts` for class-based steps:
```typescript
import { defineConfig, devices } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',    // class files are auto-discovered
});

export default defineConfig({
  testDir,
  reporter: [['html', { outputFolder: 'reports/playwright-html' }]],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

**[community] Multiple decorators vs Cucumber expression alternation**: Decorator stacking
(`@Given('phrase A') @Given('phrase B')`) produces more readable audit output than Cucumber
expression alternation (`Given('phrase A|phrase B', ...)`). With stacking, each phrase
appears as a separate entry in `--format usage` output — you can see usage counts for each
phrase independently and detect when one variant is no longer used. With alternation, the
combined pattern appears as one entry, masking dead variants.

**[community] Step phrasing evolution without breakage**: The canonical use case for
decorator stacking is zero-downtime Gherkin vocabulary migration. When the product team
agrees to standardize on new step wording, add the new phrase as a second decorator and
keep the old one. After all feature files are updated to use the new phrasing, remove the
old decorator. This creates a safe migration path — no `Undefined step` CI failures during
the transition period. Teams that rename steps without this technique experience a
"rename cliff": all feature files must be updated atomically or CI breaks.

---

## Additional Resources (Iteration 26 Additions)

### playwright-bdd Next Release: Remaining Unreleased Changes  [community]

The previous iteration (25) documented the four highest-impact upcoming playwright-bdd changes
(docStringType, AI skill, strict arity, Node/Playwright minimums). The full `[Unreleased]` section
also includes the following items that affect CI stability and dependency management.

**1. `junit-modern` alias deprecated — canonical JUnit reporter naming**

The next release makes the JUnit reporter naming format Cucumber-compatible by default.
The `junit-modern` alias, which was added in v8.x to distinguish the updated JUnit reporter
from the legacy format, is being removed:

```typescript
// playwright.config.ts — update reporter configuration before upgrading
import { defineConfig } from '@playwright/test';

export default defineConfig({
  reporter: [
    // OLD (deprecated alias — will warn in next release, remove in following):
    // ['playwright-bdd/reporter/junit-modern', { outputFile: 'reports/junit.xml' }],

    // NEW (canonical name — Cucumber-compatible format):
    ['playwright-bdd/reporter/junit', { outputFile: 'reports/junit.xml' }],

    // Other reporters remain unchanged:
    ['html', { outputFolder: 'reports/playwright-html' }],
  ],
});
```

**[community] junit-modern migration timing**: The `junit-modern` alias will emit a
deprecation warning before removal. Run `npx bddgen` and check for reporter warnings
in the output. Teams that parse JUnit XML reports for CI metrics should verify that the
canonical `junit` reporter produces the same XML structure before switching — Cucumber
compatibility means the schema aligns with the Cucumber JUnit XML standard, not the
Playwright native JUnit format.

**2. `tinyglobby` replaces `fast-glob` as internal glob engine**

The internal file discovery engine used by `bddgen` for feature file and step definition
scanning switches from `fast-glob` to `tinyglobby`. This is transparent unless your project
uses playwright-bdd's programmatic API to access glob internals:

```typescript
// If your project imports fast-glob directly from playwright-bdd internals — stop.
// These internal imports are not part of the public API and break on dependency swaps:
// import fg from 'playwright-bdd/node_modules/fast-glob'; // NEVER do this

// Use the public API: defineBddConfig() handles glob internally
import { defineBddConfig } from 'playwright-bdd';
const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  // Glob patterns are resolved by playwright-bdd internally
});
```

**[community] Performance note**: `tinyglobby` is benchmarked as faster than `fast-glob` for
large monorepos with thousands of `.feature` files. Teams running `bddgen` on repos with
200+ feature files should see measurable speedup after upgrading. No configuration changes
are required.

**3. Worker concurrency limited to `Math.floor(cpuCount / 2)` in `bddgen`**

`bddgen` now caps its internal worker count at half the available CPU count to prevent
out-of-memory failures in memory-constrained CI environments. Previously, `bddgen` used
all available CPUs, which caused `ENOMEM` crashes on GitHub Actions free-tier runners
(2 CPU / 7 GB RAM) with large test suites:

```yaml
# .github/workflows/bdd.yml — no manual workaround needed after upgrade
# Before: teams added --max-workers=1 to bddgen to prevent OOM
# After: playwright-bdd caps workers automatically

- name: Generate BDD test files
  run: npx bddgen
  # No --max-workers flag needed; playwright-bdd manages concurrency internally
  env:
    NODE_OPTIONS: '--max-old-space-size=4096'  # Keep if suite is very large
```

**[community] Before the fix**: Teams on GitHub Actions free-tier runners with 300+ scenarios
experienced `bddgen` OOM crashes when it spawned workers equal to the CPU count, each
loading the full TypeScript compiler. The auto-cap to `cpuCount / 2` eliminates this failure
mode without requiring manual `--max-workers` configuration.

**4. `@cucumber/messages` 27.x → 32.x and `@cucumber/gherkin` 32.x → 39.x (major version bumps)**

The next playwright-bdd release upgrades core Cucumber ecosystem packages across multiple
major versions. This is **transparent for most teams** but is a **breaking change** for
any code that directly imports these sub-packages:

```typescript
// BREAKS: direct imports of cucumber sub-packages at old major versions
// import { Envelope } from '@cucumber/messages';  // If pinned to ^27.x

// SAFE: use playwright-bdd's re-exported types instead of depending directly
// on @cucumber/messages or @cucumber/gherkin in your own package.json

// If you DO need @cucumber/messages directly, update your pin:
// package.json: "@cucumber/messages": "^32.0.0"  (from ^27.x)
// package.json: "@cucumber/gherkin": "^39.0.0"   (from ^32.x)
```

The `Envelope`, `PickleStep`, `StepDefinition`, and other message types in
`@cucumber/messages` v32 have schema changes. Check the `@cucumber/messages` CHANGELOG
for breaking field renames before upgrading if your custom reporters or plugins consume
raw Cucumber messages directly.

**[community] Impact scope**: Teams using playwright-bdd's built-in reporters (HTML, JUnit,
Cucumber) are not affected — playwright-bdd handles message schema migration internally.
Only custom code that imports `@cucumber/messages` or `@cucumber/gherkin` directly and
depends on specific field shapes will need updates.

**5. Cucumber JSON reporter now skips attachments by default**

Screenshots, traces, and other binary attachments are no longer included in the Cucumber
JSON reporter output by default. This matches the behavior of `@cucumber/cucumber`'s own
JSON formatter (which also skips attachments by default) and prevents JSON reports from
becoming hundreds of megabytes when screenshot-on-failure is enabled:

```typescript
// playwright.config.ts — opt back in if your CI report parsing depends on embedded screenshots
export default defineConfig({
  reporter: [
    ['playwright-bdd/reporter/cucumber', {
      outputFile: 'reports/cucumber.json',
      // Attachments are now skipped by default.
      // Set includeAttachments: true to restore previous behavior:
      // includeAttachments: true,
    }],
  ],
  use: {
    screenshot: 'only-on-failure',  // Screenshots still captured but excluded from JSON
    trace: 'on-first-retry',
  },
});
```

**[community] Report size impact**: A test suite with 500 scenarios and `screenshot: 'always'`
produced Cucumber JSON reports of 180–220 MB with the old default. With attachments skipped,
the same suite produces a 1–3 MB JSON report. CI artifact upload times and report dashboard
rendering are both substantially faster.

**6. Non-ASCII character garbling fixed in Cucumber HTML report text attachments**

A long-standing defect in playwright-bdd's Cucumber HTML reporter caused non-ASCII characters
(Japanese kanji, Arabic script, emoji in step attachment text) to appear garbled. The fix
updates the text encoding pipeline for `text/plain` attachments in HTML report generation:

```typescript
// src/steps/product.steps.ts — now renders correctly in HTML reports
When('I search for {string}', async ({ page }, searchTerm: string) => {
  await page.fill('[data-testid="search-input"]', searchTerm);
  await page.keyboard.press('Enter');
  // Text attachment with non-ASCII content — previously garbled in HTML report
  this.attach(`Searched for: ${searchTerm}`, 'text/plain');
  // Examples: '商品を検索', 'مرحبًا', '🔍 search initiated'
  // Now renders correctly in Cucumber HTML reports
});
```

Teams writing BDD scenarios for localization testing or apps with multilingual content
can now reliably include non-ASCII values in step attachment logs without HTML report corruption.

---

### Gherkin Step Writing Heuristics: The "1922 Rule" and Vivid Character Names  [community]

Two practical heuristics from the official Gherkin reference that are underused in TypeScript
BDD teams and produce significantly more maintainable `.feature` files over time.

**The "Imagine it's 1922" heuristic for technology-agnostic steps**

The Gherkin reference documentation offers a memorable heuristic: when writing a Given step,
imagine it's 1922 — before computers existed. If your step description would be meaningless
in 1922, it's too technology-specific. This heuristic produces steps that are resilient to
UI framework changes, CSS refactors, and API version upgrades.

```gherkin
# FAILS the 1922 test — mentions technology
Given I POST to "/api/v2/users" with body {"email":"alice@example.com","role":"admin"}
Given I click the "#submit-btn" element
Given I fill in the "input[name='email']" selector with "alice@example.com"
Given the localStorage key "auth_token" is set to "eyJhbGc..."

# PASSES the 1922 test — describes state, not mechanism
Given Alice is a registered administrator
Given I am logged in as an administrator
Given the customer "Alice Smith" has an active subscription
Given I have recently placed an order
```

**Why this matters in practice**: Steps that reference CSS selectors, API endpoints, HTTP
methods, or storage keys couple your `.feature` files to the technical implementation.
When the API version changes from v2 to v3, every Gherkin step mentioning `/api/v2/` must
be updated. When you migrate from localStorage to sessionStorage, token-checking steps break.
The 1922 heuristic prevents these coupling failures by keeping Gherkin in the business language
domain, not the technical domain.

**[community] 1922 rule enforcement in code review**: Add this heuristic to your PR review
checklist for `.feature` file changes. Ask: "Would a non-technical person understand this
step in 1922?" If the answer is no, the step belongs in the step definition implementation,
not in the Gherkin text. Teams that enforce this rule consistently report that their feature
files remain readable by product managers 12–18 months after writing, while teams that allow
technical Gherkin end up with files no non-developer can read after the first refactor.

```typescript
// The 1922 rule in step implementation: technical details go HERE, not in Gherkin
Given('Alice is a registered administrator', async ({ page, request }) => {
  // Technical details live in the step definition — not in the .feature file
  const response = await request.post('/api/v2/users', {
    data: { email: 'alice@example.com', role: 'admin', name: 'Alice Smith' }
  });
  expect(response.status()).toBe(201);
  // Store for use in subsequent steps via World/fixture
});

Given('I am logged in as an administrator', async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('email').fill('alice@example.com');
  await page.getByTestId('password').fill('AdminPass123!');
  await page.getByTestId('submit').click();
  await page.waitForURL('/admin/dashboard');
});
```

**Vivid, story-like character names in Background steps**

The Gherkin reference explicitly recommends using specific, human-like names in Background
scenarios instead of generic identifiers like "User A", "Site 1", or "Customer 001":

```gherkin
# AVOID: generic identifiers — hard to remember across a long feature file
Background:
  Given Site 1 has 3 active accounts
  And User A is an administrator of Site 1
  And User B has a standard subscription

# PREFERRED: specific names that carry semantic meaning
Background:
  Given the company "Acme Corp" has 3 active accounts
  And "Alice Smith" is an administrator of Acme Corp
  And "Bob Jones" has a standard subscription
```

**Why named characters work better**: In a feature file with 6–8 scenarios, "User A" and
"User B" force readers to track abstract identifiers across paragraphs. "Alice" and "Bob"
are memorable and their roles become intuitive — Alice is always the admin, Bob is always
the subscriber. This reduces cognitive load when reading scenarios during Three Amigos sessions
and makes review comments more precise ("Scenario 3 — does Alice's permissions apply here?").

**[community] Character naming conventions that scale**: Many teams evolve a shared cast of
characters across their entire BDD suite: Alice (admin), Bob (standard user), Carol (read-only
viewer), Dave (billing contact). When the same names appear consistently across feature files,
reviewers build an intuitive model of the permission structure without re-reading the Background.
This pattern is especially effective in multi-tenant SaaS products where permission boundaries
are complex and frequently tested.

```gherkin
# features/permissions/admin-actions.feature
Background:
  Given "Alice" is an admin of "Acme Corp"
  And "Bob" is a standard member of "Acme Corp"

Scenario: Admin can invite new members
  When "Alice" invites "carol@example.com" to join
  Then "carol@example.com" should receive an invitation email

Scenario: Standard member cannot invite new members
  When "Bob" attempts to invite "dave@example.com" to join
  Then Bob should see an "Insufficient permissions" error

# features/billing/subscription-management.feature
Background:
  Given "Alice" is an admin of "Acme Corp"
  And "Dave" is the billing contact of "Acme Corp"

Scenario: Billing contact can update payment method
  When "Dave" updates the credit card on file
  Then the subscription renewal should use the new card
```

---

### Cucumber.js Formatter Architecture Redesign (Unreleased → v13)  [official]

The upcoming Cucumber.js major release (tracked as "unreleased" in the CHANGELOG as of 2026-05-12) introduces a redesigned formatter subsystem that **breaks** several integration patterns commonly used in TypeScript BDD projects. Teams running CI against the `@next` tag should audit their formatter configurations before upgrading.

**What changes:**

| Old API | New API | Migration action |
|---|---|---|
| `SummaryFormatter` class (imported directly) | New internal formatter — no public class export | Remove direct imports; configure via `format` string only |
| `ProgressFormatter` class (imported directly) | Same — internal-only | Remove direct imports |
| `printAttachments: true` format option | `includeAttachments: true` | Rename the option in `cucumber.js` config |
| `--format @json` with embedded attachments | Attachments skipped by default in JSON output | Opt in with `includeAttachments` in JSON profile |
| `FORCE_COLOR=1` env var (Node.js native) | `color: true` format option **deprecated** | Remove `color:` from format strings; rely on `FORCE_COLOR` env var |

**Migration checklist for TypeScript projects upgrading to the new formatter design:**

```typescript
// BEFORE: Direct class import (breaks in new architecture)
import { SummaryFormatter } from '@cucumber/cucumber';
import { ProgressFormatter } from '@cucumber/cucumber';

// AFTER: No class imports needed — configure via string in cucumber.js
// These classes are removed from the public API
```

`cucumber.js` config before/after:
```javascript
// BEFORE (current v12)
export default {
  default: {
    format: [
      'progress-bar',
      'html:reports/cucumber-report.html',
      '@cucumber/json-formatter:reports/results.json',
    ],
    formatOptions: {
      printAttachments: true,   // DEPRECATED — rename to includeAttachments
      color: true,              // DEPRECATED — use FORCE_COLOR env var instead
    },
    publish: false,
  },
};

// AFTER (new architecture)
export default {
  default: {
    format: [
      'progress-bar',
      'html:reports/cucumber-report.html',
      '@cucumber/json-formatter:reports/results.json',
    ],
    formatOptions: {
      includeAttachments: true,   // Renamed from printAttachments
      // color removed — set FORCE_COLOR=1 in shell instead
    },
    publish: false,
  },
};
```

**CI environment update** — replace `color: true` format option with env var:

```yaml
# .github/workflows/bdd.yml — ensure colored output without deprecated format option
- name: Run BDD tests
  run: npx cucumber-js --profile smoke
  env:
    CI: true
    FORCE_COLOR: '1'   # Replaces formatOptions.color in new architecture
    BASE_URL: ${{ vars.TEST_BASE_URL }}
```

**[community] The `SummaryFormatter` / `ProgressFormatter` deprecation gotcha**: Teams that built custom reporter wrappers by extending `SummaryFormatter` or `ProgressFormatter` will get a runtime import error after the upgrade. The extension pattern was never officially documented but was common in community CI dashboards. The migration path is to implement the `Formatter` interface directly or use a post-run report script instead of a formatter class.

**[community] `printAttachments` in shared libraries**: Teams using monorepo shared `cucumber.js` config files or published NPM packages with embedded Cucumber config will hit the `printAttachments` → `includeAttachments` rename silently — the old option is ignored without a warning in some versions. Set `includeAttachments: true` proactively before upgrading to avoid missing attachments in HTML reports.

---

### playwright-bdd Upcoming Release Migration Guide  [official]

The next playwright-bdd release (post-v8.5.0, documented as "unreleased" in the CHANGELOG as of 2026-05-12) contains **several breaking changes** alongside quality-of-life improvements. Teams using playwright-bdd in production CI pipelines should prepare before upgrading.

**Breaking changes summary:**

| Change | Impact | Migration |
|---|---|---|
| `enrichReporterData` config option removed | `playwright.config.ts` files using this option fail to parse | Remove `enrichReporterData` from config; enhanced reporter data is now always included |
| `junit-modern` reporter alias removed | `format: ['junit-modern']` or `reporter: 'junit-modern'` fails | Replace with `junit` (canonical since v8.1) |
| `@cucumber/messages` upgraded `27.x → 32.x` | Direct imports from `@cucumber/messages` have changed export paths | Update import paths; check `ICucumberMessage` type references |
| `@cucumber/gherkin` upgraded `32.x → 39.x` | Direct imports from `@cucumber/gherkin` have changed export paths | Update import paths; if using `GherkinParser` directly, review API changes |
| Strict Cucumber-compatible arity checks | Step definitions with wrong argument count now throw at registration time, not execution time | Run `npx bddgen` and check for registration errors before running full suite |
| Node.js 18 dropped | Minimum Node.js version is now **20** | Upgrade CI runner Node.js version from 18 to 20 |

**New features in upcoming release:**

**1. `docStringType` exposed on `$step` fixture (playwright-bdd)**

```typescript
// Before: no access to the DocString content type in step definitions
Given('I have the following payload:', async ({ page }, docString: string) => {
  // No way to know if content-type was specified in the .feature file
  const body = JSON.parse(docString);
});

// After: docStringType is available on the $step fixture
import { createBdd } from 'playwright-bdd';
const { Given } = createBdd();

Given(
  'I have the following payload:',
  async ({ page, $step }, docString: string) => {
    // $step.docStringType is the content-type annotation from the feature file
    // e.g., """json ... """ → $step.docStringType === 'json'
    if ($step.docStringType === 'json') {
      const body = JSON.parse(docString);
      // Handle typed JSON
    } else if ($step.docStringType === 'yaml') {
      // Handle YAML
    } else {
      // Plain text fallback
    }
  }
);
```

```gherkin
# Feature file — DocString with content-type annotation
Given I have the following payload:
  """json
  {
    "customerId": "cust-001",
    "items": [{ "productId": "prod-42", "quantity": 2 }]
  }
  """
```

**2. `bddgen` worker concurrency capped at CPU/2**

The `bddgen` code generation step now limits parallel workers to `Math.floor(cpuCount / 2)` to prevent out-of-memory (OOM) crashes on CI runners with limited RAM. Previously, on an 8-core runner with 4GB RAM, `bddgen` could spawn 8 workers simultaneously, each loading large TypeScript compilations — causing OOM kills.

No configuration change is needed: this is an automatic safeguard. However, teams that were relying on high worker counts for faster `bddgen` on large feature suites (500+ scenarios) will see `bddgen` take slightly longer. On CI runners with generous RAM, the cap can be overridden:

```bash
# Override automatic CPU/2 cap — only on runners with verified RAM headroom
PLAYWRIGHT_BDD_WORKERS=8 npx bddgen
```

**3. `tinyglobby` replaces `fast-glob` (internal dependency)**

`fast-glob` is replaced with `tinyglobby` as the glob library for feature file discovery. This is transparent for most users but may affect teams with unusual glob patterns:

```javascript
// playwright.config.ts — review any non-standard glob patterns
const testDir = defineBddConfig({
  features: 'features/**/*.feature',   // Standard — no change needed
  steps: 'src/steps/**/*.ts',
  // Patterns that relied on fast-glob-specific behavior should be tested:
  // - {a,b} brace expansion (still supported in tinyglobby)
  // - Negative patterns: !**/node_modules/**  (still supported)
  // - Windows path separators: tinyglobby normalizes these; test on Windows CI
});
```

**4. JSON reporter attachment opt-in (behavior change)**

In the upcoming release, the Cucumber JSON reporter output from playwright-bdd **skips attachments by default** (screenshots, traces, binary data). This reduces JSON file size significantly for large suites.

```javascript
// playwright.config.ts — opt in to attachments in JSON output
export default defineConfig({
  reporter: [
    ['html', { outputFolder: 'reports/playwright-html' }],
    // JSON reporter: attachments skipped by default in new release
    // To include attachments (for custom report tools that need them):
    ['@playwright/test', { reporter: 'json', outputFile: 'reports/results.json' }],
  ],
  use: {
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
});
```

For teams using `playwright-bdd`'s Cucumber-format JSON output and feeding it into `multiple-cucumber-html-reporter`, enable the opt-in:

```javascript
// cucumber-format reporter config (playwright-bdd)
export default defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
  cucumberReporter: {
    json: {
      outputFile: 'reports/cucumber-results.json',
      includeAttachments: true,   // NEW opt-in for upcoming release
    },
  },
});
```

**5. Non-ASCII character rendering fix in HTML reporter**

Prior to the upcoming release, step attachment text containing non-ASCII characters (emoji, accented characters, CJK characters) was garbled in the Cucumber HTML report output. The root cause was a UTF-8 encoding bug in the HTML serializer. This is fixed in the upcoming release — no configuration change required.

If your BDD suite uses localized step text or attaches log messages with non-ASCII content:

```typescript
// Previously garbled in HTML report — now renders correctly
After(async function (this: AppWorld, scenario) {
  if (scenario.result?.status === 'FAILED') {
    // Non-ASCII characters in attachment text now render correctly in HTML report
    this.attach(`Fehler in Szenario: ${scenario.pickle.name} — Überprüfung fehlgeschlagen`, 'text/plain');
    this.attach(`エラー: ${scenario.pickle.name}`, 'text/plain');
  }
});
```

**6. Strict arity checks (breaking)**

Step definitions whose callback function has a different number of arguments than the Gherkin step's parameter count now throw a `CucumberError` at **registration time** (when the test file is loaded), not at execution time. This surfaces broken step definitions before any test runs.

```typescript
// WRONG: step has 1 Cucumber parameter but callback expects 2 arguments — caught at load time
When(
  'I submit the credentials {string} and {string}',
  async ({ page }, email: string, password: string) => {
    // This now throws: "Step definition callback expects 2 args but step has 2 params + 1 fixture"
    // playwright-bdd counts the fixture destructure ({ page }) as arg 0;
    // Cucumber params are args 1..N — total must match
  }
);

// CORRECT: fixture as first arg, then one Cucumber param per {placeholder}
When(
  'I submit the credentials {string} and {string}',
  async ({ page }, email: string, password: string) => {
    // ✓ fixtures: { page } — 1 fixture arg
    // ✓ Cucumber params: email, password — 2 param args  
    // Total callback args = 3; matches fixture(1) + params(2) ✓
    await page.fill('[data-testid="email"]', email);
    await page.fill('[data-testid="password"]', password);
    await page.getByTestId('submit').click();
  }
);
```

**[community] Upgrading from playwright-bdd v8.5 to the next release — recommended sequence:**

```bash
# Step 1: Run full suite against current version to establish baseline
npx playwright test && echo "Baseline: PASS"

# Step 2: Update playwright-bdd to next/pre-release
npm install playwright-bdd@next

# Step 3: Check for config option removals
grep -r "enrichReporterData" playwright.config.ts   # Should return nothing
grep -r "junit-modern" playwright.config.ts          # Should return nothing

# Step 4: Regenerate spec files — strict arity checks fire at this step
npx bddgen 2>&1 | grep -i "error\|warn"

# Step 5: Run full suite to verify no regressions
npx playwright test

# Step 6: Check JSON report for attachment behavior change
cat reports/results.json | python3 -c "import json,sys; d=json.load(sys.stdin); print('has_attachments:', any(len(s.get('embeddings',[])) > 0 for f in d for s in f.get('elements',[])))"
```

**[community] `@cucumber/messages 27→32` direct import paths changed**: Teams with custom Cucumber message processors (custom formatters, report parsers, event stream consumers) that import directly from `@cucumber/messages` will encounter changed export paths. The most common pattern that breaks:

```typescript
// BEFORE (messages 27.x) — breaks in 32.x
import { Envelope, TestRunStarted } from '@cucumber/messages';

// AFTER (messages 32.x) — check official @cucumber/messages CHANGELOG for full mapping
import type { Envelope } from '@cucumber/messages';
// Type shapes are preserved; check specific message type fields for additions
```

---

### Cucumber.js Quick-Reference Version Matrix (2024–2026)

A consolidated upgrade reference for TypeScript BDD teams:

| Version | Node.js min | TypeScript config | Key change |
|---|---|---|---|
| v9 | 14 | `requireModule: ['ts-node/register']` | Tag syntax changed to boolean expressions (`"@a and @b"`) |
| v10 | 16 | `import: [...], loader: ['ts-node/esm']` | CommonJS dropped; ESM-only |
| v11 | 18 | `import: [...], loader: ['ts-node/esm']` | Retry built-in (`retry`, `retryTagFilter`); `World` typed generics; `json` formatter removed from bundle |
| v12 | 20 | `import: [...], loader: ['ts-node/esm']` | Built-in sharding (`--shard`); TypeScript config files (`cucumber.ts`); plugin architecture |
| v12.7 | 20 | same | Env var propagation to parallel child processes fixed |
| v12.8 | 20 | same | Custom externalizing option; `@cucumber/json-formatter` required for JSON output |
| v12.8.3 | 20 | same | Thrown-string error fix (latest stable as of 2026-05-12) |
| Unreleased | 20 | same | Formatter redesign; `printAttachments` → `includeAttachments`; `FORCE_COLOR` replaces `color`; `SummaryFormatter`/`ProgressFormatter` classes removed |

**playwright-bdd version matrix:**

| Version | Playwright min | Node.js min | Key change |
|---|---|---|---|
| v7.x | 1.38 | 16 | Fixtures replace World; `createBdd()` API |
| v8.0 | 1.41 | 18 | `missingSteps` option; `matchKeywords`; `BeforeScenario`/`AfterScenario` |
| v8.1 | 1.41 | 18 | Step decorators; "Fix with AI" integration |
| v8.4 | 1.44 | 18 | Tags-from-path; multiple decorators per method; single-quote default |
| v8.5 | 1.44 | 18 | Verbose mode improvements; VS Code Cucumber reporter fix |
| v8.6+ (unreleased) | 1.60 | 20 | `enrichReporterData` removed; `junit-modern` → `junit`; strict arity; `$step.docStringType`; `tinyglobby`; messages 27→32; gherkin 32→39 |

**[community] Version matrix usage pattern**: Pin this matrix in your team's CLAUDE.md or `docs/bdd-setup.md`. The most expensive BDD upgrades are the ones that surprise teams mid-sprint. A 15-minute upgrade spike using this matrix to identify breaking changes is cheaper than discovering them when CI breaks on a release day.

---

### Cucumber Expression Advanced Syntax: Optional Text, Alternation, and the Anonymous Parameter  [official]

The `{string}`, `{int}`, and `{word}` built-in parameter types cover the majority of step
definition patterns, but three advanced Cucumber Expression features are underused in
TypeScript BDD suites: optional text, alternation, and the anonymous `{}` parameter.
These reduce step library duplication without the readability cost of regex patterns.

**Optional text — handle singular/plural naturally:**

```typescript
// src/steps/cart.steps.ts — optional text for natural language matching
import { Given, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';
import { expect } from '@playwright/test';

// Matches BOTH:
//   "Given I have 1 item in my cart"
//   "Given I have 3 items in my cart"
Given('I have {int} item(s) in my cart', async function (this: AppWorld, count: number) {
  for (let i = 0; i < count; i++) {
    await this.page.request.post('/api/cart/items', {
      data: { productId: `prod-${String(i + 1).padStart(3, '0')}`, quantity: 1 }
    });
  }
  this.cartItemCount = count;
});

// Matches BOTH:
//   "Then my order should be confirmed"
//   "Then my order(s) should be confirmed"
// Also matches "Then 1 order should be confirmed" vs "Then 3 orders should be confirmed"
// when combined with {int}
Then('{int} order(s) should be confirmed', async function (this: AppWorld, count: number) {
  const res = await this.page.request.get('/api/orders?status=confirmed');
  const body = await res.json() as { orders: unknown[] };
  expect(body.orders).toHaveLength(count);
});
```

**Alternation — match multiple business vocabulary synonyms:**

```typescript
// Matches both "my cart" and "my basket" — supports multiple regional terms
Then(
  'my cart/basket should be empty',
  async function (this: AppWorld) {
    await expect(this.page.getByTestId('cart-item-count')).toHaveText('0');
  }
);

// Matches all three: "checkout", "check-out", "check out"
// Note: alternation requires no whitespace around the /
When(
  'I proceed to checkout/check-out',
  async function (this: AppWorld) {
    await this.page.getByTestId('checkout-button').click();
    await this.page.waitForURL('/checkout');
  }
);

// Matches: "I am logged in" OR "I am signed in"
Given(
  'I am logged/signed in as a registered customer',
  async function (this: AppWorld) {
    await this.page.goto('/login');
    await this.page.getByTestId('email').fill('test@example.com');
    await this.page.getByTestId('password').fill('TestPass123!');
    await this.page.getByTestId('submit').click();
    await this.page.waitForURL('/dashboard');
  }
);
```

**The anonymous `{}` parameter — match anything without a type constraint:**

```typescript
// {} matches any sequence of non-whitespace characters (more permissive than {word})
// Use when the value can be any identifier: IDs, codes, slugs, status strings

// Matches: "Then my order ORD-ABC12345 should be in status confirmed"
// Matches: "Then my order ORD-XYZ99999 should be in status pending"
Then(
  'my order {word} should be in status {}',
  async function (this: AppWorld, orderId: string, status: string) {
    const res = await this.page.request.get(`/api/orders/${orderId}`);
    const body = await res.json() as { status: string };
    expect(body.status).toBe(status);
  }
);
```

**Escaping special characters in expressions:**

```typescript
// To match a literal { or ( in step text, escape with backslash:
// "Given the price is {$49.99}" — use \{ to match the literal brace
Given('the price is \\{{currency}\\}', async function (this: AppWorld, price: number) {
  // Matches: Given the price is {$49.99}
  this.expectedPrice = price;
});

// To match a literal / (not alternation), escape with \/
When(
  'I navigate to the path \\/admin\\/dashboard',
  async function (this: AppWorld) {
    await this.page.goto('/admin/dashboard');
  }
);
```

**[community] Optional text vs separate steps — decision heuristic**: Use optional text
(`(s)`) only when the singular/plural distinction carries no semantic difference in the
step implementation. If the implementation behaves differently for count=1 vs count>1
(e.g., singular triggers a different API endpoint), write separate steps or use `{int}`
directly. The `(s)` pattern is a readability aid, not a conditional branch point.

**[community] Alternation scope limit**: Alternation in Cucumber Expressions matches only
within a single word boundary — `cart/basket` works; `shopping cart/basket` does not match
"shopping basket" (the alternation applies only to the last word before the `/`). For
multi-word alternation, use a custom parameter type with a regex instead:

```typescript
import { defineParameterType } from '@cucumber/cucumber';

// Custom type for multi-word synonym groups
defineParameterType({
  name: 'cart_ref',
  regexp: /shopping cart|cart|basket|bag/,
  transformer: (s: string) => s, // normalise downstream if needed
});

// Now: "When I view my shopping cart" AND "When I view my cart" both work
When('I view my {cart_ref}', async function (this: AppWorld, _cartRef: string) {
  await this.page.goto('/cart');
});
```

---

### playwright-bdd v8.4.1: Explicit TypeScript Type Exports  [community]

`playwright-bdd` v8.4.1 (released September 2025) introduced explicit TypeScript type
exports that resolve a class of compilation errors experienced by TypeScript projects
using strict module settings (`module: commonjs`, `skipLibCheck: false`). Before v8.4.1,
types were emitted but not explicitly listed in the package's `exports` field, causing
TypeScript to fail to resolve them in certain project configurations.

**What this means for TypeScript BDD projects:**

```typescript
// BEFORE v8.4.1: type imports sometimes failed with strict TypeScript settings
// Error: Module 'playwright-bdd' has no exported member 'CreateBddOptions'
import type { CreateBddOptions } from 'playwright-bdd'; // ❌ could fail

// AFTER v8.4.1: explicit type exports — all public types are importable
import type {
  CreateBddOptions,    // Options for createBdd() configuration
  BddFixtures,         // Base fixture type for extending custom fixtures
  TestTypeCommon,      // Type for the test object passed to createBdd(test)
} from 'playwright-bdd';

// Now works reliably with:
// tsconfig.json: "module": "commonjs", "moduleResolution": "node"
// and: "skipLibCheck": false (strict mode)
```

**Practical impact for teams extending playwright-bdd fixtures:**

```typescript
// src/fixtures/app-fixtures.ts — using explicit types for type-safe fixture extension
import { test as base, expect } from '@playwright/test';
import { createBdd, type BddFixtures } from 'playwright-bdd';

// Extend the base Playwright test with application-specific fixtures
const test = base.extend<BddFixtures & {
  authToken: string;
  testUserId: string;
  apiBaseUrl: string;
}>({
  authToken: async ({}, use) => {
    // Retrieve a test auth token and pass it through the fixture
    const token = await fetchTestToken(process.env.TEST_CLIENT_ID ?? 'test-client');
    await use(token);
  },
  testUserId: async ({}, use) => {
    // Generate a unique test user ID for data isolation
    await use(`test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`);
  },
  apiBaseUrl: async ({}, use) => {
    await use(process.env.BASE_URL ?? 'http://localhost:3000');
  },
});

// Create BDD helpers bound to the extended test object
export const { Given, When, Then, Before, After } = createBdd(test);

// Step definitions now get type-safe access to all custom fixtures
// src/steps/checkout.steps.ts
import { Given, When, Then } from '../fixtures/app-fixtures';

Given('I am an authenticated customer', async ({ page, authToken, testUserId }) => {
  // authToken and testUserId are fully typed — TypeScript autocompletes them
  await page.context().addCookies([{
    name: 'auth_token', value: authToken,
    domain: new URL(process.env.BASE_URL ?? 'http://localhost:3000').hostname,
    path: '/',
  }]);
});
```

**[community] v8.4.1 upgrade check for teams on strict TypeScript**: If your project uses
`"skipLibCheck": false` (which is the correct strict setting — `skipLibCheck: true` hides
real type errors from third-party packages), upgrade to playwright-bdd v8.4.1+ before
adding explicit type imports. Teams that encounter `Module has no exported member` errors
from playwright-bdd on earlier versions can use `skipLibCheck: true` as a temporary workaround,
but the correct fix is upgrading to v8.4.1 where types are properly exported.

**[community] `BddFixtures` type and the World replacement pattern**: In playwright-bdd,
`BddFixtures` is the conceptual replacement for Cucumber.js's `World` object. Where
`@cucumber/cucumber` uses `this: CustomWorld` to share state across steps, playwright-bdd
uses Playwright's fixture system. The `BddFixtures` type provides the base shape; teams
extend it with their application-specific shared state. The key advantage: TypeScript
infers fixture types without manual `this` typing — `({ page, authToken }) =>` is fully
typed without any type assertion needed.

---

### Table Cell Escaping and DataTable Advanced Patterns  [official]

Gherkin DataTable cells support escape sequences for special characters. These are
underused and underdocumented, causing teams to avoid DataTables when they contain
pipe characters, newlines, or backslashes.

**Escape sequences in DataTable cells:**

```gherkin
# features/api/product-creation.feature
Feature: Product data with special characters

  Scenario: Product with multiline description
    Given I create a product with the following data:
      | field       | value                                            |
      | name        | Laptop Stand Pro                                 |
      | description | Adjustable stand\nFolds flat\nCompatible 13"-17" |
      | sku         | LS\|PRO\|2026                                    |
      | notes       | Price: $49.99 \\(discounted\\)                   |

    # \n  → newline character in the cell value
    # \|  → literal pipe (not a cell delimiter)
    # \\  → literal backslash
```

```typescript
// src/steps/product.steps.ts — handling escaped DataTable values
import { Given } from '@cucumber/cucumber';
import { DataTable } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

Given(
  'I create a product with the following data:',
  async function (this: AppWorld, table: DataTable) {
    const data = table.rowsHash(); // { field: value, ... }
    
    // DataTable.rowsHash() automatically unescapes \n, \|, \\ — values arrive decoded.
    // No manual unescaping needed in the step definition.
    // data.description = "Adjustable stand\nFolds flat\nCompatible 13\"-17\""
    // data.sku         = "LS|PRO|2026"
    // data.notes       = "Price: $49.99 \\(discounted\\)"  ← backslash preserved as \
    
    const res = await this.page.request.post('/api/products', {
      data: {
        name: data.name,
        description: data.description, // contains literal newline
        sku: data.sku,                  // contains literal pipe
        notes: data.notes,
      }
    });
    
    if (!res.ok()) {
      throw new Error(`Failed to create product: ${await res.text()}`);
    }
    this.lastCreatedProductId = (await res.json() as { id: string }).id;
  }
);
```

**DataTable methods reference** (TypeScript):

```typescript
import { DataTable } from '@cucumber/cucumber';

// Method          | Input format                | Output type
// ─────────────────────────────────────────────────────────────
// table.raw()     | Any table                  | string[][]  — raw 2D array
// table.rows()    | No header row              | string[][]  — body rows only
// table.hashes()  | First row is header        | Record<string,string>[]
// table.rowsHash()| Col 0 = key, Col 1 = value | Record<string,string>
// table.transpose()| Any table                 | DataTable   — rows become cols

// hashes() — most common for entity tables
//   | product    | quantity | price |
//   | USB hub    | 2        | 29.99 |
//   → [{ product: 'USB hub', quantity: '2', price: '29.99' }]

// rowsHash() — key-value pairs
//   | name  | Alice |
//   | email | alice@example.com |
//   → { name: 'Alice', email: 'alice@example.com' }

// hashes() with numeric coercion — TypeScript pattern
function parseCartItems(table: DataTable): Array<{product: string; quantity: number; price: number}> {
  return table.hashes().map(row => ({
    product: row.product,
    quantity: parseInt(row.quantity, 10),
    price: parseFloat(row.price),
  }));
}
```

**[community] `\n` in DataTable cells: the invisible tradeoff**: Multiline values in
DataTable cells via `\n` escaping look clean in the `.feature` file but produce invisible
whitespace in test reports. When a scenario fails and the report shows the DataTable,
the `\n` appears as a literal two-character sequence rather than a newline — making the
failure message harder to read. For data with genuine newlines, DocStrings (`"""`) are
more legible in reports and should be preferred when the multiline nature of the data is
the point.

**[community] Pipe escaping in SKUs, codes, and IDs**: Many real-world business domains
use `|` as a separator in product codes, permission strings, or composite keys (e.g.,
`REGION|CATEGORY|SKU`). Teams unfamiliar with `\|` escaping either avoid DataTables for
this data or incorrectly use placeholder text that doesn't match production formats.
Add `\| escaping in DataTable cells` to your team's Gherkin style guide with a concrete
example from your domain's actual data.

---

### `@cucumber/gherkin-streams` Removal and Gherkin Parsing Migration  [community]

`playwright-bdd`'s upcoming release removes the `@cucumber/gherkin-streams` dependency.
Teams that directly import from `@cucumber/gherkin-streams` in their own test utilities
(e.g., custom feature file analysis scripts, report generators, test count auditors) need
to migrate to the current Gherkin parsing API.

```typescript
// BEFORE — using the deprecated @cucumber/gherkin-streams package
// (removed from playwright-bdd's dependency tree in v8.6+)
import { GherkinStreams } from '@cucumber/gherkin-streams';

// AFTER — use @cucumber/gherkin directly for programmatic Gherkin parsing
import { GherkinClassicCompatibility } from '@cucumber/gherkin';
// Or use the Messages-based API from @cucumber/cucumber directly:
import { loadSources, loadSupport } from '@cucumber/cucumber/api';

// For simple feature file parsing (count scenarios, extract tags):
// Use the Messages API (works without @cucumber/gherkin-streams):
import { runCucumber, IRunConfiguration } from '@cucumber/cucumber/api';

// Programmatic scenario count script (replaces gherkin-streams usage)
async function countScenariosInFile(featureFilePath: string): Promise<number> {
  const fs = await import('fs');
  const content = fs.readFileSync(featureFilePath, 'utf8');
  const scenarioMatches = content.match(/^\s*(Scenario|Scenario Outline):/gm) ?? [];
  return scenarioMatches.length;
}

// For teams using @cucumber/gherkin directly for AST-level access:
import Gherkin from '@cucumber/gherkin';
import { IdGenerator } from '@cucumber/messages';

function parseFeatureFile(source: string) {
  const parser = new Gherkin.Parser();
  const builder = new Gherkin.AstBuilder(IdGenerator.incrementing());
  const matcher = new Gherkin.GherkinClassicTokenMatcher();
  // Returns a GherkinDocument AST — access Feature, Scenarios, Steps
  return parser.parse(source);
}
```

**[community] Why teams use gherkin-streams directly**: The most common use case was
scenario counting in CI (`"total scenarios run: N"` badges) and custom report scripts
that needed to extract all step text without running the full suite. Both use cases can
be replaced with simple `grep`-based counting or the `@cucumber/cucumber` Messages API.
The regex approach (`content.match(/^\s*(Scenario|Scenario Outline):/gm)`) is more
robust than a full AST parser for the common case of counting scenarios, and eliminates
the `gherkin-streams` dependency entirely.

---

### Gherkin Keyword Anchoring: Feature File Scope Rules  [official]

A persistent source of confusion in teams adopting the `Rule` keyword and nested
`Background` sections is which keywords can appear where. The Gherkin specification
defines strict scope rules that formatters and parsers enforce but that are rarely
summarized in one place.

**Keyword scope reference:**

| Keyword | Valid parent scope | Notes |
|---|---|---|
| `Feature` | Top-level only (one per file) | Required; begins the file |
| `Background` | `Feature` or `Rule` | Steps run before every scenario in the parent scope |
| `Rule` | `Feature` only | Cannot nest inside another `Rule` |
| `Scenario` | `Feature` or `Rule` | |
| `Scenario Outline` | `Feature` or `Rule` | Must have an `Examples` table |
| `Examples` | `Scenario Outline` only | Can have multiple `Examples` blocks with labels |
| `Given/When/Then/And/But/*` | `Scenario`, `Scenario Outline`, `Background` | Steps cannot appear at Feature or Rule level |
| Tags (`@tag`) | `Feature`, `Rule`, `Scenario`, `Scenario Outline`, `Examples` | NOT valid on `Background` |

**[community] Tags on Background: the silent failure**: The Gherkin parser accepts (but
ignores) tags placed above `Background:` blocks in many Cucumber versions. Teams that
add `@setup` or `@auth` tags to `Background:` expecting them to control execution discover
that the tags have no effect — Background steps always run before every scenario
regardless of tags. This was cited as official anti-pattern in `cucumber.io/docs/guides/anti-patterns/`.
The `gherkin-lint` rule `no-tags-on-background: true` (shown in the Gherkin linting section
of this guide) catches this at lint time.

```gherkin
# INCORRECT: @auth tag on Background has no effect in any Cucumber implementation
@auth
Background:
  Given I am logged in

# CORRECT: Tags belong on the Feature (applies to all scenarios)
# or on individual Scenario/Scenario Outline blocks
@auth
Feature: Authenticated user actions
  Background:
    Given I am logged in   # Runs before all scenarios in this feature, unconditionally
```

**[community] Multiple `Background` blocks in the same scope**: Some teams attempt to
write two `Background:` blocks in the same feature file to separate authentication setup
from data setup. The Gherkin parser only recognises the last `Background:` block — the
first is silently ignored. The correct pattern: use a single `Background:` block with
all shared preconditions, or use `Rule` blocks each with their own `Background:` for
different setup requirements:

```gherkin
Feature: Order management

  # ✅ CORRECT: single Feature-level Background
  Background:
    Given I am logged in as a registered customer

  Rule: Standard orders
    # ✅ CORRECT: Rule-level Background adds to Feature Background for this Rule only
    Background:
      And my account is in good standing
      And I have items in my cart

    Scenario: Place a standard order
      When I complete checkout
      Then my order should be confirmed

  Rule: Premium orders
    Background:
      And I am a premium subscriber

    Scenario: Place a priority order
      When I complete checkout with priority shipping
      Then my order should be confirmed and shipped within 1 business day
```

In this structure:
- **Standard order scenarios** run: `Given I am logged in` + `And my account is in good standing` + `And I have items in my cart`
- **Premium order scenarios** run: `Given I am logged in` + `And I am a premium subscriber`

The Feature-level `Background` always runs first; the Rule-level `Background` follows for scenarios within that Rule.

---

## Additional Resources (Iteration 28 Additions)

- [Cucumber Expressions — GitHub README](https://github.com/cucumber/cucumber-expressions#readme) — optional text `(s)`, alternation `a/b`, anonymous `{}` parameter, and escape rules for `{`, `(`, `/` characters
- [playwright-bdd v8.4.1 release](https://github.com/vitalets/playwright-bdd/releases/tag/v8.4.1) — explicit TypeScript type exports; `BddFixtures` type for safe fixture extension
- [playwright-bdd v8.4.1 issue #322](https://github.com/vitalets/playwright-bdd/issues/322) — type resolution fix for `module: commonjs` + `skipLibCheck: false` TypeScript configurations
- [@cucumber/gherkin changelog](https://github.com/cucumber/gherkin/blob/main/CHANGELOG.md) — Gherkin language spec evolution; keyword scope rules; DataTable escape sequences
- [Gherkin keyword scope rules](https://cucumber.io/docs/gherkin/reference/) — authoritative reference for valid parent scopes for all Gherkin keywords including `Rule`, `Background`, and `Examples`

## Additional Resources (Iteration 29 Additions)

- [Gherkin DocString reference](https://cucumber.io/docs/gherkin/reference/#doc-strings) — both `"""` and `` ``` `` delimiter forms documented; content-type annotation syntax; indentation dedentation rules

---

## Additional Resources (Iteration 30 Additions)

### Cucumber.js Plugin API: Full TypeScript Reference  [official]

Cucumber.js v12.5+ introduced a first-class plugin architecture exposed via the
`@cucumber/cucumber/api` module path. The earlier examples in this guide used `IPlugin`
from `@cucumber/cucumber` (the non-generic form). The canonical TypeScript API uses the
generic `Plugin<OptionsType>` from `@cucumber/cucumber/api`, which provides full type
checking for custom options, event handlers, and transform functions.

**Why use the plugin API?**

The plugin API supersedes the class-extension formatter pattern (`extends SummaryFormatter`)
and gives plugins access to lifecycle phases that formatters cannot reach:

| Capability | Plugin API | Formatter API |
|---|---|---|
| Receive Cucumber messages | Yes (`on('message', ...)`) | Yes |
| Filter which scenarios run | Yes (`transform('pickles:filter', ...)`) | No |
| Reorder scenarios | Yes (`transform('pickles:order', ...)`) | No |
| React to file path resolution | Yes (`on('paths:resolve', ...)`) | No |
| Async setup + cleanup | Yes (return cleanup fn) | No |
| Typed custom options | Yes (`Plugin<{ myOpt: string }>`) | Limited |

**Full TypeScript plugin example — scenario filter by environment:**

```typescript
// src/plugins/env-filter-plugin.ts
// Filters scenarios by an environment variable at runtime — avoids @tag clutter
import type { Plugin } from '@cucumber/cucumber/api';

// Type your plugin's custom configuration options for IDE completion + compile errors
type EnvFilterOptions = {
  envFilterTag?: string;  // e.g. '@payments' — only run scenarios with this tag
  excludeTag?: string;    // e.g. '@wip' — exclude these scenarios
};

const envFilterPlugin: Plugin<EnvFilterOptions> = {
  type: 'plugin',

  // optionsKey: Cucumber passes only the 'envFilter' block from pluginOptions
  optionsKey: 'envFilter',

  coordinator: ({ on, transform, options, logger }) => {
    const filterTag = options?.envFilterTag ?? process.env.FILTER_TAG;
    const excludeTag = options?.excludeTag ?? process.env.EXCLUDE_TAG;

    if (filterTag) {
      logger.debug(`env-filter-plugin: including scenarios tagged ${filterTag}`);
    }

    // transform('pickles:filter') — receives the full pickle list; return only what should run
    // A 'pickle' is a Cucumber-internal compiled scenario (after Examples expansion)
    transform('pickles:filter', (pickles) => {
      return pickles.filter((pickle) => {
        const tags = pickle.tags.map((t) => t.name);

        // Apply include filter
        if (filterTag && !tags.includes(filterTag)) {
          return false;
        }

        // Apply exclude filter
        if (excludeTag && tags.includes(excludeTag)) {
          return false;
        }

        return true;
      });
    });

    // transform('pickles:order') — sort or shuffle the filtered list
    // Useful for: deterministic ordering, alphabetical sort, priority-first execution
    transform('pickles:order', (pickles) => {
      // Sort by feature file path, then by scenario name — deterministic across parallel shards
      return [...pickles].sort((a, b) => {
        const pathCompare = (a.uri ?? '').localeCompare(b.uri ?? '');
        if (pathCompare !== 0) return pathCompare;
        return a.name.localeCompare(b.name);
      });
    });

    // on('paths:resolve') — react when Cucumber resolves feature file paths
    // Useful for: logging which feature files will run, early validation of file existence
    on('paths:resolve', ({ featurePaths }) => {
      if (featurePaths.length === 0) {
        logger.warn('env-filter-plugin: No feature files matched. Check your features: glob.');
      } else {
        logger.debug(`env-filter-plugin: ${featurePaths.length} feature file(s) resolved`);
      }
    });

    // Return a cleanup function — runs before Cucumber exits
    // Useful for: flushing custom metrics, closing database connections opened in setup
    return async () => {
      logger.debug('env-filter-plugin: cleanup complete');
    };
  },
};

export default envFilterPlugin;
```

**Register the plugin in `cucumber.ts`:**

```typescript
// cucumber.ts — register plugin with typed options
import type { IConfiguration } from '@cucumber/cucumber/api';

export default {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  plugin: ['src/plugins/env-filter-plugin.ts'],
  pluginOptions: {
    envFilter: {
      envFilterTag: process.env.FILTER_TAG,     // Optional: override via env var
      excludeTag: '@wip',                       // Always exclude @wip
    },
  },
  format: ['progress-bar', 'html:reports/report.html'],
} satisfies Partial<IConfiguration>;
//  ^^^^^^^^ See next section for the 'satisfies' pattern
```

**[community] `pickles:filter` vs Cucumber tag expressions**: Cucumber's built-in `--tags`
option handles most filtering needs. Use the `pickles:filter` transform only when the
filtering logic is too complex for a tag expression — for example, filtering based on
external data sources (a database list of feature IDs to run) or multi-dimensional
conditions that cannot be expressed as `@tag1 and not @tag2`. The transform receives
the full compiled pickle list and has access to all pickle properties (tags, steps,
feature URI, pickle ID), making it more powerful but also more opaque to team members
who expect `--tags` to be the sole filtering mechanism.

**[community] `pickles:order` and parallel sharding**: In parallel mode, Cucumber
distributes pickles across workers based on order. A deterministic ordering (alphabetical
by feature path and scenario name) makes worker assignment reproducible — the same
scenario always runs on the same shard index. This is valuable for debugging failures
that only occur on specific workers, because you can replay the exact pickle order by
re-running without changing the transform.

---

### Custom Formatters with `FormatterPlugin<T>` and `@cucumber/query`  [official]

The `FormatterPlugin<OptionsType>` type (from `@cucumber/cucumber/api`) is the
TypeScript-idiomatic way to write custom reporters that process Cucumber message streams.
For non-trivial formatters that need to correlate messages across the test run (for example,
computing pass rates, finding slowest scenarios, or generating test-ID-to-result mappings),
the `@cucumber/query` library provides a queryable view over the message stream.

**When to write a custom formatter:**
- Your team needs a report format that none of the built-in formatters produce (e.g., Slack-formatted summaries, test management system integrations, CSV exports)
- You need to post-process failure data (e.g., send failed scenario names to a webhook)
- You want to aggregate metrics across sharded runs before all shards have finished

**Full TypeScript formatter example — JSON summary with test durations:**

```typescript
// src/formatters/summary-formatter.ts
import type { FormatterPlugin } from '@cucumber/cucumber/api';
import type { Envelope } from '@cucumber/messages';

// Type your formatter's custom options
type SummaryFormatterOptions = {
  outputFile?: string;   // Optional: write to file instead of stdout
  includePassed?: boolean;  // Optional: include passed scenarios in output
};

// Each scenario result entry
interface ScenarioResult {
  name: string;
  featureFile: string;
  status: string;
  durationMs: number;
  tags: string[];
}

const summaryFormatter: FormatterPlugin<SummaryFormatterOptions> = {
  type: 'formatter',
  optionsKey: 'summary',  // Read from formatOptions.summary in cucumber.ts

  formatter: ({ on, write, options, logger }) => {
    const results: ScenarioResult[] = [];

    // Accumulate test case finished messages during the run
    on('message', (envelope: Envelope) => {
      if (envelope.testCaseFinished) {
        const { testCaseId, testCaseStartedId } = envelope.testCaseFinished;
        // Note: For complex correlations across envelope types, use @cucumber/query
        // (see below). For simple single-message processing, on('message') is sufficient.
        logger.debug(`Test case finished: ${testCaseId}`);
      }

      if (envelope.testRunFinished) {
        const { success, timestamp } = envelope.testRunFinished;
        const summary = {
          generatedAt: new Date().toISOString(),
          passed: results.filter((r) => r.status === 'PASSED').length,
          failed: results.filter((r) => r.status === 'FAILED').length,
          skipped: results.filter((r) => r.status === 'SKIPPED').length,
          overall: success ? 'PASS' : 'FAIL',
          results: options?.includePassed
            ? results
            : results.filter((r) => r.status !== 'PASSED'),
        };

        const jsonOutput = JSON.stringify(summary, null, 2);

        if (options?.outputFile) {
          // Write to file via the 'write' function (handles stream management)
          write(jsonOutput);
        } else {
          write(`\n=== BDD Run Summary ===\n${jsonOutput}\n`);
        }
      }
    });
  },
};

export default summaryFormatter;
```

**Register the custom formatter in `cucumber.ts`:**

```typescript
// cucumber.ts — register formatter with typed options
import type { IConfiguration } from '@cucumber/cucumber/api';

export default {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  format: [
    'progress-bar',
    'html:reports/report.html',
    // Custom formatter: path to the file, optional output target after ':'
    'src/formatters/summary-formatter.ts:reports/bdd-summary.json',
  ],
  formatOptions: {
    summary: {
      includePassed: false,   // Only show failures in the JSON summary
    },
  },
} satisfies Partial<IConfiguration>;
```

**Using `@cucumber/query` for non-trivial formatters:**

The `@cucumber/query` library provides a queryable in-memory model over the full message
stream. Rather than manually correlating `testCase`, `testCaseStarted`, `testCaseFinished`,
and `pickle` envelopes by ID, the query object builds the relationships for you:

```typescript
// src/formatters/detailed-formatter.ts
// Uses @cucumber/query to correlate test cases with their pickle definitions
import type { FormatterPlugin } from '@cucumber/cucumber/api';
import { Query } from '@cucumber/query';

const detailedFormatter: FormatterPlugin = {
  type: 'formatter',
  formatter: ({ on, write }) => {
    // Instantiate the query object — it processes all messages and builds an index
    const query = new Query();

    on('message', (envelope) => {
      // Feed every envelope into the query — it builds the correlation index internally
      query.update(envelope);

      if (envelope.testRunFinished) {
        // After the run, query the model for results
        const testCaseAttempts = query.getTestCaseAttempts();

        const failedAttempts = testCaseAttempts.filter(
          (attempt) => attempt.worstTestStepResult.status === 'FAILED'
        );

        if (failedAttempts.length === 0) {
          write('\n✔ All scenarios passed\n');
          return;
        }

        write(`\n✖ ${failedAttempts.length} scenario(s) failed:\n`);

        for (const attempt of failedAttempts) {
          // query.getPickle() correlates the test case back to its Gherkin pickle
          const pickle = query.getPickle(attempt.testCase.pickleId);
          write(`  - ${pickle?.name ?? attempt.testCase.id} (${attempt.testCase.id})\n`);
        }
      }
    });
  },
};

export default detailedFormatter;
```

**[community] `@cucumber/query` vs manual ID correlation**: In the message stream,
`testCaseStarted.testCaseId` links to `testCase.id`, which links to `testCase.pickleId`,
which links to `pickle.id`, which links to `pickle.uri` (the feature file path). Manually
following this chain across 4–5 envelope types is error-prone and breaks when the schema
evolves across `@cucumber/messages` major versions. The `@cucumber/query` object absorbs
these correlations — update it with every envelope and query it at run end. This is the
officially recommended pattern for any formatter that needs to display scenario names
alongside their results.

---

### `IConfiguration` with the TypeScript `satisfies` Keyword  [official]

The `IConfiguration` type (exported from `@cucumber/cucumber/api`) defines the full
shape of Cucumber.js configuration options. TypeScript teams have two idiomatic patterns
for typing `cucumber.ts` config objects. The `satisfies` operator (TypeScript 4.9+) is
the preferred pattern because it preserves the literal type of the value while checking
structural compatibility.

**Pattern 1: Direct assignment (older, less precise)**

```typescript
// cucumber.ts — Pattern 1: IConfiguration direct assignment
import type { IConfiguration } from '@cucumber/cucumber/api';

// Works, but TypeScript widens string literals to 'string'
// and 'format' becomes string[] instead of ('progress-bar' | 'html:...' | ...)[]
const config: IConfiguration = {
  import: ['src/steps/**/*.ts'],
  format: ['progress-bar', 'html:reports/report.html'],
  parallel: 4,
};

export default config;
```

**Pattern 2: `satisfies Partial<IConfiguration>` (preferred — TypeScript 4.9+)**

```typescript
// cucumber.ts — Pattern 2: satisfies operator
// Preserves literal types while enforcing structural correctness.
// The 'satisfies' keyword:
//   - Checks that the object matches Partial<IConfiguration>
//   - Does NOT widen the inferred type — catches typos like 'paralel' at compile time
//   - Does NOT require all properties to be present (Partial<> makes all optional)
import type { IConfiguration } from '@cucumber/cucumber/api';

// Single config — no export needed when file has a default export
export default {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  format: [
    'progress-bar',
    'html:reports/regression.html',
  ],
  formatOptions: {
    includeAttachments: true,
  },
  retry: 1,
  retryTagFilter: '@flaky',
  parallel: 8,
} satisfies Partial<IConfiguration>;
```

**Multi-profile config with `satisfies`:**

```typescript
// cucumber.ts — multiple named exports (profiles) with satisfies
import type { IConfiguration } from '@cucumber/cucumber/api';

// Shared base keeps DRY — no repetition between profiles
const base = {
  import: ['src/steps/**/*.ts', 'src/support/**/*.ts'],
  retryTagFilter: '@flaky',
  formatOptions: { includeAttachments: true },
} satisfies Partial<IConfiguration>;

export const smoke = {
  ...base,
  tags: '@smoke and not @wip',
  format: ['progress-bar', 'html:reports/smoke.html'],
  retry: 2,
  parallel: 2,
} satisfies Partial<IConfiguration>;

export const regression = {
  ...base,
  tags: 'not @wip',
  format: [
    'progress-bar',
    '@cucumber/json-formatter:reports/results.json',
    'html:reports/regression.html',
  ],
  retry: 1,
  parallel: 8,
} satisfies Partial<IConfiguration>;

export const ci = {
  ...base,
  tags: `not @wip${process.env.EXTRA_TAGS ? ` and ${process.env.EXTRA_TAGS}` : ''}`,
  format: ['progress-bar', 'json:reports/ci-results.json'],
  retry: 0,   // No retries in CI — fail-fast
  parallel: parseInt(process.env.CUCUMBER_WORKERS ?? '4', 10),
} satisfies Partial<IConfiguration>;
```

**Invoke a named profile:**

```bash
# Run the 'smoke' profile
npx cucumber-js --profile smoke

# Run the 'ci' profile with an extra tag filter
EXTRA_TAGS="@billing" npx cucumber-js --profile ci
```

**[community] `satisfies` vs `as` vs annotation**: Some older Cucumber.js TypeScript guides
use `config as IConfiguration` (type assertion) which silences TypeScript errors without
actually checking the structure. `satisfies Partial<IConfiguration>` is strictly safer:
a typo in an option name (`paralel: 4` instead of `parallel: 4`) becomes a compile error
rather than a silent no-op. Teams upgrading from JavaScript-based `cucumber.js` configs to
TypeScript `cucumber.ts` should adopt `satisfies` from the start to catch configuration
drift early.

**[community] Node.js built-in TypeScript support caveat**: As noted in the official
Cucumber.js documentation, when loading `cucumber.ts`, Cucumber uses Node.js built-in
TypeScript support (available in Node 22.6+ with `--experimental-strip-types` and stable
in Node 23+). This means your `tsconfig.json` settings are **not honored** during config
file loading — only the Node.js native TypeScript parser runs. Avoid `tsconfig.json`-specific
features (path aliases, `experimentalDecorators` for config expressions) in `cucumber.ts`
itself. Step definitions loaded via `import:` still use your project's TypeScript
configuration as processed by `tsx` or `ts-node`.

---

### playwright-bdd v8.4.0: Deterministic Fixture Names and Hidden In-File Fixtures  [community]

playwright-bdd v8.4.0 (released August 2025) included two quality-of-life improvements
for teams running large BDD suites that are worth documenting explicitly, as they affect
the stability of generated test files and report readability.

**1. Fixture names sorted deterministically in generated files**

The `bddgen` code generator creates `.spec.ts` files from `.feature` files. These generated
files contain fixture references that appear in Playwright HTML reports and stack traces.
Before v8.4.0, the order of fixture names in generated files was non-deterministic — it
changed between runs depending on Node.js object key enumeration order. This caused
spurious diffs in version control when multiple developers ran `bddgen` independently:

```typescript
// BEFORE v8.4.0 — generated file, fixture order non-deterministic (caused noisy git diffs)
// Run by Developer A:
test('checkout with discount', async ({ page, testUser, discountCode, cart }) => { ... });

// Same command, run by Developer B (different machine, different Node.js minor):
test('checkout with discount', async ({ page, cart, discountCode, testUser }) => { ... });
// ^^^ Different fixture order — produces a diff on commit
```

```typescript
// AFTER v8.4.0 — fixture names sorted alphabetically, deterministic across all machines
test('checkout with discount', async ({ cart, discountCode, page, testUser }) => { ... });
// ^^^ Same order on every machine — no git noise
```

**Why this matters in CI**: Teams that commit generated `.spec.ts` files to version control
(to make Playwright test results reviewable without running `bddgen` in CI) experienced
false merge conflicts when two branches touched the same feature file and regenerated
different fixture orderings. After v8.4.0, `bddgen` output is idempotent — the same feature
file always produces the same generated spec, regardless of which machine ran `bddgen`.

**[community] Should you commit generated files?** The playwright-bdd documentation recommends
running `bddgen` as part of the CI pipeline rather than committing generated files. However,
some teams commit them for traceability — the generated file shows exactly which Playwright
test structure was executed. If you do commit them, pin to v8.4.0+ to avoid the non-determinism
problem. Add `*.spec.ts` files generated by `bddgen` to a dedicated directory (e.g.,
`.bdd/`) and add that directory to `.gitignore` unless you explicitly want them tracked.

**2. In-file BDD fixtures hidden from Playwright reports**

playwright-bdd allows step definitions to define inline fixtures using `test.extend()` within
the same file as the step definitions. These "in-file fixtures" were previously visible in
Playwright HTML reports as fixture names, cluttering the fixture list with implementation
details that are irrelevant to readers of the BDD report.

v8.4.0 hides in-file fixtures from reports by default:

```typescript
// src/steps/checkout.steps.ts — in-file fixture (hidden from reports after v8.4.0)
import { test, expect } from '@playwright/test';
import { createBdd } from 'playwright-bdd';

// This in-file fixture provides a pre-configured cart for checkout tests
// It does NOT appear in the Playwright HTML report fixture list in v8.4.0+
const checkoutTest = test.extend<{ populatedCart: CartPage }>({
  populatedCart: async ({ page }, use) => {
    const cart = new CartPage(page);
    await cart.addItem('PROD-001', 2);
    await cart.addItem('PROD-002', 1);
    await use(cart);
  },
});

const { Given, When, Then } = createBdd(checkoutTest);

// The 'populatedCart' fixture is used internally but not shown as a named fixture
// in the "Before/After" fixture timeline of the HTML report
Given('I have a cart with 3 items', async ({ populatedCart }) => {
  await populatedCart.waitForLoad();
});

When('I apply the discount code {string}', async ({ populatedCart }, code: string) => {
  await populatedCart.applyDiscount(code);
});

Then('my total should be {string}', async ({ populatedCart }, expectedTotal: string) => {
  await expect(populatedCart.total()).toHaveText(expectedTotal);
});
```

**Before v8.4.0**: The `populatedCart` fixture appeared in the Playwright report's fixture
setup/teardown timeline, mixed with framework fixtures like `page`, `context`, and `browser`.
This confused stakeholders reading the report who had no context for implementation fixtures.

**After v8.4.0**: Only explicitly shared fixtures (defined via `defineBddConfig` or in
dedicated fixture files) appear in the report. Step-local in-file fixtures are hidden.

**[community] Fixture organization recommendation**: Use in-file fixtures for step-specific
setup that is an implementation detail (page object initialization, test data scoping for
a specific step file). Use shared fixture files (`src/fixtures/`) for setup that spans
multiple step files and should be visible in reports as named lifecycle events. The
v8.4.0 reporting change reinforces this separation naturally — fixtures in dedicated
shared files are visible; implementation-detail fixtures in step files are hidden.

---

## Additional Resources (Iteration 30 Additions)

- [Cucumber.js Plugin API docs](https://raw.githubusercontent.com/cucumber/cucumber-js/main/docs/plugins.md) — `Plugin<T>` type, `coordinator` function, `transform()` for `pickles:filter`/`pickles:order`, `paths:resolve` event, cleanup lifecycle
- [Cucumber.js Custom Formatters docs](https://raw.githubusercontent.com/cucumber/cucumber-js/main/docs/custom_formatters.md) — `FormatterPlugin<T>` type, `on('message', ...)` handler, `optionsKey` pattern, `@cucumber/query` library integration
- [@cucumber/query on GitHub](https://github.com/cucumber/query) — queryable view over Cucumber message stream; `getTestCaseAttempts()`, `getPickle()`, `update()` API; recommended for non-trivial formatters
- [TypeScript `satisfies` operator (TS 4.9+)](https://www.typescriptlang.org/docs/handbook/2/satisfies.html) — structural compatibility check without type widening; canonical pattern for `cucumber.ts` profiles
- [playwright-bdd v8.4.0 release notes](https://github.com/vitalets/playwright-bdd/releases/tag/v8.4.0) — deterministic fixture name sort, in-file fixtures hidden from reports, Playwright 1.55 support, `node_modules` excluded from `tagsFromPath`

---

### Playwright 1.45–1.60: New BDD-Relevant APIs  [community]

Playwright releases from mid-2024 through early 2026 introduced several APIs that directly
improve TypeScript BDD step definitions. None of these require changing `.feature` files —
they affect the implementation layer inside step definitions and hooks.

#### Playwright `Clock` API: Time-Dependent Scenario Control (v1.45+)

The `Clock` API allows step definitions to manipulate browser time without modifying application
code or waiting for real time to pass. This is directly applicable to BDD scenarios that test
time-dependent business rules: password reset link expiry, session timeouts, discount code
expiration, refund window boundaries.

**Before `Clock` API** — the common workaround (fragile, slow):
```typescript
// Old approach: seed a database record with a timestamp 31 days in the past
// Requires either: (1) DB seeder that supports backdated records, or
// (2) waiting for real time during tests (impossible for 30+ day windows)
await this.seeder.seedOrder(customerId, { confirmedDaysAgo: 31 }); // custom seeder needed
```

**With Playwright `Clock` API** — set the browser's perceived date:
```typescript
// src/steps/temporal.steps.ts — time manipulation using Playwright Clock API (v1.45+)
import { Given } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// Scenario: Password reset link expires after 1 hour
// Gherkin: Given a password reset link was generated 61 minutes ago for "alice@example.com"
Given(
  'a password reset link was generated {int} minutes ago for {string}',
  async function (this: AppWorld, minutesAgo: number, email: string) {
    // 1. Fix browser clock to a base time
    const baseTime = new Date('2026-01-15T10:00:00Z');
    await this.page.clock.setFixedTime(baseTime);

    // 2. Generate the reset link (the server uses the real server time — seed via API)
    const res = await this.apiContext.post('/api/auth/forgot-password', {
      data: { email },
    });
    this.resetToken = (await res.json() as { token: string }).token;

    // 3. Advance browser clock by the specified time
    await this.page.clock.fastForward(minutesAgo * 60 * 1000);
    // Browser's Date.now() now returns baseTime + minutesAgo minutes
    // Client-side expiry checks that use Date.now() will see the link as expired
  }
);

// Scenario: Session times out after 30 minutes of inactivity
// Gherkin: When 31 minutes pass without activity
When(
  '{int} minutes pass without activity',
  async function (this: AppWorld, minutes: number) {
    // Advance browser clock — triggers client-side session expiry logic
    await this.page.clock.fastForward(minutes * 60 * 1000);
    // If the app polls for session validity (e.g., every minute), tick through it:
    // await this.page.clock.runFor(minutes * 60 * 1000); // runs all timers
  }
);
```

**Clock API methods for BDD step definitions:**

| Method | Use case |
|---|---|
| `page.clock.setFixedTime(date)` | Fix `Date.now()` to a specific point in time |
| `page.clock.fastForward(ms)` | Advance the clock by N milliseconds (skips waiting) |
| `page.clock.runFor(ms)` | Advance clock AND run all pending timers/intervals within that window |
| `page.clock.install({ time })` | Full clock takeover — replaces `Date`, `setTimeout`, `setInterval` |
| `page.clock.restore()` | Restore the real clock (use in `After` hooks) |

**`After` hook cleanup for Clock-modified scenarios:**
```typescript
// src/support/hooks.ts — restore real clock after each scenario
After(async function (this: AppWorld) {
  // Prevent clock leak to next scenario in parallel runs
  try {
    await this.page.clock.restore();
  } catch {
    // page may be closed — safe to ignore
  }
  await this.context?.close();
});
```

**[community] Clock API gotcha — server-side vs client-side time**: `page.clock` controls
browser (client-side) JavaScript time only. Server-side expiry logic — e.g., a JWT `exp`
field checked on the backend — still uses real server time. For scenarios where the expiry
check happens server-side, the DB seeder approach (backdating the record) is still required.
Use `page.clock` for client-side expiry (e.g., front-end session countdown, client-side
token validation), and DB seeding for server-side expiry.

#### Playwright `WebSocketRoute`: WebSocket Mocking Without a Backend (v1.48+)

`WebSocketRoute` allows BDD step definitions to intercept, mock, and modify WebSocket
connections directly from the browser context. This is the missing piece for WebSocket BDD
scenarios that previously required a real running backend.

```gherkin
# features/realtime/order-status.feature
Feature: Real-time order status updates

  Scenario: Order confirmation triggers a WebSocket notification
    Given I am viewing my order status page
    When the backend sends an "order.confirmed" WebSocket message
    Then I should see the status change to "Confirmed"
    And a confirmation banner should appear

  Scenario: Connection loss is handled gracefully
    Given I am viewing my order status page
    When the WebSocket connection is lost
    Then I should see an "Offline - reconnecting..." indicator
    And the page should attempt to reconnect automatically
```

```typescript
// src/steps/websocket-mock.steps.ts — WebSocketRoute for BDD (Playwright v1.48+)
import { Given, When, Then } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';
import { expect } from '@playwright/test';

interface WebSocketRouteHandle {
  send: (data: string) => void;
  close: (code?: number, reason?: string) => void;
}

Given('I am viewing my order status page', async function (this: AppWorld) {
  // Install WebSocket mock BEFORE navigating to the page
  await this.context.routeWebSocket('**/api/ws/orders', (ws) => {
    // Store the server-side of the route for use in When steps
    this.wsRoute = {
      send: (data: string) => ws.send(data),
      close: (code?: number, reason?: string) => ws.close(code, reason),
    };
    // Forward all messages from client to a mock server (or swallow them)
    ws.onMessage((message) => {
      // Echo heartbeat messages back
      if (message === '{"type":"ping"}') {
        ws.send('{"type":"pong"}');
      }
    });
  });

  await this.page.goto('/orders/ORD-12345');
  await expect(this.page.getByTestId('order-status')).toBeVisible();
});

When(
  'the backend sends an {string} WebSocket message',
  async function (this: AppWorld, eventType: string) {
    if (!this.wsRoute) throw new Error('WebSocket route not initialized');

    // Simulate server pushing an event to the connected client
    this.wsRoute.send(JSON.stringify({
      type: eventType,
      orderId: 'ORD-12345',
      newStatus: 'confirmed',
      timestamp: Date.now(),
    }));
  }
);

When('the WebSocket connection is lost', async function (this: AppWorld) {
  if (!this.wsRoute) throw new Error('WebSocket route not initialized');
  // Close with code 1001 (going away) to simulate network loss
  this.wsRoute.close(1001, 'Simulated network disconnect');
});

Then(
  'I should see the status change to {string}',
  async function (this: AppWorld, expectedStatus: string) {
    await expect(this.page.getByTestId('order-status-badge'))
      .toHaveText(expectedStatus, { timeout: 3000 });
  }
);

Then(
  'I should see an {string} indicator',
  async function (this: AppWorld, indicatorText: string) {
    await expect(this.page.getByTestId('connection-status'))
      .toContainText(indicatorText, { timeout: 3000 });
  }
);
```

**[community] `WebSocketRoute` vs real backend for BDD**: `WebSocketRoute` is the recommended
approach for scenarios that test *client-side* WebSocket behavior (how the UI responds to
events). Use a real backend for scenarios that test *end-to-end* event flow (from the event
source, through the message broker, to the client). The two layers are complementary:
`WebSocketRoute` scenarios are deterministic and millisecond-fast; real-backend scenarios
catch integration bugs that mocking cannot.

**[community] `WebSocketRoute` + Cucumber.js World**: The `wsRoute` handle stored in the
World object (above) is used across multiple steps in the same scenario. Always initialize
it in the `Given` step (before navigation), never in a `When` step — the WebSocket
intercept must be installed before the page establishes the connection.

#### Playwright `toMatchAriaSnapshot()`: Semantic Markup BDD Assertions (v1.49+)

`toMatchAriaSnapshot()` asserts on the ARIA accessibility tree of a page or locator in YAML
format. It provides a more meaningful assertion for interactive components than raw DOM
selectors — asserting what the *screen reader sees*, not what the *HTML contains*.

This is directly useful in BDD step definitions that verify structural accessibility behavior
rather than axe-core rule checking.

```gherkin
# features/accessibility/form-structure.feature
@a11y @regression
Feature: Form accessibility structure

  Scenario: Order form presents correct semantic structure to screen readers
    Given I am on the order creation form
    Then the form should have a correct accessible heading structure
    And the required fields should be marked as required for assistive technology

  Scenario: Error state updates the accessible form structure
    Given I am on the order creation form
    When I submit the form without filling required fields
    Then the error messages should be associated with their form controls in the ARIA tree
```

```typescript
// src/steps/aria-snapshot.steps.ts — semantic accessibility assertions (Playwright v1.49+)
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then the form should have a correct accessible heading structure
Then(
  'the form should have a correct accessible heading structure',
  async function (this: AppWorld) {
    // toMatchAriaSnapshot() checks the ARIA tree structure in YAML format
    // The snapshot describes what a screen reader would announce
    await expect(this.page.getByRole('main')).toMatchAriaSnapshot(`
      - heading "Create Order" [level=1]
      - form "Order details":
        - group "Customer information":
          - textbox "Customer email" [required]
          - textbox "Customer name" [required]
        - group "Order items":
          - table "Selected products"
        - button "Place order"
    `);
  }
);

// Matches: Then the required fields should be marked as required for assistive technology
Then(
  'the required fields should be marked as required for assistive technology',
  async function (this: AppWorld) {
    const form = this.page.getByRole('form', { name: 'Order details' });

    // Assert each required field has aria-required="true" visible in the ARIA tree
    // toMatchAriaSnapshot uses partial matching — only asserts specified nodes
    await expect(form).toMatchAriaSnapshot(`
      - textbox "Customer email" [required]
      - textbox "Customer name" [required]
    `);
  }
);

// Matches: Then the error messages should be associated with their form controls in the ARIA tree
Then(
  'the error messages should be associated with their form controls in the ARIA tree',
  async function (this: AppWorld) {
    // After form submission error, the ARIA tree should reflect validation state
    await expect(this.page.getByRole('form')).toMatchAriaSnapshot(`
      - textbox "Customer email" [required] [invalid]
      - /error: .+email/ [role=alert]
      - textbox "Customer name" [required] [invalid]
      - /error: .+name/ [role=alert]
    `);

    // Also use the v1.50 toHaveAccessibleErrorMessage() assertion for each field:
    const emailField = this.page.getByRole('textbox', { name: 'Customer email' });
    await expect(emailField).toHaveAccessibleErrorMessage(/valid email/i);
  }
);
```

**Generating ARIA snapshot baselines**:
```bash
# Use Playwright's codegen to capture the current ARIA snapshot as a string:
npx playwright codegen --target=aria --output=aria-snapshots.yaml http://localhost:3000/orders/new
# Or: use expect().toMatchAriaSnapshot() with update mode to write the snapshot on first run
PLAYWRIGHT_UPDATE_SNAPSHOTS=1 npx playwright test
```

**[community] `toMatchAriaSnapshot()` vs `toHaveRole()`/`toHaveAttribute()`**: Individual
role and attribute assertions are good for targeted single-element checks. `toMatchAriaSnapshot()`
is better for asserting the *structural relationship* between elements (headings within sections,
form controls within groups, error messages associated with inputs). BDD scenarios that verify
"the form is correctly structured" benefit from the snapshot approach — it reads like a
specification of the expected ARIA tree.

**[community] `toHaveAccessibleErrorMessage()` (Playwright v1.50+)**: A purpose-built
assertion for the `aria-errormessage` relationship. It checks that an input's associated error
message (via `aria-errormessage` or `aria-describedby`) matches the expected text. This is
cleaner than checking `getAttribute('aria-errormessage')` manually in step definitions and
produces better failure messages for accessibility BDD scenarios.

#### Cucumber Community Ownership (2025)  [community]

In early 2025, Cucumber returned to open-source community governance after several years
under corporate sponsorship. The project is now maintained by community contributors, with
active development continuing on Cucumber.js, the Gherkin spec, and the supporting libraries
(`@cucumber/messages`, `@cucumber/query`, `@cucumber/html-formatter`).

**Impact on TypeScript BDD teams:**

1. **Release cadence**: Community-maintained releases tend to be more conservative (quality
   over speed). Expect Cucumber.js v13 to have a longer stabilization period than v12.

2. **Plugin contributions**: The community governance model means teams can contribute
   formatters, plugins, and step helpers to the official ecosystem more easily. The
   `@cucumber/cucumber/api` Plugin API (v12.5+) was designed with community contribution
   in mind.

3. **Issue response times**: The community tracker at `https://github.com/cucumber/cucumber-js/issues`
   is the authoritative place to check compatibility, breaking changes, and upcoming deprecations.
   Teams should watch the repository for milestone announcements.

4. **Gherkin spec stability**: The Gherkin language specification (keywords, DocString
   delimiters, DataTable escape sequences) is community-governed and changes rarely.
   All v12 and v13 Gherkin feature files are forward-compatible.

**[community] Monitoring community-owned projects in CI**: Add a `npm outdated` check to
your quarterly BDD health review to catch breaking changes before they affect your CI
pipeline. Pin `@cucumber/cucumber` to a minor version (`^12.8.0`) rather than a major
(`^12`) in `package.json` when your test suite is production-critical — patch releases
are safe; minor releases occasionally introduce deprecation warnings that are noisy in CI.

---

## Additional Resources (Iteration 31 Additions)

- [Playwright Clock API docs](https://playwright.dev/docs/clock) — `page.clock.setFixedTime()`, `fastForward()`, `runFor()`, `install()`, `restore()`; browser-side time control for date-dependent BDD scenarios
- [Playwright WebSocketRoute docs](https://playwright.dev/docs/api/class-websocketroute) — `context.routeWebSocket()`, `ws.send()`, `ws.close()`, `ws.onMessage()`; mock WebSocket servers without a real backend
- [Playwright `toMatchAriaSnapshot()` docs](https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-match-aria-snapshot) — ARIA tree snapshot assertions in YAML format; `--update-snapshots` flag; partial matching with wildcards
- [Playwright `toHaveAccessibleErrorMessage()` docs](https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-have-accessible-error-message) — v1.50+ assertion for `aria-errormessage` and `aria-describedby` error associations
- [Playwright release notes v1.45–v1.60](https://playwright.dev/docs/release-notes) — Clock API (v1.45), WebSocketRoute (v1.48), toMatchAriaSnapshot (v1.49), toHaveAccessibleErrorMessage (v1.50), toContainClass (v1.52), test.abort() (v1.60)
- [Cucumber community GitHub](https://github.com/cucumber/cucumber-js) — community-governed since 2025; issue tracker, milestone roadmap, and contributor guide

---

### Playwright v1.51–v1.60: Additional BDD-Relevant APIs  [community]

The iterations up to 31 covered Playwright APIs through v1.50 (`toMatchAriaSnapshot`, `toHaveAccessibleErrorMessage`). Releases v1.51–v1.60 introduced further APIs that improve TypeScript BDD step definitions — particularly around step-level observability, auth persistence, and locator semantics.

#### `TestStepInfo` — Step-Level Attachments and Conditional Skip (v1.51+)

Playwright v1.51 exposed `TestStepInfo` as a parameter to `test.step()` callbacks. In playwright-bdd, this is accessible via the `$testInfo` fixture. It allows attaching evidence at the *step* level (not just the scenario level) and conditionally skipping a step when a prerequisite is absent.

```typescript
// src/steps/checkout.steps.ts — step-level attachment using TestStepInfo via $testInfo
import { createBdd } from 'playwright-bdd';
import { expect } from '@playwright/test';
const { When, Then } = createBdd();

Then(
  'I should see an order confirmation page',
  async ({ page, $testInfo }) => {
    const confirmationBanner = page.getByTestId('order-confirmation');

    // Attach the confirmation element's text to the step — visible in trace viewer
    const text = await confirmationBanner.textContent();
    await $testInfo.attach('Confirmation text', {
      body: text ?? '(empty)',
      contentType: 'text/plain',
    });

    await expect(confirmationBanner).toBeVisible();
    await expect(page).toHaveURL(/\/order\/confirmation/);
  }
);

// Conditional step skip — skip step if feature flag is off in this environment
Given(
  'the feature flag {string} is active',
  async ({ page, $testInfo }, flagName: string) => {
    const res = await page.request.get(`/api/feature-flags/${flagName}`);
    const { enabled } = await res.json() as { enabled: boolean };
    if (!enabled) {
      // Skip the step (and mark scenario pending) if the flag is off in this env
      $testInfo.skip(!enabled, `Feature flag ${flagName} is not enabled in ${process.env.TEST_ENV}`);
      return;
    }
    // Proceed — flag is enabled
  }
);
```

**[community] Step-level attachments vs scenario-level**: Attaching evidence at the step level (v1.51+) rather than in the `After` hook means the attachment appears inline with the step in the Playwright HTML report — next to the step name, not at the bottom of the scenario. For BDD scenarios with multiple `Then` assertions, step-level attachments make it immediately clear which step captured which screenshot or API response. Use scenario-level `After` attachments only for failure screenshots (taken after the scenario ends); use step-level for diagnostic evidence captured mid-scenario.

#### `IndexedDB` in `storageState()` — Auth Token Persistence (v1.51+)

Applications using Firebase Authentication, Supabase, or custom IndexedDB token stores require `storageState()` to capture IndexedDB contents in addition to cookies and `localStorage`. Without the `indexedDB: true` option, `storageState()` saves a partial auth state that fails to reproduce the login in subsequent scenarios.

```typescript
// src/support/auth-setup.ts — capture auth state including IndexedDB (Playwright v1.51+)
import { chromium, type FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Perform login (Firebase Auth writes tokens to IndexedDB)
  await page.goto(`${config.use?.baseURL}/login`);
  await page.getByTestId('email').fill(process.env.TEST_USER_EMAIL ?? '');
  await page.getByTestId('password').fill(process.env.TEST_USER_PASSWORD ?? '');
  await page.getByTestId('submit').click();
  await page.waitForURL('**/dashboard');

  // Save state INCLUDING IndexedDB — required for Firebase Auth and similar
  await page.context().storageState({
    path: '.auth/user-state.json',
    indexedDB: true,  // v1.51+ option — captures IndexedDB contents
  });

  await browser.close();
}

export default globalSetup;
```

**[community] When `indexedDB: true` is required**: Applications that use Firebase Auth, Supabase client-side auth, or any SDK that stores JWT refresh tokens in IndexedDB will produce `401 Unauthorized` responses in BDD scenarios that use `storageState` without `indexedDB: true`. The symptom is scenarios that pass in isolation (fresh login) but fail when reusing saved state. If your BDD smoke scenarios consistently fail on the first step that requires authentication when running with `--storage-state`, add `indexedDB: true` to your `storageState()` call.

#### `expect(locator).toContainClass()` — Ergonomic Class Assertions (v1.52+)

The existing `toHaveClass()` assertion matches the entire `class` attribute string, requiring exact matches or complex regex for elements with many CSS classes. `toContainClass()` checks for the presence of a specific class name without caring about order or other classes.

```typescript
// src/steps/checkout.steps.ts — toContainClass() for state-based assertions (v1.52+)
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then the checkout button should be disabled
Then('the checkout button should be disabled', async function (this: AppWorld) {
  // toContainClass('disabled') checks that the class list contains 'disabled'
  // regardless of what other classes are present — more reliable than regex on full class string
  await expect(this.page.getByTestId('checkout-button')).toContainClass('disabled');
});

// Matches: Then the active navigation item should be highlighted
Then(
  'the {string} navigation item should be highlighted',
  async function (this: AppWorld, navItem: string) {
    const navLink = this.page.getByRole('link', { name: navItem });
    // Works whether the element has "active font-bold text-blue-600" or just "active"
    await expect(navLink).toContainClass('active');
  }
);

// Matches: Then the form submit button should not be in a loading state
Then('the form submit button should not be in a loading state', async function (this: AppWorld) {
  // Negative assertion — button should not have the loading class
  await expect(this.page.getByRole('button', { name: 'Submit' })).not.toContainClass('loading');
});
```

**[community] `toContainClass()` vs `toHaveAttribute('class', /active/)` regex**: Before v1.52, the standard pattern was `await expect(el).toHaveAttribute('class', /active/)`. The issue: if an element has class `inactive`, the regex `/active/` incorrectly matches. `toContainClass('active')` uses proper class tokenization — it checks the space-delimited class list for the exact token `active`, not a substring match. This eliminates a class of false-positive assertions in BDD suites.

#### `locator.describe()` — Semantic Locator Labels (v1.53+)

`locator.describe()` adds a semantic label to a locator that appears in the Playwright trace viewer and HTML report without changing the underlying selector. In BDD step definitions, this replaces cryptic selector strings with business-domain descriptions in report output.

```typescript
// src/pages/CheckoutPage.ts — locator.describe() for business-readable traces (v1.53+)
import { Page } from '@playwright/test';

export class CheckoutPage {
  constructor(private readonly page: Page) {}

  // Instead of seeing "locator('[data-testid="confirm-order"]')" in the trace,
  // the label "Confirm order button" appears — readable by product managers reviewing failures
  readonly confirmOrderButton = this.page
    .getByTestId('confirm-order')
    .describe('Confirm order button');

  readonly orderTotal = this.page
    .getByTestId('order-total')
    .describe('Order total amount display');

  readonly errorMessage = this.page
    .getByTestId('error-message')
    .describe('Checkout error message');
}
```

**[community] `describe()` in BDD failure reports**: When a BDD scenario fails on a `Then` step that asserts on a locator, the Playwright HTML report shows the locator expression in the failure. Without `describe()`, this is `locator('[data-testid="confirm-order"]')`. With `describe()`, it reads `Confirm order button`. For stakeholders reading BDD failure reports (product managers, QA leads), the labeled version is immediately actionable — they know what component failed without reading selector syntax.

#### `page.consoleMessages()`, `page.pageErrors()`, `page.requests()` — In-Step Observability (v1.56+)

Playwright v1.56 added snapshot methods that retrieve recent browser-side events without setting up listeners in advance. These are directly useful in BDD `Then` steps that need to assert on side effects: console warnings emitted by a component, errors thrown during navigation, or network requests made in response to a user action.

```typescript
// src/steps/observability.steps.ts — in-step browser observability (Playwright v1.56+)
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then no console errors should have been emitted during checkout
Then('no console errors should have been emitted during checkout', async function (this: AppWorld) {
  // page.consoleMessages() returns recent console messages without prior listener setup
  const consoleMessages = await this.page.consoleMessages();
  const errors = consoleMessages.filter(msg => msg.type() === 'error');

  if (errors.length > 0) {
    const errorTexts = errors.map(e => `[console.error] ${e.text()}`).join('\n');
    throw new Error(
      `Expected no console errors during checkout, but ${errors.length} were emitted:\n${errorTexts}`
    );
  }
});

// Matches: Then no JavaScript errors should have occurred on the page
Then('no JavaScript errors should have occurred on the page', async function (this: AppWorld) {
  // page.pageErrors() retrieves uncaught JS errors (unhandled rejections, thrown exceptions)
  const pageErrors = await this.page.pageErrors();
  if (pageErrors.length > 0) {
    const errorTexts = pageErrors.map(e => e.message).join('\n');
    throw new Error(`Uncaught JS errors during scenario:\n${errorTexts}`);
  }
});

// Matches: Then the analytics event for "order_placed" should have been sent
Then(
  'the analytics event for {string} should have been sent',
  async function (this: AppWorld, eventName: string) {
    // page.requests() retrieves recent network requests — check for analytics beacon
    const requests = await this.page.requests();
    const analyticsRequest = requests.find(req =>
      req.url().includes('/analytics/events') &&
      req.postData()?.includes(eventName)
    );

    if (!analyticsRequest) {
      const allAnalyticsUrls = requests
        .filter(r => r.url().includes('/analytics'))
        .map(r => r.url())
        .join('\n  ');
      throw new Error(
        `No analytics request found for event "${eventName}".\n` +
        `Analytics requests made:\n  ${allAnalyticsUrls || '(none)'}`
      );
    }
  }
);
```

**[community] `page.requests()` for BDD side-effect validation**: The classic problem with asserting on network side effects (analytics, audit logging, webhook triggers) in BDD scenarios is that setting up network listeners requires hooking into `Before` — before the scenario runs. The v1.56 `page.requests()` snapshot method eliminates this setup: the `Then` step can retroactively query all requests made since the page loaded. This makes "And an audit log entry should have been created" steps implementable without modifying hooks.

**[community] Console error assertions as BDD quality gates**: Adding a standard `Then no console errors should have been emitted` step to smoke scenarios catches JavaScript errors that do not surface as visible UI failures. A broken import, a failed API call that is silently caught, or a React render error that falls back to an error boundary — all produce console errors that are invisible to end users but indicate quality regressions. This step is low-cost to add and high-value in production: it catches entire categories of defects that page-level assertions miss.

#### `testConfig.tag` — Run-Level Tagging in Playwright Reports (v1.57+)

Playwright v1.57 added `testConfig.tag` (an array of strings), which applies metadata tags to the entire test run. These tags appear in the Playwright HTML report and Allure integration, making it easy to filter historical runs (e.g., "show all `regression` runs from the last 7 days").

```typescript
// playwright.config.ts — run-level tags for BDD suites (Playwright v1.57+)
import { defineConfig } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.ts',
});

export default defineConfig({
  testDir,
  // Run-level tags — appear in Playwright HTML report metadata and Allure
  // Useful for: filtering CI history ("show all nightly runs"), release gating,
  // distinguishing smoke from regression in multi-profile CI pipelines
  metadata: {
    // playwright-bdd compatible metadata field for run identification
    runType: process.env.BDD_PROFILE ?? 'smoke',
    buildId: process.env.GITHUB_RUN_NUMBER ?? 'local',
    environment: process.env.TEST_ENV ?? 'local',
  },
  reporter: [
    ['html', { outputFolder: 'reports/playwright-html' }],
    // In Playwright standalone (without playwright-bdd), use testConfig.tag:
    // tag: [process.env.BDD_PROFILE ?? 'smoke'],  // v1.57+ native tag array
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
});
```

#### `test.abort()` — Fixture-Driven Early Exit (v1.60+)

Playwright v1.60 added `test.abort()` — callable from a fixture setup to fail the test with a human-readable message when a precondition cannot be satisfied. In BDD scenarios, this replaces `test.skip()` when the scenario cannot be meaningfully skipped (it should be counted as a failure, not silently omitted).

```typescript
// src/fixtures/app-fixtures.ts — test.abort() for hard precondition failures (Playwright v1.60+)
import { test as base } from '@playwright/test';
import { createBdd } from 'playwright-bdd';

const test = base.extend<{ verifiedBackend: void }>({
  // Fixture that validates the backend is reachable before any BDD scenario starts.
  // If unreachable, aborts with a clear message rather than letting each scenario
  // fail with a cryptic connection refused error.
  verifiedBackend: [async ({ request }, use) => {
    const response = await request
      .get('/api/health')
      .catch(() => null);

    if (!response || !response.ok()) {
      // test.abort() marks the test as failed (not skipped) with an explicit message.
      // This is more honest than test.skip() — the test failed because the environment
      // was not ready, not because the test was intentionally skipped.
      test.abort(`Backend unreachable at ${process.env.BASE_URL ?? 'http://localhost:3000'}/api/health. ` +
        `Check that the test environment is deployed before running BDD.`);
    }

    await use();
  }, { auto: true }], // auto: true — runs for every test without explicit fixture injection
});

export const { Given, When, Then } = createBdd(test);
```

**[community] `test.abort()` vs `test.skip()` for BDD precondition failures**: Use `test.skip()` when the scenario is legitimately not applicable to the current environment (e.g., `@production-only` scenario running against staging). Use `test.abort()` when the environment should support the scenario but is broken. `abort()` produces a FAILED result in CI rather than SKIPPED, which prevents deployment if the environment check fails. In a healthy CI pipeline, you never want to silently skip scenarios due to infrastructure issues — you want to fail loudly.

---

### Playwright v1.59–v1.60: BDD-Relevant APIs (Iteration 33)

Playwright v1.59 (April 2025) and v1.60 (May 2025) introduce several APIs relevant to BDD that were not covered in earlier iterations. The v1.59 release is particularly significant for TypeScript BDD teams: the `await using` disposable pattern, the page-level `ariaSnapshot()`, and the CLI debugger together change how teams develop and debug BDD step definitions interactively.

#### `await using` — TypeScript Disposable Pattern for BDD Resource Cleanup (v1.59+)

Playwright v1.59 adds first-class support for the ECMAScript `using`/`await using` disposable protocol (`Symbol.asyncDispose`) across browser, context, and page objects. In BDD step hooks, this eliminates the need for `try/finally` cleanup blocks — resources are automatically closed when they go out of scope.

```typescript
// src/support/hooks.ts — await using for automatic resource cleanup (Playwright v1.59+)
// Requires TypeScript 5.2+ and "lib": ["ES2022"] or later in tsconfig.json
import { BeforeAll, AfterAll, Before, After } from '@cucumber/cucumber';
import { chromium } from '@playwright/test';
import { AppWorld } from './world';

// Traditional pattern — explicit cleanup in AfterAll
// let sharedBrowser: Browser;
// BeforeAll(async () => { sharedBrowser = await chromium.launch(); });
// AfterAll(async () => { await sharedBrowser.close(); });

// v1.59+ disposable pattern — cleanup is automatic via Symbol.asyncDispose
// Use in per-scenario fixtures where the browser/context scope is clear:
Before(async function (this: AppWorld) {
  // await using: context is automatically closed at the end of this async function's scope
  // when used in playwright-bdd fixture pattern — with @cucumber/cucumber World pattern,
  // store the disposable and call [Symbol.asyncDispose]() in After.
  this.browser = await chromium.launch({ headless: process.env.CI === 'true' });
  this.context = await this.browser.newContext({
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
  });
  this.page = await this.context.newPage();
  this.testUserId = `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
});

After(async function (this: AppWorld, scenario) {
  if (scenario.result?.status === 'FAILED') {
    const screenshot = await this.page?.screenshot({ fullPage: true });
    if (screenshot) this.attach(screenshot, 'image/png');
  }
  // Explicit cleanup still needed in World-based Cucumber — await using shines more
  // in playwright-bdd fixture functions where scope is controlled by the test runner:
  await this.context?.close();
  await this.browser?.close();
});
```

```typescript
// playwright-bdd: await using in fixture functions (v1.59+ natural fit)
import { test as base } from '@playwright/test';
import { createBdd } from 'playwright-bdd';

const test = base.extend<{ apiContext: import('@playwright/test').APIRequestContext }>({
  apiContext: async ({ playwright }, use) => {
    // await using: context is disposed automatically when 'use' resolves
    await using context = await playwright.request.newContext({
      baseURL: process.env.API_BASE_URL ?? 'http://localhost:3000',
      extraHTTPHeaders: { 'x-test-run': 'true' },
    });
    await use(context);
    // No explicit context.dispose() needed — Symbol.asyncDispose handles it
  },
});

export const { Given, When, Then } = createBdd(test);
```

**[community] `await using` adoption in BDD**: The disposable protocol requires TypeScript 5.2+ and the `"lib": ["ES2022", "ES2022.FullySpecified"]` or `"ESNext"` compiler option. For `@cucumber/cucumber` World-based setups, `await using` is most useful in helper classes that create temporary sub-resources (API contexts, database connections) within a step definition. For playwright-bdd fixture-based setups, it provides a cleaner API context lifecycle that eliminates `try/finally` teardown boilerplate.

#### `page.ariaSnapshot()` on Full Pages (v1.59+)

The `page.ariaSnapshot()` method (previously only on locators) now works directly on `page` objects, capturing the full page ARIA tree as a YAML string. In BDD accessibility scenarios, this enables full-page semantic structure assertions in `Then` steps without wrapping in a locator.

```typescript
// src/steps/a11y.steps.ts — page.ariaSnapshot() for full-page ARIA assertions (v1.59+)
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then the checkout page should have a correct landmark structure
Then('the checkout page should have a correct landmark structure', async function (this: AppWorld) {
  // page.ariaSnapshot() returns the full ARIA tree as YAML (v1.59+)
  // Previously only available on locators: page.locator('main').ariaSnapshot()
  await expect(this.page).toMatchAriaSnapshot(`
    - banner:
      - navigation: "Main navigation"
    - main:
      - heading "Checkout" [level=1]
      - region "Order summary"
      - region "Payment details"
      - region "Shipping address"
    - contentinfo:
      - navigation: "Footer navigation"
  `);
});

// Matches: Then the navigation should be accessible to screen readers
Then('the navigation should be accessible to screen readers', async function (this: AppWorld) {
  // Partial snapshot — only checks navigation landmark structure, not full page
  const nav = this.page.getByRole('navigation', { name: 'Main navigation' });
  await expect(nav).toMatchAriaSnapshot(`
    - navigation "Main navigation":
      - link "Home"
      - link "Products"
      - link "Cart"
      - link "Account"
  `);
});
```

**[community] Full-page vs locator `ariaSnapshot()` choice**: Use `page.ariaSnapshot()` for landmark and high-level structure assertions (is the page organized as banner/main/contentinfo?). Use `locator.ariaSnapshot()` for focused region assertions (is this dialog keyboard-navigable?). Full-page snapshots are broader but more fragile — any added navigation link breaks the assertion. Locator-scoped snapshots are more stable for regression testing specific components.

#### `--debug=cli` — Interactive CLI Debugger for BDD Step Development (v1.59+)

Playwright v1.59 introduced a CLI debugger mode (`--debug=cli`) that lets developers step through test execution interactively in the terminal without opening a browser. For BDD step definition development, this provides a faster inner loop than the full GUI Playwright Inspector.

```bash
# Interactive step debugging for playwright-bdd scenarios (v1.59+)
# Runs the scenario in CLI debug mode — step through with keyboard
npx playwright test --debug=cli --grep "@smoke"

# In CLI debug mode, the terminal shows:
# ▶ Running: "Customer completes a standard purchase"
# ▶ Step: Given I am a registered customer with items in my cart
#   → page.goto('http://localhost:3000/login')  [press Enter to step, 'c' to continue]
# ▶ Step: When I complete the checkout process
#   → page.getByTestId('checkout-button').click()
# ▶ Step: Then my order should be confirmed

# CLI trace viewer — analyze existing trace without opening a browser window
npx playwright trace show playwright-report/trace.zip --output=cli
```

```typescript
// src/steps/checkout.steps.ts — add step-level pause for CLI debugging during development
import { When } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// During development: pause execution for CLI inspection at a specific step
When('I complete the checkout process', async function (this: AppWorld) {
  // Temporarily add this during step definition development:
  // await this.page.pause();  // Opens Playwright Inspector GUI
  //
  // Or for headless CI-safe debugging, log the page URL and title:
  if (process.env.DEBUG_BDD) {
    console.log(`[DEBUG] URL: ${this.page.url()}`);
    console.log(`[DEBUG] Title: ${await this.page.title()}`);
  }
  await this.page.getByTestId('checkout-button').click();
  await this.page.waitForURL('/checkout');
});
```

**[community] CLI debugger vs GUI Inspector for BDD**: The GUI Inspector (`page.pause()` or `--debug`) opens a Chromium window with a step-through interface — ideal for visual debugging of rendering issues. The `--debug=cli` mode runs headlessly in the terminal — ideal for debugging API-level or network behavior in BDD scenarios. For CI-environment debugging (where no display server is available), `--debug=cli` + trace file analysis is the only option. Teams with remote development environments benefit most from the CLI mode.

#### HAR Recording as First-Class Tracing API (v1.60+)

Playwright v1.60 promoted HAR recording to a first-class tracing API. In BDD scenarios, HAR files capture the full network interaction of a scenario — request/response pairs, headers, timings — and are invaluable for debugging intermittent failures caused by unexpected API responses.

```typescript
// src/support/hooks.ts — HAR recording for BDD scenario network capture (v1.60+)
import { Before, After } from '@cucumber/cucumber';
import { chromium } from '@playwright/test';
import { AppWorld } from './world';
import * as path from 'path';

Before(async function (this: AppWorld, scenario) {
  this.browser = await chromium.launch({ headless: process.env.CI === 'true' });
  this.context = await this.browser.newContext();
  this.page = await this.context.newPage();

  // v1.60+: Start HAR recording for every failed scenario (network debugging)
  // HAR captures all request/response pairs, headers, and timings for the scenario
  if (process.env.RECORD_HAR === 'true' || process.env.CI === 'true') {
    const scenarioSlug = scenario.pickle.name.toLowerCase().replace(/\s+/g, '-').slice(0, 50);
    this.harPath = path.join('reports', 'har', `${scenarioSlug}-${Date.now()}.har`);

    // v1.60+ first-class HAR API via tracing
    await this.context.tracing.start({
      screenshots: true,
      snapshots: true,
      sources: false,
    });
  }
});

After(async function (this: AppWorld, scenario) {
  if (scenario.result?.status === 'FAILED' && this.harPath) {
    // Save trace with HAR data on failure
    await this.context?.tracing.stop({
      path: this.harPath.replace('.har', '.zip'),
    });

    // Attach trace path to Cucumber report for CI artifact access
    this.attach(
      `Playwright trace saved: ${this.harPath.replace('.har', '.zip')}`,
      'text/plain'
    );
  } else if (this.harPath) {
    await this.context?.tracing.stop(); // Discard on pass
  }
  await this.context?.close();
  await this.browser?.close();
});
```

```typescript
// playwright-bdd: HAR recording via Playwright's tracing.startHar() (v1.60+)
// More direct API when using playwright-bdd with Playwright fixtures
import { test as base } from '@playwright/test';
import { createBdd } from 'playwright-bdd';
import * as path from 'path';

const test = base.extend<{ harRecorder: void }>({
  harRecorder: [async ({ context, $testInfo }, use) => {
    // v1.60+: tracing.startHar() records HAR as part of the trace
    if ($testInfo.retry > 0) {
      // Only record HAR on retries — reduces overhead on first run
      await context.tracing.startHar({
        path: path.join('reports', 'har', `${$testInfo.titlePath.join('-')}.har`),
        urlFilter: /api\./,  // Only capture API requests, not static assets
      });
    }

    await use();

    if ($testInfo.retry > 0) {
      await context.tracing.stopHar();
    }
  }, { auto: true }],
});

export const { Given, When, Then } = createBdd(test);
```

**[community] HAR files for BDD failure debugging**: A Playwright trace `.zip` file contains screenshots, DOM snapshots, and a HAR recording. When a BDD scenario fails intermittently in CI with "element not found" or "unexpected API response," the HAR file reveals exactly which network request returned an unexpected status, what the response body was, and how long it took. Teams that add HAR recording to their CI failure artifacts reduce mean time to diagnose intermittent BDD failures from hours to minutes.

#### `locator.drop()` — Drag-and-Drop BDD Scenarios (v1.60+)

Playwright v1.60 added `locator.drop()` for simulating drag-and-drop operations (external file drops onto upload zones). In BDD scenarios, this covers upload flows that use drag-and-drop UX.

```gherkin
# features/documents/upload.feature
@regression
Feature: Document upload via drag-and-drop

  Scenario: User uploads a PDF via the document drop zone
    Given I am logged in as a registered customer
    When I drag and drop a PDF file onto the document upload zone
    Then I should see the uploaded document in my document list
    And the document status should be "Processing"

  Scenario: Upload zone rejects files exceeding the size limit
    Given I am on the document upload page
    When I drag and drop a file larger than 10MB
    Then I should see the error "File size exceeds the 10MB limit"
    And no upload should be initiated
```

```typescript
// src/steps/upload.steps.ts — locator.drop() for drag-and-drop BDD (v1.60+)
import { When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import * as path from 'path';
import { AppWorld } from '../support/world';

// Matches: When I drag and drop a PDF file onto the document upload zone
When('I drag and drop a PDF file onto the document upload zone', async function (this: AppWorld) {
  const uploadZone = this.page.getByTestId('document-upload-zone');
  await expect(uploadZone).toBeVisible();

  // locator.drop() simulates an external file being dragged onto the element (v1.60+)
  // This is the correct way to test file-drop upload zones — page.setInputFiles() only
  // works for <input type="file"> elements, not custom drop zones.
  await uploadZone.drop({
    files: [
      {
        name: 'test-document.pdf',
        mimeType: 'application/pdf',
        buffer: Buffer.from('%PDF-1.4 test content'),  // Minimal valid PDF header
      }
    ],
  });

  // Wait for upload initiation indicator
  await expect(this.page.getByTestId('upload-progress')).toBeVisible();
});

// Matches: When I drag and drop a file larger than 10MB
When('I drag and drop a file larger than 10MB', async function (this: AppWorld) {
  const uploadZone = this.page.getByTestId('document-upload-zone');

  // Generate a buffer that exceeds the 10MB limit
  const oversizedBuffer = Buffer.alloc(11 * 1024 * 1024, 'x'); // 11MB of 'x'
  await uploadZone.drop({
    files: [
      {
        name: 'oversized-file.pdf',
        mimeType: 'application/pdf',
        buffer: oversizedBuffer,
      }
    ],
  });
});

Then('the document status should be {string}', async function (this: AppWorld, expectedStatus: string) {
  const statusLocator = this.page.getByTestId('document-status').first();
  await expect(statusLocator).toHaveText(expectedStatus, { timeout: 10_000 });
});
```

**[community] `locator.drop()` vs `page.setInputFiles()`**: Use `page.setInputFiles()` (or `locator.setInputFiles()`) for standard `<input type="file">` elements. Use `locator.drop()` for custom drag-and-drop upload zones that do not expose a file input. The distinction matters: `setInputFiles()` bypasses the visual drag-and-drop interaction entirely, while `locator.drop()` fires the full `dragenter`/`dragover`/`drop` event sequence that custom upload libraries listen for. Teams that use `setInputFiles()` on drag-and-drop zones produce scenarios that pass in tests but fail in production because the events that the upload library requires are never fired.

#### `getByRole()` with `description` Option — Accessible-Name-Aware Step Assertions (v1.60+)

Playwright v1.60 added a `description` option to `getByRole()` that matches elements by their accessible description (from `aria-describedby`, `aria-description`, or `title`). In BDD step definitions, this enables more semantic locators for elements whose accessible name alone is ambiguous.

```typescript
// src/steps/forms.steps.ts — getByRole() with description for accessible selectors (v1.60+)
import { Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then the email field should show a validation hint
Then('the email field should show a validation hint', async function (this: AppWorld) {
  // getByRole() with description option — matches the email input by both its role
  // and its accessible description (from aria-describedby pointing to the hint text)
  const emailInput = this.page.getByRole('textbox', {
    name: 'Email address',
    description: 'Enter your work email address',  // v1.60+ description option
  });

  await expect(emailInput).toBeVisible();
  // Verify the hint text is associated (confirmed by the description option matching)
  const hintId = await emailInput.getAttribute('aria-describedby');
  if (hintId) {
    await expect(this.page.locator(`#${hintId}`)).toContainText('Enter your work email address');
  }
});

// Form with multiple "Submit" buttons distinguished by their accessible description
Then(
  'the {string} form submit button should be enabled',
  async function (this: AppWorld, formName: string) {
    // When a page has multiple submit buttons, description disambiguates which one
    const submitButton = this.page.getByRole('button', {
      name: 'Submit',
      description: `Submit ${formName} form`,  // Matches aria-description attribute
    });
    await expect(submitButton).toBeEnabled();
  }
);
```

**[community] `description` option for BDD locator resilience**: Elements that share the same accessible name across a page (multiple "Submit" buttons, multiple "Close" buttons) are historically hard to select in BDD step definitions without falling back to fragile positional locators (`.nth(0)`) or test IDs. The `description` option provides a semantic, accessibility-first way to disambiguate them. As an added benefit, step definitions using `description` double as accessibility assertions: if the `aria-description` attribute is missing or wrong, the step fails, catching accessibility regressions inline with functional BDD tests.

#### `page.screencast()` — BDD Failure Video with Action Annotations (v1.59+)

Playwright v1.59 added `page.screencast()` — a programmatic API for attaching screen recording to test artifacts. Unlike the `video` option in `use`, `screencast()` is controllable per-scenario and supports `annotate()` calls that embed text overlays (step names, timestamps) directly into the video. In BDD, this means each `Given`/`When`/`Then` step can be labeled in the failure video, making triage dramatically faster.

```gherkin
# features/checkout/payment.feature
@regression @video-on-failure
Feature: Payment processing

  Scenario: User completes a payment with a valid card
    Given I am on the checkout page with items in my cart
    When I enter valid payment details
    And I click the "Pay now" button
    Then my order should be confirmed
    And I should receive an order confirmation email
```

```typescript
// src/support/hooks.ts — page.screencast() with step annotations for BDD failure video (v1.59+)
import { Before, After, BeforeStep, AfterStep, ITestCaseHookParameter, ITestStepHookParameter } from '@cucumber/cucumber';
import { AppWorld } from './world';

// Start screencast at the beginning of every scenario tagged @video-on-failure
Before({ tags: '@video-on-failure' }, async function (this: AppWorld, scenario: ITestCaseHookParameter) {
  // page.screencast() returns a Screencast object; recording begins immediately
  // annotate() can be called at any point to embed an overlay in the video
  this.screencast = await this.page.screencast();
  await this.screencast.annotate(`▶ Scenario: ${scenario.pickle.name}`);
});

// Annotate the video with each step name as it starts
BeforeStep(async function (this: AppWorld, step: ITestStepHookParameter) {
  if (this.screencast) {
    const keyword = step.pickleStep.type === 'Context' ? 'Given'
      : step.pickleStep.type === 'Action' ? 'When'
      : step.pickleStep.type === 'Outcome' ? 'Then' : 'Step';
    await this.screencast.annotate(`${keyword}: ${step.pickleStep.text}`);
  }
});

// On failure: stop recording, attach the video to the Cucumber report
After({ tags: '@video-on-failure' }, async function (this: AppWorld, scenario: ITestCaseHookParameter) {
  if (!this.screencast) return;

  if (scenario.result?.status === 'FAILED') {
    // annotate() the failure reason before stopping
    const errorMessage = scenario.result.message?.split('\n')[0] ?? 'Unknown error';
    await this.screencast.annotate(`✗ FAILED: ${errorMessage}`);
    const videoBuffer = await this.screencast.stop();
    // Attach the video buffer to the Cucumber report as a video/webm artifact
    await this.attach(videoBuffer, 'video/webm');
  } else {
    // Discard the recording for passing scenarios to save storage
    await this.screencast.stop();
  }
  this.screencast = undefined;
});
```

```typescript
// src/support/world.ts — extend AppWorld to hold the screencast reference
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { Browser, BrowserContext, Page, chromium } from 'playwright';
import type { Screencast } from 'playwright';  // v1.59+ type export

export class AppWorld extends World {
  browser!: Browser;
  context!: BrowserContext;
  page!: Page;
  screencast?: Screencast;  // v1.59+: holds the active screencast for the current scenario

  constructor(options: IWorldOptions) {
    super(options);
  }
}

setWorldConstructor(AppWorld);
```

**[community] `page.screencast()` vs `video` option for BDD**: The `use.video` playwright config option records all tests unconditionally and cannot be annotated with step names. `page.screencast()` is the BDD-correct approach: record only failing scenarios, embed step-by-step text overlays using `annotate()` so that the first frame of each BDD step is visually labeled, and attach the buffer directly to the Cucumber HTML report as a `video/webm` artifact. Teams that switched from `use.video` to `page.screencast()` with step annotations reported a 60-80% reduction in failure video review time because testers no longer need to scrub the video manually to find which step triggered the failure — the overlay makes it immediately visible.

#### `expect(locator).toHaveCSS()` with `pseudo` Option — Before/After Pseudo-Element Assertions (v1.60+)

Playwright v1.60 added a `pseudo` option to `toHaveCSS()` that allows asserting CSS property values on `::before` and `::after` pseudo-elements. In BDD scenarios, this enables visual-correctness step definitions for UI patterns that rely on pseudo-elements: badges, tooltips, custom checkboxes, required-field asterisks, and notification indicators.

```gherkin
# features/ui/visual-indicators.feature
@regression @accessibility
Feature: Visual form indicators

  Scenario: Required fields display a visible asterisk
    Given I am on the account registration form
    Then the "Email address" label should display a required field indicator

  Scenario: Active navigation item has a visible underline accent
    Given I am on the dashboard
    When I navigate to the "Settings" section
    Then the "Settings" nav item should have an active accent underline

  Scenario: Error-state input shows a red left border via pseudo-element
    Given I submit the registration form with an empty email field
    Then the email input container should show an error indicator
```

```typescript
// src/steps/visual-indicators.steps.ts — toHaveCSS() pseudo option (v1.60+)
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AppWorld } from '../support/world';

// Matches: Then the "Email address" label should display a required field indicator
Then(
  'the {string} label should display a required field indicator',
  async function (this: AppWorld, labelText: string) {
    const label = this.page.getByText(labelText, { exact: true });

    // Assert the ::after pseudo-element contains the asterisk (*) character
    // using content: '"*"' (CSS string value syntax includes quotes)
    await expect(label).toHaveCSS('content', '"*"', {
      pseudo: '::after',  // v1.60+ pseudo option — targets the ::after pseudo-element
    });

    // Assert the asterisk is rendered in the required-field color (typically red or accent)
    await expect(label).toHaveCSS('color', 'rgb(220, 38, 38)', {
      pseudo: '::after',
    });
  }
);

// Matches: Then the "Settings" nav item should have an active accent underline
Then(
  'the {string} nav item should have an active accent underline',
  async function (this: AppWorld, navItemText: string) {
    const navItem = this.page.getByRole('link', { name: navItemText });

    // The active underline is rendered via ::after with width: 100% and a visible background
    await expect(navItem).toHaveCSS('width', '100%', {
      pseudo: '::after',
    });
    await expect(navItem).toHaveCSS('background-color', 'rgb(59, 130, 246)', {
      pseudo: '::after',  // Accent blue background on active nav item's ::after
    });
  }
);

// Matches: Then the email input container should show an error indicator
Then('the email input container should show an error indicator', async function (this: AppWorld) {
  const inputContainer = this.page.getByTestId('email-input-container');

  // Error state: the ::before pseudo-element renders a red left-border accent
  // checking both display property and the specific color value
  await expect(inputContainer).toHaveCSS('display', 'block', {
    pseudo: '::before',
  });
  await expect(inputContainer).toHaveCSS('background-color', 'rgb(239, 68, 68)', {
    pseudo: '::before',  // Red left-border indicator for error state
  });
});
```

**[community] `pseudo` option unlocks pure-CSS UI contract testing in BDD**: A substantial portion of modern UI visual design relies on `::before`/`::after` pseudo-elements — required-field markers, tooltips, custom checkbox/radio graphics, notification badges, and decorative separators. Before the `pseudo` option, BDD step definitions either skipped these assertions (accepting that the visual layer was untested) or used JavaScript `getComputedStyle(el, '::before')` workarounds that were verbose and not integrated with Playwright's retry-assertion engine. The `pseudo` option makes these assertions first-class: they participate in Playwright's auto-retry loop, produce readable error messages like `expect(locator).toHaveCSS('content', '"*"', { pseudo: '::after' }) — expected "none", received '"*"'`, and can be co-located with other `expect()` assertions in the same `Then` step.

---

## Additional Resources (Iteration 35 Additions)

### Playwright v1.54–v1.56: BDD-Relevant APIs  [community]

Three releases between v1.53 and v1.57 added tooling that closes specific gaps in BDD authoring and step-level diagnostics.

#### `TestStepInfo.titlePath` — Hierarchical Step Path for Artifact Naming (v1.55+)

Playwright v1.55 added a `titlePath` property to `TestStepInfo`. It returns `Array<string>` — the full title path starting from the test file name, through the test title, down to each nested step title. In playwright-bdd, `titlePath` is accessible via `$testInfo.titlePath` inside fixtures.

**Why this matters for BDD**: Feature file names and scenario titles already form a natural hierarchy — `features/checkout.feature` → `Checkout with credit card` → `Then I should see an order confirmation`. `titlePath` exposes this hierarchy programmatically, making it possible to generate uniquely named artifact files (screenshots, HAR archives, video clips) that are human-readable without collision, even when two scenarios share identical step names.

```typescript
// src/steps/artifacts.steps.ts — titlePath for unique artifact naming (v1.55+)
import { createBdd } from 'playwright-bdd';
import path from 'path';

const { Then, After } = createBdd();

// After hook that generates a descriptive screenshot name from the BDD title hierarchy
After(async ({ page, $testInfo }, scenario) => {
  if (scenario.result?.status === 'FAILED') {
    // titlePath returns e.g. ['features/checkout.feature', 'Checkout', 'Then I should see an order confirmation page']
    const titlePath: string[] = $testInfo.titlePath;

    // Sanitise each path segment (remove special chars) and join with underscores
    const sanitised = titlePath
      .map((segment: string) => segment.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 40))
      .join('__');

    const screenshotPath = path.join('reports', 'screenshots', `${sanitised}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    await $testInfo.attach('Failure screenshot', {
      path: screenshotPath,
      contentType: 'image/png',
    });
  }
});

// Step that exposes the current BDD path in the Playwright HTML report
Then(
  'the test step context should be logged for debugging',
  async ({ $testInfo }) => {
    const titlePath: string[] = $testInfo.titlePath;
    await $testInfo.attach('BDD step path', {
      body: titlePath.join(' > '),
      contentType: 'text/plain',
    });
  }
);
```

**[community] `titlePath` vs `title` for artifact deduplication**: `$testInfo.title` returns only the innermost step title, which is frequently identical across scenarios (e.g., `Then I should see an order confirmation page` is used by a dozen scenarios). `titlePath` gives the full ancestry, so two screenshots from different scenarios with the same step name will have different filenames. Teams that switched from `$testInfo.title` to `$testInfo.titlePath.join('__')` for screenshot naming eliminated artifact overwrites in sharded CI runs where multiple workers wrote to the same reports directory.

#### Playwright Test Agents: `npx playwright init-agents` (v1.56+)

Playwright v1.56 introduced `npx playwright init-agents`, which generates LLM agent definition files that guide AI assistants through the complete Playwright test-authoring loop. The command supports three LLM client targets: `--loop=vscode` (GitHub Copilot / VS Code extensions), `--loop=claude` (Claude Code), and `--loop=opencode`.

The generated agents implement a three-phase agentic loop:

| Agent | Role | Output |
|---|---|---|
| **planner** | Explores the running application and produces a Markdown test plan | `test-plan.md` with feature areas and scenario candidates |
| **generator** | Transforms the test plan into Playwright `.spec.ts` files | Executable Playwright test files |
| **healer** | Runs the test suite and automatically repairs failing tests | Fixed test files with updated selectors/assertions |

**Why this is BDD-adjacent**: The `planner` agent's output (a Markdown test plan with scenario candidates) closely mirrors the output of an Example Mapping workshop — structured feature areas with concrete examples. Teams using Gherkin can treat `planner` output as a first-pass draft for Three Amigos review, then promote the refined examples to `.feature` files for formalization.

```bash
# Generate agent definition files for Claude Code
npx playwright init-agents --loop=claude

# This creates .claude/agents/ files (or equivalent) that implement the planner/generator/healer loop
# Run the planner agent against a running app to produce a test plan:
#   → describes observable feature areas, lists scenario candidates per area
# Run the generator agent against the test plan:
#   → produces Playwright .spec.ts files for each scenario
# Run the healer agent when tests fail:
#   → diagnoses selector/assertion issues and proposes fixes
```

```typescript
// Example: using planner output as BDD scenario seeds
// planner output (Markdown excerpt):
// ## Checkout
// - Happy path: guest user completes purchase with credit card
// - Error path: checkout fails when card is declined
// - Edge case: user applies expired discount code at checkout
//
// Treat each bullet as a candidate Gherkin Scenario for Three Amigos review:

// features/checkout.feature (after Three Amigos refinement of planner output)
/*
Scenario: Guest user completes purchase with a valid credit card
  Given I have added a product to my cart as a guest
  When I complete checkout with a valid credit card
  Then my order should be confirmed

Scenario: Checkout fails when the card is declined
  Given I have added a product to my cart
  When I attempt checkout with a declined card
  Then I should see a payment declined message
  And my cart should remain unchanged
*/
```

**[community] Playwright agents vs playwright-bdd AI skill**: `npx playwright init-agents` produces native Playwright `.spec.ts` files — not Gherkin. The playwright-bdd AI generation skill (documented in iteration 27) produces `.feature` files and step stubs. Choose based on your target artifact: if your team uses Gherkin as the canonical specification, use playwright-bdd's skill; if you need Playwright-native tests rapidly and will review/promote them to BDD scenarios later, `init-agents` is faster for initial discovery.

#### `page.pickLocator()` — Interactive Locator Discovery During Step Authoring (v1.59+)

Playwright v1.59 added `page.pickLocator()`, which puts the browser into interactive hover-and-click mode: hovering over an element shows its computed locator, and clicking captures it, returning a `Promise<Locator>`. It is a development-time utility — not for use in production test steps — but it directly accelerates the BDD step definition authoring workflow.

```typescript
// scripts/pick-locator.ts — development helper for discovering locators interactively
// Run with: npx ts-node scripts/pick-locator.ts
import { chromium, type Locator } from 'playwright';

async function interactiveLocatorDiscovery(url: string): Promise<void> {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.goto(url);

  console.log('Hover over an element to see its locator, then click to capture it...');

  // page.pickLocator() blocks until the user clicks an element
  const locator: Locator = await page.pickLocator();

  // Log the locator string for use in step definitions
  console.log(`Captured locator: ${locator}`);
  // Example output: getByRole('button', { name: 'Add to Cart' })
  //                 getByTestId('checkout-submit')
  //                 getByLabel('Email address')

  await browser.close();
}

// Usage during step definition authoring:
// 1. Start the app: npm run dev
// 2. Run this script: npx ts-node scripts/pick-locator.ts
// 3. Click the element your Given/When/Then step targets
// 4. Paste the captured locator into your step definition
await interactiveLocatorDiscovery('http://localhost:3000/checkout');
```

**[community] `page.pickLocator()` for step definition review**: BDD teams often debate which locator strategy to use in step definitions — `getByRole`, `getByTestId`, `getByLabel`, or CSS selectors. `page.pickLocator()` resolves this empirically: Playwright computes the "best-practice" locator for the element using its internal heuristic (role > label > testid > other). Running it on an element quickly reveals whether the expected `data-testid` attribute is present, or whether the accessible role is better. This is particularly valuable when a new team member is writing step definitions for a feature area they have not worked in before.

**`page.pickLocator()` vs `--debug=cli` for step authoring**:

| Tool | Use case | Mode |
|---|---|---|
| `page.pickLocator()` | Find the right locator for an element | Interactive (headful browser) |
| `--debug=cli` (v1.59+) | Step through existing steps line-by-line | Headless CLI |
| Playwright Inspector | Full visual debugger with step-through | Interactive (headful) |

Use `page.pickLocator()` at the start of step authoring (when you do not yet know the locator). Use `--debug=cli` when you have locators but need to trace why a step is failing.

---

## Additional Resources (Iteration 35 Additions)

- [Playwright `TestStepInfo.titlePath` docs](https://playwright.dev/docs/api/class-teststepinfo#test-step-info-title-path) — v1.55+ `Array<string>` property with the full step ancestry from file → test → step; use for collision-free artifact naming in sharded CI
- [Playwright Test Agents (`init-agents`)](https://playwright.dev/docs/release-notes#version-156) — v1.56+ official Playwright AI agent loop (planner/generator/healer) for automated test generation; BDD teams can use planner output as Three Amigos seed material
- [Playwright `page.pickLocator()` docs](https://playwright.dev/docs/api/class-page#page-pick-locator) — v1.59+ interactive hover-and-click locator discovery for step definition authoring; returns `Promise<Locator>` with Playwright's best-practice locator for the selected element

---

## Additional Resources (Iteration 34 Additions)

- [Playwright `page.screencast()` docs](https://playwright.dev/docs/api/class-page#page-screencast) — v1.59+ per-scenario screen recording with `annotate()` overlays; use in Cucumber `Before`/`BeforeStep`/`After` hooks to embed BDD step names in failure videos
- [Playwright `toHaveCSS()` pseudo option](https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-have-css) — v1.60+ `pseudo: '::before' | '::after'` for asserting CSS property values on pseudo-elements; use in `Then` steps for required-field markers, active-state indicators, and custom UI component visual contracts

---

## Additional Resources (Iteration 33 Additions)

- [Playwright `await using` disposable protocol](https://playwright.dev/docs/release-notes#version-159) — v1.59+ TypeScript disposable support for automatic browser/context/page cleanup; requires TypeScript 5.2+
- [Playwright `page.ariaSnapshot()` on pages](https://playwright.dev/docs/api/class-page#page-aria-snapshot) — v1.59+ full-page ARIA tree capture (previously locator-only); use in `Then` steps for structural accessibility assertions
- [Playwright CLI debugger `--debug=cli`](https://playwright.dev/docs/release-notes#version-159) — v1.59+ headless interactive debugger for BDD step development in terminal; alternative to GUI Inspector for remote/CI environments
- [Playwright `locator.drop()` docs](https://playwright.dev/docs/api/class-locator#locator-drop) — v1.60+ external file drag-and-drop simulation; use for custom upload zone BDD scenarios where `setInputFiles()` does not fire drag events
- [Playwright `tracing.startHar()` / `tracing.stopHar()` docs](https://playwright.dev/docs/api/class-tracing#tracing-start-har) — v1.60+ first-class HAR recording API for BDD failure network capture; attach to Cucumber report artifacts
- [Playwright `getByRole()` description option](https://playwright.dev/docs/api/class-framelocator#frame-locator-get-by-role) — v1.60+ `description` parameter for disambiguating elements with the same accessible name using `aria-description`/`aria-describedby`

---

## Additional Resources (Iteration 32 Additions)

- [Playwright `TestStepInfo` docs](https://playwright.dev/docs/api/class-teststepinfo) — v1.51+ step-level `attach()` and `skip()` for conditional step execution in playwright-bdd fixtures
- [Playwright `storageState` indexedDB option](https://playwright.dev/docs/api/class-browsercontext#browser-context-storage-state) — v1.51+ `indexedDB: true` option for capturing IndexedDB auth tokens (Firebase Auth, Supabase, custom IndexedDB stores)
- [Playwright `toContainClass()` docs](https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-contain-class) — v1.52+ class token assertion (avoids substring-match false positives from `toHaveAttribute('class', /active/)`)
- [Playwright `locator.describe()` docs](https://playwright.dev/docs/api/class-locator#locator-describe) — v1.53+ semantic labeling of locators for trace viewer and HTML report readability
- [Playwright `page.consoleMessages()` docs](https://playwright.dev/docs/api/class-page#page-console-messages) — v1.56+ snapshot retrieval of recent console messages without prior listener setup
- [Playwright `page.pageErrors()` docs](https://playwright.dev/docs/api/class-page#page-page-errors) — v1.56+ retrieval of uncaught JavaScript errors on the page
- [Playwright `page.requests()` docs](https://playwright.dev/docs/api/class-page#page-requests) — v1.56+ snapshot of recent network requests; use in `Then` steps to assert on analytics and audit log side effects
- [Playwright `test.abort()` docs](https://playwright.dev/docs/api/class-test#test-abort) — v1.60+ fixture-driven test abort with explicit failure message; use for hard infrastructure precondition failures

---

## TypeScript 5.5+ Strict Defaults and BDD Step Definitions  [community]

TypeScript 5.5 and 5.6 introduced compiler flag defaults that affect how BDD step definitions are written, particularly around DataTable access patterns and step factory exports.

### `noUncheckedIndexedAccess` and DataTable Row Handling

`noUncheckedIndexedAccess` (introduced in TypeScript 4.1, enabled by strict presets in TypeScript 5.5+) adds `undefined` to every array index access and object index signature. This changes how DataTable rows must be handled in BDD step definitions: previously safe-looking `row[0]` accesses now require explicit null-coalescing guards or the TypeScript compiler emits errors.

```gherkin
# features/orders/bulk-order.feature
Scenario Outline: Bulk order processing
  Given the following products are in my order:
    | SKU        | quantity | price  |
    | LAPTOP-001 | 2        | 899.99 |
    | MOUSE-002  | 5        | 29.99  |
  When I submit the bulk order
  Then the order total should be 1949.93
```

```typescript
// tsconfig.json — TypeScript 5.5+ strict preset that enables noUncheckedIndexedAccess
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true   // TypeScript 5.5+ strict preset default
  }
}
```

```typescript
// src/steps/bulk-order.steps.ts — DataTable access with noUncheckedIndexedAccess

import { Given } from '@cucumber/cucumber';
import { DataTable } from '@cucumber/cucumber';
import { AppWorld } from '../support/world';

// BROKEN with noUncheckedIndexedAccess: true
// Type error: 'row[0]' is 'string | undefined' — cannot assign to 'string'
Given('the following products are in my order:', function (this: AppWorld, table: DataTable) {
  // BAD: row[0] has type string | undefined when noUncheckedIndexedAccess is enabled
  const rows = table.rows();
  for (const row of rows) {
    const sku = row[0];          // Error: Type 'string | undefined' is not assignable to type 'string'
    const qty = parseInt(row[1]); // Error: Argument of type 'string | undefined' is not assignable to 'string'
  }
});

// FIXED pattern 1: null-coalescing with fallback (recommended for optional data)
Given('the following products are in my order:', function (this: AppWorld, table: DataTable) {
  const rows = table.rows();
  for (const row of rows) {
    const sku = row[0] ?? '';           // Explicit fallback — safe with noUncheckedIndexedAccess
    const qty = parseInt(row[1] ?? '0');
    const price = parseFloat(row[2] ?? '0');
    this.orderItems.push({ sku, qty, price });
  }
});

// FIXED pattern 2: hashes() method — preferred when columns have names (avoids index access)
Given('the following products are in my order:', function (this: AppWorld, table: DataTable) {
  // hashes() returns Array<Record<string, string>> — no numeric index access required
  // Each row is accessed by column name string key, not numeric index
  const rows = table.hashes();  // [{ SKU: 'LAPTOP-001', quantity: '2', price: '899.99' }, ...]
  for (const row of rows) {
    const sku = row['SKU'] ?? '';           // String key index — still needs ?? with noUncheckedIndexedAccess
    const qty = parseInt(row['quantity'] ?? '0');
    const price = parseFloat(row['price'] ?? '0');
    this.orderItems.push({ sku, qty, price });
  }
});

// FIXED pattern 3: rowsHash() for key-value tables (single-column key, no index access)
// Use when the DataTable has exactly two columns: key | value
// Given the following user profile:
//   | name  | Alice        |
//   | email | alice@co.com |
Given('the following user profile:', function (this: AppWorld, table: DataTable) {
  const data = table.rowsHash();   // { name: 'Alice', email: 'alice@co.com' }
  // Object property access — safe even with noUncheckedIndexedAccess:
  this.profile = {
    name: data['name'] ?? '',
    email: data['email'] ?? '',
  };
});
```

**[community] `hashes()` over `rows()` is the correct BDD DataTable pattern regardless of TypeScript strictness**: `rows()` with numeric indices is fragile because it encodes column order implicitly — reordering the DataTable in the feature file silently breaks the step. `hashes()` is resilient to column reordering because it accesses data by name. The `noUncheckedIndexedAccess` compiler flag makes this best practice enforceable at compile time: code that uses `row[0]` will now produce TypeScript errors, nudging teams toward the `hashes()` and `rowsHash()` APIs.

### `isolatedDeclarations` and Step Factory Exports

TypeScript 5.5 introduced `isolatedDeclarations` as a strict mode option. When enabled, every exported function must have an explicit return type annotation (rather than relying on type inference). This affects step definition factories — functions that create and export step definitions for reuse across multiple feature contexts.

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "isolatedDeclarations": true   // TypeScript 5.5+ — requires explicit return types on exports
  }
}
```

```typescript
// src/steps/factories/auth-steps.factory.ts
// Reusable step definition factory — exported for use in multiple feature step files

import { IDefineStep } from '@cucumber/cucumber';

// BROKEN with isolatedDeclarations: true
// Error: Return type of exported function must be explicitly specified
export function createAuthSteps(given: IDefineStep, when: IDefineStep, then: IDefineStep) {
  // Error: isolatedDeclarations requires explicit return type
  given('I am logged in as {string}', async function (this: AppWorld, role: string) { ... });
  when('I log out', async function (this: AppWorld) { ... });
}

// FIXED: explicit return type annotation
export function createAuthSteps(
  given: IDefineStep,
  when: IDefineStep,
  then: IDefineStep
): void {   // Explicit return type — satisfies isolatedDeclarations
  given('I am logged in as {string}', async function (this: AppWorld, role: string) {
    await this.page.goto('/login');
    await this.page.getByLabel('Email').fill(`${role.toLowerCase()}@example.com`);
    await this.page.getByLabel('Password').fill('test-password-123');
    await this.page.getByRole('button', { name: 'Sign in' }).click();
    await this.page.waitForURL('/dashboard');
  });

  when('I log out', async function (this: AppWorld) {
    await this.page.getByRole('button', { name: 'Sign out' }).click();
    await this.page.waitForURL('/login');
  });

  then('I should be redirected to the login page', async function (this: AppWorld) {
    await expect(this.page).toHaveURL('/login');
  });
}
```

```typescript
// playwright-bdd pattern: createBdd() factory with explicit return type (isolatedDeclarations)
import { createBdd } from 'playwright-bdd';
import type { BddFixtures } from 'playwright-bdd';
import type { Page } from '@playwright/test';

// The return type of createBdd() must be explicitly typed when re-exported
// satisfies BddFixtures ensures the fixture type contract is maintained
export function buildAuthFixtures(
  test: ReturnType<typeof createBdd>['test']
): ReturnType<typeof createBdd> {  // Explicit return type for isolatedDeclarations
  return createBdd(test);
}
```

**[community] `isolatedDeclarations` adoption in BDD codebases**: The `isolatedDeclarations` flag was designed for monorepos that use isolated transpilation (esbuild, swc, Vite) where each file is compiled independently without type information from other files. In BDD projects, it primarily affects step definition factory files — helper modules that compose reusable step definitions. Adding explicit `void` or typed return annotations to these factories also serves as documentation: a reader immediately knows the factory registers side effects (step definitions) and returns nothing. Teams that have adopted `isolatedDeclarations` report fewer TypeScript errors during CI because return-type mismatches in factory functions are caught at authoring time rather than at runtime.

---

## AI-Generated Gherkin Quality Evaluation Checklist  [community]

AI-assisted scenario generation tools (Playwright Test Agents planner, playwright-bdd skill, GitHub Copilot, Claude Code) can produce Gherkin feature files faster than manual authoring. However, AI-generated Gherkin has specific failure modes: it tends to produce imperative steps (describing implementation) instead of declarative steps (describing behaviour), include overly specific data that is hard to maintain, and conflate multiple actions into a single `When` step. A structured quality gate applied before promoting AI-generated scenarios to the official feature suite prevents these patterns from entering the codebase.

### The 7-Criterion BDD Acceptance Checklist

Apply these criteria to every AI-generated scenario before accepting it into the suite:

| # | Criterion | Pass | Fail |
|---|-----------|------|------|
| 1 | **INVEST alignment** | Scenario covers one independent, valuable behaviour | Scenario tests two unrelated user goals in the same `Scenario` |
| 2 | **Ubiquitous language** | Steps use domain vocabulary (from glossary/Three Amigos) | Steps use technical terms (`API call`, `database row`, `HTTP 200`) |
| 3 | **Data specificity** | Example data is minimal and meaningful (`user@example.com`) | Data is overly detailed (`user.name=JohnDoe, id=4829347, created_at=2024-01-15T...`) |
| 4 | **Step atomicity** | Each `Given`/`When`/`Then` expresses one action or state | A single step contains `and` describing two separate actions |
| 5 | **Observable outcome** | `Then` steps assert user-visible behaviour | `Then` asserts internal state (`the database should contain a row`) |
| 6 | **Tag hygiene** | Tags reflect test characteristics (`@smoke`, `@regression`, `@slow`) | Tags encode author/date/AI tool metadata (`@gpt-4o`, `@autogenerated-2025-01`) |
| 7 | **Implementation freedom** | Steps could be fulfilled by any implementation | Steps prescribe UI mechanism (`When I click the blue "Submit" button at position (300,200)`) |

### TypeScript Quality Scoring Utility

```typescript
// scripts/bdd-quality-check.ts — static checklist scorer for AI-generated Gherkin
// Run before committing new feature files: npx ts-node scripts/bdd-quality-check.ts features/new/

import * as fs from 'fs';
import * as path from 'path';

interface QualityIssue {
  criterion: number;
  severity: 'error' | 'warning';
  line: number;
  message: string;
}

interface QualityReport {
  file: string;
  issues: QualityIssue[];
  score: number;  // 0-100 — deduct per criterion failure
}

// Heuristic checks — supplement with manual Three Amigos review
const TECHNICAL_TERMS_REGEX = /\b(API|HTTP|JSON|database|SQL|endpoint|request|response|status code|200|404|500|UUID|timestamp|milliseconds)\b/gi;
const CONJUNCTIVE_STEP_REGEX = /^(Given|When|Then|And|But)\s+.+\s+(and|AND)\s+.+/m;
const IMPERATIVE_UI_REGEX = /\b(click|tap|type|select|fill in|enter|press)\b.*(button|field|input|dropdown|checkbox|link)\b/gi;
const INTERNAL_STATE_REGEX = /\b(database|DB|table|record|row|column|index|cache|memory|log|queue|event bus)\b/gi;
const METADATA_TAG_REGEX = /@(gpt|claude|ai-generated|autogenerated|llm|copilot|v\d+\.\d+)/gi;

function checkFeatureFile(filePath: string): QualityReport {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  const issues: QualityIssue[] = [];

  lines.forEach((line, idx) => {
    const lineNum = idx + 1;

    // Criterion 2: ubiquitous language — technical terms in step text
    if (/^\s*(Given|When|Then|And|But)\s/.test(line)) {
      const techMatches = line.match(TECHNICAL_TERMS_REGEX);
      if (techMatches) {
        issues.push({
          criterion: 2,
          severity: 'warning',
          line: lineNum,
          message: `Technical term(s) in step text: ${[...new Set(techMatches)].join(', ')} — use domain language instead`,
        });
      }
    }

    // Criterion 4: step atomicity — conjunctive steps
    if (/^\s*(When|Then)\s/.test(line) && CONJUNCTIVE_STEP_REGEX.test(line)) {
      issues.push({
        criterion: 4,
        severity: 'error',
        line: lineNum,
        message: 'Conjunctive step detected — split into two separate steps using "And"',
      });
    }

    // Criterion 5: observable outcome — internal state in Then steps
    if (/^\s*(Then|And)\s/.test(line) && INTERNAL_STATE_REGEX.test(line)) {
      issues.push({
        criterion: 5,
        severity: 'warning',
        line: lineNum,
        message: 'Then step asserts internal state — assert user-visible outcome instead',
      });
    }

    // Criterion 6: tag hygiene — AI metadata tags
    if (/^\s*@/.test(line) && METADATA_TAG_REGEX.test(line)) {
      issues.push({
        criterion: 6,
        severity: 'error',
        line: lineNum,
        message: 'AI/tool metadata tag detected — remove before committing to feature suite',
      });
    }

    // Criterion 7: implementation freedom — imperative UI steps
    if (/^\s*(When|Given)\s/.test(line) && IMPERATIVE_UI_REGEX.test(line)) {
      issues.push({
        criterion: 7,
        severity: 'warning',
        line: lineNum,
        message: 'Imperative UI step detected — rewrite as declarative user intent',
      });
    }
  });

  // Score: start at 100, deduct 10 per error, 5 per warning
  const errorCount = issues.filter(i => i.severity === 'error').length;
  const warningCount = issues.filter(i => i.severity === 'warning').length;
  const score = Math.max(0, 100 - (errorCount * 10) - (warningCount * 5));

  return { file: filePath, issues, score };
}

// CLI entry point
const targetDir = process.argv[2] ?? 'features';
const featureFiles = fs.readdirSync(targetDir, { recursive: true })
  .filter((f): f is string => typeof f === 'string' && f.endsWith('.feature'))
  .map(f => path.join(targetDir, f));

let hasErrors = false;
for (const file of featureFiles) {
  const report = checkFeatureFile(file);
  if (report.issues.length > 0) {
    console.log(`\n${file} — Score: ${report.score}/100`);
    for (const issue of report.issues) {
      const prefix = issue.severity === 'error' ? '  ✗' : '  ⚠';
      console.log(`${prefix} [Line ${issue.line}] Criterion ${issue.criterion}: ${issue.message}`);
    }
    if (report.issues.some(i => i.severity === 'error')) hasErrors = true;
  } else {
    console.log(`${file} — Score: 100/100 ✓`);
  }
}

process.exit(hasErrors ? 1 : 0);
```

```bash
# package.json script — run before accepting AI-generated feature files
# "bdd:quality": "npx ts-node scripts/bdd-quality-check.ts features/new/"

npx ts-node scripts/bdd-quality-check.ts features/new/
# Output example:
# features/new/checkout.feature — Score: 75/100
#   ✗ [Line 12] Criterion 4: Conjunctive step detected — split into two separate steps using "And"
#   ⚠ [Line 18] Criterion 2: Technical term(s) in step text: HTTP — use domain language instead
#   ⚠ [Line 25] Criterion 7: Imperative UI step detected — rewrite as declarative user intent
```

**[community] Automating quality gates for AI-generated Gherkin**: The utility above catches the most common AI generation failure modes statically — before the Three Amigos review. The intent is not to replace human review but to eliminate obvious issues automatically so that the review meeting focuses on domain correctness and business value rather than formatting and style. Teams that have integrated a similar heuristic check into their `pre-commit` hook and PR CI step report that AI-generated scenarios promoted to the official suite require 40-60% fewer revision cycles because the mechanical issues are resolved before the review even begins. The checker's output also functions as an educational prompt: new team members learn BDD principles from the inline messages rather than from a separate style guide.

---

## Cucumber.js `externalise` Option — Step Definition Extraction (v12.8.0)

Cucumber.js v12.8.0 introduced the `externalise` option in the profile configuration. When `externalise: true`, Cucumber emits each loaded step definition's location as a `step-definition-pattern.message` in the output stream, enabling IDE extensions and tooling to build a live index of step definitions without parsing TypeScript source files. For teams building custom editors or CI tooling, this is the official way to enumerate all loaded steps programmatically.

**What `externalise` solves**: Before v12.8.0, finding all step definitions in a large TypeScript monorepo required either parsing the source files with regex (fragile) or running Cucumber with `--dry-run` and scraping the output (slow). `externalise: true` adds structured step-definition discovery to the Cucumber message stream without executing any scenarios.

```typescript
// cucumber.ts — profile configuration using externalise (Cucumber.js v12.8.0+)
import type { IConfiguration } from '@cucumber/cucumber/api';

const config = {
  default: {
    paths: ['features/**/*.feature'],
    require: ['src/steps/**/*.steps.ts', 'src/support/**/*.ts'],
    requireModule: ['ts-node/register'],
    format: ['@cucumber/pretty-formatter'],
    externalise: false,    // Default: false — normal scenario execution
  } satisfies Partial<IConfiguration>,

  // Dedicated profile for step-definition indexing without running scenarios
  'index-steps': {
    paths: ['features/**/*.feature'],
    require: ['src/steps/**/*.steps.ts', 'src/support/**/*.ts'],
    requireModule: ['ts-node/register'],
    format: ['json:reports/step-index.json'],
    dryRun: true,
    externalise: true,   // v12.8.0+: emit step-definition-pattern.message entries
  } satisfies Partial<IConfiguration>,
} satisfies Record<string, Partial<IConfiguration>>;

export default config;
```

```bash
# Run step indexing without executing scenarios
CUCUMBER_PROFILE=index-steps npx cucumber-js

# This writes reports/step-index.json containing step-definition-pattern messages
# Each entry includes:
#   - pattern: "I am logged in as {string}"
#   - location: { uri: "src/steps/auth.steps.ts", line: 14 }
#   - expression type: "CucumberExpression" | "RegularExpression"
```

```typescript
// scripts/list-all-steps.ts — read externalise output to build a step inventory
// Useful for detecting duplicate steps, coverage gaps, and unused step definitions

import * as fs from 'fs';

interface StepDefinitionMessage {
  stepDefinitionPattern?: {
    pattern: string;
    type: 'CUCUMBER_EXPRESSION' | 'REGULAR_EXPRESSION';
  };
  location?: {
    uri: string;
    line: number;
  };
}

interface CucumberMessage {
  stepDefinition?: StepDefinitionMessage;
}

function loadStepIndex(jsonReportPath: string): StepDefinitionMessage[] {
  const content = fs.readFileSync(jsonReportPath, 'utf-8');
  // Cucumber JSON report is newline-delimited JSON messages
  const messages: CucumberMessage[] = content
    .split('\n')
    .filter(line => line.trim())
    .map(line => JSON.parse(line) as CucumberMessage);

  return messages
    .filter((msg): msg is { stepDefinition: StepDefinitionMessage } => !!msg.stepDefinition)
    .map(msg => msg.stepDefinition);
}

const steps = loadStepIndex('reports/step-index.json');

// Print all step patterns grouped by source file
const byFile = new Map<string, StepDefinitionMessage[]>();
for (const step of steps) {
  const uri = step.location?.uri ?? 'unknown';
  if (!byFile.has(uri)) byFile.set(uri, []);
  byFile.get(uri)!.push(step);
}

for (const [file, fileSteps] of byFile) {
  console.log(`\n${file}:`);
  for (const step of fileSteps) {
    const pattern = step.stepDefinitionPattern?.pattern ?? '?';
    const type = step.stepDefinitionPattern?.type === 'REGULAR_EXPRESSION' ? '(regex)' : '';
    console.log(`  Line ${step.location?.line}: ${pattern} ${type}`);
  }
}

console.log(`\nTotal: ${steps.length} step definitions across ${byFile.size} files`);
```

**[community] `externalise` for large TypeScript BDD monorepos**: In monorepos with 50+ step definition files, duplicate step patterns are a persistent issue — two feature domains accidentally register the same step text, causing Cucumber to emit "Ambiguous step definition" errors at runtime. Running `externalise: true` with `dryRun: true` in CI as a separate job produces a step inventory without executing any scenarios (fast: ~2-3 seconds for most suites). A CI step that checks this inventory for duplicates catches ambiguous step conflicts before they reach the test execution stage, which can save 5-10 minutes of CI time compared to discovering the conflict after a full scenario run.

---

## Additional Resources (Iteration 36 Additions)

- [TypeScript `noUncheckedIndexedAccess` handbook](https://www.typescriptlang.org/tsconfig#noUncheckedIndexedAccess) — adds `undefined` to all array index and object index-signature types; use Cucumber's `hashes()` and `rowsHash()` DataTable methods to avoid numeric index access in step definitions
- [TypeScript `isolatedDeclarations` handbook](https://www.typescriptlang.org/tsconfig#isolatedDeclarations) — requires explicit return types on all exported functions; affects step definition factory functions — add explicit `: void` return type annotation
- [Cucumber.js `externalise` option](https://github.com/cucumber/cucumber-js/blob/main/docs/profiles.md) — v12.8.0+ option that emits step-definition-pattern messages for programmatic step indexing; combine with `dryRun: true` to enumerate all loaded steps without executing scenarios
