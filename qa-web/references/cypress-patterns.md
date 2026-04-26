# Cypress Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official + community | iteration: 1 | score: 88/100 | date: 2026-04-26 -->

## Core Principles

1. **Commands are asynchronous but chainable** — Cypress queues commands; never use `async/await` on cy commands. The `.then()` callback is for extracting values, not for async control flow.
2. **Retry-ability by default** — Most `cy.get()` and assertion calls retry until timeout. Design tests to rely on this rather than adding arbitrary `cy.wait(ms)` calls.
3. **Tests run inside the browser** — Cypress has full DOM access and can read/write app state directly, enabling fast auth setups via `cy.session()` or direct `localStorage` manipulation.
4. **Single origin per test by default** — Use `cy.origin()` for multi-domain flows (OAuth redirects). Do not mix origins without it.
5. **Fail fast, debug locally** — Cypress's time-travel debugger and `.debug()` / `.pause()` are first-class tools; tests should produce enough log output to diagnose failures without re-running.

---

## Recommended Patterns

### 1. Authentication with cy.session()

`cy.session()` caches and restores browser session state across tests, eliminating redundant login round-trips.

```typescript
// cypress/support/auth.ts
export function loginAsUser(email: string, password: string): void {
  cy.session(
    [email, password],                        // cache key
    () => {
      cy.visit('/login');
      cy.get('[data-cy="email"]').type(email);
      cy.get('[data-cy="password"]').type(password);
      cy.get('[data-cy="submit"]').click();
      cy.url().should('include', '/dashboard'); // validate session was established
    },
    {
      validate() {
        // called before restoring cache — re-login if token expired
        cy.request({ url: '/api/me', failOnStatusCode: false })
          .its('status')
          .should('eq', 200);
      },
      cacheAcrossSpecs: true,  // reuse across all spec files in the run
    }
  );
}

// In a spec:
beforeEach(() => loginAsUser('alice@example.com', 'secret'));
```

### 2. Network Mocking with cy.intercept()

Intercept and stub HTTP traffic to isolate the UI from backend flakiness.

```typescript
describe('Product listing', () => {
  it('renders stubbed products', () => {
    cy.intercept('GET', '/api/products*', { fixture: 'products.json' }).as('getProducts');
    cy.visit('/products');
    cy.wait('@getProducts');
    cy.get('[data-cy="product-card"]').should('have.length', 3);
  });

  it('shows error banner on 500', () => {
    cy.intercept('GET', '/api/products*', {
      statusCode: 500,
      body: { message: 'Internal Server Error' },
    }).as('getProductsFail');
    cy.visit('/products');
    cy.wait('@getProductsFail');
    cy.get('[data-cy="error-banner"]').should('be.visible');
  });
});
```

### 3. data-cy Selectors

Always use `data-cy` (or `data-testid`) attributes. CSS classes and element hierarchy break when styling changes.

```typescript
// ✅ Stable
cy.get('[data-cy="submit-button"]').click();

// ❌ Brittle — couples test to markup structure
cy.get('.form > div:nth-child(2) > button.btn-primary').click();
```

Add a custom Cypress type declaration to autocomplete selector names:

```typescript
// cypress/support/selectors.ts
export const sel = (id: string) => `[data-cy="${id}"]`;

// Usage:
cy.get(sel('submit-button')).click();
```

### 4. API Testing with cy.request()

Use `cy.request()` for API assertions and fast test-data seeding without going through the UI.

```typescript
// Seed a user directly via API before UI test
beforeEach(() => {
  cy.request({
    method: 'POST',
    url: '/api/users',
    headers: { Authorization: `Bearer ${Cypress.env('API_TOKEN')}` },
    body: { name: 'Test User', email: 'test@example.com' },
  }).then((response) => {
    expect(response.status).to.eq(201);
    // store created ID for cleanup
    Cypress.env('createdUserId', response.body.id);
  });
});

afterEach(() => {
  const id = Cypress.env('createdUserId');
  if (id) cy.request('DELETE', `/api/users/${id}`);
});
```

### 5. Custom Commands

Encapsulate repeated interactions in `cypress/support/commands.ts`. Keep commands single-responsibility.

```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      loginViaApi(email: string, password: string): Chainable<void>;
      selectDropdown(selector: string, option: string): Chainable<void>;
    }
  }
}

Cypress.Commands.add('loginViaApi', (email, password) => {
  cy.request('POST', '/api/auth/login', { email, password })
    .its('body.token')
    .then((token) => {
      window.localStorage.setItem('auth_token', token);
    });
});

Cypress.Commands.add('selectDropdown', (selector, option) => {
  cy.get(selector).click();
  cy.get(`[data-cy="dropdown-option"]`).contains(option).click();
  cy.get(selector).should('contain', option);
});
```

### 6. Fixtures with cy.fixture()

Keep test data in `cypress/fixtures/`. Load inline or use the `fixture:` shorthand in `cy.intercept()`.

```typescript
// cypress/fixtures/user.json
// { "id": 1, "name": "Alice", "role": "admin" }

it('displays user profile', () => {
  cy.fixture('user.json').then((user) => {
    cy.intercept('GET', '/api/me', user).as('getMe');
    cy.visit('/profile');
    cy.wait('@getMe');
    cy.get('[data-cy="user-name"]').should('have.text', user.name);
    cy.get('[data-cy="user-role"]').should('have.text', user.role);
  });
});
```

### 7. Retry-ability — Write Assertions That Wait

Cypress retries `.should()` assertions automatically. Write the assertion against the end state, not a transitional state.

```typescript
// ✅ Cypress retries until button text matches
cy.get('[data-cy="save-btn"]').should('have.text', 'Saved');

// ❌ Fragile — snapshot taken before async state update completes
cy.get('[data-cy="save-btn"]').then(($btn) => {
  expect($btn.text()).to.eq('Saved'); // no retry, will flake
});

// For sequences, chain assertions:
cy.get('[data-cy="toast"]')
  .should('be.visible')
  .and('contain', 'Successfully saved');
```

### 8. Component Testing (brief)

Cypress Component Testing mounts components in isolation without a full browser page load.

```typescript
// counter.cy.tsx
import { Counter } from '../../src/components/Counter';

describe('Counter component', () => {
  it('increments on click', () => {
    cy.mount(<Counter initialCount={0} />);
    cy.get('[data-cy="count"]').should('have.text', '0');
    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '1');
  });
});
```

Configure in `cypress.config.ts`:

```typescript
import { defineConfig } from 'cypress';
export default defineConfig({
  component: {
    devServer: { framework: 'react', bundler: 'vite' },
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

---

## Selector Strategy (Priority Order)

| Priority | Selector type | Example |
|----------|--------------|---------|
| 1 (best) | `data-cy` attribute | `cy.get('[data-cy="login-btn"]')` |
| 2 | `data-testid` attribute | `cy.get('[data-testid="modal"]')` |
| 3 | ARIA role | `cy.get('[role="dialog"]')` |
| 4 | Label / visible text | `cy.contains('Submit')` |
| 5 | Input `name` or `id` | `cy.get('#username')` |
| 6 (avoid) | CSS class / nth-child | `cy.get('.btn-primary')` |

---

## TypeScript Configuration

```jsonc
// tsconfig.json (cypress-specific override in cypress/tsconfig.json)
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["es5", "dom"],
    "types": ["cypress", "node"]
  },
  "include": ["**/*.ts", "**/*.tsx"]
}
```

Store secrets in `cypress.env.json` (gitignored) or pass via `--env`:

```bash
npx cypress run --env API_TOKEN=xyz,BASE_URL=https://staging.example.com
```

Access in tests with `Cypress.env('API_TOKEN')`.

---

## Real-World Gotchas [community]

1. **`cy.wait(ms)` as a crutch** [community] — Hard-coded waits hide timing problems rather than fixing them; they slow the suite and still flake on slow CI machines. Use `cy.wait('@alias')` or a `.should()` assertion that retries instead.

2. **Storing subject between commands with `let`** [community] — Assigning `let x; cy.get(...).then(v => x = v); use(x)` does not work because Cypress commands are queued, not synchronous. Wrap the usage inside the `.then()` callback or use aliases (`cy.as('myVar')`).

3. **`cy.intercept()` registered after `cy.visit()`** [community] — If the network request fires before the intercept is registered, stubbing silently does nothing. Always register `cy.intercept()` before `cy.visit()`.

4. **`cy.session()` cache serving a stale token** [community] — Without a `validate` callback, a cached session with an expired JWT will pass the restore step but fail mid-test. Always add a `validate()` that hits an authenticated endpoint.

5. **Shared mutable state via `Cypress.env()`** [community] — Setting values in `beforeEach` with `Cypress.env()` persists across specs when `cacheAcrossSpecs` is active or the runner reuses the process. Use unique keys per test or clean up in `afterEach`.

6. **Cross-origin navigation without `cy.origin()`** [community] — Visiting a second domain (e.g., an OAuth provider) without `cy.origin()` throws a cross-origin error. Wrap the redirected-domain commands inside `cy.origin('https://auth.provider.com', () => { ... })`.

7. **Asserting on detached DOM nodes** [community] — After a React re-render, a previously queried element may be detached. Re-query inside `.should()` or use `.find()` from a stable parent rather than caching the element reference.

---

## CI Considerations

- **Run headless** — `npx cypress run` defaults to headless Electron. For Chrome: `--browser chrome --headless`.
- **Parallelise with Cypress Cloud** — Use `--parallel --record --ci-build-id $CI_BUILD_ID` to split specs across machines. Requires a Cypress Cloud project key in `CYPRESS_RECORD_KEY`.
- **Artifact retention** — Set `screenshotsFolder` and `videosFolder` in `cypress.config.ts`; upload to CI artifact store on failure only to save storage.
- **`baseUrl` via env** — Never hardcode URLs. Set `baseUrl` in `cypress.config.ts` and override with `CYPRESS_BASE_URL=https://staging.example.com` in CI.
- **Docker image** — Use the official `cypress/included` image; it bundles all browser deps and avoids missing shared-library issues on stripped CI images.
- **Retry flaky tests** — Add `"retries": { "runMode": 2, "openMode": 0 }` in `cypress.config.ts` to automatically re-attempt failed tests in CI without masking real failures locally.

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx}',
    screenshotOnRunFailure: true,
    video: false,                   // enable in CI only
    retries: { runMode: 2, openMode: 0 },
    defaultCommandTimeout: 8000,
    requestTimeout: 10000,
    setupNodeEvents(on, config) {
      // register plugins here
      return config;
    },
  },
});
```

---

## Key APIs

| Method | Purpose | When to use |
|--------|---------|-------------|
| `cy.visit(url)` | Navigate to a URL | Start of each test flow |
| `cy.get(selector)` | Query DOM element | Primary element selector |
| `cy.contains(text)` | Find element by text content | Links, buttons without data-cy |
| `cy.intercept(method, url, response)` | Stub or spy on network requests | Isolate UI from backend |
| `cy.wait('@alias')` | Wait for an intercepted request | After intercept before assertion |
| `cy.request(options)` | Make HTTP request directly | API seeding, auth, assertions |
| `cy.session(id, setup, options)` | Cache and restore browser session | Login in `beforeEach` |
| `cy.fixture(filename)` | Load JSON test data | Stubs, assertions |
| `cy.stub(obj, method)` | Stub a JS function | Mock browser APIs or app functions |
| `cy.clock() / cy.tick(ms)` | Control JS timers | Test debounced inputs, timeouts |
| `cy.viewport(w, h)` | Set browser viewport | Responsive layout tests |
| `cy.screenshot()` | Capture screenshot | Debug; called automatically on failure |
| `.should(assertion)` | Retrying assertion | All state assertions |
| `.then(cb)` | Access command subject value | Extract values for `.request()`, etc. |
| `.as(alias)` | Name a chain for later reference | Share subjects between hooks/tests |
| `cy.origin(url, fn)` | Run commands on a different origin | OAuth / SSO flows |
| `cy.mount(component)` | Mount a component in isolation | Component testing only |
