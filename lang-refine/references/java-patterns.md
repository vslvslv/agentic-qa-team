# Java Patterns & Best Practices
<!-- sources: official (Oracle JDK 21 docs, Oracle Interface/Inheritance tutorial, awesome-java) | community (practitioner synthesis, Effective Java principles, awesome-java) | mixed | iteration: 5 | score: 100/100 | date: 2026-04-28 -->

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

### Generics with Bounded Type Parameters
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

**10. Blocking Virtual Threads on Synchronized Blocks (Java 21) [community]**
Virtual threads (introduced in Java 21) are cheap and designed for blocking I/O, but a `synchronized` block on a virtual thread **pins it to its carrier OS thread** — negating the scalability benefit. The root cause is that Java 21's virtual thread scheduler cannot unmount a pinned virtual thread. Fix: replace `synchronized` with `java.util.concurrent.locks.ReentrantLock` inside code paths that run on virtual threads, or wait for Java 24+ which lifts the pinning restriction.

```java
// BAD on virtual threads — pins carrier thread
synchronized (lock) {
    result = remoteService.fetchData();  // blocking I/O while pinned
}

// GOOD — ReentrantLock allows the virtual thread scheduler to unmount
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    result = remoteService.fetchData();  // virtual thread can unmount here
} finally {
    lock.unlock();
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

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why it's harmful | What to do instead |
|---|---|---|
| Returning null | Propagates NPE to callers silently | Return `Optional<T>` or throw a well-named exception |
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
| Assuming `Stream.toList()` is mutable | `UnsupportedOperationException` at runtime | Use `Collectors.toList()` when mutation is needed |
| `Optional<T>` as a field or collection element | Not Serializable; can itself be null; adds heap pressure | Store `null`/sentinel in fields; expose `Optional` only at return boundaries |
| `map.get()` + null check instead of `computeIfAbsent` | Verbose; non-atomic under concurrency | Use `computeIfAbsent` (atomic); `getOrDefault` for reads |
| Implementing `Comparable` for multiple sort orders | Locks in one sort order; inflexible | Use `Comparator` chains at the call site; reserve `Comparable` for natural order types |
| `Serializable` without explicit `serialVersionUID` | Class changes silently break deserialization | Declare `serialVersionUID = 1L` or avoid `Serializable`; prefer JSON/Protobuf |
