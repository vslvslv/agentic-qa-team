# API Test Patterns — C# (RestSharp or HttpClient + NUnit / MSTest / xUnit)
<!-- lang: C# | frameworks: NUnit / MSTest / xUnit | http-clients: RestSharp, HttpClient | date: 2026-04-28 -->

Use the **RestSharp section** when `CS_RESTSHARP=1` (RestSharp NuGet package detected in `.csproj`).
Use the **HttpClient section** when RestSharp is absent.
Within each section, use the sub-section that matches `CS_TEST_FW`: `nunit`, `mstest`, or `xunit`.

---

## RestSharp Section  (CS_RESTSHARP = 1)

RestSharp v107+ provides a higher-level REST client than raw `HttpClient`: fluent request
building, built-in JSON deserialization, and automatic response status checking. Prefer it
when it is already a project dependency.

### Core Pattern: RestSharp ApiClient

```csharp
// ApiTests/ApiClient.cs  (RestSharp v107+)
using RestSharp;

public sealed class ApiClient : IDisposable
{
    private readonly RestClient _client;

    public ApiClient(string? baseUrl = null)
    {
        var options = new RestClientOptions(
            baseUrl
            ?? Environment.GetEnvironmentVariable("API_URL")
            ?? "http://localhost:3001");
        _client = new RestClient(options);
    }

    public async Task AuthenticateAsync(string? email = null, string? password = null)
    {
        email    ??= Environment.GetEnvironmentVariable("E2E_USER_EMAIL")    ?? "admin@example.com";
        password ??= Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";

        var request = new RestRequest("/api/auth/login", Method.Post)
            .AddJsonBody(new { email, password });
        var res = await _client.ExecuteAsync<LoginResponse>(request);
        if (!res.IsSuccessful || res.Data is null)
            throw new InvalidOperationException($"Auth failed: {res.StatusCode}");
        _client.AddDefaultHeader("Authorization", $"Bearer {res.Data.Token}");
    }

    // Untyped — use when you only need the status code
    public Task<RestResponse> GetAsync(string path)
        => _client.ExecuteAsync(new RestRequest(path));
    public Task<RestResponse> PostAsync(string path, object body)
        => _client.ExecuteAsync(new RestRequest(path, Method.Post).AddJsonBody(body));
    public Task<RestResponse> PutAsync(string path, object body)
        => _client.ExecuteAsync(new RestRequest(path, Method.Put).AddJsonBody(body));
    public Task<RestResponse> PatchAsync(string path, object body)
        => _client.ExecuteAsync(new RestRequest(path, Method.Patch).AddJsonBody(body));
    public Task<RestResponse> DeleteAsync(string path)
        => _client.ExecuteAsync(new RestRequest(path, Method.Delete));

    // Typed — use when you need the deserialized body
    public Task<RestResponse<T>> GetAsync<T>(string path) where T : class
        => _client.ExecuteAsync<T>(new RestRequest(path));
    public Task<RestResponse<T>> PostAsync<T>(string path, object body) where T : class
        => _client.ExecuteAsync<T>(new RestRequest(path, Method.Post).AddJsonBody(body));

    /// <summary>Returns an unauthenticated copy for 401 tests.</summary>
    public ApiClient Anonymous() => new(_client.Options.BaseUrl?.ToString());

    public void Dispose() => _client.Dispose();

    private record LoginResponse(string Token);
}
```

---

### RestSharp — NUnit (CS_TEST_FW = nunit)

```csharp
// ApiTests/UsersApiTests.cs
using NUnit.Framework;

[TestFixture]
public class UsersApiTests
{
    private static ApiClient _api = null!;
    private static readonly List<int> _created = new();

    [OneTimeSetUp]
    public static async Task SetUp()
    {
        _api = new ApiClient();
        await _api.AuthenticateAsync();
    }

    [OneTimeTearDown]
    public static async Task TearDown()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    // --- GET ---

    [Test]
    public async Task GetUsers_Returns200WithArray()
    {
        var res = await _api.GetAsync<List<UserDto>>("/api/users");
        Assert.That((int)res.StatusCode, Is.EqualTo(200));
        Assert.That(res.Data, Is.Not.Null);
    }

    [Test]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        var res = await anon.GetAsync("/api/users");
        Assert.That((int)res.StatusCode, Is.EqualTo(401));
    }

    [Test]
    public async Task GetUser_Returns404ForUnknownId()
    {
        var res = await _api.GetAsync("/api/users/999999");
        Assert.That((int)res.StatusCode, Is.EqualTo(404));
    }

    // --- POST ---

    [Test]
    public async Task CreateUser_Returns201WithId()
    {
        var res = await _api.PostAsync<UserDto>("/api/users",
            new { name = "Test User", email = $"test-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}@example.com" });
        Assert.That((int)res.StatusCode, Is.EqualTo(201));
        Assert.That(res.Data!.Id, Is.GreaterThan(0));
        _created.Add(res.Data.Id);  // track for cleanup
    }

    [Test]
    public async Task CreateUser_Returns400ForMissingFields()
    {
        var res = await _api.PostAsync("/api/users", new { });
        Assert.That((int)res.StatusCode, Is.EqualTo(400));
    }

    // --- DELETE lifecycle (POST first, then DELETE) ---

    [Test]
    public async Task DeleteUser_Lifecycle_Returns204()
    {
        // Create first
        var createRes = await _api.PostAsync<UserDto>("/api/users",
            new { name = "To Delete", email = $"del-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}@example.com" });
        Assert.That((int)createRes.StatusCode, Is.EqualTo(201));
        _created.Add(createRes.Data!.Id);

        // Now delete
        var deleteRes = await _api.DeleteAsync($"/api/users/{createRes.Data.Id}");
        Assert.That((int)deleteRes.StatusCode, Is.EqualTo(204));
        _created.Remove(createRes.Data.Id);  // already gone — remove from teardown list
    }

    private record UserDto(int Id, string Name, string Email);
}
```

---

### RestSharp — MSTest (CS_TEST_FW = mstest)

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class UsersApiTests
{
    private static ApiClient _api = null!;
    private static readonly List<int> _created = new();

    [ClassInitialize]
    public static async Task SetUp(TestContext _)
    {
        _api = new ApiClient();
        await _api.AuthenticateAsync();
    }

    [ClassCleanup]
    public static async Task TearDown()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    [TestMethod]
    public async Task GetUsers_Returns200()
    {
        var res = await _api.GetAsync<List<UserDto>>("/api/users");
        Assert.AreEqual(200, (int)res.StatusCode);
        Assert.IsNotNull(res.Data);
    }

    [TestMethod]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        Assert.AreEqual(401, (int)(await anon.GetAsync("/api/users")).StatusCode);
    }

    private record UserDto(int Id, string Name, string Email);
}
```

---

### RestSharp — xUnit (CS_TEST_FW = xunit)

xUnit does not support `[OneTimeSetUp]` directly — use `IAsyncLifetime` for suite-level setup.

```csharp
using Xunit;

public class UsersApiTests : IAsyncLifetime
{
    private readonly ApiClient _api = new();
    private readonly List<int> _created = new();

    public async Task InitializeAsync() => await _api.AuthenticateAsync();

    public async Task DisposeAsync()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    [Fact]
    public async Task GetUsers_Returns200()
    {
        var res = await _api.GetAsync<List<UserDto>>("/api/users");
        Assert.Equal(200, (int)res.StatusCode);
        Assert.NotNull(res.Data);
    }

    [Fact]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        Assert.Equal(401, (int)(await anon.GetAsync("/api/users")).StatusCode);
    }

    private record UserDto(int Id, string Name, string Email);
}
```

---

## HttpClient Section  (CS_RESTSHARP = 0)

Use raw `HttpClient` when RestSharp is not in the project. Never instantiate `HttpClient`
in individual test classes — share a single instance via `ApiClient`.

```csharp
// ApiTests/ApiClient.cs
using System.Net.Http.Headers;
using System.Net.Http.Json;

public sealed class ApiClient : IDisposable
{
    private readonly HttpClient _http;

    public ApiClient(string? baseUrl = null)
    {
        _http = new HttpClient
        {
            BaseAddress = new Uri(
                baseUrl
                ?? Environment.GetEnvironmentVariable("API_URL")
                ?? "http://localhost:3001")
        };
    }

    public async Task AuthenticateAsync(string? email = null, string? password = null)
    {
        email    ??= Environment.GetEnvironmentVariable("E2E_USER_EMAIL")    ?? "admin@example.com";
        password ??= Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";

        var res = await _http.PostAsJsonAsync("/api/auth/login", new { email, password });
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadFromJsonAsync<LoginResponse>();
        _http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", body!.Token);
    }

    public Task<HttpResponseMessage> GetAsync(string path)         => _http.GetAsync(path);
    public Task<HttpResponseMessage> PostAsync<T>(string path, T body)
        => _http.PostAsJsonAsync(path, body);
    public Task<HttpResponseMessage> PutAsync<T>(string path, T body)
        => _http.PutAsJsonAsync(path, body);
    public Task<HttpResponseMessage> PatchAsync<T>(string path, T body)
        => _http.PatchAsJsonAsync(path, body);
    public Task<HttpResponseMessage> DeleteAsync(string path) => _http.DeleteAsync(path);

    /// <summary>Returns an unauthenticated copy for 401 tests.</summary>
    public ApiClient Anonymous() => new(_http.BaseAddress?.ToString());

    public void Dispose() => _http.Dispose();

    private record LoginResponse(string Token);
}
```

---

### HttpClient — NUnit (CS_TEST_FW = nunit)

```csharp
// ApiTests/UsersApiTests.cs
using NUnit.Framework;
using System.Net.Http.Json;

[TestFixture]
public class UsersApiTests
{
    private static ApiClient _api = null!;
    private static readonly List<int> _created = new();

    [OneTimeSetUp]
    public static async Task SetUp()
    {
        _api = new ApiClient();
        await _api.AuthenticateAsync();
    }

    [OneTimeTearDown]
    public static async Task TearDown()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    // --- GET ---

    [Test]
    public async Task GetUsers_Returns200WithArray()
    {
        var res = await _api.GetAsync("/api/users");
        Assert.That((int)res.StatusCode, Is.EqualTo(200));
        var body = await res.Content.ReadFromJsonAsync<List<UserDto>>();
        Assert.That(body, Is.Not.Null);
    }

    [Test]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        var res = await anon.GetAsync("/api/users");
        Assert.That((int)res.StatusCode, Is.EqualTo(401));
    }

    [Test]
    public async Task GetUser_Returns404ForUnknownId()
    {
        var res = await _api.GetAsync("/api/users/999999");
        Assert.That((int)res.StatusCode, Is.EqualTo(404));
    }

    // --- POST ---

    [Test]
    public async Task CreateUser_Returns201WithId()
    {
        var res = await _api.PostAsync("/api/users",
            new { name = "Test User", email = $"test-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}@example.com" });
        Assert.That((int)res.StatusCode, Is.EqualTo(201));
        var body = await res.Content.ReadFromJsonAsync<UserDto>();
        Assert.That(body!.Id, Is.GreaterThan(0));
        _created.Add(body.Id);  // track for cleanup
    }

    [Test]
    public async Task CreateUser_Returns400ForMissingFields()
    {
        var res = await _api.PostAsync("/api/users", new { });
        Assert.That((int)res.StatusCode, Is.EqualTo(400));
    }

    // --- DELETE lifecycle (POST first, then DELETE) ---

    [Test]
    public async Task DeleteUser_Lifecycle_Returns204()
    {
        // Create first
        var createRes = await _api.PostAsync("/api/users",
            new { name = "To Delete", email = $"del-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}@example.com" });
        Assert.That((int)createRes.StatusCode, Is.EqualTo(201));
        var created = await createRes.Content.ReadFromJsonAsync<UserDto>();
        _created.Add(created!.Id);

        // Now delete
        var deleteRes = await _api.DeleteAsync($"/api/users/{created.Id}");
        Assert.That((int)deleteRes.StatusCode, Is.EqualTo(204));
        _created.Remove(created.Id);  // already gone — remove from teardown list
    }

    private record UserDto(int Id, string Name, string Email);
}
```

---

### HttpClient — MSTest (CS_TEST_FW = mstest)

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Net.Http.Json;

[TestClass]
public class UsersApiTests
{
    private static ApiClient _api = null!;
    private static readonly List<int> _created = new();

    [ClassInitialize]
    public static async Task SetUp(TestContext _)
    {
        _api = new ApiClient();
        await _api.AuthenticateAsync();
    }

    [ClassCleanup]
    public static async Task TearDown()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    [TestMethod]
    public async Task GetUsers_Returns200()
    {
        var res = await _api.GetAsync("/api/users");
        Assert.AreEqual(200, (int)res.StatusCode);
    }

    [TestMethod]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        Assert.AreEqual(401, (int)(await anon.GetAsync("/api/users")).StatusCode);
    }
}
```

---

### HttpClient — xUnit (CS_TEST_FW = xunit)

xUnit does not support `[OneTimeSetUp]` directly — use `IAsyncLifetime` for suite-level setup.

```csharp
using Xunit;
using System.Net.Http.Json;

public class UsersApiTests : IAsyncLifetime
{
    private readonly ApiClient _api = new();
    private readonly List<int> _created = new();

    public async Task InitializeAsync() => await _api.AuthenticateAsync();

    public async Task DisposeAsync()
    {
        foreach (var id in _created)
            await _api.DeleteAsync($"/api/users/{id}");
        _api.Dispose();
    }

    [Fact]
    public async Task GetUsers_Returns200()
    {
        var res = await _api.GetAsync("/api/users");
        Assert.Equal(200, (int)res.StatusCode);
    }

    [Fact]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        using var anon = _api.Anonymous();
        Assert.Equal(401, (int)(await anon.GetAsync("/api/users")).StatusCode);
    }
}
```

---

### HttpClient — Cleanup Rules

- Declare `private static readonly List<int> _created = new()` (or equivalent per framework)
- Add every created resource ID to `_created` immediately after asserting 201
- In teardown, iterate `_created` and call `DeleteAsync` for each
- Lifecycle DELETE tests: call `_created.Remove(id)` right after asserting 204, so teardown does not double-delete
- Use timestamped unique values for `email` / `name` fields to avoid collisions in parallel runs

---

## Execute Block

```bash
export API_URL="${API_URL:-http://localhost:3001}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
dotnet test --filter "Category=Api|FullyQualifiedName~ApiTests" \
  --logger "json;LogFileName=$_TMP/qa-api-dotnet-results.json" \
  2>&1 | tee "$_TMP/qa-api-output.txt"
echo "DOTNET_EXIT_CODE: $?"
```
