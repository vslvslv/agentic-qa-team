# API Test Patterns — Python (pytest + requests)
<!-- lang: Python | date: 2026-04-28 -->

---

## Core Pattern: ApiClient

Wrap `requests.Session` in an `ApiClient` class. All tests receive an `ApiClient`
fixture — they never call `requests.get/post` directly.

```python
# tests/api/api_client.py
import os
import requests
from typing import Optional

class ApiClient:
    def __init__(self, base_url: Optional[str] = None) -> None:
        self.base_url = base_url or os.getenv("API_URL", "http://localhost:3001")
        self.session  = requests.Session()

    def authenticate(self, email: Optional[str] = None, password: Optional[str] = None) -> None:
        email    = email    or os.getenv("E2E_USER_EMAIL",    "admin@example.com")
        password = password or os.getenv("E2E_USER_PASSWORD", "password123")
        res = self.session.post(f"{self.base_url}/api/auth/login",
                                json={"email": email, "password": password})
        res.raise_for_status()
        self.session.headers.update({"Authorization": f"Bearer {res.json()['token']}"})

    def get(self, path: str, **kw):    return self.session.get(f"{self.base_url}{path}", **kw)
    def post(self, path: str, **kw):   return self.session.post(f"{self.base_url}{path}", **kw)
    def put(self, path: str, **kw):    return self.session.put(f"{self.base_url}{path}", **kw)
    def patch(self, path: str, **kw):  return self.session.patch(f"{self.base_url}{path}", **kw)
    def delete(self, path: str, **kw): return self.session.delete(f"{self.base_url}{path}", **kw)

    def anonymous(self) -> "ApiClient":
        """Returns an unauthenticated client for 401 tests."""
        return ApiClient(self.base_url)
```

---

## Test Structure

```python
# tests/api/conftest.py
import pytest
from .api_client import ApiClient

@pytest.fixture(scope="session")
def api() -> ApiClient:
    client = ApiClient()
    client.authenticate()
    return client

@pytest.fixture(scope="session")
def anon_api() -> ApiClient:
    return ApiClient()   # no authenticate() call
```

```python
# tests/api/test_users.py
import time
import pytest

created_ids: list[int] = []

@pytest.fixture(scope="session", autouse=True)
def cleanup(api):
    yield
    for user_id in created_ids:
        api.delete(f"/api/users/{user_id}")

# --- GET ---

def test_get_users_returns_200(api):
    r = api.get("/api/users")
    assert r.status_code == 200
    assert isinstance(r.json(), list)

def test_get_users_requires_auth(anon_api):
    assert anon_api.get("/api/users").status_code == 401

def test_get_user_404_for_unknown(api):
    assert api.get("/api/users/999999").status_code == 404

# --- POST ---

def test_create_user_returns_201(api):
    r = api.post("/api/users", json={
        "name": "Test User",
        "email": f"test-{int(time.time() * 1000)}@example.com",
    })
    assert r.status_code == 201
    body = r.json()
    assert body["id"] > 0
    created_ids.append(body["id"])  # track for cleanup

def test_create_user_400_missing_fields(api):
    assert api.post("/api/users", json={}).status_code == 400

# --- DELETE lifecycle ---

def test_delete_user_lifecycle(api):
    r = api.post("/api/users", json={
        "name": "To Delete",
        "email": f"del-{int(time.time() * 1000)}@example.com",
    })
    assert r.status_code == 201
    user_id = r.json()["id"]
    created_ids.append(user_id)

    del_r = api.delete(f"/api/users/{user_id}")
    assert del_r.status_code == 204
    created_ids.remove(user_id)   # already deleted — remove from cleanup list
```

---

## Cleanup Rules

- Declare `created_ids: list[int] = []` at module scope
- Append to it immediately after asserting 201
- Session-scoped `autouse` fixture iterates `created_ids` in teardown
- Lifecycle DELETE tests: `created_ids.remove(id)` right after asserting 204

---

## Execute Block

```bash
export API_URL="$_API_URL"
command -v pytest &>/dev/null && \
  pytest tests/api/ -v 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "PYTEST_EXIT_CODE: $?"
```
