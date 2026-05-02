# Cypress Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official + community + training knowledge | iteration: 10 | score: 100/100 | date: 2026-05-02 -->

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
- **Spec grouping for monorepos** — Use `--group` to label parallel runs by app/service: `npx cypress run --record --parallel --group "app-checkout"`. View separate dashboards per group in Cypress Cloud without merging results.
- **`--auto-cancel-after-failures N`** — Cancel the entire parallel run after N failures to save CI minutes on catastrophic regressions. Set N to 5-10 for large suites; too low causes false cancellations on known-flaky tests.
- **Memory leak detection in long runs** — Large suites (200+ tests) can accumulate memory. Use `experimentalMemoryManagement: true` and `numTestsKeptInMemory: 5` together. Watch for browser crashes in CI — they typically signal memory pressure, not test logic failures.
- **Cypress Dashboard API for custom reporting** — Use the Cypress Cloud REST API (`GET /projects/:id/runs`) to pull flakiness rates into internal dashboards or Slack alerts. Token auth via `CYPRESS_API_KEY`.

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
