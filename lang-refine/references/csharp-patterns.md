# C# Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 31 | score: 100/100 | date: 2026-05-12 -->
<!-- iteration trace (latest):
     Iter 23 (2026-05-04): expanded Records section with inheritance, positional vs nominal syntax, shallow
       immutability clarification, `with` on derived records, EF Core incompatibility; added .NET Testing
       Frameworks overview (MSTest/NUnit/xUnit/TUnit, VSTest vs MTP) — sourced from
       learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record and
       learn.microsoft.com/dotnet/core/testing/
     Iter 24 (2026-05-08): added Nullable Value Types deep-dive — T? syntax, Nullable<T> struct,
       HasValue/Value, null-coalescing ??, GetValueOrDefault(), is-pattern safe extraction,
       lifted operators, boxing/unboxing behavior, Nullable.GetUnderlyingType(), and anti-patterns table
       sourced from learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/nullable-value-types
     Iter 25 (2026-05-12): added Task.WhenAny — competitive race pattern for first-completed task
       dispatch; added async exception handling with AggregateException unwrapping — sourced from
       learn.microsoft.com/dotnet/csharp/asynchronous-programming/
     Iter 26 (2026-05-12): added C# 14 User-Defined Compound Assignment Operators — void instance
       operator +=/-=/*= etc for in-place mutation, instance increment operators, override/new modifiers —
       sourced from learn.microsoft.com/dotnet/csharp/language-reference/proposals/csharp-14.0/user-defined-compound-assignment
     Iter 27 (2026-05-12): added FrozenDictionary/FrozenSet, SearchValues<T>, TimeProvider, OrderedDictionary<TKey,TValue>,
       Dictionary.GetAlternateLookup, ServerSentEvents; added community gotchas: magic strings, early-return guard clauses,
       PriorityQueue misuse — sourced from learn.microsoft.com/dotnet/core/whats-new/dotnet-9/libraries and
       official async programming docs
     Iter 28 (2026-05-12): added File-Based Apps (C# 14 #!/# directives), ASP.NET Core 10
       built-in validation (AddValidation/[ValidatableType]), TypedResults.ServerSentEvents,
       [PersistentState] for Blazor prerendering; added WebSocketStream (.NET 10 networking);
       added community gotchas: `field` keyword naming conflict, extension member resolution
       ambiguity vs old-style extension methods — sourced from learn.microsoft.com/dotnet/csharp/whats-new/csharp-14
       and learn.microsoft.com/aspnet/core/release-notes/aspnetcore-10.0
     Iter 29 (2026-05-12): added EF Core 10 Named Query Filters, Vector Search (SqlVector<float>),
       LeftJoin/RightJoin LINQ operators, Complex Types (table splitting + JSON mapping), ExecuteUpdateAsync
       improvements; added .NET 10 library APIs: JsonSerializerOptions.Strict, AllowDuplicateProperties,
       PipeReader JSON deserialization, CompareOptions.NumericOrdering, Post-Quantum Cryptography
       (MLKem/MLDsa/SlhDsa), ZipArchive async APIs; added community gotchas: EF Core parameterized
       collection mode selection, SQL injection analyzer for FromSqlRaw — sourced from
       learn.microsoft.com/ef/core/what-is-new/ef-core-10.0 and
       learn.microsoft.com/dotnet/core/whats-new/dotnet-10/libraries
     Iter 30 (2026-05-12): added ASP.NET Core 10 OpenAPI 3.1 / YAML / XML-doc-comment integration,
       Cookie Auth 401/403 fix for API endpoints, IMemoryPoolFactory<T> for DI memory pools,
       X509Certificate2Collection.FindByThumbprint with SHA-256, Blazor JS Interop property get/set
       and constructor APIs; added community gotchas: OpenAPI 3.1 nullable schema breaking change,
       Cookie redirect-to-login API surprise — sourced from
       learn.microsoft.com/aspnet/core/release-notes/aspnetcore-10.0 and
       learn.microsoft.com/dotnet/core/whats-new/dotnet-10/libraries
     Iter 31 (2026-05-12): added C# 14 deep-dives — `extension` blocks (instance/static extension
       properties, extension operators, generic extension blocks), `field`-backed properties (lazy
       init, INotifyPropertyChanged pattern, struct readonly rules, breaking change disambiguation),
       null-conditional assignment (?. on LHS, compound assignment, right-side short-circuit),
       first-class Span implicit conversions (new conversion matrix, ReadOnlySpan betterness,
       `Reverse()` returns void breaking change, xUnit Assert.Equal ambiguity, covariant array
       ArrayTypeMismatchException, expression-tree Span incompatibility); added community gotchas:
       Span implicit conversion breaks Reverse(), xUnit ambiguity, covariant array crash, expression
       tree LINQ-to-SQL provider surprise; added ASP.NET Core 10 additional breaking changes —
       Blazor NavigateTo no longer throws, HttpClient response streaming, exception handler logging
       suppressed — sourced from learn.microsoft.com/dotnet/csharp/whats-new/csharp-14,
       learn.microsoft.com/dotnet/csharp/language-reference/keywords/extension,
       learn.microsoft.com/dotnet/csharp/language-reference/proposals/csharp-14.0/field-keyword,
       learn.microsoft.com/dotnet/csharp/language-reference/proposals/csharp-14.0/first-class-span-types,
       learn.microsoft.com/dotnet/csharp/language-reference/operators/member-access-operators
-->

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

### Records — Immutable Value Objects (Deep Dive)

Records provide concise syntax for immutable data types with value equality, built-in `ToString`, and nondestructive mutation via `with`. Use `record class` for reference types with value semantics (DTOs, query results, domain events). Use `record struct` for small, stack-allocated value types.

**Two declaration syntaxes:**

```csharp
// Positional syntax — compiler generates: public init-only properties, primary constructor,
// Equals/GetHashCode/ToString, Deconstruct method
public record Person(string FirstName, string LastName);

// Nominal syntax — explicit properties; use when you need different access modifiers
public record Person
{
    public required string FirstName { get; init; }
    public required string LastName  { get; init; }
}

// record struct — value type (stack-allocated, no GC pressure)
public readonly record struct Point(double X, double Y);

// record struct (mutable variant — NOT readonly)
public record struct DataMeasurement(DateTime TakenAt, double Measurement);
```

**Value equality — by content, not by reference:**

```csharp
public record Person(string FirstName, string LastName);

var p1 = new Person("Nancy", "Davolio");
var p2 = new Person("Nancy", "Davolio");

Console.WriteLine(p1 == p2);              // True — value equality
Console.WriteLine(ReferenceEquals(p1, p2)); // False — different objects

// WARNING: value equality is shallow — reference-type fields compare references
var phoneNumbers = new string[1] { "555-1234" };
var pa = new Person("Alice", "Smith") { /* can't add array here in positional */ };
// (Use nominal syntax to add array fields)
```

**Nondestructive mutation with `with`:**

```csharp
public record Order(int Id, string Status, string Region);

var original = new Order(1, "Pending", "West");
var shipped  = original with { Status = "Shipped" };   // Creates a NEW instance
var rerouted = original with { Status = "Shipped", Region = "East" };

Console.WriteLine(original.Status);         // Pending — original unchanged
Console.WriteLine(shipped.Status);          // Shipped
Console.WriteLine(original == shipped);     // False
Console.WriteLine(original == rerouted);    // False

// IMPORTANT: Computed properties must use => (expression-bodied), NOT = (field init)
// With '=', the value is computed at construction time and cached — WRONG after 'with':
public record BadCircle(double Radius)
{
    public double Area { get; } = Math.PI * Radius * Radius;  // WRONG: stale after 'with'
}

public record Circle(double Radius)
{
    public double Area => Math.PI * Radius * Radius;  // CORRECT: recomputed on access
}

var c1 = new Circle(3);
var c2 = c1 with { Radius = 4 };
Console.WriteLine(c2.Area);  // 50.26... — correct (Circle)
```

**Records with inheritance:**

```csharp
// Records can only inherit from other records (not classes)
public abstract record Vehicle(string Make, string Model);
public record Car(string Make, string Model, int Doors) : Vehicle(Make, Model);
public record Truck(string Make, string Model, double PayloadTons) : Vehicle(Make, Model);

// Value equality checks RUNTIME TYPE — two different record types are never equal
Vehicle car   = new Car("Toyota", "Camry", 4);
Vehicle truck = new Truck("Toyota", "Tacoma", 1.5);
Console.WriteLine(car == truck);  // False — different runtime types

var car2 = new Car("Toyota", "Camry", 4);
Console.WriteLine(car == car2);   // True — same type and values

// Deconstruct uses compile-time type (cast to derived type for all params)
var (make, model) = car;           // Only Vehicle params (compile-time type)
var (make2, model2, doors) = (Car)car;  // All Car params
```

**Shallow immutability — arrays and collections can still be mutated:**

```csharp
public record Person(string FirstName, string LastName, string[] PhoneNumbers);

var person = new Person("Alice", "Smith", new[] { "555-1234" });
person.PhoneNumbers[0] = "555-9999";  // This WORKS — array contents are mutable!
// The reference to the array is init-only, not the array's contents.

// Fix: use immutable collection types
public record SafePerson(string FirstName, string LastName, IReadOnlyList<string> PhoneNumbers);
// Or: System.Collections.Immutable.ImmutableArray<string>
```

**When NOT to use records — EF Core entity types:**

```csharp
// DO NOT use records as EF Core entity types.
// EF Core requires reference equality to track entity identity (same DB row = same object).
// Records use value equality — EF Core cannot distinguish two instances with identical values,
// causing incorrect change tracking, duplicate inserts, and data corruption.

// Use regular classes for EF Core entities:
public class OrderEntity       // class — reference equality
{
    public int Id { get; set; }
    public string Status { get; set; } = "";
}

// Use records for query result projections (read-only DTOs — no EF tracking):
public record OrderDto(int Id, string Status, decimal Total);
```

### .NET Testing Frameworks Overview

.NET supports four major test frameworks, each with slightly different philosophy and setup. All are compatible with `dotnet test` on the CLI.

**Framework comparison:**

| Framework | Philosophy | Key attributes | Platform support |
|---|---|---|---|
| **xUnit.net** | Modern; no setup/teardown in base class; constructor injection for fixtures | `[Fact]`, `[Theory]`, `[InlineData]` | VSTest + MTP |
| **NUnit** | Port of JUnit; rich built-in assertions; flexible fixture model | `[Test]`, `[TestCase]`, `[SetUp]`, `[TearDown]` | VSTest + MTP |
| **MSTest** | Microsoft's built-in; IDE integration; V2 fully open-source | `[TestMethod]`, `[DataRow]`, `[TestInitialize]` | VSTest + MTP |
| **TUnit** | Built entirely on MTP; async-native; no VSTest dependency | `[Test]`, `[Arguments]`, `[DataSourceDriven]` | MTP only |

**VSTest vs Microsoft Testing Platform (MTP):**
- **VSTest** — the classic test host used by VS 2019 and earlier; well established, broad support.
- **MTP (Microsoft.Testing.Platform)** — the modern replacement; faster startup, better parallelism, unified protocol. xUnit v3, NUnit, and MSTest all support MTP as of 2024–2025.
- For new projects, prefer frameworks that support MTP (xUnit v3 recommended by the community; MSTest V3 for Microsoft-first teams).

**Minimal xUnit setup:**

```csharp
// Install: dotnet add package xunit xunit.runner.visualstudio
// MyFeature.Tests/CalculatorTests.cs
using Xunit;

public class CalculatorTests
{
    [Fact]
    public void Add_TwoNumbers_ReturnsSum()
    {
        var calc = new Calculator();
        var result = calc.Add(2, 3);
        Assert.Equal(5, result);
    }

    [Theory]
    [InlineData(2, 3, 5)]
    [InlineData(-1, 1, 0)]
    [InlineData(0, 0, 0)]
    public void Add_VariousInputs_ReturnsCorrectSum(int a, int b, int expected)
    {
        var calc = new Calculator();
        Assert.Equal(expected, calc.Add(a, b));
    }
}
```

**ASP.NET Core integration testing (xUnit + WebApplicationFactory):**

```csharp
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;
using Xunit;

public class OrdersApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrdersApiTests(WebApplicationFactory<Program> factory)
    {
        // Creates an in-memory test server — no port allocation needed
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetOrders_ReturnsOk()
    {
        var response = await _client.GetAsync("/api/orders");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

---

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

### `FrozenDictionary<TKey,TValue>` and `FrozenSet<T>` — Read-Only Lookup Tables (.NET 8+)

`FrozenDictionary<TKey,TValue>` and `FrozenSet<T>` are immutable, read-optimized collections built for data that is written once at startup and read many millions of times afterwards. They trade slower construction (O(N) build with analysis) for faster lookups than `Dictionary<T>` and `HashSet<T>` at steady state. Use them for static lookup tables: allowed HTTP methods, country codes, feature flags, known command names.

```csharp
using System.Collections.Frozen;

// Build once at startup — typically in DI registration or static constructor
public static class AllowedCountryCodes
{
    // FrozenSet performs better than HashSet<T> for Contains checks in hot paths
    private static readonly FrozenSet<string> _codes = new[]
    {
        "US", "CA", "GB", "AU", "DE", "FR", "JP", "SG"
    }.ToFrozenSet(StringComparer.OrdinalIgnoreCase);

    public static bool IsAllowed(string code) => _codes.Contains(code);
}

// FrozenDictionary: read-only key-value lookup, faster than Dictionary for read-heavy use
public class CommandDispatcher
{
    private static readonly FrozenDictionary<string, Func<Task>> _handlers =
        new Dictionary<string, Func<Task>>(StringComparer.OrdinalIgnoreCase)
        {
            ["ping"]    = () => Task.CompletedTask,
            ["status"]  = GetStatusAsync,
            ["restart"] = RestartAsync
        }.ToFrozenDictionary(StringComparer.OrdinalIgnoreCase);

    public Task DispatchAsync(string command)
    {
        if (_handlers.TryGetValue(command, out var handler))
            return handler();
        throw new InvalidOperationException($"Unknown command: {command}");
    }
}

// Performance comparison guideline:
// FrozenDictionary/FrozenSet:   O(1) lookup, ~2–4x faster than Dictionary for Contains/TryGetValue
// Dictionary/HashSet:           O(1) amortized lookup with resize overhead
// Linear scan (List<T>.Contains): O(N) — never use for membership checks
```

**When to use:** application startup data (routing tables, permission sets, feature flag registries). Do NOT use for data that changes after initialization — `FrozenDictionary` is completely immutable once built.

### `SearchValues<T>` — High-Performance Character and Substring Search (.NET 8+)

`SearchValues<T>` (in `System.Buffers`) provides SIMD-accelerated searching for sets of characters or bytes within spans. It is significantly faster than `string.IndexOfAny` with multiple characters because it precomputes a lookup structure once and reuses it across many searches. .NET 9 extends `SearchValues` to support multi-string substring search.

```csharp
using System.Buffers;

public static class InputSanitizer
{
    // Create once — SearchValues precomputes a SIMD-optimized lookup at creation time
    private static readonly SearchValues<char> _specialChars =
        SearchValues.Create(['<', '>', '"', '\'', '&', '\0']);

    private static readonly SearchValues<string> _sqlKeywords =
        SearchValues.Create(["DROP", "DELETE", "TRUNCATE", "INSERT", "--"],
            StringComparison.OrdinalIgnoreCase);

    // Check for any dangerous character — much faster than char-by-char scan
    public static bool ContainsSpecialChar(ReadOnlySpan<char> input)
        => input.IndexOfAny(_specialChars) >= 0;

    // Check for SQL injection keywords — .NET 9 multi-string search
    public static bool MightContainSql(string input)
        => input.AsSpan().IndexOfAny(_sqlKeywords) >= 0;

    // Example: tokenize without allocating using EnumerateSplits (.NET 9)
    public static IEnumerable<string> SplitOnDelimiters(ReadOnlySpan<char> input)
    {
        var delimiters = SearchValues.Create([',', ';', '|', '\t']);
        var results = new List<string>();
        int start = 0;
        int idx;
        while ((idx = input[start..].IndexOfAny(delimiters)) >= 0)
        {
            results.Add(input.Slice(start, idx).ToString());
            start += idx + 1;
        }
        results.Add(input[start..].ToString());
        return results;
    }
}
```

### `TimeProvider` — Testable Time Abstraction (.NET 8+)

`TimeProvider` (in `System.Threading`) is an abstract class that abstracts time (`UtcNow`, `LocalNow`), timer creation, and timestamp measurement. Inject it via DI instead of calling `DateTime.UtcNow` directly, so tests can control the current time without patching `DateTime` or using delays.

```csharp
using System.Threading;

// Service: depend on TimeProvider instead of DateTime.UtcNow
public class SubscriptionService(
    ISubscriptionRepository repo,
    TimeProvider timeProvider,
    ILogger<SubscriptionService> logger)
{
    public async Task<bool> IsSubscriptionActiveAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var subscription = await repo.GetAsync(userId, ct);
        if (subscription is null) return false;

        // Use timeProvider instead of DateTime.UtcNow — testable
        DateTimeOffset now = timeProvider.GetUtcNow();
        return subscription.ExpiresAt > now;
    }

    public ITimer CreateRenewalReminder(
        Guid userId,
        TimeSpan daysBeforeExpiry,
        Func<Task> reminderAction)
    {
        // ITimer created via TimeProvider is also controllable in tests
        return timeProvider.CreateTimer(
            async _ => await reminderAction(),
            state: null,
            dueTime: daysBeforeExpiry,
            period: Timeout.InfiniteTimeSpan);
    }
}

// Registration in Program.cs — production uses the real time
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<SubscriptionService>();

// In unit tests — use FakeTimeProvider (from Microsoft.Extensions.TimeProvider.Testing)
// FakeTimeProvider fakeTime = new();
// fakeTime.SetUtcNow(DateTimeOffset.Parse("2026-01-01"));
// fakeTime.Advance(TimeSpan.FromDays(30));
// var sut = new SubscriptionService(mockRepo, fakeTime, NullLogger<...>.Instance);
```

### `OrderedDictionary<TKey,TValue>` — Insertion-Order Key-Value Collection (.NET 9)

`OrderedDictionary<TKey,TValue>` maintains insertion order while providing O(1) key lookups. It supports index-based access (`d.GetAt(i)`) and index-based removal (`d.RemoveAt(i)`). Use it when you need both ordered enumeration and fast key lookup — for example, processing pipelines, ordered configuration sections, or step-by-step workflow state.

```csharp
using System.Collections.Generic;

// Build an ordered pipeline where steps execute in insertion order
// but can also be retrieved by name
var pipeline = new OrderedDictionary<string, Func<string, string>>(StringComparer.OrdinalIgnoreCase)
{
    ["trim"]      = s => s.Trim(),
    ["lowercase"] = s => s.ToLowerInvariant(),
    ["normalize"] = s => System.Text.RegularExpressions.Regex.Replace(s, @"\s+", " ")
};

// Enumerate in insertion order
string Process(string input)
{
    foreach (var (name, step) in pipeline)
        input = step(input);
    return input;
}

// Fast key lookup — does this step exist?
if (pipeline.ContainsKey("lowercase"))
    Console.WriteLine("lowercase step is registered");

// Index-based access — get the second step regardless of name
var (stepName, stepFn) = pipeline.GetAt(1);

// Insert at position — unlike Dictionary, order is deterministic
pipeline.Insert(0, "sanitize", s => s.Replace("<", "&lt;"));

// Remove by index — remove first step
pipeline.RemoveAt(0);
```

### `Dictionary.GetAlternateLookup` — Zero-Allocation Span Lookups (.NET 9)

In high-throughput code, looking up dictionary keys using a `ReadOnlySpan<char>` (from a split or slice) avoids the need to allocate a `string` for the key. `GetAlternateLookup<TAlternateKey>()` returns an `AlternateLookup` struct that performs the lookup using the span without materializing a string, provided the comparer implements `IAlternateEqualityComparer<TAlternateKey, TKey>`.

```csharp
// Word frequency counter without allocating a string per word
static Dictionary<string, int> CountWords(ReadOnlySpan<char> text)
{
    var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

    // AlternateLookup: accepts ReadOnlySpan<char>, no string allocation per lookup
    var lookup = counts.GetAlternateLookup<ReadOnlySpan<char>>();

    int start = 0;
    for (int i = 0; i <= text.Length; i++)
    {
        bool atBoundary = i == text.Length || !char.IsLetterOrDigit(text[i]);
        if (atBoundary && i > start)
        {
            ReadOnlySpan<char> word = text[start..i];
            lookup[word] = lookup.TryGetValue(word, out int count) ? count + 1 : 1;
            // Key is only materialized to string when a new entry is created
        }
        if (atBoundary) start = i + 1;
    }

    return counts;
}

// Works with HashSet<T>.GetAlternateLookup too
HashSet<string> allowedNames = new(["Alice", "Bob", "Carol"], StringComparer.OrdinalIgnoreCase);
var setLookup = allowedNames.GetAlternateLookup<ReadOnlySpan<char>>();

ReadOnlySpan<char> candidate = "alice".AsSpan();
bool isAllowed = setLookup.Contains(candidate);  // no allocation
```

### `Task.WhenAny` — First-Completed Task Dispatch

`Task.WhenAny` returns a `Task<Task>` that completes as soon as any one of the supplied tasks finishes. Use it when you want to process results as they arrive (competitive race), implement a timeout alongside real work, or drain a queue of tasks one at a time in completion order rather than submission order. After `WhenAny` resolves, **always `await` the completed inner task** to propagate exceptions — `WhenAny` itself never throws even if all tasks are faulted.

```csharp
// Pattern 1: process results as each task finishes (completion-order drain)
public async Task ProcessAllAsync(
    IReadOnlyList<int> ids,
    CancellationToken ct)
{
    var pending = ids
        .Select(id => _repository.GetAsync(id, ct))
        .ToList();                        // materialize so all tasks start now

    while (pending.Count > 0)
    {
        Task<Item> finished = await Task.WhenAny(pending);
        pending.Remove(finished);

        // await the inner task to surface any exception it may have thrown
        Item item = await finished;
        await _processor.HandleAsync(item, ct);
    }
}

// Pattern 2: race a real operation against a timeout
public async Task<string> FetchWithTimeoutAsync(
    string url,
    TimeSpan timeout,
    CancellationToken ct)
{
    using var timeoutCts = new CancellationTokenSource(timeout);
    using var linked = CancellationTokenSource.CreateLinkedTokenSource(
        ct, timeoutCts.Token);

    Task<string> fetchTask = _httpClient.GetStringAsync(url, linked.Token);
    Task<string> timeoutTask = Task.FromException<string>(
        new TimeoutException($"Fetch of '{url}' exceeded {timeout.TotalSeconds}s"));

    Task<string> delayTask = Task.Delay(timeout, ct)
        .ContinueWith(_ => (string)null!, TaskContinuationOptions.OnlyOnRanToCompletion);

    Task<string> winner = await Task.WhenAny(fetchTask, delayTask);
    if (winner == delayTask)
        throw new TimeoutException($"Fetch of '{url}' exceeded {timeout.TotalSeconds}s");

    return await fetchTask;  // await original to get result or propagate exception
}

// Pattern 3: fan-out with WhenAll (preferred when order doesn't matter)
// Use WhenAll when you need ALL results and don't care about order:
var results = await Task.WhenAll(ids.Select(id => _repository.GetAsync(id, ct)));
```

**Key rules:**
- `Task.WhenAny` does NOT cancel the losing tasks — you must cancel them yourself via `CancellationToken`.
- `Task.WhenAny` never faults — always `await finished` inside the loop to surface faults.
- Materialize the task list with `.ToList()` before passing to `WhenAny`; lazy LINQ sequences create tasks one at a time instead of starting them all concurrently.

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

### File-Based Apps — C# 14 Preprocessor Directives (`#!` / `#:`)

C# 14 and the .NET 10 SDK support *file-based apps*: single `.cs` files compiled and run with `dotnet run Program.cs` without a `.csproj`. Two new preprocessor prefixes support this mode:

- **`#!`** — Unix shebang line. Ignored by the C# compiler; used by the OS to invoke `dotnet` directly.
- **`#:`** — Build directive. Passed to the SDK to configure the file's compilation (SDK version, package references, etc.). Silently ignored by the compiler but emits a warning if used in a project-based compilation.

```csharp
#!/usr/bin/env dotnet
// ^ Unix-only: chmod +x hello.cs; ./hello.cs runs this file

#:sdk Microsoft.NET.Sdk
#:property LangVersion preview
#:package Humanizer 2.14.1

using Humanizer;

Console.WriteLine(3.ToWords());        // "three"
Console.WriteLine("hello_world".Pascalize());  // "HelloWorld"
```

**Running a file-based app:**

```bash
# Compile and run in one step — no .csproj needed
dotnet run hello.cs

# Unix: make executable and invoke directly
chmod +x hello.cs
./hello.cs
```

**Why it matters:** file-based apps lower the barrier for scripts, quick experiments, and CI utilities without a full project setup. The `#:` directives compose — you can pin SDK versions, add NuGet packages, and set compiler options all inline. Use this for tooling scripts and one-off utilities; keep long-lived production code in proper projects for IDE support and multi-file organization.

**Limitation:** the C# compiler itself ignores `#!` and `#:` entirely (it doesn't error on them either). The SDK build system parses them. If you accidentally include `#:` in a project-based compilation, the compiler emits a warning.

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

### C# 14 — User-Defined Compound Assignment Operators

C# 14 (.NET 10) lets types declare `void` **instance** operator methods for compound assignment (`+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`) and increment/decrement (`++`, `--`). The compiler prefers the instance form over the traditional pattern of `x = x + y`, enabling **in-place mutation** and eliminating unnecessary allocations for mutable types like `BigInteger`, tensor buffers, or custom numeric types.

```csharp
// Before C# 14: += synthesized as x = operator+(x, y) — allocates a new instance
class Matrix
{
    public static Matrix operator +(Matrix x, Matrix y) => new Matrix(/* copy + add */);
}
var m = new Matrix();
m += other;  // allocates a brand-new Matrix, assigns to m, old m is abandoned

// C# 14: void instance operator += — mutates in place, no allocation
class Matrix
{
    private double[] _data;

    // Binary + still needed for immutable-style expressions: var c = a + b
    public static Matrix operator +(Matrix x, Matrix y) => new Matrix(/* copy + add */);

    // Instance += — in-place, no allocation
    public void operator +=(Matrix other)
    {
        for (int i = 0; i < _data.Length; i++)
            _data[i] += other._data[i];
    }

    // Instance ++ — in-place increment
    public void operator ++()
    {
        for (int i = 0; i < _data.Length; i++)
            _data[i]++;
    }
}

Matrix m = new Matrix(rows: 512, cols: 512);
m += delta;   // calls void operator += in-place — zero allocation
++m;          // calls void operator ++ in-place — zero allocation
```

**Rules:**
- The compound assignment operator must be an **instance method** with `void` return type and exactly one parameter.
- The increment/decrement operator must be an **instance method** with `void` return type and no parameters.
- The `static` modifier is **not** allowed on these forms (static form uses binary operator + assignment as before).
- A `checked operator +=` requires a paired non-checked `operator +=`.
- When both an instance `+=` and a static `+` are defined, `x += y` uses the instance form; `var z = x + y` still uses the static binary form.
- The `override` and `new` modifiers allow derived types to override or shadow a base class compound operator.

**When to use:** large mutable value types (`BigInteger`, `Matrix`, `Tensor`, custom fixed-point arithmetic). Do **not** use for types intended to be immutable — the classic static operator pattern is correct for records and value objects.

 and requires manual error handling, nested lambdas, and `Unwrap()` calls to chain operations. `async`/`await` compiles to an equivalent state machine but reads like synchronous code. Use `ContinueWith` only in rare low-level scenarios (e.g., advanced scheduler control). The official docs explicitly recommend `async`/`await` for all new code.

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

### `System.Net.ServerSentEvents` — Streaming API Consumption (.NET 9)

Server-sent events (SSE) is the protocol used by AI services (OpenAI, Azure AI) and other streaming APIs to push data to the client incrementally. .NET 9 adds `SseParser` in `System.Net.ServerSentEvents` for allocation-efficient SSE consumption using `IAsyncEnumerable<SseItem<T>>`.

```csharp
using System.Net.ServerSentEvents;
using System.Net.Http;

// Consume an SSE stream (e.g., from an AI chat endpoint)
public async IAsyncEnumerable<string> StreamChatAsync(
    string prompt,
    [EnumeratorCancellation] CancellationToken ct = default)
{
    using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/chat/completions");
    request.Content = JsonContent.Create(new { prompt, stream = true });
    request.Headers.Accept.Add(new("text/event-stream"));

    using var response = await _httpClient.SendAsync(
        request,
        HttpCompletionOption.ResponseHeadersRead,
        ct);

    response.EnsureSuccessStatusCode();
    await using var stream = await response.Content.ReadAsStreamAsync(ct);

    // SseParser yields items as they arrive — no buffering of the full response
    await foreach (SseItem<string> item in SseParser.Create(stream).EnumerateAsync(ct))
    {
        if (item.Data is "[DONE]") yield break;
        if (!string.IsNullOrEmpty(item.Data))
            yield return item.Data;
    }
}
```

**Why it matters:** before .NET 9, SSE consumption required manual line-by-line parsing of the response stream. `SseParser` handles the SSE protocol framing (event/data/id/retry fields) correctly, including multi-line data events.

### Early-Return Guard Clauses — Flatten Nesting, Not Complexity

Guard clauses validate preconditions at the top of a method and return early, eliminating the need for a deeply nested `if` tree. The main logic path then proceeds with all guarantees satisfied, making the code read top-to-bottom without rightward drift. Combine with `ArgumentNullException.ThrowIfNull` and pattern matching for the most expressive form.

```csharp
// BAD: deeply nested — must read all the way to the right to find the happy path
public async Task<OrderDto?> ProcessOrderAsync(
    OrderRequest? request,
    CancellationToken ct)
{
    if (request != null)
    {
        if (request.Items.Count > 0)
        {
            if (await _inventory.HasStockAsync(request.Items, ct))
            {
                var order = await _repository.CreateAsync(request, ct);
                return order.ToDto();
            }
        }
    }
    return null;
}

// GOOD: guard clauses — happy path runs at the left margin
public async Task<OrderDto?> ProcessOrderAsync(
    OrderRequest? request,
    CancellationToken ct)
{
    if (request is null)          return null;
    if (request.Items.Count == 0) return null;
    if (!await _inventory.HasStockAsync(request.Items, ct)) return null;

    var order = await _repository.CreateAsync(request, ct);
    return order.ToDto();
}

// In public APIs — throw rather than return null for invalid arguments
public async Task<Order> PlaceOrderAsync(
    OrderRequest request,
    CancellationToken ct = default)
{
    ArgumentNullException.ThrowIfNull(request);
    ArgumentOutOfRangeException.ThrowIfZero(request.Items.Count);

    // main logic — every precondition above is guaranteed
    return await _repository.CreateAsync(request, ct);
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

### **`DateTime.UtcNow` Called Directly in Services — Untestable Time**  [community]

Calling `DateTime.UtcNow` or `DateTimeOffset.UtcNow` directly in service code makes time-dependent logic untestable without process-level time patching. WHY it causes problems: you cannot advance time, freeze it, or simulate "now is tomorrow" in a unit test without hacks. Services that schedule reminders, expire sessions, or enforce trial periods are implicitly coupled to the system clock. Fix: inject `TimeProvider` (available since .NET 8) and call `timeProvider.GetUtcNow()` instead. Tests inject `FakeTimeProvider` from the `Microsoft.Extensions.TimeProvider.Testing` package to control time deterministically.

```csharp
// BAD: direct clock call — no way to test "what happens in 30 days"
public bool IsTrialExpired(User user)
    => DateTime.UtcNow > user.TrialStartedAt.AddDays(30);

// GOOD: inject TimeProvider — fake it in tests
public bool IsTrialExpired(User user)
    => _timeProvider.GetUtcNow() > user.TrialStartedAt.AddDays(30);
```

### **Magic Strings for Domain Constants — Silent Typo Bugs**  [community]

Embedding string literals directly in conditionals, switch expressions, or dictionary keys creates silent typo bugs. WHY it causes problems: `"Admininstrator"` compiles and runs fine; the bug only surfaces at runtime when the permission check silently fails. In a codebase where the same string appears in 12 files, renaming it requires a grep-and-replace rather than a rename refactor. Fix: define domain constants as `const string`, `static readonly string`, or — better — as a `readonly record struct` or `enum` so the type system enforces correctness and rename is one keystroke.

```csharp
// BAD: magic string in multiple files — typo-prone and not refactorable
if (user.Role == "Administrator") { }

// GOOD: constant — single source of truth, typo caught at compile time
public static class Roles
{
    public const string Administrator = "Administrator";
    public const string Viewer         = "Viewer";
    public const string Editor         = "Editor";
}

if (user.Role == Roles.Administrator) { }

// BEST: strongly-typed enum prevents invalid values entirely
public enum UserRole { Administrator, Viewer, Editor }
if (user.Role == UserRole.Administrator) { }
```

### **`PriorityQueue<T,P>` Without `.Remove()` for Priority Updates — Stale Items**  [community]

`PriorityQueue<TElement,TPriority>` does not support updating the priority of an already-enqueued item. WHY it causes problems: graph algorithms (Dijkstra, A*) need to lower the priority of a node when a shorter path is found. Without priority update support, the same node gets enqueued multiple times with different priorities, and the stale higher-priority copies are processed unnecessarily. In .NET 9, `.Remove()` enables the workaround pattern: remove then re-enqueue with the new priority. Fix: extend via an extension method; understand that `.Remove()` is O(N).

```csharp
// .NET 9: PriorityQueue.Remove enables priority updates (O(N) scan)
public static class PriorityQueueExtensions
{
    public static void UpdatePriority<TElement, TPriority>(
        this PriorityQueue<TElement, TPriority> queue,
        TElement element,
        TPriority newPriority)
    {
        queue.Remove(element, out _, out _);   // scan for element, remove if found
        queue.Enqueue(element, newPriority);   // re-enqueue with new priority
    }
}

// Simple Dijkstra-style usage:
var pq = new PriorityQueue<string, int>();
pq.Enqueue("NodeA", 10);
pq.UpdatePriority("NodeA", 3);  // now "NodeA" has priority 3
// pq.Dequeue() returns "NodeA" with priority 3

// Caution: UpdatePriority is O(N) — fine for prototyping, not for large graphs
// For production graph algorithms, use an indexed priority queue or a 3rd-party library
```

### **`field` Keyword Naming Conflict — Disambiguation Required**  [community]

The `field` contextual keyword (C# 14) clashes with any identifier named `field` in the same type. If your class has a field, property, local variable, or parameter named `field`, the compiler treats `field` as that identifier rather than the backing-field keyword. WHY it causes problems: silent semantic change — a type migrated from an explicit backing `field` variable to the new keyword syntax may compile but reference the wrong value if the old `_field` → `field` rename was done carelessly. Fix: either rename the conflicting symbol (preferred), or use the escape `@field` to access the identifier or `this.field` to access an instance member.

```csharp
// BAD: 'field' identifier conflicts with the C# 14 field keyword
public class Config
{
    private string field = "default";  // identifier named 'field'

    public string Value
    {
        get;
        set => field = value?.Trim() ?? string.Empty;  // 'field' = which one?!
        // AMBIGUOUS: compiler uses the property's synthesized backing field,
        // not the class-level 'field' identifier — silently different behavior
    }
}

// GOOD option 1: rename the conflicting identifier
public class Config
{
    private string _field = "default";  // renamed — no conflict

    public string Value
    {
        get;
        set => field = value?.Trim() ?? string.Empty;  // unambiguously: synthesized backing field
    }
}

// GOOD option 2: use @field to reference the identifier explicitly
public class Config
{
    private string field = "default";

    public string Value
    {
        get => @field;                          // @field = the class-level identifier
        set => @field = value?.Trim() ?? "";    // not the keyword
    }
}
```

### **Extension Members vs Old-Style Extension Methods — Resolution Ambiguity**  [community]

C# 14's new `extension` block syntax coexists with C# 3's classic static extension methods. When both define a method with the same name for the same receiver type, the compiler picks based on resolution rules that may surprise readers. WHY it causes problems: a library update that migrates from `static void Foo(this T t)` to an `extension(T t) { void Foo() { ... } }` block can break call sites that relied on the old static method being callable as `T.Foo(instance)` or `MyExtensions.Foo(instance)` (explicit form), because the `extension` block form does not support explicit static invocation in the same way. Fix: during migration, do not mix both forms for the same method — remove the classic form entirely when switching to the `extension` block. Document the migration with a `[Obsolete]` on the old form first to give callers time to update.

```csharp
// BAD: both forms defined — resolution is surprising
public static class OrderExtensions
{
    // Classic C# 3 form — still works
    public static decimal TotalPrice(this IReadOnlyList<OrderItem> items)
        => items.Sum(i => i.Price * i.Quantity);

    // New C# 14 extension block form for the same receiver
    extension(IReadOnlyList<OrderItem> items)
    {
        // If this also defines TotalPrice, the compiler may prefer one form
        // depending on call-site context — confusing for maintainers
        public string Summary => $"{items.Count} items, {items.Sum(i => i.Price * i.Quantity):C}";
    }
}

// GOOD: pick one style — migrate fully to extension blocks for new code
public static class OrderExtensions
{
    extension(IReadOnlyList<OrderItem> items)
    {
        public decimal TotalPrice => items.Sum(i => i.Price * i.Quantity);
        public string  Summary    => $"{items.Count} items, {items.TotalPrice:C}";
    }
}
```

### **File-Based Apps `#:` Directives in Project Files — Build Warning Flood**  [community]

Using `#:` build directives (C# 14 file-based apps feature) in `.cs` files that are part of a project-based compilation produces a compiler warning on every file that contains them. WHY it causes problems: a developer who copy-pastes a file-based app script into a `dotnet new webapi` project brings along the `#:sdk` and `#:package` directives; suddenly every build emits dozens of warnings that obscure real issues. Fix: strip all `#:` and `#!` lines when promoting a file-based script into a project-based solution. The SDK only interprets them when compiling via `dotnet run <file>` — they have no effect and generate noise in project mode.

```csharp
// file-based script — fine as standalone
#!/usr/bin/env dotnet
#:sdk Microsoft.NET.Sdk
#:package Newtonsoft.Json 13.0.3

using Newtonsoft.Json;
Console.WriteLine(JsonConvert.SerializeObject(new { hello = "world" }));

// AFTER promoting to a project — remove the #! and #: lines
// Project already has the SDK and NuGet package in .csproj:
// <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />

using Newtonsoft.Json;
Console.WriteLine(JsonConvert.SerializeObject(new { hello = "world" }));
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
| Records used as EF Core entity types | EF Core needs reference equality to track entity identity; records use value equality, causing duplicate inserts/corrupt change tracking | Use regular classes for EF entities; use records only for read-only DTOs/projections |
| Mutable collection property on a record | Array/list contents can be mutated from outside — shallow immutability broken | Use `IReadOnlyList<T>` or `ImmutableArray<T>` for collection properties on records |
| `DateTime.UtcNow` called directly in services | Untestable time — cannot simulate "tomorrow" in a unit test | Inject `TimeProvider` and call `timeProvider.GetUtcNow()` |
| Magic strings for roles/commands/status | Typo-prone; breaking rename requires grep across entire codebase | Define `const string` or `readonly record struct` constants; prefer `enum` for closed sets |
| `Dictionary<string,T>` for static lookup tables in hot paths | Resizable hash table has more overhead than needed for immutable data | Use `FrozenDictionary<K,V>.ToFrozenDictionary()` for read-only lookups |
| `string.IndexOfAny(char[])` in tight loops | Allocates array on each call site; uses non-SIMD path | Use `SearchValues<char>.Create(...)` once, store in `static readonly` |
| Calling `PriorityQueue.Enqueue` without removing old entry | Stale low-priority copy processed unnecessarily; N+1 dequeue iterations | Use `queue.Remove(element, ...)` before re-enqueue to update priority |
| `field` identifier in same class as C# 14 `field` keyword | Naming conflict — compiler resolves to different targets than expected | Rename conflicting symbol or use `@field` to explicitly reference the identifier |
| Mixing classic extension methods and C# 14 extension blocks for same type | Resolution order surprises; explicit static invocation form differs | Fully migrate to `extension` blocks; mark old form `[Obsolete]` during transition |
| `#:` directives in project-based `.cs` files | Compiler emits warning per directive per build — floods diagnostics | Strip `#:` and `#!` lines when promoting file-based scripts into project-based solutions |
| `TypedResults.ServerSentEvents` without `EnumeratorCancellation` | Client disconnect doesn't cancel the generator; connection leaks | Add `[EnumeratorCancellation] CancellationToken ct` to `IAsyncEnumerable<T>` generator |
| `FromSqlRaw` with string concatenation of user input | SQL injection — EF1002 analyzer fires at compile time (EF Core 10+) | Use `FromSql` with `FormattableString` for user-supplied values; `FromSqlRaw` only for constant SQL fragments |
| EF Core `Contains(ids)` after upgrading to EF 10 — unexpected plan changes | EF 10 changes default translation to scalar parameters; different query plans may emerge vs EF 9's JSON OPENJSON approach | Benchmark the query; override with `UseParameterizedCollectionMode` or `EF.Constant(ids)` as needed |
| `JsonDeserialize` with default options accepting unknown properties | Silently ignores unknown fields — masking schema drift, typos, and API version mismatches | Use `JsonSerializerOptions.Strict` or `JsonUnmappedMemberHandling.Disallow` for hardened deserialization |
| Sorting version strings or file names with default `string` comparer | Lexicographic order puts "10" before "2" — wrong for humans | Use `StringComparer.Create(culture, CompareOptions.NumericOrdering)` for natural sort |
| `ZipArchive` used in async code without `Task.Run` | Synchronous ZIP operations block the calling thread in async context | Use the new async `ZipArchive.CreateAsync` / `ZipFile.CreateFromDirectoryAsync` APIs (.NET 10+) |

---

## .NET 10 / ASP.NET Core 10 New APIs

### ASP.NET Core 10 — Built-In Validation (`AddValidation`)

ASP.NET Core 10 adds source-generator-based endpoint validation via `builder.Services.AddValidation()`. Annotate your request model with `[ValidatableType]` and the framework automatically validates bound parameters before the handler runs, returning a `ValidationProblem` response on failure — no FluentValidation or manual `ModelState` checks required.

```csharp
// Program.cs — enable validation globally
builder.Services.AddValidation();

// Request model — mark with [ValidatableType] for source-gen validation
using System.ComponentModel.DataAnnotations;

[ValidatableType]
public class CreateOrderRequest
{
    [Required(ErrorMessage = "Customer ID is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Customer ID must be positive.")]
    public int CustomerId { get; set; }

    [Required]
    [MinLength(1, ErrorMessage = "At least one item is required.")]
    public List<OrderItem> Items { get; set; } = [];
}

// Minimal API endpoint — validation runs before handler
app.MapPost("/orders", async (
    CreateOrderRequest request,
    IOrderService orders,
    CancellationToken ct) =>
{
    // Execution only reaches here if validation passes
    var order = await orders.CreateAsync(request, ct);
    return TypedResults.Created($"/orders/{order.Id}", order);
});

// Disable validation for a specific endpoint
app.MapPost("/admin/bulk-import", BulkImportHandler)
   .DisableValidation();
```

**Why it matters:** previously you had to install FluentValidation or write `if (!ModelState.IsValid) return BadRequest(...)` manually in every controller/handler. The new source-gen approach produces the same zero-overhead-at-runtime behavior as compiled code, validates nested objects and collections (unlike basic DataAnnotations), and integrates with `IProblemDetailsService` for consistent error responses.

### ASP.NET Core 10 — `TypedResults.ServerSentEvents` for Streaming

ASP.NET Core 10 adds first-class Server-Sent Events (SSE) support in Minimal APIs via `TypedResults.ServerSentEvents`. Pass an `IAsyncEnumerable<T>` and the framework handles the SSE framing, flushing, and cancellation automatically.

```csharp
// Minimal API streaming endpoint — returns SSE stream
app.MapGet("/metrics/realtime", (CancellationToken ct) =>
{
    return TypedResults.ServerSentEvents(
        StreamMetricsAsync(ct),
        eventType: "metrics");
});

// Generator: yields metrics as they arrive
static async IAsyncEnumerable<MetricsSnapshot> StreamMetricsAsync(
    [EnumeratorCancellation] CancellationToken ct)
{
    while (!ct.IsCancellationRequested)
    {
        yield return MetricsSnapshot.Capture();
        await Task.Delay(TimeSpan.FromSeconds(2), ct);
    }
}

// Complex object support — serialized as JSON in the SSE data field
public record MetricsSnapshot(
    double CpuPercent,
    long MemoryMb,
    DateTimeOffset CapturedAt)
{
    public static MetricsSnapshot Capture() => new(
        Random.Shared.NextDouble() * 100,
        Random.Shared.NextInt64(512, 8192),
        DateTimeOffset.UtcNow);
}
```

**Consumer side (browser/JavaScript):**
```javascript
const evtSource = new EventSource("/metrics/realtime");
evtSource.addEventListener("metrics", (event) => {
    const snapshot = JSON.parse(event.data);
    updateDashboard(snapshot);
});
```

**Why it matters:** previously SSE in ASP.NET Core required manual `Response.ContentType = "text/event-stream"` and manual `await response.Body.WriteAsync(...)` calls with the SSE framing written by hand. `TypedResults.ServerSentEvents` handles protocol framing, keeps connections alive, respects cancellation when the client disconnects, and integrates correctly with OpenAPI schema generation.

### Blazor `[PersistentState]` — Declarative Prerendering State (.NET 10)

Blazor Web Apps in .NET 10 simplify prerendering state persistence with the `[PersistentState]` attribute. Previously, passing state from the server prerender to the WebAssembly or Server-interactive runtime required verbose `PersistentComponentState` API calls with manual serialization. Now, mark a property with `[PersistentState]` and the framework handles persistence automatically.

```razor
@page "/movies"
@inject IMovieService MovieService

@if (MoviesList is null)
{
    <p>Loading...</p>
}
else
{
    <ul>
        @foreach (var movie in MoviesList)
        {
            <li>@movie.Title</li>
        }
    </ul>
}

@code {
    // Persisted across prerender → interactive boundary automatically
    [PersistentState]
    public List<Movie>? MoviesList { get; set; }

    protected override async Task OnInitializedAsync()
    {
        // ??= means: only fetch if not already restored from prerender state
        MoviesList ??= await MovieService.GetMoviesAsync();
    }
}
```

**Before .NET 10 (verbose PersistentComponentState approach):**
```csharp
[Inject] private PersistentComponentState ApplicationState { get; set; } = default!;
private PersistingComponentStateSubscription _subscription;

protected override async Task OnInitializedAsync()
{
    _subscription = ApplicationState.RegisterOnPersisting(PersistMoviesList);
    if (!ApplicationState.TryTakeFromJson<List<Movie>>("moviesList", out var restored))
    {
        MoviesList = await MovieService.GetMoviesAsync();
    }
    else
    {
        MoviesList = restored;
    }
}

private Task PersistMoviesList()
{
    ApplicationState.PersistAsJson("moviesList", MoviesList);
    return Task.CompletedTask;
}
```

**Why it matters:** the old pattern required 5+ boilerplate lines per persisted value. `[PersistentState]` collapses this to a single attribute, making prerendering viable for data-heavy pages without verbosity.

### `WebSocketStream` — Simplified WebSocket I/O (.NET 10)

.NET 10 adds `WebSocketStream` in `System.Net.WebSockets`. It wraps a `WebSocket` in a standard `Stream` interface, enabling WebSocket data to be processed with any `Stream`-consuming API (readers, writers, pipes, JSON deserializers) without custom framing code.

```csharp
using System.Net.WebSockets;
using System.IO;
using System.Text.Json;

// Server-side: wrap WebSocket in a Stream for unified I/O
app.MapGet("/ws", async (HttpContext context) =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        return;
    }

    using var ws = await context.WebSockets.AcceptWebSocketAsync();

    // Wrap in WebSocketStream — now works with any Stream-based API
    await using var wsStream = new WebSocketStream(ws);

    // Read: use StreamReader, PipeReader, or JsonSerializer directly
    await foreach (var message in JsonSerializer.DeserializeAsyncEnumerable<ChatMessage>(
        wsStream, cancellationToken: context.RequestAborted))
    {
        if (message is null) continue;
        var response = ProcessMessage(message);

        // Write back serialized response
        await JsonSerializer.SerializeAsync(wsStream, response, context.RequestAborted);
        await wsStream.FlushAsync(context.RequestAborted);
    }
});

public record ChatMessage(string User, string Text, DateTimeOffset SentAt);

// Client-side: same pattern
using var client = new ClientWebSocket();
await client.ConnectAsync(new Uri("ws://localhost:5000/ws"), CancellationToken.None);
await using var stream = new WebSocketStream(client);
// Now serialize/deserialize directly on stream — no byte framing needed
```

**Why it matters:** before `WebSocketStream`, reading from a WebSocket required `ReceiveAsync` with a manually sized byte buffer and a loop to handle partial frames. Integrating with JSON streaming or PipeReader required writing an adapter. `WebSocketStream` enables zero-glue integration with the entire `Stream` ecosystem.

---

## Nullable Value Types Deep-Dive

A *nullable value type* `T?` (equivalent to `Nullable<T>`) wraps any non-nullable value type to add a `null` state. This is essential for database columns, optional form fields, and domain values with "not set" semantics that ordinary value types cannot express.

### Declaration and Assignment

```csharp
// Any value type can become nullable with ?
double?   pi      = 3.14;
char?     letter  = 'a';
bool?     flag    = null;         // three-state boolean (database NULL pattern)
DateTime? created = null;         // absent timestamp

// Implicit widening: T → T? is always safe
int m = 10;
int? n = m;   // OK — implicit conversion

// Array of nullable value type
int?[] scores = new int?[10];     // all elements default to null
```

The default value of `T?` is `null` — its `HasValue` property returns `false`.

### Checking and Extracting the Value

**Preferred: `is` pattern matching** (safe and null-safe in one step):
```csharp
int? a = 42;
if (a is int value)
{
    Console.WriteLine($"Has value: {value}");   // "Has value: 42"
}
else
{
    Console.WriteLine("No value");
}
```

**Classic: `HasValue` / `Value` properties:**
```csharp
int? b = 10;
if (b.HasValue)
{
    Console.WriteLine(b.Value);   // Safe — only call .Value when HasValue is true
}
// NEVER: b.Value when HasValue is false → throws InvalidOperationException
```

**Null comparison** (equivalent to `HasValue`):
```csharp
int? c = 7;
if (c != null)
{
    Console.WriteLine(c.Value);
}
```

### Conversion to Non-Nullable — Null-Coalescing `??` and `GetValueOrDefault`

```csharp
int? a = 28;
int b = a ?? -1;                     // b = 28 (a has a value)

int? c = null;
int d = c ?? -1;                     // d = -1 (fallback)

int e = c.GetValueOrDefault();       // e = 0  (type's default)
int f = c.GetValueOrDefault(-999);   // f = -999 (custom default)

// Null-coalescing assignment ??= (C# 8+)
int? g = null;
g ??= 100;   // g = 100

// Explicit cast — compiles but throws at runtime if null
int? h = null;
int i = (int)h;   // InvalidOperationException at runtime — avoid this
```

### Lifted Operators

All arithmetic and comparison operators defined on `T` are *lifted* to `T?`: if either operand is `null`, the result is `null`:

```csharp
int? a = 10;
int? b = null;

int? sum = a + b;    // null  — null propagates
int? product = a * 10; // 100 — T? op T? works via lifting
a++;                 // a = 11

// Comparison edge case: null comparisons always return false except ==
int? x = 10;
Console.WriteLine(x >= null);  // False
Console.WriteLine(x <  null);  // False (NOT the logical inverse of >=)
Console.WriteLine(x == null);  // False
Console.WriteLine(null == null); // True (nullable equality special case)

// bool? logical operators follow 3-value logic (Kleene logic):
bool? t = true;
bool? n2 = null;
Console.WriteLine(t & n2);   // null   (true AND unknown = unknown)
Console.WriteLine(t | n2);   // True   (true OR unknown = true)
Console.WriteLine(false & n2); // False (false AND anything = false)
```

### Boxing and Unboxing

```csharp
int? a = 42;
object boxed = a;          // boxes as int (not Nullable<int>)

int? b = null;
object boxedNull = b;      // boxes as null reference

// Unboxing a boxed int into int? works:
int x = 41;
object xBoxed = x;
int? xNullable = (int?)xBoxed;   // OK → 41
```

**Gotcha:** `GetType()` on a non-null `int?` returns `System.Int32` (not `System.Nullable<Int32>`) because boxing strips the wrapper:
```csharp
int? a = 17;
Console.WriteLine(a.GetType().FullName);  // "System.Int32" — surprising!
// Use Nullable.GetUnderlyingType(typeof(int?)) to test at the Type level
```

### Identifying Nullable Value Types at Runtime

```csharp
bool IsNullable(Type type) => Nullable.GetUnderlyingType(type) != null;

Console.WriteLine(IsNullable(typeof(int?)));  // True
Console.WriteLine(IsNullable(typeof(int)));   // False

// Note: the `is` operator cannot distinguish int? from int at runtime
// because the boxed representation is identical for non-null values
int? a = 14;
if (a is int) Console.WriteLine("compatible with int");  // prints — can't use is to detect nullability
```

### Nullable Value Types vs Nullable Reference Types

| Feature | `int?` / `T?` (value) | `string?` / `T?` (reference, C# 8+) |
|---|---|---|
| Backed by | `Nullable<T>` struct | Same reference type — compiler annotation only |
| Runtime null check | `HasValue` / `is T v` | `!= null` / `is not null` |
| Default value | `null` (no value) | `null` (reference is null) |
| Enabled by | Always available | `<Nullable>enable</Nullable>` in csproj |
| Boxing | Strips wrapper | No change |

### Nullable Value Type Anti-Patterns

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Accessing `.Value` without checking `.HasValue` | Throws `InvalidOperationException` at runtime | Use `is int v` pattern, `??`, or `GetValueOrDefault()` |
| Using `==` to compare `int?` in loops | Allocates a boxed nullable on each comparison in older JIT versions | Use `HasValue` + `Value` equality, or `is int v && v == x` pattern |
| `(int)myNullable` without a null guard | Compiles but throws `InvalidOperationException` when null | Use `myNullable ?? defaultValue` or pattern matching |
| Using `Object.GetType()` to detect nullable | Returns the underlying type's `Type` — indistinguishable from non-nullable | Use `Nullable.GetUnderlyingType(typeof(T)) != null` |
| `Optional<T>` fields (borrowing from Java) | Not native C#; `.Value` pattern with `T?` is idiomatic | Use `T?` for value types, nullable reference types for reference types |
| Three-state `bool?` without documentation | Implicit semantics; readers don't know what `null` means | Document the three states explicitly, or use an `enum { Unknown, True, False }` |
| `DateTime?` in serialization without culture | `null` JSON round-trips as the default (midnight 0001-01-01) in some serializers | Always use `DateTimeOffset?` and configure serializer to emit/accept `null` |
| `new()` on a `record struct` positional type | Positional record structs auto-generate a `Deconstruct` — mixing positional and `new()` is fine, but forgetting `readonly` on the struct allows unintended mutation via boxing | Prefer `readonly record struct` for stack-allocated value objects |

---

## EF Core 10 — New Patterns (.NET 10 LTS)

### Named Query Filters — Multiple Per Entity with Selective Disabling

EF Core 10 introduces *named query filters*, allowing multiple independent global filters per entity type that can be individually disabled at query time. Previously, a single global filter per entity type forced all concerns (soft delete, multi-tenancy, etc.) into one combined expression, making it impossible to disable just one.

```csharp
// Model configuration: named filters
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Blog>()
        .HasQueryFilter("SoftDeletionFilter", b => !b.IsDeleted)
        .HasQueryFilter("TenantFilter", b => b.TenantId == _tenantId);
}

// Query — apply all filters (default)
var blogs = await context.Blogs.ToListAsync(ct);

// Disable only the soft-deletion filter for an admin view
var withDeleted = await context.Blogs
    .IgnoreQueryFilters(["SoftDeletionFilter"])
    .ToListAsync(ct);

// Disable all filters (existing behavior)
var all = await context.Blogs.IgnoreQueryFilters().ToListAsync(ct);
```

**Why it matters:** before EF 10 you could only call `IgnoreQueryFilters()` to disable ALL filters at once. Named filters enable composite multi-tenant + soft-delete patterns where admin queries see deleted records but still respect tenant isolation.

### Vector Search — `SqlVector<float>` for AI / RAG Workloads (EF 10 + SQL Server 2025 / Azure SQL)

EF Core 10 adds first-class support for the `vector` SQL Server data type (available in Azure SQL Database and SQL Server 2025). Use `SqlVector<float>` to store embedding vectors on entities and `EF.Functions.VectorDistance()` to perform semantic similarity search in LINQ.

```csharp
using Microsoft.EntityFrameworkCore;

// Entity: store an embedding alongside the document
public class Article
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public required string Body { get; set; }

    // Vector column — dimension must match your embedding model (1536 for text-embedding-3-small)
    [Column(TypeName = "vector(1536)")]
    public SqlVector<float>? Embedding { get; set; }
}

// Insert: populate embedding from an AI model
IEmbeddingGenerator<string, Embedding<float>> embeddingGenerator = /* inject */;
var vector = await embeddingGenerator.GenerateVectorAsync(article.Body);
article.Embedding = new SqlVector<float>(vector);
await context.SaveChangesAsync(ct);

// Semantic search: order by cosine distance from a query embedding
float[] queryVector = await embeddingGenerator.GenerateVectorAsync(userQuery);
var topMatches = await context.Articles
    .Where(a => a.Embedding != null)
    .OrderBy(a => EF.Functions.VectorDistance("cosine", a.Embedding!, new SqlVector<float>(queryVector)))
    .Take(5)
    .Select(a => new { a.Id, a.Title })
    .ToListAsync(ct);
```

**Distance metrics:** `"cosine"` (direction similarity, most common for text), `"euclidean"` (geometric distance), `"dot"` (inner product — faster, requires normalized vectors).

### `LeftJoin` and `RightJoin` — First-Class LINQ Outer Joins (EF 10 / .NET 10)

.NET 10 adds native `LeftJoin` and `RightJoin` extension methods to LINQ. EF Core 10 recognizes these methods and translates them to `LEFT JOIN` / `RIGHT JOIN` SQL. Previously, left outer joins required a verbose `GroupJoin` + `SelectMany` + `DefaultIfEmpty` construct that few developers could write from memory.

```csharp
// Before .NET 10: verbose GroupJoin pattern
var legacyQuery =
    from student in context.Students
    join dept in context.Departments
        on student.DepartmentId equals dept.Id into deptGroup
    from dept in deptGroup.DefaultIfEmpty()
    select new { student.Name, DeptName = dept == null ? "[NONE]" : dept.Name };

// .NET 10 / EF 10: native LeftJoin — idiomatic and readable
var query = context.Students
    .LeftJoin(
        context.Departments,
        student => student.DepartmentId,
        dept => dept.Id,
        (student, dept) => new
        {
            student.Name,
            DeptName = dept == null ? "[NONE]" : dept.Name
        });

// RightJoin: all departments, only matched students
var rightQuery = context.Students
    .RightJoin(
        context.Departments,
        student => student.DepartmentId,
        dept => dept.Id,
        (student, dept) => new { StudentName = student == null ? "[NONE]" : student.Name, dept.Name });
```

**Note:** C# query syntax (`from x in y join z`) does not yet support the new `LeftJoin` / `RightJoin` operators. Use method syntax.

### Complex Types — Table Splitting and JSON Mapping (EF 10)

EF 10 promotes *complex types* over owned entity types for embedded value objects. Complex types have value semantics, support `ExecuteUpdateAsync`, allow assignment copying, and map to either table columns (table splitting) or JSON columns. Unlike owned entities, they cannot be confused with separate entity instances.

```csharp
// Value object as a complex type
public class Address
{
    public required string Street { get; set; }
    public required string City { get; set; }
    public required string PostalCode { get; set; }
}

public class Customer
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public required Address ShippingAddress { get; set; }
    public Address? BillingAddress { get; set; }  // optional complex type (EF 10)
}

// Configuration: table splitting (columns in the same table)
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Customer>(b =>
    {
        b.ComplexProperty(c => c.ShippingAddress);
        b.ComplexProperty(c => c.BillingAddress);  // optional — nullable
    });
}

// Configuration: JSON mapping (single JSON column per address)
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Customer>(b =>
    {
        b.ComplexProperty(c => c.ShippingAddress, cp => cp.ToJson());
        b.ComplexProperty(c => c.BillingAddress, cp => cp.ToJson());
    });
}

// Assignment works naturally — copies values (unlike owned entity types)
var customer = await context.Customers.FindAsync(id, ct);
customer.BillingAddress = customer.ShippingAddress;  // OK — value copy, not reference
await context.SaveChangesAsync(ct);

// Bulk update on JSON column — new in EF 10 (not supported with owned entity types)
await context.Customers.ExecuteUpdateAsync(
    s => s.SetProperty(c => c.ShippingAddress.City, "Seattle"), ct);
```

**Migration note:** if you previously used owned entity types (`OwnsOne`) for table splitting or JSON, migrate to complex types. Owned entities have reference semantics which causes subtle bugs when copying or comparing values, and do not support `ExecuteUpdateAsync` on their JSON-mapped properties.

---

## .NET 10 Library APIs

### `JsonSerializerOptions.Strict` — Hardened JSON Deserialization

`JsonSerializerOptions.Strict` is a preconfigured preset that enforces security-conscious defaults: disallows duplicate JSON properties, disallows unmapped members (`JsonUnmappedMemberHandling.Disallow`), enforces case-sensitive property binding, and respects nullable annotations and required constructor parameters. Use it for public APIs, configuration parsing, and any scenario where unexpected JSON fields are a concern.

```csharp
using System.Text.Json;

// Default: lenient — extra properties ignored, duplicates use last value
string json = """{ "Name": "Alice", "Age": 30, "Unknown": "extra" }""";
var person = JsonSerializer.Deserialize<Person>(json);  // succeeds, Unknown ignored

// Strict: rejects unknown properties AND duplicate property names
JsonSerializerOptions strict = JsonSerializerOptions.Strict;

// Throws JsonException: "Unknown" is not a member of Person
JsonSerializer.Deserialize<Person>(json, strict);

// Strict also disallows duplicates
string dupe = """{ "Name": "Alice", "Name": "Bob" }""";
JsonSerializer.Deserialize<Person>(dupe, strict);  // throws: duplicate property "Name"

record Person(string Name, int Age);

// Option to disallow duplicates independently (without full Strict)
var noDupes = new JsonSerializerOptions { AllowDuplicateProperties = false };
JsonSerializer.Deserialize<Person>(dupe, noDupes);  // throws: duplicate property

// Source-gen context: enable strict mode globally in context options
[JsonSourceGenerationOptions(AllowDuplicateProperties = false)]
[JsonSerializable(typeof(Person))]
internal partial class AppJsonContext : JsonSerializerContext { }
```

**When to use:** `Strict` is ideal for security-sensitive deserialization (API inputs, config files). For maximum performance with AOT/trimming, combine `JsonSerializerOptions.Strict` with a source-generated `JsonSerializerContext`.

### `CompareOptions.NumericOrdering` — Natural Sort for Version and Version-Like Strings

`CompareOptions.NumericOrdering` makes `StringComparer` sort embedded numbers by their numeric value rather than lexicographically. `"Windows 10"` sorts after `"Windows 8"` (not before, as lexicographic sorting produces). `"2"` and `"02"` compare as equal. This is the "natural sort" behavior that end users expect for file lists, version strings, and UI tables.

```csharp
using System.Globalization;

StringComparer naturalOrder = StringComparer.Create(
    CultureInfo.CurrentCulture,
    CompareOptions.NumericOrdering);

// Sort OS names in the order a human expects
string[] versions = ["Windows 11", "Windows 8", "Windows 10", "Windows 7"];
Array.Sort(versions, naturalOrder);
// Result: ["Windows 7", "Windows 8", "Windows 10", "Windows 11"]

// Lexicographic sort gives wrong order:
Array.Sort(versions);
// Result: ["Windows 10", "Windows 11", "Windows 7", "Windows 8"] — WRONG for humans

// Numeric equality: "007" == "7" when numeric ordering
bool equal = naturalOrder.Equals("007", "7");  // True

// Useful for UI sort columns, file names, semantic version lists
var sorted = files.Order(naturalOrder).ToList();  // ["file1.txt", "file2.txt", "file10.txt"]

// Note: NumericOrdering doesn't work with index operations (IndexOf, StartsWith, etc.)
// It is only valid for comparison and ordering operations
```

### `JsonSerializer` with `PipeReader` — Zero-Copy Streaming Deserialization

`JsonSerializer.DeserializeAsync` now accepts `PipeReader` directly in .NET 10, eliminating the need to convert a `PipeReader` to a `Stream` before deserializing. Combined with `DeserializeAsyncEnumerable<T>`, this is the idiomatic approach for streaming JSON in high-throughput pipelines.

```csharp
using System.IO.Pipelines;
using System.Text.Json;

// Server: serialize an IAsyncEnumerable<T> directly to PipeWriter
public async Task StreamToClientAsync(PipeWriter writer, CancellationToken ct)
{
    var data = GenerateDataAsync(ct);
    await JsonSerializer.SerializeAsync<IAsyncEnumerable<DataPoint>>(writer, data, cancellationToken: ct);
    await writer.CompleteAsync();
}

// Client: deserialize incrementally from PipeReader — no intermediate Stream needed
public async Task ConsumeStreamAsync(PipeReader reader, CancellationToken ct)
{
    await foreach (var point in JsonSerializer.DeserializeAsyncEnumerable<DataPoint>(reader, cancellationToken: ct))
    {
        await ProcessAsync(point, ct);
    }
    await reader.CompleteAsync();
}

public record DataPoint(string Id, double Value, DateTimeOffset RecordedAt);

// Direct Pipe round-trip in a single method (useful for tests and in-process pipelines)
var pipe = new Pipe();
await JsonSerializer.SerializeAsync(pipe.Writer, new DataPoint("X1", 3.14, DateTimeOffset.UtcNow));
await pipe.Writer.CompleteAsync();
var result = await JsonSerializer.DeserializeAsync<DataPoint>(pipe.Reader);
await pipe.Reader.CompleteAsync();
```

**Why it matters:** before .NET 10, integrating JSON deserialization with `System.IO.Pipelines` required a `PipeReader.AsStream()` call, which added buffering overhead and lost the zero-copy characteristics of the pipeline. Direct `PipeReader` support enables fully allocation-efficient JSON streaming end-to-end.

### Post-Quantum Cryptography — `MLKem`, `MLDsa`, `SlhDsa` (.NET 10)

.NET 10 adds three FIPS-standardized post-quantum cryptography (PQC) algorithms: ML-KEM (key encapsulation, FIPS 203), ML-DSA (digital signatures, FIPS 204), and SLH-DSA (hash-based signatures, FIPS 205). Unlike classical `AsymmetricAlgorithm` types, PQC types use static factory methods for key generation and import. Use `IsSupported` to check platform availability before use.

```csharp
using System.Security.Cryptography;

// ML-KEM: key encapsulation for secure key exchange
// GenerateKey requires an algorithm parameter (MLKemAlgorithm enum)
using MLKem recipientKey = MLKem.GenerateKey(MLKemAlgorithm.MLKem768);

// Export public key and share with sender
string publicKeyPem = recipientKey.ExportSubjectPublicKeyInfoPem();

// Sender: encapsulate a shared secret using the recipient's public key
using MLKem senderPublic = MLKem.ImportFromPem(publicKeyPem);
// (Encapsulate/Decapsulate APIs wrap key exchange — see docs for full example)

// ML-DSA: signing and verification
private static byte[] SignWithMLDsa(string privateKeyPath, ReadOnlySpan<byte> data)
{
    using MLDsa signingKey = MLDsa.ImportFromPem(File.ReadAllText(privateKeyPath));
    return signingKey.SignData(data);  // returns signature as byte[]
}

private static bool VerifyMLDsaSignature(
    string publicKeyPath,
    ReadOnlySpan<byte> data,
    ReadOnlySpan<byte> signature)
{
    using MLDsa verifyingKey = MLDsa.ImportFromPem(File.ReadAllText(publicKeyPath));
    return verifyingKey.VerifyData(data, signature);
}

// Check platform support before use (requires OpenSSL 3.5+ or Windows CNG with PQC support)
if (!MLDsa.IsSupported)
    throw new PlatformNotSupportedException("ML-DSA is not available on this platform.");

// Note: MLDsa and SlhDsa are marked [Experimental] (SYSLIB5006) until fully finalized
```

**Algorithm guidance:**
- **ML-KEM** (FIPS 203): use for key encapsulation / key exchange. Replaces classical Diffie-Hellman and ECDH in post-quantum scenarios.
- **ML-DSA** (FIPS 204): use for digital signatures. Replaces RSA and ECDSA.
- **SLH-DSA** (FIPS 205): hash-based signature scheme, stateless. More conservative option when ML-DSA trust assumptions are uncertain.

### `ZipArchive` Async APIs (.NET 10)

.NET 10 adds native async methods for ZIP file operations. Previously, `ZipArchive` was synchronous-only; using it in async code required `Task.Run` to avoid blocking the calling thread. The new `CreateAsync`, `OpenAsync`, and `ExtractToDirectoryAsync` methods integrate naturally with async I/O pipelines.

```csharp
using System.IO.Compression;

// Create a ZIP archive asynchronously
public static async Task CreateZipAsync(
    string outputPath,
    IEnumerable<string> filePaths,
    CancellationToken ct)
{
    await using var zipStream = File.Create(outputPath);
    await using var archive = await ZipArchive.CreateAsync(
        zipStream,
        ZipArchiveMode.Create,
        leaveOpen: false,
        entryNameEncoding: null,
        ct);

    foreach (var filePath in filePaths)
    {
        var entry = archive.CreateEntry(Path.GetFileName(filePath));
        await using var entryStream = await entry.OpenAsync(ct);
        await using var fileStream = File.OpenRead(filePath);
        await fileStream.CopyToAsync(entryStream, ct);
    }
}

// Create ZIP from directory asynchronously
await ZipFile.CreateFromDirectoryAsync(
    sourceDirectoryName: "output/reports",
    destinationArchiveFileName: "reports.zip",
    cancellationToken: ct);

// Extract ZIP asynchronously
await ZipFile.ExtractToDirectoryAsync(
    sourceArchiveFileName: "reports.zip",
    destinationDirectoryName: "extracted/",
    cancellationToken: ct);
```

**Why it matters:** ZIP archiving is a common I/O operation in background jobs, file uploads, and report generation. The new async APIs eliminate the `Task.Run` wrapper anti-pattern and allow proper cancellation when the caller's token fires.

---

## EF Core 10 — Community Gotchas

### **EF Core Parameterized Collection Mode — Plan Cache vs. Query Planner Tradeoff**  [community]

EF Core 10 changes the default translation of `ids.Contains(b.Id)` queries from a JSON array parameter (`OPENJSON(...)`) to individual scalar parameters (`@ids1, @ids2, ...`). Each unique collection size still generates a distinct SQL (padded to the next batch size), but the query planner gets cardinality hints. WHY it causes problems: teams upgrading from EF 9 to EF 10 may see different query plans in production — typically faster for small collections but potentially slower for very large ones. Fix: benchmark before relying on the default. Override globally with `UseParameterizedCollectionMode(ParameterTranslationMode.Constant)` for the EF 9 JSON behavior, or per-query with `EF.Constant(ids).Contains(b.Id)` when inlining is correct for a known-small set.

```csharp
// EF 10 default: scalar parameters — query planner gets cardinality info
int[] ids = [1, 2, 3];
var blogs = await context.Blogs.Where(b => ids.Contains(b.Id)).ToListAsync(ct);
// Generated SQL: WHERE [b].[Id] IN (@ids1, @ids2, @ids3)

// Override globally to EF 9 JSON behavior
builder.Services.AddDbContext<BlogContext>(o =>
    o.UseSqlServer(conn, sql =>
        sql.UseParameterizedCollectionMode(ParameterTranslationMode.MultipleParameters)));
        // or: ParameterTranslationMode.Constant (for inlined constants)
        // or: ParameterTranslationMode.SingleParameter (JSON OPENJSON)

// Per-query override: inline constants for small, known sets
var trusted = await context.Blogs
    .Where(b => EF.Constant(new[] { 1, 2, 3 }).Contains(b.Id))
    .ToListAsync(ct);
```

### **EF Core `FromSqlRaw` String Concatenation — SQL Injection Analyzer Warning**  [community]

EF Core 10 ships a Roslyn analyzer that warns when string concatenation is used inside `FromSqlRaw`, `ExecuteSqlRaw`, or similar raw-SQL methods. WHY it causes problems: `FromSqlRaw` with concatenated user input is the most common path to SQL injection in EF Core apps. The analyzer (warning `EF1002`) fires at compile time rather than at review time. Fix: switch to `FromSql` (accepts `FormattableString` — parameters are automatically sent safely) for dynamic values. Use `FromSqlRaw` only with compile-time-constant fragments that have been manually reviewed.

```csharp
// BAD: EF1002 analyzer warning — SQL injection risk
string field = "Name";  // user-supplied
var results = context.Blogs.FromSqlRaw("SELECT * FROM Blogs WHERE [" + field + "] IS NULL");

// GOOD: FormattableString — parameters sent separately, injection-safe
// (EF automatically parameterizes the interpolated value)
string value = userInput;
var safe = context.Blogs.FromSql($"SELECT * FROM Blogs WHERE Name = {value}");

// GOOD: constant fragment with no user input — safe to use FromSqlRaw
var byStatus = context.Blogs.FromSqlRaw("SELECT * FROM Blogs WHERE IsDeleted = 0");

// If FromSqlRaw with dynamic fragments is unavoidable, suppress EF1002 with a comment
// explaining the manual sanitization performed
#pragma warning disable EF1002
var dynamic = context.Blogs.FromSqlRaw(sanitizedSql);  // manually reviewed
#pragma warning restore EF1002
```

---

## ASP.NET Core 10 — Additional New APIs

### OpenAPI 3.1 by Default + YAML Format + XML Doc Comments

ASP.NET Core 10 upgrades the built-in OpenAPI support to emit **OpenAPI 3.1** (JSON Schema draft 2020-12) by default, switches the underlying library to `Microsoft.OpenApi` 2.0.0, adds YAML output format, and automatically incorporates **XML documentation comments** from source files into the generated OpenAPI document via a Roslyn source generator.

**Behavioral changes from OpenAPI 3.0 → 3.1:**
- Nullable types use `"type": ["string", "null"]` instead of `"nullable": true`
- `oneOf` pattern for nullable complex types
- `$ref` siblings now valid (OpenAPI 3.1 allows description alongside a `$ref`)

```csharp
// Program.cs — enable XML doc comments in OpenAPI (requires GenerateDocumentationFile=true in .csproj)
builder.Services.AddOpenApi();

// Output as YAML (more concise than JSON)
app.MapOpenApi("/openapi/{documentName}.yaml");

// XML comments are automatically picked up when methods (not lambdas) are used as handlers
/// <summary>Place a new order for a customer.</summary>
/// <param name="request">The order details including customer ID and line items.</param>
/// <returns>The created order with its assigned ID.</returns>
/// <response code="201">Order created successfully.</response>
/// <response code="422">Validation error in request body.</response>
public static async Task<Results<Created<OrderDto>, ValidationProblem>> CreateOrder(
    CreateOrderRequest request,
    IOrderService orders,
    CancellationToken ct) { /* ... */ return default!; }

app.MapPost("/orders", CreateOrder);

// ProducesResponseType Description parameter (new in ASP.NET Core 10)
[HttpGet("forecast")]
[ProducesResponseType<IEnumerable<WeatherForecast>>(StatusCodes.Status200OK,
    Description = "Five-day weather forecast for the requested location.")]
public IEnumerable<WeatherForecast> GetForecast() => [];
```

**IMPORTANT breaking change:** if your OpenAPI consumers (Swagger UI, code generators, API clients) use `nullable: true` for nullable schema detection, they must be updated to handle `"type": ["T", "null"]`. Test generated clients before upgrading.

**YAML output guideline:** use `.yaml` extension for human-readable API specs checked into version control. Use `.json` for machine-to-machine integration where parser compatibility is a concern.

### Cookie Auth — 401/403 Instead of Redirects for API Endpoints

In ASP.NET Core 10, cookie authentication no longer redirects unauthenticated or unauthorized requests to the login page when the request targets an API endpoint. Instead it returns HTTP **401 Unauthorized** or **403 Forbidden** directly. This eliminates the common "why is my API returning HTML?" surprise in SPAs and API-only clients.

An endpoint is recognized as an API endpoint if it:
- Has `[ApiController]` (MVC)
- Produces or accepts JSON responses (Minimal API `TypedResults`, content negotiation)
- Is a SignalR endpoint

```csharp
// ASP.NET Core 10: API endpoints get 401/403, not login redirects

// Before ASP.NET Core 10: GET /api/orders → 302 to /Account/Login (surprise HTML to JS client)
// After ASP.NET Core 10:  GET /api/orders → 401 Unauthorized

// Override: restore redirect behavior for a specific auth scheme
builder.Services.AddAuthentication()
    .AddCookie(options =>
    {
        // Re-enable redirect for traditional web page endpoints
        options.Events.OnRedirectToLogin = context =>
        {
            // Only redirect for browser navigation (Accept: text/html) — not for API clients
            if (context.Request.Headers.Accept.Contains("text/html"))
            {
                context.Response.Redirect(context.RedirectUri);
            }
            else
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            }
            return Task.CompletedTask;
        };
    });

// Custom IApiEndpointMetadata: mark any endpoint as "API" to get 401/403 behavior
public class ApiEndpointMetadata : IApiEndpointMetadata { }
app.MapGet("/hybrid", () => "data").WithMetadata(new ApiEndpointMetadata());
```

**Why it matters:** before this change, a cookie-authenticated SPA would receive a `302 → /Account/Login` from its API calls when the session expired. JavaScript `fetch()` followed the redirect silently and the client received HTML instead of an error — causing silent failures and confusing debugging. The new behavior makes API authentication failures visible and unambiguous.

### `IMemoryPoolFactory<T>` — DI-Friendly Memory Pool (.NET 10 / ASP.NET Core 10)

`IMemoryPoolFactory<T>` is a new DI-registered abstraction for creating `MemoryPool<T>` instances. It replaces the anti-pattern of using `MemoryPool<T>.Shared` directly in classes that need scoped or isolated memory pools. Register via `AddMemoryPool<T>()` and inject the factory; the factory creates a pool per consumer, reducing cross-consumer memory pressure.

```csharp
using Microsoft.Extensions.DependencyInjection;

// Registration — adds IMemoryPoolFactory<byte> to DI
builder.Services.AddMemoryPool<byte>();

// Consumer: inject factory, create an owned pool, dispose when done
public sealed class FileProcessor(
    IMemoryPoolFactory<byte> memoryPoolFactory,
    ILogger<FileProcessor> logger) : IAsyncDisposable
{
    private readonly MemoryPool<byte> _pool = memoryPoolFactory.Create();

    public async Task ProcessAsync(Stream input, CancellationToken ct)
    {
        using IMemoryOwner<byte> buffer = _pool.Rent(minBufferSize: 4096);
        Memory<byte> memory = buffer.Memory;
        int bytesRead = await input.ReadAsync(memory, ct);
        ProcessBuffer(memory[..bytesRead]);
    }

    public async ValueTask DisposeAsync()
    {
        _pool.Dispose();
        logger.LogDebug("Memory pool released.");
        await ValueTask.CompletedTask;
    }

    private static void ProcessBuffer(ReadOnlyMemory<byte> data) { /* ... */ }
}

// Metrics: monitor pool usage at runtime
// Available under "Microsoft.AspNetCore.MemoryPool" metric namespace
```

**When to use:** background services, file processing, HTTP request body buffering, or any component that reads large streams and benefits from controlled buffer reuse. Do NOT use `MemoryPool<T>.Shared` for long-lived services — it competes with framework internals. Prefer a dedicated pool from the factory.

### `X509Certificate2Collection.FindByThumbprint` — SHA-256 and SHA-3 Certificate Lookup (.NET 10)

The old `X509Certificate2Collection.Find(X509FindType.FindByThumbprint, ...)` method only searched by SHA-1 thumbprint, making SHA-2 or SHA-3 thumbprint lookup ambiguous. .NET 10 adds `FindByThumbprint(HashAlgorithmName, ReadOnlySpan<byte>)` that accepts the hash algorithm name explicitly.

```csharp
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

// Old: Find by SHA-1 thumbprint only
var oldColl = store.Certificates.Find(
    X509FindType.FindByThumbprint,
    "ABC123...",  // hex string — SHA-1 only
    validOnly: false);

// New: Find by any hash algorithm
byte[] thumbprintBytes = Convert.FromHexString("ABCDEF...");  // SHA-256 thumbprint bytes

X509Certificate2Collection coll = store.Certificates
    .FindByThumbprint(HashAlgorithmName.SHA256, thumbprintBytes);

// Ensure at most one match (SHA-2 shouldn't collide)
Debug.Assert(coll.Count < 2, "Unexpected collision — has SHA-256 been broken?");
X509Certificate2? cert = coll.SingleOrDefault();

// SHA-3-256 variant
coll = store.Certificates.FindByThumbprint(HashAlgorithmName.SHA3_256, thumbprintBytes);

// PEM-encoded data in ASCII/UTF-8 (no encoding conversion needed — .NET 10)
byte[] pemBytes = File.ReadAllBytes("/etc/ssl/certs/my.crt");  // ASCII/UTF-8 file
PemFields fields = PemEncoding.FindUtf8(pemBytes);             // no char[] needed
byte[] derBytes = Base64.DecodeFromUtf8(pemBytes.AsSpan()[fields.Base64Data]);
```

**Why SHA-1 thumbprints are insufficient:** SHA-1 is considered cryptographically weak. Organizations that rotate to SHA-256 certificates need tooling that can uniquely identify them. The new overload eliminates the ambiguity when both SHA-256 and SHA-3-256 thumbprints are 32 bytes.

### Blazor JavaScript Interop — Property Get/Set and Constructor Invocation (.NET 10)

Blazor .NET 10 adds JS interop APIs for getting and setting JavaScript object properties and invoking JavaScript constructors. Previously these required writing JavaScript helper functions; now they can be done directly from C# via `IJSRuntime`.

```razor
@inject IJSRuntime JS

@code {
    // Invoke a JavaScript constructor — returns a JS object reference
    private IJSObjectReference? _instance;

    protected override async Task OnInitializedAsync()
    {
        // Equivalent to: new jsLib.Counter("start")
        _instance = await JS.InvokeConstructorAsync("jsLib.Counter", "start");
    }

    // Get a property value from a JS object
    private async Task<int> GetCountAsync()
    {
        // Equivalent to: jsLib.counter.value
        return await JS.GetValueAsync<int>("jsLib.counter.value");
    }

    // Set a property on a JS object
    private async Task ResetAsync()
    {
        // Equivalent to: jsLib.counter.value = 0
        await JS.SetValueAsync("jsLib.counter.value", 0);
    }

    // Get/set on a JS object reference returned from InvokeConstructorAsync
    private async Task<string> GetInstancePropertyAsync()
    {
        if (_instance is null) return "";
        return await _instance.GetValueAsync<string>("label");
    }

    private async Task SetInstancePropertyAsync(string label)
    {
        if (_instance is null) return;
        await _instance.SetValueAsync("label", label);
    }

    public async ValueTask DisposeAsync()
    {
        if (_instance is not null)
            await _instance.DisposeAsync();
    }
}
```

**Synchronous variants** (`GetValue<T>`, `SetValue`) are available for Blazor Server rendering where synchronous JS interop is possible. Use async variants for WebAssembly.

**Why it matters:** before .NET 10, reading a JS property from Blazor required writing a JS helper function: `window.getMyProp = () => myObj.prop` and calling `InvokeAsync("getMyProp")`. The new APIs eliminate boilerplate JS shim functions for simple property access, making Blazor-JS interop code far more readable.

---

## Real-World Gotchas — ASP.NET Core 10 [community]

### **OpenAPI 3.1 `nullable` Schema Breaking Change — Client Code Generators**  [community]

ASP.NET Core 10 defaults to OpenAPI 3.1, which represents nullable types as `"type": ["string", "null"]` instead of `"nullable": true`. WHY it causes problems: generated clients (NSwag, Autorest, Kiota) using OpenAPI 3.0 schema conventions may not recognize the new nullable format, leading to generated code that treats `string?` parameters as required non-nullable strings, or fails with schema validation errors. Fix: pin the OpenAPI library to 3.0 with `AddOpenApi(options => options.OpenApiVersion = OpenApiSpecVersion.OpenApi3_0)` until your code generator supports 3.1, then migrate generator and schema handling simultaneously.

```csharp
// Temporary: keep OpenAPI 3.0 while updating your client generator
builder.Services.AddOpenApi(options =>
{
    options.OpenApiVersion = OpenApiSpecVersion.OpenApi3_0;  // stays with "nullable": true
});

// Long-term: migrate generator to 3.1 and remove this override
// NSwag: update to version that supports OpenAPI 3.1 (v14+)
// Kiota: supported natively from GA
```

### **Cookie Auth Redirect-to-Login Surprise After Upgrading to ASP.NET Core 10**  [community]

Teams upgrading a hybrid MVC + API application to ASP.NET Core 10 may find that previously working login redirects stop working for endpoints decorated with `[ApiController]`. WHY it causes problems: ASP.NET Core 10 intercepts cookie auth challenge/forbid for `IApiEndpointMetadata` endpoints and returns 401/403 directly, bypassing the `OnRedirectToLogin` event handler. If you relied on cookie auth to redirect API endpoints (e.g., for a classic AJAX partial-page pattern), those redirects silently stop working. Fix: explicitly opt in to redirects per endpoint by checking `Accept: text/html` in the event handler, or use `RequireAuthorization().WithMetadata(new ExcludeApiEndpointMetadata())` to un-mark specific endpoints.

```csharp
// Detection: log whether the redirect behavior changed after upgrade
builder.Services.AddAuthentication()
    .AddCookie(options =>
    {
        options.Events.OnRedirectToLogin = context =>
        {
            // Log so you can audit which endpoints hit this path
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILogger<Program>>();
            logger.LogInformation(
                "Cookie redirect-to-login for {Path}", context.Request.Path);

            // Only redirect for traditional browser navigation
            bool isBrowser = context.Request.Headers.Accept
                .Any(v => v?.Contains("text/html") == true);
            if (isBrowser)
                context.Response.Redirect(context.RedirectUri);
            else
                context.Response.StatusCode = 401;
            return Task.CompletedTask;
        };
    });
```

---

## Anti-Patterns Quick Reference — ASP.NET Core 10 Additions

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Relying on `nullable: true` in OpenAPI 3.1 output | ASP.NET Core 10 emits `"type": ["T", "null"]` — client generators expecting `nullable: true` break silently | Pin to OpenAPI 3.0 while updating generator, or migrate generator to 3.1 first |
| Expecting cookie auth to redirect API endpoints after upgrading to .NET 10 | ASP.NET Core 10 returns 401/403 for `[ApiController]` and JSON endpoints instead of redirecting | Check `Accept` header in `OnRedirectToLogin` event to preserve redirect for browser navigations |
| Using `MemoryPool<T>.Shared` in long-lived background services | Competes with framework internals for shared buffer pool; hard to profile per-service allocations | Use `IMemoryPoolFactory<T>` from DI to get an isolated, disposable pool per service |
| Finding X.509 certificates by SHA-1 thumbprint in new apps | SHA-1 is weak; SHA-256/SHA-3 certs needed for compliance; old `Find` API only supports SHA-1 | Use `FindByThumbprint(HashAlgorithmName.SHA256, bytes)` for algorithm-specific thumbprint lookup |
| Writing JS helper shim functions for Blazor property read/write | Boilerplate JS required for every property; round-trips through the JS interop boundary | Use `JS.GetValueAsync<T>` / `JS.SetValueAsync` / `JS.InvokeConstructorAsync` directly from C# (.NET 10+) |

---

## C# 14 — Extension Members (`extension` blocks)

C# 14 introduces `extension` blocks as a new way to declare extension members. Unlike the classic `this`-parameter pattern (which only supports instance methods), `extension` blocks support **instance properties**, **static methods**, **static properties**, and **user-defined operators** — all as first-class extension members on any type. Old-style extension methods continue to work and produce identical IL; the new syntax does not break existing callers.

**Instance extension property and method in one block:**

```csharp
public static class SequenceExtensions
{
    // extension block: 'source' is the receiver — in scope for all instance members
    extension<TSource>(IEnumerable<TSource> source)
    {
        // Extension property — callable as sequence.IsEmpty
        public bool IsEmpty => !source.Any();

        // Extension method — callable as sequence.SafeFirst()
        public TSource? SafeFirst()
        {
            foreach (var item in source) return item;
            return default;
        }
    }

    // Static extension block — no receiver name needed
    extension<TSource>(IEnumerable<TSource>)
    {
        // Static extension property — callable as IEnumerable<int>.Empty
        public static IEnumerable<TSource> Empty => Enumerable.Empty<TSource>();

        // Extension operator — callable as seq1 + seq2
        public static IEnumerable<TSource> operator +(
            IEnumerable<TSource> left, IEnumerable<TSource> right)
            => left.Concat(right);
    }
}
```

Usage:

```csharp
IEnumerable<int> numbers = Enumerable.Range(1, 5);

bool empty = numbers.IsEmpty;        // instance extension property
int? first = numbers.SafeFirst();    // instance extension method
var combined = numbers + [6, 7, 8]; // extension operator

var identity = IEnumerable<int>.Empty; // static extension property
```

**Generic extension blocks with extra type parameters:**

When a member in the block needs an additional type parameter beyond the receiver's, declare it on the member itself:

```csharp
extension<TReceiver>(IEnumerable<TReceiver> source)
{
    // TArg is only needed for this member — declared on the method, not the block
    public IEnumerable<TReceiver> AppendConverted<TArg>(
        IEnumerable<TArg> second, Func<TArg, TReceiver> convert)
    {
        foreach (var item in source) yield return item;
        foreach (var item in second) yield return convert(item);
    }
}
```

**Coexistence with old-style extension methods:**

Old `this`-parameter extension methods still compile and behave identically. Migration is binary and source compatible — you can convert an old extension method to the new block syntax without a breaking change. The IL output is the same.

```csharp
// Old style — still valid, not deprecated
public static IEnumerable<int> AddValue(this IEnumerable<int> sequence, int operand)
{
    foreach (var item in sequence) yield return item + operand;
}

// New style — equivalent IL, preferred for new code with properties/operators
extension(IEnumerable<int> sequence)
{
    public IEnumerable<int> AddValue(int operand)
    {
        foreach (var item in sequence) yield return item + operand;
    }
}
```

---

## C# 14 — `field`-Backed Properties

The `field` contextual keyword lets you reference the compiler-generated backing field from inside a property accessor — without declaring a separate private field. This eliminates the boilerplate "declare backing field, keep name in sync" pattern for custom setters and lazy initialization.

**INotifyPropertyChanged pattern (the motivating use case):**

```csharp
using System.ComponentModel;
using System.Runtime.CompilerServices;

public class OrderViewModel : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    // Before C# 14: needed a private backing field _status
    // Now: `field` IS the backing field — scoped to accessors only
    public string Status
    {
        get;
        set
        {
            if (field == value) return;
            field = value;
            OnPropertyChanged();
        }
    } = "Pending";  // property initializer sets field directly (does NOT call setter)

    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
```

**Lazy initialization:**

```csharp
public class ReportService
{
    // 'field' is null-resilient: compiler infers backing field as string? (nullable)
    // and does NOT warn about uninitialized in constructor
    public string Title => field ??= ComputeTitle();

    private static string ComputeTitle() => "Generated Report";
}
```

**Mixed accessors — auto get + custom set:**

```csharp
public class Temperature
{
    public double Celsius
    {
        get;  // auto-get: reads backing field directly
        set
        {
            if (value < -273.15)
                throw new ArgumentOutOfRangeException(nameof(value),
                    "Temperature cannot go below absolute zero.");
            field = value;
        }
    }

    public double Fahrenheit => Celsius * 9 / 5 + 32;
}
```

**Breaking change — `field` as an identifier:**

```csharp
// If your class has a member named 'field', it now silently shadows it in accessors
public class MyClass
{
    private int field;   // <-- this was fine in C# 13

    public int Value
    {
        // In C# 14, 'field' inside accessors refers to the synthesized backing field,
        // NOT this.field — a CS8652 warning fires to alert you
        get => field;    // WARNING CS8652 in LangVersion 14
    }
}

// Fix: qualify the class member explicitly
public int Value { get => this.field; }

// Or: rename the class member to avoid the conflict
private int _field;
```

**Struct `readonly` interaction:**

```csharp
public struct Measurement
{
    // readonly struct or readonly property: backing field is readonly
    // Mutation in set is a compile error
    public readonly double Value
    {
        get;
        set  // ERROR: CS191 — field is readonly in a readonly context
        {
            field = value;  // cannot mutate readonly field
        }
    }
}
```

**Field-targeted attributes:**

```csharp
// [field: ...] targets the synthesized backing field when field is used
[field: NonSerialized]
public string CachedValue
{
    get => field ??= Compute();
}
```

---

## C# 14 — Null-Conditional Assignment

C# 14 allows the null-conditional member access operators (`?.` and `?[]`) on the **left-hand side** of an assignment or compound assignment. The right-hand side is evaluated only when the left-hand side is non-null — enabling safe, concise null-guard assignment without an `if` statement.

```csharp
public class Order
{
    public string? Status { get; set; }
    public List<string>? Notes { get; set; }
}

// Before C# 14:
if (order is not null)
    order.Status = GetNextStatus();

// C# 14 — null-conditional assignment: equivalent, concise
order?.Status = GetNextStatus();  // GetNextStatus() called only if order != null

// Indexer assignment with null-conditional:
messages?[0] = "first message";  // safe even if messages is null

// Compound assignment — += / -= / *= etc. are all allowed:
order?.Status += " (modified)";  // string concatenation only if order != null

// NOT allowed: ++ and -- are not supported with null-conditional
// order?.Count++;  // CS0023 — compile error
```

**Short-circuit evaluation of the right-hand side:**

The right-hand side is only evaluated when the null check passes. This is significant for methods with side effects:

```csharp
int index = 0;
int GenerateNextIndex() => ++index;

int[]? values = null;
values?[2] = GenerateNextIndex();  // GenerateNextIndex() is NOT called — values is null
Console.WriteLine(index);  // 0

values = new int[5];
values?[2] = GenerateNextIndex();  // GenerateNextIndex() IS called — values is non-null
Console.WriteLine(index);  // 1
Console.WriteLine(values[2]);  // 1
```

**Thread-safe event raise (classic pattern, still valid):**

```csharp
// Existing pattern remains canonical — not replaced by null-conditional assignment
PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Status)));
```

**Limitations and non-obvious behavior:**

```csharp
// NOT a variable: cannot be ref-assigned, passed as ref/out, or used as a ref local
string? firstName = customer?.FirstName;  // this is fine — reading
// ref string f = ref customer?.FirstName;  // CS8156 — not allowed

// Coexists with existing null-conditional chain:
// If order is null, none of the chain fires — including the assignment
order?.Customer?.Address?.City = "Seattle";  // safe — no NullReferenceException
```

---

## C# 14 — First-Class Span Implicit Conversions

C# 14 promotes `Span<T>` and `ReadOnlySpan<T>` to first-class status by adding **implicit span conversions** as standard conversions recognized by overload resolution, extension method lookup, and generic type inference.

**Conversion matrix (all now implicit):**

| From | To | Notes |
|------|----|-------|
| `T[]` | `Span<T>` | New in C# 14 |
| `T[]` | `ReadOnlySpan<T>` | New in C# 14 (covariant-compatible element types) |
| `Span<T>` | `ReadOnlySpan<T>` | New in C# 14 |
| `string` | `ReadOnlySpan<char>` | New in C# 14 |
| `ReadOnlySpan<TDerived>` | `ReadOnlySpan<TBase>` | Covariance via CastUp |

**Practical benefit — single overload covers array, Span, and ReadOnlySpan:**

```csharp
// Before C# 14: needed three overloads for full coverage
public static bool StartsWith<T>(this T[] array, T value) where T : IEquatable<T>
    => array.AsSpan().StartsWith(value);
public static bool StartsWith<T>(this Span<T> span, T value) where T : IEquatable<T>
    => span.Length != 0 && span[0].Equals(value);
public static bool StartsWith<T>(this ReadOnlySpan<T> span, T value) where T : IEquatable<T>
    => span.Length != 0 && span[0].Equals(value);

// C# 14: one overload — array and Span both implicitly convert to ReadOnlySpan<T>
public static bool StartsWith<T>(this ReadOnlySpan<T> span, T value) where T : IEquatable<T>
    => span.Length != 0 && EqualityComparer<T>.Default.Equals(span[0], value);

// All three now work:
int[] array = [1, 2, 3];
Span<int> span = array;
ReadOnlySpan<int> ros = array;
bool r1 = array.StartsWith(1);  // C# 14: valid (array → ReadOnlySpan<int>)
bool r2 = span.StartsWith(1);   // C# 14: valid (Span → ReadOnlySpan<int>)
bool r3 = ros.StartsWith(1);    // always valid
```

**Betterness rule — ReadOnlySpan is preferred over Span:**

When both `Span<T>` and `ReadOnlySpan<T>` overloads exist, `ReadOnlySpan<T>` wins. This avoids `ArrayTypeMismatchException` for covariant arrays.

```csharp
static class C
{
    public static void Process<T>(IEnumerable<T> e) => Console.Write("IEnumerable");
    public static void Process<T>(ReadOnlySpan<T> s) => Console.Write("ReadOnlySpan"); // preferred
    public static void Process<T>(Span<T> s) => Console.Write("Span");
}

int[] arr = [1, 2, 3];
C.Process(arr);  // C# 14: "ReadOnlySpan" (not "IEnumerable")
```

---

## Real-World Gotchas — C# 14 Span Conversions [community]

### **`Reverse()` on Arrays Returns `void` After Upgrading to C# 14**  [community]

In C# 13, `array.Reverse()` resolved to `Enumerable.Reverse<T>(IEnumerable<T>)`, which returns `IEnumerable<T>`. In C# 14, the new implicit span conversion causes it to resolve to `MemoryExtensions.Reverse<T>(Span<T>)` — which reverses **in place** and returns `void`. WHY it causes problems: code that iterates the result of `.Reverse()` in a `foreach` loop or LINQ chain silently breaks with a compile-time error (`void` is not enumerable). This is a real-world migration break reported widely by the .NET community when updating to .NET 10 / C# 14. Fix: call `Enumerable.Reverse(array)` explicitly, or use `array.AsEnumerable().Reverse()` to force the LINQ overload. .NET 10 adds a `T[].Reverse()` overload returning `IEnumerable<T>` to mitigate new code, but existing code compiled under C# 14 may still need changes.

```csharp
int[] numbers = [1, 2, 3, 4, 5];

// BAD in C# 14: resolves to MemoryExtensions.Reverse — returns void, not IEnumerable
// foreach (var n in numbers.Reverse()) { }  // CS0030 compile error

// GOOD: force LINQ overload explicitly
foreach (var n in Enumerable.Reverse(numbers)) { }

// ALSO GOOD: use AsEnumerable() to prevent span conversion on the receiver
foreach (var n in numbers.AsEnumerable().Reverse()) { }
```

### **xUnit `Assert.Equal` Ambiguity with Array Arguments**  [community]

C# 14's new span conversions cause xUnit's `Assert.Equal(T[], T[])` and `Assert.Equal(ReadOnlySpan<T>, Span<T>)` overloads to become ambiguous for array arguments. WHY it causes problems: test code that called `Assert.Equal(expected, actual)` with two arrays now fails to compile in C# 14 because the compiler cannot choose between the array overload and the span overload. Fix: call `.AsSpan()` on one argument to force the span overload, or use `Assert.Equal(expected.AsEnumerable(), actual)`. xUnit v2 adds more specific overloads to resolve this.

```csharp
int[] expected = [1, 2, 3];
int[] actual = GetResult();

// BAD in C# 14: CS0121 ambiguous — Assert.Equal<T>(T[], T[]) vs Assert.Equal<T>(ReadOnlySpan<T>, Span<T>)
// Assert.Equal(expected, actual);

// GOOD: explicit span conversion resolves ambiguity
Assert.Equal(expected.AsSpan(), actual.AsSpan());

// ALSO GOOD: force IEnumerable overload
Assert.Equal((IEnumerable<int>)expected, actual);
```

### **Covariant Array Crash — `Span<T>` Constructor Throws `ArrayTypeMismatchException`**  [community]

C# 14 now prefers `Span<T>` overloads over `IEnumerable<T>` overloads for arrays. This is unsafe for covariant arrays (arrays where the element type was assigned from a more derived type). WHY it causes problems: `new Span<object>(stringArray)` throws `ArrayTypeMismatchException` at runtime because `Span<object>` cannot alias a `string[]`. In C# 13 the `IEnumerable<object>` overload was chosen safely; in C# 14 the `Span<object>` overload is chosen and crashes. Fix: use `ReadOnlySpan<T>` overloads (which are preferred over `Span<T>` by the betterness rule and do not have this covariance issue), or use `.AsEnumerable()` to force the IEnumerable path.

```csharp
string[] strings = ["a", "b", "c"];
object[] objects = strings;  // covariant array assignment

static class Processor
{
    public static void Run<T>(IEnumerable<T> e) => Console.Write("safe");
    public static void Run<T>(Span<T> s) => Console.Write("unsafe"); // C# 14 prefers this
    public static void Run<T>(ReadOnlySpan<T> s) => Console.Write("safe span"); // even more preferred
}

// DANGEROUS in C# 14 if only Span<T> overload exists:
// Processor.Run(objects);  // resolves to Span<object>, crashes at runtime

// SAFE: explicitly use IEnumerable path
Processor.Run(objects.AsEnumerable());

// SAFE: add ReadOnlySpan<T> overload — preferred over Span<T> by betterness rule
// Processor.Run(objects);  // resolves to ReadOnlySpan<object> — no ArrayTypeMismatchException
```

### **Expression Tree LINQ Provider Surprise — `MemoryExtensions.Contains` Instead of `Enumerable.Contains`**  [community]

In C# 14, `array.Contains(value)` inside an expression tree now resolves to `MemoryExtensions.Contains` (the Span overload, preferred by new betterness rules), not `Enumerable.Contains`. WHY it causes problems: LINQ-to-SQL, EF Core, and other expression tree interpreters pattern-match on `Enumerable.Contains` to generate SQL `IN` clauses. If they receive `MemoryExtensions.Contains` instead, they either throw `NotSupportedException` or silently fall back to client-side evaluation — loading the full table into memory. Fix: use `Enumerable.Contains(array, value)` explicitly in expression tree lambdas until your ORM updates its visitor.

```csharp
// BAD in C# 14 inside an expression tree — resolves to MemoryExtensions.Contains
Expression<Func<int[], int, bool>> expr = (array, num) => array.Contains(num);
// LINQ-to-SQL / EF Core visitor may not recognize MemoryExtensions.Contains → runtime error

// GOOD: force Enumerable.Contains explicitly
Expression<Func<int[], int, bool>> safe = (array, num) => Enumerable.Contains(array, num);

// For EF Core queries with IEnumerable (not arrays):
int[] ids = [1, 2, 3];
var orders = await db.Orders.Where(o => ids.Contains(o.Id)).ToListAsync(ct);  // safe — ids is array, EF translates
// Risk only appears when inside Expression<Func<...>> using span-preferred APIs
```

---

## Real-World Gotchas — C# 14 Language Features [community]

### **`field` Keyword Silently Shadows a Class Member Named `field`**  [community]

If a class has an instance field or property named `field` and you use it inside a property accessor in C# 14, the compiler now resolves `field` to the synthesized backing field — not the class member. WHY it causes problems: in C# 13 the identifier `field` referred to the class member; in C# 14 it silently refers to something different, potentially causing incorrect reads/writes with no runtime error. The compiler emits a warning (CS8652) alerting you to the ambiguity, but it is easy to miss in large codebases during an LangVersion upgrade. Fix: qualify the class member as `this.field`, or rename it to `_field` / `@field`.

### **`field` in Lambda Inside Property Accessor Captures the Backing Field**  [community]

A lambda or local function declared inside a property accessor can capture `field`, and this capture keeps the backing field reachable from outside the property's immediate execution. WHY it causes problems: if you store the lambda (e.g., assign it to a field or pass it to a callback), the captured `field` reference can be mutated or read long after the property's setter/getter completes. In most cases this is intentional (e.g., `field ??= Compute()`), but in cases where the lambda is stored and later invoked, it can lead to unexpected mutation of the property's backing state.

### **`extension` Member Scope — All Members in One Static Class Must Have Unique Signatures**  [community]

`extension` blocks do not introduce a new scope. All members declared across all `extension` blocks in the same `static class` must have globally unique signatures within that class. WHY it causes problems: if two `extension` blocks declare a method with the same name and parameter types (even for different receiver types), a compile error occurs. This differs from overloading behavior developers expect from regular method overloads on a class. Fix: use different static classes for extension members on different receiver types if their method signatures would conflict.

```csharp
public static class Extensions
{
    extension(IEnumerable<int> source)
    {
        public bool IsEmpty => !source.Any();
    }

    extension(IList<int> source)
    {
        // ERROR if IsEmpty already declared above — unique signature rule
        // public bool IsEmpty => source.Count == 0;  // CS0111 duplicate
    }
}
```

---

## Anti-Patterns Quick Reference — C# 14 Additions

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Calling `.Reverse()` on an array and iterating the result in C# 14 | Resolves to `MemoryExtensions.Reverse` which returns `void` (in-place), not `IEnumerable<T>` | Use `Enumerable.Reverse(array)` or `array.AsEnumerable().Reverse()` explicitly |
| Passing covariant arrays to a `Span<T>` overload | `new Span<object>(stringArray)` throws `ArrayTypeMismatchException` at runtime | Add a `ReadOnlySpan<T>` overload (preferred by betterness rule) or use `.AsEnumerable()` |
| Using `array.Contains()` inside LINQ expression trees in C# 14 | Resolves to `MemoryExtensions.Contains` — unsupported by most LINQ-to-SQL/EF visitors | Use `Enumerable.Contains(array, value)` explicitly inside expression-tree lambdas |
| Having a member named `field` in a class with C# 14 property accessors | Silently shadowed by synthesized backing field; reads/writes wrong thing | Rename to `_field` or use `this.field` qualifier |
| Declaring extension members with conflicting signatures across `extension` blocks in the same class | All members across all extension blocks in one class share a flat namespace — CS0111 error | Separate extension blocks for conflicting signatures into different static classes |
| Using null-conditional assignment `?.=` with `++`/`--` | Increment/decrement are not supported with null-conditional assignment (CS0023) | Write an explicit null-check `if (x is not null) x.Count++` |
