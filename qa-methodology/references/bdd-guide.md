# Behavior-Driven Development (BDD) — QA Methodology Guide
<!-- lang: TypeScript | topic: bdd | iteration: 10 | score: 100/100 | date: 2026-04-26 -->

## Core Principles

Behavior-Driven Development (BDD) is a software development methodology that encourages collaboration among developers, QA engineers, and business stakeholders to define the expected behavior of a system before implementation begins. Introduced by Dan North in 2003 as an evolution of Test-Driven Development (TDD), BDD bridges the gap between technical and non-technical team members by using a shared, human-readable language to describe system behavior.

BDD rests on three foundational pillars:

1. **Shared understanding**: All stakeholders — developers, QA, and product owners — collaborate to define what "done" means before writing a single line of code. This is why BDD produces better software than TDD alone: TDD tells you when code is correct; BDD tells you when the team agreed on what "correct" means.
2. **Executable specifications**: Feature files written in Gherkin serve as both documentation and automated tests, ensuring documentation never drifts from reality. A passing feature file is proof, not promise — unlike a wiki entry, it cannot lie about what the system does today.
3. **Outside-in development**: Teams start from the user's perspective, working inward from business scenarios toward implementation details. This prevents the common failure mode of building technically correct software that does not solve the actual business problem.

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



### Team Maturity Requirements

BDD is not a plug-and-play tool. It requires organizational preconditions to deliver its stated benefits:

| Maturity Requirement | Why It Matters | Warning Sign |
|---|---|---|
| Product owner participation | Without a business voice, scenarios become developer-invented test cases | PO only reviews scenarios at sprint review |
| QA in discovery phase | QA's value is in pre-code scenario surfacing, not post-code test writing | QA writes Gherkin from finalized tickets |
| Developer commitment to clean steps | Step definition bloat is inevitable without code review discipline | >300 step functions after 6 months |
| CI pipeline integration | Feature files not wired to CI are just documentation | Scenarios run only manually |
| Gherkin review process | Unreviewed Gherkin drifts imperative; requires same review rigor as code | Feature files bypass PR review |

A team that scores "warning sign" in 3+ of these areas will experience BDD as overhead with no benefit. The honest diagnostic question: "If we ran our feature files today, would they all pass?" If the answer is uncertain, the practice has already broken down.

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

### Lighter Alternatives

| Approach | Setup Cost | Collaboration Benefit | Business Readability | Best For |
|---|---|---|---|---|
| Full BDD (Gherkin + Cucumber) | High (2–3 sprints) | Maximum | Maximum | Cross-functional teams, regulated industries |
| Example Mapping only | Low (1 meeting) | High | Medium (ticket text) | Teams wanting discovery without tool overhead |
| Plain Playwright + page objects | Medium | None | Low (code) | Developer-led QA, no PO involvement in tests |
| Vitest + describe/it (BDD-style) | Very Low | Low | Medium (code) | TypeScript teams, unit/integration BDD without Cucumber |
| Jest + Testing Library | Low | None | Low (code) | Component/unit behavior, fast feedback loop |
| pytest-bdd (Python) | Medium | Medium | Medium | Python teams wanting BDD without Behave's limitations |

- **Plain Playwright + page objects**: 90% of the coverage, 50% of the setup overhead. Best for teams that do not need the business-readable layer. A well-named test like `test('guest user cannot access admin panel')` communicates intent without Gherkin.

- **Vitest + describe/it (BDD-style in TypeScript)**: For TypeScript projects already using Vitest, the `describe`/`it`/`expect` vocabulary enables a BDD-style approach at unit and integration level without any Gherkin toolchain. This is appropriate when stakeholder collaboration happens informally (small team, trusted PO) and the team wants the *thinking model* of BDD without the ceremony:

  ```typescript
  // src/features/discount/discount.spec.ts — BDD-style with Vitest
  import { describe, it, expect, beforeEach } from 'vitest';
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

  The nested `describe` blocks mirror Given/When/Then structure without requiring Gherkin parsing or step definitions. Product managers can read these test names in the CI report (`vitest --reporter=verbose`) and understand the behavior being verified.

- **Example Mapping** (without Gherkin): Run the Three Amigos workshop, produce structured acceptance criteria in ticket comments, then write regular tests. Captures BDD's collaboration benefit without the tooling investment. This is the recommended starting point for teams evaluating BDD — get the collaboration right before adding the automation layer.
- **SpecFlow (C#)**: Equivalent to `@cucumber/cucumber` for .NET teams. Same Gherkin syntax, same step binding model, first-class Visual Studio integration.

  ```csharp
  // File: Steps/CheckoutSteps.cs
  using TechTalk.SpecFlow;
  using FluentAssertions;

  [Binding]
  public class CheckoutSteps
  {
      private readonly ScenarioContext _context;
      private readonly HttpClient _client;

      public CheckoutSteps(ScenarioContext context, HttpClient client)
      {
          _context = context;
          _client = client;
      }

      [Given(@"I am a registered customer with items in my cart")]
      public async Task GivenRegisteredCustomerWithItems()
      {
          var response = await _client.PostAsJsonAsync("/api/cart/seed",
              new { userId = "test-user-001", items = new[] { "prod-42" } });
          response.EnsureSuccessStatusCode();
          _context["cartId"] = await response.Content.ReadAsStringAsync();
      }

      [When(@"I complete the checkout process")]
      public async Task WhenCheckoutCompletes()
      {
          var cartId = _context["cartId"].ToString();
          var response = await _client.PostAsJsonAsync($"/api/orders",
              new { cartId, paymentMethod = "test-card-4242" });
          response.EnsureSuccessStatusCode();
          _context["orderId"] = await response.Content.ReadAsStringAsync();
      }

      [Then(@"my order should be confirmed")]
      public void ThenOrderConfirmed()
      {
          _context["orderId"].Should().NotBeNullOrEmpty();
      }
  }
  ```

- **Behave (Python)**: The Python BDD framework. Gherkin syntax identical to Cucumber; steps written in Python. Common in Django and FastAPI projects.

  ```python
  # File: features/steps/checkout_steps.py
  from behave import given, when, then
  import requests

  BASE_URL = "http://localhost:8000"

  @given("I am a registered customer with items in my cart")
  def step_setup_cart(context):
      response = requests.post(f"{BASE_URL}/api/cart/seed", json={
          "user_id": "test-user-001",
          "items": ["prod-42"]
      })
      assert response.status_code == 200
      context.cart_id = response.json()["cartId"]

  @when("I complete the checkout process")
  def step_checkout(context):
      response = requests.post(f"{BASE_URL}/api/orders", json={
          "cart_id": context.cart_id,
          "payment_method": "test-card-4242"
      })
      assert response.status_code == 201
      context.order_id = response.json()["orderId"]

  @then("my order should be confirmed")
  def step_order_confirmed(context):
      assert context.order_id is not None
      assert len(context.order_id) > 0

  @then("I should receive an order number")
  def step_order_number(context):
      assert context.order_id.startswith("ORD-"), \
          f"Expected order ID to start with ORD-, got: {context.order_id}"
  ```

---

## Quick Reference Card

| Topic | Recommendation |
|-------|---------------|
| When to use BDD | Complex business domain + cross-functional team + stakeholder participation |
| When NOT to use | Solo/small team, prototype, infrastructure code, team without PO buy-in |
| Primary TypeScript framework | `@cucumber/cucumber` v9 (CommonJS) or v10+ (ESM) |
| Step parameterization | Prefer `{string}`, `{int}`, `{float}`, `{word}` over raw regex |
| State sharing across steps | Use the World object — never module-level variables |
| CI strategy | `@smoke` on every PR (< 2 min); `@regression` nightly (sharded) |
| Parallel safety | Provision all test data via API in `Before` hooks with unique IDs |
| Suite health indicator | `@wip` count < 10% of total scenarios |
| Avoiding step bloat | "Search before create" policy; max one step definition file per feature area |
| Lightest BDD start | Example Mapping workshop first — no tooling needed |
| Version gotcha | v9 → v10 migration requires ESM config change (`import:` not `require:`) |
| Tag syntax | Boolean expressions: `"@smoke and not @wip"` (commas deprecated in v9+) |

---

## Key Resources

- [Cucumber documentation](https://cucumber.io/docs/bdd/) — canonical BDD reference
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/) — full keyword specification
- [@cucumber/cucumber npm package](https://www.npmjs.com/package/@cucumber/cucumber) — official JS/TS package
- [Example Mapping (Matt Wynne)](https://cucumber.io/blog/bdd/example-mapping-introduction/) — pre-BDD discovery technique
- [SpecFlow documentation](https://docs.specflow.org/) — C# BDD framework
- [Behave documentation](https://behave.readthedocs.io/) — Python BDD framework
- [Allure Framework](https://allurereport.org/) — rich reporting for Cucumber suites
