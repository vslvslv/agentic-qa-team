# General Patterns & Best Practices
<!-- sources: mixed (official docs synthesized from training knowledge: refactoring.guru, Wikipedia SOLID/DRY, GoF book, Clean Code, iluwatar/java-design-patterns, practitioner community) | iteration: 1 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Manage complexity through separation.** Every design principle at its root is about keeping things from knowing too much about each other. The goal is modules that can be understood, changed, and tested in isolation.

2. **Design for change, not for imagination.** YAGNI says don't build what you might need — build exactly what you need today, but structure it so extension is cheap. The future will surprise you; your code should accommodate that cheaply.

3. **Prefer composition over inheritance.** Inheritance creates tight coupling across a hierarchy. Composition lets you combine behaviour from independently-testable units and swap implementations at runtime.

4. **Patterns are vocabulary, not rules.** GoF patterns are names for solutions that recur. Applying them blindly adds unnecessary abstraction. Apply them when the problem they solve is present.

5. **Code is read far more than it is written.** Every naming decision, abstraction boundary, and pattern choice is a communication act toward the next developer — including future you.

---

## Principles / Patterns

### Single Responsibility Principle (SRP)
A class should have one reason to change. If a class handles both business logic and persistence, changes to either concern force you to reopen the class — increasing the chance of regression. SRP is not "do one thing" (too vague) but "have one reason to change" (testable by asking: who would ask us to change this?).

```java
// BEFORE — two reasons to change: email content AND sending mechanism
class UserNotifier {
    public void notify(User user) {
        String body = "Welcome, " + user.getName();   // content logic
        SmtpClient.send(user.getEmail(), body);        // transport logic
    }
}

// AFTER — each class has one reason to change
class WelcomeEmailComposer {
    public Email compose(User user) {
        return new Email(user.getEmail(), "Welcome, " + user.getName());
    }
}

class EmailSender {
    private final SmtpClient client;
    public void send(Email email) {
        client.send(email.getTo(), email.getBody());
    }
}
```

### Open/Closed Principle (OCP)
Software entities should be open for extension but closed for modification. Add new behaviour by adding new code, not by editing existing code. This is achieved through abstractions (interfaces, abstract classes) that allow plug-in implementations.

```java
interface DiscountStrategy {
    double apply(double price);
}

class NoDiscount implements DiscountStrategy {
    public double apply(double price) { return price; }
}

class SeasonalDiscount implements DiscountStrategy {
    private final double rate;
    public SeasonalDiscount(double rate) { this.rate = rate; }
    public double apply(double price) { return price * (1 - rate); }
}

class PriceCalculator {
    // Adding a new discount never modifies this class
    public double calculate(double price, DiscountStrategy strategy) {
        return strategy.apply(price);
    }
}
```

### Liskov Substitution Principle (LSP)
Subtypes must be substitutable for their base types without altering correctness. A derived class must honour the contract of the base class — same preconditions, postconditions, and invariants. Violating LSP is a sign that inheritance was used for code reuse rather than for a true "is-a" relationship.

```java
// VIOLATION: Square extends Rectangle but breaks the contract
// (setting width also changes height)
class Rectangle {
    protected int width, height;
    public void setWidth(int w)  { this.width = w; }
    public void setHeight(int h) { this.height = h; }
    public int area() { return width * height; }
}
class Square extends Rectangle {
    public void setWidth(int w)  { this.width = this.height = w; }  // surprise!
    public void setHeight(int h) { this.width = this.height = h; }
}

// FIX: model them as separate implementations of a shared interface
interface Shape { int area(); }
class Rectangle implements Shape { /* width/height independent */ }
class Square    implements Shape { /* single side */              }
```

### Interface Segregation Principle (ISP)
Clients should not be forced to depend on interfaces they do not use. A fat interface couples the client to all methods even if it only needs one. Split interfaces by the role the client plays toward the object.

```java
// FAT interface forces printers to implement scan()
interface Device {
    void print(Document d);
    void scan(Document d);
    void fax(Document d);
}

// SEGREGATED — clients depend only on what they use
interface Printer  { void print(Document d); }
interface Scanner  { void scan(Document d);  }
interface Fax      { void fax(Document d);   }

class SimplePrinter implements Printer {
    public void print(Document d) { /* print logic */ }
    // does not inherit scan/fax noise
}

class MultiFunctionDevice implements Printer, Scanner, Fax {
    public void print(Document d) { /* ... */ }
    public void scan(Document d)  { /* ... */ }
    public void fax(Document d)   { /* ... */ }
}
```

### Dependency Inversion Principle (DIP)
High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details; details should depend on abstractions. This is the enabling principle for dependency injection frameworks.

```java
// VIOLATION: high-level OrderService depends on low-level MySqlRepository directly
class OrderService {
    private MySqlOrderRepository repo = new MySqlOrderRepository();
    public void placeOrder(Order o) { repo.save(o); }
}

// CORRECT: both depend on the interface
interface OrderRepository { void save(Order o); }

class OrderService {
    private final OrderRepository repo;
    public OrderService(OrderRepository repo) { this.repo = repo; }
    public void placeOrder(Order o) { repo.save(o); }
}

class MySqlOrderRepository implements OrderRepository {
    public void save(Order o) { /* MySQL-specific */ }
}
```

### DRY — Don't Repeat Yourself
Every piece of knowledge should have a single, unambiguous representation in a system. Duplication of logic (not just text) means two places must change for one conceptual change — and one will be missed. DRY applies to logic, not to the coincidental similarity of two code fragments with different semantics.

```python
# VIOLATION: validation logic duplicated in two endpoints
def create_user(data):
    if len(data['name']) < 2:
        raise ValueError("Name too short")
    if '@' not in data['email']:
        raise ValueError("Invalid email")
    db.insert('users', data)

def update_user(id, data):
    if len(data['name']) < 2:        # duplicated
        raise ValueError("Name too short")
    if '@' not in data['email']:     # duplicated
        raise ValueError("Invalid email")
    db.update('users', id, data)

# FIX: extract the single authoritative validator
def validate_user_fields(data):
    if len(data['name']) < 2:
        raise ValueError("Name too short")
    if '@' not in data['email']:
        raise ValueError("Invalid email")

def create_user(data):
    validate_user_fields(data)
    db.insert('users', data)

def update_user(id, data):
    validate_user_fields(data)
    db.update('users', id, data)
```

### KISS — Keep It Simple, Stupid
Prefer the simplest solution that works. Every additional abstraction layer, every generalisation, every framework introduces cognitive load for the next reader. Solve the actual problem, not an imagined future problem.

```python
# OVER-ENGINEERED for a utility that formats a greeting
class AbstractGreetingFormatterFactory:
    def create_formatter(self): ...

class FormalGreetingFormatter:
    def format(self, name): return f"Good day, {name}."

class CasualGreetingFormatter:
    def format(self, name): return f"Hey, {name}!"

# KISS — just a function; add abstraction when you actually have two callers
def format_greeting(name: str, formal: bool = False) -> str:
    return f"Good day, {name}." if formal else f"Hey, {name}!"
```

### YAGNI — You Aren't Gonna Need It
Don't add functionality until you know it is needed. Speculative code adds maintenance cost, increases surface area for bugs, and often gets in the way of the actual solution once requirements arrive. Build the simplest thing that works and refactor when the need is clear.

```java
// YAGNI violation: "we might support plugins someday"
class ReportGenerator {
    private final List<ReportPlugin> plugins = new ArrayList<>(); // never used

    public void addPlugin(ReportPlugin p) { plugins.add(p); }  // never called

    public String generate(Data data) {
        // actual logic here — plugins ignored
        return data.toCSV();
    }
}

// YAGNI-compliant: generate the report; add plugins when a requirement exists
class ReportGenerator {
    public String generate(Data data) {
        return data.toCSV();
    }
}
```

### Law of Demeter (LoD) — Principle of Least Knowledge
A method should only call methods on: itself, its parameters, objects it creates, or its direct fields. "Don't talk to strangers." Method chains like `a.getB().getC().doThing()` create coupling to internal structure that breaks when the internal structure changes.

```java
// VIOLATION: OrderService knows about Customer's internal Address structure
class OrderService {
    public String getShippingCity(Order order) {
        return order.getCustomer().getAddress().getCity();  // train wreck
    }
}

// COMPLIANT: Order provides a single step
class Order {
    public String getShippingCity() {
        return customer.getShippingCity(); // delegates
    }
}
class Customer {
    public String getShippingCity() {
        return address.getCity();
    }
}
```

### Composition over Inheritance
Inherit for "is-a" relationships where the full contract of the parent applies. Use composition for code reuse — wrap the behaviour you need rather than inheriting from a class whose full interface you don't need. Composition allows behaviour to vary at runtime; inheritance locks it at compile-time.

```java
// INHERITANCE MISUSE: Stack extends Vector (Java's actual design mistake)
// Stack inherits get(index), add(index, elem), etc. — which violate stack semantics

// COMPOSITION: Stack wraps a storage mechanism
class Stack<T> {
    private final Deque<T> storage = new ArrayDeque<>();

    public void push(T item) { storage.push(item); }
    public T    pop()        { return storage.pop(); }
    public T    peek()       { return storage.peek(); }
    public boolean isEmpty() { return storage.isEmpty(); }
    // Only stack operations are visible — no random-access leakage
}
```

---

## GoF Creational Patterns

### Factory Method
Define an interface for creating an object, but let subclasses decide which class to instantiate. Decouples the client from the concrete type it uses.

```java
interface Logger { void log(String msg); }

class ConsoleLogger implements Logger {
    public void log(String msg) { System.out.println("[CONSOLE] " + msg); }
}

class FileLogger implements Logger {
    public void log(String msg) { /* write to file */ }
}

// Factory method — subclasses or configuration determines the product
class LoggerFactory {
    public static Logger create(String type) {
        return switch (type) {
            case "console" -> new ConsoleLogger();
            case "file"    -> new FileLogger();
            default -> throw new IllegalArgumentException("Unknown logger: " + type);
        };
    }
}
```

### Abstract Factory
Provide an interface for creating families of related or dependent objects without specifying their concrete classes. Useful when the system must be independent of how its products are created.

```java
interface Button   { void render(); }
interface Checkbox { void render(); }

interface UIFactory {
    Button   createButton();
    Checkbox createCheckbox();
}

class WindowsUIFactory implements UIFactory {
    public Button   createButton()   { return new WindowsButton(); }
    public Checkbox createCheckbox() { return new WindowsCheckbox(); }
}

class MacUIFactory implements UIFactory {
    public Button   createButton()   { return new MacButton(); }
    public Checkbox createCheckbox() { return new MacCheckbox(); }
}

class App {
    private final UIFactory factory;
    public App(UIFactory factory) { this.factory = factory; }
    public void buildUI() {
        Button btn = factory.createButton();
        btn.render();
    }
}
```

### Builder
Separate the construction of a complex object from its representation so the same construction process can create different representations. Especially valuable when an object has many optional parameters (avoid telescoping constructors).

```java
class HttpRequest {
    private final String url;
    private final String method;
    private final Map<String, String> headers;
    private final String body;

    private HttpRequest(Builder b) {
        this.url     = b.url;
        this.method  = b.method;
        this.headers = Collections.unmodifiableMap(b.headers);
        this.body    = b.body;
    }

    public static class Builder {
        private final String url;
        private String method = "GET";
        private Map<String, String> headers = new HashMap<>();
        private String body;

        public Builder(String url) { this.url = url; }
        public Builder method(String m) { this.method = m; return this; }
        public Builder header(String k, String v) { headers.put(k, v); return this; }
        public Builder body(String b) { this.body = b; return this; }
        public HttpRequest build() { return new HttpRequest(this); }
    }
}

// Usage — reads like prose
HttpRequest req = new HttpRequest.Builder("https://api.example.com/users")
    .method("POST")
    .header("Content-Type", "application/json")
    .body("{\"name\":\"Alice\"}")
    .build();
```

### Singleton
Ensure a class has only one instance and provide a global access point to it. Use sparingly — global state is a testing obstacle and a source of hidden coupling. Consider whether dependency injection can satisfy the "single instance" need without the global access point.

```java
// Thread-safe Singleton using initialization-on-demand holder idiom
class ConfigRegistry {
    private final Map<String, String> config;

    private ConfigRegistry() {
        config = loadFromFile(); // expensive one-time init
    }

    private static class Holder {
        static final ConfigRegistry INSTANCE = new ConfigRegistry();
    }

    public static ConfigRegistry getInstance() {
        return Holder.INSTANCE;
    }

    public String get(String key) {
        return config.getOrDefault(key, "");
    }

    private Map<String, String> loadFromFile() { return new HashMap<>(); }
}
```

### Prototype
Create new objects by copying an existing object (prototype). Useful when object creation is expensive or when classes to instantiate are specified at run-time.

```java
abstract class Shape implements Cloneable {
    public int x, y;
    public abstract Shape clone();
}

class Circle extends Shape {
    public int radius;

    public Circle(Circle source) {
        this.x = source.x;
        this.y = source.y;
        this.radius = source.radius;
    }

    @Override
    public Shape clone() { return new Circle(this); }
}

// Usage — clone registry avoids expensive re-creation
Map<String, Shape> registry = Map.of("circle", new Circle());
Shape copy = registry.get("circle").clone(); // cheap
```

---

## GoF Structural Patterns

### Adapter
Convert the interface of a class into another interface clients expect. Lets classes work together that couldn't otherwise because of incompatible interfaces. Wrap the adaptee; delegate all calls.

```java
// Third-party payment gateway with its own interface
class LegacyPaymentGateway {
    public boolean chargeCard(String cardNumber, int amountCents) { return true; }
}

// Your system's interface
interface PaymentProcessor {
    void charge(String cardToken, double amountDollars);
}

// Adapter bridges the gap
class PaymentGatewayAdapter implements PaymentProcessor {
    private final LegacyPaymentGateway gateway;

    public PaymentGatewayAdapter(LegacyPaymentGateway gateway) {
        this.gateway = gateway;
    }

    public void charge(String cardToken, double amountDollars) {
        int cents = (int)(amountDollars * 100);
        boolean ok = gateway.chargeCard(cardToken, cents);
        if (!ok) throw new PaymentException("Charge failed");
    }
}
```

### Decorator
Attach additional responsibilities to an object dynamically. Decorators provide a flexible alternative to subclassing for extending functionality. Each decorator wraps the original object and adds behaviour before or after delegating.

```java
interface TextTransformer {
    String transform(String input);
}

class UpperCaseTransformer implements TextTransformer {
    public String transform(String input) { return input.toUpperCase(); }
}

class TrimDecorator implements TextTransformer {
    private final TextTransformer inner;
    public TrimDecorator(TextTransformer inner) { this.inner = inner; }
    public String transform(String input) {
        return inner.transform(input.trim());
    }
}

class PrefixDecorator implements TextTransformer {
    private final TextTransformer inner;
    private final String prefix;
    public PrefixDecorator(TextTransformer inner, String prefix) {
        this.inner = inner; this.prefix = prefix;
    }
    public String transform(String input) {
        return prefix + inner.transform(input);
    }
}

// Compose freely at runtime
TextTransformer t = new PrefixDecorator(
    new TrimDecorator(new UpperCaseTransformer()), "[OUT] ");
System.out.println(t.transform("  hello  ")); // "[OUT] HELLO"
```

### Facade
Provide a simplified interface to a complex subsystem. A facade hides complexity from clients without eliminating it — the subsystem is still accessible directly when needed.

```java
// Subsystem classes (complex, low-level)
class VideoDecoder   { public RawFrames decode(File f) { return null; } }
class AudioDecoder   { public RawAudio  decode(File f) { return null; } }
class FrameRenderer  { public void render(RawFrames f) {}              }
class AudioPlayer    { public void play(RawAudio a)    {}              }

// Facade — single entry point for the common workflow
class VideoPlayer {
    private final VideoDecoder  video = new VideoDecoder();
    private final AudioDecoder  audio = new AudioDecoder();
    private final FrameRenderer renderer = new FrameRenderer();
    private final AudioPlayer   player   = new AudioPlayer();

    public void play(File file) {
        renderer.render(video.decode(file));
        player.play(audio.decode(file));
    }
}
```

### Proxy
Provide a surrogate or placeholder for another object to control access to it. Use cases: lazy initialization, caching, access control, logging, remote proxies.

```java
interface DataService { String fetchData(String key); }

class RealDataService implements DataService {
    public String fetchData(String key) {
        // expensive DB/network call
        return "data-for-" + key;
    }
}

// Caching Proxy — transparent to callers
class CachingProxy implements DataService {
    private final DataService real = new RealDataService();
    private final Map<String, String> cache = new HashMap<>();

    public String fetchData(String key) {
        return cache.computeIfAbsent(key, real::fetchData);
    }
}
```

### Composite
Compose objects into tree structures to represent part-whole hierarchies. Composite lets clients treat individual objects and compositions of objects uniformly.

```java
interface FileSystemNode {
    long size();
    void print(String indent);
}

class File implements FileSystemNode {
    private final String name;
    private final long bytes;
    public File(String name, long bytes) { this.name = name; this.bytes = bytes; }
    public long size() { return bytes; }
    public void print(String indent) {
        System.out.println(indent + name + " (" + bytes + "b)");
    }
}

class Directory implements FileSystemNode {
    private final String name;
    private final List<FileSystemNode> children = new ArrayList<>();
    public Directory(String name) { this.name = name; }
    public void add(FileSystemNode n) { children.add(n); }
    public long size() { return children.stream().mapToLong(FileSystemNode::size).sum(); }
    public void print(String indent) {
        System.out.println(indent + name + "/");
        children.forEach(c -> c.print(indent + "  "));
    }
}
```

---

## GoF Behavioral Patterns

### Strategy
Define a family of algorithms, encapsulate each one, and make them interchangeable. Strategy lets the algorithm vary independently from clients that use it. Enables open/closed principle for algorithms.

```java
interface SortStrategy<T extends Comparable<T>> {
    void sort(List<T> list);
}

class QuickSort<T extends Comparable<T>> implements SortStrategy<T> {
    public void sort(List<T> list) { Collections.sort(list); /* simplified */ }
}

class InsertionSort<T extends Comparable<T>> implements SortStrategy<T> {
    public void sort(List<T> list) { /* insertion sort impl */ }
}

class DataProcessor<T extends Comparable<T>> {
    private SortStrategy<T> strategy;
    public void setStrategy(SortStrategy<T> s) { this.strategy = s; }
    public void process(List<T> data) {
        strategy.sort(data);
        // ... further processing
    }
}
```

### Observer
Define a one-to-many dependency so that when one object (subject) changes state, all dependents (observers) are notified and updated automatically. Foundation of event-driven and reactive systems.

```java
interface StockObserver { void onPriceChange(String symbol, double price); }

class StockTicker {
    private final List<StockObserver> observers = new ArrayList<>();
    private double price;

    public void subscribe(StockObserver o)   { observers.add(o); }
    public void unsubscribe(StockObserver o) { observers.remove(o); }

    public void updatePrice(String symbol, double newPrice) {
        this.price = newPrice;
        observers.forEach(o -> o.onPriceChange(symbol, newPrice));
    }
}

class PriceAlertService implements StockObserver {
    public void onPriceChange(String symbol, double price) {
        if (price > 1000) System.out.println("Alert: " + symbol + " at " + price);
    }
}
```

### Command
Encapsulate a request as an object, thereby letting you parameterise clients with different requests, queue or log requests, and support undoable operations.

```java
interface Command { void execute(); void undo(); }

class TextEditor {
    private StringBuilder text = new StringBuilder();
    public void insertText(String s) { text.append(s); }
    public void deleteLastN(int n)   { text.delete(text.length() - n, text.length()); }
    public String getText()          { return text.toString(); }
}

class InsertCommand implements Command {
    private final TextEditor editor;
    private final String text;
    public InsertCommand(TextEditor e, String t) { editor = e; text = t; }
    public void execute() { editor.insertText(text); }
    public void undo()    { editor.deleteLastN(text.length()); }
}

class CommandHistory {
    private final Deque<Command> history = new ArrayDeque<>();
    public void execute(Command c) { c.execute(); history.push(c); }
    public void undo() { if (!history.isEmpty()) history.pop().undo(); }
}
```

### Template Method
Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. Template Method lets subclasses redefine certain steps of an algorithm without changing its structure.

```java
abstract class DataMigrator {
    // Template method — fixed skeleton
    public final void migrate() {
        connect();
        List<Record> records = extract();
        List<Record> transformed = transform(records);
        load(transformed);
        disconnect();
    }

    protected abstract void connect();
    protected abstract List<Record> extract();
    protected abstract List<Record> transform(List<Record> records);
    protected abstract void load(List<Record> records);
    protected void disconnect() { /* default: no-op */ }
}

class CsvToPostgresMigrator extends DataMigrator {
    protected void connect() { /* open CSV + PG connection */ }
    protected List<Record> extract() { /* parse CSV rows */ return List.of(); }
    protected List<Record> transform(List<Record> r) { /* map fields */ return r; }
    protected void load(List<Record> r) { /* bulk INSERT */ }
}
```

### Iterator
Provide a way to access elements of a collection sequentially without exposing the underlying representation. All modern languages have this built into their for-each constructs.

```java
class NumberRange implements Iterable<Integer> {
    private final int start, end;
    public NumberRange(int start, int end) { this.start = start; this.end = end; }

    @Override
    public Iterator<Integer> iterator() {
        return new Iterator<>() {
            int current = start;
            public boolean hasNext() { return current <= end; }
            public Integer next() {
                if (!hasNext()) throw new NoSuchElementException();
                return current++;
            }
        };
    }
}

// Usage
for (int n : new NumberRange(1, 5)) {
    System.out.println(n); // 1 2 3 4 5
}
```

### Chain of Responsibility
Pass requests along a chain of handlers. Each handler decides either to process the request or to pass it to the next handler in the chain. Decouples senders from receivers.

```java
abstract class RequestHandler {
    protected RequestHandler next;
    public RequestHandler setNext(RequestHandler next) {
        this.next = next; return next;
    }
    public abstract void handle(HttpRequest req);
}

class AuthHandler extends RequestHandler {
    public void handle(HttpRequest req) {
        if (!req.hasAuthToken()) { req.reject(401, "Unauthorized"); return; }
        if (next != null) next.handle(req);
    }
}

class RateLimitHandler extends RequestHandler {
    public void handle(HttpRequest req) {
        if (isRateLimited(req)) { req.reject(429, "Too Many Requests"); return; }
        if (next != null) next.handle(req);
    }
    private boolean isRateLimited(HttpRequest r) { return false; }
}

// Chain setup
RequestHandler chain = new AuthHandler();
chain.setNext(new RateLimitHandler());
chain.handle(incomingRequest);
```

### State
Allow an object to alter its behaviour when its internal state changes. The object will appear to change its class. Eliminates large if/switch blocks driven by state flags.

```java
interface VendingMachineState {
    void insertCoin(VendingMachine m);
    void selectProduct(VendingMachine m);
    void dispense(VendingMachine m);
}

class IdleState implements VendingMachineState {
    public void insertCoin(VendingMachine m) {
        System.out.println("Coin accepted");
        m.setState(new HasMoneyState());
    }
    public void selectProduct(VendingMachine m) { System.out.println("Insert coin first"); }
    public void dispense(VendingMachine m)      { System.out.println("Insert coin first"); }
}

class HasMoneyState implements VendingMachineState {
    public void insertCoin(VendingMachine m)    { System.out.println("Already has money"); }
    public void selectProduct(VendingMachine m) {
        System.out.println("Product selected");
        m.setState(new DispensingState());
    }
    public void dispense(VendingMachine m)      { System.out.println("Select a product first"); }
}

class DispensingState implements VendingMachineState {
    public void insertCoin(VendingMachine m)    { System.out.println("Please wait"); }
    public void selectProduct(VendingMachine m) { System.out.println("Please wait"); }
    public void dispense(VendingMachine m) {
        System.out.println("Dispensing...");
        m.setState(new IdleState());
    }
}

class VendingMachine {
    private VendingMachineState state = new IdleState();
    public void setState(VendingMachineState s) { this.state = s; }
    public void insertCoin()   { state.insertCoin(this); }
    public void selectProduct(){ state.selectProduct(this); }
    public void dispense()     { state.dispense(this); }
}
```

---

## Language Idioms

For language-agnostic principles there are no language-specific syntax idioms, but these cross-paradigm idioms apply everywhere:

- **Guard clauses over nested ifs.** Return early on invalid conditions instead of wrapping the happy path in nested blocks. This keeps the primary logic readable at the method's outermost scope.

```java
// NESTED (hard to follow)
public void processOrder(Order order) {
    if (order != null) {
        if (order.isValid()) {
            if (order.hasItems()) {
                // actual work buried 3 levels deep
                ship(order);
            }
        }
    }
}

// GUARD CLAUSES (reads linearly)
public void processOrder(Order order) {
    if (order == null)      throw new IllegalArgumentException("order is null");
    if (!order.isValid())   throw new OrderValidationException("invalid order");
    if (!order.hasItems())  throw new EmptyOrderException("no items");
    ship(order); // happy path at top level
}
```

- **Tell, don't ask.** Instead of querying an object's state and then acting on it, tell the object to perform the action. Moves behaviour to where the data lives.

```java
// ASK (breaks encapsulation)
if (account.getBalance() >= amount) {
    account.setBalance(account.getBalance() - amount);
    audit.log("debit", amount);
}

// TELL
account.debit(amount, audit); // account knows how to debit itself
```

- **Null Object pattern.** Return a no-op implementation instead of null to eliminate null checks at call sites.

```java
interface Logger { void log(String msg); }
class RealLogger  implements Logger { public void log(String m) { System.out.println(m); } }
class NullLogger  implements Logger { public void log(String m) { /* intentional no-op */ } }

class Service {
    private final Logger logger;
    // Pass NullLogger instead of null; call sites never need null checks
    public Service(Logger logger) { this.logger = Objects.requireNonNull(logger); }
}
```

- **Value objects over primitives.** Wrap domain primitives in small immutable types to prevent primitive obsession, centralise validation, and make method signatures self-documenting. The compiler then prevents callers from accidentally swapping arguments of the same raw type.

```java
// PRIMITIVE OBSESSION — compiler cannot catch swapped arguments
void transfer(String fromId, String toId, double amount) { /* ... */ }
transfer("acc-456", "acc-123", -50.0);  // silently wrong: reversed, negative OK

// VALUE OBJECTS — validated at construction, compiler-checked at call sites
final class AccountId {
    private final String value;
    public AccountId(String value) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException("blank id");
        this.value = value;
    }
    public String value() { return value; }
}

final class Money {
    private final BigDecimal amount;
    private final Currency currency;
    public Money(BigDecimal amount, Currency currency) {
        if (amount.compareTo(BigDecimal.ZERO) < 0) throw new IllegalArgumentException("negative money");
        this.amount = amount; this.currency = currency;
    }
    public BigDecimal amount()   { return amount; }
    public Currency  currency()  { return currency; }
}

void transfer(AccountId from, AccountId to, Money amount) { /* ... */ }
// Now: swapping from/to is a compile error; negative amount rejected at Money construction
```

- **Replace conditional with polymorphism.** When a switch/if-else dispatches on a type tag or enum to select behaviour, the condition will need to be updated whenever a new type is added (violating OCP). Replacing with a polymorphic dispatch eliminates the central dispatcher and makes adding new types additive.

```java
// CONDITIONAL DISPATCH — must update every switch when a new shape is added
double area(Shape shape) {
    return switch (shape.type()) {
        case CIRCLE    -> Math.PI * shape.radius() * shape.radius();
        case RECTANGLE -> shape.width() * shape.height();
        case TRIANGLE  -> 0.5 * shape.base() * shape.height();
        default -> throw new IllegalArgumentException("unknown shape");
    };
}

// POLYMORPHIC DISPATCH — adding Triangle only touches Triangle class
interface Shape       { double area(); }
record Circle   (double radius)         implements Shape { public double area() { return Math.PI * radius * radius; } }
record Rectangle(double width, double height) implements Shape { public double area() { return width * height; } }
record Triangle (double base,  double height) implements Shape { public double area() { return 0.5 * base * height; } }

// Caller: shape.area() — no switch needed, no central dispatcher to maintain
```

---

## Real-World Gotchas  [community]

**Singleton becoming global mutable state** [community] — The Singleton pattern is frequently used where dependency injection is the correct tool. A singleton that holds mutable state becomes an invisible dependency that makes unit tests order-dependent and parallel execution unsafe. WHY: tests cannot isolate the class under test because the singleton carries state from a previous test. FIX: inject the shared resource as a constructor parameter; use a DI container to manage its lifecycle.

**Premature abstraction via patterns** [community] — Developers apply GoF patterns prophylactically before the second use case exists. An interface with one implementation, a factory that creates one type, a strategy with one strategy — all add indirection with zero current benefit. WHY: the abstraction locks in assumptions about how variation will occur before you have evidence. FIX: refactor toward a pattern when you have two concrete implementations, not before. (Rule of three.)

**Violating LSP with Exception narrowing** [community] — A subclass overrides a method and throws a new checked exception not declared in the base class, or swallows an exception the caller expects. WHY: callers coded against the base-class contract cannot catch an undeclared exception; swallowing silently breaks post-conditions. FIX: only throw subtypes of declared exceptions; never widen the exception contract in an override.

**Decorator chain ordering bugs** [community] — When composing decorators (logging, caching, auth), the order of wrapping determines which concern sees what. A caching decorator placed outside an auth decorator caches responses without checking auth on cache hits. WHY: decorators are sequential — the outermost runs first on the way in, last on the way out. FIX: document the intended decoration order; consider a builder that enforces correct ordering.

**Observer memory leaks** [community] — Listeners/observers are registered but never unregistered when the subscriber is done. In long-running applications or UI frameworks this means the subject holds a reference preventing garbage collection of defunct observers. WHY: the subject's observer list is a GC root; it keeps observers alive indefinitely. FIX: provide unsubscribe/close lifecycle methods; use weak references for optional observation; audit subscription lifetimes at code review.

**Chain of Responsibility silent swallowing** [community] — A handler in the chain neither processes the request nor passes it to the next handler, silently dropping it. This is hard to diagnose because there is no error — the request just disappears. WHY: forgetting the `if (next != null) next.handle(req)` delegation is a common omission. FIX: add a default fallback handler at the end of the chain that throws or logs unhandled requests; write a test that exercises unmatched requests.

**God class disguised as a Facade** [community] — Developers use Facade as a justification for a class that has hundreds of methods and knows about every subsystem. Unlike a true facade (which delegates without adding logic), the God class accumulates business logic. WHY: "it's a facade" becomes an excuse to not decompose. FIX: a facade's methods should be thin delegators; if it has more than ~10 public methods or contains conditional logic, it has grown beyond facade responsibility.

**DRY applied to coincidental duplication** [community] — Two code fragments look identical today but represent different business concepts. Extracting them into a shared function couples them — when one changes, the other breaks unexpectedly. WHY: DRY is about single authoritative knowledge, not about removing identical text. FIX: ask "if I need to change this for reason A, would I always change the other for the same reason A?" If no, they are not the same knowledge.

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| God Class / Big Ball of Mud | Impossible to test, change, or understand in isolation; every modification risks breaking unrelated features | Apply SRP: extract cohesive responsibility clusters into separate classes |
| Singleton overuse | Hidden global state; breaks test isolation; couples callers to a specific lifecycle | Use constructor injection; let a DI container manage lifecycle |
| Magic numbers/strings | Intent is opaque; changing requires finding all occurrences | Named constants or enum types with meaningful names |
| Shotgun surgery | One logical change requires edits in many unrelated files | Apply DRY and encapsulate the changing knowledge in one place |
| Primitive obsession | Domain concepts lost in raw strings/ints; no type safety, no validation | Value objects: `Money`, `EmailAddress`, `UserId` wrapping primitives |
| Speculative generality | Dead abstraction layers "for future use"; bloats the codebase | YAGNI: remove unused abstractions; add them when two concrete cases exist |
| Feature Envy | A method that uses another class's data more than its own class's data | Move the method to the class whose data it uses |
| Inappropriate intimacy | Class accesses private/protected members of another class via reflection or friendship | Expose a clean API; use Law of Demeter |
| Anemic Domain Model | Domain objects are plain data bags; all logic lives in service classes | Put behaviour on the entities that own the data (rich domain model) |
| Sequential coupling | Methods must be called in a specific order but nothing enforces it | Use a state machine or builder that enforces ordering at compile time |
