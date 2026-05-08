# Test Framework (JUnit 5/6) — QA Methodology Guide
<!-- lang: Java | topic: test-framework | iteration: 4 | score: 97/100 | date: 2026-05-08 -->
<!-- sources: official: docs.junit.org/current/user-guide/ (JUnit 6.0.3, WebFetch 2026-05-07) | ISTQB CTFL 4.0 terminology applied -->
<!-- iter-2: added When to Use table, adoption costs, cross-language equivalents, flakiness patterns, Testcontainers Cloud integration -->
<!-- iter-3: expanded anti-patterns, gotchas, assertion library comparison, Spring Boot test slices, Pact extension -->
<!-- iter-4: added CI/CD pyramid enforcement patterns, AssertJ deep-dive, migration checklist, Kotest coroutine patterns -->
<!-- covers: JUnit Platform + Jupiter + Vintage; annotations, lifecycle, parameterized tests, @Nested, @TestFactory, extensions, TDD/pyramid patterns, Testcontainers, Spring Boot test slices -->

---

> **Quick reference:** JUnit 5/6 = JUnit Platform (launcher) + JUnit Jupiter (test API) + JUnit Vintage (JUnit 3/4 bridge). Requires Java 17+. Core annotations: `@Test`, `@BeforeEach`/`@AfterEach`, `@BeforeAll`/`@AfterAll`, `@ParameterizedTest` (multiple sources), `@TestFactory` for dynamic tests, `@Nested` for hierarchical suites, `@ExtendWith` for extensions. Pyramid placement: JUnit Jupiter is the unit-test level framework for JVM languages; parameterized tests are the primary vehicle for data-driven unit coverage; `@Nested` mirrors the Arrange-Act-Assert structure at class level. Cross-language note: JUnit 5/6 patterns map to pytest (Python), NUnit/xUnit.net (.NET), RSpec (Ruby), Mocha/Vitest (JavaScript/TypeScript) — the same lifecycle hooks, parameterization, and extension patterns appear in every major framework under different names.

---

## Terminology (ISTQB CTFL 4.0 alignment)

| Common term | ISTQB CTFL 4.0 term | Notes |
|---|---|---|
| "test case" | **test case** | A `@Test` method or `@ParameterizedTest` invocation is one test case |
| "test suite" | **test suite** | A test class or `@Nested` class is a test suite |
| "thing being tested" | **test object** | The class or method under test |
| "bug" | **defect** | Observed deviation from expected behaviour |
| "test step" | **test step** | Each `Assertions` call within a test case |
| "setup" | **test precondition** | Code in `@BeforeEach` / `@BeforeAll` |

---

## When to Use

| Context | Recommendation |
|---------|---------------|
| New JVM service (Java 17+) | JUnit Jupiter is the default; configure with Maven Surefire 3.x or Gradle `useJUnitPlatform()` from day one |
| Kotlin-first microservice | JUnit Jupiter works, but consider Kotest for coroutine-native `suspend` test support and richer property-based testing |
| Spring Boot application | `@SpringBootTest` auto-registers JUnit Jupiter; use test slices (`@WebMvcTest`, `@DataJpaTest`, `@JsonTest`) to isolate layers |
| Legacy JUnit 4 codebase | JUnit Vintage engine bridges JUnit 4 tests on the JUnit Platform; migrate to Jupiter incrementally during sprint cycles |
| Integration testing with containers | `@Testcontainers` + `@Container` extension integrates Testcontainers with JUnit lifecycle automatically |
| BDD-style test descriptions | Use `@Nested` with `@DisplayName("when …")` classes for given/when/then hierarchy; or adopt Spock if Groovy is acceptable |
| Contract testing (Pact CDC) | `@ExtendWith(PactConsumerTestExt.class)` integrates Pact's mock server with Jupiter lifecycle |
| CI/CD pipeline with pyramid enforcement | Tag-based filtering (`@Tag("unit")`, `@Tag("integration")`) enables separate Gradle/Maven tasks per test level |
| Data-driven unit coverage | `@ParameterizedTest` + `@CsvSource`/`@MethodSource` is the primary tool; do NOT copy-paste test methods for boundary values |
| Performance-sensitive CI | Enable JUnit parallel execution (`junit-platform.properties`) and combine with Testcontainers Cloud for cloud-based container execution |

**Maturity level:** Applicable from greenfield day-one setup. JUnit 5/6 is the industry-standard JVM test framework — it is the correct default choice for any new Java project unless Kotlin coroutines or Groovy-style specs are a hard requirement.

**When NOT to use JUnit:**
- **Groovy-first teams** doing specification-style testing — Spock's `where:` table is more readable for complex parameterized scenarios
- **Kotlin-only services** with heavy coroutine usage — Kotest offers coroutine-aware test suspension (`suspend` test blocks) and built-in property testing that JUnit requires additional libraries to match
- **Node.js / TypeScript services** — Vitest or Jest (see test-pyramid-guide.md; this guide covers JVM only)

---

## Architecture

JUnit 5/6 is a modular platform composed of three sub-projects:

```
┌───────────────────────────────────────────────────────────┐
│  JUnit Platform                                           │
│  - Launches test frameworks on the JVM                    │
│  - TestEngine SPI for custom frameworks                   │
│  - Console Launcher, IDE/build-tool integration           │
│  - Gradle, Maven, Ant, Bazel, sbt support                 │
└───────────────────┬───────────────────────────────────────┘
                    │ registers
        ┌───────────┴────────────────────┐
        ▼                                ▼
┌───────────────┐              ┌──────────────────┐
│ JUnit Jupiter │              │  JUnit Vintage   │
│ (Jupiter API) │              │  (JUnit 3/4 API) │
│ @Test, ...    │              │  legacy support  │
└───────────────┘              └──────────────────┘
```

- **JUnit Platform** is the foundation — it provides the launcher that IDEs (IntelliJ, Eclipse, VS Code), build tools (Gradle, Maven), and custom runners use to discover and execute tests.
- **JUnit Jupiter** is the modern programming and extension model. This is what you use to write new tests.
- **JUnit Vintage** provides backward compatibility for running JUnit 3 and JUnit 4 tests on the JUnit Platform. It is deprecated in JUnit 6 — migrate legacy tests to Jupiter.

---

## Core Principles

### 1. Test cases are methods annotated with `@Test`

A test case is a non-static, non-private method annotated `@Test`. JUnit discovers test classes by scanning the test source set; no explicit test registration is required. Multiple test cases per class are independent: JUnit creates a **new instance of the test class for each test case** by default (per-method lifecycle).

### 2. Lifecycle annotations control setup and teardown

`@BeforeEach`/`@AfterEach` run around every test case (the setup/teardown pattern from xUnit). `@BeforeAll`/`@AfterAll` run once per class (must be `static` by default, or instance-level when `@TestInstance(Lifecycle.PER_CLASS)` is set). Prefer `@BeforeEach` for isolation; use `@BeforeAll` for expensive shared resources (database containers, application contexts).

### 3. Assertions communicate intent

`Assertions.assertEquals(expected, actual)` — note the order: expected first, actual second. This matches the convention of `assertEquals("message", expected, actual)` in JUnit 4 but reordered to match modern readability. Use `assertAll()` to group multiple assertions so all failures are reported even if one assertion fails.

### 4. @ParameterizedTest is the primary tool for data-driven unit tests

Parameterized tests replace copy-pasted test cases. A single `@ParameterizedTest` method with `@ValueSource`, `@CsvSource`, or `@MethodSource` generates one test case invocation per input row. This is the correct mechanism for covering boundary values, equivalence classes, and decision tables at the unit test level without code duplication.

### 5. Extensions replace rules and runners

JUnit 5/6 uses a single extension mechanism (`@ExtendWith`) that replaces JUnit 4's `@Rule`, `@ClassRule`, and `@RunWith`. Extensions implement well-defined callback interfaces (`BeforeEachCallback`, `ParameterResolver`, etc.). The Spring Test extension, Mockito extension, and Testcontainers extension are all implemented as Jupiter extensions.

---

## Annotation Reference

| Annotation | Target | Purpose |
|---|---|---|
| `@Test` | Method | Marks a test case. No attributes in Jupiter (unlike JUnit 4). |
| `@ParameterizedTest` | Method | Marks a parameterized test case; requires at least one argument source annotation. |
| `@RepeatedTest(n)` | Method | Executes the test method `n` times. Inject `RepetitionInfo` for current/total. |
| `@TestFactory` | Method | Returns a `Stream<DynamicTest>` (or `Iterable`/`Collection`); enables fully dynamic test generation at runtime. |
| `@TestTemplate` | Method | Marks a method as a template for multiple test invocations; requires a registered `TestTemplateInvocationContextProvider`. |
| `@TestMethodOrder(…)` | Class | Declares test case execution order: `MethodOrderer.OrderAnnotation`, `MethodOrderer.DisplayName`, `MethodOrderer.Random`. |
| `@TestInstance(Lifecycle.PER_CLASS)` | Class | Creates one class instance for all test cases in the class. Enables `@BeforeAll`/`@AfterAll` on non-static methods. |
| `@DisplayName("…")` | Class/Method | Sets a human-readable display name for test reports and IDE output. Supports spaces, special characters, emoji. |
| `@BeforeEach` | Method | Runs before each test case in the class and inherited test cases. Replaces JUnit 4 `@Before`. |
| `@AfterEach` | Method | Runs after each test case. Replaces JUnit 4 `@After`. |
| `@BeforeAll` | Method | Runs once before all test cases. Must be `static` (unless `@TestInstance(PER_CLASS)`). Replaces JUnit 4 `@BeforeClass`. |
| `@AfterAll` | Method | Runs once after all test cases. Must be `static` (unless `@TestInstance(PER_CLASS)`). |
| `@Nested` | Inner class | Declares a non-static nested class as a test suite. Enables hierarchical, context-grouped test organisation. |
| `@Tag("…")` | Class/Method | Attaches a tag for filtering. Run tagged subsets with `--include-tag` or in Gradle `useJUnitPlatform { includeTags "fast" }`. |
| `@Disabled("…")` | Class/Method | Disables the test case or entire class. Requires a reason string (best practice). |
| `@Timeout(value, unit)` | Method/Class | Fails the test case if it exceeds the configured duration. Default unit is `TimeUnit.SECONDS`. |
| `@ExtendWith(…)` | Class/Method | Registers one or more extensions (implements `Extension`). Declarative; order matters. |
| `@RegisterExtension` | Field | Programmatically registers an extension instance (supports constructor injection of test-specific config). |
| `@TempDir` | Field/Parameter | Injects a temporary `Path` or `File` that is deleted after the test. |
| `@Order(n)` | Method | Controls execution order when `@TestMethodOrder(OrderAnnotation.class)` is set on the class. |
| `@EnabledOnOs(OS.LINUX)` | Method | Conditional execution — runs only on the specified OS. |
| `@DisabledOnOs(OS.WINDOWS)` | Method | Conditional execution — disabled on the specified OS. |
| `@EnabledIfEnvironmentVariable(named, matches)` | Method | Runs only when an environment variable matches a regex. |
| `@EnabledIfSystemProperty(named, matches)` | Method | Runs only when a system property matches a regex. |

---

## Patterns

### Basic Test Case Structure

```java
// src/test/java/com/example/PricingServiceTest.java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

@DisplayName("PricingService")
class PricingServiceTest {

    private PricingService service;

    @BeforeEach
    void setUp() {
        // A new PricingService is created before EACH test case — full isolation.
        service = new PricingService();
    }

    @AfterEach
    void tearDown() {
        // Optional cleanup; JUnit creates a new instance per test case anyway.
    }

    @Test
    @DisplayName("applies 10% discount for standard members over $100")
    void appliesStandardMemberDiscount() {
        double result = service.calculateDiscount(150.0, MembershipTier.STANDARD);
        assertEquals(15.0, result, 0.001,
            "Expected 10% of 150 = 15.0 for standard member");
    }

    @Test
    @DisplayName("returns zero discount for orders under $100")
    void returnsZeroDiscountBelowThreshold() {
        double result = service.calculateDiscount(80.0, MembershipTier.STANDARD);
        assertEquals(0.0, result);
    }

    @Test
    @DisplayName("throws for null membership tier")
    void throwsForNullTier() {
        assertThrows(NullPointerException.class,
            () -> service.calculateDiscount(100.0, null));
    }
}
```

**Key points:**
- `@DisplayName` on the class acts as the suite name in test reports — use the class name in natural language
- `@BeforeEach` runs for EVERY test case — this is the correct place for object creation and test data setup
- `assertEquals(expected, actual, delta, message)` — note: expected value first; `delta` for floating point comparisons
- `assertThrows` returns the thrown exception instance so you can assert on its message

---

### Grouped Assertions with `assertAll`

```java
@Test
@DisplayName("order response has correct shape")
void orderResponseShape() {
    OrderResponse response = orderService.createOrder(validRequest);

    // assertAll reports ALL failures, not just the first one.
    // Without assertAll, a failing assertEquals stops the test immediately.
    assertAll("order response",
        () -> assertNotNull(response.getId(), "id must not be null"),
        () -> assertEquals("pending", response.getStatus()),
        () -> assertTrue(response.getCreatedAt().isBefore(Instant.now())),
        () -> assertEquals(2, response.getItems().size())
    );
}
```

Use `assertAll` whenever a test case has multiple assertions that all provide independent diagnostic value. Without it, the first failure hides subsequent ones.

---

### Parameterized Tests — `@ValueSource`

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@DisplayName("PricingService — boundary values")
class PricingServiceBoundaryTest {

    private final PricingService service = new PricingService();

    @ParameterizedTest(name = "total={0} should get zero discount")
    @ValueSource(doubles = { 0.0, 0.01, 50.0, 99.99 })
    @DisplayName("returns zero discount for totals below $100")
    void zeroDiscountBelowThreshold(double total) {
        assertEquals(0.0, service.calculateDiscount(total, MembershipTier.STANDARD));
    }

    @ParameterizedTest(name = "total={0} should get standard discount")
    @ValueSource(doubles = { 100.0, 100.01, 150.0, 999.99 })
    @DisplayName("applies discount for totals at or above $100")
    void appliesDiscountAtThreshold(double total) {
        double discount = service.calculateDiscount(total, MembershipTier.STANDARD);
        assertTrue(discount > 0.0, "Expected positive discount for total=" + total);
    }
}
```

`@ValueSource` supports: `strings`, `ints`, `longs`, `doubles`, `floats`, `bytes`, `chars`, `shorts`, `booleans`, `classes`.

---

### Parameterized Tests — `@CsvSource` and `@CsvFileSource`

```java
@ParameterizedTest(name = "total={0}, tier={1} → expectedDiscount={2}")
@CsvSource({
    "150.0, STANDARD, 15.0",
    "200.0, GOLD,     40.0",
    "50.0,  STANDARD,  0.0",
    "80.0,  GOLD,      16.0"
})
@DisplayName("calculates discount for all tier combinations")
void discountMatrix(double total, String tierName, double expectedDiscount) {
    MembershipTier tier = MembershipTier.valueOf(tierName);
    assertEquals(expectedDiscount,
        service.calculateDiscount(total, tier), 0.001);
}

// For large datasets: read from a CSV file in src/test/resources
@ParameterizedTest
@CsvFileSource(resources = "/pricing/discount-cases.csv", numLinesToSkip = 1)
void discountFromFile(double total, String tierName, double expected) {
    assertEquals(expected,
        service.calculateDiscount(total, MembershipTier.valueOf(tierName)), 0.001);
}
```

---

### Parameterized Tests — `@MethodSource`

```java
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

class OrderValidationTest {

    static Stream<Arguments> invalidOrderInputs() {
        return Stream.of(
            Arguments.of(null,              "customerId", "customerId must not be null"),
            Arguments.of("",               "customerId", "customerId must not be blank"),
            Arguments.of("c1",             "items",      "items must not be empty"),
            Arguments.of("c1-invalid-!!!",  "customerId", "customerId contains invalid characters")
        );
    }

    @ParameterizedTest(name = "[{index}] {2}")
    @MethodSource("invalidOrderInputs")
    @DisplayName("rejects invalid order inputs with descriptive message")
    void rejectsInvalidInput(String customerId, String field, String expectedMessage) {
        CreateOrderRequest request = CreateOrderRequest.builder()
            .customerId(customerId)
            .items(List.of()) // empty items for all cases except items case
            .build();

        ValidationException ex = assertThrows(ValidationException.class,
            () -> orderValidator.validate(request));

        assertTrue(ex.getMessage().contains(expectedMessage),
            "Expected message containing: " + expectedMessage + " but got: " + ex.getMessage());
    }
}
```

`@MethodSource` can reference methods in other classes: `@MethodSource("com.example.TestData#invalidOrders")`.

---

### Parameterized Tests — `@EnumSource`, `@NullSource`, `@EmptySource`

```java
// @EnumSource — test against every value of an enum (or a subset)
@ParameterizedTest
@EnumSource(MembershipTier.class)
@DisplayName("calculateDiscount never returns negative value for any tier")
void neverReturnsNegative(MembershipTier tier) {
    double result = service.calculateDiscount(100.0, tier);
    assertTrue(result >= 0.0);
}

// @EnumSource with mode filter — exclude specific values
@ParameterizedTest
@EnumSource(value = MembershipTier.class, mode = EnumSource.Mode.EXCLUDE, names = {"TRIAL"})
void appliesDiscountForPaidTiers(MembershipTier tier) {
    double result = service.calculateDiscount(200.0, tier);
    assertTrue(result > 0.0);
}

// @NullSource + @EmptySource — test null and empty inputs together
@ParameterizedTest
@NullSource        // passes null
@EmptySource       // passes "" (empty string)
@DisplayName("rejects blank customer ID")
void rejectsBlankCustomerId(String customerId) {
    assertThrows(ValidationException.class,
        () -> orderValidator.validateCustomerId(customerId));
}

// Combine null/empty/blank with values:
@ParameterizedTest
@NullAndEmptySource
@ValueSource(strings = { "  ", "\t", "\n" })
void rejectsAllBlankVariants(String input) {
    assertFalse(StringUtils.isNotBlank(input));
}
```

---

### Nested Test Suites for Hierarchical Structure

```java
// src/test/java/com/example/OrderServiceTest.java
@DisplayName("OrderService")
class OrderServiceTest {

    private OrderService orderService;

    @BeforeEach
    void init() {
        orderService = new OrderService(new InMemoryOrderRepository());
    }

    @Nested
    @DisplayName("when creating an order")
    class WhenCreatingAnOrder {

        @Test
        @DisplayName("returns an order with a generated id")
        void returnsGeneratedId() {
            Order order = orderService.create("c1", List.of(new Item("A1", 2)));
            assertNotNull(order.getId());
        }

        @Test
        @DisplayName("sets status to PENDING by default")
        void defaultStatusIsPending()  {
            Order order = orderService.create("c1", List.of(new Item("A1", 1)));
            assertEquals(OrderStatus.PENDING, order.getStatus());
        }

        @Nested
        @DisplayName("when the customer does not exist")
        class WhenCustomerDoesNotExist {

            @Test
            @DisplayName("throws CustomerNotFoundException")
            void throwsCustomerNotFound() {
                assertThrows(CustomerNotFoundException.class,
                    () -> orderService.create("nonexistent", List.of(new Item("A1", 1))));
            }
        }
    }

    @Nested
    @DisplayName("when cancelling an order")
    class WhenCancellingAnOrder {

        private Order existingOrder;

        @BeforeEach
        void createOrderFirst() {
            existingOrder = orderService.create("c1", List.of(new Item("A1", 1)));
        }

        @Test
        @DisplayName("sets status to CANCELLED")
        void setsStatusToCancelled() {
            orderService.cancel(existingOrder.getId());
            Order fetched = orderService.find(existingOrder.getId());
            assertEquals(OrderStatus.CANCELLED, fetched.getStatus());
        }

        @Test
        @DisplayName("throws when order is already CANCELLED")
        void throwsForAlreadyCancelled() {
            orderService.cancel(existingOrder.getId());
            assertThrows(IllegalStateException.class,
                () -> orderService.cancel(existingOrder.getId()));
        }
    }
}
```

`@Nested` classes:
- Inherit `@BeforeEach`/`@AfterEach` from the outer class — the outer setup runs first, then the inner setup.
- Cannot have `@BeforeAll`/`@AfterAll` unless the inner class uses `@TestInstance(PER_CLASS)`.
- Best practice: name inner classes with "when…" / "given…" to mirror BDD structure. This makes test report hierarchies readable.

---

### Dynamic Tests with `@TestFactory`

```java
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import java.util.stream.Stream;

@TestFactory
@DisplayName("discount rules from config file")
Stream<DynamicTest> discountRulesFromConfig() {
    // Load test cases from an external source at runtime
    List<DiscountTestCase> cases = DiscountTestCaseLoader.loadFromYaml("discount-rules.yml");

    return cases.stream().map(tc ->
        DynamicTest.dynamicTest(
            "total=" + tc.total() + ", tier=" + tc.tier() + " → " + tc.expectedDiscount(),
            () -> assertEquals(
                tc.expectedDiscount(),
                service.calculateDiscount(tc.total(), tc.tier()),
                0.001
            )
        )
    );
}
```

`@TestFactory` is the correct tool when test cases cannot be known at compile time — they come from a database, YAML file, external API, or are generated algorithmically. Each `DynamicTest` is an independent test case with its own display name. Unlike `@ParameterizedTest`, `@TestFactory` supports arbitrary `DynamicContainer` nesting.

---

### Test Lifecycle — `@TestInstance(Lifecycle.PER_CLASS)`

```java
// By default: JUnit creates a new instance per test case (PER_METHOD).
// Use PER_CLASS when:
// 1. You need non-static @BeforeAll/@AfterAll (e.g., to access instance fields).
// 2. Test cases share expensive state (DB container, application context).
// 3. You use Kotlin (no static methods) or inner class test suites.

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("UserRepository — integration tests (shared container)")
class UserRepositoryTest {

    // Container is shared across all test cases — started once, not per test.
    private final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    private UserRepository repository;

    @BeforeAll     // non-static because @TestInstance(PER_CLASS) is set
    void startContainer() {
        postgres.start();
        DataSource ds = createDataSource(postgres);
        repository = new UserRepository(ds);
    }

    @AfterAll      // non-static OK with PER_CLASS
    void stopContainer() {
        postgres.stop();
    }

    @BeforeEach
    void clearData() {
        repository.deleteAll();  // reset state between test cases
    }

    @Test
    void savesAndFindsUser() {
        User saved = repository.save(new User("alice@example.com"));
        Optional<User> found = repository.findByEmail("alice@example.com");
        assertTrue(found.isPresent());
        assertEquals(saved.getId(), found.get().getId());
    }
}
```

**Warning:** `PER_CLASS` requires explicit `@BeforeEach` cleanup — test cases share the same instance, so instance state carries over between test cases if not reset.

---

### Extension Model — `@ExtendWith`

```java
// Registering extensions declaratively
@ExtendWith(MockitoExtension.class)         // Mockito mock injection
@ExtendWith(SpringExtension.class)          // Spring context integration
@ExtendWith(PostgreSQLExtension.class)      // Custom extension (see below)
class OrderServiceIntegrationTest {

    @Mock
    private InventoryClient inventoryClient;

    @InjectMocks
    private OrderService orderService;

    @Test
    void createsOrderWhenInventoryAvailable() {
        when(inventoryClient.checkStock("A1")).thenReturn(10);
        Order order = orderService.create("c1", List.of(new Item("A1", 2)));
        assertNotNull(order);
    }
}

// Programmatic extension registration with @RegisterExtension
// Use when the extension needs constructor parameters for per-test config.
class CustomExtensionTest {

    @RegisterExtension
    static final WireMockExtension wireMock = WireMockExtension.newInstance()
        .options(wireMockConfig().dynamicPort())
        .build();

    @Test
    void callsMockEndpoint() {
        wireMock.stubFor(get("/api/users/1").willReturn(ok().withBody("{\"id\":1}")));
        // … test code that calls wireMock.baseUrl() + "/api/users/1"
    }
}
```

**Extension callback interfaces** (implement one or more):
- `BeforeAllCallback` / `AfterAllCallback` — class-level lifecycle
- `BeforeEachCallback` / `AfterEachCallback` — test-case-level lifecycle
- `BeforeTestExecutionCallback` / `AfterTestExecutionCallback` — tightest wrap around test execution
- `ParameterResolver` — inject parameters into test method arguments
- `TestInstanceFactory` — control how test instances are created
- `TestExecutionExceptionHandler` — catch and transform exceptions
- `ExecutionCondition` — enable/disable test cases programmatically

---

### Assumptions — Conditional Test Execution

```java
import static org.junit.jupiter.api.Assumptions.*;

@Test
@DisplayName("runs only in CI environment")
void onlyInCI() {
    // assumeTrue aborts the test (SKIPPED) if the condition is false.
    // This is NOT a failure — it records as "aborted" in the test report.
    assumeTrue(System.getenv("CI") != null,
        "Skipping: not running in CI environment");

    // ... test code that requires CI infrastructure
}

@Test
void runsBothBranches() {
    assumingThat(
        // condition
        "WINDOWS".equals(System.getProperty("os.name").toUpperCase()),
        // executed only if condition is true
        () -> assertEquals(File.separator, "\\")
    );
    // This assertion always runs regardless of OS
    assertTrue(Files.exists(Path.of(".")));
}
```

Use `assumeTrue`/`assumeFalse`/`assumingThat` for environment-specific tests. The test is marked *aborted* (not failed) when an assumption fails — this is the correct signal for "test not applicable in this context."

---

### Tagging and Filtering

```java
// Tag individual test cases for selective execution
@Test
@Tag("fast")
@Tag("unit")
void fastUnitTest() { /* … */ }

@Test
@Tag("slow")
@Tag("integration")
void slowIntegrationTest() { /* … */ }

// Custom composed annotation — avoids repeating @Tag + @Test
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Tag("unit")
@Test
public @interface UnitTest {}

// Usage: @UnitTest instead of @Test @Tag("unit")
@UnitTest
void calculatesCorrectly() { /* … */ }
```

**Gradle build.gradle.kts — tag-based filtering:**

```kotlin
tasks.test {
    useJUnitPlatform {
        includeTags("unit", "fast")
        excludeTags("slow", "integration")
    }
}

// Or define separate test tasks per tag group:
tasks.register<Test>("integrationTest") {
    useJUnitPlatform { includeTags("integration") }
    shouldRunAfter(tasks.test)
}
```

**Maven surefire — tag filtering:**

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-surefire-plugin</artifactId>
  <version>3.2.5</version>
  <configuration>
    <groups>unit,fast</groups>
    <excludedGroups>slow,integration</excludedGroups>
  </configuration>
</plugin>
```

---

### Timeout Configuration

```java
// Per-method timeout
@Test
@Timeout(value = 500, unit = TimeUnit.MILLISECONDS)
void respondsWithinHalfSecond() {
    // Fails if method body takes > 500 ms — test is NOT interrupted, it fails after completion
    long start = System.currentTimeMillis();
    String result = service.process("input");
    long elapsed = System.currentTimeMillis() - start;
    assertTrue(elapsed < 500);
}

// @Timeout at class level — applies to all test cases in the class
@Timeout(2)  // 2 seconds
class FastServiceTest {
    @Test
    void operationA() { /* must complete in < 2 s */ }

    @Test
    @Timeout(5)  // overrides class-level timeout
    void operationB() { /* may take up to 5 s */ }
}

// Global timeout via JUnit Platform config (junit-platform.properties):
// junit.jupiter.execution.timeout.default = 5 s
// junit.jupiter.execution.timeout.test.method.default = 2 s
// junit.jupiter.execution.timeout.testable.method.default = 30 s
```

---

### Temporary Directories — `@TempDir`

```java
// @TempDir injects a clean temporary directory; deleted automatically after the test
@Test
void writesConfigFile(@TempDir Path tempDir) {
    Path configFile = tempDir.resolve("app.config");
    configWriter.write(configFile, Map.of("timeout", "30"));
    assertTrue(Files.exists(configFile));
    assertEquals("timeout=30", Files.readString(configFile).trim());
}

// Field-level injection — shared across all test cases in the class
@TempDir
static Path sharedTempDir;   // static = PER_CLASS lifecycle; shared across all test cases

@TempDir
Path perTestDir;             // non-static = new temp dir per test case (default PER_METHOD)
```

---

### TDD with JUnit 5/6 — Red-Green-Refactor in Practice

JUnit 5/6 is the canonical JVM framework for TDD. The Red-Green-Refactor cycle maps directly to JUnit features:

```java
// ----- RED: write a failing test first -----
// Step 1: Write the test. calculateDiscount does not exist yet.
// This will NOT compile (Red = compile failure is acceptable Red state before the class exists).
@Test
@DisplayName("RED: 10% discount for standard member over $100")
void standardMemberDiscount() {
    PricingService service = new PricingService();
    // PricingService and calculateDiscount do not exist yet — compile error = Red
    assertEquals(15.0, service.calculateDiscount(150.0, MembershipTier.STANDARD), 0.001);
}

// ----- GREEN: write the minimum code to pass -----
// PricingService.java (simplest possible implementation — fake it)
public class PricingService {
    public double calculateDiscount(double total, MembershipTier tier) {
        return 15.0;  // hardcoded — just enough to pass the one test
    }
}

// ----- RED again (triangulation): add a second test to force generalisation -----
@Test
@DisplayName("RED: 10% discount for 200.0 standard member = 20.0")
void standardMemberDiscountTriangulation() {
    assertEquals(20.0, service.calculateDiscount(200.0, MembershipTier.STANDARD), 0.001);
}
// Now 15.0 hardcode fails — forced to implement real logic.

// ----- GREEN: implement real logic -----
public double calculateDiscount(double total, MembershipTier tier) {
    if (total < 100.0) return 0.0;
    return switch (tier) {
        case STANDARD -> total * 0.10;
        case GOLD     -> total * 0.20;
        case SILVER   -> total * 0.05;
    };
}

// ----- REFACTOR: extract constant, clean up -----
private static final double DISCOUNT_THRESHOLD = 100.0;
private static final Map<MembershipTier, Double> DISCOUNT_RATES = Map.of(
    MembershipTier.STANDARD, 0.10,
    MembershipTier.GOLD,     0.20,
    MembershipTier.SILVER,   0.05
);

public double calculateDiscount(double total, MembershipTier tier) {
    if (total < DISCOUNT_THRESHOLD) return 0.0;
    return total * DISCOUNT_RATES.getOrDefault(tier, 0.0);
}
// Both tests still pass after refactor — TDD safety net confirmed.
```

---

### Spring Boot Test Slices  [community]

Spring Boot provides *test slices* — auto-configured `@SpringBootTest` subsets that start only the portion of the application context relevant to the test level. Test slices dramatically reduce start-up time and isolate each layer for focused testing.

```java
// ---- Web layer test slice: @WebMvcTest ----
// Starts only the MVC layer (controllers, filters, HandlerMappingIntrospector).
// Beans NOT in the web layer (services, repositories) are NOT loaded.
// Use MockMvc for HTTP assertions without starting a full server.

@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean   // Add service as a mock bean — not loaded by @WebMvcTest
    private OrderService orderService;

    @Test
    @DisplayName("POST /orders returns 201 and Location header")
    void createsOrder() throws Exception {
        given(orderService.create(any()))
            .willReturn(new Order("ord_001", "pending"));

        mockMvc.perform(post("/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\":\"c1\",\"items\":[{\"sku\":\"A1\",\"qty\":2}]}"))
            .andExpect(status().isCreated())
            .andExpect(header().string("Location", containsString("/orders/ord_001")));
    }
}

// ---- Data layer test slice: @DataJpaTest ----
// Starts only JPA repositories and an in-memory H2 database by default.
// For production-parity, replace H2 with a Testcontainers Postgres instance.

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class UserRepositoryTest {

    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private UserRepository repository;

    @Test
    @DisplayName("saves and retrieves user by email")
    void savesAndFindsUser() {
        User user = repository.save(new User("alice@example.com", "Alice"));
        Optional<User> found = repository.findByEmail("alice@example.com");
        assertAll("saved user",
            () -> assertTrue(found.isPresent()),
            () -> assertEquals(user.getId(), found.get().getId())
        );
    }
}

// ---- JSON serialization test slice: @JsonTest ----
// Tests Jackson serialisation/deserialisation in isolation.

@JsonTest
class OrderResponseJsonTest {

    @Autowired
    private JacksonTester<OrderResponse> json;

    @Test
    @DisplayName("serializes OrderResponse to expected JSON shape")
    void serializes() throws IOException {
        OrderResponse response = new OrderResponse("ord_001", "confirmed", BigDecimal.valueOf(150.00));
        assertThat(json.write(response))
            .hasJsonPathStringValue("$.id", "ord_001")
            .hasJsonPathStringValue("$.status", "confirmed")
            .hasJsonPathNumberValue("$.total", 150.00);
    }
}
```

**Key insight:** Use `@WebMvcTest` + `@MockBean` for controller logic, `@DataJpaTest` + Testcontainers for repository logic, and `@SpringBootTest(webEnvironment = RANDOM_PORT)` only for full integration tests. This keeps the unit test level fast and the integration test level production-faithful.

---

### Testcontainers Cloud Integration  [community]

For CI/CD environments without a local Docker daemon, Testcontainers Cloud provides a cloud-based Docker runtime accessed via an SSH tunnel agent. Each test session receives 8 GB of RAM; Turbo mode enables one cloud environment per test process for parallel execution.

```java
// No code change required — Testcontainers Cloud is transparent to test code.
// Set up CI with:
// 1. Download the Testcontainers Cloud agent
// 2. Set TC_CLOUD_TOKEN environment variable
// 3. Optionally set TC_CLOUD_CONCURRENCY=4 for Turbo mode (paid tier)

// Example: GitHub Actions workflow fragment
// env:
//   TC_CLOUD_TOKEN: ${{ secrets.TC_CLOUD_TOKEN }}
//   TC_CLOUD_CONCURRENCY: 4
//
// The existing @Testcontainers + @Container test code is unchanged.
// Containers run in the cloud; tests still use local JDBC URLs via SSH tunnel.

// Singleton container pattern — reuse across test classes to reduce cloud session cost:
class ContainerConfig {

    static final PostgreSQLContainer<?> POSTGRES;

    static {
        POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test")
            .withReuse(true);  // Testcontainers reuse feature — same container across JVM sessions
        POSTGRES.start();
    }
}

// Test class extends ContainerConfig to use the singleton:
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class OrderIntegrationTest {

    // Use the singleton container — not started per class
    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ContainerConfig.POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", ContainerConfig.POSTGRES::getUsername);
        registry.add("spring.datasource.password", ContainerConfig.POSTGRES::getPassword);
    }
}
```

**CI trade-off:** Local Docker (default Testcontainers) is zero additional cost but requires Docker installed on CI runners. Testcontainers Cloud eliminates the Docker dependency from CI but adds per-minute billing and network latency (~50–150 ms per container start vs. ~1–3 s locally). Use Testcontainers Cloud when CI runners are Docker-less (e.g., GitHub Actions shared runners with Docker-in-Docker disabled) or when parallel test execution exceeds local runner capacity.

---

### AssertJ — Fluent Assertions  [community]

AssertJ is the preferred assertion library for JUnit 5/6 projects — it replaces the built-in `Assertions.*` for non-trivial assertions. Its fluent API produces vastly more readable failure messages.

```java
import static org.assertj.core.api.Assertions.*;

// Standard Assertions (JUnit built-in) vs AssertJ comparison:

// BEFORE (JUnit Assertions):
assertEquals("alice@example.com", user.getEmail());
assertTrue(user.isActive());
assertNotNull(user.getCreatedAt());

// AFTER (AssertJ — same assertions, richer failure output):
assertThat(user.getEmail()).isEqualTo("alice@example.com");
assertThat(user.isActive()).isTrue();
assertThat(user.getCreatedAt()).isNotNull().isBefore(Instant.now());

// AssertJ strengths: collection assertions
List<Order> orders = orderService.findByCustomer("c1");
assertThat(orders)
    .hasSize(3)
    .extracting(Order::getStatus)
    .containsExactlyInAnyOrder("pending", "confirmed", "cancelled");

// Soft assertions — report all failures (like assertAll but more readable)
SoftAssertions softly = new SoftAssertions();
softly.assertThat(response.getId()).isNotNull();
softly.assertThat(response.getStatus()).isEqualTo("confirmed");
softly.assertThat(response.getTotal()).isEqualByComparingTo(BigDecimal.valueOf(150.00));
softly.assertAll(); // throws AssertionError listing all failures

// Exception assertions (prefer over assertThrows for message assertions):
assertThatThrownBy(() -> orderService.cancel("nonexistent"))
    .isInstanceOf(OrderNotFoundException.class)
    .hasMessageContaining("nonexistent")
    .hasNoCause();
```

**Rule:** Use `assertThat()` from AssertJ for all non-trivial assertions. Reserve `assertThrows` (JUnit built-in) only for the rare case where you need the exception object for further assertions outside AssertJ's `assertThatThrownBy`.

---

### Pact Contract Testing with JUnit 5  [community]

Pact consumer-driven contract tests use JUnit 5 extensions to manage the Pact mock provider lifecycle. The extension starts a local HTTP mock, executes the test body against it, and writes the pact file.

```java
import au.com.dius.pact.consumer.dsl.PactDslWithProvider;
import au.com.dius.pact.consumer.junit5.PactConsumerTestExt;
import au.com.dius.pact.consumer.junit5.PactTestFor;
import au.com.dius.pact.core.model.V4Pact;
import au.com.dius.pact.core.model.annotations.Pact;

@ExtendWith(PactConsumerTestExt.class)
@PactTestFor(providerName = "OrdersService")
class OrdersApiClientPactTest {

    @Pact(consumer = "FrontendApp")
    public V4Pact getOrderPact(PactDslWithProvider builder) {
        return builder
            .given("order ord_001 exists")
            .uponReceiving("GET order ord_001")
            .path("/orders/ord_001")
            .method("GET")
            .willRespondWith()
            .status(200)
            .headers(Map.of("Content-Type", "application/json"))
            .body(newJsonBody(o -> {
                o.stringType("id", "ord_001");
                o.stringType("status", "confirmed");
                o.numberType("total", 150.0);
            }).build())
            .toPact(V4Pact.class);
    }

    @Test
    @PactTestFor(pactMethod = "getOrderPact")
    @DisplayName("client maps 200 response to Order domain object")
    void getsOrder(MockServer mockServer) {
        OrdersApiClient client = new OrdersApiClient(mockServer.getUrl());
        Order order = client.getOrder("ord_001");
        assertThat(order.getId()).isEqualTo("ord_001");
        assertThat(order.getStatus()).isEqualTo("confirmed");
    }
}
```

---

### CI/CD Pyramid Enforcement  [community]

Separating JUnit test levels in CI allows fail-fast feedback: unit tests run first (fast gate), integration tests run second (slower, stop on first failure), and full E2E tests run last (slowest, optional for PRs).

```kotlin
// build.gradle.kts — three-task CI pipeline per test level
tasks.withType<Test> {
    useJUnitPlatform()
}

// Primary fast gate — unit tests only (< 30 seconds)
tasks.test {
    useJUnitPlatform {
        includeTags("unit")
    }
    testLogging { events("passed", "skipped", "failed") }
}

// Integration test task (runs after unit tests pass)
tasks.register<Test>("integrationTest") {
    useJUnitPlatform {
        includeTags("integration")
    }
    shouldRunAfter(tasks.test)
    testTimeout.set(Duration.ofMinutes(5))
    jvmArgs("-Xmx1g")  // more memory for containers
}

// Contract test task
tasks.register<Test>("contractTest") {
    useJUnitPlatform {
        includeTags("contract")
    }
    shouldRunAfter("integrationTest")
    systemProperty("pactPublishResults", System.getenv("CI") ?: "false")
}
```

```yaml
# .github/workflows/ci.yml — pipeline using task separation
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - run: ./gradlew test --info
      
  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    env:
      TC_CLOUD_TOKEN: ${{ secrets.TC_CLOUD_TOKEN }}  # optional: Testcontainers Cloud
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - run: ./gradlew integrationTest
      
  contract-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    env:
      PACT_BROKER_BASE_URL: ${{ vars.PACT_BROKER_URL }}
      PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - run: ./gradlew contractTest
```

---

### Cross-Language Framework Equivalents

| JUnit 5/6 (Java) | pytest (Python) | NUnit/.NET (C#) | Vitest/Jest (TypeScript) | Notes |
|---|---|---|---|---|
| `@Test` | `def test_*()` | `[Test]` | `it()` / `test()` | Test case declaration |
| `@BeforeEach` | `@pytest.fixture` (autouse) | `[SetUp]` | `beforeEach()` | Per-test setup |
| `@AfterEach` | `yield` in fixture | `[TearDown]` | `afterEach()` | Per-test teardown |
| `@BeforeAll` | `@pytest.fixture(scope='class')` | `[OneTimeSetUp]` | `beforeAll()` | Per-class setup |
| `@AfterAll` | `yield` in class fixture | `[OneTimeTearDown]` | `afterAll()` | Per-class teardown |
| `@ParameterizedTest` + `@CsvSource` | `@pytest.mark.parametrize` | `[TestCase(...)]` | `it.each([...])` | Data-driven tests |
| `@Nested` | Inner class / `class TestGroup` | Inner class | `describe()` nesting | Test grouping |
| `@ExtendWith` | `@pytest.fixture` / plugin | `[SetUpFixture]` | `vi.mock()` / custom fixture | Extension/plugin model |
| `@Tag` + `includeTags` | `@pytest.mark` + `-m "tag"` | `[Category]` | `vi.runBenchmarks()` / tags | Test filtering |
| `@Disabled` | `@pytest.mark.skip` | `[Ignore]` | `it.skip()` / `xit()` | Skip tests |
| `@Timeout` | `@pytest.mark.timeout` | `[Timeout]` | `{ timeout: ms }` | Test timeouts |
| `assertThrows(X, () -> ...)` | `pytest.raises(X)` | `Assert.Throws<X>()` | `expect(() => ...).toThrow(X)` | Exception testing |
| `@TempDir` | `tmp_path` fixture | `[TempPath]` | `os.tmpdir()` in `beforeEach` | Temp directory |
| `Assertions.assertAll()` | Manual collection | `Assert.Multiple()` | `expect.soft()` (Playwright) | Multi-failure assertion |
| AssertJ `assertThat().extracting()` | `assert [x.attr for x in list] == [...]` | `CollectionAssert.AreEquivalent` | `expect(arr).toEqual(expect.arrayContaining(...))` | Collection assertions |

---
|---|---|---|
| Unit (component test level) | `@Test`, `@ParameterizedTest`, `@Nested` | No I/O; Mockito for dependencies; runs in < 10 ms |
| Integration (component integration test level) | `@Test` + `@TestInstance(PER_CLASS)` + Testcontainers | Real I/O; `@BeforeAll` starts container; `@BeforeEach` resets state |
| System/E2E | `@Test` + REST-assured or Selenium/Playwright | Full-stack; `@BeforeAll` starts application; `@Tag("e2e")` for filtering |
| Contract (CDC) | `@ExtendWith(PactConsumerTestExt.class)` + `@Pact` | Pact mock server via extension; JUnit manages lifecycle |

**Parameterized tests sit squarely at the unit level** — they multiply test case count without multiplying test time. A single `@ParameterizedTest` with `@CsvSource` of 20 rows covers 20 boundary values in the same time as 1 test case. This is the primary tool for achieving high decision-coverage at the unit test level without copy-paste.

**`@Nested` classes map to the Arrange-Act-Assert structure** at suite level: one `@Nested` class per "given context", with individual `@Test` methods asserting different outcomes in that context. This eliminates the `given/when/then_` naming prefix pattern and replaces it with class hierarchy.

---

### JUnit 5 vs JUnit 4 Migration Reference

| JUnit 4 | JUnit 5/6 (Jupiter) | Notes |
|---|---|---|
| `@RunWith(MockitoJUnitRunner.class)` | `@ExtendWith(MockitoExtension.class)` | Extension API replaces runners |
| `@RunWith(SpringRunner.class)` | `@ExtendWith(SpringExtension.class)` | Or `@SpringBootTest` (auto-registers) |
| `@Before` | `@BeforeEach` | Renamed |
| `@After` | `@AfterEach` | Renamed |
| `@BeforeClass` | `@BeforeAll` | Must be `static` unless `@TestInstance(PER_CLASS)` |
| `@AfterClass` | `@AfterAll` | Must be `static` unless `@TestInstance(PER_CLASS)` |
| `@Ignore("…")` | `@Disabled("…")` | Reason string now required by convention |
| `@Test(expected = X.class)` | `assertThrows(X.class, () -> …)` | Cleaner; returns exception for chained assertions |
| `@Test(timeout = 500)` | `@Timeout(value = 500, unit = MILLISECONDS)` | Separate annotation |
| `@Rule` / `@ClassRule` | `@ExtendWith` / `@RegisterExtension` | Unified extension model |
| `Assume.assumeTrue(…)` | `Assumptions.assumeTrue(…)` | Same semantics; new package |
| `Assert.assertEquals(…)` | `Assertions.assertEquals(…)` | New package; same argument order |
| `@Category(FastTests.class)` | `@Tag("fast")` | String tags replace category interfaces |
| `@Parameterized.Parameters` + `@RunWith(Parameterized.class)` | `@ParameterizedTest` + source annotations | Much simpler; no separate runner |

**Running JUnit 4 tests on JUnit 5 Platform (Vintage):**

```groovy
// build.gradle — add JUnit Vintage engine to run old JUnit 4 tests
testImplementation("org.junit.vintage:junit-vintage-engine:5.11.0")
```

Note: JUnit Vintage is deprecated in JUnit 6. Target: migrate all JUnit 4 tests to Jupiter during the current sprint cycle.

---

### Build Tool Configuration

#### Gradle (Kotlin DSL)

```kotlin
// build.gradle.kts
dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.11.0")
    // For parameterized tests (included in junit-jupiter BOM):
    // testImplementation("org.junit.jupiter:junit-jupiter-params:5.11.0")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
    useJUnitPlatform()

    // JVM options for faster test runs
    jvmArgs("-XX:+EnableDynamicAgentLoading")

    // Tag filtering
    systemProperty("junit.jupiter.execution.parallel.enabled", "true")
    systemProperty("junit.jupiter.execution.parallel.mode.default", "concurrent")
}
```

#### Maven

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.11.0</version>
    <scope>test</scope>
</dependency>

<build>
  <plugins>
    <plugin>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>3.2.5</version>
      <!-- JUnit Platform is auto-detected by Surefire 3.x — no extra config needed -->
    </plugin>
  </plugins>
</build>
```

---

### Parallel Test Execution

```properties
# src/test/resources/junit-platform.properties
# Enable parallel execution (JUnit 5.3+)
junit.jupiter.execution.parallel.enabled = true
junit.jupiter.execution.parallel.mode.default = concurrent
junit.jupiter.execution.parallel.mode.classes.default = concurrent

# Limit parallelism to available processors
junit.jupiter.execution.parallel.config.strategy = dynamic
junit.jupiter.execution.parallel.config.dynamic.factor = 1.0

# Force sequential for specific test classes (e.g., those using shared state)
# Annotate the class: @Execution(ExecutionMode.SAME_THREAD)
```

**Parallel gotchas:**
- Parallel execution requires test cases to be stateless or use `@TestInstance(PER_METHOD)` (the default). Shared mutable state produces intermittent failures.
- Annotate tests with `@Execution(ExecutionMode.SAME_THREAD)` to opt out of parallelism for test classes that use shared resources (DB containers, port-binding servers).
- `@RepeatedTest` and `@ParameterizedTest` invocations run concurrently within the method by default when parallel is enabled — ensure the test method is re-entrant.

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| One assertion per test case, even when they test the same behaviour | Multiplies test count without adding coverage; creates a misleading "green" signal | Use `assertAll()` to group related assertions in one test case |
| JUnit 4 `@RunWith` + `@Test(expected = …)` still in use | Verbose; hides exception message; prevents asserting on exception fields | Migrate to `assertThrows()` which returns the exception |
| Static state in test classes without `@TestInstance(PER_CLASS)` | Per-method lifecycle creates a new instance; static fields persist across test cases and cause test pollution | Declare shared expensive resources as `@BeforeAll` / `@AfterAll` static blocks, or switch to `@TestInstance(PER_CLASS)` with explicit `@BeforeEach` cleanup |
| `@Disabled` without a reason | "Disabled" tests accumulate without context; nobody knows why they were disabled or when they will be re-enabled | Always provide a reason: `@Disabled("JTK-1234: payment gateway mock not available in CI yet")` |
| `@ParameterizedTest` with a single argument row | Defeats the purpose; a regular `@Test` is clearer | Use `@Test` for single scenarios; use `@ParameterizedTest` only when there are ≥ 2 input variations |
| Mixing unit and integration tests in the same test class | Unit tests run fast; integration tests start containers. Mixing them slows unit feedback | Use separate test classes or separate source sets; tag them differently; run unit tests first in CI |
| `assertThrows` without asserting on the exception | Tests that the code throws *any* exception, not the *right* exception with the right message | `ValidationException ex = assertThrows(ValidationException.class, () -> …); assertThat(ex.getMessage()).contains("…");` |
| Overusing `@Nested` for flat suites | `@Nested` adds value only when inner classes have distinct contexts (different `@BeforeEach` setups). Flat test classes with one `@Nested` level for no contextual reason are harder to read | Use `@Nested` only when the inner class adds a meaningful contextual `@BeforeEach` setup or groups logically distinct contexts |
| `@BeforeAll` without container sharing pattern | `@BeforeAll` runs once but if the container is not shared (e.g., created in `@BeforeEach`), you pay start-up cost per test case | Use `@TestInstance(PER_CLASS)` + `@BeforeAll` for container-dependent tests; verify start-up happens only once |
| Ignoring `@Tag` in CI | Tags are defined in code but never used in the build script to separate fast and slow tests | Configure `useJUnitPlatform { includeTags("unit") }` for the primary test task; add a separate `integrationTest` task |
| Using H2 in-memory DB for `@DataJpaTest` | H2 dialect diverges from Postgres — unique constraints, JSON operators, `ON CONFLICT` clauses silently behave differently | Replace `@AutoConfigureTestDatabase` with a Testcontainers `PostgreSQLContainer` via `@DynamicPropertySource` |
| `@SpringBootTest` for every test class | Full context start-up takes 5–30 seconds; doing it per class accumulates to minutes of CI overhead | Use test slices (`@WebMvcTest`, `@DataJpaTest`) for layer-specific tests; reserve `@SpringBootTest` for true full-stack integration tests |
| `@Mock` without `@ExtendWith(MockitoExtension.class)` | Field-injected `@Mock` annotations are not processed without the extension — fields remain null | Add `@ExtendWith(MockitoExtension.class)` to the class; or use `Mockito.mock(X.class)` in `@BeforeEach` explicitly |
| `@RepeatedTest` for flakiness detection in production tests | `@RepeatedTest(5)` masks flakiness instead of fixing it; every CI run pays 5x the test cost | Use `@RepeatedTest` only during flakiness investigation; fix the root cause and remove the repetition before merging |

---

## Real-World Gotchas  [community]

1. **`@BeforeAll` must be `static` by default** — teams upgrading from JUnit 4 add `@BeforeAll` to instance methods and get `JUnitException: @BeforeAll method must be static`. Fix: make the method `static` or add `@TestInstance(Lifecycle.PER_CLASS)` to the class.

2. **`assertThrows` catches the exception and returns it — the lambda must actually throw** — if the production code does not throw, `assertThrows` fails with "Expected … to be thrown, but nothing was thrown." A common mistake is passing a supplier that calls a void method: `assertThrows(X.class, () -> { service.doSomething(); })` — only works if `doSomething()` itself throws, not if it returns normally.

3. **`@ParameterizedTest` display names use `{index}` and `{0}`, `{1}` etc.** — the `{index}` placeholder generates a 1-based sequential index; `{0}`, `{1}` reference argument positions. Without a `name` attribute, the default is `[{index}] {arguments}` which is acceptable but verbose. Define a `name` template to make test reports readable.

4. **`@TempDir` cleanup fails on Windows when files are still open** — JUnit 5 attempts to delete the temp directory after the test. On Windows, if any handle to a file in the directory is still open (e.g., a FileInputStream not closed in `@AfterEach`), deletion fails silently (no test failure, just orphaned files). Fix: always close file handles in `@AfterEach` before JUnit attempts cleanup.

5. **Parallel execution with `@ParameterizedTest` and shared Mockito mocks** — when parallel execution is enabled, Mockito's `@Mock` fields (created per class instance in `PER_METHOD` mode) are safe. But `@InjectMocks` with a singleton service can cause cross-invocation interference if the service holds state. Fix: inject fresh mocks in `@BeforeEach` rather than relying on field injection alone.

6. **`@CsvSource` null values require a sentinel** — by default, `""` is treated as an empty string, not null. To pass null: use `nullValues = "NULL"` attribute: `@CsvSource(value = { "NULL, expected" }, nullValues = { "NULL" })`.

7. **`@ExtendWith` ordering matters** — extensions are applied in declaration order. If `@ExtendWith(MockitoExtension.class)` is listed after `@ExtendWith(SpringExtension.class)`, Mockito cannot inject mocks before Spring creates the context. Fix: follow the canonical order for your stack (e.g., Spring first, then Mockito, then custom extensions).

8. **JUnit Platform configuration file location** — `junit-platform.properties` must be on the classpath root, typically `src/test/resources/junit-platform.properties`. Placing it in `src/main/resources` or the wrong module in a multi-module project causes configuration to be silently ignored.

9. **`@TestFactory` methods must return `Stream`, `Iterable`, `Collection`, or `Iterator<DynamicNode>`** — returning `List<String>` instead of `Stream<DynamicTest>` produces a `PreconditionViolationException`. The `DynamicTest.dynamicTest(displayName, executable)` factory method is the correct entry point.

10. **Maven Surefire 2.x does not discover JUnit 5 tests** — teams on legacy Maven builds (Surefire 2.18–2.22) must explicitly add the `junit-platform-launcher` and `junit-vintage-engine` or upgrade to Surefire 3.x. Without it, test discovery silently finds zero tests and the build "passes" with no test executions.

11. **Spring context caching breaks between test slices** — Spring Boot caches the application context across test classes that use the same context configuration. Modifying a mock with `@MockBean` creates a different context key, causing a new (slow) context start-up. Fix: extract shared mock beans to a base class or `@TestConfiguration` class so context keys remain stable across test classes.

12. **`@DynamicPropertySource` must be `static`** — teams try to use `@DynamicPropertySource` on instance methods to configure container properties; it must be static. If `@TestInstance(PER_CLASS)` is set, it still must be static. Non-static methods are silently ignored, leading to `null` datasource URLs.

13. **Testcontainers container not marked `static` = one container per test method** — if a `@Container` field is not `static`, Testcontainers creates and destroys a new container for every test method in the class. On a 30-test class, this means 30 Postgres start-ups, each taking ~3 seconds = 90 seconds of overhead. Always declare `@Container` fields as `static` (or use `@TestInstance(PER_CLASS)` with non-static fields).

14. **JUnit 6 deprecates JUnit Vintage** — migrating from JUnit 4 to JUnit 6 requires removing the Vintage engine from the build and migrating all `@RunWith`, `@Rule`, and `@ClassRule` usages to Jupiter equivalents. The migration guide is at `https://junit.org/junit5/docs/current/user-guide/#migrating-from-junit4`. Teams that delay migration will find Vintage removed entirely in a future release.

15. **`@Disabled` tests accumulate without CI lint** — disabled tests are not failures and pass CI silently. Without a lint rule that fails the build when `@Disabled` count exceeds a threshold (or when `@Disabled` tests are older than 30 days), teams accumulate a graveyard of permanently-disabled tests that reduce effective coverage. Fix: add a CI step that counts `@Disabled` annotations in the codebase and fails if above a configured threshold; reference the tracking issue in every `@Disabled("JIRA-1234: …")` annotation.

16. **Parallel `@SpringBootTest` exhausts database connections** — when JUnit parallel execution starts multiple test classes simultaneously and each has a `@SpringBootTest` that opens a connection pool, the shared test database runs out of connections. Fix: use `@TestInstance(PER_CLASS)` + `@Execution(SAME_THREAD)` on Spring integration tests, or configure the test datasource with a connection pool size equal to the number of parallel test workers.

17. **`@MockBean` causes full Spring context refresh** — adding or removing a `@MockBean` on any test class invalidates the Spring context cache for all test classes that share that context configuration. In a project with 50 integration test classes, adding one `@MockBean` can add 2–3 minutes to CI because contexts must be rebuilt. Fix: consolidate `@MockBean` declarations in a shared `@TestConfiguration` base class; avoid per-test `@MockBean` additions.

---

## Tradeoffs & Alternatives

| Dimension | JUnit 5/6 Jupiter | TestNG | Spock (Groovy) | Kotest (Kotlin) |
|---|---|---|---|---|
| Language | Java, Kotlin, Groovy | Java, Kotlin | Groovy | Kotlin |
| Parameterized tests | `@ParameterizedTest` + sources | `@DataProvider` | `where:` table (spec-style) | `withData {}` or `forAll {}` |
| Extension model | `@ExtendWith` (callback interfaces) | `@Listeners` (ITestListener) | Spock extension points | Listeners + extensions |
| Parallel execution | Built-in (JUnit Platform, PER_CLASS/PER_METHOD) | Built-in (thread pool config) | Third-party or sequential | Built-in coroutine-based |
| IDE support | Excellent (IntelliJ, Eclipse, VS Code) | Excellent | Good (IntelliJ first-class) | Good (IntelliJ only) |
| Spring Boot integration | `@SpringBootTest` (auto-configured) | `SpringRunner` equivalent | `@SpringBootTest` (via bridge) | Spring extension available |
| Adoption | Industry default for Java | Legacy preference in enterprise | Popular in BDD-style teams | Growing in Kotlin projects |
| Migration from JUnit 4 | Vintage engine bridges; migration guide available | Separate runner | Rewrite required | Rewrite required |

**When to choose JUnit 5/6:** New JVM projects where Java is the primary language, Spring Boot projects, any team following industry-standard practices. JUnit 5/6 is the default test framework for Maven and Gradle archetypes.

**When to choose Kotest:** Kotlin-first projects wanting coroutine-native test execution and property-based testing built in.

**When to choose Spock:** Teams that want specification-style (given/when/then blocks in Groovy), especially for complex parameterized scenarios where Spock's `where:` table is more readable than `@CsvSource`.

---

### Adoption Costs  [community]

| Concern | Cost | Mitigation |
|---------|------|-----------|
| Migration from JUnit 4 | Medium (1–3 sprint cycles for a large codebase) | Run JUnit 4 and JUnit 5 tests in parallel via JUnit Vintage engine during migration; migrate class-by-class |
| Testcontainers CI setup | Low–Medium (4–8 h initial config) | Use `@DynamicPropertySource` pattern; pin container versions in a central constants class |
| Testcontainers Cloud agent | Low (1–2 h) + billing | Set `TC_CLOUD_TOKEN` as a CI secret; transparent to test code; free tier available |
| Parallel execution tuning | Medium (1–2 days of trial/error) | Start with `dynamic` strategy factor 0.5; monitor DB connection exhaustion before scaling up |
| Spring context caching | Low to fix after identification | Consolidate `@MockBean` in base classes; inspect context cache hits with `-Dspring.test.context.cache.maxSize=32` |
| AssertJ adoption | Low | Replace `assertEquals` with `assertThat` one class at a time; IDE can auto-migrate with structural search+replace |
| `@Tag` infrastructure | Low | Add `@Tag` annotations in one sprint; wire Gradle/Maven tasks in the same sprint |

**JUnit 5 → JUnit 6 migration checklist:**
- [ ] Remove `junit-vintage-engine` from `build.gradle.kts` (deprecated in JUnit 6)
- [ ] Upgrade all `@RunWith(…)` to `@ExtendWith(…)`
- [ ] Migrate `@Before`/`@After` to `@BeforeEach`/`@AfterEach`
- [ ] Migrate `@BeforeClass`/`@AfterClass` to `@BeforeAll`/`@AfterAll` (add `static` or `@TestInstance(PER_CLASS)`)
- [ ] Replace `@Test(expected = X.class)` with `assertThrows(X.class, () -> …)`
- [ ] Replace `@Ignore` with `@Disabled("reason")` — reason string required
- [ ] Migrate `@Category` to `@Tag`
- [ ] Replace `Assert.*` with `Assertions.*` (or AssertJ's `assertThat`)
- [ ] Verify `maven-surefire-plugin` version is 3.x (not 2.x)

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| JUnit 5/6 User Guide | Official | https://docs.junit.org/current/user-guide/ | Complete API reference; JUnit Platform + Jupiter + Vintage |
| junit-examples GitHub | Examples | https://github.com/junit-team/junit5-samples | Starter projects for Gradle, Maven, Ant, Bazel, sbt with Java/Kotlin/Groovy |
| Mockito Extension | Library | https://site.mockito.org/ | `@ExtendWith(MockitoExtension.class)` — `@Mock`, `@InjectMocks`, `@Captor` |
| Testcontainers JUnit 5 | Library | https://java.testcontainers.org/test_framework_integration/junit_5/ | `@Testcontainers` + `@Container` annotations integrate with JUnit lifecycle |
| Testcontainers Cloud | SaaS | https://testcontainers.com/cloud/docs/ | Cloud Docker daemon for CI without local Docker; 8 GB/session; Turbo mode for parallelism |
| Testcontainers Guides | Guides | https://testcontainers.com/guides/ | Practical guides: Spring Boot, Quarkus, ASP.NET, DB, Kafka, WireMock, LocalStack patterns |
| AssertJ | Library | https://assertj.github.io/doc/ | Fluent assertion library; cleaner than `Assertions.*` for complex matchers; `assertThatThrownBy`, `extracting` |
| WireMock JUnit 5 extension | Library | https://wiremock.org/docs/junit-jupiter/ | `@RegisterExtension WireMockExtension` for HTTP stub-based integration tests |
| Spring Boot Test | Library | https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing | `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`, `@JsonTest` — JUnit 5 backed |
| Pact JUnit 5 Extension | Library | https://docs.pact.io/implementation_guides/jvm/provider/junit5 | `@ExtendWith(PactConsumerTestExt.class)` — consumer-driven contract tests with JUnit lifecycle |
| Maven Surefire Plugin 3.x | Plugin | https://maven.apache.org/surefire/maven-surefire-plugin/ | Auto-discovers JUnit Platform; `<groups>` for tag filtering |
| Gradle test docs | Plugin | https://docs.gradle.org/current/dsl/org.gradle.api.tasks.testing.Test.html | `useJUnitPlatform()`, `includeTags`, `excludeTags` |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology (test case, test suite, test level) |
| JUnit 5/6 Migration Guide | Official | https://junit.org/junit5/docs/current/user-guide/#migrating-from-junit4 | Step-by-step JUnit 4 → Jupiter migration checklist |
| Kotest | Library | https://kotest.io/ | Kotlin-first test framework; coroutine-native; property-based testing built in |
