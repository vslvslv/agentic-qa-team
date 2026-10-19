# NBomber Patterns & Best Practices (C#)
<!-- lang: C# | tool: NBomber 5.x | date: 2026-04-28 -->
<!-- official: nbomber.com/docs, github.com/PragmaticFlow/NBomber -->

---

## Core Principles

1. **Scenarios are the unit of load.** Each scenario has its own load simulation and reports independently. Name scenarios clearly — they appear in the report.
2. **Auth in process init, not per iteration.** Obtain tokens before `Scenario.Create` — not inside the step function — to avoid hammering the auth endpoint during load.
3. **Use `RampingInject` + `Inject` + `RampingInject` for realistic profiles.** Ramp up slowly, sustain, ramp down. Never jump straight to max load.
4. **Set thresholds to fail CI automatically.** `WithThresholds` makes the runner exit with code `1` on breach.
5. **One `HttpClient` per process, not per VU.** `HttpClient` is thread-safe; sharing it is correct.

---

## Load Simulations

```csharp
// Ramp up → sustain → ramp down (recommended for most load tests)
Simulation.RampingInject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
Simulation.Inject(rate: 50,        interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(2)),
Simulation.RampingInject(rate: 0,  interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))

// Constant VUs (closed-model — use only when VU count matters, not RPS)
Simulation.KeepConstant(copies: 50, during: TimeSpan.FromMinutes(2))

// Stress: ramp past expected capacity to find breakpoint
Simulation.RampingVUsers(copies: 200, during: TimeSpan.FromMinutes(5))

// Smoke (single user, short)
Simulation.KeepConstant(copies: 1, during: TimeSpan.FromSeconds(30))
```

`RampingInject` / `Inject` use the **open model** (arrival rate independent of response time). Prefer this for API load tests. `KeepConstant` uses the **closed model** — correct when concurrency rather than throughput is the constraint.

---

## Full Script with Auth, Thresholds, and Report

```csharp
// PerfTests/Program.cs
using NBomber.CSharp;
using NBomber.Http.CSharp;
using NBomber.Contracts;
using System.Net.Http.Json;

var baseUrl      = Environment.GetEnvironmentVariable("API_URL")           ?? "http://localhost:3001";
var userEmail    = Environment.GetEnvironmentVariable("E2E_USER_EMAIL")    ?? "admin@example.com";
var userPassword = Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";

// Auth once at process startup
using var http = new HttpClient { BaseAddress = new Uri(baseUrl) };
var loginRes   = await http.PostAsJsonAsync("/api/auth/login", new { email = userEmail, password = userPassword });
loginRes.EnsureSuccessStatusCode();
var loginBody  = await loginRes.Content.ReadFromJsonAsync<LoginResponse>();
http.DefaultRequestHeaders.Authorization =
    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", loginBody!.Token);

// Scenario: GET /api/users
var getUsersScenario = Scenario.Create("get_users", async context =>
{
    var req = Http.CreateRequest("GET", "/api/users");
    return await Http.Send(http, req);
})
.WithWarmUpDuration(TimeSpan.FromSeconds(5))
.WithLoadSimulations(
    Simulation.RampingInject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
    Simulation.Inject(rate: 50,        interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(2)),
    Simulation.RampingInject(rate: 0,  interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
);

// Scenario: POST /api/orders (write-heavy)
var createOrderScenario = Scenario.Create("create_order", async context =>
{
    var req = Http.CreateRequest("POST", "/api/orders")
        .WithJsonBody(new { productId = 1, quantity = 1 });
    return await Http.Send(http, req);
})
.WithWarmUpDuration(TimeSpan.FromSeconds(5))
.WithLoadSimulations(
    Simulation.RampingInject(rate: 5, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
    Simulation.Inject(rate: 20,       interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(2)),
    Simulation.RampingInject(rate: 0, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
);

var stats = NBomberRunner
    .RegisterScenarios(getUsersScenario, createOrderScenario)
    .WithReportFolder("./reports/nbomber")
    .WithReportFormats(ReportFormat.Html, ReportFormat.Csv, ReportFormat.Md)
    .WithThresholds(
        // GET /api/users: p95 < 200ms, error rate < 1%
        Threshold.Create("get_users",    s => s.Ok.Latency.Percent95 < 200),
        Threshold.Create("get_users",    s => s.FailPercent < 1.0),
        // POST /api/orders: p95 < 500ms, error rate < 1%
        Threshold.Create("create_order", s => s.Ok.Latency.Percent95 < 500),
        Threshold.Create("create_order", s => s.FailPercent < 1.0)
    )
    .Run();

record LoginResponse(string Token);
```

---

## Parameterized Data with DataFeed

```csharp
// Cycle through test users to distribute load
var userFeed = DataFeed.FromLocal(new[]
{
    new { Email = "user1@example.com", Password = "pass1" },
    new { Email = "user2@example.com", Password = "pass2" },
});

var scenario = Scenario.Create("login_load", async context =>
{
    var user = userFeed.GetNextCircular(context);
    var req  = Http.CreateRequest("POST", "/api/auth/login")
        .WithJsonBody(new { email = user.Email, password = user.Password });
    return await Http.Send(http, req);
});
```

---

## NUnit / xUnit Integration

Run NBomber inside an existing test suite to enforce thresholds as test assertions:

```csharp
// PerfTests/ApiLoadTests.cs (NUnit)
using NBomber.CSharp;
using NBomber.Http.CSharp;
using NUnit.Framework;

[TestFixture]
public class ApiLoadTests
{
    [Test, Explicit("Run manually or in dedicated CI perf stage")]
    public void GetUsers_MeetsP95SLA()
    {
        using var http = new HttpClient { BaseAddress = new Uri("http://localhost:3001") };
        // (auth setup omitted for brevity)

        var scenario = Scenario.Create("get_users", async context =>
            await Http.Send(http, Http.CreateRequest("GET", "/api/users")))
            .WithLoadSimulations(Simulation.Inject(rate: 50,
                interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(1)));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .WithThresholds(
                Threshold.Create("get_users", s => s.Ok.Latency.Percent95 < 200),
                Threshold.Create("get_users", s => s.FailPercent < 1.0))
            .Run();

        Assert.That(stats.AllOkCount, Is.GreaterThan(0));
    }
}
```

Mark perf tests `[Explicit]` (NUnit) or `[Trait("Category", "perf")]` (xUnit) so they don't run in the normal unit test suite.

---

## Cleanup After Writes

If your scenario creates resources (POST → 201), delete them in a teardown step:

```csharp
var createdIds = new System.Collections.Concurrent.ConcurrentBag<int>();

var scenario = Scenario.Create("create_item", async context =>
{
    var req = Http.CreateRequest("POST", "/api/items")
        .WithJsonBody(new { name = $"perf-item-{context.ScenarioInfo.InstanceId}" });
    var res = await Http.Send(http, req);
    if (res.StatusCode == System.Net.HttpStatusCode.Created)
    {
        var body = await res.Message.Content.ReadFromJsonAsync<ItemResponse>();
        createdIds.Add(body!.Id);
    }
    return res;
});

// After NBomberRunner.Run():
foreach (var id in createdIds)
    await http.DeleteAsync($"/api/items/{id}");
```

---

## Default SLA Profiles

| Endpoint type   | p95 target | Error rate |
|-----------------|-----------|------------|
| GET (reads)     | < 200 ms  | < 1%       |
| POST/PUT (writes)| < 500 ms | < 1%       |
| Auth / login    | < 300 ms  | < 0.5%     |

---

## Execute Block

```bash
export API_URL="${API_URL:-http://localhost:3001}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
_NBOMBER_PROJ=$(find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "NBomber" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
if command -v dotnet &>/dev/null && [ -n "$_NBOMBER_PROJ" ]; then
  dotnet run --project "$_NBOMBER_PROJ" \
    2>&1 | tee "$_TMP/qa-perf-nbomber-output.txt"
  echo "NBOMBER_EXIT_CODE: $?"
fi
```

- Exit code `1` when thresholds fail — fails CI automatically
- Reports written to `./reports/nbomber/` (HTML + CSV + Markdown)
- Use `--no-build` on repeated runs after initial `dotnet build`
