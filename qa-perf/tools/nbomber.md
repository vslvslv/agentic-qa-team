# NBomber — Performance Test Patterns (C#)

> Reference: [nbomber-patterns.md](../references/nbomber-patterns.md)

## Load Simulation Types

| Test type            | Simulation                                                                   |
|----------------------|------------------------------------------------------------------------------|
| Ramp-up / load       | `RampingInject(rate, interval, during)` then `Inject(rate, interval, during)` |
| Constant throughput  | `Inject(rate: 50, interval: 1s, during: 2m)`                                |
| Virtual-user model   | `KeepConstant(copies: 50, during: 2m)`                                       |
| Stress / spike       | `RampingInject(…)` staged up then `RampingInject(rate: 0, …)` ramp-down     |
| Smoke (single user)  | `KeepConstant(copies: 1, during: 30s)`                                       |

## Script Template

```csharp
// PerfTests/ApiLoadTest.cs
using NBomber.CSharp;
using NBomber.Http.CSharp;
using NBomber.Contracts;
using System.Net.Http.Json;

// Auth — obtain token once before scenario iterations
var baseUrl     = Environment.GetEnvironmentVariable("API_URL")           ?? "http://localhost:3001";
var userEmail   = Environment.GetEnvironmentVariable("E2E_USER_EMAIL")    ?? "admin@example.com";
var userPassword= Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";

string token    = "";
using var httpClient = new HttpClient { BaseAddress = new Uri(baseUrl) };

// Warm-up: authenticate once per process
var loginRes = await httpClient.PostAsJsonAsync("/api/auth/login", new { email = userEmail, password = userPassword });
loginRes.EnsureSuccessStatusCode();
var loginBody = await loginRes.Content.ReadFromJsonAsync<LoginResponse>();
token = loginBody!.Token;
httpClient.DefaultRequestHeaders.Authorization =
    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

// Scenario
var scenario = Scenario.Create("api_load", async context =>
{
    var request  = Http.CreateRequest("GET", "/api/users");
    var response = await Http.Send(httpClient, request);
    return response;
})
.WithWarmUpDuration(TimeSpan.FromSeconds(5))
.WithLoadSimulations(
    Simulation.RampingInject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
    Simulation.Inject(rate: 50,        interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(2)),
    Simulation.RampingInject(rate: 0,  interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
);

NBomberRunner
    .RegisterScenarios(scenario)
    .WithReportFolder("./reports/nbomber")
    .WithReportFormats(ReportFormat.Html, ReportFormat.Csv, ReportFormat.Md)
    .Run();

record LoginResponse(string Token);
```

## Thresholds (fail CI on SLA breach)

```csharp
var scenario = Scenario.Create("api_load", async context => { /* ... */ })
    .WithLoadSimulations(Simulation.Inject(rate: 50, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(2)));

NBomberRunner
    .RegisterScenarios(scenario)
    .WithThresholds(
        Threshold.Create(scenarioName: "api_load", req => req.OkCount > 0),
        Threshold.Create("api_load", statsWindow =>
            statsWindow.Ok.Latency.Percent95 < 200),          // p95 < 200ms
        Threshold.Create("api_load", statsWindow =>
            statsWindow.FailPercent < 1.0)                     // error rate < 1%
    )
    .Run();
```

## Parameterized Data with DataFeed

```csharp
var users = DataFeed.FromLocal(new[] {
    new { Email = "user1@example.com", Password = "pass1" },
    new { Email = "user2@example.com", Password = "pass2" },
});

var scenario = Scenario.Create("multi_user_load", async context =>
{
    var user    = users.GetNextCircular(context);
    var request = Http.CreateRequest("POST", "/api/auth/login")
        .WithJsonBody(new { email = user.Email, password = user.Password });
    return await Http.Send(httpClient, request);
});
```

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

## Result Parsing

```bash
# Parse NBomber Markdown summary (written to ./reports/nbomber/*.md)
find . -path "*/reports/nbomber/*.md" 2>/dev/null | tail -1 | xargs cat 2>/dev/null | \
  grep -E "p95|p99|RPS|FailPercent|OkCount" | head -20
```

## CI Notes

- NBomber exits with code `1` when any threshold fails — fails CI steps automatically
- Run `dotnet run` from the perf test project directory, or `dotnet test` if wrapped in NUnit/xUnit
- Reports are written to `./reports/nbomber/` by default; override with `WithReportFolder`
- `--no-build` flag speeds up repeated CI runs after the initial build
