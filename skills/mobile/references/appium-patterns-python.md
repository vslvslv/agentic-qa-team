# Appium Test Patterns — Python
<!-- lang: Python | date: 2026-04-28 -->

---

## Setup

```python
# tests/mobile/conftest.py
import os
import pytest
from appium import webdriver
from appium.options import XCUITestOptions   # or UiAutomator2Options for Android
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

@pytest.fixture(scope="session")
def driver():
    options = XCUITestOptions()
    options.platform_name   = os.getenv("PLATFORM",     "iOS")
    options.device_name     = os.getenv("DEVICE_NAME",  "iPhone 15")
    options.bundle_id       = os.getenv("BUNDLE_ID",    "com.example.myapp")
    options.automation_name = "XCUITest"  # or "UiAutomator2"

    server_url = os.getenv("APPIUM_URL", "http://localhost:4723")
    drv = webdriver.Remote(server_url, options=options)
    drv.implicitly_wait(0)   # rely on explicit waits only
    yield drv
    drv.quit()


@pytest.fixture(autouse=True)
def reset_app(driver):
    bundle = os.getenv("BUNDLE_ID", "com.example.myapp")
    driver.terminate_app(bundle)
    driver.activate_app(bundle)
```

---

## Selector Strategy (ranked)

1. `AppiumBy.ACCESSIBILITY_ID` — preferred; maps to `accessibilityIdentifier` (iOS) / `contentDescription` (Android)
2. `AppiumBy.ID` — Android resource-id
3. `AppiumBy.IOS_PREDICATE_STRING` — iOS only, fast
4. `AppiumBy.ANDROID_UIAUTOMATOR` — Android only
5. `AppiumBy.XPATH` — last resort; slow and brittle

---

## Test Structure

```python
# tests/mobile/test_login.py
import os
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

TIMEOUT = 10


def test_shows_login_screen_on_launch(driver):
    wait = WebDriverWait(driver, TIMEOUT)
    screen = wait.until(EC.visibility_of_element_located((AppiumBy.ACCESSIBILITY_ID, "login-screen")))
    assert screen.is_displayed()


def test_logs_in_with_valid_credentials(driver):
    wait  = WebDriverWait(driver, TIMEOUT)
    email = os.getenv("E2E_USER_EMAIL",    "admin@example.com")
    pwd   = os.getenv("E2E_USER_PASSWORD", "password123")

    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "email-input").send_keys(email)
    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "password-input").send_keys(pwd)
    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "login-button").click()

    wait.until(EC.visibility_of_element_located((AppiumBy.ACCESSIBILITY_ID, "home-screen")))


def test_shows_error_with_invalid_credentials(driver):
    wait = WebDriverWait(driver, TIMEOUT)

    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "email-input").send_keys("wrong@example.com")
    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "password-input").send_keys("wrongpass")
    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "login-button").click()

    error = wait.until(EC.visibility_of_element_located((AppiumBy.ACCESSIBILITY_ID, "error-message")))
    assert "Invalid" in error.text
```

---

## Explicit Waits — Always Use `WebDriverWait`

```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

wait = WebDriverWait(driver, 10)

# Wait for element visible
el = wait.until(EC.visibility_of_element_located((AppiumBy.ACCESSIBILITY_ID, "submit-button")))

# Wait for text in element
wait.until(EC.text_to_be_present_in_element(
    (AppiumBy.ACCESSIBILITY_ID, "status-label"), "Success"))

# Never: time.sleep()
```

---

## Execute Block

```bash
export APPIUM_URL="${APPIUM_URL:-http://localhost:4723}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
command -v pytest &>/dev/null && \
  pytest tests/mobile/ -v 2>&1 | tee "$_TMP/qa-mobile-output.txt" && \
  echo "PYTEST_EXIT_CODE: $?"
```
