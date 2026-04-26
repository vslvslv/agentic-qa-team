# Selenium WebDriver Patterns & Best Practices (multi-language)
<!-- lang: JavaScript (primary) | Java, Python examples in POM section | sources: training knowledge | iteration: 0 | score: 88/100 | date: 2026-04-26 -->

## Core Principles

1. **Prefer explicit waits over all other timing strategies.** Selenium tests fail most often because of timing issues. `WebDriverWait` with `ExpectedConditions` is the only production-safe approach.
2. **Selectors should be stable, not brittle.** IDs and data-test attributes outlast CSS class renames and DOM restructuring. XPath should be a last resort.
3. **The Page Object Model (POM) isolates UI structure from test logic.** When the UI changes, you update one class — not every test.
4. **Never use `Thread.sleep` / `time.sleep` / `setTimeout`.** Hard sleeps make suites slow and still fail under load. They are a deferred bug.
5. **Treat screenshots and logs as first-class CI artifacts.** A failing test without a screenshot is a mystery; a failing test with one is a diagnosis.

---

## Selector / Locator Strategy

Use selectors in this priority order — highest reliability first:

| Priority | Locator | JavaScript example | Notes |
|----------|---------|-------------------|-------|
| 1 | `By.id` | `By.id('submit-btn')` | Fastest; guaranteed unique if valid HTML |
| 2 | `By.name` | `By.name('username')` | Good for form fields |
| 3 | `By.css` with data attribute | `By.css('[data-testid="login-form"]')` | Decoupled from style; team-owned |
| 4 | `By.css` (structural) | `By.css('.login-form > button[type="submit"]')` | Acceptable if no test ID available |
| 5 | `By.linkText` / `By.partialLinkText` | `By.linkText('Sign in')` | Only for anchor elements |
| 6 | `By.className` | `By.className('btn-primary')` | Brittle — CSS classes change with redesigns |
| 7 | `By.tagName` | `By.tagName('h1')` | Only useful for unique structural tags |
| 8 | `By.xpath` | `By.xpath('//button[@type="submit"]')` | Last resort; slow and fragile |

**Key rule:** Add `data-testid` (or `data-cy`, `data-qa`) attributes to elements during development. These attributes are cheap, stable, and make the selector contract explicit.

```javascript
// PREFER — stable, intention-revealing
const loginBtn = await driver.findElement(By.css('[data-testid="login-button"]'));

// AVOID — breaks on class rename or DOM restructure
const loginBtn = await driver.findElement(By.xpath('//div[@class="header"]//button[2]'));
```

---

## Recommended Patterns

### Explicit Waits with WebDriverWait

The standard approach for waiting on dynamic content. Always use this instead of `driver.sleep()` or implicit waits.

**JavaScript (selenium-webdriver)**
```javascript
const { Builder, By, until } = require('selenium-webdriver');

const driver = await new Builder().forBrowser('chrome').build();
const wait = driver.wait.bind(driver);

// Wait up to 10 s for element to be visible
const el = await driver.wait(
  until.elementIsVisible(driver.findElement(By.id('status-message'))),
  10_000,
  'Status message did not become visible within 10 s'
);

// Wait for URL to contain a substring (post-navigation)
await driver.wait(until.urlContains('/dashboard'), 5_000);

// Wait for element to be stale (useful after a page transition)
const oldEl = await driver.findElement(By.id('spinner'));
await driver.wait(until.stalenessOf(oldEl), 8_000);
```

**Java**
```java
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import java.time.Duration;

WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Visible
WebElement el = wait.until(
    ExpectedConditions.visibilityOfElementLocated(By.id("status-message"))
);

// Clickable (visible + enabled)
WebElement btn = wait.until(
    ExpectedConditions.elementToBeClickable(By.css("[data-testid='submit']"))
);

// Text present
wait.until(ExpectedConditions.textToBePresentInElementLocated(
    By.id("result"), "Success"
));
```

**Python**
```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

wait = WebDriverWait(driver, timeout=10)

# Visible
el = wait.until(EC.visibility_of_element_located((By.ID, "status-message")))

# Clickable
btn = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "[data-testid='submit']")))

# Custom condition (lambda)
wait.until(lambda d: len(d.find_elements(By.CSS_SELECTOR, ".result-row")) > 0)
```

---

### Fluent Waits

Use `FluentWait` when you need custom polling intervals or want to suppress specific exceptions during polling (e.g., `StaleElementReferenceException` on a list that re-renders).

**Java**
```java
import org.openqa.selenium.support.ui.FluentWait;
import org.openqa.selenium.NoSuchElementException;
import java.time.Duration;
import java.util.function.Function;

FluentWait<WebDriver> fluentWait = new FluentWait<>(driver)
    .withTimeout(Duration.ofSeconds(30))
    .pollingEvery(Duration.ofMillis(500))
    .ignoring(NoSuchElementException.class)
    .ignoring(StaleElementReferenceException.class)
    .withMessage("Product rows never loaded");

WebElement firstRow = fluentWait.until(d ->
    d.findElement(By.cssSelector("[data-testid='product-row']:first-child"))
);
```

**Python**
```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import NoSuchElementException, StaleElementReferenceException

fluent = WebDriverWait(
    driver,
    timeout=30,
    poll_frequency=0.5,
    ignored_exceptions=[NoSuchElementException, StaleElementReferenceException]
)
first_row = fluent.until(
    lambda d: d.find_element(By.CSS_SELECTOR, "[data-testid='product-row']:first-child")
)
```

---

### Page Object Model (POM)

Encapsulate page structure and interactions in a dedicated class. Tests call methods, not raw selectors.

**JavaScript**
```javascript
// pages/LoginPage.js
const { By, until } = require('selenium-webdriver');

class LoginPage {
  constructor(driver) {
    this.driver = driver;
    this.url = '/login';
  }

  async open(baseUrl) {
    await this.driver.get(baseUrl + this.url);
  }

  async login(username, password) {
    const wait = (loc) => this.driver.wait(until.elementLocated(loc), 8_000);
    await (await wait(By.css('[data-testid="username"]'))).sendKeys(username);
    await (await wait(By.css('[data-testid="password"]'))).sendKeys(password);
    await (await wait(By.css('[data-testid="submit"]'))).click();
  }

  async getErrorMessage() {
    const el = await this.driver.wait(
      until.elementLocated(By.css('[data-testid="error-msg"]')), 5_000
    );
    return el.getText();
  }
}

module.exports = { LoginPage };
```

```javascript
// tests/login.test.js
const { LoginPage } = require('../pages/LoginPage');

test('shows error on bad credentials', async () => {
  const page = new LoginPage(driver);
  await page.open(process.env.BASE_URL);
  await page.login('bad@example.com', 'wrong');
  const msg = await page.getErrorMessage();
  expect(msg).toBe('Invalid credentials');
});
```

**Java** (PageFactory + @FindBy)
```java
// pages/LoginPage.java
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import java.time.Duration;

public class LoginPage {
    private final WebDriver driver;
    private final WebDriverWait wait;

    @FindBy(css = "[data-testid='username']") private WebElement usernameInput;
    @FindBy(css = "[data-testid='password']") private WebElement passwordInput;
    @FindBy(css = "[data-testid='submit']")   private WebElement submitButton;
    @FindBy(css = "[data-testid='error-msg']") private WebElement errorMessage;

    public LoginPage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(8));
        PageFactory.initElements(driver, this);
    }

    public void login(String username, String password) {
        wait.until(ExpectedConditions.visibilityOf(usernameInput)).sendKeys(username);
        passwordInput.sendKeys(password);
        submitButton.click();
    }

    public String getErrorMessage() {
        return wait.until(ExpectedConditions.visibilityOf(errorMessage)).getText();
    }
}
```

**Python**
```python
# pages/login_page.py
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class LoginPage:
    USERNAME = (By.CSS_SELECTOR, "[data-testid='username']")
    PASSWORD = (By.CSS_SELECTOR, "[data-testid='password']")
    SUBMIT   = (By.CSS_SELECTOR, "[data-testid='submit']")
    ERROR    = (By.CSS_SELECTOR, "[data-testid='error-msg']")

    def __init__(self, driver, base_url):
        self.driver = driver
        self.wait = WebDriverWait(driver, timeout=8)
        self.base_url = base_url

    def open(self):
        self.driver.get(self.base_url + "/login")

    def login(self, username, password):
        self.wait.until(EC.visibility_of_element_located(self.USERNAME)).send_keys(username)
        self.driver.find_element(*self.PASSWORD).send_keys(password)
        self.driver.find_element(*self.SUBMIT).click()

    def get_error_message(self):
        return self.wait.until(
            EC.visibility_of_element_located(self.ERROR)
        ).text
```

---

### Screenshot on Failure

Capture a screenshot whenever a test fails. In CI this becomes your primary diagnostic artifact.

**JavaScript (Jest + selenium-webdriver)**
```javascript
// helpers/screenshotOnFailure.js
const fs = require('fs');
const path = require('path');

async function screenshotOnFailure(driver, testName, error) {
  if (!error) return;
  const safe = testName.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 80);
  const dir = path.join(__dirname, '..', 'screenshots');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${safe}-${Date.now()}.png`);
  const png = await driver.takeScreenshot();
  fs.writeFileSync(file, png, 'base64');
  console.error(`Screenshot saved: ${file}`);
}

module.exports = { screenshotOnFailure };
```

```javascript
// In your afterEach
afterEach(async () => {
  if (currentTest.failed) {
    await screenshotOnFailure(driver, currentTest.fullTitle(), currentTest.err);
  }
  await driver.quit();
});
```

**Java (JUnit 5 extension)**
```java
import org.junit.jupiter.api.extension.*;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import java.nio.file.*;

public class ScreenshotExtension implements TestWatcher {
    @Override
    public void testFailed(ExtensionContext ctx, Throwable cause) {
        ctx.getTestInstance().ifPresent(instance -> {
            try {
                WebDriver driver = ((BaseTest) instance).getDriver();
                byte[] png = ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
                Path out = Paths.get("screenshots", ctx.getDisplayName() + ".png");
                Files.createDirectories(out.getParent());
                Files.write(out, png);
            } catch (Exception e) { /* log, don't rethrow */ }
        });
    }
}
```

---

### Actions Class — Hover, Drag, Right-Click

Use `Actions` for compound gestures that a plain `.click()` cannot perform.

**JavaScript**
```javascript
const { Actions } = require('selenium-webdriver');

const actions = driver.actions({ async: true });

// Hover to reveal a dropdown
const menuItem = await driver.findElement(By.css('[data-testid="products-menu"]'));
await actions.move({ origin: menuItem }).perform();
const dropdown = await driver.wait(
  until.elementIsVisible(driver.findElement(By.css('[data-testid="products-dropdown"]'))),
  3_000
);

// Drag and drop
const source = await driver.findElement(By.id('drag-handle'));
const target = await driver.findElement(By.id('drop-zone'));
await actions.dragAndDrop(source, target).perform();

// Right-click (context menu)
await actions.contextClick(menuItem).perform();
```

**Java**
```java
import org.openqa.selenium.interactions.Actions;

Actions actions = new Actions(driver);

// Hover
WebElement menu = driver.findElement(By.cssSelector("[data-testid='products-menu']"));
actions.moveToElement(menu).perform();

// Drag and drop
WebElement source = driver.findElement(By.id("drag-handle"));
WebElement target = driver.findElement(By.id("drop-zone"));
actions.dragAndDrop(source, target).perform();
```

---

### Headless Mode

Run headless in CI to avoid needing a display server. Add `--headless=new` (Chrome 112+) for the modern headless implementation.

**JavaScript**
```javascript
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

const isCI = !!process.env.CI;
const options = new chrome.Options();
if (isCI) {
  options.addArguments('--headless=new');
  options.addArguments('--no-sandbox');          // required inside Docker
  options.addArguments('--disable-dev-shm-usage'); // prevents /dev/shm OOM in containers
  options.addArguments('--disable-gpu');
  options.windowSize({ width: 1280, height: 800 });
}

const driver = await new Builder()
  .forBrowser('chrome')
  .setChromeOptions(options)
  .build();
```

**Python**
```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import os

opts = Options()
if os.getenv("CI"):
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(options=opts)
```

---

### ChromeDriver Version Pinning

Mismatched ChromeDriver and Chrome versions cause cryptic startup failures.

**Using `selenium-manager` (Selenium 4.6+, recommended)**

Selenium 4.6+ ships with Selenium Manager which auto-downloads the correct ChromeDriver. No manual pinning needed when your Selenium version is current.

```javascript
// package.json — keep selenium-webdriver at 4.x latest
// selenium-manager handles driver matching automatically
const { Builder } = require('selenium-webdriver');
const driver = await new Builder().forBrowser('chrome').build();
// Driver binary resolved automatically
```

**Manual pin when you must control the exact driver version**
```javascript
const chrome = require('selenium-webdriver/chrome');
const { ServiceBuilder } = chrome;

// Pin to a specific chromedriver binary (e.g., downloaded by CI pipeline)
const service = new ServiceBuilder('/usr/local/bin/chromedriver-114').build();
const driver = await new Builder()
  .forBrowser('chrome')
  .setChromeService(service)
  .build();
```

```java
// Java — pin via system property (useful in Maven/Gradle CI)
System.setProperty("webdriver.chrome.driver", "/usr/local/bin/chromedriver-114");
WebDriver driver = new ChromeDriver();
```

**CI matrix pinning (GitHub Actions)**
```yaml
- name: Install Chrome + matching ChromeDriver
  uses: browser-actions/setup-chrome@v1
  with:
    chrome-version: '120'   # pins both browser and driver
```

---

## Real-World Gotchas  [community]

1. **`StaleElementReferenceException` after DOM updates** [community] — Holding a reference to a `WebElement` across a page transition or React re-render causes this; re-locate the element inside the action that needs it, or wrap in a retry loop with `FluentWait` ignoring `StaleElementReferenceException`.

2. **Implicit wait + explicit wait = non-deterministic timeouts** [community] — Setting `driver.manage().timeouts().implicitlyWait()` and also using `WebDriverWait` causes the two timers to compound unpredictably (the implicit wait delays `NoSuchElementException` which `ExpectedConditions` relies on). Use one strategy: explicit waits only, implicit wait set to 0.

3. **`element click intercepted` in headless mode** [community] — Sticky headers or cookie banners cover the target element. The fix is to scroll the element into the viewport with `JavascriptExecutor.executeScript("arguments[0].scrollIntoView(true)", el)` before clicking, or dismiss the overlay first.

4. **`--no-sandbox` in Docker without `--disable-dev-shm-usage` causes crashes** [community] — Chrome uses `/dev/shm` for shared memory; Docker containers default to 64 MB which Chrome exhausts quickly. Always add `--disable-dev-shm-usage` alongside `--no-sandbox` in containerized CI.

5. **`PageFactory` lazy proxies go stale with SPAs** [community] — Java `@FindBy` proxies re-locate on each access, which helps with stale refs but still fails when the element is momentarily absent during a React render cycle. Wrap every `PageFactory`-backed interaction in `WebDriverWait.until(ExpectedConditions.visibilityOf(...))` rather than accessing the field directly.

6. **Window/tab focus side-effects in parallel runs** [community] — If tests switch windows with `driver.switchTo().window()` and share a driver instance across threads, race conditions corrupt the window handle. Always use one driver per test thread; never share a `WebDriver` instance across threads.

7. **ChromeDriver auto-update breaks pinned versions** [community] — Chrome's background updater can push a new major version mid-pipeline, leaving the previously-downloaded ChromeDriver incompatible. Pin both Chrome and ChromeDriver versions in CI using a setup action (e.g., `browser-actions/setup-chrome`) or lock the Chrome package in your container image.

---

## CI Considerations

- **Display server**: On Linux CI without a display, use headless mode (`--headless=new`) or provide a virtual display via `Xvfb`. GitHub Actions and most hosted runners support headless directly.
- **Driver resolution**: Selenium Manager (4.6+) resolves the correct ChromeDriver automatically if you keep the `selenium-webdriver` package current. Older pipelines should use a pinned driver binary cached in CI.
- **Timeouts under load**: CI machines are slower. Increase default `WebDriverWait` timeouts by 2-3x compared to local (e.g., 10 s local → 30 s CI). Pass timeout via environment variable to avoid hardcoding.
- **Artifact upload**: Always upload `screenshots/` and browser logs as CI artifacts so failures are diagnosable without re-running. In GitHub Actions: use `actions/upload-artifact` with `if: failure()`.
- **Port conflicts**: If starting a local dev server before tests, wait for the port to be ready before launching the driver. Use a health-check loop (`wait-on` in Node, `urllib.request` retry in Python) rather than a fixed sleep.
- **Parallel execution**: Run test files in parallel processes (Jest `--runInBand=false`, pytest-xdist, JUnit `@Execution(CONCURRENT)`) but give each process its own driver instance. Never share drivers across workers.
- **`--disable-extensions` and `--disable-infobars`**: Add these flags in CI to suppress Chrome prompts that can block element interaction.

---

## Key APIs

| Method | Purpose | When to use |
|--------|---------|-------------|
| `driver.wait(until.elementLocated(loc), ms)` (JS) / `new WebDriverWait(driver, Duration)` (Java/Python) | Explicit wait — blocks until condition is met | Any dynamic content; replace all sleeps |
| `driver.findElement(By.css(…))` | Find first matching element | Single element access |
| `driver.findElements(By.css(…))` | Find all matching elements | Lists, counts, existence checks |
| `actions.move({ origin: el }).perform()` (JS) / `actions.moveToElement(el).perform()` (Java) | Hover over element | Tooltip triggers, hover menus |
| `actions.dragAndDrop(src, tgt).perform()` | Drag-and-drop | Kanban boards, sortable lists |
| `driver.takeScreenshot()` / `((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES)` | Capture viewport as PNG | Failure diagnostics, visual logging |
| `driver.executeScript("…", el)` | Run arbitrary JS in page context | Scroll into view, force-click, read computed style |
| `driver.switchTo().frame(nameOrIndex)` | Enter an iframe context | Testing embedded widgets, payment iframes |
| `driver.switchTo().alert()` | Handle browser alerts/confirms | Dismiss native dialogs |
| `driver.manage().window().setSize({width, height})` | Set viewport size | Responsive layout tests |
| `FluentWait.ignoring(ExceptionType)` | Poll with ignored exception class | Re-rendering lists (StaleElementReferenceException) |
| `By.id / By.css / By.xpath` | Locate elements by strategy | See selector priority table above |
| `ExpectedConditions.visibilityOfElementLocated(loc)` (Java/Python) / `until.elementIsVisible(el)` (JS) | Wait for element to be visible | Post-render checks |
| `ExpectedConditions.elementToBeClickable(loc)` | Wait for element to be enabled + visible | Before clicking buttons |
