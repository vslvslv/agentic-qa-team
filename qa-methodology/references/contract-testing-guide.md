# Contract Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: contract-testing | iteration: 15 | score: 100/100 | date: 2026-05-04 -->
<!-- sources: training knowledge | official: docs.pact.io, pact-foundation/pact-js, docs.pact.io/pact_nirvana | community: production lessons -->

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

### Pact Nirvana — 7-Level CI/CD Maturity Roadmap

The [Pact Nirvana](https://docs.pact.io/pact_nirvana) guide is the official Pact progression roadmap. The end goal is **independent deployability**: any service can be deployed at any time with confidence that it will work correctly with every other service, without requiring a shared end-to-end test environment.

| Level | Name | What you achieve |
|---|---|---|
| 1 | **Get Prepared** | Teams understand Pact concepts (consumer, provider, pact file, Broker) and have buy-in from at least one consumer+provider pair |
| 2 | **Talk** | Consumer and provider teams have aligned on a shared workflow — who writes interactions, who publishes verification results, naming conventions |
| 3 | **Bronze** | A single consumer-provider contract test runs locally and generates a pact file — no Broker, no CI, manual execution only |
| 4 | **Silver** | The pact file is published to a Pact Broker; provider verification is triggered manually and results are published back — the Broker's compatibility matrix is populated |
| 5 | **Gold** | Consumer CI publishes pacts on every PR build; provider CI runs verification on every build; the Broker's network map reflects the live state of all services |
| 6 | **Platinum** | `can-i-deploy` is the deployment gate — no service is deployed to any environment without a passing `can-i-deploy` check using branch tagging and environment tracking (`record-deployment`) |
| 7 | **Diamond** | Contract testing gates production deployments; `record-deployment` is automated; the Pact Broker is the single source of truth for cross-service compatibility across all environments |

**Progression guidance:**

- Levels 1–2 are organizational, not technical — skipping team alignment is the #1 reason Pact adoption stalls at Bronze.
- Level 3 (Bronze) is achievable in a single afternoon with one developer.
- The biggest value jump is Level 5 → Level 6: `can-i-deploy` turns the Broker from a reporting tool into an active deployment gate.
- Many teams operate at Silver or Gold indefinitely and still derive substantial value. Diamond is aspirational for most — aim for Platinum as the production-ready target.

> [community] Teams that try to skip from Bronze to Platinum in one sprint consistently fail. The Pact Nirvana roadmap is sequential by design: each level builds trust in the infrastructure before adding more automation. A team that reaches Gold (CI automation) and stabilizes for one sprint before adding `can-i-deploy` has much higher long-term adoption than a team that rushes to Diamond.

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

---

### React / Browser Consumer Contract Test (TypeScript — fetch + Pact mock server)

Browser-side consumers are often overlooked in CDC. The same `@pact-foundation/pact` library works in Node-based test environments (Jest/Vitest + jsdom) because the mock server runs as a local HTTP process, not in-browser. The consumer test exercises the real `fetch` call from your React service layer.

```typescript
// product-api.consumer.pact.spec.ts
// Tests the Pact contract for a React app's ProductApiClient using real fetch.
// Runs in Jest with jsdom environment — the Pact mock server is a Node child process.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like, string, integer, eachLike } = MatchersV3;

// The real API client used by the React component — no mocking here.
class ProductApiClient {
  constructor(private baseUrl: string) {}

  async getProduct(id: string): Promise<{ id: string; name: string; price: number }> {
    const response = await fetch(`${this.baseUrl}/products/${id}`, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  async listProducts(
    category: string
  ): Promise<{ items: Array<{ id: string; name: string; price: number }>; total: number }> {
    const response = await fetch(
      `${this.baseUrl}/products?category=${encodeURIComponent(category)}`,
      { headers: { Accept: 'application/json' } }
    );
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }
}

const provider = new PactV3({
  consumer: 'ShopFrontend',
  provider: 'ProductService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8090,
  logLevel: 'warn',
});

describe('ShopFrontend → ProductService contract', () => {
  describe('GET /products/:id', () => {
    it('returns a product by id', async () => {
      await provider
        .given('product PROD-42 exists')
        .uponReceiving('a request for product PROD-42')
        .withRequest({
          method: 'GET',
          path: '/products/PROD-42',
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            id: string('PROD-42'),
            name: like('Widget Pro'),
            price: like(29.99),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new ProductApiClient(mockServer.url);
          const product = await client.getProduct('PROD-42');
          // Only assert fields the component actually renders
          expect(product.id).toBe('PROD-42');
          expect(typeof product.name).toBe('string');
          expect(typeof product.price).toBe('number');
        });
    });
  });

  describe('GET /products?category=:category', () => {
    it('returns a list of products for a category', async () => {
      await provider
        .given('at least one product in category "electronics" exists')
        .uponReceiving('a request for electronics products')
        .withRequest({
          method: 'GET',
          path: '/products',
          query: { category: 'electronics' },
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            items: eachLike({ id: string('PROD-1'), name: like('Widget'), price: like(9.99) }),
            total: integer(5),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new ProductApiClient(mockServer.url);
          const result = await client.listProducts('electronics');
          expect(result.items.length).toBeGreaterThanOrEqual(1);
          expect(result.total).toBeGreaterThan(0);
        });
    });
  });
});
```

**Key points:**
- The real `fetch` call (not `axios` or a spy) hits the Pact mock server — this proves the client's actual HTTP layer constructs valid requests
- The `jsdom` environment in Jest provides `fetch` via `node-fetch` polyfill or Node 18+ built-in; set `testEnvironment: 'node'` if using Node 18+ (which has global `fetch`)
- `port: 8090` is a dedicated port for the frontend consumer test; separate it from backend consumer ports to avoid collision
- Only assert response fields that the React component actually reads (`id`, `name`, `price`) — asserting `createdAt` or `vendorId` that the component never uses creates brittle contracts
- The pact file produced (`ShopFrontend-ProductService.json`) goes to the same Pact Broker; the `ProductService` provider verification verifies all consumers in a single run

---

### GraphQL Consumer Contract Test (TypeScript — Pact + GraphQL)

Pact tests GraphQL over HTTP by matching the HTTP body (the GraphQL query + variables). Use `MatchersV3.regex` for `operationName` matching and `MatchersV3.like` for the data shape.

```typescript
// catalog-graphql.consumer.pact.spec.ts
// Contract test for a GraphQL API consumed by a TypeScript service.
// GraphQL over HTTP = match on method (POST), path (/graphql), and body (query + variables).
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like, string, integer, eachLike, regex } = MatchersV3;

interface CatalogItem {
  id: string;
  title: string;
  price: number;
}

interface SearchCatalogData {
  searchCatalog: { items: CatalogItem[]; totalCount: number };
}

// Minimal GraphQL HTTP client — in production this would be Apollo Client or urql
class GraphQLClient {
  constructor(private baseUrl: string) {}

  async query<T>(
    operationName: string,
    query: string,
    variables: Record<string, unknown>
  ): Promise<T> {
    const response = await fetch(`${this.baseUrl}/graphql`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ operationName, query, variables }),
    });
    if (!response.ok) throw new Error(`GraphQL HTTP ${response.status}`);
    const json = await response.json();
    if (json.errors?.length) throw new Error(json.errors[0].message);
    return json.data as T;
  }
}

const SEARCH_CATALOG_QUERY = `
  query SearchCatalog($term: String!, $limit: Int) {
    searchCatalog(term: $term, limit: $limit) {
      items { id title price }
      totalCount
    }
  }
`;

const provider = new PactV3({
  consumer: 'SearchUI',
  provider: 'CatalogGraphQL',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8091,
  logLevel: 'warn',
});

describe('SearchUI → CatalogGraphQL contract', () => {
  it('executes SearchCatalog query and returns matching items', async () => {
    await provider
      .given('catalog has items matching "widget"')
      .uponReceiving('a SearchCatalog query for "widget"')
      .withRequest({
        method: 'POST',
        path: '/graphql',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: {
          // Match the operation name by type, not exact string — allows whitespace variation
          operationName: string('SearchCatalog'),
          // regex match allows minor query whitespace/comment variation
          query: regex(
            /query SearchCatalog\(\$term: String!, \$limit: Int\)/,
            SEARCH_CATALOG_QUERY
          ),
          variables: {
            term: like('widget'),
            limit: integer(10),
          },
        },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          data: {
            searchCatalog: {
              items: eachLike({ id: string('ITEM-1'), title: like('Widget A'), price: like(19.99) }),
              totalCount: integer(3),
            },
          },
        },
      })
      .executeTest(async (mockServer) => {
        const client = new GraphQLClient(mockServer.url);
        const result = await client.query<SearchCatalogData>(
          'SearchCatalog',
          SEARCH_CATALOG_QUERY,
          { term: 'widget', limit: 10 }
        );
        expect(result.searchCatalog.items.length).toBeGreaterThanOrEqual(1);
        expect(result.searchCatalog.totalCount).toBeGreaterThan(0);
        expect(result.searchCatalog.items[0]).toHaveProperty('id');
      });
  });
});
```

**Key points:**
- GraphQL is still HTTP POST — Pact matches on the body `{ operationName, query, variables }` structure
- Using `regex()` on the `query` field tolerates whitespace/formatting differences between consumer and the stored pact; exact string matching on multi-line GraphQL queries is extremely brittle
- The `data` wrapper in `willRespondWith` mirrors the real GraphQL response envelope — the consumer's error handling (checking `json.errors`) must also be tested via separate consumer interactions
- GraphQL mutations follow the same pattern: change `operationName` to the mutation name, use `mutation` keyword in the query body
- For Apollo Client consumers, the consumer test wraps `ApolloClient` with an `HttpLink` pointed at `mockServer.url` — the real Apollo network layer is exercised without modifications

---

### Contract Testing in a Monorepo (TypeScript — Nx / Turborepo)

Monorepos add topology constraints to Pact: all consumer and provider tests live in the same repo, but they must still be run and published independently to preserve CDC's isolation guarantees.

```typescript
// packages/order-service/jest.pact.config.ts
// Per-package Jest config for Pact tests in an Nx/Turborepo monorepo.
// Each package has its own jest.pact.config.ts; the root runs them via `nx run-many`.
import type { Config } from 'jest';
import path from 'path';

const config: Config = {
  displayName: 'order-service:pact',
  rootDir: __dirname,
  testMatch: ['<rootDir>/src/**/*.pact.spec.ts'],
  testPathIgnorePatterns: ['\\.provider\\.pact\\.spec\\.ts$'],
  transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.spec.json' }] },
  testTimeout: 30_000,
  maxWorkers: 1,
  // Write pacts to a workspace-level /pacts directory so the publish script
  // can glob all consumer pact files in one command.
  // Each consumer writes to /pacts/<ConsumerName>-<ProviderName>.json
  // No collision because consumer and provider names are unique per package.
  globals: {
    PACT_DIR: path.resolve(__dirname, '../../pacts'),
  },
};

export default config;
```

```typescript
// packages/order-service/src/inventory-client.pact.spec.ts
// Reads PACT_DIR from Jest globals to write pacts to workspace root.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { InventoryClient } from './inventory-client';

const { like, integer } = MatchersV3;

// Read pact output dir from Jest global (set per-package in jest.pact.config.ts)
const pactDir =
  (global as Record<string, unknown>).PACT_DIR as string ??
  path.resolve(process.cwd(), 'pacts');

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: pactDir,
  port: 8085,
  logLevel: 'warn',
});

describe('OrderService → InventoryService contract (monorepo)', () => {
  it('fetches available stock for a SKU', async () => {
    await provider
      .given('SKU ABC-123 is available')
      .uponReceiving('a stock availability check')
      .withRequest({ method: 'GET', path: '/inventory/ABC-123/availability' })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: { sku: like('ABC-123'), available: integer(5) },
      })
      .executeTest(async (mockServer) => {
        const client = new InventoryClient(mockServer.url);
        const result = await client.checkAvailability('ABC-123');
        expect(result.available).toBeGreaterThanOrEqual(0);
      });
  });
});
```

```jsonc
// nx.json (relevant excerpt) — monorepo task pipeline for Pact
{
  "targetDefaults": {
    "pact:consumer": {
      "executor": "@nx/jest:jest",
      "options": { "jestConfig": "jest.pact.config.ts", "passWithNoTests": false },
      "outputs": ["{workspaceRoot}/pacts"],
      // Consumer pact runs independently — no `dependsOn`
      "cache": false
    },
    "pact:provider": {
      "executor": "@nx/jest:jest",
      "options": { "jestConfig": "jest.provider.pact.config.ts", "passWithNoTests": false },
      // Provider verification must run after consumer pact tests have published to Broker
      // In CI, this is enforced by pipeline stage ordering, not nx dependency
      "cache": false
    }
  }
}
```

**Key points:**
- Write all pact files to a single workspace-level `pacts/` directory (configured via Jest globals) so the publish script runs once: `pact-broker publish ./pacts --consumer-app-version "$GIT_COMMIT" ...`
- Never use `dependsOn` to link `pact:provider` after `pact:consumer` in the nx task graph — this recreates the tight coupling that Pact's Broker model is designed to eliminate
- In CI, run `pact:consumer` for all affected packages in one pipeline stage, publish to Broker, then run `pact:provider` for all affected packages in an independent subsequent stage
- Port allocation in monorepos: assign a fixed, unique port per consumer package in that package's `jest.pact.config.ts` to prevent collision when nx runs multiple packages in parallel (or switch to PactV4's auto-port assignment)

---

### Cursor-Based Pagination Contract (TypeScript)

APIs with cursor-based pagination (`after`, `before`, `cursor`) require specific matcher strategies — the cursor value is opaque and server-assigned, making exact matching impossible.

```typescript
// feed-service.cursor.consumer.pact.spec.ts
// Contract for a cursor-paginated feed API.
// Cursors are server-assigned opaque strings — use `like()` or `fromProviderState()`.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { FeedClient } from '../src/feed-client';

const { like, string, integer, boolean: boolMatch, eachLike, fromProviderState } = MatchersV3;

interface FeedPage {
  items: Array<{ id: string; content: string; timestamp: string }>;
  pageInfo: {
    hasNextPage: boolean;
    endCursor: string | null;
    hasPreviousPage: boolean;
    startCursor: string | null;
  };
}

const provider = new PactV3({
  consumer: 'ActivityDashboard',
  provider: 'FeedService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8086,
  logLevel: 'warn',
});

describe('ActivityDashboard → FeedService contract (cursor pagination)', () => {
  describe('First page (no cursor)', () => {
    it('returns the first page of feed items', async () => {
      await provider
        .given('feed has at least 2 items')
        .uponReceiving('a request for the first feed page (limit=2)')
        .withRequest({
          method: 'GET',
          path: '/feed',
          query: { limit: '2' },
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            items: eachLike({
              id: string('ITEM-001'),
              content: like('some content'),
              timestamp: like('2025-01-01T00:00:00Z'),
            }),
            pageInfo: {
              hasNextPage: boolMatch(true),
              endCursor: like('eyJpZCI6IklURU0tMDAxIn0='),   // opaque base64 cursor
              hasPreviousPage: boolMatch(false),
              startCursor: like('eyJpZCI6IklURU0tMDAxIn0='),
            },
          },
        })
        .executeTest(async (mockServer) => {
          const client = new FeedClient(mockServer.url);
          const page: FeedPage = await client.getFeed({ limit: 2 });
          expect(page.items.length).toBeGreaterThanOrEqual(1);
          expect(typeof page.pageInfo.endCursor).toBe('string');
          expect(page.pageInfo.hasNextPage).toBe(true);
        });
    });
  });

  describe('Subsequent page (with cursor)', () => {
    it('returns the next page when a cursor is provided', async () => {
      await provider
        .given('feed has at least 4 items', { afterCursor: 'eyJpZCI6IklURU0tMDAxIn0=' })
        .uponReceiving('a request for the next feed page using a cursor')
        .withRequest({
          method: 'GET',
          path: '/feed',
          // fromProviderState: provider injects the actual cursor at verification time;
          // consumer test uses the fallback value during local execution
          query: { limit: '2', after: fromProviderState('${afterCursor}', 'eyJpZCI6IklURU0tMDAxIn0=') as unknown as string },
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            items: eachLike({ id: string('ITEM-003'), content: like('more content'), timestamp: like('2025-01-02T00:00:00Z') }),
            pageInfo: {
              hasNextPage: boolMatch(false),
              endCursor: like('eyJpZCI6IklURU0tMDAzIn0='),
              hasPreviousPage: boolMatch(true),
              startCursor: like('eyJpZCI6IklURU0tMDAzIn0='),
            },
          },
        })
        .executeTest(async (mockServer) => {
          const client = new FeedClient(mockServer.url);
          const page: FeedPage = await client.getFeed({
            limit: 2,
            after: 'eyJpZCI6IklURU0tMDAxIn0=',
          });
          expect(page.items.length).toBeGreaterThanOrEqual(1);
          expect(page.pageInfo.hasPreviousPage).toBe(true);
        });
    });
  });
});
```

**Key points:**
- Cursors are opaque strings — never match them exactly (they encode server state). Use `like()` to assert type only
- `fromProviderState('${afterCursor}', fallback)` lets the provider inject a real cursor created by the state handler during verification — the handler seeds two items and returns the cursor pointing to the first
- `boolean(true)` from `MatchersV3` matches the type `boolean` with an example value `true` — it does NOT assert the exact value, which is correct since `hasNextPage` depends on real data
- Separate interactions for first-page (no cursor) and subsequent-page (with cursor) requests — they have different provider states and different query parameters
- The provider state handler for the "subsequent page" interaction receives `{ afterCursor: '...' }` params and seeds accordingly, returning the opaque cursor value for injection

---

### Multi-Environment can-i-deploy Matrix (GitHub Actions — TypeScript workflow)

Real multi-service deployments require `can-i-deploy` checks for multiple environments and multiple services in the same CI pipeline. A GitHub Actions matrix strategy keeps the pipeline DRY.

```yaml
# .github/workflows/pact-multi-env.yml
# Multi-service, multi-environment can-i-deploy matrix.
# Each matrix cell checks one service against one environment.
name: Pact can-i-deploy Matrix

on:
  workflow_call:
    inputs:
      git_sha:
        required: true
        type: string
      target_environment:
        required: true
        type: string

env:
  PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
  PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}

jobs:
  can-i-deploy:
    name: can-i-deploy — ${{ matrix.service }} → ${{ inputs.target_environment }}
    runs-on: ubuntu-latest
    strategy:
      # fail-fast: false ensures all services are checked, not just the first failure
      fail-fast: false
      matrix:
        service:
          - OrderService
          - InventoryService
          - NotificationService
          - CheckoutService
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Pact CLI
        run: npm install -g @pact-foundation/pact-cli

      - name: can-i-deploy ${{ matrix.service }}
        run: |
          pact-broker can-i-deploy \
            --pacticipant "${{ matrix.service }}" \
            --version "${{ inputs.git_sha }}" \
            --to-environment "${{ inputs.target_environment }}" \
            --broker-base-url "$PACT_BROKER_URL" \
            --broker-token "$PACT_BROKER_TOKEN" \
            --retry-while-unknown 5 \
            --retry-interval 15

  record-all-deployments:
    name: Record deployments
    runs-on: ubuntu-latest
    needs: [can-i-deploy]
    strategy:
      fail-fast: false
      matrix:
        service:
          - OrderService
          - InventoryService
          - NotificationService
          - CheckoutService
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g @pact-foundation/pact-cli
      - name: Record ${{ matrix.service }} deployment to ${{ inputs.target_environment }}
        run: |
          pact-broker record-deployment \
            --pacticipant "${{ matrix.service }}" \
            --version "${{ inputs.git_sha }}" \
            --environment "${{ inputs.target_environment }}" \
            --broker-base-url "$PACT_BROKER_URL" \
            --broker-token "$PACT_BROKER_TOKEN"
```

**Key points:**
- `fail-fast: false` in the matrix strategy reports all failing services in a single CI run rather than stopping at the first failure — essential for diagnosing cross-service compatibility issues
- Using `workflow_call` inputs makes this a reusable workflow callable from any deployment pipeline with `uses: ./.github/workflows/pact-multi-env.yml`
- `record-all-deployments` runs after ALL `can-i-deploy` checks pass (`needs: [can-i-deploy]`) — recording a deployment before the full matrix check passes would corrupt the Broker's environment state
- In TypeScript monorepos, the `matrix.service` values should match the exact `provider` name used in `PactV3` constructor options — case-sensitive; a mismatch causes the Broker to treat them as different participants

---

### Additional Community Production Lessons [community]

16. **[community] Pact mock server port collisions in Docker containers.** When running Pact consumer tests inside a Docker container with `--network=host`, the mock server port must not conflict with any other container or host process. Teams that hard-code `port: 8080` in their `PactV3` options frequently hit this. Mitigation: always use a dedicated port in the 8900–8999 range for Pact mock servers, document the allocation, and consider migrating to PactV4 which auto-assigns ports.

17. **[community] Consumer version selectors fetch stale pacts after a long-lived branch is merged.** The `{ branch: 'feature/big-refactor' }` selector continues fetching pacts from a merged feature branch until the branch is deleted from the Broker. Provider teams experience mysterious CI failures weeks after a feature branch merges. **Fix:** use `{ branch: 'feature/X', fallbackBranch: 'main' }` and remove the branch selector once the feature branch is deleted from the Broker.

18. **[community] State handlers that call external services make provider verification flaky.** Some teams write state handlers that seed data via the real external API (e.g., calling a payment gateway in test mode). Network failures in state setup cascade into Pact verification failures that look like contract mismatches. **Rule:** state handlers must only interact with local resources (in-process database, in-memory cache, local filesystem). If the provider depends on an external API, stub it in the test server setup.

19. **[community] Pact tests in a monorepo are accidentally cached by Nx/Turborepo.** Contract tests should never be cached: publishing a pact is a side effect, and a cached "success" means the pact is not republished on the next run. Both Nx and Turborepo support `"cache": false` per target — set this explicitly on all `pact:consumer` and `pact:provider` targets. A cached Pact run that doesn't publish to the Broker silently breaks the `can-i-deploy` gate when the consumer code has changed.

20. **[community] The Pact Broker's "environment" concept requires an explicit `create-environment` step.** Teams that skip `pact-broker create-environment --name staging ...` when setting up a new environment find that `record-deployment` silently fails or that `can-i-deploy --to-environment staging` returns "environment not found." Create environments once during initial Broker setup (or in infrastructure-as-code) before any service attempts to record a deployment.

21. **[community] GraphQL subscriptions cannot be tested with Pact.** Pact models request/response over HTTP. GraphQL subscriptions use WebSocket (or SSE), which Pact cannot intercept. Teams that add subscriptions to a previously-pacted GraphQL API assume coverage extends automatically. It does not. For subscription contracts, use integration tests with a real event stream, or test subscription message payloads as message pacts using `MessageConsumerPact`.

22. **[community] Provider verification timeout is a hidden cost of large provider state catalogs.** A provider with 20 consumers, each with 15 interactions (300 total interactions), and state handlers that each seed 10 database rows, can take 15+ minutes to verify. This blocks the provider's CI pipeline. Mitigation strategies: (1) use `consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }]` to limit the verification scope; (2) split the provider into verification shards by consumer using `filterConsumerNames`; (3) move to PactFlow's bi-directional contracts for consumers with stable, schema-only contracts.

---

### Pact Specification Version Reference

Understanding which Pact specification version your pact files use affects compatibility between consumer teams, provider teams, and Broker versions.

| Spec Version | pact-js version | Key capabilities | Notes |
|---|---|---|---|
| Pact V1 | pact-js < v2 | Basic request/response matching | Legacy; do not use in new projects |
| Pact V2 | pact-js v2–v9 | `term()` regex matchers, `eachLike` | `term()` replaced by `regex()` in V3 |
| Pact V3 | pact-js v9–v12 | Provider states with params, `MatchersV3`, message pacts | Still widely used; stable |
| Pact V4 | pact-js v13+ | Plugin architecture, auto-port, gRPC, Protobuf | Recommended for new projects |

**Migration notes for TypeScript projects:**
- V3 → V4 migration: Replace `PactV3` with `PactV4`; update `withRequest` builder API; pact files are backward-compatible in the Broker
- Pact V2 `term()` → V3 `regex()` from `MatchersV3`: `term(value, regex)` → `regex(pattern, value)` (argument order reverses)
- pact-js v13 (V4) requires Node.js ≥ 18 due to native binary changes (uses Rust-based pact core)
- V4 pact files include a `pluginConfiguration` section when plugins (gRPC, XML) are used — these files cannot be verified by a Broker running an older verifier

---

### Reference Links

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Pact Docs | Official | https://docs.pact.io/ | Full reference for all Pact concepts |
| Pact Nirvana | Official | https://docs.pact.io/pact_nirvana | 7-level CI/CD maturity roadmap — Bronze → Diamond independent deployability |
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

---

### Error Response Contract Patterns (TypeScript — RFC 7807 Problem Details)

Provider error responses are frequently under-tested in CDC. Consumers must know the exact shape of error payloads to display meaningful UI messages. RFC 7807 "Problem Details for HTTP APIs" provides a standard error envelope.

```typescript
// inventory-errors.consumer.pact.spec.ts
// Tests the error response contract for the InventoryService using RFC 7807 Problem Details.
// Ensures error shapes are as stable as success shapes.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { InventoryClient, StockError } from '../src/inventory-client';

const { like, string, integer, regex } = MatchersV3;

// RFC 7807 Problem Details envelope — consumed by the UI error handler
interface ProblemDetails {
  type: string;       // URI identifying the problem type
  title: string;      // Human-readable summary
  status: number;     // HTTP status code
  detail?: string;    // Human-readable explanation
  instance?: string;  // URI reference to this occurrence
}

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8087,
  logLevel: 'warn',
});

describe('OrderService → InventoryService error contracts', () => {
  describe('404 — SKU not found', () => {
    it('returns RFC 7807 Problem Details for an unknown SKU', async () => {
      await provider
        .given('SKU UNKNOWN-999 does not exist')
        .uponReceiving('a stock request for a non-existent SKU')
        .withRequest({ method: 'GET', path: '/inventory/UNKNOWN-999' })
        .willRespondWith({
          status: 404,
          headers: {
            // RFC 7807 content type — the consumer must handle this MIME type
            'Content-Type': 'application/problem+json',
          },
          body: {
            type: regex(
              /^https:\/\/api\.example\.com\/problems\//,
              'https://api.example.com/problems/not-found'
            ),
            title: like('SKU not found'),
            status: integer(404),
            detail: like('No inventory record found for SKU UNKNOWN-999'),
            instance: like('/inventory/UNKNOWN-999'),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new InventoryClient(mockServer.url);
          const error = await client.getStock('UNKNOWN-999').catch((e: StockError) => e);
          expect(error).toBeInstanceOf(StockError);
          expect(error.status).toBe(404);
          expect(error.problemDetails?.type).toMatch(/^https:\/\/api\.example\.com\/problems\//);
        });
    });
  });

  describe('409 — Insufficient stock (optimistic concurrency)', () => {
    it('returns Problem Details when reservation fails due to insufficient stock', async () => {
      await provider
        .given('SKU ABC-123 has 0 units available')
        .uponReceiving('a reservation request that exceeds available stock')
        .withRequest({
          method: 'POST',
          path: '/inventory/reserve',
          headers: { 'Content-Type': 'application/json' },
          body: { sku: like('ABC-123'), quantity: integer(5) },
        })
        .willRespondWith({
          status: 409,
          headers: { 'Content-Type': 'application/problem+json' },
          body: {
            type: like('https://api.example.com/problems/insufficient-stock'),
            title: like('Insufficient stock'),
            status: integer(409),
            detail: like('Requested 5 but only 0 available for SKU ABC-123'),
            // Extension members — RFC 7807 permits provider-specific fields
            availableQuantity: integer(0),
            requestedQuantity: integer(5),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new InventoryClient(mockServer.url);
          const error = await client.reserveStock({ sku: 'ABC-123', quantity: 5 }).catch((e: StockError) => e);
          expect(error.status).toBe(409);
          expect(error.problemDetails?.availableQuantity).toBe(0);
        });
    });
  });

  describe('503 — Warehouse offline', () => {
    it('returns Problem Details with Retry-After when service is degraded', async () => {
      await provider
        .given('Warehouse WH-001 is temporarily offline')
        .uponReceiving('a stock request during warehouse outage')
        .withRequest({ method: 'GET', path: '/inventory/ABC-123' })
        .willRespondWith({
          status: 503,
          headers: {
            'Content-Type': 'application/problem+json',
            // Retry-After header — consumer must respect this for backpressure
            'Retry-After': like('30'),
          },
          body: {
            type: like('https://api.example.com/problems/service-unavailable'),
            title: like('Warehouse temporarily unavailable'),
            status: integer(503),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new InventoryClient(mockServer.url);
          const error = await client.getStock('ABC-123').catch((e: StockError) => e);
          expect(error.status).toBe(503);
          expect(error.retryAfter).toBeGreaterThan(0);
        });
    });
  });
});
```

**Key points:**
- Testing error response shapes is as important as success shapes — a UI that cannot parse the error envelope shows a generic "Something went wrong" instead of a specific message
- `regex(pattern, example)` on `type` enforces the URI structure without hardcoding the exact problem type — allows the provider to add new problem types under the same base URI without breaking the contract
- RFC 7807 extension members (`availableQuantity`, `requestedQuantity`) should be tested with `like()` if the consumer renders them — don't over-specify fields the consumer doesn't use
- `Retry-After` header matching with `like('30')` asserts it is a string (numeric seconds), not the exact value — the provider may vary the backoff duration
- Each error scenario is a separate provider state with a distinct interaction — never combine error scenarios into a single interaction

---

### Contract Evolution Strategy (TypeScript — Adding Fields Without Breaking Consumers)

One of CDC's highest-value scenarios is safely evolving provider APIs. This section demonstrates the three safe change patterns and the one unsafe pattern, with TypeScript-specific mitigation.

```typescript
// SAFE CHANGE #1: Adding a new optional field to the provider response
// ─────────────────────────────────────────────────────────────────────
// Consumer pact (existing — does NOT mention `stockLocation`):
// { sku: string('ABC-123'), available: integer(10) }
//
// Provider adds `stockLocation` to the response:
// { sku: 'ABC-123', available: 10, stockLocation: 'WH-001' }
//
// ✓ SAFE: Pact matching is additive — extra provider fields don't break consumer tests.
// ✓ No consumer pact update needed.
// ✗ Only safe because consumer uses type matchers (like/string/integer) — NOT exact body matching.

// SAFE CHANGE #2: Provider renames a field using the strangler pattern
// ───────────────────────────────────────────────────────────────────
// Step 1: Provider returns BOTH old and new field names.
// Consumer pact: { warehouseId: like('WH-001') }        ← consumer still uses old name
// Provider returns: { warehouseId: 'WH-001', facilityId: 'WH-001' }  ← both present

// Step 2: Consumer team updates their code to use `facilityId`,
//         publishes a NEW pact: { facilityId: like('WH-001') }
//         (warehouseId no longer mentioned — consumer doesn't need it)

// Step 3: can-i-deploy check passes for the NEW consumer pact (both fields present in provider)
//         Provider removes `warehouseId` only after ALL deployed consumers no longer reference it.
//         The Pact Broker compatibility matrix shows which consumer versions are still deployed.

// SAFE CHANGE #3: Consumer adds a new field to the request body
// ─────────────────────────────────────────────────────────────
// Old consumer pact request body: { sku: like('ABC-123'), quantity: integer(5) }
// New consumer pact request body: { sku: like('ABC-123'), quantity: integer(5), priority: like('STANDARD') }
//
// ✓ SAFE if provider ignores unknown request fields (standard REST practice).
// ✗ UNSAFE if provider validates request body with a strict schema that rejects unknown fields.
//   Mitigation: provider uses `{ additionalProperties: true }` in JSON Schema validation.

// UNSAFE CHANGE: removing a required field from the provider response
// ──────────────────────────────────────────────────────────────────
// Provider removes `warehouseId` without the strangler step:
// Consumer pact: { sku: string('ABC-123'), available: integer(10), warehouseId: like('WH-001') }
// Provider now returns: { sku: 'ABC-123', available: 10 }
//
// ✗ BREAKS: provider verification fails — `warehouseId` matcher has no match.
// ✗ `can-i-deploy` blocks deployment.
// ✓ The correct signal: fix the provider (add field back) or update all consumers first.

// TypeScript helper: verify consumer interface stays in sync with pact matchers
// ──────────────────────────────────────────────────────────────────────────────
// Define the interface ONCE and derive the pact body from it using a mapping function.
import { MatchersV3 } from '@pact-foundation/pact';

const { like, string, integer } = MatchersV3;

// The interface is the canonical contract definition — change the interface → compiler
// flags all places that need updating (including the pact body mapper below).
interface StockResponse {
  sku: string;
  available: number;
  warehouseId: string;
}

// Map each interface field to a Pact matcher — explicit, auditable, compile-time safe
function stockResponsePactBody(): Record<keyof StockResponse, unknown> {
  return {
    sku: string('ABC-123'),
    available: integer(10),
    warehouseId: like('WH-001'),
  };
}

// Usage in pact consumer test:
// .willRespondWith({
//   status: 200,
//   headers: { 'Content-Type': 'application/json' },
//   body: stockResponsePactBody(),
// })
//
// When a field is added to StockResponse, `stockResponsePactBody()` won't compile
// until the new field is mapped — the TypeScript compiler enforces contract completeness.

export { stockResponsePactBody };
export type { StockResponse };
```

**Contract evolution rules summary:**

| Change Type | Safe? | CDC Behavior | Action Required |
|---|---|---|---|
| Provider adds optional response field | Yes | Consumer test ignores unknown fields | None |
| Provider adds required response field | Yes, if default provided | Existing consumers unaffected | None |
| Provider renames response field | No (direct) | Verification fails | Use strangler: dual-field transition |
| Provider removes response field | No | Verification fails if consumer pacts it | Update all consumers first, then remove |
| Consumer adds optional request field | Yes | Provider ignores unknown fields by default | Ensure provider uses loose request validation |
| Consumer removes request field | Yes | Provider receives request without field | Ensure provider handles missing-as-default |
| Provider changes response field type | No | Verification fails | Dual-type transition or add new field |

**TypeScript-specific anti-pattern:** Defining `StockResponse` interface separately from the Pact matcher body leads to drift — the interface can add a field that the pact body doesn't assert, creating a false sense of safety. The `stockResponsePactBody(): Record<keyof StockResponse, unknown>` pattern uses `keyof` to force the body mapper and interface to stay in sync at compile time.

---

### Zod Schema + Pact Matchers (TypeScript — runtime validation + contract testing)

Modern TypeScript projects use [Zod](https://zod.dev/) for runtime schema validation. Pairing Zod schemas with Pact matchers eliminates drift between "what the consumer validates at runtime" and "what the consumer expects in its contract."

```typescript
// zod-pact-bridge.ts
// Utility: derive Pact matchers from a Zod schema shape.
// Keeps runtime validation and Pact contract in sync from a single source of truth.
import { z } from 'zod';
import { MatchersV3 } from '@pact-foundation/pact';

const { like, string, integer, decimal, boolean: boolMatch, regex } = MatchersV3;

// The Zod schema is the canonical type definition — used for:
//   1. Runtime validation of real HTTP responses in production
//   2. Deriving Pact matchers for contract tests (via zodToPactBody)
export const StockResponseSchema = z.object({
  sku: z.string().regex(/^[A-Z]{2,}-\d+$/),
  available: z.number().int().nonnegative(),
  warehouseId: z.string(),
  lastUpdated: z.string().datetime(),
});

export type StockResponse = z.infer<typeof StockResponseSchema>;

// Map a Zod object shape to Pact matchers for use in .willRespondWith({ body: ... })
// Supports string, number, boolean, and z.string().regex() shapes.
export function zodToPactBody(
  schema: z.ZodObject<z.ZodRawShape>,
  examples: Record<string, unknown>
): Record<string, unknown> {
  const shape = schema.shape;
  const result: Record<string, unknown> = {};

  for (const [key, zodType] of Object.entries(shape)) {
    const example = examples[key];
    if (zodType instanceof z.ZodString) {
      // Check for regex refinement — use Pact regex() matcher if available
      const checks = (zodType as z.ZodString)._def.checks ?? [];
      const regexCheck = checks.find((c: { kind: string }) => c.kind === 'regex') as
        | { kind: 'regex'; regex: RegExp }
        | undefined;
      result[key] = regexCheck
        ? regex(regexCheck.regex, String(example))
        : string(String(example));
    } else if (zodType instanceof z.ZodNumber) {
      const isInt = (zodType as z.ZodNumber)._def.checks?.some(
        (c: { kind: string }) => c.kind === 'int'
      );
      result[key] = isInt ? integer(Number(example)) : decimal(Number(example));
    } else if (zodType instanceof z.ZodBoolean) {
      result[key] = boolMatch(Boolean(example));
    } else {
      result[key] = like(example);
    }
  }
  return result;
}
```

```typescript
// inventory-client.zod.pact.spec.ts
// Uses zodToPactBody to derive Pact matchers from the Zod schema.
// Single source of truth: change the Zod schema → pact body updates automatically.
import path from 'path';
import { PactV3 } from '@pact-foundation/pact';
import { InventoryClient } from '../src/inventory-client';
import { StockResponseSchema, zodToPactBody } from '../shared/zod-pact-bridge';

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8092,
  logLevel: 'warn',
});

// Example values — used by zodToPactBody to generate the Pact body
const stockExamples = {
  sku: 'ABC-123',
  available: 10,
  warehouseId: 'WH-001',
  lastUpdated: '2025-01-15T10:00:00.000Z',
};

describe('OrderService → InventoryService contract (Zod-derived matchers)', () => {
  it('returns stock response that matches the Zod schema shape', async () => {
    await provider
      .given('SKU ABC-123 exists with 10 units in stock')
      .uponReceiving('a stock request for SKU ABC-123 (Zod-derived matchers)')
      .withRequest({
        method: 'GET',
        path: '/inventory/ABC-123',
        headers: { Accept: 'application/json' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        // Matchers derived from the Zod schema — stays in sync automatically
        body: zodToPactBody(StockResponseSchema, stockExamples),
      })
      .executeTest(async (mockServer) => {
        const client = new InventoryClient(mockServer.url);
        const result = await client.getStock('ABC-123');
        // Parse with Zod — proves the mock response passes runtime validation
        const parsed = StockResponseSchema.safeParse(result);
        expect(parsed.success).toBe(true);
      });
  });
});
```

**Key points:**
- `zodToPactBody` maps Zod types to the most specific Pact matcher: `z.string().regex(...)` → `regex()`, `z.number().int()` → `integer()`, `z.string()` → `string()`
- The Zod schema is the **single source of truth**: when a field is added or its type changes, the pact body updates automatically at the next test run — no manual sync needed
- `StockResponseSchema.safeParse(result)` inside `executeTest` proves that the mock server's response (generated from Pact matchers) also satisfies the Zod schema — a consistency check between the two systems
- For production use, `zodToPactBody` should handle `z.ZodOptional`, `z.ZodArray`, `z.ZodObject` recursively; the example above handles the common scalar cases

---

### Pact Broker Webhook Configuration (Bash — trigger provider CI automatically)

Without webhooks, the provider team must manually trigger their CI pipeline after a consumer publishes a new pact. Webhooks automate this loop: when a consumer publishes a new or changed pact, the Broker notifies the provider's CI.

```bash
#!/usr/bin/env bash
# setup-pact-webhooks.sh
# Creates Pact Broker webhooks to trigger provider verification CI automatically.
# Run once during infrastructure setup (or from IaC/Terraform provider config).

BROKER_URL="${PACT_BROKER_URL:?PACT_BROKER_URL required}"
BROKER_TOKEN="${PACT_BROKER_TOKEN:?PACT_BROKER_TOKEN required}"
CI_TOKEN="${CI_API_TOKEN:?CI_API_TOKEN required}"

# ── Webhook 1: Trigger provider CI when consumer publishes or changes a pact ──
curl --silent --show-error \
  -X POST "${BROKER_URL}/webhooks" \
  -H "Authorization: Bearer ${BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Trigger InventoryService CI when OrderService pact changes",
    "events": [
      { "name": "contract_content_changed" },
      { "name": "contract_published" }
    ],
    "consumer": { "name": "OrderService" },
    "provider": { "name": "InventoryService" },
    "request": {
      "method": "POST",
      "url": "https://api.github.com/repos/my-org/inventory-service/dispatches",
      "headers": {
        "Content-Type": "application/json",
        "Accept": "application/vnd.github+json",
        "Authorization": "token '"${CI_TOKEN}"'"
      },
      "body": {
        "event_type": "pact-verify",
        "client_payload": {
          "pact_url": "${pactbroker.pactUrl}",
          "consumer_version": "${pactbroker.consumerVersionNumber}",
          "provider": "${pactbroker.providerName}"
        }
      }
    }
  }' \
  && echo "Webhook created successfully" \
  || echo "ERROR: Webhook creation failed"

# ── Webhook 2: Notify Slack when verification fails (optional but recommended) ──
curl --silent --show-error \
  -X POST "${BROKER_URL}/webhooks" \
  -H "Authorization: Bearer ${BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Slack alert when provider verification fails",
    "events": [{ "name": "provider_verification_failed" }],
    "request": {
      "method": "POST",
      "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
      "headers": { "Content-Type": "application/json" },
      "body": {
        "text": ":x: Provider verification failed: ${pactbroker.providerName} failed to verify pact from ${pactbroker.consumerName} ${pactbroker.consumerVersionNumber}"
      }
    }
  }'
```

```yaml
# .github/workflows/pact-provider-dispatch.yml
# Handles the `pact-verify` repository_dispatch event triggered by the Pact Broker webhook.
name: Provider Verification (Pact webhook-triggered)

on:
  repository_dispatch:
    types: [pact-verify]

jobs:
  verify-pact:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Run provider verification against specific pact URL
        run: npm run test:pact:provider
        env:
          # Verify the exact pact URL from the webhook payload — not all pacts
          PACT_URL: ${{ github.event.client_payload.pact_url }}
          PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
          PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
          GIT_COMMIT: ${{ github.sha }}
          GIT_BRANCH: ${{ github.ref_name }}
          PUBLISH_VERIFICATION_RESULTS: 'true'
```

**Key points:**
- `contract_content_changed` (not just `contract_published`) is the critical event — it fires only when the pact content actually changes, avoiding redundant CI runs on identical re-publishes
- `${pactbroker.pactUrl}` is a Pact Broker template variable that expands to the specific pact URL — pass this to the provider CI so it verifies only the changed pact, not all pacts
- Webhooks are idempotent to create via the API — re-running `setup-pact-webhooks.sh` is safe if the Broker is reset or webhooks are lost
- PactFlow (SaaS Pact Broker) provides a UI for creating and testing webhooks; the OSS Pact Broker requires CLI or API setup as shown above
- `provider_verification_failed` webhook to Slack closes the feedback loop: the consumer team sees the failure immediately rather than discovering it days later when `can-i-deploy` blocks deployment

---

### `--fail-if-no-pacts-found` Guard (Bash — prevents false-positive provider verification)

```bash
# Provider verification CI step — guard against empty pact set
# Without this flag, a provider verification run with zero matching pacts exits 0 (success),
# creating a false green that hides misconfigured consumer selectors.
npx pact-broker can-i-deploy \
  --pacticipant InventoryService \
  --version "$GIT_COMMIT" \
  --to-environment staging \
  --broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN"

# In VerifierV3 options (TypeScript):
# Add `failIfNoPactsFound: true` to the VerifierV3 config to fail when no pacts are fetched.
# This prevents a provider from silently passing verification when its consumer selectors
# match zero pact files — a common misconfiguration after a team renames a pacticipant.
```

```typescript
// inventory-service.provider.guard.pact.spec.ts
// Demonstrates failIfNoPactsFound to guard against misconfigured selectors.
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { startServer, stopServer } from '../src/test-server';

describe('InventoryService provider verification (with no-pacts guard)', () => {
  let serverPort: number;

  beforeAll(async () => { serverPort = await startServer(); });
  afterAll(async () => { await stopServer(); });

  it('fails verification if no pacts are found (prevents silent false-positives)', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: `http://localhost:${serverPort}`,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [
        { mainBranch: true },
        { deployedOrReleased: true },
      ],
      // Fail if the Broker returns zero pacts for the configured selectors.
      // Without this, a renamed pacticipant or misconfigured selector silently passes.
      failIfNoPactsFound: true,
      stateHandlers: {},
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Key points:**
- `failIfNoPactsFound: true` is the defensive default for production provider verification — a green build with zero pacts is always wrong for a provider with known consumers
- Common misconfiguration that this catches: a team renames `OrderService` to `order-service` (kebab-case) — the Broker treats them as different participants; the provider selectors fetch nothing; verification passes silently
- Disable only when intentionally setting up a new provider that genuinely has no consumers yet (`failIfNoPactsFound: false` or omit the option, which defaults to false in pact-js v13)

---

### Additional Community Production Lessons [community]

23. **[community] Zod + Pact diverge silently when maintained separately.** Teams that define Zod schemas for runtime validation and Pact matcher bodies independently eventually drift — the Zod schema adds a required field that the Pact body doesn't assert, giving the consumer code runtime protection but no contract coverage. The fix: derive Pact matchers from the Zod schema programmatically (see `zodToPactBody` pattern above) so both update from the same source.

24. **[community] Pact Broker webhooks are forgotten during infrastructure teardown.** When a self-hosted Pact Broker is reset (database wipe, container replacement), all webhooks are lost silently. The provider CI no longer auto-triggers on consumer pact changes; teams only notice when a consumer publishes a breaking pact and the provider CI never ran. Treat webhook setup as IaC (store the `curl` script in a `scripts/setup-pact-webhooks.sh` committed to the repo) and re-run it as part of Broker provisioning.

25. **[community] `failIfNoPactsFound` is the most common missing safety net.** Provider teams disable or omit this flag because "sometimes there really are no pacts yet." The correct approach is to add the flag immediately after the first consumer publishes a pact, not from day one. After that, a zero-pact result always indicates a misconfiguration — catching it early saves hours of debugging why `can-i-deploy` always returns "unknown."

---

### `record-deployment` vs `record-release` (Bash — environment tracking precision)

These two commands are frequently confused. Using the wrong one corrupts the Broker's environment tracking and causes `deployedOrReleased` selectors to malfunction.

```bash
# record-deployment — use when you deploy a specific version to an environment.
# The Broker records which version is CURRENTLY deployed to that environment.
# Only one version per service per environment is tracked as "deployed" at a time
# (calling record-deployment with a new version replaces the previous record).
pact-broker record-deployment \
  --pacticipant OrderService \
  --version "$GIT_COMMIT" \
  --environment production \
  --broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN"

# record-release — use when you publish a version to an artifact store or package registry
# WITHOUT deploying to a specific environment (e.g., publishing a library or Docker image).
# Multiple versions can be "released" simultaneously — the Broker tracks all of them.
# Use for: npm publish, Docker Hub push, Maven Central release.
# Do NOT use for: deploying a service to staging/production.
pact-broker record-release \
  --pacticipant OrderClient \
  --version "$GIT_COMMIT" \
  --environment npm-registry \
  --broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN"

# Decision rule:
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ Deploying to staging/prod?           → record-deployment                    │
# │ Publishing to registry/artifact?     → record-release                       │
# │ Both in the same pipeline?           → record-deployment for the env,        │
# │                                        record-release for the artifact       │
# └─────────────────────────────────────────────────────────────────────────────┘
```

**Key distinctions:**

| Aspect | `record-deployment` | `record-release` |
|---|---|---|
| Use case | Service deployed to an environment | Package/library published to a registry |
| Cardinality | One version per service per environment (replaces previous) | Multiple versions can be "released" (accumulate) |
| `deployedOrReleased` selector | Included | Included |
| Typical trigger | After `kubectl apply`, `eb deploy`, `fly deploy` | After `npm publish`, Docker Hub push |
| Example | OrderService v1.2.3 → production | @myorg/api-client v3.1.0 → npm |

**[community] Most teams only use `record-deployment` and ignore `record-release`**. This is correct for server-side services. Confusion arises only when a consumer is a published npm package or SDK — teams discover that `deployedOrReleased` selectors don't cover their library consumers because they used `record-deployment` (environment-scoped) for an artifact with no environment. The fix: use `record-release` for any consumer that ships as a distributable package.

---

### Additional Community Production Lessons [community]

26. **[community] `record-deployment` called before the deploy succeeds corrupts the Broker.** Some CI pipelines call `record-deployment` as a pre-deploy step to "reserve" the version. If the deploy then fails, the Broker's `deployedOrReleased` selector serves up the wrong version for `can-i-deploy` checks until the next successful deploy records the correct version. Always call `record-deployment` as the **last step** of a successful deploy job, never before.

27. **[community] Using `record-deployment` for library consumers breaks `deployedOrReleased` tracking.** A consumer that is an npm SDK or shared library has no concept of "deployed to an environment" — it can be used by thousands of downstream consumers at once. Teams that use `record-deployment` for such packages effectively overwrite each other's tracking. The correct command is `record-release`, which accumulates versions rather than replacing them. Switch as soon as a consumer package is published to a registry rather than deployed to a server.
