# Cypress — Web E2E Patterns

> Reference: [cypress-patterns.md](../references/cypress-patterns.md)

## Auth Setup

Use `cy.session()` (Cypress 10+) for session caching. Put the login command in
`cypress/support/commands.ts` so every spec can call `cy.login()`.

```typescript
// cypress/support/commands.ts
Cypress.Commands.add("login", (email?: string, password?: string) => {
  cy.session(
    [email ?? Cypress.env("E2E_USER_EMAIL"), password ?? Cypress.env("E2E_USER_PASSWORD")],
    () => {
      cy.visit("/login");
      cy.findByLabelText(/email/i).type(email ?? Cypress.env("E2E_USER_EMAIL"));
      cy.findByLabelText(/password/i).type(password ?? Cypress.env("E2E_USER_PASSWORD"));
      cy.findByRole("button", { name: /sign in|log in/i }).click();
      cy.url().should("not.include", "/login");
    },
    { cacheAcrossSpecs: true }
  );
});
```

```typescript
// cypress.config.ts (key sections)
import { defineConfig } from "cypress";
export default defineConfig({
  e2e: {
    baseUrl: process.env.WEB_URL ?? "http://localhost:3000",
    specPattern: "cypress/e2e/**/*.cy.{ts,js}",
    supportFile: "cypress/support/e2e.ts",
  },
});
```

## Test Structure

Test files live in `cypress/e2e/`. Describe/it are globals — no import needed for them.
Import Testing Library commands if `@testing-library/cypress` is installed.

```typescript
// cypress/e2e/dashboard.cy.ts
describe("Dashboard", () => {
  beforeEach(() => {
    cy.login();
    cy.visit("/dashboard");
  });

  it("loads without error", () => {
    cy.findByRole("main").should("be.visible");
    cy.findByRole("heading", { level: 1 }).should("exist");
  });

  it("shows error banner when API fails", () => {
    cy.intercept("GET", "/api/metrics", { statusCode: 500, body: { error: "Server error" } });
    cy.reload();
    cy.findByRole("alert").should("be.visible");
  });
});
```

## Selector Strategy (ranked)

1. `cy.findByRole` / `cy.findByLabelText` — Testing Library (if installed)
2. `[data-cy="..."]` — Cypress-specific test hook attribute
3. `[data-testid="..."]` — generic test ID attribute
4. `cy.contains("text")` — visible text content
5. **Never** CSS class selectors (`.btn-primary`), position-based (`:nth-child`)

Add `data-cy` attributes to app components for reliable selection:
```tsx
<button data-cy="submit-btn">Submit</button>
```

## API Mocking / Interception

```typescript
// Mock a response
cy.intercept("GET", "/api/users", { fixture: "users.json" }).as("getUsers");
cy.wait("@getUsers");

// Spy without mocking
cy.intercept("POST", "/api/orders").as("createOrder");
cy.findByRole("button", { name: /place order/i }).click();
cy.wait("@createOrder").its("response.statusCode").should("eq", 201);
```

## CI Notes

```bash
# Install Cypress binary (cache node_modules to skip)
npx cypress install

# Headless run
npx cypress run --headless --browser chrome

# Exit code: 0 = all passed, 1 = test failure
# Artifacts: cypress/screenshots/ (on failure) and cypress/videos/
```

- Set `CYPRESS_baseUrl` env var to override the configured `baseUrl`
- Use `--reporter json` + `--reporter-options output=cypress-results.json` for CI artifacts

## Execute Block

```bash
export CYPRESS_E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export CYPRESS_E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
npx cypress run --headless --browser chrome \
  --reporter json --reporter-options "output=$_TMP/qa-web-cypress-results.json" \
  2>&1 | tee "$_TMP/qa-web-cypress-output.txt"
echo "CYPRESS_EXIT_CODE: $?"
```
