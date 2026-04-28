# API Test Patterns — Java (REST Assured)
<!-- lang: Java | date: 2026-04-28 -->

---

## Core Pattern: ApiClient

Centralise base URI, auth token, and request helpers in one class. Test classes
receive an `ApiClient` instance — they do not configure REST Assured directly.

```java
// src/test/java/api/ApiClient.java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import static io.restassured.RestAssured.given;

public class ApiClient {
    private String token = "";

    public ApiClient() {
        RestAssured.baseURI = System.getenv() != null && System.getenv("API_URL") != null
            ? System.getenv("API_URL") : "http://localhost:3001";
    }

    public void authenticate() {
        String email    = System.getenv().getOrDefault("E2E_USER_EMAIL",    "admin@example.com");
        String password = System.getenv().getOrDefault("E2E_USER_PASSWORD", "password123");
        token = given().contentType(ContentType.JSON)
            .body("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}")
            .post("/api/auth/login")
            .then().statusCode(200)
            .extract().path("token");
    }

    private RequestSpecification auth() {
        return given().header("Authorization", "Bearer " + token).accept(ContentType.JSON);
    }

    private RequestSpecification anon() {
        return given().accept(ContentType.JSON);
    }

    public Response get(String path)                     { return auth().get(path); }
    public Response getAnon(String path)                 { return anon().get(path); }
    public Response post(String path, String jsonBody)   { return auth().contentType(ContentType.JSON).body(jsonBody).post(path); }
    public Response put(String path, String jsonBody)    { return auth().contentType(ContentType.JSON).body(jsonBody).put(path); }
    public Response delete(String path)                  { return auth().delete(path); }
}
```

---

## Test Structure

```java
// src/test/java/api/UsersApiTest.java
import org.junit.jupiter.api.*;
import java.util.ArrayList;
import java.util.List;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class UsersApiTest {
    static ApiClient api;
    static List<Integer> created = new ArrayList<>();

    @BeforeAll
    static void setUp() {
        api = new ApiClient();
        api.authenticate();
    }

    @AfterAll
    static void tearDown() {
        for (int id : created) {
            api.delete("/api/users/" + id);
        }
    }

    @Test void getUsers_returns200WithList() {
        api.get("/api/users").then().statusCode(200)
            .body("$", instanceOf(java.util.List.class));
    }

    @Test void getUsers_returns401WithoutAuth() {
        api.getAnon("/api/users").then().statusCode(401);
    }

    @Test void getUser_returns404ForUnknownId() {
        api.get("/api/users/999999").then().statusCode(404);
    }

    @Test void createUser_returns201() {
        var res = api.post("/api/users",
            "{\"name\":\"Test\",\"email\":\"test-" + System.currentTimeMillis() + "@example.com\"}");
        res.then().statusCode(201);
        int id = res.path("id");
        created.add(id);
    }

    @Test void createUser_returns400ForMissingFields() {
        api.post("/api/users", "{}").then().statusCode(400);
    }

    @Test void deleteUser_lifecycle() {
        var createRes = api.post("/api/users",
            "{\"name\":\"ToDel\",\"email\":\"del-" + System.currentTimeMillis() + "@example.com\"}");
        createRes.then().statusCode(201);
        int id = createRes.path("id");
        created.add(id);

        api.delete("/api/users/" + id).then().statusCode(204);
        created.remove(Integer.valueOf(id));  // already deleted
    }
}
```

---

## Cleanup Rules

- Declare `static List<Integer> created = new ArrayList<>()` at class level
- Add to `created` immediately after asserting 201
- `@AfterAll` iterates `created` and calls `api.delete()`
- Lifecycle tests: `created.remove(Integer.valueOf(id))` after asserting 204

---

## Execute Block

```bash
command -v mvn &>/dev/null && [ -f pom.xml ] && \
  mvn test -pl . -Dtest="*ApiTest" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "MAVEN_EXIT_CODE: $?"
command -v gradle &>/dev/null && [ -f build.gradle ] && \
  gradle test --tests "*ApiTest" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "GRADLE_EXIT_CODE: $?"
```
