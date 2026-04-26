# Java Patterns & Best Practices
<!-- sources: official (Oracle JDK 21 docs, Oracle Interface/Inheritance tutorial, awesome-java) | community (practitioner synthesis, Effective Java principles, awesome-java) | mixed | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

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
The Streams API (java.util.stream) transforms sequential data processing from imperative loops to a pipeline of composable operations. Lazy evaluation means intermediate operations cost nothing unless a terminal operation is invoked.

```java
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

record Order(String customerId, double total, String status) {}

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

---

## Language Idioms

Java idioms are features or conventions that experienced Java developers use to write expressive, maintainable code — not just patterns expressed in Java but capabilities unique to the language.

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
