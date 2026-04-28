# Playwright Patterns & Best Practices (C#)
<!-- lang: C# | frameworks: NUnit / MSTest / xUnit | sources: playwright.dev/dotnet | iteration: 1 | date: 2026-04-28 -->
<!-- official: playwright.dev/dotnet/docs/intro, /pom, /locators, /assertions, /auth, /network, /test-runners, /best-practices -->

---

## Core Principles

Same as the TypeScript edition — test user-visible behavior, rely on auto-waiting, use
semantic locators, isolate state between tests — but the C# API surface differs.
All Playwright calls are async; every call must be `await`ed.

---

## Test Framework Setup

Playwright ships NuGet adapters for NUnit, MSTest, and xUnit. Inherit the base class that
matches `CS_TEST_FW`. The base class provides `Page`, `Browser`, `BrowserContext`, and
`Playwright` instances automatically — no lifecycle setup needed.

### NUnit (CS_TEST_FW = nunit)

```csharp
// NuGet: Microsoft.Playwright.NUnit
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

[Parallelizable(ParallelScope.Self)]
[TestFixture]
public class DashboardTests : PageTest
{
    [Test]
    public async Task LoadsWithoutError()
    {
        await Page.GotoAsync("/dashboard");
        await Expect(Page.GetByRole(AriaRole.Main)).ToBeVisibleAsync();
    }

    [Test]
    public async Task ShowsErrorBannerWhenApiFails()
    {
        await Page.RouteAsync("**/api/metrics", route => route.FulfillAsync(new()
        {
            Status = 500,
            ContentType = "application/json",
            Body = "{\"error\":\"Server error\"}"
        }));
        await Page.GotoAsync("/dashboard");
        await Expect(Page.GetByRole(AriaRole.Alert)).ToBeVisibleAsync();
    }
}
```

Enable full test parallelism at assembly level:
```csharp
// AssemblyInfo.cs (or top-level in any file)
[assembly: Parallelizable(ParallelScope.Fixtures)]
[assembly: LevelOfParallelism(4)]
```

### MSTest (CS_TEST_FW = mstest)

```csharp
// NuGet: Microsoft.Playwright.MSTest
using Microsoft.Playwright.MSTest;
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class DashboardTests : PageTest
{
    [TestMethod]
    public async Task LoadsWithoutError()
    {
        await Page.GotoAsync("/dashboard");
        await Expect(Page.GetByRole(AriaRole.Main)).ToBeVisibleAsync();
    }
}
```

### xUnit (CS_TEST_FW = xunit)

```csharp
// NuGet: Microsoft.Playwright.Xunit
using Microsoft.Playwright.Xunit;

public class DashboardTests : PageTest
{
    [Fact]
    public async Task LoadsWithoutError()
    {
        await Page.GotoAsync("/dashboard");
        await Expect(Page.GetByRole(AriaRole.Main)).ToBeVisibleAsync();
    }

    [Theory]
    [InlineData("admin@example.com")]
    public async Task LoginSucceedsForUser(string email)
    {
        await Page.GotoAsync("/login");
        await Page.GetByLabel(new Regex("email", RegexOptions.IgnoreCase)).FillAsync(email);
        // ...
    }
}
```

---

## Page Object Model (POM)

Encapsulate selectors and page actions in a class. Tests import behavior, not raw
Playwright calls — a UI change is fixed in one file.

```csharp
// Tests/Pages/LoginPage.cs
using Microsoft.Playwright;
using System.Text.RegularExpressions;

public class LoginPage
{
    private readonly IPage _page;
    private readonly ILocator _emailInput;
    private readonly ILocator _passwordInput;
    private readonly ILocator _submitButton;
    private readonly ILocator _errorMessage;

    public LoginPage(IPage page)
    {
        _page          = page;
        _emailInput    = page.GetByLabel(new Regex("email", RegexOptions.IgnoreCase));
        _passwordInput = page.GetByLabel(new Regex("password", RegexOptions.IgnoreCase));
        _submitButton  = page.GetByRole(AriaRole.Button,
                           new() { NameRegex = new Regex("sign in|log in", RegexOptions.IgnoreCase) });
        _errorMessage  = page.GetByRole(AriaRole.Alert);
    }

    public async Task GotoAsync() => await _page.GotoAsync("/login");

    public async Task LoginAsync(string email, string password)
    {
        await _emailInput.FillAsync(email);
        await _passwordInput.FillAsync(password);
        await _submitButton.ClickAsync();
    }

    public async Task LoginAndWaitAsync(string email, string password)
    {
        await LoginAsync(email, password);
        await _page.WaitForURLAsync(new Regex("dashboard|home"));
    }

    public async Task<bool> IsErrorVisibleAsync() =>
        await _errorMessage.IsVisibleAsync();
}
```

Use the POM in a test:
```csharp
[Test]
public async Task LoginSucceeds()
{
    var loginPage = new LoginPage(Page);
    await loginPage.GotoAsync();
    await loginPage.LoginAndWaitAsync("admin@example.com", "password123");
    await Expect(Page).ToHaveURLAsync(new Regex("/dashboard"));
}
```

**POM rules:**
- Locators are constructed in the constructor — they auto-wait at use time (no `FindElement` calls)
- Actions are `async Task`; getters that return state use `await` and return typed values
- Never assert inside the POM — keep assertions in the test so failures point to the right place

---

## Auth — StorageState (recommended)

Save authentication state once and reuse across tests.

```csharp
// Tests/GlobalSetup.cs — NUnit SetUpFixture, runs before all tests
using Microsoft.Playwright;
using NUnit.Framework;

[SetUpFixture]
public class GlobalSetup
{
    [OneTimeSetUp]
    public async Task SetUp()
    {
        using var playwright = await Playwright.CreateAsync();
        await using var browser = await playwright.Chromium.LaunchAsync();
        var context = await browser.NewContextAsync();
        var page    = await context.NewPageAsync();

        await page.GotoAsync($"{TestConfig.BaseUrl}/login");
        await page.GetByLabel(new Regex("email", RegexOptions.IgnoreCase))
                  .FillAsync(TestConfig.UserEmail);
        await page.GetByLabel(new Regex("password", RegexOptions.IgnoreCase))
                  .FillAsync(TestConfig.UserPassword);
        await page.GetByRole(AriaRole.Button,
                   new() { NameRegex = new Regex("sign in|log in", RegexOptions.IgnoreCase) })
                 .ClickAsync();
        await page.WaitForURLAsync(new Regex("dashboard|home"));

        Directory.CreateDirectory("e2e/.auth");
        await context.StorageStateAsync(new() { Path = "e2e/.auth/user.json" });
    }
}
```

Load saved state in tests by overriding `ContextOptions()`:
```csharp
[TestFixture]
public class AuthenticatedTests : PageTest
{
    public override BrowserNewContextOptions ContextOptions() => new()
    {
        StorageStatePath = "e2e/.auth/user.json",
        BaseURL = TestConfig.BaseUrl
    };
}
```

---

## Selector Strategy (ranked)

1. `GetByRole(AriaRole.Button, new() { Name = "Submit" })` — semantic, accessible
2. `GetByLabel("Email")` — form inputs
3. `GetByPlaceholder("Search…")` — inputs without label
4. `GetByText("Dashboard")` — links / buttons with visible text
5. `GetByTestId("submit-btn")` — explicit test hooks (configure `testIdAttribute` in `.runsettings`)
6. `Locator("[data-testid='submit']")` — fallback CSS/attribute selector

Filters:
```csharp
// Narrow by text
page.GetByRole(AriaRole.Row).Filter(new() { HasText = "Alice" });

// Combine locators
page.GetByRole(AriaRole.Button).And(page.GetByText("Confirm"));
```

**Never:** raw nth-child, positional XPath, class-based selectors (`.btn-primary`).

---

## Assertions (web-first — always use `Expect()`)

`Expect()` retries until the condition is met (default 5 s) — do not use `IsVisibleAsync()`
for assertions.

```csharp
await Expect(Page).ToHaveURLAsync(new Regex("/dashboard"));
await Expect(Page).ToHaveTitleAsync(new Regex("Dashboard"));
await Expect(Page.GetByRole(AriaRole.Heading, new() { Name = "Dashboard" })).ToBeVisibleAsync();
await Expect(Page.GetByRole(AriaRole.Alert)).Not.ToBeVisibleAsync();
await Expect(Page.GetByRole(AriaRole.Row)).ToHaveCountAsync(5);
await Expect(Page.GetByRole(AriaRole.Textbox, new() { Name = "Email" }))
    .ToHaveValueAsync("admin@example.com");

// Soft assertions (accumulate failures, report all at once)
await Expect.Soft(Page.GetByRole(AriaRole.Heading)).ToBeVisibleAsync();
await Expect.Soft(Page.GetByRole(AriaRole.Button, new() { Name = "Submit" })).ToBeEnabledAsync();
// (test continues; failures are reported together at the end)
```

---

## Network Mocking

```csharp
// Fulfill (mock response)
await Page.RouteAsync("**/api/users", route => route.FulfillAsync(new()
{
    Status = 200,
    ContentType = "application/json",
    Body = "[{\"id\":1,\"name\":\"Alice\"}]"
}));

// Abort (block request — e.g., analytics noise)
await Page.RouteAsync("**/analytics/**", route => route.AbortAsync());

// Modify response (intercept and alter)
await Page.RouteAsync("**/api/config", async route =>
{
    var response = await route.FetchAsync();
    var body = await response.TextAsync();
    await route.FulfillAsync(new() { Response = response, Body = body.Replace("false", "true") });
});
```

---

## Configuration

Control browser, viewport, and base URL via `.runsettings`:

```xml
<!-- playwright.runsettings -->
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
  <Playwright>
    <BrowserName>chromium</BrowserName>
    <LaunchOptions>
      <Headless>true</Headless>
      <Args>["--no-sandbox"]</Args>
    </LaunchOptions>
  </Playwright>
</RunSettings>
```

Static config class for environment overrides:

```csharp
// Tests/TestConfig.cs
public static class TestConfig
{
    public static string BaseUrl =>
        Environment.GetEnvironmentVariable("BASE_URL") ?? "http://localhost:5000";
    public static string UserEmail =>
        Environment.GetEnvironmentVariable("E2E_USER_EMAIL") ?? "admin@example.com";
    public static string UserPassword =>
        Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";
}
```

---

## CI Notes

```bash
# Install browsers (cache the Playwright browsers path across runs)
pwsh bin/Debug/net9.0/playwright.ps1 install --with-deps chromium
# Or (Linux/macOS): dotnet run --project tests/MyTests -- install

# Run all tests (headless by default via .runsettings)
dotnet test --settings playwright.runsettings

# Filter by test category / trait
dotnet test --filter "Category=smoke"        # NUnit
dotnet test --filter "Trait=category,smoke"  # xUnit

# JSON output for CI parsing
dotnet test --logger "json;LogFileName=/tmp/qa-web-dotnet-results.json"

# Parallelism (NUnit): add [assembly: Parallelizable] and [assembly: LevelOfParallelism(N)]
```

Environment variables:
- `PLAYWRIGHT_BROWSERS_PATH` — cache browser binaries across CI runs
- `BASE_URL`, `E2E_USER_EMAIL`, `E2E_USER_PASSWORD` — override per environment

---

## Execute Block

```bash
export BASE_URL="${BASE_URL:-http://localhost:5000}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
_RUNSETTINGS=""
[ -f "playwright.runsettings" ] && _RUNSETTINGS="--settings playwright.runsettings"
dotnet test $_RUNSETTINGS \
  --logger "json;LogFileName=$_TMP/qa-web-dotnet-results.json" \
  2>&1 | tee "$_TMP/qa-web-output.txt"
echo "EXIT_CODE: $?"
```
