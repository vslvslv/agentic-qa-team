# BDD — QA Methodology Guide
<!-- lang: TypeScript | topic: bdd | iteration: 10 | score: 100/100 | date: 2026-05-03 | sources: training-knowledge -->
<!-- WebFetch and WebSearch unavailable; synthesized from training knowledge + TypeScript patterns reference -->

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
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/) — full keyword specification
- [@cucumber/cucumber npm package](https://www.npmjs.com/package/@cucumber/cucumber) — official JS/TS package (v11+)
- [playwright-bdd](https://github.com/vitalets/playwright-bdd) — Playwright-native BDD runner for TypeScript
- [Example Mapping (Matt Wynne)](https://cucumber.io/blog/bdd/example-mapping-introduction/) — pre-BDD discovery technique
- [eslint-plugin-cucumber](https://github.com/nicholasgasior/eslint-plugin-cucumber) — step definition linting rules
- [multiple-cucumber-html-reporter](https://github.com/WasiqB/multiple-cucumber-html-reporter) — merge sharded JSON reports
- [SpecFlow documentation](https://docs.specflow.org/) — C# BDD framework
- [Behave documentation](https://behave.readthedocs.io/) — Python BDD framework
- [pytest-bdd documentation](https://pytest-bdd.readthedocs.io/) — Python BDD with pytest integration (recommended for pytest teams)
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
