# Appium Test Patterns — Java
<!-- lang: Java | date: 2026-04-28 -->

---

## Setup

```java
// src/test/java/mobile/AppiumTestBase.java
import io.appium.java_client.AppiumDriver;
import io.appium.java_client.ios.IOSDriver;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.AppiumBy;
import io.appium.java_client.remote.options.BaseOptions;
import org.junit.jupiter.api.*;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import java.net.URL;
import java.time.Duration;

public abstract class AppiumTestBase {
    protected static AppiumDriver driver;
    protected static WebDriverWait wait;

    @BeforeAll
    static void setUp() throws Exception {
        var options = new BaseOptions<>()
            .amend("platformName",   System.getenv().getOrDefault("PLATFORM", "iOS"))
            .amend("appium:deviceName", System.getenv().getOrDefault("DEVICE_NAME", "iPhone 15"))
            .amend("appium:bundleId",   System.getenv().getOrDefault("BUNDLE_ID",  "com.example.myapp"))
            .amend("appium:automationName", "XCUITest");  // or "UiAutomator2" for Android

        String serverUrl = System.getenv().getOrDefault("APPIUM_URL", "http://localhost:4723");
        driver = new IOSDriver(new URL(serverUrl), options);  // swap for AndroidDriver
        wait   = new WebDriverWait(driver, Duration.ofSeconds(10));
    }

    @AfterAll
    static void tearDown() {
        if (driver != null) driver.quit();
    }

    @BeforeEach
    void resetApp() {
        driver.terminateApp(System.getenv().getOrDefault("BUNDLE_ID", "com.example.myapp"));
        driver.activateApp(System.getenv().getOrDefault("BUNDLE_ID",  "com.example.myapp"));
    }
}
```

---

## Selector Strategy (ranked)

1. `AppiumBy.ACCESSIBILITY_ID("testId")` — preferred; maps to `accessibilityIdentifier` (iOS) or `contentDescription` (Android)
2. `AppiumBy.ID("com.example.myapp:id/element")` — Android resource-id
3. `AppiumBy.IOS_PREDICATE_STRING("name == 'Submit'")` — iOS only, fast
4. `AppiumBy.ANDROID_UIAUTOMATOR("new UiSelector().text(\"Submit\")")` — Android only
5. `By.xpath("//XCUIElementTypeButton[@name='Submit']")` — last resort; slow and brittle

---

## Test Structure

```java
// src/test/java/mobile/LoginTest.java
import io.appium.java_client.AppiumBy;
import org.junit.jupiter.api.Test;
import org.openqa.selenium.support.ui.ExpectedConditions;
import static org.junit.jupiter.api.Assertions.*;

public class LoginTest extends AppiumTestBase {

    @Test
    void showsLoginScreenOnLaunch() {
        var screen = wait.until(ExpectedConditions.visibilityOfElementLocated(
            AppiumBy.accessibilityId("login-screen")));
        assertTrue(screen.isDisplayed());
    }

    @Test
    void logsInWithValidCredentials() {
        var email    = System.getenv().getOrDefault("E2E_USER_EMAIL",    "admin@example.com");
        var password = System.getenv().getOrDefault("E2E_USER_PASSWORD", "password123");

        driver.findElement(AppiumBy.accessibilityId("email-input")).sendKeys(email);
        driver.findElement(AppiumBy.accessibilityId("password-input")).sendKeys(password);
        driver.findElement(AppiumBy.accessibilityId("login-button")).click();

        wait.until(ExpectedConditions.visibilityOfElementLocated(
            AppiumBy.accessibilityId("home-screen")));
    }

    @Test
    void showsErrorWithInvalidCredentials() {
        driver.findElement(AppiumBy.accessibilityId("email-input")).sendKeys("wrong@example.com");
        driver.findElement(AppiumBy.accessibilityId("password-input")).sendKeys("wrongpass");
        driver.findElement(AppiumBy.accessibilityId("login-button")).click();

        var error = wait.until(ExpectedConditions.visibilityOfElementLocated(
            AppiumBy.accessibilityId("error-message")));
        assertTrue(error.getText().contains("Invalid"));
    }
}
```

---

## Explicit Waits — Always Use `WebDriverWait`

```java
// Never use Thread.sleep() — always wait for state
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Wait for element visible
var el = wait.until(ExpectedConditions.visibilityOfElementLocated(
    AppiumBy.accessibilityId("submit-button")));

// Wait for text in element
wait.until(ExpectedConditions.textToBePresentInElementLocated(
    AppiumBy.accessibilityId("status-label"), "Success"));
```

---

## Execute Block

```bash
command -v mvn &>/dev/null && [ -f pom.xml ] && \
  mvn test -Dtest="*Test" 2>&1 | tee "$_TMP/qa-mobile-output.txt" && \
  echo "MAVEN_EXIT_CODE: $?"
```
