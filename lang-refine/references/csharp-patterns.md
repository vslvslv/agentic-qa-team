# C# Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 22 | score: 100/100 | date: 2026-05-03 -->

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

**LINQ Execution Model — Immediate vs Deferred:**
- **Deferred streaming** (`Where`, `Select`, `Skip`, `Take`): yields one element at a time, starts on first `foreach`/`MoveNext`
- **Deferred non-streaming** (`OrderBy`, `GroupBy`, `Reverse`): must read all source before yielding any output
- **Immediate** (`Count`, `ToList`, `ToArray`, `First`, `Sum`): executes the query right away; use to materialize results

```csharp
// Deferred: no database call until enumerated
IQueryable<Order> query = _db.Orders.Where(o => o.Total > 100);

// Immediate: materializes now — prevents double enumeration
List<Order> orders = query.OrderBy(o => o.CreatedAt).ToList();
int count = orders.Count;  // in-memory property, not a second DB trip
```

**New LINQ Methods — .NET 9:**

```csharp
// CountBy — count occurrences by key without intermediate GroupBy allocation
var wordCounts = words.CountBy(w => w.ToLowerInvariant());
// Returns IEnumerable<KeyValuePair<string,int>> — no intermediate groupings

// AggregateBy — aggregate by key without allocating group collections
var totalByRegion = orders.AggregateBy(
    keySelector: o => o.Region,
    seed: 0m,
    func: (total, o) => total + o.Amount);
// Returns IEnumerable<KeyValuePair<string,decimal>>

// Index — attach a zero-based index to each element (like Python's enumerate)
foreach (var (index, item) in shoppingCart.Items.Index())
{
    Console.WriteLine($"{index + 1}. {item.Name} — {item.Price:C}");
}

// Order/OrderDescending — sort without a key selector (uses natural order)
var sorted = numbers.Order().ToList();           // ascending
var reversed = names.OrderDescending().ToList(); // descending
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

// Extended property pattern — nested properties without extra braces
public record Segment(Point Start, Point End);
static bool IsAnyEndOnXAxis(Segment segment) =>
    segment is { Start.Y: 0 } or { End.Y: 0 };  // C# 10+ extended property pattern

// Parenthesized patterns — clarify precedence in logical combinations
static bool IsNotLetter(char c) => c is not (>= 'a' and <= 'z') and not (>= 'A' and <= 'Z');
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

**Options Pattern — Strongly-Typed Configuration (IOptions / IOptionsMonitor):**

```csharp
// Options class — POCO with public read-write properties, parameterless constructor
public sealed class SmtpOptions
{
    public required string Host { get; set; }
    public int Port { get; set; } = 587;
    public required string From { get; set; }
}

// Registration with DataAnnotations validation + validate at startup
builder.Services
    .AddOptions<SmtpOptions>()
    .Bind(builder.Configuration.GetSection("Smtp"))
    .ValidateDataAnnotations()
    .ValidateOnStart();   // throws at startup if config is invalid

// Consuming: inject IOptions<T> for read-once config (singleton)
// inject IOptionsMonitor<T> for config that may change at runtime (singleton, live updates)
// inject IOptionsSnapshot<T> for per-request snapshot (scoped)
public class EmailService(IOptions<SmtpOptions> options)
{
    private readonly SmtpOptions _smtp = options.Value;

    public async Task SendAsync(string to, string subject, string body, CancellationToken ct)
    {
        using var client = new SmtpClient(_smtp.Host, _smtp.Port);
        await client.SendMailAsync(new MailMessage(_smtp.From, to, subject, body), ct);
    }
}
```

### Minimal APIs — ASP.NET Core .NET 8+ with TypedResults

ASP.NET Core Minimal APIs use `IEndpointRouteBuilder` to declare routes as lambdas or method groups. Prefer `TypedResults` over `Results` for strongly-typed return types that are captured in OpenAPI metadata. Group related endpoints with `RouteGroupBuilder` and extract to extension methods for maintainability.

```csharp
// Program.cs — use WebApplication.MapGroup + extension method for route organization
var app = builder.Build();

app.MapOrderEndpoints();
app.MapCustomerEndpoints();

// OrderEndpoints.cs — IEndpointRouteBuilder extension for cohesion
public static class OrderEndpoints
{
    public static IEndpointRouteBuilder MapOrderEndpoints(
        this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/orders")
            .WithTags("Orders")
            .RequireAuthorization();

        group.MapGet("{id:int}", GetOrder)
            .WithName("GetOrder")
            .Produces<OrderDto>()
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("", CreateOrder)
            .WithName("CreateOrder")
            .Accepts<CreateOrderRequest>("application/json");

        return routes;
    }

    // Handler as static method — testable, no DI required in delegate
    static async Task<Results<Ok<OrderDto>, NotFound>> GetOrder(
        int id,
        IOrderService orders,
        CancellationToken ct)
    {
        var order = await orders.GetByIdAsync(id, ct);
        return order is null
            ? TypedResults.NotFound()
            : TypedResults.Ok(order.ToDto());
    }

    static async Task<Results<Created<OrderDto>, ValidationProblem>> CreateOrder(
        CreateOrderRequest request,
        IOrderService orders,
        IValidator<CreateOrderRequest> validator,
        CancellationToken ct)
    {
        var validation = await validator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return TypedResults.ValidationProblem(validation.ToDictionary());

        var order = await orders.CreateAsync(request, ct);
        return TypedResults.Created($"/orders/{order.Id}", order.ToDto());
    }
}
```

### Delegates — `Func<T>` and `Action<T>` over Custom Delegate Types

Use the built-in `Func<>` and `Action<>` delegate types rather than declaring custom delegate types. They communicate intent (action vs. function), are composable, and avoid polluting the type namespace. Declare custom delegate types only when the signature is highly domain-specific and used in many places — even then, consider `Func<>` with a type alias.

```csharp
// Prefer Func<> and Action<> over declaring custom delegates
Action<string> log = message => Console.WriteLine($"[LOG] {message}");
Action<string, string> logWithLevel = (level, msg) => Console.WriteLine($"[{level}] {msg}");

Func<string, int> parseId = text => int.Parse(text.Trim());
Func<int, int, int> add = (x, y) => x + y;

// Using in method signatures — makes combinators and callbacks generic
public static IEnumerable<T> Filter<T>(
    IEnumerable<T> source,
    Func<T, bool> predicate)
    => source.Where(predicate);

// Composable pipeline: Func<T> chains naturally
Func<string, string> trim = s => s.Trim();
Func<string, string> toLower = s => s.ToLower();
Func<string, string> normalize = s => toLower(trim(s));

// Event handler shorthand with lambda — no need for a named method unless reuse needed
button.Click += (sender, e) => HandleClick((Button)sender);
```

### Result Pattern — Error Handling Without Exceptions

Exceptions are for exceptional situations, not expected failures. Using a `Result<T>` type (or discriminated union via OneOf / pattern matching) lets callers handle failure paths without try/catch and without silently swallowing errors. In C#, you can implement a minimal Result type using records and switch expressions without external libraries.

```csharp
// Lightweight Result type using records and pattern matching
public abstract record Result<T>
{
    public record Success(T Value) : Result<T>;
    public record Failure(string Error, Exception? Exception = null) : Result<T>;

    public bool IsSuccess => this is Success;
    public T? ValueOrDefault => this is Success s ? s.Value : default;
}

// Helper factories for cleaner call sites
public static class Result
{
    public static Result<T> Ok<T>(T value) => new Result<T>.Success(value);
    public static Result<T> Fail<T>(string error, Exception? ex = null)
        => new Result<T>.Failure(error, ex);
}

// Service method returns Result instead of throwing
public async Task<Result<Order>> PlaceOrderAsync(
    PlaceOrderRequest request,
    CancellationToken ct)
{
    if (!await _inventory.HasStockAsync(request.Items, ct))
        return Result.Fail<Order>("One or more items are out of stock.");

    try
    {
        var order = await _orderRepo.CreateAsync(request, ct);
        return Result.Ok(order);
    }
    catch (DbException ex)
    {
        _logger.LogError(ex, "DB error placing order");
        return Result.Fail<Order>("Database error — please try again.", ex);
    }
}

// Caller uses switch expression — no try/catch needed
var result = await _orderService.PlaceOrderAsync(request, ct);
return result switch
{
    Result<Order>.Success s  => TypedResults.Created($"/orders/{s.Value.Id}", s.Value),
    Result<Order>.Failure f  => TypedResults.Problem(f.Error),
};
```

### CPU-Bound Async — Task.Run

Use `Task.Run` to offload CPU-intensive work to a thread-pool thread so the calling thread (UI or request thread) stays responsive. Do NOT use `Task.Run` for I/O-bound work — that defeats the purpose of async. The distinction: I/O-bound operations wait for hardware; CPU-bound operations compute.

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

// In a UI event handler: keep the UI thread free during heavy calculation
private async void OnCalculateClicked(object sender, EventArgs e)
{
    var result = await Task.Run(() => RunHeavySimulation(inputData));
    DisplayResult(result);
}

// Guideline: never use Task.Run in library code — let callers decide threading
// DO in app-level code; DON'T in shared library methods that just do I/O
```

### IDisposable and IAsyncDisposable — The Dispose Pattern

Implement `IDisposable` on any class that owns unmanaged resources or `IDisposable` fields. Use the protected `Dispose(bool disposing)` virtual method to allow subclasses to override cleanup. Call `GC.SuppressFinalize(this)` after explicit disposal to prevent the finalizer from running a second time. For async resources (database connections, async streams), implement `IAsyncDisposable` and use `await using`.

```csharp
// Standard Dispose pattern for classes that own IDisposable fields
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
        // ... query logic
        return [];
    }

    public void Dispose()
    {
        if (_disposed) return;
        _connection.Dispose();
        _disposed = true;
        GC.SuppressFinalize(this);  // suppress finalizer — already cleaned up
    }
}

// IAsyncDisposable for async resources
public sealed class AsyncDataService : IAsyncDisposable
{
    private readonly DbConnection _connection = new SqlConnection(connectionString);

    public async ValueTask DisposeAsync()
    {
        await _connection.DisposeAsync();
        GC.SuppressFinalize(this);
    }
}

// Caller: use 'await using' for IAsyncDisposable
await using var service = new AsyncDataService();
var results = await service.QueryAsync(ct);
```

### `Channel<T>` — Async Producer-Consumer Pipelines

`System.Threading.Channels.Channel<T>` is the idiomatic .NET pattern for decoupled producer-consumer pipelines. Unlike `BlockingCollection<T>`, channels are fully async and backpressure-aware. A bounded channel limits queue depth (backpressure); an unbounded channel accepts unlimited items. Use `ChannelReader<T>` in consumers and `ChannelWriter<T>` in producers.

```csharp
// Create a bounded channel — producer blocks when queue is full (backpressure)
var channel = Channel.CreateBounded<WorkItem>(
    new BoundedChannelOptions(capacity: 100)
    {
        FullMode = BoundedChannelFullMode.Wait,      // await instead of drop
        SingleReader = false,
        SingleWriter = false
    });

// Producer: write items until done, then mark complete
public async Task ProduceAsync(ChannelWriter<WorkItem> writer, CancellationToken ct)
{
    try
    {
        await foreach (var item in _source.StreamAsync(ct))
        {
            await writer.WriteAsync(item, ct);  // waits if channel is full
        }
    }
    finally
    {
        writer.Complete();  // signal: no more items coming
    }
}

// Consumer: read items until channel is complete
public async Task ConsumeAsync(ChannelReader<WorkItem> reader, CancellationToken ct)
{
    // ReadAllAsync yields items as they arrive; stops when writer.Complete() is called
    await foreach (var item in reader.ReadAllAsync(ct))
    {
        await ProcessItemAsync(item, ct);
    }
}

// Wire up producer and multiple consumers concurrently
var producerTask = ProduceAsync(channel.Writer, cts.Token);
var consumerTasks = Enumerable.Range(0, 4)
    .Select(_ => ConsumeAsync(channel.Reader, cts.Token))
    .ToArray();
await Task.WhenAll([producerTask, ..consumerTasks]);
```

### `PeriodicTimer` — Tick-Accurate Background Loops (.NET 6+)

`PeriodicTimer` replaces `Task.Delay(interval)` loops for background services. Unlike `Task.Delay`, it does not drift over time — each tick fires at a fixed interval from the previous, compensating for processing time. It is properly cancellable, and skips missed ticks if the callback falls behind instead of stacking them up.

```csharp
public sealed class MetricsFlushService(
    IMetricsCollector metrics,
    ILogger<MetricsFlushService> logger)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(30));

        // WaitForNextTickAsync returns false when stoppingToken is cancelled
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await metrics.FlushAsync(stoppingToken);
                logger.LogDebug("Metrics flushed at {Time}", DateTimeOffset.UtcNow);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Log but don't crash the service — next tick will retry
                logger.LogError(ex, "Metrics flush failed");
            }
        }
    }
}

// Registration in Program.cs
builder.Services.AddHostedService<MetricsFlushService>();
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

// The Lock type also works with using for explicit scope management
using (_lock.EnterScope())
{
    // exclusive critical section — exits on Dispose
}
```

### `\e` Escape Sequence (C# 13)

C# 13 adds `\e` as a character literal for the ANSI ESCAPE character (`U+001B`). Previously `\x1b` was used, but it was error-prone: if the next characters were valid hex digits they became part of the sequence.

```csharp
// C# 13 — unambiguous ANSI escape sequence
string bold  = $"\e[1mBold text\e[0m";
string green = $"\e[32mGreen text\e[0m";

// Old (error-prone): \x1b followed by valid hex = bug
// string wrong = "\x1b[32m";  // fine, but "\x1b[3" could be parsed as \x1b3[
```

### File-Scoped Namespaces

In files with a single namespace, use file-scoped namespace declarations to reduce indentation across the entire file.

```csharp
// Instead of wrapping entire file in namespace { }
namespace MyApp.Services;

public class OrderService { }
public class InvoiceService { }
```

### Global Usings (C# 10)

Declare commonly needed namespaces once in a dedicated file so every source file in the project gets them automatically. This eliminates repetitive `using` lines at the top of each file without resorting to `#pragma` or custom tooling.

```csharp
// File: GlobalUsings.cs — applies to every .cs file in the project
global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;

// Optional: alias for commonly used generics
global using StringMap = System.Collections.Generic.Dictionary<string, string>;
```

Best practice: limit global usings to universally relevant namespaces. Domain-specific namespaces should remain local to the files that need them.

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

### Target-Typed `new()` Expression

When the variable type is known from the declaration, use `new()` without repeating the type name. This reduces redundancy while preserving explicitness.

```csharp
// Traditional: type name repeated twice
ExampleClass instance1 = new ExampleClass();

// Target-typed new: compiler infers type from left side
ExampleClass instance2 = new();

// Useful in collection initializers and object initializers
var items = new List<OrderItem>
{
    new() { ProductId = 1, Quantity = 2 },
    new() { ProductId = 2, Quantity = 1 }
};

// In field/property initializers — eliminates repetition
public class Config
{
    private readonly Dictionary<string, string> _settings = new();
    private readonly List<string> _tags = new();
}
```

### Async Method Naming Convention

Append the `Async` suffix to every method that returns `Task`, `Task<T>`, `ValueTask`, or `ValueTask<T>`. This convention makes call sites self-documenting and helps callers notice that a method must be awaited. Exception: event handlers and interface implementations that fix the name (e.g., `Controller` action methods in ASP.NET Core don't require the suffix if the framework resolves them by route).

```csharp
// Convention: Async suffix on all async method signatures
public interface IOrderService
{
    Task<Order> GetOrderAsync(int id, CancellationToken ct = default);
    Task<IReadOnlyList<Order>> GetOrdersForCustomerAsync(int customerId, CancellationToken ct = default);
    Task CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default);
}

// At call site, the suffix signals "await me"
var order = await _orderService.GetOrderAsync(orderId, ct);

// Event handlers: async void — Async suffix optional, not strictly required
private async void OnOrderSubmitted(object sender, OrderEventArgs e)
{
    await _orderService.CreateOrderAsync(e.Request, CancellationToken.None);
}
```

### `using` Directives Outside Namespace

Place `using` directives at the top of the file, outside any namespace block. When `using` is inside a namespace, name resolution is context-sensitive and can break silently when a new type with a matching partial namespace is introduced by a dependency. Outside the namespace, the fully-qualified name is always used.

```csharp
// GOOD: using at file level — always resolves to fully qualified name
using Azure;
using System.Collections.Generic;

namespace CoolStuff.AwesomeFeature;

public class FeatureService
{
    public void Process(WaitUntil wait) { }  // unambiguously Azure.WaitUntil
}

// RISKY: using inside namespace — name resolution is order-dependent
// namespace CoolStuff.AwesomeFeature
// {
//     using Azure;  // If CoolStuff.Azure is later added, this breaks silently
//     ...
// }
```

### `Span<T>` and `Memory<T>` for Zero-Allocation Buffer Operations

`Span<T>` is a stack-only ref struct providing a view over contiguous memory (array, stack-allocated, or unmanaged) without allocation. Use it for synchronous parsing, slicing, and string operations in hot paths. Use `Memory<T>` when you need to store the buffer reference across `await` points or on the heap. Use `ReadOnlySpan<T>` / `ReadOnlyMemory<T>` for read-only access.

```csharp
// Parse without string allocation using ReadOnlySpan<char>
static int SumCsvInts(ReadOnlySpan<char> input)
{
    int total = 0;
    foreach (var part in new SpanSplitter(input, ','))
        if (int.TryParse(part, out int value))
            total += value;
    return total;
}

// stackalloc for small buffers — no heap allocation
Span<byte> buffer = stackalloc byte[256];
int written = Encoding.UTF8.GetBytes("Hello, World!", buffer);
var slice = buffer[..written];

// Memory<T> for async scenarios — can cross await boundaries
public async Task ProcessBufferAsync(Memory<byte> buffer, CancellationToken ct)
{
    await _stream.ReadAsync(buffer, ct);  // safe — Memory<T> survives await
    var span = buffer.Span;               // get Span<T> for sync processing
    ParseHeader(span);
}

// Rule: prefer Span<T> for sync APIs, Memory<T> for async APIs
public int ParseLength(ReadOnlySpan<byte> header)   => ...; // sync — use Span
public Task WriteAsync(ReadOnlyMemory<byte> payload) => ...; // async — use Memory
```

### Generic Constraints — `where T :` Clauses

Generic constraints tell the compiler what a type parameter must support, enabling type-safe generic algorithms. Use `where T : IEquatable<T>` or `where T : IComparable<T>` to unlock equality/ordering operations on unbounded type parameters. Use `where T : class` for reference type semantics, `where T : struct` for value type semantics, and `where T : notnull` to exclude nullable types.

```csharp
// Without constraint: can only use System.Object members
public static bool AreEqual<T>(T a, T b) => a!.Equals(b); // boxing for value types

// With IEquatable<T> constraint: type-safe, no boxing
public static bool AreEqual<T>(T a, T b) where T : IEquatable<T>
    => a.Equals(b);  // calls T.Equals directly, no boxing

// Multiple constraints: must be a reference type, implement interface, have new()
public class Repository<T> where T : class, IEntity, new()
{
    public T Create() => new T();  // new() constraint enables this
    public T? FindById(int id) => _items.FirstOrDefault(e => e.Id == id);
}

// notnull: excludes both nullable reference types and Nullable<T>
public static T RequireValue<T>(T? value, string name) where T : notnull
{
    ArgumentNullException.ThrowIfNull(value, name);
    return value;
}

// where T : unmanaged: enables sizeof and pointer operations on T
public static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

// enum constraint: type-safe enum operations
public static string GetName<T>(T value) where T : struct, Enum
    => Enum.GetName(value) ?? value.ToString();
```

### Guard Clauses — `ArgumentException.ThrowIf*` Helpers (.NET 8+)

.NET 8 added a family of `ArgumentException.ThrowIf*` static methods and `ObjectDisposedException.ThrowIf` to replace manual `if (x == null) throw new ArgumentNullException(nameof(x))` boilerplate. Use these at public API entry points to validate inputs without ceremony. The `[CallerArgumentExpression]` attribute is used internally to automatically capture the parameter name in the exception message.

```csharp
// .NET 8+ guard helpers — replace manual if/throw patterns
public void ProcessOrder(Order? order, string customerId, IList<OrderItem> items)
{
    ArgumentNullException.ThrowIfNull(order);                        // order != null
    ArgumentException.ThrowIfNullOrEmpty(customerId);               // not null, not ""
    ArgumentException.ThrowIfNullOrWhiteSpace(customerId);          // not null, not whitespace
    ArgumentOutOfRangeException.ThrowIfNegative(items.Count);       // not < 0
    ArgumentOutOfRangeException.ThrowIfZero(items.Count);           // not == 0
    ArgumentOutOfRangeException.ThrowIfGreaterThan(items.Count, 100); // not > 100

    // safe to use all parameters below
}

// ObjectDisposedException.ThrowIf — idiomatic disposed-check
public class DataReader : IDisposable
{
    private bool _disposed;

    public string Read()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        // ... read logic
        return string.Empty;
    }

    public void Dispose()
    {
        _disposed = true;
        GC.SuppressFinalize(this);
    }
}

// [CallerArgumentExpression] — capture expression text in custom guard methods
public static T RequireNotNull<T>(
    [NotNull] T? value,
    [CallerArgumentExpression(nameof(value))] string? expression = null)
    where T : class
{
    if (value is null)
        throw new ArgumentNullException(expression, $"Expected non-null: {expression}");
    return value;
}

// Usage: exception message automatically says "order.Customer" not just "value"
var customer = RequireNotNull(order.Customer);
```

### C# 14 / .NET 10 — Extension Members

C# 14 (shipping with .NET 10) introduces a richer extension member syntax. Rather than writing isolated static methods in a separate class, you can now declare an `extension` block that groups both instance and static extension members, including properties and operators. This is a significant upgrade over the C# 3 extension method model.

```csharp
// C# 14: extension block groups instance and static extension members
public static class OrderExtensions
{
    // Instance extension block — members act like instance members
    extension(IReadOnlyList<OrderItem> items)
    {
        // Extension property
        public decimal TotalPrice => items.Sum(i => i.Price * i.Quantity);

        // Extension method
        public IReadOnlyList<OrderItem> InStock()
            => items.Where(i => i.IsInStock).ToList();
    }

    // Static extension block — members act like static members
    extension(IReadOnlyList<OrderItem>)
    {
        public static IReadOnlyList<OrderItem> Empty => [];
    }
}

// Usage — reads like built-in members
decimal total = cart.Items.TotalPrice;
var available = cart.Items.InStock();
var blank = IReadOnlyList<OrderItem>.Empty;
```

**Why it matters:** extension properties let you augment read-only domain types with computed projections without subclassing or wrappers. Static extension members eliminate the need for factory-method classes like `Enumerable.Empty<T>()`.

### C# 14 — `field` Keyword for Backing Fields in Properties

The `field` keyword replaces the explicit backing field declaration for simple property customization. The compiler synthesizes the backing field; `field` is the token to reference it inside property accessors. This eliminates the boilerplate of declaring `private T _foo;` just to add validation in a setter.

```csharp
// C# 14: use 'field' instead of a private backing field
public class EmailAddress
{
    // Compiler synthesizes the backing field; 'field' accesses it
    public string Value
    {
        get;
        set => field = value?.Trim().ToLowerInvariant()
            ?? throw new ArgumentNullException(nameof(value));
    }

    // Combined with init for immutable types
    public string Domain
    {
        get;
        init => field = value ?? throw new ArgumentNullException(nameof(value));
    }
}

// Before C# 14: required an explicit backing field
// private string _value = string.Empty;
// public string Value { get => _value; set => _value = value?.Trim() ?? throw ...; }
```

### C# 14 — Null-Conditional Assignment

The null-conditional operators (`?.` and `?[]`) can now appear on the **left-hand side** of an assignment. The right-hand side is only evaluated when the left side is not null. This eliminates the common `if (x != null) x.Prop = value;` pattern.

```csharp
// C# 14: null-conditional assignment — only assigns if customer is non-null
customer?.PendingOrder = GetCurrentOrder();
customer?.Tags?.Add("new-customer");

// Equivalent pre-C# 14 pattern
if (customer is not null)
{
    customer.PendingOrder = GetCurrentOrder();
}

// Works with compound assignment operators too
customer?.LoyaltyPoints += reward;
settings?.RetryCount -= 1;
```

### C# 14 — Lambda Parameters with Modifiers (No Type Required)

Lambda expression parameters can now carry `ref`, `out`, `in`, `scoped`, or `ref readonly` modifiers without explicitly typing each parameter. Previously, any modifier required all parameters to be explicitly typed.

```csharp
// C# 14: parameter modifiers without full type annotations
delegate bool TryParse<T>(string text, out T result);

// Before C# 14: had to type every parameter
TryParse<int> parse1 = (string text, out int result) => int.TryParse(text, out result);

// C# 14: modifier only — compiler infers types
TryParse<int> parse2 = (text, out result) => int.TryParse(text, out result);

// 'scoped' modifier prevents ref from escaping the lambda's scope
ProcessItems((scoped ref item) => item.Price *= 0.9m);
```

### `partial` Properties and Indexers (C# 13)

`partial` methods were expanded in C# 13 to support properties and indexers. Use partial properties in source-generator scenarios where the declaring declaration (the "contract") lives in a user-authored file and the implementing declaration (the body) is generated. Each partial property has exactly one declaring declaration and one implementing declaration; the signatures must match.

```csharp
// Declaring file (user-authored): contract only, no body
public partial class PersonViewModel
{
    public partial string DisplayName { get; set; }
    public partial int Age { get; }
}

// Implementing file (source-generated or hand-authored): full body
public partial class PersonViewModel
{
    private string _displayName = string.Empty;

    public partial string DisplayName
    {
        get => _displayName;
        set => _displayName = value?.Trim() ?? string.Empty;
    }

    public partial int Age => (DateTime.UtcNow.Year - _birthYear);
}
```

**When to use:** partial properties shine when a Roslyn source generator produces the backing implementation (e.g., MVVM source generators that generate `INotifyPropertyChanged` boilerplate). The user writes the declaring declaration as the spec; the generator fills in the body.

### `OverloadResolutionPriorityAttribute` (C# 13)

Library authors can annotate a method with `[OverloadResolutionPriority(n)]` to steer the compiler toward a preferred overload without breaking callers that depend on the existing one. Higher priority values win. This is intended for BCL-style library authors who need to add more-efficient overloads while preserving backward compatibility.

```csharp
using System.Runtime.CompilerServices;

public static class TextUtils
{
    // Legacy overload — still callable, but compiler prefers the new one
    public static string Normalize(string input)
        => input.Trim().ToLowerInvariant();

    // New, allocation-free overload — preferred when applicable
    [OverloadResolutionPriority(1)]
    public static string Normalize(ReadOnlySpan<char> input)
        => input.Trim().ToString().ToLowerInvariant();
}

// Call site: compiler picks the Span<char> overload when passing a string literal
// (string has implicit conversion to ReadOnlySpan<char>)
string result = TextUtils.Normalize("  Hello World  ");
```

**Guidance:** use this only for library code where you control the API surface and want to deprecate an older overload softly. Do not use it in application code where overload ambiguity is under your control.

### `nameof` with Unbound Generic Types (C# 14)

Before C# 14, `nameof` required a closed generic type (`nameof(List<int>)` returned `"List"`). C# 14 allows unbound generic types so you no longer need to pick a concrete type argument just to get the type name.

```csharp
// C# 14: unbound generic — no need to supply a type argument
string name1 = nameof(List<>);          // "List"
string name2 = nameof(Dictionary<,>);  // "Dictionary"

// Useful in exception messages and logging without allocating a dummy type argument
void Register<T>()
{
    Console.WriteLine($"Registering {nameof(T)}");  // still works
    Console.WriteLine($"Container: {nameof(List<>)}");  // clean — no dummy type
}
```

### Implicit Span Conversions (C# 14)

C# 14 introduces first-class span support with new implicit conversions between `T[]`, `Span<T>`, and `ReadOnlySpan<T>`. These conversions enable span types to be used as extension method receivers and compose naturally with other conversions, eliminating the need for explicit casts in many scenarios.

```csharp
// C# 14: implicit conversion from T[] to ReadOnlySpan<T> and Span<T>
int[] numbers = [1, 2, 3, 4, 5];

// Direct implicit conversion — no explicit cast needed
ReadOnlySpan<int> roSpan = numbers;   // T[] → ReadOnlySpan<T>
Span<int> span = numbers;             // T[] → Span<T>

// Span<T> implicitly converts to ReadOnlySpan<T>
ReadOnlySpan<int> ro = span;          // Span<T> → ReadOnlySpan<T>

// Enables zero-allocation APIs to accept arrays, spans, and read-only spans naturally
public static int Sum(ReadOnlySpan<int> values)
{
    int total = 0;
    foreach (var v in values) total += v;
    return total;
}

// All three call forms work without explicit conversion
int a = Sum(numbers);     // T[] — implicit conversion
int b = Sum(span);        // Span<T> — implicit conversion
int c = Sum(roSpan);      // ReadOnlySpan<T> — direct
```

**Why it matters:** library authors no longer need to write three overloads (`T[]`, `Span<T>`, `ReadOnlySpan<T>`) for performance-sensitive APIs. A single `ReadOnlySpan<T>` parameter now accepts all three without allocations.

### `partial` Constructors and Events (C# 14)

C# 14 extends partial members to include instance constructors and events. A partial constructor has exactly one declaring declaration and one implementing declaration. Only the implementing declaration can include a constructor initializer (`this()` or `base()`). Partial events have a field-like declaring declaration and an implementing declaration with explicit `add`/`remove` accessors.

```csharp
// Declaring file — contract only
public partial class Widget
{
    // Partial constructor — declaring declaration
    public partial Widget(string name, int id);

    // Partial event — field-like declaring declaration
    public partial event EventHandler<WidgetEventArgs>? StateChanged;
}

// Implementing file — full bodies
public partial class Widget
{
    private readonly string _name;
    private readonly int _id;

    // Partial constructor implementing declaration — base() allowed here only
    public partial Widget(string name, int id)
        : base()
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        _name = name;
        _id = id;
    }

    // Partial event implementing declaration — explicit add/remove
    private EventHandler<WidgetEventArgs>? _stateChangedHandler;
    public partial event EventHandler<WidgetEventArgs>? StateChanged
    {
        add => _stateChangedHandler += value;
        remove => _stateChangedHandler -= value;
    }
}
```

**Use case:** source generators that augment user-defined types. The user writes the declaring contract; the generator provides the implementation.



`Task.ContinueWith` predates the `async`/`await` keywords and requires manual error handling, nested lambdas, and `Unwrap()` calls to chain operations. `async`/`await` compiles to an equivalent state machine but reads like synchronous code. Use `ContinueWith` only in rare low-level scenarios (e.g., advanced scheduler control). The official docs explicitly recommend `async`/`await` for all new code.

```csharp
// BAD: ContinueWith chains — nested, hard to read, error-prone
Task<Report> report = FetchDataAsync()
    .ContinueWith(dataTask => ProcessAsync(dataTask.Result))
    .Unwrap()
    .ContinueWith(processTask => FormatReportAsync(processTask.Result))
    .Unwrap();

// GOOD: async/await — reads like sequential synchronous code
async Task<Report> BuildReportAsync(CancellationToken ct)
{
    var data = await FetchDataAsync(ct);
    var processed = await ProcessAsync(data, ct);
    return await FormatReportAsync(processed, ct);
}
// Error handling: natural try/catch works — no AggregateException unwrapping needed
```

**Why `ContinueWith` is dangerous:** exceptions in `ContinueWith` lambdas are wrapped in `AggregateException`. If you don't observe the task, the process crashes on GC finalization (in older runtimes). `async`/`await` automatically unwraps the first inner exception, making error handling identical to synchronous code.

### Short-Circuit Boolean Operators (`&&` / `||` over `&` / `|`)

Always use `&&` (conditional AND) and `||` (conditional OR) for boolean conditions. The non-short-circuit versions (`&`, `|`) evaluate both operands even if the first operand determines the outcome, which can cause `NullReferenceException` or unexpected side effects. The official Microsoft coding conventions enforce this rule.

```csharp
// BAD: non-short-circuit — evaluates both sides, throws NRE if list is null
if (list != null & list.Count > 0) { }

// GOOD: short-circuit — second clause only evaluated if first is true
if (list != null && list.Count > 0) { }

// BAD: side effect triggered even when first condition is false
if (IsEnabled() | LogAction("checking")) { }

// GOOD: LogAction only called when IsEnabled() returns true
if (IsEnabled() && LogAction("checking")) { }
```



The `[GeneratedRegex]` attribute instructs the Roslyn source generator to generate an optimized, compiled regex implementation at build time rather than at runtime. Benefits: no runtime compilation cost, no heap allocation for the `Regex` object, and better startup performance. Use this instead of `new Regex(...)` or `Regex.IsMatch(...)` for any regex used more than once.

```csharp
using System.Text.RegularExpressions;

public partial class InputValidator
{
    // Source generator produces the implementation at compile time
    [GeneratedRegex(@"^\+?[1-9]\d{1,14}$", RegexOptions.Compiled)]
    private static partial Regex E164PhoneRegex();

    [GeneratedRegex(@"^[\w\.-]+@[\w\.-]+\.\w{2,}$", RegexOptions.IgnoreCase)]
    private static partial Regex EmailRegex();

    public bool IsValidPhone(string input) => E164PhoneRegex().IsMatch(input);
    public bool IsValidEmail(string input) => EmailRegex().IsMatch(input);
}

// Idiomatic: static class for string extension with generated regex
public static partial class StringValidators
{
    [GeneratedRegex(@"\b\d{4}-\d{2}-\d{2}\b")]
    private static partial Regex DatePatternRegex();

    public static bool ContainsDate(this string input) =>
        DatePatternRegex().IsMatch(input);
}
```

### `System.Text.Json` Source Generation

`System.Text.Json` source generation produces optimized serialization code at build time, eliminating reflection-based overhead, reducing app size with AOT/trimming, and improving startup time. Add `[JsonSerializable(typeof(T))]` to a partial `JsonSerializerContext` class. Use the generated context in `JsonSerializer` calls.

```csharp
using System.Text.Json;
using System.Text.Json.Serialization;

// 1. Define the context — source generator produces serialization code
[JsonSerializable(typeof(Order))]
[JsonSerializable(typeof(List<Order>))]
[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    WriteIndented = false)]
internal partial class AppJsonContext : JsonSerializerContext { }

// 2. Use context for AOT-safe, reflection-free serialization
string json = JsonSerializer.Serialize(order, AppJsonContext.Default.Order);
Order? parsed = JsonSerializer.Deserialize(json, AppJsonContext.Default.Order);

// 3. In ASP.NET Core: register context for the whole app
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonContext.Default));
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

### **Record Computed Property Cached at Init — Stale After `with`**  [community]

A record property whose value is computed in a field initializer (using `=` rather than `=>`) is cached at construction time. WHY it causes problems: when you create a copy with `with { ... }`, the cached value reflects the original instance's data, not the modified copy. The bug is invisible at first because the values appear correct for the initial object.

```csharp
// BAD: Distance cached at init; stale after 'with' mutation
public record PointBad(double X, double Y)
{
    public double Distance { get; } = Math.Sqrt(X * X + Y * Y);  // cached once!
}

var p1 = new PointBad(3, 4);
var p2 = p1 with { Y = 0 };
Console.WriteLine(p1.Distance);  // 5.0 — correct
Console.WriteLine(p2.Distance);  // 5.0 — WRONG! should be 3.0

// GOOD: compute on access with expression-bodied property
public record PointGood(double X, double Y)
{
    public double Distance => Math.Sqrt(X * X + Y * Y);  // recomputed on each access
}

var q1 = new PointGood(3, 4);
var q2 = q1 with { Y = 0 };
Console.WriteLine(q2.Distance);  // 3.0 — correct
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

### **`async` Method Without `await` — Silent State Machine**  [community]

An `async` method body that contains no `await` expression compiles successfully but generates a warning. The method runs synchronously but still bears the overhead of the compiler-generated state machine. WHY it causes problems: it misleads callers who assume the method yields, wastes allocation overhead, and usually indicates a developer forgot to `await` something — potentially a silent logic error rather than just inefficiency. Fix: either add the missing `await`, or remove `async` and return a completed task with `Task.FromResult`.

```csharp
// BAD: async with no await — compiler warning CS1998, state machine overhead
public async Task<int> GetCountAsync()
{
    return _items.Count;  // no await — synchronous but wrapped in Task
}

// GOOD option 1: remove async, return Task.FromResult for synchronous result
public Task<int> GetCountAsync()
{
    return Task.FromResult(_items.Count);
}

// GOOD option 2: if calling path truly needs async, await the real operation
public async Task<int> GetCountAsync(CancellationToken ct)
{
    await _cache.WarmUpAsync(ct);
    return _items.Count;
}
```

### **LINQ + Async Lambdas — Deferred Execution Trap**  [community]

Using async lambdas inside LINQ operators like `Select` creates `Task<T>` objects but does not start them or await them. The tasks are only created when the sequence is enumerated, and if the IEnumerable is never materialized before `Task.WhenAll`, tasks start sequentially rather than concurrently. WHY it causes problems: what looks like parallel fan-out is actually sequential, silently running at 1x speed. Fix: always call `.ToArray()` or `.ToList()` immediately on LINQ expressions that project async lambdas, then pass the tasks array to `Task.WhenAll`.

```csharp
// BAD: tasks created lazily, NOT all started before WhenAll
var results = await Task.WhenAll(
    userIds.Select(id => GetUserAsync(id)));  // deferred — tasks start one at a time

// GOOD: materialize immediately so all tasks start before WhenAll
var tasks = userIds.Select(id => GetUserAsync(id)).ToArray();
var results = await Task.WhenAll(tasks);  // truly concurrent fan-out
```

### **Exception Swallowing in `catch` — Silent Corruption**  [community]

Catching a general `Exception` and doing nothing (or logging only) lets the program continue in an invalid state. WHY it causes problems: downstream code sees objects in partially-initialized or corrupted state, leading to failures far from the original cause that are nearly impossible to diagnose. Fix: only catch exceptions you can actually handle. If you must catch broadly, always re-throw (bare `throw`, not `throw ex`) after logging to preserve the original stack trace.

```csharp
// BAD: swallows all exceptions — program continues in invalid state
try
{
    await _repository.SaveAsync(order, ct);
}
catch (Exception)
{
    // nothing — order may not be saved, caller doesn't know
}

// BAD: throw ex — resets the stack trace, makes debugging impossible
catch (Exception ex)
{
    _logger.LogError(ex, "Save failed");
    throw ex;  // stack trace starts HERE, not at the original throw
}

// GOOD: log and re-throw with bare throw — preserves original stack trace
catch (Exception ex) when (LogAndReturnTrue(ex))
{
    throw;  // re-throws with original stack trace intact
}
// Or simply: catch, log, throw;
```

### **`Span<T>` Stored on the Heap — Compile Error or Runtime Corruption**  [community]

`Span<T>` is a stack-only ref struct. Storing it in a field, a `class`, a `List<T>`, or using it across an `await` point causes a compile error or unsafe behavior. WHY it causes problems: `Span<T>` wraps a pointer to stack memory; if that memory escapes to the heap, the pointer becomes dangling. Fix: use `Memory<T>` when you need a heap-storable buffer reference across async boundaries. Use `Span<T>` only for synchronous hot paths.

```csharp
// BAD: Span<T> cannot be a field — compile error
public class DataProcessor
{
    private Span<byte> _buffer;  // CS8345: Field cannot be of type Span<T>
}

// BAD: Span<T> cannot cross await boundary — compile error
public async Task ProcessAsync(Span<byte> data)  // CS4012: Span<T> cannot be parameter
{
    await Task.Delay(1);
    // use data — not allowed
}

// GOOD: use Memory<T> for heap/async scenarios
public async Task ProcessAsync(Memory<byte> data, CancellationToken ct)
{
    await Task.Delay(1, ct);
    var span = data.Span;  // get Span<T> only for synchronous processing
    Process(span);
}

// GOOD: use Span<T> for synchronous, zero-allocation parsing
public static int ParseInt(ReadOnlySpan<char> input)
    => int.Parse(input);  // no string allocation
```

### **`HttpClient` Instantiated per Request — Socket Exhaustion**  [community]

Creating a new `HttpClient` instance per request or in a `using` block causes socket exhaustion under load. WHY it causes problems: `HttpClient.Dispose()` closes the TCP connection but doesn't immediately release the socket; the OS keeps the socket in TIME_WAIT state. With high request rates, new sockets can't be opened. Fix: inject `IHttpClientFactory` (registers a singleton `HttpMessageHandler` pool) or register typed clients via `AddHttpClient<T>`.

```csharp
// BAD: new HttpClient per request — socket exhaustion at scale
public class WeatherService
{
    public async Task<string> GetForecastAsync()
    {
        using var client = new HttpClient();  // socket leak under load!
        return await client.GetStringAsync("https://api.weather.com/forecast");
    }
}

// GOOD: typed HttpClient — registered once, reuses pooled HttpMessageHandler
public class WeatherClient(HttpClient client)
{
    public async Task<string> GetForecastAsync(CancellationToken ct)
        => await client.GetStringAsync("/forecast", ct);
}

// Registration in Program.cs
builder.Services.AddHttpClient<WeatherClient>(c =>
    c.BaseAddress = new Uri("https://api.weather.com"));

// Usage via DI — WeatherClient is injected with a properly managed HttpClient
public class ForecastController(WeatherClient weather) : ControllerBase
{
    [HttpGet] public async Task<string> Get(CancellationToken ct)
        => await weather.GetForecastAsync(ct);
}
```

### **`static` mutable fields in web apps**  [community]

`static` mutable fields are shared across all threads in the process. WHY it causes problems: in web applications, multiple request threads read and write static state concurrently without synchronization, leading to torn reads, lost writes, and non-deterministic failures that are nearly impossible to reproduce in isolation. Fix: avoid `static` mutable state; use `Interlocked` for counters, `ConcurrentDictionary<>` for caches, and per-request scoped services via DI.

```csharp
// BAD: static mutable counter — race condition on every increment
public class RequestMetrics
{
    public static int RequestCount = 0;
    public static void Increment() => RequestCount++;  // NOT thread-safe
}

// GOOD: Interlocked for atomic operations on primitives
public static class RequestMetrics
{
    private static int _requestCount;
    public static int RequestCount => _requestCount;
    public static void Increment() => Interlocked.Increment(ref _requestCount);
}

// GOOD: ConcurrentDictionary for shared cache — all operations are atomic
private static readonly ConcurrentDictionary<string, string> _cache = new();
_cache.GetOrAdd(key, k => ComputeExpensiveValue(k));
```

### **Entity Framework N+1 Query — Lazy Navigation in a Loop**  [community]

Accessing a navigation property inside a loop without including it in the original query fires one additional SELECT per entity. WHY it causes problems: an operation that appears to load 100 orders actually fires 101 SQL queries — one for the list and one per order to fetch the related customer. This is invisible until you monitor the SQL output and is a leading cause of "it works in dev, dies in prod" performance bugs. Fix: use `.Include()` for eager loading or `.Select()` projections to load only needed data in a single query.

```csharp
// BAD: N+1 — loads 100 orders, then 100 separate SQL calls for Customer
var orders = await _db.Orders.ToListAsync(ct);
foreach (var order in orders)
{
    Console.WriteLine(order.Customer.Name);  // triggers SELECT per order!
}

// GOOD: single query with eager loading
var orders = await _db.Orders
    .Include(o => o.Customer)
    .ToListAsync(ct);

// ALSO GOOD: projection — only load the columns you need
var summaries = await _db.Orders
    .Select(o => new { o.Id, CustomerName = o.Customer.Name, o.Total })
    .ToListAsync(ct);
```

### **`DateTime.Now` vs `DateTime.UtcNow` — Timezone Bugs in Services**  [community]

Using `DateTime.Now` in a server-side service stores the server's local time, which varies per machine and timezone. WHY it causes problems: comparisons, sorting, and duration calculations break when services are deployed across regions or when daylight-saving time rolls over. Records stored with local time become inconsistent across a distributed system. Fix: always store and compare with `DateTime.UtcNow` or `DateTimeOffset.UtcNow`. Use `DateTimeOffset` when you also need to preserve the original offset for display.

```csharp
// BAD: local time — breaks in distributed or multi-region deployments
public class Event
{
    public DateTime CreatedAt { get; init; } = DateTime.Now;  // local time!
}

// GOOD: UTC time — timezone-independent comparisons
public class Event
{
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}

// BEST: DateTimeOffset preserves both UTC instant and original offset
public class Event
{
    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
}

// Comparison: always in UTC
bool isExpired = entity.ExpiresAt < DateTime.UtcNow;
```

### **Case-Insensitive String Comparison with `.ToLower()`**  [community]

Calling `.ToLower()` or `.ToUpper()` before comparing strings is culture-sensitive and fails in locales like Turkish, where `'I'.ToLower()` produces `'ı'` (dotless i), not `'i'`. WHY it causes problems: an authentication system that normalizes usernames with `.ToLower()` will allow `"ADMIN"` to log in but reject it after a Turkish locale deploy. Fix: use `string.Equals` with `StringComparison.OrdinalIgnoreCase` for invariant comparisons, or `StringComparison.CurrentCultureIgnoreCase` when locale-aware comparison is correct.

```csharp
// BAD: culture-sensitive — breaks in Turkish locale
if (username.ToLower() == "admin") { }

// GOOD: ordinal case-insensitive — invariant, works in all locales
if (string.Equals(username, "admin", StringComparison.OrdinalIgnoreCase)) { }

// In LINQ: use the overload with StringComparison
var match = users.FirstOrDefault(u =>
    string.Equals(u.Username, input, StringComparison.OrdinalIgnoreCase));

// String.Contains / StartsWith / EndsWith also accept StringComparison
if (path.Contains("users", StringComparison.OrdinalIgnoreCase)) { }
```

### **`ContinueWith` Instead of `async/await` — Nested Callback Hell**  [community]

Using `Task.ContinueWith` for sequential async operations creates deeply nested callback chains. WHY it causes problems: exceptions are wrapped in `AggregateException`, requiring manual `.Unwrap()` or inspection of `InnerExceptions`; unobserved faulted tasks crash the process on older .NET runtimes; and the code reads right-to-left rather than top-to-bottom, making control flow nearly impossible to follow. Fix: use `async`/`await` for all sequential async chains — the compiler produces the same state machine but the code is maintainable and exception handling is natural.

```csharp
// BAD: ContinueWith with nested lambdas — brittle, hard to read
Task<string> result = FetchAsync()
    .ContinueWith(t => ProcessAsync(t.Result))
    .Unwrap()
    .ContinueWith(t => t.Result.ToString());

// GOOD: async/await — sequential, debuggable, natural error handling
async Task<string> GetResultAsync(CancellationToken ct)
{
    var data = await FetchAsync(ct);
    var processed = await ProcessAsync(data, ct);
    return processed.ToString();
}
```

### **Non-Short-Circuit `&` / `|` in Boolean Guards — Unexpected NRE**  [community]

Using `&` (bitwise AND) instead of `&&` (conditional AND) in boolean conditions evaluates both operands even when the first is `false`. WHY it causes problems: a pattern like `if (obj != null & obj.Property > 0)` throws `NullReferenceException` when `obj` is null, because the right side is always evaluated. This is a common copy-paste error when developers confuse `&` (bitwise) with `&&` (logical short-circuit). Fix: always use `&&` and `||` in boolean conditions; reserve `&` and `|` for bitwise operations on integers.

```csharp
// BAD: NullReferenceException when order is null — both sides always evaluated
if (order != null & order.Items.Count > 0) { }

// GOOD: short-circuit — second clause skipped when order is null
if (order != null && order.Items.Count > 0) { }

// BAD: side effect fires even when condition is false
if (HasPermission() | Audit("access")) { }

// GOOD: Audit only called when HasPermission returns true
if (HasPermission() && Audit("access")) { }
```



Entity Framework Core tracks all entities it loads by default, maintaining a snapshot for change detection. For read-only queries this is pure overhead — it consumes memory for each snapshot and adds CPU time during `SaveChanges` for a diffing operation that is never needed. WHY it causes problems: a report that loads 10,000 rows allocates 10,000 change-tracking snapshots, significantly increasing GC pressure and response time. Fix: add `.AsNoTracking()` to any query whose results won't be updated and saved back through the same `DbContext`.

```csharp
// BAD: tracking enabled — EF keeps snapshots for entities never modified
var orders = await _db.Orders
    .Include(o => o.Items)
    .Where(o => o.CreatedAt > cutoff)
    .ToListAsync(ct);
// Every Order and OrderItem is tracked — wasted memory for a read-only report

// GOOD: AsNoTracking — no snapshots, no diffing overhead
var orders = await _db.Orders
    .AsNoTracking()
    .Include(o => o.Items)
    .Where(o => o.CreatedAt > cutoff)
    .ToListAsync(ct);

// GOOD GLOBALLY: set default for read-only contexts
_db.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;

// BEST PRACTICE: project to DTO directly — avoids loading unused columns too
var summaries = await _db.Orders
    .AsNoTracking()
    .Where(o => o.CreatedAt > cutoff)
    .Select(o => new OrderSummaryDto(o.Id, o.Total, o.Status))
    .ToListAsync(ct);
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
| Custom delegate types for generic callbacks | Clutters type namespace; harder to compose | Use `Func<T>` and `Action<T>` from the BCL |
| `async` method with no `await` in body | Silent state machine overhead, likely missing an `await` | Add missing `await` or return `Task.FromResult` without `async` |
| Task.Run in library code for I/O operations | Forces thread-pool usage onto callers; wrong for I/O | Only use `Task.Run` in app code for CPU-bound work |
| LINQ async lambda without `.ToArray()` before `WhenAll` | Sequential execution instead of concurrent fan-out | Materialize tasks array first, then `await Task.WhenAll(tasks)` |
| `using` directive inside namespace block | Name resolution is context-sensitive, breaks silently on new deps | Place all `using` directives at file level, outside namespace |
| `catch (Exception ex)` then `throw ex` | Resets stack trace — original throw location is lost | Use bare `throw` to re-throw, preserving the original stack trace |
| Storing `Span<T>` in a field or across `await` | Compile error or dangling pointer to freed stack memory | Use `Memory<T>` for heap-storable and async-safe buffer references |
| `new HttpClient()` per request | Socket exhaustion — OS keeps sockets in TIME_WAIT state | Use `IHttpClientFactory` or typed clients registered via `AddHttpClient<T>` |
| `static` mutable fields in web apps | Race conditions — multiple threads corrupt shared state | Use `Interlocked`, `ConcurrentDictionary`, or scoped DI services |
| Record computed property cached with `=` | Stale value after `with` expression mutation | Use expression-bodied `=>` to recompute on each access |
| `IOptions<T>.Value` in singleton for live config | Config changes not reflected; snapshot at startup | Use `IOptionsMonitor<T>.CurrentValue` for live-reloadable config |
| `lock(this)` or locking on `typeof(T)` | Deadlock — external code can acquire same monitor | Use `private readonly Lock _lock = new()` (.NET 9+) or `private readonly object _sync = new()` |
| `Task.Delay(0)` as a yield shortcut in tight loops | Does not actually yield the thread; scheduler may immediately resume on same thread | Use `await Task.Yield()` to force rescheduling, or throttle with a real delay |
| Entity Framework N+1 query — lazy navigation in a loop | Each loop iteration fires a new SELECT; 100 items = 101 queries | Use `.Include()` eager loading or explicit `.Select()` projections |
| String `.ToLower()` for case-insensitive comparison | Culture-sensitive; breaks in Turkish locale where 'I'.ToLower() ≠ 'i' | Use `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` |
| `DateTime.Now` vs `DateTime.UtcNow` in services | `Now` is local time, varies per server timezone; comparisons break across servers | Always use `DateTime.UtcNow` or `DateTimeOffset.UtcNow` in services and DB columns |
| EF Core read queries without `.AsNoTracking()` | Allocates change-tracking snapshots for all loaded entities; pure overhead for read-only queries | Add `.AsNoTracking()` to every query that won't call `SaveChanges` |
| Case-insensitive compare with `.ToLower()` | Culture-sensitive; produces wrong result in Turkish and other locales | Use `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` |
| Manual null guard `if (x == null) throw` | Verbose and error-prone; forgetting `nameof` gives unhelpful exception messages | Use `ArgumentNullException.ThrowIfNull(x)` (.NET 8+) |
| `ContinueWith` for sequential async | Nested lambdas, `AggregateException` wrapping, unobserved faults | Use `async`/`await` for all sequential async chains |
| `&` / `|` in boolean guards | Both sides always evaluated; NRE when left side is null | Use `&&` / `||` for short-circuit boolean evaluation |
| Regex compiled at runtime inside a method | New `Regex` object allocated on every call; parsing overhead per invocation | Use `[GeneratedRegex]` attribute with partial method for compile-time regex |
