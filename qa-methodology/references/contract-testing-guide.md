# Contract Testing (Consumer-Driven) — QA Methodology Guide
<!-- lang: JavaScript | topic: contract-testing | iteration: 3 | score: 100/100 | date: 2026-04-27 -->
<!-- sources: training knowledge (WebFetch/WebSearch unavailable) | official: docs.pact.io, pact-foundation/pact-js | community: production lessons -->

## Core Principles

Consumer-Driven Contract Testing (CDC) is a technique for testing integration points between services by defining the contract from the **consumer's perspective** rather than the provider's. The consumer specifies exactly what it needs from the provider, generating a "pact" (contract file) that the provider then verifies independently — without the consumer running at all.

### Why consumer-driven?

Traditional provider-driven approaches document what an API *can* do. CDC documents what consumers *actually use*, making breaking changes visible before they reach production.

**The 10 core concepts:**

1. **Consumer defines expectations, not the provider** — The consuming service writes tests that describe interactions it depends on (request shape + expected response shape). This means only genuinely-used fields are protected; unused fields can change freely.

2. **Pact workflow** — Consumer writes interaction → pact file (JSON) generated locally → pact file published to Pact Broker → provider pulls pact → provider verifies interactions against real code → verification result published back to Broker.

3. **Pact Broker** — Central store for pact files. Enables teams to decouple: consumer and provider CI pipelines are independent. The Broker tracks which consumer versions are compatible with which provider versions.

4. **Consumer test anatomy** — Uses `@pact-foundation/pact` to spin up a mock provider on a local port. The consumer's real HTTP client makes requests to the mock; the library records the interaction and writes the pact file.

5. **Provider verification** — The provider's CI downloads the pact from the Broker, replays recorded interactions against the real running provider, and publishes a pass/fail result.

6. **can-i-deploy** — A Pact CLI command that queries the Broker to determine whether a given consumer or provider version is safe to deploy to an environment, based on verified pact compatibility matrices.

7. **CDC vs integration tests** — CDC tests the *contract shape* (does the response have the right structure?). Integration tests test *real behaviour* (does the system behave correctly end-to-end?). CDC is fast, isolated, parallelizable; integration tests are slower but catch emergent behaviours.

8. **OpenAPI contract validation** — A lighter alternative where both sides agree on an OpenAPI spec and validate conformance using tools like `openapi-backend` or `dredd`. No Pact Broker needed, but no consumer-driven specificity.

9. **When CDC adds most value** — Microservices architectures with multiple independent consumers hitting shared providers; teams that deploy independently and need deployment safety gates.

10. **Breaking change detection** — When a provider changes a response field that a consumer pact depends on, provider verification fails before deployment, surfacing the break in CI rather than production. The key insight: the Broker's compatibility matrix shows *which consumer version is affected*, making targeted rollback possible. A provider can safely rename `warehouseId` to `facilityId` only after all consumers have published new pacts that no longer reference `warehouseId`.

---

## When to Use

**CDC is high-value when:**
- Multiple independent teams consume the same API
- Consumer and provider deploy on different schedules
- You cannot run full integration tests on every PR due to environment costs
- A service has ≥ 3 consumers with different subsets of fields
- You are migrating a monolith to microservices and want safety nets per extracted service

**CDC is overkill when:**
- Monolith: consumer and provider ship together — a compile-time check is sufficient
- Single consumer with full integration test coverage
- The "API" is a shared library (not a network call)
- Team is small and shared ownership means a grep/refactor covers breakage
- The integration point is with an external third-party API you don't control (use OpenAPI validation instead)

**CDC for non-HTTP protocols:**
- **GraphQL**: Pact supports GraphQL queries via HTTP body matching; use `GraphQLInteraction` from `@pact-foundation/pact`. Provider verification works the same way.
- **gRPC**: Pact V4 has experimental gRPC/Protobuf support. For stable setups, use `buf`'s breaking change detection on Protobuf schemas as a lighter alternative.
- **Async (Kafka/SNS/SQS)**: Use `MessageConsumerPact` as shown in the Patterns section below.

### Position in the Testing Pyramid

```
         /\
        /E2E\          ← Slow, expensive; test critical user journeys only
       /------\
      / Integr.\       ← Test real service wiring; thin layer (smoke tests)
     /----------\
    /  Contract  \     ← CDC lives here: fast, isolated, per-service
   /--------------\
  /    Unit Tests  \   ← Fast, no I/O; test business logic
 /------------------\
```

CDC sits between unit and integration tests. It replaces the "does the API shape match?" concern from integration tests, allowing the integration test layer to focus purely on end-to-end behaviour rather than structural compatibility.

---

## Patterns

### Pact Consumer Test (JavaScript / Node.js)

```javascript
// order-service.consumer.pact.spec.js
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client.js';

const { like, string, integer } = MatchersV3;

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8081,
  logLevel: 'warn',
});

describe('OrderService → InventoryService contract', () => {
  describe('GET /inventory/:sku', () => {
    it('returns stock level for a known SKU', async () => {
      await provider
        .given('SKU ABC-123 exists with 10 units in stock')
        .uponReceiving('a request for stock level of SKU ABC-123')
        .withRequest({
          method: 'GET',
          path: '/inventory/ABC-123',
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            sku: string('ABC-123'),
            available: integer(10),
            warehouseId: like('WH-001'),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new OrderClient(mockServer.url);
          const result = await client.getStock('ABC-123');
          expect(result.sku).toBe('ABC-123');
          expect(result.available).toBeGreaterThanOrEqual(0);
        });
    });
  });

  describe('GET /inventory/:sku — 404 path', () => {
    it('handles unknown SKU gracefully', async () => {
      await provider
        .given('SKU UNKNOWN-999 does not exist')
        .uponReceiving('a request for a non-existent SKU')
        .withRequest({ method: 'GET', path: '/inventory/UNKNOWN-999' })
        .willRespondWith({ status: 404 })
        .executeTest(async (mockServer) => {
          const client = new OrderClient(mockServer.url);
          await expect(client.getStock('UNKNOWN-999')).rejects.toThrow('Stock not found');
        });
    });
  });
});
```

**Key points:**
- Use `MatchersV3` (`like`, `string`, `integer`) rather than exact values — this prevents brittle tests while still asserting the contract shape
- The `given(...)` string becomes a *provider state* that the provider side must implement
- The pact file is written to `./pacts/` after the test run

---

### Pact Provider Verification (JavaScript / Node.js)

```javascript
// inventory-service.provider.pact.spec.js
import { VerifierV3 } from '@pact-foundation/pact';
import { startServer, stopServer } from '../src/test-server.js';
import { db } from '../src/db.js';

describe('InventoryService provider verification', () => {
  let serverPort;

  beforeAll(async () => {
    serverPort = await startServer();
  });

  afterAll(async () => {
    await stopServer();
  });

  it('satisfies all consumer pacts', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: `http://localhost:${serverPort}`,

      // Pull pacts from broker in CI; use local file in dev
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [
        { mainBranch: true },
        { deployedOrReleased: true },
      ],

      // Provider states: map state names to setup functions
      stateHandlers: {
        'SKU ABC-123 exists with 10 units in stock': async () => {
          await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
        },
        'SKU UNKNOWN-999 does not exist': async () => {
          await db.clear('UNKNOWN-999');
        },
      },

      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,

      // Inject auth tokens that the real provider requires
      // Pact ignores Authorization headers in matching, but the provider
      // still needs them to serve responses correctly
      requestFilter: (req, _res, next) => {
        req.headers['Authorization'] = `Bearer ${process.env.PROVIDER_TEST_TOKEN}`;
        next();
      },
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `consumerVersionSelectors` controls which consumer pacts to verify: `mainBranch` + `deployedOrReleased` covers the important cases
- `stateHandlers` seed test data for each provider state string defined in consumer tests — mismatch here is the #1 cause of false failures
- Set `publishVerificationResult` to `true` only in CI via env var (not local dev)
- `requestFilter` injects auth headers that the provider needs to respond correctly — Pact deliberately ignores `Authorization` in matching but providers still need it

---

### Pact File Structure (JSON)

```json
{
  "consumer": { "name": "OrderService" },
  "provider": { "name": "InventoryService" },
  "interactions": [
    {
      "description": "a request for stock level of SKU ABC-123",
      "providerStates": [
        { "name": "SKU ABC-123 exists with 10 units in stock" }
      ],
      "request": {
        "method": "GET",
        "path": "/inventory/ABC-123",
        "headers": { "Accept": "application/json" }
      },
      "response": {
        "status": 200,
        "headers": { "Content-Type": "application/json" },
        "body": { "sku": "ABC-123", "available": 10, "warehouseId": "WH-001" },
        "matchingRules": {
          "body": {
            "$.sku":         { "matchers": [{ "match": "type" }] },
            "$.available":   { "matchers": [{ "match": "integer" }] },
            "$.warehouseId": { "matchers": [{ "match": "type" }] }
          }
        }
      }
    }
  ],
  "metadata": {
    "pactSpecification": { "version": "3.0.0" },
    "pact-js": { "version": "12.1.0" }
  }
}
```

---

### can-i-deploy in CI

```bash
# Install Pact CLI
npm install --save-dev @pact-foundation/pact-cli

# Check whether OrderService v1.2.3 can be deployed to production
npx pact-broker can-i-deploy \
  --pacticipant OrderService \
  --version "1.2.3" \
  --to-environment production \
  --broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN"

# Typical CI step (exits non-zero if unsafe to deploy)
npx pact-broker can-i-deploy \
  --pacticipant OrderService \
  --version "$GIT_COMMIT" \
  --to-environment staging \
  --broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN" \
  --retry-while-unknown 3 \
  --retry-interval 10
```

**CI pipeline order:**
1. Consumer tests run → pact file generated → published to Broker
2. Provider tests run → verify pact → publish result to Broker
3. `can-i-deploy` runs before deploy step in each pipeline
4. Deploy proceeds only if `can-i-deploy` exits 0

### Publishing Pacts to the Broker (CI script)

```bash
#!/usr/bin/env bash
# publish-pacts.sh — run after consumer test suite generates ./pacts/*.json

set -euo pipefail

PACT_DIR="$(pwd)/pacts"
CONSUMER_VERSION="${GIT_COMMIT:?GIT_COMMIT env var required}"
CONSUMER_BRANCH="${GIT_BRANCH:?GIT_BRANCH env var required}"
BROKER_URL="${PACT_BROKER_URL:?PACT_BROKER_URL env var required}"
BROKER_TOKEN="${PACT_BROKER_TOKEN:?PACT_BROKER_TOKEN env var required}"

echo "Publishing pacts from ${PACT_DIR} for version ${CONSUMER_VERSION} on branch ${CONSUMER_BRANCH}"

npx pact-broker publish "${PACT_DIR}" \
  --consumer-app-version "${CONSUMER_VERSION}" \
  --branch "${CONSUMER_BRANCH}" \
  --broker-base-url "${BROKER_URL}" \
  --broker-token "${BROKER_TOKEN}" \
  --tag "${CONSUMER_BRANCH}"

echo "Pacts published. Checking can-i-deploy for staging..."

npx pact-broker can-i-deploy \
  --pacticipant OrderService \
  --version "${CONSUMER_VERSION}" \
  --to-environment staging \
  --broker-base-url "${BROKER_URL}" \
  --broker-token "${BROKER_TOKEN}" \
  --retry-while-unknown 5 \
  --retry-interval 15

echo "can-i-deploy: PASSED — safe to deploy to staging"
```

**Notes:**
- `--branch` (Pact Broker ≥ v2.82 / PactFlow) is preferred over `--tag` for branch tracking; use both for compatibility with older brokers
- The `set -euo pipefail` ensures the script fails fast if any Pact CLI command exits non-zero
- Store `PACT_BROKER_TOKEN` as a CI secret — never in source control

---

### Message Pact Consumer Test (JavaScript — async/event-driven)

```javascript
// notification-service.message.pact.spec.js
// Tests the shape of an event message consumed from a queue/topic
import path from 'path';
import { MessageConsumerPact, asynchronousBodyHandler, MatchersV3 } from '@pact-foundation/pact';

const { like, string, timestamp } = MatchersV3;

const messagePact = new MessageConsumerPact({
  consumer: 'NotificationService',
  provider: 'OrderService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

// The handler that processes the actual message in production
async function handleOrderCreatedEvent(body) {
  if (!body.orderId || !body.customerId) {
    throw new Error('Missing required fields: orderId, customerId');
  }
  // send notification logic...
}

describe('NotificationService consumes OrderCreated events', () => {
  it('handles a well-formed OrderCreated message', () => {
    return messagePact
      .given('an order has just been placed')
      .expectsToReceive('an OrderCreated event')
      .withContent({
        orderId: string('ORD-9876'),
        customerId: like('CUST-001'),
        totalAmount: like(99.99),
        currency: string('USD'),
        createdAt: timestamp("yyyy-MM-dd'T'HH:mm:ssXXX", '2024-01-15T10:00:00+00:00'),
      })
      .withMetadata({ contentType: 'application/json' })
      .verify(asynchronousBodyHandler(handleOrderCreatedEvent));
  });
});
```

**Key points:**
- `MessageConsumerPact` tests async message contracts (Kafka, SNS, SQS) — not just HTTP
- `asynchronousBodyHandler` wraps your real production message handler, proving the contract is exercised by real code
- The generated pact file looks identical to HTTP pacts but describes message shape instead of request/response
- Provider side uses `MessageProviderPact` to publish sample messages and verify they match

---

### Shared Provider State Constants (JavaScript — prevents silent mismatches)

```javascript
// pact-states.js — shared constants imported by both consumer and provider tests
// Place in a shared package or committed to a contracts repository

export const InventoryStates = {
  SKU_IN_STOCK: (sku, qty) =>
    `SKU ${sku} exists with ${qty} units in stock`,
  SKU_NOT_FOUND: (sku) =>
    `SKU ${sku} does not exist`,
  WAREHOUSE_OFFLINE: (warehouseId) =>
    `Warehouse ${warehouseId} is temporarily offline`,
};

// In consumer test — import and use the constant
import { InventoryStates } from '../shared/pact-states.js';

await provider
  .given(InventoryStates.SKU_IN_STOCK('ABC-123', 10))
  .uponReceiving('a stock-level request');
// ...

// In provider stateHandlers — same constant, no string drift
import { InventoryStates } from '../shared/pact-states.js';

const stateHandlers = {
  [InventoryStates.SKU_IN_STOCK('ABC-123', 10)]: async () => {
    await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
  },
  [InventoryStates.SKU_NOT_FOUND('UNKNOWN-999')]: async () => {
    await db.clear('UNKNOWN-999');
  },
};
```

**Key points:**
- String-based provider states are the #1 cause of silent CDC test failures: consumer renames a state string, handler silently stops matching
- Exporting factory functions (not raw strings) means a typo produces a JS reference error at import time, not a silent test pass
- The shared module can also export response schemas, making contract drift visible at code review

---

### Dynamic Provider State with `fromProviderState`

```javascript
// order-details.consumer.pact.spec.js
// Scenario: the consumer fetches an order by its server-assigned ID.
// The exact ID is unknown at test-write time; the provider state handler
// creates the record and injects the ID via a state variable.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client.js';

const { fromProviderState, like, string, integer } = MatchersV3;

const provider = new PactV3({
  consumer: 'CheckoutService',
  provider: 'OrderService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8082,
  logLevel: 'warn',
});

describe('CheckoutService → OrderService contract', () => {
  it('fetches a specific order by server-assigned ID', async () => {
    await provider
      .given('an order exists', { orderId: 'ORD-DYNAMIC-001' })
      .uponReceiving('a request for order details')
      .withRequest({
        method: 'GET',
        // fromProviderState: path uses the value the provider injects
        path: fromProviderState('/orders/${orderId}', '/orders/ORD-DYNAMIC-001'),
        headers: { Accept: 'application/json' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          id: fromProviderState('${orderId}', 'ORD-DYNAMIC-001'),
          status: string('PENDING'),
          totalAmount: like(99.99),
          lineItems: like([{ sku: string('SKU-1'), qty: integer(2) }]),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new OrderClient(mockServer.url);
        const result = await client.getOrder('ORD-DYNAMIC-001');
        expect(result.id).toBe('ORD-DYNAMIC-001');
        expect(result.status).toBeDefined();
      });
  });
});
```

**Key points:**
- `fromProviderState('${orderId}', 'ORD-DYNAMIC-001')` tells Pact: "during consumer test, use the fallback value; during provider verification, replace it with the state variable `orderId` injected by the state handler"
- The provider state handler receives `{ orderId: 'ORD-DYNAMIC-001' }` as parameters, seeds the database, then returns `{ orderId: createdRecord.id }` — Pact injects this into the interaction at replay time
- This pattern eliminates hardcoded IDs in pact files, making provider state handlers simpler and pacts reusable across environments

---

### OpenAPI Validation Alternative (JavaScript)

```javascript
// openapi-validation.spec.js — validate provider response against spec
import SwaggerParser from '@apidevtools/swagger-parser';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

describe('InventoryService OpenAPI conformance', () => {
  let api;
  const ajv = new Ajv({ strict: false });
  addFormats(ajv);

  beforeAll(async () => {
    api = await SwaggerParser.dereference('./openapi/inventory.yaml');
  });

  it('GET /inventory/{sku} 200 response matches schema', async () => {
    const schema = api.paths['/inventory/{sku}'].get.responses['200']
      .content['application/json'].schema;

    const validate = ajv.compile(schema);
    const response = { sku: 'ABC-123', available: 10, warehouseId: 'WH-001' };
    expect(validate(response)).toBe(true);
  });
});
```

**When to choose OpenAPI validation over Pact:**
- Single consumer, stable API
- Team already maintains an OpenAPI spec
- Pact Broker infrastructure cost is not justified
- You need schema-level validation but not interaction-level replay

---

### Enabling WIP / Pending Pacts (JavaScript)

```javascript
// inventory-service.provider.pact.spec.js — with WIP and pending pacts enabled
// This prevents new unverified consumer pacts from blocking provider CI.
import { VerifierV3 } from '@pact-foundation/pact';
import { startServer, stopServer } from '../src/test-server.js';
import { db } from '../src/db.js';

describe('InventoryService provider verification (with WIP/pending enabled)', () => {
  let serverPort;

  beforeAll(async () => { serverPort = await startServer(); });
  afterAll(async () => { await stopServer(); });

  it('satisfies all consumer pacts, treating new ones as advisory', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: `http://localhost:${serverPort}`,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [
        { mainBranch: true },
        { deployedOrReleased: true },
      ],

      // WIP pacts: pacts that have never been successfully verified are
      // treated as "pending" — failures are reported but don't fail the build.
      // This lets consumers publish new pacts ahead of provider implementation
      // without blocking the provider pipeline.
      enablePending: true,
      includeWipPactsSince: '2024-01-01', // ISO date — include WIP pacts since this date

      stateHandlers: {
        'SKU ABC-123 exists with 10 units in stock': async () => {
          await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
        },
        'SKU UNKNOWN-999 does not exist': async () => {
          await db.clear('UNKNOWN-999');
        },
      },

      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `enablePending: true` — pacts that have *never* been verified before are "pending". Failures in pending pacts show in the output but do not cause the build to fail
- `includeWipPactsSince` — date threshold for which WIP pacts to include; prevents very old unverified pacts from silently reappearing
- Once the provider verifies a pending pact successfully, it loses its pending status and becomes a hard gate going forward
- This feature requires Pact Broker ≥ v2.60+ or PactFlow

---

### Pact V4 / pact-js v13 Migration (JavaScript)

```javascript
// order-service.consumer.pact.v4.spec.js — pact-js v13 (Pact V4 spec)
// V4 uses PactV4 class; otherwise the consumer API is similar to V3.
// Key difference: no `port` option — mock server auto-assigns a port.
import path from 'path';
import { PactV4, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client.js';

const { string, integer, like } = MatchersV3;

const provider = new PactV4({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  // V4: no `port` — auto-assigned; avoids port collision in parallel test suites
  logLevel: 'warn',
});

describe('OrderService → InventoryService (Pact V4)', () => {
  it('returns stock level for a known SKU', async () => {
    await provider
      .addInteraction()
      .given('SKU ABC-123 exists with 10 units in stock')
      .uponReceiving('a request for stock level of SKU ABC-123')
      .withRequest('GET', '/inventory/ABC-123', (builder) => {
        builder.headers({ Accept: 'application/json' });
      })
      .willRespondWith(200, (builder) => {
        builder
          .headers({ 'Content-Type': 'application/json' })
          .jsonBody({
            sku: string('ABC-123'),
            available: integer(10),
            warehouseId: like('WH-001'),
          });
      })
      .executeTest(async (mockServer) => {
        const client = new OrderClient(mockServer.url);
        const result = await client.getStock('ABC-123');
        expect(result.sku).toBe('ABC-123');
        expect(typeof result.available).toBe('number');
      });
  });
});
```

**Key points:**
- `PactV4` class replaces `PactV3`; V4 pact files are backward-compatible — the Pact Broker accepts both V3 and V4 specs
- No `port` option: V4 auto-assigns the mock server port, eliminating port collision when running test files in parallel
- `addInteraction()` builder API replaces the chained `.given().uponReceiving()` pattern from V3; behaviour is equivalent
- V4 supports a plugin architecture for gRPC, Protobuf, and XML via community plugins — install the plugin and enable it in `PactV4` constructor options
- **When to migrate:** new projects should start with pact-js v13 (V4); for existing V3 pact files the transition is safe since V4 is backward-compatible

---

### GitHub Actions CI Pipeline for Pact (full workflow)

```yaml
# .github/workflows/pact.yml
name: Pact Contract Tests

on:
  push:
    branches: [main, 'feature/**']
  pull_request:

env:
  PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
  PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}

jobs:
  # ── Consumer side ──────────────────────────────────────────────────────────
  consumer-pact:
    name: Consumer — generate pacts
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Run consumer pact tests
        run: npx jest --testPathPattern="\.pact\.spec\." --forceExit
      - name: Publish pacts to broker
        run: |
          npx pact-broker publish ./pacts \
            --consumer-app-version "${{ github.sha }}" \
            --branch "${{ github.ref_name }}" \
            --broker-base-url "$PACT_BROKER_URL" \
            --broker-token "$PACT_BROKER_TOKEN"

  # ── Provider side ──────────────────────────────────────────────────────────
  provider-pact:
    name: Provider — verify pacts
    runs-on: ubuntu-latest
    needs: []
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Start provider test server
        run: npm run start:test &
        env:
          PORT: 3001
      - name: Wait for server to be ready
        run: npx wait-on http://localhost:3001/health --timeout 30000
      - name: Run provider verification
        run: npx jest --testPathPattern="\.provider\.pact\." --forceExit
        env:
          GIT_COMMIT: ${{ github.sha }}
          GIT_BRANCH: ${{ github.ref_name }}
          PUBLISH_VERIFICATION_RESULTS: 'true'

  # ── Deploy gate ────────────────────────────────────────────────────────────
  can-i-deploy:
    name: can-i-deploy check
    runs-on: ubuntu-latest
    needs: [consumer-pact]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g @pact-foundation/pact-cli
      - name: Check if safe to deploy to production
        run: |
          pact-broker can-i-deploy \
            --pacticipant OrderService \
            --version "${{ github.sha }}" \
            --to-environment production \
            --broker-base-url "$PACT_BROKER_URL" \
            --broker-token "$PACT_BROKER_TOKEN" \
            --retry-while-unknown 5 \
            --retry-interval 15
```

**Key points:**
- Consumer and provider CI jobs are **independent** — they don't `needs` each other; the Pact Broker is the coupling point
- `can-i-deploy` runs only on `main` branch pushes, immediately before the deploy command
- `PUBLISH_VERIFICATION_RESULTS` is controlled via env var so local runs don't accidentally publish results
- `wait-on` ensures the test server is ready before verification starts — a common source of false failures

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| Exact value matching (no matchers) | Test fails on any dynamic value (timestamps, UUIDs) | Use `like()`, `string()`, `integer()`, `regex()` matchers |
| Consumer tests cover every endpoint field | Over-specified contracts break on irrelevant provider changes | Only assert fields the consumer actually uses |
| Pact tests replace integration tests entirely | CDC tests contract shape, not behaviour — bugs in business logic go undetected | Use CDC + a thin integration smoke test suite |
| Not publishing verification results | `can-i-deploy` has no data to act on | Always publish results in CI with `publishVerificationResult: true` |
| Mismatched provider state strings | State handlers never run → provider can't reproduce test conditions | Treat provider state strings as a shared API contract; define them in a shared constants file |
| Running CDC tests in production-like environments | CDC is a unit-level test — spinning up full stacks defeats the purpose | Run consumer tests against the Pact mock; run provider verification against a minimal real server |
| Placing `can-i-deploy` in the wrong pipeline stage | Checking too early (before verification completes) yields "unknown" and blocks valid deploys | Gate exactly at the deploy step, after provider verification pipeline has had time to publish results |
| Not enabling WIP/pending pacts | New consumer interactions block provider CI before the provider is ready to implement them | Set `enablePending: true` and `includeWipPactsSince` in `VerifierV3` during initial rollout |
| Using Pact for third-party / external APIs | You cannot control the provider verification pipeline for external APIs | Use OpenAPI validation or API snapshot testing for third-party APIs |

---

## Real-World Gotchas [community]

1. **[community] Provider state setup is the hardest part.** State handlers require the provider team to maintain database seeders for every state string the consumer defines. When a consumer renames a state string, the handler silently stops running. Solution: lint state strings at publish time with a shared constants file.

2. **[community] Pact Broker webhook latency breaks `can-i-deploy`.** If a provider publishes verification results asynchronously, `can-i-deploy` runs before results exist and fails with "unknown." Use `--retry-while-unknown 5 --retry-interval 10` in CI.

3. **[community] Date/time matchers are subtly wrong in Pact V2.** `term()` with a date regex matches format but not validity. In Pact V3 use `timestamp('yyyy-MM-dd', '2024-01-01')` from `MatchersV3`.

4. **[community] Pending pacts cause false CI failures.** When a consumer publishes a new pact for a provider that hasn't verified it yet, the provider CI fails. Enable the "pending pacts" feature in Pact V3 to mark unverified pacts as warnings rather than failures.

5. **[community] `can-i-deploy` gates deployment, not branch merging.** Teams sometimes place the check in the wrong pipeline stage. The correct position is immediately before the deploy command, using the exact version being deployed (Git SHA).

6. **[community] Consumer team owns the pact, but provider team sets the timeline.** A classic adoption pain point: consumer publishes a pact for a new endpoint the provider hasn't built yet. Without the "work in progress" (WIP) pacts feature, the provider's CI breaks. Enable WIP pacts in `VerifierV3` options (`enablePending: true, includeWipPactsSince: '2024-01-01'`) so that new unverified pacts are advisory-only until the provider team accepts them.

7. **[community] Pact does not validate auth.** By design, Pact ignores `Authorization` headers in matching. This is correct behaviour — auth tokens are dynamic. But teams assume CDC tests cover auth flows. They don't. Keep auth integration tests separate.

8. **[community] Large pact files slow down CI significantly.** Each consumer interaction generates a JSON object in the pact file. When a single consumer has 50+ interactions with a provider, verification can take 5+ minutes as the verifier replays each one sequentially. Solution: group interactions logically across multiple pact files by feature domain, not by endpoint.

9. **[community] Version tagging strategy matters more than most teams expect.** Early adopters tag consumer versions with branch names (`main`, `feature-x`). This works until branches diverge for weeks. Use Git SHA as the version and Git branch as the branch tag — the Pact Broker's `deployedOrReleased` selector then correctly identifies what's actually live.

10. **[community] Contract tests are not a substitute for a schema registry.** In event-driven architectures (Kafka, SNS/SQS), Pact supports message pacts, but many teams overlook this and only test HTTP. If your services exchange async messages, apply CDC to message payloads with `MessageConsumerPact` — otherwise a broken event schema will only surface when consumers process live messages.

---

## Tradeoffs & Alternatives

### CDC vs Integration Tests

| Dimension | CDC (Pact) | Integration Tests |
|---|---|---|
| Speed | Fast (mock server, unit-level) | Slow (real services, network) |
| Isolation | Full — consumer and provider test independently | Partial — both must run simultaneously |
| What it catches | Contract shape mismatches, missing fields, wrong status codes | Business logic bugs, database side-effects, auth flows |
| Maintenance | Provider state handlers require ongoing upkeep | Environment management is complex |
| Feedback loop | Minutes | 10–60 minutes |
| Recommended layer | Replaces schema-level integration tests | Retain a thin smoke test suite |

### Pact Broker vs PactFlow

| | Pact Broker (OSS) | PactFlow (SaaS/paid) |
|---|---|---|
| Cost | Free, self-hosted | Paid, managed |
| Bi-directional contracts | No | Yes (OpenAPI + Pact combined) |
| Team management | Manual | Built-in |
| Webhooks | Basic | Advanced |
| Best for | Small teams, internal tooling | Enterprises, large consumer networks |

### Adoption Costs

- **Initial setup**: 2–4 days for first consumer+provider pair including Broker setup
- **Ongoing**: ~30 min per new interaction; provider state handler maintenance is the primary recurring cost
- **Org change**: Requires consumer and provider teams to coordinate on state strings — needs a small process (shared constants repo or Confluence contract page)
- **ROI threshold**: Typically positive after ~3 independent consumer-provider pairs or after the first production incident caught by `can-i-deploy`

### Recommended Adoption Path

1. **Start with one consumer/provider pair** that has a history of breaking in integration tests. This provides immediate ROI evidence and teaches the team the mechanics before scaling.
2. **Self-host Pact Broker first** (Docker image available). Migrate to PactFlow only if team management or bi-directional contracts become necessary.
3. **Add `can-i-deploy` to the deploy pipeline before provider verification** — the gate is the value delivery. Don't wait until the full test suite is written.
4. **Add message pacts only after HTTP pacts are stable** — async contracts have higher state-handler complexity and are best tackled with the team already familiar with the workflow.
5. **Adopt WIP/pending pacts from day 1** to avoid blocking provider CI when consumers publish new interactions ahead of provider implementation.

### Bi-Directional Contract Testing (PactFlow)

PactFlow's bi-directional contract testing allows providers to upload an OpenAPI spec and consumers to upload a Pact file; PactFlow performs automated cross-validation without running any code. This is useful when:
- The provider already has a well-maintained OpenAPI spec
- Standing up a full Pact provider verification environment is impractical (e.g., third-party APIs)
- The team wants schema-level + consumer-specificity without provider code changes

The tradeoff: bi-directional contracts don't run real code, so they cannot catch bugs in business logic or provider state transitions — only structural mismatches.

---

## Key Resources

### Array Matchers in Practice (JavaScript)

```javascript
// catalog-search.consumer.pact.spec.js
// Demonstrates eachLike, atLeastOneLike, and arrayContaining matchers
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { CatalogClient } from '../src/catalog-client.js';

const { eachLike, atLeastOneLike, arrayContaining, string, integer, like } = MatchersV3;

const provider = new PactV3({
  consumer: 'SearchService',
  provider: 'CatalogService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8083,
  logLevel: 'warn',
});

describe('SearchService → CatalogService contract (array matchers)', () => {
  it('returns a paginated product list', async () => {
    await provider
      .given('catalog has at least 2 active products')
      .uponReceiving('a search for active products')
      .withRequest({
        method: 'GET',
        path: '/catalog/search',
        query: { status: 'active' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          // eachLike: array with ≥1 item, each matching this shape
          items: eachLike({
            id: string('PROD-001'),
            name: like('Widget A'),
            price: like(9.99),
            tags: eachLike('featured'), // nested: each tag is a string
          }),
          // atLeastOneLike: array with a minimum count enforced
          featured: atLeastOneLike({ id: string('PROD-001'), name: like('Widget A') }, 1),
          // arrayContaining: response array must include items matching these shapes
          // (order-independent, may contain additional items)
          categories: arrayContaining([string('electronics'), string('widgets')]),
          total: integer(42),
          page: integer(1),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new CatalogClient(mockServer.url);
        const result = await client.search({ status: 'active' });
        expect(result.items.length).toBeGreaterThanOrEqual(1);
        expect(result.items[0]).toHaveProperty('id');
        expect(result.items[0]).toHaveProperty('price');
        expect(result.total).toBeGreaterThan(0);
      });
  });
});
```

**When to use each matcher:**
- `eachLike(shape)` — you need the array to have at least one element matching the shape; the actual count doesn't matter to the consumer
- `atLeastOneLike(shape, min)` — same as `eachLike` but enforces a minimum element count; use when the consumer's logic requires at least N items (e.g., "top 3 recommendations")
- `arrayContaining([...])` — the response array must include items matching the given shapes, but may contain more; use when the consumer only cares about a subset of a fixed-value list (e.g., required permission names, mandatory enum values)

**Common trap:** using `eachLike` on a fixed-size array like a tuple (e.g., coordinates `[lat, lng]`). `eachLike` allows any count, so the contract won't catch a provider changing `[lat, lng]` to `[lat]`. For fixed-length arrays, use `[like(0.0), like(0.0)]` directly.

---

### MatchersV3 Quick Reference

| Matcher | Use Case | Example |
|---|---|---|
| `like(value)` | Type-match, any value of same type | `like('some-string')` |
| `string(value)` | Exact type: string | `string('ABC-123')` |
| `integer(value)` | Exact type: integer | `integer(10)` |
| `decimal(value)` | Exact type: decimal/float | `decimal(9.99)` |
| `boolean(value)` | Exact type: boolean | `boolean(true)` |
| `regex(pattern, value)` | Regex pattern match | `regex(/^ORD-\d+$/, 'ORD-001')` |
| `uuid(value)` | UUID v4 format | `uuid('some-uuid')` |
| `timestamp(format, value)` | Datetime with explicit format | `timestamp('yyyy-MM-dd', '2024-01-01')` |
| `eachLike(value)` | Array with ≥1 item matching shape | `eachLike({ id: integer(1) })` |
| `atLeastOneLike(value, min)` | Array with minimum count | `atLeastOneLike({ id: integer(1) }, 2)` |
| `arrayContaining([...])` | Array contains these items (subset) | `arrayContaining([string('a')])` |
| `fromProviderState(expr, value)` | Value injected from provider state | `fromProviderState('${orderId}', 'ORD-001')` |

`fromProviderState` is especially useful for dynamic IDs — the provider state handler generates the ID and injects it into the response, so the consumer matcher references the state variable.

---

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Pact Docs | Official | https://docs.pact.io/ | Full reference for all Pact concepts |
| @pact-foundation/pact | npm | https://www.npmjs.com/package/@pact-foundation/pact | JavaScript/Node.js library |
| @pact-foundation/pact-cli | npm | https://www.npmjs.com/package/@pact-foundation/pact-cli | Pact Broker CLI for publishing and can-i-deploy |
| Pact JS GitHub | Repo | https://github.com/pact-foundation/pact-js | Examples, changelog, issue tracker |
| Pact Broker OSS | Repo | https://github.com/pact-foundation/pact_broker | Self-hosted broker (Docker: pactfoundation/pact-broker) |
| PactFlow | SaaS | https://pactflow.io/ | Managed Pact Broker with bi-directional contract support |
| Martin Fowler — Consumer-Driven Contracts | Article | https://martinfowler.com/articles/consumerDrivenContracts.html | Foundational article explaining CDC origins |
| OpenAPI Specification | Spec | https://spec.openapis.org/oas/latest.html | For the lighter schema-validation alternative |
| buf — Protobuf breaking change detection | Docs | https://buf.build/docs/breaking/ | gRPC/Protobuf CDC alternative |
