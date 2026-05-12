# Java Patterns & Best Practices
<!-- sources: official (Oracle JDK 21-25 docs, Oracle Interface/Inheritance tutorial, awesome-java, iluwatar/java-design-patterns, Oracle Stream package-summary, OpenJDK JEP index, JEP 491, JEP 477, JEP 454 FFM, JEP 484 Class-File API, JEP 502 Stable Values, JEP 505 Structured Concurrency updated, JUnit 5.11-5.13 release notes, JUnit 6.0 release notes, Mockito 5.x-5.22 release notes, AssertJ 3.27 release notes, Testcontainers 2.0 release notes, WireMock docs, Awaitility docs, Spring Boot 3.4-3.5 release notes, Spring Framework 6.2 MockitoBean docs, MockMvcTester docs, JPMS official tutorial, Hexagonal Architecture official) | community (practitioner synthesis, Effective Java principles, awesome-java, OpenJDK JEPs, Spring pitfalls, JPA gotchas, practitioner testing patterns, JPMS pitfalls, Valhalla community analysis, locale deprecation, Object.wait pinning, teeing collector, Path.of idiom, List.copyOf null semantics, Spring @Async self-invocation, HikariCP connection pool, Thread.Builder API, KDF security APIs, @ServiceConnection pattern, @MockitoBean migration, MockMvcTester fluent assertions, JUnit 5.11 @FieldSource @AutoClose, JUnit 5.12 @EnumSource range, JUnit 5.13 @ParameterizedClass, Testcontainers 2.0 module renaming, JUnit 6.0 migration, AssertJ 3.27 CompletableFuture assertions, Spring Boot 3.5 SSL Testcontainers, Mockito 5.22 Kotlin singleton mocking) | mixed | iteration: 32 | score: 98/100 | date: 2026-05-12 -->

## Core Philosophy

1. **Prefer interfaces over classes as types** — program to abstractions so implementations can be swapped without cascading changes throughout the codebase.
2. **Fail fast and make illegal states unrepresentable** — use type-system features (Optional, sealed classes, records) to make bad states impossible to construct rather than catching them at runtime.
3. **Immutability by default** — immutable objects are thread-safe and easier to reason about; add mutability only when there's a compelling performance reason.
4. **Composition over inheritance** — favour delegation and interface-based composition; deep inheritance hierarchies couple callers to internal implementation details.
5. **Treat checked exceptions as part of the API contract** — throw them only when the caller can realistically recover; use unchecked exceptions for programming errors and unrecoverable failures.

---

## Principles / Patterns

### Builder Pattern
When a class requires more than three or four constructor parameters — especially optional ones — the telescoping-constructor approach becomes unreadable and error-prone. The Builder pattern provides a fluent API that names each argument and enforces a valid, complete object on `build()`.

```java
public final class HttpRequest {
    private final String url;
    private final String method;
    private final int timeoutMs;
    private final boolean followRedirects;

    private HttpRequest(Builder b) {
        this.url            = Objects.requireNonNull(b.url, "url");
        this.method         = b.method;
        this.timeoutMs      = b.timeoutMs;
        this.followRedirects = b.followRedirects;
    }

    public static final class Builder {
        private final String url;           // required
        private String method         = "GET";
        private int    timeoutMs      = 5_000;
        private boolean followRedirects = true;

        public Builder(String url) { this.url = url; }

        public Builder method(String method) {
            this.method = method;
            return this;
        }

        public Builder timeoutMs(int ms) {
            this.timeoutMs = ms;
            return this;
        }

        public Builder followRedirects(boolean follow) {
            this.followRedirects = follow;
            return this;
        }

        public HttpRequest build() { return new HttpRequest(this); }
    }
}

// Usage
HttpRequest req = new HttpRequest.Builder("https://api.example.com/data")
        .method("POST")
        .timeoutMs(10_000)
        .followRedirects(false)
        .build();
```

### Static Factory Methods (Effective Java Item 1)
Prefer static factory methods over constructors. They have names (making intent clear), can return cached/singleton instances, can return subtypes, and can encapsulate complex initialization logic. This is the pattern behind `Optional.of()`, `List.of()`, `Path.of()`, and `Comparator.comparing()`.

```java
public final class Connection {
    private final String url;
    private final boolean readOnly;

    // Private constructor — all creation goes through factories
    private Connection(String url, boolean readOnly) {
        this.url = url;
        this.readOnly = readOnly;
    }

    // Named factory methods — intent is explicit
    public static Connection readWrite(String url) {
        return new Connection(url, false);
    }

    public static Connection readOnly(String url) {
        return new Connection(url, true);
    }

    // Factory that returns cached instances (flyweight-style)
    private static final Connection DEV_CONNECTION =
        new Connection("jdbc:h2:mem:test", false);

    public static Connection dev() {
        return DEV_CONNECTION;  // same instance every time
    }
}

// Usage — intent is self-documenting
var conn = Connection.readOnly("jdbc:postgresql://prod-db/myapp");
var dev  = Connection.dev();

// Enum-based factory: maps domain types to implementations
public sealed interface Parser<T> permits JsonParser, XmlParser, CsvParser {
    T parse(String input);

    static <T> Parser<T> forFormat(String format, Class<T> type) {
        return switch (format.toLowerCase()) {
            case "json" -> new JsonParser<>(type);
            case "xml"  -> new XmlParser<>(type);
            case "csv"  -> new CsvParser<>(type);
            default     -> throw new IllegalArgumentException("Unknown format: " + format);
        };
    }
}
```

### Optional\<T\> — Representing Absence Explicitly
`Optional<T>` eliminates null-related `NullPointerException` at call sites by making the absence of a value part of the type signature. Use it as a return type when a method might return no result; never use it as a field type or parameter type.

```java
import java.util.Optional;

public class UserRepository {
    private final Map<Long, User> store = new HashMap<>();

    public Optional<User> findById(long id) {
        return Optional.ofNullable(store.get(id));
    }
}

// Caller — no null checks, declarative handling
userRepository.findById(42L)
    .map(User::getEmail)
    .filter(email -> email.contains("@company.com"))
    .ifPresentOrElse(
        email -> System.out.println("Internal user: " + email),
        ()    -> System.out.println("User not found or external")
    );

// Chain with fallback
String displayName = userRepository.findById(id)
    .map(User::getDisplayName)
    .orElse("Anonymous");
```

### Streams API — Declarative Data Processing
The Streams API (java.util.stream) transforms sequential data processing from imperative loops to a pipeline of composable operations. Lazy evaluation means intermediate operations cost nothing unless a terminal operation is invoked. `flatMap` flattens nested structures; `mapMulti` (Java 16+) is a performant alternative for conditional expansion.

```java
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

record Order(String customerId, double total, String status) {}
record Customer(String id, List<Order> orders) {}

public class OrderAnalysis {
    public Map<String, Double> totalsByCustomer(List<Order> orders) {
        return orders.stream()
            .filter(o -> "COMPLETED".equals(o.status()))
            .collect(Collectors.groupingBy(
                Order::customerId,
                Collectors.summingDouble(Order::total)
            ));
    }

    public List<String> topCustomers(List<Order> orders, int limit) {
        return orders.stream()
            .filter(o -> "COMPLETED".equals(o.status()))
            .collect(Collectors.groupingBy(
                Order::customerId,
                Collectors.summingDouble(Order::total)
            ))
            .entrySet().stream()
            .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
            .limit(limit)
            .map(Map.Entry::getKey)
            .toList();   // Java 16+ unmodifiable list
    }

    // flatMap — flatten nested collections into a single stream
    public List<Order> allOrdersForCustomers(List<Customer> customers) {
        return customers.stream()
            .flatMap(c -> c.orders().stream())   // Customer → Stream<Order>
            .filter(o -> o.total() > 0)
            .toList();
    }

    // mapMulti (Java 16+) — more efficient than flatMap for conditional multi-expansion
    // Push 0, 1, or N elements per input without allocating intermediate streams
    public List<String> expandTags(List<Order> orders) {
        return orders.<String>mapMulti((order, downstream) -> {
            downstream.accept(order.customerId());
            if (order.total() > 100) {
                downstream.accept("HIGH_VALUE:" + order.customerId());
            }
            // emit nothing for orders with zero total
        }).distinct().toList();
    }
}
```

### Checked vs. Unchecked Exceptions
Checked exceptions (subclasses of `Exception` but not `RuntimeException`) are part of the method signature. They signal recoverable conditions the caller is expected to handle — e.g., `IOException` for file operations. Unchecked exceptions (`RuntimeException` and its subclasses) indicate programming errors or unrecoverable failures.

```java
// GOOD — checked exception for recoverable I/O failure
public byte[] readConfig(Path path) throws IOException {
    return Files.readAllBytes(path);
}

// GOOD — unchecked for invalid precondition (programming error)
public void setAge(int age) {
    if (age < 0 || age > 150) {
        throw new IllegalArgumentException("Age out of range: " + age);
    }
    this.age = age;
}

// BAD — swallowing checked exception hides the failure
public byte[] readConfigSilent(Path path) {
    try {
        return Files.readAllBytes(path);
    } catch (IOException e) {
        return new byte[0]; // caller has no idea something went wrong
    }
}

// BETTER — wrap and re-throw if checked exception doesn't fit the abstraction
public Config loadConfig(Path path) {
    try {
        byte[] bytes = Files.readAllBytes(path);
        return Config.parse(bytes);
    } catch (IOException e) {
        throw new ConfigLoadException("Failed to load config from " + path, e);
    }
}
```

### Interface-First Design
Define behaviour through interfaces before writing concrete implementations. This decouples callers from implementation details and makes substitution (including test doubles) trivial.

```java
// Define the contract
public interface NotificationSender {
    void send(Notification notification);
}

// Concrete implementation
public class EmailSender implements NotificationSender {
    private final SmtpClient smtp;

    public EmailSender(SmtpClient smtp) {
        this.smtp = smtp;
    }

    @Override
    public void send(Notification n) {
        smtp.sendEmail(n.recipient(), n.subject(), n.body());
    }
}

// Test double — no mocking framework needed
public class InMemorySender implements NotificationSender {
    private final List<Notification> sent = new ArrayList<>();

    @Override
    public void send(Notification n) { sent.add(n); }

    public List<Notification> getSent() { return Collections.unmodifiableList(sent); }
}

// Service depends on the interface — not the concrete class
public class OrderService {
    private final NotificationSender sender;

    public OrderService(NotificationSender sender) {   // injected
        this.sender = sender;
    }
}
```

### Immutable Value Objects / Records (Java 16+)
Records are the idiomatic way to create immutable value carriers in modern Java. They auto-generate constructor, accessors, `equals`, `hashCode`, and `toString`. For pre-Java 16 code, hand-craft immutable classes using `final` fields and a private constructor.

```java
// Java 16+ record — immutable by default, compact notation
public record Money(BigDecimal amount, Currency currency) {

    // Compact canonical constructor for validation
    public Money {
        Objects.requireNonNull(amount,   "amount");
        Objects.requireNonNull(currency, "currency");
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }
        amount = amount.setScale(currency.getDefaultFractionDigits(), RoundingMode.HALF_EVEN);
    }

    public Money add(Money other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException("Currency mismatch");
        }
        return new Money(amount.add(other.amount), currency);
    }
}

// Usage — each operation returns a new instance
Money price = new Money(new BigDecimal("9.99"), Currency.getInstance("USD"));
Money tax   = new Money(new BigDecimal("0.80"), Currency.getInstance("USD"));
Money total = price.add(tax);  // returns new Money(10.79, USD)
```

### Defensive Programming with `java.util.Objects`
The `Objects` utility class (since Java 7, significantly enhanced through Java 16+) provides null-safe operations and precondition checks that should be used in all public API entry points.

```java
import java.util.Objects;

public final class Invoice {
    private final String invoiceId;
    private final List<LineItem> lineItems;
    private final BigDecimal discount;

    public Invoice(String invoiceId, List<LineItem> lineItems, BigDecimal discount) {
        // Fail-fast validation with meaningful messages
        this.invoiceId  = Objects.requireNonNull(invoiceId, "invoiceId must not be null");
        this.lineItems  = List.copyOf(Objects.requireNonNull(lineItems, "lineItems"));
        this.discount   = Objects.requireNonNullElse(discount, BigDecimal.ZERO); // fallback
    }

    // Null-safe equality — avoids NPE when either side may be null
    public boolean sameInvoice(Invoice other) {
        return Objects.equals(this.invoiceId, other.invoiceId);
    }

    // Null-safe hash for use in collections
    @Override
    public int hashCode() {
        return Objects.hash(invoiceId, discount);
    }

    // Java 9+: Objects.requireNonNullElseGet for lazy default
    public static Invoice withDefaults(String id, List<LineItem> items) {
        BigDecimal discount = Objects.requireNonNullElseGet(
            fetchDiscount(id),
            () -> BigDecimal.ZERO  // only computed if fetchDiscount returns null
        );
        return new Invoice(id, items, discount);
    }

    // Java 9+: Objects.checkIndex / checkFromToIndex for array bounds
    public LineItem getItem(int index) {
        Objects.checkIndex(index, lineItems.size()); // throws IndexOutOfBoundsException if invalid
        return lineItems.get(index);
    }
}
```

### Generics Bounds — PECS and Type-Safe Containers
Use bounded wildcards to write flexible, reusable APIs. The PECS mnemonic — **Producer Extends, Consumer Super** — tells you when to use `? extends T` (you're reading from the collection) vs. `? super T` (you're writing to it).

```java
import java.util.List;

public class Collections {

    // Producer — you READ from src, so src uses ? extends T
    public static <T> void copy(List<? super T> dest, List<? extends T> src) {
        for (T item : src) {
            dest.add(item);
        }
    }

    // Bounded type parameter ensures Comparable
    public static <T extends Comparable<T>> T max(List<T> list) {
        if (list.isEmpty()) throw new IllegalArgumentException("Empty list");
        T result = list.get(0);
        for (T item : list) {
            if (item.compareTo(result) > 0) result = item;
        }
        return result;
    }
}

// Type-safe heterogeneous container — advanced pattern from Effective Java Item 33
public class TypeSafeContainer {
    private final Map<Class<?>, Object> map = new HashMap<>();

    public <T> void put(Class<T> type, T value) {
        map.put(Objects.requireNonNull(type), value);
    }

    public <T> T get(Class<T> type) {
        return type.cast(map.get(type));
    }
}

// Wildcard capture helper — enables mutation of wildcarded collections
// through a private helper method that "captures" the wildcard into a named T
public class WildcardCapture {
    // Public method with wildcard — caller doesn't need to name the type
    public static void swap(List<?> list, int i, int j) {
        swapHelper(list, i, j);  // delegate to helper for type safety
    }

    // Private helper captures the wildcard into T — enables set()
    private static <T> void swapHelper(List<T> list, int i, int j) {
        T tmp = list.get(i);
        list.set(i, list.get(j));
        list.set(j, tmp);
    }
}
```

### var — Local Variable Type Inference (Java 10+)
`var` infers the type of local variables from the right-hand side, reducing boilerplate without losing static typing. Use it when the type is obvious from context; avoid it when it obscures the type and harms readability.

```java
// GOOD — type obvious from constructor on the right
var users         = new ArrayList<User>();
var userMap       = new HashMap<String, User>();
var configPath    = Path.of("/etc/myapp/config.json");

// GOOD — eliminates verbose generic repetition in loops
for (var entry : userMap.entrySet()) {
    System.out.println(entry.getKey() + " -> " + entry.getValue());
}

// BAD — return type of method call is not obvious
var result = process(data);   // What type is result?

// BAD — in lambda parameters where it adds nothing
// (inference already works without var here)
users.stream().map((var u) -> u.getName());  // prefer: .map(User::getName)
```

### Virtual Threads (Java 21) — Scalable Concurrency Without Reactor Complexity
Virtual threads are lightweight threads managed by the JVM rather than the OS. They enable thread-per-request style code (blocking I/O, familiar `try/catch` error handling) to scale to millions of concurrent operations without the callback complexity of reactive frameworks. The JVM automatically mounts/unmounts virtual threads on carrier OS threads when they block.

```java
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.List;

public class VirtualThreadDemo {

    // Create a virtual-thread-per-task executor — recommended for I/O-bound workloads
    public List<String> fetchAll(List<String> urls) throws Exception {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Future<String>> futures = urls.stream()
                .map(url -> executor.submit(() -> fetchContent(url)))
                .toList();

            List<String> results = new ArrayList<>();
            for (Future<String> f : futures) {
                results.add(f.get());  // blocks virtual thread, not OS thread
            }
            return results;
        }
    }

    // Structured concurrency (Java 21 preview) — scoped, bounded task lifetimes
    public Result processOrder(long orderId) throws Exception {
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            Future<User>    user    = scope.fork(() -> userService.findById(orderId));
            Future<Product> product = scope.fork(() -> productService.findByOrder(orderId));

            scope.join().throwIfFailed();   // waits for both; cancels on first failure
            return new Result(user.resultNow(), product.resultNow());
        }
    }

    private String fetchContent(String url) throws Exception {
        // Blocking HTTP call — safe on a virtual thread
        var client = java.net.http.HttpClient.newHttpClient();
        var request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url)).build();
        return client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString()).body();
    }
}
```

### Decorator Pattern — Composing Behaviours Without Subclassing
The Decorator wraps a target interface with additional behaviour while delegating core work to the wrapped instance. Java's functional interfaces make one-line decorators trivial, but explicit decorator classes remain appropriate for stateful or complex cross-cutting concerns.

```java
// Core interface
public interface DataProcessor {
    String process(String input);
}

// Concrete implementation
public class TrimProcessor implements DataProcessor {
    @Override
    public String process(String input) { return input.trim(); }
}

// Decorator — adds logging without modifying TrimProcessor
public class LoggingProcessor implements DataProcessor {
    private final DataProcessor delegate;
    private static final System.Logger LOG = System.getLogger(LoggingProcessor.class.getName());

    public LoggingProcessor(DataProcessor delegate) {
        this.delegate = Objects.requireNonNull(delegate);
    }

    @Override
    public String process(String input) {
        LOG.log(System.Logger.Level.DEBUG, "Processing: {0}", input);
        String result = delegate.process(input);
        LOG.log(System.Logger.Level.DEBUG, "Result: {0}", result);
        return result;
    }
}

// Functional decorator — one-liner using lambdas (Java 8+)
DataProcessor timed = input -> {
    long start = System.nanoTime();
    String result = new TrimProcessor().process(input);
    System.out.printf("Took %d ns%n", System.nanoTime() - start);
    return result;
};

// Stack decorators fluently for the full pipeline
DataProcessor pipeline = new LoggingProcessor(new TrimProcessor());
String result = pipeline.process("  hello world  ");
```

### Strategy Pattern — Interchangeable Algorithms via Functional Interfaces
The Strategy pattern encapsulates a family of algorithms behind a common interface so the algorithm can be selected and swapped at runtime. In modern Java, a `@FunctionalInterface` replaces a full strategy class hierarchy — the lambda IS the strategy.

```java
// Strategy interface — a single abstract method makes it a lambda target
@FunctionalInterface
public interface PricingStrategy {
    double applyDiscount(double basePrice, int quantityOrdered);

    // Built-in named strategies as static factories on the interface
    static PricingStrategy standard() {
        return (price, qty) -> price;  // no discount
    }

    static PricingStrategy volumeDiscount(double threshold, double rate) {
        return (price, qty) -> qty >= threshold ? price * (1 - rate) : price;
    }

    static PricingStrategy seasonal(double rate) {
        return (price, qty) -> price * (1 - rate);
    }
}

// Context class — holds the strategy
public class OrderPricer {
    private final PricingStrategy strategy;

    public OrderPricer(PricingStrategy strategy) {
        this.strategy = strategy;
    }

    public double calculateTotal(List<OrderLine> lines) {
        return lines.stream()
            .mapToDouble(line -> strategy.applyDiscount(line.basePrice(), line.quantity()))
            .sum();
    }
}

// Usage — swap strategies at call site without modifying OrderPricer
var standardPricer  = new OrderPricer(PricingStrategy.standard());
var bulkPricer      = new OrderPricer(PricingStrategy.volumeDiscount(10, 0.15));
var salePricer      = new OrderPricer(PricingStrategy.seasonal(0.20));
```

### CompletableFuture — Async Composition
`CompletableFuture<T>` enables non-blocking async pipelines by composing async operations with `thenApply`, `thenCompose`, and `exceptionally`. It is the standard approach for async composition in pre-virtual-thread codebases and remains useful when you need explicit async execution control.

```java
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class AsyncOrderService {
    private final ExecutorService ioPool = Executors.newFixedThreadPool(10);

    public CompletableFuture<OrderSummary> buildSummary(long orderId) {
        CompletableFuture<Order> orderFuture =
            CompletableFuture.supplyAsync(() -> orderRepo.findById(orderId), ioPool);

        CompletableFuture<User> userFuture =
            orderFuture.thenComposeAsync(
                order -> CompletableFuture.supplyAsync(
                    () -> userRepo.findById(order.userId()), ioPool));

        return orderFuture.thenCombine(userFuture,
            (order, user) -> new OrderSummary(order, user))
            .exceptionally(ex -> {
                log.error("Failed to build order summary for {}", orderId, ex);
                return OrderSummary.empty(orderId);
            });
    }
}
```

### Hexagonal Architecture (Ports and Adapters)
Hexagonal Architecture (Alistair Cockburn, 2005) keeps the domain model free of infrastructure concerns by inverting dependencies: infrastructure adapters (databases, HTTP, message queues) implement domain-defined ports (interfaces). The application core never imports framework classes — it only depends on its own interfaces. This makes the core testable without any infrastructure, and swappable (e.g., swap Postgres for in-memory for tests) without touching domain logic.

```java
// === Domain layer — no framework imports ===

// Port: what the domain needs from persistence (incoming → domain uses this)
public interface OrderRepository {
    void save(Order order);
    Optional<Order> findById(OrderId id);
}

// Port: what the domain needs for notifications (outgoing → domain drives this)
public interface OrderEventPublisher {
    void publish(OrderPlaced event);
}

// Domain service: depends only on ports — no Spring, no JDBC, no Kafka
public class PlaceOrderUseCase {
    private final OrderRepository   orders;
    private final OrderEventPublisher events;

    public PlaceOrderUseCase(OrderRepository orders, OrderEventPublisher events) {
        this.orders  = orders;
        this.events  = events;
    }

    public OrderId execute(PlaceOrderCommand cmd) {
        var order = Order.create(cmd.customerId(), cmd.items());
        orders.save(order);
        events.publish(new OrderPlaced(order.id(), order.customerId()));
        return order.id();
    }
}

// === Infrastructure layer — implements domain ports ===

// Adapter: JPA implementation of the domain port
@Repository
public class JpaOrderRepository implements OrderRepository {
    private final OrderJpaRepository jpa; // Spring Data JPA interface

    @Override public void save(Order order) { jpa.save(OrderEntity.from(order)); }

    @Override public Optional<Order> findById(OrderId id) {
        return jpa.findById(id.value()).map(OrderEntity::toDomain);
    }
}

// Adapter: Kafka implementation of the publisher port
@Component
public class KafkaOrderEventPublisher implements OrderEventPublisher {
    private final KafkaTemplate<String, Object> kafka;

    @Override
    public void publish(OrderPlaced event) {
        kafka.send("orders.placed", event.orderId().value(), event);
    }
}

// === Test: domain tested with in-memory adapters, zero infrastructure ===
class PlaceOrderUseCaseTest {
    OrderRepository         repo      = new InMemoryOrderRepository();
    OrderEventPublisher     publisher = new InMemoryEventPublisher();
    PlaceOrderUseCase       useCase   = new PlaceOrderUseCase(repo, publisher);

    @Test void execute_savesOrderAndPublishesEvent() {
        var cmd = new PlaceOrderCommand(CustomerId.of("c1"), List.of(item("SKU-1", 2)));
        var id  = useCase.execute(cmd);

        assertThat(repo.findById(id)).isPresent();
        assertThat(publisher.published()).hasSize(1);
    }
}
```

**Why it matters in Java:** Java's rich interface system and dependency injection (Spring, Guice, CDI) make hexagonal architecture idiomatic rather than awkward. The pattern forces interface-first design at the architecture level — every infrastructure technology (DB, MQ, HTTP client) is behind an interface the domain defines. This is the structural complement to the **Interface-First Design** principle above; where that principle governs individual classes, hexagonal architecture governs module boundaries.

---

## Language Idioms

Java idioms are features or conventions that experienced Java developers use to write expressive, maintainable code — not just patterns expressed in Java but capabilities unique to the language.

### Pattern Matching for instanceof (Java 16+)
Eliminates the redundant cast after an `instanceof` check. The binding variable is scoped to the branch where the check succeeds, preventing accidental use outside the guarded block.

```java
// Old style — redundant cast, easy to mismatch type
Object obj = getPayload();
if (obj instanceof String) {
    String s = (String) obj;     // cast needed despite check
    System.out.println(s.length());
}

// New style — binding variable eliminates the cast
if (obj instanceof String s) {
    System.out.println(s.length());   // s is in scope here only
}

// Combining with switch (Java 21 pattern matching for switch)
public String describe(Object obj) {
    return switch (obj) {
        case Integer i when i < 0  -> "negative int: " + i;
        case Integer i             -> "positive int: " + i;
        case String  s when s.isBlank() -> "blank string";
        case String  s             -> "string: " + s;
        case null                  -> "null";
        default                    -> "other: " + obj.getClass().getSimpleName();
    };
}
```

### Method References
Instead of writing a lambda that only delegates to a single method, use a method reference. It reads closer to English, signals intent more clearly, and avoids shadowing the argument name.

```java
List<String> names = List.of("Alice", "Bob", "Carol");

// Instead of: names.forEach(name -> System.out.println(name));
names.forEach(System.out::println);            // instance method ref on receiver

// Instead of: names.stream().map(s -> s.toUpperCase())
names.stream().map(String::toUpperCase).toList();   // instance method ref on type

// Constructor reference
List<User> users = names.stream()
    .map(User::new)     // instead of: .map(name -> new User(name))
    .toList();
```

### Enhanced Switch Expressions (Java 14+)
Switch expressions use `->` arms and return values, eliminating fall-through bugs and intermediate variables.

```java
// Old style — fall-through risk, no return value
String label;
switch (status) {
    case PENDING:  label = "Waiting"; break;
    case ACTIVE:   label = "Running"; break;
    default:       label = "Unknown";
}

// New style — exhaustive, returns value, no fall-through
String label = switch (status) {
    case PENDING -> "Waiting";
    case ACTIVE  -> "Running";
    case CLOSED  -> "Done";
};
```

### Text Blocks (Java 15+)
Text blocks eliminate escape-heavy string literals for JSON, SQL, and HTML snippets.

```java
String json = """
        {
            "name": "Alice",
            "role": "admin",
            "active": true
        }
        """;

String sql = """
        SELECT u.id, u.name, o.total
        FROM   users u
        JOIN   orders o ON o.user_id = u.id
        WHERE  o.status = 'COMPLETED'
        ORDER  BY o.total DESC
        """;
```

### Sealed Classes + Pattern Matching (Java 17+)
Sealed classes restrict which classes may extend a type, enabling exhaustive pattern matching in `switch` without a default branch.

```java
public sealed interface Shape permits Circle, Rectangle, Triangle {}

public record Circle(double radius)              implements Shape {}
public record Rectangle(double width, double height) implements Shape {}
public record Triangle(double base, double height) implements Shape {}

// Exhaustive switch — compiler verifies all cases covered
public double area(Shape shape) {
    return switch (shape) {
        case Circle    c -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.width() * r.height();
        case Triangle  t -> 0.5 * t.base() * t.height();
    };
}
```

### Record Patterns — Destructuring in Pattern Matching (Java 21)
Record patterns allow you to deconstruct a record's components directly inside a `switch` arm or `instanceof` check, eliminating intermediate accessor calls and making structural decomposition more declarative. They compose naturally with sealed classes and nested pattern matching.

```java
// Domain model
public sealed interface Shape permits Circle, Rectangle, Triangle {}
public record Circle(double radius)                   implements Shape {}
public record Rectangle(double width, double height)  implements Shape {}
public record Triangle(double base, double height)    implements Shape {}

// Record pattern in switch — destructure components directly in the arm
public double perimeter(Shape shape) {
    return switch (shape) {
        case Circle(double r)                       -> 2 * Math.PI * r;
        case Rectangle(double w, double h)          -> 2 * (w + h);
        case Triangle(double b, double h)           -> b + 2 * Math.sqrt(h * h + (b / 2) * (b / 2));
    };
}

// Record pattern in instanceof — bound variables usable immediately
Object payload = receiveMessage();
if (payload instanceof Rectangle(double w, double h) && w > h) {
    System.out.println("Landscape rectangle: " + w + " x " + h);
}

// Nested record patterns — deconstruct trees and compositions
public record Point(double x, double y) {}
public record Line(Point start, Point end) {}

double length(Object obj) {
    return switch (obj) {
        // Destructure nested records in one arm — no intermediate variable needed
        case Line(Point(double x1, double y1), Point(double x2, double y2)) ->
            Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
        default -> throw new IllegalArgumentException("Not a Line: " + obj);
    };
}
```

### try-with-resources
Any `AutoCloseable` resource declared in the `try` header is closed automatically even if an exception is thrown, preventing resource leaks.

```java
public String readFile(Path path) throws IOException {
    try (var reader = Files.newBufferedReader(path, StandardCharsets.UTF_8)) {
        var sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line).append('\n');
        }
        return sb.toString();
    }
    // reader.close() called automatically — even on exception
}
```

### String.formatted / String.format
Use `String.formatted()` (Java 15+) for inline formatting without the static import noise.

```java
// Old
String msg = String.format("User %s has %d notifications", user.name(), count);

// New — method on the literal/variable
String msg = "User %s has %d notifications".formatted(user.name(), count);
```

### Comparator Chaining
`Comparator.comparing()` plus `.thenComparing()` builds multi-key sort order declaratively without nested if/else.

```java
import java.util.Comparator;
import java.util.List;

record Employee(String department, String lastName, int salary) {}

List<Employee> employees = fetchEmployees();

// Primary: department ascending, secondary: salary descending, tertiary: name ascending
List<Employee> sorted = employees.stream()
    .sorted(Comparator.comparing(Employee::department)
        .thenComparing(Comparator.comparingInt(Employee::salary).reversed())
        .thenComparing(Employee::lastName))
    .toList();  // Java 16+ — unmodifiable list; use Collectors.toList() if mutation needed
```

### @FunctionalInterface and Default Interface Methods
Marking a single-abstract-method interface with `@FunctionalInterface` enforces at compile time that the interface has exactly one abstract method — making it a valid lambda target. `default` methods let you add behaviour to interfaces without breaking existing implementors.

```java
// @FunctionalInterface — compiler enforces exactly one abstract method
@FunctionalInterface
public interface Transformer<T, R> {
    R transform(T input);

    // Default method: behaviour added without forcing implementors to change
    default Transformer<T, R> andLog(String label) {
        return input -> {
            R result = this.transform(input);
            System.out.printf("[%s] %s → %s%n", label, input, result);
            return result;
        };
    }

    // Static factory method on the interface — groups related utilities
    static <T> Transformer<T, T> identity() {
        return t -> t;
    }
}

// Usage — lambda satisfies the single abstract method
Transformer<String, Integer> lengthOf = String::length;
Transformer<String, Integer> logged   = lengthOf.andLog("size-check");
int n = logged.transform("hello");  // prints: [size-check] hello → 5
```

### Functional Interfaces and Lambda Composition
Java's `java.util.function` package provides `Function`, `Predicate`, `Consumer`, and `Supplier`. Compose them with `andThen`, `compose`, and `and`/`or`/`negate` instead of writing imperative wrappers.

```java
import java.util.function.Function;
import java.util.function.Predicate;

// Build a reusable validation pipeline
Predicate<String> notBlank   = s -> s != null && !s.isBlank();
Predicate<String> validEmail = s -> s.contains("@") && s.contains(".");
Predicate<String> validInput = notBlank.and(validEmail);

// Function composition — reads left-to-right with andThen
Function<String, String> trim       = String::trim;
Function<String, String> toLowerCase = String::toLowerCase;
Function<String, String> normalize   = trim.andThen(toLowerCase);

List<String> emails = rawEmails.stream()
    .map(normalize)
    .filter(validInput)
    .toList();
```

### StampedLock — Optimistic Reads for Low-Contention Shared State
`StampedLock` (Java 8+) offers three locking modes — write, read, and **optimistic read** — and is significantly faster than `ReentrantReadWriteLock` when reads dominate and contention is low. The optimistic read mode doesn't acquire any lock at all: you read, then validate that no write occurred during the read. If validation fails, you fall back to a proper read lock.

```java
import java.util.concurrent.locks.StampedLock;

public class Point {
    private double x, y;
    private final StampedLock lock = new StampedLock();

    public void move(double deltaX, double deltaY) {
        long stamp = lock.writeLock();   // exclusive write lock
        try {
            x += deltaX;
            y += deltaY;
        } finally {
            lock.unlockWrite(stamp);
        }
    }

    // Optimistic read: try without locking; validate; fall back to read lock if needed
    public double distanceFromOrigin() {
        long stamp = lock.tryOptimisticRead();   // no lock acquired
        double currentX = x, currentY = y;      // snapshot

        if (!lock.validate(stamp)) {
            // A write happened during our read — upgrade to real read lock
            stamp = lock.readLock();
            try {
                currentX = x;
                currentY = y;
            } finally {
                lock.unlockRead(stamp);
            }
        }
        return Math.hypot(currentX, currentY);
    }

    // Convert read stamp to write stamp if condition warrants upgrade
    public void moveIfAtOrigin(double newX, double newY) {
        long stamp = lock.readLock();
        try {
            while (x == 0.0 && y == 0.0) {
                long ws = lock.tryConvertToWriteLock(stamp);
                if (ws != 0L) {          // upgrade succeeded
                    stamp = ws;
                    x = newX;
                    y = newY;
                    break;
                } else {
                    lock.unlockRead(stamp);
                    stamp = lock.writeLock();  // wait for exclusive lock
                }
            }
        } finally {
            lock.unlock(stamp);
        }
    }
}
```

**When to use:** `StampedLock` wins over `ReentrantReadWriteLock` when: (1) reads vastly outnumber writes, (2) the read body is short (optimistic read validates quickly), and (3) you don't need reentrancy (StampedLock is non-reentrant — calling `readLock()` from a thread that holds a write stamp deadlocks). Never use `StampedLock` with virtual threads that can be interrupted while blocked in `lock()` — use `tryLock(timeout)` variants instead.

### SequencedCollection (Java 21)
`SequencedCollection` is a new interface in Java 21 that gives `List`, `Deque`, and `LinkedHashSet` a uniform API for accessing/removing first and last elements — no more `list.get(0)` vs `deque.peekFirst()` inconsistency.

```java
import java.util.ArrayList;
import java.util.SequencedCollection;

SequencedCollection<String> items = new ArrayList<>(List.of("a", "b", "c", "d"));

String first = items.getFirst();   // "a" — replaces list.get(0)
String last  = items.getLast();    // "d" — replaces list.get(list.size() - 1)

items.addFirst("z");               // insert at head
items.removeLast();                // remove tail

// reversed() returns a reversed view without copying
SequencedCollection<String> reversed = items.reversed();
reversed.forEach(System.out::println);  // z, a, b, c
```

### SequencedMap (Java 21) — Consistent First/Last Access for Ordered Maps
`SequencedMap` extends `SequencedCollection` semantics to map interfaces. `LinkedHashMap` and `TreeMap` both implement it, providing a uniform API for accessing the first and last entries without casting or maintaining a parallel `TreeMap` reference.

```java
import java.util.LinkedHashMap;
import java.util.SequencedMap;

// LinkedHashMap preserves insertion order and implements SequencedMap
SequencedMap<String, Integer> scores = new LinkedHashMap<>();
scores.put("Alice", 95);
scores.put("Bob",   87);
scores.put("Carol", 92);

// First and last entry — no need for iterator.next() or Iterables.getLast()
Map.Entry<String, Integer> first = scores.firstEntry();  // Alice=95
Map.Entry<String, Integer> last  = scores.lastEntry();   // Carol=92

// pollFirstEntry / pollLastEntry — atomic remove-and-return (useful for LRU eviction)
Map.Entry<String, Integer> removed = scores.pollFirstEntry();  // removes Alice=95

// Reversed view — iterates from Carol to Bob without copying
SequencedMap<String, Integer> reversed = scores.reversed();
reversed.forEach((name, score) ->
    System.out.println(name + ": " + score));  // Carol, Bob

// putFirst / putLast — insert at head or tail (LinkedHashMap only; TreeMap ignores position)
scores.putFirst("Zoe", 99);   // Zoe becomes the new first entry
scores.putLast("Dan",  80);   // Dan becomes the new last entry
```

**When to use:** `SequencedMap` is the correct type for LRU caches (`LinkedHashMap(capacity, 0.75f, true)`), ordered audit logs, and any structure where "oldest" or "most-recent" entries need efficient access. Use `sequencedKeySet()`, `sequencedValues()`, and `sequencedEntrySet()` to get `SequencedCollection` views that also support `addFirst`/`addLast` (for `LinkedHashMap`).

### EnumSet and EnumMap — Enum-Optimised Collections
`EnumSet` and `EnumMap` are specialised implementations for enum keys that use compact bit-vector and array representations internally — dramatically more efficient than `HashSet<MyEnum>` or `HashMap<MyEnum, V>`. Use them whenever the key domain is an enum type.

```java
public enum Permission { READ, WRITE, EXECUTE, ADMIN }

// EnumSet — a compact, efficient set of enum constants
EnumSet<Permission> adminPerms  = EnumSet.allOf(Permission.class);
EnumSet<Permission> readOnly    = EnumSet.of(Permission.READ);
EnumSet<Permission> readWrite   = EnumSet.of(Permission.READ, Permission.WRITE);

// Set operations — fast bit-manipulation under the hood
EnumSet<Permission> missing = EnumSet.complementOf(readOnly);  // {WRITE, EXECUTE, ADMIN}
boolean canAdmin = adminPerms.containsAll(readOnly);            // true

// EnumMap — array-backed map keyed by enum ordinal; faster than HashMap
EnumMap<Permission, String> descriptions = new EnumMap<>(Permission.class);
descriptions.put(Permission.READ,    "Can view resources");
descriptions.put(Permission.WRITE,   "Can modify resources");
descriptions.put(Permission.EXECUTE, "Can run commands");
descriptions.put(Permission.ADMIN,   "Full administrative access");

// Iteration preserves enum declaration order (unlike HashMap)
descriptions.forEach((perm, desc) -> System.out.println(perm + ": " + desc));
```

### java.time API — Modern Date and Time
The `java.time` package (Java 8+, JSR-310) is the definitive replacement for `java.util.Date`, `Calendar`, and `SimpleDateFormat`. All classes are immutable and thread-safe. Use `LocalDate`/`LocalDateTime` for human dates; `Instant` for machine timestamps; `ZonedDateTime` for timezone-aware operations; `Duration`/`Period` for amounts of time.

```java
import java.time.*;
import java.time.format.DateTimeFormatter;

// LocalDate — date without time; no timezone; human calendars
LocalDate today    = LocalDate.now();
LocalDate nextWeek = today.plusWeeks(1);
LocalDate birthday = LocalDate.of(1990, Month.JUNE, 15);
long daysOld = ChronoUnit.DAYS.between(birthday, today);

// LocalDateTime — date + time without timezone
LocalDateTime meeting = LocalDateTime.of(2026, 5, 10, 14, 30);

// Instant — machine timestamp; nanosecond precision; UTC
Instant now  = Instant.now();
Instant later = now.plusSeconds(3600);

// ZonedDateTime — instant in a specific timezone
ZonedDateTime nyNow    = ZonedDateTime.now(ZoneId.of("America/New_York"));
ZonedDateTime tokyoNow = nyNow.withZoneSameInstant(ZoneId.of("Asia/Tokyo"));

// Formatting and parsing — DateTimeFormatter is immutable (thread-safe)
DateTimeFormatter iso = DateTimeFormatter.ISO_LOCAL_DATE;
String formatted   = today.format(iso);                      // "2026-05-03"
LocalDate parsed   = LocalDate.parse("2026-05-03", iso);

// Duration (machine precision) vs Period (human calendar units)
Duration twoHours   = Duration.ofHours(2);
Period   threeMonths = Period.ofMonths(3);
LocalDate deadline   = today.plus(threeMonths);
```

### Effective Enum Patterns — Abstract Methods and Singleton Enums
Java enums are full classes. Each constant can override abstract methods, implement interfaces, and carry fields. This enables the "Constant-Specific Class Body" pattern (Effective Java Item 34): behaviour varies per constant without a `switch` statement scattered throughout the codebase.

```java
// Abstract method per constant — each constant defines its own behaviour
public enum Operation {
    PLUS("+") {
        @Override public double apply(double x, double y) { return x + y; }
    },
    MINUS("-") {
        @Override public double apply(double x, double y) { return x - y; }
    },
    TIMES("*") {
        @Override public double apply(double x, double y) { return x * y; }
    },
    DIVIDE("/") {
        @Override public double apply(double x, double y) {
            if (y == 0) throw new ArithmeticException("Division by zero");
            return x / y;
        }
    };

    private final String symbol;
    Operation(String symbol) { this.symbol = symbol; }

    public abstract double apply(double x, double y);

    @Override public String toString() { return symbol; }

    // Enum as a safe lookup by symbol — no switch, no null
    private static final Map<String, Operation> BY_SYMBOL =
        Arrays.stream(values())
              .collect(Collectors.toMap(op -> op.symbol, op -> op));

    public static Optional<Operation> fromSymbol(String sym) {
        return Optional.ofNullable(BY_SYMBOL.get(sym));
    }
}

// Enum as a thread-safe singleton (Effective Java Item 3)
// Best singleton pattern in Java — enum handles serialization and reflection attacks
public enum DatabasePool {
    INSTANCE;

    private final HikariDataSource pool = initPool();

    private HikariDataSource initPool() {
        var config = new HikariConfig();
        config.setJdbcUrl(System.getenv("DB_URL"));
        return new HikariDataSource(config);
    }

    public Connection getConnection() throws SQLException {
        return pool.getConnection();
    }
}
```

### Unnamed Patterns and Unnamed Variables (Java 22+)
Java 22 introduced unnamed patterns (`_`) for ignoring components you don't need in pattern matching, and unnamed variables (`_`) for lambda parameters and catch clauses you don't use. This reduces boilerplate and makes intent clear.

```java
// Unnamed pattern — ignore components you don't need
sealed interface Event permits OrderPlaced, PaymentReceived, ShipmentSent {}
record OrderPlaced(String orderId, double amount) implements Event {}
record PaymentReceived(String paymentId, double amount) implements Event {}
record ShipmentSent(String trackingId) implements Event {}

// Unnamed pattern: _ ignores the component we don't care about
public boolean isFinancialEvent(Event event) {
    return switch (event) {
        case OrderPlaced(_, double amount) when amount > 0 -> true;
        case PaymentReceived _  -> true;  // unnamed pattern: entire record ignored
        case ShipmentSent _     -> false;
    };
}

// Unnamed variable in catch — we're handling but not using the exception object
try {
    return Integer.parseInt(raw);
} catch (NumberFormatException _) {   // _ signals: caught but intentionally unused
    return 0;
}

// Unnamed variable in lambda — side-effect only
list.forEach(_ -> counter.increment());  // parameter unused by intent
```

### Scoped Values (Java 21 preview / Java 23 standard)
`ScopedValue` is the modern, thread-safe alternative to `ThreadLocal` for passing context through a call tree without explicit parameter threading. Unlike `ThreadLocal`, scoped values are immutable within a scope and automatically cleaned up when the scope ends — making them safe for virtual threads.

```java
import java.lang.ScopedValue;

public class RequestHandler {

    // Declare a scoped value — typically a public static final
    private static final ScopedValue<User> CURRENT_USER = ScopedValue.newInstance();
    private static final ScopedValue<String> REQUEST_ID  = ScopedValue.newInstance();

    // Bind values for the duration of a request
    public void handle(HttpRequest request) {
        User user = authenticate(request);
        String requestId = UUID.randomUUID().toString();

        ScopedValue.where(CURRENT_USER, user)
                   .where(REQUEST_ID, requestId)
                   .run(() -> {
                       // All code called within this block can read these values
                       processRequest(request);
                   });
        // Values automatically cleaned up after run() completes
    }

    // Deep in the call stack — no parameter needed
    private void processRequest(HttpRequest request) {
        User user = CURRENT_USER.get();       // type-safe, no cast
        String rid = REQUEST_ID.get();
        log.info("Processing request {} for user {}", rid, user.name());
        // ...
    }
}
```

**Why prefer ScopedValue over ThreadLocal for virtual threads:**
- `ThreadLocal` survives the thread's lifetime and must be explicitly removed — in virtual-thread-per-task models, this causes leaks.
- `ScopedValue` bindings are **immutable** within the scope and automatically cleaned up.
- Virtual threads can inherit scoped values from their parent structured concurrency scope.

### Stream Gatherers (Java 22+ — JEP 485)
`Stream.gather(Gatherer)` is a new terminal-like intermediate operation that enables custom intermediate stream operations beyond what `map`, `filter`, and `flatMap` support. Useful for sliding windows, stateful transformations, and grouping without collecting.

```java
import java.util.stream.Gatherer;
import java.util.stream.Gatherers;

// Built-in gatherers (Java 22+)
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8);

// Sliding window of size 3
List<List<Integer>> windows = numbers.stream()
    .gather(Gatherers.windowSliding(3))
    .toList();
// [[1,2,3], [2,3,4], [3,4,5], [4,5,6], [5,6,7], [6,7,8]]

// Fixed window (tumbling)
List<List<Integer>> chunks = numbers.stream()
    .gather(Gatherers.windowFixed(3))
    .toList();
// [[1,2,3], [4,5,6], [7,8]]

// Custom gatherer: running total
Gatherer<Integer, ?, Integer> runningTotal = Gatherer.ofSequential(
    () -> new int[]{0},                                       // initializer
    (state, element, downstream) -> {                         // integrator
        state[0] += element;
        return downstream.push(state[0]);
    }
);

List<Integer> totals = numbers.stream()
    .gather(runningTotal)
    .toList();
// [1, 3, 6, 10, 15, 21, 28, 36]
```

### Primitive Types in Patterns (Java 23+ — JEP 455)
Java 23 extended pattern matching to support primitive types in `instanceof` and `switch`, eliminating the awkward narrowing cast pattern and enabling exhaustive switching over primitives with guarded cases.

```java
// Before Java 23 — boxing + instanceof or manual cast needed
Object rawValue = getSensorReading();
if (rawValue instanceof Integer i && i > 100) {
    triggerAlert(i);
}

// Java 23+ — primitive types work directly in instanceof patterns
int reading = getSensorValueAsInt();
if (reading instanceof int i && i > 100) {  // no boxing; direct primitive pattern
    triggerAlert(i);
}

// Switch over primitives with type patterns (Java 23+)
// Previously only constants were valid switch arms
double result = switch (reading) {
    case int i when i < 0    -> 0.0;           // negative: clamp
    case int i when i > 1000 -> 1.0;           // saturate
    case int i               -> i / 1000.0;    // normalise
};

// Exhaustive over byte/short/char/int/long without a default arm
// when all sub-ranges are covered by guarded cases (Java 23+ preview)
byte status = getStatusByte();
String description = switch (status) {
    case byte b when b == 0   -> "idle";
    case byte b when b == 1   -> "active";
    case byte b when b < 0    -> "error: " + b;
    default                   -> "unknown: " + status;
};
```

### Structured Concurrency (Java 21 preview → Java 24 standard — JEP 505)
Structured concurrency treats a group of related tasks as a single unit of work. If any subtask fails, sibling tasks are automatically cancelled, and all task lifetimes are bounded to the enclosing scope. This eliminates the common bug where a parent thread continues while child tasks leak into the background.

```java
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Subtask;

// ShutdownOnFailure — cancel all subtasks if any fails
public record OrderDetails(User user, Inventory inventory, Pricing pricing) {}

public OrderDetails buildOrderDetails(long orderId) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        // Fork all three fetches concurrently
        Subtask<User>      user      = scope.fork(() -> userService.findById(orderId));
        Subtask<Inventory> inventory = scope.fork(() -> inventoryService.check(orderId));
        Subtask<Pricing>   pricing   = scope.fork(() -> pricingService.quote(orderId));

        scope.join()           // wait for all subtasks to complete or any to fail
             .throwIfFailed(); // re-throws the first exception

        // All subtasks succeeded — safe to read results
        return new OrderDetails(user.get(), inventory.get(), pricing.get());
    }
    // scope.close() cancels any still-running subtasks automatically
}

// ShutdownOnSuccess — return the first successful result, cancel the rest
public String fetchFromFastestReplica(List<String> replicaUrls) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnSuccess<String>()) {
        replicaUrls.forEach(url -> scope.fork(() -> httpClient.fetch(url)));
        scope.join();
        return scope.result();  // returns the first successful response
    }
}
```

### Module Import Declarations (Java 24 standard — JEP 476)
Module import declarations (`import module <name>;`) import all public top-level types exported by a module in a single statement, eliminating the boilerplate of dozens of individual type imports in files that use many classes from a module (e.g., `java.base`, `java.sql`, `java.xml`).

```java
// Before: explicit per-type imports (verbose for utility/glue code)
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.function.Function;
import java.util.function.Predicate;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Files;

// After: one line imports everything from java.base
import module java.base;

// Also useful for application modules in multi-module builds
import module com.example.shared;   // imports all exported packages from your shared module

public class DataProcessor {
    // Can use ArrayList, HashMap, Optional, Path, Files, Stream, Collectors directly
    public Map<String, List<String>> groupByPrefix(List<String> items) {
        return items.stream()
            .collect(Collectors.groupingBy(s -> s.substring(0, 1)));
    }
}
```

**Note:** Module imports are a convenience shorthand. Ambiguity is resolved by explicit single-type imports — a `import java.util.Date;` after `import module java.base;` selects `java.util.Date` over `java.sql.Date`.

### Flexible Constructor Bodies (Java 22 preview → Java 23 preview — JEP 492/513, targeting Java 25 standard)
Flexible constructor bodies allow statements to appear before the explicit `super()` or `this()` call in a constructor, provided those statements do not reference `this`. This enables argument validation and preparation (e.g., null checks, defensive copies) before delegating to the superclass, replacing the awkward static helper method workaround.

```java
// Before Java 22: argument validation before super() required a static helper
public class BoundedIntRange extends IntRange {
    public BoundedIntRange(int low, int high) {
        super(validate(low, high));   // forced to use static helper — ugly
    }
    private static int[] validate(int low, int high) {
        if (low > high) throw new IllegalArgumentException(low + " > " + high);
        return new int[]{low, high};
    }
}

// Java 22+ preview: statements before super() are now legal
public class BoundedIntRange extends IntRange {
    public BoundedIntRange(int low, int high) {
        // Statements before super() — allowed as long as 'this' is not referenced
        if (low > high) {
            throw new IllegalArgumentException(
                "low (%d) must be ≤ high (%d)".formatted(low, high));
        }
        int adjustedLow = Math.max(low, 0);   // clamp to non-negative
        super(adjustedLow, high);              // super() still required, just not first
    }
}

// Useful for records: compact canonical constructors already allow this,
// but for plain classes it eliminates a significant design friction.
public class NonNullList<E> extends ArrayList<E> {
    public NonNullList(List<? extends E> source) {
        Objects.requireNonNull(source, "source must not be null");  // before super()
        super(source);
    }
}
```

### Parallel Stream Optimization — `unordered()` and `groupingByConcurrent()`
Two underused optimizations for parallel streams: `unordered()` tells the stream pipeline that element order does not matter, enabling the runtime to skip buffering for order-sensitive operations (`distinct()`, `limit()`). `Collectors.groupingByConcurrent()` produces a `ConcurrentHashMap` directly using a concurrent merge algorithm — faster than `groupingBy()` in parallel because it avoids per-thread maps and a final merge step.

```java
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

// groupingBy in parallel: creates per-thread maps, merges at the end
Map<String, List<Order>> byStatus = orders.parallelStream()
    .collect(Collectors.groupingBy(Order::status));   // ordered; sequential merge

// groupingByConcurrent: writes directly into ConcurrentHashMap — no merge step
// NOTE: result order within each group is non-deterministic
Map<String, List<Order>> byStatusConcurrent = orders.parallelStream()
    .collect(Collectors.groupingByConcurrent(Order::status));

// unordered() + parallel: skip order-preservation buffering in distinct/limit
long uniqueCount = largeStream
    .parallel()
    .unordered()        // hint: order irrelevant — allows optimised parallel distinct
    .distinct()
    .count();

// Combining: fully unordered concurrent grouping — maximum parallelism
ConcurrentHashMap<Department, List<Employee>> grouped = employees.parallelStream()
    .unordered()
    .collect(Collectors.groupingByConcurrent(
        Employee::department,
        ConcurrentHashMap::new,
        Collectors.toList()
    ));
```

**When to use:** `groupingByConcurrent()` wins on large datasets where merging per-thread maps is the bottleneck. `unordered()` helps when the pipeline contains `distinct()`, `sorted()`, or `limit()` and you don't need encounter order preserved. Always benchmark — for small collections, sequential is faster.

### Record Wither Pattern — Immutable "Copy With Change"
Records are immutable — there is no built-in `with` syntax for creating a copy with one field changed (unlike Kotlin data classes). The idiomatic Java workaround is to add explicit `withXxx()` methods that call the canonical constructor with the new value for the changed field. For records with many fields, this is verbose but keeps the immutability contract intact. Lombok's `@With` or Java 25's planned "withers" proposal (not yet standard) are alternatives worth tracking.

```java
public record UserProfile(
    String userId,
    String displayName,
    String email,
    boolean active,
    Instant createdAt
) {
    // Wither methods: return a new record with one field changed, rest unchanged
    public UserProfile withDisplayName(String newName) {
        return new UserProfile(userId, newName, email, active, createdAt);
    }

    public UserProfile withEmail(String newEmail) {
        // Can include validation in the wither
        if (!newEmail.contains("@")) {
            throw new IllegalArgumentException("Invalid email: " + newEmail);
        }
        return new UserProfile(userId, displayName, newEmail, active, createdAt);
    }

    public UserProfile deactivated() {
        return new UserProfile(userId, displayName, email, false, createdAt);
    }
}

// Usage — chain wither calls; original is unchanged; each call returns a new instance
UserProfile original = new UserProfile("u1", "Alice", "alice@old.com", true, Instant.now());
UserProfile updated  = original
    .withEmail("alice@new.com")
    .withDisplayName("Alice Smith");

// Original is unchanged — immutability preserved
System.out.println(original.email());   // alice@old.com
System.out.println(updated.email());    // alice@new.com
```

**Why idiomatic:** Records guarantee immutability; wither methods provide a fluent API for producing modified copies without exposing setters. Until a Java language feature adds native wither syntax, this explicit pattern is the standard approach endorsed by the community.

### Unnamed Classes and Instance Main Methods (Java 25 — JEP 477)
Java 25 standardizes the ability to write simple programs without the boilerplate of `public class Foo { public static void main(String[] args) {} }`. An unnamed class file can contain top-level methods and fields, and an instance `main()` method (no `static`, no `String[]` required) becomes the entry point. This makes Java more accessible for scripting, quick experiments, and educational contexts without changing how production code is written.

```java
// Java 25 unnamed class — no class declaration, no static, args optional
// File: Hello.java
void main() {
    System.out.println("Hello, World!");
}

// With a helper method — also at top level
String greet(String name) {
    return "Hello, %s!".formatted(name);
}

void main() {
    System.out.println(greet("Alice"));  // Hello, Alice!
}

// Import is still allowed
import java.util.List;

void main() {
    var names = List.of("Alice", "Bob", "Carol");
    names.forEach(name -> System.out.println(greet(name)));
}
```

**Note for production code:** Unnamed classes and instance main are for scripting and teaching contexts. Production application entry points should still use `public static void main(String[] args)` or Spring Boot's `@SpringBootApplication` — not unnamed classes — for clarity and compatibility with tooling.

### Foreign Function & Memory API — Safe Native Interop (Java 22 standard — JEP 454)
The Foreign Function & Memory (FFM) API replaces `sun.misc.Unsafe` and JNI for native code interop. It provides type-safe, scope-bound access to off-heap memory (`MemorySegment`) and the ability to call native functions directly (`Linker`). Unlike JNI, FFM APIs are checked by the compiler and automatically free native memory when the arena goes out of scope.

```java
import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public class NativeStrlen {

    // Call the C standard library strlen() from Java — no JNI boilerplate
    public static long strlen(String input) throws Throwable {
        Linker linker = Linker.nativeLinker();
        SymbolLookup stdlib = linker.defaultLookup();

        // Look up 'strlen' in the C runtime
        MemorySegment strlenAddr = stdlib.find("strlen")
            .orElseThrow(() -> new RuntimeException("strlen not found"));

        // Describe the function: takes a pointer, returns size_t (a long)
        FunctionDescriptor desc = FunctionDescriptor.of(
            ValueLayout.JAVA_LONG,    // return type: size_t
            ValueLayout.ADDRESS       // parameter: const char*
        );

        MethodHandle strlen = linker.downcallHandle(strlenAddr, desc);

        // Allocate a confined arena — native memory freed automatically at close()
        try (Arena arena = Arena.ofConfined()) {
            MemorySegment cString = arena.allocateFrom(input);  // Java String → C string
            return (long) strlen.invoke(cString);
        }
    }
}
```

**When to use:** FFM is for library authors integrating with native code (OS APIs, BLAS, OpenSSL, CUDA). For most application code, use a JVM library wrapper instead. Never use `sun.misc.Unsafe` in new code — FFM is the sanctioned replacement.

### Class-File API — Programmatic Bytecode Manipulation (Java 24 standard — JEP 484)
The Class-File API provides a standard Java library for reading, writing, and transforming `.class` files. It replaces third-party bytecode libraries (ASM, Javassist) for use cases like instrumentation, annotation processors, and code generators that need to inspect or modify compiled classes.

```java
import java.lang.classfile.*;
import java.lang.constant.ClassDesc;
import java.lang.constant.MethodTypeDesc;
import java.nio.file.Files;
import java.nio.file.Path;

public class ClassFileExample {

    // Read a class file and print all method names
    public static void listMethods(Path classFile) throws Exception {
        byte[] bytes = Files.readAllBytes(classFile);
        ClassModel model = ClassFile.of().parse(bytes);

        model.methods().forEach(method ->
            System.out.println(method.methodName().stringValue()
                + method.methodType().stringValue())
        );
    }

    // Transform: add a System.out.println at the start of every method
    public static byte[] instrumentMethods(byte[] classBytes) {
        return ClassFile.of().transform(
            ClassFile.of().parse(classBytes),
            ClassTransform.transformingMethods(
                (methodBuilder, methodElement) -> {
                    if (methodElement instanceof CodeModel code) {
                        methodBuilder.withCode(codeBuilder -> {
                            // Inject: System.out.println("<methodName> called")
                            codeBuilder
                                .getstatic(ClassDesc.of("java.lang.System"), "out",
                                    ClassDesc.of("java.io.PrintStream"))
                                .ldc(methodBuilder.methodName().stringValue() + " called")
                                .invokevirtual(ClassDesc.of("java.io.PrintStream"), "println",
                                    MethodTypeDesc.ofDescriptor("(Ljava/lang/String;)V"));
                            // Then emit all original instructions
                            code.forEach(codeBuilder::with);
                        });
                    } else {
                        methodBuilder.with(methodElement);
                    }
                }
            )
        );
    }
}
```

**Note:** The Class-File API is designed for tooling authors, not application developers. It follows the class file format version that the running JVM understands — always generates valid bytecode for the current JVM version. For simple annotation-based code generation, use APT (Annotation Processing Tool) or Lombok instead.

### Java Platform Module System (JPMS) — Strong Encapsulation at the Architecture Level
The Java Platform Module System (JPMS, Java 9+) introduces `module-info.java` as an explicit contract for what a module exposes and what it depends on. Each module declares its exported packages (accessible to other modules) and its required modules (compile and runtime dependencies). This enables strong encapsulation at the JVM level — `public` inside a non-exported package is inaccessible to other modules, regardless of the access modifier.

```java
// === module-info.java for the domain module ===
// File: src/com.example.orders.domain/module-info.java
module com.example.orders.domain {
    // Exports the public API — only these packages are accessible outside the module
    exports com.example.orders.domain.model;
    exports com.example.orders.domain.ports;

    // Internal packages (impl, spi) are NOT exported — fully encapsulated
    // com.example.orders.domain.internal is invisible to other modules
}

// === module-info.java for the infrastructure module ===
// File: src/com.example.orders.infrastructure/module-info.java
module com.example.orders.infrastructure {
    requires com.example.orders.domain;     // depends on domain
    requires spring.context;                // Spring DI
    requires java.sql;                      // JDBC
    requires jakarta.persistence;           // JPA

    // Opens packages to Spring for reflection-based injection
    // 'opens' = runtime reflection only; 'exports' = compile + runtime access
    opens com.example.orders.infrastructure.persistence to spring.orm;

    // Qualified export: only the test framework module can access this
    exports com.example.orders.infrastructure.testing to com.example.orders.application.test;
}

// === module-info.java for the application entry point ===
module com.example.orders.application {
    requires com.example.orders.domain;
    requires com.example.orders.infrastructure;
    requires spring.boot;
    requires spring.boot.autoconfigure;
}

// === Using ServiceLoader for plugin/extension points ===
// In module-info: declare a service used by the module
module com.example.orders.domain {
    exports com.example.orders.domain.ports;
    uses com.example.orders.domain.ports.PaymentGateway;  // ServiceLoader SPI
}

// In the payment-stripe module: provide the implementation
module com.example.payments.stripe {
    requires com.example.orders.domain;
    provides com.example.orders.domain.ports.PaymentGateway
        with com.example.payments.stripe.StripePaymentGateway;
}

// Discover all available implementations at runtime — no hardcoded class names
ServiceLoader<PaymentGateway> gateways = ServiceLoader.load(PaymentGateway.class);
PaymentGateway gateway = gateways.findFirst()
    .orElseThrow(() -> new IllegalStateException("No PaymentGateway implementation found"));
```

**Key JPMS rules:**
- `exports <package>` — compile-time + runtime accessible to all modules.
- `opens <package>` — runtime reflection only (for frameworks like Spring, Jackson, Hibernate).
- `requires transitive` — re-exports a dependency; callers of your module also get access to the dependency.
- `requires static` — compile-time only dependency (optional at runtime); useful for annotation processors.

**When to use JPMS:** Multi-module Maven/Gradle projects with clear layer boundaries (domain/infra/application), library JAR publishing (to expose only the public API), or applications that use `jlink` to create minimal JVM runtime images. For Spring Boot monoliths or microservices using classpath mode, JPMS is optional — but `module-info.java` in each module enforces boundaries at build time even without the full modular JVM runtime.

### `Collectors.teeing()` — Dual Aggregation in One Pass (Java 12+)
`Collectors.teeing(downstreamA, downstreamB, merger)` applies two independent collectors to the same stream simultaneously and merges their results. This eliminates the need to iterate the collection twice or collect into an intermediate list before applying two reduction operations.

```java
import java.util.stream.Collectors;
import java.util.DoubleSummaryStatistics;

record SalaryStats(double min, double max, double avg, long count) {}

// Without teeing: stream collected twice (or iterated twice with a loop)
List<Double> salaries = employees.stream()
    .map(Employee::salary)
    .toList();
double min = salaries.stream().mapToDouble(d -> d).min().orElse(0);
double max = salaries.stream().mapToDouble(d -> d).max().orElse(0);

// With teeing: single pass, two collectors
SalaryStats stats = employees.stream()
    .map(Employee::salary)
    .collect(Collectors.teeing(
        Collectors.summarizingDouble(Double::doubleValue),    // downstream A: full stats
        Collectors.counting(),                                // downstream B: count
        (DoubleSummaryStatistics s, Long c) ->
            new SalaryStats(s.getMin(), s.getMax(), s.getAverage(), c)
    ));

// Another use: split into two groups in one pass (replaces partitioningBy when you need both)
record PartitionResult<T>(List<T> matches, List<T> nonMatches) {}

PartitionResult<Order> result = orders.stream()
    .collect(Collectors.teeing(
        Collectors.filtering(o -> o.total() > 100, Collectors.toList()),
        Collectors.filtering(o -> o.total() <= 100, Collectors.toList()),
        PartitionResult::new
    ));
```

**When to use:** `teeing()` is ideal when you need two separate aggregation results (statistics + count, two filtered groups, sum + max) and iterating the source twice would be expensive. For more than two downstream collectors, chain multiple `teeing()` calls or use a custom `Collector`.

### `Path.of()` and `Files` — Modern File I/O Idioms (Java 11+)
`Path.of()` (Java 11+) replaces the verbose `Paths.get()` factory. The `Files` utility class provides one-liner methods for common file operations that previously required boilerplate streams. Use `Files.writeString()` / `Files.readString()` for text; `Files.write()` / `Files.readAllBytes()` for binary.

```java
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.charset.StandardCharsets;

// Path.of() — replaces Paths.get() (Paths.get() still works but Path.of() is idiomatic post-Java-11)
Path configFile = Path.of("/etc/myapp", "config.json");       // varargs join with OS separator
Path relative   = Path.of("src", "main", "resources", "app.properties");

// Files.readString / writeString — no stream boilerplate for text files
String content = Files.readString(configFile, StandardCharsets.UTF_8);  // Java 11+
Files.writeString(Path.of("/tmp/output.txt"), "Hello World\n",
    StandardCharsets.UTF_8,
    java.nio.file.StandardOpenOption.CREATE,
    java.nio.file.StandardOpenOption.APPEND);

// Files.createTempFile / createTempDirectory — safe temp file creation
Path tmpFile = Files.createTempFile("prefix-", ".tmp");      // OS-managed temp dir
Path tmpDir  = Files.createTempDirectory("work-");

// Files.copy / move with options
Files.copy(configFile, Path.of("/tmp/config-backup.json"),
    java.nio.file.StandardCopyOption.REPLACE_EXISTING);

// Walk directory tree — lazy, closes automatically
try (var stream = Files.walk(Path.of("src"))) {
    List<Path> javaFiles = stream
        .filter(p -> p.toString().endsWith(".java"))
        .toList();
}

// Files.isSameFile — canonical comparison (handles symlinks and different representations)
boolean same = Files.isSameFile(Path.of("./config.json"), Path.of("/app/config.json"));
```

**Key idioms:** Prefer `Path.of()` over `new File(...)` in all new code — `Path` is the modern NIO.2 API. Prefer `Files.readString()` over `new BufferedReader(new FileReader(...))` for text files. Always wrap `Files.walk()` and `Files.lines()` in `try-with-resources` — they open file system iterators.

### `Map.entry()` and `Map.ofEntries()` — Readable Map Literals (Java 9+)
`Map.entry(k, v)` creates an immutable `Map.Entry` without the verbose `new AbstractMap.SimpleEntry<>(k, v)` syntax. Combined with `Map.ofEntries()`, it allows map literals with more than 10 entries (the limit of `Map.of()`).

```java
import java.util.Map;

// Map.of() — up to 10 key-value pairs
Map<String, Integer> small = Map.of(
    "one",   1,
    "two",   2,
    "three", 3
);

// Map.ofEntries() + Map.entry() — unlimited entries, more readable for many pairs
Map<String, String> httpCodes = Map.ofEntries(
    Map.entry("200", "OK"),
    Map.entry("201", "Created"),
    Map.entry("400", "Bad Request"),
    Map.entry("401", "Unauthorized"),
    Map.entry("403", "Forbidden"),
    Map.entry("404", "Not Found"),
    Map.entry("500", "Internal Server Error"),
    Map.entry("503", "Service Unavailable")
    // Can have any number of entries — no limit
);

// Map.entry() as a return value or local variable — cleaner than AbstractMap.SimpleEntry
public Map.Entry<String, Integer> mostFrequent(Map<String, Integer> freq) {
    return freq.entrySet().stream()
        .max(Map.Entry.comparingByValue())
        .orElseThrow();
}

// Map.copyOf() — defensive immutable copy of any map (Java 10+)
Map<String, Integer> mutable = new HashMap<>(Map.of("a", 1, "b", 2));
mutable.put("c", 3);
Map<String, Integer> snapshot = Map.copyOf(mutable);  // throws on null keys/values
```

---

## Real-World Gotchas  [community]

**1. Returning null instead of Optional [community]**
Returning `null` from a method propagates `NullPointerException` to callers who forget to check. The root cause is that Java allows null everywhere but the type system doesn't track it. Fix: return `Optional<T>` for methods that may return no result, use `Objects.requireNonNull` at validation boundaries, and annotate parameters with `@NonNull` / `@Nullable` (JSR-305 or JetBrains annotations).

**2. Overusing Checked Exceptions [community]**
Wrapping every infrastructure failure in a checked exception forces every caller to either handle or re-declare it, resulting in boilerplate `catch(Exception e) { throw new RuntimeException(e); }` ladders. The root cause is misapplying the "caller should handle" rule to failures that are never actually handled. Fix: only throw checked exceptions for conditions the immediate caller can realistically recover from; use unchecked exceptions wrapped with context for the rest.

**3. Mutating Collections Passed as Parameters [community]**
Methods that silently modify a `List` or `Map` passed by the caller create spooky action at a distance — the caller's collection changes without any indication in the method signature. Fix: return a new collection, accept `Collections.unmodifiableList(input)` internally, or document mutation clearly. Use `List.copyOf()` to defensively copy on entry.

**4. Using String Concatenation in Loops [community]**
`String` is immutable; `s += item` inside a loop creates O(n²) temporary objects. In tight loops this triggers frequent GC. Fix: use `StringBuilder` for imperative accumulation, or prefer the `Collectors.joining()` collector in streams.

```java
// BAD
String result = "";
for (String item : items) { result += item + ", "; }

// GOOD
String result = String.join(", ", items);
// or
String result = items.stream().collect(Collectors.joining(", "));
```

**5. Comparing Strings (and Integers) with == [community]**
`==` compares object identity, not value. For string literals it "works" due to string interning, masking the bug until strings come from runtime input (database, user, network). Fix: always use `.equals()` for object comparison; use `Objects.equals(a, b)` when either side might be null.

```java
// BAD — works for literals, breaks for runtime strings
if (status == "ACTIVE") { ... }

// GOOD
if ("ACTIVE".equals(status)) { ... }   // null-safe: literal on left
```

**6. Ignoring Thread-Safety of SimpleDateFormat / Calendar [community]**
`SimpleDateFormat` and the old `java.util.Calendar` are not thread-safe. Sharing instances across threads causes data corruption without obvious errors. Fix: use `java.time` (DateTimeFormatter, LocalDate, ZonedDateTime) which is immutable and thread-safe by design.

```java
// BAD — shared across threads
private static final SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd");

// GOOD — DateTimeFormatter is immutable
private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd");
String formatted = LocalDate.now().format(DTF);
```

**7. Catching Exception or Throwable too broadly [community]**
Catching `Exception` swallows `InterruptedException`, which resets the interrupt flag and can deadlock thread pools. Catching `Throwable` swallows `OutOfMemoryError` and `StackOverflowError`, masking JVM-level failures. Fix: catch the narrowest exception type possible; if you must catch broadly, at minimum log and re-interrupt for `InterruptedException`.

```java
// BAD
try { Thread.sleep(1000); } catch (Exception e) { /* swallows interrupt */ }

// GOOD
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // restore interrupt flag
    throw new RuntimeException("Interrupted", e);
}
```

**8. Raw Types Instead of Generics [community]**
Using raw types (e.g., `List` instead of `List<String>`) bypasses compile-time type checking, re-introducing the ClassCastExceptions that generics were designed to prevent. Raw types exist only for backward compatibility. Fix: always parameterize generic types; enable `-Xlint:unchecked` in your build to surface existing raw type usage.

**9. Confusing `Stream.toList()` (Java 16+) with a Mutable List [community]**
`Stream.toList()` returns an **unmodifiable** list (any `add`/`set` throws `UnsupportedOperationException`), whereas `Collectors.toList()` returns a `java.util.ArrayList`. The root cause is that the two methods look identical at a glance and the javadoc distinction is easy to miss. Fix: use `Stream.toList()` when you only need to read results; use `.collect(Collectors.toList())` explicitly when you need to mutate the result list after collection.

```java
// GOOD — read-only result; fast and clear intent
List<String> names = users.stream().map(User::name).toList();

// GOOD — mutable result needed
List<String> mutableNames = users.stream()
    .map(User::name)
    .collect(Collectors.toList());  // returns ArrayList
mutableNames.add("ExtraName");      // safe
```

**10. Blocking Virtual Threads on Synchronized Blocks (Java 21–23) — Fixed in Java 24 [community]**
Virtual threads (introduced in Java 21) are cheap and designed for blocking I/O, but in Java 21–23 a `synchronized` block on a virtual thread **pins it to its carrier OS thread** — negating the scalability benefit. The root cause is that Java 21–23's virtual thread scheduler cannot unmount a pinned virtual thread. **Java 24 (JEP 491) lifted this restriction**: `synchronized` no longer pins virtual threads — they can unmount during blocking operations inside `synchronized` blocks just as they can with `ReentrantLock`. If you are on Java 21–23, the fix is to replace `synchronized` with `java.util.concurrent.locks.ReentrantLock` in high-concurrency paths. On Java 24+, `synchronized` is safe with virtual threads.

```java
// Java 21–23 only: BAD on virtual threads — pins carrier thread
synchronized (lock) {
    result = remoteService.fetchData();  // blocking I/O while pinned (Java 21-23)
}

// Java 21–23: GOOD — ReentrantLock allows the virtual thread scheduler to unmount
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    result = remoteService.fetchData();  // virtual thread can unmount here
} finally {
    lock.unlock();
}

// Java 24+: synchronized is safe with virtual threads (JEP 491)
// The scheduler can now unmount during blocking calls inside synchronized blocks.
// ReentrantLock remains a good choice for its tryLock() / timed-lock API,
// but pinning is no longer a reason to avoid synchronized.
synchronized (this) {
    result = remoteService.fetchData();  // safe on Java 24+ virtual threads
}
```

**11. Storing `Optional<T>` in a Field or Collection [community]**
`Optional` was designed as a return type only — not as a field type, parameter type, or collection element. Storing it in a field means it can itself be `null` (breaking its null-safety promise), it's not `Serializable`, and it adds heap allocation for every absent value. Fix: store `null` or a sentinel value in fields; use `@Nullable` annotations + `Objects.requireNonNull` at API boundaries; never put `Optional` in a `List` or `Map`.

```java
// BAD — Optional as field adds allocation and serialisation problems
public class UserProfile {
    private Optional<String> nickname;  // can itself be null!
}

// GOOD — store null; expose Optional only at the return boundary
public class UserProfile {
    private String nickname;  // null means absent

    public Optional<String> getNickname() {
        return Optional.ofNullable(nickname);
    }
}
```

**12. Breaking the equals/hashCode Contract [community]**
If you override `equals` without overriding `hashCode`, objects that are logically equal will hash to different buckets in `HashMap`/`HashSet`, causing silent lookup failures. The root cause is that Java's `Object.hashCode()` uses object identity by default — a perfectly equal object by your definition will not be found via hash-based lookup unless both methods agree. Fix: always override both together; use `record` which auto-generates a correct contract, or IDE "Generate equals() and hashCode()" — and include the same fields in both.

```java
// BAD — only equals overridden; HashSet/HashMap will break
public class OrderId {
    private final String value;
    public OrderId(String value) { this.value = value; }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof OrderId other)) return false;
        return value.equals(other.value);
    }
    // hashCode NOT overridden — uses identity hash!
}

Set<OrderId> ids = new HashSet<>();
ids.add(new OrderId("ORD-1"));
System.out.println(ids.contains(new OrderId("ORD-1")));  // FALSE — different hash!

// GOOD — record auto-generates correct equals + hashCode
public record OrderId(String value) {}

// GOOD — manual implementation: same fields in both methods
@Override public boolean equals(Object o) {
    return o instanceof OrderId other && value.equals(other.value);
}
@Override public int hashCode() { return Objects.hash(value); }
```

**13. Using HashMap.get() Instead of getOrDefault() / computeIfAbsent() [community]**
Calling `map.get(key)` and immediately checking for null is verbose and error-prone; forgetting the null check causes a NPE. More critically, patterns like `if (!map.containsKey(k)) map.put(k, new ArrayList<>())` are not atomic and break under concurrent access even with `ConcurrentHashMap`. Fix: use `getOrDefault` for read-only lookups and `computeIfAbsent` for read-and-initialize patterns — both are atomic on `ConcurrentHashMap`.

```java
// BAD — two lookups, not atomic
Map<String, List<String>> groups = new ConcurrentHashMap<>();
if (!groups.containsKey(category)) {
    groups.put(category, new ArrayList<>());  // race condition window
}
groups.get(category).add(item);

// GOOD — atomic single operation on ConcurrentHashMap
groups.computeIfAbsent(category, k -> new ArrayList<>()).add(item);

// GOOD — read with default (no mutation)
List<String> items = groups.getOrDefault(category, Collections.emptyList());
```

**14. Implementing `Comparable` When You Should Use `Comparator` [community]**
Implementing `Comparable<T>` embeds a single "natural order" into the class, making it impossible to sort the same type in multiple ways without subclassing or external utilities. The root cause is conflating "entity identity" with "display or business sort order". Fix: implement `Comparable<T>` only for types with a single, universally agreed natural order (e.g., `BigDecimal`, `LocalDate`); use `Comparator` chains for business-specific sort orders to keep the ordering logic near its consumer.

```java
// QUESTIONABLE — baking a particular sort order into the domain object
public class Product implements Comparable<Product> {
    @Override
    public int compareTo(Product other) {
        return this.price.compareTo(other.price);  // forever price-ascending only
    }
}

// BETTER — keep domain class clean; define orderings at the call site
Comparator<Product> byPriceAsc  = Comparator.comparing(Product::price);
Comparator<Product> byNameThenPrice = Comparator.comparing(Product::name)
                                                 .thenComparing(Product::price);

List<Product> sorted = products.stream().sorted(byPriceAsc).toList();
```

**15. Implementing Serializable Without Declaring serialVersionUID [community]**
`java.io.Serializable` triggers automatic `serialVersionUID` generation based on class structure. Adding or removing a field regenerates the UID, causing `InvalidClassException` when deserializing data serialized with the old version. The root cause is treating serialization as a free persistence mechanism. Fix: declare `private static final long serialVersionUID = 1L;` explicitly on every `Serializable` class; or better, avoid `Serializable` entirely — use JSON/Protobuf/Avro for persistence and messaging.

```java
// BAD — compiler-generated serialVersionUID; changes with every class modification
public class UserSession implements Serializable {
    private String userId;
    private Instant createdAt;
    // implicitly: serialVersionUID = <unpredictable hash>
}

// ACCEPTABLE — explicit UID prevents accidental breakage
public class UserSession implements Serializable {
    private static final long serialVersionUID = 1L;
    private String userId;
    private Instant createdAt;
}

// BEST for new code — avoid Serializable; use explicit serialisation
public record UserSession(String userId, Instant createdAt) {}
// Serialize to JSON: objectMapper.writeValueAsString(session)
```

**16. CompletableFuture Swallowing Exceptions Silently [community]**
`CompletableFuture` chains that use `thenApply` or `thenAccept` without a terminal `exceptionally` or `whenComplete` handler will silently swallow exceptions. If the result `CompletableFuture` is never observed (e.g., fire-and-forget), the exception is lost with no log or alert. The root cause is that unlike `Thread.UncaughtExceptionHandler`, there is no default handler for unobserved `CompletableFuture` failures.

```java
// BAD — exceptions vanish if nobody calls .get() or .join() on the future
CompletableFuture.supplyAsync(() -> riskyOperation())
    .thenApply(result -> transform(result));  // if supplyAsync throws, nobody sees it

// GOOD — always attach exceptionally() or whenComplete() for error handling
CompletableFuture.supplyAsync(() -> riskyOperation())
    .thenApply(result -> transform(result))
    .exceptionally(ex -> {
        log.error("Async operation failed", ex);
        return defaultValue();
    });

// GOOD — whenComplete always runs (success or failure)
CompletableFuture.supplyAsync(() -> riskyOperation())
    .whenComplete((result, ex) -> {
        if (ex != null) log.error("Failed", ex);
        else processResult(result);
    });
```
**WHY:** A `CompletableFuture` is not a fire-and-forget mechanism. Unobserved exceptions are "dropped" at the CompletableFuture level without propagating to any thread's uncaught exception handler. In production services, this creates silent failures that are nearly impossible to debug.

**17. Using ThreadLocal with Virtual Threads Causes Memory Leaks [community]**
`ThreadLocal` variables are designed for OS threads where the thread is expensive to create and lives for a long time. With `Executors.newVirtualThreadPerTaskExecutor()`, a new virtual thread is created per task — potentially millions — and if any `ThreadLocal` values are set but not removed via `ThreadLocal.remove()`, they accumulate heap pressure. The root cause is that virtual threads are pooled differently from OS threads but still share `ThreadLocal` semantics. Fix: use `ScopedValue` (Java 21+) for context propagation in virtual-thread-heavy code; always call `threadLocal.remove()` in `finally` blocks if `ThreadLocal` must be used.

```java
// BAD — ThreadLocal leaks with virtual threads
private static final ThreadLocal<RequestContext> CONTEXT = new ThreadLocal<>();

public void handleRequest(Request req) {
    CONTEXT.set(new RequestContext(req.userId()));  // set but potentially never removed
    try {
        processRequest(req);
    } finally {
        CONTEXT.remove();  // MUST remove; easy to forget
    }
}

// GOOD — ScopedValue; automatically cleaned up when scope exits
private static final ScopedValue<RequestContext> CONTEXT = ScopedValue.newInstance();

public void handleRequest(Request req) {
    ScopedValue.where(CONTEXT, new RequestContext(req.userId()))
               .run(() -> processRequest(req));  // cleanup is automatic
}
```
**WHY:** Each virtual thread that sets a `ThreadLocal` and never removes it retains a reference to the object even after the task completes. With millions of short-lived virtual threads, this silently exhausts heap memory.

**18. Not Defensively Copying Mutable Inputs in Constructors [community]**
Storing a mutable collection passed by a caller allows the caller to modify the object's internal state after construction, breaking immutability invariants. This is especially subtle with `List`, `Map`, and `Date` (mutable!). The root cause is assuming the caller will not retain and modify their reference.

```java
// BAD — caller still holds a reference to the list
public class Order {
    private final List<LineItem> items;

    public Order(List<LineItem> items) {
        this.items = items;  // if caller does items.add(...) later, our order changes!
    }
}

// GOOD — defensive copy on entry
public class Order {
    private final List<LineItem> items;

    public Order(List<LineItem> items) {
        this.items = List.copyOf(items);  // immutable snapshot; null-safe
    }

    // ALSO: defensive copy on return if exposing a mutable view
    public List<LineItem> getItems() {
        return Collections.unmodifiableList(items);  // or List.copyOf(items)
    }
}
```
**WHY:** An object that allows external mutation of its fields is not truly immutable. "Final" only prevents reassigning the reference — it does not make the referenced list immutable. Use `List.copyOf()` (null-safe, throws on null elements) or `Collections.unmodifiableList()` depending on whether you need snapshot semantics or a live read-only view.

**19. Misusing Parallel Streams for I/O-bound Work [community]**
`stream.parallel()` uses the common `ForkJoinPool`, which defaults to `Runtime.getRuntime().availableProcessors() - 1` threads. Using it for I/O-bound tasks (database calls, HTTP, file reads) starves CPU-bound computations sharing that pool — and it does NOT scale beyond the number of processors. The root cause is confusing parallelism (more CPUs) with concurrency (more tasks in flight). Fix: use virtual threads (`Executors.newVirtualThreadPerTaskExecutor()`) for I/O-bound concurrency; reserve `parallel()` for CPU-bound, data-parallel operations on large collections.

```java
// BAD — parallel stream doing I/O starves the shared ForkJoinPool
List<User> users = ids.parallelStream()
    .map(id -> database.findUserById(id))  // blocking I/O on ForkJoinPool thread
    .toList();

// GOOD — virtual threads for I/O-bound concurrency
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<User>> futures = ids.stream()
        .map(id -> executor.submit(() -> database.findUserById(id)))
        .toList();
    List<User> users = futures.stream()
        .map(f -> { try { return f.get(); } catch (Exception e) { throw new RuntimeException(e); } })
        .toList();
}

// OK — parallel stream for CPU-bound data processing over large arrays
double sum = largeDoubleArray.stream()
    .parallel()
    .mapToDouble(d -> Math.sqrt(d))   // pure CPU computation — good fit for parallel
    .sum();
```
**WHY:** The `ForkJoinPool` common pool is shared across the entire JVM (including framework internals). Blocking it on I/O tasks can deadlock or severely degrade unrelated parallel streams. Virtual threads are designed exactly for this use case — cheap, scalable I/O concurrency without starving CPU workers.

**20. Forgetting to Close HttpClient (Java 11+) [community]**
`java.net.http.HttpClient` holds a thread pool and connection pool that are NOT automatically closed. Creating a new `HttpClient` per request leaks threads until GC happens to finalize the client. The root cause is that `HttpClient` looks lightweight to create but is actually a heavyweight resource. Fix: create one `HttpClient` instance per application lifecycle (or per connection pool configuration), store it as a field or singleton, and close it on shutdown.

```java
// BAD — new client per request; leaks connection pool threads
public String fetchData(String url) throws Exception {
    var client = HttpClient.newHttpClient();  // new pool every call
    var request = HttpRequest.newBuilder().uri(URI.create(url)).build();
    return client.send(request, BodyHandlers.ofString()).body();
}

// GOOD — shared client, closed with try-with-resources or on shutdown
public class ApiClient implements AutoCloseable {
    private final HttpClient client = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .executor(Executors.newVirtualThreadPerTaskExecutor())  // virtual threads for sends
        .build();

    public String fetch(String url) throws Exception {
        var request = HttpRequest.newBuilder().uri(URI.create(url)).build();
        return client.send(request, BodyHandlers.ofString()).body();
    }

    @Override
    public void close() throws Exception {
        client.close();  // available since Java 21
    }
}
```
**WHY:** Each `HttpClient.newHttpClient()` creates a dedicated thread pool (default: one thread per processor). In applications that make frequent, short-lived calls, this silently accumulates thread stacks until the JVM crashes with `OutOfMemoryError: unable to create native thread`.

**21. Using String.intern() as a Memory Optimization [community]**
`String.intern()` stores a string in the JVM's string pool so that identical strings share a single reference. Developers sometimes use it to reduce memory when storing millions of repeated strings. However, in modern JVMs (JDK 7+), the string pool lives on the heap, and aggressive interning on high-throughput paths is measured to slow down GC because the pool is a permanent reference root. The root cause is applying an outdated optimization from the PermGen era. Fix: use a `HashMap<String, String>` as a manual string cache when you genuinely need deduplication; or use `String.intern()` only for strings that are truly static and few in number (e.g., protocol tokens).

```java
// BAD — interning dynamically generated strings causes GC pressure
for (String line : Files.readAllLines(Path.of("data.csv"))) {
    String key = line.split(",")[0].intern();  // floods string pool with CSV data
    cache.put(key, parseRecord(line));
}

// GOOD — manual canonical map for deduplication with bounded size
private final Map<String, String> canonicalStrings = new HashMap<>();

private String deduplicate(String s) {
    return canonicalStrings.computeIfAbsent(s, k -> k);
}
```
**WHY:** The JVM's string pool is a `ConcurrentHashMap` protected by a global lock. On multi-threaded applications with millions of unique strings, `intern()` becomes a bottleneck. Use explicit deduplication maps with controlled eviction (e.g., `LinkedHashMap` with LRU) instead.

**22. Integer Overflow in Arithmetic Without Using Math.addExact [community]**
Java's `int` and `long` arithmetic silently wraps on overflow — there's no exception, no flag, no indication that a calculation produced a wrong result. This is a common source of subtle bugs in financial calculations, size computations, and index arithmetic. Fix: use `Math.addExact`, `Math.multiplyExact`, and `Math.subtractExact` (Java 8+) when overflow must be detected; use `BigDecimal` for monetary values.

```java
// BAD — silent overflow; no exception, wrong result
int a = Integer.MAX_VALUE;
int b = a + 1;  // b = -2147483648 (Integer.MIN_VALUE) — wrong!

// GOOD — throws ArithmeticException on overflow
int safe = Math.addExact(a, 1);  // throws: "integer overflow"

// GOOD — for financial calculations, BigDecimal is always correct
BigDecimal price   = new BigDecimal("99999999.99");
BigDecimal taxRate = new BigDecimal("0.09");
BigDecimal tax     = price.multiply(taxRate, new MathContext(10, RoundingMode.HALF_EVEN));

// GOOD — detect overflow in complex expressions using long
long result = (long) a * b;  // upcast before multiply to avoid int overflow
if (result > Integer.MAX_VALUE) {
    throw new ArithmeticException("Result exceeds int range: " + result);
}
```
**WHY:** Integer overflow in Java is undefined behavior in C but defined (wrapping) behavior in Java — so the compiler does not flag it and the JVM does not throw. Real-world bugs from silent overflow include the famous `(low + high) / 2` binary search overflow bug and financial calculation errors.

**23. `Arrays.asList()` vs `List.of()` — Fixed-Size vs Truly Immutable [community]**
`Arrays.asList()` returns a fixed-size list backed by the original array: you can call `set()` on it, the array and list share the same backing store (mutating one mutates the other), but calling `add()` or `remove()` throws `UnsupportedOperationException`. `List.of()` returns a truly unmodifiable list where ALL mutating operations throw. The root cause is that `Arrays.asList()` predates the Collections factory methods and has surprising semantics. Fix: prefer `List.of()` for literal immutable lists; use `new ArrayList<>(Arrays.asList(...))` when you need a mutable copy.

```java
String[] arr = {"a", "b", "c"};
List<String> asList = Arrays.asList(arr);   // fixed-size, backed by array

asList.set(0, "z");    // OK — set works
arr[1] = "y";          // also changes asList[1] — same backing array!
asList.add("d");       // throws UnsupportedOperationException

// List.of() — truly immutable, no shared array
List<String> immutable = List.of("a", "b", "c");
immutable.set(0, "z"); // throws UnsupportedOperationException — even set!

// When you need a mutable copy
List<String> mutable = new ArrayList<>(List.of("a", "b", "c"));
mutable.add("d");      // OK
```
**WHY:** Code that receives a `List` and calls `set()` on it will "work" with `Arrays.asList()` but break with `List.of()`. Code that calls `add()` breaks with both but gives the same exception, masking the underlying difference. Always choose the right factory for the intended semantics.

**24. Logging Instead of Propagating Exceptions — Log-and-Rethrow Anti-Pattern [community]**
Logging an exception at the catch site AND re-throwing it results in the same stack trace appearing multiple times in logs — once at the catch point, once at each level above. This makes root-cause analysis harder, not easier. The root cause is defensive logging without considering what the upstream caller does with the exception. Fix: either log OR throw, not both. Only the layer that makes a final decision about the exception (i.e., does not re-throw) should log it.

```java
// BAD — logs the exception AND re-throws it; stack trace appears twice (or more) in logs
public User findUser(long id) {
    try {
        return userRepository.findById(id);
    } catch (DatabaseException e) {
        log.error("Failed to find user {}", id, e);  // logged here
        throw e;                                      // AND propagated — logged again upstream
    }
}

// GOOD — propagate with context; let the boundary layer (controller/handler) log once
public User findUser(long id) {
    try {
        return userRepository.findById(id);
    } catch (DatabaseException e) {
        throw new UserLookupException("Cannot find user id=" + id, e);  // wraps with context
    }
}

// GOOD — boundary layer: log once, at the point of final handling
// (e.g., REST controller exception handler)
@ExceptionHandler(UserLookupException.class)
public ResponseEntity<Error> handleUserLookup(UserLookupException e) {
    log.error("User lookup failed", e);   // logged ONCE
    return ResponseEntity.status(404).body(new Error(e.getMessage()));
}
```
**WHY:** Log-and-rethrow produces duplicate log lines. In high-traffic services, this doubles log volume and makes Kibana/Splunk/Loki searches confusing because the same incident has multiple log entries at different stack depths.

**25. Iterating a Map with `keySet()` and Then Calling `get()` [community]**
Iterating over `map.keySet()` and calling `map.get(key)` inside the loop performs two hash lookups per entry — one to get the key, one to retrieve the value. On large maps or tight loops, this roughly doubles the work. Fix: always iterate over `map.entrySet()` which provides the key-value pair in a single lookup.

```java
// BAD — two hash lookups per iteration (keySet() + get())
for (String key : map.keySet()) {
    String value = map.get(key);   // second lookup — wasteful
    process(key, value);
}

// GOOD — entrySet() provides key and value together (single lookup)
for (Map.Entry<String, String> entry : map.entrySet()) {
    process(entry.getKey(), entry.getValue());
}

// ALSO GOOD — forEach lambda (Java 8+)
map.forEach((key, value) -> process(key, value));

// METHOD REFERENCE form when the method signature matches
map.forEach(MyClass::process);
```
**WHY:** A `HashMap` bucket lookup requires computing `hashCode()`, finding the bucket, and walking the chain. With `keySet()` + `get()`, you do this twice. With `entrySet()`, you traverse the internal table once. For a 10,000-entry map with complex `hashCode()`, this measurably affects performance in hot loops.

**26. Using `Optional.get()` Without `isPresent()` Check [community]**
`Optional.get()` throws `NoSuchElementException` if the Optional is empty — it is NOT a null-safe operation. Using `optional.get()` directly without checking `isPresent()` is no safer than dereferencing a null reference; you've just replaced `NullPointerException` with `NoSuchElementException`. Fix: use `orElse()`, `orElseGet()`, `orElseThrow()`, `ifPresent()`, or `map()`/`flatMap()` chaining — never call `get()` without a preceding `isPresent()` check.

```java
Optional<User> user = repo.findById(id);

// BAD — throws NoSuchElementException if empty; no better than dereferencing null
String email = user.get().getEmail();

// BAD — get() with isPresent() is verbose and breaks the monadic chaining idiom
if (user.isPresent()) {
    String email = user.get().getEmail();
}

// GOOD — declarative, exception thrown on absence with a meaningful message
User u = user.orElseThrow(() -> new UserNotFoundException("No user with id " + id));

// GOOD — provide default
String email = user.map(User::getEmail).orElse("unknown@example.com");

// GOOD — side-effect only when present
user.ifPresent(u -> notificationService.notify(u));

// GOOD — if present/absent both need handling
user.ifPresentOrElse(
    u -> log.info("Found: {}", u.name()),
    () -> log.warn("User {} not found", id)
);
```
**WHY:** `Optional.get()` is the only method on `Optional` that can throw without a null being involved. It exists for rare cases where the developer has external knowledge that the optional is non-empty (e.g., after `isPresent()`). In practice, it signals a design error — if you know the value is present, you shouldn't have returned an `Optional` in the first place.

**27. Modifying a Collection While Iterating It — ConcurrentModificationException [community]**
`java.util` collections (ArrayList, HashMap, HashSet) use a `modCount` mechanism that throws `ConcurrentModificationException` if the collection is structurally modified while an enhanced `for` loop or iterator is in progress. This happens even on single-threaded code. The root cause is using the enhanced for loop (which creates an implicit `Iterator`) and then calling `list.remove()` directly on the collection instead of `iterator.remove()`. Fix: collect items to remove in a separate list and remove after iteration, use `removeIf()`, or use `Iterator.remove()`.

```java
List<String> items = new ArrayList<>(List.of("a", "b", "c", "d"));

// BAD — throws ConcurrentModificationException
for (String item : items) {
    if (item.equals("b")) {
        items.remove(item);  // modifies collection while iterator is live
    }
}

// GOOD — removeIf (Java 8+) — clear, single-line, no manual iterator
items.removeIf(item -> item.equals("b"));

// GOOD — Iterator.remove() — safe way to remove during iteration
Iterator<String> it = items.iterator();
while (it.hasNext()) {
    if (it.next().equals("b")) {
        it.remove();   // safe: removes via iterator, updates modCount correctly
    }
}

// GOOD — collect then remove
List<String> toRemove = items.stream()
    .filter(i -> i.equals("b"))
    .toList();
items.removeAll(toRemove);
```
**WHY:** The fast-fail `modCount` check exists to catch bugs, not as a concurrency mechanism — it works on single-threaded code too. `CopyOnWriteArrayList` avoids the issue but is only appropriate for read-heavy, rarely-written collections due to copy-on-write overhead.

**28. Forgetting to Close Streams from `Files.lines()` [community]**
`Files.lines(path)` opens a file and returns a lazy `Stream<String>`. If the stream is not closed, the file handle leaks until GC runs a finalizer. In applications processing many files, this exhausts the OS file descriptor limit with no helpful error until `Too many open files` appears. Fix: always use `Files.lines()` inside a `try-with-resources` block; or prefer `Files.readAllLines()` for small files where the full content fits in memory.

```java
// BAD — file handle leaks; stream not closed
Stream<String> lines = Files.lines(Path.of("data.txt"));
long count = lines.filter(l -> l.startsWith("#")).count();
// lines is never closed — file descriptor leaks

// GOOD — try-with-resources closes the stream (and the file) automatically
try (Stream<String> lines = Files.lines(Path.of("data.txt"))) {
    long count = lines.filter(l -> l.startsWith("#")).count();
}  // file closed here even if an exception is thrown

// ALSO GOOD — for small files, readAllLines loads fully, closes immediately
List<String> allLines = Files.readAllLines(Path.of("data.txt"), StandardCharsets.UTF_8);
long count = allLines.stream().filter(l -> l.startsWith("#")).count();
```
**WHY:** `Stream<String>` implements `AutoCloseable`, but unlike database connections and sockets, developers rarely think of streams as resources. `Files.lines()` documentation warns about this, but it's easy to miss. In containerised environments with strict fd limits (e.g., Docker default of 1024), this causes failures under moderate load.

**29. Using String.format() in Log Messages Instead of Parameterised Logging [community]**
`String.format("User %s logged in from %s", user, ip)` eagerly builds the string even when the log level is below the threshold. For a `DEBUG` message in production where DEBUG is disabled, this allocates a formatted string for every call, only for the logging framework to immediately discard it. Fix: use parameterised logging arguments (`log.debug("User {} logged in from {}", user, ip)`) which are only evaluated if the message is actually logged.

```java
// BAD — String.format() always runs; allocates a String even when DEBUG is off
log.debug("Processing order " + orderId + " for user " + userId);   // string concat
log.debug(String.format("Computed %d items in %.2fms", count, elapsed));  // String.format

// GOOD — parameterised logging; string only built when level is enabled
log.debug("Processing order {} for user {}", orderId, userId);       // SLF4J style
log.debug("Computed {} items in {}ms", count, elapsed);

// Also good — isEnabled guard for expensive computations
if (log.isDebugEnabled()) {
    log.debug("State dump: {}", expensiveStateSnapshot());  // function not called unless debug on
}
```
**WHY:** In a high-throughput service logging millions of DEBUG lines per second (disabled in prod), String.format() adds significant GC pressure. SLF4J's `{}` placeholders only call `toString()` on the arguments when the level is actually enabled. This is not just a style preference — it is a measurable performance difference in hot code paths.

**30. Ignoring the `@Override` Annotation [community]**
Omitting `@Override` on methods intended to override a supertype method causes silent bugs: if the method signature changes in the supertype (e.g., a parameter type changes or the method is removed), the "override" silently becomes an overload or orphaned method. The root cause is treating `@Override` as optional because the code compiles without it. Fix: always add `@Override` on methods that are intended to override superclass or interface methods — the compiler will flag it immediately if the method no longer matches.

```java
// BAD — if Comparable.compareTo(T other) changes, this silently stops overriding it
public class Version {
    public int compareTo(Version other) {   // missing @Override
        return Integer.compare(this.major, other.major);
    }
}

// GOOD — @Override guarantees this is actually an override; compiler error if not
public class Version implements Comparable<Version> {
    @Override
    public int compareTo(Version other) {
        return Integer.compare(this.major, other.major);
    }
}

// Also: @Override must be used when implementing interface methods in Java 6+
public class EmailSender implements NotificationSender {
    @Override  // required: catches interface method removal/rename at compile time
    public void send(Notification n) { /* ... */ }
}
```
**WHY:** A missing `@Override` on `equals(Object)` is a classic Java trap — developers write `equals(MyClass other)` (an overload) instead of `equals(Object other)` (the override), and the wrong method is silently called in collections. `@Override` turns this runtime bug into a compile-time error.

**31. Stateful Lambdas in Parallel Streams Cause Data Races [community]**
The Java Stream specification requires that behavioral parameters (lambdas in `map`, `filter`, `peek`, etc.) be **stateless** — they must not depend on or modify mutable state outside the lambda. Violating this is safe on sequential streams but causes non-deterministic data races on `parallelStream()`. The root cause is that developers test with sequential streams and promote to parallel without reading the non-interference contract. Fix: ensure all lambdas in a stream pipeline are purely functional (depend only on their input); collect results using `Collectors` instead of mutating an external list.

```java
// BAD — mutable accumulator shared across parallel stream threads; data race
List<String> results = new ArrayList<>();
items.parallelStream()
    .filter(s -> s.length() > 3)
    .forEach(s -> results.add(s));   // ArrayList is not thread-safe; races here

// ALSO BAD — synchronized wrapper removes parallelism benefit; adds contention
List<String> sync = Collections.synchronizedList(new ArrayList<>());
items.parallelStream().forEach(sync::add);

// GOOD — collect() handles thread-safety internally; works correctly in parallel
List<String> results = items.parallelStream()
    .filter(s -> s.length() > 3)
    .collect(Collectors.toList());   // thread-safe collector; correct and fast

// GOOD — stateless lambda referencing only the parameter
List<String> upper = items.parallelStream()
    .map(String::toUpperCase)        // stateless: depends only on the element
    .filter(s -> !s.isBlank())
    .toList();
```
**WHY:** The Java Stream runtime is free to split a parallel stream across threads in any order. `ArrayList.add()` has no synchronisation — two threads calling it concurrently can corrupt the internal array, causing silent data loss or `ArrayIndexOutOfBoundsException` that only appears under load. The correct fix is to use `collect()`, not `synchronizedList`, because synchronised wrappers serialise all access and eliminate the parallelism gain.

**32. ORM Lazy Loading N+1 Query Problem [community]**
When using JPA/Hibernate with default lazy loading, fetching a parent collection and then accessing a child association inside a loop emits one SQL query for the parent list and N additional queries — one per child element. The root cause is that lazy associations load on first access, and most developers don't notice until production load reveals thousands of queries per request. Fix: use JPQL `JOIN FETCH` or JPA `EntityGraph` to load associations in a single query; enable `spring.jpa.show-sql=true` in dev to detect N+1 during testing.

```java
// BAD — N+1 query pattern: 1 query for orders + N queries for customers
List<Order> orders = em.createQuery("SELECT o FROM Order o", Order.class)
    .getResultList();

for (Order order : orders) {
    // Each call to order.getCustomer() fires a separate SELECT — N hits to DB
    System.out.println(order.getCustomer().getName());
}

// GOOD — JOIN FETCH loads customer in a single query
List<Order> orders = em.createQuery(
    "SELECT o FROM Order o JOIN FETCH o.customer", Order.class)
    .getResultList();

// GOOD — JPA EntityGraph: declarative eager loading, no JPQL rewrite
@EntityGraph(attributePaths = {"customer", "lineItems"})
@Query("SELECT o FROM Order o WHERE o.status = :status")
List<Order> findByStatusWithDetails(@Param("status") String status);

// GOOD — detect N+1 in tests with Hibernate statistics
SessionFactory sf = emf.unwrap(SessionFactory.class);
sf.getStatistics().setStatisticsEnabled(true);
// After test: assert sf.getStatistics().getQueryExecutionCount() == 1
```
**WHY:** A page that renders 100 orders will fire 101 database queries with lazy loading and 1 with `JOIN FETCH`. At 1ms per query, that is the difference between a 1ms and 100ms response. Hibernate's default `FetchType.LAZY` is the right choice for fields you often don't need — but you must explicitly opt into eager loading when you know you'll access the association, not rely on the proxy to fetch it for you.

**33. Using `Stream.reduce(String::concat)` for String Joining [community]**
`Stream<String>.reduce("", String::concat)` appears to work but runs in **O(n²)** time because each `concat` call copies all characters accumulated so far into a new string. This is the classic quadratic string concatenation problem manifested in stream form. The root cause is that `reduce` is designed for values (integers, sums) — not for mutable StringBuilder-style accumulation. Fix: use `Collectors.joining()` which uses a `StringJoiner` internally, or `String.join()` for simple cases.

```java
List<String> parts = List.of("Hello", " ", "World", "!");

// BAD — O(n²): each concat copies the growing prefix + next element
String result = parts.stream().reduce("", String::concat);

// GOOD — O(n): Collectors.joining uses StringJoiner, not string copies
String result = parts.stream().collect(Collectors.joining());

// GOOD — with delimiter/prefix/suffix
String csv = parts.stream().collect(Collectors.joining(", ", "[", "]"));
// → "[Hello,  , World, !]"

// GOOD — for a simple fixed-delimiter join without a stream
String joined = String.join(" ", parts);  // → "Hello  World !"
```
**WHY:** On a stream of 10,000 strings each averaging 50 characters, `reduce("", String::concat)` copies roughly 500,000 + 500,050 + 500,100 … ≈ 2.5 billion characters. `Collectors.joining()` copies each character exactly once. The Java Streams API documentation explicitly calls out this anti-pattern in its discussion of mutable reduction.

**34. Calling `stream.parallel()` on a Spliterator With `SUBSIZED` Characteristic Missing [community]**
`parallelStream()` works best when the stream's underlying `Spliterator` can accurately predict sub-split sizes (`SUBSIZED` characteristic). `ArrayList`, arrays, and `IntStream.range()` have `SUBSIZED` — the framework can partition work evenly. `LinkedList`, lazy-generated streams, and custom spliterators that lack this characteristic cause unbalanced work distribution: one thread gets 7/8 of the work and 7 threads sit idle. The root cause is that `parallelStream()` looks the same regardless of the underlying data source — there is no compile-time warning.

```java
// GOOD source for parallelStream — ArrayList is SIZED + SUBSIZED
List<Widget> widgets = new ArrayList<>(loadWidgets());  // converts from LinkedList
double sum = widgets.parallelStream()
    .mapToDouble(Widget::weight)
    .sum();   // even work distribution across ForkJoinPool

// BAD source for parallelStream — LinkedList is ORDERED but not SUBSIZED
List<Widget> linked = new LinkedList<>(loadWidgets());
double sum = linked.parallelStream()    // uneven splits; often slower than sequential
    .mapToDouble(Widget::weight)
    .sum();

// BAD source — lazy infinite stream: unordered sequential generation
Stream<UUID> ids = Stream.generate(UUID::randomUUID);
ids.parallel().limit(1000).forEach(...);  // cannot be split predictably

// GOOD — use Arrays.stream() or IntStream.range() for index-based parallelism
double[] values = fetchValues();
double sum = Arrays.stream(values).parallel().sum();  // optimal splits
```
**WHY:** The `ForkJoinPool` work-stealing algorithm requires sub-split size estimates to balance tasks. Without `SUBSIZED`, the splitter guesses and often front-loads one worker. A `LinkedList.parallelStream()` over 1 million elements typically runs slower than `ArrayList.parallelStream()` over the same elements because the list cannot be split at arbitrary indices — it must traverse from the head.

**35. `BigDecimal.equals()` Considers Scale — Use `compareTo()` for Numeric Equality [community]**
`BigDecimal.equals()` considers both numeric value AND scale — `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` returns `false` even though both represent the same mathematical value. This breaks `HashMap` lookups, `Set` membership tests, and any equality check on `BigDecimal` values that may differ only in trailing zeros. The root cause is that `BigDecimal` encodes significant figures, so `1.0` and `1.00` are semantically different objects (2 sig figs vs 3). Fix: use `compareTo() == 0` for mathematical equality checks; use `stripTrailingZeros()` to normalize before storing in sets or as map keys.

```java
BigDecimal a = new BigDecimal("1.0");
BigDecimal b = new BigDecimal("1.00");

// BAD — equals() checks scale: returns false even though a == b mathematically
System.out.println(a.equals(b));         // false!

// BAD — Map lookup breaks if key was inserted with different scale
Map<BigDecimal, String> prices = new HashMap<>();
prices.put(new BigDecimal("9.90"), "Widget");
String name = prices.get(new BigDecimal("9.9")); // null — different scale, different bucket

// GOOD — use compareTo() for mathematical equality
System.out.println(a.compareTo(b) == 0);  // true

// GOOD — normalize scale before using as map key
Map<BigDecimal, String> normalized = new HashMap<>();
normalized.put(new BigDecimal("9.90").stripTrailingZeros(), "Widget");
String found = normalized.get(new BigDecimal("9.9").stripTrailingZeros()); // "Widget"

// GOOD — sorting/min/max: Comparator based on compareTo
List<BigDecimal> amounts = List.of(new BigDecimal("1.0"), new BigDecimal("1.00"), new BigDecimal("2.5"));
BigDecimal min = amounts.stream().min(BigDecimal::compareTo).orElseThrow();
// → 1.0 (the first 1.x encountered — compareTo considers them equal)
```
**WHY:** Because `BigDecimal` implements `Comparable<BigDecimal>` but `equals()` is inconsistent with `compareTo()`, the documentation explicitly warns that `BigDecimal` is unusual in this respect. Using it in `TreeSet`/`TreeMap` (which use `compareTo`) produces different behavior than `HashSet`/`HashMap` (which use `equals`). Always use `compareTo()` for monetary value comparisons.

**36. Using `double`/`float` for Monetary Values [community]**
`double` and `float` use binary floating-point representation, which cannot exactly represent most decimal fractions. `0.1 + 0.2` in IEEE 754 double precision is `0.30000000000000004`, not `0.3`. This causes rounding errors that silently accumulate in financial calculations — cents off in small transactions become dollars off at scale. The root cause is treating `double` as a "real number" type rather than a "binary approximation" type. Fix: always use `BigDecimal` with explicit scale and `RoundingMode` for money; or represent monetary values as integer cents and convert only for display.

```java
// BAD — binary floating-point loses precision silently
double price  = 0.10;
double tax    = 0.03;
double total  = price + tax;
System.out.println(total);   // 0.13000000000000001 — NOT 0.13

// BAD — accumulation of floating-point errors
double sum = 0.0;
for (int i = 0; i < 1000; i++) {
    sum += 0.01;
}
System.out.printf("%.20f%n", sum);  // 9.99999999999998046... — NOT 10.0

// GOOD — BigDecimal with explicit scale and rounding mode
BigDecimal price  = new BigDecimal("0.10");
BigDecimal tax    = new BigDecimal("0.03");
BigDecimal total  = price.add(tax);  // exactly 0.13

// GOOD — BigDecimal for percentage computations with controlled rounding
BigDecimal vatRate  = new BigDecimal("0.20");
BigDecimal subtotal = new BigDecimal("99.95");
BigDecimal vat      = subtotal.multiply(vatRate)
                               .setScale(2, RoundingMode.HALF_EVEN);  // 19.99

// GOOD — represent as integer cents to avoid any floating point entirely
// store 99 for $0.99; display as amount / 100.0 or BigDecimal.valueOf(cents, 2)
long priceCents = 99L;  // $0.99
long taxCents   = 3L;   // $0.03
long totalCents = priceCents + taxCents;  // 102 cents = $1.02 (exact integer arithmetic)
BigDecimal display = BigDecimal.valueOf(totalCents, 2);  // "1.02"
```
**WHY:** IEEE 754 double has 52 mantissa bits — about 15–16 significant decimal digits. A value like `0.1` is stored as `0.1000000000000000055511151231257827021181583404541015625`. For a high-volume payment system processing a billion transactions at $0.01 each, cumulative rounding errors can produce incorrect totals. The JVM spec guarantees `double` precision but not decimal exactness. `BigDecimal` is the standard Java solution: it stores decimal numbers exactly (subject to the scale you specify) and gives you full control over rounding.

**37. Spring `@Transactional` Self-Invocation Bypass [community]**
When a method annotated with `@Transactional` is called from another method **within the same class**, Spring's proxy-based AOP never intercepts the call — the transaction is silently skipped. The root cause is that Spring's `@Transactional` is implemented via a JDK dynamic proxy or CGLIB subclass: only calls routed through the proxy are intercepted. An internal `this.myMethod()` call bypasses the proxy entirely.

```java
// BAD — internal call bypasses the proxy; no transaction is started for processItem
@Service
public class OrderService {

    public void processBatch(List<Order> orders) {
        for (Order order : orders) {
            this.processItem(order);  // direct method call on 'this'; no proxy intercept!
        }
    }

    @Transactional  // NEVER fires for the internal call above
    public void processItem(Order order) {
        repo.save(order);
        eventPublisher.publish(new OrderProcessed(order.id()));
    }
}

// GOOD — extract to a separate Spring-managed bean so the proxy wraps the call
@Service
public class OrderProcessor {
    @Transactional
    public void processItem(Order order) {
        repo.save(order);
        eventPublisher.publish(new OrderProcessed(order.id()));
    }
}

@Service
public class OrderService {
    private final OrderProcessor processor;

    public void processBatch(List<Order> orders) {
        orders.forEach(processor::processItem);  // goes through proxy — transaction fires
    }
}
```
**WHY:** This is the single most common Spring pitfall. The `@Transactional` annotation on `processItem` will show in the source code, yet the transaction never opens. Debugging requires JPA exception handlers to notice that no EntityManager is bound to the thread. Fix: always call `@Transactional` methods from a different Spring bean; alternatively use `ApplicationContext.getBean(OrderService.class)` to get the proxy, but the separate-bean pattern is far cleaner.

**38. JPA `@Transactional(readOnly = true)` Missing on Read Methods [community]**
Most JPA repositories fetch data without modifying it, yet developers often omit `readOnly = true` on read-only transactions. Without it, Hibernate enables dirty-checking — tracking all loaded entities for changes — even when the method never modifies anything. On large result sets, dirty checking adds significant CPU overhead and prevents some database-side read optimizations (e.g., Postgres allows read replicas for `SET TRANSACTION READ ONLY`). Fix: annotate all read-only service methods with `@Transactional(readOnly = true)`; Spring Data JPA repository methods already do this by default, but custom service methods do not.

```java
// BAD — full transaction with dirty checking, even though nothing is written
@Transactional
public List<OrderSummary> getRecentOrders(String userId) {
    return orderRepo.findByUserIdOrderByCreatedAtDesc(userId, Pageable.ofSize(20));
}

// GOOD — readOnly=true skips dirty checking; hints database read replica routing
@Transactional(readOnly = true)
public List<OrderSummary> getRecentOrders(String userId) {
    return orderRepo.findByUserIdOrderByCreatedAtDesc(userId, Pageable.ofSize(20));
}

// GOOD — default Spring Data JPA: findAll(), findById() already use readOnly=true
// But any custom @Service method wrapping repository calls needs explicit annotation:
@Transactional(readOnly = true)
public DashboardStats getDashboardStats(String tenantId) {
    long orders = orderRepo.countByTenantId(tenantId);
    BigDecimal revenue = orderRepo.sumRevenueByTenantId(tenantId);
    return new DashboardStats(orders, revenue);
}
```
**WHY:** Hibernate's first-level cache tracks every entity loaded in a session. Without `readOnly = true`, it stores a snapshot of each entity for dirty-checking at flush time. On a query returning 10,000 rows, this doubles memory usage and CPU time. With `readOnly = true`, Hibernate skips snapshot creation and tells JDBC drivers the transaction is read-only, enabling connection pool optimizations.

**39. Overriding `finalize()` for Resource Cleanup [community]**
The `finalize()` method (deprecated since Java 9, removed in Java 18) was commonly misused for resource cleanup. Even before removal, relying on it was dangerous: the JVM offers no timing guarantee — an object's finalizer may run minutes after it becomes eligible, or never. This caused file descriptor leaks, database connection exhaustion, and native memory leaks that only appeared under GC pressure. The modern replacement is `java.lang.ref.Cleaner` for post-GC cleanup, but `AutoCloseable` + `try-with-resources` should be the first choice.

```java
// BAD — finalize() is unreliable and has been removed in Java 18+
public class LegacyFileHandle {
    private final FileInputStream fis;

    @Override
    @Deprecated
    protected void finalize() throws Throwable {
        try { fis.close(); } finally { super.finalize(); }
        // Not guaranteed to run; removed in Java 18; never write this
    }
}

// GOOD — AutoCloseable; cleanup is deterministic via try-with-resources
public class FileHandle implements AutoCloseable {
    private final FileInputStream fis;

    public FileHandle(Path path) throws IOException {
        this.fis = new FileInputStream(path.toFile());
    }

    @Override
    public void close() throws IOException {
        fis.close();
    }
}

// GOOD — java.lang.ref.Cleaner for true post-GC cleanup (last-resort safety net only)
// Use only when you cannot control close() call sites (e.g., library code)
public class NativeBuffer {
    private static final java.lang.ref.Cleaner CLEANER = java.lang.ref.Cleaner.create();

    private final long address;
    private final java.lang.ref.Cleaner.Cleanable cleanable;

    public NativeBuffer(int size) {
        this.address = allocateNative(size);
        this.cleanable = CLEANER.register(this, () -> freeNative(address));
        // Cleaner holds a Runnable, NOT a reference to 'this' — no leak
    }

    public void close() {
        cleanable.clean();  // explicit cleanup when possible; Cleaner is the safety net
    }
}
```
**WHY:** `finalize()` created a resurrection window: any finalizer that stores `this` somewhere resurrected the object, requiring two GC cycles to collect. Finalizers also blocked GC threads. `Cleaner` avoids both problems by holding a `Runnable` (no reference to the cleaned object) and running in a separate daemon thread.

**40. Not Using `@SafeVarargs` on Generic Varargs Methods [community]**
When a method accepts `T... args` (generic varargs), the compiler emits an unchecked warning because varargs internally creates an array, and arrays and generics don't mix safely in Java. Developers often suppress this with `@SuppressWarnings("unchecked")` on the caller instead of `@SafeVarargs` on the method declaration. `@SafeVarargs` is the correct solution: it documents that the method itself does not perform unsafe operations on the varargs array, and suppresses the warning at the declaration rather than at every call site.

```java
// BAD — @SuppressWarnings at each call site; boilerplate; wrong layer
@SuppressWarnings("unchecked")
List<String> result = combine(list1, list2, list3);

// ALSO BAD — unchecked warning on the method itself without documentation
public <T> List<T> combine(List<T>... lists) {  // heap pollution warning
    List<T> result = new ArrayList<>();
    for (List<T> list : lists) result.addAll(list);
    return result;
}

// GOOD — @SafeVarargs promises we don't write into the varargs array itself
// Rule: safe if the method only reads from varargs, never writes back to it or escapes it
@SafeVarargs
public final <T> List<T> combine(List<T>... lists) {
    List<T> result = new ArrayList<>();
    for (List<T> list : lists) result.addAll(list);  // only reads lists[i], safe
    return result;
}

// SAFE to call — no warning at call site
List<String> merged = combine(List.of("a", "b"), List.of("c"), List.of("d", "e"));

// UNSAFE — do NOT add @SafeVarargs to this: varargs array element is stored
// @SafeVarargs  ← WRONG
public <T> T[][] storeAll(T... items) {
    return (T[][]) new Object[][]{ items };  // escapes varargs array — NOT safe
}
```
**WHY:** Without `@SafeVarargs`, every call site that passes generic collections gets an unchecked warning, cluttering build output and training developers to suppress warnings broadly. `@SafeVarargs` is the correct contract annotation: it signals that the method author guarantees safe usage, and the warning moves from N call sites to 0. It can only be applied to `final`, `static`, or constructor methods (ensuring the contract cannot be violated by an override).

**41. Using `CopyOnWriteArrayList` in Write-Heavy Scenarios [community]**
`CopyOnWriteArrayList` (and `CopyOnWriteArraySet`) are designed for the rare case where **reads dominate and writes are infrequent**. Every structural modification (add, set, remove) creates a full copy of the underlying array — an O(n) allocation. Under moderate write load, this causes GC pressure that slows read throughput, defeating the purpose. The root cause is assuming "thread-safe list" means "always use `CopyOnWriteArrayList`". Fix: use `CopyOnWriteArrayList` only for event-listener lists and config snapshots where iteration dominates and mutations are very rare. For general concurrent mutable lists, use `Collections.synchronizedList(new ArrayList<>())` with explicit synchronization on the iterator, or a `ConcurrentLinkedDeque`, or redesign with immutable snapshots.

```java
// BAD — write-heavy scenario; CopyOnWriteArrayList copies entire array per add
CopyOnWriteArrayList<String> log = new CopyOnWriteArrayList<>();
for (int i = 0; i < 1_000_000; i++) {
    log.add("event-" + i);   // copies 0, 1, 2, ... i elements = O(n²) total work
}

// GOOD for write-heavy — ConcurrentLinkedDeque or synchronized ArrayList
Queue<String> log = new ConcurrentLinkedDeque<>();
log.add("event");   // O(1); lock-free CAS operation

// CORRECT use of CopyOnWriteArrayList — listener registry (rare writes, many reads)
CopyOnWriteArrayList<EventListener> listeners = new CopyOnWriteArrayList<>();
listeners.add(myListener);           // rare: only when listener registers
// Safe concurrent iteration — snapshot taken at iterator creation time
for (EventListener l : listeners) {  // iterates a frozen snapshot
    l.onEvent(event);
}
```
**WHY:** A `CopyOnWriteArrayList` with 100,000 elements requires copying 800 KB (100,000 × 8-byte references) on every write. In a system adding 10,000 events per second, this creates 8 GB/s of object allocation pressure. The GC overhead produces stop-the-world pauses that hurt the reads the structure was meant to protect. Benchmark before choosing; the JDK `java.util.concurrent` package provides purpose-built alternatives for every concurrency shape.

**42. Using `WeakHashMap` as a General Cache — Keys Evicted Unpredictably [community]**
`WeakHashMap` holds **weak references to its keys** — if the only reference to a key is in the map itself, the key (and its entry) can be garbage-collected at any GC cycle. Developers use it as a "self-cleaning cache" but are surprised when entries disappear while the key is still logically in use, or when entries survive longer than expected because the key is reachable from somewhere else. The root cause is misunderstanding weak reference reachability: string literals and enum constants are always strongly reachable, so `WeakHashMap<String, ...>` and `WeakHashMap<MyEnum, ...>` **never evict entries** — they behave like a regular `HashMap`. Fix: use `WeakHashMap` only when the map's lifecycle should follow the key object's lifecycle (e.g., per-object metadata). For caches with size or TTL eviction, use Caffeine or Guava Cache.

```java
// SURPRISE — String literals are strongly referenced; entries NEVER evict
WeakHashMap<String, Data> cache = new WeakHashMap<>();
String key = "my-key";               // interned literal — always strongly reachable
cache.put(key, heavyData);
key = null;                          // your reference is gone, but the intern pool still holds it
System.gc();
System.out.println(cache.size());    // still 1 — entry was NOT collected!

// CORRECT use — map lifecycle follows key object lifetime
WeakHashMap<MyObject, Metadata> objectMeta = new WeakHashMap<>();
MyObject obj = new MyObject();
objectMeta.put(obj, new Metadata("created"));
// When obj is no longer referenced anywhere:
obj = null;
System.gc();
// Entry may now be collected — map size becomes 0 at some future GC cycle

// GOOD alternative for a time-bounded cache with size eviction
// Use Caffeine (de-facto standard) or Guava Cache
LoadingCache<String, Data> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(Duration.ofMinutes(30))
    .build(key -> loadData(key));
```
**WHY:** `WeakHashMap` offers no control over when eviction occurs — it happens at the GC's discretion, which may be milliseconds or hours after the key becomes weakly reachable. In production, unpredictable eviction under load (when GC runs more frequently) causes cache miss spikes. Moreover, iterating a `WeakHashMap` is not thread-safe even if reads are concurrent — you need external synchronization or a `Collections.synchronizedMap(new WeakHashMap<>())` wrapper. Caffeine's `weakKeys()` option provides the same semantic with LRU eviction bounds and thread safety.

**43. Splitting a Package Across JPMS Modules — Split Packages [community]**
The Java Module System (JPMS) prohibits two different named modules from exporting the same package. A "split package" — where `com.example.util` is defined in both `moduleA` and `moduleB` — causes a module-resolution error at startup: `Error: Module A reads package com.example.util from both A and B`. This is the most common JPMS adoption blocker in large codebases. The root cause is organic code growth where packages were never organized by module boundary. Fix: either merge the modules, rename one of the packages, or move all types to one module and add a `provides`/`uses` ServiceLoader point for extension.

```java
// BAD — com.example.util.StringUtils exists in BOTH moduleA and moduleB
// module-info.java in moduleA:
module moduleA {
    exports com.example.util;  // com.example.util.StringUtils here
}
// module-info.java in moduleB:
module moduleB {
    exports com.example.util;  // com.example.util.DateUtils here — SAME package!
}
// Result: java.lang.module.FindException at startup — both modules read same package

// GOOD — rename to unique packages per module
module moduleA {
    exports com.example.moduleA.util;   // StringUtils lives here
}
module moduleB {
    exports com.example.moduleB.util;   // DateUtils lives here
}

// GOOD — consolidate into a shared utility module
module com.example.shared.util {
    exports com.example.util;  // both StringUtils and DateUtils in one module
}
module moduleA {
    requires com.example.shared.util;  // depends on the shared module
}
module moduleB {
    requires com.example.shared.util;  // same
}
```
**WHY:** JPMS enforces one-module-per-package at the JVM level. This is intentional — split packages break the assumption that a module owns its packages exclusively. In classpath mode (no module-info), the JVM picks the first JAR that provides the package and ignores the rest, causing `ClassNotFoundException` or `NoSuchMethodError` at runtime rather than startup. The JPMS rule surfaces this bug at module-resolution time (before `main()` is called), which is far better than random runtime failures.

**44. Using `instanceof` Checks in Visitor-like Dispatch Instead of Sealed Classes + Switch [community]**
A chain of `if (obj instanceof Foo foo) ... else if (obj instanceof Bar bar) ...` scattered through the codebase is the classic "type tag" anti-pattern. It couples all dispatch sites to the concrete subtypes, requires modifying all sites when a new subtype is added, and provides no exhaustiveness check. The root cause is applying open-world (arbitrary-subclass) thinking to a closed domain model where all variants are known. Fix: model closed hierarchies with `sealed` classes/interfaces and use pattern-matching `switch` — the compiler enforces exhaustiveness and every dispatch site is automatically up-to-date when a new variant is added.

```java
// BAD — instanceof chain; no exhaustiveness; fragile when new type added
public double calculateShipping(Parcel parcel) {
    if (parcel instanceof LetterParcel lp) {
        return lp.weight() * 0.5;
    } else if (parcel instanceof BoxParcel bp) {
        return bp.volume() * 1.2 + bp.weight() * 0.3;
    } else if (parcel instanceof PalletParcel pp) {
        return pp.weight() * 0.8;
    }
    throw new IllegalArgumentException("Unknown parcel type: " + parcel.getClass());
    // Compiler doesn't check if all types are handled — missing type = runtime crash
}

// GOOD — sealed hierarchy + exhaustive switch; compiler rejects missing cases
public sealed interface Parcel permits LetterParcel, BoxParcel, PalletParcel {}
public record LetterParcel(double weight)                        implements Parcel {}
public record BoxParcel(double weight, double volume)            implements Parcel {}
public record PalletParcel(double weight)                        implements Parcel {}

public double calculateShipping(Parcel parcel) {
    return switch (parcel) {
        case LetterParcel  lp -> lp.weight() * 0.5;
        case BoxParcel     bp -> bp.volume() * 1.2 + bp.weight() * 0.3;
        case PalletParcel  pp -> pp.weight() * 0.8;
        // No default needed — compiler verifies all permits variants are covered
        // Adding a new Parcel subtype immediately causes a compile error here
    };
}
```
**WHY:** The `instanceof` chain has a silent completeness assumption that the compiler cannot verify. A new `Parcel` subtype added by a teammate compiles fine, but the shipping calculation silently falls through to the exception. With `sealed + switch`, the compiler flags every `switch` site that doesn't handle the new type — turning a potential runtime bug across the entire codebase into N compile errors that are trivial to fix.

**45. `Object.wait()` / `notify()` Also Pins Virtual Threads in Java 21–23 [community]**
`Object.wait()` and `Object.notify()` are called inside a `synchronized` block by definition, so they suffer the same virtual thread pinning problem as `synchronized` in Java 21–23. A virtual thread calling `wait()` on a monitor blocks its carrier OS thread for the entire wait duration — this is separate from the synchronized-entry pinning issue. In Java 24 (JEP 491), `Object.wait()` was also fixed: virtual threads are now unmounted during `wait()` in Java 24+, just as they are during blocking I/O. On Java 21–23, migrate to `java.util.concurrent.locks.Condition` (from `ReentrantLock`) for coroutine-safe waiting.

```java
// Java 21–23: BAD — Object.wait() pins carrier OS thread for the full wait duration
public class LegacyQueue<T> {
    private final Queue<T> queue = new LinkedList<>();

    public synchronized T take() throws InterruptedException {
        while (queue.isEmpty()) {
            wait();  // pins carrier OS thread in Java 21–23; virtual thread cannot unmount
        }
        return queue.poll();
    }

    public synchronized void put(T item) {
        queue.add(item);
        notifyAll();
    }
}

// Java 21–23: GOOD — ReentrantLock + Condition; virtual thread unmounts during await()
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

public class VirtualThreadSafeQueue<T> {
    private final Queue<T> queue = new LinkedList<>();
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notEmpty = lock.newCondition();

    public T take() throws InterruptedException {
        lock.lock();
        try {
            while (queue.isEmpty()) {
                notEmpty.await();  // virtual thread unmounts; carrier OS thread is free
            }
            return queue.poll();
        } finally {
            lock.unlock();
        }
    }

    public void put(T item) {
        lock.lock();
        try {
            queue.add(item);
            notEmpty.signal();
        } finally {
            lock.unlock();
        }
    }
}

// Java 24+: Object.wait() is safe with virtual threads (JEP 491 also covers wait/notify)
// The original synchronized + wait() form works correctly on Java 24+.
```
**WHY:** In Java 21–23, the JVM cannot unmount a virtual thread from its carrier while it holds a monitor (either blocked on `synchronized` entry OR inside `wait()`). Even a 100ms `wait()` pins the carrier thread for the entire duration. With virtual threads intended to number in the hundreds of thousands, a handful of waiting threads pinning their carriers can starve the entire scheduler. Java 24 resolved both issues (JEP 491).

**46. `List.copyOf()` Throws NullPointerException on Null Elements — Unlike `Collections.unmodifiableList()` [community]**
`List.copyOf(collection)` creates an unmodifiable snapshot and **throws `NullPointerException` if any element is null**. This is intentional (the method contract rejects null elements), but it is easy to confuse with `Collections.unmodifiableList()`, which wraps the original list without null-checking its elements. The root cause is that `List.of()` and `List.copyOf()` enforce "no null elements" as an invariant, whereas `Collections.unmodifiableList()` is a transparent wrapper. The difference is significant when migrating older code that uses null-as-sentinel.

```java
List<String> withNulls = new ArrayList<>(Arrays.asList("a", null, "c"));

// Collections.unmodifiableList — live view; null elements are preserved
List<String> view = Collections.unmodifiableList(withNulls);
System.out.println(view.get(1));  // null — works fine
withNulls.set(0, "z");
System.out.println(view.get(0));  // "z" — reflects mutation in original (live view!)

// List.copyOf — snapshot; THROWS NullPointerException if any element is null
List<String> snapshot = List.copyOf(withNulls);  // throws NullPointerException!

// SAFE pattern when nulls might be present
List<String> safeSnapshot = withNulls.stream()
    .filter(Objects::nonNull)
    .toList();   // null-safe, unmodifiable snapshot

// Also: Map.copyOf() and Set.copyOf() have the same null-rejection rule
Map<String, String> mapWithNull = new HashMap<>();
mapWithNull.put("key", null);  // value is null
Map<String, String> copied = Map.copyOf(mapWithNull);  // throws NullPointerException!
```
**WHY:** `List.of()` / `List.copyOf()` follow the "no-null" contract established by the factory methods for consistency and performance (they can use more efficient internal representations without null checks throughout). If you're replacing `Collections.unmodifiableList()` with `List.copyOf()`, audit for null elements first — the NPE will be thrown at copy time (construction), not when the element is accessed, which can be confusing to diagnose.

**47. Using `new Locale("en", "US")` — Deprecated Since Java 19 [community]**
The `Locale(String, String)` and `Locale(String, String, String)` constructors were deprecated since Java 19 in favour of `Locale.of(String, String)` and the `Locale.Builder` API. The constructors did not validate their inputs — `new Locale("EN", "us")` silently created a malformed locale (language tag should be lowercase, country uppercase). `Locale.of()` normalizes the case, and `Locale.Builder` validates against IETF BCP 47 language tag syntax. The root cause is decades of code written before the API was improved in Java 7 (IANA language tag support) and the deprecation becoming effective only in Java 19.

```java
import java.util.Locale;

// DEPRECATED since Java 19 — no validation, accepts malformed inputs
Locale bad  = new Locale("EN", "us");   // wrong: language should be lowercase, country uppercase
Locale ok   = new Locale("en", "US");   // works but deprecated
Locale bad2 = new Locale("en-US");      // WRONG: this creates a language "en-us", not en/US!

// GOOD — Locale.of() (Java 19+): normalizes language to lowercase, country to uppercase
Locale us      = Locale.of("en", "US");          // normalizes automatically
Locale german  = Locale.of("de", "DE");
Locale chinese = Locale.of("zh", "CN", "Hans");  // with variant

// GOOD — pre-defined constants for common locales (available since Java 1.1)
Locale usStandard = Locale.US;          // Locale.of("en", "US")
Locale uk         = Locale.UK;          // Locale.of("en", "GB")
Locale french     = Locale.FRENCH;      // Locale.of("fr")

// GOOD — Locale.Builder for IETF BCP 47 compliant tags with validation
Locale serbian = new Locale.Builder()
    .setLanguage("sr")
    .setScript("Latn")
    .setRegion("RS")
    .build();

// GOOD — parse from IETF BCP 47 string
Locale fromTag = Locale.forLanguageTag("zh-Hans-CN");  // preferred for external strings

// WARNING: Locale.getDefault() changes affect all code in the JVM — avoid in library code
// Use explicit Locale parameter everywhere instead of relying on default
String formatted = String.format(Locale.US, "%.2f", 3.14159);  // always uses . as decimal
```
**WHY:** `new Locale("en-US")` is a common typo that creates a locale with language tag `"en-us"` (hyphen included in the language code) rather than language `"en"` and country `"US"`. This compiles and runs without error but produces wrong formatting (falls back to ROOT locale) and is invisible until a user sees `"$3.14"` rendered as `"3.14"` or a date displayed in the wrong format.

**48. `String.chars()` Returns `IntStream`, Not `Stream<Character>` [community]**
`String.chars()` returns an `IntStream` of char values (as `int`), not a `Stream<Character>`. This is a source of surprise: mapping `s.chars()` gives you `int` values that must be explicitly cast to `char` to get characters. The root cause is that `char` can be widened to `int` without loss, and providing a primitive `IntStream` avoids boxing overhead — but it makes the API less intuitive. Use `.codePoints()` for Unicode code points (including surrogate pairs); use `chars()` only for BMP characters where `char` encoding is sufficient.

```java
String s = "Hello";

// SURPRISE — chars() returns IntStream, not Stream<Character>
s.chars()
 .forEach(c -> System.out.print(c));  // prints: 72101108108111 (ints, not chars!)

// CORRECT — cast int to char explicitly
s.chars()
 .mapToObj(c -> String.valueOf((char) c))   // IntStream → Stream<String>
 .forEach(System.out::print);              // prints: Hello

// ALSO CORRECT — (char) cast in print
s.chars()
 .forEach(c -> System.out.print((char) c));  // prints: Hello

// For Unicode-correct character processing (handles emoji, surrogate pairs)
"Hello 🌍".codePoints()
    .mapToObj(Character::toString)  // code point → String (handles multi-char emoji)
    .forEach(System.out::print);

// Common use case: count occurrences of a character
long count = "banana".chars()
    .filter(c -> c == 'a')  // compare to int, not char
    .count();  // 3

// Collect chars to a String — needs manual joining
String upper = "hello".chars()
    .map(Character::toUpperCase)
    .collect(StringBuilder::new,
             StringBuilder::appendCodePoint,
             StringBuilder::append)
    .toString();  // "HELLO"

// Simpler for pure transformation: use String methods
String upperSimple = "hello".toUpperCase(Locale.ROOT);  // not always needed via chars()
```
**WHY:** Developers naturally expect `Stream<Character>` from `String.chars()` because `String` is conceptually a sequence of characters. The surprise of getting `IntStream` manifests in code that prints ints instead of chars, or compares `char` literals with `==` against `int` values (which actually works due to promotion, making the bug even subtler). The rule: always cast `c` to `(char)` when you need the character value, or use `Character.toString(c)` for a `String`.

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why it's harmful | What to do instead |
|---|---|---|
| Returning null | Propagates NPE to callers silently | Return `Optional<T>` or throw a well-named exception |
| Overloaded constructors with same parameters | Ambiguous; callers must count arguments | Use static factory methods with descriptive names |
| Overusing inheritance | Couples subclasses to superclass internals; fragile base class problem | Favour composition; use interfaces |
| God class | Single class accretes all logic; impossible to test or change | Apply SRP; split into focused, injected collaborators |
| Magic numbers/strings | Undocumented intent; refactoring breaks silently | Name constants with `static final` or enums |
| Checked exceptions everywhere | Forces callers to handle failures they can't recover from | Use unchecked exceptions; wrap with context |
| Mutable public fields | Any code can change state; invariants impossible to maintain | Use private fields with accessors; prefer records |
| Singleton via static state | Hidden dependency; untestable; concurrency issues | Use dependency injection; pass the dependency |
| String concatenation in loops | O(n²) object allocation | `StringBuilder`, `Collectors.joining()` |
| `== ` for object equality | Compares identity, not value | Always use `.equals()` |
| Ignoring `equals`/`hashCode` contract | Objects in Sets/Maps behave unexpectedly | Override both together; use `record` or IDE generation |
| Exposing mutable internals | Callers can corrupt object state | Return `Collections.unmodifiableList()` or defensive copies |
| Using raw types | Bypasses generic type safety | Always parameterize: `List<String>`, not `List` |
| Catching `Exception`/`Throwable` broadly | Swallows `InterruptedException`, hides JVM errors | Catch the narrowest type; handle `InterruptedException` properly |
| `new Thread()` without pool | Uncontrolled thread creation; OOM under load | Use `ExecutorService` / virtual threads (Java 21) |
| Blocking inside reactive/async code | Defeats concurrency model; stalls thread pools | Use non-blocking APIs; offload to separate executor |
| `synchronized` in virtual threads (Java 21) | Pins carrier OS thread; kills scalability | Use `ReentrantLock` instead of `synchronized` blocks |
| `ThreadLocal` in virtual-thread code | Memory leaks; one leak per task × millions of tasks | Use `ScopedValue` (Java 21+) for context propagation |
| Assuming `Stream.toList()` is mutable | `UnsupportedOperationException` at runtime | Use `Collectors.toList()` when mutation is needed |
| `Optional<T>` as a field or collection element | Not Serializable; can itself be null; adds heap pressure | Store `null`/sentinel in fields; expose `Optional` only at return boundaries |
| `map.get()` + null check instead of `computeIfAbsent` | Verbose; non-atomic under concurrency | Use `computeIfAbsent` (atomic); `getOrDefault` for reads |
| Implementing `Comparable` for multiple sort orders | Locks in one sort order; inflexible | Use `Comparator` chains at the call site; reserve `Comparable` for natural order types |
| `Serializable` without explicit `serialVersionUID` | Class changes silently break deserialization | Declare `serialVersionUID = 1L` or avoid `Serializable`; prefer JSON/Protobuf |
| `stream.parallel()` for I/O-bound tasks | Starves shared ForkJoinPool; blocks CPU-bound work | Use virtual threads (`newVirtualThreadPerTaskExecutor`) for I/O |
| `new HttpClient()` per request | Leaks thread pools; OOM under load | Share one `HttpClient` per application lifecycle; close on shutdown |
| `String.intern()` on dynamic data | Floods JVM pool; GC pause spikes on high-throughput paths | Use a bounded `HashMap` cache for deduplication |
| Integer arithmetic without overflow check | Silent wrap; produces wrong results with no exception | Use `Math.addExact`/`multiplyExact`; `BigDecimal` for money |
| `Arrays.asList()` when immutability is expected | Fixed-size (not immutable); shares backing array | Use `List.of()` for immutable; `new ArrayList<>(...)` for mutable copy |
| Log-and-rethrow exception pattern | Duplicate log entries; obscures root cause in multi-layer stacks | Log once at the final handling boundary; propagate with context otherwise |
| `map.keySet()` + `get()` in loop | Two hash lookups per entry; wasteful on large maps | Iterate `map.entrySet()` or use `map.forEach()` |
| `Optional.get()` without `isPresent()` | Throws `NoSuchElementException` on empty; no safer than null | Use `orElse()`, `orElseThrow()`, `map()`, `ifPresent()` chains |
| Modifying collection during for-each loop | `ConcurrentModificationException` at runtime | Use `removeIf()`, `Iterator.remove()`, or collect-then-remove pattern |
| Unclosed `Files.lines()` stream | Leaks file descriptors; crashes under load with "Too many open files" | Wrap in `try-with-resources`; use `Files.readAllLines()` for small files |
| `String.format()` in log messages | Always builds string even when log level is disabled; adds GC pressure | Use SLF4J parameterised logging `log.debug("msg {}", arg)` |
| Stateful lambda in `parallelStream()` | Data race on shared mutable state; non-deterministic results or corruption | Use `collect(Collectors.toList())` — collector handles thread-safety internally |
| ORM lazy loading in a loop (N+1) | 1 + N database queries per request; invisible until production load | Use `JOIN FETCH` or `@EntityGraph` to load associations in a single query |
| `stream.reduce("", String::concat)` for joining | O(n²) string copying; quadratic time on large streams | Use `Collectors.joining()` or `String.join()` |
| `parallelStream()` on SUBSIZED-absent sources (LinkedList) | Unbalanced work splits; often slower than sequential | Use `ArrayList`, arrays, or `IntStream.range()` as parallel stream source |
| Module imports (`import module`) misuse | Ambiguous type resolution when same name exists in two modules | Add explicit single-type import after module import to resolve ambiguity |
| `BigDecimal.equals()` for numeric equality | Returns false for same value with different scale (1.0 ≠ 1.00) | Use `compareTo() == 0`; `stripTrailingZeros()` before using as map key |
| `double`/`float` for monetary values | Binary floating-point cannot represent 0.1 exactly; silent rounding errors accumulate | Use `BigDecimal` with explicit scale and `RoundingMode`; or store as integer cents |
| Spring `@Transactional` on self-invoked method | AOP proxy not in call path; transaction silently never opens | Call `@Transactional` methods from a different Spring-managed bean |
| No `@Transactional(readOnly = true)` on reads | Hibernate dirty-checks all loaded entities; wasted CPU + memory | Always annotate read-only service methods with `readOnly = true` |
| `finalize()` for resource cleanup | No timing guarantee; deprecated Java 9, removed Java 18; GC resurrection risk | Use `AutoCloseable` + `try-with-resources`; `Cleaner` as last-resort safety net |
| Missing `@SafeVarargs` on generic varargs | Unchecked warning at every call site; N warnings instead of 1 at declaration | Add `@SafeVarargs` to `final`/`static` methods that only read from varargs |
| In-memory H2 instead of real DB in tests | Dialect differences (JSON columns, arrays, window functions) hide integration bugs | Use Testcontainers with the production database engine (Postgres, MySQL, etc.) |
| `Thread.sleep()` in async test assertions | Flaky: too short = false failure, too long = slow CI | Use Awaitility `await().untilAsserted(...)` for polling async state |
| Split packages across JPMS modules | Module-resolution error at startup; two modules own the same package | Rename packages per module or consolidate into a shared module |
| `instanceof` chain instead of sealed + switch | Compiler cannot verify exhaustiveness; new subtypes break dispatch silently | Use `sealed` hierarchy + pattern-matching `switch`; compiler enforces all variants |
| Infrastructure code in domain module | Domain imports Spring/JDBC/Kafka; cannot test domain without starting infrastructure | Apply hexagonal architecture; keep domain behind ports (interfaces); adapters implement ports |
| `Object.wait()` in virtual threads (Java 21–23) | `wait()` pins carrier OS thread for entire wait duration; same as synchronized pinning | Use `ReentrantLock` + `Condition.await()` on Java 21–23; safe on Java 24+ |
| `List.copyOf()` on collection with null elements | Throws `NullPointerException` at construction time (unlike `Collections.unmodifiableList()`) | Filter nulls first (`stream().filter(Objects::nonNull).toList()`) or use `unmodifiableList` if nulls are expected |
| `new Locale("en", "US")` — deprecated constructor | No input validation; `new Locale("en-US")` silently creates wrong locale | Use `Locale.of("en", "US")`, predefined `Locale.US`, or `Locale.forLanguageTag("en-US")` |
| `String.chars()` used as `Stream<Character>` | Returns `IntStream` of `int` values; printing without cast yields integers | Cast `(char) c` or use `Character.toString(c)`; use `codePoints()` for Unicode correctness |

---

## Java Testing Patterns

Modern Java testing relies on four complementary layers: JUnit 5 for test structure, Mockito for isolation, AssertJ for expressive assertions, and Testcontainers for real-infrastructure integration tests. Use them together; each covers what the others cannot.

### JUnit 5 — Parameterized and Dynamic Tests

JUnit 5's `@ParameterizedTest` eliminates copy-pasted test methods. `@CsvSource` covers table-driven cases inline; `@MethodSource` provides complex object arguments. `@DynamicTest` generates tests at runtime for property-based or data-driven scenarios.

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import java.util.stream.Stream;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

class DiscountCalculatorTest {

    // Inline table-driven — each row is a separate test
    @ParameterizedTest(name = "qty={0}, price={1} → expected={2}")
    @CsvSource({
        "1,  100.0,  100.0",
        "10, 100.0,  90.0",   // 10% bulk discount
        "50, 100.0,  75.0",   // 25% volume discount
    })
    void bulkDiscount(int qty, double price, double expected) {
        assertEquals(expected, new DiscountCalculator().apply(qty, price), 0.001);
    }

    // MethodSource: complex objects as arguments
    @ParameterizedTest
    @MethodSource("invalidOrders")
    void rejectsInvalidOrders(Order order, String reason) {
        assertThrows(IllegalArgumentException.class,
            () -> new OrderValidator().validate(order), reason);
    }

    static Stream<org.junit.jupiter.params.provider.Arguments> invalidOrders() {
        return Stream.of(
            org.junit.jupiter.params.provider.Arguments.of(
                new Order(null, 1), "null product"),
            org.junit.jupiter.params.provider.Arguments.of(
                new Order("SKU-1", -1), "negative quantity")
        );
    }

    // TestFactory — generate tests dynamically (e.g., from a data file)
    @TestFactory
    Stream<DynamicTest> dynamicDiscountTests() {
        return Stream.of(
            new int[]{1, 100, 100},
            new int[]{10, 100, 90},
            new int[]{50, 100, 75}
        ).map(row -> dynamicTest(
            "qty=%d price=%d → %d".formatted(row[0], row[1], row[2]),
            () -> assertEquals(row[2],
                (int) new DiscountCalculator().apply(row[0], row[1]))
        ));
    }
}
```

### Mockito — Argument Captors and Strict Mocks

Use `ArgumentCaptor` when you need to assert on complex objects passed to a mock (e.g., verify the exact event published). Enable `MockitoSettings(strictness = STRICT_STUBS)` to catch unnecessary stubbing — stubs that are set up but never called indicate dead test code.

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.STRICT_STUBS)  // fails on unnecessary stubs
class OrderServiceTest {

    @Mock  NotificationSender sender;
    @Mock  OrderRepository    repo;
    @InjectMocks OrderService service;

    @Captor ArgumentCaptor<Notification> notifCaptor;

    @Test
    void placingOrder_sendsConfirmationWithCorrectDetails() {
        // Arrange
        Order order = new Order("ORD-1", "user-42", 99.99);
        when(repo.save(order)).thenReturn(order);

        // Act
        service.placeOrder(order);

        // Assert — capture what was actually sent to the sender
        verify(sender).send(notifCaptor.capture());
        Notification sent = notifCaptor.getValue();
        assertThat(sent.recipient()).isEqualTo("user-42");
        assertThat(sent.subject()).contains("ORD-1");
        assertThat(sent.body()).contains("99.99");
    }

    @Test
    void placeOrder_doesNotSendOnRepositoryFailure() {
        when(repo.save(any())).thenThrow(new DatabaseException("disk full"));
        assertThrows(OrderException.class, () -> service.placeOrder(new Order()));
        verifyNoInteractions(sender);  // important: no notification on failure
    }
}
```

### AssertJ — Fluent, Readable Assertions

AssertJ's fluent API produces far more informative failure messages than JUnit `assertEquals` and enables chained assertions on the same subject without repeating it. Use `assertThatThrownBy` for exception assertions and `assertThat(list).extracting(...)` for collection field assertions.

```java
import static org.assertj.core.api.Assertions.*;

@Test
void assertj_fluent_assertions() {
    List<User> users = List.of(
        new User("Alice", "alice@example.com", 30, true),
        new User("Bob",   "bob@example.com",   25, false)
    );

    // Collection assertions — readable, composable
    assertThat(users)
        .hasSize(2)
        .extracting(User::name)
        .containsExactly("Alice", "Bob");

    // Field-level extraction across collection
    assertThat(users)
        .extracting(User::name, User::active)
        .containsExactly(
            tuple("Alice", true),
            tuple("Bob",   false)
        );

    // Exception assertion — better than assertThrows when you need the message
    assertThatThrownBy(() -> new User(null, "test@x.com", 25, true))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("name");

    // Optional assertion — don't unwrap manually
    Optional<User> found = Optional.of(users.get(0));
    assertThat(found)
        .isPresent()
        .hasValueSatisfying(u -> assertThat(u.email()).endsWith("@example.com"));

    // Map assertions
    Map<String, User> byEmail = Map.of("alice@example.com", users.get(0));
    assertThat(byEmail)
        .containsKey("alice@example.com")
        .extractingByKey("alice@example.com")
        .extracting(User::name)
        .isEqualTo("Alice");
}
```

### Testcontainers — Real Infrastructure in Integration Tests

Testcontainers starts disposable Docker containers for databases, message brokers, and other services. Tests run against the actual technology — not a mock or in-memory substitute — so integration issues surface in CI rather than production.

```java
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
class UserRepositoryIntegrationTest {

    // Container is shared across all tests in this class (reuse = true)
    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    // Wire the dynamic port into Spring's datasource config before context starts
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",    postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired UserRepository repo;

    @Test
    void savedUser_canBeRetrievedById() {
        User saved = repo.save(new User("Alice", "alice@example.com"));
        Optional<User> found = repo.findById(saved.id());
        assertThat(found).isPresent()
            .hasValueSatisfying(u -> assertThat(u.email()).isEqualTo("alice@example.com"));
    }
}
```

**Testing anti-patterns:**

| Anti-Pattern | Why it's harmful | What to do instead |
|---|---|---|
| `assertEquals` with cryptic failure message | `expected: <42> but was: <43>` gives no context | Use AssertJ's `assertThat(actual).isEqualTo(42).as("order total after 10% discount")` |
| In-memory H2 instead of real DB for integration tests | H2 ignores dialect differences (JSON columns, array types, window functions) that break on Postgres | Use Testcontainers with the production database engine |
| `Mockito.when(...)` on every test even when stub is irrelevant | Unnecessary stubs mask unused-stub bugs and add noise | Enable `STRICT_STUBS`; only stub what the test exercises |
| Testing private methods directly via reflection | Brittle; private APIs change without notice | Test behaviour through public API; if private method is complex, extract it to a package-private collaborator |
| `Thread.sleep()` in tests to wait for async events | Flaky; too short = false failures, too long = slow CI | Use `Awaitility.await().untilAsserted(...)` for polling; or restructure to synchronous testing with `@Async` disabled |
| Forgetting `@AutoConfigureTestDatabase(replace = NONE)` when using `@ServiceConnection` with `@DataJpaTest` | Spring Boot replaces the container datasource with H2 despite `@ServiceConnection` being present | Always add `replace = Replace.NONE` on `@DataJpaTest` when using Testcontainers `@ServiceConnection` |
| Using `@MockBean` in Spring Boot 3.4+ | `@MockBean` still works but `@MockitoBean` is now the canonical API and will receive future improvements | Migrate to `@MockitoBean` / `@MockitoSpyBean` from `org.springframework.test.context.bean.override.mockito` |

---

## REST Assured — API Testing DSL

REST Assured brings readable, BDD-style HTTP API testing to Java. Its `given/when/then` DSL reads like a specification and integrates with Hamcrest matchers for rich JSON/XML assertions.

**Version 6.0 baseline:** Java 17+, Spring Framework 7, Jackson 3, Groovy 5. Released 2025-12-12.

**Maven dependency:**
```xml
<dependency>
  <groupId>io.rest-assured</groupId>
  <artifactId>rest-assured</artifactId>
  <version>6.0.0</version>
  <scope>test</scope>
</dependency>
```

### Core Pattern: given / when / then

```java
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

// Minimal GET assertion
when()
    .get("https://api.example.com/users/1")
.then()
    .statusCode(200)
    .body("id", equalTo(1))
    .body("name", notNullValue());
```

### Full Request with given()

```java
import io.restassured.http.ContentType;

given()
    .baseUri("https://api.example.com")
    .contentType(ContentType.JSON)
    .header("Authorization", "Bearer " + token)
    .pathParam("userId", 42)
    .queryParam("include", "profile")
    .body("""
        {
          "name": "Alice Updated",
          "email": "alice@example.com"
        }
        """)
.when()
    .put("/users/{userId}")
.then()
    .statusCode(200)
    .body("name", equalTo("Alice Updated"))
    .body("email", equalTo("alice@example.com"))
    .header("Content-Type", containsString("application/json"));
```

### JSON Path Assertions

REST Assured uses GPath (Groovy) expressions for JSON/XML traversal — a superset of JSONPath:

```java
given()
    .get("/orders")
.then()
    .statusCode(200)
    // Nested property
    .body("orders[0].customer.name", equalTo("Alice"))
    // Collection size
    .body("orders", hasSize(greaterThan(0)))
    // Presence in collection
    .body("orders.id", hasItems(101, 102, 103))
    // Filtering (GPath)
    .body("orders.findAll { it.status == 'PAID' }.size()", equalTo(2))
    // Nested array element
    .body("orders[0].items[0].sku", startsWith("SKU-"));
```

### Reusable Request/Response Specifications

Centralise common configuration so individual tests only specify what varies:

```java
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;
import org.junit.jupiter.api.BeforeAll;

class UserApiTest {

    private static RequestSpecification requestSpec;
    private static ResponseSpecification responseSpec;

    @BeforeAll
    static void setupSpecs() {
        requestSpec = new RequestSpecBuilder()
            .setBaseUri("https://api.example.com")
            .addHeader("Authorization", "Bearer " + System.getenv("API_TOKEN"))
            .setContentType(ContentType.JSON)
            .build();

        responseSpec = new ResponseSpecBuilder()
            .expectStatusCode(200)
            .expectContentType(ContentType.JSON)
            .build();
    }

    @Test
    void getUser_returnsProfile() {
        given()
            .spec(requestSpec)
            .pathParam("id", 1)
        .when()
            .get("/users/{id}")
        .then()
            .spec(responseSpec)
            .body("id", equalTo(1));
    }

    @Test
    void createUser_returns201() {
        given()
            .spec(requestSpec)
            .body(new UserRequest("Bob", "bob@example.com"))
        .when()
            .post("/users")
        .then()
            .statusCode(201)
            .body("name", equalTo("Bob"));
    }
}
```

### Authentication

```java
// Basic auth
given()
    .auth().basic("username", "password")
    .get("/secure-endpoint");

// OAuth 2 bearer token
given()
    .auth().oauth2(accessToken)
    .get("/api/resource");

// Preemptive basic auth (sends credentials without waiting for 401 challenge)
given()
    .auth().preemptive().basic("user", "pass")
    .get("/resource");
```

### Extracting Response Values

```java
// Extract a single field
String name = given()
    .pathParam("id", 1)
.when()
    .get("/users/{id}")
.then()
    .statusCode(200)
.extract()
    .path("name");

// Extract the full response body as a POJO
User user = given()
    .get("/users/1")
.then()
    .statusCode(200)
.extract()
    .as(User.class);

// Extract a header
String location = given()
    .body(newUserJson)
.when()
    .post("/users")
.then()
    .statusCode(201)
.extract()
    .header("Location");
```

### Spring MockMvc Integration

For Spring Boot tests without a running server:

```java
import io.restassured.module.mockmvc.RestAssuredMockMvc;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        RestAssuredMockMvc.mockMvc(mockMvc);
    }

    @Test
    void getUser_returns200() {
        RestAssuredMockMvc
            .given()
                .param("id", 1)
            .when()
                .get("/users/{id}", 1)
            .then()
                .statusCode(200)
                .body("id", equalTo(1));
    }
}
```

### REST Assured Anti-Patterns

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Hard-coded base URL in every test | Breaks when environment changes; impossible to run against staging | Set `RestAssured.baseURI` globally in `@BeforeAll` or use `RequestSpecBuilder` |
| `statusCode(200)` but no body assertion | Test passes even if the response body is empty or malformed | Always assert at least one meaningful field in the response body |
| No `RequestSpecification` for shared headers | Auth token and content-type repeated in every test; change in one place misses others | Extract shared config into `RequestSpecBuilder` applied in `@BeforeAll` |
| Asserting on `body()` without `statusCode()` | A 500 error with a matching fragment in the error body causes a false positive | Always assert `statusCode` before body content |
| Checking collection order with `equalTo(list)` | Order-sensitive assertion fails on sorted/paginated responses with different order | Use `containsInAnyOrder()` or `hasItems()` unless order is part of the contract |
| `extract().path()` for every field separately | Multiple `.extract()` calls each deserialize the response | Use `extract().as(MyDto.class)` to deserialize once and assert on the POJO |
| Parsing JWT/signed headers manually in tests | Brittle; breaks when signing algorithm changes | Use mock Auth servers (WireMock/Testcontainers Keycloak) for full token flow |
| `CopyOnWriteArrayList` in write-heavy scenarios | O(n) array copy per write; GC pressure destroys throughput | Use `ConcurrentLinkedDeque` or `Collections.synchronizedList`; reserve COW for listener registries |
| `WeakHashMap` with interned keys (String/enum) | Interned keys are always strongly reachable; entries never evict — behaves like a regular HashMap | Use `WeakHashMap` only for per-object metadata whose lifetime follows the key; use Caffeine for TTL/size-bounded caches |
| Missing `@Override` annotation | Silent overloads instead of overrides; bugs evade the compiler | Always annotate intended overrides; catches signature mismatches at compile time |

---

## WireMock — HTTP Stub Server for External API Testing

WireMock is the standard tool for stubbing external HTTP services in Java integration tests. It starts an embedded HTTP server that intercepts calls to external APIs (payment gateways, third-party REST services, internal microservices) and returns programmed responses. Tests run fast, deterministically, and without real network access.

**Maven dependency (WireMock 3.x, JUnit 5):**
```xml
<dependency>
  <groupId>org.wiremock</groupId>
  <artifactId>wiremock-standalone</artifactId>
  <version>3.5.4</version>
  <scope>test</scope>
</dependency>
```

### Core Pattern: Stub + Verify

```java
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import com.github.tomakehurst.wiremock.client.WireMock;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

class PaymentGatewayClientTest {

    // WireMock starts on a random port; use getPort() to configure the SUT
    @RegisterExtension
    static WireMockExtension wm = WireMockExtension.newInstance()
        .options(wireMockConfig().dynamicPort())
        .build();

    @Test
    void chargeCard_successfulResponse_returnsTransactionId() {
        // Stub: return a 200 for POST /charges
        wm.stubFor(post(urlEqualTo("/charges"))
            .withHeader("Content-Type", equalTo("application/json"))
            .withRequestBody(matchingJsonPath("$.amount", equalTo("9999")))
            .willReturn(aResponse()
                .withStatus(200)
                .withHeader("Content-Type", "application/json")
                .withBody("""
                    {"transactionId": "txn-abc-123", "status": "APPROVED"}
                    """)));

        // System under test configured to hit WireMock's URL
        PaymentGatewayClient client =
            new PaymentGatewayClient("http://localhost:" + wm.getPort());

        ChargeResult result = client.charge(new ChargeRequest("card-tok-1", 9999));

        assertThat(result.transactionId()).isEqualTo("txn-abc-123");
        assertThat(result.status()).isEqualTo("APPROVED");

        // Verify: assert the SUT sent the expected request
        wm.verify(postRequestedFor(urlEqualTo("/charges"))
            .withHeader("Authorization", matching("Bearer .+"))
            .withRequestBody(matchingJsonPath("$.token", equalTo("card-tok-1"))));
    }

    @Test
    void chargeCard_gatewayTimeout_throwsRetryableException() {
        // Stub a network-level timeout
        wm.stubFor(post(urlEqualTo("/charges"))
            .willReturn(aResponse()
                .withFault(com.github.tomakehurst.wiremock.http.Fault.CONNECTION_RESET_BY_PEER)));

        PaymentGatewayClient client =
            new PaymentGatewayClient("http://localhost:" + wm.getPort());

        assertThatThrownBy(() -> client.charge(new ChargeRequest("card-tok-1", 100)))
            .isInstanceOf(RetryableGatewayException.class);
    }

    @Test
    void chargeCard_rate429_triggersBackoff() {
        // First call: 429 Too Many Requests; second call: 200 OK
        wm.stubFor(post(urlEqualTo("/charges"))
            .inScenario("Rate Limit")
            .whenScenarioStateIs("Started")
            .willSetStateTo("Retried")
            .willReturn(aResponse().withStatus(429)
                .withHeader("Retry-After", "1")));

        wm.stubFor(post(urlEqualTo("/charges"))
            .inScenario("Rate Limit")
            .whenScenarioStateIs("Retried")
            .willReturn(aResponse().withStatus(200)
                .withBody("{\"transactionId\":\"txn-retry-1\",\"status\":\"APPROVED\"}")));

        PaymentGatewayClient client =
            new PaymentGatewayClient("http://localhost:" + wm.getPort());
        ChargeResult result = client.chargeWithRetry(new ChargeRequest("tok", 100));
        assertThat(result.transactionId()).isEqualTo("txn-retry-1");
        wm.verify(2, postRequestedFor(urlEqualTo("/charges")));
    }
}
```

### WireMock Anti-Patterns  [community]

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `stubFor(any(anyUrl()).willReturn(ok()))` catch-all stub | Any request hits the stub, masking routing bugs and missing requests | Stub exact URL + method + key header/body fields |
| Not calling `verify()` after stubbing | Test proves the SUT handles the response but not that it sent the right request | Always `verify(postRequestedFor(...))` to assert outbound request shape |
| Hard-coded WireMock port | Tests fail if another service holds the port on CI | Always use `dynamicPort()` and configure the SUT with `getPort()` |
| Stubbing response bodies as raw strings inline | Long JSON strings are brittle and hard to maintain | Load stub bodies from `__files/` classpath resources; use `aResponse().withBodyFile("response.json")` |
| Sharing a single WireMock instance across tests without reset | Stubs from test A fire in test B; test ordering matters | Use `@RegisterExtension` per class (resets between tests automatically) or call `wm.resetAll()` in `@BeforeEach` |

---

## Awaitility — Polling Async State in Tests

Awaitility is the standard Java library for asserting on asynchronous outcomes in tests. Instead of sleeping for a fixed duration (which causes either false failures or slow CI), Awaitility polls the assertion on a configurable interval until it passes or times out.

**Maven dependency:**
```xml
<dependency>
  <groupId>org.awaitility</groupId>
  <artifactId>awaitility</artifactId>
  <version>4.2.2</version>
  <scope>test</scope>
</dependency>
```

### Core Pattern

```java
import static org.awaitility.Awaitility.await;
import static org.awaitility.Durations.*;
import static org.assertj.core.api.Assertions.assertThat;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class EmailServiceTest {

    @Test
    void publishingAnEvent_eventuallySendsConfirmationEmail() {
        // Arrange — trigger async email dispatch
        eventBus.publish(new OrderPlaced("ORD-42", "alice@example.com"));

        // Assert — poll every 100ms for up to 5 seconds
        await()
            .atMost(Duration.ofSeconds(5))
            .pollInterval(Duration.ofMillis(100))
            .untilAsserted(() ->
                assertThat(capturedEmails)
                    .anySatisfy(email -> {
                        assertThat(email.to()).isEqualTo("alice@example.com");
                        assertThat(email.subject()).contains("ORD-42");
                    })
            );
    }

    @Test
    void processingQueue_drainsAllItemsEventually() {
        queue.addAll(List.of("item-1", "item-2", "item-3"));
        processor.startAsync();

        // Wait until the predicate becomes true
        await("queue drained")   // alias helps identify which await failed
            .atMost(TEN_SECONDS)
            .until(() -> queue.isEmpty());

        assertThat(processedItems).containsExactlyInAnyOrder("item-1", "item-2", "item-3");
    }

    @Test
    void cacheWarmer_populatesCacheWithinSLA() {
        cacheWarmer.start();

        // Assert with custom poll interval and ignore exceptions during warmup
        await()
            .atMost(Duration.ofSeconds(10))
            .pollInterval(ONE_HUNDRED_MILLISECONDS)
            .ignoreExceptions()   // don't fail the wait on CacheNotReadyException
            .untilAsserted(() ->
                assertThat(cache.get("key-1")).isNotNull()
            );
    }
}
```

### Awaitility Best Practices  [community]

- **Always use `untilAsserted()`** with AssertJ assertions rather than `until(() -> condition)` when you need to inspect values — `untilAsserted` gives you a rich failure message if the timeout is hit.
- **Name your awaits** with the string overload `await("what we're waiting for")` — the name appears in the timeout exception, making CI failures self-documenting.
- **Use `ignoreExceptions()`** when the state under test transitions through exception-throwing intermediate states (e.g., a cache that throws before it's warmed up).
- **Set a global default** in `@BeforeAll`: `Awaitility.setDefaultTimeout(Duration.ofSeconds(5))` — avoids repeating the same `atMost(...)` in every test.
- **Never mix Awaitility with `Thread.sleep()`** before the await — the poll starts immediately; a prior sleep adds latency for no benefit.

---

## Spring Boot Test Slices — Focused Integration Tests

Spring Boot's test slice annotations start only the subset of the application context needed for a specific layer — no full `@SpringBootApplication` context. This makes slice tests 3–10× faster than full `@SpringBootTest` while still testing real Spring wiring, validation, and data access.

### @WebMvcTest — Controller Layer Only

`@WebMvcTest` starts the MVC layer (controllers, filters, `HandlerMethodArgumentResolver`, security configuration) but does NOT start the service or repository layers. Use `@MockBean` to inject mock collaborators.

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)  // only UserController's slice is started
class UserControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockBean
    UserService userService;   // real service layer is NOT started; this is a Mockito mock

    @Test
    void getUser_existingId_returns200WithBody() throws Exception {
        given(userService.findById(1L))
            .willReturn(new UserDto(1L, "Alice", "alice@example.com"));

        mockMvc.perform(get("/users/1").accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("Alice"))
            .andExpect(jsonPath("$.email").value("alice@example.com"));
    }

    @Test
    void createUser_invalidBody_returns400() throws Exception {
        // @Valid on controller parameter triggers Bean Validation before service is called
        String invalidBody = """
            {"name": "", "email": "not-an-email"}
            """;

        mockMvc.perform(post("/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidBody))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errors").isArray());
    }

    @Test
    void getUser_notFound_returns404() throws Exception {
        given(userService.findById(99L))
            .willThrow(new UserNotFoundException("No user with id 99"));

        mockMvc.perform(get("/users/99"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.message").value("No user with id 99"));
    }
}
```

### @DataJpaTest — Repository Layer Only

`@DataJpaTest` starts only the JPA layer (entities, repositories, Hibernate, embedded DB by default). It wraps each test in a transaction that rolls back after the test — no cleanup code needed. Use `@AutoConfigureTestDatabase(replace = NONE)` with Testcontainers to test against the real database engine.

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = Replace.NONE)  // don't replace with H2; use real Postgres
class UserRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url",      postgres::getJdbcUrl);
        r.add("spring.datasource.username", postgres::getUsername);
        r.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    UserRepository repo;

    @Test
    void findByEmail_existingEmail_returnsUser() {
        // Arrange — @DataJpaTest wraps in a transaction; rolled back after test
        repo.save(new User("Alice", "alice@example.com"));

        // Act
        var found = repo.findByEmail("alice@example.com");

        // Assert
        assertThat(found).isPresent()
            .hasValueSatisfying(u -> assertThat(u.name()).isEqualTo("Alice"));
    }

    @Test
    void findActiveUsersSince_returnsOnlyActiveAfterCutoff() {
        var cutoff = Instant.now().minus(Duration.ofDays(7));
        repo.save(new User("Alice", "a@x.com", true,  Instant.now().minus(Duration.ofDays(3))));
        repo.save(new User("Bob",   "b@x.com", false, Instant.now().minus(Duration.ofDays(1))));
        repo.save(new User("Carol", "c@x.com", true,  Instant.now().minus(Duration.ofDays(10))));

        List<User> active = repo.findActiveUsersSince(cutoff);

        assertThat(active)
            .hasSize(1)
            .extracting(User::name)
            .containsExactly("Alice");
    }
}
```

### Spring Test Slice Summary  [community]

| Slice Annotation | What it starts | What to mock | When to use |
|---|---|---|---|
| `@WebMvcTest` | MVC layer (controllers, filters, security) | `@MockBean` for services/repos | Test request mapping, validation, serialization, error handlers |
| `@DataJpaTest` | JPA + Hibernate + DataSource | n/a (use embedded DB or Testcontainers) | Test JPQL/native queries, entity mapping, repo methods |
| `@DataMongoTest` | Spring Data MongoDB | n/a (Testcontainers MongoDB) | Test MongoDB document mapping and repository queries |
| `@RestClientTest` | Spring `RestTemplate`/`RestClient` + `MockRestServiceServer` | `@MockBean` (rarely needed) | Test HTTP client code + `MessageConverter` config |
| `@JsonTest` | Jackson `ObjectMapper` only | n/a | Test `@JsonSerialize`/`@JsonDeserialize` custom converters |
| `@SpringBootTest` | Full context | `@MockBean` sparingly | End-to-end wiring; only when slices can't cover the scenario |

**Best practices for slice tests:**  [community]
- Prefer `@WebMvcTest` + `@MockBean` over `@SpringBootTest` with `@AutoConfigureMockMvc` — the slice is 5–10× faster.
- Use `@DataJpaTest` + `Replace.NONE` + Testcontainers for repository tests — H2 dialect differences produce false passes.
- One test class per controller or repository; if a test class grows beyond 10 methods, it's testing too much.
- Set `spring.jpa.properties.hibernate.enable_lazy_load_no_trans=false` in `test/resources/application-test.properties` to surface lazy loading bugs during `@DataJpaTest` runs before they hit production.

---

## JUnit 5.11–5.13 — Recent Testing Additions

### @FieldSource — Field-Backed Parameterized Tests (JUnit 5.11)

`@FieldSource` feeds parameterized test arguments from a field (static or instance) instead of a method or inline literal. It follows the same rules as `@MethodSource` but is simpler when the argument set is a plain collection that doesn't need transformation logic.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.FieldSource;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class EmailValidatorTest {

    // Static field — single type: each element is a single argument
    static final List<String> VALID_EMAILS = List.of(
        "alice@example.com",
        "bob+tag@company.org",
        "carol.smith@subdomain.example.com"
    );

    static final List<String> INVALID_EMAILS = List.of(
        "missing-at-sign",
        "@no-local-part.com",
        "no-domain@"
    );

    @ParameterizedTest(name = "''{0}'' should be valid")
    @FieldSource("VALID_EMAILS")
    void acceptsValidEmails(String email) {
        assertThat(EmailValidator.isValid(email)).isTrue();
    }

    @ParameterizedTest(name = "''{0}'' should be rejected")
    @FieldSource("INVALID_EMAILS")
    void rejectsInvalidEmails(String email) {
        assertThat(EmailValidator.isValid(email)).isFalse();
    }

    // External field reference: fully-qualified field name from another class
    @ParameterizedTest
    @FieldSource("com.example.TestData#EDGE_CASE_INPUTS")
    void handlesEdgeCases(String input) {
        assertThat(() -> EmailValidator.isValid(input)).doesNotThrowAnyException();
    }
}
```

**When to use `@FieldSource` vs `@MethodSource`:** Use `@FieldSource` when the argument data is a static list or set with no transformation needed. Use `@MethodSource` when arguments require computation, transformation, or streaming.

### @AutoClose — Automatic Resource Cleanup in Tests (JUnit 5.11)

`@AutoClose` on a test field causes JUnit to call `close()` (or any other configured method) on the resource after the test completes — without requiring a `try-with-resources` block or manual `@AfterEach`. Works on any `AutoCloseable`.

```java
import org.junit.jupiter.api.AutoClose;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class DatabaseConnectionTest {

    // @AutoClose calls close() after each test (or after the class if static)
    @AutoClose
    private final DatabaseConnection conn = DatabaseConnection.openTestConnection();

    // Static @AutoClose field: closed after all tests in the class complete
    @AutoClose
    private static final WireMockServer wireMock = new WireMockServer(8089);

    @Test
    void queryUsers_returnsNonEmptyResult() {
        var results = conn.query("SELECT * FROM users LIMIT 10");
        assertThat(results).isNotEmpty();
    }

    @Test
    void connectionIsOpen_beforeClose() {
        assertThat(conn.isOpen()).isTrue();
        // No manual close() call needed — @AutoClose handles it after this test
    }
}

// Custom close method: @AutoClose("shutdown") calls shutdown() instead of close()
class ServerTest {
    @AutoClose("shutdown")
    private final EmbeddedServer server = EmbeddedServer.start(8080);

    @Test
    void healthCheck_returns200() {
        // server.shutdown() is called after this test completes
    }
}
```

**Gotcha:** `@AutoClose` fields must be non-null before any test runs. If a field is lazily initialized and stays null, JUnit skips the close call (no NPE). For `static` fields, `close()` is invoked once after all tests in the class complete — equivalent to `@AfterAll`.

### Repeatable Source Annotations and `argumentSet()` (JUnit 5.11)

In JUnit 5.11, `@…Source` annotations became **repeatable**, allowing multiple sources to feed a single `@ParameterizedTest`. The new `argumentSet(name, args...)` factory method gives each row a human-readable name without embedding it in the CSV value.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import java.util.stream.Stream;
import static org.junit.jupiter.params.provider.Arguments.argumentSet;

class ShippingCalculatorTest {

    // Multiple @MethodSource annotations on the same test (JUnit 5.11+)
    @ParameterizedTest(name = "{0}")
    @MethodSource("standardShipments")
    @MethodSource("expressShipments")       // second source feeds into the same test
    void calculatesCorrectRate(String label, double weightKg, double expected) {
        assertThat(ShippingCalculator.rate(weightKg)).isEqualTo(expected, within(0.01));
    }

    static Stream<Arguments> standardShipments() {
        return Stream.of(
            argumentSet("light parcel (0.5 kg)", 0.5, 3.50),   // named row
            argumentSet("medium parcel (2 kg)",  2.0, 5.00),
            argumentSet("heavy parcel (10 kg)", 10.0, 12.00)
        );
    }

    static Stream<Arguments> expressShipments() {
        return Stream.of(
            argumentSet("express light (0.5 kg)", 0.5, 7.00),   // express premium
            argumentSet("express heavy (10 kg)", 10.0, 20.00)
        );
    }
}
```

### @EnumSource Range Selection (JUnit 5.12)

JUnit 5.12 added `from` and `to` attributes to `@EnumSource`, enabling selection of a contiguous range of enum constants without listing each one individually or using a regex `names` pattern.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

enum Priority { LOW, MEDIUM, HIGH, CRITICAL, EMERGENCY }

class AlertRoutingTest {

    // Select a contiguous range by enum declaration order
    @ParameterizedTest(name = "{0} triggers standard alert")
    @EnumSource(value = Priority.class, from = "LOW", to = "HIGH")  // LOW, MEDIUM, HIGH
    void standardPriorities_routeToStandardQueue(Priority priority) {
        assertThat(AlertRouter.queueFor(priority)).isEqualTo("standard");
    }

    @ParameterizedTest(name = "{0} triggers escalation")
    @EnumSource(value = Priority.class, from = "CRITICAL")          // CRITICAL, EMERGENCY
    void highPriorities_routeToEscalationQueue(Priority priority) {
        assertThat(AlertRouter.queueFor(priority)).isEqualTo("escalation");
    }
}
```

### @ParameterizedClass — Class-Level Parameterization (JUnit 5.13)

`@ParameterizedClass` (JUnit 5.13, May 2025) extends the parameterization concept from individual methods to entire test classes. Each argument set creates a new invocation of the entire class — all `@Test`, `@BeforeEach`, and `@AfterEach` methods run for each argument. This is the right tool when many tests share a common parameterized setup (e.g., the same test suite run against multiple database engines or API versions).

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedClass;
import org.junit.jupiter.params.provider.ValueSource;
import static org.assertj.core.api.Assertions.assertThat;

// Entire class is instantiated once per argument
// All @Test methods in this class run for each value
@ParameterizedClass
@ValueSource(strings = {"postgres", "mysql", "h2"})
class DatabaseAdapterCompatibilityTest {

    private final String dialect;
    private final DatabaseAdapter adapter;

    // Constructor receives the parameterized argument
    DatabaseAdapterCompatibilityTest(String dialect) {
        this.dialect = dialect;
        this.adapter = DatabaseAdapter.forDialect(dialect);
    }

    @Test
    void insert_thenFindById_roundTripsCorrectly() {
        var id = adapter.insert(new Record("key", "value"));
        assertThat(adapter.findById(id)).isPresent()
            .hasValueSatisfying(r -> assertThat(r.value()).isEqualTo("value"));
    }

    @Test
    void batchInsert_respectsTransactionBoundary() {
        assertThatCode(() -> adapter.batchInsert(generateRecords(100)))
            .doesNotThrowAnyException();
    }

    // @BeforeParameterizedClassInvocation runs before all tests for one argument
    // @AfterParameterizedClassInvocation runs after all tests for one argument
}
```

**When to use `@ParameterizedClass` vs `@ParameterizedTest`:** Use `@ParameterizedClass` when multiple test methods share the same parameterized context (e.g., all tests in a database compatibility suite need the same dialect). Use `@ParameterizedTest` when only one method has varied inputs.

---

## Spring Boot @ServiceConnection — Modern Testcontainers Wiring (Spring Boot 3.1+)

`@ServiceConnection` (Spring Boot 3.1+) eliminates the boilerplate `@DynamicPropertySource` configuration block when wiring Testcontainers into `@SpringBootTest`. Spring Boot automatically reads the connection details from the container and configures the corresponding Spring Boot auto-configuration (DataSource, RedisConnectionFactory, KafkaTemplate, etc.) to point at the container's dynamic port.

```java
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
class OrderIntegrationTest {

    // @ServiceConnection wires datasource URL/user/password automatically
    // No @DynamicPropertySource block needed
    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    // Works for Redis, Kafka, MongoDB, RabbitMQ, and many more (Spring Boot 3.1+)
    @Container
    @ServiceConnection
    static final KafkaContainer kafka =
        new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.6.0"));

    @Autowired
    OrderRepository orderRepo;

    @Autowired
    KafkaTemplate<String, Object> kafkaTemplate;

    @Test
    void placeOrder_persistsAndPublishesEvent() {
        var order = orderRepo.save(new Order("user-1", List.of("SKU-001")));
        assertThat(order.id()).isNotNull();

        kafkaTemplate.send("orders.placed", order.id().toString(), order);
        // Awaitility assertion on consumer...
    }
}

// ------ OLD approach (still works, but verbose) ------
@SpringBootTest
@Testcontainers
class OldStyleTest {

    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    // @DynamicPropertySource required when @ServiceConnection is not available
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",      postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

**Supported containers out of the box (Spring Boot 3.4):** PostgreSQL, MySQL, MariaDB, MongoDB, Redis, RabbitMQ, Kafka, Cassandra, Couchbase, Elasticsearch, Neo4j, Grafana LGTM. For any container not natively supported, `@DynamicPropertySource` remains the fallback.

**Gotcha — `@DataJpaTest` + `@ServiceConnection`:** When using `@DataJpaTest`, add `@AutoConfigureTestDatabase(replace = Replace.NONE)` alongside `@ServiceConnection` — otherwise Spring Boot replaces the container datasource with an embedded H2.

---

## Spring Framework 6.2 — @MockitoBean and @MockitoSpyBean

Spring Framework 6.2 (Spring Boot 3.4+) introduced `@MockitoBean` and `@MockitoSpyBean` as first-class replacements for Spring Boot's `@MockBean` and `@SpyBean`. The new annotations live in `org.springframework.test.context.bean.override.mockito` and are part of the core Spring TestContext Framework rather than the Boot test module.

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    MockMvcTester mvc;    // AssertJ-based MockMvc wrapper (Spring Boot 3.4 / Spring MVC 7)

    @MockitoBean             // replaces UserService bean in the context with a Mockito mock
    UserService userService;

    @MockitoSpyBean          // wraps the real AuditService with a spy — real methods called by default
    AuditService auditService;

    @Test
    void getUser_existingId_returns200() {
        given(userService.findById(1L))
            .willReturn(new UserDto(1L, "Alice", "alice@example.com"));

        // MockMvcTester: fluent AssertJ-based API (no Hamcrest matchers needed)
        assertThat(mvc.get().uri("/users/1"))
            .hasStatusOk()
            .bodyJson()
            .extractingPath("$.name").isEqualTo("Alice");
    }

    @Test
    void getUser_triggersAuditLog() {
        given(userService.findById(42L))
            .willReturn(new UserDto(42L, "Bob", "bob@example.com"));

        mvc.get().uri("/users/42").exchange();

        // MockitoSpyBean: verify real audit service was called with correct args
        verify(auditService).log("user.read", 42L);
    }
}
```

**`@MockitoBean` vs `@MockBean` differences:**

| Feature | `@MockBean` (Boot) | `@MockitoBean` (Spring 6.2) |
|---|---|---|
| Package | `org.springframework.boot.test.mock.mockito` | `org.springframework.test.context.bean.override.mockito` |
| Requires Spring Boot | Yes | No — works with plain Spring Framework |
| Context reset strategy | Resets context if beans differ between tests | Supports `REPLACE_OR_CREATE` and `WRAP` strategies explicitly |
| Deprecation | Not deprecated, but `@MockitoBean` is preferred in Spring 6.2+ | New canonical API |
| Usage in non-Boot tests | Limited | Full support in `@SpringJUnitConfig` tests |

**Migration:** In Spring Boot 3.4+ projects, prefer `@MockitoBean` over `@MockBean` for new test code. Existing `@MockBean` tests continue to work — no forced migration.

---

## MockMvcTester — AssertJ-Native MockMvc API (Spring Boot 3.4 / Spring Framework 7)

`MockMvcTester` wraps `MockMvc` with an AssertJ-based fluent API, replacing Hamcrest matchers with chainable AssertJ assertions. It's auto-configured by `@WebMvcTest` when AssertJ is on the classpath, and can be injected directly as a `@Autowired` field.

```java
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import static org.assertj.core.api.Assertions.assertThat;

@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    MockMvcTester mvc;    // auto-configured; no setup needed

    @MockitoBean
    OrderService orderService;

    @Test
    void createOrder_validRequest_returns201() {
        given(orderService.place(any())).willReturn(new OrderDto("ORD-1", "PLACED"));

        assertThat(
            mvc.post().uri("/orders")
               .contentType(MediaType.APPLICATION_JSON)
               .content("""
                   {"productId": "P-123", "quantity": 2}
                   """)
        )
            .hasStatus(HttpStatus.CREATED)
            .bodyJson()
            .extractingPath("$.orderId").isEqualTo("ORD-1");
    }

    @Test
    void createOrder_invalidRequest_returns400WithValidationErrors() {
        assertThat(
            mvc.post().uri("/orders")
               .contentType(MediaType.APPLICATION_JSON)
               .content("""{"quantity": -1}""")  // missing productId, negative quantity
        )
            .hasStatus(HttpStatus.BAD_REQUEST)
            .bodyJson()
            .extractingPath("$.errors").asArray().hasSizeGreaterThan(0);
    }

    @Test
    void getOrder_notFound_returns404() {
        given(orderService.findById("MISSING")).willThrow(new OrderNotFoundException("MISSING"));

        assertThat(mvc.get().uri("/orders/MISSING"))
            .hasStatus(HttpStatus.NOT_FOUND)
            .bodyJson()
            .extractingPath("$.message").asString().contains("MISSING");
    }

    // Extract to a POJO for multi-field assertions
    @Test
    void getOrder_existingId_returnsFullDto() {
        given(orderService.findById("ORD-1"))
            .willReturn(new OrderDto("ORD-1", "PLACED"));

        MvcTestResult result = mvc.get().uri("/orders/ORD-1").exchange();

        assertThat(result).hasStatusOk();
        OrderDto dto = result.getResponse().getContentAs(OrderDto.class);
        assertThat(dto.orderId()).isEqualTo("ORD-1");
        assertThat(dto.status()).isEqualTo("PLACED");
    }
}
```

**MockMvcTester vs Classic MockMvc:**

```java
// OLD — MockMvc with Hamcrest matchers
mockMvc.perform(get("/users/1").accept(MediaType.APPLICATION_JSON))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.name", equalTo("Alice")))
    .andExpect(jsonPath("$.email", endsWith("@example.com")));

// NEW — MockMvcTester with AssertJ
assertThat(mvc.get().uri("/users/1").accept(MediaType.APPLICATION_JSON))
    .hasStatusOk()
    .bodyJson()
    .extractingPath("$.name").isEqualTo("Alice");
```

**Why prefer MockMvcTester:** Consistent AssertJ API across unit tests and integration tests; richer failure messages (shows actual vs expected JSON path); `hasStatus(HttpStatus.X)` is more readable than `status().isXxx()`; AssertJ's `.satisfies()`, `.asArray()`, `.asString()` chaining works naturally on extracted JSON values.

---

## Mockito 5.x — Notable Testing Improvements

### Auto-Detection in `mockStatic` and `mockConstruction` (Mockito 5.21)

Mockito 5.21 added automatic class detection for `mockStatic` and `mockConstruction`, reducing the redundant type specification in `try` blocks.

```java
import org.mockito.MockedStatic;
import org.mockito.MockedConstruction;
import static org.mockito.Mockito.*;

// Before 5.21 — type must be specified twice
try (MockedStatic<LocalDate> mockedDate = mockStatic(LocalDate.class)) {
    mockedDate.when(LocalDate::now).thenReturn(LocalDate.of(2025, 5, 1));
    // ...
}

// 5.21+ — withSettings().defaultAnswer() example; auto-detection infers the type
// (auto-detection is most useful in construction mocking where generic inference works)
try (MockedConstruction<EmailSender> mocked = mockConstruction(
         EmailSender.class,                                   // type specified once
         (mock, context) -> when(mock.send(any())).thenReturn(true)
     )) {
    var service = new NotificationService();  // EmailSender constructed inside
    service.notify("alice@example.com", "Hello");
    verify(mocked.constructed().get(0)).send("alice@example.com");
}
```

### STRICT_STUBS with Inline Mock Maker — Gotcha [community]

Mockito 5.x ships with the **inline mock maker** as default on Java 21+, enabling mocking of `final` classes and `static` methods without additional configuration. However, combining `STRICT_STUBS` with inline mocks can trigger unexpected "unnecessary stubbing" failures when a stubbed method is called inside a `verify()` check. The fix: scope `STRICT_STUBS` checks carefully — avoid re-stubbing inside assertion helpers.

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.STRICT_STUBS)
class FinalClassMockTest {

    @Mock
    SealedOrFinalService service;  // Mockito 5.x can mock final/sealed classes without config

    @Test
    void mocksFinalClass_withStrictStubs() {
        // Stub is used exactly once — STRICT_STUBS happy
        when(service.compute(42)).thenReturn("result");
        assertThat(service.compute(42)).isEqualTo("result");
    }

    // BAD — STRICT_STUBS flags 'when(service.compute(99))' as unnecessary
    // if service.compute(99) is never actually called by the code under test
    @Test
    void unnecessaryStub_failsWithStrictStubs() {
        when(service.compute(99)).thenReturn("never used");  // UnnecessaryStubbingException!
        // Fix: remove the stub, or use lenient() for stubs that are conditionally needed
        lenient().when(service.compute(99)).thenReturn("never used");  // no strict check
    }
}
```

---

## Stable Values (Java 25 preview — JEP 502)

`StableValue` provides lazily-initialized final fields without the complexity and pitfalls of double-checked locking or `volatile`. A stable value is computed once on first access and then frozen — the JVM can apply the same optimizations (inlining, constant folding) as for `static final` fields.

```java
import java.lang.invoke.StableValue;

public class ConfigService {

    // Stable value: initialized lazily on first access; effectively final after that
    private final StableValue<DatabaseConfig> dbConfig =
        StableValue.of(() -> DatabaseConfig.load());  // supplier called at most once

    private final StableValue<List<String>> allowedOrigins =
        StableValue.of(() -> fetchAllowedOriginsFromDb());

    public DatabaseConfig getDbConfig() {
        return dbConfig.get();   // initialized on first call; cached thereafter
    }

    public boolean isOriginAllowed(String origin) {
        return allowedOrigins.get().contains(origin);
    }
}

// Replaces double-checked locking — the old pattern
public class OldConfigService {
    // BAD — complex, error-prone, requires volatile
    private volatile DatabaseConfig dbConfig;

    public DatabaseConfig getDbConfig() {
        if (dbConfig == null) {
            synchronized (this) {
                if (dbConfig == null) {                // second check inside lock
                    dbConfig = DatabaseConfig.load();  // initialization under lock
                }
            }
        }
        return dbConfig;
    }
}

// StableValue for Map of lazily-computed entries (JEP 502)
// The JVM can treat stable values as constants for JIT inlining purposes
Map<String, StableValue<HeavyResource>> resources = new HashMap<>();

StableValue<HeavyResource> resource = StableValue.of(() -> loadHeavyResource("key1"));
resources.put("key1", resource);

// Later — loads only once, regardless of concurrent access
HeavyResource r = resources.get("key1").get();
```

**Why StableValue over other lazy patterns:**
- `static final` fields: initialized at class load time — not lazy.
- `Supplier` + `volatile` + double-checked locking: correct but complex; error-prone to write; not JIT-friendly.
- `Holder class idiom` (`private static class Holder { static final X = init(); }`): lazy but only works for static fields; no instance-scoped laziness.
- `StableValue`: lazy, instance-scoped, concurrency-safe, JIT-friendly (JVM can inline after first initialization), no boilerplate.

**Note:** `StableValue` is a preview feature in Java 25. Enable with `--enable-preview` and `--source 25`. The API may change before standardization. Track [JEP 502](https://openjdk.org/jeps/502) for final API details.

---

### Thread.Builder API — Explicit Virtual and Platform Thread Creation (Java 21+)
`Thread.ofVirtual()` and `Thread.ofPlatform()` return a `Thread.Builder` that replaces the verbose `new Thread(...)` constructor pattern. They give fine-grained control over name prefix, daemon flag, stack size, and uncaught-exception handler before starting, and they support both one-off threads and `ThreadFactory` instances for use with `ExecutorService`.

```java
import java.lang.Thread;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// Explicit virtual thread with name and uncaught-exception handler
Thread vt = Thread.ofVirtual()
    .name("order-processor-", 0)            // name prefix + auto-incrementing suffix
    .uncaughtExceptionHandler((t, ex) ->
        System.err.println(t.getName() + " failed: " + ex.getMessage()))
    .unstarted(() -> processOrders());       // returns Thread, not yet running
vt.start();

// Platform thread with custom stack size
Thread platform = Thread.ofPlatform()
    .name("batch-writer")
    .daemon(true)
    .stackSize(512 * 1024)                  // 512 KB stack — reduce for many threads
    .unstarted(this::writeBatch);
platform.start();

// ThreadFactory for use with ExecutorService.newThreadPerTaskExecutor()
import java.util.concurrent.ThreadFactory;

ThreadFactory virtualFactory = Thread.ofVirtual()
    .name("req-", 0)
    .factory();   // returns a ThreadFactory that creates named virtual threads

ExecutorService executor = Executors.newThreadPerTaskExecutor(virtualFactory);
// Each submitted task runs on a virtual thread named req-0, req-1, req-2, ...
executor.submit(() -> handleRequest(request));
```

**Why prefer `Thread.Builder` over `new Thread(...)`:**
- Constructor-chained configuration is clearer than a seven-parameter constructor.
- `name(prefix, start)` automatically generates sequential names (req-0, req-1, …) without a counter variable.
- `factory()` produces a `ThreadFactory` compatible with all `ExecutorService` APIs that accept one.
- `unstarted()` creates the thread without starting it — useful when you need the thread reference before the task begins.

---

### StructuredTaskScope.Joiner — Custom Join Policies (Java 25 preview — JEP 505)
Java 25 updated Structured Concurrency (JEP 505) to add `StructuredTaskScope.Joiner<T, R>`, a functional interface that encapsulates the join policy of a scope. The previous `ShutdownOnFailure` / `ShutdownOnSuccess` classes are now built on top of `Joiner`. This enables custom aggregation policies — for example, collecting all successes while ignoring failures — without subclassing `StructuredTaskScope`.

```java
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Subtask;
import java.util.concurrent.StructuredTaskScope.Joiner;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

// Built-in joiners — recommended for most use cases
public OrderDetails buildOrderDetails(long orderId) throws Exception {

    // ShutdownOnFailure: cancel all if any subtask fails (most common)
    try (var scope = StructuredTaskScope.open(Joiner.awaitAllSuccessfulOrThrow())) {
        Subtask<User>      user      = scope.fork(() -> userService.findById(orderId));
        Subtask<Inventory> inventory = scope.fork(() -> inventoryService.check(orderId));
        scope.join();   // waits for all; throwIfFailed() not needed — awaitAllSuccessfulOrThrow does it

        return new OrderDetails(user.get(), inventory.get());
    }
}

// Custom Joiner: collect all successful results, log failures
public List<String> fetchAllAvailable(List<String> urls) throws Exception {
    List<String> successes = new java.util.concurrent.CopyOnWriteArrayList<>();

    try (var scope = StructuredTaskScope.open(
        Joiner.<String, Void>custom(
            (subtask, state) -> {
                if (subtask.state() == Subtask.State.SUCCESS) {
                    successes.add(subtask.get());
                }
                // returning null means "continue; don't short-circuit the scope"
                return null;
            },
            () -> null   // finisher: returns Void — all subtasks ran to completion
        )
    )) {
        urls.forEach(url -> scope.fork(() -> httpClient.fetch(url)));
        scope.join();   // all subtasks finish; failures are collected not thrown
        return List.copyOf(successes);
    }
}
```

**When to use custom `Joiner`:**
- You need partial results (collect successes, discard/log failures) rather than fail-fast.
- You need a custom short-circuit policy (e.g., stop after 3 successes out of N attempts).
- Built-in `awaitAllSuccessfulOrThrow()` (fail-fast) and `anySuccessfulResultOrThrow()` (first-success) cover 80% of use cases — reach for a custom `Joiner` only when neither fits.

---

### HikariCP — Production Connection Pool Configuration
HikariCP is the standard JDBC connection pool for Java applications. Default configuration is functional but suboptimal for production; the most impactful settings are `maximumPoolSize`, `minimumIdle`, `connectionTimeout`, and `keepaliveTime`. Misconfigured pools are a leading cause of production database outages.

```java
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

HikariConfig config = new HikariConfig();

// ── Connection identity ──────────────────────────────────────────────────────
config.setJdbcUrl("jdbc:postgresql://db-host:5432/myapp");
config.setUsername(System.getenv("DB_USER"));
config.setPassword(System.getenv("DB_PASS"));
config.setDriverClassName("org.postgresql.Driver");

// ── Pool sizing ──────────────────────────────────────────────────────────────
// Rule of thumb: maximumPoolSize = Tn × (Cm / Cn) + 1
// Tn = number of threads, Cm = response time with connection, Cn = wait for connection
// For a typical web service: cores × 2 + 1 (empirical starting point)
config.setMaximumPoolSize(10);
config.setMinimumIdle(5);              // keep 5 connections warm; avoids cold-start latency

// ── Timeouts ─────────────────────────────────────────────────────────────────
config.setConnectionTimeout(30_000);  // max ms to wait for a connection from pool (30s)
config.setIdleTimeout(600_000);       // max ms a connection can sit idle before eviction (10m)
config.setMaxLifetime(1_800_000);     // max connection lifetime (30m); must be < DB timeout
config.setKeepaliveTime(30_000);      // send keepalive query every 30s to prevent stale connections

// ── Connection validation ────────────────────────────────────────────────────
config.setConnectionTestQuery("SELECT 1");           // only needed if JDBC4 isValid() unavailable
config.setValidationTimeout(5_000);

// ── Pool name (appears in metrics, JMX, and log output) ─────────────────────
config.setPoolName("orders-db-pool");

// ── Performance options ──────────────────────────────────────────────────────
config.addDataSourceProperty("cachePrepStmts",          "true");   // cache prepared statements
config.addDataSourceProperty("prepStmtCacheSize",       "250");
config.addDataSourceProperty("prepStmtCacheSqlLimit",   "2048");
config.addDataSourceProperty("useServerPrepStmts",      "true");   // PostgreSQL

// ── Metrics integration (Micrometer) ─────────────────────────────────────────
// config.setMetricRegistry(meterRegistry);   // enables hikaricp.* in Actuator/Prometheus

HikariDataSource dataSource = new HikariDataSource(config);
```

**Key HikariCP gotchas [community]:**
1. **`maxLifetime` must be less than the database's `wait_timeout`** — if the DB closes an idle connection but HikariCP still has it in the pool, the next borrow throws `Connection is closed`. Set `maxLifetime` to 25–30 seconds less than the DB wait timeout.
2. **`connectionTimeout` is not a socket timeout** — it is the maximum wait for a free connection *from the pool*. Set the JDBC driver's `socketTimeout` separately for network-level timeout protection.
3. **Never set `minimumIdle = 0` in production** — the pool will empty under low traffic and then spike latency when traffic returns because new connections take 50–200 ms to establish.
4. **Pool size ≠ thread count** — a pool of 100 rarely outperforms a pool of 10 if the database can only handle 10 concurrent connections efficiently. Use connection pool metrics (HikariCP `pending` gauge) to right-size.

---

### Spring `@Async` Self-Invocation Bypass — Same Proxy Problem as `@Transactional` [community]
Spring `@Async` has the same AOP proxy limitation as `@Transactional`: calling an `@Async` method from within the same bean executes it **synchronously** because the call never goes through the Spring proxy. The method runs in the calling thread, not the task executor, which can cause UI-blocking, deadlocks, or missing thread-context propagation (security, MDC logging, request scope).

```java
// BAD — @Async method called internally; runs on calling thread, not async executor
@Service
public class ReportService {

    public void generateDailyReports() {
        for (String tenant : tenants) {
            this.generateReport(tenant);    // "this" call bypasses proxy — NOT async!
        }
    }

    @Async("reportExecutor")
    public CompletableFuture<Void> generateReport(String tenantId) {
        // Expected to run in 'reportExecutor' thread pool — but doesn't when self-invoked
        reportEngine.build(tenantId);
        return CompletableFuture.completedFuture(null);
    }
}

// GOOD — extract @Async method to a separate Spring-managed bean
@Service
public class AsyncReportRunner {
    @Async("reportExecutor")
    public CompletableFuture<Void> run(String tenantId) {
        reportEngine.build(tenantId);
        return CompletableFuture.completedFuture(null);
    }
}

@Service
public class ReportService {
    private final AsyncReportRunner runner;   // injected — call goes through proxy

    public void generateDailyReports() {
        tenants.forEach(tenant -> runner.run(tenant));   // proxied → actually async
    }
}
```

**Three additional `@Async` pitfalls [community]:**
1. **`void` return type on `@Async` swallows exceptions** — `void` async methods have no `CompletableFuture` to attach a handler to. Use `CompletableFuture<Void>` and always attach `.exceptionally(...)` or use an `AsyncUncaughtExceptionHandler`.
2. **Missing `@EnableAsync` on the configuration class** — `@Async` annotations compile and deploy fine but execute synchronously until `@EnableAsync` is on a `@Configuration` class. This is invisible in unit tests where the real Spring context isn't loaded.
3. **MDC logging context is lost in async threads** — the async executor thread doesn't inherit the calling thread's SLF4J MDC (trace ID, user ID). Use `MDC.getCopyOfContextMap()` before the async call and restore it at the start of the `@Async` method, or configure a `TaskDecorator` on the executor.

```java
// GOOD — TaskDecorator propagates MDC to async threads
@Bean(name = "reportExecutor")
public Executor reportExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(4);
    executor.setMaxPoolSize(8);
    executor.setQueueCapacity(100);
    executor.setTaskDecorator(runnable -> {
        Map<String, String> contextMap = MDC.getCopyOfContextMap();    // capture on caller thread
        return () -> {
            try {
                if (contextMap != null) MDC.setContextMap(contextMap); // restore on async thread
                runnable.run();
            } finally {
                MDC.clear();   // clean up to avoid thread-pool contamination
            }
        };
    });
    executor.initialize();
    return executor;
}
```
**WHY:** Without a `TaskDecorator`, every log line emitted from an `@Async` method is missing the trace ID or correlation ID from the originating request — making distributed tracing impossible in production. This is the most common silent failure when teams first add `@Async` to an existing service.

---

### Hibernate Second-Level Cache — When Not to Enable It [community]
Hibernate's second-level cache (2LC) stores entity data in a shared cache (Ehcache, Infinispan, Caffeine) across sessions. It reduces database reads for frequently-accessed, rarely-changed entities. However, enabling it naively on entities that are frequently written causes stale reads, cache stampedes, and consistency bugs that are harder to debug than the original N+1 query problem.

```java
// APPROPRIATE — 2LC on read-mostly, rarely changed entities
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_ONLY)  // safest strategy; entity never modified
@Table(name = "countries")
public class Country {
    @Id Long id;
    String name;
    String isoCode;
    // Never updated after initial data load
}

// APPROPRIATE — READ_WRITE for entities updated infrequently
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_WRITE)  // soft-lock on update; consistent
@Table(name = "product_catalog")
public class Product {
    @Id Long id;
    String name;
    BigDecimal price;  // changes perhaps daily, not every second
}

// BAD — 2LC on a high-write entity causes stale reads and cache invalidation storm
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_WRITE)  // too noisy; invalidation on every tx
@Table(name = "order_events")  // INSERT-heavy; never read by ID in a cached pattern
public class OrderEvent { ... }

// CHECK cache effectiveness — enable Hibernate statistics in dev
SessionFactory sf = emf.unwrap(SessionFactory.class);
sf.getStatistics().setStatisticsEnabled(true);
// After test suite:
// getStatistics().getSecondLevelCacheHitCount() should be >> miss count
// If hit rate < 50%, the cache is hurting more than helping (invalidation overhead)
```

**When second-level cache makes sense [community]:**
- Entities are read far more often than they are written (ratio > 10:1).
- Entity size is small (< 10 KB) — large blobs waste cache memory.
- Cache TTL tolerance: stale data for a few seconds is acceptable.
- Entity is looked up by primary key (`findById`) — not by complex JPQL queries (query cache is separate and riskier).

**When NOT to use 2LC:**
- High-write entities (order status, inventory counts, event logs) — every write invalidates every cached copy.
- Multi-node deployments without a distributed cache (Infinispan, Redis) — each node has a stale local copy after another node writes.
- Entities with frequently-changed associations — Hibernate invalidates parent cache when a collection member changes.

---

## Additional Anti-Patterns Quick Reference

| Anti-Pattern | Why it's harmful | What to do instead |
|---|---|---|
| `new Thread(...)` constructor | No name, stack size, or uncaught-exception control; hard to trace in thread dumps | Use `Thread.ofVirtual().name(...).unstarted(...)` or `Thread.ofPlatform()` builder |
| `@Async` self-invocation | Same proxy bypass as `@Transactional`; method runs synchronously without warning | Extract `@Async` method to a separate Spring-managed bean |
| `@Async` with `void` return type | Exceptions are silently swallowed; no way to attach error handler | Return `CompletableFuture<Void>`; attach `exceptionally()` handler |
| Missing MDC propagation in `@Async` executor | Trace ID and correlation ID lost in async threads; distributed tracing breaks | Configure a `TaskDecorator` that copies MDC to the async thread |
| Hibernate 2LC on write-heavy entities | Cache invalidation on every write adds overhead; stale reads under load | Enable 2LC only for read-mostly entities (`READ_ONLY` or `READ_WRITE` with hit rate > 50%) |
| HikariCP `maxLifetime` >= DB `wait_timeout` | DB closes connection while pool still holds it; next borrow throws `Connection is closed` | Set `maxLifetime` ≥ 30s less than DB wait timeout |
| HikariCP `minimumIdle = 0` in production | Pool empties at low traffic; reconnects on spike add 50–200 ms latency | Keep `minimumIdle` ≥ 2–5 to maintain warm connections |
| `StructuredTaskScope` without `Joiner` custom policy | `ShutdownOnFailure` cancels all on first error; may not fit partial-success use cases | Use `Joiner.custom(...)` to collect all successes and log failures independently |
| `@DynamicPropertySource` for Testcontainers wiring | Verbose; four lines per container; easy to get URL/user/password mapping wrong | Use `@ServiceConnection` (Spring Boot 3.1+) — auto-wires datasource/Redis/Kafka from container |
| `@MockBean` in new Spring Boot 3.4+ test code | Lives in Boot module only; `@MockitoBean` (Spring 6.2) is now the canonical API with better strategy control | Prefer `@MockitoBean` and `@MockitoSpyBean` from `org.springframework.test.context.bean.override.mockito` |
| `MockMvc` with Hamcrest matchers | Verbose; Hamcrest failure messages lack context; mixes two assertion libraries in one test | Use `MockMvcTester` with AssertJ assertions (auto-configured by `@WebMvcTest` in Spring Boot 3.4+) |
| `@ParameterizedTest` on every method in a class that shares the same setup | Each method needs its own source annotation; setup is duplicated | Use `@ParameterizedClass` (JUnit 5.13) to run the entire class with each argument set |
| Manual `close()` in `@AfterEach` for test resources | Verbose; easy to forget; hides intent | Use `@AutoClose` (JUnit 5.11) on the field — JUnit calls `close()` automatically after each test |
| Hardcoded Testcontainers module coordinates (pre-2.0) | `org.testcontainers:mysql` → artifact renamed; build breaks silently on upgrade | Use `org.testcontainers:testcontainers-mysql` (2.0+); check all module artifact IDs on upgrade |
| AssertJ `extracting(Function...)` assuming `List<Object>` | 3.27+ narrows to common supertype; code expecting `Object` may fail to compile | Use `.extracting(User::name)` for single field (returns `AbstractStringAssert`); cast only when truly needed |
| JUnit 5 test code compiled with Java < 17 targeting JUnit 6 | JUnit 6 requires Java 17 minimum; Java 8/11 tests cannot run | Keep JUnit 5.x for Java 8–16 projects; migrate to JUnit 6 only after Java 17 baseline is set |
| `@CsvSource` using `lineSeparator` attribute | JUnit 6 removed `lineSeparator` — auto-detection replaces it; breaks builds | Remove the attribute; JUnit 6 auto-detects line endings |

---

## Testcontainers 2.0 — Migration and Breaking Changes (October 2024)

Testcontainers 2.0 introduced several breaking changes that affect existing test suites. Most projects targeting Spring Boot 3.x should upgrade but must address the module coordinate renames before the build compiles.

### Module Artifact ID Renaming

All container module artifact IDs gained a `testcontainers-` prefix. Update Maven/Gradle dependencies:

```xml
<!-- BEFORE (Testcontainers 1.x) -->
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>postgresql</artifactId>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>mysql</artifactId>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>kafka</artifactId>
</dependency>

<!-- AFTER (Testcontainers 2.0+) -->
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>testcontainers-postgresql</artifactId>
  <version>2.0.0</version>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>testcontainers-mysql</artifactId>
  <version>2.0.0</version>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>testcontainers-kafka</artifactId>
  <version>2.0.0</version>
</dependency>
```

### Package Restructuring

Container classes moved to module-specific packages. Update imports:

```java
// BEFORE (Testcontainers 1.x)
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.containers.KafkaContainer;

// AFTER (Testcontainers 2.0+)
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.mysql.MySQLContainer;
import org.testcontainers.kafka.KafkaContainer;
```

### JUnit 4 Support Removed

Testcontainers 2.0 removed JUnit 4 support entirely. Any `@Rule`-based container management must migrate to JUnit 5 `@Container` + `@Testcontainers`:

```java
// BEFORE (JUnit 4 @Rule pattern — removed in Testcontainers 2.0)
@Rule
public PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

// AFTER — JUnit 5 with @Testcontainers extension (works in both 1.x and 2.x)
@Testcontainers
class MyTest {
    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");
}
```

### Default Constructor Changes

Container classes no longer provide a no-arg default constructor. Always specify an image:

```java
// BEFORE — no-arg constructor used the default image (removed in 2.0)
PostgreSQLContainer<?> db = new PostgreSQLContainer<>();  // compilation error in 2.0

// AFTER — always specify the image explicitly
PostgreSQLContainer<?> db = new PostgreSQLContainer<>("postgres:16-alpine");
```

**Gotcha — `@ServiceConnection` with Testcontainers 2.0 + Spring Boot 3.x:** `@ServiceConnection` fully supports 2.0 container classes. The package import change is the only adaptation required — the annotation behaviour is unchanged.

---

## AssertJ 3.27 — New Assertions (December 2024)

AssertJ 3.27 added several new assertion methods relevant to modern Java testing. The most commonly needed additions are the `actual()` escape hatch, CompletableFuture time-bounded assertions, and the `doesNotMatch(Predicate)` negative predicate check.

### `actual()` — Access the Subject Under Test

`actual()` returns the wrapped object directly from an assertion chain without terminating it, enabling you to pass the subject to a helper while staying in AssertJ's fluent style:

```java
import static org.assertj.core.api.Assertions.assertThat;

@Test
void usingActualToInspectSubject() {
    User user = new User("Alice", "alice@example.com", 30);

    assertThat(user)
        .isNotNull()
        .satisfies(u -> {
            // actual() provides the typed subject without breaking the chain
            User subject = assertThat(u).actual();  // returns User
            System.out.println("Testing user: " + subject.name());  // debugging
        });

    // More common use: extracting for further assertion
    assertThat(List.of("foo", "bar", "baz"))
        .filteredOn(s -> s.startsWith("b"))
        .actual()  // List<String> — the filtered result
        .forEach(s -> assertThat(s).hasSize(3));
}
```

### CompletableFuture Time-Bounded Assertions (3.27)

New assertions for testing async code with explicit timeout bounds — no Awaitility needed for simple cases:

```java
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import static org.assertj.core.api.Assertions.assertThat;

@Test
void completableFutureTimeBoundedAssertions() throws Exception {
    CompletableFuture<String> future = CompletableFuture
        .supplyAsync(() -> {
            // some computation
            return "result";
        });

    // Asserts completion within a timeout — fails if future doesn't complete in time
    assertThat(future)
        .succeedsWithin(Duration.ofSeconds(2))
        .isEqualTo("result");

    // isCompletedWithValueMatchingWithin (3.27) — verify value AND timing
    assertThat(CompletableFuture.completedFuture("hello"))
        .isCompletedWithValueMatching(s -> s.startsWith("hel"), "should start with hel");

    CompletableFuture<String> failingFuture =
        CompletableFuture.failedFuture(new RuntimeException("boom"));

    // Assert the future fails with a specific exception type within a timeout
    assertThat(failingFuture)
        .failsWithin(Duration.ofSeconds(1))
        .withThrowableOfType(RuntimeException.class)
        .withMessage("boom");
}
```

### `doesNotMatch(Predicate)` — Negative Predicate Testing (3.27)

Complements the existing `matches(Predicate)` with a clear negative form:

```java
import java.util.function.Predicate;
import static org.assertj.core.api.Assertions.assertThat;

@Test
void negativePredicateAssertion() {
    String username = "alice_123";

    // Before 3.27 — verbose: negate the predicate inline
    assertThat(username).matches(s -> !s.contains(" "), "should not contain spaces");

    // 3.27+ — explicit negative form; clearer intent in failure messages
    Predicate<String> containsSpaces = s -> s.contains(" ");
    assertThat(username).doesNotMatch(containsSpaces, "username should not contain spaces");

    // Useful in collection assertions too
    assertThat(List.of("alice", "bob", "carol"))
        .allSatisfy(name -> assertThat(name).doesNotMatch(
            s -> s.isBlank(), "name should not be blank"));
}
```

**Gotcha — `extracting(Function...)` type narrowing in 3.27:** `assertThat(list).extracting(fn1, fn2)` now returns the common supertype instead of `List<Object>`. If your test code was explicitly typed to `Object`, it may fail to compile. Fix: use `.extracting(fn).as(String.class)` or rely on the narrowed type.

---

## JUnit 6.0 — Migration Notes (2025)

JUnit 6.0 is the first major version bump since JUnit 5. Key changes affect build configuration, minimum Java version, and CSV parsing. Most JUnit 5.x test code compiles on JUnit 6 with only import changes and dependency updates.

### Breaking Changes Checklist

**Java 17 minimum.** JUnit 6 requires Java 17+. Projects on Java 8–16 must stay on JUnit 5.x.

**Module changes.** `junit-platform-runner` is removed; replace with the Launcher API or IDE/build-tool native integration. `junit-platform-jfr` is absorbed into `junit-platform-launcher`.

**`@MethodOrderer.Alphanumeric` removed.** Replace with `@MethodOrderer.Default` for ordering by method name, or `@TestMethodOrder(MethodOrderer.MethodName.class)`.

**`MethodOrderer.Alphanumeric` and `ClassOrderer.Alphanumeric` removed.** No direct replacement — use `MethodName` or a custom comparator.

**`ReflectionSupport.loadClass()` removed.** Use `ClassLoader.loadClass()` or `Class.forName()` directly.

**FastCSV replaces univocity-parsers for `@CsvSource`/`@CsvFileSource`.** Most CSV data works unchanged. The `lineSeparator` attribute is removed (auto-detection). Extra characters after closing quotes now throw a parse exception instead of silently passing.

**JSpecify nullability annotations.** All JUnit APIs now carry `@Nullable`/`@NonNull` annotations from the JSpecify project. Null safety violations that were previously silent become compile-time warnings with `-Xlint:null`.

### New Features Worth Adopting

**Kotlin suspend function support.** `@Test` methods can now use the `suspend` modifier directly — no coroutine bridge required for Kotlin coroutine tests.

**`ExtensionContext.Store.computeIfAbsent()`** replaces the deprecated `getOrComputeIfAbsent()`. The new method does not accept null return values, avoiding the ambiguity between "absent" and "stored null".

```java
// JUnit 5.x — getOrComputeIfAbsent (deprecated in 6.0, removed)
Object resource = store.getOrComputeIfAbsent(MyKey.class, k -> createResource());

// JUnit 6.0 — computeIfAbsent (non-null return; throws on null from supplier)
MyResource resource = store.computeIfAbsent(MyKey.class, k -> createResource(), MyResource.class);
```

**`--fail-fast` cancellation token.** JUnit 6 introduces a `CancellationToken` that propagates cancellation from the launcher to running tests, enabling clean shutdown of long-running test suites in CI.

**`@TestMethodOrder` inheritance.** `@TestMethodOrder` on a parent class now applies recursively to all `@Nested` inner classes — no need to repeat the annotation.

### Migration Path from JUnit 5.x

1. Set Java 17 as the project minimum (`<java.version>17</java.version>` in Maven, `sourceCompatibility = JavaVersion.VERSION_17` in Gradle).
2. Update JUnit BOM: `junit-bom:6.0.0`.
3. Remove `junit-platform-runner` dependency; configure the JUnit Platform Launcher directly.
4. Replace `@MethodOrderer.Alphanumeric` with `@TestMethodOrder(MethodOrderer.MethodName.class)`.
5. Audit `@CsvSource` data for extra characters after quoted values — FastCSV is stricter.
6. Run `./mvnw test` (or `./gradlew test`) and fix any compilation errors from removed APIs.

---

## Mockito 5.22 — Kotlin Singleton Mocking and Auto-Detection

### Kotlin `object` Declaration Mocking (5.22)

Mockito 5.22 added support for mocking Kotlin `object` declarations (singletons) via `mockSingleton()`. Previously, Kotlin objects could only be mocked with PowerMock or special Kotlin test libraries. This is relevant in mixed Java/Kotlin codebases where singleton services are defined as Kotlin objects.

```java
// Kotlin singleton (object declaration)
// object EmailService { fun send(to: String): Boolean = TODO() }

import org.mockito.Mockito;

// Java test mocking a Kotlin object singleton
try (var mock = Mockito.mockSingleton(EmailService.class)) {
    // All calls to EmailService.INSTANCE.send(...) now go through the mock
    Mockito.when(EmailService.INSTANCE.send(Mockito.any())).thenReturn(true);

    boolean result = EmailService.INSTANCE.send("alice@example.com");

    assertThat(result).isTrue();
    Mockito.verify(EmailService.INSTANCE).send("alice@example.com");
}
// After try block: original singleton behaviour is restored
```

**Note:** Kotlin `object` mocking requires the inline mock maker (default on Java 21+). Calling `mockSingleton()` on a regular (non-Kotlin-object) class throws `IllegalArgumentException`.

### `ReturnsEmptyValues` for Unstubbed `Future`/`CompletionStage` (5.22)

Mockito 5.22 also changed the default answer for unstubbed methods returning `Future` or `CompletionStage`: they now return a **completed future** with a null value rather than `null` itself. This prevents `NullPointerException` in code that chains `.thenApply(...)` on an unstubbed method result without checking for null.

```java
@Mock
OrderService orderService;  // not stubbed

@Test
void unstubbedFutureReturnsCompletedFuture() {
    // Before 5.22: orderService.placeAsync() returned null → NPE on .thenApply()
    // After 5.22: returns CompletableFuture.completedFuture(null) → safe to chain

    CompletableFuture<Order> result = orderService.placeAsync(new OrderRequest());
    // result is non-null completed future; chaining is safe
    result.thenApply(order -> order != null ? order.id() : "none");  // no NPE
}
```

---

## Spring Boot 3.5 — SSL Testcontainers Support

Spring Boot 3.5 extended `@ServiceConnection` to support encrypted connections. New annotations enable SSL between the test and the Testcontainers service for supported technologies.

```java
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.testcontainers.service.connection.ssl.PostgreSqlSslBundle;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@SpringBootTest
@Testcontainers
class SecurePostgresIntegrationTest {

    // @ServiceConnection with SSL — new in Spring Boot 3.5
    // Spring configures a TLS DataSource pointing at the container's SSL endpoint
    @Container
    @ServiceConnection
    @PostgreSqlSslBundle           // annotation enables SSL for this connection
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withCreateContainerCmdModifier(cmd ->
                cmd.withCmd("postgres", "-c", "ssl=on"));

    // DataSource is automatically configured with TLS — no manual ssl-mode property needed
}
```

**Supported SSL annotations (Spring Boot 3.5):** `@CassandraSslBundle`, `@ElasticsearchSslBundle`, `@KafkaSslBundle`, `@MongoDbSslBundle`, `@RabbitMqSslBundle`, `@RedisSslBundle`, and `@PostgreSqlSslBundle`.

**When to use SSL Testcontainers:** When your production database requires TLS and you want integration tests to verify TLS handshake, certificate validation, and connection behaviour — not just query correctness. Without this feature, TLS-related misconfigurations only surface at production deployment.

---

## AssertJ Record and Sealed Class Introspection (3.27+)

AssertJ 3.27.1 fixed record accessor introspection, making record-based assertions more reliable in `usingRecursiveComparison()` and field-extracting assertions. Sealed class support also improved with native JDK methods replacing reflection heuristics.

```java
// Record assertions — improved in 3.27.1
public record Address(String street, String city, String zip) {}
public record User(String name, String email, Address address) {}

@Test
void recursiveComparisonWithRecords() {
    User actual   = new User("Alice", "alice@example.com",
                             new Address("123 Main St", "Springfield", "12345"));
    User expected = new User("Alice", "alice@example.com",
                             new Address("123 Main St", "Springfield", "12345"));

    // usingRecursiveComparison correctly introspects record accessors in 3.27.1+
    assertThat(actual)
        .usingRecursiveComparison()
        .isEqualTo(expected);

    // Single-field assertion on nested record component
    assertThat(actual)
        .extracting(u -> u.address().city())
        .isEqualTo("Springfield");

    // Ignoring specific fields in recursive comparison
    assertThat(actual)
        .usingRecursiveComparison()
        .ignoringFields("email")          // skip email comparison
        .isEqualTo(expected);
}

// Sealed class isInstanceOf — uses JDK isSealed()/getPermittedSubclasses() in 4.0.0-M1+
public sealed interface Shape permits Circle, Rectangle {}
public record Circle(double radius) implements Shape {}
public record Rectangle(double w, double h) implements Shape {}

@Test
void sealedClassAssertions() {
    Shape shape = new Circle(5.0);

    assertThat(shape).isInstanceOf(Circle.class);
    assertThat(shape)
        .isNotInstanceOf(Rectangle.class)
        .satisfies(s -> assertThat(((Circle) s).radius()).isEqualTo(5.0));
}
```

**Gotcha — recursive comparison with records pre-3.27.1:** Record components are accessed via generated accessor methods (`name()`, not `getName()`). Older AssertJ versions missed these using reflection strategies designed for JavaBeans. 3.27.1 fixed the introspection to use `Class.getRecordComponents()`, which returns `RecordComponent` objects with the correct accessor methods.


