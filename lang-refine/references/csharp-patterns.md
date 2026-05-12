# C# Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 40 | score: 98/100 | date: 2026-05-12 -->
<!-- iteration trace (latest):
     Iter 40 (2026-05-12): added .NET 10 MTP native dotnet test support via global.json (runner opt-in, compatibility
       matrix, before/after workflow comparison); added xUnit v3 TestContext static API (TestContext.Current,
       SendDiagnosticMessage, CancellationToken, TestState, thread-continuation gotcha); added TUnit [Timeout]
       attribute patterns (per-test budget, Retry combination, assembly-level default, CT injection, swallowed
       OperationCanceledException gotcha); added C# 14 extension blocks as test builder helpers (extension
       properties and static factories for test setup, field keyword in test builder lazy init, static-class
       requirement gotcha) — sourced from learn.microsoft.com/dotnet/core/whats-new/dotnet-10/sdk,
       xunit.net/docs, github.com/thomhurst/TUnit, learn.microsoft.com/dotnet/csharp/whats-new/csharp-14
     Iter 39 (2026-05-12): added Code Coverage section (coverlet.collector, dotnet test --collect, coverlet.msbuild
       MSBuild integration, reportgenerator HTML reports, threshold enforcement, dotnet-coverage tool vs coverlet
       comparison); added Stryker.NET Mutation Testing (install, run, stryker-config.json thresholds high/low/break,
       mutation-level, coverage-analysis, --since incremental analysis, dashboard reporter); added Test Ordering
       section (xUnit ITestCaseOrderer + TestPriorityAttribute, xUnit CollectionBehavior parallelism control,
       NUnit [Order] attribute); added .NET Aspire Integration Testing (DistributedApplicationTestingBuilder,
       CreateAsync, CreateHttpClient, WaitForResourceAsync, GetEndpoint); added community gotchas: coverlet
       collector vs msbuild instrument-time difference, Stryker timeout loops on complex async code, xUnit
       ITestCaseOrderer breaks xUnit v3 due to assembly name change, Aspire test startup latency and resource
       readiness races — sourced from learn.microsoft.com/dotnet/core/testing/unit-testing-code-coverage,
       stryker-mutator.io/docs/stryker-net, learn.microsoft.com/dotnet/core/testing/order-unit-tests,
       learn.microsoft.com/dotnet/aspire
     Iter 38 (2026-05-12): added Testcontainers.NET integration testing (ContainerBuilder, SqlServerContainer,
       PostgreSqlContainer, lifecycle management with IAsyncLifetime, resource reuse); added MockHttp /
       WireMock.NET for HttpClient testing (RichardSzalay.MockHttp — MockedRequest, When/Respond, Verify;
       WireMock.Net — WireMockServer, WithBody JSON matching, stateful scenarios); added xUnit
       ITestOutputHelper diagnostic logging; added NetArchTest / ArchUnitNET architecture enforcement tests
       (layering, naming, dependency rules); added community gotchas: Testcontainers socket privilege on Linux CI,
       MockHttp BaseAddress mismatch, WireMock.Net port conflicts, NetArchTest reflection overhead on large assemblies
       — sourced from dotnet.testcontainers.org, github.com/richardszalay/mockhttp,
       github.com/WireMock-Net/WireMock.Net, github.com/BenMorris/NetArchTest
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
     Iter 37 (2026-05-12): added MSTest SDK project type (MSTest.Sdk/4.x, EnableAspireTesting, EnablePlaywright)
       and MTP extension ecosystem (Retry, Hot Reload, Crash/Hang Dump); added xUnit v3 Assert.Equivalent
       structural assertion with RespectingRuntimeTypes and RespectingDeclaredTypes modes; added NUnit 4.x
       FixtureLifeCycle attribute (SingleInstance vs InstancePerTestCase) with parallel test isolation pattern;
       added FluentAssertions v8.9 BeEqualTo/NotBeEqualTo collection aliases and type-based property exclusion
       in BeEquivalentTo; added community gotchas: MSTest SDK Dependabot/NuGet update blind spot, MTP Retry
       tool license surprise, xUnit Assert.Equivalent runtime-type gotcha with sealed vs open hierarchies —
       sourced from learn.microsoft.com/dotnet/core/testing/unit-testing-mstest-sdk,
       learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-retry,
       learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-hot-reload, and
       github.com/fluentassertions/fluentassertions/releases/tag/8.9.0
     Iter 36 (2026-05-12): added NUnit 4.x migration guide (Classic API → NUnit.Framework.Legacy, Assert.AreEqual
       obsolete, NUnit4TestAdapter requirement); added MSTest v4 — Assert.That lambda, CallerArgumentExpression
       diagnostics, breaking API surface changes; added FluentAssertions v8 breaking changes (Xceed Community
       License, DataSets moved to separate package, Span/Memory/ReadOnlySpan assertions, BeNaN/NotBeNaN,
       ComparingNullCollectionsAsEmpty, ComparingNullStringsAsEmpty, BeEquivalentTo perf improvement);
       added TUnit framework overview (source generators, parallel-by-default, [Arguments]/[MatrixDataSource]/
       [ClassDataSource], DI injection, [DependsOn], [NotInParallel], built-in assertions); added xUnit v3
       CancellationToken injection into test methods and Assert.Multiple soft assertions; added community
       gotchas: FluentAssertions v8 Xceed license surprise, NUnit 4 classic API removal shock, TUnit parallel
       default breaks test-order dependencies — sourced from github.com/fluentassertions/fluentassertions/releases,
       github.com/microsoft/testfx/releases, github.com/nunit/nunit/releases, github.com/thomhurst/TUnit
     Iter 35 (2026-05-12): added comprehensive testing section — Moq patterns (MockBehavior.Strict/Loose,
       argument matchers, SetupSequence, Verify call counts, async Task/ValueTask setups), NSubstitute
       as alternative (Arg.*, Received(), DidNotReceive()), FluentAssertions deep-dive (BeEquivalentTo,
       WithStrictOrdering, exception assertions, FA v7 licensing change), xUnit v3 new features
       (IAsyncLifetime, TheoryData<T>, IAssemblyFixture, fixture scoping table), NUnit data-driven
       tests ([TestCase], [TestCaseSource], [Values] combinatorial, async ThrowsAsync), MSTest v3
       async TestInitialize/Cleanup + Parallelize, CustomWebApplicationFactory with mock injection,
       Bogus test data fakers with seeded determinism, AutoFixture [AutoData], Respawn DB reset,
       Verify snapshot testing; added Testing Anti-Patterns table (14 entries) and 5 community
       gotchas (Moq non-virtual silent failure, VerifyAll omission, IClassFixture order dependency,
       BeEquivalentTo unordered collections, Task.Delay flaky timing)
       AddStandardHedgingHandler, AddResilienceHandler custom pipeline (retry/circuit-breaker/timeout), DisableForUnsafeHttpMethods,
       dynamic options reload, TimeoutRejectedException vs TimeoutException gotcha, Application Insights ordering gotcha;
       sources: learn.microsoft.com/dotnet/core/resilience/http-resilience
     Iter 33 (2026-05-12): added Channel<T> multi-producer/multi-consumer fan-out pattern, BoundedChannelFullMode
       drop modes (DropOldest/DropNewest/DropWrite) with itemDropped callback; added sync-over-async bridge
       pattern (GetAwaiter().GetResult() vs Task.Run wrapping, deadlock risks); added LINQ-async interaction
       idiom (ToArray vs ToList choice for WhenAll vs WhenAny patterns); added community gotchas: LINQ deferred
       execution silently prevents concurrent task fan-out, single-producer channel optimisation lost when
       SingleWriter is left as true with concurrent writes; sourced from
       learn.microsoft.com/dotnet/core/extensions/channels and
       learn.microsoft.com/dotnet/csharp/asynchronous-programming/async-scenarios
     Iter 32 (2026-05-12): added .NET 10 JIT deep-dive (struct argument promotion, loop inversion
       graph-based improvement, array interface method devirtualization, array enumeration
       de-abstraction, code layout Travelling Salesman heuristic, inlining improvements — return type
       propagation and profile-data-aware size tolerance); .NET 10 stack allocation improvements
       (small value-type arrays, small reference-type arrays, escape analysis for local struct fields
       and delegates); AVX10.2 support; Arm64 write-barrier improvements; NativeAOT type
       preinitializer improvements; added ActivitySourceOptions + TelemetrySchemaUrl for
       OpenTelemetry-aligned tracing; rate-limit trace sampling; Activity events/links out-of-proc
       serialization; ISOWeek DateOnly overloads; StringNormalizationExtensions span APIs;
       UTF-8 hex-string conversion; OrderedDictionary TryAdd/TryGetValue with index output;
       IReadOnlyTensor / Tensor<T> stable APIs; ExportPkcs12 with algorithm selection; static
       lambda modifier; lambda attributes idiom; community gotchas: captured-closure heap allocation
       in .NET 9 vs stack in .NET 10, static lambda prevents accidental capture, lambda attribute
       limitations — sourced from learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime,
       learn.microsoft.com/dotnet/core/whats-new/dotnet-10/libraries,
       learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions
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

---

## .NET 10 Runtime — JIT Compiler Improvements

.NET 10 introduces significant JIT enhancements that improve performance without any code changes. Understanding these improvements helps write code that takes maximum advantage of the JIT's capabilities, and avoids patterns that accidentally defeat optimizations.

### Struct Argument Promotion into Shared Registers

When a struct is passed to a method and the calling convention requires packing multiple members into a single register, the JIT now places promoted struct members into shared registers directly — without first storing to memory and reloading. This eliminates intermediate memory operations for small structs with members smaller than the register width.

```csharp
// The JIT optimizes structs whose members fit in registers
// Before .NET 10: members stored to stack, then loaded into register
// .NET 10: direct register packing — no intermediate memory round-trip
struct Pair
{
    public int X;
    public int Y;
}

// Call this method: JIT packs X and Y into one 64-bit register on x64
// You don't need to do anything special — the JIT handles it automatically
static void Consume(Pair p) => Console.WriteLine(p.X + p.Y);

// Best practice: keep value-type structs small and tightly packed
// Benefit increases when the struct is used in tight loops
```

### Graph-Based Loop Inversion

.NET 10 upgrades loop inversion from lexical analysis to graph-based loop recognition, covering all natural loops (single entry-point). This enables the JIT to transform more `while` loops into `do-while` shapes, unlocking loop cloning, loop unrolling, and induction variable optimizations on loops that were previously missed.

```csharp
// The JIT transforms this while loop:
while (i < array.Length)
{
    sum += array[i++];
}

// Into: if (i < array.Length) { do { sum += array[i++]; } while (i < array.Length); }
// The do-while shape allows the JIT to remove bounds checks inside the loop body
// No code changes needed — compiler handles it; write idiomatic while/for loops
```

### Array Interface Method Devirtualization

Previously the JIT could not devirtualize array interface methods (e.g., `IEnumerable<T>` on `T[]`), leaving virtual dispatch overhead in `foreach` over `IEnumerable<T>` variables holding arrays. .NET 10 fixes this: the JIT now devirtualizes array interface methods, enabling inlining and stack allocation of the enumerator.

```csharp
// .NET 9: virtual calls remain, blocking inlining
// .NET 10: JIT devirtualizes — same performance as direct array iteration
static int Sum(int[] array)
{
    IEnumerable<int> temp = array;     // typed as interface
    int sum = 0;
    foreach (var num in temp)          // .NET 10: devirtualized to array path
        sum += num;
    return sum;
}

// Best practice: don't artificially widen array types to interfaces in hot paths
// If you DO need IEnumerable<T>, .NET 10 removes the performance penalty automatically
```

---

## .NET 10 Runtime — Stack Allocation Improvements

.NET 10 significantly expands the JIT's ability to stack-allocate objects, reducing GC pressure in methods that create short-lived objects.

### Small Arrays of Value Types — Automatic Stack Allocation

The JIT now stack-allocates small, fixed-sized arrays of value types that don't escape their parent method. No annotation is required.

```csharp
// .NET 10: JIT stack-allocates {1, 2, 3} — no heap allocation, no GC pressure
static void Sum()
{
    int[] numbers = { 1, 2, 3 };
    int sum = 0;
    for (int i = 0; i < numbers.Length; i++)
        sum += numbers[i];
    Console.WriteLine(sum);
}

// Conditions for stack allocation:
// 1. Fixed size known at compile time
// 2. Array doesn't escape the method (not stored in fields, not returned, not passed out)
// 3. Element type is a value type (no GC pointers in .NET 10 for value types;
//    reference types also supported — see next section)
```

### Small Arrays of Reference Types — Stack Allocation (.NET 10 Extension)

.NET 10 extends stack allocation to small arrays of reference types whose lifetime is scoped to the method.

```csharp
// .NET 10: JIT stack-allocates string[] — no heap allocation
static void Print()
{
    string[] words = { "Hello", "World!" };
    foreach (var str in words)
        Console.WriteLine(str);
}

// The array reference itself is stack-allocated; the strings are still on the heap
// This pattern is common in ASP.NET Core middlewares and message formatters
// No code changes needed — the JIT decides automatically
```

### Escape Analysis for Local Struct Fields and Delegates

.NET 10 extends escape analysis to objects referenced by **local struct fields** and to **delegates**. An object held only by a non-escaping local struct no longer forces heap allocation.

```csharp
struct GCStruct { public int[] Arr; }

static int Main()
{
    int[] x = new int[10];
    GCStruct y = new GCStruct { Arr = x };
    // .NET 9: x heap-allocated (struct field blocked escape analysis)
    // .NET 10: x stack-allocated — y doesn't escape, so x doesn't either
    return y.Arr[0];
}

// Delegate escape analysis: Func<T> allocated on stack when it doesn't escape
static int RunLocal()
{
    int local = 1;
    var func = (int x) => x + local;  // closure + delegate
    int sum = 0;
    for (int i = 0; i < 100; i++) sum += func(i);
    // .NET 10: Func object is stack-allocated (doesn't escape RunLocal)
    // Closure object (holding 'local') still heap-allocated in .NET 10;
    // planned for improvement in future releases
    return sum;
}
```

**Practical guidance:** write natural code — small local arrays, short-lived lambdas, structs holding arrays. The JIT's escape analysis handles allocation decisions automatically. Avoid patterns that force escape: storing in fields, returning from methods, or passing via `ref` out-parameters.

---

## .NET 10 Runtime — Other JIT and Platform Improvements

### AVX10.2 Support (x64)

.NET 10 adds intrinsics for AVX10.2 via `System.Runtime.Intrinsics.X86.Avx10v2`. AVX10.2 is disabled by default until compatible hardware is available. Use `Avx10v2.IsSupported` to guard before use — the same pattern as all other hardware intrinsics.

```csharp
using System.Runtime.Intrinsics.X86;

if (Avx10v2.IsSupported)
{
    // Use AVX10.2 intrinsics here
    // Currently: write code paths, enable when hardware becomes available
}
else
{
    // Scalar or AVX2 fallback
}
```

### Arm64 Write-Barrier Improvements

.NET 10 ports the dynamic write-barrier selection (already available on x64) to Arm64. The new default Arm64 write-barrier handles GC regions more precisely, producing **8–20% GC pause time improvements** in benchmarks. This is automatic — no code changes needed. The improvement is most visible in server workloads with large heaps and frequent Gen0/Gen1 collections.

### NativeAOT Type Preinitializer Improvements

NativeAOT's type preinitializer now supports all variants of `conv.*` (casting/conversion opcodes) and `neg` opcodes. This allows static constructors and type initializers that contain casts or negations to be preinitialized at compile time, reducing runtime startup cost in AOT-published applications.

---

## Lambda Expressions — C# Idioms for Static Lambdas and Attributes

### Static Lambda Modifier — Prevent Accidental Capture

The `static` modifier on a lambda expression prevents it from capturing any local variables or instance state from the enclosing scope. Use it on lambdas in hot paths or event handlers where you intentionally do not want to close over state.

```csharp
// Static lambda: cannot capture outer variables — captures only static members
Func<double, double> square = static x => x * x;

// Useful in LINQ pipelines to signal "no captures" and prevent accidental closures
var activePrimes = numbers
    .Where(static n => n > 1 && IsPrime(n))  // 'static' prevents accidentally capturing a local
    .Select(static n => n * n)
    .ToList();

// Static lambdas in event subscriptions:
button.Click += static (sender, e) => Console.WriteLine("Clicked");
// Compiler enforces: no access to 'this' or instance fields inside a static lambda

// Common gotcha: if you try to capture, you get CS8421 — a helpful compile-time error
int threshold = 10;
// var filter = static x => x > threshold;  // CS8421: cannot capture 'threshold'
var filter = static x => x > 10;            // correct: use literal
```

### Lambda Attributes — Annotating Lambdas for Analysis

C# supports attributes on lambda expressions and their parameters. Attributes on lambdas are visible to analyzers via reflection but are **not enforced by the delegate `Invoke` path** — the runtime ignores them at invocation time.

```csharp
using System.Diagnostics.CodeAnalysis;

// Attribute on a lambda parameter — useful for null analysis
var concat = ([DisallowNull] string a, [DisallowNull] string b) => a + b;

// Return attribute via [return: ...] syntax
var safe = [return: NotNullIfNotNull(nameof(s))] (string? s) =>
    s is null ? null : s.Trim();

// Attribute on the lambda expression itself — useful for code analyzers
Func<string?, int?> parse = [ProvidesNullCheck] (s) =>
    s is not null ? int.Parse(s) : null;

// IMPORTANT: ConditionalAttribute CANNOT be applied to a lambda
// The attribute has no effect at invocation time — design for analysis tools, not runtime behavior
// Prefer applying [Obsolete], [RequiresUnreferencedCode], etc. on named methods instead
```

### Lambda Parameter Modifiers Without Explicit Types (C# 14)

C# 14 allows adding parameter modifiers (`ref`, `out`, `in`, `scoped`, `ref readonly`) to lambda parameters without specifying the explicit type, as long as the compiler can infer the type.

```csharp
// C# 13 and earlier: modifiers required explicit types on ALL parameters
delegate bool TryParse<T>(string text, out T result);
TryParse<int> old = (string text, out int result) => int.TryParse(text, out result);

// C# 14: modifiers allowed on implicitly-typed parameters
TryParse<int> modern = (text, out result) => int.TryParse(text, out result);

// 'scoped' modifier — signals ref struct doesn't escape beyond the lambda
Func<Span<int>, int> sumSpan = (scoped Span<int> s) =>
{
    int total = 0;
    foreach (var n in s) total += n;
    return total;
};

// NOTE: 'params' modifier STILL requires explicit type on all parameters
// delegate int Sum(params int[] values);
// Sum sum = (params int[] v) => v.Sum();  // still required: explicit type on params parameter
```

---

## .NET 10 Libraries — Additional APIs

### ActivitySourceOptions and TelemetrySchemaUrl (OpenTelemetry Alignment)

`ActivitySource` and `Meter` now accept a telemetry schema URL, aligning with the OpenTelemetry specification's `schemaUrl` concept. Use `ActivitySourceOptions` to configure all properties at construction time.

```csharp
using System.Diagnostics;

// Before .NET 10: no telemetry schema URL support
// var source = new ActivitySource("MyApp.Orders", "1.0.0");

// .NET 10: use ActivitySourceOptions for full configuration
var source = new ActivitySource(new ActivitySourceOptions
{
    Name = "MyApp.Orders",
    Version = "1.0.0",
    TelemetrySchemaUrl = "https://opentelemetry.io/schemas/1.24.0"
});

// Meter also supports TelemetrySchemaUrl
var meter = new System.Diagnostics.Metrics.Meter(
    "MyApp.Metrics",
    version: "1.0.0",
    tags: null,
    scope: null);
// Meter.TelemetrySchemaUrl is set via the Meter constructor overload that accepts it

// Why it matters: OpenTelemetry collectors use schemaUrl to apply semantic convention
// transformations. Setting it prevents "unknown schema" warnings in OTel backends.
```

### Activity Events and Links — Out-of-Process Serialization (.NET 10)

The `Microsoft-Diagnostics-DiagnosticSource` event-source provider now serializes `ActivityEvent` and `ActivityLink` metadata when writing out-of-process traces. Previously only span start/stop and basic tags were serialized; events and links were silently dropped.

```csharp
using System.Diagnostics;

using var activity = ActivitySource.StartActivity("ProcessOrder");
if (activity is not null)
{
    // Events — now serialized out-of-process in .NET 10
    activity.AddEvent(new ActivityEvent("validation.started"));
    activity.AddEvent(new ActivityEvent("payment.authorized",
        tags: new ActivityTagsCollection { { "gateway", "stripe" } }));

    // Links — now serialized out-of-process in .NET 10
    // Use links to connect related traces (e.g., parent saga, triggering request)
    var linkedContext = new ActivityContext(
        ActivityTraceId.CreateRandom(), ActivitySpanId.CreateRandom(),
        ActivityTraceFlags.Recorded);
    activity.AddTag("linkedTrace", linkedContext.TraceId.ToHexString());
}
// Practical impact: distributed tracing tools (Jaeger, Zipkin, OpenTelemetry Collector)
// now receive the full event timeline, not just start/end times
```

### Rate-Limit Trace Sampling

.NET 10 adds a rate-limiting sampling option for out-of-process trace serialization via the `Microsoft-Diagnostics-DiagnosticSource` event source. This caps the number of root activities serialized per second, giving more predictable cost than ratio-based sampling.

```
// Configure in FilterAndPayloadSpecs (e.g., via EventSource listener or ETW configuration)
// Limit serialization to 100 root activities per second across all ActivitySources:
[AS]*/-ParentRateLimitingSampler(100)

// Scoped to a specific ActivitySource:
[AS]MyApp.Orders/-ParentRateLimitingSampler(50)
```

---

## .NET 10 Libraries — Globalization and Strings

### ISOWeek DateOnly Overloads

`System.Globalization.ISOWeek` now supports `DateOnly` in addition to `DateTime`. This eliminates the need to convert `DateOnly` to `DateTime` just to get the ISO week number.

```csharp
using System.Globalization;

DateOnly today = DateOnly.FromDateTime(DateTime.UtcNow);

// Before .NET 10: had to convert to DateTime
// int week = ISOWeek.GetWeekOfYear(today.ToDateTime(TimeOnly.MinValue));

// .NET 10: native DateOnly support
int week = ISOWeek.GetWeekOfYear(today);          // e.g., 20
int year = ISOWeek.GetYear(today);                 // ISO year (may differ from calendar year)
DateOnly monday = ISOWeek.ToDateOnly(year, week, DayOfWeek.Monday); // first day of that week
```

### StringNormalizationExtensions — Span-Based Unicode Normalization

`StringNormalizationExtensions` (.NET 10) adds span-based Unicode normalization APIs, eliminating the need to allocate a `string` when the source is a `ReadOnlySpan<char>` or `char[]`.

```csharp
using System.Text;

// Before .NET 10: must allocate a string to normalize
char[] inputChars = GetInputBuffer();
string normalized = new string(inputChars).Normalize(NormalizationForm.FormC);

// .NET 10: span-based APIs — no string allocation
ReadOnlySpan<char> input = inputChars;

// Check if already normalized
bool isNormal = input.IsNormalized(NormalizationForm.FormC);

// Get required output length before allocating
int requiredLength = input.GetNormalizedLength(NormalizationForm.FormC);
Span<char> output = requiredLength <= 256
    ? stackalloc char[requiredLength]
    : new char[requiredLength];

bool success = input.TryNormalize(output, out int charsWritten, NormalizationForm.FormC);
ReadOnlySpan<char> result = output[..charsWritten];
```

### UTF-8 Hex-String Conversion

`Convert` in .NET 10 adds UTF-8 overloads for hex-string operations, avoiding encoding conversions in byte-heavy pipelines.

```csharp
// Before .NET 10: convert UTF-8 bytes → chars → parse hex
byte[] utf8Hex = "DEADBEEF"u8.ToArray();
byte[] decoded = Convert.FromHexString(System.Text.Encoding.UTF8.GetString(utf8Hex));

// .NET 10: directly from UTF-8 span — no intermediate string
byte[] decoded2 = Convert.FromHexString(utf8Hex.AsSpan());

// TryToHexString — write hex as UTF-8 bytes without allocating a string
byte[] data = { 0xDE, 0xAD, 0xBE, 0xEF };
Span<byte> hexBuf = stackalloc byte[data.Length * 2];
bool ok = Convert.TryToHexString(data, hexBuf, out int written);
// hexBuf[..written] = "DEADBEEF" as UTF-8 bytes

// Lowercase variant for URL-safe / JSON-friendly output
Convert.TryToHexStringLower(data, hexBuf, out written);
// hexBuf[..written] = "deadbeef"
```

---

## .NET 10 Libraries — Collections and Serialization

### OrderedDictionary — TryAdd/TryGetValue with Index Output

`OrderedDictionary<TKey,TValue>` (.NET 9+) adds overloads that return the entry's zero-based index, enabling efficient update-or-insert (upsert) without two separate lookups.

```csharp
var counts = new System.Collections.Generic.OrderedDictionary<string, int>();

// Classic approach: two lookups
if (counts.TryGetValue("apple", out int existing))
    counts["apple"] = existing + 1;
else
    counts.Add("apple", 1);

// .NET 10 approach: single lookup, direct index-based update
void Upsert(OrderedDictionary<string, int> dict, string key)
{
    if (!dict.TryAdd(key, 1, out int index))
    {
        // Key already present; increment via index — O(1), no re-hash
        int current = dict.GetAt(index).Value;
        dict.SetAt(index, current + 1);
    }
}

// TryGetValue with index — retrieve value and its position simultaneously
if (counts.TryGetValue("apple", out int val, out int pos))
{
    Console.WriteLine($"apple = {val} at position {pos}");
    counts.SetAt(pos, val * 2);  // double it in-place
}
```

### Tensor<T> — Stable API (.NET 10)

`System.Numerics.Tensors.Tensor<T>` is stable in .NET 10 (no longer `[Experimental]`). The new `IReadOnlyTensor` non-generic interface enables working with tensors without knowing `T` at compile time. Slice operations now return views without copying data.

```csharp
using System.Numerics.Tensors;

// Create a 2D tensor (matrix)
Tensor<float> matrix = Tensor.Create<float>([3, 4]);

// Fill with values
for (int i = 0; i < 3; i++)
    for (int j = 0; j < 4; j++)
        matrix[[i, j]] = i * 4 + j;

// Slicing — returns a view, no copy (.NET 10)
ReadOnlyTensorSpan<float> row1 = matrix.AsReadOnlyTensorSpan([[1..2, 0..4]]);

// Arithmetic via C# 14 extension operators (when T supports IAdditionOperators<T,T,T>)
// tensor + tensor works for Tensor<int>, Tensor<float>, etc.
Tensor<float> a = Tensor.Create<float>([10], new float[] { 1f, 2f, 3f });
Tensor<float> b = Tensor.Create<float>([10], new float[] { 4f, 5f, 6f });
Tensor<float> sum = a + b;  // element-wise addition via extension operator

// Non-generic access via IReadOnlyTensor
IReadOnlyTensor untypedTensor = matrix;
System.Buffers.NIndex[] lengths = untypedTensor.Lengths;
```

---

## .NET 10 Libraries — Cryptography

### ExportPkcs12 with Algorithm Selection

`X509Certificate.ExportPkcs12` now accepts a `Pkcs12ExportPbeParameters` enum or `PbeParameters` for fine-grained control over the encryption algorithm used in PKCS#12/PFX export.

```csharp
using System.Security.Cryptography.X509Certificates;

X509Certificate2 cert = LoadCertificate();

// Legacy: TripleDES + SHA-1 — maximum compatibility (Windows XP-era format)
byte[] legacyPfx = cert.ExportPkcs12(
    Pkcs12ExportPbeParameters.Pkcs12TripleDesSha1,
    "password");

// Modern: AES-256 + SHA-256 — recommended for new deployments
byte[] modernPfx = cert.ExportPkcs12(
    Pkcs12ExportPbeParameters.Pbes2Aes256Sha256,
    "password");

// Custom: full control over algorithm and iteration count
var customParams = new PbeParameters(
    PbeEncryptionAlgorithm.Aes256Cbc,
    HashAlgorithmName.SHA256,
    iterationCount: 600_000);
byte[] customPfx = cert.ExportPkcs12(customParams, "password");

// Choose based on consumer:
// - Targeting cross-platform modern systems → Pbes2Aes256Sha256
// - Targeting legacy Windows or third-party systems → Pkcs12TripleDesSha1
// Default (no parameter) keeps the old behavior for backward compatibility
```

---

## Real-World Gotchas — .NET 10 JIT and Performance [community]

### **Closure Allocated on Heap Prevents Stack Allocation of Delegate — .NET 10 Scope** [community]

In .NET 10, when a lambda captures an outer variable, the `Func` object can be stack-allocated but the **closure class** (the object holding the captured variable) is still heap-allocated. WHY it causes problems: developers see the .NET 10 announcement about "delegate stack allocation" and assume zero heap allocation for short-lived lambdas with captured variables. In reality, only the `Func` wrapper is stack-allocated in .NET 10; the closure itself remains on the heap. Fix: avoid capturing variables in hot-path lambdas; use static lambdas instead, or pass state via parameters.

```csharp
int threshold = 10;
// 'threshold' is captured → closure object heap-allocated, Func wrapper stack-allocated (.NET 10)
var filter = (int x) => x > threshold;

// Better for hot paths: no capture — static lambda, pass threshold as parameter
static bool IsAboveThreshold(int x, int threshold) => x > threshold;

// Or with Func: avoid capture entirely
var filter2 = static (int x) => x > 10;  // no closure, no heap allocation
```

### **`static` Lambda Cannot Access `this` or Instance Members** [community]

Adding `static` to a lambda prevents accidental capture but also makes it a compile error to use `this`, instance fields, or instance methods. WHY it causes problems: when refactoring a non-static lambda to static in a class, any read of an instance member triggers CS8421. This is by design — but it surprises developers who expected to still read `readonly` fields. Fix: pass required instance data as a parameter, or use a local copy of the value before the lambda.

```csharp
public class Processor
{
    private readonly int _multiplier = 2;

    public IEnumerable<int> Scale(IEnumerable<int> values)
    {
        // This fails — static lambda cannot access 'this._multiplier'
        // return values.Select(static x => x * _multiplier);  // CS8421

        // Fix A: capture in a local (non-static)
        int m = _multiplier;
        return values.Select(x => x * m);

        // Fix B: restructure as a static method and call it
        // return values.Select(x => Scale(x, _multiplier));
    }
}
```

### **Lambda Attributes Are Invisible to the Runtime at Invocation** [community]

Attributes on lambda expressions (e.g., `[DisallowNull]`, `[RequiresUnreferencedCode]`) are discoverable via reflection on the synthesized delegate type, but the **delegate's `Invoke` method does not check attributes at call time**. WHY it causes problems: developers apply `[Obsolete]` or `[RequiresUnreferencedCode]` to lambdas expecting runtime enforcement (warning or exception). Neither fires at the call site. These attributes only affect static analysis tools (Roslyn analyzers, nullable flow analysis, trimming analysis). Fix: apply enforcement attributes on named methods; use lambdas for callbacks where the delegate is typed to a well-annotated named method.

---

## Anti-Patterns Quick Reference — .NET 10 JIT and Lambda Additions

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Expecting zero heap allocation for capturing lambdas in .NET 10 | Closure class is still heap-allocated; only the `Func` wrapper is stack-allocated | Use static lambdas or pass state as parameters to eliminate captures |
| Using `static` lambda when it needs instance members | CS8421 compile error — static lambdas cannot close over `this` | Capture the needed value in a local variable before the lambda, or use a named static method |
| Applying `[Obsolete]` or `[RequiresUnreferencedCode]` directly to a lambda | Attributes on lambdas are not enforced at the invocation call site | Apply enforcement attributes to named methods; use lambdas as typed callbacks |
| Passing coerced `IEnumerable<T>` arrays to devirtualizable paths expecting optimization | In .NET 10 array devirtualization is automatic, but explicit `IEnumerable<T>` variables still trigger the optimized path | No action needed — JIT handles it; just avoid storing arrays in `IEnumerable<T>` fields unnecessarily |
| Using PKCS#12 default export encryption in new deployments | Default uses TripleDES+SHA1 (weak legacy format) | Use `Pkcs12ExportPbeParameters.Pbes2Aes256Sha256` for modern deployments |

---

## Channel<T> — Advanced Patterns (Multi-Producer, Drop Modes, Callbacks)

### Multiple Producers and Consumers — Fan-Out / Fan-In

When `SingleWriter = true` or `SingleReader = true` is set, the channel's internal implementation elects a faster single-writer or single-reader path. Setting these to `false` explicitly enables the concurrent multi-producer / multi-consumer path. Call `writer.Complete()` only after **all** producers finish — a partial complete closes the channel prematurely.

```csharp
using System.Threading.Channels;

// GPS coordinates streaming from multiple sensors to multiple processors
public readonly record struct Coordinates(Guid DeviceId, double Lat, double Lon);

var channel = Channel.CreateUnbounded<Coordinates>(
    new UnboundedChannelOptions
    {
        SingleWriter = false,   // multiple sensors write concurrently
        SingleReader = false,   // multiple processors consume concurrently
        AllowSynchronousContinuations = false   // avoid stack overflows in tight loops
    });

// Fan-out: three concurrent producers, each representing a sensor
Task[] producers = Enumerable.Range(0, 3)
    .Select(id => Task.Run(async () =>
    {
        for (int i = 0; i < 100; i++)
        {
            await channel.Writer.WriteAsync(
                new Coordinates(Guid.NewGuid(), -90 + id * 30, -180 + id * 60));
        }
    }))
    .ToArray();

// Fan-in: two concurrent consumers drain the channel
Task[] consumers = Enumerable.Range(0, 2)
    .Select(_ => Task.Run(async () =>
    {
        await foreach (var coord in channel.Reader.ReadAllAsync())
            Console.WriteLine($"[{coord.DeviceId:N}] ({coord.Lat:F1}, {coord.Lon:F1})");
    }))
    .ToArray();

// CRITICAL: complete only after ALL producers finish
await Task.WhenAll(producers);
channel.Writer.Complete();

await Task.WhenAll(consumers);
```

### Bounded Channel Drop Modes and `itemDropped` Callback

When a bounded channel is full and the producer cannot wait (e.g., a sensor that must never block), use `DropOldest`, `DropNewest`, or `DropWrite` modes. Register an `itemDropped` callback to observe which items were silently discarded — important for metrics and debugging.

```csharp
using System.Threading.Channels;

int droppedCount = 0;

// Sliding window of the 1000 most recent readings — drop oldest when full
var channel = Channel.CreateBounded<Coordinates>(
    new BoundedChannelOptions(capacity: 1_000)
    {
        FullMode = BoundedChannelFullMode.DropOldest,   // drop oldest to make room
        SingleWriter = true,   // single high-frequency sensor
        SingleReader = false,
        AllowSynchronousContinuations = false
    },
    itemDropped: static (Coordinates dropped) =>
    {
        // invoked synchronously when an item is dropped
        Interlocked.Increment(ref droppedCount);
        // Log/metric: emit a counter but do not block
    });

// Writer: never blocks, always succeeds (DropOldest makes room)
while (sensorIsRunning)
{
    var coords = ReadSensor();
    channel.Writer.TryWrite(coords);  // TryWrite never blocks — FullMode handles the rest
}

// DropWrite: drop the incoming item instead (keep existing queue intact)
var telemetryChannel = Channel.CreateBounded<string>(
    new BoundedChannelOptions(256)
    {
        FullMode = BoundedChannelFullMode.DropWrite   // newest items dropped when full
    },
    itemDropped: item => Console.Error.WriteLine($"[DROPPED] {item}"));
```

**Drop mode selection guide:**

| Mode | When to use | Data loss |
|------|-------------|-----------|
| `Wait` (default) | Consumer keeps up; producer can block | None |
| `DropOldest` | Sliding-window; latest reading most important | Oldest items |
| `DropNewest` | Oldest data must be preserved (audit log) | Most recent items |
| `DropWrite` | Producer must never see data removed from queue | Incoming item |

---

## Sync-over-Async Bridge Pattern

### When You Must Call Async Code from a Sync Context

The correct approach is always "async all the way". When that is impossible (legacy codebase, static constructors, `IDisposable.Dispose()`, console `Main` before C# 7.1), use the following ranked options.

**Option 1 — `GetAwaiter().GetResult()` (preferred sync-block)**

Preserves the original exception (no `AggregateException` wrapping) and is marginally less allocating than `.Result`.

```csharp
// When you cannot use async — rare; document WHY
public static string LoadConfigSync(string path)
{
    // GetAwaiter().GetResult() rethrows the original exception,
    // unlike .Result which wraps in AggregateException
    return File.ReadAllTextAsync(path).GetAwaiter().GetResult();
}
```

**Option 2 — `Task.Run(...).GetAwaiter().GetResult()` for sync-context deadlock avoidance**

When the calling code has a `SynchronizationContext` (ASP.NET Classic, WinForms, WPF), direct `.GetAwaiter().GetResult()` can deadlock because the async continuation awaits the sync context that the blocking call holds. Offloading to `Task.Run` breaks the sync context chain:

```csharp
// Legacy ASP.NET Classic or WinForms: avoid deadlock by escaping sync context
string html = Task.Run(async () =>
    await httpClient.GetStringAsync("https://example.com")
).GetAwaiter().GetResult();
// Task.Run schedules on the ThreadPool (no SynchronizationContext), so the
// continuation can resume without needing to re-enter the blocked context.
```

**Option 3 — `.Result` / `.Wait()` (avoid)**

Wraps exceptions in `AggregateException`. Only use when you specifically need to inspect `AggregateException.InnerExceptions`.

```csharp
// Avoid — exception is wrapped in AggregateException
try { task.Wait(); }
catch (AggregateException ae) { ae.Handle(e => e is OperationCanceledException); }
```

**Community signal — deadlock triangle:** The deadlock occurs when three conditions are met simultaneously: (1) a `SynchronizationContext` exists (UI thread, classic ASP.NET request context), (2) `ConfigureAwait(false)` is NOT used on every await in the async chain, and (3) the calling thread blocks synchronously. Fixing any one of the three breaks the deadlock. In modern ASP.NET Core there is no `SynchronizationContext` by default, so `.GetAwaiter().GetResult()` is safe — but it remains a code smell that prevents horizontal scaling.

---

## Language Idioms — Async / LINQ Interaction

### `ToArray()` vs `ToList()` When Creating Tasks from LINQ

LINQ uses deferred (lazy) execution. A `Select(id => GetAsync(id))` expression does NOT fire the async calls until the sequence is enumerated. This means tasks do not start until `Task.WhenAll` iterates the `IEnumerable` — which defeats concurrency because the calls are dispatched sequentially. **Always materialize to an array or list immediately.**

```csharp
// BAD: deferred — GetUserAsync fires one at a time (sequential)
var tasks = userIds.Select(id => GetUserAsync(id));   // IEnumerable<Task<User>> — not started yet
var users = await Task.WhenAll(tasks);                // fires them one by one → no concurrency

// GOOD with ToArray: concurrent fan-out, fixed-size collection
var tasks = userIds.Select(id => GetUserAsync(id)).ToArray();  // all tasks START here
var users = await Task.WhenAll(tasks);                          // waits for all concurrently

// GOOD with ToList: concurrent fan-out when you need to mutate (e.g., WhenAny remove pattern)
var tasks = userIds.Select(id => GetUserAsync(id)).ToList();
while (tasks.Count > 0)
{
    var done = await Task.WhenAny(tasks);
    tasks.Remove(done);
    Console.WriteLine($"Processed user {(await done).Id}");
}
```

**Choice rule:**
- Use `ToArray()` for `Task.WhenAll` where count is fixed and you only read results.
- Use `ToList()` for `Task.WhenAny` drain loops where you need to remove completed tasks.
- Never pass a raw `IEnumerable<Task>` to `Task.WhenAll` / `Task.WhenAny` if the selector has side effects or starts I/O — it materializes lazily, defeating parallelism.

---

## Real-World Gotchas — Channel<T> and Async [community]

### **`SingleWriter = true` with Concurrent Writers Causes Corruption** [community]

`Channel.CreateUnbounded<T>()` defaults to `SingleWriter = true` for performance — it skips internal locking on the write path. WHY it causes problems: if you create the channel with this default and then call `WriteAsync` from multiple tasks concurrently, you get data corruption or dropped items because the single-writer fast path has no thread-safety guarantees. Fix: always set `SingleWriter = false` when multiple producers write to the same channel.

```csharp
// BAD: default SingleWriter=true but writing from multiple tasks
var channel = Channel.CreateUnbounded<int>();  // SingleWriter defaults to true!
await Task.WhenAll(
    Task.Run(async () => { for (int i = 0; i < 100; i++) await channel.Writer.WriteAsync(i); }),
    Task.Run(async () => { for (int i = 100; i < 200; i++) await channel.Writer.WriteAsync(i); })
);
// Items may be dropped or corrupted — the fast path assumes single-producer

// GOOD: explicitly mark multi-writer
var channel = Channel.CreateUnbounded<int>(
    new UnboundedChannelOptions { SingleWriter = false, SingleReader = false });
```

### **Not Completing the Channel Writer Stalls Consumers Forever** [community]

`ChannelReader<T>.ReadAllAsync()` and `await foreach` return only when the writer is marked complete. If a producer crashes without calling `writer.Complete()` (or `writer.TryComplete()`), all consumers hang indefinitely. WHY it causes problems: unhandled exceptions in producers silently strand consumers. Fix: always call `writer.TryComplete(exception)` in a `catch`/`finally` block; use `TryComplete` over `Complete` to avoid `ChannelClosedException` if already completed.

```csharp
static async Task ProduceAsync(ChannelWriter<int> writer, CancellationToken ct)
{
    try
    {
        for (int i = 0; i < 1_000; i++)
            await writer.WriteAsync(i, ct);

        writer.Complete();              // signal success
    }
    catch (Exception ex)
    {
        writer.TryComplete(ex);         // signal failure — consumers receive ChannelClosedException
    }
}
```

### **LINQ Deferred Execution Silently Prevents Concurrent Task Fan-Out** [community]

`IEnumerable<Task<T>>` from LINQ does not start the tasks. WHY it causes problems: developers write `Task.WhenAll(items.Select(x => FetchAsync(x)))` expecting parallel fan-out, but the tasks are dispatched sequentially by `WhenAll` as it enumerates the lazy sequence. Elapsed time is the sum, not the maximum. No compiler warning is emitted. Fix: materialize with `.ToArray()` immediately after the `Select`.

```csharp
// Total elapsed ≈ sum of all fetch times (serial execution, no parallelism)
var results = await Task.WhenAll(items.Select(x => FetchAsync(x)));  // BUG

// Total elapsed ≈ max of all fetch times (true parallel fan-out)
var results = await Task.WhenAll(items.Select(x => FetchAsync(x)).ToArray());
```

---

## Anti-Patterns Quick Reference — Channels and Async Interaction

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `Channel.CreateUnbounded<T>()` with multiple writers | Default `SingleWriter=true` skips locking — concurrent writes corrupt data | Set `SingleWriter = false` explicitly when multiple producers write |
| Producer exits without calling `writer.Complete()` | Consumers hang in `ReadAllAsync` forever | Always call `writer.TryComplete(ex)` in `finally` or `catch` |
| `BoundedChannelFullMode.DropOldest` without `itemDropped` callback | Silently discards data with no observability | Register `itemDropped:` callback for metrics/logging |
| `Task.WhenAll(items.Select(...))` without `.ToArray()` | LINQ deferred execution runs tasks serially | `.ToArray()` before `Task.WhenAll` to start all tasks concurrently |
| `.Result` or `.Wait()` on `Task` in sync-over-async bridge | Wraps exceptions in `AggregateException`; higher deadlock risk | Use `.GetAwaiter().GetResult()`; prefer `Task.Run(async () => ...).GetAwaiter().GetResult()` in sync-context environments |
| Blocking on async inside `SynchronizationContext` without `Task.Run` | Context deadlock: awaiter tries to marshal back to blocked thread | Escape context via `Task.Run(() => asyncMethod())` before blocking |

---

## HTTP Resilience — Polly v8 / `Microsoft.Extensions.Http.Resilience`

Transient failures (network blips, overloaded dependencies, DNS flaps) are unavoidable in distributed systems. The `Microsoft.Extensions.Http.Resilience` package (built on Polly v8) adds retry, circuit-breaker, timeout, rate-limiting, and hedging strategies directly to `IHttpClientBuilder`, composing them into a resilience pipeline that wraps every request through a typed/named `HttpClient`.

```
dotnet add package Microsoft.Extensions.Http.Resilience
```

### Standard Resilience Handler — One-Line Defense-in-Depth

`AddStandardResilienceHandler` applies five strategies in a sensible default order:

| Layer | Strategy | Default |
|---|---|---|
| 1 | Rate limiter | 1 000 permits, no queue |
| 2 | Total timeout | 30 s (including retries) |
| 3 | Retry | 3 retries, exponential back-off + jitter, 2 s base delay |
| 4 | Circuit breaker | 10 % failure rate over 30 s, 100 req min throughput, 5 s break |
| 5 | Attempt timeout | 10 s per attempt |

```csharp
// Program.cs — add the standard resilience pipeline to a typed client
builder.Services
    .AddHttpClient<CatalogClient>(c =>
        c.BaseAddress = new Uri("https://catalog.example.com"))
    .AddStandardResilienceHandler();

// CatalogClient.cs
public class CatalogClient(HttpClient client)
{
    public IAsyncEnumerable<Product?> GetProductsAsync(CancellationToken ct = default)
        => client.GetFromJsonAsAsyncEnumerable<Product>("/products", ct);
}

// Disable retries for non-idempotent methods (POST, PUT, DELETE, PATCH, CONNECT)
// to avoid duplicate inserts or unintended side effects
builder.Services
    .AddHttpClient<OrderClient>(c => c.BaseAddress = new Uri("https://orders.example.com"))
    .AddStandardResilienceHandler(options =>
    {
        options.Retry.DisableForUnsafeHttpMethods();
        // Or selectively: options.Retry.DisableFor(HttpMethod.Post, HttpMethod.Delete);
    });
```

**Important:** only call `AddStandardResilienceHandler` **once** per client. Stacking multiple handlers multiplies retry counts — if you need to customise, use `AddResilienceHandler` instead.

### Custom Resilience Pipeline — `AddResilienceHandler`

For fine-grained control, compose strategies explicitly. Strategies execute from the outermost (first registered) to the innermost (closest to the network call).

```csharp
builder.Services
    .AddHttpClient<PaymentClient>(c =>
        c.BaseAddress = new Uri("https://payments.example.com"))
    .AddResilienceHandler("PaymentPipeline", pipeline =>
    {
        // 1. Retry — exponential back-off, up to 4 attempts, jitter prevents thundering herd
        pipeline.AddRetry(new HttpRetryStrategyOptions
        {
            MaxRetryAttempts = 4,
            BackoffType       = DelayBackoffType.Exponential,
            UseJitter         = true,
            Delay             = TimeSpan.FromSeconds(1)
        });

        // 2. Circuit breaker — trips after 20% failure rate over 10-second window
        pipeline.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
        {
            SamplingDuration   = TimeSpan.FromSeconds(10),
            FailureRatio       = 0.2,
            MinimumThroughput  = 5,
            BreakDuration      = TimeSpan.FromSeconds(15),
            // Only count 5xx and 408/429 as failures; don't trip on 4xx domain errors
            ShouldHandle = args => ValueTask.FromResult(
                args.Outcome.Result?.StatusCode is
                    >= HttpStatusCode.InternalServerError or
                    HttpStatusCode.RequestTimeout or
                    HttpStatusCode.TooManyRequests)
        });

        // 3. Per-attempt timeout — gives each try a hard deadline
        pipeline.AddTimeout(TimeSpan.FromSeconds(8));
    });
```

**Ordering matters:** timeout → circuit-breaker → retry is the canonical inside-out order. Placing retry outside timeout means timeouts count as retriable failures. Placing circuit-breaker outside retry means the breaker trips after the full retry sequence exhausts itself, not after individual fast-failing attempts.

### Hedging — Parallel Speculative Retries

Hedging fires a duplicate request after a configurable delay if the first request hasn't returned. Use it when latency matters more than extra load on the dependency.

```csharp
// Use standard hedging handler — fires a second attempt if the first hasn't responded
// within the hedge delay (default 2 s), keeping a per-endpoint circuit-breaker pool
builder.Services
    .AddHttpClient<SearchClient>(c =>
        c.BaseAddress = new Uri("https://search.example.com"))
    .AddStandardHedgingHandler();

// For A/B testing: route weighted traffic across two endpoints
builder.Services
    .AddHttpClient<FeatureClient>(c =>
        c.BaseAddress = new Uri("https://stable.example.com"))
    .AddStandardHedgingHandler(routing =>
    {
        routing.ConfigureWeightedGroups(opts =>
        {
            opts.Groups.Add(new WeightedUriEndpointGroup
            {
                Endpoints =
                {
                    new() { Uri = new("https://stable.example.com"),      Weight = 90 },
                    new() { Uri = new("https://experimental.example.com"), Weight = 10 }
                }
            });
        });
    });
```

### Dynamic Retry Options via `IOptionsMonitor`

Resilience options can be reloaded at runtime without restarting the app. Bind the options to a configuration section and call `EnableReloads` inside `AddResilienceHandler`.

```csharp
// appsettings.json:
// "RetryOptions": { "Retry": { "MaxRetryAttempts": 5, "BackoffType": "Linear" } }

builder.Services
    .Configure<HttpStandardResilienceOptions>(
        builder.Configuration.GetSection("RetryOptions"));

builder.Services
    .AddHttpClient<CatalogClient>(c =>
        c.BaseAddress = new Uri("https://catalog.example.com"))
    .AddResilienceHandler("DynamicPipeline",
        (pipeline, ctx) =>
        {
            // Enable live-reload: when IOptionsMonitor detects a change, the pipeline rebuilds
            ctx.EnableReloads<HttpStandardResilienceOptions>("RetryOptions");

            var opts = ctx.GetOptions<HttpStandardResilienceOptions>("RetryOptions");
            pipeline.AddRetry(opts.Retry);
        });
```

**Why it matters:** in Kubernetes deployments, you can tune retry counts and back-off via ConfigMap hot-reload without a pod restart. Combine with `IOptionsMonitor<T>` for other configuration sections too.

---

## Real-World Gotchas — Resilience [community]

### **`TimeoutRejectedException` Is Not `TimeoutException`** [community]

When using Polly's timeout strategy (directly or via `AddStandardResilienceHandler`), a timed-out attempt throws `Polly.Timeout.TimeoutRejectedException`, which inherits from `Exception` — **not** from `System.TimeoutException`. WHY it causes problems: a `catch (TimeoutException)` block will silently miss Polly timeouts, and retry `ShouldHandle` predicates that filter on `TimeoutException` will not recognize Polly-generated timeouts. Fix: catch or filter on `TimeoutRejectedException` from the `Polly` namespace, or combine both in a union catch.

```csharp
using Polly.Timeout;

// BAD: silently misses Polly timeout — TimeoutRejectedException is NOT TimeoutException
try
{
    var result = await _client.GetStringAsync("/resource", ct);
}
catch (TimeoutException ex) // WON'T catch Polly timeout!
{
    _logger.LogWarning("Timed out: {Msg}", ex.Message);
}

// GOOD: catch Polly's timeout exception explicitly
try
{
    var result = await _client.GetStringAsync("/resource", ct);
}
catch (TimeoutRejectedException ex)
{
    _logger.LogWarning("Polly timeout: {Msg}", ex.Message);
}

// In ShouldHandle delegate: handle TimeoutRejectedException explicitly
pipeline.AddRetry(new HttpRetryStrategyOptions
{
    ShouldHandle = args => ValueTask.FromResult(
        args.Outcome.Exception is TimeoutRejectedException or HttpRequestException)
});
```

### **Retrying Non-Idempotent HTTP Methods — Duplicate Inserts** [community]

`AddStandardResilienceHandler` retries **all** HTTP methods by default, including `POST`. WHY it causes problems: a `POST /orders` that creates a record in the database may succeed on the server, but the network drops the response before the client receives it. The retry fires a second `POST`, creating a duplicate order. Fix: always call `options.Retry.DisableForUnsafeHttpMethods()` for any client that calls state-mutating endpoints, or design APIs to be idempotent with client-generated idempotency keys.

```csharp
// BAD: retries POST — may create duplicate orders if response is lost
services.AddHttpClient<OrderClient>()
    .AddStandardResilienceHandler();

// GOOD: disable retries for POST/PUT/DELETE/PATCH
services.AddHttpClient<OrderClient>()
    .AddStandardResilienceHandler(opts =>
        opts.Retry.DisableForUnsafeHttpMethods());

// BEST for state-mutating APIs: send idempotency key in request header
// so the server can detect and deduplicate replayed requests
public async Task<Order?> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct)
{
    var idempotencyKey = Guid.NewGuid().ToString();
    using var message = new HttpRequestMessage(HttpMethod.Post, "/orders");
    message.Headers.Add("Idempotency-Key", idempotencyKey);
    message.Content = JsonContent.Create(request);
    var response = await _client.SendAsync(message, ct);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadFromJsonAsync<Order>(ct);
}
```

### **Stacking Multiple Resilience Handlers — Multiplicative Retries** [community]

Calling `AddStandardResilienceHandler` twice, or calling it alongside `AddResilienceHandler`, compounds the pipelines. WHY it causes problems: two retry layers with 3 retries each yield up to 9 attempts (3 × 3), multiplying load on an already-stressed dependency. The outer layer sees the inner layer's retries as a single slow response, potentially tripping the circuit breaker prematurely. Fix: call `RemoveAllResilienceHandlers()` before `AddResilienceHandler` when you need to override a default registered via `ConfigureHttpClientDefaults`.

```csharp
// BAD: global default + per-client handler — retries compound
services.ConfigureHttpClientDefaults(b => b.AddStandardResilienceHandler());
services.AddHttpClient<SpecialClient>()
    .AddResilienceHandler("Extra", p => p.AddRetry(...));  // now 3*N retries!

// GOOD: clear the inherited handler before adding custom one
services.AddHttpClient<SpecialClient>()
    .RemoveAllResilienceHandlers()
    .AddResilienceHandler("Custom", p =>
    {
        p.AddRetry(new HttpRetryStrategyOptions { MaxRetryAttempts = 2 });
        p.AddTimeout(TimeSpan.FromSeconds(5));
    });
```

### **Registering Resilience Before Application Insights — Missing Telemetry** [community]

When using .NET Application Insights ≤ 2.22.0 alongside `Microsoft.Extensions.Http.Resilience`, registering resilience services **before** `AddApplicationInsightsTelemetry` causes all Application Insights telemetry to be dropped. WHY it causes problems: resilience registration mutates the `IHttpClientFactory` pipeline in a way that conflicts with Application Insights' internal HTTP interception hooks when AI services haven't been set up yet. Fix: always call `AddApplicationInsightsTelemetry` first, or upgrade to Application Insights ≥ 2.23.0 which resolves the ordering dependency.

```csharp
// BAD: resilience registered first — all AI telemetry missing
services.AddHttpClient().AddStandardResilienceHandler();
services.AddApplicationInsightsTelemetry();  // No telemetry captured!

// GOOD: register Application Insights before resilience
services.AddApplicationInsightsTelemetry();
services.AddHttpClient().AddStandardResilienceHandler();
```

---

## Anti-Patterns Quick Reference — Resilience

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `AddStandardResilienceHandler` applied twice (or + `AddResilienceHandler`) | Multiplicative retries — 3×3 = 9 attempts; circuit-breaker trips on aggregated latency | Call `RemoveAllResilienceHandlers()` before `AddResilienceHandler` for custom pipelines |
| Retrying `POST`/`DELETE` with default standard resilience handler | Non-idempotent methods re-execute, causing duplicate inserts/deletes | Call `options.Retry.DisableForUnsafeHttpMethods()` or design APIs with idempotency keys |
| Catching `TimeoutException` instead of `TimeoutRejectedException` in Polly pipelines | Polly timeouts silently not handled; incorrect fallback behavior | Catch `Polly.Timeout.TimeoutRejectedException`; also handle in `ShouldHandle` delegates |
| Registering `AddStandardResilienceHandler` before `AddApplicationInsightsTelemetry` (AI ≤ 2.22.0) | All Application Insights telemetry is lost silently | Register AI services first, or upgrade to Application Insights ≥ 2.23.0 |
| No `ShouldHandle` filter on circuit breaker — trips on 4xx client errors | 404/401 responses counted as failures; breaker opens for valid domain errors | Filter `ShouldHandle` to 5xx, 408, 429 only; domain errors shouldn't trip the breaker |
| No jitter on retry back-off — all clients retry simultaneously | Thundering herd: overloaded service slammed by synchronized retries after failure | Always set `UseJitter = true` on exponential back-off strategies |

---

## Testing Patterns — Moq, FluentAssertions, xUnit v3, NUnit, MSTest

### Moq — Mocking Dependencies

Moq is the most widely used .NET mocking library. It creates fake implementations of interfaces and virtual members using expression-based setup and verification. Always prefer constructor injection so mocks can be passed in; avoid mocking concrete non-virtual types (which Moq cannot intercept).

```csharp
// Install: dotnet add package Moq
using Moq;
using Xunit;

public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _repoMock = new(MockBehavior.Strict);
    private readonly Mock<IEventBus> _busMock = new(MockBehavior.Loose);

    [Fact]
    public async Task CreateOrderAsync_ValidRequest_PublishesEvent()
    {
        // Arrange: set up expected calls
        var request = new CreateOrderRequest(CustomerId: 1, Items: [new("SKU-1", 2)]);
        var created  = new Order(Id: 42, CustomerId: 1, Status: "Pending");

        _repoMock
            .Setup(r => r.SaveAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(created);

        _busMock
            .Setup(b => b.PublishAsync(It.IsAny<OrderCreatedEvent>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var sut = new OrderService(_repoMock.Object, _busMock.Object);

        // Act
        var result = await sut.CreateOrderAsync(request, CancellationToken.None);

        // Assert
        Assert.Equal(42, result.Id);

        // Verify the event was published exactly once with the correct order ID
        _busMock.Verify(
            b => b.PublishAsync(
                It.Is<OrderCreatedEvent>(e => e.OrderId == 42),
                It.IsAny<CancellationToken>()),
            Times.Once);

        _repoMock.VerifyAll();  // verifies ALL Strict setups were called
    }
}
```

**`MockBehavior.Strict` vs `MockBehavior.Loose`:**
- `Strict` — any call not explicitly set up throws `MockException`. Use for critical dependencies where unexpected calls are bugs.
- `Loose` (default) — non-set-up methods return `default`/empty values. Use for ancillary dependencies (loggers, event buses).

```csharp
// MockBehavior.Strict example — accidental call detection
var repoMock = new Mock<IOrderRepository>(MockBehavior.Strict);
repoMock.Setup(r => r.GetAsync(1, default)).ReturnsAsync(new Order(1));
// Any other call on repoMock throws MockException immediately
```

**Argument matchers — `It.*`:**

```csharp
// It.IsAny<T>() — any value including null
_mock.Setup(s => s.Find(It.IsAny<string>())).Returns(null);

// It.Is<T>(predicate) — custom condition
_mock.Setup(s => s.Save(It.Is<Order>(o => o.Total > 0))).ReturnsAsync(true);

// It.IsIn / It.IsNotIn — membership check
_mock.Setup(s => s.GetRegion(It.IsIn("US", "CA", "GB"))).Returns("North America");

// It.IsRegex — string regex match
_mock.Setup(s => s.Lookup(It.IsRegex(@"^\d{5}$"))).Returns(new ZipInfo());

// Capture argument for custom assertions
Order? capturedOrder = null;
_repoMock
    .Setup(r => r.SaveAsync(It.IsAny<Order>(), default))
    .Callback<Order, CancellationToken>((o, _) => capturedOrder = o)
    .ReturnsAsync(new Order(1));
// After act: Assert.Equal("Pending", capturedOrder!.Status);
```

**Setting up sequences and exceptions:**

```csharp
// Return different values on successive calls
var seq = _mock.SetupSequence(s => s.GetNextIdAsync())
    .ReturnsAsync(1)
    .ReturnsAsync(2)
    .ThrowsAsync(new InvalidOperationException("No more IDs"));

// Throw on first call, succeed on retry
_mock.SetupSequence(s => s.ConnectAsync(It.IsAny<CancellationToken>()))
    .ThrowsAsync(new IOException("connection refused"))
    .Returns(Task.CompletedTask);  // second call succeeds
```

**Verifying call counts:**

```csharp
_mock.Verify(s => s.LogWarning(It.IsAny<string>()), Times.Never);
_mock.Verify(s => s.Save(It.IsAny<Order>()), Times.Exactly(2));
_mock.Verify(s => s.SendEmail(It.IsAny<string>()), Times.AtLeastOnce);
_mock.Verify(s => s.Flush(), Times.Between(1, 3, Range.Inclusive));
```

**Moq v4.20+ — async Task/ValueTask setups:**

```csharp
// ValueTask return — use ReturnsAsync directly
_mock.Setup(s => s.GetCountAsync()).ReturnsAsync(42);

// Void async — Returns(Task.CompletedTask)
_mock.Setup(s => s.FlushAsync(It.IsAny<CancellationToken>()))
     .Returns(Task.CompletedTask);

// ThrowsAsync for faulted tasks
_mock.Setup(s => s.CommitAsync(default))
     .ThrowsAsync(new DbException("Deadlock detected"));
```

### NSubstitute — Fluent Mocking Alternative

NSubstitute is a popular alternative to Moq with a cleaner fluent API. Rather than `mock.Setup(x => x.Method()).Returns(y)`, NSubstitute uses `sub.Method().Returns(y)` — the mock itself is the configuration target.

```csharp
// Install: dotnet add package NSubstitute
using NSubstitute;
using Xunit;

public class InvoiceServiceTests
{
    private readonly IInvoiceRepository _repo = Substitute.For<IInvoiceRepository>();
    private readonly IEmailSender _email    = Substitute.For<IEmailSender>();

    [Fact]
    public async Task SendInvoice_ExistingCustomer_SendsEmail()
    {
        // Arrange: return values by calling the substitute directly
        _repo.GetAsync(Arg.Any<int>(), Arg.Any<CancellationToken>())
             .Returns(new Invoice(Id: 7, CustomerId: 3, Total: 99.99m));

        var sut = new InvoiceService(_repo, _email);

        // Act
        await sut.SendAsync(7, CancellationToken.None);

        // Assert: verify call was received
        await _email.Received(1).SendAsync(
            Arg.Is<string>(s => s.Contains("Invoice #7")),
            Arg.Any<CancellationToken>());

        // Assert: call was NOT made
        await _repo.DidNotReceive().DeleteAsync(Arg.Any<int>(), Arg.Any<CancellationToken>());
    }
}
```

**NSubstitute argument matchers:**

```csharp
// Arg.Any<T>() — any value
// Arg.Is<T>(predicate) — custom condition
// Arg.Do<T>(action) — capture argument as side effect
// Arg.Invoke(args) — invoke a callback argument

string? capturedSubject = null;
_email.SendAsync(Arg.Do<string>(s => capturedSubject = s), default)
      .Returns(Task.CompletedTask);

// After Act: Assert.Equal("Your invoice #7", capturedSubject);
```

**When to choose NSubstitute over Moq:** NSubstitute has no `Setup()` ceremony and reads closer to production code. It is preferred by teams that find Moq's lambda setup verbose. It does not support `MockBehavior.Strict`, so unexpected calls return defaults rather than throwing — use `Received()` assertions for verification rigor.

### FluentAssertions — Expressive Test Assertions

FluentAssertions replaces framework-native `Assert.*` calls with a fluent, English-readable API that produces more informative failure messages. Add `using FluentAssertions;` and chain `.Should()` on any value.

```csharp
// Install: dotnet add package FluentAssertions
using FluentAssertions;

// Scalar values
result.Should().Be(42);
price.Should().BeGreaterThan(0m).And.BeLessThan(1000m);
name.Should().StartWith("Mr.").And.EndWith("Smith");
flag.Should().BeTrue();
value.Should().BeNull();
value.Should().NotBeNull();

// Strings
text.Should().Contain("error").And.NotBeNullOrWhiteSpace();
text.Should().MatchRegex(@"^\d{4}-\d{2}-\d{2}$");

// Collections
list.Should().HaveCount(3);
list.Should().Contain(x => x.Id == 42);
list.Should().BeInAscendingOrder(x => x.Name);
list.Should().AllSatisfy(x => x.IsActive.Should().BeTrue());
list.Should().NotContainNulls();

// Object equivalency — deep structural comparison
result.Should().BeEquivalentTo(expected, options =>
    options.Excluding(o => o.CreatedAt)  // exclude volatile properties
           .ComparingByMembers<OrderItem>());  // force member comparison for structs

// Exception assertions
act.Should().Throw<ArgumentException>()
   .WithMessage("*cannot be empty*")
   .WithParameterName("customerId");

await asyncAct.Should().ThrowAsync<HttpRequestException>()
              .WithMessage("*404*");

// No exception
act.Should().NotThrow();
```

**`BeEquivalentTo` — the most powerful assertion:**

```csharp
// Compares all public members by value (not reference) recursively
var expected = new OrderDto(Id: 1, Status: "Shipped", Total: 99.99m);
actual.Should().BeEquivalentTo(expected,
    opts => opts
        .ExcludingMissingMembers()           // ignore extra members on actual
        .Using<decimal>(ctx =>
            ctx.Subject.Should().BeApproximately(ctx.Expectation, 0.01m))
        .WhenTypeIs<decimal>());             // custom comparison for decimals

// Collections of objects — element order ignored by default
actualList.Should().BeEquivalentTo(expectedList);

// Enforce order
actualList.Should().BeEquivalentTo(expectedList,
    opts => opts.WithStrictOrdering());
```

**FluentAssertions 7.x changes (2025):** Version 7 introduced a commercial license for business use (non-FOSS projects). The package is still free for open-source. Community alternatives: `Shouldly` and `TUnit`'s built-in assertions. If you cannot use FA v7+ commercially, pin to v6.x or switch to Shouldly.

### xUnit v3 — Key Differences from v2

xUnit v3 (GA 2024) adds async-first test infrastructure, removes VSTest host support (runs on Microsoft Testing Platform only), and adds `[Theory]` improvements.

```csharp
// Install: dotnet add package xunit xunit.v3.runner.visualstudio (v3 packages)
// xUnit v3 test method — same [Fact]/[Theory] attributes, new async capabilities
using Xunit;

public class CartTests
{
    // v3: constructor and IAsyncLifetime both supported for async setup/teardown
    [Fact]
    public async Task AddItem_UpdatesTotal()
    {
        var cart = await CartBuilder.CreateAsync();
        await cart.AddItemAsync(new CartItem("SKU-1", 2, 9.99m));
        cart.Total.Should().Be(19.98m);
    }

    // v3: TheoryData<T> type for strongly-typed parameterized tests
    public static TheoryData<decimal, decimal, decimal> PricingData => new()
    {
        { 10m, 0.1m, 9m },   // price, discount, expected
        { 20m, 0.5m, 10m },
        { 0m,  1.0m, 0m }
    };

    [Theory]
    [MemberData(nameof(PricingData))]
    public void ApplyDiscount_ReturnsExpected(decimal price, decimal discount, decimal expected)
    {
        var result = PricingEngine.Apply(price, discount);
        result.Should().Be(expected);
    }
}

// v3: IAsyncLifetime for async setup and teardown
public class DatabaseFixture : IAsyncLifetime
{
    public required TestDbContext Db { get; private set; }

    public async Task InitializeAsync()
    {
        Db = await TestDbContext.CreateInMemoryAsync();
        await Db.SeedTestDataAsync();
    }

    public async Task DisposeAsync()
    {
        await Db.DisposeAsync();
    }
}

// Use as a class fixture for shared state across tests in one class
public class OrderQueryTests(DatabaseFixture db) : IClassFixture<DatabaseFixture>
{
    [Fact]
    public async Task GetOrders_ReturnsAll()
    {
        var orders = await db.Db.Orders.ToListAsync();
        orders.Should().NotBeEmpty();
    }
}
```

**xUnit v3 fixture scoping:**

| Scope | Interface | Use case |
|---|---|---|
| Per-test | Constructor injection | Stateless dependencies |
| Per-class | `IClassFixture<TFixture>` | Shared expensive setup (e.g., DB, test server) |
| Per-collection | `ICollectionFixture<TFixture>` + `[Collection]` | Cross-class shared fixture (e.g., single integration test server) |
| Per-assembly | `IAssemblyFixture<TFixture>` (v3 only) | Single instance for all tests in assembly |

### NUnit — Data-Driven Tests and Parameterized Suites

NUnit excels at data-driven tests via `[TestCase]`, `[TestCaseSource]`, and `[Values]`.

```csharp
// Install: dotnet add package NUnit NUnit3TestAdapter
using NUnit.Framework;

[TestFixture]
public class PriceCalculatorTests
{
    private PriceCalculator _calc = null!;

    [SetUp]
    public void SetUp() => _calc = new PriceCalculator();

    [TearDown]
    public void TearDown() { /* cleanup */ }

    // Inline data — parameters in attribute
    [TestCase(10.0, 0.2, 8.0)]
    [TestCase(100.0, 0.5, 50.0)]
    [TestCase(0.0, 0.1, 0.0)]
    public void ApplyDiscount_ReturnsCorrectPrice(
        double price, double discount, double expected)
    {
        _calc.ApplyDiscount(price, discount).Should().BeApproximately(expected, 0.001);
    }

    // External data source — test cases from a method or field
    public static IEnumerable<TestCaseData> EdgeCases()
    {
        yield return new TestCaseData(double.MaxValue, 0.0, double.MaxValue)
            .SetName("MaxValue with no discount");
        yield return new TestCaseData(-1.0, 0.5, 0.0)
            .SetName("Negative price defaults to zero");
    }

    [TestCaseSource(nameof(EdgeCases))]
    public void ApplyDiscount_EdgeCases(double price, double discount, double expected)
        => _calc.ApplyDiscount(price, discount).Should().Be(expected);

    // [Values] — combinatorial testing (all combinations)
    [Test]
    public void IsValidPrice_Combinatorial(
        [Values(0.0, 1.0, -1.0)] double price,
        [Values(true, false)] bool allowNegative)
    {
        bool result = _calc.IsValidPrice(price, allowNegative);
        if (allowNegative || price >= 0) result.Should().BeTrue();
        else result.Should().BeFalse();
    }
}
```

**NUnit async test support:**

```csharp
[Test]
public async Task FetchOrder_ReturnsOrder()
{
    var order = await _service.GetByIdAsync(1, CancellationToken.None);
    order.Should().NotBeNull();
    order!.Id.Should().Be(1);
}

// Assert.ThrowsAsync — NUnit built-in for async exception testing
[Test]
public void GetOrder_NotFound_ThrowsAsync()
{
    Assert.ThrowsAsync<NotFoundException>(
        () => _service.GetByIdAsync(999, CancellationToken.None));
}
```

### MSTest v3 — Modern Setup and Data Rows

MSTest V3 (2024+) adds `[TestInitialize]`/`[TestCleanup]` async support, `[DataRow]` improvements, and parallelism via `[Parallelize]`.

```csharp
// Install: dotnet add package MSTest.TestFramework MSTest.TestAdapter
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
[Parallelize(Workers = 4, Scope = ExecutionScope.MethodLevel)]
public class ProductServiceTests
{
    private Mock<IProductRepository> _repoMock = null!;
    private ProductService _sut = null!;

    [TestInitialize]
    public async Task InitAsync()
    {
        _repoMock = new Mock<IProductRepository>();
        _sut = new ProductService(_repoMock.Object);
        await _sut.WarmUpAsync();
    }

    [TestCleanup]
    public async Task CleanupAsync() => await _sut.DisposeAsync();

    // DataRow with named parameters
    [DataTestMethod]
    [DataRow("Electronics", 5, DisplayName = "Electronics category with 5 items")]
    [DataRow("Books", 0,     DisplayName = "Books category with no items")]
    public async Task GetProducts_ReturnsFilteredList(string category, int expectedCount)
    {
        _repoMock.Setup(r => r.GetByCategoryAsync(category, default))
                 .ReturnsAsync(Enumerable.Range(0, expectedCount)
                     .Select(i => new Product(i, category))
                     .ToList());

        var result = await _sut.GetProductsAsync(category, CancellationToken.None);
        Assert.AreEqual(expectedCount, result.Count);
    }
}
```

### Integration Testing — `CustomWebApplicationFactory` with Test Services

Replace real services with test doubles in `WebApplicationFactory` for full-stack integration tests without a real database or external APIs.

```csharp
// Custom factory — substitutes real services with test doubles
public class TestWebApplicationFactory<TProgram> : WebApplicationFactory<TProgram>
    where TProgram : class
{
    // Expose mocks so test classes can configure them per-test
    public Mock<IPaymentGateway> PaymentGatewayMock { get; } = new(MockBehavior.Strict);
    public Mock<IEmailSender>    EmailSenderMock     { get; } = new(MockBehavior.Loose);

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(services =>
        {
            // Remove the real payment gateway
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(IPaymentGateway));
            if (descriptor is not null) services.Remove(descriptor);

            // Register the mock
            services.AddSingleton(PaymentGatewayMock.Object);
            services.AddSingleton(EmailSenderMock.Object);

            // Use in-memory database instead of real SQL
            services.AddDbContext<AppDbContext>(opts =>
                opts.UseInMemoryDatabase("TestDb_" + Guid.NewGuid()));
        });
    }
}

// Test class using the custom factory
public class CheckoutApiTests : IClassFixture<TestWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory<Program> _factory;

    public CheckoutApiTests(TestWebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client  = factory.CreateClient();
    }

    [Fact]
    public async Task PostCheckout_ChargesPayment_SendsConfirmation()
    {
        // Configure mocks for this specific test
        _factory.PaymentGatewayMock
            .Setup(g => g.ChargeAsync(It.IsAny<PaymentRequest>(), default))
            .ReturnsAsync(new PaymentResult(Success: true, TransactionId: "TXN-001"));

        _factory.EmailSenderMock
            .Setup(e => e.SendAsync(It.IsAny<string>(), It.IsAny<string>(), default))
            .Returns(Task.CompletedTask);

        // Act
        var response = await _client.PostAsJsonAsync("/api/checkout",
            new CheckoutRequest(CartId: Guid.NewGuid(), PaymentMethod: "card"));

        // Assert HTTP level
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Assert service interactions
        _factory.EmailSenderMock.Verify(
            e => e.SendAsync(It.Is<string>(s => s.Contains("confirmation")),
                             It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
```

### Test Data Builders — Bogus and AutoFixture

**Bogus** generates realistic fake data. **AutoFixture** auto-fills properties for SUT setup, reducing boilerplate. Use them to avoid brittle test data literals.

```csharp
// Install: dotnet add package Bogus
using Bogus;

public static class Fakers
{
    private static readonly Faker<Order> _orderFaker = new Faker<Order>()
        .RuleFor(o => o.Id,           f => f.Random.Int(1, 10_000))
        .RuleFor(o => o.CustomerId,   f => f.Random.Int(1, 500))
        .RuleFor(o => o.Status,       f => f.PickRandom("Pending", "Shipped", "Delivered"))
        .RuleFor(o => o.Total,        f => Math.Round(f.Random.Decimal(1, 500), 2))
        .RuleFor(o => o.CreatedAt,    f => f.Date.RecentOffset(days: 30));

    // Deterministic seed — reproducible in CI
    public static Order Order(int? seed = null)
    {
        if (seed.HasValue) _orderFaker.UseSeed(seed.Value);
        return _orderFaker.Generate();
    }

    public static IReadOnlyList<Order> Orders(int count, int? seed = null)
    {
        if (seed.HasValue) _orderFaker.UseSeed(seed.Value);
        return _orderFaker.Generate(count);
    }
}

// Usage in tests — no magic literals scattered across test files
var order    = Fakers.Order(seed: 42);    // deterministic for regression tests
var orders   = Fakers.Orders(10);        // varied data for collection tests
```

```csharp
// Install: dotnet add package AutoFixture AutoFixture.Xunit2
using AutoFixture;
using AutoFixture.Xunit2;

public class InventoryServiceTests
{
    // [AutoData] — fixture auto-fills all parameters
    [Theory, AutoData]
    public void Reserve_EnoughStock_ReturnsTrue(
        InventoryService sut,      // auto-created with auto-created constructor args
        string sku,                // random string
        int quantity)              // random int
    {
        // Customize: override generated value
        var fixture = new Fixture();
        fixture.Customize<InventoryService>(c =>
            c.FromFactory(() => new InventoryService(
                fixture.Freeze<Mock<IInventoryRepository>>().Object)));

        var result = sut.Reserve(sku, Math.Abs(quantity) + 1);
        result.Should().BeOfType<ReservationResult>();
    }
}
```

### Test Isolation — Respawn for Database Reset

**Respawn** resets a real database to a clean state between tests faster than drop-and-recreate, by generating `DELETE` statements in dependency order.

```csharp
// Install: dotnet add package Respawn
using Respawn;
using System.Data.SqlClient;

public class OrderRepositoryIntegrationTests : IAsyncLifetime
{
    private readonly string _connectionString = TestConfig.ConnectionString;
    private Respawner _respawner = null!;

    public async Task InitializeAsync()
    {
        // Configure Respawn once per fixture
        _respawner = await Respawner.CreateAsync(_connectionString, new RespawnerOptions
        {
            TablesToIgnore = [new Table("migrations"), new Table("seed_data")],
            DbAdapter = DbAdapter.SqlServer
        });
    }

    public async Task DisposeAsync()
    {
        // Reset DB after every test — runs DELETE statements, not DROP/CREATE
        await _respawner.ResetAsync(_connectionString);
    }

    [Fact]
    public async Task SaveAsync_NewOrder_PersistedToDatabase()
    {
        await using var conn = new SqlConnection(_connectionString);
        var repo  = new OrderRepository(conn);
        var order = Fakers.Order(seed: 1);

        await repo.SaveAsync(order, CancellationToken.None);

        var loaded = await repo.GetByIdAsync(order.Id, CancellationToken.None);
        loaded.Should().BeEquivalentTo(order, opts => opts.Excluding(o => o.CreatedAt));
    }
}
```

### Snapshot Testing — Verify

**Verify** (Shouldly ecosystem) performs snapshot testing: on first run it writes the output to a `.verified.txt` / `.json` file; on subsequent runs it diffs the output against the stored snapshot. Use for complex HTML, JSON, or object graph output that is hard to express with individual assertions.

```csharp
// Install: dotnet add package Verify.Xunit (or Verify.NUnit / Verify.MSTest)
using VerifyXunit;
using Xunit;

[UsesVerify]
public class InvoiceRendererTests
{
    [Fact]
    public async Task RenderInvoice_ProducesExpectedHtml()
    {
        var invoice  = Fakers.Invoice(seed: 1);
        var renderer = new InvoiceRenderer();

        string html = renderer.Render(invoice);

        // First run: creates InvoiceRendererTests.RenderInvoice_ProducesExpectedHtml.verified.txt
        // Subsequent runs: compares against stored snapshot — fails if anything changed
        await Verify(html);
    }

    [Fact]
    public async Task SerializeOrder_MatchesSchema()
    {
        var order = Fakers.Order(seed: 42);

        // Snapshot a JSON object — auto-serialized, null fields excluded by default
        await Verify(order)
            .ScrubMember<Order>(o => o.CreatedAt);  // scrub volatile timestamp
    }
}
```

---

## Testing Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `MockBehavior.Strict` on every mock | Brittle tests break on any internal call order change | Use `Strict` only for critical dependencies; `Loose` for loggers and ancillary services |
| `Mock.Verify()` never called | Setups are configured but interactions never verified — tests pass with wrong behavior | Always call `mock.Verify()` or `mock.VerifyAll()` at the end of arrange-act-assert |
| Mocking concrete non-virtual classes with Moq | Moq cannot intercept non-virtual methods — mock has no effect | Extract an interface or make the method virtual; prefer interfaces for DI |
| `Assert.Equal(expected, actual)` with complex objects | Equality is reference-based by default — test passes with wrong data | Use `BeEquivalentTo` (FluentAssertions) or implement `Equals`/`IEquatable<T>` |
| Shared mutable test state (static fields in test class) | Parallel test runs corrupt each other's state | Declare mocks per-test in constructor; use `IClassFixture` only for read-only shared state |
| Integration tests using real DB with no reset | Leftover data from one test breaks the next — order-dependent failures | Use Respawn, EF in-memory, or SQLite in-memory; reset state between tests |
| Hard-coded test data literals scattered across 50 test files | Brittle — changing an entity shape requires updating all literals | Centralize with a Faker or Builder; use seeded Bogus for determinism |
| `await Task.Delay(...)` to wait for async side effects | Flaky — delay too short fails on slow CI; too long is wasteful | Use `Polly.WaitAndRetryAsync` or `FluentAssertions.Extensions.BeAsync` polling instead |
| xUnit constructor with slow I/O (DB connect, HTTP) | Runs for every test — 100 tests = 100 connections | Use `IClassFixture<T>` for shared expensive setup; constructor for cheap initialization |
| `Assert.True(list.Count == 5)` | Failure message says "True != False" — no context | Use `Assert.Equal(5, list.Count)` or `list.Should().HaveCount(5)` for informative output |
| Calling `mock.Setup()` after `Act` | Setup has no effect — the call already happened | Always arrange (setup) before act |
| FluentAssertions v7+ in commercial project without license | License violation; FA v7 requires commercial license for closed-source | Pin to FA v6.x (MIT), switch to Shouldly (MIT), or purchase FA license |
| NUnit `[Test]` without `[TestFixture]` when running with older adapter | Tests silently not discovered by some older runners | Always decorate test classes with `[TestFixture]` for NUnit compatibility |
| xUnit `[Theory]` with no `[InlineData]` or `[MemberData]` | Test is never executed — xUnit skips parameterized tests with no data | Always pair `[Theory]` with at least one data attribute |

---

## Real-World Gotchas — Testing [community]

### **Moq `Setup` on a Non-Virtual Method — Silently Has No Effect** [community]

Moq intercepts calls by generating a proxy class that overrides virtual members. If you set up a method that is not virtual (and not part of an interface), the setup silently does nothing — the real method executes. WHY it causes problems: the test appears to configure mock behavior but the real implementation runs, causing side effects or returning production values. This is the single most common source of "mocking isn't working" confusion. Fix: always mock interfaces or abstract classes. If you must mock a concrete class, the target method must be `virtual` or `abstract`.

```csharp
// BAD: Foo.GetValue() is not virtual — Setup has no effect
var mock = new Mock<Foo>();
mock.Setup(f => f.GetValue()).Returns(42);  // silently ignored!
// Real Foo.GetValue() executes when mock.Object.GetValue() is called

// GOOD: mock an interface or make the method virtual
public interface IFoo { int GetValue(); }
var mock = new Mock<IFoo>();
mock.Setup(f => f.GetValue()).Returns(42);  // works correctly
```

### **`Moq.VerifyAll()` Forgets to Assert Interactions** [community]

Calling `mock.Setup(...)` without a matching `mock.Verify(...)` or `mock.VerifyAll()` at the end means the test can pass even if the interaction never occurred. WHY it causes problems: you intended to verify that an email was sent, but forgot to call `Verify`. The test passes when the production code removes the email call — which is a real regression. Fix: prefer `MockBehavior.Strict` for interactions that must occur, or always add explicit `Verify` calls at the end of every test that uses a mock.

### **xUnit `IClassFixture` State Shared Across Tests — Order Dependency** [community]

`IClassFixture<T>` creates one instance shared across all tests in the class. If one test modifies the fixture's state, subsequent tests see the mutated state. WHY it causes problems: tests that pass in isolation fail when run in a suite because they depend on the order xUnit happens to execute them — which is not guaranteed. Fix: design fixtures to be read-only after `InitializeAsync`; reset mutable state in a `ResetAsync()` call at the start of each test (not in the fixture constructor).

### **FluentAssertions `BeEquivalentTo` Ignores Collections by Default — Wrong Semantics for Ordered Results** [community]

`BeEquivalentTo` compares collections without regard to element order by default (uses set semantics). WHY it causes problems: a test asserting that an API returns items sorted by price passes even when the order is wrong, because FA rearranges elements for comparison. Fix: use `.WithStrictOrdering()` when the expected order matters, or use `Equal` for exact ordered comparison.

```csharp
// BAD: passes even if items are returned in random order
result.Items.Should().BeEquivalentTo(expected.Items);

// GOOD: enforce ordering
result.Items.Should().BeEquivalentTo(expected.Items,
    opts => opts.WithStrictOrdering());

// ALSO GOOD: xUnit Assert.Equal preserves order
Assert.Equal(expected.Items, result.Items);
```

### **`await Task.Delay()` in Tests for Async Side Effects — Flaky CI** [community]

Using `await Task.Delay(500)` to wait for a background operation to complete is a timing anti-pattern. On fast machines the delay is unnecessary; on slow CI the delay may still be too short. WHY it causes problems: flaky tests that fail intermittently in CI but pass locally — among the most time-consuming debugging problems. Fix: expose a `Task` or `Completion` token from the background operation so the test can await directly, or use `WaitUntil` polling with a reasonable timeout.

```csharp
// BAD: flaky — assumes 500ms is always enough
await service.StartProcessingAsync();
await Task.Delay(500);
processed.Should().BeTrue();

// GOOD: expose completion as awaitable
await service.StartProcessingAsync();
await service.WaitForCompletionAsync(timeout: TimeSpan.FromSeconds(5));
processed.Should().BeTrue();
```

---

## NUnit 4.x — Migration and Breaking Changes

NUnit 4.0 (released November 2023) and subsequent 4.x releases (through 4.6 as of May 2026) dropped the classic assertion API that shipped since NUnit 2. Classic assertions such as `Assert.AreEqual`, `Assert.IsNull`, `Assert.IsTrue`, and `Assert.IsFalse` were removed from the `NUnit.Framework` namespace and moved to a compatibility shim in `NUnit.Framework.Legacy`.

### Classic API → Constraint Model Migration

```csharp
// NUnit 3 — classic API (still compiles with NUnit.Framework.Legacy import)
using NUnit.Framework.Legacy;

Assert.AreEqual(expected, actual);
Assert.AreNotEqual(a, b);
Assert.IsNull(value);
Assert.IsNotNull(value);
Assert.IsTrue(condition);
Assert.IsFalse(condition);
Assert.AreSame(a, b);
Assert.IsInstanceOf<T>(obj);
Assert.Throws<T>(() => action());

// NUnit 4 — constraint model (preferred; already available in NUnit 3)
using NUnit.Framework;

Assert.That(actual, Is.EqualTo(expected));
Assert.That(actual, Is.Not.EqualTo(a));
Assert.That(value, Is.Null);
Assert.That(value, Is.Not.Null);
Assert.That(condition, Is.True);
Assert.That(condition, Is.False);
Assert.That(actual, Is.SameAs(a));
Assert.That(obj, Is.InstanceOf<T>());
Assert.That(() => action(), Throws.TypeOf<T>());
```

**Why the change?** The constraint model (`Assert.That`) produces superior failure messages by embedding the full assertion expression. Classic assertions give "Expected 5 but was 3"; the constraint model gives "Expected: 5 But was: 3" with the expression that produced the value.

**Migration path:** The `NUnit.Framework.Legacy` package exists specifically as a temporary migration aid. Add `dotnet add package NUnit.Framework.Legacy` and use `using NUnit.Framework.Legacy;` to compile unchanged NUnit 3 test files. The intent is to migrate each file to the constraint model over time and then remove the legacy dependency.

### NUnit 4 Additional Breaking Changes

```csharp
// TestAdapter version: NUnit 4 requires NUnit3TestAdapter v4.6+ (VS 2022 17.8+)
// Install: dotnet add package NUnit3TestAdapter --version 4.6.*

// [SetUpFixture] changes: now uses [OneTimeSetUp]/[OneTimeTearDown] exclusively
[SetUpFixture]
public class AssemblySetUp
{
    [OneTimeSetUp]
    public static void InitializeAll() { /* runs once per assembly */ }

    [OneTimeTearDown]
    public static void TearDownAll() { /* runs once after all tests */ }
}

// Multiple asserts — NUnit 4 adds Assert.Multiple for soft assertions
[Test]
public void Order_HasExpectedProperties()
{
    var order = new Order(Id: 1, Status: "Shipped", Total: 99.99m);

    // All assertions evaluated; all failures reported (not just the first)
    Assert.Multiple(() =>
    {
        Assert.That(order.Id, Is.EqualTo(1));
        Assert.That(order.Status, Is.EqualTo("Shipped"));
        Assert.That(order.Total, Is.EqualTo(99.99m).Within(0.001m));
    });
}
```

**NUnit 4 requirement checklist:**
- `NUnit` package `>= 4.0`
- `NUnit3TestAdapter` package `>= 4.6`
- Microsoft Testing Platform (`dotnet test`) or VSTest adapter — both supported in NUnit 4
- Replace `using NUnit.Framework;` classic assertions with constraint model, or add `using NUnit.Framework.Legacy;` as a bridge

---

## MSTest v4 — Assert.That and CallerArgumentExpression (2024+)

MSTest v4 (released October 2024) adds a new `Assert.That` overload that accepts a lambda expression, inspects the expression via `CallerArgumentExpression`, and emits detailed diagnostics on failure. It also restructured internal types that should never have been public.

```csharp
// Install: dotnet add package MSTest.TestFramework --version 4.*
//          dotnet add package MSTest.TestAdapter --version 4.*
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class ZooTests
{
    [TestMethod]
    public void GetAnimal_ReturnsExpected()
    {
        var zoo = new Zoo();
        zoo.Add(new Animal("Giraffe"));

        Animal animal = zoo.GetAnimal();

        // v4: Assert.That with lambda — inspects the expression at compile time
        // Failure message: "'expected' expression: '"Giraffe"', 'actual' expression: 'animal.Name'
        //                   Expected: "Giraffe"  Actual: "Zebra""
        Assert.That(() => animal.Name == "Giraffe");
    }
}
```

**MSTest v4 improvements:**
- `Assert.That(() => expr)` — evaluates `expr`, on failure shows expression text, expected value, and actual value side-by-side
- `CallerArgumentExpression` used internally across all `Assert.*` methods for richer messages (e.g., `Assert.AreEqual(expected, actual)` now shows the expression `actual` came from, not just the value)
- Internal types hidden: many previously public types in the MSTest pipeline were made internal; existing test code is unaffected unless you directly referenced infrastructure types
- `Microsoft.Testing.Platform` updated to v2 — aligns with .NET 10 testing infrastructure

**MSTest v3 → v4 migration:** For most teams the migration is a package version bump (`3.x` → `4.x`). Only teams that extended MSTest internals (custom runners, reflection over MSTest types) are affected by the API surface changes.

---

## FluentAssertions v8 — Breaking Changes and New Assertions (2024+)

FluentAssertions v8 (released late 2024) introduced major breaking changes alongside new assertion capabilities.

### License Change — Xceed Community License

```
// FluentAssertions v7 (2023): commercial license required for business use
// FluentAssertions v8 (2024): Xceed Community License
//
// Xceed Community License key terms:
// - Free for open-source (MIT / Apache / etc.) projects
// - Free for evaluation and learning
// - Commercial license required for closed-source / proprietary software
//
// Decision tree:
// Open-source project?              → Use FluentAssertions v8 (free)
// Proprietary / commercial project? → Pin FA to v6.x (MIT), switch to Shouldly,
//                                      or purchase an Xceed commercial license
//
// Shouldly v4.3 (MIT, Jan 2025) is a drop-in alternative for most assertions:
//   price.ShouldBe(99.99m);
//   list.ShouldContain(x => x.Id == 42);
//   action.ShouldThrow<ArgumentException>();
```

### Breaking API Changes in v8

```csharp
// DataSet / DataTable assertions REMOVED from core package
// Install separately: dotnet add package FluentAssertions.DataSets
using FluentAssertions.DataSets;   // v8 only — separate package
dataSet.Should().HaveTable("Orders");

// HttpResponseMessage assertions REMOVED from core package
// Use built-in MSTest / xUnit assertions, or inspect the response object manually:
response.StatusCode.Should().Be(HttpStatusCode.OK);  // still works (StatusCode is a property)
// No more: response.Should().HaveStatusCode(HttpStatusCode.OK);

// .NET Framework < 4.7 and .NET Core < 3.0 support dropped
// Minimum: .NET 4.7+ / .NET Core 3.1+ / .NET 5+
```

### New Assertions in v8.x

```csharp
// Span<T> / ReadOnlySpan<T> / Memory<T> / ReadOnlyMemory<T> assertions (v8.9+)
ReadOnlySpan<byte> buffer = GetData();
buffer.Should().HaveLength(4);
buffer.Should().StartWith(new byte[] { 0xFF, 0xD8 });   // JPEG header
buffer.Should().Contain(new byte[] { 0xFF, 0xD9 });     // JPEG footer

Memory<char> chars = "hello".AsMemory();
chars.Should().BeEquivalentTo("hello".AsMemory());

// BeNaN / NotBeNaN — floating-point NaN checks (v8.0+)
double result = Math.Sqrt(-1);
result.Should().BeNaN();

double goodValue = Math.Sqrt(4);
goodValue.Should().NotBeNaN();

// HaveMillisecond / NotHaveMillisecond — temporal precision assertions (v8.9+)
DateTime ts = new DateTime(2025, 1, 15, 10, 30, 45, 500);
ts.Should().HaveMillisecond(500);
ts.Should().NotHaveMillisecond(0);

// BeEquivalentTo with new null-handling options (v8.10+)
// ComparingNullCollectionsAsEmpty — null collection == empty collection
actualDto.Should().BeEquivalentTo(expectedDto, opts =>
    opts.ComparingNullCollectionsAsEmpty());

// ComparingNullStringsAsEmpty — null string == "" during equivalency
actualDto.Should().BeEquivalentTo(expectedDto, opts =>
    opts.ComparingNullStringsAsEmpty());

// Performance: BeEquivalentTo on large unordered collections is significantly
// faster in v8.10+ due to optimized set-comparison algorithm (no longer O(n²))
```

**FluentAssertions version decision table:**

| Project type | Recommended version | License |
|---|---|---|
| Open-source / FOSS | v8.x (latest) | Xceed Community (free) |
| Proprietary, budget constrained | v6.x (MIT) | MIT — no upgrade |
| Proprietary, willing to pay | v8.x + Xceed commercial license | Commercial |
| Proprietary, any budget | Shouldly v4.x | MIT — free |

---

## xUnit v3 — Additional New Features

The current guide covers xUnit v3's `IAsyncLifetime`, `TheoryData<T>`, and `IAssemblyFixture`. The following features are also notable in v3.x (stable from 3.0 in early 2024, latest 3.2.2 as of April 2025):

### CancellationToken Injection into Test Methods

xUnit v3 test methods can accept a `CancellationToken` parameter directly. The framework provides a token that is cancelled when the test timeout expires or the test runner is shut down — no manual `CancellationTokenSource` needed.

```csharp
using Xunit;

public class OrderServiceTests
{
    // xUnit v3: declare CancellationToken parameter — framework injects it automatically
    [Fact]
    public async Task GetOrderAsync_ReturnsOrder(CancellationToken cancellationToken)
    {
        var service = new OrderService();

        // Pass the framework-provided token — auto-cancelled on test timeout
        var order = await service.GetOrderAsync(1, cancellationToken);

        order.Should().NotBeNull();
        order!.Id.Should().Be(1);
    }

    // Works for Theory too
    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    public async Task GetOrderAsync_MultipleIds(int id, CancellationToken cancellationToken)
    {
        var order = await _service.GetOrderAsync(id, cancellationToken);
        order.Should().NotBeNull();
    }
}
```

**Why this matters:** In xUnit v2, passing a cancellation token to async tests required wiring up `CancellationTokenSource` manually, then disposing it in `Dispose()`. The v3 injection eliminates this boilerplate and ties the timeout/cancellation lifecycle to the test runner directly.

### Assert.Multiple — Soft Assertions

xUnit v3 adds `Assert.Multiple` for evaluating multiple independent assertions without aborting on the first failure. All failures are collected and reported together.

```csharp
[Fact]
public async Task PlaceOrder_ReturnsFullyPopulatedResponse()
{
    var response = await _sut.PlaceOrderAsync(new OrderRequest(CustomerId: 1));

    // All assertions evaluated — all failures listed in the output
    Assert.Multiple(
        () => Assert.NotNull(response),
        () => Assert.Equal("Pending", response!.Status),
        () => Assert.True(response.Id > 0, "Id should be positive"),
        () => Assert.NotEqual(default, response.CreatedAt)
    );
}
```

**Comparison with FluentAssertions `AssertionScope`:**

```csharp
// FluentAssertions equivalent — also collects all failures
using (new AssertionScope())
{
    response.Should().NotBeNull();
    response!.Status.Should().Be("Pending");
    response.Id.Should().BePositive();
    response.CreatedAt.Should().NotBe(default);
}
```

Both collect all failures before throwing. Use `Assert.Multiple` (xUnit v3 built-in) if you want no extra dependencies; use `AssertionScope` if your team already uses FluentAssertions.

---

## TUnit — Source-Generated, Parallel-by-Default Test Framework

TUnit is a modern .NET testing framework (v1.44 as of May 2025) that uses Roslyn source generators for test discovery at compile time rather than runtime reflection. This removes the need for a runner host process and makes tests compatible with Native AOT.

### Core Differences from xUnit / NUnit

| Feature | xUnit v3 | NUnit 4 | TUnit |
|---|---|---|---|
| Test discovery | Runtime reflection | Runtime reflection | Compile-time source generators |
| Default parallelism | Per-collection isolation | Sequential within fixture | Parallel by default (all tests) |
| Native AOT | No | No | Yes |
| DI in tests | Manual / WebApplicationFactory | Manual | Built-in `[ClassDataSource]` with DI |
| Assembly fixture | `IAssemblyFixture<T>` | `[SetUpFixture]` | `[ClassDataSource(Shared = SharedType.PerTestSession)]` |
| Soft assertions | `Assert.Multiple` | `Assert.Multiple` | Built-in `.AwaitAssertion` / `AssertionScope` |

### Getting Started

```csharp
// Install: dotnet add package TUnit
using TUnit.Core;

public class CartTests
{
    // [Test] replaces [Fact] and [Theory] from xUnit
    [Test]
    public async Task AddItem_UpdatesTotal()
    {
        var cart = new ShoppingCart();
        await cart.AddItemAsync(new CartItem("SKU-1", 2, 9.99m));

        await Assert.That(cart.Total).IsEqualTo(19.98m);
    }

    // [Arguments] replaces [InlineData] / [TestCase]
    [Test]
    [Arguments(10.0, 0.2, 8.0)]
    [Arguments(100.0, 0.5, 50.0)]
    [Arguments(0.0, 0.1, 0.0)]
    public async Task ApplyDiscount_ReturnsExpected(
        double price, double discount, double expected)
    {
        var result = PricingEngine.Apply(price, discount);
        await Assert.That(result).IsEqualTo(expected).Within(0.001);
    }

    // [MatrixDataSource] — combinatorial: all combinations of all parameter values
    [Test]
    [MatrixDataSource]
    public async Task IsValidPrice_Combinatorial(
        [Matrix(0.0, 1.0, -1.0)] double price,
        [Matrix(true, false)] bool allowNegative)
    {
        bool result = PricingEngine.IsValidPrice(price, allowNegative);
        if (allowNegative || price >= 0)
            await Assert.That(result).IsTrue();
        else
            await Assert.That(result).IsFalse();
    }
}
```

### Dependency Injection in Tests

TUnit supports direct DI injection into test class constructors when the class is registered as a `[ClassDataSource]`:

```csharp
// Register real services via ClassDataSource — no WebApplicationFactory needed for unit DI
[ClassDataSource<OrderService>(Shared = SharedType.PerTestSession)]
public class OrderServiceTests(OrderService sut)
{
    [Test]
    public async Task GetByIdAsync_ExistingOrder_ReturnsOrder()
    {
        var order = await sut.GetByIdAsync(1, default);
        await Assert.That(order).IsNotNull();
    }
}
```

### Controlling Parallelism

```csharp
// TUnit runs ALL tests in parallel by default — use these attributes to restrict:

// [DependsOn] — ensure one test runs after another
[Test]
public async Task CreateOrder_Succeeds() { /* ... */ }

[Test]
[DependsOn(nameof(CreateOrder_Succeeds))]
public async Task ShipOrder_AfterCreate_Succeeds() { /* ... */ }

// [NotInParallel] with a key — tests with the same key run sequentially
[Test]
[NotInParallel("DatabaseMutations")]
public async Task UpdateOrder_StatusToShipped() { /* ... */ }

[Test]
[NotInParallel("DatabaseMutations")]
public async Task CancelOrder_ByCustomer() { /* ... */ }

// [ParallelLimit<T>] — cap concurrency for a resource (e.g., DB connections)
public class DatabaseLimiter : IParallelLimit
{
    public int Limit => 5;  // max 5 concurrent DB tests
}

[Test]
[ParallelLimit<DatabaseLimiter>]
public async Task HeavyDatabaseTest() { /* ... */ }
```

### Built-In Assertions

TUnit ships its own assertion library using an async-first fluent API:

```csharp
// Scalar
await Assert.That(value).IsEqualTo(42);
await Assert.That(name).StartsWith("Alice");
await Assert.That(flag).IsTrue();
await Assert.That(obj).IsNull();

// Collections
await Assert.That(list).HasCount().EqualTo(3);
await Assert.That(list).Contains(x => x.Id == 42);
await Assert.That(list).IsInOrder().Using<int>(Comparer<int>.Default);

// Exceptions
await Assert.ThrowsAsync<ArgumentException>(async () => await sut.DoAsync(null));

// Equivalency
await Assert.That(actual).IsEquivalentTo(expected);
```

**When to choose TUnit:** TUnit is the right choice when you need Native AOT compatibility, source-generator-based discovery (faster CI cold start), or you want parallel-by-default semantics with fine-grained dependency control. Teams migrating from xUnit will find the attribute surface familiar; the main adjustment is switching from `Assert.Equal(expected, actual)` to `await Assert.That(actual).IsEqualTo(expected)`.

---

## Real-World Gotchas — Testing Libraries v7/v8/v4 [community]

### **FluentAssertions v8 Xceed License — Commercial Projects Silently Non-Compliant** [community]

Upgrading `<PackageReference Include="FluentAssertions" Version="*" />` (wildcard) automatically pulled v8 for many teams at end of 2024. The Xceed Community License for v8 requires a commercial license for proprietary software. Teams with wildcard version pins got the license change without reviewing it. WHY it causes problems: legal exposure in commercial codebases that auto-updated via `dotnet outdated` or Dependabot. Fix: (a) pin to v6.x explicitly (`Version="6.*"`), (b) switch to Shouldly or Awaitility.NET (both MIT), or (c) review and purchase Xceed license. Auditing `dotnet list package` across all repos is the first step.

```xml
<!-- Pin to MIT-licensed v6.x -->
<PackageReference Include="FluentAssertions" Version="6.*" />

<!-- Or switch to Shouldly (MIT, actively maintained) -->
<PackageReference Include="Shouldly" Version="4.*" />
```

### **NUnit 4 Classic API Removal — `Assert.AreEqual` Not Found** [community]

Teams upgrading from NUnit 3 to NUnit 4 by bumping the package version encounter `CS0117: 'Assert' does not contain a definition for 'AreEqual'`. This shocks teams that have thousands of `Assert.AreEqual` calls. WHY it causes problems: a version bump becomes a large refactor. The fix is NOT to roll back NUnit 4 — instead, add `NUnit.Framework.Legacy` as a temporary shim and plan incremental migration to `Assert.That(actual, Is.EqualTo(expected))`.

```xml
<!-- Temporary migration bridge — remove after migrating all test files -->
<PackageReference Include="NUnit.Framework.Legacy" Version="1.*" />
```

```csharp
// Add this using to any file with classic assertions — no code changes needed yet
using NUnit.Framework.Legacy;

// Your existing NUnit 3 classic assertions compile again:
Assert.AreEqual(expected, actual);
Assert.IsNull(value);
```

### **TUnit Parallel Default Breaks State-Sharing Test Patterns** [community]

TUnit runs tests in parallel by default. Teams migrating from xUnit (where tests within a collection are sequential) discover that shared state — static fields, file system paths, database rows, environment variables — causes intermittent failures when tests run concurrently. WHY it causes problems: tests that passed with sequential execution corrupt each other's state in TUnit's parallel model. Fix: audit every test for shared mutable state. Use `[NotInParallel]` for tests that genuinely must be sequential, `[ParallelLimit<T>]` for resource-constrained tests, and `[DependsOn]` for ordered chains.

```csharp
// BAD: static mutable field accessed by multiple tests in parallel
public class ReportTests
{
    private static List<string> _generatedFiles = new();

    [Test]
    public async Task GenerateReport_CreatesFile()
    {
        var path = await _sut.GenerateAsync();
        _generatedFiles.Add(path);  // race condition in parallel
    }
}

// GOOD: isolate per-test, use [NotInParallel] if truly sequential
[Test]
[NotInParallel("FileSystem")]
public async Task GenerateReport_CreatesFile()
{
    var path = await _sut.GenerateAsync();
    // local variable, not shared
    File.Exists(path).Should().BeTrue();
    File.Delete(path);
}
```

### **xUnit v3 `CancellationToken` Parameter Must Be Last** [community]

When using xUnit v3's automatic `CancellationToken` injection, the token parameter must be the last parameter in the method signature. If it appears before a `[Theory]` data parameter, xUnit treats it as a data-injection slot and fails to find matching test data. WHY it causes problems: subtle misordering causes `InvalidOperationException` at runtime with a confusing message about missing test data.

```csharp
// BAD: CancellationToken before Theory data parameter — xUnit tries to inject test data for it
[Theory]
[InlineData(1)]
public async Task GetOrder_ById(CancellationToken ct, int id) { /* fails at discovery */ }

// GOOD: CancellationToken last
[Theory]
[InlineData(1)]
public async Task GetOrder_ById(int id, CancellationToken ct) { /* correct */ }

// Also GOOD: [Fact] with only CancellationToken — no ordering issue
[Fact]
public async Task GetAllOrders(CancellationToken ct) { /* correct */ }
```

---

## Anti-Patterns Quick Reference — Testing Library Updates

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Wildcard `Version="*"` on FluentAssertions | Auto-upgrades to v8 Xceed license — legal exposure for commercial code | Pin to `"6.*"` (MIT) or switch to Shouldly `"4.*"` (MIT) |
| Upgrading to NUnit 4 without `NUnit.Framework.Legacy` bridge | Breaks all `Assert.AreEqual` / `Assert.IsNull` calls — CI fails immediately | Add `NUnit.Framework.Legacy` package as bridge; migrate incrementally |
| TUnit without parallelism attributes on shared-state tests | Parallel default corrupts shared state — intermittent CI failures | Use `[NotInParallel]` / `[DependsOn]` / per-test state isolation |
| xUnit v3 `CancellationToken` not last in `[Theory]` method | Discovery error — test data injection sees token slot | Always declare `CancellationToken ct` as the last parameter |
| MSTest v4 `Assert.That(() => a.Prop == b)` for null `a` | Lambda throws NRE before Assert evaluates it — test error, not assertion failure | Guard null before `Assert.That`, or use `Assert.IsNotNull(a)` first |
| FluentAssertions v8 `DataSet` assertions after upgrade | `HaveTable` / `HaveColumn` no longer in core — `MissingMethodException` | Add `FluentAssertions.DataSets` NuGet package |
| `MSTest.Sdk` version pinned in `global.json` only | Dependabot and `dotnet outdated` don't see SDK-style version — silent drift | Check `global.json` + project file version manually; use Renovate with custom pattern |
| MTP `Retry` extension on unit tests | Retry masks broken logic, hiding real failures — tests pass on second attempt | Use `--retry-failed-tests` only for integration/environment-dependent tests |
| xUnit v3 `Assert.Equivalent` with open class hierarchy | Default `RespectingDeclaredTypes` allows derived type fields to be ignored — hidden data loss in assertions | Use `Assert.Equivalent(expected, actual, strict: true)` or `BeEquivalentTo` with `RespectingRuntimeTypes()` when inheritance matters |

---

## MSTest SDK — Project-Type Simplification (MSTest.Sdk 3.4+)

`MSTest.Sdk` is a custom MSBuild SDK that replaces the traditional `Microsoft.NET.Sdk` for MSTest projects. It bundles all MSTest dependencies, sets sensible defaults, and enables Microsoft.Testing.Platform (MTP) out of the box.

### Minimal `MSTest.Sdk` Project File

```xml
<!-- Old-style MSTest project — multiple packages, manual runner opt-in -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <EnableMSTestRunner>true</EnableMSTestRunner>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="MSTest" Version="4.1.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />
  </ItemGroup>
</Project>

<!-- New-style: MSTest.Sdk handles everything automatically -->
<Project Sdk="MSTest.Sdk/4.1.0">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

Pin the SDK version in `global.json` to keep all projects aligned:

```json
{
  "msbuild-sdks": {
    "MSTest.Sdk": "4.1.0"
  }
}
```

### Built-In Profiles and Extensions

`MSTest.Sdk` supports three extension profiles via `TestingExtensionsProfile`:

| Profile | Included extensions |
|---|---|
| `None` | No extensions |
| `Default` (implicit) | Code Coverage + TRX Report |
| `AllMicrosoft` | Code Coverage + TRX + Crash Dump + Hang Dump + Hot Reload + Retry + Fakes |

```xml
<!-- Explicit Default profile (same as omitting the property) -->
<TestingExtensionsProfile>Default</TestingExtensionsProfile>

<!-- Override: disable CodeCoverage, add Retry on top of Default -->
<EnableMicrosoftTestingExtensionsCodeCoverage>false</EnableMicrosoftTestingExtensionsCodeCoverage>
<EnableMicrosoftTestingExtensionsRetry>true</EnableMicrosoftTestingExtensionsRetry>
```

### Aspire and Playwright Integration

`MSTest.Sdk` provides one-line enablement for Aspire and Playwright testing:

```xml
<!-- Aspire integration testing (MSTest.Sdk 3.4+) -->
<Project Sdk="MSTest.Sdk/4.1.0">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <EnableAspireTesting>true</EnableAspireTesting>
  </PropertyGroup>
</Project>

<!-- Playwright end-to-end testing (MSTest.Sdk 3.4+) -->
<Project Sdk="MSTest.Sdk/4.1.0">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <EnablePlaywright>true</EnablePlaywright>
  </PropertyGroup>
</Project>
```

Both properties bring in the required dependencies and implicit `using` directives automatically — no manual `<PackageReference>` entries needed.

**Gotcha — `MSTest.Sdk` migration note:** When switching an existing project from `Microsoft.NET.Sdk` to `MSTest.Sdk`, remove `<EnableMSTestRunner>`, `<OutputType>Exe</OutputType>`, `<IsPackable>false</IsPackable>`, and all `MSTest.*` + `Microsoft.NET.Test.Sdk` `<PackageReference>` entries — the SDK adds them implicitly. Leaving them causes duplicate package warnings and potential version conflicts.

---

## Microsoft.Testing.Platform — Retry and Hot Reload Extensions

### Retry Extension — Flaky Test Resilience (`Microsoft.Testing.Extensions.Retry`)

The MTP Retry extension reruns failed tests up to N times before reporting them as failed. It is designed for integration tests subject to transient environment failures (network blips, container startup races) — **not** for unit tests.

```dotnetcli
# Add the package (auto-registered when Microsoft.Testing.Platform.MSBuild is present)
dotnet add package Microsoft.Testing.Extensions.Retry

# CLI: retry failed tests up to 3 times
dotnet run --project MyIntegrationTests -- --retry-failed-tests 3

# Safety valve — stop retrying if >50% of tests are failing (env problem, not flakiness)
dotnet run --project MyIntegrationTests -- --retry-failed-tests 2 --retry-failed-tests-max-percentage 50

# Count cap — stop retrying if more than 10 individual tests failed
dotnet run --project MyIntegrationTests -- --retry-failed-tests 3 --retry-failed-tests-max-tests 10
```

**Important constraints:**
- Not supported on browser platforms (Blazor WASM test host).
- Cannot be combined with Hot Reload mode (`TESTINGPLATFORM_HOTRELOAD_ENABLED=1`).
- Ships under the **Microsoft.Testing.Platform Tools license** — review before commercial use or redistribution.

```xml
<!-- Enable Retry explicitly in a project using MSTest.Sdk -->
<Project Sdk="MSTest.Sdk/4.1.0">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <EnableMicrosoftTestingExtensionsRetry>true</EnableMicrosoftTestingExtensionsRetry>
  </PropertyGroup>
</Project>
```

### Hot Reload Extension — Rapid Test Iteration (`Microsoft.Testing.Extensions.HotReload`)

The Hot Reload extension applies code changes to a running test session without restarting the process. Available in "console mode" only (not Test Explorer in VS or VS Code as of early 2026).

```json
// launchSettings.json — enable hot reload for the test project
{
  "profiles": {
    "MyTests": {
      "commandName": "Project",
      "environmentVariables": {
        "TESTINGPLATFORM_HOTRELOAD_ENABLED": "1"
      }
    }
  }
}
```

The Hot Reload package also ships under the **Microsoft.Testing.Platform Tools license** (restrictive, non-commercial for third-party tool redistribution).

---

## NUnit 4.x — `[FixtureLifeCycle]` for Per-Test Instance Isolation

NUnit 3 creates one instance of a `[TestFixture]` class and runs all `[Test]` methods on it. Shared mutable fields accumulate state across tests, causing ordering bugs. NUnit 4 introduced `[FixtureLifeCycle]` to control whether a new instance is created for every test.

```csharp
// Default (SingleInstance — NUnit 3 behavior, still default in NUnit 4):
// ONE fixture instance shared across all tests — fields accumulate state.
[TestFixture]
public class SharedStateTests
{
    private List<string> _log = new();  // shared across all [Test] methods

    [Test] public void Test1() => _log.Add("T1");
    [Test] public void Test2() => Assert.That(_log, Is.Empty);  // FAILS if Test1 ran first
}

// InstancePerTestCase — fresh fixture instance created for every [Test] method
[TestFixture]
[FixtureLifeCycle(LifeCycle.InstancePerTestCase)]
public class IsolatedTests
{
    // Field is reset for every test — no shared state
    private Mock<IOrderService> _sut = new(MockBehavior.Strict);

    [SetUp]
    public void SetUp()
    {
        // Runs on a brand-new instance — safe, no leftover state from previous tests
        _sut.Setup(s => s.GetAsync(It.IsAny<int>(), default))
            .ReturnsAsync(new Order(1));
    }

    [Test]
    public async Task GetAsync_ReturnsOrder()
    {
        var order = await _sut.Object.GetAsync(1, default);
        Assert.That(order!.Id, Is.EqualTo(1));
    }

    [Test]
    public async Task GetAsync_AnotherTest()
    {
        // Fresh Mock — SetUp called on new instance, zero leftover invocations
        var order = await _sut.Object.GetAsync(1, default);
        Assert.That(order, Is.Not.Null);
    }
}
```

**When to use each lifecycle:**

| `LifeCycle` value | When to use |
|---|---|
| `SingleInstance` (default) | Tests sharing expensive read-only setup (e.g., parsed config, compiled regex) |
| `InstancePerTestCase` | Any test with `Mock<T>` fields, mutable state, or setup that must be fresh per test |

**With parallel tests:** Combining `InstancePerTestCase` with `[Parallelizable]` is safe — each parallel test runs on its own instance. `SingleInstance` with `[Parallelizable]` requires all field access to be thread-safe (e.g., lock-protected or immutable).

```csharp
// Safe combination: fresh instance per test + all tests run in parallel
[TestFixture]
[FixtureLifeCycle(LifeCycle.InstancePerTestCase)]
[Parallelizable(ParallelScope.All)]
public class ParallelSafeTests
{
    private readonly Mock<IEmailSender> _email = new();

    [Test] public async Task Send_ValidEmail_Succeeds() { /* isolated Mock */ }
    [Test] public async Task Send_EmptyTo_Throws()      { /* isolated Mock */ }
}
```

---

## xUnit v3 — `Assert.Equivalent` Structural Equality

xUnit v3 adds `Assert.Equivalent` for deep structural comparison — comparing objects by their public member values rather than reference identity. It covers the most common use case without requiring FluentAssertions.

```csharp
// Basic: compares all public properties recursively by value
var expected = new OrderDto(Id: 42, Status: "Shipped", Total: 99.99m);
var actual   = service.GetOrderDto(42);

Assert.Equivalent(expected, actual);
// Fails with a detailed diff if any property differs

// strict: true — actual must not have extra members that expected lacks
// (default: extra members on actual are silently ignored)
Assert.Equivalent(expected, actual, strict: true);

// Collections — order-sensitive element-by-element comparison
var expectedItems = new[] { new Item("SKU-1", 2), new Item("SKU-2", 1) };
Assert.Equivalent(expectedItems, actual.Items);
// Note: order matters — unlike FA BeEquivalentTo which is order-insensitive by default
```

**`strict` parameter semantics:**
- `strict: false` (default) — actual may have more members than expected; only expected's members are checked. Useful when asserting a partial projection/DTO.
- `strict: true` — both sides must expose the same set of members. Use when comparing full entity objects where extra members on actual are a bug.

**Comparison with FluentAssertions `BeEquivalentTo`:**

| Feature | `Assert.Equivalent` (xUnit v3) | FA `BeEquivalentTo` |
|---|---|---|
| Deep member comparison | Yes | Yes |
| Order-insensitive collections | No — order matters | Yes (default), opt-in to ordered |
| Exclude specific members | No | Yes (`Excluding(x => x.Prop)`) |
| Exclude by type | No | Yes (v8.9+: `Excluding(m => m.Type == typeof(T))`) |
| Custom comparers per type | No | Yes |
| Null-as-empty option | No | Yes (v8.10 `ComparingNullCollectionsAsEmpty`) |
| Dependency | xUnit v3 built-in | FluentAssertions NuGet |

Use `Assert.Equivalent` for quick structural equality checks with no extra dependencies; use `BeEquivalentTo` when you need exclusions, collection-order flexibility, or custom comparers.

---

## FluentAssertions v8.9 — Collection Aliases and Type-Based Exclusion

### `BeEqualTo` / `NotBeEqualTo` — Collection Equivalence Aliases (v8.9)

v8.9 added `BeEqualTo` and `NotBeEqualTo` as named aliases for `BeEquivalentTo`/`NotBeEquivalentTo` on collections. These match the general assertion convention (`x.Should().Be(y)`) and are the preferred names in new code.

```csharp
// Existing names (still work in v8.9)
list.Should().BeEquivalentTo(expected);
list.Should().NotBeEquivalentTo(other);

// New aliases (v8.9+) — identical semantics, preferred for collections
list.Should().BeEqualTo(expected);
list.Should().NotBeEqualTo(other);
```

### Type-Based Property Exclusion in `BeEquivalentTo` (v8.9)

Prior to v8.9, excluding properties required specifying each path individually. v8.9 added support for excluding all properties of a given type across the entire object graph:

```csharp
public record OrderDto(int Id, string Status, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

// Old — must exclude each timestamp property by path
actual.Should().BeEquivalentTo(expected,
    opts => opts
        .Excluding(o => o.CreatedAt)
        .Excluding(o => o.UpdatedAt));

// New (v8.9+) — exclude all properties of type DateTimeOffset in one expression
actual.Should().BeEquivalentTo(expected,
    opts => opts.Excluding(member => member.Type == typeof(DateTimeOffset)));

// Combine type-based and path-based exclusions
actual.Should().BeEquivalentTo(expected, opts => opts
    .Excluding(member => member.Type == typeof(DateTimeOffset))
    .Excluding(o => o.InternalAuditLog));
```

This is especially useful for DTOs with audit timestamps scattered across multiple nested types — one expression covers them all.

---

## Real-World Gotchas — MTP and MSTest SDK [community]

### **MSTest SDK Version Not Visible to Dependabot or `dotnet outdated`** [community]

`MSTest.Sdk` is a NuGet-provided MSBuild SDK whose version lives in `global.json` under `msbuild-sdks`. Standard NuGet tooling — `dotnet outdated`, Dependabot, Visual Studio NuGet Manager — does not scan `global.json` for SDK versions. WHY it causes problems: teams run a stale `MSTest.Sdk` version for months after security fixes or breaking change patches are released. Fix: use Renovate Bot with a custom extractor that matches `global.json` `msbuild-sdks` patterns, or audit `global.json` manually on each sprint.

```json
// global.json — dotnet outdated does NOT warn you when this version is outdated
{
  "msbuild-sdks": {
    "MSTest.Sdk": "4.1.0"   // check NuGet.org manually: nuget.org/packages/MSTest.Sdk
  }
}
```

### **MTP Retry / Hot Reload / Crash Dump Extensions Have a Restrictive License** [community]

Several MTP extensions ship under the **Microsoft.Testing.Platform Tools license**, which is NOT MIT or Apache. It restricts redistribution as part of a third-party SDK or tool. The extensions affected include `Microsoft.Testing.Extensions.Retry`, `Microsoft.Testing.Extensions.HotReload`, `Microsoft.Testing.Extensions.CrashDump`, and `Microsoft.Testing.Extensions.HangDump`. WHY it causes problems: teams enabling `<TestingExtensionsProfile>AllMicrosoft</TestingExtensionsProfile>` silently pull in restricted-license packages that violate their open-source licensing policy. Fix: use `Default` profile; add restricted-license extensions explicitly only to internal test projects.

```xml
<!-- RISKY: AllMicrosoft pulls in restricted-license extensions -->
<TestingExtensionsProfile>AllMicrosoft</TestingExtensionsProfile>

<!-- SAFE: Default profile only — MIT-compatible -->
<TestingExtensionsProfile>Default</TestingExtensionsProfile>

<!-- If you need Retry for integration tests, opt in explicitly and document the license decision -->
<EnableMicrosoftTestingExtensionsRetry>true</EnableMicrosoftTestingExtensionsRetry>
<!-- License: https://www.nuget.org/packages/Microsoft.Testing.Extensions.Retry -->
```

### **`Assert.Equivalent` Ignores Derived-Class Members When Variables Are Typed as Base Class** [community]

xUnit v3's `Assert.Equivalent` uses the compile-time (declared) type to determine which members to compare. When objects are stored in base-class variables, properties added in derived classes are silently skipped. WHY it causes problems: assertions pass even when derived-class data is wrong, giving false confidence in test coverage for polymorphic code.

```csharp
class Shape { public string Color { get; set; } = ""; }
class Circle : Shape { public double Radius { get; set; } }

Shape expected = new Circle { Color = "red", Radius = 5.0 };
Shape actual   = new Circle { Color = "red", Radius = 0.0 };  // wrong radius!

// BAD: Assert.Equivalent sees Shape — Radius property is not compared
Assert.Equivalent(expected, actual);  // PASSES (silently wrong)

// FIX 1: cast both sides to the concrete type
Assert.Equivalent((Circle)expected, (Circle)actual);  // FAILS correctly

// FIX 2: use strict mode — forces type-shape validation (still uses declared type,
// but also fails if actual has extra required members missing from expected)
Assert.Equivalent(expected, actual, strict: true);  // may still miss Radius

// FIX 3: FluentAssertions with RespectingRuntimeTypes
actual.Should().BeEquivalentTo(expected, opts => opts.RespectingRuntimeTypes());  // FAILS correctly
```

---

## Anti-Patterns Quick Reference — MTP, MSTest SDK, and New Assertions

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `MSTest.Sdk` version managed only in `global.json` | `dotnet outdated` / Dependabot blind spot — version drifts silently | Check NuGet.org manually; use Renovate with custom SDK extractor |
| `<TestingExtensionsProfile>AllMicrosoft</TestingExtensionsProfile>` in OSS project | Pulls in restricted-license extensions — violates MIT/Apache OSS policy | Use `Default` profile; explicitly enable only needed restricted extensions |
| `--retry-failed-tests` on unit test suite | Masks broken logic — tests pass on retry, hiding real bugs | Reserve Retry for integration/environment-sensitive tests only |
| `Assert.Equivalent` on base-type variables with derived data | Derived-class members silently ignored — false pass | Cast to concrete type, or use FA `BeEquivalentTo` with `RespectingRuntimeTypes()` |
| `[FixtureLifeCycle(LifeCycle.SingleInstance)]` with Moq + `[Parallelizable]` | Shared Mock state races — intermittent test failures | Use `InstancePerTestCase` with Moq, or make all shared fixtures immutable |
| `EnableAspireTesting` in non-Aspire test projects | Pulls unnecessary Aspire dependencies, inflates binary | Only set `EnableAspireTesting` in projects that reference Aspire components |

---

## Testcontainers.NET — Docker-Based Integration Testing

Testcontainers.NET (v3.x, stable since late 2023) spins up real Docker containers inside test code. Each container is a fully real database, message broker, or cache — no emulator quirks, no schema drift. The library integrates with `IAsyncLifetime` so containers start before the first test and stop automatically after the last.

### Installing and Running a SQL Server Container

```csharp
// dotnet add package Testcontainers
// dotnet add package Testcontainers.MsSql
using Testcontainers.MsSql;
using Xunit;

public class OrderRepositoryTests : IAsyncLifetime
{
    // Fluent builder configures the container image, credentials, and startup wait strategy
    private readonly MsSqlContainer _db = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
        .WithPassword("Test@1234!")
        .Build();

    // IAsyncLifetime — container starts before any test in this class
    public async Task InitializeAsync()
    {
        await _db.StartAsync();

        // Apply schema migrations using the real connection string
        var connString = _db.GetConnectionString();
        await MigrationsHelper.ApplyAsync(connString);
    }

    public async Task DisposeAsync()
    {
        await _db.StopAsync();
        await _db.DisposeAsync();
    }

    [Fact]
    public async Task SaveAsync_PersistsOrder()
    {
        await using var conn = new SqlConnection(_db.GetConnectionString());
        var repo  = new OrderRepository(conn);
        var order = Fakers.Order(seed: 1);

        await repo.SaveAsync(order, CancellationToken.None);

        var loaded = await repo.GetByIdAsync(order.Id, CancellationToken.None);
        loaded.Should().BeEquivalentTo(order, opts => opts.Excluding(o => o.CreatedAt));
    }
}
```

### PostgreSQL Container (Npgsql)

```csharp
// dotnet add package Testcontainers.PostgreSql
using Testcontainers.PostgreSql;

public class InventoryDbTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _pg = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .WithDatabase("inventory_test")
        .WithUsername("tester")
        .WithPassword("pw")
        .Build();

    public Task InitializeAsync() => _pg.StartAsync();
    public Task DisposeAsync()    => _pg.DisposeAsync().AsTask();

    [Fact]
    public async Task QueryInventory_ReturnsItems()
    {
        await using var conn = new NpgsqlConnection(_pg.GetConnectionString());
        var items = await conn.QueryAsync<InventoryItem>("SELECT * FROM inventory");
        items.Should().NotBeEmpty();
    }
}
```

### Container Reuse Across Tests (`IClassFixture`)

Starting a container per test class is fast for a handful of classes but wasteful for a large suite. Promote the container to a shared `IClassFixture` and use Respawn to reset data between tests instead.

```csharp
// Shared fixture — container starts once for all test classes that use it
public class SqlServerFixture : IAsyncLifetime
{
    private readonly MsSqlContainer _db = new MsSqlBuilder().Build();

    public string ConnectionString => _db.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _db.StartAsync();
        await MigrationsHelper.ApplyAsync(ConnectionString);
        Respawner = await Respawner.CreateAsync(ConnectionString, new RespawnerOptions
        {
            TablesToIgnore = [new Table("__EFMigrationsHistory")]
        });
    }

    public Respawner Respawner { get; private set; } = null!;

    public Task DisposeAsync() => _db.DisposeAsync().AsTask();
}

// Each test resets data via Respawn — no container restart needed
[Collection("SqlServer")]
public class ProductRepositoryTests(SqlServerFixture fixture) : IAsyncLifetime
{
    public Task InitializeAsync() => fixture.Respawner.ResetAsync(fixture.ConnectionString);
    public Task DisposeAsync()    => Task.CompletedTask;

    [Fact]
    public async Task GetByCategory_ReturnsProducts() { /* ... */ }
}
```

**Testcontainers module ecosystem (as of 2025):** SQL Server, PostgreSQL, MySQL, MongoDB, Redis, Kafka, RabbitMQ, Elasticsearch, MinIO, LocalStack, Azure CosmosDB emulator, and many more are available as typed builder packages (`Testcontainers.*`). Each adds a strongly-typed builder with sensible defaults.

---

## HttpClient Testing — MockHttp and WireMock.Net

Real `HttpClient` calls in unit tests are slow, brittle, and have network side effects. Two libraries dominate .NET HTTP mocking:

- **RichardSzalay.MockHttp** — in-process mock `HttpMessageHandler`; fast, zero ports, ideal for unit tests
- **WireMock.Net** — runs a real HTTP server on a loopback port; supports response templating, stateful scenarios, and request journals; ideal for contract/integration tests

### MockHttp (`RichardSzalay.MockHttp`)

```csharp
// dotnet add package RichardSzalay.MockHttp
using RichardSzalay.MockHttp;
using System.Net.Http.Json;

public class WeatherClientTests
{
    [Fact]
    public async Task GetForecastAsync_ReturnsForecast()
    {
        // 1. Create handler and configure expected requests
        var mockHttp = new MockHttpMessageHandler();

        mockHttp
            .When(HttpMethod.Get, "https://api.weather.example/forecast*")
            .WithQueryString("city", "Seattle")
            .Respond(HttpStatusCode.OK,
                     JsonContent.Create(new ForecastDto(City: "Seattle", TempC: 12)));

        // 2. Create HttpClient backed by the mock handler
        var client = mockHttp.ToHttpClient();
        client.BaseAddress = new Uri("https://api.weather.example/");

        var sut = new WeatherClient(client);

        // 3. Act
        var forecast = await sut.GetForecastAsync("Seattle", CancellationToken.None);

        // 4. Assert response
        forecast.City.Should().Be("Seattle");
        forecast.TempC.Should().Be(12);

        // 5. Assert all expected calls were made
        mockHttp.VerifyNoOutstandingExpectation();
        mockHttp.VerifyNoOutstandingRequest();  // no unexpected calls
    }

    [Fact]
    public async Task GetForecastAsync_On500_ThrowsHttpRequestException()
    {
        var mockHttp = new MockHttpMessageHandler();
        mockHttp.When("*").Respond(HttpStatusCode.InternalServerError);

        var client = mockHttp.ToHttpClient();
        client.BaseAddress = new Uri("https://api.weather.example/");

        var sut    = new WeatherClient(client);
        var act    = async () => await sut.GetForecastAsync("Seattle", default);

        await act.Should().ThrowAsync<HttpRequestException>();
    }
}
```

**Key MockHttp matchers:**

| Matcher | Example |
|---|---|
| URL glob | `.When("https://api.example/*")` |
| HTTP method | `.When(HttpMethod.Post, url)` |
| Query string | `.WithQueryString("key", "value")` |
| Request body | `.WithContent("application/json", "{...}")` |
| Headers | `.WithHeaders("Authorization", "Bearer *")` |
| Any remaining | `.When(HttpMethod.Get, "*")` — catch-all fallback |

### WireMock.Net — Loopback HTTP Server

```csharp
// dotnet add package WireMock.Net
using WireMock.Server;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;

public class PaymentGatewayTests : IDisposable
{
    private readonly WireMockServer _server;
    private readonly PaymentClient  _sut;

    public PaymentGatewayTests()
    {
        // Start a WireMock server on a random free port
        _server = WireMockServer.Start();

        var client = new HttpClient { BaseAddress = new Uri(_server.Url!) };
        _sut = new PaymentClient(client);
    }

    [Fact]
    public async Task ChargeAsync_Success_ReturnsTransactionId()
    {
        // Stub the POST /charge endpoint
        _server
            .Given(Request.Create()
                .WithPath("/charge")
                .WithBody(new JsonMatcher(new { Amount = 99.99, Currency = "USD" }))
                .UsingPost())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithBodyAsJson(new { TransactionId = "TXN-001", Success = true }));

        var result = await _sut.ChargeAsync(99.99m, "USD", CancellationToken.None);

        result.Success.Should().BeTrue();
        result.TransactionId.Should().Be("TXN-001");

        // Verify the request was received exactly once
        _server.LogEntries.Should().HaveCount(1);
    }

    [Fact]
    public async Task ChargeAsync_Retry_EventuallySucceeds()
    {
        // Stateful scenario: first call returns 503, second returns 200
        _server
            .Given(Request.Create().WithPath("/charge").UsingPost())
            .InScenario("charge-retry")
            .WillSetStateTo("first-attempted")
            .RespondWith(Response.Create().WithStatusCode(503));

        _server
            .Given(Request.Create().WithPath("/charge").UsingPost())
            .InScenario("charge-retry")
            .WhenStateIs("first-attempted")
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithBodyAsJson(new { TransactionId = "TXN-002", Success = true }));

        var result = await _sut.ChargeWithRetryAsync(99.99m, "USD", CancellationToken.None);

        result.Success.Should().BeTrue();
        _server.LogEntries.Should().HaveCount(2);  // initial 503 + retry 200
    }

    public void Dispose() => _server.Dispose();
}
```

**MockHttp vs WireMock.Net:**

| Aspect | MockHttp | WireMock.Net |
|---|---|---|
| Runs in-process | Yes — no ports opened | No — listens on loopback port |
| Speed | Very fast | Fast (loopback only) |
| Stateful scenarios | No | Yes (`InScenario` / `WhenStateIs`) |
| Request journal / log | No | Yes (`_server.LogEntries`) |
| Response templating | No | Yes (Handlebars templates) |
| Best for | Unit tests of HttpClient-consuming services | Contract tests, integration tests, scenario flows |

---

## xUnit — `ITestOutputHelper` for Diagnostic Logging

`ITestOutputHelper` is xUnit's mechanism for writing diagnostic messages that appear in the test output when a test fails. Unlike `Console.WriteLine`, output written via `ITestOutputHelper` is scoped to the individual test and captured by the runner even in parallel runs.

```csharp
using Xunit;
using Xunit.Abstractions;

public class PaymentServiceTests(ITestOutputHelper output)
{
    // xUnit v2/v3: inject via constructor — primary constructor syntax shown (C# 12+)

    [Fact]
    public async Task ProcessPayment_LogsEachStep()
    {
        output.WriteLine("Starting ProcessPayment test at {0:O}", DateTimeOffset.UtcNow);

        var service = new PaymentService(logger: new XunitLogger(output));
        var request = new PaymentRequest(Amount: 50m, Currency: "GBP");

        output.WriteLine("Sending payment request: {0}", request);
        var result = await service.ProcessAsync(request, CancellationToken.None);

        output.WriteLine("Result: Success={0}, TxId={1}", result.Success, result.TransactionId);
        result.Success.Should().BeTrue();
    }
}
```

**Routing `ILogger<T>` output to `ITestOutputHelper`:**

Teams commonly write a thin `XunitLogger<T>` adapter (or install the `Xunit.Extensions.Logging` package) so that production `ILogger<T>` calls appear in xUnit's output:

```csharp
// Install: dotnet add package Xunit.Extensions.Logging  (community package)
using Microsoft.Extensions.Logging;
using Xunit.Extensions.Logging;

public class OrderWorkflowTests(ITestOutputHelper output)
{
    [Fact]
    public async Task ProcessOrder_LogsWarningOnLowStock()
    {
        // Wire ILogger to xUnit output — messages appear when test fails or -v is set
        ILoggerFactory logFactory = LoggerFactory.Create(b =>
            b.AddXunit(output).SetMinimumLevel(LogLevel.Debug));

        var sut = new OrderWorkflow(logFactory.CreateLogger<OrderWorkflow>());

        await sut.ProcessAsync(new Order { Sku = "RARE-ITEM", Quantity = 100 });
        // If warning was logged, it appears in the test result output
    }
}
```

**`ITestOutputHelper` in fixtures:**

Fixtures cannot accept `ITestOutputHelper` in their constructor (they're created by the framework before the test class). Forward it from the test class instead:

```csharp
public class DatabaseFixture : IAsyncLifetime
{
    // Output forwarded per-test via a property, not the fixture constructor
    public ITestOutputHelper? Output { get; set; }

    public async Task InitializeAsync()
    {
        Output?.WriteLine("Starting container at {0:O}", DateTimeOffset.UtcNow);
        // ...
    }
    public Task DisposeAsync() => Task.CompletedTask;
}

public class OrderTests(DatabaseFixture db, ITestOutputHelper output)
    : IClassFixture<DatabaseFixture>
{
    public OrderTests(DatabaseFixture db, ITestOutputHelper output) : this()
    {
        db.Output = output;  // forward per-test output to the fixture
    }
}
```

---

## Architecture Testing — NetArchTest and ArchUnitNET

Architecture tests enforce structural rules — layering, naming conventions, dependency direction — by inspecting assemblies with reflection. They run as ordinary unit tests and fail the build when someone violates the agreed architecture.

### NetArchTest

```csharp
// dotnet add package NetArchTest.Rules
using NetArchTest.Rules;

public class ArchitectureTests
{
    private const string DomainNs      = "MyApp.Domain";
    private const string AppNs         = "MyApp.Application";
    private const string InfrastructureNs = "MyApp.Infrastructure";
    private const string WebNs         = "MyApp.Web";

    // Domain layer must NOT depend on infrastructure
    [Fact]
    public void Domain_ShouldNot_DependOnInfrastructure()
    {
        var result = Types.InAssembly(typeof(Order).Assembly)
            .That().ResideInNamespace(DomainNs)
            .ShouldNot().HaveDependencyOn(InfrastructureNs)
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            because: string.Join(", ", result.FailingTypeNames ?? []));
    }

    // Application layer should not reference Web layer
    [Fact]
    public void Application_ShouldNot_DependOnWeb()
    {
        var result = Types.InAssembly(typeof(IOrderService).Assembly)
            .That().ResideInNamespace(AppNs)
            .ShouldNot().HaveDependencyOn(WebNs)
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            because: string.Join(", ", result.FailingTypeNames ?? []));
    }

    // All classes in Domain.Entities must be sealed or abstract (no unintentional subclassing)
    [Fact]
    public void DomainEntities_ShouldBe_SealedOrAbstract()
    {
        var result = Types.InAssembly(typeof(Order).Assembly)
            .That()
            .ResideInNamespace($"{DomainNs}.Entities")
            .ShouldNot().BeClasses()  // excludes interfaces and abstract base types
            .Or().Meet(t => !t.IsSealed && !t.IsAbstract)  // OR be unsealed concrete classes
            .GetResult();

        // Alternatively: enforce only sealed
        var sealed_ = Types.InAssembly(typeof(Order).Assembly)
            .That().ResideInNamespace($"{DomainNs}.Entities").And().AreClasses()
            .Should().BeSealed()
            .GetResult();

        sealed_.IsSuccessful.Should().BeTrue(
            because: string.Join(", ", sealed_.FailingTypeNames ?? []));
    }

    // Repository interfaces must end in "Repository"
    [Fact]
    public void RepositoryInterfaces_ShouldFollow_NamingConvention()
    {
        var result = Types.InAssembly(typeof(IOrderRepository).Assembly)
            .That()
            .ImplementInterface(typeof(IRepository<>))
            .And().AreInterfaces()
            .Should().HaveNameEndingWith("Repository")
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            because: string.Join(", ", result.FailingTypeNames ?? []));
    }

    // Controllers must be in the Web namespace
    [Fact]
    public void Controllers_ShouldReside_InWebNamespace()
    {
        var result = Types.InAssembly(typeof(Program).Assembly)
            .That().HaveNameEndingWith("Controller")
            .Should().ResideInNamespace(WebNs)
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            because: string.Join(", ", result.FailingTypeNames ?? []));
    }
}
```

**Common NetArchTest predicates:**

| Predicate | Example |
|---|---|
| `ResideInNamespace` | `.That().ResideInNamespace("MyApp.Domain")` |
| `HaveNameEndingWith` | `.That().HaveNameEndingWith("Service")` |
| `ImplementInterface` | `.That().ImplementInterface(typeof(ICommand))` |
| `Inherit` | `.That().Inherit(typeof(BaseEntity))` |
| `HaveDependencyOn` | `.ShouldNot().HaveDependencyOn("Dapper")` |
| `BeSealed` | `.Should().BeSealed()` |
| `BePublic` / `NotBePublic` | `.Should().NotBePublic()` for value objects |

---

## Real-World Gotchas — Integration and Architecture Testing [community]

### **Testcontainers Requires Docker Socket — Fails on Restricted Linux CI** [community]

Testcontainers connects to the Docker daemon via `/var/run/docker.sock`. Many restricted CI environments (GitHub Actions default runners, Bitbucket Pipelines) expose the socket but some hardened CI images do not. WHY it causes problems: tests fail at container startup with `Cannot connect to the Docker daemon` — not a test logic failure, but an infrastructure one. Fix: set `DOCKER_HOST` or `TESTCONTAINERS_HOST_OVERRIDE` env vars; use Ryuk resource reuse (`TESTCONTAINERS_RYUK_DISABLED=true`) when the container should persist across runs; or switch to GitHub Actions with `services:` blocks for the database container.

```yaml
# GitHub Actions: use service containers instead of Testcontainers when needed
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: tester
          POSTGRES_PASSWORD: pw
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

### **MockHttp `BaseAddress` Mismatch Silently Falls Through to Catch-All** [community]

`MockHttpMessageHandler` matches requests by full URL. If the `HttpClient.BaseAddress` and the registered `When(url)` pattern use different schemes, trailing slashes, or path segments, requests silently fall through to any catch-all `When("*")` stub instead of the intended one. WHY it causes problems: the test passes with the wrong status code or response body; CI reports green, production is broken. Fix: always log unmatched requests explicitly with `mockHttp.Fallback.Throw(new Exception("Unexpected request"))` during development.

```csharp
// RISKY: BaseAddress trailing slash and path are combined differently than expected
client.BaseAddress = new Uri("https://api.example.com/v1/");  // trailing slash
mockHttp.When("https://api.example.com/v1/orders");  // works
mockHttp.When("https://api.example.com/orders");     // NEVER matches — wrong base

// SAFE: set catch-all to throw so missed stubs are loud failures
var mockHttp = new MockHttpMessageHandler();
mockHttp.Fallback.Throw(new InvalidOperationException("Unexpected HTTP call — add a stub"));
```

### **WireMock.Net `WireMockServer.Start()` Port Conflicts on Parallel Test Runs** [community]

`WireMockServer.Start()` without arguments picks a random free port via `WireMockServer.Start(port: 0)` — which is correct. Teams that hard-code a port (e.g., `WireMockServer.Start(9091)`) get `AddressAlreadyInUse` errors when two test classes run in parallel. WHY it causes problems: tests fail non-deterministically depending on which class starts first, making root cause hard to identify. Fix: always use `WireMockServer.Start()` (random port) and construct the `HttpClient.BaseAddress` from `_server.Url`.

```csharp
// BAD: hard-coded port — breaks under parallel runs
_server = WireMockServer.Start(9091);
var client = new HttpClient { BaseAddress = new Uri("http://localhost:9091/") };

// GOOD: random port; read URL from server instance
_server = WireMockServer.Start();
var client = new HttpClient { BaseAddress = new Uri(_server.Url!) };
```

### **NetArchTest Reflection Overhead Adds 5–30 Seconds on Large Assemblies** [community]

NetArchTest loads every type in the target assembly (and its transitive dependencies) via reflection to build the type graph. On assemblies with thousands of types or large transitive dependency trees, this takes 5–30 seconds per test class. WHY it causes problems: the architecture test suite, which should be fast, becomes the slowest part of `dotnet test`, discouraging teams from running it. Fix: place all architecture tests in a single `[Collection("Architecture")]` class so the assembly is loaded only once; use `typeof(SomeType).Assembly` rather than string-based assembly discovery; and run architecture tests in a separate CI step that doesn't block developer feedback.

```csharp
// GOOD: share the loaded assembly across all architecture tests in one class
// Instead of multiple test classes each loading the assembly separately,
// put all NetArchTest assertions in a single class — one reflection pass

[Collection("Architecture")]  // Serialize with other arch tests if needed
public class CleanArchitectureTests
{
    // Cache the assembly reference — reflection runs once per class instantiation
    private static readonly System.Reflection.Assembly DomainAssembly =
        typeof(Order).Assembly;

    [Fact]
    public void Domain_ShouldNot_ReferenceInfrastructure() { /* ... */ }

    [Fact]
    public void Domain_ShouldNot_ReferenceApplication()    { /* ... */ }

    [Fact]
    public void Entities_ShouldBe_Sealed()                 { /* ... */ }
}
```

---

## Anti-Patterns Quick Reference — Infrastructure and Architecture Testing

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `new HttpClient()` in unit test with live network call | Flaky (network-dependent), slow, has real side effects | Use MockHttp or WireMock.Net to intercept all HTTP calls |
| MockHttp `When("*")` catch-all without `mockHttp.Fallback.Throw(...)` | Missed stubs return `null` silently — tests pass with wrong data | Set fallback to throw so unmatched requests are loud failures |
| `WireMockServer.Start(hardcodedPort)` | Port conflicts under parallel test runs | Always use `WireMockServer.Start()` (random port) |
| One test class per architecture rule with NetArchTest | Assembly loaded via reflection for every class — O(classes * assembly size) startup | Consolidate all architecture assertions into one `[Collection]` test class |
| Testcontainers with no `DisposeAsync` | Container continues running after the test suite, consuming memory and ports | Always implement `IAsyncLifetime.DisposeAsync` on the fixture |
| `Console.WriteLine` in xUnit tests for diagnostics | Output lost in parallel runs; not captured by the runner | Use `ITestOutputHelper.WriteLine` — scoped to the test, captured on failure |

---

## Code Coverage — Coverlet and ReportGenerator

Code coverage measures which lines, branches, and methods are exercised by tests. In .NET, **Coverlet** is the standard open-source collector; **ReportGenerator** converts raw Cobertura XML into browsable HTML. Both are free and cross-platform.

### Setup and collection (DataCollector approach — recommended)

`dotnet new xunit` already includes `coverlet.collector`. Run tests and collect coverage in one step:

```bash
# Produces TestResults/{guid}/coverage.cobertura.xml
dotnet test --collect:"XPlat Code Coverage"

# Force the output format and merge results from multiple test projects
dotnet test --collect:"XPlat Code Coverage" \
  -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura
```

The `"XPlat Code Coverage"` argument is a friendly name for the Coverlet data collector. Use `"Code Coverage"` (without quotes) to invoke the .NET built-in collector, which produces a binary `.coverage` file (VS-only format) instead of Cobertura XML.

### Generate an HTML report with ReportGenerator

```bash
# Install globally (once per machine)
dotnet tool install -g dotnet-reportgenerator-globaltool

# Generate from the XML produced by dotnet test
reportgenerator \
  -reports:"**/TestResults/**/coverage.cobertura.xml" \
  -targetdir:"coveragereport" \
  -reporttypes:Html
```

Open `coveragereport/index.html` to browse per-file line/branch/method coverage. Common additional formats: `Cobertura`, `lcov`, `Badges`, `MarkdownSummaryGithub`.

### MSBuild integration — coverlet.msbuild

For projects already using MSBuild-based builds or where the DataCollector approach is unavailable:

```xml
<!-- Add to your test .csproj -->
<ItemGroup>
  <PackageReference Include="coverlet.msbuild" Version="6.*" />
</ItemGroup>
```

```bash
dotnet test /p:CollectCoverage=true \
            /p:CoverletOutputFormat=cobertura \
            /p:CoverletOutput=./coverage.cobertura.xml
```

### CI threshold enforcement — fail build below N%

```bash
# Fail if line coverage drops below 80% or branch coverage below 70%
dotnet test --collect:"XPlat Code Coverage" \
  -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Threshold=80 \
     DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.ThresholdType=line \
     DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.ThresholdStat=Total

# MSBuild equivalent
dotnet test /p:CollectCoverage=true \
            /p:Threshold=80 \
            /p:ThresholdType=line \
            /p:ThresholdStat=total
```

### dotnet-coverage tool — built-in alternative

`.NET 8+` ships `dotnet-coverage` as a cross-platform global tool that wraps the built-in collector and can merge, convert, and snapshot coverage:

```bash
dotnet tool install -g dotnet-coverage

# Collect and output Cobertura directly (no VS binary format)
dotnet-coverage collect "dotnet test" -f cobertura -o coverage.cobertura.xml

# Merge coverage from multiple test runs into one report
dotnet-coverage merge -f cobertura -o merged.xml ./test1/coverage.xml ./test2/coverage.xml
```

**Coverlet vs dotnet-coverage comparison:**

| Feature | coverlet.collector | dotnet-coverage |
|---|---|---|
| Output format | Cobertura XML (human-readable) | Binary `.coverage` or Cobertura with flag |
| Integration | `--collect:"XPlat Code Coverage"` | Separate CLI invocation wrapping `dotnet test` |
| Threshold enforcement | Built-in MSBuild props | Requires external check on exit code |
| Multi-run merge | Manual (ReportGenerator can merge) | `dotnet-coverage merge` |
| .NET Framework support | Yes | Partial (Windows only for binary format) |

---

## Stryker.NET — Mutation Testing

Mutation testing evaluates test suite _quality_ by injecting artificial bugs (mutants) into the production code and verifying that your tests catch them. A **mutation score of 80%+** is a reasonable target for business-critical code. High line coverage does not guarantee effective tests; mutation testing surfaces gaps in assertions.

### Installation and quickstart

```bash
# Global install (per machine)
dotnet tool install -g dotnet-stryker

# Project-local install (reproducible CI)
dotnet new tool-manifest    # once per repo
dotnet tool install dotnet-stryker

# Run from your test project directory — no config needed for most projects
dotnet stryker
```

Stryker discovers the source project automatically from the test project's `<ProjectReference>`. The HTML report opens in the browser after the run.

### stryker-config.json — key options

```json
{
  "stryker-config": {
    "project": "MyApp.csproj",
    "mutation-level": "Standard",
    "thresholds": {
      "high": 80,
      "low": 60,
      "break": 0
    },
    "coverage-analysis": "perTest",
    "concurrency": 4,
    "reporter": ["html", "progress"],
    "mutate": [
      "src/**/*.cs",
      "!src/**/*.Generated.cs",
      "!src/**/Migrations/**"
    ],
    "ignore-methods": [
      "ToString",
      "GetHashCode"
    ]
  }
}
```

**Threshold semantics:**
- `high` (default 80): score above this → green; below → yellow in the report
- `low` (default 60): score below this → red in the report
- `break` (default 0): score **at or below** this → non-zero exit code, fails CI build

**`mutation-level` options:**
- `Basic` — arithmetic, equality operators only (fastest)
- `Standard` (default) — adds string, boolean, and LINQ mutations
- `Advanced` — adds bitwise, assignment mutations
- `Complete` — all mutators including regex and initializer mutations (slowest)

### Incremental analysis — `--since`

```bash
# Only mutate code changed since the main branch — dramatically faster for PRs
dotnet stryker --since:main

# Store baseline in .stryker-dashboard (disk) so unchanged mutant results are reused
dotnet stryker --with-baseline:main
```

### Coverage analysis modes

`coverage-analysis` tells Stryker which tests to run per mutant:

| Mode | Behaviour | Speed |
|---|---|---|
| `off` | Run all tests for every mutant | Slowest; safest |
| `perTest` (default) | Run only tests that cover each mutant (via coverage data) | ~3–10× faster |
| `perTestInIsolation` | Same as perTest but re-initialises static state between tests | Slower than perTest; use for static state side effects |
| `all` | Batch mutants, run all tests once per batch | Faster than off; less accurate |

### Reading the HTML report — mutant statuses

| Status | Meaning |
|---|---|
| **Killed** | A test caught the mutant — good |
| **Survived** | No test caught the mutant — gap in assertions |
| **No Coverage** | No test runs the mutated line at all |
| **Timeout** | Mutant caused an infinite loop (counted as killed) |
| **Compile Error** | Stryker generated an invalid mutant (internal; not your fault) |

---

## Test Ordering — xUnit, NUnit, MSTest

Unit tests should ideally be order-independent. When integration tests genuinely require sequencing (e.g., a create-then-read-then-delete workflow), use the ordering mechanisms below. Always pair ordering with disabled parallelism — ordering only controls _start_ sequence; parallel execution can still overlap tests.

### xUnit — `ITestCaseOrderer` with `TestPriorityAttribute`

xUnit provides no built-in ordering attribute; you implement `ITestCaseOrderer` yourself (or use the community `xunit.extensions.ordering` package for a simpler API).

```csharp
// 1. Define the attribute
[AttributeUsage(AttributeTargets.Method, AllowMultiple = false)]
public class TestPriorityAttribute(int priority) : Attribute
{
    public int Priority { get; } = priority;
}

// 2. Implement ITestCaseOrderer
using Xunit.Abstractions;
using Xunit.Sdk;

public class PriorityOrderer : ITestCaseOrderer
{
    public IEnumerable<TTestCase> OrderTestCases<TTestCase>(
        IEnumerable<TTestCase> testCases) where TTestCase : ITestCase
    {
        var sorted = new SortedDictionary<int, List<TTestCase>>();
        foreach (var tc in testCases)
        {
            int priority = tc.TestMethod.Method
                .GetCustomAttributes(typeof(TestPriorityAttribute).AssemblyQualifiedName!)
                .FirstOrDefault()
                ?.GetNamedArgument<int>(nameof(TestPriorityAttribute.Priority)) ?? 0;

            if (!sorted.TryGetValue(priority, out var list))
                sorted[priority] = list = [];
            list.Add(tc);
        }

        foreach (var tc in sorted.Values.SelectMany(l => l.OrderBy(t => t.TestMethod.Method.Name)))
            yield return tc;
    }
}

// 3. Apply to a test class — disable parallelism first
[TestCaseOrderer(
    ordererTypeName: "MyProject.Tests.PriorityOrderer",
    ordererAssemblyName: "MyProject.Tests")]
public class OrderedIntegrationTests
{
    [Fact, TestPriority(-10)]
    public async Task Step1_CreateResource() { /* ... */ }

    [Fact, TestPriority(0)]
    public async Task Step2_ReadResource() { /* ... */ }

    [Fact, TestPriority(10)]
    public async Task Step3_DeleteResource() { /* ... */ }
}
```

**Disable parallelism across test classes** (assembly-level, typically in `AssemblyInfo.cs`):

```csharp
[assembly: CollectionBehavior(DisableTestParallelization = true)]
```

To control the order of test _collections_ (not just methods within a class), implement `ITestCollectionOrderer` and apply `[assembly: TestCollectionOrderer(...)]`.

### NUnit — `[Order]` attribute

NUnit provides `[Order(n)]` directly on test methods. Lower values run first. Tests without `[Order]` run last in undefined order. NUnit runs tests sequentially within a single thread by default; the `[Order]` attribute alone is sufficient without additional parallelism configuration.

```csharp
using NUnit.Framework;

[TestFixture]
public class OrderedNUnitTests
{
    [Test, Order(-5)]
    public void Step1_SetupDatabase() { /* runs first */ }

    [Test, Order(0)]
    public void Step2_SeedData() { /* runs second */ }

    [Test, Order(5)]
    public void Step3_VerifyAndCleanup() { /* runs third */ }
}
```

### MSTest — alphabetical order with `OrderTestsByNameInClass`

MSTest 3.6+ adds a runsettings option that sorts methods by name within the class:

```xml
<!-- myproject.runsettings -->
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
  <MSTest>
    <OrderTestsByNameInClass>true</OrderTestsByNameInClass>
  </MSTest>
</RunSettings>
```

```bash
dotnet test --settings myproject.runsettings
```

A common naming convention is to prefix test methods with numeric step numbers: `Test01_Create`, `Test02_Read`, `Test03_Delete`.

---

## .NET Aspire Integration Testing

.NET Aspire provides `DistributedApplicationTestingBuilder` — an xUnit/NUnit/MSTest-compatible test harness that starts the full Aspire AppHost (all containers, services, and resources) inside the test process. This replaces ad-hoc `docker-compose` scripts and Testcontainers boilerplate for Aspire-based systems.

### Package setup

```xml
<!-- In your dedicated test project (.csproj) -->
<ItemGroup>
  <!-- Reference the AppHost project so the test can discover resources -->
  <ProjectReference Include="..\MyApp.AppHost\MyApp.AppHost.csproj" />
  <PackageReference Include="Aspire.Hosting.Testing" Version="9.*" />
  <PackageReference Include="xunit"                   Version="2.*" />
  <PackageReference Include="xunit.runner.visualstudio" Version="2.*" />
</ItemGroup>
```

### Writing an Aspire integration test

```csharp
using Aspire.Hosting;
using Aspire.Hosting.Testing;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using Xunit;

public class AppHostTests : IAsyncLifetime
{
    private DistributedApplication? _app;

    public async Task InitializeAsync()
    {
        // Build and start the entire Aspire AppHost
        var appHost = await DistributedApplicationTestingBuilder
            .CreateAsync<Projects.MyApp_AppHost>();

        // Optionally override resources — e.g. swap real DB for Testcontainers
        // appHost.Services.ConfigureHttpClientDefaults(b => b.AddStandardResilienceHandler());

        _app = await appHost.BuildAsync();
        await _app.StartAsync();
    }

    public async Task DisposeAsync()
    {
        if (_app is not null)
            await _app.DisposeAsync();
    }

    [Fact]
    public async Task ApiService_ReturnsHealthy()
    {
        // Wait for the "apiservice" resource to reach Running state
        var resourceNotifications = _app!.Services
            .GetRequiredService<ResourceNotificationService>();

        await resourceNotifications.WaitForResourceAsync(
            "apiservice",
            KnownResourceStates.Running)
            .WaitAsync(TimeSpan.FromSeconds(30));

        // Get an HttpClient pre-configured with the service's base address
        using var client = _app.CreateHttpClient("apiservice");

        var response = await client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ApiService_GetWeatherForecast_ReturnsFiveItems()
    {
        var resourceNotifications = _app!.Services
            .GetRequiredService<ResourceNotificationService>();

        await resourceNotifications.WaitForResourceAsync(
            "apiservice", KnownResourceStates.Running)
            .WaitAsync(TimeSpan.FromSeconds(30));

        using var client = _app.CreateHttpClient("apiservice");
        var forecasts = await client.GetFromJsonAsync<WeatherForecast[]>("/weatherforecast");

        Assert.NotNull(forecasts);
        Assert.Equal(5, forecasts.Length);
    }
}
```

**Key API surface:**

| Member | Purpose |
|---|---|
| `DistributedApplicationTestingBuilder.CreateAsync<TAppHost>()` | Bootstraps the AppHost; returns a builder for overriding services |
| `builder.BuildAsync()` | Materialises `DistributedApplication` (does not start resources yet) |
| `app.StartAsync()` | Starts all resources (containers, services); waits for initial health |
| `app.CreateHttpClient("resourceName")` | Returns `HttpClient` with `BaseAddress` set to the named resource's endpoint |
| `ResourceNotificationService.WaitForResourceAsync(name, state)` | Async wait until a resource reaches a given state |
| `app.GetEndpoint("resourceName", "endpointName")` | Returns the `Uri` for a specific named endpoint of a resource |
| `app.DisposeAsync()` | Stops all resources and tears down containers |

---

## Real-World Gotchas — Code Coverage, Mutation Testing, and Test Ordering [community]

### **Coverlet DataCollector vs MSBuild Produce Different Instrumentation** [community]

`coverlet.collector` (DataCollector, `--collect:"XPlat Code Coverage"`) instruments assemblies at _run time_ via the VSTest platform. `coverlet.msbuild` instruments at _compile time_. WHY it causes problems: the two modes can report different line counts, especially for auto-generated code and compiler-synthesised state machines (async methods, iterators). MSBuild instrumentation is tighter but more fragile with AOT or trimming. DataCollector mode is recommended for most projects. Fix: choose one mode per project and stick to it; mixing them in a single solution produces incoherent merged reports.

```bash
# DataCollector mode — recommended; no .csproj changes needed beyond the package reference
dotnet test --collect:"XPlat Code Coverage"

# MSBuild mode — compile-time instrumentation; add coverlet.msbuild package
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
```

### **Stryker Timeout Loops on Complex `async` Code With `await foreach`** [community]

Stryker's default `additional-timeout` (5 000 ms) is relative to the median test run time. Long-running integration tests or async pipelines that use `await foreach` + infinite `IAsyncEnumerable` producers can cause mutants to trigger the timeout repeatedly, classifying every mutant as `Timeout` (which counts as killed). WHY it causes problems: the mutation score looks artificially high because every mutant "times out" rather than surviving. Fix: exclude infinite-pipeline code from mutation with `!` patterns, raise `additional-timeout`, or set `coverage-analysis: "off"` for those test classes.

```json
{
  "stryker-config": {
    "mutate": [
      "src/**/*.cs",
      "!src/**/StreamProcessing/**"
    ],
    "additional-timeout": 10000
  }
}
```

### **xUnit `ITestCaseOrderer` Type Name Breaks in xUnit v3** [community]

xUnit v2's `ITestCaseOrderer` uses `GetCustomAttributes(assemblyQualifiedName)` to look up attributes. In xUnit v3, the reflection API changed: attribute lookup now uses the full type name without version/culture tokens. WHY it causes problems: orderers that worked in v2 silently stop ordering in v3 — tests run in undefined order without any error message. Fix: when migrating to xUnit v3, verify the `ordererTypeName` and `ordererAssemblyName` strings still resolve; add a constructor-time assertion or log from the orderer to confirm it is being called.

```csharp
// xUnit v3: use the full assembly-qualified name WITHOUT version tokens
// BAD (v2 style — includes version/culture tokens in some reflection paths):
// "MyProject.Tests.PriorityOrderer, MyProject.Tests, Version=1.0.0.0, Culture=neutral"
// GOOD: simple type + assembly only
[TestCaseOrderer(
    ordererTypeName:     "MyProject.Tests.PriorityOrderer",
    ordererAssemblyName: "MyProject.Tests")]
public class OrderedTests { /* ... */ }
```

### **Aspire Test Startup Latency — `WaitForResourceAsync` Is Required, Not Optional** [community]

`_app.StartAsync()` returns as soon as the Aspire orchestrator has _submitted_ start requests for all resources. Containers are not yet running and HTTP endpoints are not yet listening. WHY it causes problems: `CreateHttpClient("apiservice").GetAsync("/health")` immediately after `StartAsync()` returns `Connection refused` — not a test logic failure, but a timing one. Fix: always `await WaitForResourceAsync("resourceName", KnownResourceStates.Running)` with a `WaitAsync` timeout before issuing any HTTP call. If the timeout is too short on slow CI runners, increase it or set it via an environment variable.

```csharp
// WRONG: races against container startup
await _app.StartAsync();
using var client = _app.CreateHttpClient("apiservice");
var response = await client.GetAsync("/health");  // May get Connection refused

// CORRECT: wait for Running state before any request
await _app.StartAsync();
var notifications = _app.Services.GetRequiredService<ResourceNotificationService>();
await notifications
    .WaitForResourceAsync("apiservice", KnownResourceStates.Running)
    .WaitAsync(TimeSpan.FromSeconds(60));  // generous timeout for slow CI
using var client = _app.CreateHttpClient("apiservice");
var response = await client.GetAsync("/health");  // always reachable now
```

---

## .NET 10 — MTP Native Support in `dotnet test` via `global.json`

Starting with .NET 10 SDK, `dotnet test` natively supports Microsoft.Testing.Platform (MTP) without wrapping the test project as an executable or using a separate runner entry point. Enable it solution-wide by adding a `test` section to `global.json`:

```json
{
  "sdk": { "version": "10.0.100" },
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

With this setting, `dotnet test` routes all test discovery and execution through MTP instead of VSTest. All MTP extensions (Retry, Hot Reload, Crash/Hang Dump, code coverage) work without changing project files.

**Before .NET 10 — the pre-MTP workflow:**

```bash
# Old: dotnet test used VSTest host; MTP projects ran via dotnet run
dotnet test MyTests/MyTests.csproj                   # VSTest path
dotnet run --project MyTests/MyTests.csproj -- --list-tests  # MTP path (workaround)

# New (.NET 10): dotnet test works for both VSTest and MTP projects
dotnet test MyTests/MyTests.csproj                   # MTP used when global.json opt-in present
dotnet test MySolution.sln --filter "Category=Unit"  # solution-level filter works unchanged
```

**Compatibility matrix:**

| Framework | MTP support | `dotnet test` .NET 10 native |
|---|---|---|
| xUnit v3 | Yes (MTP only — no VSTest) | Yes |
| MSTest v3+ | Yes (opt-in `EnableMSTestRunner`) | Yes |
| NUnit 4.x | Yes (via `NUnit.TestAdapter` 5+) | Yes |
| TUnit | Yes (MTP native) | Yes |

> **Source:** learn.microsoft.com/dotnet/core/whats-new/dotnet-10/sdk — "Support for Microsoft.Testing.Platform (MTP) in `dotnet test`"

---

## xUnit v3 — `TestContext` Static Diagnostic API

xUnit v3 exposes a static `TestContext.Current` property that makes test metadata and cancellation available anywhere in the call stack without constructor injection. This is a major ergonomics improvement for deeply nested helper methods and shared utilities that previously needed `ITestOutputHelper` to be threaded through every method.

```csharp
using Xunit;

public class OrderProcessingTests
{
    [Fact]
    public async Task ProcessOrder_Succeeds()
    {
        // TestContext.Current is always set on the test thread
        var ctx = TestContext.Current;

        // Write diagnostic output — same as ITestOutputHelper.WriteLine
        ctx.SendDiagnosticMessage("Starting order processing test at {0}", DateTime.UtcNow);

        // CancellationToken from framework — honours test timeout + runner shutdown
        var order = await OrderService.ProcessAsync(OrderBuilder.Default(), ctx.CancellationToken);

        Assert.Equal(OrderStatus.Processed, order.Status);
    }
}

// Deep helper — no need to pass ITestOutputHelper as a parameter
public static class TestHelpers
{
    public static async Task SeedDatabaseAsync(AppDbContext db)
    {
        // Access output and cancellation from anywhere on the test thread
        var ctx = TestContext.Current;
        ctx?.SendDiagnosticMessage("Seeding database with test data...");

        await db.Orders.AddRangeAsync(OrderFactory.CreateMany(10));
        await db.SaveChangesAsync(ctx?.CancellationToken ?? CancellationToken.None);

        ctx?.SendDiagnosticMessage("Database seed complete — {0} orders inserted", 10);
    }
}
```

**Key `TestContext` members:**

| Member | Purpose |
|---|---|
| `TestContext.Current` | Static — returns the current test's context; `null` outside a test |
| `ctx.CancellationToken` | Cancelled when test timeout fires or runner shuts down |
| `ctx.SendDiagnosticMessage(format, args)` | Writes to test output (equivalent to `ITestOutputHelper.WriteLine`) |
| `ctx.Test` | Metadata: test class, method name, display name, traits |
| `ctx.TestState` | `Running`, `Passed`, `Failed`, `Skipped` — read after act phase to branch teardown logic |

> **Gotcha [community]:** `TestContext.Current` is set on the synchronous continuation that xUnit dispatches. If you `await` and continue on a different `SynchronizationContext`, `Current` may return `null`. Always capture `var ctx = TestContext.Current` at the start of the test method and pass `ctx` to helpers rather than calling `TestContext.Current` inside the helper after an `await`.

---

## TUnit — `[Timeout]` Attribute and Per-Test Cancellation

TUnit's parallel-by-default execution model makes test-level timeouts a first-class concern. The `[Timeout]` attribute accepts a duration in milliseconds and causes the test to fail (not just cancel) if it does not complete within that duration. Unlike xUnit's runner-level timeout, TUnit `[Timeout]` is composable — you can stack it with `[Retry]` and it applies per attempt, not across all retries.

```csharp
using TUnit.Core;
using TUnit.Assertions;
using TUnit.Assertions.Extensions;

// 5-second timeout on a single test
[Test]
[Timeout(5_000)]
public async Task FetchExternalRate_CompletesWithinSLA()
{
    var rate = await ExchangeRateClient.GetAsync("USD", "EUR");
    await Assert.That(rate).IsGreaterThan(0m);
}

// Timeout + Retry: each attempt has its own 3-second budget
[Test]
[Timeout(3_000)]
[Retry(3)]
public async Task ProcessQueue_DrainsFiveItems()
{
    var processed = await QueueProcessor.DrainAsync(count: 5);
    await Assert.That(processed).IsEqualTo(5);
}

// Assembly-wide timeout default: set in test class or assembly attribute
[assembly: Timeout(10_000)]  // 10 s fallback for any test without its own [Timeout]

// Access the injected CancellationToken that [Timeout] drives
[Test]
[Timeout(2_000)]
public async Task StreamData_HonoursTimeout(CancellationToken cancellationToken)
{
    // TUnit injects a CT linked to the [Timeout] deadline
    await foreach (var chunk in DataStream.ReadAsync(cancellationToken))
    {
        await ProcessChunkAsync(chunk, cancellationToken);
    }
}
```

**Combining `[Timeout]` with `[NotInParallel]` for sequential integration tests:**

```csharp
// Sequential group with per-test budget prevents suite-level timeout from masking hangs
[Test]
[NotInParallel("DatabaseMigration")]
[Timeout(15_000)]
public async Task RunMigration_V12_Succeeds()
{
    var result = await MigrationRunner.ApplyAsync("V12");
    await Assert.That(result.Applied).IsTrue();
}

[Test]
[DependsOn(nameof(RunMigration_V12_Succeeds))]
[NotInParallel("DatabaseMigration")]
[Timeout(5_000)]
public async Task Schema_HasNewColumn()
{
    var columns = await SchemaInspector.GetColumnsAsync("orders");
    await Assert.That(columns).Contains("discount_code");
}
```

> **Gotcha [community]:** `[Timeout]` on TUnit uses `CancellationToken` cancellation internally, which surfaces as `OperationCanceledException`. If your code swallows `OperationCanceledException` (e.g., in a broad `catch (Exception)` block), the test may appear to hang until the runner's global timeout fires rather than failing at the `[Timeout]` boundary. Always re-throw `OperationCanceledException` or use `catch (Exception ex) when (ex is not OperationCanceledException)`.

---

## C# 14 `extension` Blocks as Test Builder Helpers

C# 14 extension blocks are particularly ergonomic for test builder/assertion helper patterns. Instead of the classic `TestExtensions.cs` static class with `this`-parameter methods, an `extension` block co-locates the test helpers with a clear receiver type and can add both instance methods **and** instance properties — useful for fluent builders and custom assertion chains.

```csharp
// Classic approach — scattered static class, verbose invocation
public static class OrderTestExtensions
{
    public static Order WithStatus(this Order o, string status)
        => o with { Status = status };

    public static bool IsExpired(this Order o)
        => o.ExpiresAt < DateTime.UtcNow;
}

// C# 14 extension block — groups all Order test helpers together
extension(Order order) // instance receiver named 'order'
{
    // Instance extension property — no () needed at call site
    public bool IsExpiredForTest => order.ExpiresAt < DateTime.UtcNow;

    // Instance extension method — builder-style mutation for test setup
    public Order WithStatus(string status) => order with { Status = status };

    // Static extension method — factory for default test instances
    public static Order DefaultTest() => new(
        Id: 1,
        CustomerId: 42,
        Status: "Pending",
        Total: 99.99m,
        ExpiresAt: DateTime.UtcNow.AddDays(30));
}

// Usage in xUnit test — reads as fluent production-code style
[Fact]
public void ShippedOrder_IsNotExpired()
{
    var order = Order.DefaultTest().WithStatus("Shipped");

    Assert.False(order.IsExpiredForTest);
    Assert.Equal("Shipped", order.Status);
}

// Using the field keyword for a lazy-computed test fixture property
// (test helper class, not production code — field keyword avoids a backing field declaration)
public class OrderTestBuilder
{
    public string Status { get; set; } = "Pending";
    public decimal Total { get; set; } = 0m;

    // field keyword: compiler synthesises the backing field; get/set adds custom logic
    public IReadOnlyList<string> Tags
    {
        get => field ??= [];          // lazy init — no explicit backing field needed
        set => field = value.ToList().AsReadOnly();
    }

    public Order Build() => new(
        Id: Random.Shared.Next(1, 10_000),
        CustomerId: 1,
        Status: Status,
        Total: Total,
        ExpiresAt: DateTime.UtcNow.AddDays(1));
}
```

> **Gotcha [community]:** The C# 14 `extension` block syntax (`extension(ReceiverType receiver) { ... }`) is only valid in `static` classes. If you place an `extension` block in a non-static class you get `CS9208`. Test helper classes that mix extension blocks with regular static helper methods should be declared `static` — which is already the idiomatic pattern for test extensions.

---

## Anti-Patterns Quick Reference — Coverage, Mutation, and Ordering

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Treating 100% line coverage as a quality gate | High coverage does not mean good assertions — tests may cover lines without asserting anything | Use mutation testing (Stryker) to measure assertion effectiveness |
| Running Stryker on all code with `mutation-level: Complete` in CI | Extremely slow (hours on mid-sized projects) — blocks developer feedback | Use `Standard` level on PRs; `Advanced` or `Complete` only on scheduled nightly runs |
| Mixing `coverlet.collector` and `coverlet.msbuild` in the same solution | Incoherent merged reports — line counts differ per mode | Pick one mode per solution; DataCollector (`--collect`) is the simpler default |
| Writing xUnit tests that assume execution order without `ITestCaseOrderer` | xUnit runs tests within a class in reflection-defined order, which varies by platform | Either make tests fully independent or apply `ITestCaseOrderer` + `[TestPriority]` |
| Calling `CreateHttpClient` before `WaitForResourceAsync` in Aspire tests | Race condition — container may not be listening yet, producing flaky `Connection refused` | Always await `WaitForResourceAsync` + `WaitAsync(timeout)` before first HTTP call |
| Using `dotnet-reportgenerator` with a single test project's XML | Multi-project solutions have multiple XML files; missing files skews coverage down | Use glob pattern `"**/coverage.cobertura.xml"` to collect all test project outputs |
