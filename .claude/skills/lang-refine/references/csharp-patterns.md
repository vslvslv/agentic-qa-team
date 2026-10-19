# C# Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 1 | score: 100/100 | date: 2026-04-27 -->

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

// GroupBy with aggregation — use method syntax for clarity
var salesByRegion = orders
    .GroupBy(o => o.Region)
    .Select(g => new
    {
        Region = g.Key,
        TotalSales = g.Sum(o => o.Total),
        OrderCount = g.Count(),
        AverageOrder = g.Average(o => o.Total)
    })
    .OrderByDescending(r => r.TotalSales)
    .ToList();

// SelectMany — flatten nested collections
var allTags = posts
    .SelectMany(p => p.Tags)
    .Distinct()
    .OrderBy(t => t)
    .ToList();

// Zip — pair two sequences element-by-element
var names = new[] { "Alice", "Bob", "Carol" };
var scores = new[] { 95, 87, 92 };
var leaderboard = names.Zip(scores, (name, score) => $"{name}: {score}");
```

### async/await + ConfigureAwait + CancellationToken

The Task Asynchronous Programming (TAP) model lets you write non-blocking I/O-bound code that reads like synchronous code. Await tasks instead of blocking with `.Result` or `.Wait()`. Start independent tasks before awaiting them to enable true concurrency. Use `ConfigureAwait(false)` in library code to avoid capturing the synchronization context. Pass `CancellationToken` through the entire async call chain to support cooperative cancellation.

```csharp
// Good: start independent tasks concurrently, then await results
public async Task<DashboardData> GetDashboardAsync(
    int userId,
    CancellationToken cancellationToken = default)
{
    var userTask = _userService.GetUserAsync(userId, cancellationToken);
    var ordersTask = _orderService.GetRecentOrdersAsync(userId, cancellationToken);
    var notificationsTask = _notificationService.GetUnreadAsync(userId, cancellationToken);

    // Await all at once — runs in ~max(each) time, not sum
    await Task.WhenAll(userTask, ordersTask, notificationsTask);

    return new DashboardData
    {
        User = await userTask,
        Orders = await ordersTask,
        Notifications = await notificationsTask
    };
}

// Library code: ConfigureAwait(false) avoids sync context capture
public async Task<string> FetchDataAsync(string url, CancellationToken ct = default)
{
    var response = await _httpClient.GetAsync(url, ct).ConfigureAwait(false);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
}

// Linked cancellation: combine caller token with an internal timeout
public async Task<Report> GenerateReportAsync(
    ReportRequest request,
    CancellationToken externalToken)
{
    using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
    using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(
        externalToken, timeoutCts.Token);
    try
    {
        return await _reportBuilder.BuildAsync(request, linkedCts.Token);
    }
    catch (OperationCanceledException) when (timeoutCts.IsCancellationRequested)
    {
        throw new TimeoutException("Report generation exceeded 30 seconds.");
    }
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

// ThrowIfNull guard for public API entry points
public void UpdateProfile(UserProfile profile, string newBio)
{
    ArgumentNullException.ThrowIfNull(profile);
    ArgumentException.ThrowIfNullOrWhiteSpace(newBio);
    // safe to use profile and newBio below without null checks
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

Console.WriteLine(original.Status);     // Pending
Console.WriteLine(updated.Status);      // Shipped
Console.WriteLine(original == updated); // False — value equality compares all properties

// Record with computed property — compute on access, not initialization
public record Circle(double Radius)
{
    // Correct: re-computed on each access after 'with' mutation
    public double Area => Math.PI * Radius * Radius;
    // Wrong: = Math.PI * Radius * Radius — cached at init, stale after 'with'
}

// Record struct for value type (stack-allocated, no heap pressure)
public readonly record struct Point(double X, double Y)
{
    public double Distance => Math.Sqrt(X * X + Y * Y);
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
    public async Task<Order> CreateOrderAsync(
        CreateOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        logger.LogInformation("Creating order for customer {CustomerId}", request.CustomerId);
        var order = new Order(request.CustomerId, request.Items);
        await repository.SaveAsync(order, cancellationToken);
        await eventBus.PublishAsync(new OrderCreatedEvent(order.Id), cancellationToken);
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

// Fluent builder extension on IServiceCollection — makes DI registration readable
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddOrderProcessing(this IServiceCollection services)
    {
        services.AddScoped<IOrderRepository, SqlOrderRepository>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddSingleton<IEventBus, InMemoryEventBus>();
        return services;
    }
}

// Usage reads naturally
builder.Services.AddOrderProcessing();
string title = "hello world".ToTitleCase();
string preview = "Long article body text here".Truncate(10);
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
    _ => "Unknown"
};

// List pattern matching on CSV data
decimal ParseTransaction(string[] fields) => fields switch
{
    [_, "DEPOSIT", _, var amount]     => decimal.Parse(amount),
    [_, "WITHDRAWAL", .., var amount] => -decimal.Parse(amount),
    [_, "FEE", var fee]               => -decimal.Parse(fee),
    _ => throw new InvalidOperationException("Unknown transaction format")
};

// Type pattern — dispatch by runtime type without casting
string Describe(object shape) => shape switch
{
    Circle c when c.Radius > 100 => $"Large circle, area={c.Area:F2}",
    Circle c               => $"Circle, radius={c.Radius}",
    Point { X: 0, Y: 0 }  => "Origin",
    Point p                => $"Point at ({p.X}, {p.Y})",
    null                   => "null",
    _                      => shape.GetType().Name
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

// BackgroundService needs IServiceScopeFactory to access scoped services safely
public sealed class ReportWorker(
    ILogger<ReportWorker> logger,
    IServiceScopeFactory scopeFactory)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using var scope = scopeFactory.CreateScope();
            var service = scope.ServiceProvider.GetRequiredService<IReportService>();
            await service.GenerateDailyReportAsync(stoppingToken);
            await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
        }
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

// Raw string literal — no escaping needed for \n, \t, JSON, regex, C# code
string json = """
    {
        "message": "Hello\nWorld",
        "regex": "^\d{3}-\d{4}$"
    }
    """;

// New in C# 13: \e escape sequence for ANSI escape codes
string bold = $"\e[1mBold text\e[0m";
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

### params Collections (C# 13)

`params` is no longer limited to arrays. Use it with `ReadOnlySpan<T>` for zero-allocation variadic arguments in hot paths.

```csharp
// C# 13: params on Span avoids array allocation at call site
public static int Sum(params ReadOnlySpan<int> values)
{
    int total = 0;
    foreach (var v in values) total += v;
    return total;
}

// Callers pass values naturally — no array created
int result = Sum(1, 2, 3, 4, 5);
```

### New `Lock` Type (C# 13 / .NET 9)

The new `System.Threading.Lock` type provides better thread synchronization semantics than locking on `object`. The `lock` statement recognizes `Lock` and uses the efficient `EnterScope()` API.

```csharp
// Old: lock on object — no semantic meaning, can be accidentally locked elsewhere
private readonly object _syncRoot = new();
lock (_syncRoot) { /* ... */ }

// New in .NET 9: Lock type — semantically clear, supports using pattern
private readonly Lock _lock = new();
lock (_lock) { /* compiler generates Lock.EnterScope(), not Monitor.Enter() */ }
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
// Old: using statement with braces adds a nesting level
using (var connection = new SqlConnection(connectionString))
{
    // ...
}

// New: using declaration — disposed at end of method/scope
using var connection = new SqlConnection(connectionString);
using var command = new SqlCommand(query, connection);
await connection.OpenAsync();
var result = await command.ExecuteScalarAsync();
```

### `var` for Obvious Types and Anonymous Results

Use `var` when the type is evident from the right-hand side (constructor calls, casts, LINQ projections). Use explicit types in `foreach` loops and when the type is not obvious from context.

```csharp
var user = new User { Id = 1, Name = "Alice" };           // obvious: constructor
var count = users.Count(u => u.IsActive);                  // NOT obvious → use int
foreach (User u in GetActiveUsers()) { }                   // explicit type in foreach
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

### `using` Aliases for Complex Types (C# 12)

In C# 12, `using` aliases can alias any type including tuples, arrays, and generic constructions — not just named types. Use this for self-documenting complex signatures.

```csharp
// Alias a tuple type for readable use throughout the file
using Coordinate = (double Latitude, double Longitude);
using ErrorCode = int;
using StringList = System.Collections.Generic.List<string>;

Coordinate home = (47.6062, -122.3321);
Console.WriteLine($"Lat: {home.Latitude}, Lon: {home.Longitude}");
```

### Index and Range Operators

Use `^` (from-end) and `..` (range) operators for expressive slice operations on arrays, spans, and strings.

```csharp
int[] numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

int last     = numbers[^1];         // 9
int[] last3  = numbers[^3..];       // [7, 8, 9]
int[] middle = numbers[2..5];       // [2, 3, 4]
int[] copy   = numbers[..];         // full copy

string path = "src/main/Program.cs";
string file = path[path.LastIndexOf('/') + 1..]; // "Program.cs"
```

### `ValueTask` for High-Throughput Async APIs

`ValueTask` is a struct that avoids heap allocation when an async operation completes synchronously (common in cache-hit scenarios, tight loops, etc.). Use it in hot paths. Constraints: a `ValueTask` can only be awaited once; do not store it and await it multiple times.

```csharp
// Use ValueTask when the operation often completes synchronously
public ValueTask<User?> GetUserAsync(int id, CancellationToken ct = default)
{
    // Cache hit — synchronous path, no heap allocation
    if (_cache.TryGetValue(id, out var cached))
        return ValueTask.FromResult<User?>(cached);

    // Cache miss — fall through to async path
    return FetchFromDatabaseAsync(id, ct);
}

private async ValueTask<User?> FetchFromDatabaseAsync(int id, CancellationToken ct)
{
    var user = await _db.Users.FindAsync(id, ct).ConfigureAwait(false);
    if (user is not null) _cache[id] = user;
    return user;
}
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

### **Missing CancellationToken in Async Methods**  [community]

Defining public async methods without a `CancellationToken` parameter makes them non-cooperative. WHY it causes problems: in web APIs and background services, requests can be cancelled (e.g., client disconnects, timeout). Without the token, the operation keeps running after the response is already abandoned, wasting CPU, DB connections, and memory. Fix: always add `CancellationToken ct = default` to every public async method signature and thread it through all downstream calls.

```csharp
// BAD: cannot be cancelled — keeps running even after HTTP client disconnects
public async Task<IEnumerable<Product>> SearchAsync(string query)
{
    var items = await _db.Products.Where(p => p.Name.Contains(query)).ToListAsync();
    return items;
}

// GOOD: caller passes token; downstream DB and HTTP calls respect it
public async Task<IEnumerable<Product>> SearchAsync(
    string query,
    CancellationToken cancellationToken = default)
{
    return await _db.Products
        .Where(p => p.Name.Contains(query))
        .ToListAsync(cancellationToken);
}
```

### **Record Immutability Is Shallow**  [community]

Records with `init`-only properties appear immutable but are only shallowly so. WHY it causes problems: a property of type `List<T>` or `string[]` on a record can have its contents mutated from outside, breaking the invariant that the record is a stable snapshot. Fix: use immutable collection types (`IReadOnlyList<T>`, `ImmutableArray<T>`) for collection properties on records, or copy on construction.

```csharp
// BAD: record appears immutable, but list is mutable from outside
public record Order(int Id, List<OrderItem> Items);
var order = new Order(1, new List<OrderItem> { new("SKU-1") });
order.Items.Add(new OrderItem("SKU-2")); // mutates "immutable" record!

// GOOD: use IReadOnlyList or ImmutableArray
public record Order(int Id, IReadOnlyList<OrderItem> Items);
```

### **ValueTask Awaited Multiple Times**  [community]

`ValueTask` is a struct that can wrap either a completed result or an `IValueTaskSource`. Awaiting it more than once gives undefined behavior. WHY it causes problems: the underlying `IValueTaskSource` implementation may reuse the object for a different operation by the time you await it a second time, leading to wrong results or exceptions. Fix: if you need to await the same operation's result multiple times, call `.AsTask()` once and store the `Task`.

```csharp
// BAD: ValueTask awaited twice — undefined behavior
ValueTask<int> vt = GetValueAsync();
int a = await vt;
int b = await vt;  // BUG: vt may be stale or recycled

// GOOD: convert to Task when multiple awaits are needed
Task<int> t = GetValueAsync().AsTask();
int a = await t;
int b = await t;  // safe — Task caches the result
```

### **IDisposable Not Cascaded — Resource Leak**  [community]

A class that holds an `IDisposable` field and doesn't implement `IDisposable` itself leaks the held resource until the GC finalizes it (non-deterministic, may never happen for OS handles). WHY it causes problems: connection pool exhaustion, file handle leaks, and memory leaks accumulate silently under load. Fix: implement `IDisposable` on any class that owns `IDisposable` fields, and cascade `Dispose()` to each owned resource.

```csharp
// BAD: SqlConnection never explicitly disposed — connection pool exhausted over time
public class DataLoader
{
    private readonly SqlConnection _conn = new(connectionString);
    public async Task<List<Row>> LoadAsync(CancellationToken ct) { /* uses _conn */ return []; }
}

// GOOD: implement IDisposable and cascade
public sealed class DataLoader : IDisposable
{
    private readonly SqlConnection _conn = new(connectionString);
    public async Task<List<Row>> LoadAsync(CancellationToken ct) { /* uses _conn */ return []; }
    public void Dispose() => _conn.Dispose();
}
// Caller: using var loader = new DataLoader();
```

### **IAsyncEnumerable — Async Streams**  [community]

Returning `Task<List<T>>` for streaming data loads all records into memory before the first item can be processed. `IAsyncEnumerable<T>` with `await foreach` lets consumers process items as they arrive, reducing memory usage and improving time-to-first-result. WHY it matters: a paginated API that returns 10,000 rows does not need to buffer everything — stream each page as it arrives.

```csharp
// Producer: yield individual items from paginated API
public async IAsyncEnumerable<Issue> GetIssuesAsync(
    string repo,
    [EnumeratorCancellation] CancellationToken ct = default)
{
    string? cursor = null;
    bool hasMore = true;
    while (hasMore)
    {
        var page = await _api.FetchPageAsync(repo, cursor, ct);
        foreach (var issue in page.Items)
            yield return issue;
        hasMore = page.HasNextPage;
        cursor = page.NextCursor;
    }
}

// Consumer: process items as they arrive — no buffering
await foreach (var issue in _service.GetIssuesAsync("dotnet/docs", ct)
    .WithCancellation(ct)
    .ConfigureAwait(false))
{
    await ProcessIssueAsync(issue, ct);
}
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
| Public async method without `CancellationToken` | Cannot be cancelled; wastes resources after request ends | Add `CancellationToken ct = default` to every async signature |
| Locking on `this` or public objects | External code can acquire the same lock, causing deadlocks | Use a private `readonly object` field or `Lock` (.NET 9+) |
| Returning `Task<List<T>>` for large result sets | Buffers entire result in memory before first item is returned | Use `IAsyncEnumerable<T>` with `await foreach` for streaming |
| Awaiting `ValueTask` more than once | Undefined behavior — underlying source may be recycled | Call `.AsTask()` once and store the `Task` if multiple awaits needed |
| Class owns `IDisposable` but doesn't implement it | Resource leak — GC finalization is non-deterministic | Implement `IDisposable` and cascade `Dispose()` to owned fields |
