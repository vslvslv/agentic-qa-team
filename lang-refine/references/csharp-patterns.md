# C# Patterns & Best Practices
<!-- sources: mixed | iteration: 0 | score: 95/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Readability over cleverness** — C# code should read like a sequence of intent-revealing statements. async/await, pattern matching, and LINQ are tools for clarity, not puzzles to impress colleagues.
2. **Immutability by default** — Use records, init-only properties, and readonly fields. Mutability should be deliberate and documented.
3. **Type safety is your friend** — Nullable reference types, generics, and the type system catch bugs at compile time. Fight the urge to use `object`, `dynamic`, or suppress nullable warnings.
4. **Composition over inheritance** — Prefer interfaces, extension methods, and composition. Deep class hierarchies in C# lead to fragile base class problems and tight coupling.
5. **Async all the way down** — Mixing sync and async code causes deadlocks in ASP.NET Core. Async is viral by nature; design the call chain before writing the first method.

---

## Principles / Patterns

### LINQ — Query and Method Syntax

LINQ provides two syntaxes for querying in-memory collections, databases, and XML. Use query syntax when the intent resembles SQL (filter, order, group) and method syntax for chaining transformations. Always place `where` before `orderby` and `select` so the collection is filtered before sorting.

```csharp
// Method syntax — preferred for simple transforms
var activeUsers = users
    .Where(u => u.IsActive && u.CreatedAt > DateTime.UtcNow.AddDays(-30))
    .OrderBy(u => u.LastName)
    .Select(u => new { u.Id, FullName = $"{u.FirstName} {u.LastName}" })
    .ToList();

// Query syntax — clearer for joins and grouping
var seattleOrders =
    from customer in customers
    join order in orders on customer.Id equals order.CustomerId
    where customer.City == "Seattle"
    orderby order.CreatedAt descending
    select new { CustomerName = customer.Name, order.Total };
```

### async/await + ConfigureAwait

The Task Asynchronous Programming (TAP) model lets you write non-blocking I/O-bound code that reads like synchronous code. Await tasks instead of blocking with `.Result` or `.Wait()`. Start independent tasks before awaiting them to enable true concurrency. Use `ConfigureAwait(false)` in library code to avoid capturing the synchronization context.

```csharp
// Good: start independent tasks concurrently, then await results
public async Task<DashboardData> GetDashboardAsync(int userId)
{
    var userTask = _userService.GetUserAsync(userId);
    var ordersTask = _orderService.GetRecentOrdersAsync(userId);
    var notificationsTask = _notificationService.GetUnreadAsync(userId);

    // Await all at once — runs in ~max(each) time, not sum
    await Task.WhenAll(userTask, ordersTask, notificationsTask);

    return new DashboardData
    {
        User = await userTask,
        Orders = await ordersTask,
        Notifications = await notificationsTask
    };
}

// Library code: avoid capturing the synchronization context
public async Task<string> FetchDataAsync(string url)
{
    var response = await _httpClient.GetAsync(url).ConfigureAwait(false);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadAsStringAsync().ConfigureAwait(false);
}
```

### Nullable Reference Types

Enabling nullable reference types (`<Nullable>enable</Nullable>` in .csproj) makes the compiler track nullability. Annotate reference types as nullable (`string?`) when null is a valid value. Use the null-conditional operator (`?.`) to safely dereference, and the null-coalescing operator (`??`) to provide defaults. Avoid the null-forgiving operator (`!`) except when the compiler cannot infer non-nullability.

```csharp
#nullable enable

public record UserProfile(string Name, string? Bio);

public string GetDisplayBio(UserProfile? profile)
{
    // Null-conditional + null-coalescing: safe and concise
    return profile?.Bio ?? "No bio provided";
}

public void ProcessProfile(UserProfile profile)
{
    // Use 'is not null' pattern instead of != null for cleaner intent
    if (profile.Bio is not null)
    {
        Console.WriteLine(profile.Bio.Trim());
    }
}
```

### Records — Immutable Value Objects

Records provide concise syntax for immutable data types with value equality, built-in `ToString`, and nondestructive mutation via `with`. Use `record class` for reference types with value semantics (DTOs, query results, domain events). Use `record struct` for small, stack-allocated value types.

```csharp
// Positional record — compiler generates constructor, properties, Equals, GetHashCode, ToString
public record Address(string Street, string City, string PostalCode);

// Nondestructive mutation with 'with' expression
public record Order(int Id, string Status, Address DeliveryAddress);

var original = new Order(1, "Pending", new Address("123 Main St", "Seattle", "98101"));
var updated = original with { Status = "Shipped" };

Console.WriteLine(original.Status);   // Pending
Console.WriteLine(updated.Status);    // Shipped
Console.WriteLine(original == updated); // False — value equality compares all properties

// Record with computed property — compute on access, not initialization
public record Circle(double Radius)
{
    public double Area => Math.PI * Radius * Radius;  // NOT: = Math.PI * Radius * Radius
}
```

### Primary Constructors

C# 12 introduced primary constructors for classes and structs (not just records). Parameters become scoped to the class body, reducing boilerplate for dependency injection and simple initialization.

```csharp
// Primary constructor for a service class — parameters available throughout
public class OrderService(
    IOrderRepository repository,
    ILogger<OrderService> logger,
    IEventBus eventBus)
{
    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        logger.LogInformation("Creating order for customer {CustomerId}", request.CustomerId);
        var order = new Order(request.CustomerId, request.Items);
        await repository.SaveAsync(order);
        await eventBus.PublishAsync(new OrderCreatedEvent(order.Id));
        return order;
    }
}
```

### Extension Methods

Extension methods add functionality to types you don't own without subclassing. Use them for utility operations on domain objects, fluent API builders, and IEnumerable pipelines. Place them in a separate static class, typically in a `Extensions` namespace.

```csharp
public static class StringExtensions
{
    public static bool IsNullOrWhiteSpace(this string? value) =>
        string.IsNullOrWhiteSpace(value);

    public static string Truncate(this string value, int maxLength) =>
        value.Length <= maxLength ? value : value[..maxLength] + "...";

    public static string ToTitleCase(this string value) =>
        System.Globalization.CultureInfo.CurrentCulture.TextInfo.ToTitleCase(value.ToLower());
}

// Usage reads naturally as a method on the string
string title = "hello world".ToTitleCase();                  // "Hello World"
string preview = "Long article body text here".Truncate(10); // "Long artic..."
```

### Pattern Matching

C# pattern matching replaces long if-else chains and type-casting boilerplate with concise, compiler-validated switch expressions. The compiler warns when switch arms are unreachable or when input is not fully handled. Use property patterns, relational patterns, and logical combinators for expressive data-driven logic.

```csharp
// Switch expression with property pattern and relational pattern
public decimal CalculateShipping(Order order) => order switch
{
    { Status: "Cancelled" } => 0m,
    { Items.Count: 0 } => throw new ArgumentException("Order has no items"),
    { Total: > 100m, DeliveryAddress.Country: "US" } => 0m,    // free shipping
    { Total: >= 50m } => 4.99m,
    { Total: < 50m, DeliveryAddress.Country: not "US" } => 19.99m,
    _ => 9.99m
};

// Relational + logical patterns for range checks
string ClassifyBmi(double bmi) => bmi switch
{
    < 18.5 => "Underweight",
    >= 18.5 and < 25.0 => "Normal",
    >= 25.0 and < 30.0 => "Overweight",
    >= 30.0 => "Obese",
    double.NaN => "Invalid",
    _ => "Unknown"
};

// List pattern matching on CSV data
decimal ParseTransaction(string[] fields) => fields switch
{
    [_, "DEPOSIT", _, var amount]     => decimal.Parse(amount),
    [_, "WITHDRAWAL", .., var amount] => -decimal.Parse(amount),
    [_, "FEE", var fee]               => -decimal.Parse(fee),
    _ => throw new InvalidOperationException($"Unknown transaction format")
};
```

### Dependency Injection (IServiceCollection)

.NET's built-in DI container (`Microsoft.Extensions.DependencyInjection`) is the standard way to wire dependencies. Register services at startup using `AddSingleton`, `AddScoped`, or `AddTransient`. Inject via constructor parameters. Never resolve services manually with `IServiceProvider` inside business logic (service locator anti-pattern).

```csharp
// Registration — startup/Program.cs
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddSingleton<IEventBus, InMemoryEventBus>();
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();

// Multiple implementations of same interface — keyed services (.NET 8+)
builder.Services.AddKeyedSingleton<IPaymentProcessor, StripeProcessor>("stripe");
builder.Services.AddKeyedSingleton<IPaymentProcessor, PayPalProcessor>("paypal");

// Consumer — receives the correct implementation via constructor injection
public class CheckoutService(
    IOrderService orderService,
    [FromKeyedServices("stripe")] IPaymentProcessor paymentProcessor,
    ILogger<CheckoutService> logger)
{
    public async Task<CheckoutResult> ProcessAsync(CartSummary cart)
    {
        logger.LogInformation("Processing checkout for cart {CartId}", cart.Id);
        var order = await orderService.CreateOrderAsync(cart);
        return await paymentProcessor.ChargeAsync(order);
    }
}
```

---

## Language Idioms

These are C#-specific features that make code more expressive — not generic OOP patterns rephrased in C#.

### String Interpolation and Raw String Literals

Prefer `$"..."` over `string.Format(...)` or concatenation. For multi-line strings with special characters, use raw string literals (`""" ... """`), which do not require escaping.

```csharp
string name = "World";
string greeting = $"Hello, {name}!";

// Raw string literal — no escaping needed for \n, \t, JSON, regex
string json = """
    {
        "message": "Hello\nWorld",
        "regex": "^\d{3}-\d{4}$"
    }
    """;
```

### Collection Expressions (C# 12)

Use collection expressions (`[...]`) to initialize any collection type uniformly. Works for arrays, `List<T>`, `ImmutableArray<T>`, `Span<T>`, and more.

```csharp
string[] vowels = ["a", "e", "i", "o", "u"];
List<int> primes = [2, 3, 5, 7, 11];

// Spread operator combines collections
int[] first = [1, 2, 3];
int[] second = [4, 5, 6];
int[] combined = [..first, ..second];  // [1, 2, 3, 4, 5, 6]
```

### File-Scoped Namespaces

In files with a single namespace, use file-scoped namespace declarations to reduce indentation across the entire file.

```csharp
// Instead of wrapping entire file in namespace { }
namespace MyApp.Services;

public class OrderService { }
public class InvoiceService { }
```

### `using` Declaration for Disposables

The braceless `using` declaration disposes the resource at the end of the enclosing scope without extra indentation.

```csharp
// Old: using statement with braces
using (var connection = new SqlConnection(connectionString))
{
    // ...
}

// New: using declaration — disposed at end of method
using var connection = new SqlConnection(connectionString);
using var command = new SqlCommand(query, connection);
await connection.OpenAsync();
var result = await command.ExecuteScalarAsync();
```

### `var` for Obvious Types and Anonymous Results

Use `var` when the type is evident from the right-hand side (constructor calls, casts, LINQ projections). Use explicit types in `foreach` loops and when the type is not obvious from context.

```csharp
var user = new User { Id = 1, Name = "Alice" };          // obvious: constructor
var count = users.Count(u => u.IsActive);                 // NOT obvious → use int
foreach (User user in GetActiveUsers()) { }               // explicit type in foreach
var projection = users.Select(u => new { u.Id, u.Name }); // required for anonymous
```

### `required` Properties and `init` Accessors

Mark properties as `required` to force initialization at construction time. Use `init` to allow setting only during object initializer, making properties effectively immutable after construction.

```csharp
public class OrderRequest
{
    public required int CustomerId { get; init; }
    public required List<OrderItem> Items { get; init; }
    public string? PromoCode { get; init; }
}

var request = new OrderRequest
{
    CustomerId = 42,
    Items = [new OrderItem("SKU-001", 2)]
};
// request.CustomerId = 99;  // Compile error: init-only property
```

---

## Real-World Gotchas  [community]

### **async void** — Fire-and-Forget Exception Swallower  [community]

Using `async void` outside event handlers means exceptions are unobserved and crash the process silently on some runtimes, with no stack trace in logs. WHY it causes problems: exceptions thrown from `async void` methods are posted to the thread's synchronization context and cannot be caught with `try/catch` by the caller. Fix: always return `Task` from async methods. For background work, use `IHostedService` or `BackgroundService`.

```csharp
// BAD: exceptions disappear silently
private async void FireAndForget() => await DoWorkAsync();

// GOOD: return Task, let the caller handle or propagate
private async Task DoWorkAsync() => await _repository.SaveAsync();
```

### **.Result and .Wait() — Sync-over-Async Deadlock**  [community]

Calling `.Result` or `.Wait()` on a Task in an ASP.NET Core request context blocks the thread while holding the synchronization context lock. If the awaited async method tries to resume on the same context, it deadlocks. WHY it causes problems: ASP.NET (non-Core) and UI frameworks have a single-threaded synchronization context; the continuation cannot resume because the thread is blocked waiting for it. Fix: `await` all the way up, or use `ConfigureAwait(false)` in library code.

```csharp
// BAD: deadlock in ASP.NET / WPF
var data = GetDataAsync().Result;

// GOOD: await properly
var data = await GetDataAsync();
```

### **Captured Loop Variables in Lambdas**  [community]

Capturing a loop variable in a lambda captures the variable itself, not its value at the time the lambda is created. When the lambda executes, it reads the current (final) value of the variable. WHY it causes problems: all closures share a single variable, so they all see the last value after the loop completes. Fix: copy the loop variable to a local variable inside the loop before capturing.

```csharp
// BAD: all lambdas capture the same 'i', print 10, 10, 10...
var actions = new List<Action>();
for (int i = 0; i < 10; i++)
    actions.Add(() => Console.WriteLine(i));

// GOOD: capture a copy
for (int i = 0; i < 10; i++)
{
    int captured = i;
    actions.Add(() => Console.WriteLine(captured));
}
```

### **DI Lifetime Mismatch — Scoped in Singleton**  [community]

Injecting a Scoped service into a Singleton causes the Scoped service to behave as a Singleton because the Singleton outlives the scope. WHY it causes problems: DbContext (a Scoped service) holds an internal unit-of-work state. As a Singleton, it accumulates changes across all requests without flushing, leading to data corruption and thread-safety violations. Fix: inject `IServiceScopeFactory` in Singletons and create a scope explicitly per operation. The .NET runtime validates this in Development mode.

```csharp
// BAD: DbContext captured for app lifetime
public class DataProcessor(AppDbContext dbContext) { }  // registered Singleton!

// GOOD: create a scope for each operation
public class DataProcessor(IServiceScopeFactory scopeFactory)
{
    public async Task ProcessAsync()
    {
        using var scope = scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        // dbContext is properly scoped to this operation
    }
}
```

### **LINQ Deferred Execution — Enumerating Twice**  [community]

LINQ queries are lazy — they execute each time they are enumerated. Calling `.Count()` then `foreach` on the same `IQueryable` hits the database twice. Passing an `IEnumerable<T>` to a method that enumerates it multiple times multiplies the work. WHY it causes problems: unexpected N database roundtrips, or O(N^2) behaviour for in-memory queries. Fix: materialize with `.ToList()` or `.ToArray()` when you need to use the results more than once.

```csharp
// BAD: two database trips
var query = _context.Orders.Where(o => o.IsActive);
int count = query.Count();          // Trip 1
foreach (var order in query) { }   // Trip 2

// GOOD: materialize once
var orders = _context.Orders.Where(o => o.IsActive).ToList();
int count = orders.Count;
foreach (var order in orders) { }
```

### **Nullable Reference Types Suppressed with !**  [community]

Using the null-forgiving operator (`!`) to silence nullable warnings without actually guaranteeing non-nullability introduces `NullReferenceException` at runtime in places the compiler promised were safe. WHY it causes problems: it defeats the entire purpose of the nullability analysis; bugs reappear in production that the type system was designed to prevent. Fix: handle the nullable case explicitly, restructure to provide a non-null value, or document clearly WHY null cannot occur at that point.

```csharp
// BAD: suppresses the warning, doesn't fix the bug
string value = GetMaybeNull()!.Trim();

// GOOD: handle the null case
string? raw = GetMaybeNull();
string value = raw?.Trim() ?? string.Empty;
```

### **string Concatenation in Loops — StringBuilder**  [community]

Concatenating strings with `+` in a loop allocates a new string on each iteration because strings are immutable. For 10,000 iterations, this creates 10,000 intermediate allocations. WHY it causes problems: O(N^2) memory and CPU usage for large N, causing GC pressure and noticeable latency spikes. Fix: use `StringBuilder` for loops, or LINQ's `string.Join` / `string.Concat` for static sequences.

```csharp
// BAD: O(N^2) allocations
string result = "";
foreach (var item in items) result += item + ", ";

// GOOD: O(N) with StringBuilder
var sb = new StringBuilder();
foreach (var item in items) sb.Append(item).Append(", ");
string result = sb.ToString();

// ALSO GOOD: for static sequences
string joined = string.Join(", ", items);
```

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `async void` (outside event handlers) | Exceptions are unobservable and crash the process | Return `Task` or `Task<T>` from all async methods |
| `.Result` / `.Wait()` on Tasks | Deadlocks in sync-context environments (ASP.NET, WPF) | `await` all the way up the call chain |
| Suppressing nullable warnings with `!` | Runtime `NullReferenceException` in "safe" code paths | Handle null explicitly with `?.`, `??`, or restructure |
| Service Locator (resolving from IServiceProvider in business logic) | Hides dependencies, makes testing hard | Inject all dependencies via constructor |
| Injecting Scoped into Singleton | Scoped service lives forever, causing data corruption | Inject `IServiceScopeFactory`, create scopes explicitly |
| LINQ without materializing (`ToList`) | Multiple enumerations hit DB or compute multiple times | Materialize with `.ToList()` when reusing results |
| `catch (Exception)` without filtering | Swallows every exception including `StackOverflowException` | Catch specific exception types; use exception filters |
| `string` concatenation in loops | O(N^2) allocations, GC pressure | Use `StringBuilder` or `string.Join` |
| Mutable public properties on domain objects | Invariants broken from outside the aggregate | Use `init`-only or private setters; expose methods |
| Using `dynamic` to avoid type complexity | Loses all compile-time safety and IDE tooling | Use generics, interfaces, or pattern matching |
