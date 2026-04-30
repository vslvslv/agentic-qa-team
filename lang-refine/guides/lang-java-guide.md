# Java Patterns & Best Practices
<!-- sources: official (Oracle JDK 21 docs, Oracle Interface/Inheritance tutorial, awesome-java) | community (practitioner synthesis, Effective Java principles, awesome-java) | mixed | iteration: 2 | score: 100/100 | date: 2026-04-30 -->

## Core Philosophy

1. **Prefer interfaces over classes as types** — program to abstractions so implementations can be swapped without cascading changes throughout the codebase.
2. **Fail fast and make illegal states unrepresentable** — use type-system features (Optional, sealed classes, records) to make bad states impossible to construct rather than catching them at runtime.
3. **Immutability by default** — immutable objects are thread-safe and easier to reason about; add mutability only when there is a compelling performance reason.
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
        this.url             = Objects.requireNonNull(b.url, "url");
        this.method          = b.method;
        this.timeoutMs       = b.timeoutMs;
        this.followRedirects = b.followRedirects;
    }

    public static final class Builder {
        private final String url;            // required
        private String  method          = "GET";
        private int     timeoutMs       = 5_000;
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
            .flatMap(c -> c.orders().stream())
            .filter(o -> o.total() > 0)
            .toList();
    }

    // mapMulti (Java 16+) — efficient alternative to flatMap for conditional expansion
    public List<String> expandTags(List<Order> orders) {
        return orders.<String>mapMulti((order, downstream) -> {
            downstream.accept(order.customerId());
            if (order.total() > 100) {
                downstream.accept("HIGH_VALUE:" + order.customerId());
            }
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

    public OrderService(NotificationSender sender) { this.sender = sender; }
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
Use bounded wildcards to write flexible, reusable APIs. The PECS mnemonic — **Producer Extends, Consumer Super** — tells you when to use `? extends T` (reading from the collection) vs. `? super T` (writing to it).

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
var users      = new ArrayList<User>();
var userMap    = new HashMap<String, User>();
var configPath = Path.of("/etc/myapp/config.json");

// GOOD — eliminates verbose generic repetition in loops
for (var entry : userMap.entrySet()) {
    System.out.println(entry.getKey() + " -> " + entry.getValue());
}

// BAD — return type of method call is not obvious
var result = process(data);   // What type is result?

// BAD — in lambda parameters where it adds nothing
users.stream().map((var u) -> u.getName());  // prefer: .map(User::getName)
```

### Virtual Threads (Java 21) — Scalable Concurrency Without Reactor Complexity
Virtual threads are lightweight threads managed by the JVM rather than the OS. They enable thread-per-request style code (blocking I/O, familiar `try/catch` error handling) to scale to millions of concurrent operations without the callback complexity of reactive frameworks.

```java
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.List;

public class VirtualThreadDemo {

    // Virtual-thread-per-task executor — recommended for I/O-bound workloads
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
        var client  = java.net.http.HttpClient.newHttpClient();
        var request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url)).build();
        return client.send(request,
            java.net.http.HttpResponse.BodyHandlers.ofString()).body();
    }
}
```

### CompletableFuture — Async Composition
`CompletableFuture<T>` enables non-blocking async pipelines by composing async operations with `thenApply`, `thenCompose`, and `exceptionally`. It remains useful when you need explicit async execution control in pre-virtual-thread codebases.

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

Java idioms are features or conventions that experienced Java developers use to write expressive, maintainable code — not just patterns expressed in Java, but capabilities specific to the language.

### Pattern Matching for instanceof (Java 16+)
Eliminates the redundant cast after an `instanceof` check. The binding variable is scoped to the branch where the check succeeds, preventing accidental use outside the guarded block.

```java
// Old style — redundant cast
Object obj = getPayload();
if (obj instanceof String) {
    String s = (String) obj;
    System.out.println(s.length());
}

// New style — binding variable eliminates the cast
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Pattern matching for switch (Java 21)
public String describe(Object obj) {
    return switch (obj) {
        case Integer i when i < 0      -> "negative int: " + i;
        case Integer i                 -> "positive int: " + i;
        case String  s when s.isBlank() -> "blank string";
        case String  s                 -> "string: " + s;
        case null                      -> "null";
        default -> "other: " + obj.getClass().getSimpleName();
    };
}
```

### Method References
Instead of writing a lambda that only delegates to a single method, use a method reference. It reads closer to English, signals intent more clearly, and avoids shadowing the argument name.

```java
List<String> names = List.of("Alice", "Bob", "Carol");

// Instance method reference on receiver
names.forEach(System.out::println);

// Instance method reference on type
names.stream().map(String::toUpperCase).toList();

// Constructor reference
List<User> users = names.stream()
    .map(User::new)
    .toList();
```

### Enhanced Switch Expressions (Java 14+)
Switch expressions use `->` arms and return values, eliminating fall-through bugs and intermediate variables.

```java
// Old style — fall-through risk, no return value
String label;
switch (status) {
    case PENDING: label = "Waiting"; break;
    case ACTIVE:  label = "Running"; break;
    default:      label = "Unknown";
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

public record Circle(double radius)                  implements Shape {}
public record Rectangle(double width, double height) implements Shape {}
public record Triangle(double base,  double height)  implements Shape {}

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
    .toList();
```

### @FunctionalInterface and Default Interface Methods
`@FunctionalInterface` enforces at compile time that an interface has exactly one abstract method, making it a valid lambda target. `default` methods let you add behaviour to interfaces without breaking existing implementors.

```java
@FunctionalInterface
public interface Transformer<T, R> {
    R transform(T input);

    default Transformer<T, R> andLog(String label) {
        return input -> {
            R result = this.transform(input);
            System.out.printf("[%s] %s -> %s%n", label, input, result);
            return result;
        };
    }

    static <T> Transformer<T, T> identity() {
        return t -> t;
    }
}

// Usage
Transformer<String, Integer> lengthOf = String::length;
Transformer<String, Integer> logged   = lengthOf.andLog("size-check");
int n = logged.transform("hello");  // prints: [size-check] hello -> 5
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
Function<String, String> trim        = String::trim;
Function<String, String> toLowerCase = String::toLowerCase;
Function<String, String> normalize   = trim.andThen(toLowerCase);

List<String> emails = rawEmails.stream()
    .map(normalize)
    .filter(validInput)
    .toList();
```

### Unnamed Patterns and Unnamed Variables (Java 22+)
Java 22 introduced unnamed patterns (`_`) for ignoring components you do not need in pattern matching, and unnamed variables (`_`) for lambda parameters and catch clauses you do not use. This reduces boilerplate and makes intent clear.

```java
// Unnamed pattern — ignore components you don't need
sealed interface Event permits OrderPlaced, PaymentReceived, ShipmentSent {}
record OrderPlaced(String orderId, double amount)  implements Event {}
record PaymentReceived(String paymentId, double amount) implements Event {}
record ShipmentSent(String trackingId)             implements Event {}

public boolean isFinancialEvent(Event event) {
    return switch (event) {
        case OrderPlaced(_, double amount) when amount > 0 -> true;
        case PaymentReceived _  -> true;
        case ShipmentSent _     -> false;
    };
}

// Unnamed variable in catch — intentionally unused exception object
try {
    return Integer.parseInt(raw);
} catch (NumberFormatException _) {
    return 0;
}

// Unnamed variable in lambda — side-effect only
list.forEach(_ -> counter.increment());
```

### SequencedCollection (Java 21)
`SequencedCollection` is a new interface in Java 21 that gives `List`, `Deque`, and `LinkedHashSet` a uniform API for accessing/removing first and last elements.

```java
import java.util.ArrayList;
import java.util.SequencedCollection;

SequencedCollection<String> items = new ArrayList<>(List.of("a", "b", "c", "d"));

String first = items.getFirst();   // "a"
String last  = items.getLast();    // "d"

items.addFirst("z");
items.removeLast();

// reversed() returns a reversed view without copying
items.reversed().forEach(System.out::println);
```

---

## Real-World Gotchas  [community]

**1. Returning null instead of Optional [community]**
Returning `null` from a method propagates `NullPointerException` to callers who forget to check. The root cause is that Java allows null everywhere but the type system does not track it. Fix: return `Optional<T>` for methods that may return no result, use `Objects.requireNonNull` at validation boundaries, and annotate parameters with `@NonNull` / `@Nullable`.

**2. Overusing Checked Exceptions [community]**
Wrapping every infrastructure failure in a checked exception forces every caller to either handle or re-declare it, resulting in boilerplate `catch(Exception e) { throw new RuntimeException(e); }` ladders. The root cause is misapplying the "caller should handle" rule to failures that are never actually handled. Fix: only throw checked exceptions for conditions the immediate caller can realistically recover from; use unchecked exceptions for the rest.

**3. Mutating Collections Passed as Parameters [community]**
Methods that silently modify a `List` or `Map` passed by the caller create spooky action at a distance — the caller's collection changes without any indication in the method signature. Fix: return a new collection, or use `List.copyOf()` to defensively copy on entry.

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
`==` compares object identity, not value. For string literals it appears to work due to string interning, masking the bug until strings come from runtime input (database, user, network). Fix: always use `.equals()` for object comparison; use `Objects.equals(a, b)` when either side might be null.

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
Catching `Exception` swallows `InterruptedException`, which resets the interrupt flag and can deadlock thread pools. Fix: catch the narrowest exception type possible; if you must catch broadly, at minimum log and re-interrupt for `InterruptedException`.

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
Using raw types (e.g., `List` instead of `List<String>`) bypasses compile-time type checking, re-introducing ClassCastExceptions that generics were designed to prevent. Fix: always parameterize generic types; enable `-Xlint:unchecked` in your build to surface existing raw type usage.

**9. Confusing `Stream.toList()` with a Mutable List [community]**
`Stream.toList()` (Java 16+) returns an **unmodifiable** list (any `add`/`set` throws `UnsupportedOperationException`), whereas `Collectors.toList()` returns a mutable `ArrayList`. Fix: use `Stream.toList()` when you only need to read results; use `.collect(Collectors.toList())` explicitly when you need to mutate the result list.

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
Virtual threads are cheap and designed for blocking I/O, but a `synchronized` block on a virtual thread **pins it to its carrier OS thread** — negating the scalability benefit. Fix: replace `synchronized` with `java.util.concurrent.locks.ReentrantLock` inside code paths that run on virtual threads.

```java
// BAD on virtual threads — pins carrier thread
synchronized (lock) {
    result = remoteService.fetchData();  // blocking I/O while pinned
}

// GOOD — ReentrantLock allows the virtual thread scheduler to unmount
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    result = remoteService.fetchData();
} finally {
    lock.unlock();
}
```

**11. Storing `Optional<T>` in a Field or Collection [community]**
`Optional` was designed as a return type only — not as a field type, parameter type, or collection element. Storing it in a field means it can itself be `null`, it is not `Serializable`, and it adds heap allocation for every absent value. Fix: store `null` or a sentinel value in fields; expose `Optional` only at return boundaries.

```java
// BAD — Optional as field
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
If you override `equals` without overriding `hashCode`, objects that are logically equal will hash to different buckets in `HashMap`/`HashSet`, causing silent lookup failures. Fix: always override both together; use `record` which auto-generates a correct contract.

```java
// BAD — only equals overridden
public class OrderId {
    private final String value;
    public OrderId(String value) { this.value = value; }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof OrderId other)) return false;
        return value.equals(other.value);
    }
    // hashCode NOT overridden!
}

Set<OrderId> ids = new HashSet<>();
ids.add(new OrderId("ORD-1"));
System.out.println(ids.contains(new OrderId("ORD-1")));  // FALSE!

// GOOD — record auto-generates correct equals + hashCode
public record OrderId(String value) {}
```

**13. Using HashMap.get() Instead of getOrDefault() / computeIfAbsent() [community]**
Calling `map.get(key)` and immediately checking for null is verbose and error-prone; forgetting the null check causes a NPE. More critically, the check-then-act pattern is not atomic and breaks under concurrent access even with `ConcurrentHashMap`. Fix: use `getOrDefault` for read-only lookups and `computeIfAbsent` for read-and-initialize patterns — both are atomic on `ConcurrentHashMap`.

```java
// BAD — two lookups, not atomic
Map<String, List<String>> groups = new ConcurrentHashMap<>();
if (!groups.containsKey(category)) {
    groups.put(category, new ArrayList<>());  // race condition window
}
groups.get(category).add(item);

// GOOD — atomic single operation
groups.computeIfAbsent(category, k -> new ArrayList<>()).add(item);

// GOOD — read with default
List<String> items = groups.getOrDefault(category, Collections.emptyList());
```

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why it's harmful | What to do instead |
|---|---|---|
| Returning null | Propagates NPE to callers silently | Return `Optional<T>` or throw a well-named exception |
| Overusing inheritance | Couples subclasses to superclass internals; fragile base class problem | Favour composition; use interfaces |
| God class | Single class accretes all logic; impossible to test or change | Apply SRP; split into focused, injected collaborators |
| Magic numbers/strings | Undocumented intent; refactoring breaks silently | Name constants with `static final` or enums |
| Checked exceptions everywhere | Forces callers to handle failures they cannot recover from | Use unchecked exceptions; wrap with context |
| Mutable public fields | Any code can change state; invariants impossible to maintain | Use private fields with accessors; prefer records |
| Singleton via static state | Hidden dependency; untestable; concurrency issues | Use dependency injection; pass the dependency |
| String concatenation in loops | O(n²) object allocation | `StringBuilder`, `Collectors.joining()` |
| `==` for object equality | Compares identity, not value | Always use `.equals()` |
| Ignoring `equals`/`hashCode` contract | Objects in Sets/Maps behave unexpectedly | Override both together; use `record` or IDE generation |
| Exposing mutable internals | Callers can corrupt object state | Return `Collections.unmodifiableList()` or defensive copies |
| Using raw types | Bypasses generic type safety | Always parameterize: `List<String>`, not `List` |
| Catching `Exception`/`Throwable` broadly | Swallows `InterruptedException`, hides JVM errors | Catch the narrowest type; handle `InterruptedException` properly |
| `new Thread()` without pool | Uncontrolled thread creation; OOM under load | Use `ExecutorService` / virtual threads (Java 21) |
| `synchronized` in virtual threads (Java 21) | Pins carrier OS thread; kills scalability | Use `ReentrantLock` instead of `synchronized` blocks |
| `Stream.toList()` assumed mutable | `UnsupportedOperationException` at runtime | Use `Collectors.toList()` when mutation is needed |
| `Optional<T>` as field or collection element | Not Serializable; can itself be null; adds heap pressure | Store null/sentinel in fields; expose `Optional` only at return boundaries |
| `map.get()` + null check instead of `computeIfAbsent` | Verbose; non-atomic under concurrency | Use `computeIfAbsent` (atomic); `getOrDefault` for reads |
