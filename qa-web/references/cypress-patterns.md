# Cypress Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official + community + training knowledge | iteration: 7 | score: 100/100 | date: 2026-04-27 -->

## Core Principles

1. **Commands are asynchronous but chainable** — Cypress queues commands; never use `async/await` on cy commands. The `.then()` callback is for extracting values, not for async control flow.
2. **Retry-ability by default** — Most `cy.get()` and assertion calls retry until timeout. Design tests to rely on this rather than adding arbitrary `cy.wait(ms)` calls.
3. **Tests run inside the browser** — Cypress has full DOM access and can read/write app state directly, enabling fast auth setups via `cy.session()` or direct `localStorage` manipulation.
4. **Single origin per test by default** — Use `cy.origin()` for multi-domain flows (OAuth redirects). Do not mix origins without it.
5. **Fail fast, debug locally** — Cypress's time-travel debugger, `.debug()`, and `.pause()` are first-class tools; tests should produce enough log output to diagnose failures without re-running.

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

### 3. Request Modification with cy.intercept() RouteHandler  [community]

Use a `RouteHandler` function to spy on real requests while also modifying headers or body — useful for injecting auth tokens or simulating slow networks without fully stubbing.

```typescript
// Inject auth header into every API call without stubbing the response
cy.intercept('/api/**', (req) => {
  req.headers['x-test-token'] = 'test-token-value';
  // Let the request continue to the real server
  req.continue((res) => {
    // Optionally modify the response too
    if (res.statusCode === 401) {
      res.statusCode = 200;
      res.body = { error: 'simulated auth bypass' };
    }
  });
}).as('apiCalls');

// Simulate network latency
cy.intercept('GET', '/api/slow-endpoint', (req) => {
  req.on('response', (res) => {
    res.setDelay(1500); // ms
  });
});
```

### 4. data-cy Selectors

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

### 5. API Testing with cy.request()

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

### 6. Custom Commands

Encapsulate repeated interactions in `cypress/support/commands.ts`. Keep commands single-responsibility.

```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      loginViaApi(email: string, password: string): Chainable<void>;
      selectDropdown(selector: string, option: string): Chainable<void>;
      resetDatabase(): Chainable<void>;
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

// Database reset via task (runs in Node.js, not browser)
Cypress.Commands.add('resetDatabase', () => {
  cy.task('resetDb');  // defined in cypress/plugins/index.ts
});
```

### 7. Fixtures with cy.fixture() — Type-Safe Usage  [community]

Keep test data in `cypress/fixtures/`. Load inline or use the `fixture:` shorthand in `cy.intercept()`. Use TypeScript generics for type safety on fixture data.

```typescript
// cypress/fixtures/user.json
// { "id": 1, "name": "Alice", "role": "admin" }

// Define fixture type for IntelliSense and compile-time safety
interface UserFixture {
  id: number;
  name: string;
  role: 'admin' | 'user' | 'guest';
}

it('displays user profile', () => {
  // Use generic type parameter for type-safe access
  cy.fixture<UserFixture>('user.json').then((user) => {
    cy.intercept('GET', '/api/me', user).as('getMe');
    cy.visit('/profile');
    cy.wait('@getMe');
    cy.get('[data-cy="user-name"]').should('have.text', user.name);
    cy.get('[data-cy="user-role"]').should('have.text', user.role);
    // user.role is typed as 'admin' | 'user' | 'guest' — compile error if typo
    expect(['admin', 'user', 'guest']).to.include(user.role);
  });
});
```

### 8. Retry-ability — Write Assertions That Wait

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

### 9. Test Isolation — State Reset Between Tests  [community]

Each test must start from a known state. Never rely on order-dependent state from previous tests.

```typescript
// cypress/support/e2e.ts
beforeEach(() => {
  // Clear all session-persisted state before each test
  cy.clearAllCookies();
  cy.clearAllLocalStorage();
  cy.clearAllSessionStorage();
});

// For database-backed state, use a cy.task to trigger a reset
// (runs server-side in Node.js where DB drivers are available)
beforeEach(() => {
  cy.task('db:seed', { scenario: 'fresh' });
});

// cypress.config.ts — register the task
import { defineConfig } from 'cypress';
import { seedDatabase } from './cypress/plugins/db';

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', {
        'db:seed': ({ scenario }) => seedDatabase(scenario).then(() => null),
      });
    },
  },
});
```

### 10. Spying on Functions with cy.spy()  [community]

Use `cy.spy()` to monitor function calls without replacing them. Unlike `cy.stub()`, spies let the original function run while recording calls for assertions.

```typescript
it('calls analytics on button click', () => {
  // Spy on a method without stubbing the implementation
  const spy = cy.spy(window, 'gtag').as('analytics');

  cy.visit('/pricing');
  cy.get('[data-cy="upgrade-btn"]').click();

  // Assert the spy was called with specific args
  cy.get('@analytics').should('have.been.calledWithMatch', 'event', 'upgrade_click');
  cy.get('@analytics').should('have.been.calledOnce');
});

it('monitors XHR send without stubbing', () => {
  cy.visit('/form');
  // Spy on XMLHttpRequest.prototype.send to track actual calls
  const xhrSpy = cy.spy(XMLHttpRequest.prototype, 'send').as('xhrSend');
  cy.get('[data-cy="submit"]').click();
  cy.get('@xhrSend').should('have.been.called');
});
```

### 11. Overwriting Built-In Commands  [community]

Use `Cypress.Commands.overwrite()` to add logging, guards, or pre-conditions to standard commands.

```typescript
// cypress/support/commands.ts — make cy.visit() always wait for network idle
Cypress.Commands.overwrite('visit', (originalFn, url, options) => {
  // Log the visit for better test output
  Cypress.log({ name: 'visit', message: url });

  return originalFn(url, {
    // Merge caller's options with your defaults
    onBeforeLoad(win) {
      // Silence console errors in CI to reduce noise
      if (Cypress.env('CI')) {
        cy.stub(win.console, 'error').as('consoleError');
      }
      options?.onBeforeLoad?.(win);
    },
    ...options,
  });
});

// Extend cy.get() to assert element is not disabled before interacting
Cypress.Commands.overwrite('click', (originalFn, element, options) => {
  cy.wrap(element).should('not.be.disabled');
  return originalFn(element, options);
});
```

### 12. Component Testing

Cypress Component Testing mounts components in isolation without a full browser page load. Supports React, Vue, Angular, and Svelte.

```typescript
// counter.cy.tsx — React example
import React from 'react';
import { Counter } from '../../src/components/Counter';

describe('Counter component', () => {
  it('increments on click', () => {
    cy.mount(<Counter initialCount={0} />);
    cy.get('[data-cy="count"]').should('have.text', '0');
    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '1');
  });

  it('does not go below zero', () => {
    cy.mount(<Counter initialCount={0} />);
    cy.get('[data-cy="decrement"]').click();
    cy.get('[data-cy="count"]').should('have.text', '0');
  });
});
```

```typescript
// product-card.cy.ts — Vue 3 example
import { mount } from 'cypress/vue';
import ProductCard from '../../src/components/ProductCard.vue';

describe('ProductCard', () => {
  it('emits add-to-cart event', () => {
    const onAddToCart = cy.stub().as('addToCart');
    mount(ProductCard, {
      props: { product: { id: 1, name: 'Widget', price: 9.99 } },
      attrs: { onAddToCart },
    });
    cy.get('[data-cy="add-to-cart"]').click();
    cy.get('@addToCart').should('have.been.calledOnce');
  });
});
```

Configure in `cypress.config.ts`:

```typescript
import { defineConfig } from 'cypress';
export default defineConfig({
  component: {
    devServer: { framework: 'react', bundler: 'vite' }, // or 'vue', 'angular'
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

### 13. Debugging with .debug(), .pause(), and cy.log()  [community]

Use Cypress's built-in debugging commands rather than `console.log` — they integrate with the time-travel UI.

```typescript
it('debugs step by step', () => {
  cy.visit('/dashboard');

  // Pause execution — opens DevTools, lets you inspect DOM manually
  cy.get('[data-cy="user-menu"]').pause();

  // Log a value to the Cypress command log (not just the browser console)
  cy.get('[data-cy="cart-count"]')
    .invoke('text')
    .then((text) => cy.log(`Cart count is: ${text}`));

  // .debug() drops the element into console as `subject`
  cy.get('[data-cy="modal"]').debug();

  // Conditional breakpoint — only pause when condition fails
  cy.get('[data-cy="status-badge"]').should(($el) => {
    if (!$el.text().includes('Active')) {
      cy.pause(); // pause only on failure branch
    }
  });
});
```

### 14. Multi-Origin Authentication (OAuth/SSO) with cy.origin()

For auth flows that redirect to a third-party domain, wrap the foreign-domain commands in `cy.origin()`.

```typescript
it('logs in via OAuth provider', () => {
  cy.visit('/login');
  cy.get('[data-cy="oauth-login"]').click();

  // Navigate to the OAuth provider's domain
  cy.origin('https://accounts.provider.com', () => {
    cy.get('#email').type(Cypress.env('OAUTH_EMAIL'));
    cy.get('#password').type(Cypress.env('OAUTH_PASSWORD'));
    cy.get('#sign-in').click();
  });

  // Back on the app domain
  cy.url().should('include', '/dashboard');
  cy.get('[data-cy="user-avatar"]').should('be.visible');
});
```

### 15. Scroll and User Interaction Actions  [community]

Use Cypress action commands for realistic scroll, drag, and keyboard interactions. Avoid direct jQuery manipulation for gestures.

```typescript
it('loads more items on scroll', () => {
  cy.visit('/feed');
  cy.get('[data-cy="feed-item"]').should('have.length', 10);

  // Scroll to the bottom of the page
  cy.scrollTo('bottom');
  cy.get('[data-cy="feed-item"]').should('have.length.greaterThan', 10);

  // Scroll a specific element into view
  cy.get('[data-cy="load-more-sentinel"]').scrollIntoView();

  // Keyboard shortcuts
  cy.get('[data-cy="search-input"]').type('{ctrl}a').type('new search');

  // Drag and drop (requires @4.0+)
  cy.get('[data-cy="draggable-item"]')
    .trigger('dragstart')
    .get('[data-cy="drop-zone"]')
    .trigger('drop');
});
```

### 16. Dual-Query Commands with Cypress.Commands.addQuery()  [community]

Cypress 12+ introduced `Cypress.Commands.addQuery()` for commands that query the DOM synchronously on every retry without yielding a new command. Use it instead of `Commands.add()` for pure selectors to avoid wrapping in `.then()`.

```typescript
// cypress/support/commands.ts
// Adds cy.getByTestId() that retries like cy.get() — not like a .then() callback
Cypress.Commands.addQuery('getByTestId', (testId: string) => {
  // Return a function; Cypress calls it on every retry attempt
  return (subject) => {
    const root = subject ?? cy.state('window').document;
    const el = Cypress.$(root).find(`[data-testid="${testId}"]`);
    // Throw to trigger retry; Cypress catches this and tries again
    if (el.length === 0) {
      throw new Error(`No element found with [data-testid="${testId}"]`);
    }
    return el;
  };
});

// Type declaration
declare global {
  namespace Cypress {
    interface Chainable {
      getByTestId(testId: string): Chainable<JQuery<HTMLElement>>;
    }
  }
}

// Usage — fully retrying, composable
cy.getByTestId('submit-btn').should('be.visible').click();
```

### 17. Scoped Queries with cy.within() and cy.wrap()

Use `cy.within()` to scope subsequent `cy.get()` calls to a specific parent element. Use `cy.wrap()` to bring synchronous values (plain JS objects, DOM nodes, Promises) into the Cypress command chain.

```typescript
// cy.within() — scope to a table row without complex selectors
it('edits the second row', () => {
  cy.get('[data-cy="orders-table"]').within(() => {
    // cy.get() here only searches inside the orders-table
    cy.get('tr').eq(1).within(() => {
      cy.get('[data-cy="edit-btn"]').click();
    });
  });
  cy.get('[data-cy="edit-modal"]').should('be.visible');
});

// cy.wrap() — assert on a synchronous value inside a Cypress chain
it('validates helper output', () => {
  const discount = applyDiscount(100, 0.2); // returns 80
  cy.wrap(discount).should('equal', 80);
});

// cy.wrap() — bring a Promise into the chain
it('waits for async setup', () => {
  cy.wrap(
    fetch('/api/seed').then((r) => r.json())
  ).its('status').should('eq', 'ok');
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
// cypress/tsconfig.json (Cypress-specific override)
{
  "compilerOptions": {
    "target": "es2017",
    "lib": ["es2017", "dom"],
    "types": ["cypress", "node"],
    "strict": true,
    "esModuleInterop": true,
    "jsx": "react-jsx",
    "moduleResolution": "bundler"
  },
  "include": ["**/*.ts", "**/*.tsx", "../node_modules/cypress/types"]
}
```

Store secrets in `cypress.env.json` (gitignored) or pass via `--env`:

```bash
npx cypress run --env API_TOKEN=xyz,BASE_URL=https://staging.example.com
```

Access in tests with `Cypress.env('API_TOKEN')`.

**Type-safe environment variables:**

```typescript
// cypress/support/env.ts
declare global {
  namespace Cypress {
    interface ResolvedConfigOptions {
      env: {
        API_TOKEN: string;
        BASE_URL: string;
        OAUTH_EMAIL: string;
        OAUTH_PASSWORD: string;
      };
    }
  }
}
```

---

## Real-World Gotchas [community]

1. **`cy.wait(ms)` as a crutch** [community] — Hard-coded waits hide timing problems rather than fixing them; they slow the suite and still flake on slow CI machines. Use `cy.wait('@alias')` or a `.should()` assertion that retries instead.

2. **Storing subject between commands with `let`** [community] — Assigning `let x; cy.get(...).then(v => x = v); use(x)` does not work because Cypress commands are queued, not synchronous. Wrap the usage inside the `.then()` callback or use aliases (`cy.as('myVar')`).

3. **`cy.intercept()` registered after `cy.visit()`** [community] — If the network request fires before the intercept is registered, stubbing silently does nothing. Always register `cy.intercept()` before `cy.visit()`.

4. **`cy.session()` cache serving a stale token** [community] — Without a `validate` callback, a cached session with an expired JWT will pass the restore step but fail mid-test. Always add a `validate()` that hits an authenticated endpoint.

5. **Shared mutable state via `Cypress.env()`** [community] — Setting values in `beforeEach` with `Cypress.env()` persists across specs when `cacheAcrossSpecs` is active or the runner reuses the process. Use unique keys per test or clean up in `afterEach`.

6. **Cross-origin navigation without `cy.origin()`** [community] — Visiting a second domain (e.g., an OAuth provider) without `cy.origin()` throws a cross-origin error. Wrap the redirected-domain commands inside `cy.origin('https://auth.provider.com', () => { ... })`.

7. **Asserting on detached DOM nodes** [community] — After a React re-render, a previously queried element may be detached. Re-query inside `.should()` or use `.find()` from a stable parent rather than caching the element reference.

8. **`cy.clock()` not advancing automatically** [community] — `cy.clock()` replaces `Date`, `setTimeout`, and `setInterval` globally but they only advance when you call `cy.tick(ms)`. Tests that stub timers but never tick will hang or produce false positives. Always pair `cy.clock()` with `cy.tick()` or `cy.clock().invoke('restore')` at the end.

9. **`cy.task()` must return a value (not `undefined`)** [community] — If a `cy.task()` handler returns `undefined` or a Promise that resolves to `undefined`, Cypress throws `"cy.task('x') failed because the task handler did not return a value"`. Always return `null` as the sentinel no-value result.

10. **Videos consuming CI storage** [community] — Cypress records a video for every spec by default, even passing ones. On a large suite this fills CI artifact storage quickly. Set `video: false` in `cypress.config.ts` and only enable it per-job when you need failure recordings.

---

## CI Considerations

- **Run headless** — `npx cypress run` defaults to headless Electron. For Chrome: `--browser chrome --headless`.
- **Parallelise with Cypress Cloud** — Use `--parallel --record --ci-build-id $CI_BUILD_ID` to split specs across machines. Requires a Cypress Cloud project key in `CYPRESS_RECORD_KEY`.
- **Artifact retention** — Set `screenshotsFolder` and `videosFolder` in `cypress.config.ts`; upload to CI artifact store on failure only to save storage.
- **`baseUrl` via env** — Never hardcode URLs. Set `baseUrl` in `cypress.config.ts` and override with `CYPRESS_BASE_URL=https://staging.example.com` in CI.
- **Docker image** — Use the official `cypress/included` image; it bundles all browser deps and avoids missing shared-library issues on stripped CI images.
- **Retry flaky tests** — Add `"retries": { "runMode": 2, "openMode": 0 }` in `cypress.config.ts` to automatically re-attempt failed tests in CI without masking real failures locally.
- **`--spec` flag for targeted runs** — In monorepos or large suites, run only changed specs with `--spec "cypress/e2e/checkout/**"` to keep PR feedback loops fast.
- **Node version pinning** — Pin the Node.js version in CI to match the dev environment. Cypress is sensitive to Node.js ABI changes that affect native modules.
- **`experimentalOriginDependencies`** — Set to `true` in `cypress.config.ts` to allow `cy.origin()` to load custom commands defined in the support file inside origin callbacks; without it, commands like `cy.loginViaApi()` are not available inside `cy.origin()`.
- **Flakiness root-cause beyond retries** — Retries mask symptoms; fix root causes: (1) ensure `cy.intercept()` is registered before `cy.visit()`; (2) replace `cy.wait(ms)` with `cy.wait('@alias')`; (3) use `beforeEach` state resets; (4) avoid `cy.get().then()` snapshot patterns for assertions.
- **Cypress Cloud Flaky Test Detection** — Cypress Cloud automatically marks tests as "flaky" when they pass on retry. Review the Flaky Tests dashboard weekly; a test flaking in CI 3+ times signals a test design issue, not just infrastructure noise.

```typescript
// cypress.config.ts — production-ready CI config
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx}',
    screenshotOnRunFailure: true,
    video: false,                   // enable in CI only via env override
    retries: { runMode: 2, openMode: 0 },
    defaultCommandTimeout: 8000,
    requestTimeout: 10000,
    responseTimeout: 30000,
    pageLoadTimeout: 60000,
    viewportWidth: 1280,
    viewportHeight: 720,
    experimentalMemoryManagement: true, // reduces memory pressure in long runs
    numTestsKeptInMemory: 5,           // lower for large suites
    setupNodeEvents(on, config) {
      // Register tasks for server-side operations
      on('task', {
        log: (message: string) => { console.log(message); return null; },
      });
      // Read env-specific config from files
      const envConfig = require(`./cypress/config/${config.env.environment || 'local'}.json`);
      return { ...config, ...envConfig };
    },
  },
  component: {
    devServer: { framework: 'react', bundler: 'vite' },
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

### GitHub Actions Example

```yaml
# .github/workflows/e2e.yml
name: E2E Tests
on: [push, pull_request]
jobs:
  cypress:
    runs-on: ubuntu-latest
    container:
      image: cypress/included:13.6.0   # pin major version
    strategy:
      matrix:
        # Run 3 parallel machines
        containers: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - name: Run Cypress
        run: npx cypress run
          --record --parallel
          --ci-build-id "${{ github.run_id }}-${{ github.run_attempt }}"
          --browser chrome
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          CYPRESS_BASE_URL: ${{ vars.STAGING_URL }}
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: cypress-screenshots-${{ matrix.containers }}
          path: cypress/screenshots/
          retention-days: 7
```

---

## Advanced Patterns

### Cypress Module API — Programmatic Runs

The Cypress Module API lets you invoke Cypress programmatically from a Node.js script (e.g., a custom CI orchestrator, a script that seeds the DB first, or a monorepo runner that maps spec files to environments).

```typescript
// scripts/run-e2e.ts
import cypress from 'cypress';
import { seedDatabase, teardownDatabase } from '../db/helpers';

async function main(): Promise<void> {
  await seedDatabase({ scenario: 'full' });

  const result = await cypress.run({
    browser: 'chrome',
    headless: true,
    spec: 'cypress/e2e/checkout/**/*.cy.ts',
    config: {
      baseUrl: process.env.CYPRESS_BASE_URL ?? 'http://localhost:3000',
      video: false,
      retries: { runMode: 2, openMode: 0 },
    },
    env: {
      API_TOKEN: process.env.API_TOKEN,
    },
  });

  await teardownDatabase();

  if (result.status === 'failed' || result.totalFailed > 0) {
    console.error(`${result.totalFailed} spec(s) failed`);
    process.exit(1);
  }
}

main().catch((err) => { console.error(err); process.exit(1); });
```

Run with: `npx ts-node scripts/run-e2e.ts`

### Environment-Based Configuration

```typescript
// cypress/config/staging.json
// { "baseUrl": "https://staging.example.com", "env": { "API_TOKEN": "..." } }

// Run with: npx cypress run --env environment=staging
```

### Accessibility Testing Integration  [community]

Integrate `cypress-axe` to catch accessibility regressions automatically.

```typescript
// cypress/support/e2e.ts
import 'cypress-axe';

// In a spec:
it('has no detectable accessibility violations', () => {
  cy.visit('/dashboard');
  cy.injectAxe();
  cy.checkA11y('[data-cy="main-content"]', {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] },
  });
});
```

### Visual Regression Testing  [community]

Use `@percy/cypress` or `cypress-image-snapshot` for pixel-level regression detection.

```typescript
// After installing @percy/cypress:
import '@percy/cypress';

it('matches visual snapshot', () => {
  cy.visit('/landing');
  cy.percySnapshot('Landing page', { widths: [375, 1280] });
});
```

### Tagging Tests for Selective Runs  [community]

Use `@cypress/grep` to tag and filter tests without separate spec files.

```typescript
// Install: npm install @cypress/grep
// In cypress/support/e2e.ts: import registerCypressGrep from '@cypress/grep'
// registerCypressGrep()

describe('Checkout flow', { tags: ['@critical', '@smoke'] }, () => {
  it('completes purchase', { tags: '@critical' }, () => {
    // ...
  });
});

// Run only critical tests:
// npx cypress run --env grep=@critical
```

---

## Key APIs

| Method | Purpose | When to use |
|--------|---------|-------------|
| `cy.visit(url)` | Navigate to a URL | Start of each test flow |
| `cy.get(selector)` | Query DOM element | Primary element selector |
| `cy.contains(text)` | Find element by text content | Links, buttons without data-cy |
| `cy.intercept(method, url, handler)` | Stub, spy, or modify network requests | Isolate UI from backend |
| `cy.wait('@alias')` | Wait for an intercepted request | After intercept before assertion |
| `cy.request(options)` | Make HTTP request directly | API seeding, auth, assertions |
| `cy.session(id, setup, options)` | Cache and restore browser session | Login in `beforeEach` |
| `cy.fixture(filename)` | Load JSON test data | Stubs, assertions |
| `cy.stub(obj, method)` | Stub a JS function | Mock browser APIs or app functions |
| `cy.clock() / cy.tick(ms)` | Control JS timers | Test debounced inputs, timeouts |
| `cy.viewport(w, h)` | Set browser viewport | Responsive layout tests |
| `cy.screenshot()` | Capture screenshot | Debug; called automatically on failure |
| `cy.task(name, args)` | Run code in Node.js context | DB operations, file I/O |
| `.should(assertion)` | Retrying assertion | All state assertions |
| `.then(cb)` | Access command subject value | Extract values for `.request()`, etc. |
| `.as(alias)` | Name a chain for later reference | Share subjects between hooks/tests |
| `cy.origin(url, fn)` | Run commands on a different origin | OAuth / SSO flows |
| `cy.mount(component)` | Mount a component in isolation | Component testing only |
| `.debug()` | Drop subject to DevTools console | Live debugging |
| `.pause()` | Pause test execution | Step-through debugging |
| `cy.log(message)` | Add entry to Cypress command log | Structured test output |
| `cy.scrollTo(position)` | Scroll page or element | Infinite scroll, lazy-load testing |
| `cy.clearAllCookies()` | Clear all browser cookies | Test isolation in `beforeEach` |
| `cy.clearAllLocalStorage()` | Clear all localStorage | Test isolation in `beforeEach` |
| `cy.spy(obj, method)` | Monitor function calls without stubbing | Analytics, event tracking assertions |
| `cy.clock()` | Freeze/control JS timers globally | Test timeouts, debounce, polling |
| `cy.tick(ms)` | Advance frozen clock by milliseconds | Pair with `cy.clock()` |
| `Cypress.Commands.addQuery()` | Add a retrying synchronous query command | Custom element selectors |
| `Cypress.Commands.overwrite()` | Wrap a built-in command with custom logic | Add logging/guards to `cy.visit()` |
| `cypress.run(options)` | Programmatically invoke Cypress | Custom CI scripts, monorepo runners |
