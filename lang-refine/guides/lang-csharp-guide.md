# C# Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 3 | score: 100/100 | date: 2026-04-30 -->

## Core Philosophy

1. **Readability over cleverness** — C# code should read like a sequence of intent-revealing statements. `async`/`await`, pattern matching, and LINQ are tools for clarity, not puzzles to impress colleagues.
2. **Immutability by default** — Use records, `init`-only properties, and `readonly` fields. Mutability should be deliberate and documented.
3. **Type safety is your ally** — Nullable reference types, generics, and the type system catch bugs at compile time. Fight the urge to use `object`, `dynamic`, or suppress nullable warnings with `!`.
4. **Composition over inheritance** — Prefer interfaces, extension methods, and small composable types. Deep class hierarchies lead to fragile base class problems and tight coupling.
5. **Async all the way down** — Mixing sync and async code causes deadlocks in ASP.NET Core. Async is viral by nature; design the full call chain before writing the first method.

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

// GroupBy with aggregation
var salesByRegion = orders
    .GroupBy(o => o.Region)
    .Select(g => new
    {
        Region    = g.Key,
        Total     = g.Sum(o => o.Total),
        Count     = g.Count(),
        Average   = g.Average(o => o.Total)
    })
    .OrderByDescending(r => r.Total)
    .ToList();

// SelectMany — flatten nested collections
var allTags = posts
    .SelectMany(p => p.Tags)
    .Distinct()
    .OrderBy(t => t)
    .ToList();
```

### async/await + ConfigureAwait + CancellationToken

The Task Asynchronous Programming (TAP) model lets you write non-blocking I/O-bound code that reads like synchronous code. Await tasks instead of blocking with `.Result` or `.Wait()`. Start independent tasks before awaiting them to enable true concurrency. Use `ConfigureAwait(false)` in library code. Pass `CancellationToken` through the entire async call chain.

```csharp
// Start independent tasks concurrently — runs in ~max(each) time, not sum
public async Task<DashboardData> GetDashboardAsync(
    int userId,
    CancellationToken ct = default)
{
    var userTask          = _userService.GetUserAsync(userId, ct);
    var ordersTask        = _orderService.GetRecentOrdersAsync(userId, ct);
    var notificationsTask = _notificationService.GetUnreadAsync(userId, ct);

    await Task.WhenAll(userTask, ordersTask, notificationsTask);

    return new DashboardData
    {
        User          = await userTask,
        Orders        = await ordersTask,
        Notifications = await notificationsTask
    };
}

// Library code: ConfigureAwait(false) avoids sync context capture
public async Task<string> FetchAsync(string url, CancellationToken ct = default)
{
    var response = await _http.GetAsync(url, ct).ConfigureAwait(false);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
}

// Linked cancellation: combine caller token with internal timeout
public async Task<Report> GenerateReportAsync(
    ReportRequest request,
    CancellationToken externalCt)
{
    using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
    using var linkedCts  = CancellationTokenSource.CreateLinkedTokenSource(
                               externalCt, timeoutCts.Token);
    try
    {
        return await _builder.BuildAsync(request, linkedCts.Token);
    }
    catch (OperationCanceledException) when (timeoutCts.IsCancellationRequested)
    {
        throw new TimeoutException("Report generation exceeded 30 seconds.");
    }
}
```

### Nullable Reference Types

Enabling nullable reference types (`<Nullable>enable</Nullable>` in .csproj) makes the compiler track nullability. Annotate reference types as nullable (`string?`) when null is a valid value. Use `?.` for safe dereference and `??` for defaults.

```csharp
#nullable enable

public record UserProfile(string Name, string? Bio);

// Null-conditional + null-coalescing: safe and concise
public string GetDisplayBio(UserProfile? profile)
    => profile?.Bio ?? "No bio provided";

// 'is not null' pattern — clearer intent than != null
public void ProcessProfile(UserProfile profile)
{
    if (profile.Bio is not null)
        Console.WriteLine(profile.Bio.Trim());
}

// ThrowIfNull / ThrowIfNullOrWhiteSpace guards at public API entry points
public void UpdateProfile(UserProfile profile, string newBio)
{
    ArgumentNullException.ThrowIfNull(profile);
    ArgumentException.ThrowIfNullOrWhiteSpace(newBio);
    // safe below — compiler knows both are non-null
}
```

### Records — Immutable Value Objects

Records provide concise syntax for immutable data types with value equality, `ToString`, and nondestructive mutation via `with`. Use `record class` for DTOs, query results, and domain events. Use `record struct` for small, stack-allocated value types.

```csharp
// Positional record — compiler generates constructor, Equals, GetHashCode, ToString
public record Address(string Street, string City, string PostalCode);

// Nondestructive mutation with 'with'
public record Order(int Id, string Status, Address DeliveryAddress);

var original = new Order(1, "Pending", new Address("123 Main St", "Seattle", "98101"));
var shipped  = original with { Status = "Shipped" };

Console.WriteLine(original.Status);           // Pending
Console.WriteLine(shipped.Status);            // Shipped
Console.WriteLine(original == shipped);       // False — value equality

// Computed property: use => not =  (avoids stale cache after 'with')
public record Circle(double Radius)
{
    public double Area => Math.PI * Radius * Radius;   // correct: re-computed
}

// record struct for stack-allocated value type
public readonly record struct Point(double X, double Y)
{
    public double Distance => Math.Sqrt(X * X + Y * Y);
}
```

### Primary Constructors (C# 12)

C# 12 introduced primary constructors for classes and structs. Parameters become scoped to the class body, reducing boilerplate for dependency injection and simple initialization.

```csharp
// Primary constructor — parameters available throughout the class body
public class OrderService(
    IOrderRepository  repository,
    ILogger<OrderService> logger,
    IEventBus         eventBus)
{
    public async Task<Order> CreateOrderAsync(
        CreateOrderRequest request,
        CancellationToken  ct = default)
    {
        logger.LogInformation("Creating order for {CustomerId}", request.CustomerId);
        var order = new Order(request.CustomerId, request.Items);
        await repository.SaveAsync(order, ct);
        await eventBus.PublishAsync(new OrderCreatedEvent(order.Id), ct);
        return order;
    }
}
```

### Extension Methods

Extension methods add functionality to types you don't own without subclassing. Use them for utility operations, fluent API builders, and `IEnumerable` pipelines.

```csharp
public static class StringExtensions
{
    public static bool IsNullOrWhiteSpace(this string? value)
        => string.IsNullOrWhiteSpace(value);

    public static string Truncate(this string value, int maxLength)
        => value.Length <= maxLength ? value : value[..maxLength] + "...";

    public static string ToTitleCase(this string value)
        => System.Globalization.CultureInfo.CurrentCulture
               .TextInfo.ToTitleCase(value.ToLower());
}

// Fluent DI registration via extension on IServiceCollection
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
string title   = "hello world".ToTitleCase();
string preview = "Long article body text here".Truncate(10);
```

### Pattern Matching

C# pattern matching replaces long if-else chains and casting boilerplate with concise, compiler-validated switch expressions. The compiler warns when arms are unreachable or when input is not fully handled.

```csharp
// Switch expression with property and relational patterns
public decimal CalculateShipping(Order order) => order switch
{
    { Status: "Cancelled" }                                  => 0m,
    { Items.Count: 0 }                                       => throw new ArgumentException("No items"),
    { Total: > 100m, DeliveryAddress.Country: "US" }         => 0m,
    { Total: >= 50m }                                        => 4.99m,
    { Total: < 50m, DeliveryAddress.Country: not "US" }      => 19.99m,
    _                                                        => 9.99m
};

// Relational + logical patterns for range checks
string ClassifyBmi(double bmi) => bmi switch
{
    < 18.5                  => "Underweight",
    >= 18.5 and < 25.0      => "Normal",
    >= 25.0 and < 30.0      => "Overweight",
    >= 30.0                 => "Obese",
    _                       => "Unknown"
};

// List pattern matching on CSV data
decimal ParseTransaction(string[] fields) => fields switch
{
    [_, "DEPOSIT",    _, var amount]     =>  decimal.Parse(amount),
    [_, "WITHDRAWAL", .., var amount]    => -decimal.Parse(amount),
    [_, "FEE",           var fee]        => -decimal.Parse(fee),
    _                                    => throw new InvalidOperationException("Unknown format")
};
```

### Dependency Injection (IServiceCollection)

.NET's built-in DI container is the standard way to wire dependencies. Register services at startup, inject via constructor. Never resolve from `IServiceProvider` inside business logic (service-locator anti-pattern).

```csharp
// Registration — Program.cs / startup
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddSingleton<IEventBus, InMemoryEventBus>();
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();

// Keyed services (.NET 8+) — multiple implementations of the same interface
builder.Services.AddKeyedSingleton<IPaymentProcessor, StripeProcessor>("stripe");
builder.Services.AddKeyedSingleton<IPaymentProcessor, PayPalProcessor>("paypal");

// BackgroundService needs IServiceScopeFactory for scoped services
public sealed class ReportWorker(
    ILogger<ReportWorker>  logger,
    IServiceScopeFactory   scopeFactory) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using var scope   = scopeFactory.CreateScope();
            var service       = scope.ServiceProvider.GetRequiredService<IReportService>();
            await service.GenerateDailyReportAsync(stoppingToken);
            await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
        }
    }
}
```

### Delegates — `Func<T>` and `Action<T>`

Use the built-in `Func<>` and `Action<>` delegate types rather than declaring custom delegate types. They communicate intent, are composable, and avoid polluting the type namespace.

```csharp
// Prefer Func<> and Action<> over custom delegate declarations
Action<string>          log         = msg  => Console.WriteLine($"[LOG] {msg}");
Func<string, int>       parseId     = text => int.Parse(text.Trim());
Func<int, int, int>     add         = (x, y) => x + y;

// Generic method that accepts any predicate
public static IEnumerable<T> Filter<T>(IEnumerable<T> source, Func<T, bool> predicate)
    => source.Where(predicate);

// Composable pipeline
Func<string, string> trim      = s => s.Trim();
Func<string, string> toLower   = s => s.ToLower();
Func<string, string> normalize = s => toLower(trim(s));

// Event handler shorthand — lambda instead of named method
button.Click += (sender, e) => HandleClick((Button)sender);
```

### IDisposable and IAsyncDisposable

Implement `IDisposable` on any class that owns unmanaged resources or `IDisposable` fields. Use `IAsyncDisposable` and `await using` for async resources such as database connections.

```csharp
// Standard Dispose pattern
public sealed class DataService : IDisposable
{
    private readonly SqlConnection _connection;
    private bool _disposed;

    public DataService(string connectionString)
        => _connection = new SqlConnection(connectionString);

    public async Task<List<Row>> QueryAsync(string sql, CancellationToken ct)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        await _connection.OpenAsync(ct);
        return [];
    }

    public void Dispose()
    {
        if (_disposed) return;
        _connection.Dispose();
        _disposed = true;
        GC.SuppressFinalize(this);
    }
}

// IAsyncDisposable for async resources
public sealed class AsyncDataService : IAsyncDisposable
{
    private readonly DbConnection _connection;
    public async ValueTask DisposeAsync()
    {
        await _connection.DisposeAsync();
        GC.SuppressFinalize(this);
    }
}

// Caller: await using automatically calls DisposeAsync
await using var svc = new AsyncDataService();
```

### CPU-Bound Async — `Task.Run`

Use `Task.Run` to offload CPU-intensive work to a thread-pool thread so the calling thread (UI or request handler) stays responsive. Do NOT use `Task.Run` for I/O-bound work — that wastes a thread-pool thread waiting for hardware. The rule: I/O-bound operations wait for hardware (await directly); CPU-bound operations compute (offload with `Task.Run`).

```csharp
// I/O-bound: await directly — no Task.Run needed
public async Task<string> FetchPageAsync(string url, CancellationToken ct)
    => await _httpClient.GetStringAsync(url, ct);

// CPU-bound: offload to thread pool with Task.Run
public async Task<byte[]> CompressImageAsync(byte[] imageBytes, CancellationToken ct)
{
    // Compression is CPU-intensive — offload so the caller stays responsive
    return await Task.Run(() => ImageCompressor.Compress(imageBytes), ct);
}

// UI event handler: keep the UI thread free during heavy computation
private async void OnCalculateClicked(object sender, EventArgs e)
{
    var result = await Task.Run(() => RunHeavySimulation(inputData));
    DisplayResult(result);
}

// RULE: never use Task.Run in library code — let callers decide threading strategy
// DO in app-level code (controllers, ViewModels); DON'T in shared library methods
```

---

## Language Idioms

These are C#-specific features that make code more expressive — not generic OOP patterns rephrased in C#.

### String Interpolation and Raw String Literals

Prefer `$"..."` over `string.Format(...)` or concatenation. For multi-line strings with special characters, use raw string literals (`""" ... """`), which need no escaping. C# 13 added the `\e` escape sequence for ANSI escape codes.

```csharp
string name     = "World";
string greeting = $"Hello, {name}!";

// Format specifiers inside interpolation
decimal price = 19.99m;
string formatted = $"Price: {price:C2}";                  // "Price: $19.99"
string padded    = $"ID: {id,6:D}";                       // right-align in 6 chars

// Raw string literal — no escaping for \n, JSON, regex, embedded C# code
string json = """
    {
        "message": "Hello\nWorld",
        "regex": "^\d{3}-\d{4}$"
    }
    """;

// Interpolated raw string literal — combines both
string report = $"""
    Order {orderId} for {customerName}
    Total: {total:C2}
    Status: {status}
    """;
```

### Collection Expressions (C# 12)

Use `[...]` to initialize any collection type uniformly. The spread operator `..` combines collections without allocation overhead.

```csharp
string[] vowels = ["a", "e", "i", "o", "u"];
List<int> primes = [2, 3, 5, 7, 11];

// Spread operator
int[] first    = [1, 2, 3];
int[] second   = [4, 5, 6];
int[] combined = [..first, ..second];   // [1, 2, 3, 4, 5, 6]
```

### `params` on `ReadOnlySpan<T>` (C# 13)

`params` is no longer limited to arrays — use it with `ReadOnlySpan<T>` for zero-allocation variadic arguments in hot paths.

```csharp
public static int Sum(params ReadOnlySpan<int> values)
{
    int total = 0;
    foreach (var v in values) total += v;
    return total;
}

int result = Sum(1, 2, 3, 4, 5);   // no array created at call site
```

### New `Lock` Type (C# 13 / .NET 9)

`System.Threading.Lock` gives better thread-synchronization semantics than locking on `object`. The `lock` statement recognizes `Lock` and uses the efficient `EnterScope()` API rather than `Monitor.Enter`/`Exit`. This prevents accidental external code from acquiring the same lock and makes the synchronization intent explicit to readers and IDE tooling.

```csharp
// Old pattern: lock on object — any code with a reference can lock it
public class Counter
{
    private readonly object _syncRoot = new();
    private int _value;

    public void Increment()
    {
        lock (_syncRoot) { _value++; }
    }

    public int Value { get { lock (_syncRoot) { return _value; } } }
}

// New pattern (.NET 9+): Lock type — compiler generates Lock.EnterScope()
public class Counter
{
    private readonly Lock _lock  = new();
    private int           _value;

    public void Increment()
    {
        lock (_lock) { _value++; }   // → Lock.EnterScope(), not Monitor.Enter
    }

    public int Value { get { lock (_lock) { return _value; } } }
}
```

### File-Scoped Namespaces

In files with a single namespace, use file-scoped namespace declarations to remove one level of indentation across the entire file. This is the recommended style for all new files in .NET 6+.

```csharp
// BEFORE: traditional namespace wraps entire file in a block
namespace MyApp.Services
{
    public class OrderService { }
    public class InvoiceService { }
}

// AFTER: file-scoped — saves one level of indentation for every line in the file
namespace MyApp.Services;

public class OrderService  { }
public class InvoiceService { }

// Multiple top-level types are supported; each belongs to the same namespace
public interface IOrderService { }
```

### `using` Declaration for Disposables

The braceless `using` declaration disposes the resource at the end of the enclosing scope without extra nesting.

```csharp
// Old: nesting level added by using statement
using (var connection = new SqlConnection(connectionString))
{
    // use connection
}

// New: using declaration — disposed at end of method/scope
using var connection = new SqlConnection(connectionString);
using var command    = new SqlCommand(query, connection);
await connection.OpenAsync();
var result = await command.ExecuteScalarAsync();
```

### `var` Usage Rules

Use `var` when the type is evident from the right-hand side (constructor calls, casts, LINQ projections with anonymous types). Use explicit types in `foreach` loops and when the type would otherwise be ambiguous.

```csharp
var user       = new User { Id = 1, Name = "Alice" };              // obvious: constructor
int count      = users.Count(u => u.IsActive);                     // NOT obvious — use int
foreach (User u in GetActiveUsers()) { }                           // explicit in foreach
var projection = users.Select(u => new { u.Id, u.Name });          // required for anonymous
```

### `required` Properties and `init` Accessors

Mark properties as `required` to force initialization at construction time. Use `init` to allow setting only during the object initializer, making properties effectively immutable after construction.

```csharp
public class OrderRequest
{
    public required int          CustomerId { get; init; }
    public required List<OrderItem> Items   { get; init; }
    public string?               PromoCode  { get; init; }
}

var request = new OrderRequest
{
    CustomerId = 42,
    Items      = [new OrderItem("SKU-001", 2)]
};
// request.CustomerId = 99;  // Compile error: init-only property
```

### `using` Aliases for Complex Types (C# 12)

`using` aliases can now alias any type — tuples, arrays, generic constructions — not just named types. Use this for self-documenting complex signatures.

```csharp
using Coordinate = (double Latitude, double Longitude);
using StringList = System.Collections.Generic.List<string>;

Coordinate home = (47.6062, -122.3321);
Console.WriteLine($"Lat: {home.Latitude}, Lon: {home.Longitude}");
```

### Index and Range Operators

Use `^` (from-end) and `..` (range) for expressive slice operations on arrays, spans, and strings.

```csharp
int[] numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

int   last   = numbers[^1];         // 9
int[] last3  = numbers[^3..];       // [7, 8, 9]
int[] middle = numbers[2..5];       // [2, 3, 4]

string path = "src/main/Program.cs";
string file = path[path.LastIndexOf('/') + 1..];   // "Program.cs"
```

### `ValueTask` for High-Throughput Async APIs

`ValueTask` avoids heap allocation when an async operation completes synchronously (cache-hit scenarios, tight loops). Use in hot paths. Constraint: a `ValueTask` can only be awaited once.

```csharp
// Returns ValueTask — allocates nothing on cache hit
public ValueTask<User?> GetUserAsync(int id, CancellationToken ct = default)
{
    if (_cache.TryGetValue(id, out var cached))
        return ValueTask.FromResult<User?>(cached);

    return FetchFromDatabaseAsync(id, ct);
}

private async ValueTask<User?> FetchFromDatabaseAsync(int id, CancellationToken ct)
{
    var user = await _db.Users.FindAsync(id, ct).ConfigureAwait(false);
    if (user is not null) _cache[id] = user;
    return user;
}
```

### `Span<T>` and `Memory<T>` for Zero-Allocation Buffer Operations

`Span<T>` is a stack-only ref struct providing a view over contiguous memory without allocation. Use for synchronous parsing in hot paths. Use `Memory<T>` when the buffer reference crosses `await` points.

```csharp
// Parse CSV ints without string allocation
static int SumCsvInts(ReadOnlySpan<char> input)
{
    int total = 0;
    int start = 0;
    for (int i = 0; i <= input.Length; i++)
    {
        if (i == input.Length || input[i] == ',')
        {
            if (int.TryParse(input[start..i], out int v)) total += v;
            start = i + 1;
        }
    }
    return total;
}

// stackalloc for small buffers — no heap allocation
Span<byte> buffer  = stackalloc byte[256];
int        written = Encoding.UTF8.GetBytes("Hello, World!", buffer);

// Memory<T> for async scenarios — survives await
public async Task ProcessBufferAsync(Memory<byte> buffer, CancellationToken ct)
{
    await _stream.ReadAsync(buffer, ct);
    ParseHeader(buffer.Span);
}
```

### Generic Constraints — `where T :` Clauses

Generic constraints unlock type-safe generic algorithms. Use `where T : IEquatable<T>` or `where T : IComparable<T>` for equality/ordering without boxing.

```csharp
// IEquatable<T> constraint: type-safe, no boxing
public static bool AreEqual<T>(T a, T b) where T : IEquatable<T>
    => a.Equals(b);

// Multiple constraints: reference type, interface, new()
public class Repository<T> where T : class, IEntity, new()
{
    public T Create()     => new T();
    public T? FindById(int id) => _items.FirstOrDefault(e => e.Id == id);
}

// notnull: excludes nullable reference types and Nullable<T>
public static T RequireValue<T>(T? value, string name) where T : notnull
{
    ArgumentNullException.ThrowIfNull(value, name);
    return value;
}

// enum constraint: type-safe enum operations
public static string GetEnumName<T>(T value) where T : struct, Enum
    => Enum.GetName(value) ?? value.ToString();
```

### `IAsyncEnumerable<T>` — Async Streams

`IAsyncEnumerable<T>` with `await foreach` lets consumers process items as they arrive from a paginated API or database cursor, reducing peak memory usage versus buffering everything into a `List<T>`.

```csharp
// Producer: yield items from paginated API
public async IAsyncEnumerable<Issue> GetIssuesAsync(
    string repo,
    [EnumeratorCancellation] CancellationToken ct = default)
{
    string? cursor  = null;
    bool    hasMore = true;
    while (hasMore)
    {
        var page = await _api.FetchPageAsync(repo, cursor, ct);
        foreach (var issue in page.Items)
            yield return issue;
        hasMore = page.HasNextPage;
        cursor  = page.NextCursor;
    }
}

// Consumer: process as items arrive, no buffering
await foreach (var issue in _service.GetIssuesAsync("dotnet/docs", ct))
    await ProcessIssueAsync(issue, ct);
```

### `Task.WhenAny` — Racing Tasks and Timeouts

`Task.WhenAny` returns as soon as the first of the supplied tasks completes. Use it to implement racing (return the first successful result), timeouts (race the real work against `Task.Delay`), and progress processing in order-of-completion rather than declaration order.

```csharp
// Timeout pattern: race the real work against a delay task
public async Task<Result> WithTimeoutAsync(
    Task<Result> workTask,
    TimeSpan     timeout,
    CancellationToken ct)
{
    var timeoutTask = Task.Delay(timeout, ct);
    var winner      = await Task.WhenAny(workTask, timeoutTask);

    if (winner == timeoutTask)
        throw new TimeoutException($"Operation exceeded {timeout.TotalSeconds}s.");

    return await workTask;   // re-await to surface any exception from workTask
}

// Process tasks in order-of-completion, not declaration order
public async Task ProcessInCompletionOrderAsync(IEnumerable<int> ids, CancellationToken ct)
{
    var remaining = ids.Select(id => FetchAsync(id, ct)).ToList();
    while (remaining.Count > 0)
    {
        var done = await Task.WhenAny(remaining);
        remaining.Remove(done);
        var result = await done;   // re-await to propagate exceptions
        Console.WriteLine($"Processed: {result}");
    }
}
```

### `Lazy<T>` — Thread-Safe Deferred Initialization

`Lazy<T>` defers construction of an expensive object until first access. The default `LazyThreadSafetyMode.ExecutionAndPublication` ensures the factory runs only once even under concurrent access. Use when initialization is expensive and the object may never be needed.

```csharp
// Lazy singleton — factory runs once, result cached forever
private readonly Lazy<ExpensiveService> _service =
    new(() => new ExpensiveService(connectionString),
        LazyThreadSafetyMode.ExecutionAndPublication);

public ExpensiveService Service => _service.Value;

// In DI-registered services, prefer constructor injection over Lazy<T>
// Use Lazy<T> only when initialization cost is significant and access is rare:
public class ReportGenerator(Lazy<IReportEngine> engine)
{
    public async Task<Report> GenerateAsync(ReportRequest request, CancellationToken ct)
    {
        // engine.Value is resolved only when the first report is generated
        return await engine.Value.BuildAsync(request, ct);
    }
}
```

---

## Real-World Gotchas  [community]

### **`async void` — Fire-and-Forget Exception Swallower**  [community]

Using `async void` outside event handlers means exceptions are unobserved and crash the process silently. WHY: exceptions thrown from `async void` are posted to the thread's synchronization context and cannot be caught with `try/catch` by the caller. Fix: always return `Task`; for background work use `IHostedService` or `BackgroundService`.

```csharp
// BAD: exceptions disappear silently
private async void FireAndForget() => await DoWorkAsync();

// GOOD: return Task — caller can await and catch
private async Task DoWorkAsync() => await _repository.SaveAsync();
```

### **`.Result` / `.Wait()` — Sync-over-Async Deadlock**  [community]

Calling `.Result` or `.Wait()` on a Task in an ASP.NET Core or WPF context blocks the thread while holding the synchronization context lock. If the awaited async method tries to resume on the same context, it deadlocks. WHY: single-threaded sync contexts cannot resume the continuation because the thread is blocked waiting for it. Fix: `await` all the way up, or use `ConfigureAwait(false)` in library code.

```csharp
// BAD: deadlock in ASP.NET / WPF
var data = GetDataAsync().Result;

// GOOD: await properly
var data = await GetDataAsync();
```

### **Captured Loop Variables in Lambdas**  [community]

Capturing a loop variable in a lambda captures the variable itself, not its value at the moment the lambda was created. WHY: all closures share a single variable, so they all see the last value after the loop completes. Fix: copy the loop variable to a local before capturing.

```csharp
// BAD: all lambdas print the final value of i (10, 10, 10 ...)
var actions = new List<Action>();
for (int i = 0; i < 10; i++)
    actions.Add(() => Console.WriteLine(i));

// GOOD: capture a copy
for (int i = 0; i < 10; i++)
{
    int local = i;
    actions.Add(() => Console.WriteLine(local));
}
```

### **DI Lifetime Mismatch — Scoped in Singleton**  [community]

Injecting a Scoped service into a Singleton causes the Scoped service to behave as a Singleton because the Singleton outlives the scope. WHY: `DbContext` (Scoped) holds an internal unit-of-work state; as a Singleton it accumulates changes across all requests, causing data corruption and thread-safety violations. Fix: inject `IServiceScopeFactory` and create a scope per operation. .NET validates this in Development mode.

```csharp
// BAD: DbContext captured for app lifetime
public class DataProcessor(AppDbContext dbContext) { }  // registered Singleton!

// GOOD: create a scope per operation
public class DataProcessor(IServiceScopeFactory scopeFactory)
{
    public async Task ProcessAsync()
    {
        using var scope   = scopeFactory.CreateScope();
        var       dbCtx   = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        // dbCtx is properly scoped here
    }
}
```

### **LINQ Deferred Execution — Enumerating Twice**  [community]

LINQ queries are lazy — they execute every time they are enumerated. Calling `.Count()` then `foreach` on the same `IQueryable` hits the database twice. WHY: unexpected N database roundtrips or O(N²) in-memory work. Fix: materialize with `.ToList()` or `.ToArray()` when the result will be used more than once.

```csharp
// BAD: two database trips
var query = _context.Orders.Where(o => o.IsActive);
int   count = query.Count();          // Trip 1
foreach (var o in query) { }          // Trip 2

// GOOD: materialize once
var orders = _context.Orders.Where(o => o.IsActive).ToList();
int count  = orders.Count;
foreach (var o in orders) { }
```

### **Nullable Warning Suppression with `!`**  [community]

Using the null-forgiving operator (`!`) to silence nullable warnings without actually guaranteeing non-nullability introduces `NullReferenceException` at runtime in places the compiler promised were safe. WHY: it defeats the entire purpose of nullability analysis. Fix: handle the nullable case explicitly or restructure to ensure non-nullability.

```csharp
// BAD: suppresses warning without fixing the bug
string value = GetMaybeNull()!.Trim();

// GOOD: handle null explicitly
string value = GetMaybeNull()?.Trim() ?? string.Empty;
```

### **`string` Concatenation in Loops — `StringBuilder`**  [community]

Concatenating strings with `+` in a loop allocates a new string on each iteration because strings are immutable. WHY: O(N²) memory and CPU for large N, causing GC pressure and latency spikes. Fix: use `StringBuilder` for loops, or `string.Join` / `string.Concat` for static sequences.

```csharp
// BAD: O(N²) allocations
string result = "";
foreach (var item in items) result += item + ", ";

// GOOD: O(N) with StringBuilder
var sb = new StringBuilder();
foreach (var item in items) sb.Append(item).Append(", ");
string result = sb.ToString();

// ALSO GOOD: for static sequences
string joined = string.Join(", ", items);
```

### **Missing `CancellationToken` in Public Async Methods**  [community]

Defining public async methods without a `CancellationToken` parameter makes them non-cooperative. WHY: in web APIs and background services, requests can be cancelled (client disconnect, timeout). Without the token, the operation keeps running, wasting CPU, DB connections, and memory. Fix: add `CancellationToken ct = default` to every public async method.

```csharp
// BAD: cannot be cancelled
public async Task<IEnumerable<Product>> SearchAsync(string query)
    => await _db.Products.Where(p => p.Name.Contains(query)).ToListAsync();

// GOOD: cooperative cancellation throughout
public async Task<IEnumerable<Product>> SearchAsync(
    string            query,
    CancellationToken ct = default)
    => await _db.Products
           .Where(p => p.Name.Contains(query))
           .ToListAsync(ct);
```

### **Record Immutability Is Shallow**  [community]

Records with `init`-only properties appear immutable but are only shallowly so. WHY: a `List<T>` property on a record can have its contents mutated from outside, breaking the invariant. Fix: use immutable collection types (`IReadOnlyList<T>`, `ImmutableArray<T>`) for collection properties on records.

```csharp
// BAD: list is mutable even though the record looks immutable
public record Order(int Id, List<OrderItem> Items);
var order = new Order(1, new List<OrderItem> { new("SKU-1") });
order.Items.Add(new OrderItem("SKU-2"));   // mutates "immutable" record!

// GOOD: use IReadOnlyList or ImmutableArray
public record Order(int Id, IReadOnlyList<OrderItem> Items);
```

### **`ValueTask` Awaited Multiple Times**  [community]

`ValueTask` is a struct wrapping either a completed result or an `IValueTaskSource`. Awaiting it more than once causes undefined behaviour. WHY: the underlying source may be recycled for a different operation. Fix: call `.AsTask()` once and store the `Task` if multiple awaits are needed.

```csharp
// BAD: undefined behavior — vt may be stale or recycled
ValueTask<int> vt = GetValueAsync();
int a = await vt;
int b = await vt;   // BUG

// GOOD: convert to Task for multiple awaits
Task<int> t = GetValueAsync().AsTask();
int a = await t;
int b = await t;   // safe — Task caches the result
```

### **`IDisposable` Not Cascaded — Resource Leak**  [community]

A class that holds an `IDisposable` field but does not implement `IDisposable` leaks the resource until GC finalizes it (non-deterministic). WHY: connection pool exhaustion and file handle leaks accumulate silently under load. Fix: implement `IDisposable` on any class that owns `IDisposable` fields.

```csharp
// BAD: SqlConnection never explicitly disposed
public class DataLoader
{
    private readonly SqlConnection _conn = new(connectionString);
}

// GOOD: cascade Dispose
public sealed class DataLoader : IDisposable
{
    private readonly SqlConnection _conn = new(connectionString);
    public void Dispose() => _conn.Dispose();
}
// Caller: using var loader = new DataLoader();
```

### **`async` Method Without `await` — Silent State Machine**  [community]

An `async` method with no `await` compiles with warning CS1998 and generates a state machine with no benefit. WHY: it misleads callers who assume yielding occurs, and usually indicates a missing `await`. Fix: either add the missing `await`, or remove `async` and return `Task.FromResult`.

```csharp
// BAD: CS1998, state machine overhead, likely missing await
public async Task<int> GetCountAsync()
    => _items.Count;   // no await

// GOOD option 1: synchronous result
public Task<int> GetCountAsync()
    => Task.FromResult(_items.Count);

// GOOD option 2: genuinely async
public async Task<int> GetCountAsync(CancellationToken ct)
{
    await _cache.WarmUpAsync(ct);
    return _items.Count;
}
```

### **LINQ Async Lambdas Without `.ToArray()` Before `Task.WhenAll`**  [community]

Using async lambdas inside LINQ `Select` creates `Task<T>` objects but does not start all of them before `WhenAll`. WHY: tasks are created lazily; what looks like concurrent fan-out is actually sequential. Fix: materialize with `.ToArray()` immediately so all tasks start before `WhenAll`.

```csharp
// BAD: tasks start one at a time — not concurrent
var results = await Task.WhenAll(
    userIds.Select(id => GetUserAsync(id)));

// GOOD: materialize first — truly concurrent fan-out
var tasks   = userIds.Select(id => GetUserAsync(id)).ToArray();
var results = await Task.WhenAll(tasks);
```

### **`new HttpClient()` per Request — Socket Exhaustion**  [community]

Creating a new `HttpClient` instance per request causes socket exhaustion under load. WHY: `HttpClient.Dispose()` closes the TCP connection but does not immediately release the socket; the OS keeps it in TIME_WAIT. Fix: inject `IHttpClientFactory` or register typed clients via `AddHttpClient<T>`.

```csharp
// BAD: socket leak under load
public async Task<string> GetForecastAsync()
{
    using var client = new HttpClient();
    return await client.GetStringAsync("https://api.weather.com/forecast");
}

// GOOD: typed HttpClient — reuses pooled HttpMessageHandler
public class WeatherClient(HttpClient client)
{
    public async Task<string> GetForecastAsync(CancellationToken ct)
        => await client.GetStringAsync("/forecast", ct);
}

builder.Services.AddHttpClient<WeatherClient>(c =>
    c.BaseAddress = new Uri("https://api.weather.com"));
```

### **Static Mutable State — Thread-Safety and Data Corruption**  [community]

`static` mutable fields are shared across all threads. WHY: in web applications, multiple request threads read and write without synchronization, causing torn reads, lost writes, and non-deterministic failures. Fix: use `Interlocked` for counters, `ConcurrentDictionary<>` for caches, and per-request scoped services via DI.

```csharp
// BAD: race condition on every increment
public class RequestMetrics
{
    public static int RequestCount = 0;
    public static void Increment() => RequestCount++;   // NOT thread-safe
}

// GOOD: atomic operations
public static class RequestMetrics
{
    private static int _count;
    public static int Count    => _count;
    public static void Increment() => Interlocked.Increment(ref _count);
}
```

### **`Task.WhenAll` — Only the First Exception Surfaces**  [community]

When `Task.WhenAll` is awaited and multiple tasks have faulted, the `await` only rethrows the first exception from the `AggregateException.InnerExceptions` collection. The others are silently swallowed. WHY: `await` unwraps `AggregateException` and throws just the first inner exception; remaining failures go unnoticed, making failure diagnosis misleading. Fix: inspect `task.Exception.InnerExceptions` on each task, or use a try/catch that catches `AggregateException` directly on the `Task` object before awaiting.

```csharp
// Setup: three tasks, two of which throw
var t1 = Task.FromException(new InvalidOperationException("error 1"));
var t2 = Task.FromResult(42);
var t3 = Task.FromException(new ArgumentException("error 3"));

// BAD: only "error 1" surfaces — "error 3" is lost
try { await Task.WhenAll(t1, t2, t3); }
catch (Exception ex) { Console.WriteLine(ex.Message); }  // prints "error 1" only

// GOOD: capture all tasks, inspect each exception individually
var tasks = new[] { t1, t2, t3 };
try
{
    await Task.WhenAll(tasks);
}
catch
{
    var errors = tasks
        .Where(t => t.IsFaulted)
        .SelectMany(t => t.Exception!.InnerExceptions)
        .ToList();

    foreach (var err in errors)
        _logger.LogError(err, "Task failed");

    throw;   // re-throw to propagate caller-visible failure
}
```

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `async void` outside event handlers | Exceptions crash the process silently | Return `Task` or `Task<T>` |
| `.Result` / `.Wait()` on Tasks | Deadlocks in sync-context environments | `await` all the way up |
| Suppressing nullable warnings with `!` | Runtime `NullReferenceException` in "safe" code | Handle null explicitly |
| Service Locator (`IServiceProvider` in business logic) | Hides dependencies, makes testing hard | Constructor injection |
| Scoped service injected into Singleton | Scoped lives forever, data corruption | Use `IServiceScopeFactory` |
| LINQ without `.ToList()` / `.ToArray()` materialization | Multiple enumerations hit DB or compute multiple times | Materialize when reusing |
| `catch (Exception)` then `throw ex` | Resets stack trace, loses original throw location | Bare `throw` |
| `catch (Exception)` with no action | Swallows exceptions, program runs in invalid state | Catch specific types; log and rethrow |
| `string` concatenation in loops | O(N²) allocations, GC pressure | `StringBuilder` or `string.Join` |
| Public async method without `CancellationToken` | Cannot be cancelled; wastes resources | Add `CancellationToken ct = default` |
| `async` method with no `await` (CS1998) | State machine overhead, likely missing `await` | Add `await` or return `Task.FromResult` |
| `Task.Run` for I/O-bound work in library code | Forces thread-pool onto callers; wrong for I/O | Use `Task.Run` only for CPU-bound work in app code |
| LINQ async lambda without `.ToArray()` before `WhenAll` | Sequential, not concurrent | `.ToArray()` first, then `WhenAll` |
| `new HttpClient()` per request | Socket exhaustion (TIME_WAIT) | `IHttpClientFactory` or typed clients |
| `static` mutable fields in multi-threaded code | Race conditions, torn reads | `Interlocked`, `ConcurrentDictionary`, scoped DI |
| Mutable collection properties on records | Shallow immutability broken from outside | `IReadOnlyList<T>` or `ImmutableArray<T>` |
| `ValueTask` awaited multiple times | Undefined behavior, recycled source | `.AsTask()` once |
| `IDisposable` field in class without `IDisposable` | Resource leak, pool exhaustion | Cascade `Dispose()` |
| Using `dynamic` to avoid type complexity | Loses compile-time safety and IDE tooling | Generics, interfaces, pattern matching |
| `using` directive inside namespace block | Context-sensitive name resolution breaks silently | Place `using` directives at file level |
| Locking on `this` or public objects | External code can acquire the same lock | Private `readonly object` or `Lock` (.NET 9+) |
| `Span<T>` stored in a field or across `await` | Compile error or dangling pointer | `Memory<T>` for heap/async scenarios |
| `await Task.WhenAll(...)` without inspecting all faults | Only first exception surfaces; others silently lost | Inspect `.Exception.InnerExceptions` on each faulted task |
