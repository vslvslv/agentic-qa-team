# Java Patterns & Best Practices
<!-- sources: official (Oracle JDK 21 docs, Oracle Interface/Inheritance tutorial, awesome-java, iluwatar/java-design-patterns, Oracle Stream package-summary, OpenJDK JEP index, JEP 491, JEP 477) | community (practitioner synthesis, Effective Java principles, awesome-java, OpenJDK JEPs) | mixed | iteration: 24 | score: 100/100 | date: 2026-05-12 -->

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

**36. Using `double` or `float` for Monetary Calculations [community]**
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
| Missing `@Override` annotation | Silent overloads instead of overrides; bugs evade the compiler | Always annotate intended overrides; catches signature mismatches at compile time |
