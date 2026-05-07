# Test Framework (JUnit 5/6) — QA Methodology Guide
<!-- lang: Java | topic: test-framework | iteration: 1 | score: 88/100 | date: 2026-05-07 -->
<!-- sources: official: docs.junit.org/current/user-guide/ (JUnit 6.0.3, WebFetch 2026-05-07) | ISTQB CTFL 4.0 terminology applied -->
<!-- covers: JUnit Platform + Jupiter + Vintage; annotations, lifecycle, parameterized tests, @Nested, @TestFactory, extensions, TDD/pyramid patterns -->

---

> **Quick reference:** JUnit 5/6 = JUnit Platform (launcher) + JUnit Jupiter (test API) + JUnit Vintage (JUnit 3/4 bridge). Requires Java 17+. Core annotations: `@Test`, `@BeforeEach`/`@AfterEach`, `@BeforeAll`/`@AfterAll`, `@ParameterizedTest` (multiple sources), `@TestFactory` for dynamic tests, `@Nested` for hierarchical suites, `@ExtendWith` for extensions. Pyramid placement: JUnit Jupiter is the unit-test level framework for JVM languages; parameterized tests are the primary vehicle for data-driven unit coverage; `@Nested` mirrors the Arrange-Act-Assert structure at class level.

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

### JUnit 5/6 in the Test Pyramid

| Test level | JUnit role | Typical setup |
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

---

## Real-World Gotchas [community]

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

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| JUnit 5/6 User Guide | Official | https://docs.junit.org/current/user-guide/ | Complete API reference; JUnit Platform + Jupiter + Vintage |
| junit-examples GitHub | Examples | https://github.com/junit-team/junit5-samples | Starter projects for Gradle, Maven, Ant, Bazel, sbt with Java/Kotlin/Groovy |
| Mockito Extension | Library | https://site.mockito.org/ | `@ExtendWith(MockitoExtension.class)` — `@Mock`, `@InjectMocks`, `@Captor` |
| Testcontainers JUnit 5 | Library | https://java.testcontainers.org/test_framework_integration/junit_5/ | `@Testcontainers` + `@Container` annotations integrate with JUnit lifecycle |
| AssertJ | Library | https://assertj.github.io/doc/ | Fluent assertion library; cleaner than `Assertions.*` for complex matchers |
| WireMock JUnit 5 extension | Library | https://wiremock.org/docs/junit-jupiter/ | `@RegisterExtension WireMockExtension` for HTTP stub-based integration tests |
| Spring Boot Test | Library | https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing | `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest` — JUnit 5 backed |
| Maven Surefire Plugin 3.x | Plugin | https://maven.apache.org/surefire/maven-surefire-plugin/ | Auto-discovers JUnit Platform; `<groups>` for tag filtering |
| Gradle test docs | Plugin | https://docs.gradle.org/current/dsl/org.gradle.api.tasks.testing.Test.html | `useJUnitPlatform()`, `includeTags`, `excludeTags` |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology (test case, test suite, test level) |
