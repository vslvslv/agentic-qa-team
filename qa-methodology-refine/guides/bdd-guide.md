# Behavior-Driven Development (BDD) — QA Methodology Guide
<!-- lang: JavaScript | topic: bdd | iteration: 2 | score: 100/100 | date: 2026-04-30 | sources: training-knowledge + qa-methodology/references/bdd-guide.md -->
<!-- WebFetch and WebSearch unavailable; synthesized from training knowledge + existing bdd-guide.md (TypeScript) + javascript-patterns reference -->

## Core Principles

Behavior-Driven Development (BDD) is a software development methodology that encourages
collaboration among developers, QA engineers, and business stakeholders to define the expected
behavior of a system **before** implementation begins. Introduced by Dan North in 2003 as an
evolution of TDD, BDD bridges the gap between technical and non-technical team members by using
a shared, human-readable language to describe system behavior.

BDD rests on three foundational pillars:

1. **Shared understanding**: All stakeholders — developers, QA, and product owners — collaborate to
   define what "done" means before writing a single line of code. This is why BDD produces better
   software than TDD alone: TDD tells you when code is correct; BDD tells you when the team agreed
   on what "correct" means.
2. **Executable specifications**: Feature files written in Gherkin serve as both documentation and
   automated tests, ensuring documentation never drifts from reality. A passing feature file is
   proof, not promise — unlike a wiki entry, it cannot lie about what the system does today.
3. **Outside-in development**: Teams start from the user's perspective, working inward from business
   scenarios toward implementation details. This prevents the common failure mode of building
   technically correct software that does not solve the actual business problem.

The key insight of BDD is that software failures are often **communication failures**, not technical
ones. The Standish Group repeatedly identifies unclear requirements and stakeholder misalignment as
the top causes of project failure — not code quality. By forcing a concrete, example-driven
conversation before development, BDD surfaces misunderstandings at the cheapest point: before code
is written.

**Team maturity requirements**: BDD is a practice built over 2–3 sprints, not a tool you install:
- A product owner or BA who attends Three Amigos sessions and writes business rules in plain English.
- A QA engineer who can distinguish a business scenario from a test script and challenges "what
  happens when..." edge cases.
- A developer who treats step definitions as production-quality code, not throwaway glue.

Without all three, BDD collapses into "Gherkin theater" — the form of the practice without the substance.

## When to Use

BDD adds clear value in the following contexts:

- **Complex business domains** where rules are non-trivial and ambiguity is common (insurance pricing,
  financial workflows, healthcare eligibility, e-commerce checkout rules).
- **Cross-functional teams** where product managers, QA, and developers need a shared truth about behavior.
- **Regression-heavy features** where living documentation prevents behavior regressions over months of iteration.
- **Onboarding-heavy environments** where new team members need to understand system behavior quickly without
  reading implementation code.
- **Compliance and audit requirements** where human-readable proof of tested behavior has business value.

BDD adds overhead and should be avoided or used selectively in:

- **Rapid prototypes** or early-stage products where requirements change daily.
- **Small solo teams** where the collaboration overhead exceeds the communication benefit.
- **Pure UI exploration** or visual testing where Gherkin provides no semantic advantage.
- **Teams without product/QA buy-in** — BDD without the collaboration model degrades into a slow, verbose test framework.
- **Microservice internals** — unit/integration tests serve better than Gherkin for internal logic.

---

## Patterns

### Feature File Structure

A feature file is a plain-text file (`.feature` extension) that uses Gherkin syntax to describe
the behavior of a feature from a user's perspective. It is the central artifact in BDD — the thing
developers implement against, QA validates, and product managers read.

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
- **Background**: Steps that run before every `Scenario` in the file. Use for shared setup — avoid assertions here.
- **Scenario**: A single concrete example of behavior. Each scenario must be independent.
- **Scenario Outline**: A parameterized scenario template combined with an `Examples` table.
- **Examples**: A data table that feeds rows into a `Scenario Outline`. Each row is a separate test execution.

### Given-When-Then Grammar

Given-When-Then is the three-part structure for expressing behavior as a concrete example:

- **Given** (precondition): Establishes the context or state before the action. Describes the world, not the actions that created it.
- **When** (action): The single event or action that triggers the behavior being tested.
- **Then** (expected outcome): The observable result that verifies the behavior. Must be something the system produces, not an internal state.

Supporting keywords: **And** / **But** continue the same clause; **`*`** is a context-free bullet step for Background blocks.

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

The imperative style tightly couples scenarios to UI implementation. When `#submit-button` changes,
every test using it breaks. The declarative style survives UI refactors because the *what* is stable
even when the *how* changes.

**Three real failure patterns (bad vs good):**

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
  And I click "#place-order-btn"
  Then the text "Order #" should appear on the page

# GOOD: Pattern 1 fixed — Declarative / business intent
Scenario: Customer completes a standard purchase
  Given I am a registered customer with items in my cart
  When I complete the checkout process
  Then my order should be confirmed
  And I should receive an order number

# ================================================
# BAD: Pattern 2 — Testing multiple behaviors in one scenario
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

### Step Definitions (JavaScript / @cucumber/cucumber)

Step definitions connect Gherkin steps to executable test logic. Each matches a Gherkin step using
a string or regular expression and executes the corresponding automation code.

**Why step definitions matter**: They translate the business language in `.feature` files into
technical automation code. A well-organized step definition library lets product managers write new
scenarios by combining existing steps — lowering the cost of adding BDD coverage to new features.

**Cucumber expression parameter types** (built-in):

| Type | Gherkin | JavaScript |
|------|---------|------------|
| `{string}` | `"hello"` or `'hello'` | `string` |
| `{int}` | `42` | `number` |
| `{float}` | `3.14` | `number` |
| `{word}` | `confirmed` (no spaces) | `string` |

**Project bootstrap (JavaScript + Cucumber.js + Playwright):**

```bash
# Install dependencies
npm install --save-dev @cucumber/cucumber @playwright/test
npx playwright install chromium
```

`cucumber.js` (ESM config for Cucumber.js v10+):
```javascript
// cucumber.js — ESM format (v10+ requires this, not cucumber.json)
export default {
  default: {
    import: ['src/steps/**/*.js', 'src/support/**/*.js'],
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
    publish: false,
  },
  smoke: {
    import: ['src/steps/**/*.js', 'src/support/**/*.js'],
    tags: '@smoke and not @wip',
    format: ['progress-bar', 'json:reports/smoke-results.json'],
    parallel: 4,
  },
  regression: {
    import: ['src/steps/**/*.js', 'src/support/**/*.js'],
    tags: '@regression and not @wip',
    format: ['progress-bar', 'html:reports/regression-report.html'],
    parallel: 8,
  },
};
```

`package.json`:
```json
{
  "type": "module",
  "scripts": {
    "test:bdd": "cucumber-js",
    "test:bdd:smoke": "cucumber-js --profile smoke",
    "test:bdd:regression": "cucumber-js --profile regression"
  },
  "devDependencies": {
    "@cucumber/cucumber": "^11.0.0",
    "@playwright/test": "^1.44.0"
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
│   │   ├── checkout.steps.js
│   │   └── auth.steps.js
│   └── support/                 # World, hooks, helpers
│       ├── world.js
│       └── hooks.js
├── reports/                     # Generated reports (gitignored)
└── cucumber.js
```

**Step definition file** (`src/steps/checkout.steps.js`):

```javascript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';

// IMPORTANT: Use regular functions (not arrow functions) so that
// 'this' refers to the World object. Arrow functions break 'this' binding.

// Matches: Given I am logged in as a registered customer
Given('I am logged in as a registered customer', async function () {
  await this.page.goto('/login');
  await this.page.fill('[data-testid="email"]', 'test@example.com');
  await this.page.fill('[data-testid="password"]', 'TestPass123!');
  await this.page.click('[data-testid="submit"]');
  await this.page.waitForURL('/dashboard');
});

// Matches: And my shopping cart contains: (DataTable)
Given('my shopping cart contains:', async function (table) {
  const rows = table.hashes(); // [{ product, quantity, price }, ...]
  for (const row of rows) {
    await this.page.request.post('/api/cart/items', {
      data: { productName: row.product, quantity: parseInt(row.quantity, 10) },
    });
  }
});

// Matches: When I enter valid credit card details
When('I enter valid credit card details', async function () {
  await this.page.fill('[data-testid="card-number"]', '4242424242424242');
  await this.page.fill('[data-testid="card-expiry"]', '12/28');
  await this.page.fill('[data-testid="card-cvv"]', '123');
});

// Matches: Then I should see an order confirmation page
Then('I should see an order confirmation page', async function () {
  await expect(this.page.locator('[data-testid="order-confirmation"]')).toBeVisible();
  expect(this.page.url()).toContain('/order/confirmation');
});

// Matches: Then I should see the error {string}
Then('I should see the error {string}', async function (errorMessage) {
  await expect(
    this.page.locator('[data-testid="error-message"]')
  ).toHaveText(errorMessage);
});
```

**World object** (`src/support/world.js`) — shared state across steps in a scenario:

```javascript
import { setWorldConstructor, World } from '@cucumber/cucumber';

/**
 * AppWorld holds all scenario-scoped state. Each scenario gets a
 * fresh instance — this is the safe alternative to module-level variables.
 * The World constructor receives { parameters, attach, log } from Cucumber.
 */
export class AppWorld extends World {
  /** @type {import('@playwright/test').Browser} */  browser = null;
  /** @type {import('@playwright/test').BrowserContext} */ context = null;
  /** @type {import('@playwright/test').Page} */     page = null;

  /** Scenario-scoped data store — add fields as needed */
  authToken = null;
  lastApiResponse = null;
  currentOrderId = null;

  constructor(options) {
    super(options);
    // this.parameters comes from cucumber.js worldParameters config
    this.baseUrl = options.parameters?.baseUrl ?? process.env.BASE_URL ?? 'http://localhost:3000';
  }

  /**
   * Navigate relative to the configured base URL.
   * Use this in step definitions instead of hard-coding absolute URLs.
   */
  async navigateTo(path) {
    await this.page.goto(`${this.baseUrl}${path}`);
  }

  /**
   * Seed data via API and store the result on the World.
   * Preferred over UI-driven setup — 10x faster, always stable.
   */
  async seedCart(items) {
    const res = await this.page.request.post('/api/cart/seed', {
      data: { items },
    });
    if (!res.ok()) throw new Error(`Cart seed failed: ${res.status()}`);
    const body = await res.json();
    this.cartId = body.cartId;
    return body;
  }
}

setWorldConstructor(AppWorld);
```

**Hooks** (`src/support/hooks.js`):

```javascript
import { Before, After, BeforeAll, AfterAll, Status } from '@cucumber/cucumber';
import { chromium } from '@playwright/test';

let sharedBrowser;

BeforeAll(async function () {
  sharedBrowser = await chromium.launch({
    headless: process.env.CI === 'true',
  });
});

AfterAll(async function () {
  await sharedBrowser?.close();
});

Before(async function (scenario) {
  const tags = scenario.pickle.tags.map((t) => t.name);
  this.browser = sharedBrowser;
  this.context = await sharedBrowser.newContext({
    // Adjust viewport for mobile-tagged scenarios
    ...(tags.includes('@mobile') && {
      viewport: { width: 390, height: 844 },
    }),
  });
  this.page = await this.context.newPage();
});

After(async function (scenario) {
  if (scenario.result?.status === Status.FAILED) {
    const screenshot = await this.page.screenshot({ fullPage: true });
    this.attach(screenshot, 'image/png'); // embeds in Cucumber HTML report
    console.error(`FAILED: ${scenario.pickle.name}`);
    console.error(`  URL at failure: ${this.page.url()}`);
  }
  await this.context?.close();
});
```

### Scenario Outline & Examples (data-driven)

`Scenario Outline` eliminates copy-paste scenarios that differ only in input values. The
`<placeholder>` syntax gets substituted with each row from the `Examples` table at runtime.

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
      | email                | password    | expected_outcome          | status_code |
      | alice@example.com    | wrongpass   | Invalid email or password | 401         |
      | notauser@example.com | anything    | Invalid email or password | 401         |
      | alice@example.com    |             | Password is required      | 400         |
```

Multiple `Examples` blocks with labels act as logical groupings. Each row generates a distinct
test execution; the Cucumber HTML report shows each row as a named test case with its inputs,
making failures immediately traceable to the input set.

**Step definition binding for Scenario Outline** (`src/steps/auth.steps.js`):

```javascript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';

Given('I am on the login page', async function () {
  await this.page.goto('/login');
  await expect(this.page.locator('[data-testid="login-form"]')).toBeVisible();
});

When(
  'I submit the credentials {string} and {string}',
  async function (email, password) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="submit"]');
  }
);

Then(
  'I should see the response {string}',
  async function (expectedOutcome) {
    const successMsg = this.page.locator('[data-testid="welcome-message"]');
    const errorMsg = this.page.locator('[data-testid="error-message"]');
    const visible = (await successMsg.isVisible()) ? successMsg : errorMsg;
    await expect(visible).toContainText(expectedOutcome);
  }
);
```

### BDD for REST APIs (Without Browser Automation)

BDD is not limited to browser testing. Many valuable BDD scenarios target API behavior directly —
they run in milliseconds, not seconds, and validate the contract between services in language the
product team can review.

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

```javascript
// src/steps/api.steps.js — API BDD without a browser
import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { app } from '../../src/app.js';

const api = supertest(app);

Given('I have a valid API authentication token', async function () {
  const res = await api.post('/api/auth/token').send({
    clientId: process.env.TEST_CLIENT_ID,
    clientSecret: process.env.TEST_CLIENT_SECRET,
  });
  assert.equal(res.status, 200, `Expected 200 but got ${res.status}`);
  this.authToken = res.body.accessToken;
});

Given('I have the following order payload:', function (docString) {
  this.requestBody = JSON.parse(docString);
});

When('I POST to {string}', async function (path) {
  this.response = await api
    .post(path)
    .set('Authorization', `Bearer ${this.authToken}`)
    .set('Content-Type', 'application/json')
    .send(this.requestBody);
});

When('I GET {string}', async function (path) {
  this.response = await api
    .get(path)
    .set('Authorization', `Bearer ${this.authToken}`);
});

Then('the response status is {int}', function (expectedStatus) {
  assert.equal(
    this.response.status,
    expectedStatus,
    `Expected HTTP ${expectedStatus} but got ${this.response.status}. ` +
      `Body: ${JSON.stringify(this.response.body)}`
  );
});

Then(
  'the response body contains a field {string} matching {word}',
  function (field, pattern) {
    const regex = new RegExp(pattern.replace(/^\/|\/$/g, ''));
    assert.match(
      String(this.response.body[field]),
      regex,
      `Field "${field}" = "${this.response.body[field]}" does not match ${pattern}`
    );
  }
);

Then(
  'the response body contains {string} equal to {string}',
  function (field, value) {
    assert.equal(
      this.response.body[field],
      value,
      `Expected body.${field} = "${value}" but got "${this.response.body[field]}"`
    );
  }
);
```

**Why API BDD matters**: Browser tests are 10–50x slower than API tests. By pushing behavioral
verification to the API layer wherever possible, teams keep BDD suites fast enough to run on every
PR. Rule of thumb: use browser automation only for scenarios where the UI interaction itself is the
thing being tested. For all business logic reachable via API, use API-level BDD.

### Tags, Filtering, and CI Integration

Tags (`@tagname`) control which scenarios run in which CI pipeline stage.

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

**Running tagged subsets:**

```bash
# PR gate: smoke only (fast, < 2 minutes)
npx cucumber-js --profile smoke

# Nightly: all non-WIP scenarios
npx cucumber-js --tags "not @wip"

# Ad-hoc: specific tag combination (v9+ boolean expression syntax)
npx cucumber-js --tags "@payments and @negative"

# WARNING: Old comma-based syntax is silently ignored in v9+
# npx cucumber-js --tags @smoke,@regression  ← BROKEN in v9+
# Use: npx cucumber-js --tags "@smoke or @regression"
```

### Living Documentation

Living documentation is the concept that feature files serve as the definitive, always-current
description of system behavior — **because they are the tests**. Unlike a Wiki page that ages
independently of the code, a passing feature file proves the described behavior exists today.

**Why it matters**: In traditional teams, requirements live in Confluence; test cases live in
TestRail; code lives in the repository. These three representations drift apart within weeks of
delivery. Bugs occur precisely in the gaps between them. BDD collapses all three into a single
artifact — the `.feature` file — that is simultaneously a requirement, a test, and documentation.

Tools that generate browsable HTML reports from Cucumber output:
- **Cucumber HTML reports** (built-in, zero config)
- **Allure Framework** (rich, timeline, screenshots, JIRA integration)
- **`@cucumber/html-formatter`** — publishes a navigable feature file browser

**Practical rule**: If a feature file describes behavior that cannot currently be executed as a
passing test, it must be tagged `@wip` or removed. Stale feature files destroy trust in the
documentation and eliminate BDD's primary value proposition.

### Three Amigos Collaboration  [community]

The Three Amigos is a pre-development workshop involving three perspectives:

1. **Product/Business** (the "what"): Describes the goal and the business rule.
2. **Developer** (the "how"): Identifies technical constraints and edge cases.
3. **QA** (the "what could go wrong"): Surfaces missing scenarios, boundary conditions, and error paths.

The output is a set of agreed-upon Gherkin scenarios that all three parties have signed off on.
These scenarios become the acceptance criteria for the sprint ticket.

**Why it works**: Each role sees different blind spots. Product forgets error states. Developers
forget business rules. QA forgets security or performance concerns. The meeting forces all three to
confront the same concrete example before code exists.

**Example Mapping** (from Matt Wynne, Cucumber Ltd) as a structured warm-up:
1. Yellow card: Write the user story title.
2. Blue cards: Write one card per business rule.
3. Green cards: Write one concrete example per rule (becomes a Gherkin scenario).
4. Red cards: Write open questions that cannot be answered in the meeting.

If there are 15 green cards and 8 red cards, the story is not ready to develop.

**Example Mapping output format (YAML artifact from a Three Amigos session):**

```yaml
# example-map-checkout-discount.yaml
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
      - "Alice enters EXPIRED2023 → error: 'Code has expired'"
    open_questions:
      - "Q: Do we show when the code expired, or just that it is invalid?"

  - id: R3
    text: "Each code can only be used once per customer"
    examples:
      - "Alice uses SAVE10, then tries SAVE10 again → error: 'Code already used'"
    open_questions:
      - "Q: Does cancellation restore the code?"

blockers:
  - "Q (R2): Display expired date or generic invalid message — awaiting PO decision"
```

Each `example` maps directly to a `Scenario`; each `open_question` maps to a `@wip` scenario with
a comment until the question is answered.

**[community] Practical Three Amigos guidelines from teams running BDD at scale:**
- Keep sessions to 30–45 minutes per user story.
- Run as a standing meeting every Monday for the sprint's upcoming stories. Teams that run it ad-hoc
  skip it under pressure; a recurring calendar slot maintains discipline.
- Three Amigos is a *discovery* meeting, not a sign-off meeting. Gherkin gets refined after.

### playwright-bdd: JavaScript-First BDD with Playwright's Native Runner  [community]

`playwright-bdd` is an open-source library that bridges Cucumber's Gherkin layer with Playwright
Test's native runner. It compiles `.feature` files into spec files that Playwright runs directly —
enabling Playwright's HTML reporter, trace viewer, and `--shard` support without Cucumber-specific
CI plumbing.

**Why use `playwright-bdd` over `@cucumber/cucumber` + Playwright?**
- Playwright's native `--shard` syntax works out of the box
- Playwright Trace Viewer captures screenshots, network, and DOM snapshots on failure
- Fixtures replace the World object — no `this` binding issues
- `data-testid` selectors with Playwright's auto-wait reduce flakiness

**Setup:**

```bash
npm install --save-dev playwright-bdd @playwright/test
npx playwright install chromium
```

`playwright.config.js`:
```javascript
import { defineConfig, devices } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'features/**/*.feature',
  steps: 'src/steps/**/*.js',
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

`src/steps/checkout.steps.js` using **Playwright fixtures** instead of World:
```javascript
import { createBdd } from 'playwright-bdd';
import { expect } from '@playwright/test';

// createBdd returns typed Given/When/Then bound to Playwright fixtures
// No 'this' binding needed — page is injected as a named fixture
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

Then('I should see the error {string}', async ({ page }, errorMessage) => {
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
```

**[community] `playwright-bdd` tradeoff vs `@cucumber/cucumber`**: The Playwright-native approach
trades Cucumber's rich tag expression system (`@smoke and not @wip`) for Playwright's simpler
`--grep` regex. For large test suites with complex tag strategies, `@cucumber/cucumber` with its
profile system is more expressive. For teams already invested in Playwright who want the living
documentation layer without a second runner, `playwright-bdd` is lower friction.

### CI/CD Integration and Report Publishing

BDD suites that run in CI without publishing readable reports lose the "living documentation" value:
failures become log noise rather than traceable business-behavior regressions.

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
        if: always()
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
        shard: [1, 2, 3, 4]
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
- Always upload reports with `if: always()` — failure reports are more valuable than success reports.
- Use matrix sharding for regression suites; Cucumber.js `--parallel` for within-shard parallelism.
- Smoke gate on every PR; full regression nightly on main.
- Set `CI: true` — hooks can use this to take screenshots on failure and disable browser slowMo.

### Gherkin Linting with `gherkin-lint`  [community]

Feature files have no compiler to enforce structural rules. Without tooling, feature files drift:
some use imperative style, others mix business language with technical terms.

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
  "one-feature-per-file": true,
  "use-and": true,
  "no-restricted-tags": {
    "tags": ["@fixme", "@broken", "@skip"],
    "description": "Use @wip instead of {{tag}}"
  },
  "scenario-size": {
    "steps-length": { "Given": 3, "When": 1, "Then": 5 }
  },
  "max-scenarios-per-file": { "maxScenarios": 10 }
}
```

**Running gherkin-lint in CI:**
```yaml
- name: Lint feature files
  run: npx gherkin-lint 'features/**/*.feature'
```

**[community] `scenario-size: When: 1` as team discipline**: Enforcing a maximum of one `When` step
per scenario is controversial but highly effective. It forces teams to split "and then the user does X
and Y" scenarios into focused single-behavior test cases. The initial pushback is significant; the
payoff is a test suite where every failing scenario points to exactly one behavior that broke.

---


### 1. Imperative Style (UI-coupled steps)

**Problem**: Steps describe UI interactions rather than business intent.

```gherkin
# Anti-pattern: implementation-coupled
When I click the button with id "checkout-btn"
And I wait 2 seconds
And I select "Visa" from the dropdown "#card-type"
```

**Why it hurts**: Every UI change cascades into feature file edits. Scenarios become
change-amplifiers instead of change-detectors.

**Fix**: Write at the domain level. Delegate UI interaction to the step definition code.

### 2. Step Definition Bloat

**Problem**: Hundreds of highly specific, single-use step definitions that cannot be reused.

```javascript
// Anti-pattern: over-specific steps
Given('the user alice@example.com is logged in with password TestPass123! on staging', ...)
Given('the user bob@corp.com is logged in with password Admin!123 on staging', ...)
```

**Fix**: Use Cucumber expressions with parameters.

```javascript
// Good: parameterized — one step replaces dozens
Given('{string} is logged in', async function (email) { /* ... */ });
```

### 3. Arrow Functions Break the World Object

**Problem**: Using arrow functions in step definitions causes `this` to be `undefined`.

```javascript
// Anti-pattern — arrow function: this is undefined at runtime
Given('I am on the login page', async () => {
  await this.page.goto('/login'); // TypeError: Cannot read properties of undefined
});

// GOOD — regular function: this is the World object
Given('I am on the login page', async function () {
  await this.page.goto('/login');
});
```

**Why it hurts**: Arrow functions do not bind `this` — they inherit it from the enclosing
lexical scope, which is the module scope (undefined in strict ESM mode). This is the most
common beginner error in JavaScript BDD and produces cryptic runtime failures.

### 4. Scenario Interdependence

**Problem**: Scenarios that share state or must run in order.

```gherkin
# Anti-pattern: implicit ordering
Scenario: Create a product    # Must run first to populate DB
Scenario: Edit the product    # Depends on Scenario 1
Scenario: Delete the product  # Depends on Scenario 2
```

**Fix**: Each scenario is hermetic. Use `Background`, hooks, or API calls in `Before` hooks
to establish state independently.

### 5. Vague Then Steps

**Problem**: `Then` steps assert internal state or vague outcomes.

```gherkin
# Anti-pattern: not user-observable
Then the database should contain a record with status "confirmed"
Then the React state should have isLoading set to false
```

**Fix**: Assert what the user can observe: UI elements, API responses, emails, redirects.

### 6. Global Module-Level State in Step Definitions

**Problem**: Using `let` variables at the top of a step definition file to share state
across steps — instead of using the World object.

```javascript
// Anti-pattern — module-level shared state breaks parallel execution
let currentOrder;

When('I confirm the order', async function () {
  currentOrder = await this.page.getByTestId('order-id').textContent();
});

Then('my order should be confirmed', function () {
  // currentOrder might be from a DIFFERENT scenario running in parallel!
  assert.ok(currentOrder.startsWith('ORD-'));
});
```

**Fix**: Store all scenario-scoped state on `this` (the World object):

```javascript
When('I confirm the order', async function () {
  this.currentOrderId = await this.page.getByTestId('order-id').textContent();
});

Then('my order should be confirmed', function () {
  assert.ok(this.currentOrderId.startsWith('ORD-'));
});
```

---

## Real-World Gotchas  [community]

**[community] 1. Feature file ownership confusion**: Teams struggle with who owns `.feature` files.
Developers treat them as test code (and refactor without business review). Product managers treat them
as documentation (and let them drift from test reality). Establish a rule: no Gherkin change without
Three Amigos sign-off.

**[community] 2. Step definition duplication across feature files**: As the suite grows, different
team members write steps for the same behavior in slightly different phrasing, creating a graveyard
of near-duplicate step functions. Use `npx cucumber-js --dry-run --format usage` periodically to
audit dead steps.

**[community] 3. Slow suite syndrome**: BDD suites that run browser automation for every scenario
become the slowest part of CI. At 500+ scenarios, a 30-minute run is common. Mitigation: tag
scenarios (`@smoke`, `@regression`, `@slow`), run only `@smoke` on PRs, full suite nightly.

**[community] 4. The "BDD theater" failure mode**: Teams write Gherkin after the code is done,
effectively reverse-engineering documentation from implementation. This delivers zero of the
communication benefit of BDD. BDD must begin in the discovery phase, not after development.

**[community] 5. Cucumber is not BDD**: The tool is not the methodology. Teams can use Cucumber
without doing BDD (writing Gherkin in isolation, no collaboration). Teams can do BDD without Cucumber
(structured conversations, example mapping, then plain test frameworks). The collaboration is the
practice; Cucumber is optional tooling.

**[community] 6. Cucumber.js v10+ ESM migration breaks CommonJS setups**: Cucumber.js v10 dropped
CommonJS support. Projects using the traditional `requireModule: ['ts-node/register']` or CJS
`require` config will fail with `Error: require() of ES Module`. The fix is to switch to ESM config:

```javascript
// cucumber.js (ESM format — v10+)
export default {
  default: {
    import: ['src/steps/**/*.js', 'src/support/**/*.js'],
    // NOT 'require' — use 'import' for ESM
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
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

**[community] 7. Tag expression syntax changed in Cucumber.js v9+**: The old comma-based tag filter
(`--tags @smoke,@regression`) is silently ignored. Use boolean expressions:

```bash
# Old (v8 and below) — broken silently in v9+
npx cucumber-js --tags @smoke,@regression

# Correct (v9+) — explicit boolean expressions
npx cucumber-js --tags "@smoke or @regression"
npx cucumber-js --tags "@regression and not @wip"
```

**[community] 8. Parallel execution breaks shared state**: When running scenarios in parallel
(`--parallel 8`), any global state — a shared database row, a shared test user, a shared API key
counter — produces intermittent failures that are nearly impossible to debug. Each scenario must
provision its own data via API calls in `Before` hooks, using generated unique identifiers.

**[community] 9. Over-reliance on UI for state setup**: BDD scenarios that establish `Given`
preconditions by clicking through the UI to create data are 10x slower and 10x more fragile than
scenarios that use direct API calls. Only automate via browser what the scenario is actually
*testing*. Everything else goes through the API or direct DB seeding.

**[community] 10. @wip tag debt**: The `@wip` tag is meant to mark scenarios under active
development. Teams often forget to remove it, creating scenarios never executed in CI. Treat
`@wip` count as a health metric — fail CI if `@wip` exceeds 10% of total scenarios:

```javascript
// scripts/check-wip.js — run in CI
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const files = execSync('find features -name "*.feature"').toString().trim().split('\n');
let total = 0;
let wip = 0;
for (const file of files) {
  const content = readFileSync(file, 'utf8');
  total += (content.match(/^\s*(Scenario|Scenario Outline):/gm) || []).length;
  wip += (content.match(/@wip/g) || []).length;
}
const pct = Math.round((wip / total) * 100);
console.log(`@wip scenarios: ${wip}/${total} (${pct}%)`);
if (pct > 10) { console.error('FAIL: @wip count exceeds 10%'); process.exit(1); }
```

**[community] 11. BDD is the top of the pyramid, not the whole pyramid**: Teams that adopt BDD
sometimes mistake it for their entire test strategy, writing BDD scenarios for unit-level behavior.
A BDD scenario that checks whether a discount calculation is mathematically correct belongs in a
unit test — it runs 1000x faster, requires no browser setup, and gives a clearer failure message.
BDD scenarios should cover user-observable system behavior; everything below belongs in lower
pyramid layers.

**[community] 12. Use `--dry-run` before writing step definitions**: Run `npx cucumber-js --dry-run`
after writing new `.feature` files to see unmatched steps without executing any tests. This produces
a scaffold of step definition stubs:

```bash
npx cucumber-js --dry-run
# Output includes:
# You can implement missing steps with the snippets below:
# Given('I have a valid API authentication token', function () {
#   // Write code here that turns the phrase above into concrete actions
# });
```

**[community] 13. DocStrings vs DataTables — choosing the right multiline input format**: Use
`DocString` (triple-quoted block) for freeform or pre-structured text (JSON payloads, HTML). Use
`DataTable` for tabular data where each row is an entity. Mixing them — encoding JSON inside a
DataTable cell — makes step definitions parse twice and produces cryptic failure messages.

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

# BAD: JSON stuffed into a DataTable cell
Given my cart contains:
  | product data                                   |
  | {"name":"Laptop stand","qty":1,"price":49.99} |
```

**[community] 14. The `json` formatter was removed in Cucumber.js v11**: Teams relying on
`"json:reports/results.json"` for CI report merging will get `Error: Cannot find formatter json`.
Install `@cucumber/json-formatter` separately:

```bash
npm install --save-dev @cucumber/json-formatter
```

```javascript
// cucumber.js v11 — explicit json formatter
export default {
  default: {
    import: ['src/steps/**/*.js', 'src/support/**/*.js'],
    format: [
      'progress-bar',
      '@cucumber/json-formatter:reports/results.json',
      'html:reports/cucumber-report.html',
    ],
  },
};
```

---

## Tradeoffs & Alternatives

### When BDD Adds Value

| Context | BDD Benefit | Estimated ROI timeline |
|---------|-------------|----------------------|
| Complex business rules | Forces rule articulation before code | Pays back in sprint 2–3 |
| Multiple stakeholders | Single source of truth for all parties | Immediate, first Three Amigos |
| High-turnover teams | Feature files onboard new members fast | Pays back after 1st team change |
| Regulated industries | Human-readable audit evidence | Pays back at first audit |
| Long-lived products (2+ years) | Living documentation stays current | Compounds monthly |

### When BDD Adds Overhead

| Context | Why BDD Hurts |
|---------|--------------|
| Solo developer | Collaboration overhead with no collaboration |
| Prototype / MVP | Gherkin + step code doubles test authoring time |
| Pure UI testing | No semantic advantage over plain selectors |
| Team without buy-in | Becomes just a slow, verbose test framework |
| Microservice internals | Unit/integration tests serve better |

### Lighter Alternatives

| Approach | Setup Cost | Collaboration Benefit | Business Readability | Best For |
|----------|------------|----------------------|---------------------|---------|
| Full BDD (Gherkin + Cucumber) | High (2–3 sprints) | Maximum | Maximum | Cross-functional teams, regulated industries |
| Example Mapping only | Low (1 meeting) | High | Medium (ticket text) | Teams wanting discovery without tool overhead |
| Plain Playwright + page objects | Medium | None | Low (code) | Developer-led QA, no PO involvement in tests |
| Jest/Vitest + describe/it (BDD-style) | Very Low | Low | Medium (code) | Unit/integration BDD without Cucumber |
| pytest-bdd (Python) | Medium | Medium | Medium | Python teams wanting BDD without Behave's limitations |

**Plain Playwright + page objects**: 90% of the coverage, 50% of the setup overhead. A well-named
test like `test('guest user cannot access admin panel')` communicates intent without Gherkin:

```javascript
// tests/access-control.spec.js — plain Playwright without Gherkin
import { test, expect } from '@playwright/test';

test('guest user cannot access admin panel', async ({ page }) => {
  await page.goto('/admin');
  // Should be redirected to login
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();
});

test('registered user can view their order history', async ({ page }) => {
  // Use storageState or API setup to authenticate
  await page.goto('/account/orders');
  await expect(page.getByTestId('order-list')).toBeVisible();
});
```

**Jest/Vitest describe/it (BDD-style in JavaScript)**: For JavaScript projects, the
`describe`/`it`/`expect` vocabulary enables a BDD-style approach at unit and integration level
without any Gherkin toolchain:

```javascript
// src/features/discount/discount.spec.js — BDD-style with Jest/Vitest
import { describe, it, expect } from 'vitest'; // or from '@jest/globals'
import { applyDiscount } from './discount.service.js';
import { createTestCart } from '../__fixtures__/cart.factory.js';

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
      const expiredCode = {
        code: 'EXPIRED23',
        type: 'percent',
        value: 20,
        expiresAt: new Date('2023-01-01'),
      };
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

The nested `describe` blocks mirror Given/When/Then structure without Gherkin parsing overhead.

**Example Mapping (without Gherkin)**: Run the Three Amigos workshop, produce structured acceptance
criteria in ticket comments, then write regular tests. Captures BDD's collaboration benefit without
the tooling investment. This is the recommended starting point for teams evaluating BDD.

### Known Adoption Costs

- **2–3 sprints** to establish the Three Amigos cadence and step definition library from scratch.
- **Step definition maintenance**: step functions are production-quality code. They need code review,
  refactoring, and periodic audits. Budget ~10–15% of QA engineering time for BDD maintenance once
  a suite exceeds 200 scenarios.
- **CI pipeline overhead**: Cucumber.js v11 parallel execution requires browser provisioning per
  shard. At scale (500+ scenarios, 4 shards), CI time for BDD suite often exceeds 30 minutes unless
  aggressively split into smoke/regression tiers.
- **Tooling churn**: Cucumber.js had breaking changes at v9 (tag syntax), v10 (ESM), and v11
  (formatters, World generics). Budget for upgrade cycles when staying on supported versions.

---

## BDD Readiness Checklist

**Collaboration pre-conditions:**
- [ ] Product owner or BA can attend 30-minute Three Amigos sessions for each story
- [ ] QA is involved before development starts (not just in the test phase)
- [ ] Developers are willing to treat step definitions as production-quality code (code reviewed, no copy-paste)
- [ ] Team agrees on a ubiquitous language glossary

**Technical pre-conditions:**
- [ ] A working CI pipeline that can run `npx cucumber-js`
- [ ] At least one team member has written step definitions before, or budget for a 1-week learning spike
- [ ] Application has a test environment with seeded data or API-level setup support
- [ ] Page object layer (or API client layer) exists or is planned

**Ongoing health metrics (review monthly):**
- [ ] `@wip` scenarios below 10% of total
- [ ] Average scenario execution time below 5 seconds for non-browser scenarios
- [ ] Step definition count growth rate (>10% per sprint = bloat risk)
- [ ] Last Three Amigos session was this sprint

If fewer than 6 of these boxes are checked, start with **Example Mapping only** for one quarter.
Get the collaboration right before adding the automation layer.

---

## ISTQB CTFL 4.0 Terminology in BDD Context  [community]

| BDD informal term | ISTQB CTFL 4.0 canonical term | Why the distinction matters |
|---|---|---|
| "test scenario" | **test condition** | "Scenario" is a Gherkin keyword; "test condition" is the testable aspect; conflating them causes confusion in audit documents |
| "test script" | **test case** | A test case has preconditions + inputs + expected results + postconditions. A Gherkin scenario maps to exactly one test case |
| "test layer" | **test level** | BDD scenarios operate at system or acceptance test level |
| "test source" | **test basis** | Business rules and user stories that inform Gherkin scenarios |
| "bug" | **defect** | ISTQB distinguishes defect (in work product), failure (observable incorrect behavior), and error (human mistake) |
| "test set" | **test suite** | A set of related feature files constitutes a test suite |

---

## Ubiquitous Language: BDD as a Domain-Driven Design Artifact  [community]

BDD's Gherkin vocabulary is implicitly a **Ubiquitous Language** (UL) exercise from Domain-Driven
Design (DDD). Every noun and verb in a feature file is a claim about the shared language of the
bounded context. Teams that treat BDD and DDD as separate practices end up with Gherkin that uses
developer jargon in some scenarios and business language in others.

**Why this matters**: When the Gherkin says `the order is confirmed` but the codebase says
`OrderStatus.PROCESSED`, the team has two different languages for the same concept. Over 12 months,
these diverge further: feature file says `customer`, API says `user`, database says `account`.

**Ubiquitous Language Glossary — YAML artifact reviewed in Three Amigos sessions:**

```yaml
# docs/ubiquitous-language.yaml
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
```

**Enforcing UL consistency in step definitions (JavaScript):**

```javascript
// src/support/ubiquitous-language-guard.js
// Run in a Before hook — warns when Gherkin step text contains forbidden synonyms
import { Before } from '@cucumber/cucumber';

// Key: canonical term; Value: forbidden synonyms
const SYNONYMS = {
  Customer: ['user', 'account', 'buyer', 'shopper'],
  Cart:     ['basket', 'bag', 'wishlist'],
  Order:    ['purchase', 'transaction', 'booking'],
};

Before(function (scenario) {
  const stepTexts = scenario.pickle.steps.map((s) => s.text.toLowerCase());
  for (const [canonicalTerm, forbidden] of Object.entries(SYNONYMS)) {
    for (const synonym of forbidden) {
      const violations = stepTexts.filter((text) => text.includes(synonym));
      if (violations.length > 0) {
        console.warn(
          `[UL] Scenario "${scenario.pickle.name}" uses "${synonym}" — ` +
            `prefer canonical term "${canonicalTerm}". ` +
            `Steps: ${violations.join('; ')}`
        );
      }
    }
  }
});
```

**[community] Production impact**: Teams that maintain a UL glossary and enforce it in Three Amigos
sessions report 40–60% fewer "wait, what do you mean by X?" clarification rounds in sprint planning.
The glossary becomes the most-referenced onboarding document for new hires.

**[community] BDD bounded context alignment**: Each `features/` subdirectory should correspond to
one DDD bounded context (`features/checkout/`, `features/inventory/`, `features/identity/`). Step
definitions scoped to a context prevent leakage. When a scenario needs two bounded contexts, it is
a signal that it is testing integration — and belongs at the contract testing layer.

---

## Step Health: Detecting Unused and Duplicate Step Definitions  [community]

As a BDD suite grows, unused and near-duplicate step definitions accumulate silently. Unlike dead
TypeScript code (caught by `noUnusedLocals`), unused step definitions are strings — no compiler
can detect them.

**Unused step detection with Cucumber's built-in `--format usage`:**

```bash
# Show all steps with usage count — steps with 0 uses are candidates for removal
npx cucumber-js --dry-run --format usage

# Output format:
# Pattern                                        | Uses | Location
# ------------------------------------------------|------|------------------
# I am logged in as a registered customer         |   12 | steps/auth.js:5
# I am on the checkout page                       |    1 | steps/checkout.js:23
# I fill in the field {string} with {string}      |    0 | steps/forms.js:47  ← UNUSED
```

**Quarterly step audit workflow (JavaScript):**

```javascript
// scripts/step-audit.js — run weekly to track suite health
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

function auditScenarios(featuresDir) {
  const files = execSync(`find ${featuresDir} -name "*.feature"`)
    .toString()
    .trim()
    .split('\n')
    .filter(Boolean);

  let totalScenarios = 0;
  let wipCount = 0;
  const filesOver10 = [];

  for (const file of files) {
    const content = readFileSync(file, 'utf8');
    const scenarios = (content.match(/^\s*(Scenario|Scenario Outline):/gm) || []).length;
    const wip = (content.match(/@wip/g) || []).length;
    totalScenarios += scenarios;
    wipCount += wip;
    if (scenarios > 10) {
      filesOver10.push(`${file} (${scenarios} scenarios)`);
    }
  }

  return {
    totalScenarios,
    wip: wipCount,
    wipPercentage: Math.round((wipCount / Math.max(totalScenarios, 1)) * 100),
    averagePerFile: Math.round(totalScenarios / Math.max(files.length, 1)),
    filesOver10,
  };
}

const result = auditScenarios('features/');
console.table(result);
if (result.wipPercentage > 10) {
  console.error('FAIL: @wip count exceeds 10% — resolve or remove stale WIP scenarios');
  process.exit(1);
}
```

**Scenario count health metrics:**

| Metric | Healthy range | Warning signal | Action |
|--------|--------------|----------------|--------|
| Total scenarios | < 500 | 500–1000 | Audit for duplicates and imperative scenarios |
| Scenarios per feature file | 3–10 | > 15 | Feature needs to be split |
| `@wip` scenarios | < 5% of total | > 10% | Sprint review: resolve or remove |
| Unused step definitions | < 5% | > 20% | Quarterly step audit |
| Average scenario execution time | < 10s | > 30s | Move business logic to API-level BDD |
| Three Amigos sessions per sprint | ≥ 1 per story | < 1/sprint | BDD without collaboration = theater |

**[community] The 500-scenario warning**: Teams with 500+ BDD scenarios typically report one or more
of: 45+ minute nightly runs, developers disabling CI to merge quickly, business users who stopped
reading the reports 6 months ago. The root cause is almost always that the suite grew beyond
acceptance tests into unit-test territory (scenarios checking individual business rules that belong
in unit tests) or imperative scenarios that test UI mechanics rather than business behavior.

---

## BDD and Contract Testing: Defining the Boundary  [community]

BDD scenarios describe *user-observable behavior* end-to-end. Contract tests describe *service
interface obligations* between producers and consumers. The two methodologies are complementary
but should not overlap — mixing them creates scenarios that are both slow and brittle.

**The rule**: BDD scenarios should treat downstream service calls as opaque. They should not assert
on internal service behavior. Contract tests (Pact/CDC) own that layer.

```gherkin
# CORRECT BDD — treats payment service as opaque
Scenario: Order total is charged on checkout
  Given I am a registered customer with items in my cart
  When I complete the checkout process with a valid card
  Then my order should be confirmed
  And I should receive an order confirmation email
  # BDD does NOT assert: "a POST was sent to /api/payments/charge"
  # That is a contract test concern

# INCORRECT — BDD leaking into contract territory
Scenario: Payment service receives correct charge amount
  Given I am a registered customer with cart total $109.97
  When I complete checkout
  Then the payment service should receive a POST to /api/payments/charge
  And the request body should contain amount 10997 in cents
  # This belongs in a Pact consumer test, not a feature file
```

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

**[community] Lesson from production**: Teams that use BDD to test microservice APIs end-to-end
find that every deployment of *any* downstream service can break *all* BDD scenarios — not because
behavior changed, but because a response field name changed or a new required header was added.
Once Pact is in place, BDD scenarios become stable because they test user behavior, not wire format.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Cucumber documentation | Official docs | https://cucumber.io/docs/bdd/ | Canonical BDD and Gherkin reference |
| Gherkin reference | Official docs | https://cucumber.io/docs/gherkin/reference/ | Full keyword specification |
| @cucumber/cucumber npm | Package | https://www.npmjs.com/package/@cucumber/cucumber | Official JS package (v11+) |
| playwright-bdd | Library | https://github.com/vitalets/playwright-bdd | Playwright-native BDD runner for JS/TS |
| Example Mapping | Blog post | https://cucumber.io/blog/bdd/example-mapping-introduction/ | Pre-BDD discovery technique (Matt Wynne) |
| eslint-plugin-cucumber | Library | https://github.com/nicholasgasior/eslint-plugin-cucumber | Step definition linting rules |
| multiple-cucumber-html-reporter | Library | https://github.com/WasiqB/multiple-cucumber-html-reporter | Merge sharded JSON reports |
| Allure Framework | Reporting | https://allurereport.org/ | Rich reporting for Cucumber suites |
| Pact documentation | Official docs | https://docs.pact.io/ | Consumer-driven contract testing for service boundaries |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Standardized testing terminology reference |
