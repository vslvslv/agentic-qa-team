# Contract Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: contract-testing | iteration: 26 | score: 100/100 | date: 2026-05-12 -->
<!-- sources: training knowledge | official: docs.pact.io, pact-foundation/pact-js, docs.pact.io/pact_nirvana, docs.pact.io/plugins (WebFetch 2026-05-07), github.com/pactflow/pact-protobuf-plugin (WebFetch 2026-05-07), github.com/pact-foundation/pact-plugins (WebFetch 2026-05-07), github.com/pact-foundation/pact-js/releases (WebFetch 2026-05-12), github.com/pact-foundation/pact-js/blob/master/docs/migrations/16.md (WebFetch 2026-05-12), docs.pact.io/pact_broker/webhooks (WebFetch 2026-05-12), pactflow.io/blog (WebFetch 2026-05-12), github.com/pact-foundation/pact-js CHANGELOG.md (WebFetch 2026-05-12), docs.pact.io/implementation_guides/javascript/docs/graphql (WebFetch 2026-05-12), docs.pact.io/consumer (WebFetch 2026-05-12), docs.pact.io/consumer/contract_tests_not_functional_tests (WebFetch 2026-05-12), github.com/pact-foundation/pact-js/issues/1713 (WebFetch 2026-05-12), github.com/pact-foundation/pact-js/issues/1748 (WebFetch 2026-05-12), docs.pact.io/consumer (WebFetch 2026-05-12 iteration 23), github.com/pact-foundation/pact-js/releases (WebFetch 2026-05-12 iteration 23), pactflow.io/blog (WebFetch 2026-05-12 iteration 23), docs.pact.io/implementation_guides/javascript/docs/matching (WebFetch 2026-05-12 iteration 24), github.com/pact-foundation/pact-js/issues (WebFetch 2026-05-12 iteration 24), docs.pact.io (WebFetch 2026-05-12 iteration 25), docs.pact.io/consumer (WebFetch 2026-05-12 iteration 25), docs.pact.io/consumer/contract_tests_not_functional_tests (WebFetch 2026-05-12 iteration 25), pactflow.io/blog (WebFetch 2026-05-12 iteration 25), github.com/pact-foundation/pact-js/issues/1600 (WebFetch 2026-05-12 iteration 25), github.com/pact-foundation/pact-js/issues (WebFetch 2026-05-12 iteration 25), docs.pact.io/implementation_guides/javascript/docs/consumer (WebFetch 2026-05-12 iteration 26), github.com/pact-foundation/pact-js/releases (WebFetch 2026-05-12 iteration 26), github.com/pact-foundation/pact-js/issues/1568 (WebFetch 2026-05-12 iteration 26), github.com/pact-foundation/pact-js/issues/1438 (WebFetch 2026-05-12 iteration 26) | community: production lessons -->
<!-- new in iteration 24: extended MatchersV3 quick reference (atMostLike, constrainedArrayLike, includes, nullValue, equal, eachKeyMatches, eachValueMatches), InterfaceToTemplate<T> TypeScript utility, constrainedArrayLike bounded-array pattern, community lessons 47-49 (executeTest single-interaction-per-call constraint, constrainedArrayLike for bounded APIs, InterfaceToTemplate drift) -->
<!-- new in iteration 26: Multipart form data / file upload contract testing pattern (multipartBody/binaryFile V4 DSL, official docs May 2026), SpecificationVersion enum for explicit spec version control, community lessons 54-57 (EADDRINUSE with provider.setup() missing finalize, Jest --watch tracing subscriber warning, multipart form data over-specification anti-pattern, SpecificationVersion enum usage) -->
<!-- new in iteration 25: The Bug Catcher Rule (formal principle for interaction inclusion), BDD-style scenario sentence pattern, V4 statusCode class matching (success/clientError/serverError), mTLS client certificate workaround for VerifierV3, ConsumerVersionSelector fallbackBranch TypeScript type gap, status code range matching feature request #1600, community lessons 50-53 (5 reasons contract testing fails, BDD-style naming prevents duplicate interactions, status code class matching avoids unnecessary provider states, mTLS/client-cert provider verification) -->
<!-- new in iteration 17: pact-js v16 breaking changes and migration guide (Node ≥20, PactV4→Pact, MatchersV3→Matchers rename, addAsynchronousInteraction, v16.3 interaction metadata), updated Pact Specification Version Reference table, community lesson 28 (v16 upgrade gotchas) -->
<!-- new in iteration 18: contract_requiring_verification_published webhook (supersedes contract_content_changed, Pact Broker 2.82.0+), pact-js v16.2 withMatchingRules for async/sync interactions, pact-js v16.4 addInteractionReference, PactFlow Drift (spec-driven provider compliance CI), updated Pact Specification Version Reference table with v16.1–v16.4, community lesson 29 (deprecated webhook event), community lesson 30 (Drift for BDCT gap) -->
<!-- new in iteration 19: addGraphQLInteraction() native V4 GraphQL DSL (pact-js v16.0.0+) replaces body-matching regex approach, PactFlow MCP Server (August 2025) section, community lessons 31 and 32 (GraphQL native DSL migration, MCP-assisted contract test generation) -->
<!-- new in iteration 20: pact-js v16.3.1 patch (content type extraction from matchers), POST/PUT/PATCH GIGO anti-pattern, UI layer testing limitations, over-specifying validation rules anti-pattern, community lessons 33–35 -->
<!-- new in iteration 21: pact-js v16.3.0 race condition bug (issue #1713, parallel Vitest load), provider verification filtering enhancement request (issue #1748), community lessons 36–37 -->
<!-- new in iteration 22: Request Precision vs Response Flexibility pattern (TypeScript) + Golden Rule, two new anti-patterns (duplicate descriptions, sensitive data in pacts), community lessons 38–41 (Content-Length hang issue #1602, stateHandlers+requestFilter bug #1434, duplicate uponReceiving descriptions, credentials in pact files) -->
<!-- new in iteration 23: tRPC consumer contract testing pattern (TypeScript), Prisma/Drizzle ORM state handler patterns, Vitest 2.x singleFork mode, non-deterministic pact files anti-pattern, community lessons 42–46 (tRPC boundary misuse, ORM state handler teardown gaps, Vitest 2.x pool changes, dynamic example values breaking CI diffs, interaction count explosion in CRUD services) -->

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
- **When to migrate:** new TypeScript projects should start with pact-js v16 (V4); in v16+ the preferred import is `Pact`/`Matchers` (aliases for `PactV4`/`MatchersV3`). For existing V3 pact files the transition is safe since V4 is backward-compatible. For existing pact-js v13–v15 codebases using `PactV4`/`MatchersV3`, upgrading to v16 requires only a Node.js ≥ 20 runtime update — no import changes needed unless you want to use the new canonical names.

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
    "@pact-foundation/pact": "^16.0.0",
    "@pact-foundation/pact-cli": "^1.0.0",
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0",
    "wait-on": "^7.0.0"
  }
  // NOTE: pact-js v16+ requires Node.js >= 20.
  // If you are on pact-js v13 (Node >= 18), use "@pact-foundation/pact": "^13.0.0".
  // v13→v16 is a drop-in upgrade for V4 code; V2 code requires import renaming.
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

### Request Precision vs Response Flexibility (TypeScript)

The consumer controls the request it sends, so exact values are safe on the request side. The provider controls the response, so loose type-based matchers prevent brittle contracts that break on irrelevant provider changes.

```typescript
// request-response-matching-strategy.consumer.pact.spec.ts
// Demonstrates the precision vs flexibility matching strategy:
//   - Requests: exact values where the consumer fully controls the input
//   - Responses: type matchers (like, string, integer) for fields the consumer reads
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { UserAPI } from '../src/user-api';

const { like, string, integer, regex } = MatchersV3;

interface CreateUserResponse {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

const provider = new PactV3({
  consumer: 'FrontendApp',
  provider: 'UserService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8095,
  logLevel: 'warn',
});

describe('FrontendApp → UserService contract (precision vs flexibility)', () => {
  it('creates a new user and returns the created resource', async () => {
    await provider
      .given('no user with email alice@example.com exists')
      .uponReceiving('a POST /users request to create Alice (precision-request, flexible-response)')
      .withRequest({
        method: 'POST',
        path: '/users',
        headers: {
          // Exact Content-Type: consumer always sends exactly this
          'Content-Type': 'application/json',
        },
        body: {
          // Exact request body: the consumer constructs this — use exact values
          name: 'Alice',
          email: 'alice@example.com',
          role: 'member',
        },
      })
      .willRespondWith({
        status: 201,
        headers: {
          // Exact status code; Content-Type with type matcher (charset variation OK)
          'Content-Type': like('application/json'),
        },
        body: {
          // Server-assigned: use type matchers — consumer only needs the type, not the exact value
          id: regex(/^[0-9a-f-]{36}$/, '550e8400-e29b-41d4-a716-446655440000'),
          // Echo of request fields: use like() — confirms the field round-trips
          name: like('Alice'),
          email: like('alice@example.com'),
          role: like('member'),
          // Server-generated timestamp: type-match only
          createdAt: like('2025-01-15T10:00:00Z'),
        },
      })
      .executeTest(async (mockServer) => {
        const api = new UserAPI(mockServer.url);
        const result: CreateUserResponse = await api.createUser({
          name: 'Alice',
          email: 'alice@example.com',
          role: 'member',
        });
        // Only assert fields the consumer code actually uses
        expect(result.id).toBeDefined();
        expect(result.name).toBe('Alice');
        expect(result.email).toBe('alice@example.com');
      });
  });
});
```

**Decision rules for matcher selection:**

| Field origin | Matcher strategy | Rationale |
|---|---|---|
| Consumer-constructed (request body) | Exact value | Consumer controls it — exact matching is safe and documents intent |
| Server-assigned ID / UUID | `regex()` or `like()` | Value is dynamic; consumer only needs the type |
| Echo of request field in response | `like(requestValue)` | Confirms round-trip without locking to a specific value |
| Server-generated timestamp | `like()` or `timestamp()` | Format matters; exact value does not |
| Enum field consumer renders | `string('ACTIVE')` or `like()` | `like()` if new enum values should not break the consumer; exact only if the consumer has a switch statement |
| Count / total in paginated response | `integer()` | Type matters; exact count depends on server state |

**The Golden Rule (official Pact guidance):** Write unit tests for your API client first; the pact file is the side effect. This keeps contract tests focused on what the consumer actually parses — not on exhaustively documenting the provider's API surface.

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
| Testing provider validation rules in consumer pacts | Creates unnecessarily tight coupling — when the provider relaxes a validation rule (e.g., increases a character limit), the consumer contract breaks for no valid reason | Test that the provider returns an error status for invalid input; leave specific rule testing to the provider's own functional test suite |
| Using Pact for UI-layer integration tests | UI tests involve multiple simultaneous provider calls with slight variations, creating a cartesian explosion of interactions and tests that are very hard to debug | Scope Pact to isolated API client units; use generated pact files as HTTP stubs for UI integration tests |
| POST/PUT/PATCH without echoing updated values in the response | Since interactions are tested in isolation, a misnamed field (e.g., `lastname` instead of `surname`) is silently ignored by the provider and the contract passes — GIGO (Garbage In, Garbage Out) | Always assert the response body echoes back the key updated values; pair request body field names with response body validation to surface silent field mismatches |
| Duplicate `uponReceiving` descriptions in the same consumer pact file | The Pact Broker de-duplicates interactions by `(description, providerState)` tuple — the second overwrites the first with no warning; the first interaction disappears from the pact file silently | Use unique, scenario-specific descriptions: `uponReceiving('GET /orders/ORD-123 — happy path')` not `uponReceiving('a request for order details')` |
| Real credentials, tokens, or PII as matcher example values | Pact files are published to the Pact Broker and may be committed to VCS; literal credentials become permanently accessible to anyone with Broker access | Use fictional example values: `like('Bearer test-token-placeholder')`; omit `Authorization` headers from the pact body entirely and inject them via `requestFilter` |
| Running Pact consumer tests with full file parallelism in pact-js v16.3.x | A race condition in the native FFI layer causes `mockServerMatchedSuccessfully()` to return false intermittently under CPU pressure, producing "request not received" failures despite the mock server successfully handling the request | Set `singleThread: true` (Vitest) or `maxWorkers: 1` (Jest) for pact consumer test projects, or upgrade to a patched version; pin pact-js version and verify fix in changelog before re-enabling parallelism |

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
| `atMostLike(value, max)` | Array with maximum count | `atMostLike({ id: integer(1) }, 5)` |
| `constrainedArrayLike(min, max, value)` | Array with min and max count bounds | `constrainedArrayLike(1, 10, { id: integer(1) })` |
| `arrayContaining([...])` | Array contains these items (subset) | `arrayContaining([string('a')])` |
| `eachKeyMatches(value)` | Every key in an object matches a matcher | `eachKeyMatches(regex(/^\w+$/, 'tag'))` |
| `eachValueMatches(value)` | Every value in an object matches a matcher | `eachValueMatches(string('active'))` |
| `includes(value)` | String contains the given substring | `includes('ERROR:')` |
| `nullValue()` | Explicitly matches JSON `null` | `nullValue()` |
| `equal(value)` | Exact equality (no type flexibility) | `equal('CONFIRMED')` |
| `fromProviderState(expr, value)` | Value injected from provider state | `fromProviderState('${orderId}', 'ORD-001')` |

**When to choose `equal` vs `string`:** `equal('CONFIRMED')` asserts the exact value and type — it fails if the provider returns `'confirmed'` (wrong case) or any other string. Use `equal` only when the consumer's code path depends on the exact value (e.g., an enum that drives a switch statement). `string('CONFIRMED')` asserts the type is string with an example — the provider can return any string without breaking the contract.

**When to choose `eachKeyMatches` / `eachValueMatches`:** These are the fluent API equivalents of the `eachKey`/`eachValue` matching rule expressions used in `withMatchingRules`. Use the fluent matchers when the key/value validation is simple (type or regex); drop down to `withMatchingRules` only when combining `eachKey` + `eachValue` + `atLeast` on the same field.

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

### GraphQL Consumer Contract Test (TypeScript — Native `addGraphQLInteraction()` API)

pact-js v16.0.0 introduced a native GraphQL DSL via `addGraphQLInteraction()` on the `Pact` (V4) class. This is the **recommended approach** for new TypeScript projects. It handles the `operationName`, `query`, and `variables` body structure automatically — no manual regex matching on query strings.

```typescript
// catalog-graphql.consumer.pact.spec.ts
// Native V4 GraphQL DSL — pact-js v16.0.0+
// addGraphQLInteraction() handles query/variables body structure automatically.
import path from 'path';
import { Pact, Matchers } from '@pact-foundation/pact';

const { like, string, integer, eachLike } = Matchers;

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

// Use Pact (V4 alias) — addGraphQLInteraction() is only on the V4 DSL
const provider = new Pact({
  consumer: 'SearchUI',
  provider: 'CatalogGraphQL',
  dir: path.resolve(process.cwd(), 'pacts'),
  // V4: no port option — mock server auto-assigns a free port
  logLevel: 'warn',
});

describe('SearchUI → CatalogGraphQL contract (native V4 GraphQL DSL)', () => {
  it('executes SearchCatalog query and returns matching items', async () => {
    await provider
      .addGraphQLInteraction()
      .given('catalog has items matching "widget"')
      .uponReceiving('a SearchCatalog query for "widget"')
      // withOperation sets the GraphQL operationName — matched by type (string), not exact value
      .withOperation('SearchCatalog')
      // withVariables sets the query variables — matched by Pact matchers
      .withVariables({ term: like('widget'), limit: integer(10) })
      // withRequest sets method and path only — the body (query + operationName + variables)
      // is constructed automatically by the GraphQL DSL builder
      .withRequest('POST', '/graphql')
      // withQuery accepts a string or a graphql-tag AST node
      .withQuery(SEARCH_CATALOG_QUERY)
      .willRespondWith(200, (builder) => {
        builder
          .headers({ 'Content-Type': 'application/json' })
          .jsonBody({
            data: {
              searchCatalog: {
                items: eachLike({
                  id: string('ITEM-1'),
                  title: like('Widget A'),
                  price: like(19.99),
                }),
                totalCount: integer(3),
              },
            },
          });
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

  it('executes AddToCart mutation', async () => {
    const ADD_TO_CART_MUTATION = `
      mutation AddToCart($itemId: String!, $quantity: Int!) {
        addToCart(itemId: $itemId, quantity: $quantity) {
          success
          cartTotal
        }
      }
    `;

    await provider
      .addGraphQLInteraction()
      .given('item ITEM-1 is available')
      .uponReceiving('an AddToCart mutation for ITEM-1')
      .withOperation('AddToCart')
      .withVariables({ itemId: string('ITEM-1'), quantity: integer(2) })
      .withRequest('POST', '/graphql')
      // withQuery also accepts mutation documents — the DSL distinguishes query vs mutation
      // by the keyword in the document string
      .withQuery(ADD_TO_CART_MUTATION)
      .willRespondWith(200, (builder) => {
        builder.jsonBody({
          data: {
            addToCart: {
              success: true,
              cartTotal: like(39.98),
            },
          },
        });
      })
      .executeTest(async (mockServer) => {
        const client = new GraphQLClient(mockServer.url);
        const result = await client.query<{ addToCart: { success: boolean; cartTotal: number } }>(
          'AddToCart',
          ADD_TO_CART_MUTATION,
          { itemId: 'ITEM-1', quantity: 2 }
        );
        expect(result.addToCart.success).toBe(true);
        expect(typeof result.addToCart.cartTotal).toBe('number');
      });
  });
});
```

**Key points:**
- `addGraphQLInteraction()` is available on `Pact` (V4 DSL only — not `PactV3`); it generates a V4 pact file
- `withOperation(name)` sets the `operationName` field — matched by string type, not exact value; allows formatting differences
- `withQuery(document)` accepts a string or a `graphql-tag` AST node — the DSL handles serialization and whitespace normalization automatically, eliminating the regex-on-query-string brittleness of the old body-matching approach
- `withVariables(vars)` accepts Pact matchers (`like()`, `integer()`, etc.) for the variables object — matched the same way as HTTP body matchers
- Mutations use `withQuery()` exactly like queries — the keyword in the document (`query` vs `mutation`) distinguishes them; no separate `withMutation()` method is needed
- `addGraphQLInteraction()` does NOT support GraphQL subscriptions — subscriptions use WebSocket/SSE, which Pact cannot intercept. Test subscriptions separately with `MessageConsumerPact` (for message payloads) or integration tests
- For Apollo Client consumers, wrap `ApolloClient` with an `HttpLink` pointed at `mockServer.url` — the real Apollo network layer is exercised without modifications

**Migration from the old body-matching approach (PactV3 + regex):**

The guide previously showed this pattern (still valid for PactV3 codebases):

```typescript
// OLD approach — PactV3 with manual body matching (still works, but more brittle)
// Use this ONLY if you're on pact-js v12 or earlier, or maintaining a PactV3 codebase
.withRequest({
  method: 'POST', path: '/graphql',
  body: {
    operationName: string('SearchCatalog'),
    query: regex(/query SearchCatalog\(\$term: String!/, SEARCH_CATALOG_QUERY),
    variables: { term: like('widget'), limit: integer(10) },
  },
})
```

The new `addGraphQLInteraction()` approach is preferred because:
1. No regex on query strings — whitespace changes and comment additions don't break the contract
2. Query normalization is handled by the DSL — no need to match exact query string format
3. The pact file explicitly records the operation, query, and variables as structured fields

---

### Pact Plugin Framework — gRPC and Protobuf Contract Testing

The Pact Plugin Framework extends contract testing beyond REST/HTTP to gRPC, WebSockets, MQTT, GraphQL (body-based matching via plugins), and Protocol Buffers. It was released December 2022 after a developer preview beginning in 2021.

#### Architecture

```
┌──────────────────────────────┐
│  Pact Client Library         │   (language-specific: JS, JVM, Python, Rust…)
│  (pact-js, pact-jvm, etc.)   │
└──────────┬───────────────────┘
           │ gRPC messages
┌──────────▼───────────────────┐
│  Plugin Driver               │   (Rust or JVM implementation)
│  - Discovers plugins         │   ~/.pact/plugins/<name>-<version>/
│  - Reads pact-plugin.json    │   (manifest)
│  - Starts plugin process     │
│  - Routes messages to plugin │
└──────────┬───────────────────┘
           │ gRPC (plugin protocol)
┌──────────▼───────────────────┐
│  Plugin (e.g. protobuf)      │   gRPC server; handles content
│  - Reads .proto files        │   matching, mock server,
│  - Creates mock gRPC server  │   provider verification
│  - Matches Protobuf payloads │
└──────────────────────────────┘
```

Three interaction types are supported:
- **Synchronous/HTTP** — classic REST (no plugin needed)
- **Asynchronous/Message** — one-way events (Kafka, SNS, SQS); plugin adds Protobuf body matching
- **Synchronous/Message** — request-response over gRPC; bidirectional/streaming excluded in current stable version

#### Installing the pact-plugin-cli and Protobuf Plugin

```bash
# 1. Install pact-plugin-cli (cross-platform binary — no npm install needed)
#    Releases: https://github.com/pact-foundation/pact-plugins/releases
curl -LO https://github.com/pact-foundation/pact-plugins/releases/latest/download/pact-plugin-cli-linux-x86_64.gz
gunzip pact-plugin-cli-linux-x86_64.gz && chmod +x pact-plugin-cli-linux-x86_64
mv pact-plugin-cli-linux-x86_64 /usr/local/bin/pact-plugin-cli

# 2. Install the PactFlow protobuf/gRPC plugin (installs to ~/.pact/plugins/)
pact-plugin-cli -y install https://github.com/pactflow/pact-protobuf-plugin/releases/latest

# Result directory structure:
# ~/.pact/plugins/protobuf-<version>/
# ├── pact-plugin.json          ← plugin manifest
# └── pact-protobuf-plugin      ← executable (gRPC server)

# Override plugin location via env var (useful in CI):
export PACT_PLUGIN_DIR=/opt/pact/plugins
```

#### Plugin Manifest (`pact-plugin.json`)

```json
{
  "manifestVersion": 1,
  "pluginInterfaceVersion": 1,
  "name": "protobuf",
  "version": "0.3.15",
  "executableType": "exec",
  "entryPoint": "pact-protobuf-plugin",
  "pluginConfig": {
    "protocVersion": "3.19.1",
    "downloadUrl": "https://github.com/protocolbuffers/protobuf/releases/download",
    "hostToBindTo": "127.0.0.1"
  }
}
```

The Plugin Driver reads this manifest, starts the plugin process on load, and routes test lifecycle messages to it over gRPC. `hostToBindTo` should be `127.0.0.1` in Docker environments without IPv6.

#### gRPC Consumer Contract Test (Java — PactV4 + protobuf plugin)

```java
// AreaCalculatorConsumerTest.java
// Consumer: calls Calculator.calculate(ShapeMessage) → AreaResponse
// Requires pact-jvm-consumer + pact-plugin-driver on classpath
@ExtendWith(PactConsumerTestExt.class)
@PactTestFor(providerName = "AreaCalculatorProvider", providerType = ProviderType.SYNCH_MESSAGE)
public class AreaCalculatorConsumerTest {

    @Pact(consumer = "AreaCalculatorConsumer")
    public V4Pact calculateRectangleArea(PactBuilder builder) {
        return builder
            .usingPlugin("protobuf")
            .expectsToReceive("Calculate rectangle area", "core/interaction/synchronous-message")
            .with(Map.of(
                "pact:content-type", "application/grpc",
                "pact:proto",         filePath("../proto/area_calculator.proto"),
                "pact:proto-service", "Calculator/calculate",
                // request shape with matching rules
                "request", Map.of(
                    "rectangle", Map.of(
                        "length", "matching(number, 3)",
                        "width",  "matching(number, 4)"
                    )
                ),
                // response shape with matching rules
                "response", Map.of(
                    "value", "matching(number, 12)"
                )
            ))
            .toPact();
    }

    @Test
    @PactTestFor(pactMethod = "calculateRectangleArea")
    void verifyCalculateRectangle(V4Interaction.SynchronousMessages interaction) {
        // interaction.getRequestContents() gives the decoded Protobuf request bytes
        // interaction.getResponseContents() gives the decoded Protobuf response bytes
        // Your real client code would use the gRPC channel pointed at the mock server
        assertThat(interaction).isNotNull();
    }
}
```

#### gRPC Provider Verification (Java — Pact Verifier CLI or unit test)

```bash
# Verifier CLI approach — verify a running gRPC server against pacts from broker
pact-provider-verifier \
  --provider "AreaCalculatorProvider" \
  --provider-base-url grpc://localhost:50051 \
  --pact-broker-base-url "$PACT_BROKER_URL" \
  --broker-token "$PACT_BROKER_TOKEN" \
  --consumer-version-selectors '{"mainBranch": true}' \
  --publish-verification-results \
  --provider-app-version "$GIT_COMMIT"
```

#### Protobuf Message Consumer (Async — single message, not gRPC)

```java
// For async message contracts where the message body is a Protobuf-encoded payload
// (e.g., Kafka message containing a serialised protobuf Person)
@Pact(consumer = "AddressBookConsumer")
public V4Pact personMessagePact(PactBuilder builder) {
    return builder
        .usingPlugin("protobuf")
        .expectsToReceive("A person message", "core/interaction/message")
        .with(Map.of(
            "message.contents", Map.of(
                "pact:content-type", "application/protobuf",
                "pact:proto",        filePath("addressbook.proto"),
                "pact:message-type", "Person",
                "name",              "notEmpty('Fred')",
                "id",                "matching(regex, '100\\d+', '1000001')"
            )
        ))
        .toPact();
}
```

#### Matching Rule Reference for Protobuf Fields

| Field type | Matching expression | Example |
|---|---|---|
| Numeric scalar | `matching(number, <example>)` | `"length": "matching(number, 3)"` |
| String non-empty | `notEmpty('<example>')` | `"name": "notEmpty('Fred')"` |
| Regex | `matching(regex, '<pattern>', '<example>')` | `"id": "matching(regex, '\\d+', '42')"` |
| Repeated field (array) | `atLeast(<n>), eachValue(matching(...))` | `"numbers": "atLeast(1), eachValue(matching(regex, '\\d+', '1'))"` |
| Map field | `eachKey(...), eachValue(...), atLeast(<n>)` | `"labels": {"pact:match": "eachKey(matching(regex, '\\w+', '')), eachValue(matching(type, '')), atLeast(1)"}` |
| Provider state injection | `matching(number, fromProviderState('${expr}', <example>))` | `"length": "matching(number, fromProviderState('${rectLen}', 3))"` |
| Binary bytes | raw array or base64 string | `"raw_bytes": [1, 2, 3]` or `"raw_bytes": "AQID"` |

#### gRPC Error Response Verification

```java
// Test that the provider returns a gRPC UNIMPLEMENTED status for unsupported operations
.with(Map.of(
    "pact:content-type",  "application/grpc",
    "pact:proto",         filePath("service.proto"),
    "pact:proto-service", "Calculator/unsupportedOp",
    "request",  Map.of("value", "matching(number, 1)"),
    // No "response" key — use responseMetadata for error status
    "responseMetadata", Map.of(
        "grpc-status",  "UNIMPLEMENTED",
        "grpc-message", "matching(type, 'operation not supported')"
    )
))
```

#### Plugin Versioning in CI

```yaml
# .github/workflows/pact-grpc.yml — install exact plugin version in CI
- name: Install pact-plugin-cli
  run: |
    curl -LO https://github.com/pact-foundation/pact-plugins/releases/download/pact-plugin-cli-v0.1.2/pact-plugin-cli-linux-x86_64.gz
    gunzip pact-plugin-cli-linux-x86_64.gz
    chmod +x pact-plugin-cli-linux-x86_64
    sudo mv pact-plugin-cli-linux-x86_64 /usr/local/bin/pact-plugin-cli

- name: Install protobuf plugin (pinned version)
  run: |
    pact-plugin-cli -y install \
      https://github.com/pactflow/pact-protobuf-plugin/releases/tag/v-0.3.15
  env:
    PACT_PLUGIN_DIR: /opt/pact/plugins

- name: Run consumer pact tests
  run: ./gradlew test
  env:
    PACT_PLUGIN_DIR: /opt/pact/plugins
```

**Critical CI gotcha:** The plugin binary on the consumer machine (which generates the pact file) and the provider machine (which verifies it) must be the **same major version**. Version drift between local and CI plugin binaries causes silent verification failures — the pact file is written but provider verification skips the interaction. Always pin the plugin version explicitly.

#### What the Protobuf Plugin Does NOT Support (Current Stable)

| Unsupported feature | Workaround |
|---|---|
| Proto2 syntax | Migrate to proto3 or use schema-level comparison tools (buf) |
| gRPC streaming (bidirectional or one-way server/client streams) | Test streaming with integration tests; Pact is designed for unary RPC |
| Non-string map keys | Convert map to `repeated` message with key+value fields |
| Default field values | Assert explicitly; protobuf defaults are invisible to the matcher |

#### When to Use the Plugin Framework vs HTTP Pact

| Scenario | Recommended approach |
|---|---|
| REST/JSON API | Standard PactV3/V4 HTTP interaction — no plugin needed |
| gRPC unary RPC | Pact protobuf plugin — provides consumer-driven shape verification at the proto field level |
| gRPC streaming | Integration test or buf schema breaking-change detection — plugin does not support streaming yet |
| Async Protobuf messages (Kafka) | `MessageConsumerPact` + protobuf plugin for body matching |
| GraphQL | Standard HTTP body matching (query in POST body); no plugin needed |
| WebSockets (MQTT, STOMP) | Plugin framework — prototype transport plugins available; check plugin directory |
| Third-party gRPC API you don't control | Use `buf` breaking-change detection on the imported proto schema instead of Pact |

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
| Pact V4 | pact-js v13–v15 | Plugin architecture, auto-port, gRPC, Protobuf | Previously `PactV4`/`MatchersV3` |
| Pact V4 | pact-js v16.0 | Same spec + renamed default exports; Node ≥ 20; `addAsynchronousInteraction` | `Pact`/`Matchers` are now the V4 aliases; v13-style `PactV4` still works via the versioned export |
| Pact V4 | pact-js v16.1 | `withMatchingRules` on HTTP/async/sync interactions | Allows raw matching rule DSL for edge cases not covered by fluent matcher API |
| Pact V4 | pact-js v16.2 | `withMatchingRules` extended to async message and synchronous message interactions | Full matching rule support across all interaction types |
| Pact V4 | pact-js v16.3 | `.pending()`, `.withComment()`, `.withTestName()` per-interaction metadata | Per-interaction advisory-only flag; comments and test names visible in Broker UI |
| Pact V4 | pact-js v16.3.1 | Bug fix: content type extraction from matcher-wrapped `Content-Type` headers | Resolves body-parser failure when `Content-Type` header uses `like()` matcher in provider verification |
| Pact V4 | pact-js v16.4 | `addInteractionReference()` — external interaction reference support | Reuse interaction definitions stored outside the test file; v16.4.0 released 2026-05-04 |

**Migration notes for TypeScript projects:**

**pact-js v13 → v16 (current recommended version):**

```typescript
// BEFORE (pact-js v13–v15)
import { PactV3, PactV4, MatchersV3 } from '@pact-foundation/pact';
const provider = new PactV4({ ... });

// AFTER (pact-js v16+ — preferred style)
import { Pact, Matchers } from '@pact-foundation/pact';
//  Pact  === PactV4 (V4 HTTP DSL)
//  Matchers === MatchersV3 (flex matchers)
const provider = new Pact({ ... });

// Old names still work via versioned exports — no forced migration:
import { PactV4, MatchersV3 } from '@pact-foundation/pact'; // still valid
import { PactV3 } from '@pact-foundation/pact';             // still valid

// Legacy V2 DSL (plain Pact / Matchers pre-v16):
import { PactV2, MatchersV2 } from '@pact-foundation/pact'; // replaces old Pact/Matchers
```

**pact-js v16 breaking changes checklist:**
- Node.js ≥ 20 is now required (v16, v18, v19 all end-of-life)
- `Pact` now aliases `PactV4` (previously was the V2 HTTP DSL)
- `Matchers` now aliases `MatchersV3` (previously was V2 matchers)
- Libraries that wrap pact-js (`jest-pact`, `nestjs-pact`) need compatible updates — check their changelogs before upgrading
- `MatchersV2.AnyTemplate` removed — replace with explicit union types

**New V4 APIs added in pact-js v13–v16:**
- `addAsynchronousInteraction()` — V4 DSL method for async message contracts (replaces `MessageConsumerPact` for V4 pact files)
- `addSynchronousInteraction()` — V4 DSL for synchronous message/gRPC contracts
- `addInteractionReference()` — V4 DSL method to support external interaction references (v16.4+)
- Interaction metadata: `.withComment()`, `.withTestName()`, `.pending()` on V4 interactions (v16.3+) — allows marking interactions as advisory-only inline without `enablePending` at the verifier level

**Older migration notes:**
- V3 → V4: Replace `PactV3` with `PactV4` (or `Pact` in v16+); update `withRequest` to the builder API; pact files are backward-compatible in the Broker
- Pact V2 `term()` → V3 `regex()` from `MatchersV3`/`Matchers`: `term(value, regex)` → `regex(pattern, value)` (argument order reverses)
- V4 pact files include a `pluginConfiguration` section when plugins (gRPC, XML) are used — these files cannot be verified by a Broker running an older verifier

---

### pact-js v16 — Migration Pattern and New Interaction Metadata (TypeScript)

pact-js v16 (released 2026) ships the most impactful breaking changes since v13. Node.js ≥ 20 is required, and the default export names were restructured to promote V4 as the primary API.

#### v16 Import Update (drop-in for existing V4 code)

```typescript
// BEFORE — pact-js v13–v15 consumer test
import { PactV4, MatchersV3 } from '@pact-foundation/pact';

const { string, integer, like } = MatchersV3;

const provider = new PactV4({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

// AFTER — pact-js v16+ (preferred style)
// No API changes — only the import aliases changed.
// PactV4 and MatchersV3 still work via the versioned exports:
import { PactV4, MatchersV3 } from '@pact-foundation/pact'; // still valid in v16

// Alternatively, use the new canonical names:
import { Pact, Matchers } from '@pact-foundation/pact'; // Pact === PactV4, Matchers === MatchersV3

const { string, integer, like } = Matchers;

const provider = new Pact({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});
// The resulting pact file is identical to the v13 version.
// The Pact Broker and provider verification are backward-compatible.
```

#### v16 New Feature — Interaction Metadata (`.pending()`, `.withComment()`, `.withTestName()`)

pact-js v16.3 adds per-interaction metadata to the V4 DSL. This enables fine-grained control over which interactions are advisory-only, without requiring `enablePending` at the entire verifier level.

```typescript
// order-service.consumer.pact.v16.spec.ts
// Demonstrates v16.3 per-interaction metadata: pending, comment, testName.
import path from 'path';
import { Pact, Matchers } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client';

const { string, integer, like } = Matchers;

const provider = new Pact({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

describe('OrderService → InventoryService contract (v16 metadata)', () => {

  it('returns stock level for a known SKU (stable interaction)', async () => {
    await provider
      .addInteraction()
      .given('SKU ABC-123 exists with 10 units in stock')
      .uponReceiving('a request for stock level of SKU ABC-123')
      // withTestName maps the interaction to a specific Jest test — visible in Broker UI
      .withTestName('returns stock level for a known SKU (stable interaction)')
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
      });
  });

  it('handles a not-yet-implemented batch endpoint (pending interaction)', async () => {
    await provider
      .addInteraction()
      .given('batch stock endpoint is supported')
      .uponReceiving('a batch stock request for multiple SKUs')
      // .pending() marks this interaction as advisory — provider CI reports failure
      // but does NOT fail the build. Equivalent to enablePending for a single interaction.
      .pending(true)
      .withComment('Waiting for provider team to implement /inventory/batch in Sprint 23')
      .withTestName('handles batch stock request (pending until Sprint 23)')
      .withRequest('POST', '/inventory/batch', (builder) => {
        builder
          .headers({ 'Content-Type': 'application/json' })
          .jsonBody({ skus: [string('ABC-123'), string('XYZ-456')] });
      })
      .willRespondWith(200, (builder) => {
        builder.jsonBody({
          results: [
            { sku: string('ABC-123'), available: integer(10) },
            { sku: string('XYZ-456'), available: integer(0) },
          ],
        });
      })
      .executeTest(async (mockServer) => {
        const client = new OrderClient(mockServer.url);
        const result = await client.getBatchStock(['ABC-123', 'XYZ-456']);
        expect(result.results.length).toBe(2);
      });
  });
});
```

**Key points:**
- `.pending(true)` is the v16.3 per-interaction alternative to `enablePending: true` on the verifier — it marks only this interaction as advisory-only; all other interactions in the same pact remain hard gates
- `.withComment(message)` stores a human-readable note in the pact JSON — visible in the Pact Broker UI and useful for cross-team communication about in-progress features
- `.withTestName(name)` links the interaction to a specific test name — the Broker UI displays this, improving traceability when a single consumer test file generates many interactions
- When `.pending(true)` is set on an interaction, the Broker marks it as pending when the consumer publishes; it becomes a hard gate only after the provider successfully verifies it once

#### v16 `addAsynchronousInteraction()` (replaces `MessageConsumerPact` for V4)

```typescript
// notification-service.async.pact.v16.spec.ts
// v16 V4 DSL approach for async message contracts using addAsynchronousInteraction().
// This replaces MessageConsumerPact for teams on pact-js v16+ who want V4 pact files.
import path from 'path';
import { Pact, Matchers } from '@pact-foundation/pact';

const { like, string, timestamp } = Matchers;

interface OrderCreatedEvent {
  orderId: string;
  customerId: string;
  totalAmount: number;
  createdAt: string;
}

const messagePact = new Pact({
  consumer: 'NotificationService',
  provider: 'OrderService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

async function handleOrderCreatedEvent(body: OrderCreatedEvent): Promise<void> {
  if (!body.orderId || !body.customerId) {
    throw new Error('Missing required fields: orderId, customerId');
  }
}

describe('NotificationService consumes OrderCreated events (V4 async, pact-js v16)', () => {
  it('handles a well-formed OrderCreated message', async () => {
    await messagePact
      .addAsynchronousInteraction()
      .given('an order has just been placed')
      .uponReceiving('an OrderCreated event')
      .withContent({
        orderId: string('ORD-9876'),
        customerId: like('CUST-001'),
        totalAmount: like(99.99),
        createdAt: timestamp("yyyy-MM-dd'T'HH:mm:ssXXX", '2024-01-15T10:00:00+00:00'),
      })
      .withMetadata({ contentType: 'application/json' })
      .executeTest(async (body: OrderCreatedEvent) => {
        await handleOrderCreatedEvent(body);
        // no explicit assertions needed — if handleOrderCreatedEvent throws, test fails
      });
  });
});
```

**Key points:**
- `addAsynchronousInteraction()` is the V4 equivalent of `MessageConsumerPact` — it produces a V4 pact file (not V3), which means the plugin architecture and per-interaction metadata features are available
- `executeTest` receives the decoded message body directly (type-checked as `OrderCreatedEvent`), not a wrapper object — cleaner than the V3 `asynchronousBodyHandler` pattern
- For teams on pact-js v13–v15 using `MessageConsumerPact`, migration is optional — `MessageConsumerPact` still works in v16; use `addAsynchronousInteraction` only for new V4 pact files

---



| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Pact Docs | Official | https://docs.pact.io/ | Full reference for all Pact concepts |
| Pact Nirvana | Official | https://docs.pact.io/pact_nirvana | 7-level CI/CD maturity roadmap — Bronze → Diamond independent deployability |
| @pact-foundation/pact | npm | https://www.npmjs.com/package/@pact-foundation/pact | TypeScript/Node.js library |
| @pact-foundation/pact-cli | npm | https://www.npmjs.com/package/@pact-foundation/pact-cli | Pact Broker CLI for publishing and can-i-deploy |
| Pact JS GitHub | Repo | https://github.com/pact-foundation/pact-js | Examples, changelog, issue tracker |
| Pact Broker OSS | Repo | https://github.com/pact-foundation/pact_broker | Self-hosted broker (Docker: pactfoundation/pact-broker) |
| PactFlow | SaaS | https://pactflow.io/ | Managed Pact Broker with bi-directional contract support |
| Pact Plugin Framework | Official | https://docs.pact.io/plugins | Plugin architecture docs: gRPC, WebSockets, MQTT, Protobuf, GraphQL |
| pact-protobuf-plugin | Repo | https://github.com/pactflow/pact-protobuf-plugin | PactFlow's official gRPC/Protobuf plugin; installation, manifest, Java/Rust examples |
| pact-foundation/pact-plugins | Repo | https://github.com/pact-foundation/pact-plugins | Plugin driver source (Rust + JVM); plugin protocol design docs |
| pact-plugin-cli | Binary | https://github.com/pact-foundation/pact-plugins/releases | CLI tool for installing/listing/uninstalling Pact plugins |
| buf — Protobuf breaking change detection | Docs | https://buf.build/docs/breaking/ | gRPC/Protobuf CDC alternative when streaming is needed (Pact does not support streaming) |
| Martin Fowler — Consumer-Driven Contracts | Article | https://martinfowler.com/articles/consumerDrivenContracts.html | Foundational article explaining CDC origins |
| ts-jest | npm | https://www.npmjs.com/package/ts-jest | TypeScript preprocessor for Jest — compile pact tests without a separate tsc step |
| openapi-types | npm | https://www.npmjs.com/package/openapi-types | TypeScript types for OpenAPI 2.0/3.0/3.1 documents |
| OpenAPI Specification | Spec | https://spec.openapis.org/oas/latest.html | For the lighter schema-validation alternative |
| pact-js CHANGELOG | Repo | https://github.com/pact-foundation/pact-js/blob/master/CHANGELOG.md | Full version history; v16 breaking changes and migration notes |
| pact-js v16 Migration Guide | Repo | https://github.com/pact-foundation/pact-js/blob/master/docs/migrations/16.md | Node ≥20 requirement, PactV4→Pact rename, MatchersV3→Matchers rename, addAsynchronousInteraction |
| Pact Broker Webhooks | Official | https://docs.pact.io/pact_broker/webhooks | Webhook events: contract_requiring_verification_published (recommended, v2.82.0+) vs contract_content_changed (legacy) |
| PactFlow Drift | Product | https://pactflow.io/blog/schemas-can-be-contracts/ | Provider spec-compliance CI — validates running service against OpenAPI spec; closes BDCT blind spot |
| PactFlow MCP Server | Product | https://pactflow.io/blog/ | AI-assisted contract test generation and Broker querying from IDE/AI agent workflows (PactFlow only, August 2025) |
| pact-js GraphQL docs | Official | https://docs.pact.io/implementation_guides/javascript/docs/graphql | Native addGraphQLInteraction() V4 DSL — withOperation/withQuery/withVariables |
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
#
# Requires Pact Broker >= 2.82.0 (or PactFlow) for contract_requiring_verification_published.
# Older brokers: use "contract_content_changed" instead (see note below).

BROKER_URL="${PACT_BROKER_URL:?PACT_BROKER_URL required}"
BROKER_TOKEN="${PACT_BROKER_TOKEN:?PACT_BROKER_TOKEN required}"
CI_TOKEN="${CI_API_TOKEN:?CI_API_TOKEN required}"

# ── Webhook 1: Trigger provider CI when a pact requires verification ──────────
# RECOMMENDED: contract_requiring_verification_published (Pact Broker >= 2.82.0)
# Supersedes: contract_content_changed + contract_published
#
# Smart deduplication: fires once per provider version that lacks verification,
# targeting the latest main-branch version AND any version deployed to an environment.
# Unlike contract_content_changed, it avoids redundant builds when content is republished
# without changes.
#
# New template variables not available in contract_content_changed:
#   ${pactbroker.providerVersionNumber}    — SHA of provider version to check out
#   ${pactbroker.providerVersionBranch}    — branch of provider version
#   ${pactbroker.providerVersionDescriptions} — human-readable description (e.g., "latest from main")
curl --silent --show-error \
  -X POST "${BROKER_URL}/webhooks" \
  -H "Authorization: Bearer ${BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Trigger InventoryService CI when OrderService pact requires verification",
    "events": [
      { "name": "contract_requiring_verification_published" }
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
          "consumer_branch": "${pactbroker.consumerVersionBranch}",
          "provider": "${pactbroker.providerName}",
          "provider_sha": "${pactbroker.providerVersionNumber}",
          "provider_branch": "${pactbroker.providerVersionBranch}",
          "description": "${pactbroker.providerVersionDescriptions}"
        }
      }
    }
  }' \
  && echo "Webhook created successfully" \
  || echo "ERROR: Webhook creation failed"

# NOTE: If your Pact Broker is older than 2.82.0, use these events instead:
#   "events": [
#     { "name": "contract_content_changed" },
#     { "name": "contract_published" }
#   ]
# Upgrade the Broker (or migrate to PactFlow) to access the smarter event.

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
# Uses the contract_requiring_verification_published event (Pact Broker >= 2.82.0).
name: Provider Verification (Pact webhook-triggered)

on:
  repository_dispatch:
    types: [pact-verify]

jobs:
  verify-pact:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          # Check out the exact provider SHA from the webhook payload,
          # so verification runs against the correct provider version.
          # Falls back to the default branch for manually triggered runs.
          ref: ${{ github.event.client_payload.provider_sha || github.ref }}
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
          GIT_COMMIT: ${{ github.event.client_payload.provider_sha || github.sha }}
          GIT_BRANCH: ${{ github.event.client_payload.provider_branch || github.ref_name }}
          PUBLISH_VERIFICATION_RESULTS: 'true'
```

**Key points:**
- `contract_requiring_verification_published` (Pact Broker 2.82.0+) supersedes `contract_content_changed` + `contract_published` — it fires once per provider version that lacks verification results, targeting the latest main-branch version AND any deployed version. The older events trigger on every publish, causing redundant CI runs when a pact is republished with identical content
- `${pactbroker.providerVersionNumber}` and `${pactbroker.providerVersionBranch}` are new template variables in this event — pass them in the webhook payload to the provider CI so it can check out the exact commit that needs verification rather than defaulting to HEAD
- `${pactbroker.providerVersionDescriptions}` is a human-readable summary (e.g., "latest from main branch, deployed in test") — useful in Slack notification bodies for context
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

28. **[community] pact-js v16 export rename breaks `jest-pact` and `nestjs-pact` without a co-upgrade.** In pact-js v16, `Pact` and `Matchers` were renamed to alias `PactV4`/`MatchersV3`, while the old V2 DSL is now `PactV2`/`MatchersV2`. Wrapper libraries that proxy the old `Pact` export (`jest-pact`, `nestjs-pact`, `@pact-foundation/nest`) instantiated against the V2 class — after the v16 upgrade they silently instantiate a V4 class, causing unexpected behavior or type errors. **Fix:** co-upgrade the wrapper library and pact-js together; check the wrapper library's changelog for a v16-compatible release before running `npm update @pact-foundation/pact`. Also: pact-js v16 requires Node.js ≥ 20 — teams on Node 18 LTS must upgrade their CI runner image first (e.g., `node:20-alpine` in Docker, `node-version: '20'` in GitHub Actions).

29. **[community] Using `contract_content_changed` webhook event causes redundant provider CI builds.** The older `contract_content_changed` event fires whenever a pact is published — even if the content is identical to the previous version (e.g., a re-publish during a CI retry). This triggers unnecessary provider verification runs that add pipeline noise. The correct event since Pact Broker 2.82.0 is `contract_requiring_verification_published`, which smart-deduplicates by provider version and fires only when a provider version actually needs new verification. Teams on self-hosted Pact Broker should check their version (`GET /diagnostic/status`) before upgrading the webhook; teams on PactFlow can switch immediately.

30. **[community] Bi-directional contract testing (BDCT) has a blind spot: the running service may not match its OpenAPI spec.** BDCT verifies that the provider's OpenAPI spec is compatible with consumer pacts, but it does NOT verify that the running provider actually implements the spec. A provider can pass BDCT while having a route that returns 500 or a wrong field type in production. PactFlow's new Drift tool closes this gap: it generates a full test suite from the OpenAPI spec and runs it against the live service in CI. The combined strategy: Drift gates "spec conformance" (does the service do what the spec says?) and BDCT gates "consumer compatibility" (does the spec satisfy all consumer needs?). Both must pass before deployment.

---

### pact-js v16.2 — `withMatchingRules` for Async and Sync Interactions (TypeScript)

pact-js v16.1–v16.2 added `withMatchingRules` to allow explicit matching rule DSL on HTTP, async message, and synchronous message interactions. This is an escape hatch for edge cases where the fluent `MatchersV3` API doesn't express the required matching rule — for example, complex nested `eachValue` rules on Protobuf-like structures or custom matching expressions.

```typescript
// notification-service.async.matching-rules.pact.spec.ts
// Demonstrates withMatchingRules on an async message interaction (pact-js v16.2+).
// Use case: the message payload contains a map field where both keys and values
// need to be validated by regex — not directly expressible via MatchersV3 fluent API.
import path from 'path';
import { Pact, Matchers } from '@pact-foundation/pact';

const { like, string } = Matchers;

interface MetadataPayload {
  eventId: string;
  attributes: Record<string, string>; // map<string, string> — keys are tag names, values are tag values
}

const messagePact = new Pact({
  consumer: 'AuditService',
  provider: 'EventBus',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

async function handleMetadataEvent(body: MetadataPayload): Promise<void> {
  if (!body.eventId) throw new Error('Missing eventId');
  if (typeof body.attributes !== 'object') throw new Error('attributes must be an object');
}

describe('AuditService consumes metadata events (withMatchingRules)', () => {
  it('handles an event with dynamic map attributes', async () => {
    await messagePact
      .addAsynchronousInteraction()
      .given('an event with dynamic attributes')
      .uponReceiving('a metadata event with a key-value attributes map')
      .withContent({
        eventId: string('EVT-001'),
        // attributes is a dynamic map — represent with like() for basic type assertion
        attributes: like({ 'region': 'us-east-1' }),
      })
      // withMatchingRules: apply explicit matching rules that the fluent API cannot express.
      // Here: eachKey validates key format; eachValue validates value format.
      .withMatchingRules({
        body: {
          '$.attributes': {
            combine: 'AND',
            matchers: [
              // All keys must be lowercase alphanumeric with hyphens
              { match: 'eachKey', rules: [{ match: 'regex', regex: '^[a-z][a-z0-9-]*$' }] },
              // All values must be non-empty strings
              { match: 'eachValue', rules: [{ match: 'type' }] },
              { match: 'values', rules: [{ match: 'notEmpty' }] },
            ],
          },
        },
      })
      .withMetadata({ contentType: 'application/json' })
      .executeTest(async (body: MetadataPayload) => {
        await handleMetadataEvent(body);
      });
  });
});
```

**Key points:**
- `withMatchingRules({ body: { ... } })` accepts raw matching rule objects from the Pact V4 matching DSL — the same format that appears in the pact JSON file under `matchingRules`
- Use `withMatchingRules` only when the fluent matcher API (`MatchersV3` / `Matchers`) cannot express the requirement — the fluent API is always preferred for readability
- `eachKey` and `eachValue` matching rules are the most common reason to drop down to the raw DSL: they validate every key/value in a dynamic map, which has no direct `MatchersV3` equivalent
- The `combine: 'AND'` tells Pact to apply all listed matchers together; use `'OR'` when any single matcher passing is sufficient
- `withMatchingRules` is available on HTTP interactions (`.withRequest()` / `.willRespondWith()` step), async message interactions (`.addAsynchronousInteraction()`), and sync message interactions (`.addSynchronousInteraction()`) as of v16.2.0

---

### pact-js v16.4 — `addInteractionReference` (TypeScript — external interaction reuse)

`addInteractionReference` was added in pact-js v16.4.0 (2026-05-04). It allows a consumer test to reference an interaction that is defined externally — in a shared package, a separate file, or a contract repository — rather than defining the interaction inline. This supports large teams that share interaction definitions across multiple consumer services.

```typescript
// shared/inventory-interactions.ts
// Shared interaction definitions for the InventoryService contract.
// Consumers import these rather than defining interactions inline.
// Centralizes the contract definition; reduces duplication across consumer test files.
import { PactV3, MatchersV3, InteractionObject } from '@pact-foundation/pact';

const { like, string, integer } = MatchersV3;

// Exported interaction definitions — consumers use addInteractionReference() to include them
export const InventoryInteractions = {
  getStockForKnownSku: (): InteractionObject => ({
    state: 'SKU ABC-123 exists with 10 units in stock',
    uponReceiving: 'a request for stock level of SKU ABC-123',
    withRequest: {
      method: 'GET',
      path: '/inventory/ABC-123',
      headers: { Accept: 'application/json' },
    },
    willRespondWith: {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
      body: {
        sku: string('ABC-123'),
        available: integer(10),
        warehouseId: like('WH-001'),
      },
    },
  }),
} as const;
```

```typescript
// checkout-service.consumer.pact.spec.ts
// Uses addInteractionReference to reuse the shared InventoryInteractions definition.
// The checkout service also needs the same InventoryService endpoint as the order service.
import path from 'path';
import { PactV3 } from '@pact-foundation/pact';
import { CheckoutClient } from '../src/checkout-client';
import { InventoryInteractions } from '../shared/inventory-interactions';

const provider = new PactV3({
  consumer: 'CheckoutService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8093,
  logLevel: 'warn',
});

describe('CheckoutService → InventoryService contract (shared interaction reference)', () => {
  it('verifies stock level for checkout validation', async () => {
    // addInteractionReference: include a pre-defined interaction object.
    // The pact file records the interaction identically to an inline definition.
    // Verification on the provider side is unchanged.
    await provider
      .addInteractionReference(InventoryInteractions.getStockForKnownSku())
      .executeTest(async (mockServer) => {
        const client = new CheckoutClient(mockServer.url);
        const result = await client.checkInventory('ABC-123');
        expect(result.available).toBeGreaterThanOrEqual(0);
      });
  });
});
```

**Key points:**
- `addInteractionReference(interactionObject)` accepts an `InteractionObject` (the same type used by `PactV3`'s interaction builder) and produces an identical pact file to inline definition — provider verification is unaffected
- Primary use case: multiple consumer services that all depend on the same provider endpoint. Instead of duplicating the interaction definition in each test file, they import from a shared package — a rename or type change in the shared definition updates all consumers simultaneously
- `addInteractionReference` is a V4 DSL addition (available in pact-js v16.4.0+, Pact V4 spec); it is not available in `PactV3`
- Prefer inline interactions for simple test cases — `addInteractionReference` is most valuable when ≥3 consumers share an identical interaction with a single provider endpoint
- The shared interactions module should be versioned alongside the provider contract (e.g., in a monorepo `packages/contracts/` directory or a published `@org/api-contracts` npm package)

---

### PactFlow Drift — Provider Compliance Testing (TypeScript / CI)

PactFlow Drift (released 2026) closes the gap in bi-directional contract testing (BDCT): BDCT verifies that an OpenAPI spec is compatible with consumer pacts, but it does not verify that the running service actually implements the spec. Drift validates the running provider against its OpenAPI spec in CI.

**Architecture:**

```
┌──────────────────────────────────────────────────────────────────────┐
│  Standard Pact CDC                                                    │
│  Consumer pact → Broker → Provider verification → can-i-deploy       │
│  ✓ Confirms: consumer expectations met by provider                   │
│  ✗ Blind spot: provider may return wrong types / statuses in prod    │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  PactFlow BDCT + Drift (combined)                                     │
│                                                                       │
│  Drift:                                                               │
│    OpenAPI spec → auto-generated test suite → run vs live service    │
│    ✓ Confirms: running provider implements the spec correctly         │
│                                                                       │
│  BDCT (PactFlow):                                                     │
│    Consumer pact + Provider OpenAPI spec → cross-validation          │
│    ✓ Confirms: spec satisfies all consumer expectations              │
│                                                                       │
│  can-i-deploy:                                                        │
│    Gate deployment: both Drift and BDCT must pass                    │
└──────────────────────────────────────────────────────────────────────┘
```

**When to use Drift vs standard Pact CDC:**

| Scenario | Recommended |
|---|---|
| Multiple independent consumer teams, independent deployments | Standard Pact CDC (consumer-driven) |
| Provider already has a well-maintained OpenAPI spec | BDCT + Drift |
| Third-party API you don't control (cannot run provider verification) | BDCT with provider-uploaded spec |
| Provider spec exists but running service may diverge (e.g., legacy, code-gen mismatch) | Drift |
| New greenfield TypeScript API with typed route handlers | Standard Pact CDC (types and pacts both enforce contract) |

**CI integration (GitHub Actions):**

```yaml
# .github/workflows/drift.yml
# Runs PactFlow Drift to verify provider spec conformance on every provider push.
name: PactFlow Drift — Provider Spec Compliance

on:
  push:
    branches: [main, 'feature/**']

jobs:
  drift:
    name: Drift — OpenAPI spec compliance
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci

      - name: Start provider service
        run: node dist/server.js &
        env:
          PORT: 3001
          NODE_ENV: test

      - name: Wait for provider to be ready
        run: npx wait-on http://localhost:3001/health --timeout 30000

      - name: Run Drift against OpenAPI spec
        # Drift CLI: download from PactFlow docs / available as Docker image
        # drift run --spec <openapi-file> --target <provider-url>
        run: |
          npx @pactflow/drift run \
            --spec ./openapi/inventory.yaml \
            --target http://localhost:3001 \
            --report-format junit \
            --output drift-results.xml
        env:
          PACTFLOW_TOKEN: ${{ secrets.PACTFLOW_TOKEN }}

      - name: Upload Drift results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: drift-results
          path: drift-results.xml
```

**Key points:**
- Drift is available to PactFlow and Swagger Contract Testing customers (not the OSS Pact Broker)
- It generates a test suite from the OpenAPI spec (including request/response validation, status codes, and required fields) and runs it against the actual running service — catching implementation drift that BDCT alone cannot detect
- Drift + BDCT together enforce both "the spec is consumer-compatible" and "the service implements the spec" — providing full contract confidence before `can-i-deploy`
- For teams using standard Pact CDC (not BDCT), Drift is complementary: add it to the provider CI to catch spec-implementation drift independently of consumer pacts
- If your TypeScript provider uses code generation from OpenAPI (e.g., `openapi-typescript-codegen`), Drift serves as a regression test: a code-gen update that changes the generated route handler signatures will fail the Drift run before it reaches staging

---

### PactFlow MCP Server — AI-Assisted Contract Test Generation (2025)

PactFlow released an MCP (Model Context Protocol) server in August 2025 that integrates contract testing directly into developer IDEs and AI agent workflows. It allows LLM-powered tools (Claude Code, GitHub Copilot, Cursor) to query the Pact Broker for existing contracts, generate new consumer tests, and identify compatibility issues — without leaving the IDE.

**What the MCP server enables:**
- Query the Pact Broker directly from your IDE chat: "which consumers depend on `GET /inventory/:sku`?"
- Generate consumer pact tests by describing the interaction in natural language — the AI produces idiomatic TypeScript using `addGraphQLInteraction()` or `PactV4`
- Review breaking changes: ask "what will break if I remove `warehouseId` from the response?" and get an answer derived from the live Pact Broker compatibility matrix
- AI-powered code review of existing pact files: identifies over-specified matchers, missing error interactions, and provider state drift

**When to use the MCP server:**
- Onboarding new teams to Pact — the AI can generate a starter consumer test from an OpenAPI spec
- Large provider with many consumers — ask the Broker "which consumers depend on this field?" before a breaking change
- Contract test maintenance — AI review surfaces redundant interactions and suggests matcher improvements

**Limitations:**
- Requires PactFlow (not available on the OSS Pact Broker)
- Generated tests must be reviewed — AI output follows the correct DSL patterns but may over-specify matchers (exact values instead of `like()`) or miss required provider states
- Does not replace understanding of Pact fundamentals — teams that skip the learning curve and rely solely on AI generation end up with brittle contracts

**Integration pattern (Claude Code + Pact Broker MCP):**

```jsonc
// .claude/settings.json (or equivalent MCP config)
// Add the PactFlow MCP server so Claude Code can query the Pact Broker directly
{
  "mcpServers": {
    "pactflow": {
      "command": "npx",
      "args": ["@pactflow/mcp-server"],
      "env": {
        "PACTFLOW_BASE_URL": "${PACT_BROKER_URL}",
        "PACTFLOW_API_TOKEN": "${PACT_BROKER_TOKEN}"
      }
    }
  }
}
```

Once configured, ask your AI assistant:
- "Generate a Pact consumer test for `GET /inventory/:sku` from the existing pact file for CheckoutService"
- "Which consumer pacts will be broken if I rename `warehouseId` to `facilityId` in the InventoryService response?"
- "Show me all provider states registered for InventoryService"

---

### Additional Community Production Lessons [community]

31. **[community] The old PactV3 body-matching regex approach for GraphQL breaks on query reformatting.** Teams that use `regex(/query SearchCatalog\(/, queryString)` in their GraphQL consumer pact tests find that a code formatter (Prettier, ESLint) reformatting the query constant breaks the pact — the regex no longer matches the new whitespace. The fix is to migrate to `addGraphQLInteraction()` with `withQuery()`, which normalizes the query document before matching. This is the recommended approach in pact-js v16. Legacy tests using `PactV3` with body matchers still work but require maintainers to keep the regex in sync with the formatter's output.

32. **[community] AI-generated Pact tests from PactFlow MCP over-specify matchers in ~40% of cases.** Teams adopting the PactFlow MCP Server report that AI-generated consumer tests commonly use exact string matching (`string('ABC-123')` instead of `like('ABC-123')`) and missing `like()` wrappers on dynamic IDs. The root cause: the AI is trained on examples where specificity reads as confidence. A standard review checklist item — "does every ID, timestamp, and server-assigned field use `like()` or `fromProviderState()`?" — catches most of these before they reach the Broker. AI generation is best used for scaffolding test structure, not for final matcher selection.

33. **[community] POST/PUT/PATCH pacts silently pass when field names are wrong (GIGO).** Because Pact interactions are tested in isolation — you cannot chain a POST then a GET to verify persistence — a consumer that sends `{ lastname: 'Smith' }` when the provider expects `{ surname: 'Smith' }` will receive a 200 from the provider (which ignores the unknown field) and the pact passes. Only by asserting that the response echoes back the sent field value does the mismatch surface. Best practice: for write operations, always include a response body assertion that mirrors the key fields from the request body. This pairs naturally with the strangler field-renaming pattern: when a field is renamed, the echo assertion fails before deployment.

34. **[community] Consumer pacts that test provider validation rules create unnecessary coupling.** A common overreach is writing interactions like "when `username` exceeds 100 characters, provider returns 422 with specific error text." This test encodes a provider business rule into the consumer contract. When the provider legitimately relaxes that limit (say, to 255 characters), the consumer's pact starts failing even though the consumer itself is unaffected. Official Pact guidance is explicit: contract tests catch misunderstanding and breaking changes — not provider correctness. Test that invalid input returns an error status; leave validation-rule specifics to the provider's own functional test suite.

35. **[community] pact-js v16.3.1 (April 29 2026) fixes content type extraction from matchers.** Projects that set the `Content-Type` header inside a `MatchersV3` body wrapper (e.g., `headers: { 'Content-Type': like('application/json') }`) experienced the verifier failing to correctly identify the content type for body parsing in v16.3.0. The v16.3.1 patch ("extract content type from matchers") resolves this by extracting the plain string value from a matcher-wrapped header before passing it to the body parser. If you use type matchers on the `Content-Type` header in provider verification, upgrade to v16.3.1 or later before running verification in CI.

36. **[community] pact-js v16.3.0 has a race condition under parallel Vitest load that causes `mockServerMatchedSuccessfully()` to intermittently return false.** When running Pact consumer tests in parallel (default in Vitest ≥ 4.x with multiple test files), the native FFI layer's request tracking can be called before asynchronous match recording completes — causing valid interactions to fail with "Mock server failed: expected request not received" even though the mock server correctly handled the request and returned a 200. The failure rate is low (< 10% of interactions) but correlates with CPU pressure from parallel file execution, making it particularly hard to diagnose. **Workaround:** add `--fileParallelism=false` to Vitest CLI flags for pact test projects, or run pact tests as a dedicated project with `singleThread: true` in `vitest.config.ts`. Downgrading to v16.2.0 eliminates the issue. The root cause (race in `@pact-foundation/pact-core` v19.x native FFI) was tracked in [issue #1713](https://github.com/pact-foundation/pact-js/issues/1713) and remained unresolved in v16.4.0; check the changelog before upgrading past v16.4.0.

37. **[community] Provider verification has no built-in interaction filter — running against one failing interaction requires running all interactions.** Teams that adopt Pact find that debugging a single failing provider interaction (e.g., one specific state handler out of 30) requires running the full verification suite each time — there is no `--filter-by-description` or `--filter-by-state` CLI flag in pact-js (tracked in [issue #1748](https://github.com/pact-foundation/pact-js/issues/1748)). This slows local debugging significantly when the provider test server is slow to start or has many interactions. **Practical workaround until a filter is available:** use the `pactUrls` option in `VerifierV3` to point at a local pact file, and temporarily remove all but the failing interaction from a copy of that file. This gives targeted, fast feedback during active development. Alternatively, use `filterConsumerNames` to narrow to a single consumer if the failing interaction belongs to a specific consumer. Neither workaround is ergonomic — this is a known friction point for large provider verification suites.

38. **[community] Empty JSON body `{}` hangs Express provider verification due to `Content-Length` mismatch (open in v16, pact-js issue #1602).** When a Pact interaction sends a POST/PUT/PATCH request with an empty JSON body `{}`, the verifier sometimes sets an incorrect `Content-Length` header. Express's `express.json()` middleware reads fewer bytes than the header indicates and waits indefinitely for more data — the test hangs with no timeout error. **Workaround:** add a `requestFilter` to delete the `Content-Length` header before it reaches the middleware:

```typescript
const verifier = new VerifierV3({
  // ... other options ...
  requestFilter: (req, _res, next) => {
    // Workaround for pact-js issue #1602: Content-Length mismatch
    // causes Express json() middleware to hang on empty body {}.
    // Remove it and let Express recalculate from the body.
    delete req.headers['content-length'];
    next();
  },
});
```

This does not affect body matching — Pact matches the body content independently of the `Content-Length` header. Apply the workaround selectively if your provider uses `content-length` for security (e.g., request size limits); in that case, re-calculate the correct value rather than deleting the header entirely.

39. **[community] `stateHandlers` are silently ignored when `requestFilter` is also configured (open in pact-js ≥v13, issue #1434).** A subtle interaction between `requestFilter` and `stateHandlers` in `VerifierV3` causes state setup to be routed as an HTTP POST to `http://127.0.0.1:/_pactSetup` instead of invoking the handler function directly — the state handler never runs, the request times out after 30 seconds, and the interaction fails with a misleading "provider state setup failed" error rather than exposing the real cause. **Diagnosis:** if state handlers appear to not be running in a test that also uses `requestFilter`, enable `logLevel: 'debug'` and look for a line like `POST http://127.0.0.1:/_pactSetup` — this confirms the handler is being bypassed. **Workaround:** expose the state setup endpoint explicitly on the provider test server rather than relying on pact-js's internal handler invocation:

```typescript
// inventory-service.provider.pact.spec.ts
// Workaround for pact-js issue #1434:
// Expose /_pactSetup as an HTTP endpoint when requestFilter is present.
import express from 'express';
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { app as providerApp } from '../src/app';
import { db } from '../src/db';

// State map — same logic as stateHandlers, but served via HTTP endpoint
const states: Record<string, () => Promise<void>> = {
  'SKU ABC-123 exists with 10 units in stock': async () => {
    await db.seed({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' });
  },
  'SKU UNKNOWN-999 does not exist': async () => {
    await db.clear('UNKNOWN-999');
  },
};

// Wrap the provider app, adding the /_pactSetup endpoint
const testApp = express();
testApp.use(express.json());

// Pact state setup route — receives { state: 'provider state name', action: 'setup'|'teardown' }
testApp.post('/_pactSetup', async (req, res) => {
  const { state, action } = req.body as { state: string; action: 'setup' | 'teardown' };
  if (action === 'setup' && states[state]) {
    await states[state]();
    res.status(200).json({ result: state });
  } else {
    res.status(200).json({ result: 'no-op' });
  }
});

// Mount the real provider app
testApp.use(providerApp);

describe('InventoryService provider verification (requestFilter + state workaround)', () => {
  let server: ReturnType<typeof testApp.listen>;
  let serverUrl: string;

  beforeAll(async () => {
    await new Promise<void>((resolve) => {
      server = testApp.listen(0, '127.0.0.1', () => {
        const addr = server.address() as { port: number };
        serverUrl = `http://127.0.0.1:${addr.port}`;
        resolve();
      });
    });
  });

  afterAll(async () => {
    await new Promise<void>((res) => server.close(() => res()));
  });

  it('satisfies all consumer pacts', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: serverUrl,
      // stateHandlers intentionally omitted — handled via /_pactSetup endpoint above
      // because requestFilter + stateHandlers interact incorrectly (issue #1434)
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }],
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
      requestFilter: (req, _res, next) => {
        req.headers['Authorization'] = `Bearer ${process.env.PROVIDER_TEST_TOKEN}`;
        next();
      },
    });

    await verifier.verifyProvider();
  });
});
```

The `/_pactSetup` endpoint receives `{ state: '<provider state name>', action: 'setup' | 'teardown' }` from the pact-js verifier internals. Once exposed as an HTTP route, the state setup works correctly regardless of whether `requestFilter` is also configured.

40. **[community] Duplicate `uponReceiving` descriptions within the same consumer-provider pair silently overwrite each other in the pact file.** The Pact Broker de-duplicates interactions by `(description, providerState)` tuple. When two tests in the same consumer file use `.uponReceiving('a request for order details')` with the same provider state, the second interaction overwrites the first in the generated pact JSON — the first interaction disappears entirely without any warning from pact-js. This is particularly dangerous in test suites that copy-paste interaction scaffolding: the provider verification passes (fewer interactions to verify) and the consumer's real intent is simply not tested. **Prevention:** adopt a naming convention that encodes the scenario uniquely — e.g., `uponReceiving('a GET request for order ORD-123 (happy path)')` rather than generic descriptions. The `withTestName()` metadata (pact-js v16.3+) records the Jest/Vitest test name in the Broker UI but does not prevent de-duplication — unique `uponReceiving` strings are the only guard.

41. **[community] Sensitive data in pact files published to the Broker is a security risk.** Consumer tests that use real authorization tokens, customer IDs, or PII as literal matcher examples embed that data in the generated pact JSON. Since pact files are published to the Pact Broker (and possibly committed to version control), real credentials or personal data become permanently accessible to anyone with Broker access. Always use `like()` with a fictional example value for credentials, UUIDs, and customer identifiers: `like('Bearer test-token-placeholder')` rather than `like(process.env.REAL_TOKEN)`. For authorization headers specifically, Pact ignores `Authorization` header matching by design — omit `Authorization` from the pact body entirely and inject it via `requestFilter` in the provider verifier.

---

### tRPC Contract Testing (TypeScript — boundary testing at the HTTP layer)

[tRPC](https://trpc.io/) builds fully type-safe client-server communication using TypeScript inference — when the same TypeScript monorepo owns both the consumer and provider, tRPC's compile-time guarantees eliminate many of the cross-service structural mismatches that CDC catches. However, CDC remains necessary in two scenarios:

1. **Cross-repository or cross-team tRPC**: the consumer and provider live in separate repos, so TypeScript types cannot be shared at compile time.
2. **tRPC with a non-TypeScript consumer**: a mobile app or a third-party service consumes the tRPC HTTP endpoint without using the TypeScript client.

In these scenarios, tRPC procedures map to HTTP endpoints (`/trpc/<procedure>` with a POST body `{ "0": { json: <input> } }` for mutations). These endpoints can be contract-tested using standard Pact HTTP interactions.

```typescript
// trpc-report.consumer.pact.spec.ts
// Tests the Pact contract for a tRPC `report.create` mutation consumed
// from a separate repository (no shared TypeScript types at compile time).
// tRPC mutation endpoint: POST /trpc/report.create
// Body shape: { "0": { "json": { title, content, severity } } }
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like, string, integer } = MatchersV3;

// Response type matches the shape the consuming service actually parses
interface ReportCreateResponse {
  result: {
    data: {
      json: {
        id: string;
        createdAt: string;
      };
    };
  };
}

const provider = new PactV3({
  consumer: 'DashboardFrontend',
  provider: 'ReportingService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8095,
  logLevel: 'warn',
});

describe('DashboardFrontend → ReportingService tRPC contract', () => {
  it('creates a report via tRPC mutation and receives the created ID', async () => {
    await provider
      .given('ReportingService is ready to accept new reports')
      .uponReceiving('a tRPC report.create mutation')
      .withRequest({
        method: 'POST',
        path: '/trpc/report.create',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        // tRPC batch format: the "0" key is the batch index
        body: {
          '0': {
            json: {
              title: like('Incident Report Q2'),
              content: like('Details of the incident...'),
              severity: like('high'),
            },
          },
        },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          result: {
            data: {
              json: {
                id: string('RPT-001'),
                createdAt: like('2025-01-15T10:00:00Z'),
              },
            },
          },
        },
      })
      .executeTest(async (mockServer) => {
        // Call the tRPC endpoint directly via fetch — no tRPC client dependency
        const response = await fetch(`${mockServer.url}/trpc/report.create`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify({
            '0': { json: { title: 'Incident Report Q2', content: 'Details...', severity: 'high' } },
          }),
        });
        const json: ReportCreateResponse = await response.json();
        expect(json.result.data.json.id).toBeDefined();
        expect(json.result.data.json.createdAt).toBeDefined();
      });
  });
});
```

**Key points:**
- tRPC batch format wraps the input as `{ "0": { "json": <input> } }` — match with `like()` on the input fields so the contract does not lock to specific values
- The response is wrapped in `{ result: { data: { json: <output> } } }` — only assert the fields the consumer actually reads from this envelope
- Use standard HTTP `fetch` (or `axios`) in the consumer test, not the tRPC client — this isolates the HTTP contract from tRPC client library internals and makes the pact file portable to non-TypeScript consumers
- Provider verification works identically to REST: the tRPC endpoint is a regular HTTP route; `VerifierV3` replays the interaction against the running tRPC server with no tRPC-specific config

**When CDC adds no value for tRPC:**
- Both consumer and provider live in the same TypeScript monorepo with a shared tRPC router type — TypeScript's `inferRouterInputs<AppRouter>` and `inferRouterOutputs<AppRouter>` already provide compile-time cross-boundary type safety; a Pact interaction duplicates this coverage without adding runtime protection
- In this case, prefer end-to-end type inference and a thin integration smoke test instead of CDC

---

### Prisma / Drizzle ORM State Handler Patterns (TypeScript)

State handlers that seed a relational database are the most common source of flakiness and maintenance cost in provider verification. Modern TypeScript backends use Prisma or Drizzle ORM — both have idiomatic patterns for test state setup that are safer than raw SQL.

```typescript
// inventory-service.provider.prisma.pact.spec.ts
// State handlers using Prisma ORM — idiomatic for TypeScript Prisma backends.
// Prisma's transaction API and upsert allow atomic, conflict-safe state setup.
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { PrismaClient } from '@prisma/client';
import { createServer } from 'http';
import { AddressInfo } from 'net';
import { app } from '../src/app';

const prisma = new PrismaClient();

// Prisma state handlers — prefer upsert over insert to make handlers idempotent
const stateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
  'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
    // upsert: safe to run multiple times; avoids UNIQUE constraint errors on reruns
    await prisma.inventoryItem.upsert({
      where: { sku: 'ABC-123' },
      create: { sku: 'ABC-123', available: 10, warehouseId: 'WH-001' },
      update: { available: 10, warehouseId: 'WH-001' },
    });
  },
  'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
    // deleteMany: safe when row may or may not exist
    await prisma.inventoryItem.deleteMany({
      where: { sku: 'UNKNOWN-999' },
    });
  },
  // Teardown state: called after verification with action: 'teardown'
  // In Prisma: wrap in a transaction to reset all seeded data atomically
  'teardown': async (): Promise<void> => {
    await prisma.$transaction([
      prisma.inventoryItem.deleteMany({ where: { sku: { in: ['ABC-123'] } } }),
    ]);
  },
};

describe('InventoryService provider verification (Prisma state handlers)', () => {
  let serverUrl: string;
  let closeServer: () => Promise<void>;

  beforeAll(async () => {
    await prisma.$connect();
    await new Promise<void>((resolve, reject) => {
      const server = createServer(app);
      server.listen(0, '127.0.0.1', () => {
        const { port } = server.address() as AddressInfo;
        serverUrl = `http://127.0.0.1:${port}`;
        closeServer = () => new Promise<void>((res, rej) => server.close((err) => (err ? rej(err) : res())));
        resolve();
      });
      server.on('error', reject);
    });
  });

  afterAll(async () => {
    await closeServer();
    await prisma.$disconnect();
  });

  it('satisfies all consumer pacts', async () => {
    const verifier = new VerifierV3({
      provider: 'InventoryService',
      providerBaseUrl: serverUrl,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }],
      stateHandlers,
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });
    await verifier.verifyProvider();
  });
});
```

**Drizzle ORM equivalent for state handlers:**

```typescript
// State handler using Drizzle ORM — insert-or-update pattern with conflict resolution
import { db } from '../src/db';
import { inventoryItems } from '../src/schema';
import { eq } from 'drizzle-orm';

const drizzleStateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
  'SKU ABC-123 exists with 10 units in stock': async (): Promise<void> => {
    // Drizzle: onConflictDoUpdate for idempotent upsert (PostgreSQL / SQLite)
    await db
      .insert(inventoryItems)
      .values({ sku: 'ABC-123', available: 10, warehouseId: 'WH-001' })
      .onConflictDoUpdate({
        target: inventoryItems.sku,
        set: { available: 10, warehouseId: 'WH-001' },
      });
  },
  'SKU UNKNOWN-999 does not exist': async (): Promise<void> => {
    await db.delete(inventoryItems).where(eq(inventoryItems.sku, 'UNKNOWN-999'));
  },
};
```

**Key points:**
- `upsert` (Prisma) / `onConflictDoUpdate` (Drizzle) makes state handlers **idempotent** — pact-js can call them multiple times if provider verification retries; a naive `insert` would throw a `UNIQUE` constraint error on the second call
- Never use `deleteAll` or `truncate` in state handlers without a clear scope — a truncate that clears a shared table corrupts parallel test runs or leaves the database in an unexpected state for subsequent interactions
- `prisma.$disconnect()` in `afterAll` is mandatory — leaving PrismaClient connections open causes Jest/Vitest to hang after test completion (`--forceExit` masks this, not fixes it)
- For Drizzle with SQLite (common in local dev and edge runtimes), `onConflictDoUpdate` requires the `better-sqlite3` driver to be set up with WAL mode to avoid write contention from parallel state handler calls

---

### Vitest 2.x Compatibility (TypeScript — pool and threading changes)

Vitest 2.0 (released June 2024) changed the default execution pool from `threads` to `forks`, which affects how Pact mock servers interact with the test runner.

```typescript
// vitest.config.ts — Pact-compatible config for Vitest 2.x
// Vitest 2.x default pool changed from 'threads' to 'forks'.
// Both PactV3 and PactV4 work with 'forks', but port allocation strategy differs.
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // For pact-js consumer tests: 'forks' (default in Vitest 2.x) is safe with PactV4
    // (auto-port). For PactV3 with fixed ports, use singleFork to prevent port collision.
    pool: 'forks',
    poolOptions: {
      forks: {
        // singleFork: run all pact test files in a single forked process.
        // Equivalent to maxWorkers: 1 in Jest — prevents port collision when using
        // PactV3 (fixed port). Not needed for PactV4 (auto-port).
        // Set to false if ALL your pact tests use PactV4 with no explicit port option.
        singleFork: true,
      },
    },
    testTimeout: 120_000,
    include: ['**/*.pact.spec.ts', '**/*.provider.pact.spec.ts'],
    exclude: ['node_modules', 'dist'],
  },
});
```

**Vitest 2.x pool migration guide:**

| Scenario | Vitest 1.x setting | Vitest 2.x equivalent | Notes |
|---|---|---|---|
| PactV3 consumer tests (fixed port) | `singleThread: true` | `pool: 'forks', singleFork: true` | `singleThread` was removed in Vitest 2.x |
| PactV4 consumer tests (auto-port) | Default (threads) | Default (forks) | Auto-port PactV4 is safe with any pool |
| Provider verification | `singleThread: true` | `pool: 'forks', singleFork: true` | Provider verification is stateful; run serially |

**Key points:**
- `singleThread: true` was removed in Vitest 2.x — replace with `pool: 'forks', poolOptions: { forks: { singleFork: true } }` for the same behavior
- The `threads` pool (Vitest 1.x default) ran all workers in a single Node.js process using `worker_threads`; the `forks` pool (Vitest 2.x default) spawns separate OS processes — pact-js's native binary FFI is more stable with `forks` because each fork has its own native module instance, eliminating the race condition that caused issue #1713 under `threads`
- PactV4 with auto-port assignment is the recommended upgrade path: no port configuration, no `singleFork` needed, parallelizable across forks

---

### Non-Deterministic Pact Files Anti-Pattern (TypeScript)

Pact files that contain different content on every run cause noise in version control diffs and in Pact Broker's deduplication logic. The most common sources of non-determinism:

```typescript
// ❌ ANTI-PATTERN: dynamic values without fixed examples
// Each test run produces a different pact file, causing spurious Broker webhook triggers
// and noisy git diffs.
import { v4 as uuidv4 } from 'uuid';
import { MatchersV3 } from '@pact-foundation/pact';

const { uuid, timestamp } = MatchersV3;

// BAD: uuid() without a fixed example generates a new UUID on every run
body: {
  id: uuid(),                          // ← generates new UUID each run: non-deterministic
  createdAt: timestamp('yyyy-MM-dd'),  // ← no fixed example: defaults to "now"
  requestId: like(uuidv4()),           // ← uuidv4() called at import time: changes each run
}

// ✅ CORRECT: always provide a fixed, fictional example value
body: {
  id: uuid('550e8400-e29b-41d4-a716-446655440000'),   // ← fixed example
  createdAt: timestamp('yyyy-MM-dd', '2025-01-15'),   // ← fixed example
  requestId: like('req-00000000-0000-0000-0000-000000000001'), // ← fixed fictional value
}
```

**Why non-deterministic pact files are harmful:**

1. **Pact Broker webhook flood**: `contract_content_changed` fires on every publish because the file content changes every run, even when no interaction has changed. This triggers provider verification runs that serve no purpose.
2. **CI diff noise**: `git diff` on pact files shows meaningless UUID and timestamp churn, making code review harder and causing false merge conflicts when two branches both update pact files.
3. **Broker deduplication breaks**: The Broker stores pact files by content hash; a changed UUID creates a new pact version entry, inflating storage and degrading query performance over time.
4. **`contract_requiring_verification_published` (Pact Broker 2.82.0+)** partially mitigates this by deduplicating on provider version — but only for the webhook trigger, not for storage or diff noise.

**Checklist for deterministic pact files:**
- All `uuid()` matchers: provide a fixed UUID example string
- All `timestamp()` matchers: provide a fixed date string in the correct format
- All `like(value)` calls: use a hard-coded string/number, not a dynamically generated value
- Never call `Date.now()`, `new Date()`, `crypto.randomUUID()`, or any PRNG in pact body definitions
- Commit pact files to version control (optional but useful) — non-determinism surfaces immediately in `git diff`

---

### Additional Community Production Lessons [community]

42. **[community] tRPC's compile-time safety does not replace CDC when consumer and provider live in separate repositories.** Teams that adopt tRPC within a monorepo correctly gain end-to-end type inference for free — `inferRouterOutputs<AppRouter>` enforces that the consumer's TypeScript code matches the provider's route return type at compile time. When those same teams extract services into separate repos (common during scaling), they assume tRPC's safety still holds. It does not: without a shared `AppRouter` type, tRPC clients silently fall back to `unknown` types and the HTTP body format is opaque. CDC at the HTTP layer (using Pact HTTP interactions against `/trpc/<procedure>` endpoints) fills this gap. The rule: if you cannot `import type { AppRouter } from '../provider'` without crossing a repo boundary, you need CDC.

43. **[community] ORM state handlers without proper teardown cause intermittent provider verification failures.** Teams that set up test data in Prisma or Drizzle state handlers but skip teardown accumulate stale rows in the test database. This causes unique constraint violations on the second verification run (if the previous run left a row with a conflicting primary key) and causes state-dependent tests to pass or fail depending on execution order. The fix: make every `setup` state handler idempotent (use `upsert` / `onConflictDoUpdate` rather than `insert`) AND implement teardown handlers that clean up every row created during setup. Pact calls state handlers with `action: 'teardown'` after each interaction; only register teardown handlers for states that modify persistent data.

44. **[community] Vitest 2.x `pool: 'threads'` was removed silently for most Vitest config users.** Projects that upgraded from Vitest 1.x to Vitest 2.x with a `singleThread: true` setting in `vitest.config.ts` found that the option was silently ignored — Vitest 2.x removed `singleThread` and changed the default pool to `forks`. Pact consumer tests that relied on `singleThread: true` for PactV3 port safety started failing with EADDRINUSE errors intermittently. The upgrade checklist: (1) replace `singleThread: true` with `pool: 'forks', poolOptions: { forks: { singleFork: true } }`, or (2) migrate to PactV4 (which uses auto-port assignment and does not need serial execution). Check for Vitest 2.x deprecation warnings during `npm update` — the removed option does not cause an error, only a silent no-op.

45. **[community] Dynamic example values in pact files trigger redundant webhook builds and inflate Pact Broker storage.** A common setup mistake: teams call `like(uuidv4())` or `like(new Date().toISOString())` in pact body definitions. Since these values change on every test run, the pact file content hash changes on every consumer CI run. The `contract_content_changed` webhook event fires every time, triggering provider verification even though no actual interaction changed. At scale (10 consumer services × 20 builds/day), this generates 200 unnecessary provider CI runs per day. The fix is deterministic examples: always use hard-coded fictional values (`like('550e8400-e29b-41d4-a716-446655440000')` instead of `like(uuidv4())`). The `contract_requiring_verification_published` event (Pact Broker 2.82.0+) partially mitigates the webhook flood but does not fix the storage inflation or git diff noise.

46. **[community] CRUD services generate interaction count explosions without a composition strategy.** A provider with full CRUD (Create, Read, Update, Delete, List, List-with-filters) on five resources quickly accumulates 30+ interactions per consumer. With three consumers, that is 90+ interactions to verify, each requiring a state handler and database seed. Provider verification time scales linearly with interaction count. Prevention strategies: (1) group related interactions into a single `it` block using `executeTest` with multiple `addInteraction` calls (within one pact-js session, multiple interactions can be registered before `executeTest`); (2) for list-with-filters, use a single interaction with broad matchers rather than one interaction per filter combination; (3) use `filterConsumerNames` in `VerifierV3` options to run verification for one consumer at a time in separate CI shards; (4) promote stable, schema-only providers to BDCT (OpenAPI spec + PactFlow) so consumer CDC interactions only cover the fields the consumer actually reads, not the full API surface.

---

### `constrainedArrayLike` — Bounded Array Contracts (TypeScript)

For APIs that enforce size constraints on array responses (e.g., paginated endpoints with a maximum page size, or APIs that return at least one item but cap at a configurable limit), `constrainedArrayLike` is more precise than `eachLike` or `atLeastOneLike`.

```typescript
// notifications-feed.consumer.pact.spec.ts
// Demonstrates constrainedArrayLike for APIs with hard min/max array bounds.
// Use case: a notification feed that always returns ≥1 item and at most 20 items per page.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { NotificationClient } from '../src/notification-client';

// Import the full set of array matchers — atMostLike and constrainedArrayLike
// are available from MatchersV3 alongside eachLike and atLeastOneLike
const {
  constrainedArrayLike,
  atMostLike,
  like,
  string,
  integer,
  boolean: boolMatch,
} = MatchersV3;

interface Notification {
  id: string;
  type: string;
  message: string;
  read: boolean;
}

interface NotificationPage {
  items: Notification[];
  hasMore: boolean;
  totalUnread: number;
}

const provider = new PactV3({
  consumer: 'DashboardUI',
  provider: 'NotificationService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8097,
  logLevel: 'warn',
});

describe('DashboardUI → NotificationService contract (bounded arrays)', () => {
  it('returns a bounded notification page (1–20 items, enforced by API contract)', async () => {
    await provider
      .given('user has 3 unread notifications')
      .uponReceiving('a request for the first notification page (page_size=20)')
      .withRequest({
        method: 'GET',
        path: '/notifications',
        query: { page_size: '20' },
        headers: { Accept: 'application/json' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          // constrainedArrayLike(min, max, shape):
          // - min=1: the API guarantees at least 1 item when the user has notifications
          // - max=20: the API never returns more than page_size items
          // Use when the API contract explicitly documents array size bounds.
          // Use eachLike when only a lower bound (≥1) is meaningful.
          items: constrainedArrayLike(1, 20, {
            id: string('NOTIF-001'),
            type: like('order_shipped'),
            message: like('Your order has shipped'),
            read: boolMatch(false),
          }),
          hasMore: boolMatch(false),
          totalUnread: integer(3),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new NotificationClient(mockServer.url);
        const page: NotificationPage = await client.getNotifications({ page_size: 20 });
        expect(page.items.length).toBeGreaterThanOrEqual(1);
        expect(page.items.length).toBeLessThanOrEqual(20);
        expect(page.totalUnread).toBeGreaterThanOrEqual(0);
      });
  });

  it('returns at most 5 notifications for a preview widget', async () => {
    await provider
      .given('user has 10 notifications')
      .uponReceiving('a request for notification preview (page_size=5)')
      .withRequest({
        method: 'GET',
        path: '/notifications',
        query: { page_size: '5' },
        headers: { Accept: 'application/json' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          // atMostLike(shape, max): array with at most max items.
          // Use when only the upper bound matters (no guaranteed minimum).
          items: atMostLike(
            { id: string('NOTIF-001'), type: like('order_shipped'), message: like('msg'), read: boolMatch(false) },
            5
          ),
          hasMore: boolMatch(true),
          totalUnread: integer(10),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new NotificationClient(mockServer.url);
        const page = await client.getNotifications({ page_size: 5 });
        expect(page.items.length).toBeLessThanOrEqual(5);
      });
  });
});
```

**Array matcher selection guide:**

| Situation | Matcher | Semantics |
|---|---|---|
| Array with at least 1 item, no upper bound | `eachLike(shape)` | ≥1, unbounded |
| Array with at least N items | `atLeastOneLike(shape, N)` | ≥N, unbounded |
| Array with at most N items | `atMostLike(shape, N)` | ≤N, unbounded minimum |
| Array with exactly min..max items | `constrainedArrayLike(min, max, shape)` | ≥min, ≤max |
| Array must contain specific items (subset check) | `arrayContaining([...])` | Ordered subset match |
| Fixed-length tuple | `[like(x), like(y)]` | Exact length; each element matched |

---

### `InterfaceToTemplate<T>` — TypeScript Type Compatibility Utility

`pact-js` exports `InterfaceToTemplate<T>` to resolve TypeScript type errors that arise when building a Pact response body from a TypeScript interface. The pact body uses `MatchersV3` matcher types (e.g., `AnyTemplate`, `MatchersV3.Type`) which are not always assignable to a plain interface type, causing `TS2322` errors on the `body:` property.

```typescript
// typed-pact-body.consumer.pact.spec.ts
// Demonstrates InterfaceToTemplate<T> to avoid TS2322 errors when constructing
// pact body objects from TypeScript interfaces.
import path from 'path';
import { PactV3, MatchersV3, InterfaceToTemplate } from '@pact-foundation/pact';
import { InventoryClient } from '../src/inventory-client';

const { like, string, integer, eachLike, regex } = MatchersV3;

// The consumer's TypeScript interface for the expected response
interface StockSummary {
  sku: string;
  available: number;
  reserved: number;
  warehouseId: string;
  items: Array<{ location: string; count: number }>;
}

// Without InterfaceToTemplate, this line produces TS2322:
// Type '{ sku: PactV3Type; available: PactV3Type; ... }' is not assignable
// to type 'StockSummary' because 'sku' expects 'string' not 'PactV3Type'.

// WITH InterfaceToTemplate<T>: wraps each interface field in an AnyTemplate union,
// making the compiler accept MatchersV3 values in place of concrete types.
const stockSummaryBody: InterfaceToTemplate<StockSummary> = {
  sku: string('ABC-123'),
  available: integer(10),
  reserved: integer(2),
  warehouseId: regex(/^WH-\d{3}$/, 'WH-001'),
  items: eachLike({ location: like('SHELF-A1'), count: integer(5) }),
};

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8098,
  logLevel: 'warn',
});

describe('OrderService → InventoryService contract (InterfaceToTemplate)', () => {
  it('returns a typed stock summary', async () => {
    await provider
      .given('SKU ABC-123 has stock data')
      .uponReceiving('a stock summary request for SKU ABC-123')
      .withRequest({
        method: 'GET',
        path: '/inventory/ABC-123/summary',
        headers: { Accept: 'application/json' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: stockSummaryBody,    // ← no TS2322 error with InterfaceToTemplate
      })
      .executeTest(async (mockServer) => {
        const client = new InventoryClient(mockServer.url);
        const result: StockSummary = await client.getStockSummary('ABC-123');
        expect(result.available).toBeGreaterThanOrEqual(0);
        expect(result.items.length).toBeGreaterThanOrEqual(1);
      });
  });
});
```

**Key points:**
- `InterfaceToTemplate<T>` is a mapped type that replaces each property type `P` in `T` with `P | AnyTemplate` — the TypeScript compiler accepts both the concrete type and any `MatchersV3` value in its place
- Import it directly from `@pact-foundation/pact`: `import { InterfaceToTemplate } from '@pact-foundation/pact'`
- Use it on the `const` that holds the pact body shape, not on the `willRespondWith` `body:` property itself — this keeps type inference intact
- **Limitation:** `InterfaceToTemplate<T>` does not enforce that every field in `T` is present in the body object — it only resolves assignability errors. The `Record<keyof T, unknown>` pattern (from the Contract Evolution section) is stricter and preferred when completeness matters
- **When NOT to use it:** If a `TS2322` error appears in the pact body, the first question should be "is this matcher correct?" — type errors often indicate a mismatch between the interface and the matcher. `InterfaceToTemplate` should be a last resort, not a first fix

---

### Additional Community Production Lessons [community]

47. **[community] Each `executeTest()` call in pact-js V4 creates a new mock server session — multiple `addInteraction()` calls before one `executeTest()` is the correct pattern for multi-step workflows, not chaining `executeTest()` calls.** Teams writing multi-step consumer workflows (e.g., create then fetch) often chain `executeTest` calls sequentially: `await provider.addInteraction(...).executeTest(...)` then `await provider.addInteraction(...).executeTest(...)`. Each `executeTest` call starts and stops the mock server, so the second call runs against a fresh server that has no knowledge of the first interaction. The correct pattern for recording multiple interactions in a single pact session is to call `addInteraction()` multiple times before a single `executeTest()` — all registered interactions are available to the mock server for the duration of that one `executeTest` call. Using separate `executeTest` calls (one per interaction) is correct when each interaction is an independent test case (one `it` block, one `executeTest`) — the confusion arises when teams want to test a workflow that genuinely chains two calls.

48. **[community] `constrainedArrayLike` is under-used for APIs with documented size limits, leading to overly permissive contracts.** Teams that know their API enforces a maximum page size (e.g., `GET /notifications?page_size=20` never returns more than 20 items) routinely use `eachLike` instead of `constrainedArrayLike(1, 20, shape)`. The consequence: the consumer's pact does not enforce the upper bound, so a provider that accidentally returns 200 items (buffer overflow, off-by-one in pagination logic) will pass provider verification. `constrainedArrayLike` is specifically designed for this case — it encodes both the minimum guarantee (the provider always returns at least one item when state is set up) and the maximum contract (the provider never exceeds the page size). Use it whenever the API spec documents a maximum array length.

49. **[community] `InterfaceToTemplate<T>` silently relaxes completeness checking — teams use it to silence TS2322 errors without realizing the body is now missing required fields.** `InterfaceToTemplate<T>` makes all interface fields optional from TypeScript's perspective (each field becomes `field?: P | AnyTemplate`). Teams that import it to suppress type errors sometimes end up with pact bodies that are missing required fields — the TypeScript compiler no longer complains that `reservedQuantity` is absent because the mapped type treats it as optional. The contract then tests fewer fields than the interface defines, giving a false sense of coverage. **Safer alternative:** use `Record<keyof StockSummary, unknown>` on the body const — this enforces that every key in the interface appears in the body while still accepting `MatchersV3` values. Reserve `InterfaceToTemplate<T>` for bodies with deeply nested types where the key-completeness check is impractical.

---

### The Bug Catcher Rule — Interaction Inclusion Decision Framework (TypeScript)

The official Pact consumer documentation formalizes a principle for deciding whether an interaction belongs in a pact file: **"If I don't include this scenario, what specific bug in the consumer or misunderstanding about the provider API could go undetected?"** If the answer is "none," the interaction adds maintenance cost without value.

```typescript
// bug-catcher-rule-examples.consumer.pact.spec.ts
// Demonstrates how to apply the Bug Catcher Rule to decide which interactions to include.
// Each interaction is annotated with its bug-catching justification.
import path from 'path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrderClient } from '../src/order-client';

const { like, string, integer } = MatchersV3;

const provider = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  port: 8099,
  logLevel: 'warn',
});

describe('OrderService → InventoryService (Bug Catcher Rule applied)', () => {
  // ✅ INCLUDE: catches a misunderstanding about the response shape.
  // If warehouseId is removed from the provider response, this consumer's
  // routing logic silently uses undefined. Bug is real; test catches it.
  it('GET /inventory/:sku — includes warehouseId field the consumer routes on', async () => {
    await provider
      .given('SKU ABC-123 exists in warehouse WH-001')
      .uponReceiving('a stock request where the consumer needs warehouseId for routing')
      .withRequest({ method: 'GET', path: '/inventory/ABC-123' })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          sku: string('ABC-123'),
          available: integer(10),
          // ← Bug catcher: consumer's routing logic reads this field; its absence would
          //   silently route to a default warehouse instead of failing fast.
          warehouseId: like('WH-001'),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new OrderClient(mockServer.url);
        const result = await client.getStock('ABC-123');
        expect(result.warehouseId).toBeDefined();  // ← the assertion that catches the bug
      });
  });

  // ✅ INCLUDE: catches the consumer not handling 404 gracefully.
  // Without this, the consumer code could throw an unhandled exception on 404
  // instead of returning a "not available" state to its caller.
  it('GET /inventory/:sku — 404 path catches consumer error handling', async () => {
    await provider
      .given('SKU UNKNOWN-999 does not exist')
      .uponReceiving('a stock request for a non-existent SKU')
      .withRequest({ method: 'GET', path: '/inventory/UNKNOWN-999' })
      .willRespondWith({ status: 404 })
      .executeTest(async (mockServer) => {
        const client = new OrderClient(mockServer.url);
        // ← Bug catcher: verifies consumer converts 404 to domain error, not unhandled promise rejection
        await expect(client.getStock('UNKNOWN-999')).rejects.toThrow('Stock not found');
      });
  });

  // ❌ DO NOT INCLUDE: this interaction tests a provider business rule (quantity validation),
  // not a consumer-side behaviour. If the provider relaxes the limit from 100 to 1000,
  // this test breaks — but the consumer's code is completely unaffected.
  // Remove it: the provider's own functional test suite owns this rule.
  //
  // it('GET /inventory/:sku — tests that provider enforces qty < 100 limit', async () => { ... });

  // ❌ DO NOT INCLUDE: this interaction tests every permutation of query parameters.
  // The consumer sends the same request structure regardless of filter values.
  // One parameterized test proves the request is constructed correctly.
  // Duplicating it for 5 filter values adds 4 interactions with zero additional bug detection.
});
```

**Decision checklist before adding a new interaction:**

| Question | If Yes → | If No → |
|---|---|---|
| Does the consumer code read a specific response field? | Include the field with an appropriate matcher | Omit the field from the pact body |
| Does the consumer handle this error status differently from other errors? | Include the status code interaction | Omit — one generic 4xx interaction is sufficient |
| Does removing this interaction hide a real consumer bug? | Include the interaction | Remove or merge it |
| Does this interaction test a provider validation rule the consumer doesn't enforce? | Remove — belongs in provider tests | Include if the consumer renders the error message |
| Is this interaction identical to an existing one with a different parameter value? | Consider a single parameterized interaction | Include if the parameter drives different consumer code paths |

**BDD-style scenario naming that satisfies the Bug Catcher Rule:**

The official Pact consumer guide recommends forming interaction names as a **natural-language sentence** combining the provider state, request description, and response to improve Broker UI readability and prevent duplicate description collisions:

```typescript
// BAD: generic, collision-prone, doesn't capture WHY
.given('a product exists')
.uponReceiving('a request for a product')

// GOOD: specific, self-documenting, matches the bug it catches
.given('product PROD-42 exists with price $29.99')
.uponReceiving('a GET /products/PROD-42 request for the product price display')
// Natural-language sentence: "Given product PROD-42 exists with price $29.99,
//   upon receiving a GET /products/PROD-42 request for the product price display,
//   the consumer expects a 200 response with id, name, and price fields."
```

The combination of `given` + `uponReceiving` forms a unique key in the Pact Broker — using scenario-specific strings eliminates the silent de-duplication overwrite problem (community lesson #40).

---

### V4 Status Code Class Matching (TypeScript — `statusCode` matcher)

Pact V4 introduced a `statusCode` matching rule that accepts semantic class names (`'success'`, `'redirect'`, `'clientError'`, `'serverError'`, `'nonError'`) rather than exact status codes. This eliminates unnecessary provider states when the consumer only cares about the *class* of response, not the exact code.

**Status code classes:**

| Class name | Matches | Use when |
|---|---|---|
| `'success'` | 200–299 | Consumer handles any 2xx the same way |
| `'redirect'` | 300–399 | Consumer follows any redirect |
| `'clientError'` | 400–499 | Consumer shows a generic "bad request" error |
| `'serverError'` | 500–599 | Consumer shows a retry or error boundary |
| `'nonError'` | 100–399 | Consumer only branches on error vs. non-error |

```typescript
// inventory-status-class.consumer.pact.spec.ts
// Demonstrates V4 statusCode class matching using the PactV4/Pact DSL.
// Use case: consumer shows a generic "unavailable" state for any 5xx response,
// making the exact status code (500, 502, 503, 504) irrelevant to the contract.
import path from 'path';
import { Pact, Matchers } from '@pact-foundation/pact';
import { InventoryClient } from '../src/inventory-client';

const { like } = Matchers;

const provider = new Pact({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
  // V4: no port — auto-assigned
});

describe('OrderService → InventoryService (V4 statusCode class matching)', () => {
  it('handles any 5xx server error as "service unavailable"', async () => {
    await provider
      .addInteraction()
      .given('InventoryService is experiencing a server error')
      .uponReceiving('a stock request during a server error condition')
      .withRequest('GET', '/inventory/ABC-123', (builder) => {
        builder.headers({ Accept: 'application/json' });
      })
      .willRespondWith(500, (builder) => {
        // statusCode class matcher: matches any status in 500-599
        // The builder's first argument (500) is the example; the matcher overrides it at verification.
        builder.statusCode('serverError');
        // Optional: match the body shape too — any error response body the consumer reads
        builder.jsonBody({
          message: like('Internal server error'),
        });
      })
      .executeTest(async (mockServer) => {
        const client = new InventoryClient(mockServer.url);
        // Consumer should throw a ServiceUnavailableError for any 5xx, not just 500
        await expect(client.getStock('ABC-123')).rejects.toThrow('ServiceUnavailable');
      });
  });

  it('handles any 4xx client error as "bad request" without specific validation details', async () => {
    await provider
      .addInteraction()
      .given('InventoryService rejects the request as invalid')
      .uponReceiving('a stock request with an invalid SKU format')
      .withRequest('GET', '/inventory/!!invalid!!', (builder) => {
        builder.headers({ Accept: 'application/json' });
      })
      .willRespondWith(400, (builder) => {
        // statusCode class matcher: matches any status in 400-499
        // Use this when the consumer renders a generic "invalid request" UI regardless of 400/404/422.
        builder.statusCode('clientError');
      })
      .executeTest(async (mockServer) => {
        const client = new InventoryClient(mockServer.url);
        await expect(client.getStock('!!invalid!!')).rejects.toThrow('InvalidRequest');
      });
  });
});
```

**Key points:**
- `builder.statusCode('serverError')` in the `willRespondWith` callback uses the V4 `statusCode` matching rule — the numeric argument to `willRespondWith(500, ...)` is the example value used in the consumer test; the class matcher is applied at provider verification
- `statusCode('success')` is particularly useful when a provider legitimately returns `200` or `201` or `204` for the same logical operation depending on context — instead of writing separate interactions for each, use one interaction with class matching and test the consumer's response-parsing code once
- This feature is only available in the V4 DSL (`Pact` / `PactV4` class with `addInteraction()` builder) — it is NOT available in `PactV3`
- Avoid using `statusCode('nonError')` for success cases — be explicit with `statusCode('success')` so the contract documents intent clearly
- The `statusCode` class matcher is an **open issue** in pact-js as a formal fluent API method (issue #1600); the builder callback pattern shown above is the recommended approach in V4. If the class matcher API is not yet available in your pact-js version, use `withMatchingRules` directly:

```typescript
// Fallback for versions where builder.statusCode() is not yet exposed:
.willRespondWith(500, (builder) => {
  builder.withMatchingRules({
    status: { matchers: [{ match: 'statusCode', status: 'serverError' }] },
  });
})
```

---

### mTLS / Client Certificate Provider Verification (TypeScript)

Providers that require mutual TLS (mTLS) authentication — where both the client and server present certificates — cannot be verified with the standard `VerifierV3` setup, which does not expose TLS client certificate configuration. This is an open issue in pact-js (issue #1509: "Unable to pass client certificate from pact-js verifier").

**Current workarounds (as of pact-js v16.4):**

**Option 1 — TLS-terminating reverse proxy (recommended)**

Start the provider test server behind a local reverse proxy (nginx, caddy, or a custom Node.js `https.createServer`) that handles TLS termination. The Pact verifier communicates with the proxy over plain HTTP; the proxy handles client certificates upstream.

```typescript
// inventory-service.mtls.provider.pact.spec.ts
// Workaround for pact-js issue #1509: mTLS provider verification.
// Uses a TLS-terminating proxy so the Pact verifier connects over plain HTTP.
import { VerifierV3, VerifierOptions } from '@pact-foundation/pact';
import { createServer as createHttpServer } from 'http';
import { createServer as createHttpsServer } from 'https';
import { readFileSync } from 'fs';
import { AddressInfo } from 'net';
import { app } from '../src/app';

// 1. Start the real provider over plain HTTP (no TLS) on an internal port.
//    The Pact verifier connects to this port directly.
//    If the real provider ONLY accepts mTLS, wrap it in a proxy as shown below.
async function startPlainHttpServer(): Promise<{ url: string; close: () => Promise<void> }> {
  return new Promise((resolve, reject) => {
    const server = createHttpServer(app);
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address() as AddressInfo;
      resolve({
        url: `http://127.0.0.1:${port}`,
        close: () => new Promise<void>((res, rej) => server.close((err) => (err ? rej(err) : res()))),
      });
    });
    server.on('error', reject);
  });
}

describe('InventoryService provider verification (mTLS workaround)', () => {
  let serverUrl: string;
  let closeServer: () => Promise<void>;

  beforeAll(async () => {
    const server = await startPlainHttpServer();
    serverUrl = server.url;
    closeServer = server.close;
  });

  afterAll(async () => {
    await closeServer();
  });

  it('satisfies all consumer pacts via plain HTTP proxy', async () => {
    const stateHandlers: NonNullable<VerifierOptions['stateHandlers']> = {
      'SKU ABC-123 exists with 10 units in stock': async () => { /* seed */ },
    };

    const verifier = new VerifierV3({
      provider: 'InventoryService',
      // The verifier connects to the plain HTTP server — no mTLS required here.
      // In production, the app is fronted by a load balancer or API gateway that handles mTLS;
      // the test server is the app itself without TLS (appropriate for local/CI verification).
      providerBaseUrl: serverUrl,
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      consumerVersionSelectors: [{ mainBranch: true }, { deployedOrReleased: true }],
      stateHandlers,
      publishVerificationResult: process.env.PUBLISH_VERIFICATION_RESULTS === 'true',
      providerVersion: process.env.GIT_COMMIT,
      providerVersionBranch: process.env.GIT_BRANCH,
    });

    await verifier.verifyProvider();
  });
});
```

**Option 2 — `requestFilter` to inject client certificates as headers**

If the provider validates client identity via a certificate-derived header (common in Kubernetes service mesh environments where mTLS is handled by the mesh and forwarded as a header):

```typescript
// Use requestFilter to inject the client identity header that mTLS would provide.
// This works when the provider validates X-Client-Cert-Subject or similar headers,
// not raw TLS handshakes.
const verifier = new VerifierV3({
  // ...
  requestFilter: (req, _res, next) => {
    // Inject the client certificate subject as a header (service mesh pattern).
    // The provider validates this header instead of a raw TLS certificate.
    req.headers['X-Client-Cert-Subject'] = 'CN=pact-verifier,O=TestOrg';
    next();
  },
});
```

**When mTLS verification is unavoidable:**
- If the provider cannot be started without TLS, use the Pact CLI (`pact-provider-verifier`) directly rather than pact-js `VerifierV3` — the CLI binary supports `--client-cert` and `--client-key` flags
- Track issue #1509 for native pact-js support: once resolved, `VerifierV3` will accept `tlsClientCert` and `tlsClientKey` options

---

### `ConsumerVersionSelector` `fallbackBranch` TypeScript Type Gap (pact-js ≤ v16.4)

The Pact Broker supports a `fallbackBranch` property on consumer version selectors, allowing verification to fall back to a different branch if the specified branch has no pacts. This is essential during feature branch development — without `fallbackBranch`, a provider verifying against a consumer feature branch that doesn't exist yet returns "unknown" instead of safely falling back to `main`.

**The type gap:** In pact-js v13–v16.4, `ConsumerVersionSelector` does not declare `fallbackBranch` in its TypeScript type definition (issue #1418). The property works at runtime but produces a TypeScript compile error unless you cast around the type.

```typescript
// consumer-version-selectors.ts — typed workaround for fallbackBranch gap
import { ConsumerVersionSelector } from '@pact-foundation/pact';

// Extend the official type to include fallbackBranch until pact-js fixes #1418.
// Keep this file — when pact-js adds fallbackBranch to ConsumerVersionSelector,
// remove the extension and the as-cast below; tsc will tell you when it's safe.
type ConsumerVersionSelectorWithFallback = ConsumerVersionSelector & {
  fallbackBranch?: string;
};

// PRODUCTION-READY: selectors that cover all important cases plus feature branch safety
const selectors: ConsumerVersionSelectorWithFallback[] = [
  { mainBranch: true },
  { deployedOrReleased: true },
  // During feature branch development: verify against the consumer's feature branch,
  // falling back to main if the branch has no pacts yet.
  // Remove this selector once the feature branch merges.
  {
    branch: process.env.CONSUMER_BRANCH ?? 'main',
    fallbackBranch: 'main',
  } as ConsumerVersionSelectorWithFallback,
];

// Pass to VerifierV3 — the as-cast to ConsumerVersionSelector[] is necessary
// until pact-js #1418 is resolved (the runtime behavior is correct).
export const productionSelectors = selectors as ConsumerVersionSelector[];

// Usage in provider verification:
// const verifier = new VerifierV3({
//   ...
//   consumerVersionSelectors: productionSelectors,
// });
```

**Key points:**
- The `fallbackBranch` property is fully supported by the Pact Broker at runtime — it is only the TypeScript type definition in pact-js that is missing it (issue #1418 filed as an enhancement)
- The `as ConsumerVersionSelectorWithFallback` cast is safe because the pact-js native binary passes the selector object as-is to the Broker API; unknown properties are ignored by the TypeScript runtime but passed through to the HTTP call
- Set `CONSUMER_BRANCH` in CI from the triggering consumer's branch name (available via `${pactbroker.consumerVersionBranch}` in the webhook payload) — this allows the provider to verify the exact consumer branch that triggered the webhook

---

### Additional Community Production Lessons [community]

50. **[community] Five structural reasons contract testing initiatives fail — and how to prevent them.** PactFlow's production data across hundreds of organizations identifies five patterns that consistently cause Pact adoption to stall or be abandoned: (1) **scope creep** — teams try to replace all integration tests with Pact in one sprint, creating too much churn; fix: add CDC incrementally, starting with one consumer/provider pair; (2) **lack of organizational buy-in** — providers refuse to run verification because they weren't part of the adoption decision; fix: negotiate Pact Nirvana level goals cross-team before writing any tests; (3) **maintenance burden underestimated** — state handler upkeep is scoped as a one-time cost; fix: explicitly plan for 30-min/new-interaction ongoing maintenance in sprint capacity; (4) **learning curve not addressed** — teams try to learn Pact, the Broker, and CI integration simultaneously; fix: start with local pact file generation only (Nirvana Level 3) before introducing the Broker; (5) **verification results not published** — teams generate pact files but never set `publishVerificationResult: true` in CI, so `can-i-deploy` has no data to gate on. The single most impactful first action for at-risk adoption: publish the first verification result to the Broker within the first week.

51. **[community] BDD-style scenario naming with `given` + `uponReceiving` as a natural-language sentence prevents two classes of problems simultaneously.** Using descriptive, scenario-specific strings for both `.given()` and `.uponReceiving()` (e.g., `'given product PROD-42 has zero stock, upon receiving a reserve request, the consumer expects a 409 with availableQuantity=0'`) produces two benefits that generic names (`'product exists'`, `'reserve request'`) do not: (a) the unique description string prevents the Pact Broker's silent de-duplication overwrite (community lesson #40) — if two tests produce the same `(description, providerState)` tuple, the second overwrites the first; (b) the Pact Broker UI becomes self-documenting, showing the intent of each interaction without requiring developers to read the test code. The overhead is one well-named `it()` block per interaction — this is the same discipline as descriptive unit test names, not additional work.

52. **[community] V4 statusCode class matching eliminates unnecessary provider states for error contracts.** A common but wasteful pattern: teams write separate provider states for every HTTP error a consumer might receive — `'given service returns 500'`, `'given service returns 502'`, `'given service returns 503'` — each requiring its own state handler. The provider tests run 3x longer to verify the same consumer behavior: "show a generic error boundary for any 5xx." Pact V4's `statusCode('serverError')` class matcher collapses these into a single interaction: one state (`'given InventoryService is unavailable'`), one state handler, one interaction. If the provider legitimately returns different 5xx codes in different failure modes, CDC is not the right tool — a thin integration smoke test that verifies each failure mode's actual behavior is more appropriate.

53. **[community] mTLS provider verification requires the test server to run without TLS, which sometimes conflicts with the provider's initialization logic.** Providers that enforce mTLS at the application layer (not the load balancer) — where `express.Request.socket.getPeerCertificate()` is called in middleware — cannot be correctly tested by the pact-js verifier because the verifier connects over plain HTTP and no client certificate is presented. The plain HTTP workaround (Option 1 above) causes these providers to reject every request with a 401 or 403 in the middleware. The correct fix for such providers is to wrap the TLS validation middleware in an environment check: `if (process.env.NODE_ENV !== 'pact-test') { /* validate cert */ }` — this is the same pattern used for disabling auth middleware in unit tests. Track issue #1509 for native TLS support in the pact-js verifier, which would eliminate the need for this workaround entirely.

---

### Multipart Form Data / File Upload Contract Testing (TypeScript — V4 DSL)

File upload endpoints are frequently skipped in CDC because teams assume only JSON bodies can be contract-tested. Pact V4's `multipartBody()` and `binaryFile()` builder methods enable contract testing of `multipart/form-data` requests — useful for any consumer that uploads images, documents, or mixed-content payloads.

The `multipartBody()` method is the simpler path for typical file uploads (single part, text or binary). For complex payloads with metadata + binary parts, use `binaryFile()` with explicit `withMatchingRules`.

```typescript
// file-upload.consumer.pact.spec.ts
// Contract for a multipart/form-data file upload endpoint.
// Uses Pact V4's multipartBody() builder — available on the addInteraction() DSL.
import path from 'path';
import { Pact, Matchers, SpecificationVersion } from '@pact-foundation/pact';
import FormData from 'form-data';
import axios from 'axios';
import fs from 'fs';

const { like } = Matchers;

// Path to a small test fixture file committed alongside the test
const testFilePath = path.resolve(__dirname, './fixtures/test-upload.txt');

// Use Pact (V4 alias) — multipartBody() is only available on the V4 DSL addInteraction() builder.
// SpecificationVersion.SPECIFICATION_VERSION_V4 explicitly pins the spec version in the pact file.
const provider = new Pact({
  consumer: 'DocumentService',
  provider: 'StorageService',
  dir: path.resolve(process.cwd(), 'pacts'),
  spec: SpecificationVersion.SPECIFICATION_VERSION_V4,
  logLevel: 'warn',
  // V4: no port — auto-assigned
});

describe('DocumentService → StorageService contract (file upload)', () => {
  it('uploads a text file via multipart form data', async () => {
    await provider
      .addInteraction()
      .given('StorageService is ready to accept uploads')
      .uponReceiving('a POST /upload request with a text file attachment')
      .withRequest('POST', '/upload', (builder) => {
        // multipartBody(contentType, filePath, mimePartName, boundary?)
        // contentType: MIME type of the file part
        // filePath: absolute path to a test fixture file
        // mimePartName: the form field name (matches FormData.append key)
        builder.multipartBody('text/plain', testFilePath, 'file');
      })
      .willRespondWith(200, (builder) => {
        builder.jsonBody({
          fileId: like('FILE-abc123'),
          size: like(1024),
          status: like('uploaded'),
        });
      })
      .executeTest(async (mockServer) => {
        const form = new FormData();
        form.append('file', fs.createReadStream(testFilePath));
        const response = await axios.post(`${mockServer.url}/upload`, form, {
          headers: form.getHeaders(),
        });
        expect(response.data.fileId).toBeDefined();
        expect(response.data.status).toBe('uploaded');
      });
  });
});
```

**For complex multipart requests (metadata + binary file)** — use `binaryFile()` with `matchingRules`:

```typescript
// image-upload.consumer.pact.spec.ts
// Complex multipart: JSON metadata part + binary image part.
// Uses binaryFile() with explicit matching rules on Content-Type header and body parts.
import path from 'path';
import { Pact, Matchers, SpecificationVersion } from '@pact-foundation/pact';
import FormData from 'form-data';
import axios from 'axios';
import fs from 'fs';

const { like, regex } = Matchers;

const boundary = '----PactTestBoundary123';
const testImagePath = path.resolve(__dirname, './fixtures/test-image.jpg');
// Create a minimal multipart body fixture for the pact body record
const multipartFixturePath = path.resolve(__dirname, './fixtures/image-upload.bin');

const provider = new Pact({
  consumer: 'GalleryApp',
  provider: 'ImageService',
  dir: path.resolve(process.cwd(), 'pacts'),
  spec: SpecificationVersion.SPECIFICATION_VERSION_V4,
  logLevel: 'warn',
});

describe('GalleryApp → ImageService contract (complex multipart)', () => {
  it('uploads an image with metadata', async () => {
    await provider
      .addInteraction()
      .given('ImageService is ready to accept image uploads')
      .uponReceiving('a POST /images request with a JPEG image and metadata')
      .withRequest('POST', '/images', (builder) => {
        builder
          .headers({
            // Explicit Content-Type with boundary — matched by regex at verification
            'Content-Type': `multipart/form-data; boundary=${boundary}`,
          })
          // binaryFile: records the raw multipart body bytes from a fixture file.
          // At provider verification, the body bytes are replayed and matched.
          .binaryFile(
            `multipart/form-data; boundary=${boundary}`,
            multipartFixturePath
          )
          .matchingRules({
            body: [
              {
                // Match the image part by content type, not by byte-exact content
                path: '$.image',
                rules: [Matchers.contentType('image/jpeg')],
              },
            ],
            header: [
              {
                path: 'Content-Type',
                rules: [
                  regex(
                    'multipart/form-data;\\s*boundary=.*',
                    `multipart/form-data; boundary=${boundary}`
                  ),
                ],
              },
            ],
          });
      })
      .willRespondWith(201, (builder) => {
        builder.jsonBody({
          imageId: like('IMG-001'),
          url: like('https://storage.example.com/img/IMG-001.jpg'),
        });
      })
      .executeTest(async (mockServer) => {
        const form = new FormData();
        form.append('image', fs.createReadStream(testImagePath), {
          filename: 'test.jpg',
          contentType: 'image/jpeg',
        });
        const response = await axios.post(`${mockServer.url}/images`, form, {
          headers: form.getHeaders(),
        });
        expect(response.data.imageId).toBeDefined();
      });
  });
});
```

**Key points:**
- `multipartBody(contentType, filePath, mimePartName)` is the simplest V4 multipart API — it handles the boundary, MIME encoding, and content-type header automatically. Use this for most single-file upload scenarios
- `binaryFile(contentType, fixturePath)` records raw bytes from a fixture file — use it with `.matchingRules` when you need content-type-based matching on specific parts rather than byte-exact replay
- `Matchers.contentType('image/jpeg')` matches the MIME content type of a binary part without byte-for-byte comparison — essential for image/PDF uploads where byte content varies between test runs
- The `SpecificationVersion` enum (`import { SpecificationVersion } from '@pact-foundation/pact'`) is available in pact-js v13+ and explicitly pins the Pact spec version in the constructor; `SpecificationVersion.SPECIFICATION_VERSION_V4` is the recommended value for all new TypeScript projects
- The fixture file (`test-upload.txt`, `image-upload.bin`) must be committed to version control alongside the test — use small, minimal files; the actual content is not tested by the contract (content-type is)
- `multipartBody()` and `binaryFile()` are only available on the `Pact` (V4) class's `addInteraction()` DSL — they are NOT available in `PactV3`

**Anti-pattern:** Matching the binary file body byte-for-byte using `equal()` on the multipart content. Binary fixtures differ between machines (line endings, encoding) and change whenever the fixture is regenerated. Use `Matchers.contentType()` for binary parts and `like()` for metadata fields.

---

### `SpecificationVersion` Enum Reference (TypeScript)

The `SpecificationVersion` enum allows explicit declaration of which Pact specification version a consumer test targets. Without it, pact-js defaults to Pact V2 for HTTP interactions (backward-compatible but missing V3/V4 capabilities).

```typescript
import { Pact, PactV3, SpecificationVersion } from '@pact-foundation/pact';

// SpecificationVersion enum values:
// SPECIFICATION_VERSION_V2 — PactV2: basic request/response, term() matchers (legacy)
// SPECIFICATION_VERSION_V3 — PactV3: MatchersV3, provider states with params, message pacts
// SPECIFICATION_VERSION_V4 — PactV4 (current): plugins, auto-port, addInteraction() DSL,
//                             .pending(), .withComment(), multipartBody(), statusCode() class matching

// Explicitly specifying V4 (recommended for all new projects):
const provider = new Pact({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  spec: SpecificationVersion.SPECIFICATION_VERSION_V4,
  logLevel: 'warn',
});

// PactV3 with explicit V3 spec (for projects intentionally targeting V3 pact files):
const providerV3 = new PactV3({
  consumer: 'OrderService',
  provider: 'InventoryService',
  dir: path.resolve(process.cwd(), 'pacts'),
  spec: SpecificationVersion.SPECIFICATION_VERSION_V3, // explicit; equivalent to the default
  port: 8081,
  logLevel: 'warn',
});
```

**When to set `spec` explicitly:**
- `spec: SpecificationVersion.SPECIFICATION_VERSION_V4` — use for all new projects; enables V4 features: plugin architecture, auto-port, interaction metadata, `multipartBody()`, `statusCode()` class matching
- `spec: SpecificationVersion.SPECIFICATION_VERSION_V3` — use when your provider verification infrastructure is on a version that cannot process V4 pact files (e.g., pact-jvm < 4.4 or pact-ruby < 1.25). V3 pact files are still the right choice for these legacy provider stacks
- Omitting `spec` — acceptable but not recommended; the default is V2 for `PactV3` and V4 for `Pact` (V4 alias). Making it explicit documents intent and prevents confusion when reading the code

---

### Additional Community Production Lessons [community]

54. **[community] EADDRINUSE errors with PactV3's `provider.setup()` + `provider.finalize()` lifecycle API.** Teams that use the older manual lifecycle API (`provider.setup()` / `provider.finalize()`) instead of `executeTest()` frequently encounter "Address already in use (os error 98)" errors when the `afterAll` hook fails to call `provider.finalize()`. The `finalize()` call releases the mock server port; omitting it leaves the port bound until the OS reclaims it, causing the next test run to fail with EADDRINUSE. The fix: always pair `setup()` with `finalize()` in a `try/finally` block, or migrate to `executeTest()` which handles server lifecycle automatically:

```typescript
// FRAGILE: manual lifecycle — finalize() not guaranteed if test throws
beforeAll(async () => { await provider.setup(); });
afterAll(async () => { await provider.finalize(); }); // ← skipped if beforeAll threw

// SAFE: executeTest() handles lifecycle — no manual setup/finalize needed
await provider
  .given('...')
  .uponReceiving('...')
  .withRequest({ ... })
  .willRespondWith({ ... })
  .executeTest(async (mockServer) => { /* test here */ });

// IF you must use the manual API (e.g., shared mock server across multiple it() blocks):
// wrap in try/finally so finalize() always runs
beforeAll(async () => { await provider.setup(); });
afterAll(async () => {
  try { /* verify interactions */ }
  finally { await provider.finalize(); } // ← guaranteed to run
});
```

This issue is tracked as pact-js issue #1568. It is most common in projects that copy-paste PactV2-era test patterns which used the manual lifecycle API before `executeTest()` was introduced in pact-js v12+. The correct migration is to move to `executeTest()` — it was designed specifically to eliminate this class of resource-leak issue.

55. **[community] Jest `--watch` and `--watchAll` modes print a non-fatal "Global tracing subscriber" warning on every file re-run (pact-js issue #1438).** When running Pact consumer tests with `jest --watch`, a warning appears in the console on each re-trigger: `"Failed to initialise global tracing subscriber - a global default trace dispatcher has already been set"`. This is a cosmetic issue — tests pass normally and no functionality is affected. The root cause is pact-js's Rust telemetry layer attempting to re-initialize a global trace dispatcher that Jest's hot-reload already initialized. Setting `PACT_DO_NOT_TRACK=true` does not suppress this warning. **Workaround:** suppress the warning at the Jest configuration level by filtering stderr output, or simply accept the noise during local watch-mode development. Do not use this warning as a signal that tests are failing — verify actual test results from the Jest output, not from the tracing subscriber message. This does not affect CI runs (which use `jest --ci` or `jest --runInBand`, not watch mode).

56. **[community] Multipart form data contracts over-specify binary content when the fixture file changes on disk.** Teams that use `binaryFile()` or `multipartBody()` without `Matchers.contentType()` matching rules record the raw bytes of a specific test fixture into the pact file. When the fixture file is regenerated (e.g., a test image re-exported at a different quality level, or a fixture updated for a new test case), the pact file content changes — triggering a `contract_content_changed` webhook event and a provider re-verification run for what is effectively a test-infrastructure change, not a contract change. **Best practice:** always use `Matchers.contentType('image/jpeg')` on binary body parts rather than byte-exact matching; use `like()` for metadata fields. The contract captures "the consumer sends a JPEG image" without locking to specific bytes — the provider verifies that it accepts `image/jpeg` content, which is the actual contract requirement.

57. **[community] Omitting `spec: SpecificationVersion.SPECIFICATION_VERSION_V4` causes `multipartBody()` and `statusCode()` class matching to fail silently.** When a `Pact` instance is constructed without an explicit `spec` option, it defaults to V2 for some DSL paths. Calling `multipartBody()`, `builder.statusCode()`, or `.pending()` on a V2 pact silently produces a pact file without the expected V4 structures — the build passes but the pact file is missing the content type rules or status code matchers. **Fix:** always set `spec: SpecificationVersion.SPECIFICATION_VERSION_V4` explicitly when using any V4-only feature. Import `SpecificationVersion` from `@pact-foundation/pact` — it is available in pact-js v13+. TypeScript will not warn you when a V4 method is called on a V2 or V3 pact instance because the builder types are shared; the type system cannot enforce the spec version / feature matrix.
