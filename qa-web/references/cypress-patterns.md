# Cypress Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official + community + training knowledge | iteration: 37 | score: 100/100 | date: 2026-05-12 -->
<!-- official: docs.cypress.io/guides/references/best-practices, /api/commands/session, /api/commands/intercept, /api/commands/selectfile, /guides/end-to-end-testing/testing-strategies, /guides/component-testing/overview, /guides/cloud/introduction, /api/commands/press, /api/commands/env, /app/references/changelog#15-0-0, /app/references/changelog#15-14-2, /app/continuous-integration/github-actions (Apr 2026), /app/guides/network-requests, /app/references/module-api, /api/cypress-api/stop, /api/commands/prompt, /api/cypress-api/element-selector-api, /api/cypress-api/expose, /app/references/migration-guide -->
<!-- new in this iteration (37): cy.prompt() BDD Gherkin + placeholder loop caching (pattern 115), Cypress Module API expose + posixExitCodes deep example (pattern 116), cy.env() multi-key single-call + log:false (pattern 117), 7 new community gotchas (94-100): .invoke() throws on Promise (Cy15), cy.wait([]) routeId crash (15.14.2), Chrome 137 --load-extension removal, transitive CVE monitoring, cy.prompt() rate-limit exhaustion in parallel CI, experimentalStudio flag removal causes parse error (Cy 15.4+), injectDocumentDomain removal in Cy 15 -->
<!-- previous iteration: cy.url()/cy.location() automation-client change in v15 (cross-origin gotcha), cy.fixture() cache invalidation stale-data gotcha after cy.writeFile(), cy.wrap() circular reference protection, synchronous XHR route handler browser freeze (v15.8 fix), defaultBrowser config option for local developer DX, 4 new community gotchas (90-93), pattern 114 (defaultBrowser + browser override patterns) -->

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

// Role-specific session keys — prevents stale cache when users have different permissions
export function loginAsRole(role: 'admin' | 'user' | 'viewer'): void {
  const credentials: Record<typeof role, { email: string; password: string }> = {
    admin:  { email: 'admin@example.com',  password: Cypress.env('ADMIN_PASS') },
    user:   { email: 'user@example.com',   password: Cypress.env('USER_PASS') },
    viewer: { email: 'viewer@example.com', password: Cypress.env('VIEWER_PASS') },
  };
  const { email, password } = credentials[role];

  cy.session(
    [role, email],                             // role in key — separate cache per role
    () => {
      cy.visit('/login');
      cy.get('[data-cy="email"]').type(email);
      cy.get('[data-cy="password"]').type(password);
      cy.get('[data-cy="submit"]').click();
      cy.url().should('include', '/dashboard');
    },
    {
      validate() {
        cy.request({ url: '/api/me', failOnStatusCode: false })
          .its('body.role').should('eq', role);  // validate ROLE, not just auth status
      },
      cacheAcrossSpecs: true,
    }
  );
}
```

### 2. Network Mocking with cy.intercept()

Intercept and stub HTTP traffic to isolate the UI from backend flakiness. Use the `routeMatcher` object form for precise matching on method, URL, headers, query params, and body.

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

  it('intercepts only requests with specific headers (routeMatcher object form)', () => {
    // Use RouteMatcher object for multi-dimension matching
    cy.intercept({
      method: 'GET',
      url: '/api/products*',
      headers: { 'x-api-version': '2' },
      query: { sort: 'price' },
    }, { fixture: 'products-v2-sorted.json' }).as('getProductsV2Sorted');

    cy.visit('/products?sort=price');
    cy.wait('@getProductsV2Sorted');
    cy.get('[data-cy="product-card"]').first().should('have.attr', 'data-price');
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

### 18. Page Object Model (TypeScript class-based)  [community]

Encapsulate page interactions in typed POM classes. In Cypress, POM methods return `void` (or the POM instance for fluent chaining) rather than `WebElement` references, because Cypress subjects are ephemeral.

```typescript
// cypress/pages/LoginPage.ts
export class LoginPage {
  private readonly url = '/login';

  visit(): this {
    cy.visit(this.url);
    return this;
  }

  fillEmail(email: string): this {
    cy.get('[data-cy="email"]').clear().type(email);
    return this;
  }

  fillPassword(password: string): this {
    cy.get('[data-cy="password"]').clear().type(password);
    return this;
  }

  submit(): this {
    cy.get('[data-cy="submit"]').click();
    return this;
  }

  assertErrorMessage(message: string): this {
    cy.get('[data-cy="error-message"]').should('contain.text', message);
    return this;
  }
}

// cypress/pages/index.ts
export { LoginPage } from './LoginPage';

// In spec:
import { LoginPage } from '../pages';

describe('Authentication', () => {
  it('shows error on invalid credentials', () => {
    new LoginPage()
      .visit()
      .fillEmail('bad@user.com')
      .fillPassword('wrong')
      .submit()
      .assertErrorMessage('Invalid credentials');
  });
});
```

### 19. File Upload with cy.selectFile()

`cy.selectFile()` (added in Cypress 9.3) replaces the community plugin `cypress-file-upload`. It works with both real file paths and inline buffer content.

```typescript
it('uploads a CSV report', () => {
  cy.visit('/import');

  // Select a file from the fixtures directory
  cy.get('[data-cy="file-input"]').selectFile('cypress/fixtures/report.csv');
  cy.get('[data-cy="upload-btn"]').click();
  cy.get('[data-cy="upload-status"]').should('contain.text', 'Import successful');
});

it('uploads a dynamically generated file', () => {
  cy.visit('/import');

  // Pass file content as a Cypress.Buffer for dynamic data
  cy.get('[data-cy="file-input"]').selectFile({
    contents: Cypress.Buffer.from('id,name\n1,Alice\n2,Bob'),
    fileName: 'users.csv',
    mimeType: 'text/csv',
    lastModified: Date.now(),
  });

  cy.get('[data-cy="upload-btn"]').click();
  cy.get('[data-cy="row-count"]').should('have.text', '2');
});

it('drag-drops a file onto a dropzone', () => {
  cy.visit('/upload');

  // Use action: 'drag-drop' for dropzone-based upload components
  cy.get('[data-cy="dropzone"]').selectFile('cypress/fixtures/image.png', {
    action: 'drag-drop',
  });

  cy.get('[data-cy="preview-image"]').should('be.visible');
});
```

### 20. Type-safe Selector Maps with `as const`  [community]

Define all `data-cy` selectors in a central const map using `as const`. This prevents typos, enables IDE autocomplete, and makes selector changes traceable.

```typescript
// cypress/support/selectors.ts
export const SELECTORS = {
  auth: {
    emailInput:    '[data-cy="email"]',
    passwordInput: '[data-cy="password"]',
    submitButton:  '[data-cy="submit"]',
    errorMessage:  '[data-cy="error-message"]',
  },
  nav: {
    homeLink:    '[data-cy="nav-home"]',
    profileLink: '[data-cy="nav-profile"]',
    logoutBtn:   '[data-cy="nav-logout"]',
  },
  dashboard: {
    welcomeText: '[data-cy="welcome-text"]',
    statCards:   '[data-cy="stat-card"]',
  },
} as const;

// Derive the nested value type for any autocomplete or type assertion
type SelectorGroup = typeof SELECTORS;

// Usage — typos become compile errors
import { SELECTORS as S } from '../support/selectors';

cy.get(S.auth.emailInput).type('alice@example.com');
cy.get(S.auth.submitButton).click();
cy.get(S.dashboard.welcomeText).should('contain', 'Alice');
```

### 21. Typed cy.task() with Generics  [community]

`cy.task()` runs code in the Node.js plugin context. Use a typed task map interface to get IntelliSense on task names and return values across the entire test suite.

```typescript
// cypress/plugins/task-types.ts — central type contract
export interface CypressTasks {
  'db:seed': (scenario: string) => Promise<null>;
  'db:query': (sql: string) => Promise<Record<string, unknown>[]>;
  'email:get': (address: string) => Promise<{ subject: string; body: string } | null>;
  log: (message: string) => null;
}

// cypress.config.ts — implement every task
import type { CypressTasks } from './cypress/plugins/task-types';
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', {
        'db:seed': async (scenario) => {
          await seedDatabase(scenario);
          return null;                         // must return null, not undefined
        },
        'db:query': async (sql) => runQuery(sql),
        'email:get': async (address) => getLatestEmail(address),
        log: (message) => { console.log(message); return null; },
      } satisfies CypressTasks);               // satisfies verifies all keys present
    },
  },
});

// Custom command wrapper for type-safe calls
declare global {
  namespace Cypress {
    interface Chainable {
      task<K extends keyof CypressTasks>(
        event: K,
        arg?: Parameters<CypressTasks[K]>[0]
      ): Chainable<Awaited<ReturnType<CypressTasks[K]>>>;
    }
  }
}

// Usage — fully typed
cy.task('db:seed', 'fresh-user').then(() => {
  cy.task('email:get', 'user@example.com').then((email) => {
    expect(email?.subject).to.include('Welcome');
  });
});
```

### 22. Responsive Testing with cy.viewport()  [community]

Test breakpoint-specific behavior systematically by parameterizing viewport sizes. Use `beforeEach` with a viewport map to avoid duplicating tests.

```typescript
// cypress/support/viewports.ts
export const VIEWPORTS = {
  mobile:  { width: 375,  height: 812,  label: 'mobile-portrait' },
  tablet:  { width: 768,  height: 1024, label: 'tablet' },
  desktop: { width: 1280, height: 720,  label: 'desktop' },
} as const satisfies Record<string, { width: number; height: number; label: string }>;

// Parameterized responsive spec
import { VIEWPORTS } from '../support/viewports';

const breakpoints = [VIEWPORTS.mobile, VIEWPORTS.tablet, VIEWPORTS.desktop] as const;

breakpoints.forEach(({ width, height, label }) => {
  describe(`Navigation at ${label}`, () => {
    beforeEach(() => {
      cy.viewport(width, height);
      cy.visit('/');
    });

    it('shows appropriate nav for viewport', () => {
      if (width <= 768) {
        cy.get('[data-cy="hamburger-menu"]').should('be.visible');
        cy.get('[data-cy="desktop-nav"]').should('not.be.visible');
      } else {
        cy.get('[data-cy="desktop-nav"]').should('be.visible');
        cy.get('[data-cy="hamburger-menu"]').should('not.exist');
      }
    });
  });
});
```

### 23. URL and Location Assertions with cy.location()

Use `cy.location()` to assert on specific URL parts (pathname, search, hash) without brittle full-URL string matching.

```typescript
it('redirects to the correct route with query params', () => {
  cy.visit('/search?q=cypress&page=1');

  // Assert on individual URL parts — more robust than cy.url().should('include', ...)
  cy.location('pathname').should('eq', '/search');
  cy.location('search').should('eq', '?q=cypress&page=1');
  cy.location('hash').should('be.empty');

  // Filter results and assert query string updated
  cy.get('[data-cy="filter-active"]').click();
  cy.location('search').should('include', 'filter=active');
});

it('stays on the same page after failed form submission', () => {
  cy.visit('/register');
  cy.get('[data-cy="submit"]').click();  // submit empty form

  // Use location rather than url() to avoid full-URL fragility in multi-env setups
  cy.location('pathname').should('eq', '/register');
});
```

### 24. File I/O in Tests with cy.readFile() and cy.writeFile()  [community]

Use `cy.readFile()` to assert on generated exports (CSV, JSON, PDF) and `cy.writeFile()` to persist test data or seed files without calling a server endpoint.

```typescript
it('exports data as a CSV file', () => {
  cy.visit('/reports');
  cy.get('[data-cy="export-csv"]').click();

  // Wait for the download to complete, then assert on its content
  cy.readFile('cypress/downloads/report.csv', { timeout: 15_000 })
    .should('contain', 'id,name,date')
    .and('contain', 'Alice');
});

it('seeds JSON fixture file for the next test', () => {
  const testUser = { id: 'usr_test', email: 'e2e@example.com', role: 'admin' };

  // Write a fixture dynamically — useful for parameterized test data generation
  cy.writeFile('cypress/fixtures/current-user.json', testUser);

  cy.intercept('GET', '/api/me', { fixture: 'current-user.json' }).as('getMe');
  cy.visit('/dashboard');
  cy.wait('@getMe');
  cy.get('[data-cy="user-badge"]').should('contain', 'e2e@example.com');
});
```

### 25. Shadow DOM Traversal

Cypress can query inside Shadow DOM with the `includeShadowDom` option or globally via `cypress.config.ts`. Without it, `cy.get()` stops at shadow boundaries.

```typescript
// cypress.config.ts — enable globally (affects all cy.get() calls)
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    includeShadowDom: true,  // traverse shadow roots automatically
  },
});

// Per-call override: disable shadow traversal for a specific query
cy.get('[data-cy="shadow-host"]', { includeShadowDom: false });
```

```typescript
// spec — query elements inside a Web Component's shadow root
it('interacts with shadow DOM element', () => {
  cy.visit('/web-components-demo');

  // With includeShadowDom: true in config, cy.get() pierces shadow roots
  cy.get('my-button').shadow().find('[data-cy="inner-btn"]').click();

  // Or use .shadow() explicitly on the host element
  cy.get('custom-input')
    .shadow()
    .find('input')
    .type('shadow DOM input value');

  cy.get('custom-input')
    .shadow()
    .find('[data-cy="validation-msg"]')
    .should('not.exist');
});
```

### 26. iframe Testing with cy.frameLoaded() and cy.iframe()  [community]

Cypress does not natively support iframes beyond same-origin. For same-origin iframes use the `cypress-iframe` plugin; for cross-origin use `cy.origin()` combined with `cy.iframe()`.

```typescript
// Install: npm install cypress-iframe
// cypress/support/e2e.ts: import 'cypress-iframe'

it('fills a form inside an iframe', () => {
  cy.visit('/embedded-form');

  // Wait for the iframe to fully load
  cy.frameLoaded('[data-cy="payment-frame"]');

  // Enter the iframe context and query elements inside
  cy.iframe('[data-cy="payment-frame"]').within(() => {
    cy.get('#card-number').type('4111 1111 1111 1111');
    cy.get('#expiry').type('12/28');
    cy.get('#cvv').type('123');
    cy.get('#submit-payment').click();
  });

  // Back on the parent page — assert post-submit state
  cy.get('[data-cy="payment-success"]').should('be.visible');
});
```

**[community]** WHY: The `cypress-iframe` plugin replaces `cy.get('iframe').its('0.contentDocument.body').then(cy.wrap)` — the raw approach is fragile because `contentDocument` may be null until the frame loads and is undefined for cross-origin frames. The plugin handles load timing reliably.

### 27. Handling Uncaught Exceptions and Console Errors  [community]

By default Cypress fails a test when the application throws an uncaught JavaScript error. Override this selectively for known non-critical errors.

```typescript
// cypress/support/e2e.ts — global handler for known ignorable errors
Cypress.on('uncaught:exception', (err, runnable) => {
  // Return false to prevent Cypress from failing the test
  // Only do this for errors you understand and cannot fix
  if (err.message.includes('ResizeObserver loop limit exceeded')) {
    // Browser/OS-specific warning, not a real failure
    return false;
  }
  if (err.message.includes('Non-Error promise rejection')) {
    return false;
  }
  // For all other errors, let Cypress fail the test
  return true;
});

// Per-test override — suppress for a single test only
it('loads a page with a known 3rd-party error', () => {
  cy.on('uncaught:exception', (err) => {
    if (err.message.includes('Stripe.js not found')) return false;
    return true;
  });

  cy.visit('/checkout');
  cy.get('[data-cy="checkout-form"]').should('be.visible');
});
```

**[community]** WHY: Globally returning `false` from `uncaught:exception` masks real regressions. Always filter by specific error message and log the suppressed error so you can track whether its frequency changes.

### 28. Deep Property Access and Method Calls with cy.its() and cy.invoke()

Use `cy.its()` for zero-argument property access (including nested dot-paths) and `cy.invoke()` to call a method on the subject and get its return value.

```typescript
// cy.its() — read a property from the command subject
it('reads nested object property', () => {
  cy.request('/api/user/1').its('body.address.city').should('eq', 'Berlin');

  // Read DOM property (not attribute)
  cy.get('[data-cy="product-img"]').its('naturalWidth').should('be.gt', 0);

  // Read a fixture property without .then()
  cy.fixture('config.json').its('featureFlags.darkMode').should('be.true');
});

// cy.invoke() — call a method on the subject
it('calls a method on the subject and asserts result', () => {
  // Trim whitespace from element text before asserting
  cy.get('[data-cy="price-tag"]')
    .invoke('text')
    .invoke('trim')
    .should('eq', '$9.99');

  // Call jQuery method on a DOM element
  cy.get('[data-cy="accordion"]').invoke('height').should('be.gt', 100);

  // Trigger a method on an app object exposed to the window
  cy.window().invoke('appBridge.logout');
  cy.location('pathname').should('eq', '/login');
});
```

### 29. Running Shell Commands with cy.exec()

`cy.exec()` runs a shell command in the Node.js context and yields `{ code, stdout, stderr }`. Use it for database seeding scripts, file cleanup, and compile-step verification.

```typescript
it('seeds the database before the test', () => {
  cy.exec('npm run db:seed -- --scenario fresh', {
    timeout: 30_000,       // allow up to 30 s for DB seed
    failOnNonZero: true,   // fail the test if exit code !== 0
  }).then((result) => {
    expect(result.code).to.eq(0);
    cy.log(`Seed output: ${result.stdout}`);
  });

  cy.visit('/dashboard');
  cy.get('[data-cy="user-count"]').should('have.text', '0');
});

it('verifies a file was generated', () => {
  cy.get('[data-cy="export-pdf"]').click();

  // Poll the filesystem via exec for the generated file
  cy.exec('ls cypress/downloads/*.pdf', { failOnNonZero: false })
    .its('stdout')
    .should('include', '.pdf');
});
```

**[community]** WHY: `cy.exec()` runs in the Cypress Node.js subprocess, not the browser, so it has access to the full filesystem and npm scripts. This is the right tool for heavyweight setup/teardown that doesn't need a server endpoint — unlike `cy.task()`, which requires registering handlers in `cypress.config.ts`.

### 30. Component Testing with Providers (React Context & Redux)  [community]

When mounting components that depend on React Context or a Redux store, wrap them in `cy.mount()` using a custom `mount` command that injects the required providers.

```typescript
// cypress/support/component.tsx — override mount with providers
import React from 'react';
import { mount } from 'cypress/react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { ThemeProvider } from '@mui/material';
import { createTestStore } from '../../src/store/testStore';
import { lightTheme } from '../../src/theme';

declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof mount;
    }
  }
}

Cypress.Commands.add('mount', (component, options = {}) => {
  const store = options.reduxState
    ? createTestStore(options.reduxState)
    : createTestStore();

  const wrapped = (
    <Provider store={store}>
      <MemoryRouter initialEntries={[options.routePath ?? '/']}>
        <ThemeProvider theme={lightTheme}>
          {component}
        </ThemeProvider>
      </MemoryRouter>
    </Provider>
  );

  return mount(wrapped, options);
});

// In a spec — mount a component that reads from the Redux store
import { UserProfile } from '../../src/components/UserProfile';

it('renders logged-in user profile', () => {
  cy.mount(<UserProfile />, {
    reduxState: {
      auth: { user: { name: 'Alice', role: 'admin' }, isLoggedIn: true },
    },
  });

  cy.get('[data-cy="user-name"]').should('have.text', 'Alice');
  cy.get('[data-cy="admin-badge"]').should('be.visible');
});

// React Context (custom context provider) — no Redux
import { UserContext, UserContextValue } from '../../src/contexts/UserContext';
import { NotificationBanner } from '../../src/components/NotificationBanner';

it('shows notification banner when UserContext has an alert', () => {
  const mockContextValue: UserContextValue = {
    user: { id: 'usr_1', name: 'Bob', role: 'user' },
    alert: { type: 'warning', message: 'Your trial expires tomorrow' },
    dismissAlert: cy.stub().as('dismissAlert'),
  };

  cy.mount(
    <UserContext.Provider value={mockContextValue}>
      <NotificationBanner />
    </UserContext.Provider>
  );

  cy.get('[data-cy="notification-banner"]')
    .should('be.visible')
    .and('contain.text', 'Your trial expires tomorrow');

  cy.get('[data-cy="dismiss-btn"]').click();
  cy.get('@dismissAlert').should('have.been.calledOnce');
});
```

### 31. Network Throttling via Chrome DevTools Protocol (CDP)  [community]

Cypress exposes `cy.wrap(Cypress.automation(...))` and the `before:browser:launch` hook to simulate slow network conditions using the Chrome DevTools Protocol. This is useful for testing loading states, skeleton screens, and timeout handling.

```typescript
// cypress/support/commands.ts — custom command for network throttling
declare global {
  namespace Cypress {
    interface Chainable {
      throttleNetwork(profile: 'offline' | 'slow3g' | 'fast3g' | 'online'): Chainable<void>;
    }
  }
}

const NETWORK_PROFILES = {
  offline:  { offline: true,  latency: 0,   downloadThroughput: 0,       uploadThroughput: 0 },
  slow3g:   { offline: false, latency: 400,  downloadThroughput: 500 / 8 * 1024,   uploadThroughput: 500 / 8 * 1024 },
  fast3g:   { offline: false, latency: 100,  downloadThroughput: 1500 / 8 * 1024,  uploadThroughput: 750 / 8 * 1024 },
  online:   { offline: false, latency: 0,   downloadThroughput: -1,      uploadThroughput: -1 },
} as const;

Cypress.Commands.add('throttleNetwork', (profile) => {
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Network.emulateNetworkConditions',
      params: NETWORK_PROFILES[profile],
    })
  );
});

// In a spec — test skeleton loading screen on slow connection
it('shows skeleton loader on slow 3G', () => {
  cy.throttleNetwork('slow3g');
  cy.visit('/products');
  cy.get('[data-cy="skeleton-loader"]').should('be.visible');
  cy.get('[data-cy="product-list"]').should('be.visible');   // waits for real content
  cy.throttleNetwork('online');  // restore at end
});
```

### 32. Sinon Stub Matchers and Spy Assertions  [community]

Cypress bundles Sinon.js. Access it via `cy.stub()` and use `sinon.match.*` matchers for flexible argument assertions without specifying exact values.

```typescript
it('calls the analytics service with correct event shape', () => {
  // Stub a global method — stops the real implementation running
  const trackStub = cy.stub(window, 'analytics').as('track');

  cy.visit('/purchase-complete');
  cy.get('[data-cy="confirm-order"]').click();

  // Assert the stub was called with a sinon.match object shape
  cy.get('@track').should('have.been.calledWithMatch',
    sinon.match({
      event: 'purchase',
      properties: sinon.match({
        revenue: sinon.match.number,
        currency: sinon.match.string,
        items:    sinon.match.array,
      }),
    })
  );
});

it('retries an API call on failure using sinon call count', () => {
  let callCount = 0;

  cy.intercept('POST', '/api/order', (req) => {
    callCount += 1;
    if (callCount < 3) {
      req.reply({ statusCode: 503 });
    } else {
      req.reply({ statusCode: 200, body: { orderId: 'ord_123' } });
    }
  }).as('postOrder');

  cy.get('[data-cy="place-order"]').click();
  // App should retry 3 times; assert the intercepted route was hit 3 times
  cy.get('@postOrder.all').should('have.length', 3);
  cy.get('[data-cy="order-confirmation"]').should('be.visible');
});
```

### 33. cy.all() for Parallel Multi-Element Assertions (Cypress 13.4+)  [community]

`cy.all()` runs multiple Cypress queries in parallel and resolves when all complete. Use it to assert on several independent elements simultaneously without sequential chaining, reducing test duration in large assertion blocks.

```typescript
// Wait for all three widgets to load before asserting any of them
it('dashboard widgets all render on load', () => {
  cy.visit('/dashboard');

  cy.all(
    () => cy.get('[data-cy="revenue-widget"]').should('be.visible'),
    () => cy.get('[data-cy="users-widget"]').should('be.visible'),
    () => cy.get('[data-cy="orders-widget"]').should('be.visible'),
  );

  // After cy.all() all three widgets are confirmed visible
  cy.get('[data-cy="revenue-widget"]').invoke('text').should('match', /\$[\d,]+/);
});

// Combine with cy.intercept aliases — wait for multiple requests simultaneously
it('loads page data from multiple endpoints', () => {
  cy.intercept('GET', '/api/stats').as('stats');
  cy.intercept('GET', '/api/notifications').as('notifications');
  cy.intercept('GET', '/api/user').as('user');

  cy.visit('/dashboard');

  cy.all(
    () => cy.wait('@stats'),
    () => cy.wait('@notifications'),
    () => cy.wait('@user'),
  );

  cy.get('[data-cy="dashboard-ready"]').should('be.visible');
});

// Version guard — cy.all() requires Cypress 13.4+
// Add to cypress/support/e2e.ts
before(() => {
  const version = Cypress.version.split('.').map(Number);
  if (version[0] < 13 || (version[0] === 13 && version[1] < 4)) {
    throw new Error(`cy.all() requires Cypress 13.4+. Current version: ${Cypress.version}`);
  }
});
```

### 34. WebKit (Safari) Testing with experimentalWebKitSupport  [community]

Cypress 10.8+ supports Safari/WebKit via an experimental flag. This allows cross-browser coverage without Playwright for teams already using Cypress.

```typescript
// cypress.config.ts — enable WebKit support
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    experimentalWebKitSupport: true,
  },
});
```

```bash
# Run tests in WebKit (Safari engine) — requires @cypress/webkit package
npm install @cypress/webkit
npx cypress run --browser webkit
```

```typescript
// cypress.config.ts — run specific specs in WebKit via project config
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    experimentalWebKitSupport: true,
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx}',
  },
  // Define a WebKit project for targeted runs
  projects: [
    { name: 'chrome',  browser: 'chrome' },
    { name: 'webkit',  browser: 'webkit', specPattern: 'cypress/e2e/cross-browser/**' },
  ],
});
```

**[community]** WHY: WebKit support is experimental as of 2026 and has known gaps (no CDP automation support, limited `cy.origin()` behaviour). Use it for smoke-level cross-browser confidence rather than full E2E coverage; keep the main suite on Chrome/Firefox.

### 35. Iterating DOM Collections with cy.each()

`cy.each()` iterates over a jQuery collection, letting you assert on or interact with each element individually. Unlike `.should('have.length', n)`, it validates per-element content.

```typescript
it('all product cards show a price', () => {
  cy.visit('/products');
  cy.get('[data-cy="product-card"]').each(($card, index) => {
    // cy.wrap() brings the jQuery element into the Cypress chain
    cy.wrap($card).find('[data-cy="price"]').invoke('text').then((text) => {
      expect(text.trim()).to.match(/^\$[\d.]+$/, `Card ${index} price format invalid`);
    });
    cy.wrap($card).find('[data-cy="add-to-cart"]').should('not.be.disabled');
  });
});

it('fills in a dynamic form with different values per row', () => {
  const entries = ['Alice', 'Bob', 'Carol'];
  cy.visit('/bulk-add');

  cy.get('[data-cy="name-input"]').each(($input, index) => {
    cy.wrap($input).clear().type(entries[index]);
  });

  cy.get('[data-cy="submit-all"]').click();
  cy.get('[data-cy="success-count"]').should('have.text', '3');
});
```

### 36. Keyboard Accessibility Testing with cy.focused() and Tab Navigation

Test keyboard focus order and ARIA interactions without mouse clicks. `cy.focused()` yields the currently focused element.

```typescript
it('tab key moves focus through form fields in order', () => {
  cy.visit('/contact');

  // Focus the first field explicitly
  cy.get('[data-cy="name-input"]').focus();
  cy.focused().should('have.attr', 'data-cy', 'name-input');

  // Tab to next field
  cy.focused().tab();  // requires cypress-plugin-tab: npm install cypress-plugin-tab
  cy.focused().should('have.attr', 'data-cy', 'email-input');

  cy.focused().tab();
  cy.focused().should('have.attr', 'data-cy', 'message-textarea');

  cy.focused().tab();
  cy.focused().should('have.attr', 'data-cy', 'submit-button');
});

it('closes modal with Escape key', () => {
  cy.visit('/dashboard');
  cy.get('[data-cy="open-modal-btn"]').click();
  cy.get('[data-cy="modal"]').should('be.visible');

  // Dismiss with keyboard
  cy.get('body').type('{esc}');
  cy.get('[data-cy="modal"]').should('not.exist');

  // Focus should return to the trigger
  cy.focused().should('have.attr', 'data-cy', 'open-modal-btn');
});
```

### 37. Browser Navigation with cy.go() and cy.reload()

Test browser back/forward history and page reload behaviors, especially for SPAs with client-side routing.

```typescript
it('back button navigates to the previous route', () => {
  cy.visit('/products');
  cy.get('[data-cy="product-link"]').first().click();
  cy.location('pathname').should('match', /^\/products\/\d+/);

  // Browser back
  cy.go('back');
  cy.location('pathname').should('eq', '/products');

  // Browser forward
  cy.go('forward');
  cy.location('pathname').should('match', /^\/products\/\d+/);

  // Also accept delta: cy.go(-1) / cy.go(1)
  cy.go(-1);
  cy.location('pathname').should('eq', '/products');
});

it('persists cart after hard reload', () => {
  cy.visit('/cart');
  cy.get('[data-cy="cart-count"]').should('have.text', '2');

  // Hard reload (clears JS state, exercises localStorage/session restore)
  cy.reload(true);  // true = force reload bypassing cache

  cy.get('[data-cy="cart-count"]').should('have.text', '2');
});
```

### 38. Custom Chai Assertions with chai-subset  [community]

Use `chai-subset` to assert that an object *contains* a subset of keys without specifying the full structure — useful for API response bodies with auto-generated fields.

```typescript
// cypress/support/e2e.ts
import chaiSubset from 'chai-subset';
// npm install -D chai-subset @types/chai-subset
chai.use(chaiSubset);

// Usage in a spec
it('API response contains required order fields', () => {
  cy.request('POST', '/api/orders', {
    productId: 'prod_123',
    quantity: 2,
  }).then((response) => {
    expect(response.status).to.eq(201);

    // Assert partial shape — don't specify auto-generated fields
    expect(response.body).to.containSubset({
      status:    'pending',
      productId: 'prod_123',
      quantity:  2,
      user:      { role: 'customer' },
    });

    // orderId, createdAt, etc. can be anything — no assertion needed
    expect(response.body).to.have.property('orderId').that.is.a('string');
  });
});
```

**[community]** WHY: Asserting on the full response body with `deep.equal` couples your test to every auto-generated field (IDs, timestamps, versions). When the server adds a new field, the test breaks despite the behavior being correct. `containSubset` pins only the fields your test cares about.

### 39. cy.title() and cy.hash() Assertions

Use `cy.title()` to assert the document title (important for SEO and accessibility) and `cy.hash()` for URL fragment identifiers used in anchor navigation.

```typescript
it('sets the correct document title per route', () => {
  cy.visit('/');
  cy.title().should('eq', 'Home | Acme Corp');

  cy.visit('/products');
  cy.title().should('include', 'Products');

  cy.get('[data-cy="product-link"]').first().click();
  // Dynamic title includes the product name
  cy.title().should('match', /^.+ \| Acme Corp$/);
});

it('navigates to anchored section via hash link', () => {
  cy.visit('/docs/getting-started');

  cy.get('[data-cy="installation-link"]').click();

  // Assert the hash updated — tests anchor navigation worked
  cy.hash().should('eq', '#installation');

  // Assert the target section is in the viewport
  cy.get('#installation').should('be.visible');

  // Full URL fragment composition via location()
  cy.location().then((loc) => {
    expect(loc.pathname).to.eq('/docs/getting-started');
    expect(loc.hash).to.eq('#installation');
  });
});
```

### 40. cy.contains() with Options for Partial and Case-Insensitive Matching

`cy.contains()` accepts an options object to control timeout, case sensitivity, and shadow DOM traversal — features that aren't obvious from the basic usage.

```typescript
it('finds text content case-insensitively', () => {
  cy.visit('/search-results');

  // Default: case-sensitive
  cy.contains('Search Results').should('be.visible');

  // Case-insensitive match — useful for mixed-case dynamic content
  cy.contains(/search results/i).should('be.visible');  // regex is always case-insensitive

  // Scope to a parent and override timeout
  cy.get('[data-cy="results-container"]').within(() => {
    cy.contains('No results found', { timeout: 15_000 }).should('not.exist');
  });

  // Match inside shadow DOM
  cy.contains('Add to Cart', { includeShadowDom: true }).click();
});

it('distinguishes between multiple matching elements', () => {
  cy.visit('/checkout');

  // cy.contains() returns the FIRST matching element — be explicit about scope
  cy.get('[data-cy="cart-item"]').contains('Remove').first().click();

  // Better: scope to a specific row to avoid matching the wrong "Remove"
  cy.get('[data-cy="cart-item"]').eq(1).contains('Remove').click();
  cy.get('[data-cy="cart-item"]').should('have.length', 1);
});
```

### 41. Testing React Error Boundaries  [community]

Test that error boundaries catch component crashes and render a fallback UI, instead of letting uncaught errors cascade.

```typescript
// Component: <ErrorBoundary fallback={<p data-cy="error-fallback">...</p>}>

it('renders error boundary fallback when child throws', () => {
  // Suppress Cypress uncaught:exception for the intentional throw
  cy.on('uncaught:exception', (err) => {
    if (err.message.includes('Test error boundary')) return false;
    return true;
  });

  // Trigger the error condition (e.g., via a query param that causes the component to throw)
  cy.visit('/product/999?force-error=true');

  // App-level error boundary should catch and render fallback
  cy.get('[data-cy="error-fallback"]').should('be.visible')
    .and('contain.text', 'Something went wrong');

  // The rest of the page should still function
  cy.get('[data-cy="main-nav"]').should('be.visible');
});

// Component test: mount with props that cause a throw
it('ErrorBoundary component catches render error', () => {
  const BrokenChild = () => { throw new Error('Test error boundary'); };

  cy.on('uncaught:exception', () => false);  // suppress for this test

  cy.mount(
    <ErrorBoundary fallback={<p data-cy="error-fallback">Error caught</p>}>
      <BrokenChild />
    </ErrorBoundary>
  );

  cy.get('[data-cy="error-fallback"]').should('have.text', 'Error caught');
});
```

### 42. Suite-Level vs Global Hooks Pattern  [community]

Cypress has three levels of hooks: test-level, suite-level (describe block), and global (support file). Understanding their scope prevents state leakage.

```typescript
// cypress/support/e2e.ts — global hooks run before EVERY test in EVERY spec
beforeEach(() => {
  // Global reset — safe for all tests
  cy.clearAllCookies();
  cy.clearAllLocalStorage();
});

// In a spec — suite-level hooks scope to the describe block
describe('Admin area', () => {
  // Runs once before all tests in this describe — not idempotent, be careful
  before(() => {
    cy.request('POST', '/api/test/seed-admin').then(() => {
      cy.log('Admin data seeded once for the suite');
    });
  });

  // Runs before each test in this describe — idempotent is ideal
  beforeEach(() => {
    loginAsUser('admin@example.com', 'admin-password');
    cy.visit('/admin');
  });

  // Runs once after all tests — cleanup
  after(() => {
    cy.request('DELETE', '/api/test/cleanup-admin');
  });

  it('shows user management panel', () => {
    cy.get('[data-cy="user-mgmt"]').should('be.visible');
  });
});
```

**[community]** WHY: `before()` hooks run once and share state across tests — if a test modifies that state, subsequent tests in the block see the mutated state and become order-dependent. Prefer `beforeEach()` with idempotent setup. Use `before()` only for expensive one-time operations (e.g., seeding a large dataset) where immutability is guaranteed.

### 43. Intercepting GraphQL Operations  [community]

GraphQL sends all operations to a single endpoint (usually `/graphql`). Distinguish between operations by inspecting the request body.

```typescript
// Intercept a specific GraphQL operation by operation name
cy.intercept('POST', '/graphql', (req) => {
  if (req.body.operationName === 'GetUser') {
    req.reply({
      data: {
        user: { id: '1', name: 'Alice', role: 'admin' },
      },
    });
  }
  // All other operations pass through to the real server
}).as('gql');

cy.visit('/profile');

// Wait for the specific operation (body-matched alias)
cy.wait('@gql').its('request.body.operationName').should('eq', 'GetUser');
cy.get('[data-cy="user-name"]').should('have.text', 'Alice');
```

```typescript
// Intercept all GraphQL mutations and assert on variables
cy.intercept('POST', '/graphql', (req) => {
  const { operationName, variables } = req.body as {
    operationName: string;
    variables: Record<string, unknown>;
  };

  if (operationName === 'UpdateProfile') {
    // Validate variables before replying
    expect(variables.input).to.have.property('name').that.is.a('string');
    req.reply({ data: { updateProfile: { success: true } } });
  }
}).as('mutations');

cy.get('[data-cy="save-profile"]').click();
cy.wait('@mutations').its('request.body.variables.input.name').should('not.be.empty');
cy.get('[data-cy="save-success"]').should('be.visible');
```

### 44. cy.window() and cy.document() for App State Access

Access the application's `window` and `document` objects to assert on global state, dispatch custom events, or read DOM properties not exposed via data attributes.

```typescript
it('stores auth token in window.appState', () => {
  cy.visit('/');
  loginAsUser('alice@example.com', 'password');

  // Assert on a property of the app's window object
  cy.window().its('appState.auth.isLoggedIn').should('be.true');
  cy.window().its('appState.auth.userId').should('be.a', 'string');
});

it('dispatches a custom event to trigger app behavior', () => {
  cy.visit('/live-feed');

  // Dispatch a CustomEvent that the app listens for
  cy.window().then((win) => {
    win.dispatchEvent(new win.CustomEvent('newMessage', {
      detail: { id: 'msg_1', text: 'Hello from Cypress', sender: 'Bot' },
    }));
  });

  cy.get('[data-cy="feed-message"]').should('contain', 'Hello from Cypress');
});

it('reads document title and meta description', () => {
  cy.visit('/about');

  cy.document()
    .its('head')
    .find('meta[name="description"]')
    .should('have.attr', 'content')
    .and('not.be.empty');
});
```

### 45. Waiting for Multiple Aliases with cy.wait([])

`cy.wait()` accepts an array of aliases to wait for multiple requests before proceeding. All requests must complete before the assertion continues.

```typescript
it('page loads data from all required endpoints', () => {
  cy.intercept('GET', '/api/user').as('user');
  cy.intercept('GET', '/api/products').as('products');
  cy.intercept('GET', '/api/cart').as('cart');

  cy.visit('/dashboard');

  // Wait for all three requests before asserting — avoids race conditions
  cy.wait(['@user', '@products', '@cart']).spread((userReq, productsReq, cartReq) => {
    expect(userReq.response?.statusCode).to.eq(200);
    expect(productsReq.response?.statusCode).to.eq(200);
    expect(cartReq.response?.statusCode).to.eq(200);
  });

  cy.get('[data-cy="dashboard-loaded"]').should('be.visible');
});

it('retries only failed requests', () => {
  cy.intercept('GET', '/api/slow-data', { delay: 2000, fixture: 'data.json' }).as('slowData');

  cy.visit('/slow-page');

  // Single wait with custom timeout
  cy.wait('@slowData', { timeout: 10_000 })
    .its('response.statusCode')
    .should('eq', 200);
});
```

### 46. Cookie Management — Targeted Clearing vs Bulk  [community]

Use `cy.clearCookie(name)` for surgical cleanup when tests share domain cookies and you only want to remove one specific cookie without disrupting session cookies needed by other test setup.

```typescript
it('cookie management patterns', () => {
  cy.visit('/');

  // Clear a single cookie by name — preserves other session cookies
  cy.clearCookie('preferences');

  // Clear all cookies — full reset, use in global beforeEach
  cy.clearAllCookies();

  // Get and assert on a specific cookie
  cy.getCookie('sessionId').should('have.property', 'httpOnly', true);
  cy.getCookie('sessionId').its('value').should('match', /^[a-f0-9]{32}$/);

  // Get all cookies — useful for debugging
  cy.getCookies().then((cookies) => {
    const secureCookies = cookies.filter(c => c.secure);
    expect(secureCookies).to.have.length.greaterThan(0);
  });

  // Set a cookie for testing consent banners or feature flags
  cy.setCookie('cookie_consent', 'true', {
    httpOnly: false,
    secure: false,
    path: '/',
  });
  cy.visit('/');  // cookie_consent=true prevents banner from showing
  cy.get('[data-cy="cookie-banner"]').should('not.exist');
});
```

**[community]** WHY: Using `cy.clearAllCookies()` in every `beforeEach` is safe but can slow down suites where `cy.session()` manages cookies. If you use `cy.session()`, let it handle cookie management — calling `clearAllCookies()` before session restoration forces a full re-login on every test.

### 47. Timer and Debounce Testing with cy.clock() and cy.tick()

`cy.clock()` freezes all JavaScript timers globally. Use `cy.tick(ms)` to advance time without waiting in real time — essential for testing debounced inputs, auto-dismiss toasts, and polling intervals.

```typescript
it('shows and auto-dismisses toast after 3 seconds', () => {
  cy.clock();  // freeze all timers before visiting
  cy.visit('/dashboard');

  cy.get('[data-cy="trigger-toast"]').click();
  cy.get('[data-cy="toast"]').should('be.visible');

  // Fast-forward 2999 ms — toast should still be visible
  cy.tick(2999);
  cy.get('[data-cy="toast"]').should('be.visible');

  // Fast-forward 1 more ms to reach the 3 second dismiss timeout
  cy.tick(1);
  cy.get('[data-cy="toast"]').should('not.exist');
});

it('debounced search fires after 500ms of inactivity', () => {
  cy.intercept('GET', '/api/search*').as('search');
  cy.clock();
  cy.visit('/search');

  cy.get('[data-cy="search-input"]').type('cypress');

  // No request should fire during typing (debounce delay is 500ms)
  cy.get('@search.all').should('have.length', 0);

  cy.tick(500);  // advance past debounce threshold

  // Now the debounced request should have been sent
  cy.wait('@search').its('request.url').should('include', 'cypress');
});

it('polling interval fires correctly', () => {
  cy.intercept('GET', '/api/status').as('statusPoll');
  cy.clock();
  cy.visit('/monitor');

  // First request fires on mount
  cy.wait('@statusPoll');

  // Advance past the 10-second polling interval
  cy.tick(10_000);
  cy.wait('@statusPoll');  // second poll should have fired

  cy.tick(10_000);
  cy.wait('@statusPoll');  // third poll

  cy.get('@statusPoll.all').should('have.length', 3);
});
```

### 48. Cypress.config() — Runtime Configuration Reading

Read and assert on configuration values at runtime without hardcoding them in specs. Useful for environment-dependent behavior and for feature flags loaded from `cypress.config.ts`.

```typescript
it('uses the correct base URL for the environment', () => {
  // Read config at test time
  const baseUrl = Cypress.config('baseUrl');
  expect(baseUrl).to.not.be.empty;

  cy.visit('/');
  cy.location('origin').should('eq', baseUrl?.replace(/\/$/, ''));
});

it('skips visual assertions on short timeouts', () => {
  const timeout = Cypress.config('defaultCommandTimeout');

  // Skip slow assertions in environments with tight timeouts
  if (timeout < 5000) {
    cy.log('Skipping visual regression in short-timeout environment');
    return;
  }

  cy.visit('/landing');
  cy.percySnapshot('Landing page');
});

// Safe cy.pause() guard — only pauses in interactive (non-CI) mode
const safePause = () => {
  if (!Cypress.config('isInteractive') || Cypress.env('CI')) return;
  cy.pause();
};

it('debugs a complex interaction', () => {
  cy.visit('/checkout');
  cy.get('[data-cy="step-1"]').click();
  safePause();  // pauses in cy:open, no-ops in cy:run
  cy.get('[data-cy="step-2"]').should('be.visible');
});
```

### 49. Download Testing — Asserting on Downloaded Files

Test that file downloads produce the expected file in the downloads folder.

```typescript
// cypress.config.ts — configure downloads folder
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    downloadsFolder: 'cypress/downloads',
    // Clear downloads folder before each run via task
    setupNodeEvents(on) {
      on('before:run', async () => {
        const path = require('path');
        const fs = require('fs');
        const folder = path.join(process.cwd(), 'cypress/downloads');
        if (fs.existsSync(folder)) {
          fs.readdirSync(folder).forEach((f: string) =>
            fs.unlinkSync(path.join(folder, f))
          );
        }
      });
    },
  },
});

// In a spec — trigger download and assert on file
it('downloads a PDF invoice', () => {
  cy.visit('/orders/123');

  cy.get('[data-cy="download-invoice"]').click();

  // Wait up to 15 s for the file to appear in downloads folder
  cy.readFile('cypress/downloads/invoice-123.pdf', 'binary', { timeout: 15_000 })
    .should('have.length.gt', 0);  // non-empty binary
});

it('downloads and validates CSV content', () => {
  cy.visit('/reports');
  cy.get('[data-cy="export-csv"]').click();

  cy.readFile('cypress/downloads/report.csv', { timeout: 15_000 })
    .then((content: string) => {
      const rows = content.trim().split('\n');
      expect(rows[0]).to.eq('id,name,date,amount');  // header row
      expect(rows.length).to.be.gt(1);               // at least one data row
    });
});
```

### 50. cy.intercept() with `times` Option

The `times` option limits how many requests an intercept stub matches, then lets subsequent requests through to the real server. Useful for testing retry logic.

```typescript
it('shows error then recovers when API is temporarily unavailable', () => {
  // First request fails, subsequent requests succeed
  cy.intercept('GET', '/api/data', { statusCode: 503 }, { times: 1 }).as('firstAttempt');
  cy.intercept('GET', '/api/data', { fixture: 'data.json' }).as('retry');

  cy.visit('/data-page');

  // App should show error on first load attempt
  cy.wait('@firstAttempt');
  cy.get('[data-cy="error-state"]').should('be.visible');

  // Trigger manual retry
  cy.get('[data-cy="retry-btn"]').click();

  // Second request goes through to the real stub (fixture)
  cy.wait('@retry');
  cy.get('[data-cy="data-list"]').should('be.visible');
});

it('intercepts only the first two paginated requests', () => {
  cy.intercept('GET', '/api/items?page=*', { fixture: 'items-page1.json' }, { times: 2 }).as('pages');

  cy.visit('/items');
  cy.get('[data-cy="load-more"]').click();
  cy.wait('@pages.all').should('have.length', 2);

  // Third page load goes to the real server
  cy.get('[data-cy="load-more"]').click();
  cy.get('[data-cy="item-list"]').should('have.length.gt', 0);
});
```

### 51. Conditional Logic Anti-Pattern — The Correct Approach  [community]

Cypress's retry-ability conflicts with conditional logic. The pattern `if (cy.get(...).length)` does not work because `cy.get()` returns a Chainable, not a DOM element. Here is the correct approach for handling optional UI elements.

```typescript
// ❌ Anti-pattern — cy.get() always returns a Chainable (never falsy)
if (cy.get('[data-cy="cookie-banner"]')) {
  cy.get('[data-cy="accept-cookies"]').click();
}

// ✅ Correct — use .then() with jQuery to check synchronous DOM state
cy.get('body').then(($body) => {
  if ($body.find('[data-cy="cookie-banner"]').length > 0) {
    cy.get('[data-cy="accept-cookies"]').click();
  }
});

// ✅ Better — set the state deterministically before the test
// (e.g., set a cookie so the banner never shows in tests)
beforeEach(() => {
  cy.setCookie('cookie_consent', 'accepted');
});

// ✅ For truly optional UI, use cy.get().then() with jQuery length
const dismissBannerIfPresent = () => {
  cy.get('body').then(($body) => {
    if ($body.find('[data-cy="promo-modal"]').length) {
      cy.get('[data-cy="close-modal"]').click();
      cy.get('[data-cy="promo-modal"]').should('not.exist');
    }
  });
};
```

**[community]** WHY: Using `.then()` with jQuery gives you a synchronous snapshot of the DOM at the moment the command executes. This is the only safe way to do conditional UI branching. The trade-off is that the snapshot may be stale if the UI changes after the `.then()` fires — prefer deterministic state setup over conditional checks wherever possible.

### 52. Asserting with .should(callback) for Complex Conditions

Use `.should(callback)` when you need to assert on multiple properties of a subject or express conditions that the built-in assertion matchers can't represent.

```typescript
it('validates complex form state', () => {
  cy.visit('/checkout');
  cy.get('[data-cy="payment-summary"]').should(($el) => {
    // Multiple assertions on the same element — all retry together
    expect($el).to.be.visible;
    expect($el.find('[data-cy="subtotal"]').text()).to.match(/^\$[\d.]+$/);
    expect($el.find('[data-cy="total"]').text()).to.not.equal('$0.00');
    expect(Number($el.find('[data-cy="total"]').text().replace('$', ''))).to.be.gt(0);
  });
});

it('validates list item states', () => {
  cy.visit('/tasks');
  cy.get('[data-cy="task-list"]').should(($list) => {
    const items = $list.find('[data-cy="task-item"]');
    expect(items.length).to.be.gte(3);

    const completedItems = items.filter('.completed');
    const pendingItems  = items.not('.completed');

    // At least one of each type
    expect(completedItems.length).to.be.gte(1);
    expect(pendingItems.length).to.be.gte(1);
  });
});
```

### 53. Filtering Collections with .filter() and .not()

Use `.filter()` and `.not()` to narrow down a jQuery collection to elements matching a CSS selector, then assert or interact with the filtered set.

```typescript
it('can select multiple items and only selected items get highlighted', () => {
  cy.visit('/selectable-list');

  // Click specific items
  cy.get('[data-cy="list-item"]').eq(0).click();
  cy.get('[data-cy="list-item"]').eq(2).click();

  // Assert exactly 2 items are selected
  cy.get('[data-cy="list-item"]').filter('.selected').should('have.length', 2);

  // Assert the non-selected items don't have the class
  cy.get('[data-cy="list-item"]').not('.selected').should('have.length.gt', 0)
    .each(($item) => {
      expect($item).to.not.have.class('selected');
    });
});

it('bulk action applies only to filtered items', () => {
  cy.visit('/user-list');

  // Filter visible, active users (those with both classes)
  cy.get('[data-cy="user-row"]')
    .filter('.active')
    .filter(':visible')
    .should('have.length.gte', 1)
    .first()
    .find('[data-cy="checkbox"]')
    .check();

  cy.get('[data-cy="bulk-deactivate"]').click();
  cy.get('[data-cy="user-row"].active').should('have.length.lt', 3);
});
```

### 54. experimentalModifyObstructiveThirdPartyCode for Embedded Widgets  [community]

When testing pages with third-party embedded scripts (analytics, chat widgets, payment iframes) that inject code breaking Cypress's injection mechanism, enable this flag.

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    // Modifies third-party code that prevents Cypress from loading
    // Required for some Stripe, Intercom, Salesforce, or HubSpot widgets
    experimentalModifyObstructiveThirdPartyCode: true,
    // Pair with a list of allowed 3rd-party domains for network policy
    // blockHosts: ['analytics.example.com']  // optional: block analytics to speed up tests
  },
});
```

**[community]** WHY: Third-party scripts sometimes detect iframe embedding (Cypress runs tests in an iframe) and throw errors or redirect the page. `experimentalModifyObstructiveThirdPartyCode` patches these checks at the network level. The downside is that it may modify scripts in unexpected ways — test thoroughly after enabling, and disable for specs that don't need it by using per-spec config overrides.

### 55. LocalStorage and SessionStorage Testing  [community]

Read and assert on values the application stores in `localStorage` and `sessionStorage`, and seed state before tests to avoid going through the full UI flow.

```typescript
it('persists user preferences to localStorage', () => {
  cy.visit('/settings');
  cy.get('[data-cy="theme-toggle"]').click();

  // Assert the app wrote the correct value
  cy.window().then((win) => {
    expect(win.localStorage.getItem('theme')).to.eq('dark');
  });

  // Shorter: use cy.getAllLocalStorage() (Cypress 12+)
  cy.getAllLocalStorage().then((storage) => {
    // storage is { [origin]: { [key]: value } }
    const appStorage = storage[window.location.origin] ?? {};
    expect(appStorage['theme']).to.eq('dark');
  });
});

// Seed localStorage before visiting — skip UI setup flow
beforeEach(() => {
  // Set app state as if the user is already logged in
  cy.window().then((win) => {
    win.localStorage.setItem('auth_token', 'test-jwt-token');
    win.localStorage.setItem('user_id', 'usr_test_123');
  });
  // Alternative: use cy.visit() with onBeforeLoad callback
  cy.visit('/dashboard', {
    onBeforeLoad(win) {
      win.localStorage.setItem('feature_flag_new_ui', 'true');
    },
  });
});

it('clears cart from localStorage on checkout completion', () => {
  cy.window().then((win) => {
    win.localStorage.setItem('cart', JSON.stringify([{ id: 1, qty: 2 }]));
  });
  cy.visit('/checkout');
  cy.get('[data-cy="complete-order"]').click();
  cy.get('[data-cy="order-confirmation"]').should('be.visible');

  cy.window().its('localStorage').invoke('getItem', 'cart').should('be.null');
});
```

### 56. DOM Traversal — find(), closest(), siblings

Use Cypress's jQuery-based traversal commands to navigate the DOM tree in relation to a found element.

```typescript
it('traverses DOM to assert on related elements', () => {
  cy.visit('/table-view');

  // .find() — search descendants of the subject
  cy.get('[data-cy="orders-table"]').find('tbody tr').should('have.length.gte', 1);

  // .closest() — walk up the DOM to the nearest matching ancestor
  cy.get('[data-cy="delete-btn"]').first().closest('tr').within(() => {
    cy.get('[data-cy="order-id"]').invoke('text').then((id) => {
      cy.log(`Deleting order: ${id}`);
    });
  });

  // .siblings() — get elements at the same DOM level
  cy.get('[data-cy="active-tab"]').siblings('[data-cy="tab"]').should('not.have.class', 'active');

  // .parent() — one level up
  cy.get('[data-cy="error-message"]')
    .parent('[data-cy="form-field"]')
    .should('have.class', 'has-error');

  // .children() — direct children only (not descendants)
  cy.get('[data-cy="nav-menu"]')
    .children('[data-cy="nav-item"]')
    .should('have.length', 5);
});
```

### 57. Lodash Utilities via Cypress._  [community]

Cypress bundles Lodash as `Cypress._`. Use it for sorting, grouping, and transforming test data in `.then()` callbacks without importing a separate lodash package.

```typescript
it('validates sorted and unique product list', () => {
  cy.request('/api/products').then((response) => {
    const products = response.body as Array<{ id: number; name: string; price: number }>;

    // Use Cypress._ (Lodash) for data manipulation
    const prices       = Cypress._.map(products, 'price');
    const uniquePrices = Cypress._.uniq(prices);
    const sortedNames  = Cypress._.sortBy(products, 'name').map(p => p.name);

    // All prices must be positive and unique
    expect(prices.every((p) => p > 0)).to.be.true;
    expect(uniquePrices).to.have.length(prices.length);

    // Names must be in ascending alphabetical order
    const productNames = products.map((p) => p.name);
    expect(productNames).to.deep.eq(sortedNames);
  });
});

it('groups API results for table row count assertion', () => {
  cy.request('/api/orders').then((response) => {
    const orders = response.body as Array<{ status: string; amount: number }>;

    const byStatus = Cypress._.groupBy(orders, 'status');
    const pendingCount = (byStatus['pending'] ?? []).length;

    cy.visit('/orders');
    cy.get('[data-cy="status-filter"]').select('pending');
    cy.get('[data-cy="order-row"]').should('have.length', pendingCount);
  });
});
```

### 58. Spec-Level Configuration Overrides

Override specific `cypress.config.ts` values per-spec or per-test using the `{ config: {...} }` syntax on `describe` or `it` blocks.

```typescript
// Increase timeout only for this describe block (slow integration tests)
describe('Third-party payment integration', { defaultCommandTimeout: 20_000, requestTimeout: 30_000 }, () => {
  it('completes payment with real Stripe test card', () => {
    cy.visit('/checkout');
    // ... payment flow through real Stripe
  });
});

// Disable retry for a suite that must not mask first-run failures
describe('Data integrity assertions', { retries: 0 }, () => {
  it('database write is idempotent', () => {
    cy.request('POST', '/api/data', { key: 'test' });
    cy.request('POST', '/api/data', { key: 'test' });
    cy.request('GET', '/api/data?key=test').its('body').should('have.length', 1);
  });
});

// Override viewport just for one test
it('renders correctly on 4K display', { viewportWidth: 3840, viewportHeight: 2160 }, () => {
  cy.visit('/dashboard');
  cy.get('[data-cy="grid-layout"]').should('be.visible');
});
```

### 59. Multi-Step Wizard Testing Pattern  [community]

Test multi-step forms and wizards by asserting on each step's state before advancing. Use `cy.session()` to bypass early steps in tests that focus on later steps.

```typescript
// Helper: complete step 1 (personal info) — used by tests focused on step 2+
const completeStep1 = () => {
  cy.get('[data-cy="first-name"]').type('Alice');
  cy.get('[data-cy="last-name"]').type('Smith');
  cy.get('[data-cy="email"]').type('alice@example.com');
  cy.get('[data-cy="next-btn"]').click();
  cy.get('[data-cy="step-2-heading"]').should('be.visible');
};

describe('Registration wizard', () => {
  beforeEach(() => {
    cy.visit('/register');
    cy.get('[data-cy="step-1-heading"]').should('be.visible');
  });

  it('step 1: validates required fields', () => {
    cy.get('[data-cy="next-btn"]').click();
    cy.get('[data-cy="first-name-error"]').should('contain.text', 'Required');
    cy.get('[data-cy="email-error"]').should('contain.text', 'Required');
    cy.location('pathname').should('eq', '/register');  // did not advance
  });

  it('step 2: plan selection', () => {
    completeStep1();

    // Assert step 2 UI
    cy.get('[data-cy="plan-card"]').should('have.length', 3);
    cy.get('[data-cy="plan-card"]').contains('Pro').click();
    cy.get('[data-cy="selected-plan"]').should('contain.text', 'Pro');

    cy.get('[data-cy="next-btn"]').click();
    cy.get('[data-cy="step-3-heading"]').should('be.visible');
  });

  it('back button returns to previous step without losing data', () => {
    completeStep1();
    cy.get('[data-cy="plan-card"]').contains('Pro').click();
    cy.get('[data-cy="back-btn"]').click();

    // Step 1 fields should still be populated
    cy.get('[data-cy="step-1-heading"]').should('be.visible');
    cy.get('[data-cy="email"]').should('have.value', 'alice@example.com');
  });
});
```

### 60. Keyboard Shortcuts and Modifier Keys

Cypress's `.type()` supports special key sequences. Test keyboard shortcuts and accessibility using the `{key}` syntax.

```typescript
it('Ctrl+S saves the document', () => {
  cy.visit('/editor');
  cy.get('[data-cy="editor-content"]').type('New document content');

  // Trigger keyboard shortcut — Ctrl+S
  cy.get('[data-cy="editor-content"]').type('{ctrl}s');

  cy.get('[data-cy="save-indicator"]').should('have.text', 'Saved');
  cy.get('[data-cy="last-saved-time"]').should('not.be.empty');
});

it('arrow keys navigate the dropdown menu', () => {
  cy.visit('/search');
  cy.get('[data-cy="search-input"]').type('cypress');
  cy.get('[data-cy="dropdown-item"]').should('have.length.gte', 3);

  // Navigate with arrow keys
  cy.get('[data-cy="search-input"]').type('{downarrow}');
  cy.get('[data-cy="dropdown-item"]').first().should('have.class', 'focused');

  cy.get('[data-cy="search-input"]').type('{downarrow}');
  cy.get('[data-cy="dropdown-item"]').eq(1).should('have.class', 'focused');

  // Select with Enter
  cy.get('[data-cy="search-input"]').type('{enter}');
  cy.location('pathname').should('include', '/results');
});

it('select all and replace text', () => {
  cy.visit('/notes');
  cy.get('[data-cy="note-editor"]').type('Old text');

  // Select all and replace
  cy.get('[data-cy="note-editor"]')
    .type('{selectAll}')
    .type('Replacement text');

  cy.get('[data-cy="note-editor"]').should('have.value', 'Replacement text');
});
```

### 61. cy.request() with Form Data and File Uploads

`cy.request()` supports `multipart/form-data` for testing file upload APIs directly, bypassing the UI.

```typescript
it('uploads a file via the API directly', () => {
  const formData = new FormData();
  formData.append('name', 'test-upload.csv');

  // Read a fixture file as binary and append to FormData
  cy.fixture('sample.csv', 'binary').then((fileContent) => {
    const blob = Cypress.Blob.binaryStringToBlob(fileContent, 'text/csv');
    formData.append('file', blob, 'sample.csv');
  });

  cy.request({
    method: 'POST',
    url: '/api/upload',
    headers: {
      Authorization: `Bearer ${Cypress.env('API_TOKEN')}`,
      // Note: do NOT set Content-Type here — the browser sets it with the boundary
    },
    body: formData,
  }).then((response) => {
    expect(response.status).to.eq(201);
    expect(response.body).to.have.property('fileId').that.is.a('string');
  });
});

it('tests a multipart form submission', () => {
  cy.request({
    method: 'POST',
    url: '/api/profile',
    headers: { Authorization: `Bearer ${Cypress.env('API_TOKEN')}` },
    form: true,  // Sets Content-Type: application/x-www-form-urlencoded
    body: {
      displayName: 'Alice Smith',
      bio: 'QA Engineer',
      timezone: 'UTC+1',
    },
  }).its('status').should('eq', 200);
});
```

### 62. Cypress Cloud Smart Orchestration  [community]

Smart Orchestration is a Cypress Cloud feature that reorders spec execution based on historical failure rates and durations to find failures faster and balance load across parallel machines.

```yaml
# .github/workflows/e2e.yml — enable Smart Orchestration features
- name: Run Cypress with Smart Orchestration
  run: npx cypress run
    --record
    --parallel
    --ci-build-id "${{ github.run_id }}"
    # Smart Orchestration flags (enabled automatically when --record is used with Cypress Cloud)
    # --auto-cancel-after-failures N  # Cancel the run after N test failures across all machines
  env:
    CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
```

```typescript
// cypress.config.ts — configure auto-cancel on failures
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    // Cancel the entire parallel run after this many test failures
    // Reduces CI costs by stopping machines early on catastrophic failures
    // (configured via Cypress Cloud project settings, not config file)
    retries: { runMode: 1, openMode: 0 },
    // Cypress Cloud also supports spec-level flakiness detection:
    // failed tests that pass on retry are flagged as "flaky"
  },
});
```

**[community]** WHY: Without Smart Orchestration, Cypress distributes specs evenly but doesn't consider which specs fail most often. Smart Orchestration runs historically-failing specs first, so CI gets feedback about known-problematic areas in the first few minutes rather than at the end of a 30-minute run.

### 63. Form Control Commands — check(), uncheck(), select()

Use the purpose-built form commands for checkboxes, radio buttons, and `<select>` elements. They are more readable and handle accessibility attributes correctly.

```typescript
it('manages form controls with type-specific commands', () => {
  cy.visit('/profile-settings');

  // Checkbox — check() / uncheck() are more readable than .click()
  cy.get('[data-cy="notifications-email"]').check();
  cy.get('[data-cy="notifications-email"]').should('be.checked');

  cy.get('[data-cy="notifications-sms"]').uncheck();
  cy.get('[data-cy="notifications-sms"]').should('not.be.checked');

  // Check multiple checkboxes by value
  cy.get('[data-cy="interest-checkbox"]').check(['coding', 'testing', 'devops']);
  cy.get('[data-cy="interest-checkbox"]:checked').should('have.length', 3);

  // Select — by visible text, value, or index
  cy.get('[data-cy="timezone-select"]').select('UTC+1');
  cy.get('[data-cy="timezone-select"]').should('have.value', 'Europe/Berlin');

  cy.get('[data-cy="language-select"]').select(0);  // select by index
  cy.get('[data-cy="language-select"]').invoke('val').should('not.be.empty');

  // Multi-select
  cy.get('[data-cy="tags-multi-select"]').select(['javascript', 'typescript', 'react']);
  cy.get('[data-cy="tags-multi-select"]').invoke('val').should('deep.eq', ['javascript', 'typescript', 'react']);
});

it('radio button selection', () => {
  cy.visit('/payment');

  cy.get('[data-cy="payment-method"]').check('credit_card');
  cy.get('[data-cy="payment-method"]:checked').should('have.value', 'credit_card');
  cy.get('[data-cy="credit-card-form"]').should('be.visible');

  cy.get('[data-cy="payment-method"]').check('paypal');
  cy.get('[data-cy="paypal-form"]').should('be.visible');
  cy.get('[data-cy="credit-card-form"]').should('not.exist');
});
```

### 64. Stubbing window.open() and window.print()  [community]

Third-party links and print dialogs open new windows or tabs, which Cypress cannot control. Stub these methods to prevent the browser from opening windows and assert that they were called.

```typescript
it('opens terms and conditions in a new tab', () => {
  cy.visit('/register');

  // Stub window.open before the test triggers it
  cy.window().then((win) => {
    cy.stub(win, 'open').as('windowOpen');
  });

  cy.get('[data-cy="terms-link"]').click();

  // Assert window.open was called with the correct URL
  cy.get('@windowOpen').should('have.been.calledOnce')
    .and('have.been.calledWith', '/terms-and-conditions', '_blank');
});

it('triggers print dialog on invoice page', () => {
  cy.visit('/invoice/123');

  cy.window().then((win) => {
    cy.stub(win, 'print').as('printDialog');
  });

  cy.get('[data-cy="print-invoice"]').click();

  cy.get('@printDialog').should('have.been.calledOnce');
});

it('prevents navigation to external URL (stub href redirect)', () => {
  cy.visit('/dashboard');

  // Intercept navigation to external site
  cy.window().then((win) => {
    cy.stub(win.location, 'assign').as('locationAssign');
  });

  cy.get('[data-cy="external-link"]').click();

  cy.get('@locationAssign').should('have.been.calledWithMatch',
    sinon.match(/^https:\/\/external\.example\.com/)
  );
});
```

### 65. Slow Typing Simulation for Input Validation  [community]

Use the `delay` option in `.type()` to simulate a user typing slowly. This is useful for testing real-time validation that fires on each keypress, debounced search inputs, and character counters.

```typescript
it('character counter updates as user types', () => {
  cy.visit('/compose');
  cy.get('[data-cy="tweet-input"]').type('Hello Cypress!', { delay: 50 });

  // Counter should update in real time
  cy.get('[data-cy="char-count"]').should('have.text', '14');

  // Test the limit
  cy.get('[data-cy="tweet-input"]')
    .clear()
    .type('x'.repeat(280), { delay: 0 });  // delay: 0 for fast filling at the limit

  cy.get('[data-cy="char-count"]').should('have.text', '280');
  cy.get('[data-cy="char-count"]').should('have.class', 'limit-reached');
  cy.get('[data-cy="submit-btn"]').should('be.disabled');
});

it('shows real-time email validation on each keystroke', () => {
  cy.visit('/register');
  cy.get('[data-cy="email-input"]').type('not-an-email', { delay: 80 });
  cy.get('[data-cy="email-error"]').should('be.visible');

  cy.get('[data-cy="email-input"]').type('@domain.com', { delay: 80 });
  cy.get('[data-cy="email-error"]').should('not.exist');
});
```

### 66. Dynamic Intercept Aliasing with req.alias  [community]

Assign aliases dynamically within an intercept handler based on request content. This allows a single intercept to handle multiple operation types and still provide named aliases for assertions.

```typescript
// Single intercept, multiple dynamic aliases by operation
cy.intercept('POST', '/api/**', (req) => {
  const path = new URL(req.url).pathname;

  if (path.includes('/users')) {
    req.alias = 'createUser';
  } else if (path.includes('/orders')) {
    req.alias = 'createOrder';
  } else if (path.includes('/payments')) {
    req.alias = 'processPayment';
  }
  // All requests continue to real server — no req.reply()
});

cy.visit('/checkout');
cy.get('[data-cy="complete-order"]').click();

// Wait on the dynamically assigned aliases in sequence
cy.wait('@createOrder').its('response.statusCode').should('eq', 201);
cy.wait('@processPayment').its('response.body.status').should('eq', 'succeeded');
cy.get('[data-cy="confirmation-number"]').should('be.visible');

// Combining times + req.alias: intercept the first request dynamically, pass rest through
cy.intercept('GET', '/api/products*', (req) => {
  const page = new URL(req.url).searchParams.get('page') ?? '1';
  req.alias = `productsPage${page}`;
  if (page === '1') {
    req.reply({ fixture: 'products-page1.json' });
  }
  // Pages 2+ hit the real server
});

cy.visit('/products');
cy.wait('@productsPage1').its('response.body.items').should('have.length', 20);

cy.get('[data-cy="next-page"]').click();
// Page 2 goes to real server — no stub
cy.get('[data-cy="product-list"]').should('be.visible');
```

### 67. Angular Component Testing

Cypress Component Testing works with Angular via the Angular DevKit bundler. Mount Angular components with `TestBed`-style inputs/outputs.

```typescript
// button.cy.ts — Angular component test
import { ButtonComponent } from './button.component';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('ButtonComponent', () => {
  it('emits click event when clicked', () => {
    cy.mount(ButtonComponent, {
      componentProperties: {
        label: 'Save',
        disabled: false,
      },
    });
    cy.get('[data-cy="btn"]').should('have.text', 'Save');
    cy.get('[data-cy="btn"]').click();
    cy.get('@clickedSpy').should('have.been.calledOnce');
  });

  it('is disabled when disabled input is true', () => {
    cy.mount(ButtonComponent, {
      componentProperties: { label: 'Disabled', disabled: true },
    });
    cy.get('[data-cy="btn"]').should('be.disabled');
  });
});
```

```typescript
// cypress.config.ts — Angular component config
import { defineConfig } from 'cypress';

export default defineConfig({
  component: {
    devServer: {
      framework: 'angular',
      bundler: 'webpack',
    },
    specPattern: '**/*.cy.ts',
  },
});
```

**[community]** WHY: Angular components often require `NgModule` providers (services, HTTP clients, router). Use `imports` / `providers` in the mount options rather than a separate test module — this mirrors how the component is bootstrapped in production and keeps the test close to real behaviour.

### 67b. Next.js Component Testing — Router Mock  [community]

Next.js components that use `useRouter()` need the router to be mocked. For App Router components, use `MemoryRouterProvider` from `next-router-mock`.

```typescript
// npm install --save-dev next-router-mock
// cypress/support/component.tsx — custom mount with Next.js router mock

import React from 'react';
import { mount } from 'cypress/react';
import MemoryRouterProvider from 'next-router-mock/dist/MemoryRouterProvider';

// Override cy.mount() with Next.js router mock provider
Cypress.Commands.overwrite('mount', (originalFn, component, options = {}) => {
  const { routerOptions = {}, ...restOptions } = options as any;

  const wrapped = (
    <MemoryRouterProvider
      url={routerOptions.pathname ?? '/'}
      query={routerOptions.query}
    >
      {component}
    </MemoryRouterProvider>
  );

  return originalFn(wrapped, restOptions);
});

// In a spec — mount a Next.js Page Router component
import { ProductPage } from '../../src/pages/products/[id]';

it('renders product page with mocked router', () => {
  cy.mount(<ProductPage product={{ id: '123', name: 'Widget', price: 9.99 }} />, {
    routerOptions: {
      pathname: '/products/123',
      query: { id: '123' },
    },
  });

  cy.get('[data-cy="product-name"]').should('have.text', 'Widget');
  cy.get('[data-cy="product-price"]').should('have.text', '$9.99');
});

// App Router (Next.js 13+): use the server components testing pattern
// Next.js App Router server components require a different approach:
// - Use cy.visit() for server component integration tests (not cy.mount())
// - cy.mount() is for Client Components only
```

**[community]** WHY: `useRouter()` from `next/navigation` and `next/router` throws when called outside a Next.js provider. Wrapping with `MemoryRouterProvider` allows components to read `router.pathname`, `router.query`, and call `router.push()` without the full Next.js runtime. For App Router server components, there is no `cy.mount()` equivalent — use `cy.visit()` with a local Next.js dev server instead.



Use `cy.request()` to build a pure API test suite that validates backend contracts independently of the UI. This is faster than E2E tests and catches API regressions without a running frontend.

```typescript
// cypress/e2e/api/users.api.cy.ts — standalone API tests
describe('Users API', () => {
  let authToken: string;

  before(() => {
    // Authenticate once for the entire suite
    cy.request('POST', '/api/auth/login', {
      email: Cypress.env('API_USER'),
      password: Cypress.env('API_PASS'),
    }).then((res) => {
      expect(res.status).to.eq(200);
      authToken = res.body.token;
    });
  });

  it('GET /api/users — returns paginated list', () => {
    cy.request({
      method: 'GET',
      url: '/api/users?page=1&limit=10',
      auth: { bearer: authToken },
    }).then((res) => {
      expect(res.status).to.eq(200);
      expect(res.body).to.have.all.keys('data', 'total', 'page', 'limit');
      expect(res.body.data).to.be.an('array').with.length.lte(10);
      res.body.data.forEach((user: { id: string; email: string; role: string }) => {
        expect(user).to.have.property('id').that.is.a('string');
        expect(user).to.have.property('email').that.matches(/@/);
        expect(['admin', 'user', 'viewer']).to.include(user.role);
      });
    });
  });

  it('POST /api/users — creates a user and returns 201 with location header', () => {
    cy.request({
      method: 'POST',
      url: '/api/users',
      auth: { bearer: authToken },
      body: { name: 'API Test User', email: `api-test-${Date.now()}@example.com`, role: 'user' },
      failOnStatusCode: false,
    }).then((res) => {
      expect(res.status).to.eq(201);
      expect(res.headers).to.have.property('location').that.matches(/\/api\/users\//);
      expect(res.body).to.have.property('id').that.is.a('string');

      // Cleanup — delete the created user
      const userId = res.body.id;
      cy.request({ method: 'DELETE', url: `/api/users/${userId}`, auth: { bearer: authToken } })
        .its('status').should('eq', 204);
    });
  });

  it('DELETE /api/users/:id — returns 404 for non-existent user', () => {
    cy.request({
      method: 'DELETE',
      url: '/api/users/non-existent-id',
      auth: { bearer: authToken },
      failOnStatusCode: false,
    }).its('status').should('eq', 404);
  });
});
```

### 69. cy.intercept() Body Matching for JSON APIs  [community]

Match intercepts against the request body using the `body` property of the routeMatcher. Useful for distinguishing between calls to the same endpoint with different payloads (e.g., create vs update, or GraphQL operations without `operationName`).

```typescript
// Match POST /api/items only when body contains specific field values
cy.intercept({
  method: 'POST',
  url: '/api/items',
  body: {
    type: 'task',           // exact match on type field
    priority: 'high',
  },
}, {
  statusCode: 201,
  body: { id: 'task_001', type: 'task', priority: 'high', title: 'Mocked Task' },
}).as('createHighPriorityTask');

// Different stub for low-priority — same URL, different body
cy.intercept({
  method: 'POST',
  url: '/api/items',
  body: { type: 'task', priority: 'low' },
}, { statusCode: 201, body: { id: 'task_002', type: 'task', priority: 'low' } }).as('createLowPriorityTask');

// Partial body matching using a RegExp or minimatch pattern on body fields
cy.intercept({
  method: 'POST',
  url: '/api/search',
  body: { query: /^cypress/i },  // body.query starts with "cypress" (case-insensitive)
}, { fixture: 'search-results.json' }).as('cypressSearch');

cy.visit('/items');
cy.get('[data-cy="priority-select"]').select('high');
cy.get('[data-cy="add-item"]').click();
cy.wait('@createHighPriorityTask').its('request.body.priority').should('eq', 'high');
```

**[community]** WHY: Without body matching, a single `cy.intercept('POST', '/api/items')` catches ALL item creation calls regardless of payload. When the test creates both high and low priority items, the last registered stub wins for all calls, potentially hiding assertion failures where the wrong stub response was used. Use body matching to route each request to its correct stub.

### 70. cy.stub().callsFake() and callsArg() Patterns  [community]

Use `callsFake()` to replace a stubbed function with a custom implementation and `callsArg()` to invoke one of the stub's arguments as a callback — both are essential for testing callback-driven APIs and complex async patterns.

```typescript
it('uses callsFake() to control stub behavior dynamically', () => {
  let callCount = 0;
  const fetchStub = cy.stub(window, 'fetch').callsFake(async (url: string) => {
    callCount += 1;
    if (callCount === 1) {
      // First call: return error to test retry logic
      return new Response('Service Unavailable', { status: 503 });
    }
    // Subsequent calls: return success
    return new Response(JSON.stringify({ data: 'result' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  });

  cy.visit('/data-page');
  cy.get('[data-cy="retry-btn"]').click();
  cy.get('[data-cy="data-content"]').should('contain', 'result');

  // The stub was called twice (initial + retry)
  cy.wrap(fetchStub).should('have.been.calledTwice');
});

it('uses callsArg() to invoke a callback argument', () => {
  // Stub a function that accepts a callback as its second argument
  cy.stub(window, 'requestAnimationFrame').callsArg(0).as('raf');

  cy.visit('/animated-counter');
  cy.get('[data-cy="start-animation"]').click();

  // requestAnimationFrame callback was invoked synchronously by the stub
  cy.get('[data-cy="counter"]').should('have.text', '1');
  cy.get('@raf').should('have.been.called');
});

it('uses stub.withArgs() for argument-conditional behavior', () => {
  const logStub = cy.stub(console, 'log').as('consoleLog');

  // .withArgs() creates a conditional sub-stub — only matches specific args
  logStub.withArgs(sinon.match.string).returns(undefined);

  cy.visit('/logger');
  cy.get('[data-cy="log-message"]').click();

  // Assert that the stub was called with a string argument
  cy.get('@consoleLog').should('have.been.calledWithMatch', sinon.match.string);
});
```

**[community]** WHY: `cy.stub(fn).returns(value)` is too coarse for functions that need to behave differently across multiple calls. `callsFake()` gives you full control over the implementation, letting you simulate retry sequences, progressive loading states, or random failures without modifying application code. `callsArg(n)` is critical for testing callback-driven patterns (timers, event handlers, legacy Node-style callbacks) without real async overhead.

### 71. Cypress 14 Breaking Changes and Upgrade Notes

Cypress 14 (released 2025) introduced several breaking changes teams should address during upgrade:

```typescript
// BREAKING: cy.origin() now requires experimentalOriginDependencies: true
// to use custom commands inside origin callbacks
// cypress.config.ts
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    experimentalOriginDependencies: true,  // required since Cy 14 for custom cmds in cy.origin()
  },
});

// BREAKING: Module support in cy.origin() — import statements now work
it('uses imports inside cy.origin()', () => {
  cy.origin('https://auth.example.com', () => {
    // In Cy 14, ESM imports are supported inside cy.origin() callbacks
    const { loginHelper } = require('../support/auth');  // CommonJS still works
    loginHelper();
  });
});
```

```typescript
// BREAKING: Component Testing — React 18 concurrent mode fully supported
// Cy 14 dropped React 16/17 component testing support (removed in Cy 12 for CT)
// Vue 2 component testing is no longer supported; use Vue 3

// MIGRATION: test retries config moved to per-project level
// OLD (Cy 13): { retries: { runMode: 2, openMode: 0 } }
// NEW (Cy 14): retries can be set per-project in multi-project configs
import { defineConfig } from 'cypress';
export default defineConfig({
  e2e: {
    retries: {
      runMode: 2,    // CI: retry twice on failure
      openMode: 0,   // local: never retry (fail fast for developers)
      experimentalStrategy: 'detect-flake-and-pass-on-threshold',
      experimentalOptions: {
        maxStopIfAnyPassed: 1,  // pass the test after first success in retry
      },
    },
  },
});
```

**[community]** WHY: Upgrading Cypress major versions without reviewing the changelog causes silent test changes. The most common Cy 14 breakage is `cy.origin()` callbacks that call custom commands — they silently stop working without `experimentalOriginDependencies: true`. Always run `npx cypress verify` and check the Cypress migration guide before bumping the major version in CI.

### 72. Server-Sent Events (SSE) Testing Pattern  [community]

`cy.intercept()` cannot stream SSE (`text/event-stream`) responses, but you can control the server side via `cy.task()` and assert on the UI receiving events.

```typescript
// cypress.config.ts — SSE test task
import { defineConfig } from 'cypress';
import { EventEmitter } from 'events';

const sseEmitter = new EventEmitter();

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', {
        // Trigger an SSE event from the test
        'sse:emit': ({ event, data }) => {
          sseEmitter.emit(event, data);
          return null;
        },
      });
    },
  },
});

// In a spec — control SSE from the test
it('updates live feed when SSE event arrives', () => {
  cy.visit('/live-feed');

  // Wait for the initial SSE connection
  cy.get('[data-cy="connection-status"]').should('have.text', 'Connected');

  // Emit an SSE event from the Node.js test server
  cy.task('sse:emit', { event: 'newPost', data: { id: 'post_1', title: 'Breaking News' } });

  // Assert the UI received and rendered the event
  cy.get('[data-cy="feed-item"]').should('contain', 'Breaking News');
});
```

**[community]** WHY: SSE connections are long-lived HTTP streams that Cypress's `cy.intercept()` cannot stub. The `cy.task()` bridge to Node.js is the only Cypress-native way to trigger SSE events and is more reliable than injecting events via `cy.window()`. If your SSE server is embedded in a Next.js or Express app, you can expose a test-only endpoint that pushes events on demand and call it via `cy.request()` instead of `cy.task()`.

### 73. cy.stub().onCall(n) — Call-Number-Specific Stub Behavior  [community]

Use `stub.onCall(n)` to define different behavior for the first, second, or Nth invocation of a stubbed function. Unlike `callsFake()` with a counter variable, `onCall()` is declarative and composable.

```typescript
it('shows loading state on first call, data on second', () => {
  const fetchStub = cy.stub(window, 'fetch')
    .as('fetch')
    .onCall(0).resolves(new Response(JSON.stringify({ status: 'loading' }), { status: 202 }))
    .onCall(1).resolves(new Response(JSON.stringify({ items: ['a', 'b'] }), { status: 200 }));

  cy.visit('/dashboard');

  // First fetch → 202 accepted → loading spinner
  cy.get('[data-cy="loading-spinner"]').should('be.visible');

  // Second fetch (triggered by poll or manual retry) → 200 with data
  cy.get('[data-cy="retry-btn"]').click();
  cy.get('[data-cy="item-list"]').should('have.length', 2);

  cy.get('@fetch').should('have.been.calledTwice');
});

it('simulates MFA flow: first call returns challenge, second returns token', () => {
  const authStub = cy.stub(window, 'fetch').as('authFetch');

  authStub.onCall(0).resolves(
    new Response(JSON.stringify({ mfaRequired: true, challengeId: 'ch_123' }), { status: 200 })
  );
  authStub.onCall(1).resolves(
    new Response(JSON.stringify({ token: 'jwt.abc.def', userId: 'usr_1' }), { status: 200 })
  );

  cy.visit('/login');
  cy.get('[data-cy="email"]').type('alice@example.com');
  cy.get('[data-cy="password"]').type('secret');
  cy.get('[data-cy="submit"]').click();

  // First call → MFA challenge UI appears
  cy.get('[data-cy="mfa-input"]').should('be.visible');
  cy.get('[data-cy="mfa-input"]').type('123456');
  cy.get('[data-cy="mfa-submit"]').click();

  // Second call → authenticated
  cy.url().should('include', '/dashboard');
});
```

**[community]** WHY: Managing call-count behavior via a mutable `let callCount = 0` closure inside `callsFake()` creates invisible shared state — if the test runs multiple times (e.g., retried in CI), the counter carries over and the second run gets the wrong behavior. `onCall(n)` declares behavior per-call at stub creation time, making the stub self-contained and retry-safe.

### 74. testIsolation — Per-Test Browser State Reset (Cypress 12+)

`testIsolation` (introduced in Cypress 12, `true` by default) clears cookies, localStorage, and session storage before each test. Disable it only for suites that explicitly manage shared state across tests.

```typescript
// cypress.config.ts — testIsolation is true by default in Cypress 12+
// You only need to set it explicitly when DISABLING it (not recommended for most cases)
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    testIsolation: true,   // default — clears all browser state before each test
    // Set false only for legacy suites that share state between tests (migration scenario)
    // testIsolation: false,
  },
});

// Per-suite override — disable isolation for a specific describe block
describe('Legacy stateful suite (migration)', { testIsolation: false }, () => {
  // Tests in this block share browser state between tests
  it('step 1: sets up state', () => {
    cy.window().then(win => win.localStorage.setItem('step', '1'));
  });

  it('step 2: reads state from step 1', () => {
    // testIsolation: false → localStorage from step 1 is still present
    cy.window().its('localStorage').invoke('getItem', 'step').should('eq', '1');
  });
});

// The correct modern pattern — always use testIsolation: true and explicit setup
describe('Modern isolated suite', () => {
  // With testIsolation: true (default), each test starts clean
  beforeEach(() => {
    // Explicit setup is self-documenting and test-order-independent
    cy.window().then(win => win.localStorage.setItem('step', 'reset'));
  });

  it('reads the state it sets up', () => {
    cy.window().its('localStorage').invoke('getItem', 'step').should('eq', 'reset');
  });
});
```

**[community]** WHY: Before `testIsolation: true` (Cypress < 12), teams relied on `cy.clearAllCookies()` + `cy.clearAllLocalStorage()` in every `beforeEach`. Forgetting these in one spec caused mysterious state bleed between tests. `testIsolation: true` makes isolation automatic — but teams migrating from Cypress 11 often set it to `false` for compatibility and never re-enable it. Audit your config: if `testIsolation: false`, migrate tests to explicit setup and re-enable isolation.

### 75. CTRF (Common Test Report Format) Integration  [community]

CTRF provides a vendor-neutral test result schema that works across Playwright, Cypress, Jest, and Vitest. Use `cypress-ctrf-json-reporter` to generate CTRF reports for unified dashboard visibility.

```typescript
// Install: npm install --save-dev cypress-ctrf-json-reporter
// cypress.config.ts — add CTRF reporter
import { defineConfig } from 'cypress';

export default defineConfig({
  reporter: 'cypress-ctrf-json-reporter',
  reporterOptions: {
    outputDir: 'ctrf',          // output directory
    outputFile: 'results.json', // output file name
    minimal: false,             // include per-test timings and metadata
  },
  e2e: {
    // ... rest of config
  },
});
```

```bash
# After the run, ctrf/results.json contains:
# { "results": { "summary": { "tests": 42, "passed": 40, "failed": 2, ... }, "tests": [...] } }

# Use ctrf-io/ai-test-reporter to summarize failures with Claude/GPT
npx ai-test-reporter ctrf/results.json --reporter claude

# Upload to GitHub PR comment with ctrf-io/github-test-reporter
npx github-test-reporter ctrf/results.json
```

```typescript
// Combine with custom Cypress reporter for dual output (spec progress + CTRF)
// cypress.config.ts — multi-reporter with mochawesome + CTRF
import { defineConfig } from 'cypress';

export default defineConfig({
  reporter: 'cypress-multi-reporters',
  reporterOptions: {
    configFile: 'reporter-config.json',
  },
  // reporter-config.json:
  // { "reporterEnabled": "spec, cypress-ctrf-json-reporter",
  //   "cypressCtrfJsonReporterReporterOptions": { "outputDir": "ctrf", "outputFile": "results.json" } }
});
```

**[community]** WHY: Teams running Cypress alongside Playwright or Jest in a monorepo end up with test result formats that are incompatible — JUnit XML from Cypress, JSON from Playwright, and tap from Jest. CTRF normalises all three into a single schema, enabling unified dashboards, PR comment bots, and AI failure summarizers that work across all test frameworks without custom parsing.

### 76. WebSocket Testing via cy.stub() + cy.task()  [community]

`cy.intercept()` cannot intercept WebSocket connections. Use `cy.stub(win, 'WebSocket')` to replace the WebSocket constructor for UI assertion tests, or use `cy.task()` to control a real WebSocket server for integration-level tests.

```typescript
// Approach 1: Stub the WebSocket constructor for UI behavior tests
it('shows live updates received over WebSocket', () => {
  // Create a mock WebSocket class
  let mockWs: {
    onmessage: ((event: MessageEvent) => void) | null;
    onopen: (() => void) | null;
    send: () => void;
    close: () => void;
    readyState: number;
  };

  cy.visit('/live-dashboard', {
    onBeforeLoad(win) {
      // Replace the WebSocket constructor before the app script runs
      cy.stub(win, 'WebSocket').callsFake(() => {
        mockWs = {
          onmessage: null,
          onopen: null,
          send: cy.stub().as('wsSend'),
          close: cy.stub(),
          readyState: WebSocket.OPEN,
        };
        // Simulate connection established
        setTimeout(() => mockWs.onopen?.(), 10);
        return mockWs;
      }).as('WebSocketConstructor');
    },
  });

  cy.get('[data-cy="connection-status"]').should('have.text', 'Connected');

  // Simulate receiving a message from the server
  cy.window().then(() => {
    mockWs.onmessage?.(
      new MessageEvent('message', {
        data: JSON.stringify({ type: 'price_update', symbol: 'AAPL', price: 185.42 }),
      })
    );
  });

  cy.get('[data-cy="price-aapl"]').should('have.text', '$185.42');
});

// Approach 2: cy.task() bridge to a real WebSocket test server
it('sends and receives messages via real WebSocket server', () => {
  cy.task('ws:start', { port: 4001 }).as('wsServer');
  cy.visit('/chat');

  cy.get('[data-cy="message-input"]').type('Hello from Cypress');
  cy.get('[data-cy="send-btn"]').click();

  // Task reads messages received by the test WS server
  cy.task('ws:getMessages').then((messages: string[]) => {
    expect(messages).to.include('Hello from Cypress');
  });

  // Task pushes a message from the server to the client
  cy.task('ws:broadcast', { message: 'Server says hi!' });
  cy.get('[data-cy="chat-message"]').last().should('contain', 'Server says hi!');

  cy.task('ws:stop');
});
```

**[community]** WHY: Teams often discover too late that `cy.intercept()` silently ignores WebSocket upgrade requests. The stub-constructor approach is the only fully client-side method and works without a test server, but it requires the app to expose the WS instance early enough for the stub to be in place. The `cy.task()` bridge to a real WS server is more realistic but adds infrastructure. For most production apps, stub the constructor for unit-style UI tests and use the task bridge for end-to-end message flow tests.

### 77. Email Testing with Mailhog/Mailpit via cy.task()  [community]

Test transactional emails (welcome emails, password resets, OTP codes) by running a local SMTP trap server and reading emails via `cy.task()`.

```typescript
// cypress/plugins/email.ts — Mailpit HTTP API client
interface MailpitMessage {
  ID: string;
  Subject: string;
  To: Array<{ Address: string }>;
  Text: string;
  HTML: string;
}

export const emailTasks = {
  'email:getLatest': async (toAddress: string): Promise<MailpitMessage | null> => {
    const base = process.env.MAILPIT_URL ?? 'http://localhost:8025';
    const res = await fetch(`${base}/api/v1/messages`);
    const data: { messages: MailpitMessage[] } = await res.json();

    const match = data.messages.find(m =>
      m.To.some(r => r.Address === toAddress)
    );
    return match ?? null;
  },

  'email:deleteAll': async () => {
    const base = process.env.MAILPIT_URL ?? 'http://localhost:8025';
    await fetch(`${base}/api/v1/messages`, { method: 'DELETE' });
    return null;
  },

  'email:extractOtp': async (toAddress: string): Promise<string | null> => {
    const base = process.env.MAILPIT_URL ?? 'http://localhost:8025';
    const res = await fetch(`${base}/api/v1/messages`);
    const data: { messages: MailpitMessage[] } = await res.json();

    const msg = data.messages.find(m => m.To.some(r => r.Address === toAddress));
    if (!msg) return null;

    // Extract 6-digit OTP from email body
    const match = msg.Text.match(/\b(\d{6})\b/);
    return match?.[1] ?? null;
  },
};

// In a spec — registration with email verification
describe('Registration flow', () => {
  beforeEach(() => {
    cy.task('email:deleteAll');
  });

  it('sends a verification email after signup', () => {
    cy.visit('/register');
    cy.get('[data-cy="email"]').type('newuser@example.com');
    cy.get('[data-cy="password"]').type('Password123!');
    cy.get('[data-cy="submit"]').click();

    cy.get('[data-cy="verify-email-prompt"]').should('be.visible');

    // Wait for email to arrive (polling with retry)
    cy.task('email:getLatest', 'newuser@example.com').should('not.be.null');

    cy.task('email:getLatest', 'newuser@example.com').then((msg: MailpitMessage | null) => {
      expect(msg?.Subject).to.include('Verify your email');
      expect(msg?.Text).to.include('newuser@example.com');
    });
  });

  it('completes OTP verification flow', () => {
    // Trigger OTP email via API (faster than UI registration)
    cy.request('POST', '/api/auth/send-otp', { email: 'otp@example.com' });

    // Retry until OTP email arrives (up to 15s)
    cy.task('email:extractOtp', 'otp@example.com').should('match', /^\d{6}$/).then((otp) => {
      cy.visit('/verify');
      cy.get('[data-cy="otp-input"]').type(otp as string);
      cy.get('[data-cy="verify-btn"]').click();
      cy.get('[data-cy="verified-banner"]').should('be.visible');
    });
  });
});
```

**[community]** WHY: Testing email flows by checking the real email inbox (via IMAP) is slow (10-30s per email) and flaky (email delays, spam filters). Local SMTP traps like Mailpit capture all outgoing email synchronously, making email assertions as fast as API assertions. The key pattern is `cy.task().should('not.be.null')` for polling — Cypress retries `.should()` on task results, so you get automatic retry without a `cy.wait(ms)` crutch.

### 78. cy.trigger() for Native DOM Events  [community]

Use `cy.trigger()` to fire native DOM events that Cypress action commands don't cover — mouseover, pointermove, custom events, drag-related events, and touch events.

```typescript
it('shows tooltip on mouseover', () => {
  cy.visit('/products');

  // Trigger mouseover to reveal tooltip
  cy.get('[data-cy="info-icon"]').trigger('mouseover');
  cy.get('[data-cy="tooltip"]').should('be.visible').and('contain', 'Learn more');

  // Trigger mouseout to hide it
  cy.get('[data-cy="info-icon"]').trigger('mouseout');
  cy.get('[data-cy="tooltip"]').should('not.exist');
});

it('fires pointer events for canvas/SVG interactions', () => {
  cy.visit('/chart');

  // Get element dimensions to calculate relative coordinates
  cy.get('[data-cy="chart-canvas"]').then(($canvas) => {
    const rect = $canvas[0].getBoundingClientRect();
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;

    cy.get('[data-cy="chart-canvas"]')
      .trigger('pointerdown', { clientX: rect.left + centerX, clientY: rect.top + centerY })
      .trigger('pointermove', { clientX: rect.left + centerX + 50, clientY: rect.top + centerY })
      .trigger('pointerup');
  });

  cy.get('[data-cy="selected-range"]').should('not.be.empty');
});

it('dispatches custom application events', () => {
  cy.visit('/notification-center');

  // Trigger a custom event that the app dispatches internally
  cy.get('[data-cy="notification-host"]').trigger('app:notification', {
    bubbles: true,
    detail: { type: 'success', message: 'Export complete', id: 'notif_1' },
  });

  cy.get('[data-cy="notification-item"]').should('contain', 'Export complete');
});
```

**[community]** WHY: Cypress action commands (`click()`, `type()`, `check()`) are high-level and simulate user intent. `cy.trigger()` fires raw DOM events for scenarios where the high-level commands don't apply: hover states, pointer/touch events, canvas drawing, drag-and-drop via `dragstart/dragover/drop`, and custom application events. Unlike action commands, `trigger()` does not perform actionability checks (visibility, enabled state) — this is intentional for events fired programmatically by the app itself.

### 79. React Testing Library (RTL) with Cypress Component Tests  [community]

When your team uses React Testing Library conventions, use `@testing-library/cypress` to bring RTL queries (`findByRole`, `findByLabelText`) into Cypress Component Testing specs.

```typescript
// Install: npm install --save-dev @testing-library/cypress
// cypress/support/component.ts
import '@testing-library/cypress/add-commands';

// login-form.cy.tsx
import React from 'react';
import { LoginForm } from '../../src/components/LoginForm';

describe('LoginForm component', () => {
  it('submits with accessible role-based queries', () => {
    const onSubmit = cy.stub().as('onSubmit');
    cy.mount(<LoginForm onSubmit={onSubmit} />);

    // Use ARIA roles and labels — aligns with screen reader experience
    cy.findByRole('textbox', { name: /email/i }).type('alice@example.com');
    cy.findByLabelText(/password/i).type('secret');
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.get('@onSubmit').should('have.been.calledWith', {
      email: 'alice@example.com',
      password: 'secret',
    });
  });

  it('shows validation error for empty email', () => {
    cy.mount(<LoginForm onSubmit={cy.stub()} />);

    cy.findByRole('button', { name: /sign in/i }).click();

    // RTL query for the error message by ARIA role
    cy.findByRole('alert').should('contain.text', 'Email is required');
  });

  it('disables submit button while loading', () => {
    // Pass a never-resolving promise to simulate pending state
    cy.mount(<LoginForm onSubmit={() => new Promise(() => {})} />);

    cy.findByRole('textbox', { name: /email/i }).type('alice@example.com');
    cy.findByLabelText(/password/i).type('secret');
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.findByRole('button', { name: /signing in/i }).should('be.disabled');
  });
});
```

**[community]** WHY: Teams that write unit tests with React Testing Library use ARIA roles and labels as their selector strategy — `getByRole('button', { name: /submit/i })` rather than `data-testid`. Using `@testing-library/cypress` brings the same query strategy into Cypress Component Testing, keeping selector conventions consistent across unit and integration tests. The queries also serve as implicit WCAG 4.1.2 compliance checks: if `findByRole('button', { name: /sign in/i })` can't find the element, the component is missing an accessible name.

### 80. Polling Helper — Wait for Async Background Jobs  [community]

For long-running background jobs (report generation, import processing, async webhooks), wrap `cy.request()` in a recursive polling helper with backoff. Unlike `cy.wait(ms)`, this retries until the job is done without wasting time on fast jobs.

```typescript
// cypress/support/poll.ts — recursive polling with backoff
export function pollUntil<T>(
  fn: () => Cypress.Chainable<T>,
  predicate: (value: T) => boolean,
  options: { maxAttempts?: number; intervalMs?: number } = {}
): Cypress.Chainable<T> {
  const { maxAttempts = 20, intervalMs = 1000 } = options;
  let attempts = 0;

  const attempt = (): Cypress.Chainable<T> => {
    return fn().then((value) => {
      attempts++;
      if (predicate(value)) return cy.wrap(value);
      if (attempts >= maxAttempts) throw new Error(`Polling timed out after ${attempts} attempts`);
      // Wait before next attempt using cy.wait — integrates with Cypress queue
      return cy.wait(intervalMs).then(() => attempt());
    });
  };

  return attempt();
}

// In a spec — poll until a background job status becomes 'completed'
import { pollUntil } from '../support/poll';

it('generates a report asynchronously', () => {
  cy.request('POST', '/api/reports', { type: 'quarterly', year: 2025 })
    .its('body.jobId')
    .then((jobId: string) => {
      // Poll the job status API until it returns 'completed' or 'failed'
      pollUntil(
        () => cy.request(`/api/jobs/${jobId}`).its('body'),
        (job: { status: string }) => job.status === 'completed',
        { maxAttempts: 30, intervalMs: 1500 }  // up to 45 seconds
      ).then((job: { status: string; reportUrl: string }) => {
        expect(job.status).to.eq('completed');

        // Now visit the report URL
        cy.visit(job.reportUrl);
        cy.get('[data-cy="report-title"]').should('be.visible');
      });
    });
});

// Simpler pattern: cy.request() inside .should() for a single retry loop
it('waits for webhook delivery with .should() retry', () => {
  cy.request('POST', '/api/webhooks/trigger', { event: 'payment.success' });

  // Retry the GET until the webhook log shows delivery
  cy.request('/api/webhooks/log').its('body').should((log: Array<{ event: string; delivered: boolean }>) => {
    const delivered = log.find(e => e.event === 'payment.success' && e.delivered);
    expect(delivered, 'webhook not yet delivered').to.exist;
  });
});
```

**[community]** WHY: `cy.wait(30000)` to handle a background job that usually finishes in 2 seconds wastes 28 seconds on every passing test run. The polling helper exits as soon as the job is done. The trade-off is complexity — for simple polling needs, `cy.request().its('body').should(...)` (which Cypress retries automatically) is sufficient. Use the recursive helper only when you need configurable backoff or when the total wait would exceed `defaultCommandTimeout`.

### 81. TypeScript Path Aliases in Cypress  [community]

Configure TypeScript path aliases so Cypress test files can use the same `@/components/*` imports as the main application, avoiding brittle relative paths.

```typescript
// tsconfig.json (project root) — define path aliases
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@fixtures/*": ["cypress/fixtures/*"],
      "@pages/*": ["cypress/pages/*"],
      "@support/*": ["cypress/support/*"]
    }
  }
}

// cypress/tsconfig.json — extend the root tsconfig for Cypress files
{
  "extends": "../tsconfig.json",
  "compilerOptions": {
    "types": ["cypress"],
    "paths": {
      "@/*": ["../src/*"],
      "@fixtures/*": ["../fixtures/*"],
      "@pages/*": ["../pages/*"],
      "@support/*": ["../support/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx"]
}
```

```typescript
// cypress.config.ts — register path aliases with the bundler (Vite example)
import { defineConfig } from 'cypress';
import { resolve } from 'path';

export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
      viteConfig: {
        resolve: {
          alias: {
            '@': resolve(__dirname, 'src'),
          },
        },
      },
    },
  },
});
```

```typescript
// In a spec — use path aliases instead of relative paths
import { LoginPage } from '@pages/LoginPage';        // cypress/pages/LoginPage.ts
import { makeUser } from '@support/factories/user';  // cypress/support/factories/user.ts
import type { Product } from '@/types/product';      // src/types/product.ts (shared with app)

describe('Product page', () => {
  it('shows product details', () => {
    const product: Product = { id: 'prod_1', name: 'Widget', price: 9.99 };
    cy.intercept('GET', '/api/products/prod_1', product).as('getProduct');

    cy.visit('/products/prod_1');
    cy.wait('@getProduct');
    cy.get('[data-cy="product-name"]').should('have.text', product.name);
  });
});
```

**[community]** WHY: Long relative paths like `import { LoginPage } from '../../../pages/LoginPage'` break when files are moved and are hard to read. Path aliases give test files the same import ergonomics as source files. The key pitfall is that `tsconfig.json` paths only affect TypeScript compilation — the Vite/webpack bundler also needs the alias registered (via `resolve.alias` in Vite or `resolve.modules` in webpack). Set up both to avoid "Cannot find module '@/...'" runtime errors that don't show at compile time.

### 82. Performance Timing Assertions via Navigation Timing API  [community]

Assert on page load performance metrics using the browser's `window.performance` API from within a Cypress test. These are lightweight smoke-level performance checks, not a substitute for k6 or Lighthouse.

```typescript
// Custom command to assert on navigation timing
declare global {
  namespace Cypress {
    interface Chainable {
      assertPageLoadTime(maxMs: number): Chainable<void>;
      assertLargestContentfulPaint(maxMs: number): Chainable<void>;
    }
  }
}

Cypress.Commands.add('assertPageLoadTime', (maxMs: number) => {
  cy.window().then((win) => {
    const [entry] = win.performance.getEntriesByType('navigation') as PerformanceNavigationTiming[];
    if (!entry) {
      cy.log('No navigation entry found — skipping timing assertion');
      return;
    }
    const loadTime = entry.loadEventEnd - entry.startTime;
    expect(loadTime, `Page load time ${loadTime.toFixed(0)}ms > limit ${maxMs}ms`).to.be.lessThan(maxMs);
    cy.log(`Page load time: ${loadTime.toFixed(0)}ms (limit: ${maxMs}ms)`);
  });
});

Cypress.Commands.add('assertLargestContentfulPaint', (maxMs: number) => {
  // LCP is available via PerformanceObserver — read accumulated entries
  cy.window().then((win) => {
    const lcpEntries = win.performance.getEntriesByType('largest-contentful-paint');
    if (lcpEntries.length === 0) {
      cy.log('LCP entry not available (page may not have finished painting)');
      return;
    }
    const lcp = lcpEntries[lcpEntries.length - 1].startTime;
    expect(lcp, `LCP ${lcp.toFixed(0)}ms > limit ${maxMs}ms`).to.be.lessThan(maxMs);
    cy.log(`LCP: ${lcp.toFixed(0)}ms (limit: ${maxMs}ms)`);
  });
});

// In a spec — smoke-level performance check on the landing page
it('landing page loads within 3 seconds', () => {
  cy.visit('/');

  // Wait for meaningful content before asserting
  cy.get('[data-cy="hero-heading"]').should('be.visible');

  // Assert on navigation timing
  cy.assertPageLoadTime(3000);
  cy.assertLargestContentfulPaint(2500);
});

// Assert on API response time via cy.intercept() duration
it('product API responds within 500ms', () => {
  cy.intercept('GET', '/api/products*').as('products');
  cy.visit('/products');

  cy.wait('@products').then((interception) => {
    const duration = interception.duration ?? 0;
    expect(duration, `API response time ${duration}ms > 500ms`).to.be.lessThan(500);
    cy.log(`Products API: ${duration}ms`);
  });
});
```

**[community]** WHY: Running full load tests in Cypress is inappropriate (Cypress runs in the same browser as the app, introducing overhead). However, adding a single `assertPageLoadTime(3000)` to a smoke test catches accidental regressions — a new dependency that doubles load time — without a dedicated k6 run. The `interception.duration` from `cy.wait('@alias')` is the most reliable E2E measure of API latency from the test's perspective.

### 83. Cypress `--grep` Tag Filtering via @cypress/grep  [community]

Use `@cypress/grep` to run tagged subsets of tests — smoke, critical, or regression — from a single spec suite. Replaces the need for separate spec files per environment.

```typescript
// Install: npm install --save-dev @cypress/grep
// cypress/support/e2e.ts
import registerCypressGrep from '@cypress/grep';
registerCypressGrep();

// Tag tests with @tag syntax in titles
describe('Checkout flow', { tags: ['@critical', '@smoke'] }, () => {
  it('completes purchase with credit card', { tags: '@critical' }, () => {
    // ...
  });

  it('shows order confirmation email sent message', { tags: '@regression' }, () => {
    // ...
  });

  it('handles expired card gracefully', { tags: ['@regression', '@edge-cases'] }, () => {
    // ...
  });
});
```

```bash
# Run only @critical tests in CI fast path (PR builds)
npx cypress run --env grep=@critical

# Run @smoke tests with reporting
npx cypress run --env grep=@smoke --record

# Exclude @edge-cases (useful for staging where environment has known limitations)
npx cypress run --env grepInvert=@edge-cases

# Run all tests tagged @regression OR @critical
npx cypress run --env grep="@regression|@critical"

# Run tests with BOTH tags (AND logic)
npx cypress run --env grep="@regression @critical"
```

```typescript
// cypress.config.ts — register grep plugin
import { defineConfig } from 'cypress';
import registerCypressGrep from '@cypress/grep/src/plugin';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      registerCypressGrep(config);
      return config;
    },
  },
});
```

**[community]** WHY: Separate spec files per environment (`smoke.cy.ts`, `regression.cy.ts`) lead to test duplication — the same test logic exists in two files that drift apart over time. Tag-based filtering keeps all tests in domain-organized spec files and lets you slice them by purpose at runtime. The pattern enables a three-tier CI strategy: `@smoke` on every PR (2-5 min), `@critical` on merge to main (10-15 min), full suite nightly.

### 84. Cypress + Storybook Smoke Integration  [community]

Use `cy.visit()` to open Storybook stories and assert on their rendered output — a lightweight integration test between Storybook (component catalogue) and Cypress (browser automation).

```typescript
// cypress/e2e/storybook-smoke.cy.ts
// Assumes Storybook is running at http://localhost:6006

const STORYBOOK_URL = Cypress.env('STORYBOOK_URL') ?? 'http://localhost:6006';

// Build the Storybook iframe URL from story ID
const storyUrl = (storyId: string) =>
  `${STORYBOOK_URL}/iframe.html?id=${storyId}&viewMode=story`;

describe('Storybook component smoke tests', () => {
  it('Button component renders default variant', () => {
    cy.visit(storyUrl('components-button--default'));
    cy.get('[data-cy="btn"]').should('be.visible').and('not.be.disabled');
  });

  it('Button loading state renders spinner', () => {
    cy.visit(storyUrl('components-button--loading'));
    cy.get('[data-cy="btn"]').should('be.disabled');
    cy.get('[data-cy="spinner"]').should('be.visible');
  });

  it('FormField shows error state', () => {
    cy.visit(storyUrl('components-formfield--error'));
    cy.get('[data-cy="field-error"]').should('be.visible');
    cy.get('[role="alert"]').should('contain.text', 'This field is required');
  });

  it('DataTable renders with correct column count', () => {
    cy.visit(storyUrl('components-datatable--with-data'));
    cy.get('th').should('have.length.gte', 3);
    cy.get('tbody tr').should('have.length.gte', 1);
  });
});

// cypress.config.ts — configure Storybook URL from env
// npx cypress run --env STORYBOOK_URL=http://localhost:6006
```

**[community]** WHY: Cypress Component Testing mounts components in isolation within a Vite/webpack dev server. This is ideal for interaction tests but requires the same bundler setup as the app. Storybook stories already define all component states — using `cy.visit()` on the Storybook iframe URL reuses those state definitions as a free test fixture. The Storybook approach is lower maintenance: when the component state changes, the story is updated once and all Cypress smoke tests automatically get the new state.

### 85. Strict cy.intercept() Verification — Asserting No Unexpected Requests  [community]

Use `cy.intercept()` with `spy` mode and after-test assertions to verify that a user action did NOT trigger unexpected network requests — useful for asserting optimistic UI patterns and debounce effectiveness.

```typescript
it('search input debounces — does not fire on every keystroke', () => {
  // Track ALL requests to the search API
  cy.intercept('GET', '/api/search*').as('searchRequests');

  cy.visit('/search');
  cy.clock();

  // Type quickly — debounce should prevent requests during typing
  cy.get('[data-cy="search-input"]').type('cypress', { delay: 50 });

  // Only 7 characters typed but debounce delay (500ms) not reached yet
  cy.get('@searchRequests.all').should('have.length', 0);

  // Advance past debounce threshold
  cy.tick(500);

  // Exactly ONE request should fire after debounce — not 7
  cy.get('@searchRequests.all').should('have.length', 1);
  cy.wait('@searchRequests').its('request.url').should('include', 'query=cypress');
});

it('clicking "Save" only once does not trigger duplicate requests', () => {
  cy.intercept('POST', '/api/documents').as('save');
  cy.visit('/editor');

  cy.get('[data-cy="doc-content"]').type('Test content');
  cy.get('[data-cy="save-btn"]').click();

  // Assert button is disabled after click (prevents double submit)
  cy.get('[data-cy="save-btn"]').should('be.disabled');

  // Exactly one POST request — no duplicates
  cy.wait('@save').its('response.statusCode').should('eq', 201);
  cy.get('@save.all').should('have.length', 1);
});

// Assert that a cancelled operation stops pending requests
it('cancelling a request removes it from the pending queue', () => {
  let requestReceived = false;

  cy.intercept('GET', '/api/slow-data', (req) => {
    requestReceived = true;
    req.on('response', (res) => {
      res.setDelay(2000);  // simulate slow server
    });
  }).as('slowData');

  cy.visit('/data-page');
  cy.get('[data-cy="cancel-btn"]').click();  // user cancels before data loads

  // After cancel, the component should not render stale data
  cy.get('[data-cy="data-content"]').should('not.exist');
  cy.get('[data-cy="cancelled-message"]').should('be.visible');
});
```

**[community]** WHY: Tests usually assert that something happened — a request fired, a modal appeared. But for optimistic UI, debounce, and idempotency patterns, asserting that something did NOT happen is equally important. Using `@alias.all` with `.should('have.length', N)` provides a deterministic count assertion. Without this, a form that submits twice on double-click can pass all its tests because the happy path assertion only checks for ≥1 request, not exactly 1.

### 86. Svelte Component Testing  [community]

Cypress Component Testing supports Svelte via the `@vitejs/plugin-svelte` bundler plugin. Mount Svelte components with props and assert on their rendered output.

```typescript
// cypress.config.ts — Svelte component testing setup
import { defineConfig } from 'cypress';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig({
  component: {
    devServer: {
      framework: 'svelte',
      bundler: 'vite',
      viteConfig: {
        plugins: [svelte()],
      },
    },
    specPattern: 'src/**/*.cy.{ts,svelte}',
  },
});
```

```typescript
// src/components/Counter.cy.ts — Svelte component test
import { mount } from 'cypress/svelte';
import Counter from './Counter.svelte';

describe('Counter component', () => {
  it('renders with initial count', () => {
    mount(Counter, { props: { initialCount: 5 } });
    cy.get('[data-cy="count"]').should('have.text', '5');
  });

  it('increments count on button click', () => {
    mount(Counter, { props: { initialCount: 0 } });

    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '1');

    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '2');
  });

  it('dispatches custom "countChanged" event', () => {
    const onCountChanged = cy.stub().as('countChanged');

    // Use Cypress event handler for Svelte custom events
    mount(Counter, {
      props: { initialCount: 0 },
      extensions: {
        on: { countChanged: onCountChanged },
      },
    });

    cy.get('[data-cy="increment"]').click();
    cy.get('@countChanged').should('have.been.calledWith', 1);
  });
});
```

**[community]** WHY: Svelte's reactivity model is fundamentally different from React/Vue — updates are compiled to direct DOM mutations rather than virtual DOM diffing. Cypress Component Testing for Svelte is valuable because Svelte's `{#if}`, `{#each}`, and `$:` reactive declarations can produce subtle DOM state that's difficult to test in isolation with pure unit tests. Mounting Svelte components in a real browser via Cypress catches reactivity edge cases (e.g., `$:` re-runs not triggering when expected) that Jest/Vitest JSDOM mocks miss.

### 87. Seeding Test Data with @faker-js/faker  [community]

Replace static fixture files and hardcoded test data with dynamically generated realistic data using `@faker-js/faker`. Seeded with a fixed seed value for reproducible failures.

```typescript
// Install: npm install --save-dev @faker-js/faker
// cypress/support/faker-seed.ts
import { faker } from '@faker-js/faker';

// Seed with a fixed value for reproducible test data — use Date.now() for randomness
faker.seed(42);

export function fakeUser(overrides: Partial<{
  email: string;
  name: string;
  role: 'admin' | 'user' | 'viewer';
}> = {}) {
  return {
    id: faker.string.uuid(),
    email: overrides.email ?? faker.internet.email({ provider: 'e2e.test' }),
    name: overrides.name ?? faker.person.fullName(),
    role: (overrides.role ?? 'user') as 'admin' | 'user' | 'viewer',
    phone: faker.phone.number({ style: 'national' }),
    createdAt: faker.date.past({ years: 1 }).toISOString(),
  };
}

export function fakeProduct(overrides: Partial<{
  name: string;
  price: number;
  category: string;
}> = {}) {
  return {
    id: faker.string.uuid(),
    name: overrides.name ?? faker.commerce.productName(),
    price: overrides.price ?? Number(faker.commerce.price({ min: 1, max: 500 })),
    category: overrides.category ?? faker.commerce.department(),
    sku: faker.string.alphanumeric({ length: 8, casing: 'upper' }),
    inStock: faker.datatype.boolean(),
    description: faker.commerce.productDescription(),
  };
}

// In a spec — generate realistic test data
import { fakeUser, fakeProduct } from '../support/faker-seed';

it('admin can create a product', () => {
  const admin = fakeUser({ role: 'admin' });
  const product = fakeProduct({ price: 29.99 });

  // Seed user via API
  cy.request('POST', '/api/test/users', admin);

  // Login as admin
  loginAsRole('admin');

  cy.visit('/admin/products/new');
  cy.get('[data-cy="product-name"]').type(product.name);
  cy.get('[data-cy="product-price"]').type(String(product.price));
  cy.get('[data-cy="product-sku"]').type(product.sku);
  cy.get('[data-cy="submit"]').click();

  cy.get('[data-cy="success-toast"]').should('contain', 'Product created');
  cy.get('[data-cy="product-list"]').should('contain', product.name);
});
```

**[community]** WHY: Hardcoded test data names like "Test User" and "Widget" appear in screenshots, making it hard to distinguish which test created which data. Faker generates realistic names that look like production data in screenshots and catch edge cases with special characters (apostrophes in names, hyphens in phone numbers, long product descriptions) that hardcoded data misses. Use `faker.seed(number)` for reproducible failures — when a test fails with a faker-generated value, record the seed and re-run with that seed to reproduce the exact failure.

### 88. Clipboard Testing with navigator.clipboard  [community]

Test "Copy to clipboard" functionality by granting clipboard permissions via CDP and reading the clipboard value from `navigator.clipboard`.

```typescript
// cypress/support/commands.ts — clipboard helper
declare global {
  namespace Cypress {
    interface Chainable {
      grantClipboardPermission(): Chainable<void>;
      readClipboard(): Chainable<string>;
    }
  }
}

Cypress.Commands.add('grantClipboardPermission', () => {
  // Grant clipboard-read and clipboard-write permissions via CDP
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Browser.grantPermissions',
      params: {
        permissions: ['clipboardReadWrite', 'clipboardSanitizedWrite'],
        origin: window.location.origin,
      },
    })
  );
});

Cypress.Commands.add('readClipboard', () => {
  cy.window().then((win) => {
    return win.navigator.clipboard.readText();
  });
});

// In a spec — test a "Copy link" button
describe('Share functionality', () => {
  before(() => {
    cy.grantClipboardPermission();
  });

  it('copies shareable link to clipboard', () => {
    cy.visit('/articles/123');

    cy.get('[data-cy="copy-link-btn"]').click();
    cy.get('[data-cy="copy-success-toast"]').should('be.visible');

    cy.readClipboard().should('match', /^https?:\/\/.+\/articles\/123$/);
  });

  it('copies code snippet to clipboard', () => {
    cy.visit('/docs/api-reference');

    cy.get('[data-cy="code-block"]').first().find('[data-cy="copy-code"]').click();

    cy.readClipboard().then((text) => {
      expect(text.trim()).to.not.be.empty;
      expect(text).to.include('import');  // sanity check for code content
    });
  });
});
```

**[community]** WHY: By default Cypress (and browsers) deny clipboard access, so `navigator.clipboard.readText()` rejects with `NotAllowedError`. The CDP `Browser.grantPermissions` call is the only way to grant clipboard access in an automated browser context. The `--allow-clipboard-read-write-for-testing` Chrome flag (from `before:browser:launch`) also works but affects the entire browser session. CDP grants are per-origin and more surgical. Electron does not support CDP clipboard grants — run clipboard tests only against Chrome.

### 89. Intercept Header Assertion and Modification  [community]

Assert on request headers sent by the application (e.g., CORS headers, API versioning headers) and inject response headers for testing header-dependent UI behavior.

```typescript
// Assert that the app sends the correct API version header
it('sends X-API-Version header on all API requests', () => {
  cy.intercept('GET', '/api/**', (req) => {
    // Spy on the header without modifying the request
    expect(req.headers['x-api-version']).to.eq('2');
  }).as('apiRequests');

  cy.visit('/products');
  cy.wait('@apiRequests');
});

// Inject response headers to test header-dependent behavior
it('shows CORS error when server returns wrong CORS headers', () => {
  cy.intercept('GET', '/api/public-data', (req) => {
    req.reply({
      statusCode: 200,
      body: { items: [1, 2, 3] },
      headers: {
        // Missing 'Access-Control-Allow-Origin' — simulate misconfigured CORS
        'Content-Type': 'application/json',
      },
    });
  }).as('publicData');

  cy.visit('/public-page');
  cy.wait('@publicData');
  cy.get('[data-cy="cors-error-msg"]').should('be.visible');
});

// Assert on X-Request-ID for distributed tracing
it('includes X-Request-ID in all authenticated requests', () => {
  const observedIds = new Set<string>();

  cy.intercept('/api/**', (req) => {
    const requestId = req.headers['x-request-id'] as string | undefined;
    if (requestId) {
      expect(requestId).to.match(/^[0-9a-f-]{36}$/i);  // UUID format
      expect(observedIds.has(requestId), 'X-Request-ID must be unique per request').to.be.false;
      observedIds.add(requestId);
    }
  });

  loginAsRole('user');
  cy.visit('/dashboard');
  cy.get('[data-cy="load-more"]').click();
  cy.get('[data-cy="settings-link"]').click();

  // All three API requests should have unique X-Request-IDs
  cy.wrap(observedIds).its('size').should('be.gte', 3);
});
```

**[community]** WHY: Header assertions are often neglected in E2E tests because headers are invisible to the user. But headers carry security-critical information (CSRF tokens, API version contracts, correlation IDs for distributed tracing). Asserting inside a `cy.intercept()` handler that headers are present and correctly formatted is the only way to catch regressions where a header is accidentally dropped without the user experience changing. Use this pattern during API contract audits and security reviews.

### 90. Geolocation and Permissions Testing via CDP  [community]

Test geolocation-dependent features (store locators, localized content, shipping estimates) by overriding the browser's geolocation via CDP before visiting the page.

```typescript
// cypress/support/commands.ts — geolocation override
declare global {
  namespace Cypress {
    interface Chainable {
      setGeolocation(coords: { latitude: number; longitude: number; accuracy?: number }): Chainable<void>;
    }
  }
}

Cypress.Commands.add('setGeolocation', ({ latitude, longitude, accuracy = 100 }) => {
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setGeolocationOverride',
      params: { latitude, longitude, accuracy },
    })
  );
});

// In a spec — test a store locator feature
it('shows stores near the user location', () => {
  // Set location to New York City before visiting
  cy.setGeolocation({ latitude: 40.7128, longitude: -74.006 });

  cy.visit('/store-locator');
  cy.get('[data-cy="use-my-location"]').click();

  // App should detect NYC and show local stores
  cy.get('[data-cy="location-display"]').should('contain', 'New York');
  cy.get('[data-cy="store-card"]').should('have.length.gte', 1);
});

it('shows localized shipping estimate based on detected region', () => {
  // Set location to London
  cy.setGeolocation({ latitude: 51.5074, longitude: -0.1278 });

  cy.visit('/checkout');
  cy.get('[data-cy="detect-location"]').click();

  cy.get('[data-cy="shipping-region"]').should('contain', 'United Kingdom');
  cy.get('[data-cy="shipping-currency"]').should('contain', 'GBP');
});

it('handles geolocation permission denied gracefully', () => {
  // Revoke geolocation permission
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Browser.resetPermissions',
      params: {},
    })
  );

  cy.visit('/store-locator');
  cy.get('[data-cy="use-my-location"]').click();

  // App should handle the denial gracefully
  cy.get('[data-cy="geolocation-error"]').should('contain', 'Location access denied');
  cy.get('[data-cy="manual-address-input"]').should('be.visible');
});
```

**[community]** WHY: Geolocation features are almost never tested in automated suites because the default browser behavior (show permission prompt) blocks test execution. CDP `Emulation.setGeolocationOverride` bypasses both the permission prompt and the physical GPS hardware, setting precise coordinates instantly. This enables CI-stable tests for any feature that reads `navigator.geolocation.getCurrentPosition()`. For permission-denied scenarios, use `Browser.resetPermissions` to revoke the geolocation grant — this is more reliable than trying to click the browser's native permission dialog.

### 91. Parallel Test Execution with Custom Worker Allocation  [community]

Optimize CI test duration by explicitly grouping specs by complexity and allocating parallel workers accordingly.

```yaml
# .github/workflows/e2e.yml — differentiated parallelism by test weight
name: E2E Tests — Weighted Parallel
on: [push, pull_request]

jobs:
  e2e-fast:
    name: Fast specs (auth, smoke)
    runs-on: ubuntu-latest
    container:
      image: cypress/included:14.0.0
    steps:
      - uses: actions/checkout@v4
      - name: Run fast specs
        run: npx cypress run --spec "cypress/e2e/auth/**,cypress/e2e/smoke/**" --record --parallel --ci-build-id "${{ github.run_id }}-fast"
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}

  e2e-medium:
    name: Medium specs (checkout, products)
    runs-on: ubuntu-latest
    container:
      image: cypress/included:14.0.0
    strategy:
      matrix:
        containers: [1, 2]  # 2 workers for medium complexity
    steps:
      - uses: actions/checkout@v4
      - name: Run medium specs
        run: npx cypress run --spec "cypress/e2e/checkout/**,cypress/e2e/products/**" --record --parallel --ci-build-id "${{ github.run_id }}-medium"
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}

  e2e-slow:
    name: Slow specs (reports, admin)
    runs-on: ubuntu-latest
    container:
      image: cypress/included:14.0.0
    strategy:
      matrix:
        containers: [1, 2, 3]  # 3 workers for slow, long-running specs
    steps:
      - uses: actions/checkout@v4
      - name: Run slow specs
        run: npx cypress run --spec "cypress/e2e/reports/**,cypress/e2e/admin/**" --record --parallel --ci-build-id "${{ github.run_id }}-slow"
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
```

```typescript
// cypress/support/e2e.ts — mark test start time for spec timing
const specStartTime = Date.now();

after(() => {
  const duration = ((Date.now() - specStartTime) / 1000).toFixed(1);
  cy.log(`Spec completed in ${duration}s`);
  // Log to CTRF or a custom metric for worker allocation tuning
});
```

**[community]** WHY: Cypress Cloud's balanced load distribution works well for suites with uniform spec durations, but many teams have a small number of very slow specs (10+ min report generation, admin CRUD) that create a "long tail" — one worker is still running when all others have finished. Splitting by complexity and allocating more workers to slow spec groups cuts total CI wall time without paying for more machines on fast specs. The `--ci-build-id` suffix differentiates Cypress Cloud runs so each group's results appear separately in the dashboard.

### 92. Test Isolation Audit Command  [community]

Detect test isolation violations by logging initial state and asserting that each test resets properly. Use as a pre-commit check for suites with `testIsolation: false`.

```typescript
// cypress/support/isolation-audit.ts
// Add to support/e2e.ts imports to enable isolation auditing

const AUDITED_KEYS = ['theme', 'auth_token', 'user_id', 'cart', 'feature_flags'] as const;

// Capture state AFTER each test to detect state leakage
afterEach(function () {
  if (this.currentTest?.state === 'passed') {
    cy.window().then((win) => {
      const residual: Record<string, string | null> = {};
      AUDITED_KEYS.forEach((key) => {
        const val = win.localStorage.getItem(key);
        if (val !== null) residual[key] = val;
      });

      if (Object.keys(residual).length > 0) {
        // Log a warning — don't fail (auditing mode, not enforcement mode)
        cy.log(
          `⚠ Isolation warning: "${this.currentTest?.title}" left localStorage keys: ${JSON.stringify(residual)}`
        );
      }
    });
  }
});

// Stronger: in enforcement mode, fail the test if it leaves state behind
// Replace cy.log with: throw new Error(...)
```

```typescript
// cypress/support/e2e.ts — enable isolation audit selectively
// Only audit in development (not CI) to avoid noise
if (!Cypress.env('CI')) {
  require('./isolation-audit');
}
```

**[community]** WHY: Cross-test state pollution is the root cause of most "passes locally, fails in CI" flakiness. The audit command makes state residue visible during local development, before it causes non-deterministic failures in parallel CI runs. Running it unconditionally in CI would be noisy (every test logs residual state), so limit it to local development or add it to a dedicated `audit` tagged test run.

### 93. Cypress `after:run` Hook — Post-Suite Reporting  [community]

Use the `after:run` event in `setupNodeEvents` to send test results to external systems (Slack, PagerDuty, internal dashboards) or to clean up shared test resources.

```typescript
// cypress.config.ts — after:run hook
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('after:run', async (results) => {
        // results is a CypressRunResult or CypressFailedRunResult
        if (results.status === 'failed') {
          console.error('Run failed — no results to report');
          return;
        }

        const { totalTests, totalPassed, totalFailed, totalPending, totalSkipped } = results;
        const passRate = ((totalPassed / totalTests) * 100).toFixed(1);

        // Send Slack notification on failure
        if (totalFailed > 0) {
          await fetch(process.env.SLACK_WEBHOOK_URL ?? '', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              text: `❌ E2E suite: ${totalFailed}/${totalTests} tests failed (${passRate}% pass rate)`,
              attachments: [{
                color: 'danger',
                fields: [
                  { title: 'Failed', value: String(totalFailed), short: true },
                  { title: 'Passed', value: String(totalPassed), short: true },
                ],
              }],
            }),
          });
        }

        // Clean up test database state after every run
        const { dbTasks } = await import('./cypress/plugins/db');
        await dbTasks['db:clean']();

        console.log(`Run complete: ${totalPassed}/${totalTests} passed (${passRate}%)`);
      });
    },
  },
});
```

```typescript
// Type the results object for full autocomplete
import type { CypressRunResult } from 'cypress';

// Access per-spec results
on('after:run', (results: CypressRunResult) => {
  results.runs.forEach((run) => {
    const slowTests = run.tests
      .filter((t) => (t.attempts[0]?.wallClockDuration ?? 0) > 10000)  // > 10s
      .map((t) => ({ title: t.title.join(' > '), duration: t.attempts[0]?.wallClockDuration }));

    if (slowTests.length > 0) {
      console.warn(`Slow tests in ${run.spec.relative}:`, slowTests);
    }
  });
});
```

**[community]** WHY: `after:run` is the correct hook for post-suite cleanup (not `after()` in specs, which runs per-spec). Using it for Slack notifications ensures the message fires once per run, not once per spec file. The `results.runs[].tests` array gives per-test duration, making it the ideal place to surface slow tests that should be moved to dedicated performance test infrastructure. Note: `after:run` only fires when using `cypress run` (headless CI), not during `cypress open` (interactive dev).

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

11. **`cypress-file-upload` plugin no longer needed** [community] — The legacy `cypress-file-upload` community plugin (`cy.attachFile()`) is incompatible with Cypress 12+ and causes subtle failures when the input element is hidden. Use the built-in `cy.selectFile()` (available since Cypress 9.3) instead; it handles both visible and programmatically triggered inputs and accepts `Cypress.Buffer` for dynamic file content, eliminating the dependency entirely.

12. **POM methods returning DOM elements cause async issues** [community] — Teams porting Selenium-style POM to Cypress sometimes write methods that return `cy.get(...)` results (Cypress Chainable objects) and store them in variables. A Cypress Chainable is not a DOM element — it's a command queued for later execution. Using a stored Chainable reference after the queue has moved on produces confusing "subject changed" errors. POM methods in Cypress should return `this` (for fluency) or `void`, and assertions should live inside the method or in the calling test.

13. **Shadow DOM queries silently returning empty sets** [community] — When `includeShadowDom` is not enabled and you try to `cy.get()` an element inside a Web Component's shadow root, Cypress returns an empty jQuery set without throwing. The test then times out with "element not found" rather than a meaningful shadow-boundary error. Always set `includeShadowDom: true` globally or use `.shadow()` explicitly when testing Web Components.

14. **`cy.exec()` environment differs from your terminal** [community] — `cy.exec()` inherits the Node.js subprocess environment, which may not have the same PATH, environment variables, or shell aliases as your interactive terminal. Scripts that work locally can fail in `cy.exec()` with "command not found". Use absolute paths for executables or set `env` explicitly: `cy.exec('cmd', { env: { PATH: process.env.PATH } })`.

15. **`cy.its()` silently resolves `undefined` for missing properties** [community] — If you call `cy.its('body.nonexistent.deeply.nested')` on a response object and an intermediate key is `undefined`, Cypress does not immediately throw — it continues the chain with `undefined` and only fails at the downstream assertion. This makes debugging difficult because the error points to the assertion, not the missing key. Always assert that the parent key exists before traversing deeply: `cy.its('body.user').should('have.property', 'address').its('city').should('eq', 'Berlin')`.

16. **`cy.all()` not available before Cypress 13.4** [community] — Attempting to use `cy.all()` in older versions causes a `cy.all is not a function` runtime error. Check `cypress.version` in `beforeAll` or pin the Cypress version in CI to ensure the API is available. The equivalent workaround in older versions is sequential `cy.wait('@alias1'); cy.wait('@alias2');` which is slower but universally supported.

17. **CDP network throttling resets on each `cy.visit()`** [community] — The Chrome DevTools Protocol emulation set via `Cypress.automation('remote:debugger:protocol', ...)` applies to the current page session. When Cypress calls `cy.visit()` it navigates the page, but the CDP session is reused — however, some browser versions reset network conditions on navigation. Always set throttling AFTER `cy.visit()` or re-apply it in a `cy.intercept()` `req.on('response', res => res.setDelay(...))` approach if you need it for requests triggered immediately on page load.

18. **Sinon stubs not restored between tests by default** [community] — `cy.stub()` and `cy.spy()` created in a test body are automatically restored after the test (Cypress wraps Sinon's sandbox). However, stubs added in `before()` (not `beforeEach()`) persist across all tests in the block. Always use `beforeEach()` for stubs that should be fresh per test, and never manually call `stub.restore()` — let Cypress manage it to avoid double-restore errors.

19. **`cy.each()` callback index is 0-based but error messages are 1-based in Cypress output** [community] — When a `cy.each()` callback throws for element at index 2, the Cypress test runner displays the failure with a 0-based index. Teams often spend time looking at the wrong element in screenshots. Log `index + 1` in your error message: `cy.wrap($el).find('[data-cy="price"]').should('exist').then(() => {}, () => { throw new Error(\`Row ${index + 1} missing price\`) })`.

20. **`cy.reload(true)` bypasses Service Worker cache** [community] — Hard-reloading with `cy.reload(true)` forces the browser to skip the Service Worker cache and re-fetch all assets from the network. For PWA tests that rely on cached assets being served offline, use `cy.reload()` (no argument) to preserve the SW cache. Using `cy.reload(true)` in these tests will cause false failures when the network is intercepted or throttled.

21. **`cy.contains()` returns the first match globally, not within scope** [community] — `cy.contains('Remove')` queries the entire document, not just the current subject's descendants. If you chain it off a `cy.get('[data-cy="cart-item"]')` without `.within()`, it may still match a "Remove" button outside the cart item. Always scope with `.within()` or chain `.contains()` directly: `cy.get('[data-cy="cart-item"]').eq(0).contains('Remove').click()`.

22. **`before()` hook failures skip all tests in the suite silently** [community] — If a `before()` hook throws (e.g., a seeding API call returns 500), Cypress marks all tests in the describe block as failed without running them. The error message says "before all hook failed" but doesn't clearly indicate WHICH test failed. Add explicit `cy.log()` statements in `before()` hooks and consider wrapping the hook in error handling to surface the failure type early.

23. **GraphQL intercepts matching all operations when only one should match** [community] — When intercepting `/graphql`, a single `cy.intercept()` stub catches ALL GraphQL operations (queries, mutations, subscriptions). If you stub only `GetUser` but a concurrent `GetCart` also fires, the stub may reply to the wrong operation or cause the test to time out waiting for `@alias`. Always check `req.body.operationName` before calling `req.reply()`, or use separate intercepts with unique aliases for each operation.

24. **`cy.wait(['@a', '@b'])` order is non-deterministic** [community] — When passing an array of aliases to `cy.wait()`, Cypress resolves each alias in the order the requests actually arrived, not in the order listed in the array. The result array from `cy.wait([...]).spread(...)` maps to *completion* order. If your assertion depends on a specific index being a specific alias, use sequential `cy.wait('@a'); cy.wait('@b')` instead.

25. **`cy.clock()` must be called before the page action that starts timers** [community] — If the timer that auto-dismisses a toast is started inside a `useEffect` on mount, calling `cy.clock()` AFTER `cy.visit()` will not freeze that timer — it already started with the real clock. Always call `cy.clock()` before `cy.visit()` to ensure all timers started during page load are under Cypress's control.

26. **`cy.intercept()` `times` option does not reset between tests** [community] — If you define a `cy.intercept()` with `times: 1` in a `beforeEach()`, the stub is consumed after the first test that triggers the route. The second test's `beforeEach` registers a fresh stub — but if tests share a `before()` hook that sets up intercepts, the counter persists. Always register time-limited intercepts in `beforeEach()`, not `before()`.

27. **Conditional UI testing leads to intermittent failures** [community] — Using `cy.get('[data-cy="modal"]').then($el => { if ($el.length) ... })` to handle optional UI elements works but creates non-deterministic tests: if the modal appears asynchronously after the `.then()` snapshot, the condition is evaluated too early. Prefer deterministic setup (set cookies, local storage, or seed flags before visiting) so optional elements are either always present or always absent in each test.

28. **`.filter()` and `.not()` use jQuery's synchronous CSS matching** [community] — `.filter('.active')` on a Cypress collection applies jQuery's selector engine at the moment the filter runs, without retry. If the CSS class is applied asynchronously (e.g., a fade-in animation adds the class after 200ms), `.filter('.active')` will return an empty set. Wrap the filter in `.should($list => expect($list.filter('.active')).to.have.length.gte(1))` to trigger retry.

29. **`cy.window().then()` localStorage writes execute immediately, not queued** [community] — When you call `cy.window().then(win => { win.localStorage.setItem('key', 'val'); })`, the `setItem` runs synchronously inside the Cypress command queue's resolution step. This means subsequent `cy.get()` calls in the same test will see the written value. However, if the page was already loaded before the write, the React/Angular app may not react to the localStorage change — you usually need to `cy.reload()` after writing to localStorage for the app to pick up the new value.

30. **`Cypress._` Lodash does not include all lodash methods** [community] — Cypress bundles a specific Lodash version that may not match the latest lodash API. Methods added in recent lodash versions may be absent. If you need a specific lodash method not available in `Cypress._`, import lodash explicitly in your support file: `import _ from 'lodash'` — this is safe since Cypress runs in a Node.js/browser hybrid environment.

31. **`.type('{ctrl}s')` modifier keys are case-sensitive on macOS** [community] — On macOS, Cypress uses `{ctrl}` for the Control key and `{meta}` for the Command key (⌘). Many macOS applications use Command (not Control) for shortcuts like save, copy, paste. If your tests run on macOS CI agents, use `{meta}s` for "⌘+S" and `{ctrl}s` for "Ctrl+S" on Linux/Windows. Platform-agnostic: detect `Cypress.platform` and choose the modifier: `const MOD = Cypress.platform === 'darwin' ? '{meta}' : '{ctrl}'`.

32. **`cy.request()` with FormData loses the Content-Type boundary** [community] — When using `cy.request()` with a FormData body, Cypress may serialize it incorrectly if you manually set `Content-Type: multipart/form-data`. The `Content-Type` header for multipart must include the boundary string (e.g., `multipart/form-data; boundary=----...`), which is auto-generated by the browser's fetch API. Do NOT set Content-Type manually when sending FormData — omit it and let Cypress/the browser set it correctly.

33. **`.check()` fails on hidden inputs even when the label is visible** [community] — Custom checkbox components often hide the `<input type="checkbox">` and style a visible `<label>` or `<div>` instead. `.check()` targets the input and will fail with "element is not visible" on hidden inputs. Use `cy.get('[data-cy="custom-checkbox"]').click()` on the visible label/div, or pass `{ force: true }` only as a last resort (it bypasses visibility checks and can mask real accessibility issues).

34. **`window.open()` stub only works when set before the action** [community] — `cy.stub(win, 'open')` must be registered before the user action that triggers `window.open()`. If you stub inside a `.then()` callback that runs asynchronously after the button click, the original `window.open()` has already been called. Always set up stubs in `beforeEach()` or before any interaction commands in the test body.

35. **`req.alias` in `cy.intercept()` handler overrides the `.as()` alias** [community] — If you call both `cy.intercept(...).as('myAlias')` and set `req.alias = 'dynamicAlias'` inside the handler, the `req.alias` takes precedence. This is by design and documented, but teams often expect the `.as()` name to win. Decide on one aliasing strategy per intercept — either use `.as()` for static aliases or `req.alias` for dynamic ones, never both on the same intercept.

36. **`cy.intercept()` does not intercept WebSocket or Server-Sent Events** [community] — `cy.intercept()` only intercepts HTTP/XHR/fetch requests. If your app uses WebSocket connections (e.g., `ws://` or `wss://`) or SSE streams (`text/event-stream`), Cypress cannot stub or spy on them directly. The workaround is to stub the WebSocket constructor via `cy.window().then(win => cy.stub(win, 'WebSocket').as('ws'))` for constructor-level assertions, or use `cy.task()` to control the server side directly. For SSE, intercept the initial HTTP handshake request but know that the streaming data is not interceptable.

37. **Nested `cy.intercept()` in `beforeEach` causes route accumulation** [community] — Each call to `cy.intercept()` adds a new route to Cypress's routing table. If you register the same route in `beforeEach()` for a 50-test suite, you end up with 50 stacked intercepts for that route. While the last registration wins, the accumulated routes consume memory and can cause subtle ordering issues. Use `cy.intercept()` inside individual tests only when the stub is unique per test; use `before()` for shared stubs that should exist for the entire suite.

38. **`cy.intercept()` body matching is a shallow, not deep, partial match** [community] — When you specify `body: { type: 'task' }` in a routeMatcher, Cypress matches requests whose body *contains* the `type` field with that value, but only at the top level. Nested fields (e.g., `body: { metadata: { version: 2 } }`) are matched shallowly — the outer key must exist but inner keys are compared by reference equality, not deep subset matching. For deep partial matching, use a `RouteHandler` function and inspect `req.body` manually with `expect(req.body).to.containSubset({...})`.

39. **`cy.stub().callsFake()` does not restore the original on `cy.restore()` if the stub was created outside a test** [community] — Cypress's automatic stub cleanup runs after each test and restores all stubs created inside that test. If you create stubs in `before()` (once for the suite), they are NOT automatically restored after individual tests — only after the entire suite. If a test in the middle of a suite needs the original function, call `stub.restore()` manually and recreate the stub in `afterEach`. This is a common source of state leakage between tests when using `callsFake()` on window methods.

40. **`cy.request()` follows redirects automatically — use `failOnStatusCode: false` for 3xx assertions** [community] — By default `cy.request()` follows HTTP redirects and returns the final response. If you need to assert that a request returns a `301 Moved Permanently`, set `followRedirect: false` in the options to get the original redirect response. Without this, the resolved response always has a 2xx status from the final destination, hiding the redirect chain entirely.

41. **Angular component tests fail without `NoopAnimationsModule`** [community] — Angular components that use animation (`@angular/animations`) trigger async state changes during tests. Without importing `NoopAnimationsModule` (or `BrowserAnimationsModule`) in the component mount, Cypress cannot know when animations finish and assertions on post-animation DOM state become timing-dependent. Always add `imports: [NoopAnimationsModule]` to your mount options for Angular component tests to make animations synchronous.

42. **Cypress Cloud Smart Orchestration `--auto-cancel-after-failures` is set per project, not per run** [community] — The `--auto-cancel-after-failures N` flag sets a project-level threshold in Cypress Cloud that persists across all runs. Temporarily setting it for a single CI run does not work as expected — the Cloud uses the project's saved configuration. To change the threshold for a specific run (e.g., raising it during a known-flaky release window), update the project settings in the Cypress Cloud UI, then reset it afterwards. Mixing per-run CLI flags with Cloud project settings leads to unpredictable cancellation behavior.

43. **`before:browser:launch` args pushed after Cypress sets them can conflict** [community] — When using `launchOptions.args.push(...)`, Cypress may have already added its own flags (e.g., `--remote-debugging-port`). Pushing a conflicting duplicate flag (e.g., a second `--disable-gpu`) can cause Chrome to log warnings or, in rare cases, fail to launch. Always check `launchOptions.args` for existing flags before pushing: `if (!launchOptions.args.includes('--disable-gpu')) launchOptions.args.push('--disable-gpu')`.

44. **`cy.type()` masking with `{ log: false }` still logs the selector** [community] — When you call `cy.get('[data-cy="password"]').type(secret, { log: false })`, the `log: false` suppresses the `type` log entry, but the preceding `cy.get()` command still logs the selector string. The test log shows `get [data-cy="password"]` which reveals the element name. For inputs labeled "password" this is fine, but for generic `[data-cy="api-key"]` inputs the element name also hints at the value type. Use the `Cypress.Commands.overwrite('type', ...)` masking approach (see section above) which replaces the log entry text rather than suppressing it entirely.

45. **Direct database seeding via `cy.task()` bypasses application-level audit logging** [community] — Using Prisma/Knex directly in `cy.task()` for test setup is fast and reliable, but it skips all middleware: audit logs, event hooks, cascade rules enforced by the application layer, and Elasticsearch index updates. If your test relies on data being indexed or events being emitted, seed via the API (`cy.request()`) despite the extra overhead. Reserve direct DB seeding for states that the API cannot create (corrupted data, expired dates, constraint violations).

46. **`cy.stub(win, 'open').callsFake()` must be set up before `cy.visit()`** [community] — `window.open` stubs need to be registered before the page loads if the app auto-triggers a popup on mount (e.g., a `useEffect` that opens a chat widget). If you stub after `cy.visit()`, the window has already loaded and any popup triggered during mount has already called the real `window.open`. Set up the stub using `cy.visit(url, { onBeforeLoad: (win) => cy.stub(win, 'open').as('popup') })` to guarantee the stub is in place before the first script runs.

47. **Factory functions using `Date.now()` produce non-deterministic IDs across parallel workers** [community] — Test data factories that generate IDs or emails using `Date.now()` (e.g., `email-${Date.now()}@e2e.test`) can produce duplicate values when two parallel Cypress workers start within the same millisecond. Use a combination of `Date.now()` + `Math.random()` or, better, a UUID v4 library: `import { v4 as uuidv4 } from 'uuid'`. In factories: `id: uuidv4()`, `email: \`user-${uuidv4().slice(0, 8)}@e2e.test\``.

48. **`cy.checkA11y()` only catches violations visible at test time — not after interactions** [community] — `cypress-axe`'s `cy.checkA11y()` scans the DOM at the moment it is called. If a modal opens, a dropdown expands, or an error message appears after a form submission, none of those dynamically revealed elements are checked unless you call `cy.checkA11y()` again after each interaction. For thorough coverage: call `cy.injectAxe()` once and `cy.checkA11y()` after every significant state change (form submit, modal open, accordion expand, tab change). Tracking axe violations per page state is more effective than a single check on page load.

49. **`cy.stub().onCall(n)` state carries across retries** [community] — When Cypress retries a failed test, it re-runs the test body but does NOT recreate stubs registered in `before()` or at module scope. If you use `cy.stub().onCall(0)` and `onCall(1)` to simulate a two-step flow (e.g., MFA challenge then success), a retried test will start at `onCall(2)` — past the configured behavior — and get `undefined` responses. Always register stubs in `beforeEach()` so they're freshly created on each attempt.

50. **`testIsolation: false` can cause invisible cross-spec pollution** [community] — Disabling `testIsolation` (Cypress 12+) prevents the automatic browser state reset between tests. If any test writes to `sessionStorage` or `indexedDB` without cleaning up, subsequent tests in the file will see that data even if they don't explicitly depend on it. The failure mode is non-deterministic: tests pass when run alone but fail in a full-suite run. Always audit `testIsolation: false` suites with explicit `afterEach` cleanup, or better, migrate them to `testIsolation: true`.

51. **CTRF reporter and `cypress-multi-reporters` conflict on `reporter` key** [community] — When using `cypress-multi-reporters` to combine CTRF with the built-in `spec` reporter, both reporters must be listed in `reporter-config.json`, not split between `cypress.config.ts` and the config file. Setting `reporter: 'spec'` in `cypress.config.ts` and listing CTRF only in the multi-reporter config causes CTRF to be silently ignored — no output file is generated. Always verify CTRF output exists after the first CI run before depending on it for dashboards.

52. **`cy.stub().callsFake()` on `window.fetch` does not affect `XMLHttpRequest` (and vice versa)** [community] — Modern apps may use either `fetch` or `XMLHttpRequest` depending on the library (Axios uses XHR by default; native browser code uses `fetch`). Stubbing `window.fetch` has no effect on XHR calls, and `cy.intercept()` intercepts both. If your test stubs `window.fetch` but the app uses Axios without `adapter: 'fetch'`, your stub is never called. Use `cy.intercept()` for network-level interception unless you specifically need to test the `fetch` API itself.

53. **WebSocket constructor stub must be set in `onBeforeLoad`, not after `cy.visit()`** [community] — The WebSocket constructor (`new WebSocket(url)`) is typically called during module initialization or inside a `useEffect` on mount. Stubbing `win.WebSocket` after `cy.visit()` has returned means the app's `useEffect` has already run and the real WebSocket connection is already open. The stub never intercepts anything. Always set WebSocket stubs inside the `cy.visit(url, { onBeforeLoad })` callback to guarantee the stub is in place before the first script executes.

54. **`cy.task()` does not retry automatically — wrap in `.should()` for polling** [community] — `cy.task()` executes once and yields the result. If you call `cy.task('email:getLatest', address)` immediately after triggering a transactional email, the task may return `null` because the email hasn't arrived yet. `cy.task().should('not.be.null')` causes Cypress to retry the entire `task → assertion` chain, effectively polling until the email arrives or the timeout expires. Without `.should()`, a single null result fails the test immediately rather than waiting.

55. **`cy.stub(win, 'WebSocket')` breaks apps that check `instanceof WebSocket`** [community] — Replacing the global `WebSocket` constructor with a stub class means `someSocket instanceof WebSocket` returns `false` for both stub instances and real WebSocket objects (since the `WebSocket` reference now points to your stub). Apps that use `instanceof` checks (e.g., in reconnection logic or type guards) may silently skip branches or crash. Test for this by logging `someSocket instanceof WebSocket` in the browser console after stubbing. If it matters, copy the original reference: `const OriginalWebSocket = win.WebSocket; cy.stub(win, 'WebSocket').callsFake((...args) => { const ws = new OriginalWebSocket(...args); /* wrap */ return ws; })`.

56. **`cy.trigger('mouseover')` does not work on elements that use CSS `:hover` pseudo-class** [community] — `cy.trigger('mouseover')` fires a DOM `mouseover` event, but CSS `:hover` styles are applied by the browser's rendering engine based on actual pointer position — not JavaScript events. If your tooltip is revealed via `div:hover { display: block }` (pure CSS), `cy.trigger('mouseover')` will not make it appear because the browser's internal hover state is not updated by synthetic events. Use `cy.realHover()` from `cypress-real-events` (fires real pointer events via CDP) for CSS hover states, or use `cy.trigger()` only for JavaScript-driven hover handlers (`mouseenter`, `mouseover` event listeners).

57. **TypeScript path aliases require both `tsconfig.json` and bundler configuration** [community] — Setting `"paths": { "@/*": ["src/*"] }` in `tsconfig.json` only affects TypeScript's type resolution at compile time — it does NOT make the alias work at runtime. Vite requires the alias in `vite.config.ts` under `resolve.alias`; webpack requires it in `resolve.alias` or `resolve.modules`. A common symptom: tests compile successfully with TypeScript but fail at runtime with "Cannot find module '@/...'" because the bundler doesn't know about the alias. Always verify both layers are configured when adding path aliases.

58. **`window.performance.getEntriesByType('navigation')` returns empty until page finishes loading** [community] — If you call `cy.assertPageLoadTime()` immediately after `cy.visit()`, the `loadEventEnd` timing may be 0 because the load event hasn't fired yet. Always assert on a meaningful element (`cy.get('[data-cy="hero"]').should('be.visible')`) before reading performance entries to ensure the page has fully loaded. Additionally, performance timing is not available in Electron — run timing assertions only against Chrome or Firefox by detecting `Cypress.browser.name !== 'electron'`.

59. **`@cypress/grep` tag filtering does not propagate to `before()` hooks** [community] — When using `--env grep=@smoke` to run a subset of tests, Cypress still executes `before()` hooks in every `describe` block regardless of whether any tests in that block match the grep filter. If your `before()` hooks do expensive setup (DB seeding, API login), they run even for suites where all tests are filtered out, wasting CI time. Migrate expensive setup from `before()` to `beforeEach()` with `cy.session()` caching, which only runs when the session doesn't exist — reducing overhead for grep-filtered runs.

60. **Storybook story IDs change when the component's display name changes** [community] — Cypress + Storybook smoke tests that use hardcoded story IDs (e.g., `components-button--default`) break silently when the Storybook story title is renamed. Cypress `cy.visit()` on a non-existent story ID shows an empty iframe rather than throwing an error — the test passes but isn't actually testing anything. Always assert on a specific element after `cy.visit(storyUrl(...))` to detect a missing story, and run `npx storybook build --quiet` in CI to catch story ID changes before merging.

61. **`@alias.all` for counting requests requires the intercept to be set up before the action** [community] — Asserting `cy.get('@save.all').should('have.length', 1)` only counts requests intercepted after `cy.intercept()` was registered. If the intercept is set up after the request fires (e.g., inside a `.then()` callback that runs asynchronously), some requests are missed. Set up ALL intercepts at the beginning of the test body, before any UI interactions, to ensure every request is captured in the count.

62. **Svelte component tests fail with `Cannot use 'import.meta.env'` outside of Vite** [community] — Svelte components that read `import.meta.env.VITE_API_URL` work in the dev server but throw in Cypress component tests if the Vite config doesn't expose environment variables. Add `define: { 'import.meta.env.VITE_API_URL': JSON.stringify('http://localhost:3000') }` to the Vite config in `cypress.config.ts` to inject test values. Never set `import.meta.env.VITE_API_URL` to `undefined` — Svelte's compiler inlines `import.meta.env.*` at build time, so a missing define causes a literal `undefined` string in the bundle.

63. **`faker.seed()` must be called once per test file, not per test** [community] — `faker.seed(42)` resets the internal PRNG to a fixed starting point. If called in `beforeEach`, each test gets the SAME data (same email, same name, same UUID) because the seed resets before every test. Either call `faker.seed()` once at the top of the file (to get different data per test but reproducible per file), or use `faker.seed(Date.now())` in a `before()` hook and log the seed with `cy.log()` so you can reproduce failures.

64. **Clipboard permission grant (`Browser.grantPermissions`) is not supported in Electron** [community] — `Cypress.automation('remote:debugger:protocol', { command: 'Browser.grantPermissions', ... })` works only in Chrome-family browsers (Chrome, Chromium, Edge). Cypress's default Electron browser does not support CDP `Browser.grantPermissions`, and the command silently fails — `navigator.clipboard.readText()` still throws `NotAllowedError`. Always guard clipboard tests with `if (Cypress.browser.name !== 'electron')` or add `{ browser: '!electron' }` to the test block. Run clipboard tests explicitly with `--browser chrome` in CI.

65. **`cy.intercept()` header assertions inside the handler do not fail the test gracefully** [community] — When you call `expect(req.headers['x-api-version']).to.eq('2')` inside a `cy.intercept()` handler and the assertion fails, Cypress logs an `AssertionError` in the browser console but does NOT automatically fail the currently running test. The test continues, and the assertion failure surfaces as an `uncaught:exception` event. Wrap route handler assertions in a `try/catch` and call `req.destroy()` or `throw` to ensure the test fails clearly: `if (!req.headers['x-token']) { req.reply({ statusCode: 401 }); throw new Error('Missing auth header'); }`.

66. **`Emulation.setGeolocationOverride` persists across `cy.visit()` calls but resets between tests** [community] — Once you call `cy.setGeolocation({...})` using the CDP command, the override applies to all subsequent page loads in the same test. When `testIsolation: true` (default in Cypress 12+), the override is cleared between tests because Cypress navigates to `about:blank` which triggers a new browser context. However, if `testIsolation: false`, the geolocation override from one test leaks into subsequent tests. Always call `cy.setGeolocation()` in the test body (not a global `before()`), or reset with `Emulation.clearGeolocationOverride` in `afterEach`.

67. **Weighted parallel CI jobs using separate `--ci-build-id` suffixes create separate Cypress Cloud runs** [community] — When you split tests into `fast`, `medium`, and `slow` job groups with different `--ci-build-id` values (e.g., `${{ github.run_id }}-fast`), Cypress Cloud treats them as three separate runs. This means the Flaky Test dashboard, Smart Orchestration (fail-fast), and branch status checks do not aggregate across groups — a failure in `e2e-slow` does not cancel `e2e-fast`. Use the same `--ci-build-id` for all groups if you want unified Smart Orchestration, or accept separate runs for independent group reporting.

68. **`cy.window().then()` callbacks are NOT retried — use `.should()` for polling window properties** [community] — Unlike `cy.get()` which retries until the element appears, `.then()` callbacks execute once and do not retry. `cy.window().then(win => { expect(win.appReady).to.be.true; })` will immediately fail if `appReady` is not yet set. Replace with `cy.window().should('have.property', 'appReady', true)`, which Cypress retries until the assertion passes or the timeout expires. For nested window properties use `cy.window().its('store.state.user.id').should('eq', 42)`.

69. **`cy.origin()` requires the `experimentalModifyObstructiveThirdPartyCode` option for some SSO flows** [community] — When testing third-party SSO providers (Okta, Azure AD, Google) with `cy.origin()`, some providers serve pages with Content-Security-Policy or X-Frame-Options headers that block Cypress from instrumenting the page. `experimentalModifyObstructiveThirdPartyCode: true` in `cypress.config.ts` rewrites these security headers during testing so Cypress can modify the JavaScript context. Be aware this option also strips CSP headers from all third-party origins — never enable it in production builds, and confine it to the `e2e` configuration block only. For production-safe SSO testing, use `cy.session()` to cache the authenticated state after a single manual sign-in.

70. **Cypress 15 fails to launch on Ubuntu 20.04 (glibc < 2.31)** [community] — Cypress 15 prebuilt binaries require glibc 2.31 or higher. Ubuntu 20.04 ships glibc 2.31 but is approaching end-of-life; Ubuntu 18.04 (glibc 2.27) will not work at all. Teams still using `runs-on: ubuntu-20.04` in GitHub Actions may see a cryptic binary launch failure: `error while loading shared libraries: libm.so.6: GLIBC_2.33 not found`. Upgrade to `ubuntu-22.04` (glibc 2.35) or `ubuntu-24.04` (glibc 2.39). In Docker-based pipelines, update from `cypress/included:14.x` to `cypress/included:15.x` images — they are built on Node 22/Debian 12 which satisfies the glibc requirement.

71. **`cy.intercept()` route order matters — more specific routes must be registered first** [community] — Cypress matches intercepts in registration order; the first matching route wins for a given request. If you register `cy.intercept('GET', '/api/**')` before `cy.intercept('GET', '/api/products*')`, the wildcard catches all API calls including `/api/products`, and the specific stub is never reached. Register specific routes BEFORE generic wildcards to ensure priority. This is particularly subtle in shared `beforeEach` blocks that register a global catch-all, then individual tests try to register specific stubs that are silently outrun by the earlier wildcard.

72. **Docker container mismatch between install job and parallel workers causes binary not found** [community] — When using a two-job GitHub Actions pattern (install → workers), the install job must use the same Docker image as the worker jobs. If the install job runs on `ubuntu-24.04` (bare runner) but workers use `cypress/browsers:22.15.0` (Docker container), the Cypress binary is cached at a different path and is not found in the container. Cypress then downloads the binary fresh in every parallel worker, defeating the entire caching strategy and adding 1-2 minutes per worker. Always match the runtime environment: if workers use Docker containers, the install job must also use the same Docker container.

73. **Svelte 5 `$props()` runes are not accessible via `extensions.on` in Cypress CT** [community] — In Svelte 4, components that used `createEventDispatcher()` could have their events intercepted via `extensions.on.eventName` in the `cy.mount()` options. In Svelte 5, events are replaced by callback props (`on:click` → `onclick`), and the `createEventDispatcher()` API is deprecated. The `extensions.on` mount option silently does nothing for Svelte 5 callback props — stubs registered there are never called, and the test passes (or fails) without ever receiving the event. Always pass event handler stubs as component props: `mount(MyComponent, { props: { onActionName: cy.stub().as('handler') } })` in Svelte 5.

74. **React 19 `act()` warnings in Cypress CT do not fail tests but indicate state update timing issues** [community] — Cypress Component Testing does not wrap commands in `React.act()` — it relies on its own retry mechanism. React 19 logs `Warning: An update to X was not wrapped in act(...)` when a state update is triggered from outside React's scheduler (e.g., a timer callback, a WebSocket message, or a third-party library that directly calls `setState`). These warnings appear in the browser console but do NOT fail Cypress tests. However, they indicate that your assertion may be racing the state update. Fix by: (1) asserting on the final rendered state with `.should()` (which retries) rather than immediately after the trigger, (2) using `cy.clock()` to control timer-driven state updates, or (3) using `cy.intercept()` to wait for the network trigger that drives the state change.

75. **TypeScript 6 `verbatimModuleSyntax: true` breaks Cypress support file imports that mix type and value imports** [community] — TypeScript 6 enables `verbatimModuleSyntax` by default in strict mode, requiring all type-only imports to use `import type`. In Cypress support files, it is common to write `import { CypressTasks } from './task-types'` where `CypressTasks` is a type-only export. Under `verbatimModuleSyntax`, this causes a compile error: `This import is never used as a value and must use 'import type'`. Running `npx tsc --noEmit` on your `cypress/` directory after enabling TypeScript 6 reveals all affected imports. Fix: replace `import { Type }` with `import type { Type }` throughout `cypress/support/`, `cypress/pages/`, and `cypress/plugins/` directories. This is a purely mechanical change and can be automated with the TypeScript language server's "add import type" quick fix or `npx ts-expect-error --fix`.

76. **`cy.env(['KEY']).then()` nesting leads to excessively deep callback pyramids** [community] — The async nature of `cy.env()` (Cypress 15.10+) means that any test logic requiring multiple env vars must be nested inside a `.then()`. Teams that naively migrate from `Cypress.env()` to `cy.env()` end up with deeply nested code: `cy.env(['A']).then(({ A }) => { cy.env(['B']).then(({ B }) => { cy.request(...) }) })`. Instead, request all required keys in a single `cy.env()` call: `cy.env(['API_TOKEN', 'BASE_URL', 'TEST_EMAIL']).then(({ API_TOKEN, BASE_URL, TEST_EMAIL }) => { /* all vars available here */ })`. For suites that use the same vars across many tests, create a typed helper command (e.g., `cy.loginSecure()`) that calls `cy.env()` internally — callers never see the `.then()` nesting.

77. **`ElementSelector` API replaces Selector Playground API in Cypress 15** [community] — The Selector Playground (the crosshair icon in the Cypress App that suggested selectors) was renamed to the **ElementSelector** in Cypress 15 as part of the UI redesign. If you have plugin code or documentation referencing `Cypress.SelectorPlayground`, the API was renamed to `Cypress.ElementSelector`. The behavior and method signatures remain identical: `Cypress.ElementSelector.defaults({ selectorPriority: ['data-cy', 'data-testid', 'id'] })` still works. Teams using third-party plugins that extend the selector playground may need to update plugin versions if they reference the old API name.

---

## CI Considerations

- **Run headless** — `npx cypress run` defaults to headless Electron. For Chrome: `--browser chrome --headless`.
- **Parallelise with Cypress Cloud** — Use `--parallel --record --ci-build-id $CI_BUILD_ID` to split specs across machines. Requires a Cypress Cloud project key in `CYPRESS_RECORD_KEY`.
- **Artifact retention** — Set `screenshotsFolder` and `videosFolder` in `cypress.config.ts`; upload to CI artifact store on failure only to save storage.
- **`baseUrl` via env** — Never hardcode URLs. Set `baseUrl` in `cypress.config.ts` and override with `CYPRESS_BASE_URL=https://staging.example.com` in CI.
- **Docker image** — Use the official `cypress/included` or `cypress/browsers` image; it bundles all browser deps and avoids missing shared-library issues on stripped CI images. Ensure install job and worker jobs use the same Docker image.
- **Retry flaky tests** — Add `"retries": { "runMode": 2, "openMode": 0 }` in `cypress.config.ts` to automatically re-attempt failed tests in CI without masking real failures locally.
- **`--spec` flag for targeted runs** — In monorepos or large suites, run only changed specs with `--spec "cypress/e2e/checkout/**"` to keep PR feedback loops fast.
- **Node version pinning** — Pin Node.js to 20 or 22 (LTS) or 24 for Cypress 15+. Node.js 18 support was dropped in Cypress 15. Node.js 24 is supported from Cypress 15.0. Cypress 15 also requires glibc 2.31+ — use `ubuntu-22.04` or `ubuntu-24.04` in GitHub Actions (not `ubuntu-20.04`).
- **`experimentalOriginDependencies`** — Set to `true` in `cypress.config.ts` to allow `cy.origin()` to load custom commands defined in the support file inside origin callbacks; without it, commands like `cy.loginViaApi()` are not available inside `cy.origin()`.
- **Flakiness root-cause beyond retries** — Retries mask symptoms; fix root causes: (1) ensure `cy.intercept()` is registered before `cy.visit()`; (2) replace `cy.wait(ms)` with `cy.wait('@alias')`; (3) use `beforeEach` state resets; (4) avoid `cy.get().then()` snapshot patterns for assertions.
- **Cypress Cloud Flaky Test Detection** — Cypress Cloud automatically marks tests as "flaky" when they pass on retry. Review the Flaky Tests dashboard weekly; a test flaking in CI 3+ times signals a test design issue, not just infrastructure noise.
- **Spec grouping for monorepos** — Use `--group` to label parallel runs by app/service: `npx cypress run --record --parallel --group "app-checkout"`. View separate dashboards per group in Cypress Cloud without merging results.
- **`--auto-cancel-after-failures N`** — Cancel the entire parallel run after N failures to save CI minutes on catastrophic regressions. Set N to 5-10 for large suites; too low causes false cancellations on known-flaky tests.
- **Memory leak detection in long runs** — Large suites (200+ tests) can accumulate memory. Use `experimentalMemoryManagement: true` and `numTestsKeptInMemory: 5` together. Watch for browser crashes in CI — they typically signal memory pressure, not test logic failures.
- **`GITHUB_TOKEN` in GitHub Actions** — Always pass `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` to the Cypress action step. Without it, Cypress Cloud misidentifies reruns as new builds and Smart Orchestration cancels them immediately (zero tests run). Also pass `COMMIT_INFO_MESSAGE` and `COMMIT_INFO_SHA` for correct PR commit context in Cloud dashboards.
- **`cypress-io/github-action@v7`** — The current major version of the official GitHub Action is `v7` (updated 2026). It supports `ubuntu-24.04`, the `build` shorthand for pre-test build steps, and improved artifact caching. The previous `v6` action is still functional but does not receive new features.
- **Cypress Dashboard API for custom reporting** — Use the Cypress Cloud REST API (`GET /projects/:id/runs`) to pull flakiness rates into internal dashboards or Slack alerts. Token auth via `CYPRESS_API_KEY`.
- **Cache `node_modules` and Cypress binary in CI** — The Cypress binary (~200 MB) and `node_modules` are the main sources of slow CI setup. Cache both using the CI system's cache step: cache `node_modules` by `package-lock.json` hash, and the Cypress binary by `CYPRESS_CACHE_FOLDER` path (defaults to `~/.cache/Cypress`). A warm cache reduces setup time from 2-3 min to ~10 s.
- **Use `cy.origin()` over `chromeWebSecurity: false`** — The `chromeWebSecurity: false` config flag disables cross-origin restrictions globally, enabling cross-domain navigation without errors. However, it also disables CORS, mixed-content blocking, and CSP — making your test environment unrealistically permissive. Prefer `cy.origin()` for multi-domain flows; it correctly simulates the real browser security model.
- **`path` module usage in `setupNodeEvents`** — Always import `path` via `require('path')` rather than `import` in `setupNodeEvents` — the `setupNodeEvents` function runs in Node.js CommonJS context even if the rest of the config file uses ESM. Using `import path from 'path'` in a `.mjs`-named config file is fine, but mixing ESM `import` with CJS `require()` in the same `setupNodeEvents` will cause errors in some bundler configurations.

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
    runs-on: ubuntu-24.04       # glibc 2.39 — satisfies Cypress 15 minimum (2.31)
    container:
      image: cypress/browsers:22.15.0   # pin browser versions for consistency
    strategy:
      matrix:
        # Run 3 parallel machines
        containers: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: cypress-io/github-action@v7  # v7 is the current major (2026)
        with:
          record: true
          parallel: true
          ci-build-id: "${{ github.run_id }}-${{ github.run_attempt }}"
          browser: chrome
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          CYPRESS_BASE_URL: ${{ vars.STAGING_URL }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # required for Cloud PR detection
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

Integrate `cypress-axe` to catch accessibility regressions automatically. Run axe after every significant state change, not just on initial page load.

```typescript
// cypress/support/e2e.ts
import 'cypress-axe';

// Custom command to log violations — improve axe output readability
Cypress.Commands.add('checkAccessibility', (context?: string | Node | null) => {
  cy.checkA11y(
    context ?? undefined,
    {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa'] },
    },
    // Custom violation handler — logs each violation with its impact level
    (violations) => {
      violations.forEach((violation) => {
        cy.log(`[a11y:${violation.impact}] ${violation.id}: ${violation.description}`);
        violation.nodes.forEach((node) => {
          cy.log(`  Target: ${node.target.join(', ')}`);
        });
      });
    },
    // failSilently: false means the test fails if violations are found
    false,
  );
});

// In a spec — check accessibility after modal opens (not just on initial load)
it('modal is accessible when opened', () => {
  cy.visit('/dashboard');
  cy.injectAxe();

  // Check initial page
  cy.checkAccessibility();

  // Open modal and check again — new content must also be accessible
  cy.get('[data-cy="open-modal-btn"]').click();
  cy.get('[data-cy="modal"]').should('be.visible');
  cy.checkAccessibility('[data-cy="modal"]');
});

// In CI: fail on critical and serious violations only, warn on moderate
it('homepage has no critical accessibility violations', () => {
  cy.visit('/');
  cy.injectAxe();
  cy.checkA11y(
    undefined,
    {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] },
      rules: { 'color-contrast': { enabled: false } },  // skip color rules in dark-mode
    },
    undefined,
    // Set to true to log violations without failing the test (warning mode)
    Cypress.env('A11Y_WARN_ONLY') === 'true',
  );
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

// cypress-image-snapshot alternative — local snapshots without Percy cloud service
// npm install --save-dev @simonsmith/cypress-image-snapshot
// cypress/support/e2e.ts: import { addMatchImageSnapshotCommand } from '@simonsmith/cypress-image-snapshot/command'
// addMatchImageSnapshotCommand()

it('matches local visual snapshot', () => {
  cy.visit('/dashboard');
  // First run creates snapshot; subsequent runs compare
  cy.get('[data-cy="main-chart"]').matchImageSnapshot('main-chart', {
    failureThreshold: 0.01,         // allow 1% pixel difference
    failureThresholdType: 'percent',
    customSnapshotsDir: 'cypress/snapshots',
  });
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

### Test Data Factories (TypeScript)  [community]

Avoid hardcoded fixture JSON for every variation. Use TypeScript factory functions that generate typed test data with sensible defaults and per-test overrides.

### Overwriting cy.type() to Mask Sensitive Values in Logs  [community]

Passwords typed with `cy.type()` are visible in the Cypress command log and CI artifacts (screenshots). Override `cy.type()` to mask values containing the word "password" or marked with a `sensitive` option.

```typescript
// cypress/support/commands.ts — mask sensitive values in command log
Cypress.Commands.overwrite('type', (originalFn, element, text, options) => {
  // Detect sensitive input: either options.sensitive is set, or the element has type="password"
  const isSensitive =
    options?.sensitive === true ||
    Cypress.$(element).attr('type') === 'password';

  if (isSensitive) {
    // Mask the value in the log — replace with asterisks
    const masked = '*'.repeat(String(text).length);
    Cypress.log({
      name:    'type',
      message: masked,
      $el:     Cypress.$(element),
    });
    // Call the original without logging (log: false suppresses the default log entry)
    return originalFn(element, text, { ...options, log: false });
  }

  return originalFn(element, text, options);
});

// Type declaration — add sensitive option
declare global {
  namespace Cypress {
    interface TypeOptions {
      sensitive?: boolean;
    }
  }
}

// Usage — password fields mask automatically (type="password")
cy.get('[data-cy="password"]').type(Cypress.env('USER_PASS'));

// Usage — explicitly mark any field as sensitive
cy.get('[data-cy="api-key-input"]').type(Cypress.env('API_KEY'), { sensitive: true });
```

**[community]** WHY: By default, `cy.type('my-secret-password')` writes the literal value to the Cypress test runner's command log, which is captured in CI screenshots and stored as artifacts. If those artifacts are accessible to anyone with repo access (or CI artifact download permissions), secrets can be leaked. Masking at the `cy.type()` level prevents this without requiring `{ log: false }` at every call site.

### cy.wait() with Timeout Override

Override the default request timeout per `cy.wait()` call for endpoints that are legitimately slow (third-party integrations, long-running reports).

```typescript
it('waits for a slow export job to complete', () => {
  cy.intercept('GET', '/api/export/status').as('exportStatus');

  cy.visit('/reports');
  cy.get('[data-cy="generate-report"]').click();

  // Override the default 5 s wait timeout for this specific slow endpoint
  cy.wait('@exportStatus', { timeout: 60_000 })
    .its('response.statusCode').should('eq', 200);

  cy.get('[data-cy="download-report"]').should('be.visible');
});

it('waits for multiple slow requests with individual timeouts', () => {
  cy.intercept('GET', '/api/analytics/summary').as('analytics');
  cy.intercept('GET', '/api/inventory/count').as('inventory');

  cy.visit('/dashboard');

  // Sequential waits with different timeouts per alias
  cy.wait('@analytics', { timeout: 30_000 });    // analytics is slow
  cy.wait('@inventory', { timeout: 5_000 });     // inventory is fast

  cy.get('[data-cy="dashboard-loaded"]').should('be.visible');
});
```

### Cypress Retry Configuration — experimentalStrategy  [community]

Cypress 13+ supports a `detect-flake-and-pass-on-threshold` retry strategy that marks a test as "flaky-but-passing" rather than failing, enabling gradual flakiness reduction without blocking deploys.

```typescript
// cypress.config.ts — flake detection strategy
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    retries: {
      runMode: 3,    // allow 3 attempts
      openMode: 0,
      experimentalStrategy: 'detect-flake-and-pass-on-threshold',
      experimentalOptions: {
        // Pass the test as long as it succeeds at least once in maxAttempts tries
        maxStopIfAnyPassed: 1,
      },
    },
  },
});
```

```yaml
# CI: separate job to report flaky tests without failing the build
- name: Run Cypress with flake detection
  run: npx cypress run --record
  env:
    CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
    # Flaky tests are reported to Cypress Cloud as "flaky" not "failed"
    # Build passes even if tests are flaky (as long as they pass on at least one retry)

- name: Report flaky test count
  run: |
    # Use Cypress Cloud API to check flaky rate
    curl -H "Authorization: Bearer $CYPRESS_API_KEY" \
      "https://api.cypress.io/v1/projects/$PROJECT_ID/runs/latest" \
      | jq '.flaky_tests | length'
```

**[community]** WHY: The default Cypress retry behavior (retry-until-fail) means a flaky test can block a deploy if it happens to fail on all retries on a busy CI day. `detect-flake-and-pass-on-threshold` separates "is the test flaky?" (a quality metric) from "does the test block the build?" (a release gate). This lets teams track and fix flaky tests systematically without forcing emergency reverts every time a known-flaky test fails.


```typescript
// cypress/factories/user.factory.ts
export interface TestUser {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'viewer';
  isActive: boolean;
  createdAt: string;
}

// Factory with Partial override — caller specifies only what matters for the test
export function makeUser(overrides: Partial<TestUser> = {}): TestUser {
  return {
    id: `usr_${Math.random().toString(36).slice(2, 10)}`,
    name: 'Test User',
    email: `user-${Date.now()}@example.com`,
    role: 'user',
    isActive: true,
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

export function makeAdminUser(overrides: Partial<TestUser> = {}): TestUser {
  return makeUser({ role: 'admin', name: 'Admin User', ...overrides });
}

// In a spec
import { makeUser, makeAdminUser } from '../factories/user.factory';

it('admin sees all users', () => {
  const admin = makeAdminUser();
  const regularUser = makeUser({ role: 'user' });

  cy.intercept('GET', '/api/me', admin).as('getMe');
  cy.intercept('GET', '/api/users', [admin, regularUser]).as('getUsers');

  cy.visit('/admin/users');
  cy.wait(['@getMe', '@getUsers']);

  cy.get('[data-cy="user-row"]').should('have.length', 2);
  cy.get('[data-cy="user-row"]').first()
    .find('[data-cy="role-badge"]')
    .should('have.text', 'admin');
});
```

**[community]** WHY: Hardcoded fixture JSON files become a maintenance burden when the data model changes — you update 30 fixture files when a field is renamed. Factories give you a single source of truth for default test data, type-check all fields at compile time, and make the test intent clear: `makeAdminUser({ isActive: false })` communicates that the test is specifically about an inactive admin, not a generic user state.

### Network Error Simulation with forceNetworkError  [community]

Simulate network-level failures (connection dropped, DNS failure) using `forceNetworkError: true` in `cy.intercept()`. This is distinct from HTTP error status codes — the request never reaches the server.

```typescript
it('shows offline error when network is unavailable', () => {
  // Force a network error on the data fetch — not an HTTP error, a connection failure
  cy.intercept('GET', '/api/dashboard*', { forceNetworkError: true }).as('networkFail');

  cy.visit('/dashboard');
  cy.wait('@networkFail');

  // App should handle network errors distinctly from API errors
  cy.get('[data-cy="error-banner"]')
    .should('be.visible')
    .and('contain.text', 'Network error');

  cy.get('[data-cy="retry-btn"]').should('be.visible');
});

it('queues actions when offline and syncs on reconnect', () => {
  cy.visit('/notes');
  cy.get('[data-cy="note-input"]').type('Offline note');

  // Go offline after the page loads
  cy.intercept('POST', '/api/notes', { forceNetworkError: true }).as('offlineCreate');
  cy.get('[data-cy="save-note"]').click();
  cy.wait('@offlineCreate');

  // Note should be queued (optimistic UI)
  cy.get('[data-cy="sync-indicator"]').should('contain', 'Pending sync');

  // Restore connectivity
  cy.intercept('POST', '/api/notes', { statusCode: 201, body: { id: 'note_1' } }).as('onlineCreate');
  cy.get('[data-cy="sync-now"]').click();
  cy.wait('@onlineCreate');

  cy.get('[data-cy="sync-indicator"]').should('contain', 'Synced');
});
```

**[community]** WHY: `forceNetworkError` simulates the real-world "no internet" scenario that cannot be reproduced by returning a 503 or 0-byte response. Apps that only handle HTTP error codes will show a confusing error (e.g., "undefined is not an object") instead of a user-friendly offline message when `forceNetworkError` is used. Testing both HTTP errors and network errors catches two different failure modes in your error boundary code.

### cy.request() with Cookies — Session-Based Auth API Testing  [community]

When your API uses session cookies instead of Bearer tokens, `cy.request()` automatically sends and receives cookies from the Cypress cookie jar.

```typescript
it('session cookie is sent automatically with cy.request()', () => {
  // Log in via UI to establish the session cookie
  cy.visit('/login');
  cy.get('[data-cy="email"]').type('admin@example.com');
  cy.get('[data-cy="password"]').type(Cypress.env('ADMIN_PASS'));
  cy.get('[data-cy="submit"]').click();
  cy.url().should('include', '/dashboard');

  // cy.request() sends the session cookie automatically — no Authorization header needed
  cy.request('GET', '/api/admin/users').then((res) => {
    expect(res.status).to.eq(200);
    expect(res.body).to.be.an('array');
  });
});

it('sets session cookie manually for API-only tests', () => {
  // Bypass UI login by calling the auth API and extracting the session cookie
  cy.request('POST', '/api/auth/login', {
    email: 'admin@example.com',
    password: Cypress.env('ADMIN_PASS'),
  }).then((res) => {
    // Session cookie is automatically stored in the Cypress cookie jar
    expect(res.status).to.eq(200);
  });

  // Subsequent cy.request() calls carry the session cookie
  cy.request('DELETE', '/api/admin/users/test-user-id')
    .its('status').should('eq', 204);
});

it('tests that protected routes reject unauthenticated requests', () => {
  // Make sure we have no cookies (unauthenticated)
  cy.clearAllCookies();

  cy.request({
    method: 'GET',
    url: '/api/admin/users',
    failOnStatusCode: false,
  }).its('status').should('eq', 401);
});
```

### experimentalRunAllSpecs — Local Parallel Runs

Run all specs in a single browser instance without relaunching the browser between specs. Faster for local development when running the full suite.

```typescript
// cypress.config.ts — experimental local parallelism
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    experimentalRunAllSpecs: true,  // run all specs in a single browser session
    // Note: cy.session() with cacheAcrossSpecs: true is essential here —
    // without it, each spec still requires a full login cycle
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx}',
  },
});
```

```bash
# Run all specs in a single browser instance (faster local full-suite run)
npx cypress run --browser chrome

# The experimentalRunAllSpecs flag is set in config — no CLI flag needed
# To disable for a specific CI environment:
CYPRESS_experimentalRunAllSpecs=false npx cypress run
```

**[community]** WHY: Without `experimentalRunAllSpecs`, Cypress launches a new browser instance for every spec file. On a 50-spec suite this means 50 browser launches, each taking ~2s = ~100s of overhead. With `experimentalRunAllSpecs`, the overhead is a single launch. The trade-off is that browser state (cookies, localStorage) persists between specs unless cleared in `beforeEach` — making test isolation even more important.

### Database Seeding with Prisma/Knex via cy.task()  [community]

Use `cy.task()` to run database operations directly from tests, bypassing the API and ensuring deterministic state for each test.

```typescript
// cypress/plugins/db.ts — Prisma seeding task handlers
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const dbTasks = {
  'db:seed:user': async (data: { email: string; role: string }) => {
    const user = await prisma.user.upsert({
      where: { email: data.email },
      update: { role: data.role },
      create: {
        email: data.email,
        name: 'E2E Test User',
        role: data.role,
        passwordHash: '$2b$10$test-hash',  // pre-hashed test password
      },
    });
    return { id: user.id, email: user.email };
  },

  'db:clean': async (tables?: string[]) => {
    const targetTables = tables ?? ['order', 'user'];
    for (const table of targetTables) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (prisma as any)[table].deleteMany({
        where: { email: { endsWith: '@e2e.test' } },
      });
    }
    return null;
  },

  'db:query': async (sql: string) => {
    const result = await prisma.$queryRawUnsafe(sql);
    return result;
  },
};

// cypress.config.ts — register db tasks
import { defineConfig } from 'cypress';
import { dbTasks } from './cypress/plugins/db';

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', dbTasks);
      on('after:run', async () => {
        // Clean up all E2E test data after the run
        await dbTasks['db:clean']();
      });
    },
  },
});

// In a spec — deterministic database state
describe('User management', () => {
  let testUserId: string;

  beforeEach(() => {
    cy.task('db:seed:user', {
      email: 'admin@e2e.test',
      role: 'admin',
    }).then((user: { id: string }) => {
      testUserId = user.id;
    });
  });

  afterEach(() => {
    cy.task('db:clean', ['user']);
  });

  it('admin can deactivate a user account', () => {
    loginAsRole('admin');
    cy.visit(`/admin/users/${testUserId}`);
    cy.get('[data-cy="deactivate-btn"]').click();
    cy.get('[data-cy="status-badge"]').should('have.text', 'Inactive');

    // Verify in DB directly
    cy.task('db:query', `SELECT is_active FROM users WHERE id = '${testUserId}'`)
      .then((rows: Array<{ is_active: boolean }>) => {
        expect(rows[0].is_active).to.be.false;
      });
  });
});
```

**[community]** WHY: Seeding via `cy.request()` to the app's API is subject to the same auth, validation, and rate-limiting rules as the real user. This makes test setup fragile — a validation change can break 20 tests that have nothing to do with the validation itself. Direct database seeding via `cy.task()` bypasses application logic and is the only reliable way to set up edge-case states (e.g., a user with a corrupted record, an expired subscription, or a foreign key constraint that the API won't create).

### before:browser:launch Hook — Browser Flag Injection  [community]

Use the `before:browser:launch` hook in `cypress.config.ts` to inject browser flags, extensions, or custom preferences before Cypress opens the browser.

```typescript
// cypress.config.ts — browser launch customization
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('before:browser:launch', (browser, launchOptions) => {
        // Disable the browser's password save prompt
        if (browser.name === 'chrome') {
          launchOptions.preferences.default['credentials_enable_service'] = false;
          launchOptions.preferences.default['profile.password_manager_enabled'] = false;
        }

        // Allow clipboard API without permission prompt (for copy-to-clipboard tests)
        if (browser.name === 'chrome') {
          launchOptions.args.push('--use-fake-ui-for-media-stream');
          launchOptions.args.push('--use-fake-device-for-media-stream');  // fake webcam
          launchOptions.args.push('--allow-clipboard-read-write-for-testing');
        }

        // Disable GPU for headless stability
        launchOptions.args.push('--disable-gpu');

        // Load a Chrome extension for testing (e.g., a Chrome extension you're building)
        const extensionPath = path.join(__dirname, 'cypress/extensions/my-extension');
        if (browser.name === 'chrome') {
          launchOptions.extensions.push(extensionPath);
        }

        return launchOptions;
      });
    },
  },
});
```

**[community]** WHY: Chrome's built-in password manager, geolocation prompts, and notification dialogs can interrupt automated tests by showing native browser UI that Cypress cannot interact with. The `before:browser:launch` hook is the only way to suppress these at the browser level — `cy.on()` event handlers operate on the page, not on native browser chrome. Always add `--disable-gpu` for headless CI to prevent intermittent rendering issues on GPU-less CI agents.

### Multi-Window Testing with cy.origin() and Window References  [community]

Cypress cannot directly control a second browser tab or popup window. Use `window.open()` stubs, `cy.origin()`, or single-window navigation patterns to handle multi-window flows.

```typescript
// Pattern 1: Stub window.open() and navigate in the same tab instead
it('handles OAuth popup by navigating in the same window', () => {
  // Intercept OAuth popup and redirect in the same tab
  cy.window().then((win) => {
    // Redirect the popup URL to the same window
    cy.stub(win, 'open').callsFake((url: string) => {
      win.location.href = url;  // navigate main window to OAuth URL
    });
  });

  cy.get('[data-cy="oauth-btn"]').click();

  // Now the OAuth flow happens in the same window — cy.origin() can handle it
  cy.origin('https://accounts.google.com', () => {
    cy.get('#identifierId').type(Cypress.env('GOOGLE_EMAIL'));
    cy.get('#identifierNext').click();
    cy.get('#password input').type(Cypress.env('GOOGLE_PASSWORD'));
    cy.get('#passwordNext').click();
  });

  cy.url().should('include', '/dashboard');
});

// Pattern 2: For apps that open a new tab for print/share/export
it('asserts that a new tab URL was requested without navigating', () => {
  cy.window().then((win) => {
    cy.stub(win, 'open').as('windowOpen');
  });

  cy.visit('/invoice/123');
  cy.get('[data-cy="share-link"]').click();

  cy.get('@windowOpen')
    .should('have.been.calledWith',
      sinon.match(/^https:\/\/share\.example\.com\/invoice\/123/),
      '_blank'
    );
});
```

**[community]** WHY: Cypress's architecture runs tests inside an iframe in a single browser window. Opening a real second tab creates a separate window context that Cypress cannot reach. The stub-and-redirect pattern is the most maintainable solution because it keeps the entire test flow within a single window, making assertions straightforward. Avoid hacks like using `cy.task()` to scrape the clipboard for tab URLs — they are flaky and OS-dependent.

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
| `cy.selectFile(file, options)` | Trigger file input / drag-drop upload | File upload testing (replaces `cypress-file-upload`) |
| `cy.readFile(path)` | Read a file from the filesystem | Assert generated files, read fixtures dynamically |
| `cy.writeFile(path, data)` | Write a file from the test | Create temp test data, persist test state to disk |
| `cy.location(key)` | Assert on parts of the current URL | Check pathname, search params, hash without full URL match |
| `cy.within(fn)` | Scope all subsequent queries to a parent | Target elements inside a repeated component |
| `cy.wrap(subject)` | Bring a value/Promise into the Cypress chain | Assert on synchronous helpers or async setup |
| `Cypress.Buffer.from(data)` | Create a binary buffer for file content | Dynamic file content in `cy.selectFile()` |
| `cy.exec(cmd, options)` | Run a shell command in Node.js context | DB seed scripts, file cleanup, compile-step checks |
| `cy.its(property)` | Read a nested property from the subject | Fixture fields, DOM properties, response body paths |
| `cy.invoke(method, ...args)` | Call a method on the subject | Trim text, jQuery methods, app-window bridge calls |
| `.shadow()` | Enter a shadow root from a host element | Web Component / Custom Element inner element queries |
| `cy.on('uncaught:exception', fn)` | Handle uncaught app errors per-test | Suppress known 3rd-party errors without masking regressions |
| `Cypress.on('uncaught:exception', fn)` | Handle uncaught app errors globally | Filter ignorable errors (ResizeObserver, non-Error rejections) |
| `cy.frameLoaded(selector)` | Wait for an iframe to fully load | Precedes `cy.iframe()` for embedded form/widget tests |
| `cy.iframe(selector)` | Enter an iframe's DOM context | Form/payment widget iframe interaction |
| `cy.all(...fns)` | Run multiple queries in parallel (Cypress 13.4+) | Assert multiple independent elements simultaneously |
| `Cypress.automation(cmd, params)` | Send a raw CDP command to the browser | Network throttling, browser state inspection |
| `sinon.match.*` | Flexible argument matchers for stub/spy assertions | Partial object shape assertions on `cy.stub()` calls |
| `cy.each(fn)` | Iterate over a jQuery collection | Per-element assertions, dynamic form filling |
| `cy.focused()` | Yield the currently focused element | Keyboard navigation and ARIA focus order tests |
| `cy.go(direction)` | Browser back/forward navigation | SPA routing history tests |
| `cy.reload(hardReload?)` | Reload the current page | Persistence tests; `true` bypasses cache |
| `chai-subset` (plugin) | Assert partial object subset with `containSubset()` | API response body assertions without full equality |
| `cy.title()` | Yield the document `<title>` text | SEO/accessibility page title assertions |
| `cy.hash()` | Yield the URL fragment/hash | Anchor navigation and hash-routing assertions |
| `cy.window()` | Yield the app's `window` object | App state access, custom event dispatch |
| `cy.document()` | Yield the app's `document` object | DOM meta tag assertions, document property reads |
| `cy.getCookie(name)` | Get a specific cookie by name | Assert on cookie properties (httpOnly, secure, value) |
| `cy.getCookies()` | Get all cookies | Debug cookie state, filter by property |
| `cy.setCookie(name, value, opts)` | Set a cookie before a test | Pre-set consent flags, feature flag cookies |
| `cy.clearCookie(name)` | Clear a single named cookie | Surgical cookie removal without disrupting session |
| `cy.wait([aliases])` | Wait for multiple aliased requests | Ensure all endpoints respond before asserting |
| `cy.clock()` | Freeze JS timers globally | Debounce, toast auto-dismiss, polling interval tests |
| `Cypress.config(key)` | Read config value at runtime | Environment-adaptive assertions, safePause guard |
| `cy.intercept(..., { times: N })` | Limit intercept to first N matching requests | Retry logic testing; let subsequent requests pass through |
| `.filter(selector)` | Filter a jQuery collection by CSS selector | Narrow down lists to matching items |
| `.not(selector)` | Exclude matching elements from collection | Assert on non-matching items in a set |
| `.should(callback)` | Complex multi-property assertion with retry | Conditions that built-in matchers can't express |
| `cy.getAllLocalStorage()` | Read all localStorage per origin (Cypress 12+) | Assert app state written to localStorage |
| `cy.window().then(win => win.localStorage)` | Direct localStorage access | Write test state, assert on app-written values |
| `.find(selector)` | Search descendants of current subject | Scoped element search within a container |
| `.closest(selector)` | Walk up DOM to nearest matching ancestor | Find parent row/container of a child element |
| `.siblings(selector)` | Get sibling elements at the same DOM level | Tab/nav active-state assertions |
| `.parent(selector)` | Get the direct parent element | Field-level error state assertions |
| `.children(selector)` | Get direct children (not all descendants) | Menu item count, list direct child assertions |
| `Cypress._(data)` | Lodash utility bundled with Cypress | Data transformation in `.then()` callbacks |
| `describe(name, { config }, fn)` | Per-suite configuration override | Increase timeouts for slow suites |
| `it(name, { config }, fn)` | Per-test configuration override | Override viewport, retries, or timeouts per test |
| `cy.request({ form: true })` | Send URL-encoded form data | Form submission API testing without FormData |
| `Cypress.Blob.binaryStringToBlob()` | Convert binary string to Blob | Prepare fixture files for FormData upload |
| `Cypress.platform` | Get the OS platform string | Platform-conditional modifier key selection |
| `{ctrl}`, `{meta}`, `{shift}` key tokens | Modifier keys in `.type()` | Keyboard shortcut testing |
| `{downarrow}`, `{uparrow}`, `{enter}` key tokens | Navigation keys in `.type()` | Dropdown/menu keyboard navigation tests |
| `cy.check(value)` | Check a checkbox or radio by value | Multi-checkbox selection, radio groups |
| `cy.uncheck(value)` | Uncheck a checkbox by value | Unselect options in multi-checkbox groups |
| `cy.select(value)` | Select a `<select>` option by text/value/index | Dropdown form field selection |
| `cy.type(text, { delay: N })` | Type with per-keystroke delay in ms | Real-time validation, debounced search, char counters |
| `req.alias = 'name'` | Assign an alias inside intercept handler | Dynamic aliasing based on request content |
| `cy.stub().callsFake(fn)` | Replace stub implementation with custom function | Simulate retry sequences, progressive loading states |
| `cy.stub().callsArg(n)` | Invoke the nth argument as a callback | Test callback-driven APIs and animation frame patterns |
| `cy.stub().withArgs(matcher)` | Create conditional sub-stub for specific arguments | Argument-selective stub behavior |
| `cy.request({ auth: { bearer } })` | Send a Bearer token auth request | Standalone API test suites without UI login |
| `cy.request({ followRedirect: false })` | Disable redirect following in cy.request() | Assert on 301/302 redirect responses directly |
| `cy.mount(Component, { componentProperties })` | Angular/Vue component property injection | Mount with typed inputs for component isolation tests |
| `cy.task('sse:emit', data)` | Trigger SSE events via Node.js task bridge | Server-Sent Event testing without cy.intercept() |
| `experimentalOriginDependencies: true` | Allow custom commands inside cy.origin() (Cy 14+) | Support loginViaApi() and other custom cmds in OAuth flows |
| `experimentalStrategy: 'detect-flake-and-pass-on-threshold'` | Smart retry strategy (Cy 14 retries) | Pass a test once it succeeds within retry budget |
| `cy.intercept({ body: { key: value } })` | Match intercept by request body content | Distinguish multiple POST calls to the same endpoint |
| `cy.intercept(url, { forceNetworkError: true })` | Simulate a network connection failure | Test offline/no-internet error handling distinct from HTTP errors |
| `makeUser(overrides)` (factory pattern) | Generate typed test data with defaults | Replace hardcoded fixtures with compile-time-safe factories |
| `experimentalRunAllSpecs: true` | Run all specs in a single browser session | Reduce browser launch overhead in local full-suite runs |
| `on('before:browser:launch', (browser, opts) => {...})` | Inject browser flags/preferences before launch | Disable password prompts, fake media devices, load extensions |
| `launchOptions.args.push('--flag')` | Add a Chrome CLI flag via launch options | Disable GPU, allow clipboard, suppress native dialogs |
| `cy.stub(win, 'open').callsFake(url => win.location.href = url)` | Redirect popup to same tab for cy.origin() testing | Single-window OAuth/popup flow workaround |
| `prisma.$queryRawUnsafe(sql)` via cy.task() | Direct DB query from test via Prisma | Verify database state after UI action without an API round-trip |
| `cy.trigger(eventName, options)` | Fire a raw DOM event on an element | Hover states, pointer events, canvas interactions, custom app events |
| `cy.findByRole(role, { name })` (via `@testing-library/cypress`) | Query by ARIA role and accessible name | RTL-style component tests with accessibility-first selectors |
| `cy.findByLabelText(text)` (RTL) | Query form field by its visible label | Input field selection using screen-reader-visible labels |
| `cy.findByText(text)` (RTL) | Query element by exact/regex text content | Text-content assertions without data-cy dependencies |
| `pollUntil(fn, predicate, opts)` (custom helper) | Recursive polling with configurable backoff | Long-running async job status polling without fixed `cy.wait(ms)` |
| `cy.request().its('body').should(predicate)` | Retrying API poll via assertion | Simple one-shot polling without a recursive helper |
| `resolve.alias` in `vite.config.ts` | Bundler path alias registration | Required alongside `tsconfig.json` paths for runtime alias resolution |
| `win.performance.getEntriesByType('navigation')` | Read Navigation Timing API entries | Lightweight page load performance assertions in E2E tests |
| `interception.duration` | Response time in milliseconds from cy.wait() | API latency smoke assertions per endpoint |
| `registerCypressGrep(config)` | Enable @cypress/grep tag filtering | Runtime test subset selection by `@tag` without separate spec files |
| `--env grep=@smoke` | Filter tests by tag at runtime | PR builds run only @smoke; nightly runs full suite |
| `--env grepInvert=@edge-cases` | Exclude tests by tag at runtime | Skip environment-incompatible tests without modifying spec files |
| `cy.visit(storyUrl(storyId))` | Visit Storybook story iframe directly | Storybook component smoke tests using Cypress browser automation |
| `cy.get('@alias.all').should('have.length', N)` | Assert exact request count | Verify debounce, idempotency, no-duplicate-submission patterns |
| `interception.request.url` | Inspect full request URL in cy.wait() | Assert on query params, path segments in intercepted requests |
| `cy.realHover()` (via cypress-real-events) | Fire real CDP pointer events for CSS hover | Test CSS :hover states that don't respond to synthetic events |
| `mount(SvelteComponent, { props, extensions })` | Mount Svelte component via `cypress/svelte` | Svelte reactive component testing in real browser |
| `extensions.on.eventName` in Svelte mount | Listen for Svelte custom event dispatches | Assert on component-dispatched events in Svelte CT |
| `faker.seed(n)` | Seed @faker-js/faker PRNG for reproducible data | Fixed seed for reproducible failures; log seed for debug |
| `faker.internet.email({ provider })` | Generate realistic email with custom domain | Test data factory with domain-scoped emails for cleanup |
| `faker.string.uuid()` | Generate a v4 UUID | Unique test data IDs that don't collide across parallel workers |
| `cy.grantClipboardPermission()` (custom) | Grant CDP clipboard-read/write permission | Prerequisite for `navigator.clipboard.readText()` in Chrome |
| `cy.readClipboard()` (custom) | Read clipboard text via navigator.clipboard | Assert on "Copy to clipboard" button behavior |
| `Browser.grantPermissions` via CDP | Grant browser permissions programmatically | Clipboard, geolocation, notifications in Chrome automated tests |
| `req.headers['header-name']` inside intercept handler | Read request header value | Assert API version, auth, correlation ID headers in flight |
| `req.reply({ headers: { ... } })` | Inject response headers | Test header-dependent UI (CORS error display, cache behavior) |
| `Emulation.setGeolocationOverride` via CDP | Override GPS location for geolocation tests | Test store locators, region-based content, shipping estimates |
| `cy.setGeolocation({ lat, lng })` (custom) | Fluent CDP geolocation override command | Geolocation feature tests without physical GPS or permission prompts |
| `Browser.resetPermissions` via CDP | Reset all granted browser permissions | Test permission-denied scenarios after granting them per-test |
| `--ci-build-id "${{ github.run_id }}-group"` | Tag CI build for weighted parallel groups | Separate Cypress Cloud dashboard views per spec complexity tier |
| `cy.task('email:getLatest', addr).should(...)` | Poll email task with retry | Transactional email verification (Mailpit/Mailhog) |
| `cy.task('ws:broadcast', data)` | Push WS message from test server | Integration-level WebSocket message flow tests |
| `cy.visit(url, { onBeforeLoad(win) {...} })` | Run code before page scripts execute | WebSocket stubs, feature flag injection, localStorage seeding |
| `cy.stub().onCall(n).resolves(val)` | Define Nth-call resolved value | Declarative per-call stub sequences (retry, MFA flows) |
| `cy.stub().onCall(0).rejects(err)` | Make Nth call reject with an error | Test error recovery without a real failing server |
| `testIsolation: true/false` | Auto-reset browser state between tests (Cy 12+) | Control per-spec or globally; keep true for isolation |
| `describe(name, { testIsolation: false }, fn)` | Disable isolation for one suite | Legacy test migration without global config change |
| `cypress-ctrf-json-reporter` | Generate CTRF unified test result JSON | Cross-framework test reporting and AI failure summarizers |
| `cy.stub().onCall(0).resolves(val)` | Chain per-call resolved values fluently | Declarative multi-call stubs without counter variables |
| `cy.wait('@alias', { timeout: N })` | Per-alias timeout override | Handle legitimately slow third-party endpoints per-wait |
| `cy.checkA11y(context, opts, logFn, failSilently)` | Full cypress-axe check with violation logging | WCAG 2.1 AA compliance testing with custom violation handler |
| `cy.percySnapshot(name, { widths: [...] })` | Percy visual snapshot across viewports | Multi-breakpoint visual regression detection |
| `.matchImageSnapshot(name, { failureThreshold })` | Local image snapshot comparison | Pixel-diff visual regression without Percy cloud service |
| `on('after:run', async (results) => {...})` | Post-suite hook for Slack/cleanup (Cy 13+) | Run once per `cypress run`; access per-test durations in `results.runs[].tests` |
| `results.totalFailed` in `after:run` | Count of failed tests in the completed run | Trigger conditional Slack alerts / artifact uploads in `setupNodeEvents` |
| `results.runs[].tests[].attempts[0].wallClockDuration` | Per-test wall-clock duration in ms | Identify slow tests after a full run for performance triage |
| `afterEach(() => { cy.window().then(win => { ... }) })` | Per-test cleanup assertion hook | Detect residual localStorage keys left by tests (isolation audit) |
| `win.localStorage.getItem(key)` in `afterEach` | Read localStorage entry in test browser context | Isolation audit: flag keys still set after a test completes |
| `cy.window().should('have.property', key, val)` | Retrying assertion on window property | Poll `window.appReady` or custom window state without `.then()` anti-pattern |
| `cy.window().its('nested.prop').should(...)` | Retrying nested window property read | Deep window state polling that `.then()` can't retry |
| `experimentalModifyObstructiveThirdPartyCode: true` | Rewrite third-party CSP/XFO headers for Cypress | Required for `cy.origin()` on strict SSO providers (Okta, Azure AD) |
| `Emulation.clearGeolocationOverride` via CDP | Remove active geolocation override | Reset GPS state in `afterEach` when `testIsolation: false` |
| `cy.press(key)` | Dispatch a native keyboard event (Cy 14.3+) | Tab-order tests, Escape to dismiss, arrow-key navigation, single-character press |
| `cy.press(Cypress.Keyboard.Keys.TAB)` | Real Tab event via key constants | Focus management / tab-order assertions (replaces cypress-plugin-tab) |
| `cy.env(['KEY']).then(({ KEY }) => {...})` | Async secure env var retrieval (Cy 15.10+) | Sensitive secrets (API keys, passwords) — prevents hydration into window state |
| `Cypress.expose('key', value)` | Register public config synchronously (Cy 15.10+) | Feature flags, API versions — non-sensitive, visible in Cypress App resolved config |
| `allowCypressEnv: false` in config | Throw on deprecated Cypress.env() calls | Enforce migration to cy.env() for all secret access in the test suite |
| `result.exitCode` in cy.exec() | Exit code from shell command (Cy 15+) | Renamed from `result.code` in Cypress 15; TypeScript error guides migration |
| `provideExperimentalZonelessChangeDetection()` | Enable Angular zoneless mode in CT | Mount Angular 21+ zoneless components without Zone.js dependency |
| `cy.readFile(path).should(...)` | Retrying file query (Cy 15+ query promotion) | Assert on generated/downloaded files; retries until assertion passes |
| `mount(SvelteComponent, { props: { onEventName: handler } })` | Svelte 5 callback prop event handler | Pass event stubs as props (replaces `extensions.on` from Svelte 4) |
| `mount(Component, { props: { initialCount: 5 } })` | React 19 / Svelte 5 / Vue 3 prop injection | Unified `props` key works across all framework adapters in Cypress CT |
| `cy.env(['A', 'B']).then(({ A, B }) => {...})` | Batch multiple env keys in one call | Avoid nested `.then()` pyramids when multiple secrets are needed |
| `Cypress.ElementSelector.defaults({ selectorPriority: [...] })` | Configure element selector priority (Cy 15+, renamed from SelectorPlayground) | Control which attributes the Element Selector UI suggests in the Cypress App |
| `cypress-io/github-action@v7` | Official GitHub Action for Cypress (v7, 2026) | Handles caching, browser install, parallelization with `ubuntu-24.04` |
| `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` | Required env var for Cypress Cloud PR detection | Prevents Smart Orchestration from cancelling reruns as empty builds |
| `COMMIT_INFO_MESSAGE: ${{ github.event.pull_request.title }}` | Pass PR title to Cypress Cloud | Correct PR context in Cloud dashboards for pull_request triggered runs |
| `cy.prompt(steps, options)` | AI natural language → Cypress commands (Cy 15.13+, beta) | Accelerate test authoring; use Generate & Export workflow, not self-healing, in CI |
| `cy.prompt(steps, { placeholders })` | Placeholder injection for sensitive data in cy.prompt() | Keeps passwords/tokens out of AI context while still parameterizing steps |
| `Cypress.stop()` | Halt all remaining tests in current spec (Cy 14.2+) | Fail-fast in afterEach; environment precondition guards in beforeEach |
| `--posix-exit-codes` (CLI, Cy 15.4+) | Return exit code 1 (not N) on any test failure | POSIX-compliant CI pipelines; aligns with shell script error conventions |
| `--pass-with-no-tests` (CLI, Cy 15.11+) | Exit 0 when no spec files match the glob | Monorepo CI jobs for unchanged packages; dynamic spec selection |
| `passWithNoTests: true` (config) | Config equivalent of --pass-with-no-tests | Persistent no-tests-is-OK setting in cypress.config.ts |
| `posixExitCodes: true` (Module API, Cy 15.10+) | POSIX exit codes in programmatic cypress.run() | Custom CI orchestration scripts |
| `expose: {}` (Module API, Cy 15.10+) | Pass public config values in programmatic run | Non-sensitive flags (API version, env name) alongside env secrets |
| `experimentalFastVisibility: true` (Cy 15.8+) | Faster visibility checks via getBoundingClientRect | Large suites with deep DOM trees; test display:contents elements carefully |
| `justInTimeCompile: true` (default webpack CT, Cy 14+) | Compile only current-spec modules | Reduces memory for large webpack CT suites; true by default since Cy 14 |
| `experimentalRunAllSpecs: true` (component, Cy 15.9+) | All component specs in one browser session | Eliminates browser relaunch overhead for 100+ component specs |
| `Cypress.browser.family !== 'chromium'` | Browser family guard for CDP commands | Required for all Cypress.automation() CDP calls since Firefox uses BiDi (Cy 14.1+) |
| `defaultBrowser: 'chrome'` (config, Cy 13.16+) | Set default browser for `cypress open` locally | Ensure developers and CI use the same Chrome engine; avoids Electron/Chrome divergence |
| `cy.location()` (Cy 15+) | Returns URL via automation client, not window | Available cross-origin in cy.origin() blocks; ancestorOrigins not available — use cy.window() for those |
| `cy.wrap(circularObj)` (Cy 15.7+) | Safely wrap circular reference objects | Circular reference protection added; older versions freeze the Cypress App |

### 101. Svelte 5 Component Testing  [community]

Cypress Component Testing supports Svelte 5 (currently in Alpha tier). Svelte 5 introduced the **runes** API (`$props()`, `$state()`, `$effect()`) and replaced event directives (`on:click`) with the `onclick` HTML attribute convention. The `extensions.on` mount option from Svelte 4 is replaced by prop-based callbacks in Svelte 5.

```typescript
// cypress.config.ts — Svelte 5 component testing setup
import { defineConfig } from 'cypress';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig({
  component: {
    devServer: {
      framework: 'svelte',
      bundler: 'vite',
      viteConfig: {
        plugins: [svelte()],
      },
    },
    specPattern: 'src/**/*.cy.{ts,svelte}',
  },
});
```

```typescript
// Counter.svelte (Svelte 5 — runes API)
// <script lang="ts">
//   let { initialCount = 0, onCountChange }: { initialCount?: number; onCountChange?: (n: number) => void } = $props();
//   let count = $state(initialCount);
//   function increment() { count++; onCountChange?.(count); }
// </script>
// <p data-cy="count">{count}</p>
// <button data-cy="increment" onclick={increment}>+</button>

// Counter.cy.ts — Svelte 5 component test (runes API)
import { mount } from 'cypress/svelte';
import Counter from './Counter.svelte';

describe('Counter component (Svelte 5 runes)', () => {
  it('renders with initial count from $props()', () => {
    mount(Counter, { props: { initialCount: 5 } });
    cy.get('[data-cy="count"]').should('have.text', '5');
  });

  it('increments $state on button click', () => {
    mount(Counter, { props: { initialCount: 0 } });
    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '1');
    cy.get('[data-cy="increment"]').click();
    cy.get('[data-cy="count"]').should('have.text', '2');
  });

  it('calls onCountChange prop callback on increment', () => {
    const onCountChange = cy.stub().as('countChanged');

    // Svelte 5: pass callback as a prop (not via extensions.on)
    mount(Counter, {
      props: { initialCount: 0, onCountChange },
    });

    cy.get('[data-cy="increment"]').click();
    cy.get('@countChanged').should('have.been.calledWith', 1);

    cy.get('[data-cy="increment"]').click();
    cy.get('@countChanged').should('have.been.calledWith', 2);
  });
});
```

**Svelte 4 vs Svelte 5 mount differences:**

| Feature | Svelte 4 | Svelte 5 |
|---------|----------|----------|
| Props | `mount(Cmp, { props: { count: 0 } })` | Same — no change |
| Event dispatch | `extensions: { on: { eventName: handler } }` | Pass handler as prop: `props: { onEventName: handler }` |
| Reactivity | `let count = 0` + `$:` reactive statements | `let count = $state(0)` |
| Component events | `createEventDispatcher()` | Callback props |

**[community]** WHY: Svelte 5's `$props()` and `$state()` runes are compiled differently from Svelte 4's reactive declarations. The `extensions.on` mounting option that worked for Svelte 4 `createEventDispatcher()` events does not work for Svelte 5 callback props — the mount option is simply ignored without throwing an error, causing tests to silently never receive the callback. Always migrate event handler assertions to prop-based stubs when upgrading a Svelte 4 CT suite to Svelte 5.

### 102. React 19 Component Testing

Cypress Component Testing fully supports React 19. The key change is that React 19 removed the `act()` automatic batching from the test environment — Cypress's built-in retry-ability handles this transparently, but some patterns require updating.

```typescript
// cypress/support/component.tsx — React 19 mount with providers
import React from 'react';
import { mount } from 'cypress/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// React 19 requires a fresh QueryClient per test to avoid state bleed
Cypress.Commands.add('mount', (component, options = {}) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,          // disable retries in tests
        staleTime: Infinity,   // prevent auto-refetch
      },
    },
  });

  const wrapped = (
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  );

  return mount(wrapped, options);
});

// product-card.cy.tsx — React 19 component test
import React from 'react';
import { ProductCard } from '../../src/components/ProductCard';

describe('ProductCard (React 19)', () => {
  it('renders product name and price', () => {
    cy.mount(
      <ProductCard
        product={{ id: 'prod_1', name: 'Widget', price: 9.99, inStock: true }}
        onAddToCart={cy.stub().as('addToCart')}
      />
    );

    cy.get('[data-cy="product-name"]').should('have.text', 'Widget');
    cy.get('[data-cy="product-price"]').should('have.text', '$9.99');
  });

  it('emits onAddToCart when Add button is clicked', () => {
    const onAddToCart = cy.stub().as('addToCart');
    cy.mount(
      <ProductCard
        product={{ id: 'prod_1', name: 'Widget', price: 9.99, inStock: true }}
        onAddToCart={onAddToCart}
      />
    );

    cy.get('[data-cy="add-to-cart"]').click();
    cy.get('@addToCart').should('have.been.calledWith', 'prod_1');
  });

  it('disables Add button when out of stock', () => {
    cy.mount(
      <ProductCard
        product={{ id: 'prod_2', name: 'Gadget', price: 24.99, inStock: false }}
        onAddToCart={cy.stub()}
      />
    );

    cy.get('[data-cy="add-to-cart"]').should('be.disabled');
    cy.get('[data-cy="out-of-stock-label"]').should('be.visible');
  });

  // React 19 Server Component: use cy.visit() not cy.mount() for RSC
  // Server Components cannot be mounted in isolation — they require the full
  // Next.js runtime. Test RSC behavior via cy.visit() with a local dev server.
});
```

**[community]** WHY: React 19 changed how `act()` wraps state updates — some community plugins that called `ReactDOM.act()` directly break because React 19's concurrent mode handles batching differently. Cypress Component Testing uses its own retry loop rather than wrapping commands in `act()`, so it is not affected by this change. However, if you see `Warning: An update to X inside a test was not wrapped in act(...)` in the browser console during Cypress CT, it means a third-party component is directly scheduling state updates outside React's scheduler. Use `cy.get('[data-cy="..."]').should(...)` (which retries) instead of asserting immediately after the action.

### 103. GitHub Actions v7 Upgrade and Node.js 24 Support

Cypress 15 added Node.js 24 support and changed the minimum Linux glibc requirement to 2.31. Update CI configurations accordingly.

```yaml
# .github/workflows/e2e.yml — Cypress 15 + GitHub Actions v7 (2026 pattern)
name: E2E Tests
on: [push, pull_request]

jobs:
  install:
    runs-on: ubuntu-24.04    # ubuntu-24.04 has glibc 2.39 (satisfies Cy 15 minimum of 2.31)
    steps:
      - uses: actions/checkout@v4
      - uses: cypress-io/github-action@v7    # v7 is the current major (was v6 in 2025)
        with:
          runTests: false                     # install only — do not run tests
          build: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build-artifact
          path: dist
          retention-days: 1

  cypress-run:
    runs-on: ubuntu-24.04
    needs: install
    strategy:
      fail-fast: false          # don't cancel other containers if one fails
      matrix:
        containers: [1, 2, 3]   # 3 parallel machines
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: build-artifact
          path: dist
      # Use Docker for browser version consistency across parallel workers
      - uses: cypress-io/github-action@v7
        with:
          record: true
          parallel: true
          group: 'E2E Chrome'
          browser: chrome
          ci-build-id: '${{ github.run_id }}-${{ github.run_attempt }}'
          start: npm start
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}   # REQUIRED: prevents PR re-run detection failures
          CYPRESS_BASE_URL: ${{ vars.STAGING_URL }}
          COMMIT_INFO_MESSAGE: ${{ github.event.pull_request.title }}  # correct PR title in Cloud
          COMMIT_INFO_SHA: ${{ github.event.pull_request.head.sha }}   # correct SHA for PR runs
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: cypress-screenshots-${{ matrix.containers }}
          path: cypress/screenshots/
          retention-days: 7
```

```yaml
# Docker-based CI for deterministic browser versions (recommended for large teams)
# Uses cypress/browsers image to pin Chrome version across all workers
  cypress-docker:
    runs-on: ubuntu-24.04
    container:
      image: cypress/browsers:22.15.0          # Node 22 LTS; Chrome and Firefox included
      # For Node 24: cypress/browsers:24.x.x (check Docker Hub for latest)
    needs: install
    strategy:
      matrix:
        containers: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: build-artifact
      - uses: cypress-io/github-action@v7
        with:
          record: true
          parallel: true
          browser: chrome
          ci-build-id: '${{ github.run_id }}'
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**[community]** WHY: Three common CI failures in 2026 stem from this upgrade path: (1) `ubuntu-20.04` images have glibc 2.31 but are end-of-life — Cypress 15's binary may fail to launch; switch to `ubuntu-24.04` which ships glibc 2.39. (2) Mixing Docker containers between the install job and worker jobs causes the binary paths to differ, breaking the cached binary lookup — always use the same Docker image in both. (3) Omitting `GITHUB_TOKEN` causes Cypress Cloud to misidentify reruns and conflate them with the original run — Smart Orchestration sees a "new build" with zero specs remaining and cancels immediately, making all parallel workers show zero tests run.

---

## Cypress Cloud MCP Integration  [community]

Cypress Cloud v2 (2026) introduced a Model Context Protocol (MCP) server that exposes test run results, flakiness data, and stack traces directly to AI coding assistants (Claude, Cursor, GitHub Copilot).

**What the MCP server enables:**
- Query test run results by branch, spec, or status without leaving your IDE
- Ask "which tests are flaky this sprint?" and get structured data back
- Paste stack traces into Claude with context from the Cloud run timeline
- Audit accessibility and visual regression failures inline with AI assistance

**Setup:**

```json
// .vscode/settings.json or mcp-config in your AI tool
{
  "mcpServers": {
    "cypress-cloud": {
      "command": "npx",
      "args": ["@cypress/mcp-server"],
      "env": {
        "CYPRESS_API_KEY": "${env:CYPRESS_API_KEY}",
        "CYPRESS_PROJECT_ID": "${env:CYPRESS_PROJECT_ID}"
      }
    }
  }
}
```

```typescript
// Example queries the MCP enables:
// "Show me all failing tests on branch feature/checkout for the last 3 runs"
// "Which tests have been marked flaky more than 3 times this week?"
// "Explain this stack trace: [paste from Cloud dashboard]"
```

**Recorded run flag required:** MCP access requires your tests to be recorded to Cypress Cloud (`--record --key $CYPRESS_RECORD_KEY`). Tests run without `--record` are not indexed by the Cloud and are invisible to the MCP server.

> **[community]** WHY: The AI-assisted workflow closes the loop between CI failures and developer context. Previously, a failing CI run meant: copy URL, open Cloud dashboard, click into the failing test, copy the stack trace, switch to IDE, open a chat window. With the MCP server, the AI assistant queries the Cloud directly — the developer never leaves the editor. This is especially powerful for debugging flaky tests where cross-run pattern analysis (which the MCP can perform) is more useful than single-run inspection.

### 94. cy.press() — Native Keyboard Event Dispatch (Cypress 14.3+)

`cy.press()` dispatches real native keyboard events, making it the correct tool for focus management, Tab-order navigation, and single-key interactions. Unlike `cy.type()` (which inputs text), `cy.press()` targets a single key at a time and yields `null` (not chainable).

```typescript
// cypress/support/commands.ts — type declaration for cy.press
// (Built-in since Cypress 14.3 — no declaration needed if types are up to date)
import { Keyboard } from 'cypress';  // Cypress.Keyboard.Keys is the key constants map

// Pattern 1: Focus management / Tab order test (replaces cypress-plugin-tab)
it('tab key cycles through form fields in correct order', () => {
  cy.visit('/contact');

  cy.get('[data-cy="name-input"]').focus();
  cy.focused().should('have.attr', 'data-cy', 'name-input');

  // cy.press(TAB) dispatches a real Tab event — no plugin required
  cy.press(Cypress.Keyboard.Keys.TAB);
  cy.focused().should('have.attr', 'data-cy', 'email-input');

  cy.press(Cypress.Keyboard.Keys.TAB);
  cy.focused().should('have.attr', 'data-cy', 'message-textarea');

  cy.press(Cypress.Keyboard.Keys.TAB);
  cy.focused().should('have.attr', 'data-cy', 'submit-button');
});

// Pattern 2: Escape key dismisses modal — correct approach vs cy.type('{esc}')
it('Escape closes the confirmation dialog', () => {
  cy.visit('/settings');
  cy.get('[data-cy="delete-account-btn"]').click();
  cy.get('[data-cy="confirm-dialog"]').should('be.visible');

  // cy.press() for single key events — no subject required (fires on focused element)
  cy.press(Cypress.Keyboard.Keys.ESC);

  cy.get('[data-cy="confirm-dialog"]').should('not.exist');
  // Focus should return to the trigger element
  cy.focused().should('have.attr', 'data-cy', 'delete-account-btn');
});

// Pattern 3: Arrow key navigation in a custom listbox
it('arrow keys navigate the custom dropdown listbox', () => {
  cy.visit('/search');
  cy.get('[data-cy="search-input"]').type('cypress');
  cy.get('[data-cy="suggestion-list"]').should('be.visible');

  // DOWN arrow: move focus into the suggestion list
  cy.press(Cypress.Keyboard.Keys.DOWN);
  cy.focused().should('have.attr', 'role', 'option');

  cy.press(Cypress.Keyboard.Keys.DOWN);
  cy.get('[data-cy="suggestion-item"].focused').should('have.text', 'Cypress docs');

  // ENTER to select
  cy.press(Cypress.Keyboard.Keys.ENTER);
  cy.location('pathname').should('include', '/results');
});

// Pattern 4: UTF-8 single character press
it('typing an accented character inserts the correct Unicode code point', () => {
  cy.visit('/form');
  cy.get('[data-cy="name-input"]').focus();
  cy.press('é');
  cy.get('[data-cy="name-input"]').should('have.value', 'é');
});
```

**cy.press() vs cy.type() decision table:**

| Scenario | Use |
|----------|-----|
| Tab navigation, focus order | `cy.press(TAB)` |
| Escape to dismiss dialog | `cy.press(ESC)` |
| Arrow key menu navigation | `cy.press(DOWN)` |
| Single character / Unicode | `cy.press('é')` |
| Multi-character text input | `cy.type('hello world')` |
| Modifier combination (Ctrl+S) | `cy.type('{ctrl}s')` |
| Select all then replace | `cy.type('{selectAll}New text')` |

**[community]** WHY: `cy.type('{tab}')` historically dispatched a synthetic DOM event that some browsers processed differently from a real Tab keypress — focus movement in custom components and shadow DOM trees was unreliable. `cy.press()` activates the browser's transient activation state and dispatches through the same code path as a physical keyboard, making Tab-order tests reliable without the `cypress-plugin-tab` community plugin that many teams used to depend on.

### 95. cy.env() — Async Secure Environment Variable Access (Cypress 15.10+)

Cypress 15.10 introduced `cy.env()` as a secure replacement for the deprecated `Cypress.env()`. The new command retrieves only the variables you explicitly request and prevents all env vars from being automatically hydrated into browser state.

```typescript
// DEPRECATED (Cypress.env() still works but will be removed):
// const apiToken = Cypress.env('API_TOKEN');   // hydrates ALL env vars into window

// PREFERRED (Cypress 15.10+):
// cy.env() — async, only exposes what you request

// Pattern 1: Single variable
it('authenticates with the configured API key', () => {
  cy.env(['API_TOKEN']).then(({ API_TOKEN }) => {
    cy.request({
      url: '/api/protected-resource',
      headers: { Authorization: `Bearer ${API_TOKEN}` },
    }).its('status').should('eq', 200);
  });
});

// Pattern 2: Multiple variables in one call
it('logs in with configured test user credentials', () => {
  cy.env(['TEST_EMAIL', 'TEST_PASSWORD']).then(({ TEST_EMAIL, TEST_PASSWORD }) => {
    cy.visit('/login');
    cy.get('[data-cy="email"]').type(TEST_EMAIL);
    cy.get('[data-cy="password"]').type(TEST_PASSWORD);
    cy.get('[data-cy="submit"]').click();
    cy.url().should('include', '/dashboard');
  });
});

// Pattern 3: Custom command using cy.env() for a reusable auth helper
Cypress.Commands.add('loginSecure', () => {
  cy.env(['AUTH_EMAIL', 'AUTH_PASSWORD', 'API_BASE_URL']).then(
    ({ AUTH_EMAIL, AUTH_PASSWORD, API_BASE_URL }) => {
      cy.session(
        ['secure-login', AUTH_EMAIL],
        () => {
          cy.request('POST', `${API_BASE_URL}/auth/login`, {
            email: AUTH_EMAIL,
            password: AUTH_PASSWORD,
          }).then((res) => {
            window.localStorage.setItem('auth_token', res.body.token);
          });
        },
        {
          validate() {
            cy.env(['API_BASE_URL']).then(({ API_BASE_URL }) => {
              cy.request({ url: `${API_BASE_URL}/me`, failOnStatusCode: false })
                .its('status').should('eq', 200);
            });
          },
          cacheAcrossSpecs: true,
        }
      );
    }
  );
});

// Pattern 4: Opting out of Cypress.env() for security
// cypress.config.ts — prevent any test from calling deprecated Cypress.env()
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    allowCypressEnv: false,  // throws if Cypress.env() is called — migrate to cy.env()
  },
});
```

**Type-safe `cy.env()` wrapper:**

```typescript
// cypress/support/env-typed.ts — typed wrapper for cy.env()
const ENV_KEYS = ['API_TOKEN', 'API_BASE_URL', 'TEST_EMAIL', 'TEST_PASSWORD'] as const;
type EnvKey = typeof ENV_KEYS[number];

export function typedEnv<K extends EnvKey[]>(keys: K) {
  return cy.env(keys) as Cypress.Chainable<Pick<Record<EnvKey, string>, K[number]>>;
}

// Usage — fully typed; typos on key names become TypeScript errors
typedEnv(['API_TOKEN', 'API_BASE_URL']).then(({ API_TOKEN, API_BASE_URL }) => {
  cy.request(`${API_BASE_URL}/users`, { headers: { Authorization: `Bearer ${API_TOKEN}` } });
});
```

**[community]** WHY: `Cypress.env()` serializes every configured environment variable into the browser's JavaScript context, making all secrets visible in the browser memory and in test runner logs. A `console.log(Cypress.env())` (accidentally left in code or by a malicious dependency) leaks every secret in the CI log. `cy.env(['key'])` exposes only the specific variable names you request, never their values in logs (`log: true` shows the key name, never the value), and does not hydrate the entire env dict into window state.

### 96. Cypress.expose() — Public Configuration Values

`Cypress.expose(key, value)` (Cypress 15.10+) registers non-sensitive configuration values that are accessible synchronously throughout the test suite and visible in the Cypress App's resolved configuration view. Use it for feature flags, API versions, and environment identifiers that are not secrets.

```typescript
// cypress.config.ts — expose public configuration
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // Expose non-sensitive values for synchronous access in tests
      // (These appear in the Cypress App's Resolved Config panel)
      return config;
    },
  },
});

// cypress/support/e2e.ts — expose values before any test runs
before(() => {
  // Expose API version and environment identifier — neither is sensitive
  Cypress.expose('API_VERSION', '2');
  Cypress.expose('ENVIRONMENT', Cypress.env('ENVIRONMENT') ?? 'local');
  Cypress.expose('FEATURE_NEW_CHECKOUT', Cypress.env('FEATURE_NEW_CHECKOUT') === 'true');
});

// Usage in tests — synchronous, no .then() required
it('sends the correct API version header', () => {
  const apiVersion = Cypress.config('API_VERSION') as string;  // exposed values available via config

  cy.intercept('/api/**', (req) => {
    expect(req.headers['x-api-version']).to.eq(apiVersion);
  }).as('apiCalls');

  cy.visit('/products');
  cy.wait('@apiCalls');
});

it('shows the new checkout UI when feature flag is enabled', () => {
  const newCheckout = Cypress.config('FEATURE_NEW_CHECKOUT') as boolean;

  cy.visit('/cart');
  cy.get('[data-cy="checkout-btn"]').click();

  if (newCheckout) {
    cy.get('[data-cy="new-checkout-flow"]').should('be.visible');
  } else {
    cy.get('[data-cy="legacy-checkout-form"]').should('be.visible');
  }
});
```

**cy.env() vs Cypress.expose() decision table:**

| Value type | Access pattern | Use |
|-----------|---------------|-----|
| API keys, passwords, tokens | Async, `.then()` required | `cy.env(['KEY'])` |
| Feature flags, API version | Sync, read directly | `Cypress.expose('key', val)` |
| Base URLs for non-sensitive environments | Sync | `Cypress.expose('BASE_URL', ...)` |
| DB connection strings | Never expose to browser | Use `cy.task()` only |

**[community]** WHY: Before `Cypress.expose()`, teams either used `Cypress.env()` for public values (which also exposed secrets) or stored values in a custom global (`window.TEST_CONFIG = {...}`). `Cypress.expose()` creates a dedicated typed mechanism: values appear in the Cypress App's resolved configuration panel, making them debuggable without code changes. Keeping public and secret config in separate APIs also makes a security audit straightforward — scan for `cy.env()` to find all secret access points, and `Cypress.expose()` for public config.

### 97. Cypress 15 Breaking Changes and Upgrade Notes

Cypress 15 (2026) introduced several breaking changes requiring code updates when upgrading from Cypress 14.

```typescript
// BREAKING CHANGE 1: cy.exec() — 'code' renamed to 'exitCode'
// Upgrade from v14 to v15

// ❌ Cypress 14 and earlier
cy.exec('npm run build').then((result) => {
  expect(result.code).to.eq(0);         // 'code' property removed in v15
});

// ✅ Cypress 15+
cy.exec('npm run build').then((result) => {
  expect(result.exitCode).to.eq(0);     // use 'exitCode' (aligns with execa v4)
  cy.log(`stdout: ${result.stdout}`);
  cy.log(`stderr: ${result.stderr}`);
});

// Automated migration: search and replace 'result.code' → 'result.exitCode'
// TypeScript users: the type error at result.code guides you to the change
```

```typescript
// BREAKING CHANGE 2: @cypress/vite-dev-server is now ESM-only; min Vite 5

// ❌ CommonJS config (fails in Cypress 15 + Vite dev server)
const { defineConfig } = require('cypress');
module.exports = defineConfig({ component: { devServer: { bundler: 'vite' } } });

// ✅ ESM config (cypress.config.ts or cypress.config.mjs)
import { defineConfig } from 'cypress';
export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
      // Vite 5+ required — if you're on Vite 4, upgrade first
    },
  },
});

// cypress.config.ts — check Vite version compatibility
// package.json should have "vite": ">=5.0.0" for Cypress 15 CT
```

```typescript
// BREAKING CHANGE 3: Firefox CDP removed — Firefox now uses WebDriver BiDi

// ❌ CDP commands that relied on Firefox CDP (Cypress 14 and earlier with Firefox)
// Network throttling via CDP does NOT work on Firefox in Cypress 15
// cy.wrap(Cypress.automation('remote:debugger:protocol', { ... })) — Firefox only

// ✅ Guard CDP commands to Chrome/Chromium only
const throttleNetwork = (profile: string) => {
  // CDP commands only work on Chrome-family browsers
  if (Cypress.browser.family !== 'chromium') {
    cy.log(`Skipping network throttle — CDP not supported in ${Cypress.browser.name}`);
    return;
  }
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Network.emulateNetworkConditions',
      params: NETWORK_PROFILES[profile],
    })
  );
};

// ✅ Firefox tests in Cypress 15 still work for all non-CDP features:
// cy.intercept(), cy.session(), cy.origin(), component testing
// WebDriver BiDi is the new protocol — most Cypress APIs are protocol-agnostic
```

```bash
# Node.js version requirements for Cypress 15:
# - Node.js 18 support REMOVED (end-of-life)
# - Node.js 23 support REMOVED (odd release)
# - Supported: Node.js 20 (LTS) and Node.js 22 (LTS)
# - Bundled Node: 22.15.1

# Check your CI workflow:
# .github/workflows/e2e.yml — update node-version
# - node-version: '18'   ← remove
# + node-version: '22'   ← or '20'

# Webpack 4 support removed — upgrade to Webpack 5 if using webpack bundler for CT
```

```typescript
// BREAKING CHANGE 4: cy.origin() now required for all subdomain navigation
// (document.domain injection removed; injectDocumentDomain: true is deprecated in v14,
//  may be removed in a future major after v15)

// If you have tests navigating between app.example.com and api.example.com
// and previously relied on document.domain = 'example.com', migrate to cy.origin():

// ❌ No longer supported without injectDocumentDomain: true
cy.visit('https://app.example.com');
cy.visit('https://api.example.com/oauth/callback');  // throws SecurityError in v14+

// ✅ Use cy.origin() for cross-subdomain navigation
cy.visit('https://app.example.com');
cy.get('[data-cy="login"]').click();

cy.origin('https://accounts.example.com', () => {
  cy.get('[data-cy="sso-email"]').type(Cypress.env('SSO_EMAIL'));
  cy.get('[data-cy="sso-submit"]').click();
});

cy.url().should('include', 'app.example.com/dashboard');
```

**[community]** WHY: The `cy.exec()` `code` → `exitCode` rename aligns Cypress with the underlying `execa` library's API and is the only property-level rename in Cypress 15. TypeScript users get a compile-time error pointing directly to the change; JavaScript users discover it at runtime. The safest upgrade path: (1) bump Cypress in a branch, (2) run `tsc --noEmit` on your `cypress/` directory to catch the `exitCode` rename and any other type-breaking changes, (3) run the full suite in CI before merging.

### 98. Angular 21 Zoneless Component Testing

Cypress Component Testing supports Angular 21's new zoneless change detection mode (released with Angular 17+, stabilized in 21). Zoneless components do not rely on Zone.js and use explicit `ChangeDetectorRef.markForCheck()` or signals for updates.

```typescript
// cypress.config.ts — Angular component testing config
import { defineConfig } from 'cypress';

export default defineConfig({
  component: {
    devServer: {
      framework: 'angular',
      bundler: 'webpack',
    },
    specPattern: '**/*.cy.ts',
  },
});
```

```typescript
// product-form.cy.ts — Angular 21 zoneless component
import { ProductFormComponent } from './product-form.component';
import { provideExperimentalZonelessChangeDetection } from '@angular/core';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('ProductFormComponent (zoneless)', () => {
  it('submits with valid data', () => {
    cy.mount(ProductFormComponent, {
      imports: [],
      providers: [
        // Required for zoneless Angular testing
        provideExperimentalZonelessChangeDetection(),
        provideHttpClientTesting(),
      ],
    });

    cy.get('[data-cy="product-name"]').type('New Widget');
    cy.get('[data-cy="product-price"]').type('19.99');
    cy.get('[data-cy="submit"]').click();

    // With zoneless, change detection runs on explicit signal/markForCheck triggers
    // Cypress's automatic retry handles the async update correctly
    cy.get('[data-cy="success-message"]').should('be.visible');
  });

  it('shows validation error for empty name', () => {
    cy.mount(ProductFormComponent, {
      providers: [provideExperimentalZonelessChangeDetection()],
    });

    cy.get('[data-cy="submit"]').click();

    // Signal-based reactive form errors update synchronously — no retry needed
    cy.get('[data-cy="name-error"]').should('contain.text', 'Name is required');
  });
});
```

**`NoopAnimationsModule` for zoneless tests:**

```typescript
// For components using animations, import NoopAnimationsModule to prevent async animation timing
import { NoopAnimationsModule } from '@angular/platform-browser/animations';

cy.mount(AnimatedDialogComponent, {
  imports: [NoopAnimationsModule],   // makes animations synchronous
  providers: [provideExperimentalZonelessChangeDetection()],
});
```

**[community]** WHY: The most common zoneless component test failure is "element not visible" immediately after a state change. In zone-based Angular, Zone.js automatically triggers change detection after every async operation. In zoneless mode, change detection only runs when a signal changes or `markForCheck()` is called — which happens correctly in the application, but test code that directly patches a property without going through a signal may not trigger a re-render. Always interact through the component's public input signals or typed component properties, never by patching internal state directly.

### 99. cy.readFile() as a Retrying Query Command (Cypress 15+)

Starting in Cypress 15, `cy.readFile()` was promoted to a **query command** — it retries automatically when chained assertions fail, polling the filesystem until the assertion passes or the timeout expires. This eliminates the manual polling pattern previously required for generated files.

```typescript
// BEFORE Cypress 15 (manual polling required for generated files):
// cy.readFile sometimes needed explicit timeout + manual wait
it('waits for a report to be generated (old pattern)', () => {
  cy.get('[data-cy="generate-report"]').click();
  // Had to use large timeout hoping file appears in time
  cy.readFile('cypress/downloads/report.csv', { timeout: 30_000 })
    .should('contain', 'id,name');
});

// CYPRESS 15+ (readFile is a query command — automatic retry with assertion):
it('waits for generated CSV by asserting with .should()', () => {
  cy.get('[data-cy="generate-report"]').click();

  // readFile retries on each .should() failure — no fixed timeout needed
  // Cypress will re-read the file on every retry attempt until assertion passes
  cy.readFile('cypress/downloads/report.csv')
    .should('contain', 'id,name,date,amount')
    .and('match', /Alice.*2026/);
});

// Advanced: combine readFile query with custom assertion for complex file validation
it('validates JSON export structure', () => {
  cy.get('[data-cy="export-json"]').click();

  cy.readFile<{ records: Array<{ id: string; status: string }> }>(
    'cypress/downloads/export.json'
  ).should((json) => {
    expect(json.records).to.be.an('array').with.length.gt(0);
    expect(json.records[0]).to.have.property('id').that.is.a('string');
    expect(json.records[0]).to.have.property('status').that.is.oneOf(['active', 'inactive']);
  });
});

// Polling binary files (PDF, images) — assert non-empty before content check
it('generates a PDF export', () => {
  cy.get('[data-cy="export-pdf"]').click();

  cy.readFile('cypress/downloads/report.pdf', 'binary')
    .should('have.length.gt', 0);  // readFile retries until file exists and is non-empty
});
```

**[community]** WHY: Before the query promotion, `cy.readFile()` was a one-shot command — if the file didn't exist at the moment it ran, the test immediately failed. Teams worked around this with `cy.wait(5000)` before `cy.readFile()`, or with `cy.task()` polling loops. Now that `cy.readFile()` retries on assertion failure, the idiomatic approach is simply `cy.readFile(path).should(...)` — the retry loop is built in. The key gotcha: the file must be created in the `cypress/downloads` folder (or the configured `downloadsFolder`) on the same machine running Cypress; remote file generation requires a `cy.task()` bridge.

### 100. TypeScript 6 and Vite 8 Component Testing Setup

Cypress 15 added official support for TypeScript 6 and Vite 8. These newer versions require minor configuration updates.

```json
// tsconfig.json — TypeScript 6 configuration updates for Cypress CT
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",   // required for TypeScript 6 with Vite
    "strict": true,
    "jsx": "react-jsx",
    "types": ["cypress", "node"],
    "verbatimModuleSyntax": true,    // TypeScript 6 default: enforces import type for types
    "noUncheckedSideEffectImports": true  // TypeScript 6 new: side-effect imports must be explicit
  },
  "include": ["cypress/**/*.ts", "cypress/**/*.tsx", "src/**/*.ts", "src/**/*.tsx"]
}
```

```typescript
// cypress.config.ts — Vite 8 component testing setup
import { defineConfig } from 'cypress';
import react from '@vitejs/plugin-react';

export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
      viteConfig: {
        plugins: [react()],
        // Vite 8: explicit esbuild target for TypeScript 6 output
        esbuild: {
          target: 'es2022',
        },
        build: {
          target: 'es2022',
        },
      },
    },
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

```typescript
// TypeScript 6 verbatimModuleSyntax impact on Cypress test files:
// Import type declarations must use `import type` or they cause errors

// ❌ TS6 with verbatimModuleSyntax: true — emits unused import
import { CypressTasks } from './task-types';  // type-only import treated as value import

// ✅ Use `import type` for type-only imports
import type { CypressTasks } from './task-types';
import type { Product } from '@/types/product';

// This also applies to fixture types:
// ✅
import type { UserFixture } from '../fixtures/user';
cy.fixture<UserFixture>('user.json').then((user) => {
  expect(user.role).to.be.oneOf(['admin', 'user', 'guest']);
});
```

**[community]** WHY: TypeScript 6's `verbatimModuleSyntax` option (now a default in strict configurations) requires all type-only imports to use `import type`. Teams upgrading TypeScript alongside Cypress 15 often see a flood of "Module ... has no exported member" or "This import is never used" errors that are actually the TS6 `verbatimModuleSyntax` rule being enforced for the first time. Run `npx tsc --noEmit` after updating TypeScript before adding Cypress 15 — fix all TS6 type import errors first, then address any Cypress-specific type changes (e.g., `result.exitCode`) in a separate pass.

### 104. cy.prompt() — AI-Powered Natural Language Test Steps (Cypress 15.13+, Beta)

`cy.prompt()` converts plain-English step descriptions into executable Cypress commands using AI. Introduced as experimental in earlier 15.x versions, it moved to beta in 15.13.0 and no longer requires the `experimentalPromptCommand` config flag. It supports two workflows: **Generate & Export** (one-time generation into committed code) and **Self-Healing** (kept as `cy.prompt()` in production specs for automatic UI adaptation).

```typescript
// Pattern 1: Generate & Export — create test steps, review, export to source control
// Run once: Cypress executes the prompt, AI generates real Cypress commands.
// Export the generated code via "Get Code" button in the Command Log.
// Then replace cy.prompt() with the exported commands so CI runs without AI.

it('completes the checkout flow using AI-generated steps', () => {
  cy.prompt([
    'visit /cart',
    'click the checkout button',
    'type "Alice Smith" in the full name field',
    'type "alice@example.com" in the email field',
    'click the place order button',
    'assert that the order confirmation number is visible',
  ]);
  // After reviewing the generated code in the Command Log, export and commit it.
  // This replaces the cy.prompt() call with deterministic commands.
});
```

```typescript
// Pattern 2: Self-Healing — keep cy.prompt() in CI for adaptive selector updates
// The AI re-evaluates selectors on each run; useful during rapid UI development.
// Best for tests that run on components that change frequently.
// WARNING: self-healing fires AI calls on every run — use sparingly.

it('submits a registration form (self-healing mode)', () => {
  cy.prompt([
    'visit /register',
    'type "newuser@example.com" in the email field',
    'type "{{ password }}" in the password field',  // placeholder keeps secret out of AI context
    'click the register button',
    'assert that the welcome banner contains "newuser@example.com"',
  ], {
    placeholders: { password: Cypress.env('TEST_PASSWORD') },  // injected at runtime
  });
});
```

```typescript
// Pattern 3: Hybrid — use cy.prompt() for new flow discovery, export stable steps
// During initial test authoring, cy.prompt() accelerates creation.
// Once the flow is stable, export and commit the concrete commands.

// cypress.config.ts — no special config needed in Cypress 15.13+ (flag removed)
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    // cy.prompt() is available by default in Cypress 15.13+
    // No experimentalPromptCommand: true needed
  },
});
```

```bash
# Authentication requirement: must be logged into Cypress Cloud OR use --record flag
# Free tier: 100 prompts / 500 steps per hour
# Paid tier: 600 prompts / 3,000 steps per hour

npx cypress open  # log in via Cypress App → Cloud → Sign in
# OR
npx cypress run --record --key $CYPRESS_RECORD_KEY  # authenticates via Cloud key
```

**cy.prompt() limitations:**
- E2E tests only — no component testing support
- Chromium browsers only (Chrome, Edge, Electron)
- Canvas and iframe content not supported
- No `cy.request()` API testing steps (UI interactions only)
- Max 50 steps per call

**[community]** WHY: The most critical production decision with `cy.prompt()` is whether to use it in CI (self-healing mode) or export to concrete code. Self-healing mode means the AI re-runs on every test execution, consuming rate-limit quota and adding latency (2-5s per cy.prompt() call). For a 50-test suite where 20 tests use `cy.prompt()`, this adds 40-100s to every CI run. Use self-healing only for genuinely unstable UI flows (e.g., a component in active development); export all stable tests to concrete Cypress commands that run deterministically without AI.

### 105. Cypress.stop() — Conditional Test Execution Halt (Cypress 14.2+)

`Cypress.stop()` immediately stops the Cypress runner on the current machine. Unlike `cy.skip()` (which skips a single test), `Cypress.stop()` prevents all remaining tests from executing. Use it in `afterEach` for fail-fast behaviour or in `beforeEach` as an environment precondition guard.

```typescript
// Pattern 1: Fail-fast in afterEach — stop the suite on first test failure
// Useful when tests are order-dependent or share expensive setup state.
// Reduces CI time by not running 50 more tests after a critical setup failure.

// cypress/support/e2e.ts — global fail-fast guard
afterEach(function () {
  // 'this.currentTest' is available in function() hooks (not arrow functions)
  if (this.currentTest?.state === 'failed') {
    cy.log(`Stopping suite after failure: "${this.currentTest.title}"`);
    Cypress.stop();
    return;  // REQUIRED: code after Cypress.stop() in the same block still runs
  }
});

// Pattern 2: Environment precondition guard in beforeEach
// Stop the entire spec if a required service is unavailable.
describe('Third-party payment integration', () => {
  before(() => {
    cy.request({
      url: '/api/health/stripe',
      failOnStatusCode: false,
    }).then((res) => {
      if (res.status !== 200) {
        cy.log('Stripe health check failed — stopping payment tests');
        Cypress.stop();
        return;
      }
    });
  });

  it('processes a payment with test card', () => {
    // Only runs if Stripe service is healthy
    cy.visit('/checkout');
    // ...
  });
});
```

```typescript
// Pattern 3: Environment-based conditional execution
// Stop tests that require a specific environment (e.g., production smoke tests
// should not run against a development environment).

beforeEach(() => {
  const baseUrl = Cypress.config('baseUrl') ?? '';
  const isProduction = baseUrl.includes('production.example.com');
  const isSmokeOnly = Cypress.env('SMOKE_ONLY') === 'true';

  if (isSmokeOnly && !isProduction) {
    cy.log(`SMOKE_ONLY is true but baseUrl is not production: ${baseUrl}`);
    Cypress.stop();
    return;
  }
});
```

**Behavior by mode:**
- `cypress run` (CI): skips all remaining tests in the current spec; uploads videos/screenshots/Test Replay to Cypress Cloud
- `cypress open` (interactive): stops the runner but keeps the Cypress App open for inspection

**[community]** WHY: `Cypress.stop()` is often confused with `cy.skip()` or throwing an error in a `before()` hook. The critical difference: `Cypress.stop()` gracefully stops the runner and still collects artifacts (screenshots, video) for already-completed tests, while throwing from `before()` marks all pending tests as failed and surfaces a cryptic "before all hook failed" error. Always add a `return` statement immediately after `Cypress.stop()` — code in the same `afterEach` or `beforeEach` block runs even after `Cypress.stop()` is called, and failing to return causes unexpected side effects.

### 106. Cypress CLI Flags — --posix-exit-codes and --pass-with-no-tests

Two CI-focused CLI flags added in Cypress 15.4 and 15.11 improve integration with POSIX-compliant CI pipelines and dynamic test selection workflows.

```bash
# --posix-exit-codes (Cypress 15.4+)
# Returns exit code 1 for any test failure, regardless of how many tests failed.
# Default Cypress behavior: exit code = number of failed tests (can be > 1).
# POSIX convention: non-zero exit means "failure"; the exact code is usually 1.
# Impact: tools like `|| exit 1` and shell condition checks work correctly.

npx cypress run --posix-exit-codes
# Exit codes with --posix-exit-codes:
#   0  — all tests passed
#   1  — one or more tests failed (replaces the default "N tests failed" exit code)
#   112 — Cypress could not determine which spec to run next (network/Cloud issue)

# --pass-with-no-tests (Cypress 15.11+)
# Exits with code 0 when no spec files match the --spec glob or file-based filter.
# Without this flag: Cypress exits 1 if no tests match (treated as a failure).
# With this flag: "no tests found" is not an error — useful for conditional CI jobs.

npx cypress run --spec "cypress/e2e/feature-x/**" --pass-with-no-tests
# Exits 0 when feature-x directory doesn't exist or contains no .cy.ts files
```

```typescript
// cypress.config.ts — configure both flags persistently for CI
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    // Equivalent to --pass-with-no-tests CLI flag
    passWithNoTests: true,  // Added in Cypress 15.11
    // Note: posixExitCodes can also be set in the Module API (see below)
  },
});
```

```typescript
// Module API — include posixExitCodes in programmatic runs (Cypress 15.10+)
import cypress from 'cypress';

const result = await cypress.run({
  spec: process.env.TEST_SPEC ?? 'cypress/e2e/**/*.cy.ts',
  posixExitCodes: true,          // --posix-exit-codes equivalent
  config: {
    passWithNoTests: true,       // --pass-with-no-tests equivalent
  },
  expose: {                      // new in 15.10 — public config values
    API_VERSION: '2',
    ENVIRONMENT: process.env.ENVIRONMENT ?? 'local',
  },
});

// With posixExitCodes: true, result.totalFailed > 0 always means exit 1
if (result.status === 'failed' || result.totalFailed > 0) {
  process.exit(1);
}
```

```yaml
# .github/workflows/e2e.yml — use --posix-exit-codes for correct CI failure detection
- name: Run Cypress E2E (POSIX exit codes)
  run: npx cypress run --posix-exit-codes --pass-with-no-tests
  env:
    CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

# Monorepo pattern: run spec subset for changed package, exit 0 if no specs found
- name: Run affected E2E tests
  run: |
    CHANGED_PACKAGE=$(./scripts/detect-changed-package.sh)
    npx cypress run \
      --spec "packages/${CHANGED_PACKAGE}/cypress/e2e/**" \
      --pass-with-no-tests \
      --posix-exit-codes
```

**[community]** WHY: Without `--posix-exit-codes`, a CI step that runs `cypress run` and gets exit code 5 (5 failures) can fool shell scripts that check `[ $? -ne 0 ]` into reporting an error correctly, but tools like `make`, `jest --bail`, or Python's `subprocess.check_call()` interpret specific non-zero exit codes differently. With POSIX exit codes, the convention is unambiguous: 0 = success, 1 = failure, anything else = system error. `--pass-with-no-tests` is essential in monorepo CI where a spec glob may legitimately match zero files for unchanged packages — without it, every unchanged package's CI job fails with "No spec files were found" which is not a real test failure.

### 107. Firefox WebDriver BiDi — CDP Guard Pattern (Cypress 14.1+)

Starting with Firefox 135 and Cypress 14.1, Firefox uses the **WebDriver BiDi** automation protocol instead of Chrome DevTools Protocol (CDP). CDP-specific commands (`Cypress.automation('remote:debugger:protocol', ...)`) must be guarded to Chrome-family browsers.

```typescript
// cypress/support/commands.ts — CDP-safe network throttling (Chrome only)
declare global {
  namespace Cypress {
    interface Chainable {
      throttleNetwork(profile: 'offline' | 'slow3g' | 'fast3g' | 'online'): Chainable<void>;
      setGeolocation(coords: { latitude: number; longitude: number; accuracy?: number }): Chainable<void>;
      grantClipboardPermission(): Chainable<void>;
    }
  }
}

const NETWORK_PROFILES = {
  offline: { offline: true,  latency: 0,   downloadThroughput: 0,       uploadThroughput: 0 },
  slow3g:  { offline: false, latency: 400,  downloadThroughput: 500 / 8 * 1024,  uploadThroughput: 500 / 8 * 1024 },
  fast3g:  { offline: false, latency: 100,  downloadThroughput: 1500 / 8 * 1024, uploadThroughput: 750 / 8 * 1024 },
  online:  { offline: false, latency: 0,   downloadThroughput: -1,      uploadThroughput: -1 },
} as const;

// All CDP commands must be guarded: Cypress.browser.family !== 'chromium'
Cypress.Commands.add('throttleNetwork', (profile) => {
  if (Cypress.browser.family !== 'chromium') {
    cy.log(`Skipping network throttle — CDP not supported on ${Cypress.browser.name} (BiDi)`);
    return;
  }
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Network.emulateNetworkConditions',
      params: NETWORK_PROFILES[profile],
    })
  );
});

Cypress.Commands.add('setGeolocation', ({ latitude, longitude, accuracy = 100 }) => {
  if (Cypress.browser.family !== 'chromium') {
    cy.log(`Skipping geolocation override — CDP not supported on ${Cypress.browser.name} (BiDi)`);
    return;
  }
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setGeolocationOverride',
      params: { latitude, longitude, accuracy },
    })
  );
});

Cypress.Commands.add('grantClipboardPermission', () => {
  if (Cypress.browser.family !== 'chromium') {
    cy.log(`Clipboard permission grant requires Chrome (CDP). Current: ${Cypress.browser.name}`);
    return;
  }
  cy.wrap(
    Cypress.automation('remote:debugger:protocol', {
      command: 'Browser.grantPermissions',
      params: {
        permissions: ['clipboardReadWrite', 'clipboardSanitizedWrite'],
        origin: window.location.origin,
      },
    })
  );
});
```

```typescript
// Per-test browser guard — skip CDP-dependent tests on Firefox
it('network throttling shows skeleton loader on slow 3G', { browser: '!firefox' }, () => {
  cy.throttleNetwork('slow3g');  // safe — only runs on Chrome
  cy.visit('/products');
  cy.get('[data-cy="skeleton-loader"]').should('be.visible');
  cy.get('[data-cy="product-list"]').should('be.visible');
  cy.throttleNetwork('online');
});

// Alternatively, use Cypress.browser.family check inside the test
it('geolocation-based store lookup', () => {
  if (Cypress.browser.family !== 'chromium') {
    cy.log('Geolocation override skipped — not running on Chrome');
    return;
  }
  cy.setGeolocation({ latitude: 40.7128, longitude: -74.006 });
  cy.visit('/store-locator');
  cy.get('[data-cy="use-my-location"]').click();
  cy.get('[data-cy="store-card"]').should('have.length.gte', 1);
});
```

```yaml
# GitHub Actions — run CDP tests only on Chrome, non-CDP tests on both
jobs:
  cypress-chrome:
    runs-on: ubuntu-24.04
    steps:
      - uses: cypress-io/github-action@v7
        with:
          browser: chrome  # Chrome: all tests including CDP-dependent
          record: true
          
  cypress-firefox:
    runs-on: ubuntu-24.04
    steps:
      - uses: cypress-io/github-action@v7
        with:
          browser: firefox  # Firefox: only non-CDP tests (network throttle, geolocation, clipboard skipped)
          record: true
          group: 'Firefox E2E'
```

**[community]** WHY: Firefox switched from CDP to WebDriver BiDi in Firefox 135 (shipped with Cypress 14.1 compatibility). Teams that added CDP-based network throttling, geolocation, or clipboard commands before this change find those commands silently no-op on Firefox — or worse, throw an opaque error like `"protocol not supported"`. The `Cypress.browser.family !== 'chromium'` guard prevents silent failures by logging a clear message when skipping a CDP operation on Firefox. WebDriver BiDi does not yet expose equivalents for all CDP capabilities (geolocation emulation, network throttling, permission grants) — for these features, Chrome remains the only supported browser.

### 108. justInTimeCompile — Webpack Component Testing Memory Optimization

`justInTimeCompile` (default `true` since Cypress 14.0) compiles only the resources directly needed for the current spec, rather than compiling the entire component tree up front. This significantly reduces memory consumption for large component test suites on webpack.

```typescript
// cypress.config.ts — justInTimeCompile is true by default for webpack CT
// You only need to set it explicitly when DISABLING it for debugging
import { defineConfig } from 'cypress';

export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'webpack',  // justInTimeCompile applies to webpack only (not Vite)
    },
    specPattern: 'src/**/*.cy.{ts,tsx}',
    // justInTimeCompile: true,  // this is the default — no need to specify
    // justInTimeCompile: false, // disable to debug "module not found" errors
  },
});
```

```typescript
// Vite users: justInTimeCompile does not apply — Vite handles this natively.
// The setting is a webpack-specific memory optimization.
// cypress.config.ts — Vite CT (no justInTimeCompile config needed)
import { defineConfig } from 'cypress';
import react from '@vitejs/plugin-react';

export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',        // Vite: no justInTimeCompile setting
      viteConfig: {
        plugins: [react()],
      },
    },
  },
});
```

```bash
# Monitoring JIT compile impact in large monorepos
# Use Cypress's built-in memory management flags together with justInTimeCompile:

npx cypress run \
  --component \
  --browser chrome \
  --env experimentalMemoryManagement=true \
  --config numTestsKeptInMemory=3

# Signs that justInTimeCompile is helping:
# - First spec runs slower (compile on demand), subsequent specs fast
# - Memory stays low throughout the run instead of growing per spec
# - No OOM crashes even with 500+ component specs
```

**[community]** WHY: Before `justInTimeCompile: true`, webpack compiled the entire component bundle before running the first test — for a monorepo with 400+ components, this could take 60-120s of startup time and allocate 2-4 GB of memory for all component modules simultaneously. JIT compilation eliminates the startup cost but adds a small per-spec compile step. The trade-off matters most in monorepos with many independent component suites: if your spec pattern matches components across 10 feature areas, the pre-JIT compilation compiled all 10 areas regardless of which 2 you were testing. Set `justInTimeCompile: false` only when debugging "module not found" errors, as JIT compilation can occasionally surface bundler configuration issues that full upfront compilation masks.

### 109. experimentalFastVisibility — Faster Element Visibility Checks (Cypress 15.8+)

`experimentalFastVisibility` changes the internal algorithm Cypress uses to determine element visibility, reducing the overhead of every `cy.get()`, `.should('be.visible')`, and interaction command actionability check.

```typescript
// cypress.config.ts — enable experimental fast visibility checks
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    experimentalFastVisibility: true,  // Cypress 15.8.0+
    // Impact: faster test execution; different behavior for edge-case visibility scenarios
  },
  component: {
    devServer: { framework: 'react', bundler: 'vite' },
    experimentalFastVisibility: true,  // applies to both e2e and component testing
  },
});
```

```typescript
// Known edge cases to test after enabling experimentalFastVisibility:

// 1. Elements with `display: contents` — visibility detection may differ
// 2. Clipped overflow: elements outside scrollable containers
// 3. Elements inside shadow DOM with restrictive CSS
// 4. Absolutely positioned elements with z-index layering

// Recommended validation approach: run your full suite twice (with/without)
// and compare results to catch any false-positive visibility assertions

// Example: element that may behave differently with fast visibility
it('validates display:contents element visibility', () => {
  cy.visit('/complex-layout');

  // This assertion may behave differently under experimentalFastVisibility
  cy.get('[data-cy="display-contents-wrapper"]')
    .find('[data-cy="inner-content"]')
    .should('be.visible');

  // If this flakes after enabling the flag, report to Cypress GitHub issues
  // and disable experimentalFastVisibility as a workaround
});
```

```bash
# Enable/disable per CI run for A/B comparison
CYPRESS_experimentalFastVisibility=true npx cypress run  # test with flag
CYPRESS_experimentalFastVisibility=false npx cypress run  # test without flag
```

**[community]** WHY: The standard Cypress visibility algorithm traverses the DOM tree and checks multiple CSS properties (display, visibility, opacity, overflow, clip, transform) for the element and all its ancestors. For complex component hierarchies, this can execute hundreds of property reads per visibility check. `experimentalFastVisibility` uses a faster algorithm that relies on the browser's `getBoundingClientRect()` and IntersectionObserver, which are O(1) rather than O(depth). The performance gain is most visible in suites with dense DOM trees (data grids, rich text editors, nested card layouts) where each visibility check currently traverses 10-20 ancestor nodes. Enable it in a non-blocking CI job first and compare failure rates before making it the default.

### 110. Cypress Studio — Default-Enabled (Cypress 15.4+)

Cypress Studio is now available by default without the `experimentalStudio` configuration flag (enabled in 15.4.0). Studio lets you record UI interactions visually, add assertions by right-clicking elements, and generate Cypress commands from live browser actions.

```typescript
// Before Cypress 15.4: required explicit config flag
// ❌ No longer needed
// cypress.config.ts (pre-15.4)
// experimentalStudio: true  // REMOVED — Studio is always on now

// ✅ Cypress 15.4+: Studio is enabled by default in cypress open
// No configuration required
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    // Studio is available automatically — no experimentalStudio flag
  },
});
```

```typescript
// Studio workflow with @cypress/grep tags (supported since Cypress 15.2)
// Studio-generated tests can be tagged with @cypress/grep syntax

describe('User settings flow', { tags: ['@smoke'] }, () => {
  // Open Studio on a specific test: hover the test in Cypress App → "Add Commands to Test"
  // Studio records your interactions and adds them to the test body
  it('updates notification preferences', { tags: ['@regression', '@settings'] }, () => {
    // Studio-generated code appears here after recording:
    cy.visit('/settings/notifications');
    cy.get('[data-cy="email-notifications"]').check();
    cy.get('[data-cy="save-settings"]').click();
    cy.get('[data-cy="success-toast"]').should('be.visible');  // added via right-click → Assert
  });
});
```

```bash
# Running Studio (requires cypress open — not available in cypress run)
npx cypress open --browser chrome

# Studio + @cypress/grep: run only Studio-tagged tests
npx cypress run --env grep=@smoke  # works with Studio-authored tests

# Studio in CI: Studio-generated code is plain Cypress commands — runs in CI without Studio
npx cypress run --headless
```

**Studio key features in Cypress 15:**
- Add assertions by right-clicking on elements (generates `.should()` commands)
- Create new tests while focused on a spec
- Word wrap for generated code (added 15.12)
- Works with `@cypress/grep` tag filtering (since 15.2)
- Unsaved Studio changes warn before code export

**[community]** WHY: The most common Studio gotcha is attempting to use it during `cypress run` (headless CI) — Studio is exclusively a `cypress open` feature. Code generated by Studio is standard Cypress TypeScript, so it runs in CI without any Studio dependency. However, teams that use Studio's "self-healing" mode (keeping `cy.prompt()` in code) should understand that Studio-generated code does NOT self-heal — only `cy.prompt()` stubs self-heal. Studio generates static code that is committed and runs deterministically. Treat Studio as a code-generation assistant, not a runtime AI layer.

### 111. experimentalRunAllSpecs for Component Testing (Cypress 15.9+)

`experimentalRunAllSpecs` was expanded in Cypress 15.9 to support component testing in addition to E2E tests. This flag runs all specs in a single browser session, eliminating browser launch overhead between specs.

```typescript
// cypress.config.ts — enable for both testing types
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    experimentalRunAllSpecs: true,  // run all E2E specs in one browser session
  },
  component: {
    devServer: { framework: 'react', bundler: 'vite' },
    experimentalRunAllSpecs: true,  // NEW in Cypress 15.9 — component testing support
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

```bash
# Run all component tests in a single browser session
npx cypress run --component --browser chrome

# Disable per-run for a specific CI job (e.g., debugging isolation issues)
CYPRESS_experimentalRunAllSpecs=false npx cypress run --component
```

```typescript
// Component testing with experimentalRunAllSpecs: isolation requirements
// Without experimentalRunAllSpecs: browser relaunches between specs (full reset)
// With experimentalRunAllSpecs: browser persists — you MUST clean up between tests

// cypress/support/component.ts — ensure isolation when specs share a browser session
afterEach(() => {
  // Unmount the component (Cypress CT does this automatically, but explicit is safer)
  // Any global state modified by the component must be reset
  cy.window().then((win) => {
    // Reset any global state the component may have set
    win.localStorage.clear();
    win.sessionStorage.clear();
  });
});

// Modules that register global side effects (event listeners on document/window)
// must clean up in afterEach to avoid polluting subsequent component specs
afterEach(() => {
  // If the component adds document-level event listeners, they persist in
  // experimentalRunAllSpecs mode. Always use useEffect cleanup in React:
  // useEffect(() => { document.addEventListener('keydown', handler); return () => document.removeEventListener('keydown', handler); }, []);
});
```

**[community]** WHY: The browser launch overhead for component tests is proportionally larger than for E2E tests — each component spec launch starts Vite's dev server transaction, processes the module graph for the spec, and hydrates the test framework. For suites with 100+ component specs, this overhead adds 5-10 minutes to CI wall time. `experimentalRunAllSpecs` eliminates this by reusing the browser session. The isolation risk is lower for component tests than for E2E tests because each component is mounted fresh via `cy.mount()` — the browser's DOM is fully reset between specs by Cypress's automatic cleanup. The main risk is component-level global side effects (window event listeners, global CSS variables, browser API patches) that survive unmounting. Always clean these up in `afterEach` regardless of `experimentalRunAllSpecs`.

### 112. React SSR Hydration Bootstrap Script (`<script data-cy-bootstrap>`) — Cypress 15.11+

Cypress 15.11 introduced a manual bootstrap injection mechanism that solves React Server-Side Rendering (SSR) hydration mismatches in component tests. When Cypress renders a React component in its test harness, the server-rendered HTML and the client-side React tree can diverge, triggering `suppressHydrationWarning` noise or hard hydration errors.

```typescript
// cypress/support/component.ts — enable SSR hydration mode for React 18/19 apps
import { mount } from 'cypress/react18';
import './commands';

// For Next.js 15+ or Remix apps with SSR hydration: add the bootstrap attribute
// to the mount container so Cypress defers React hydration to the first render cycle
Cypress.Commands.add('mount', (component, options = {}) => {
  return mount(component, {
    ...options,
    // data-cy-bootstrap tells Cypress to inject a <script> that triggers React.hydrateRoot
    // instead of React.createRoot, matching the SSR path
    mountingOptions: {
      ...(options as any).mountingOptions,
      bootstrapScript: true,   // emits <script data-cy-bootstrap> into the mount container
    },
  });
});
```

```typescript
// cart-summary.cy.tsx — testing an SSR component that uses suppressHydrationWarning
import { CartSummary } from './CartSummary';

describe('CartSummary (SSR component)', () => {
  it('hydrates correctly without mismatch warnings', () => {
    cy.mount(<CartSummary initialItems={[{ id: '1', name: 'Widget', price: 9.99 }]} />);

    // Previously: React would log "Text content did not match" hydration warnings
    // With bootstrapScript: true, React.hydrateRoot is used — no mismatch
    cy.get('[data-cy="cart-total"]').should('have.text', '$9.99');
    cy.get('[data-cy="cart-item-count"]').should('have.text', '1 item');
  });

  it('handles dynamic timestamps that differ between server and client', () => {
    // Components using Date.now() in server render but a locale string client-side
    // previously broke hydration. The bootstrap script allows React to correct this
    // during the hydration pass without throwing.
    cy.mount(<CartSummary initialItems={[]} />);

    cy.get('[data-cy="last-updated"]').should('be.visible');
  });
});
```

```typescript
// For apps NOT using SSR: bootstrapScript is not needed (React.createRoot path)
// Only enable when testing components from a Next.js App Router or Remix route

// cypress.config.ts — no special config needed; bootstrapScript is per-mount
import { defineConfig } from 'cypress';
export default defineConfig({
  component: {
    devServer: {
      framework: 'next',   // or 'react'
      bundler: 'webpack',  // Turbopack not yet supported for Cypress CT
    },
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

**[community]** WHY: React's `hydrateRoot` and `createRoot` differ in how they process the initial DOM. In a Cypress component test, there is no actual server-rendered HTML — Cypress injects the component into a blank DOM. When a component calls `suppressHydrationWarning` (typically date/time fields or user-agent-dependent content), React in `createRoot` mode ignores the mismatch silently, but React in `hydrateRoot` mode surfaces it as a warning that can mask real hydration bugs. The `data-cy-bootstrap` script injection signals Cypress to simulate the SSR entry point, making component tests for SSR apps more faithful to their production rendering path.

### 113. `Cypress.ElementSelector.defaults()` — Custom Selector Priority for Studio and cy.prompt()

`Cypress.ElementSelector` (renamed from `Cypress.SelectorPlayground` in Cypress 15.0) controls the selector algorithm used by Cypress Studio, `cy.prompt()`, and the element picker in `cypress open`. Configuring a custom `selectorPriority` ensures generated selectors match your team's conventions.

```typescript
// cypress/support/e2e.ts — configure element selector priority globally
// This affects: Studio "Add Commands", cy.prompt() selector generation,
// and the element picker crosshair in cypress open

Cypress.ElementSelector.defaults({
  // Priority order: first matching strategy wins
  // Full list of accepted values:
  // 'data-cy' | 'data-test' | 'data-testid' | 'data-qa'
  // 'attribute:ATTR_NAME' (any custom data attribute)
  // 'name' | 'id' | 'class' | 'tag' | 'attributes' | 'nth-child'
  selectorPriority: [
    'data-cy',          // first: our own data-cy attribute
    'data-testid',      // second: data-testid (for third-party components)
    'attribute:aria-label',  // third: accessible name (good for screen-reader labels)
    'attribute:name',        // fourth: form element name attribute
    'id',               // fifth: id (stable but often auto-generated)
    'class',            // sixth: CSS class (fragile, last resort before nth-child)
  ],
});
```

```typescript
// Example: what Studio generates for a button with our config vs. default config

// Button markup:
// <button data-cy="submit-order" data-testid="checkout-submit" id="btn-123" class="btn-primary">
//   Place Order
// </button>

// With default selectorPriority:
// → '[data-cy="submit-order"]'  (data-cy is first in default list too)

// Without data-cy attribute on a third-party component:
// <input aria-label="Search products" name="q" class="search-input search-input--lg" />

// With our custom selectorPriority — aria-label picked (position 3):
// → '[aria-label="Search products"]'

// With Cypress default — class picked (unstable for styled components):
// → '.search-input'
```

```typescript
// cypress/support/component.ts — same defaults apply to component testing
// Register early in the support file so Studio and cy.prompt() see the custom priority

Cypress.ElementSelector.defaults({
  selectorPriority: [
    'data-cy',
    'data-testid',
    'attribute:aria-label',
    'attribute:role',
    'name',
    'id',
  ],
  // onElement(el): override selection logic entirely for special cases
  onElement(el: JQuery<HTMLElement>): string | null {
    // Custom logic: prefer data-cy but fall back to aria-label for icon buttons
    const dataCy = el.attr('data-cy');
    if (dataCy) return `[data-cy="${dataCy}"]`;

    const ariaLabel = el.attr('aria-label');
    if (ariaLabel) return `[aria-label="${ariaLabel}"]`;

    return null; // fall through to selectorPriority list
  },
});
```

```typescript
// Verifying the configured selector in a test (useful for debugging Studio output):
it('confirms selector strategy is applied', () => {
  cy.visit('/checkout');
  // The element picker in cypress open should now suggest data-cy selectors first
  // cy.prompt() will prefer data-cy when generating selectors for AI-authored tests
  cy.get('[data-cy="place-order-btn"]').should('exist');
});
```

**[community]** WHY: If you don't configure `Cypress.ElementSelector.defaults()`, Studio and `cy.prompt()` generate selectors based on whatever comes first in the default priority (`data-cy, data-test, data-testid, data-qa, name, id, class, tag`). Teams that use a mix of `data-cy` and `data-testid` on different components (e.g., company components use `data-cy`, third-party MUI/Radix components use `data-testid`) benefit from explicitly listing both in priority order. The most impactful customization is adding `attribute:aria-label` before `class` — it prevents Studio from generating fragile CSS class selectors for icon buttons and SVG elements that lack data attributes.

---

## Additional Real-World Gotchas [community]

78. **`cy.prompt()` re-executes AI on every CI run in self-healing mode** [community] — If you leave `cy.prompt()` calls in committed test code and run them in CI, the AI is called on every run, consuming rate-limit quota (100 prompts/500 steps/hour on free tier). On a large parallel CI suite, this can exhaust your hourly quota within minutes and cause subsequent tests to fail with "rate limit exceeded". Use `cy.prompt()` only for initial test authoring (Generate & Export workflow), then replace with exported concrete Cypress commands before committing to main. Reserve self-healing mode for feature branches during active UI development.

79. **`Cypress.stop()` code after the call still runs in the same hook** [community] — Calling `Cypress.stop()` does not immediately halt execution of the current `afterEach` or `beforeEach` block. Code written after `Cypress.stop()` in the same function will execute. This is intentional (teardown may still be needed), but teams often assume `Cypress.stop()` is like a `return` statement. Always add an explicit `return` immediately after `Cypress.stop()` to prevent unintended code from running: `Cypress.stop(); return;`. Without the return, the rest of the hook function executes and can trigger additional commands that clutter the test log.

80. **Firefox WebDriver BiDi silently ignores CDP automation commands** [community] — When Cypress switches Firefox to WebDriver BiDi (Firefox 135+, Cypress 14.1+), calls to `Cypress.automation('remote:debugger:protocol', ...)` do not throw an error — they silently succeed with an empty response or no-op. Network throttling applied via CDP on Firefox appears to work (no error), but the throttling has no effect on the actual network. This is especially deceptive for throttling tests: the test passes because the skeleton loader never appears (no throttling), but the assertion is against the wrong behavior. Always guard CDP commands with `if (Cypress.browser.family !== 'chromium')` and verify the command had an effect by asserting on the resulting UI state.

81. **`justInTimeCompile: false` may surface bundler config errors hidden by JIT** [community] — JIT compilation compiles only the modules needed by the current spec, which can hide bundler misconfiguration. With JIT enabled, a webpack alias typo in a module that's never imported by your spec passes silently. When you disable JIT for debugging, webpack compiles the entire bundle upfront and surfaces all errors at once — which can look like disabling JIT "broke" compilation when it actually exposed pre-existing issues. If disabling JIT reveals new webpack errors, fix them with JIT still disabled (so you see all errors at once), then re-enable JIT.

82. **`experimentalFastVisibility` returns false for `display: contents` elements** [community] — CSS `display: contents` makes an element's children participate in layout as if the element itself didn't exist. The standard Cypress visibility algorithm correctly handles `display: contents` elements (visible if children are visible). The `experimentalFastVisibility` algorithm uses `getBoundingClientRect()`, which returns `{ width: 0, height: 0 }` for `display: contents` elements (they have no box). `should('be.visible')` therefore fails for `display: contents` wrapper elements under `experimentalFastVisibility`. If your component library uses `display: contents` for slot-based wrappers (Headless UI, Radix, etc.), test carefully before enabling this flag.

83. **`--pass-with-no-tests` can hide genuine spec discovery failures in CI** [community] — The `--pass-with-no-tests` flag treats "no matching spec files" as success. In a monorepo where spec paths are dynamically computed per changed package, a bug in the path computation script can result in an empty spec glob that passes with exit 0 — silently running zero tests. To detect this, check the Cypress run output for `"No spec files were found"` log line and fail the CI step if found but not expected: `npx cypress run --pass-with-no-tests 2>&1 | tee cypress-output.txt; if grep -q "No spec files were found" cypress-output.txt && [ "$ALLOW_NO_SPECS" != "true" ]; then exit 1; fi`. Set `ALLOW_NO_SPECS=true` only for jobs that legitimately run on unchanged packages.

84. **Cypress Studio `@cypress/grep` tag propagation requires registerCypressGrep before Studio records** [community] — When using Cypress Studio to add commands to tests that are tagged with `@cypress/grep`, the `registerCypressGrep()` call in `cypress/support/e2e.ts` must be loaded before Studio initializes. If `registerCypressGrep` is imported conditionally (e.g., only in non-CI environments), Studio-enhanced tests may not have their `@tags` property recognized during `cypress open` recording sessions. Always register grep unconditionally in `support/e2e.ts`, and control the grep filter via CLI flags (`--env grep=@smoke`) rather than conditional imports.

85. **Brotli-compressed API responses in Cypress proxy may appear empty in `cy.intercept()` handlers** [community] — Cypress 15.11 added Brotli decompression support in the Cypress proxy. However, if your API server sends Brotli-compressed responses and your intercepted `req.reply()` in `cy.intercept()` handler tries to read `res.body` before decompression completes, `res.body` may be a Buffer containing raw Brotli bytes instead of the parsed JSON. This surfaces as empty or garbled response bodies in intercept spy logs. Ensure you await full decompression by reading `res.body` only inside `req.continue(res => { ... })` — Cypress automatically decompresses the body before invoking the response handler. The issue only manifests when directly calling `req.reply()` with a passthrough and immediately reading the streamed body in the same synchronous tick.

86. **`cy.intercept()` delay values ≥ 2³¹ (≈ 24.8 days) were silently ignored before Cypress 15.13.1** [community] — Prior to 15.13.1, passing a `delay` value greater than or equal to `2**31` milliseconds to a `cy.intercept()` stub caused the delay to be silently discarded — the response arrived immediately with no error. This was a `setTimeout` integer overflow: `setTimeout(fn, 2**31)` fires immediately in V8. In Cypress 15.13.1, a validation error is now thrown at stub registration time. If your test suite has any intercepts with large delay values (e.g., generated programmatically as `maxDelay * 1000`), ensure they stay below `2**31 - 1` (≈ 596 hours). WHY: any realistic network simulation delay is measured in seconds to minutes, not days; values above this threshold are almost always unintentional unit errors (seconds passed as milliseconds without multiplication correction).

87. **Apps with `<base target="_top">` or `<base target="_parent">` break Cypress iframe navigation** [community] — Cypress runs tests inside an iframe. Applications that set a `<base target="_top">` or `<base target="_parent">` HTML element instruct the browser to load all un-targeted links and form submissions in the top-level frame, which navigates out of the Cypress test iframe entirely. This causes tests to fail silently: the page appears to navigate but the test runner loses the page and subsequent commands time out. The fix (Cypress 15.14.2) strips unsafe target attributes from base elements automatically. If you're on an older version, add a `cy.on('before:window:load', win => { win.document.querySelectorAll('base[target]').forEach(el => el.removeAttribute('target')); })` guard in `cypress/support/e2e.ts` as a temporary workaround until you upgrade.

88. **Memory leak in `cypress open` from accumulating `uncaughtException` listeners** [community] — In versions before Cypress 15.14.1, each time a spec was re-run during `cypress open` (e.g., while watching files in development), an additional `uncaughtException` listener was registered on the Mocha runner without removing the previous one. After 20-30 re-runs of a complex spec, the Cypress app became sluggish and eventually consumed several gigabytes of memory, requiring a restart. The leak is fixed in 15.14.1. If you're on an older version and experience memory growth during active TDD sessions with `cypress open`, restart the runner every 30-50 re-runs as a stopgap.

89. **`allowCypressEnv: false` blocks ALL `Cypress.env()` calls, including those in plugin and support files** [community] — When you set `allowCypressEnv: false` in `cypress.config.ts` to enforce migration from `Cypress.env()` to `cy.env()`, Cypress throws at test time for any remaining `Cypress.env()` call — including those inside third-party plugins, `cypress/support/e2e.ts`, or community recipes that haven't been updated. A common failure mode is enabling `allowCypressEnv: false` after migrating your own test code, then discovering that `@cypress/grep`'s tag filter, `cypress-axe`, or Cypress Studio internally use `Cypress.env()` to read configuration. Always audit with a grep: `grep -r "Cypress\.env(" cypress/` to find all callsites before setting the flag. As a migration bridge, use `allowCypressEnv: 'warn'` (logs deprecation warnings without throwing) to identify remaining usages without blocking CI.

90. **`cy.url()` and `cy.location()` use automation clients in Cypress 15 — not all properties are available inside `cy.origin()` blocks** [community] — Cypress 15 changed `cy.url()`, `cy.location()`, `cy.hash()`, `cy.title()`, `cy.go()`, and `cy.reload()` to source their values from the CDP or WebDriver BiDi automation client instead of the `window` object. This was done to eliminate cross-origin access restrictions so these commands work anywhere in a test, including inside `cy.origin()` blocks. The catch: the automation client only exposes a subset of window properties. Code that reads `cy.location()` and expects the full `Location` object (all eight properties: `href`, `origin`, `protocol`, `host`, `hostname`, `port`, `pathname`, `search`, `hash`) continues to work, but any custom code that previously relied on extended `window.location` properties (e.g., accessing `window.location` via `cy.window().its('location.ancestorOrigins')`) will no longer work via `cy.location()` and must use `cy.window().then(win => win.location.ancestorOrigins)` instead. This affects exactly the properties not present in the standard URL/Location automation-client response. WebKit still uses the `window` object, so behavior can differ per browser in mixed CI matrices.

91. **`cy.fixture()` cache is invalidated by `cy.writeFile()` — but only as of Cypress 15** [community] — In Cypress 14 and earlier, if a test used `cy.writeFile()` to update a fixture file and then loaded that fixture via `cy.fixture()` or `cy.intercept({ fixture: '...' })` in the same or a later test within the same run, the old cached fixture content was served instead of the updated file. The fixture cache did not observe file modifications made mid-run. Cypress 15 fixed this: `cy.writeFile()` now triggers fixture cache invalidation. If your test suite uses dynamic fixture generation (e.g., writing fixture data from API responses or seeding unique IDs) and then consuming those fixtures via `cy.intercept({ fixture: '...' })`, the pattern is only reliable on Cypress 15+. Also fixed in Cypress 15: tests calling `cy.fixture(name, 'binary')` and `cy.fixture(name)` in different `it()` blocks no longer interfere — different encoding options now produce consistent results regardless of test execution order. Upgrade to Cypress 15 if you rely on mid-run fixture mutation.

92. **`cy.wrap()` freezes the Cypress App when passed an object with circular references** [community] — Before Cypress 15.7.0, calling `cy.wrap(obj)` on any JavaScript object that contained a circular reference (e.g., a DOM element's `owner` property, a Redux store internal structure, or any `{ self: obj }` reference) caused infinite recursion in Cypress's internal cloning logic, hanging the Cypress App completely and requiring a force-quit. The only symptom was the app becoming unresponsive with no error message. Cypress 15.7.0 fixed the recursion by adding circular reference detection, but if you're on an older version: (a) never wrap raw DOM elements directly — use `cy.get()` to query them; (b) avoid wrapping objects that might contain circular references; (c) use `cy.wrap(JSON.parse(JSON.stringify(obj)))` as a shallow-safe workaround for serializable objects. Common unexpected sources: `cy.wrap(event.target)`, `cy.wrap(window)`, and `cy.wrap(this)` inside a `this`-bound Mocha suite.

93. **Synchronous XHR requests with `cy.intercept()` route handlers froze the browser before Cypress 15.8.0** [community] — Legacy code that uses synchronous `XMLHttpRequest` (i.e., `xhr.open('GET', url, false)` with the third argument `false`) causes the browser's main thread to block until the request completes. When a `cy.intercept()` route handler was registered for such a URL, Cypress's async interception logic and the browser's synchronous XHR semantics deadlocked: the browser waited for the XHR response (blocking the thread), while Cypress's handler waited for the browser's event loop to process the intercept callback (which couldn't run because the thread was blocked). The result was a browser freeze that required a test timeout. Cypress 15.8.0 resolved this with a synchronous passthrough path for synchronous XHR. If you're on an older version, the workaround is to register a `cy.intercept()` stub with `{ forceNetworkError: false }` and a static body — synchronous XHR stubs are returned synchronously without invoking the async route handler. For new code, there is no reason to use synchronous XHR; migrate callers to `fetch()` or async `XMLHttpRequest`.

---

### 114. `defaultBrowser` Config — Local Developer Experience and CI Browser Override

The `defaultBrowser` configuration option (Cypress 13.16.0+) sets which browser Cypress opens by default when running `cypress open` without a `--browser` CLI flag. This is separate from the `--browser` CI flag and only affects local development sessions.

```typescript
// cypress.config.ts — set the default browser for local cypress open sessions
import { defineConfig } from 'cypress';

export default defineConfig({
  // defaultBrowser applies only to 'cypress open' (local interactive mode).
  // It does NOT affect 'cypress run' — CI always passes --browser explicitly.
  defaultBrowser: 'chrome',  // 'chrome' | 'edge' | 'firefox' | 'electron' | 'webkit'

  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.ts',
  },
});
```

```typescript
// cypress.config.ts — per-project defaultBrowser for multi-project setups
// Useful when E2E tests are Chrome-first but component tests use Electron (faster)
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    // defaultBrowser at top-level applies to both e2e and component unless overridden
  },
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
    },
    specPattern: 'src/**/*.cy.tsx',
    // Component tests open with Electron by default — fast startup, no browser install needed
    // Override per-project by adding defaultBrowser inside the component block (not supported
    // directly; use --browser electron in npm scripts for component testing scripts)
  },
  defaultBrowser: 'chrome',  // top-level: E2E tests open in Chrome by default
});
```

```bash
# CI: always specify --browser explicitly — defaultBrowser is ignored in cypress run
npx cypress run --browser chrome --record --key $CYPRESS_RECORD_KEY

# Local: run E2E in Firefox for cross-browser verification, overriding defaultBrowser
npx cypress open --browser firefox

# Local: run E2E in the default browser (as configured in defaultBrowser)
npx cypress open
# → Opens Chrome (per defaultBrowser: 'chrome' config)

# npm scripts — recommended approach for team consistency
# package.json
# {
#   "scripts": {
#     "cy:open": "cypress open",                           // uses defaultBrowser
#     "cy:open:ff": "cypress open --browser firefox",    // cross-browser check
#     "cy:run": "cypress run --browser chrome",          // CI-style headless run
#     "cy:run:edge": "cypress run --browser edge"        // Edge cross-browser CI
#   }
# }
```

---

### 115. cy.prompt() BDD Gherkin Pattern with Placeholder Loop Caching  [community]

`cy.prompt()` introduced in Cypress 15.13+ supports a placeholder system that prevents sensitive values from being transmitted to the AI model while enabling the generated code to be cached across multiple test parametrizations. Combining this with Gherkin-style step wording lowers the barrier for non-developers and enables reuse via parameterized loops.

```typescript
// Pattern 1: BDD Gherkin-style steps — no step definition files required
// AI interprets Given/When/Then/And/But syntax natively
describe('Feature: Shopping cart checkout', () => {
  it('Scenario: Complete checkout with standard shipping', () => {
    cy.prompt([
      'Given the user is authenticated as "shopper@example.com"',
      'When the user navigates to "/cart"',
      'And the user selects "Standard Shipping"',
      'And the user enters {{cardNumber}} in the card number field',
      'And the user enters {{cardExpiry}} in the expiry field',
      'And the user clicks the "Place Order" button',
      'Then the order confirmation number should be visible',
      'And the user should be redirected to "/order-confirmation"',
    ], {
      // Placeholders: values injected at runtime; never sent to the AI model
      // The cache key uses the step text with placeholder tokens — same for all card numbers
      placeholders: {
        cardNumber: Cypress.env('TEST_CARD_NUMBER'),
        cardExpiry: Cypress.env('TEST_CARD_EXPIRY'),
      },
    });
  });
});
```

```typescript
// Pattern 2: Parameterized loop with placeholder caching
// The AI generates the Cypress code once; subsequent iterations reuse the cache
// with different placeholder values — no additional AI calls

interface Product {
  name: string;
  expectedPrice: string;
}

const products: Product[] = [
  { name: 'Wireless Headphones',  expectedPrice: '$49.99' },
  { name: 'Mechanical Keyboard',  expectedPrice: '$89.99' },
  { name: 'USB-C Hub',            expectedPrice: '$29.99' },
];

products.forEach(({ name, expectedPrice }) => {
  it(`verifies product price: ${name}`, () => {
    cy.prompt(
      [
        'navigate to /catalog',
        'search for {{productName}}',
        'click the first search result',
        'verify the displayed price is {{price}}',
      ],
      {
        placeholders: {
          productName: name,      // different per iteration
          price: expectedPrice,   // different per iteration
        },
      }
    );
    // Concrete Cypress assertions after AI-generated steps
    cy.url().should('include', '/product/');
  });
});
```

```typescript
// Pattern 3: Secure credential handling — combine cy.env() + cy.prompt() placeholders
// cy.env() prevents the value from reaching the browser DevTools;
// placeholders prevent it from being transmitted to the AI model.
// Use BOTH layers for maximum security on secrets like API tokens.

it('admin can delete any user account', () => {
  cy.env(['ADMIN_EMAIL', 'ADMIN_PASSWORD']).then(({ ADMIN_EMAIL, ADMIN_PASSWORD }) => {
    cy.prompt(
      [
        'visit /admin/login',
        'type {{email}} in the email field',
        'type {{password}} in the password field',
        'click the Sign In button',
        'navigate to /admin/users',
        'click Delete next to the user named "test-user@example.com"',
        'click Confirm in the confirmation dialog',
        'verify "User deleted successfully" message is visible',
      ],
      {
        placeholders: {
          email:    ADMIN_EMAIL,     // from cy.env() — never in browser DevTools
          password: ADMIN_PASSWORD,  // from cy.env() — never sent to AI model
        },
      }
    );
  });
});
```

**cy.prompt() caching rules:**
- Cache key = step text array + placeholder KEYS (not values). Changing a placeholder value reuses the cache; changing step text or key names invalidates it.
- First-run AI generation takes 2-5 s per `cy.prompt()` call. All subsequent runs with the same step text (regardless of placeholder values) are instant.
- Max 50 steps per `cy.prompt()` call. Split large flows into multiple calls.
- Supported: E2E tests, Chromium browsers only. Not supported: Component tests, iframe/canvas elements, `cy.request()` API steps.

**[community]** WHY: The placeholder loop pattern is the correct way to use `cy.prompt()` for data-driven scenarios. A naive approach would call `cy.prompt()` with interpolated strings (e.g., `` `search for ${name}` ``), which invalidates the cache on every iteration because the step text changes. Using placeholders keeps the step text constant, allows the cache to be shared across all loop iterations, and reduces AI calls from N (one per product) to 1 (first run only). On a 20-product test loop, this cuts AI quota consumption by 95%.

---

### 116. Cypress Module API — `expose`, `posixExitCodes`, and CI Orchestration

The Cypress Module API (`cypress.run()` / `cypress.open()`) lets you invoke Cypress programmatically from Node.js scripts. Cypress 15.10 added `expose` and `posixExitCodes` options, and `cypress.run()` now also accepts `parallel` for coordinating multi-machine runs from a custom orchestrator.

```typescript
// scripts/run-cypress.ts — production-grade custom CI orchestrator
import cypress from 'cypress';

async function runCypress(): Promise<void> {
  let result: CypressCommandLine.CypressRunResult | CypressCommandLine.CypressFailedRunResult;

  try {
    result = await cypress.run({
      browser:           'chrome',
      headless:          true,
      record:            true,
      parallel:          true,
      group:             'e2e-checkout',
      tag:               ['ci', 'checkout'],
      ciBuildId:         process.env.GITHUB_RUN_ID ?? 'local',
      spec:              'cypress/e2e/checkout/**/*.cy.ts',
      posixExitCodes:    true,           // exit 0 = pass, exit 1 = any failure (POSIX)
      // expose: non-sensitive public config injected into cy.config().env.expose
      // (Cypress.expose() reads these from test code synchronously)
      expose: {
        apiVersion:    'v2',
        environment:   process.env.TARGET_ENV ?? 'staging',
        releaseTag:    process.env.GITHUB_REF_NAME ?? 'local',
        featureFlags: {
          newCheckout: process.env.FEATURE_NEW_CHECKOUT === 'true',
        },
      },
      // env: sensitive values — not automatically serialized into browser DevTools
      env: {
        API_TOKEN:      process.env.API_TOKEN,
        ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
      },
      config: {
        baseUrl:          `https://${process.env.TARGET_ENV ?? 'staging'}.example.com`,
        retries:          { runMode: 2, openMode: 0 },
        video:            true,
        screenshotOnRunFailure: true,
      },
    });
  } catch (err) {
    // Cypress could not start (binary missing, network error, etc.)
    // This is NOT a test failure — it is an infrastructure error
    console.error('[cypress runner] Fatal launch error:', (err as Error).message);
    process.exit(1);
  }

  // result.failures > 0 means Cypress itself failed (not tests); tests are result.totalFailed
  if ('failures' in result && result.failures) {
    console.error('[cypress runner] Cypress execution failed:', result.message);
    process.exit(1);
  }

  const { totalFailed, totalTests, totalPassed, totalSkipped } = result as CypressCommandLine.CypressRunResult;
  console.log(`[cypress runner] Run complete: ${totalPassed}/${totalTests} passed, ${totalFailed} failed, ${totalSkipped} skipped`);

  // With posixExitCodes: true, result.totalFailed > 0 → Cypress already sets exit code 1
  // Without posixExitCodes, Cypress exits with the failure count (e.g., 3 failures → exit 3)
  // which breaks CI systems expecting only exit 0/1
  process.exit(totalFailed > 0 ? 1 : 0);
}

runCypress();
```

```typescript
// How test code reads expose values (non-sensitive, synchronous):
// cypress/support/e2e.ts
before(() => {
  // Expose values are accessible via Cypress.config() after cypress.run() sets them
  // In tests, read via Cypress.expose('key') — same as Cypress.env() but public
  const apiVersion  = Cypress.expose('apiVersion');          // 'v2'
  const environment = Cypress.expose('environment');         // 'staging'
  const newCheckout = Cypress.expose('featureFlags').newCheckout; // true/false

  // Conditionally skip component-only tests if feature flag is off
  if (!newCheckout) {
    cy.log(`[setup] New checkout feature disabled — skipping CT specs`);
  }
});
```

```bash
# CI usage — run the orchestrator script
npx ts-node scripts/run-cypress.ts

# Or compile first for production CI (faster startup):
npx tsc -p tsconfig.scripts.json
node dist/scripts/run-cypress.js
```

**Module API options cheatsheet (Cypress 15.10+):**

| Option | Type | Purpose |
|--------|------|---------|
| `posixExitCodes` | `boolean` | Exit 0/1 only (POSIX standard); prevents exit code = failure count |
| `expose` | `Record<string, unknown>` | Non-sensitive public config; read via `Cypress.expose()` in tests |
| `env` | `Record<string, string>` | Sensitive config; read via `cy.env()` (not hydrated into browser DevTools automatically) |
| `ciBuildId` | `string` | Unique run ID for Smart Orchestration grouping in Cypress Cloud |
| `parallel` | `boolean` | Enable Cypress Cloud parallel distribution across CI workers |
| `group` | `string` | Label for this batch of specs in Cypress Cloud; enables separate dashboards |

**[community]** WHY: Most teams use `cypress.run()` for its result object to drive custom reporting (e.g., posting pass/fail to Slack or updating a deployment status badge). The critical mistake is missing the `try/catch` around `cypress.run()` — when Cypress itself fails to launch (binary not found, bad config, Node version mismatch), the returned Promise **rejects** rather than resolving with a failure result. Without `try/catch`, the orchestrator script exits with an unhandled rejection and the CI pipeline reports a network/infra error instead of a helpful diagnostic message.

---

### 117. cy.env() — Multi-Key Single-Call Pattern and `log: false` for Sensitive Values

`cy.env()` (Cypress 15.10+) must be called with all required keys in a **single call** to avoid pyramid nesting. Additionally, the `log: false` option suppresses the retrieved values from the Cypress Command Log, which is critical for secrets that would otherwise appear in screenshots, Test Replay recordings, and CI log artifacts.

```typescript
// ❌ ANTI-PATTERN: nested cy.env() calls create callback pyramids
it('authenticates and seeds test data', () => {
  cy.env(['API_TOKEN']).then(({ API_TOKEN }) => {
    cy.env(['DB_SEED_KEY']).then(({ DB_SEED_KEY }) => {
      cy.env(['BASE_URL']).then(({ BASE_URL }) => {
        // Three levels deep just to get three values
        cy.request({ url: `${BASE_URL}/seed`, headers: { Authorization: `Bearer ${API_TOKEN}`, 'x-seed-key': DB_SEED_KEY } });
      });
    });
  });
});

// ✅ PREFERRED: single cy.env() call retrieves all keys at once
it('authenticates and seeds test data', () => {
  cy.env(['API_TOKEN', 'DB_SEED_KEY', 'BASE_URL']).then(({ API_TOKEN, DB_SEED_KEY, BASE_URL }) => {
    cy.request({
      url:     `${BASE_URL}/seed`,
      headers: {
        Authorization: `Bearer ${API_TOKEN}`,
        'x-seed-key':  DB_SEED_KEY,
      },
      failOnStatusCode: true,
    });
  });
});
```

```typescript
// log: false — prevents secret values from appearing in Command Log
// Use for API tokens, passwords, private keys — any value that would be
// sensitive if captured in a screenshot or Cypress Cloud Test Replay recording.
it('creates a signed API request', () => {
  cy.env(['HMAC_SECRET', 'API_KEY'], { log: false }).then(({ HMAC_SECRET, API_KEY }) => {
    // HMAC_SECRET and API_KEY are NOT shown in the Command Log
    // The cy.env() command itself still appears as a "cy.env()" entry,
    // but the retrieved values are masked

    // Build the signed request using the secrets
    const timestamp = Date.now().toString();
    cy.task('hmac:sign', { key: HMAC_SECRET, message: timestamp }).then((signature: string) => {
      cy.request({
        method:  'GET',
        url:     '/api/protected',
        headers: {
          'x-api-key':   API_KEY,
          'x-timestamp': timestamp,
          'x-signature': signature,
        },
      }).its('status').should('eq', 200);
    });
  });
});
```

```typescript
// Pattern: Reusable custom command that encapsulates cy.env() nesting
// Callers never deal with .then() — the complexity is hidden in the command definition

// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      apiRequest(
        method: string,
        endpoint: string,
        body?: Record<string, unknown>
      ): Chainable<Cypress.Response<unknown>>;
    }
  }
}

Cypress.Commands.add('apiRequest', (method, endpoint, body) => {
  cy.env(['API_TOKEN', 'API_BASE_URL'], { log: false }).then(({ API_TOKEN, API_BASE_URL }) => {
    cy.request({
      method,
      url:     `${API_BASE_URL}${endpoint}`,
      headers: { Authorization: `Bearer ${API_TOKEN}` },
      body,
      failOnStatusCode: false,
    });
  });
});

// Usage in specs — clean, no .then() nesting at the call site:
it('creates a product', () => {
  cy.apiRequest('POST', '/products', { name: 'Widget', price: 9.99 })
    .its('status').should('eq', 201);
});

it('lists products', () => {
  cy.apiRequest('GET', '/products')
    .its('body').should('be.an', 'array').and('have.length.greaterThan', 0);
});
```

**cy.env() key considerations:**
- Pass all required keys in one array: `cy.env(['A', 'B', 'C'])`.
- Use `{ log: false }` for any value that should not appear in Test Replay recordings, screenshots, or CI log output.
- `cy.env()` is the async alternative to deprecated `Cypress.env()`. Use `Cypress.expose()` for public, non-sensitive values that need synchronous access (e.g., feature flags, API versions).
- Keys are case-sensitive: `cy.env(['apiToken'])` ≠ `cy.env(['API_TOKEN'])`. Match exactly how they are set in `cypress.config.ts`, `cypress.env.json`, or `CYPRESS_*` env vars.

**[community]** WHY: Teams that migrate from `Cypress.env()` to `cy.env()` often create a new pyramid problem by calling `cy.env()` once per variable, matching the old synchronous pattern mechanically translated to async. This is worse than the deprecated API because each nested `.then()` adds cognitive complexity. The correct migration is to batch all variables for a given test into a single `cy.env([...])` call at the start of the test or in a helper command. If you find yourself nesting `cy.env()` calls, that is a code smell indicating you need a helper command that encapsulates the multi-key retrieval.

---

## Additional Real-World Gotchas (Iteration 37) [community]

94. **`.invoke()` throws an error if the function returns a Promise (Cypress 15)** [community] — Prior to Cypress 15, calling `.invoke('methodName')` on an object where `methodName` returned a Promise would silently resolve with the Promise object itself rather than the resolved value — causing confusing downstream assertion failures. Cypress 15 changed this: `.invoke()` now throws `Error: .invoke() only works with synchronous functions. If the function returns a Promise, use .then() instead.` This is a **breaking change** for any test that calls `.invoke()` on async class methods, async store actions (Vuex `dispatch`, Redux `dispatch`), or any method that returns a Promise. Migration: replace `cy.wrap(obj).invoke('asyncMethod', args)` with `cy.wrap(obj).then(o => o.asyncMethod(args))`. The `.then()` form correctly waits for the Promise to settle before yielding the resolved value to the next command.

95. **`cy.wait([aliases])` crashes with `Cannot read properties of undefined (reading 'routeId')` on retry** [community] — Cypress 15.14.2 introduced a regression in `cy.wait([])` (multi-alias wait form) that manifested when any intercepted request matching an alias was retried by the browser (e.g., a `503` response triggered a client retry). The retry fired a second request for the same alias before the first was consumed, causing Cypress's internal alias state to reference a stale route entry. The result was an unhandled rejection: `Cannot read properties of undefined (reading 'routeId')` in the Cypress runner. The fix (released in 15.14.3) resolves the stale reference. If you are on 15.14.2, the workaround is to split `cy.wait(['@alias1', '@alias2'])` into sequential individual `cy.wait('@alias1'); cy.wait('@alias2');` calls — the multi-alias form is what triggers the bug, while the single-alias form does not.

96. **Chrome 137 removed `--load-extension` support, breaking extension-based auth test patterns** [community] — Some teams inject browser extensions (e.g., a corporate SSO extension or a cookie-injection extension) during Cypress tests by passing `--load-extension=/path/to/extension` via the `before:browser:launch` hook. Chrome 137 (released early 2026) dropped support for `--load-extension` and `--disable-extensions-except` in non-developer mode binary builds. Tests that previously worked on Chrome 136 and below silently fail to load the extension on Chrome 137+, with no error logged — the extension just isn't installed. The fix is to use the `Chrome for Testing` (CfT) binary instead of the stable Chrome channel, since CfT retains `--load-extension` support in developer/testing builds. Update your `CYPRESS_CHROME_BIN` environment variable to point to the CfT binary, or pin to `cypress/browsers:22.15.0` Docker image which bundles a compatible CfT version. Alternatively, migrate extension-based auth to `cy.session()` with direct API login to eliminate the extension dependency entirely.

97. **Cypress transitive dependencies carry exploitable CVEs — pin a minimum Cypress version in your security policy** [community] — Cypress bundles many dependencies internally (axios, node-forge, simple-git, etc.). When upstream CVEs are disclosed for these packages, they are only patched in new Cypress minor/patch releases — you cannot independently update the bundled dependency. In 2025-2026, several high-severity CVEs were found in Cypress transitive dependencies: axios (CVE-2025-62718, CVE-2026-40175 — request forgery), node-forge (CVE-2026-33896 — certificate validation bypass), and simple-git (CVE-2026-28292 — RCE via malicious `.gitconfig`). None of these are exploitable by test code in normal usage, but they trigger automated security scanners (Snyk, Dependabot, GitHub Advanced Security) that block CI pipelines with false-positive vulnerability alerts. Set a minimum Cypress version in your `package.json` `engines` field and enable Dependabot `groupBy: "dependencies"` to get grouped Cypress update PRs rather than individual transitive dependency alerts that look scarier than they are. Track security patches at: `docs.cypress.io/app/references/changelog`.

98. **`cy.prompt()` self-healing mode exhausts Cypress Cloud rate limits in large parallel CI suites** [community] — `cy.prompt()` makes an AI call on every test run when a cached selector fails to find an element (self-healing). In a large suite (e.g., 50+ specs, 5 workers) where 15 specs use `cy.prompt()` in self-healing mode, a single UI redesign that invalidates selectors triggers 15 × 5 = 75 AI calls in one CI run — which can hit the hourly limit (100 prompts/500 steps on the free tier; 600 prompts/3,000 steps on the paid tier) within a single parallel run. When the limit is exceeded, all remaining `cy.prompt()` calls fail with a rate-limit error, causing a cascade of test failures that appear as test logic failures rather than quota failures. To detect this: check for `cy:prompt:rate-limit-exceeded` events in the Cypress Cloud run logs. To prevent it: use the **Generate & Export** workflow for all committed tests (so AI is never called in CI), and reserve self-healing mode exclusively for feature branches during active UI development where the export workflow is premature.

99. **`experimentalStudio: true` in cypress.config.ts causes a parse error in Cypress 15.4+** [community] — Cypress Studio was promoted from experimental to default in Cypress 15.4.0. The `experimentalStudio` config flag was simultaneously removed from the valid config schema. If your `cypress.config.ts` still contains `experimentalStudio: true` after upgrading to Cypress 15.4+, Cypress throws a configuration validation error at startup: `Unknown configuration option: experimentalStudio`. This happens before any tests run, causing the entire CI job to fail with an opaque config error rather than a test failure. The fix is to remove the `experimentalStudio: true` line from your config entirely — Studio is now always enabled without any flag. The same applies to `experimentalPromptCommand: true` (removed in Cypress 15.13.0 when `cy.prompt()` moved to beta) and `experimentalModifyObstructiveThirdPartyCode` (which remains valid but is now enabled by default for `cy.origin()` flows in Cypress 15).

100. **`injectDocumentDomain: true` config was silently removed in Cypress 15, breaking multi-subdomain tests on older workarounds** [community] — Prior to Cypress 14, teams testing applications that communicated across subdomains (e.g., `app.example.com` reading `window.localStorage` from `api.example.com`) used `injectDocumentDomain: true` to force `document.domain = 'example.com'` on each page load, enabling cross-subdomain DOM access. Cypress 13 deprecated this flag with a deprecation warning. Cypress 14 kept the flag but issued a stronger warning. Cypress 15 **silently removed** the flag from the valid config schema — setting `injectDocumentDomain: true` in Cypress 15 generates the same `Unknown configuration option` error as gotcha #99. Teams that upgraded from Cypress 13 directly to 15 without addressing the deprecation find that their multi-subdomain tests now throw a launch error rather than a test failure, making the root cause non-obvious. The fix: remove `injectDocumentDomain: true` and replace cross-subdomain DOM access with `cy.origin()` callbacks — each subdomain gets its own `cy.origin()` block where Cypress instruments the page independently.

---

**[community]** WHY: Without `defaultBrowser`, Cypress 13+ defaults to Electron when opening the test runner locally. Electron is convenient for CI (no browser installation required) but differs from production Chrome in several ways: Electron uses an older Chromium base than the latest stable Chrome, does not support extensions, and its CDP implementation diverges for a few automation APIs. Teams that develop tests locally in Electron but run CI in Chrome regularly hit false-local-passes: the test works in Electron's Chromium but fails in Chrome due to subtle CSS rendering differences (particularly for animations and `contain: strict` layout), Web Crypto API availability, or `navigator.userAgent` checks in the application. Setting `defaultBrowser: 'chrome'` ensures every developer opens the same browser as CI, catching these discrepancies immediately. The trade-off: Chrome must be installed on developer machines, whereas Electron ships bundled with Cypress.

---
