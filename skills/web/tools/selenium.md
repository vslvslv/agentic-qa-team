# Selenium WebDriver — Web E2E Patterns

> Reference: [selenium-patterns.md](../references/selenium-patterns.md)

Selenium is multi-language. Use `TARGET_LANG` (detected in the Preamble) to pick the
right imports, test structure, and execute command. Examples below cover TypeScript/JS
and Java; adapt for Python/C#/Ruby following the same patterns.

## Auth Setup — Save & Restore Cookies

Selenium has no native session persistence. The standard pattern is:
1. Login once in a `@BeforeAll` / `before()` / `conftest.py` fixture
2. Save cookies/localStorage to a JSON file
3. Restore in `@BeforeEach` / `beforeEach()` for each test

**Java example:**

```java
// src/test/java/base/BaseTest.java
public class BaseTest {
  protected static WebDriver driver;
  protected static List<Cookie> authCookies;

  @BeforeAll
  static void login() {
    driver = new ChromeDriver(new ChromeOptions().addArguments("--headless=new"));
    driver.get(BASE_URL + "/login");
    driver.findElement(By.cssSelector("[data-testid='email']")).sendKeys(USER_EMAIL);
    driver.findElement(By.cssSelector("[data-testid='password']")).sendKeys(USER_PASS);
    driver.findElement(By.cssSelector("[data-testid='submit']")).click();
    new WebDriverWait(driver, Duration.ofSeconds(10))
        .until(ExpectedConditions.urlContains("/dashboard"));
    authCookies = new ArrayList<>(driver.manage().getCookies());
  }

  @BeforeEach
  void restoreSession() {
    driver.get(BASE_URL);
    authCookies.forEach(c -> driver.manage().addCookie(c));
    driver.navigate().refresh();
  }

  @AfterAll
  static void tearDown() { if (driver != null) driver.quit(); }
}
```

## Selector Strategy (ranked)

1. `By.id("elementId")` — fastest, most stable
2. `By.cssSelector("[data-testid='btn-submit']")` — explicit test hooks
3. `By.name("fieldName")` — form fields
4. `By.linkText("exact text")` — links with exact visible text
5. `By.xpath("//button[@aria-label='Submit']")` — last resort, attribute-based only
- **Never**: `By.className` (fragile), positional XPath (`//div[3]/span[2]`)

## Explicit Waits

```java
// Always use WebDriverWait; never Thread.sleep()
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Wait for element visible
WebElement el = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("result")));

// Wait for URL to change
wait.until(ExpectedConditions.urlContains("/dashboard"));

// Wait for text in element
wait.until(ExpectedConditions.textToBePresentInElementLocated(By.id("status"), "Success"));
```

## TypeScript / JavaScript Example

```typescript
// test/dashboard.test.ts (using selenium-webdriver + jest)
import { Builder, By, until, WebDriver } from "selenium-webdriver";
import chrome from "selenium-webdriver/chrome.js";

let driver: WebDriver;
beforeAll(async () => {
  driver = await new Builder().forBrowser("chrome")
    .setChromeOptions(new chrome.Options().addArguments("--headless=new"))
    .build();
  await driver.get(`${process.env.WEB_URL ?? "http://localhost:3000"}/login`);
  await driver.findElement(By.css("[data-testid='email']")).sendKeys("admin@example.com");
  await driver.findElement(By.css("[data-testid='password']")).sendKeys("password123");
  await driver.findElement(By.css("[data-testid='submit']")).click();
  await driver.wait(until.urlContains("/dashboard"), 10000);
});
afterAll(async () => driver.quit());

test("dashboard heading visible", async () => {
  const h1 = await driver.findElement(By.css("h1"));
  expect(await h1.isDisplayed()).toBe(true);
});
```

## CI Notes

```bash
# Chrome + ChromeDriver version must match — use webdriver-manager or chromedriver npm
npx chromedriver --version   # JS/TS
mvn versions:display-dependency-updates  # Java: check selenium-java version

# Headless mode (Chrome 112+)
# JS: new chrome.Options().addArguments("--headless=new")
# Java: options.addArguments("--headless=new")
```

- Selenium Grid for parallel execution across browsers/OSes
- Screenshot on failure: call `((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE)`

## Execute Block

Dispatched by detected runner and language:

```bash
# TypeScript / JavaScript (jest)
npx jest --testPathPattern="test/.*\\.test\\.(ts|js)$" --forceExit \
  2>&1 | tee "$_TMP/qa-web-selenium-output.txt"
echo "SELENIUM_EXIT_CODE: $?"

# Java (Maven + JUnit/TestNG)
# mvn test -pl . 2>&1 | tee "$_TMP/qa-web-selenium-output.txt"

# Python (pytest)
# pytest tests/selenium/ -v 2>&1 | tee "$_TMP/qa-web-selenium-output.txt"

# C# (.NET)
# dotnet test 2>&1 | tee "$_TMP/qa-web-selenium-output.txt"
```
