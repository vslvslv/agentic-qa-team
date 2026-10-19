# Appium Test Patterns — C#
<!-- lang: C# | frameworks: NUnit / MSTest / xUnit | date: 2026-04-28 -->

---

## Setup

```csharp
// MobileTests/AppiumTestBase.cs
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Appium.iOS;    // swap for AndroidDriver
using OpenQA.Selenium.Support.UI;
using NUnit.Framework;

public abstract class AppiumTestBase
{
    protected static IOSDriver Driver = null!;   // or AndroidDriver
    protected static WebDriverWait Wait = null!;

    [OneTimeSetUp]
    public static void SetUp()
    {
        var options = new AppiumOptions();
        options.PlatformName = Environment.GetEnvironmentVariable("PLATFORM") ?? "iOS";
        options.AddAdditionalAppiumOption("appium:deviceName",
            Environment.GetEnvironmentVariable("DEVICE_NAME") ?? "iPhone 15");
        options.AddAdditionalAppiumOption("appium:bundleId",
            Environment.GetEnvironmentVariable("BUNDLE_ID") ?? "com.example.myapp");
        options.AddAdditionalAppiumOption("appium:automationName", "XCUITest"); // or UiAutomator2

        var serverUrl = new Uri(
            Environment.GetEnvironmentVariable("APPIUM_URL") ?? "http://localhost:4723");
        Driver = new IOSDriver(serverUrl, options);
        Wait   = new WebDriverWait(Driver, TimeSpan.FromSeconds(10));
    }

    [OneTimeTearDown]
    public static void TearDown() => Driver?.Quit();

    [SetUp]
    public void ResetApp()
    {
        var bundle = Environment.GetEnvironmentVariable("BUNDLE_ID") ?? "com.example.myapp";
        Driver.TerminateApp(bundle);
        Driver.ActivateApp(bundle);
    }
}
```

---

## Selector Strategy (ranked)

1. `MobileBy.AccessibilityId("testId")` — preferred; maps to `accessibilityIdentifier` (iOS) / `contentDescription` (Android)
2. `MobileBy.Id("com.example.myapp:id/element")` — Android resource-id
3. `MobileBy.IosNSPredicate("name == 'Submit'")` — iOS only, fast
4. `MobileBy.AndroidUIAutomator("new UiSelector().text(\"Submit\")")` — Android only
5. `By.XPath("//XCUIElementTypeButton[@name='Submit']")` — last resort; slow and brittle

---

## NUnit — Test Structure

```csharp
// MobileTests/LoginTests.cs
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Support.UI;
using OpenQA.Selenium.Support.Extensions;
using NUnit.Framework;

[TestFixture]
public class LoginTests : AppiumTestBase
{
    [Test]
    public void ShowsLoginScreenOnLaunch()
    {
        var screen = Wait.Until(d => d.FindElement(MobileBy.AccessibilityId("login-screen")));
        Assert.That(screen.Displayed, Is.True);
    }

    [Test]
    public void LogsInWithValidCredentials()
    {
        var email    = Environment.GetEnvironmentVariable("E2E_USER_EMAIL")    ?? "admin@example.com";
        var password = Environment.GetEnvironmentVariable("E2E_USER_PASSWORD") ?? "password123";

        Driver.FindElement(MobileBy.AccessibilityId("email-input")).SendKeys(email);
        Driver.FindElement(MobileBy.AccessibilityId("password-input")).SendKeys(password);
        Driver.FindElement(MobileBy.AccessibilityId("login-button")).Click();

        var home = Wait.Until(d => d.FindElement(MobileBy.AccessibilityId("home-screen")));
        Assert.That(home.Displayed, Is.True);
    }

    [Test]
    public void ShowsErrorWithInvalidCredentials()
    {
        Driver.FindElement(MobileBy.AccessibilityId("email-input")).SendKeys("wrong@example.com");
        Driver.FindElement(MobileBy.AccessibilityId("password-input")).SendKeys("wrongpass");
        Driver.FindElement(MobileBy.AccessibilityId("login-button")).Click();

        var error = Wait.Until(d => d.FindElement(MobileBy.AccessibilityId("error-message")));
        Assert.That(error.Text, Does.Contain("Invalid"));
    }
}
```

---

## MSTest variant

Replace `AppiumTestBase` annotations:
```csharp
[TestClass]
public class LoginTests : AppiumTestBase
{
    [ClassInitialize] public static void Init(TestContext _) => SetUp();
    [ClassCleanup]    public static void Cleanup() => TearDown();
    [TestInitialize]  public void Reset() => ResetApp();

    [TestMethod]
    public void ShowsLoginScreenOnLaunch() { /* same body */ }
}
```

## xUnit variant

```csharp
public class LoginTests : AppiumTestBase, IAsyncLifetime
{
    public Task InitializeAsync() { SetUp(); return Task.CompletedTask; }
    public Task DisposeAsync()    { TearDown(); return Task.CompletedTask; }

    [Fact]
    public void ShowsLoginScreenOnLaunch() { /* same body */ }
}
```

---

## Explicit Waits — Always Use `WebDriverWait`

```csharp
// Never Thread.Sleep() — always wait for state
var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(10));

// Wait for element visible
var el = wait.Until(d => d.FindElement(MobileBy.AccessibilityId("submit-button")));

// Wait for condition
wait.Until(d =>
{
    var el = d.FindElement(MobileBy.AccessibilityId("status-label"));
    return el.Text.Contains("Success") ? el : null;
});
```

---

## Execute Block

```bash
export APPIUM_URL="${APPIUM_URL:-http://localhost:4723}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
command -v dotnet &>/dev/null && \
  dotnet test --filter "FullyQualifiedName~MobileTests" \
    --logger "json;LogFileName=$_TMP/qa-mobile-dotnet-results.json" \
    2>&1 | tee "$_TMP/qa-mobile-output.txt" && \
  echo "DOTNET_EXIT_CODE: $?"
```
