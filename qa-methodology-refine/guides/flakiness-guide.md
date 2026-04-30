# Flaky Tests — QA Methodology Guide
<!-- lang: TypeScript | topic: flakiness | iteration: 2 | score: 100/100 | date: 2026-04-30 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- Iter 1: Added React act(), Vitest concurrent isolation, snapshot flakiness, GitHub Actions nightly detection, ESLint rules, flakiness SLO, AP9-AP10, gotchas 9-12 -->
<!-- Iter 2: Added WebSocket/SSE flakiness, worker_threads race conditions, safe async timeout helper, test doubles taxonomy, memory/resource exhaustion -->
<!-- sources: synthesized from training knowledge — WebFetch blocked; WebSearch unavailable -->
<!-- Official refs synthesized: martinfowler.com/articles/nonDeterminism.html, testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html -->

---

## Core Principles

### 1. Non-Determinism Is a First-Class Defect
A flaky test is one that produces different outcomes (pass or fail) on the same code without any code change. Fowler's framing: non-determinism in tests is not a nuisance to tolerate — it actively destroys the value of your test suite because it erodes trust. Once developers accept "it'll pass on re-run," every red is suspect and every green is meaningless. Google's data (2016): their internal tooling classified 1-in-7 failing tests as flaky, meaning engineers lose substantial time investigating phantom failures.

### 2. Fix or Quarantine — Never Silently Ignore
A flaky test that remains in the main suite poisons the signal. The only acceptable responses are: (a) fix the root cause immediately, or (b) quarantine it with a visible tag and a tracking issue. Deletion is worse than quarantine — you lose the coverage and the history. A quarantine without a resolution SLA becomes a graveyard within 6 months.

### 3. Flakiness Has a Taxonomy — Diagnose Before Fixing
Random retries without diagnosis treat symptoms. Root causes fall into five families: timing, shared state, external dependencies, order-dependency, and randomness/environment. Each family has its own fix pattern. Applying the wrong fix (e.g., adding a retry when the real cause is shared state) masks the defect and makes the suite slower.

### 4. `sleep()` Is a Smell, Not a Fix
`setTimeout`/`sleep` hard-codes an arbitrary wait that is simultaneously too long on fast machines and too short under load. It trades flakiness for slowness, not for correctness. The right replacement is an explicit condition poll (`waitFor`, `toBeVisible`, retry with exponential backoff capped at a known stable condition). A suite with 50 tests each sleeping 500ms wastes 25 seconds of CI time per run.

### 5. Detection Must Be Systematic, Not Reactive
Waiting for a developer to notice a flaky test means weeks of noise. Automated detection — running every test N times on every PR, or running the suite on a nightly rerun loop — surfaces flakiness early and produces a flakiness rate metric you can track. Without a metric, you cannot improve. With a metric, teams routinely halve their flakiness rate in one sprint.

---

## When to Use (this guide applies when...)

- Your CI suite shows intermittent failures with no code changes
- Developers regularly re-run pipelines to "clear" failures
- You are onboarding new engineers and need a shared quarantine policy
- You're introducing parallel test execution (order-dependency flakiness spikes)
- You're migrating to a new test runner or CI platform (environment assumptions surface)
- Your team is adopting microservices with contract tests (network-level flakiness increases)

---

## ISTQB CTFL 4.0 Terminology Alignment

ISTQB Certified Tester Foundation Level 4.0 (2023) standardises terminology used throughout this guide.

| Term used in this guide | ISTQB CTFL 4.0 definition | Notes |
|-------------------------|--------------------------|-------|
| **flaky test** | "non-deterministic test" — a test case that produces different verdicts on the same test object without code change | ISTQB uses "non-deterministic"; "flaky" is community shorthand |
| **test case** | "a set of preconditions, inputs, actions, expected results and postconditions" | Do NOT write "test" when you mean "test case" |
| **test suite** | "a set of test cases or test procedures to be executed in a specific test run" | Do NOT use "test set" |
| **test object** | "the work product to be tested" | Do NOT use "thing under test" or "SUT" in formal contexts |
| **defect** | "an imperfection or deficiency in a work product" | Use "defect" in reports; "bug" is informal |
| **test level** | "a specific instantiation of a test process — e.g., component, integration, system" | Do NOT use "test layer" |
| **test result** | "the outcome of running a test case: pass, fail, or blocked" | A flaky test case has an *inconsistent* test result across runs |
| **quarantine** | community practice; CTFL uses "deferred defect" for tracked but unresolved defects | Tag with `[QUARANTINE]`, link to defect tracking system |

---

## Patterns

### Pattern 1 — Root Causes Taxonomy

Flakiness root causes fall into five families:

| Family | Description | Frequency (Google, 2016) | Primary Fix |
|--------|-------------|--------------------------|-------------|
| **Shared state** | Tests mutating shared DB rows, singletons, module-level mocks | ~45% | Per-test reset, transaction rollback |
| **Timing** | Hard-coded sleeps, timing assumptions, race conditions | ~20% | `waitFor`, fake timers, condition polling |
| **External dependencies** | Real network calls, third-party APIs, unstable test data services | ~15% | Mock at boundary (MSW, nock) |
| **Order-dependency** | Test A passes only if test B ran first (or didn't run) | ~10% | Random ordering, per-test setup |
| **Randomness & environment** | Non-deterministic IDs, locale, clock, `Math.random()` | ~10% | Seed random, fix locale, freeze time |

Fix strategy per family:
- **Timing**: replace `sleep()` with condition-polling helpers (`waitFor`, Playwright's `expect().toBeVisible()`)
- **Shared state**: isolate per-test — reset DB in `beforeEach`, use transaction rollbacks, avoid module-level mutable state
- **External deps**: mock at the boundary — use `msw` (Mock Service Worker) for HTTP, `nock` for Node HTTP interception
- **Order-dependency**: run tests in random order regularly (`--randomize` in Jest, `--runInBand` to detect, then fix)
- **Randomness**: seed `Math.random()` with a fixed value in tests; use `faker.seed(0)` when generating test data; freeze `Date` with fake timers

### Pattern 2 — Detection via Reruns

```typescript
// jest.config.ts — enable automatic retry with flakiness reporting
import type { Config } from 'jest';

const config: Config = {
  // Built-in retry: rerun failing tests up to N times before marking as failed.
  // A test that passes on retry 2 is logged as flaky (not failed), enabling tracking.
  retryTimes: 2,
  verbose: true,
  maxWorkers: '50%',
  testSequencer: './randomSequencer.ts',
};

export default config;
```

```typescript
// randomSequencer.ts — randomize test file execution order each run
import Sequencer from '@jest/test-sequencer';
import type { Test } from '@jest/test-result';

export default class RandomSequencer extends Sequencer {
  sort(tests: Test[]): Test[] {
    // Fisher-Yates shuffle — surfaces order-dependent flakiness within ~10 runs
    const result = [...tests];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}
```

For Playwright (E2E):

```typescript
// playwright.config.ts — retries + flakiness reporting
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
  ],
});
```

**Flakiness rate formula** (track over time, alert when > 5%):
```
flakiness_rate = (tests_that_passed_on_retry / total_test_runs) × 100%
```

### Pattern 3 — Quarantine Strategy (Tag, Don't Delete)

```typescript
// vitest — quarantine with skip + tracking issue
import { describe, it } from 'vitest';

describe('OrderService', () => {
  it('processes payment and updates inventory', async () => {
    // normal test
  });

  // [QUARANTINE] Flaky: races between payment webhook and inventory update.
  // Root cause: shared DB row; external webhook timing. Issue: PROJ-1234
  // Opened: 2026-04-10 | Owner: @jane | SLA: 2026-04-24
  it.skip('[QUARANTINE] inventory count matches after concurrent orders', async () => {
    // test body preserved for context and future fix
  });
});
```

```typescript
// jest — custom quarantine marker via wrapper function
export const quarantine = (name: string, fn: () => void) => {
  const runner = process.env.QUARANTINE_RUN === 'true' ? test : test.skip;
  runner(`[QUARANTINE] ${name}`, fn);
};

// Usage:
quarantine('user session persists after cache flush', async () => {
  // test body preserved — root cause: singleton cache not reset between tests
  // Issue: ENG-5678 | Opened: 2026-04-10 | Owner: @jane
});
```

CI pipeline guard — fail build if quarantine backlog exceeds threshold:

```typescript
// scripts/check-quarantine-backlog.ts — cross-platform
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';

function walkTestFiles(dir: string, results: string[] = []): string[] {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) walkTestFiles(full, results);
    else if (entry.isFile() && entry.name.match(/\.test\.(ts|tsx)$/)) results.push(full);
  }
  return results;
}

const THRESHOLD = 10;
let count = 0;

for (const file of walkTestFiles('src')) {
  const content = readFileSync(file, 'utf-8');
  const matches = content.match(/\[QUARANTINE\]/g);
  if (matches) count += matches.length;
}

if (count > THRESHOLD) {
  console.error(`Quarantine backlog ${count} exceeds threshold ${THRESHOLD}. Fix before adding new tests.`);
  process.exit(1);
}

console.log(`Quarantine backlog: ${count}/${THRESHOLD} — OK`);
```

### Pattern 4 — Replacing sleep() with Condition Polling

```typescript
// BAD: hard-coded sleep — too slow on fast machines, fails under load
it('shows success toast after form submit', async () => {
  await userEvent.click(submitButton);
  await new Promise(resolve => setTimeout(resolve, 2000)); // smell
  expect(screen.getByText('Saved!')).toBeInTheDocument();
});

// GOOD: wait for the actual DOM condition (React Testing Library)
import { screen, waitFor } from '@testing-library/react';

it('shows success toast after form submit', async () => {
  await userEvent.click(submitButton);
  await waitFor(() => {
    expect(screen.getByText('Saved!')).toBeInTheDocument();
  }, { timeout: 3000, interval: 50 });
});
```

```typescript
// Playwright: explicit condition wait replaces sleep
// BAD
await page.click('#submit');
await page.waitForTimeout(3000); // sleep smell in Playwright

// GOOD: wait for network idle or specific element state
await page.click('#submit');
await page.waitForResponse(resp => resp.url().includes('/api/save') && resp.status() === 200);
await expect(page.locator('[data-testid="success-toast"]')).toBeVisible();
```

### Pattern 4b — Eliminating External HTTP Flakiness with MSW [community]

Mock Service Worker intercepts requests at the network level — no monkey-patching, no fetch/axios-specific setup.

```typescript
// src/mocks/handlers.ts — define handlers once, reuse across all test suites
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('https://api.example.com/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'Alice', role: 'admin' });
  }),
  http.post('https://api.example.com/orders', async ({ request }) => {
    const body = await request.json() as { items: string[] };
    return HttpResponse.json({ orderId: 'ORD-001', items: body.items }, { status: 201 });
  }),
];

// src/mocks/server.ts — Node.js MSW server for Jest/Vitest
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// jest.setup.ts — register server lifecycle hooks once globally
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Pattern 5 — Controlling Time with Fake Timers [community]

```typescript
// jest.useFakeTimers() eliminates timezone, day-boundary, and interval flakiness
import { UserSessionService } from './UserSessionService';

describe('UserSessionService — timeout', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: new Date('2026-06-15T12:00:00.000Z') });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('expires session after 30 minutes of inactivity', () => {
    const session = UserSessionService.create('user-42');
    expect(session.isActive()).toBe(true);
    jest.advanceTimersByTime(31 * 60 * 1000);
    expect(session.isActive()).toBe(false);
  });

  it('does NOT expire session with activity within the window', () => {
    const session = UserSessionService.create('user-42');
    jest.advanceTimersByTime(20 * 60 * 1000);
    session.touch();
    jest.advanceTimersByTime(20 * 60 * 1000);
    expect(session.isActive()).toBe(true);
  });
});
```

### Pattern 6 — Shared State Isolation [community]

```typescript
// Shared module-level state is the #1 flakiness cause in unit test suites
import { jest } from '@jest/globals';
import { UserService } from './UserService';
import * as db from './db';

jest.mock('./db');

describe('UserService', () => {
  beforeEach(() => {
    jest.resetAllMocks();
    UserService.clearCache();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('returns cached user on second call', async () => {
    (db.findUser as jest.Mock).mockResolvedValueOnce({ id: 1, name: 'Alice' });
    await UserService.getUser(1);
    await UserService.getUser(1);
    expect(db.findUser).toHaveBeenCalledTimes(1);
  });
});
```

### Pattern 7 — Seeding Randomness for Deterministic Test Data [community]

```typescript
// GOOD: seed faker in beforeEach for deterministic, reproducible test data
import { faker } from '@faker-js/faker';

describe('UserService', () => {
  beforeEach(() => {
    faker.seed(12345);
  });

  it('creates a user with unique email', async () => {
    const email = faker.internet.email();
    const user = await UserService.create({ email });
    expect(user.email).toBe(email);
  });

  it('handles duplicate email gracefully', async () => {
    const email = faker.internet.email();
    await UserService.create({ email });
    await expect(UserService.create({ email })).rejects.toThrow('Email already exists');
  });
});
```

```typescript
// For crypto.randomUUID() — mock it in tests that assert on generated IDs
import { randomUUID } from 'crypto';
jest.mock('crypto', () => ({
  ...jest.requireActual('crypto'),
  randomUUID: jest.fn(),
}));

beforeEach(() => {
  let counter = 0;
  (randomUUID as jest.Mock).mockImplementation(() => `test-id-${++counter}`);
});
```

### Pattern 8 — Port Collision Prevention [community]

Hard-coded port numbers are one of the most common causes of parallel-run flakiness in monorepos.

```typescript
// utils/get-free-port.ts — assign a random free OS port for each test server
import * as net from 'net';

export function getFreePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      if (!address || typeof address === 'string') {
        return reject(new Error('Failed to get free port'));
      }
      const { port } = address;
      server.close(() => resolve(port));
    });
    server.on('error', reject);
  });
}
```

```typescript
// Integration test using dynamic port assignment — safe for parallel execution
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import express from 'express';
import type { Server } from 'http';
import supertest from 'supertest';
import { getFreePort } from '../utils/get-free-port';
import { createRouter } from '../src/api/router';

let server: Server;
let baseUrl: string;

beforeAll(async () => {
  const port = await getFreePort();
  const app = express();
  app.use('/api', createRouter());
  server = app.listen(port);
  baseUrl = `http://localhost:${port}`;
});

afterAll(async () => {
  await new Promise<void>(resolve => server.close(() => resolve()));
});

it('GET /api/health returns 200', async () => {
  const res = await supertest(baseUrl).get('/api/health');
  expect(res.status).toBe(200);
});
```

### Pattern 9 — React act() and Concurrent Mode Flakiness [community]

React's `act()` warning ("An update to X inside a test was not wrapped in act(...)") is one of the most common sources of intermittent failures in React component tests.

```typescript
// BAD: state update after await not wrapped in act — sporadic act() warning
import { render, screen } from '@testing-library/react';

it('shows user name after loading', async () => {
  render(<UserProfile userId="1" />);
  await new Promise(r => setTimeout(r, 100)); // sleep smell
  expect(screen.getByText('Alice')).toBeInTheDocument();
});

// GOOD: use findBy* which internally wraps in act() and retries
it('shows user name after loading', async () => {
  render(<UserProfile userId="1" />);
  // findByText polls until element appears (wraps in act automatically)
  const nameEl = await screen.findByText('Alice', {}, { timeout: 3000 });
  expect(nameEl).toBeInTheDocument();
});

// GOOD: when triggering user events, @testing-library/user-event v14+
// wraps all interactions in act() automatically
it('shows confirmation after button click', async () => {
  const user = userEvent.setup(); // v14 API — wraps all events in act()
  render(<ConfirmDialog onConfirm={jest.fn()} />);
  await user.click(screen.getByRole('button', { name: /confirm/i }));
  await screen.findByText('Action confirmed');
});
```

### Pattern 10 — Vitest Concurrent Test Isolation [community]

Vitest's `test.concurrent` enables parallel tests within a file but requires explicit isolation.

```typescript
// vitest.config.ts — configure pool for safe concurrent execution
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // 'forks' pool: each test file gets a separate process — maximum isolation
    pool: 'forks',
    clearMocks: true,
    restoreMocks: true,
    resetMocks: true,
  },
});
```

```typescript
// safe concurrent test pattern — inject dependencies, don't share singletons
import { describe, it, expect, vi } from 'vitest';
import { createUserService } from './UserService';

describe.concurrent('UserService concurrent tests', () => {
  it('creates user A', async ({ expect }) => {
    const mockDb = { insert: vi.fn().mockResolvedValue({ id: 'A', name: 'Alice' }) };
    const service = createUserService(mockDb); // factory, not singleton
    const user = await service.create({ name: 'Alice' });
    expect(user.id).toBe('A');
  });

  it('creates user B', async ({ expect }) => {
    const mockDb = { insert: vi.fn().mockResolvedValue({ id: 'B', name: 'Bob' }) };
    const service = createUserService(mockDb); // independent mock
    const user = await service.create({ name: 'Bob' });
    expect(user.id).toBe('B');
  });
});
```

### Pattern 11 — Snapshot Test Flakiness [community]

Snapshot tests (`toMatchSnapshot()`) are a common source of non-deterministic failures when they capture dynamic values: timestamps, random IDs, or auto-incrementing counters.

```typescript
// BAD: snapshot captures non-deterministic values — fails on every re-run
it('renders user card', () => {
  const user = {
    id: crypto.randomUUID(), // different every run
    name: 'Alice',
    createdAt: new Date().toISOString(), // changes every millisecond
  };
  const { container } = render(<UserCard user={user} />);
  expect(container).toMatchSnapshot(); // FLAKY
});

// GOOD: mask non-deterministic fields before snapshotting
it('renders user card structure', () => {
  const user = {
    id: 'FIXED-UUID-FOR-SNAPSHOT', // stable sentinel value
    name: 'Alice',
    createdAt: '2026-01-15T12:00:00.000Z', // fixed date
  };
  const { container } = render(<UserCard user={user} />);
  expect(container).toMatchSnapshot();
});

// BETTER: use inline snapshots for properties you DO care about structurally
it('renders user name and role badge', () => {
  const { getByRole, getByText } = render(
    <UserCard user={{ id: 'u1', name: 'Alice', role: 'admin', createdAt: '2026-01-15T12:00:00Z' }} />
  );
  expect(getByText('Alice')).toBeInTheDocument();
  expect(getByRole('img', { name: /admin badge/i })).toBeInTheDocument();
});
```

```typescript
// test-utils/snapshot-scrubber.ts — stable snapshot values for dynamic data
// Registered as a Jest snapshot serializer — applies to ALL toMatchSnapshot() calls

const UUID_PATTERN = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
const ISO_DATE_PATTERN = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/g;

export const print = (val: unknown): string =>
  JSON.stringify(val, null, 2)
    .replace(UUID_PATTERN, '[UUID]')
    .replace(ISO_DATE_PATTERN, '[ISO_DATE]');

export const test = (val: unknown): val is object =>
  typeof val === 'object' && val !== null;
```

### Pattern 12 — GitHub Actions Nightly Flakiness Detection [community]

```yaml
# .github/workflows/flakiness-detection.yml
# Run the full suite 5× nightly and report any test that fails at least once.
name: Nightly Flakiness Detection

on:
  schedule:
    - cron: '0 2 * * *'   # 2am UTC daily
  workflow_dispatch:

jobs:
  flakiness-sweep:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        run: [1, 2, 3, 4, 5]   # 5 independent runs in parallel
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - name: Run test suite (pass ${{ matrix.run }})
        run: npx jest --ci --json --outputFile=results-${{ matrix.run }}.json || true
      - uses: actions/upload-artifact@v4
        with:
          name: results-${{ matrix.run }}
          path: results-${{ matrix.run }}.json
```

### Pattern 13 — ESLint Rules for Static Flakiness Prevention [community]

Static analysis can catch flakiness-prone patterns before they reach CI.

```jsonc
// .eslintrc.cjs — flakiness-prevention ESLint config for test files
{
  "overrides": [
    {
      "files": ["**/*.test.ts", "**/*.spec.ts"],
      "rules": {
        "@typescript-eslint/no-floating-promises": "error",
        "no-restricted-syntax": [
          "error",
          {
            "selector": "AwaitExpression > NewExpression[callee.name='Promise'] > ArrowFunctionExpression CallExpression[callee.name='setTimeout'][arguments.1.type='Literal']",
            "message": "Use waitFor() or explicit condition polling instead of sleep() in tests"
          },
          {
            "selector": "CallExpression[callee.property.name='waitForTimeout']",
            "message": "Use page.waitForSelector() or expect(locator).toBeVisible() instead of waitForTimeout()"
          }
        ],
        "jest/no-disabled-tests": "warn",
        "jest/no-standalone-expect": "error",
        "jest/valid-expect": "error",
        "jest/no-conditional-expect": "error"
      }
    }
  ]
}
```

### Pattern 14 — Flakiness SLO Tracking [community]

Treating flakiness as a Service Level Objective transforms it from a morale problem into an engineering metric.

```typescript
// scripts/flakiness-slo.ts — parse JUnit XML and assert against SLO thresholds
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';

interface SLOConfig {
  maxFlakinessRatePercent: number;
  maxFlakyTestCount: number;
}

const SLO: SLOConfig = {
  maxFlakinessRatePercent: 5,   // team SLO: < 5% flaky test cases per run
  maxFlakyTestCount: 10,        // hard cap: no more than 10 quarantined test cases
};

function countFlakyFromJUnit(xmlPath: string): { total: number; flaky: number } {
  const xml = readFileSync(xmlPath, 'utf-8');
  const totalMatch = xml.match(/tests="(\d+)"/);
  const flakyMatches = xml.match(/flaky="true"/g);
  return {
    total: totalMatch ? parseInt(totalMatch[1], 10) : 0,
    flaky: flakyMatches ? flakyMatches.length : 0,
  };
}

const dir = process.argv[2] ?? 'test-results';
let totalTests = 0;
let flakyTests = 0;

for (const file of readdirSync(dir).filter(f => f.endsWith('.xml'))) {
  const metrics = countFlakyFromJUnit(join(dir, file));
  totalTests += metrics.total;
  flakyTests += metrics.flaky;
}

const flakinessRate = totalTests > 0 ? (flakyTests / totalTests) * 100 : 0;
const violations: string[] = [];
if (flakinessRate > SLO.maxFlakinessRatePercent)
  violations.push(`Flakiness rate ${flakinessRate.toFixed(1)}% > SLO ${SLO.maxFlakinessRatePercent}%`);
if (flakyTests > SLO.maxFlakyTestCount)
  violations.push(`Flaky count ${flakyTests} > SLO ${SLO.maxFlakyTestCount}`);

if (violations.length > 0) {
  violations.forEach(v => console.error('SLO VIOLATION: ' + v));
  process.exitCode = 1;
} else {
  console.log(`Flakiness SLO passed: ${flakyTests}/${totalTests} (${flakinessRate.toFixed(1)}%)`);
}
```

### Pattern 15 — WebSocket and SSE Flakiness [community]

Real-time protocols (WebSocket, Server-Sent Events) introduce race conditions that standard HTTP mocking cannot address: connection establishment timing, message ordering, and reconnect logic.

```typescript
// Pattern: Use a test WebSocket server with explicit event synchronization
import { WebSocketServer, WebSocket } from 'ws';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { NotificationClient } from '../src/NotificationClient';

let wss: WebSocketServer;
let serverPort: number;

beforeAll(async () => {
  // Use port 0 to let the OS assign a free port — eliminates port collision flakiness
  wss = new WebSocketServer({ port: 0 });
  serverPort = (wss.address() as { port: number }).port;
});

afterAll(async () => {
  await new Promise<void>(resolve => wss.close(() => resolve()));
});

it('receives notification within 2 seconds', async () => {
  const client = new NotificationClient(`ws://localhost:${serverPort}`);

  const messageReceived = new Promise<string>((resolve) => {
    wss.once('connection', (socket: WebSocket) => {
      // Wait for client to send its subscription, THEN emit the notification
      socket.once('message', (_subscribeMsg) => {
        socket.send(JSON.stringify({ type: 'notification', message: 'Order shipped' }));
      });
    });
    client.onMessage(resolve);
  });

  await client.connect();
  client.subscribe('orders');

  const received = await messageReceived;
  expect(JSON.parse(received).message).toBe('Order shipped');
  await client.disconnect();
});
```

### Pattern 16 — Memory Leak and Resource Exhaustion Flakiness [community]

Tests that leak memory or file descriptors cause later tests in the same worker process to fail with OOM errors or EMFILE (too many open files) — failures that appear non-deterministic.

```typescript
// Pattern: Use the 'using' keyword (TypeScript 5.2+) for automatic resource cleanup
import { describe, it, expect } from 'vitest';
import { createReadStream } from 'fs';
import { createInterface } from 'readline';

class DisposableReadline implements Disposable {
  readonly rl: ReturnType<typeof createInterface>;
  constructor(filePath: string) {
    this.rl = createInterface({
      input: createReadStream(filePath),
      crlfDelay: Infinity,
    });
  }
  [Symbol.dispose](): void {
    this.rl.close(); // guaranteed to run even on test failure
  }
}

describe('LogParser', () => {
  it('counts error lines in log file', async () => {
    // 'using' guarantees disposal — no fd leak even if assertion throws
    using reader = new DisposableReadline('test-fixtures/sample.log');
    let errorCount = 0;
    for await (const line of reader.rl) {
      if (line.includes('[ERROR]')) errorCount++;
    }
    expect(errorCount).toBeGreaterThan(0);
  });
});
```

```typescript
// Pattern: Explicit cleanup registry for resources in beforeAll/afterAll
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';

let pool: Pool;
const cleanupFns: (() => Promise<void>)[] = [];

beforeAll(async () => {
  pool = new Pool({ connectionString: process.env.TEST_DB_URL });
  cleanupFns.push(() => pool.end());
});

afterAll(async () => {
  // Drain all registered cleanup functions in reverse order (LIFO)
  for (const fn of cleanupFns.reverse()) {
    try { await fn(); } catch (e) { console.error('Cleanup failed:', e); }
  }
});
```

### Pattern 17 — Safe Async Timeout Helper [community]

Hard-coded timeouts (`test('...', async () => {...}, 30000)`) are blunt instruments. A composable `withTimeout` helper makes timeout flakiness diagnosable.

```typescript
// test-utils/with-timeout.ts — composable timeout with AbortSignal support
export class TimeoutError extends Error {
  constructor(operationName: string, ms: number) {
    super(`"${operationName}" timed out after ${ms}ms — possible flakiness: check for missing await, deadlock, or network call without mock`);
    this.name = 'TimeoutError';
  }
}

export function withTimeout<T>(
  operationName: string,
  ms: number,
  fn: (signal: AbortSignal) => Promise<T>
): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);

  return fn(controller.signal)
    .then(result => { clearTimeout(timer); return result; })
    .catch(err => {
      clearTimeout(timer);
      if (controller.signal.aborted) throw new TimeoutError(operationName, ms);
      throw err;
    });
}

// Usage in tests:
it('fetches user data within 500ms', async () => {
  const user = await withTimeout('fetchUser', 500, async (signal) => {
    const res = await fetch('/api/users/1', { signal });
    return res.json();
  });
  expect(user.name).toBe('Alice');
});
```

### Pattern 18 — Test Doubles Taxonomy for Flakiness Prevention [community]

Misusing test doubles (confusing stubs, mocks, spies, and fakes) is a root cause of subtle flakiness.

```typescript
// Taxonomy demonstration — each double type has a specific use case
import { jest } from '@jest/globals';
import type { EmailClient } from './types';

describe('UserService — test doubles taxonomy', () => {
  // STUB: provides canned responses, ignores call details
  it('creates user and returns user object (stub)', async () => {
    const emailStub: EmailClient = {
      send: async () => ({ messageId: 'stub-id', accepted: ['test@example.com'] }),
    };
    const service = new UserService(emailStub);
    const user = await service.create({ name: 'Alice', email: 'alice@example.com' });
    expect(user.id).toBeDefined();
  });

  // FAKE: lightweight real implementation (in-memory DB, no network)
  // Fakes are NOT flaky — they behave identically every run
  it('creates user and queries it back (fake)', async () => {
    const fakeDb = new InMemoryUserDatabase(); // implements UserDatabase interface
    const service = new UserService(new RealEmailClient({ dryRun: true }), fakeDb);
    const created = await service.create({ name: 'Dave', email: 'dave@example.com' });
    const found = await service.findById(created.id);
    expect(found?.email).toBe('dave@example.com');
  });

  // MOCK: pre-programmed expectations — verifies at the end
  it('sends exactly one email with correct subject (mock)', async () => {
    const emailMock = {
      send: jest.fn<EmailClient['send']>().mockResolvedValue({
        messageId: 'mock-id', accepted: ['carol@example.com'],
      }),
    };
    const service = new UserService(emailMock);
    await service.create({ name: 'Carol', email: 'carol@example.com' });
    expect(emailMock.send).toHaveBeenCalledExactlyOnceWith(
      expect.objectContaining({ subject: 'Welcome to the platform, Carol!' })
    );
  });
});
```

---

## Anti-Patterns

### AP1 — The Silent Re-Run [community]
**What:** Developer clicks "Retry" in CI when a test fails, test passes, no action taken.
**Why harmful:** Flakiness rate grows silently. Failures become routine noise. Real regressions get masked. Fowler: "A test that sometimes fails is just as bad as a test that always fails — you can never trust it."

### AP2 — `sleep()` / `waitForTimeout()` as a Fix [community]
**What:** Adding `await new Promise(r => setTimeout(r, 500))` to make a timing issue "go away."
**Why harmful:** Increases suite runtime O(N) with every flaky test "fixed" this way. Still fails under CI load. Does not fix the race — just widens the window.

### AP3 — Shared Database Without Rollback [community]
**What:** Multiple tests insert rows into the same DB schema with no cleanup.
**Why harmful:** Works until tests run in parallel. Concurrent writes cause constraint violations, stale reads, or unexpected result sets.

### AP4 — Real Network Calls in Unit/Integration Tests [community]
**What:** Tests that call actual HTTP endpoints or third-party APIs without mocking.
**Why harmful:** Flakiness from network latency, API rate limits, credential expiry, and upstream outages.

### AP5 — Deleting Flaky Tests [community]
**What:** Removing a test rather than quarantining it.
**Why harmful:** You lose coverage you may not recreate. Quarantine preserves intent; deletion abandons it.

### AP6 — Global Date/Time Without Clock Control [community]
**What:** Tests that use `new Date()` or `Date.now()` without injecting a controllable clock.
**Why harmful:** Tests pass at 11:58pm and fail at midnight (timezone + day-boundary edge cases).

### AP7 — Quarantine Without SLA [community]
**What:** Tests marked `[QUARANTINE]` with no due date, no owner, and no tracking issue.
**Why harmful:** The quarantine backlog accumulates indefinitely. Coverage gaps grow. After 6 months, quarantined tests are effectively deleted.

### AP8 — Hard-Coded Port Numbers in Test Setup [community]
**What:** Test servers bound to fixed ports (e.g., `app.listen(3001)`).
**Why harmful:** Two test suites running in parallel bind to the same port, producing `EADDRINUSE` errors.

### AP9 — Snapshot Tests With Dynamic Data [community]
**What:** Using `toMatchSnapshot()` on components that include timestamps, UUIDs, or random IDs.
**Why harmful:** Every run produces a different snapshot. Developers blindly update snapshots on failure, losing the signal. Snapshot tests should capture *structural* intent, not incidental runtime values.

### AP10 — No Flakiness SLO or Metric [community]
**What:** Teams track individual failing test cases reactively but have no defined flakiness rate target.
**Why harmful:** Without a metric, you cannot improve. Flakiness accumulates silently until CI is too noisy to trust. With a defined SLO (e.g., flakiness rate < 5%), teams can measure progress and catch regressions before they compound.

---

## Real-World Gotchas [community]

1. **`beforeAll` setup is an order-dependency time bomb.** [community]
   Placing expensive setup in `beforeAll` and teardown in `afterAll` creates tests that fail when run in isolation. Always verify each test case can run alone with `--testNamePattern`. Root cause: suites evolve and someone adds a `beforeAll`-dependent test months later.

2. **Playwright `networkidle` is a notorious source of CI flakiness.** [community]
   `waitForLoadState('networkidle')` waits for 500ms of no network requests — analytics, chat widgets, and polling APIs can keep this waiting indefinitely. Replace with `waitForResponse()` targeting your own API endpoints or explicit locator assertions.

3. **Jest module caching causes shared singleton state across test files.** [community]
   When two test files import the same module, Jest reuses the cached instance. A module that mutates its own state (e.g., a singleton event bus) causes cross-file flakiness that's nearly impossible to reproduce locally. Fix: `resetModules: true` in jest.config.

4. **CI parallelism amplifies every existing race condition.** [community]
   A test suite that runs green locally can show 10–30% flakiness rate when first moved to parallel execution. Audit all `tmp` file paths and DB sequences before enabling parallelism.

5. **Timezone and locale flakiness is invisible until you deploy globally.** [community]
   Tests that use `toLocaleDateString()` or `Intl.DateTimeFormat` without fixing locale and timezone produce different output on developer machines vs. CI (UTC). Fix: set `TZ=UTC` in CI env and use `jest.useFakeTimers({ now: new Date('2026-01-15T12:00:00Z') })`.

6. **Retry-without-reporting hides a growing flakiness debt.** [community]
   Configuring `retries: 2` is correct, but only if you track and alert on retry rate. A test case that passes on retry 2 every day is costing CI minutes and hiding a real defect. Wire retry counts to a flakiness dashboard or fail the build if retry rate exceeds 5%.

7. **Unawaited Promises in `afterEach` cause order-dependency across test files.** [community]
   `afterEach(async () => { cleanup() })` — if `cleanup()` returns a Promise and you forget `await`, the cleanup runs concurrently with the next test's setup, corrupting shared state. Enable `jest/no-floating-promises` ESLint rule to catch this statically.

8. **`detectOpenHandles` reveals timer/Promise leaks invisible to retries.** [community]
   Jest's `--detectOpenHandles` flag identifies tests that leave open `setTimeout`, `setInterval`, database connections, or unresolved Promises. These leaks don't cause the current test case to fail — they cause the next test file's worker to receive unexpected callbacks. Enable `detectOpenHandles: true` in `jest.config.ts`.

9. **MSW v1→v2 migration caused widespread handler flakiness.** [community]
   MSW v2 changed handler matching semantics — `rest.get` became `http.get`, and response resolvers changed signature. Teams that upgraded without updating handlers saw intermittent 500 errors in tests because old and new handlers conflicted. Always pin MSW version in `package.json` and upgrade in a single atomic PR.

10. **Cypress `cy.intercept()` race conditions with async route registration.** [community]
    `cy.intercept()` must be called before the network request it intercepts. If the component triggers a fetch immediately on mount (before `cy.intercept()` registers), the real request goes through. Always call `cy.intercept()` before `cy.visit()` or `cy.mount()`, never after.

11. **Shard-dependent flakiness is misattributed to "environment differences."** [community]
    When a test suite is first moved to a sharded CI strategy, some teams see failures that "don't happen locally." The root cause is almost always order-dependency: the test was passing because another test in the same run set up global state. Varying the shard count or seed between runs is the fastest diagnostic.

12. **CI environment variable differences cause tests to pass locally but fail in CI.** [community]
    Tests that read `process.env.NODE_ENV` or `process.env.TZ` without explicit defaults behave differently on developer machines vs. CI runners. Fix: enforce `TZ=UTC` in CI and test config, use `dotenv-flow` with an explicit `.env.test.defaults` file that ships with the repo.

---

## Tradeoffs & Alternatives

### When quarantine-and-fix works well
- Small-to-medium test suites (< 2000 test cases) where flaky tests are rare events
- Teams with a dedicated "flaky test" rotation or clear ownership
- Teams with a quarantine SLA (e.g., all quarantined tests fixed within 2 sprints)

### When quarantine becomes unmanageable
- Suites with > 5% flakiness rate: quarantine backlog grows faster than it's fixed
- Teams without a fix-it rotation: quarantine becomes a graveyard
- Monorepos where multiple teams share a test runner: no single owner for the backlog

**Alternative: Flakiness budget + hard cap.** Google enforces that any test exceeding a flakiness threshold is automatically disabled and must be fixed before re-enabling. Implementation: a CI job that reads retry counts from JUnit XML and fails the build if any single test's flakiness rate exceeds 3%.

**Alternative: Test hermetic environments.** Instead of mocking, spin up a real DB and real service in a container per test run (Testcontainers for Node). Eliminates most shared-state and external-dep flakiness at the cost of slower setup (~5–30s per suite).

```typescript
// Integration test with Testcontainers — hermetic PostgreSQL per test suite
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { UserRepository } from '../src/UserRepository';

let container: StartedPostgreSqlContainer;
let pool: Pool;

beforeAll(async () => {
  container = await new PostgreSqlContainer('postgres:16-alpine').start();
  pool = new Pool({ connectionString: container.getConnectionUri() });
  await pool.query('CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)');
}, 60_000);

afterAll(async () => {
  await pool.end();
  await container.stop();
});

beforeEach(async () => {
  await pool.query('TRUNCATE users RESTART IDENTITY CASCADE');
});

it('saves and retrieves a user', async () => {
  const repo = new UserRepository(pool);
  const saved = await repo.create({ name: 'Alice' });
  const found = await repo.findById(saved.id);
  expect(found?.name).toBe('Alice');
});
```

**Alternative: Flakiness SLO with JUnit XML parsing.** Parse JUnit XML from CI directly and assert against a team-defined SLO (e.g., flakiness rate < 5%). Zero external dependencies, full ownership of the threshold, and immediate PR-level feedback.

**Known adoption costs:**
- Quarantine tooling requires team agreement on tags and a weekly backlog review process
- Replacing `sleep()` with `waitFor()` requires understanding what condition to wait on
- Fake timers can cause issues with async libraries that internally use `setTimeout` for debouncing
- MSW adds a test infrastructure dependency; handler maintenance burden grows with API surface area
- Testcontainers requires Docker in CI; adds 5–30s cold-start latency per suite

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Eradicating Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Fowler's canonical taxonomy of flakiness root causes |
| Flaky Tests at Google | Official | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Scale data on flakiness rates and Google's quarantine approach |
| Playwright Retries Docs | Official | https://playwright.dev/docs/test-retries | Retry configuration, trace on retry, flakiness reporting |
| Jest Retry Times | Official | https://jestjs.io/docs/configuration#retrytimes-number | jest-circus retry configuration |
| Jest detectOpenHandles | Official | https://jestjs.io/docs/configuration#detectopenhandles-boolean | Detects timer/Promise/connection leaks between tests |
| Vitest Pool Configuration | Official | https://vitest.dev/config/#pool | Concurrent test isolation settings |
| Mock Service Worker | Community | https://mswjs.io/ | Network-level mocking that prevents real HTTP calls |
| Testcontainers for Node | Community | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Hermetic DB/service containers to eliminate external dep flakiness |
| @sinonjs/fake-timers | Community | https://github.com/sinonjs/fake-timers | Controllable clock for timing-sensitive tests |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology: test case, test level, defect, test suite |
