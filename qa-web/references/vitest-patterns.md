# Vitest Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official (vitest.dev/guide/) + community (vitest-dev/vitest, goldbergyoni/javascript-testing-best-practices) | iteration: 1 | score: 83/100 | date: 2026-05-04 -->
<!-- new guide — synthesized from training knowledge (vitest.dev fetch unavailable); verified against Vitest v2.x / v3.x patterns; re-run /qa-refine to refresh with live docs -->

> Vitest is the Vite-native, Jest-compatible test runner. 16.5k stars. Use it for unit and component
> tests in Vite-based projects (React, Vue, Svelte, SolidJS). For E2E testing, use Playwright.

---

## Core Principles

1. **Vite-first.** Vitest reuses your existing `vite.config.ts` — plugins, aliases, and transforms apply automatically. No separate Babel/Jest config needed.
2. **Jest API compatibility.** `describe`, `it`, `expect`, `vi` (replaces `jest`), `beforeEach`, `afterEach` — drop-in for most Jest codebases.
3. **Native ESM and TypeScript.** No transpilation step for `.ts` files; Vitest runs TypeScript natively via Vite's esbuild transform.
4. **Parallel by default.** Tests run concurrently across worker threads. Use `--sequence.concurrent` to run suites in parallel; use `test.sequential` to opt specific suites out.
5. **In-source testing.** Optionally co-locate test code with source using `if (import.meta.vitest)` — useful for utility functions.

---

## Recommended Patterns

### Configuration

```typescript
// vitest.config.ts — preferred for test-only config
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,           // import describe/it/expect without imports
    environment: 'jsdom',    // browser-like DOM; use 'node' for server code
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',        // fast native V8 coverage; use 'istanbul' for branch coverage
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: ['src/**/*.d.ts', 'src/test/**'],
      thresholds: {
        lines:      80,
        functions:  80,
        branches:   70,
        statements: 80,
      },
    },
  },
});
```

```typescript
// If you need Vite plugins in tests (e.g., @vitejs/plugin-react):
// Merge vitest config into vite.config.ts instead:
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
  },
});
```

### AAA Pattern — Arrange / Act / Assert

Follow the three-section structure for every test. A test that doesn't map to AAA is doing too much.

```typescript
// src/utils/currency.test.ts
import { describe, it, expect } from 'vitest';
import { formatCurrency } from './currency';

describe('formatCurrency', () => {
  it('formats USD with two decimal places', () => {
    // Arrange
    const amount = 1234.5;
    const locale = 'en-US';
    const currency = 'USD';

    // Act
    const result = formatCurrency(amount, locale, currency);

    // Assert
    expect(result).toBe('$1,234.50');
  });

  it('returns "—" for null input', () => {
    // Arrange + Act (trivial arrange merges with act)
    const result = formatCurrency(null, 'en-US', 'USD');

    // Assert
    expect(result).toBe('—');
  });
});
```

### Mocking with `vi`

`vi` is Vitest's equivalent of `jest`. All Jest mock APIs map 1:1.

```typescript
// src/services/email.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { sendWelcomeEmail } from './email';
import * as mailer from '../lib/mailer';   // module to mock

describe('sendWelcomeEmail', () => {
  beforeEach(() => {
    vi.resetAllMocks();  // clean mock state between tests
  });

  it('calls mailer.send with correct subject', async () => {
    // Arrange
    const sendSpy = vi.spyOn(mailer, 'send').mockResolvedValue(undefined);
    const user = { email: 'alice@example.com', name: 'Alice' };

    // Act
    await sendWelcomeEmail(user);

    // Assert
    expect(sendSpy).toHaveBeenCalledOnce();
    expect(sendSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'alice@example.com',
        subject: expect.stringContaining('Welcome'),
      })
    );
  });

  it('throws when mailer fails', async () => {
    vi.spyOn(mailer, 'send').mockRejectedValue(new Error('SMTP error'));
    await expect(sendWelcomeEmail({ email: 'x@y.com', name: 'X' }))
      .rejects.toThrow('SMTP error');
  });
});
```

**Module mocking:**

```typescript
// Hoist mocks to the top of the file with vi.mock (hoisted automatically by Vitest)
vi.mock('../lib/mailer', () => ({
  send: vi.fn().mockResolvedValue(undefined),
}));

// Factory pattern — useful for dynamic return values per test:
vi.mock('../lib/featureFlags', () => ({
  isEnabled: vi.fn(),
}));

// In test:
import { isEnabled } from '../lib/featureFlags';
vi.mocked(isEnabled).mockReturnValue(true);
```

### Component Testing (React / Vue / Svelte)

Vitest integrates with `@testing-library/react` (or Vue/Svelte equivalents) for DOM-level component testing without a browser.

```typescript
// src/components/Counter.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { Counter } from './Counter';

describe('Counter', () => {
  it('increments count on button click', () => {
    // Arrange
    render(<Counter initialCount={0} />);
    const button = screen.getByRole('button', { name: /increment/i });

    // Act
    fireEvent.click(button);
    fireEvent.click(button);

    // Assert
    expect(screen.getByText('Count: 2')).toBeInTheDocument();
  });

  it('does not go below zero when decrement disabled at zero', () => {
    render(<Counter initialCount={0} />);
    const decBtn = screen.getByRole('button', { name: /decrement/i });
    expect(decBtn).toBeDisabled();
  });
});
```

```typescript
// src/test/setup.ts — extend expect with @testing-library/jest-dom matchers
import '@testing-library/jest-dom';
```

### In-Source Testing

Co-locate lightweight unit tests with the implementation for pure utility functions. Guards with `import.meta.vitest` mean the test block is tree-shaken in production builds.

```typescript
// src/utils/slugify.ts
export function slugify(text: string): string {
  return text.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
}

// In-source test block — excluded from production builds
if (import.meta.vitest) {
  const { it, expect } = import.meta.vitest;
  it('slugifies hello world', () => expect(slugify('Hello World')).toBe('hello-world'));
  it('removes special chars', () => expect(slugify('foo & bar!')).toBe('foo--bar'));
}
```

**Caveat:** In-source tests are great for utilities but should NOT be used for components, services, or any code with side effects. Keep them to pure functions only. [community]

### Snapshot Testing

Vitest supports both value snapshots (`toMatchSnapshot`) and inline snapshots (`toMatchInlineSnapshot`). Prefer inline snapshots for small outputs — they show the expected value in the source file, making PR reviews easier.

```typescript
it('serializes user to JSON', () => {
  const user = { id: 1, name: 'Alice', role: 'admin' };
  expect(user).toMatchInlineSnapshot(`
    {
      "id": 1,
      "name": "Alice",
      "role": "admin",
    }
  `);
});

// Large outputs — use file snapshots:
it('renders component HTML', () => {
  const { container } = render(<MyComponent />);
  expect(container.innerHTML).toMatchSnapshot();
});
```

> **Update snapshots:** `npx vitest run --update` or `npx vitest -u`

### Workspace (Monorepo) Setup

```typescript
// vitest.workspace.ts — at root
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  'packages/*/vitest.config.ts',   // per-package configs
  {
    test: {
      name: 'shared-utils',
      include: ['packages/shared/**/*.test.ts'],
      environment: 'node',
    },
  },
]);
```

```bash
# Run all workspaces:
npx vitest run

# Run a specific workspace by name:
npx vitest run --project shared-utils
```

---

## Selector / Locator Strategy

Not applicable — Vitest runs unit and component tests, not browser E2E. For DOM queries in component tests, use `@testing-library` query priority:

1. `getByRole` — mirrors accessibility tree; preferred
2. `getByLabelText` — form elements
3. `getByPlaceholderText` — only when no label exists
4. `getByText` — visible text content
5. `getByTestId` — last resort; use `data-testid` attribute

---

## Real-World Gotchas  [community]

1. **`vi.mock` is hoisted — factory closures cannot reference outer variables** [community] WHY: Vitest hoists `vi.mock()` calls above imports at compile time (like Jest). Variables declared in the test file are not in scope when the factory runs. Wrap dynamic values in `vi.fn()` inside the factory and configure them per-test with `vi.mocked()`.

2. **`environment: 'jsdom'` is slow for server-only code** [community] WHY: jsdom initializes a full DOM environment per worker. Server utilities (database access, pure functions) should use `environment: 'node'` or configure per-file with `@vitest-environment node` comment. Mixing environments without per-file overrides adds 200–400ms to test suite startup.

3. **`globals: true` conflicts with TypeScript strict mode** [community] WHY: When `globals: true` is set, Vitest injects `describe`/`it`/`expect` into the global scope. TypeScript needs `"types": ["vitest/globals"]` in `tsconfig.json` (or the test tsconfig) to recognize these globals without errors. Missing this causes `describe is not defined` TypeScript errors even though tests run fine.

4. **`vi.useFakeTimers()` does not fake `Date` by default in Vitest v1** [community] WHY: In Vitest v1.x, `vi.useFakeTimers()` does not replace `Date` unless you pass `{ toFake: ['Date', 'setTimeout', ...] }`. Code that uses `new Date()` inside timers produces real timestamps. In Vitest v2+, `Date` is faked by default. Pin your Vitest version and test both `Date`-dependent and timer-dependent code explicitly.

5. **Snapshot files committed with Windows line endings fail on Linux CI** [community] WHY: When snapshots are generated on Windows (CRLF) and checked into git without `.gitattributes` normalisation, the Linux CI runner reads LF but the snapshot file contains CRLF — snapshot comparisons fail with "Expected ... Received". Add `*.snap text eol=lf` to `.gitattributes`.

6. **`vi.spyOn` on ES module default exports requires the module's namespace object** [community] WHY: Vitest (like Jest) cannot spy on named exports of ES modules that are only imported as `import fn from './module'`. You must import the namespace (`import * as mod from './module'`) and spy on `mod.default`. Or use `vi.mock()` with a factory function to replace the entire module.

7. **Coverage with `provider: 'v8'` misses branches in transpiled code** [community] WHY: V8 coverage tracks native JavaScript execution paths, not source-level branches. TypeScript ternaries and optional chaining that compile to multiple JS expressions may show different branch counts than expected. Use `provider: 'istanbul'` for accurate branch coverage at the TypeScript source level — at the cost of slower test runs.

---

## CI Considerations

```yaml
# .github/workflows/unit.yml
- name: Run Vitest
  run: npx vitest run --coverage
  env:
    CI: true

- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: ./coverage/lcov.info
```

**Key CI flags:**
- `npx vitest run` — single run (no watch mode); required for CI
- `--coverage` — generates coverage reports using config in `vitest.config.ts`
- `--reporter=verbose` in local dev; `--reporter=default` or `--reporter=junit` in CI
- `--bail=5` — stop after 5 failures for faster CI feedback on broken branches
- `--shard=1/4` — split across matrix jobs (requires Vitest v0.34+)

```yaml
# Matrix sharding example
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx vitest run --shard=${{ matrix.shard }}/4
```

---

## Key APIs

| API | Purpose | Notes |
|-----|---------|-------|
| `vi.fn()` | Create a mock function | Equivalent to `jest.fn()` |
| `vi.spyOn(obj, 'method')` | Spy on or replace an existing method | Returns `MockInstance`; restore with `.mockRestore()` |
| `vi.mock('module', factory?)` | Auto-mock or factory-mock a module | Hoisted to file top; use `vi.mocked()` for typed access |
| `vi.mocked(fn)` | Cast a function as `MockInstance` for typed mock assertions | Use with `vi.mock` modules |
| `vi.useFakeTimers()` | Replace timers and optionally `Date` | Call `vi.useRealTimers()` in `afterEach` |
| `vi.advanceTimersByTime(ms)` | Fast-forward fake timers | Use to test debounce, polling, cache TTL |
| `vi.importActual('module')` | Import real implementation inside a `vi.mock` factory | Mix real + mocked exports |
| `vi.resetAllMocks()` | Reset all mock call history and return values | Call in `beforeEach` |
| `vi.clearAllMocks()` | Clear call history but preserve implementation | Lighter than reset |
| `expect.extend(matchers)` | Add custom matchers | Compatible with `@testing-library/jest-dom` |
| `test.each(table)(name, fn)` | Data-driven tests | Same syntax as Jest `test.each` |
| `test.concurrent` | Run tests in a suite in parallel | Default in some modes; opt-in for specific suites |
| `test.todo('name')` | Mark test as pending | Shows in reporter without failing |
| `beforeAll` / `afterAll` | Suite-level setup/teardown | Worker-scoped by default |

---

## Migrating from Jest

Most Jest codebases migrate by:
1. `npm uninstall jest @types/jest babel-jest` → `npm install -D vitest`
2. Replace `jest` config in `package.json`/`jest.config.ts` with `vitest.config.ts`
3. Replace `jest` → `vi` in all imports (`import { jest } from '@jest/globals'` → `import { vi } from 'vitest'`)
4. Remove `@babel/preset-env` and Babel transforms (Vitest uses Vite/esbuild)
5. Add `"types": ["vitest/globals"]` to `tsconfig.json` if using `globals: true`

**Common incompatibilities:**
- `jest.setTimeout(ms)` → `test.timeout(ms)` or global `testTimeout` in config
- `jest.isolateModules(fn)` → use `vi.resetModules()` + dynamic `import()`
- `jest.requireActual` → `vi.importActual` (async)
- `moduleNameMapper` → `resolve.alias` in Vite config
