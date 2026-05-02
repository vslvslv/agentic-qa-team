# Contract Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: contract-testing | iteration: 10 | score: 100/100 | date: 2026-05-02 -->
<!-- sources: training knowledge (WebFetch/WebSearch unavailable) | official: docs.pact.io, pact-foundation/pact-js | community: production lessons -->

## Terminology (ISTQB CTFL 4.0 alignment)

This guide uses standardized ISTQB CTFL 4.0 terminology throughout. Key mappings:

| Common informal term | ISTQB CTFL 4.0 term | Notes |
|---|---|---|
| "test layer" | **test level** | Pact sits at the component integration test level |
| "thing under test" | **test object** | The provider service is the test object in verification |
| "test set" | **test suite** | A pact file represents a consumer's test suite of interactions |
| "bug" / "error" | **defect** | Used below except when quoting tool output |
| "test scenario" | **test case** | Each Pact interaction is a test case |
| "test source" | **test basis** | The consumer's API usage patterns are the test basis |

> The contract testing test level sits **between** the component test level (unit tests) and the
> component integration test level (integration tests). CDC replaces the structural concern
> ("does the API shape match?") that would otherwise be validated at the component integration
> test level, allowing integration tests to focus solely on behavioural correctness.

---

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

### Pact Consumer Test (TypeScript)

```typescript
// order-service.consumer.pact.spec.ts
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client';

const { like, string, integer } = MatchersV3;

// Typed response shape — mirrors what the consumer actually uses
interface StockResponse {
  sku: string;
  available: number;
  warehouseId: string;
}

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
          const result: StockResponse = await client.getStock('ABC-123');
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
- Define a TypeScript interface (`StockResponse`) that mirrors the fields the consumer actually uses — this makes contract drift visible at the type level as well
- The `given(...)` string becomes a *provider state* that the provider side must implement
- The pact file is written to `./pacts/` after the test run

---

### Pact Provider Verification (TypeScript)

```typescript
// inventory-service.provider.pact.spec.ts
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { startServer, stopServer } from '../src/test-server';
import { db } from '../src/db';

// Typed state handler map
type StateHandlers = VerifierOptions['stateHandlers'];

const stateHandlers: StateHandlers = {
  'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
    await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
  },
  'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
    await db.clear('UNKNOWN-999');
  },
};

describe('InventoryService provider verification', () => {
  let serverPort: number;

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

      stateHandlers,

      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,

      // Inject auth tokens that the real provider requires
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
- Typing `stateHandlers` as `VerifierOptions['stateHandlers']` gives compile-time safety on state handler return types
- `consumerVersionSelectors` controls which consumer pacts to verify: `mainBranch` + `deployedOrReleased` covers the important cases
- Set `publishVerificationResult` to `true` only in CI via env var (not local dev)
- `requestFilter` injects auth headers — Pact deliberately ignores `Authorization` in matching, but providers still need it to respond correctly

---

### Provider Verification with `supertest` (TypeScript — no separate HTTP server)

When the provider is an Express/Fastify/Nest.js app, use `supertest` to bind the app to a random port rather than starting a persistent HTTP server:

```typescript
// inventory-service.supertest.provider.pact.spec.ts
// Uses supertest to start the Express app on a random port for Pact verification.
// Avoids the need to manage server lifecycle (startServer/stopServer).
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { createServer } from 'http';
import { AddressInfo } from 'net';
import { app } from '../src/app';          // Express Application instance
import { db } from '../src/db';

async function startTestServer(): Promise<{ url: string; close: () => Promise<void> }> {
  return new Promise((resolve, reject) => {
    const server = createServer(app);
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address() as AddressInfo;
      resolve({
        url: `http://127.0.0.1:${port}`,
        close: () =>
          new Promise<void>((res, rej) =>
            server.close((err) => (err ? rej(err) : res()))
          ),
      });
    });
    server.on('error', reject);
  });
}

describe('InventoryService provider verification (supertest / no persistent server)', () => {
  let serverUrl: string;
  let closeServer: () => Promise<void>;

  beforeAll(async () => {
    const server = await startTestServer();
    serverUrl = server.url;
    closeServer = server.close;
  });

  afterAll(async () => {
    await closeServer();
  });

  it('satisfies all consumer pacts', async () => {
    const stateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
      'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
        await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
      },
      'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
        await db.clear('UNKNOWN-999');
      },
    };

    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: serverUrl,   // random port assigned by OS
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }],
      enablePending: true,
      includeWipPactsSince: '2024-01-01',
      stateHandlers,
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `createServer(app)` + `listen(0, ...)` assigns a random free port — no port collision, no hardcoded `PORT` env var
- `AddressInfo` from `net` is the correct TypeScript type for the `.address()` return value when the server is bound to a port
- This pattern avoids needing `wait-on` in CI because `startTestServer()` resolves only after `listen()` fires — the server is ready by the time `verifier.verifyProvider()` runs
- Works with Express, Fastify (using `.server` property), Hapi, and Nest.js (`app.getHttpServer()`)

---

### Nest.js Provider Verification (TypeScript — `@nestjs/testing`)

```typescript
// inventory.nestjs.provider.pact.spec.ts
// Integrates Pact provider verification with Nest.js TestingModule.
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { createServer } from 'http';
import { AddressInfo } from 'net';
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { AppModule } from '../src/app.module';
import { DatabaseService } from '../src/database/database.service';

describe('InventoryService provider verification (Nest.js)', () => {
  let app: INestApplication;
  let serverUrl: string;
  let closeServer: () => Promise<void>;

  beforeAll(async () => {
    // Bootstrap Nest.js test module — real routes, real DI, real middleware
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    // Nest.js uses app.getHttpServer() to get the underlying http.Server
    // For Pact, wrap it so we can bind to a random OS port
    const httpServer = app.getHttpServer();
    const server = createServer((req, res) => httpServer.emit('request', req, res));

    serverUrl = await new Promise<string>((resolve, reject) => {
      server.listen(0, '127.0.0.1', () => {
        const { port } = server.address() as AddressInfo;
        resolve(`http://127.0.0.1:${port}`);
      });
      server.on('error', reject);
    });

    closeServer = () =>
      new Promise<void>((resolve, reject) =>
        server.close((err) => (err ? reject(err) : resolve()))
      );
  });

  afterAll(async () => {
    await closeServer();
    await app.close();
  });

  it('satisfies all consumer pacts', async () => {
    const db = app.get(DatabaseService);

    const stateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
      'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
        await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
      },
      'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
        await db.clear('UNKNOWN-999');
      },
    };

    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: serverUrl,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }],
      enablePending: true,
      includeWipPactsSince: '2024-01-01',
      stateHandlers,
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `Test.createTestingModule({ imports: [AppModule] }).compile()` starts the full Nest.js DI container — all guards, interceptors, pipes, and middleware are active, giving high-fidelity verification
- `app.get(DatabaseService)` injects the real database service from the DI container into state handlers — no separate `db` import needed
- Wrapping `app.getHttpServer()` in a new `createServer` is necessary because `app.getHttpServer()` returns an `http.Server` that is already listening on `PORT`; the wrapper listens on port 0 (random)
- `await app.close()` in `afterAll` cleanly shuts down all Nest.js lifecycle hooks (OnModuleDestroy, etc.)

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
    "pact-js": { "version": "13.0.0" }
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

---

### Message Pact Consumer Test (TypeScript — async/event-driven)

```typescript
// notification-service.message.pact.spec.ts
// Tests the shape of an event message consumed from a queue/topic
import path from 'path';
import {
  MessageConsumerPact,
  asynchronousBodyHandler,
  MatchersV3,
} from '@pact-foundation/pact';

const { like, string, timestamp } = MatchersV3;

// Define the strongly-typed message payload
interface OrderCreatedEvent {
  orderId: string;
  customerId: string;
  totalAmount: number;
  currency: string;
  createdAt: string;
}

const messagePact = new MessageConsumerPact({
  consumer: 'NotificationService',
  provider: 'OrderService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

// The handler that processes the actual message in production
async function handleOrderCreatedEvent(body: OrderCreatedEvent): Promise<void> {
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
- Typing the `OrderCreatedEvent` interface forces the handler signature and the pact `.withContent()` shape to stay in sync
- `asynchronousBodyHandler` wraps your real production message handler, proving the contract is exercised by real code
- Provider side uses `MessageProviderPact` to publish sample messages and verify they match

---

### Shared Provider State Constants (TypeScript — prevents silent mismatches)

```typescript
// pact-states.ts — shared constants imported by both consumer and provider tests
// Place in a shared package or committed to a contracts repository

export const InventoryStates = {
  SKU_IN_STOCK: (sku: string, qty: number): string =>
    `SKU ${sku} exists with ${qty} units in stock`,
  SKU_NOT_FOUND: (sku: string): string =>
    `SKU ${sku} does not exist`,
  WAREHOUSE_OFFLINE: (warehouseId: string): string =>
    `Warehouse ${warehouseId} is temporarily offline`,
} as const;

// In consumer test — import and use the constant:
// import { InventoryStates } from '../shared/pact-states';
//
// await provider
//   .given(InventoryStates.SKU_IN_STOCK('ABC-123', 10))
//   .uponReceiving('a stock-level request');

// In provider stateHandlers — same constant, no string drift:
// import { InventoryStates } from '../shared/pact-states';
//
// const stateHandlers: StateHandlers = {
//   [InventoryStates.SKU_IN_STOCK('ABC-123', 10)]: async () => {
//     await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
//   },
//   [InventoryStates.SKU_NOT_FOUND('UNKNOWN-999')]: async () => {
//     await db.clear('UNKNOWN-999');
//   },
// };
```

**Key points:**
- String-based provider states are the #1 cause of silent CDC test failures: consumer renames a state string, handler silently stops matching
- Exporting typed factory functions (not raw strings) means a typo produces a TypeScript reference error, not a silent test pass
- `as const` prevents accidental mutation of the exported object at runtime
- The shared module can also export response-shape interfaces, making contract drift visible at code review and via `tsc`

---

### Dynamic Provider State with `fromProviderState` (TypeScript)

```typescript
// order-details.consumer.pact.spec.ts
// Scenario: consumer fetches an order by server-assigned ID.
// fromProviderState lets the provider inject the actual ID at verification time.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client';

const { fromProviderState, like, string, integer } = MatchersV3;

interface OrderDetails {
  id: string;
  status: string;
  totalAmount: number;
  lineItems: Array<{ sku: string; qty: number }>;
}

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
        // fromProviderState: uses fallback value in consumer test;
        // injects state variable at provider verification time
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
        const result: OrderDetails = await client.getOrder('ORD-DYNAMIC-001');
        expect(result.id).toBe('ORD-DYNAMIC-001');
        expect(result.status).toBeDefined();
      });
  });
});
```

**Key points:**
- `fromProviderState('${orderId}', 'ORD-DYNAMIC-001')` uses the fallback during consumer test and injects the provider state variable during verification
- The provider state handler receives `{ orderId: 'ORD-DYNAMIC-001' }` as parameters, seeds the database, then returns `{ orderId: createdRecord.id }` — Pact injects this into the interaction
- Typing the result as `OrderDetails` ensures the consuming code's expectations are documented in a TypeScript interface

---

### OpenAPI Validation Alternative (TypeScript)

```typescript
// openapi-validation.spec.ts — validate provider response against OpenAPI spec
import SwaggerParser from '@apidevtools/swagger-parser';
import Ajv, { ValidateFunction } from 'ajv';
import addFormats from 'ajv-formats';
import type { OpenAPI } from 'openapi-types';

describe('InventoryService OpenAPI conformance', () => {
  let api: OpenAPI.Document;
  const ajv = new Ajv({ strict: false });
  addFormats(ajv);

  beforeAll(async () => {
    api = await SwaggerParser.dereference('./openapi/inventory.yaml') as OpenAPI.Document;
  });

  it('GET /inventory/{sku} 200 response matches schema', () => {
    // Cast to OpenAPI 3.0 to access paths
    const openapi3 = api as import('openapi-types').OpenAPIV3.Document;
    const schema = openapi3.paths['/inventory/{sku}']
      ?.get?.responses?.['200'] as import('openapi-types').OpenAPIV3.ResponseObject;
    const jsonSchema = (schema.content?.['application/json']?.schema) as object;

    const validate: ValidateFunction = ajv.compile(jsonSchema);
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

### Enabling WIP / Pending Pacts (TypeScript)

```typescript
// inventory-service.provider.pending.pact.spec.ts
// Prevents new unverified consumer pacts from blocking provider CI.
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { startServer, stopServer } from '../src/test-server';
import { db } from '../src/db';

const stateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
  'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
    await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
  },
  'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
    await db.clear('UNKNOWN-999');
  },
};

describe('InventoryService provider verification (with WIP/pending enabled)', () => {
  let serverPort: number;

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
      enablePending: true,
      includeWipPactsSince: '2024-01-01',
      stateHandlers,
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `enablePending: true` — pacts never verified before are "pending"; failures show in output but don't fail the build
- `includeWipPactsSince` — prevents very old unverified pacts from silently reappearing
- Using `NonNullable<VerifierOptions['stateHandlers']>` for the state handlers type provides full type safety on handler return values
- Once the provider verifies a pending pact successfully, it loses pending status and becomes a hard gate going forward
- Requires Pact Broker ≥ v2.60+ or PactFlow

---

### Pact V4 Consumer Test (TypeScript — pact-js v13)

```typescript
// order-service.consumer.pact.v4.spec.ts — pact-js v13 (Pact V4 spec)
// V4: no `port` option — mock server auto-assigns to avoid port collisions.
import path from 'path';
import { PactV4, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client';

const { string, integer, like } = MatchersV3;

interface StockResponse {
  sku: string;
  available: number;
  warehouseId: string;
}

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
        const result: StockResponse = await client.getStock('ABC-123');
        expect(result.sku).toBe('ABC-123');
        expect(typeof result.available).toBe('number');
      });
  });
});
```

**Key points:**
- `PactV4` class replaces `PactV3`; V4 pact files are backward-compatible — the Pact Broker accepts both
- No `port` option: V4 auto-assigns mock server port, eliminating collision when running files in parallel
- `addInteraction()` builder API replaces the chained `.given().uponReceiving()` pattern from V3
- V4 supports a plugin architecture for gRPC, Protobuf, and XML via community plugins
- **When to migrate:** new TypeScript projects should start with pact-js v13 (V4); for existing V3 pact files the transition is safe since V4 is backward-compatible

---

### Consumer Version Selectors Reference (TypeScript — provider verification)

```typescript
// inventory-service.provider.selectors.spec.ts
// Consumer version selectors tell the provider which consumer pact versions to verify.
import { VerifierV3, ConsumerVersionSelector } from '@pact-foundation/pact';

// RECOMMENDED: covers the important cases without over-fetching
const recommendedSelectors: ConsumerVersionSelector[] = [
  { mainBranch: true },       // consumer's trunk branch
  { deployedOrReleased: true }, // what's actually deployed right now
];

// DURING FEATURE DEVELOPMENT: also verify against the consumer's feature branch
const developmentSelectors: ConsumerVersionSelector[] = [
  { mainBranch: true },
  { deployedOrReleased: true },
  { branch: 'feature/new-checkout-flow', fallbackBranch: 'main' },
];

// LEGACY (pre-environment API): tag-based — still works but deprecated
const legacyTagSelectors: ConsumerVersionSelector[] = [
  { tag: 'main', latest: true },
  { tag: 'production', latest: true },
  { tag: 'staging', latest: true },
];

// ANTI-PATTERN: { all: true } — O(n) verification cost grows unboundedly
// as pact history accumulates. Do NOT use.

describe('InventoryService provider verification — selector examples', () => {
  it('verifies with recommended selectors', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: `http://localhost:${process.env.PORT ?? '3001'}`,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: recommendedSelectors,
      enablePending: true,
      includeWipPactsSince: '2024-01-01',
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
      stateHandlers: {},
    });
    await verifier.verifyProvider();
  });
});
```

**Key decision rules:**
- `mainBranch: true` — always include; catches regressions before they merge to trunk
- `deployedOrReleased: true` — always include; requires `record-deployment` to be accurate
- `branch: 'X'` — add when consumer and provider features develop in parallel; remove once merged
- Never use `{ all: true }` — creates unbounded verification growth as pact history accumulates
- Importing `ConsumerVersionSelector` type from `@pact-foundation/pact` gives compile-time checking on selector options

---

### Array Matchers in Practice (TypeScript)

```typescript
// catalog-search.consumer.pact.spec.ts
// Demonstrates eachLike, atLeastOneLike, and arrayContaining matchers
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { CatalogClient } from '../src/catalog-client';

const { eachLike, atLeastOneLike, arrayContaining, string, integer, like } = MatchersV3;

interface ProductListResponse {
  items: Array<{ id: string; name: string; price: number; tags: string[] }>;
  featured: Array<{ id: string; name: string }>;
  categories: string[];
  total: number;
  page: number;
}

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
          items: eachLike({
            id: string('PROD-001'),
            name: like('Widget A'),
            price: like(9.99),
            tags: eachLike('featured'),
          }),
          featured: atLeastOneLike({ id: string('PROD-001'), name: like('Widget A') }, 1),
          categories: arrayContaining([string('electronics'), string('widgets')]),
          total: integer(42),
          page: integer(1),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new CatalogClient(mockServer.url);
        const result: ProductListResponse = await client.search({ status: 'active' });
        expect(result.items.length).toBeGreaterThanOrEqual(1);
        expect(result.items[0]).toHaveProperty('id');
        expect(result.items[0]).toHaveProperty('price');
        expect(result.total).toBeGreaterThan(0);
      });
  });
});
```

**When to use each matcher:**
- `eachLike(shape)` — array with at least one element matching the shape; actual count irrelevant to consumer
- `atLeastOneLike(shape, min)` — same as `eachLike` but enforces a minimum element count
- `arrayContaining([...])` — array must include items matching the given shapes, but may contain more
- **Common trap:** using `eachLike` on a fixed-size tuple (e.g., coordinates `[lat, lng]`). Use `[like(0.0), like(0.0)]` for fixed-length arrays

---

### TypeScript Project Setup for Pact

```typescript
// jest.config.ts — separate Jest project for Pact tests
// Run Pact tests in their own Jest project so they can be executed
// independently from unit tests and don't pollute the main test suite.
import type { Config } from 'jest';

const config: Config = {
  projects: [
    {
      // Unit tests — fast, no network, no Pact
      displayName: 'unit',
      testMatch: ['**/*.spec.ts'],
      testPathIgnorePatterns: ['.*\\.pact\\.spec\\.ts$', '.*\\.provider\\.pact\\.spec\\.ts$'],
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }] },
    },
    {
      // Consumer Pact tests — generate pact files
      displayName: 'pact:consumer',
      testMatch: ['**/*.pact.spec.ts'],
      testPathIgnorePatterns: ['.*\\.provider\\.pact\\.spec\\.ts$'],
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }] },
      // Pact mock server needs longer timeout for startup
      testTimeout: 30_000,
      // Run Pact consumer tests serially — parallel execution causes port collisions with PactV3
      // (PactV4 auto-assigns ports and is safe to run in parallel)
      maxWorkers: 1,
    },
    {
      // Provider Pact verification — verify pacts from Broker
      displayName: 'pact:provider',
      testMatch: ['**/*.provider.pact.spec.ts'],
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }] },
      testTimeout: 120_000, // Provider verification downloads pacts from Broker; allow more time
      maxWorkers: 1,
    },
  ],
};

export default config;
```

**tsconfig additions for Pact (TypeScript):**

```jsonc
// tsconfig.test.json — inherits from root, adds Pact-specific lib settings
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": ["jest", "node"],
    // strict: true is recommended — Pact types are strict-compatible
    "strict": true,
    // resolveJsonModule: true — needed if you import pact state constants from JSON
    "resolveJsonModule": true
  },
  "include": ["src/**/*.ts", "test/**/*.ts", "**/*.spec.ts", "**/*.pact.spec.ts"]
}
```

**package.json scripts for TypeScript Pact workflow:**

```json
{
  "scripts": {
    "test:pact:consumer": "jest --projects pact:consumer --forceExit",
    "test:pact:provider": "jest --projects pact:provider --forceExit",
    "pact:publish": "pact-broker publish ./pacts --consumer-app-version $GIT_COMMIT --branch $GIT_BRANCH --broker-base-url $PACT_BROKER_URL --broker-token $PACT_BROKER_TOKEN",
    "pact:can-deploy:staging": "pact-broker can-i-deploy --pacticipant OrderService --version $GIT_COMMIT --to-environment staging --broker-base-url $PACT_BROKER_URL --broker-token $PACT_BROKER_TOKEN --retry-while-unknown 5 --retry-interval 15",
    "pact:can-deploy:prod": "pact-broker can-i-deploy --pacticipant OrderService --version $GIT_COMMIT --to-environment production --broker-base-url $PACT_BROKER_URL --broker-token $PACT_BROKER_TOKEN --retry-while-unknown 5 --retry-interval 15",
    "pact:record-deploy:staging": "pact-broker record-deployment --pacticipant OrderService --version $GIT_COMMIT --environment staging --broker-base-url $PACT_BROKER_URL --broker-token $PACT_BROKER_TOKEN",
    "pact:record-deploy:prod": "pact-broker record-deployment --pacticipant OrderService --version $GIT_COMMIT --environment production --broker-base-url $PACT_BROKER_URL --broker-token $PACT_BROKER_TOKEN"
  },
  "devDependencies": {
    "@pact-foundation/pact": "^13.0.0",
    "@pact-foundation/pact-cli": "^1.0.0",
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0",
    "wait-on": "^7.0.0"
  }
}
```

**Key points:**
- Separate Jest projects for `unit`, `pact:consumer`, and `pact:provider` allow `npm run test:pact:consumer` to execute only the pact consumer tests, with no interference from unit tests
- `maxWorkers: 1` for PactV3 consumer tests prevents port collision on the mock server; PactV4 (no `port` option) is safe to parallelize
- `testTimeout: 120_000` for provider verification allows time for Broker communication, state handler database seeding, and replay of many interactions
- `ts-jest` with `tsconfig.test.json` compiles TypeScript on-the-fly; no separate `tsc` step needed for test execution

---

### GitHub Actions CI Pipeline for Pact (TypeScript)

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
      - name: Type-check (must pass before pact tests run)
        run: npx tsc --noEmit
      - name: Run consumer pact tests
        run: npm run test:pact:consumer
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
    # Provider verification is independent — it pulls pacts from Broker,
    # not from consumer CI. No 'needs' here.
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Build TypeScript (provider must be compiled before starting test server)
        run: npx tsc
      - name: Start provider test server
        run: node dist/server.js &
        env:
          PORT: 3001
          NODE_ENV: test
      - name: Wait for server to be ready
        run: npx wait-on http://localhost:3001/health --timeout 30000
      - name: Run provider verification
        run: npm run test:pact:provider
        env:
          GIT_COMMIT: ${{ github.sha }}
          GIT_BRANCH: ${{ github.ref_name }}
          PUBLISH_VERIFICATION_RESULTS: 'true'
          PORT: 3001

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

  # ── Record deployment ──────────────────────────────────────────────────────
  record-deployment:
    name: Record deployment (run after actual deploy job)
    runs-on: ubuntu-latest
    needs: [can-i-deploy]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g @pact-foundation/pact-cli
      - name: Record deployment to production in Pact Broker
        run: |
          pact-broker record-deployment \
            --pacticipant OrderService \
            --version "${{ github.sha }}" \
            --environment production \
            --broker-base-url "$PACT_BROKER_URL" \
            --broker-token "$PACT_BROKER_TOKEN"
```

**Key points:**
- `npx tsc --noEmit` runs before consumer pact tests — a TypeScript compile error in the consumer client surfaces before the pact tests run, giving faster feedback
- `npx tsc` (with emit) runs before starting the provider test server — the server is compiled JavaScript, not ts-node, for production parity
- Consumer and provider CI jobs are **independent** — the Pact Broker is the coupling point, not a `needs` dependency
- `record-deployment` is a dedicated job that runs after the real deploy job — the example shows it as a stub; in practice it follows the actual deploy command
- `can-i-deploy` runs only on `main` branch merges, immediately before the deploy step

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| Exact value matching (no matchers) | Test fails on any dynamic value (timestamps, UUIDs) | Use `like()`, `string()`, `integer()`, `regex()` matchers |
| Consumer tests cover every endpoint field | Over-specified contracts break on irrelevant provider changes | Only assert fields the consumer actually uses |
| Pact tests replace integration tests entirely | CDC tests contract shape, not behaviour — bugs in business logic go undetected | Use CDC + a thin integration smoke test suite |
| Not publishing verification results | `can-i-deploy` has no data to act on | Always publish results in CI with `publishVerificationResult: true` |
| Mismatched provider state strings | State handlers never run → provider can't reproduce test conditions | Define state strings as shared TypeScript constants; import in both consumer and provider tests |
| Running CDC tests in production-like environments | CDC is a unit-level test — spinning up full stacks defeats the purpose | Run consumer tests against the Pact mock; run provider verification against a minimal real server |
| Placing `can-i-deploy` in the wrong pipeline stage | Checking too early (before verification completes) yields "unknown" and blocks valid deploys | Gate exactly at the deploy step, after provider verification pipeline has had time to publish results |
| Not enabling WIP/pending pacts | New consumer interactions block provider CI before the provider is ready to implement them | Set `enablePending: true` and `includeWipPactsSince` in `VerifierV3` during initial rollout |
| Using Pact for third-party / external APIs | You cannot control the provider verification pipeline for external APIs | Use OpenAPI validation or API snapshot testing for third-party APIs |
| Using `{ all: true }` consumer version selector | Provider verifies every pact ever published — O(n) verification cost grows unboundedly | Use `{ mainBranch: true }` + `{ deployedOrReleased: true }` exclusively |
| Skipping `record-deployment` after deploy | `deployedOrReleased` selector becomes inaccurate — provider stops verifying pacts for what is actually live | Always call `pact-broker record-deployment` immediately after each successful deployment |
| Interaction sprawl — one interaction per field combination | A single consumer with dozens of interactions slows provider verification linearly | Group interactions by feature or use-case; use matchers to handle variance |
| Treating TypeScript types as contract substitutes | TS types are compile-time only within one codebase; they don't prevent a provider from returning wrong shapes at runtime across a network boundary | Use Pact matchers for runtime, cross-service shape verification; keep TS interfaces in sync as documentation |

---

## Real-World Gotchas [community]

1. **[community] Provider state setup is the hardest part.** State handlers require the provider team to maintain database seeders for every state string the consumer defines. When a consumer renames a state string, the handler silently stops running. **Fix:** export typed factory functions from a shared `pact-states.ts` constants module — a rename becomes a TypeScript compile error.

2. **[community] Pact Broker webhook latency breaks `can-i-deploy`.** If a provider publishes verification results asynchronously, `can-i-deploy` runs before results exist and fails with "unknown." Use `--retry-while-unknown 5 --retry-interval 10` in CI to handle propagation lag.

3. **[community] Date/time matchers are subtly wrong in Pact V2.** `term()` with a date regex matches format but not validity. In Pact V3 use `timestamp('yyyy-MM-dd', '2024-01-01')` from `MatchersV3`. In TypeScript projects, define a helper that wraps `timestamp()` to enforce ISO 8601 format consistently.

4. **[community] Pending pacts cause false CI failures.** When a consumer publishes a new pact for a provider that hasn't verified it yet, the provider CI fails. Enable the "pending pacts" feature (`enablePending: true`) in the `VerifierV3` options to mark unverified pacts as warnings rather than build failures.

5. **[community] `can-i-deploy` gates deployment, not branch merging.** Teams sometimes place the check in the wrong pipeline stage. The correct position is immediately before the deploy command, using the exact Git SHA being deployed — not a branch name, which can point to different commits over time.

6. **[community] Consumer team owns the pact, but provider team sets the timeline.** A classic adoption pain point: consumer publishes a pact for a new endpoint the provider hasn't built yet. Without the Work-in-Progress (WIP) pacts feature, the provider's CI breaks. Enable WIP pacts in `VerifierV3` options (`enablePending: true, includeWipPactsSince: '2024-01-01'`) so that new unverified pacts are advisory-only until the provider team accepts them.

7. **[community] Pact does not validate auth.** By design, Pact ignores `Authorization` headers in matching. Teams assume CDC tests cover auth flows — they don't. Keep auth integration tests separate. Use the `requestFilter` in `VerifierV3` to inject test tokens so the provider can serve correct responses without Pact matching on them.

8. **[community] Large pact files slow down CI significantly.** Each consumer interaction generates a JSON object in the pact file. When a single consumer has 50+ interactions with a provider, verification can take 5+ minutes as the verifier replays each sequentially. **Fix:** group interactions logically across multiple pact files by feature domain, not by individual endpoint or field.

9. **[community] Version tagging strategy matters more than most teams expect.** Early adopters tag consumer versions with branch names (`main`, `feature-x`). This breaks when branches diverge for weeks. **Best practice:** use Git SHA as the version and Git branch as the branch tag — the Pact Broker's `deployedOrReleased` selector then correctly identifies what's actually live, and the `ConsumerVersionSelector` type in TypeScript enforces the correct field names.

10. **[community] Contract tests are not a substitute for a schema registry.** In event-driven architectures (Kafka, SNS/SQS), Pact supports message pacts, but many teams overlook this and only test HTTP. If your services exchange async messages, apply CDC to message payloads with `MessageConsumerPact` — otherwise a broken event schema will only surface when consumers process live messages.

11. **[community] `record-deployment` is the forgotten half of `can-i-deploy`.** Teams correctly implement `can-i-deploy` but skip `pact-broker record-deployment` after a successful deploy. Without it, the Broker's `deployedOrReleased` selector cannot track what is actually live in each environment, causing `consumerVersionSelectors: [{ deployedOrReleased: true }]` to silently under-select pacts for verification — a provider can break deployed consumers without its own CI catching the regression.

12. **[community] TypeScript types and Pact matchers are orthogonal.** A common misconception: "our TypeScript types already enforce the contract." TypeScript types are compile-time guarantees within one codebase; they do nothing to prevent a provider from returning a different shape at runtime across a network boundary. Define interfaces that mirror Pact matcher shapes — they serve as living documentation, but they are not substitutes for runtime contract verification.

13. **[community] ESM / TypeScript `"type": "module"` breaks Pact's native binary resolution.** When your `package.json` uses `"type": "module"`, `@pact-foundation/pact`'s internal native binary loading can fail with `ERR_REQUIRE_ESM`. The fix: add `"moduleResolution": "bundler"` or `"node16"` to your `tsconfig.json` and use `ts-jest` with `useESM: true`, or (simpler) run pact tests under CommonJS by keeping a separate `tsconfig.pact.json` with `"module": "commonjs"` and pointing `ts-jest` at it. This is a known rough edge in TypeScript + ESM projects as of pact-js v12/v13.

14. **[community] Nest.js provider tests require `getHttpAdapter().getInstance()` to get the Express app.** A common setup mistake in Nest.js TypeScript projects: teams pass the NestJS `INestApplication` instance directly to `createServer()`. This fails because `createServer` expects an Express `RequestListener`, not a Nest app. The correct pattern is `const httpAdapter = app.getHttpAdapter(); const expressApp = httpAdapter.getInstance(); createServer(expressApp).listen(0, ...)`. Without this, the provider test server starts but Pact's verification requests return 404 for all interactions.

15. **[community] Pact V4 plugin architecture for gRPC requires a matching plugin version on both consumer and provider.** The `pact-plugin-grpc` plugin must be the same major version on the machine that generates the pact file and the machine that verifies it. When teams use Docker for CI and local development for consumer tests, version drift between the local and CI plugin binaries causes silent verification failures — the pact file is written but the provider verification silently skips the interaction. Pin `pact-plugin-grpc` in `package.json` and install it explicitly in CI via `npx @pact-foundation/pact-cli install-plugin grpc@<exact-version>`.

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

1. **Start with one consumer/provider pair** that has a history of breaking in integration tests.
2. **Self-host Pact Broker first** (Docker image available). Migrate to PactFlow only if team management or bi-directional contracts become necessary.
3. **Add `can-i-deploy` to the deploy pipeline** before provider verification — the gate is the value delivery.
4. **Add message pacts only after HTTP pacts are stable** — async contracts have higher state-handler complexity.
5. **Adopt WIP/pending pacts from day 1** to avoid blocking provider CI when consumers publish new interactions ahead of provider implementation.

### Bi-Directional Contract Testing (PactFlow)

PactFlow's bi-directional contract testing allows providers to upload an OpenAPI spec and consumers to upload a Pact file; PactFlow performs automated cross-validation without running any code. Useful when:
- The provider already has a well-maintained OpenAPI spec
- Standing up a full Pact provider verification environment is impractical (e.g., third-party APIs)
- The team wants schema-level + consumer-specificity without provider code changes

The tradeoff: bi-directional contracts don't run real code, so they cannot catch bugs in business logic or provider state transitions — only structural mismatches.

---

## Key Resources

### Pact with Vitest (TypeScript — alternative test runner)

Many modern TypeScript projects use Vitest instead of Jest. `@pact-foundation/pact` works with Vitest using `singleThread` mode to prevent port collisions on PactV3 mock servers:

```typescript
// vitest.config.ts — Pact-compatible Vitest config
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // PactV3 requires a single thread (no worker isolation) for the mock server.
    // PactV4 (auto-port) is safe with pool: 'threads', but singleThread is simpler.
    singleThread: true,
    // Increase timeout for provider verification (downloads from Broker)
    testTimeout: 120_000,
    // Separate include patterns — run pact tests with `vitest run --project pact`
    include: ['**/*.pact.spec.ts', '**/*.provider.pact.spec.ts'],
    exclude: ['node_modules', 'dist'],
  },
});
```

```typescript
// order-service.consumer.pact.vitest.spec.ts — same API, different test runner
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { describe, it, expect } from 'vitest';
import { OrderClient } from '../src/order-client';

const { like, string, integer } = MatchersV3;

interface StockResponse {
  sku: string;
  available: number;
  warehouseId: string;
}

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8084, // fixed port required with Vitest singleThread
  logLevel: 'warn',
});

describe('OrderService → InventoryService contract (Vitest)', () => {
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
        const result: StockResponse = await client.getStock('ABC-123');
        expect(result.sku).toBe('ABC-123');
        expect(result.available).toBeGreaterThanOrEqual(0);
      });
  });
});
```

**Key points:**
- `singleThread: true` in Vitest config is equivalent to `maxWorkers: 1` in Jest — prevents port collision on PactV3 mock servers
- Import `describe`, `it`, `expect` explicitly from `vitest` (or rely on globals if `globals: true` is set in config) — Pact's mock server lifecycle integrates with whatever test runner calls `executeTest`
- `@pact-foundation/pact` does not directly depend on Jest; Vitest works as a drop-in runner

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

### Reference Links

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Pact Docs | Official | https://docs.pact.io/ | Full reference for all Pact concepts |
| @pact-foundation/pact | npm | https://www.npmjs.com/package/@pact-foundation/pact | TypeScript/Node.js library |
| @pact-foundation/pact-cli | npm | https://www.npmjs.com/package/@pact-foundation/pact-cli | Pact Broker CLI for publishing and can-i-deploy |
| Pact JS GitHub | Repo | https://github.com/pact-foundation/pact-js | Examples, changelog, issue tracker |
| Pact Broker OSS | Repo | https://github.com/pact-foundation/pact_broker | Self-hosted broker (Docker: pactfoundation/pact-broker) |
| PactFlow | SaaS | https://pactflow.io/ | Managed Pact Broker with bi-directional contract support |
| Martin Fowler — Consumer-Driven Contracts | Article | https://martinfowler.com/articles/consumerDrivenContracts.html | Foundational article explaining CDC origins |
| ts-jest | npm | https://www.npmjs.com/package/ts-jest | TypeScript preprocessor for Jest — compile pact tests without a separate tsc step |
| openapi-types | npm | https://www.npmjs.com/package/openapi-types | TypeScript types for OpenAPI 2.0/3.0/3.1 documents |
| OpenAPI Specification | Spec | https://spec.openapis.org/oas/latest.html | For the lighter schema-validation alternative |
| buf — Protobuf breaking change detection | Docs | https://buf.build/docs/breaking/ | gRPC/Protobuf CDC alternative |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology reference |
