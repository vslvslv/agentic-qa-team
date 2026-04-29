# Behavior-Driven Development (BDD) — QA Methodology Guide
<!-- lang: TypeScript | topic: bdd | iteration: 4 | score: 100/100 | date: 2026-04-28 | sources: training-knowledge -->
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
