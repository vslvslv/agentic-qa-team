# Kotlin Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Conciseness without sacrificing clarity.** Kotlin eliminates ceremony (semicolons, `new`, boilerplate getters/setters) so that intent is front and center. Shorter code is only better when it is still readable.
2. **Null safety as a first-class contract.** Every type carries nullability in its signature. This shifts null-pointer bugs from runtime crashes to compile-time errors, making APIs self-documenting.
3. **Immutability by default.** Prefer `val` over `var`, immutable collection interfaces over mutable ones, and data classes with `copy()` over mutation. Mutation should be the exception, not the default.
4. **Coroutines for structured concurrency.** Asynchronous code should have clear, predictable lifetimes. Structured concurrency means a parent scope always outlives its children, making cancellation and error propagation deterministic.
5. **Expressions over statements.** `if`, `when`, and `try` are expressions that return values. Prefer expression form to reduce mutation and make data flow explicit.

---

## Principles / Patterns

### Data Classes

Data classes are Kotlin's idiomatic equivalent of plain value objects (DTOs, records). The compiler auto-generates `equals()`, `hashCode()`, `toString()`, `copy()`, and `componentN()` destructuring functions from the primary constructor.

```kotlin
data class Customer(
    val id: Long,
    val name: String,
    val email: String
)

// Structural equality works out of the box
val a = Customer(1L, "Alice", "alice@example.com")
val b = Customer(1L, "Alice", "alice@example.com")
println(a == b)  // true

// copy() creates a modified clone without mutating the original
val updated = a.copy(email = "newalice@example.com")

// Destructuring via componentN
val (id, name, email) = updated
println("$id: $name — $email")
```

Use `data class` for any type whose identity is defined by its values. Avoid using `data class` for entities with mutable lifecycle state (e.g., JPA entities).

---

### Extension Functions

Extension functions add methods to a type without subclassing or wrapping, keeping domain logic close to the type it augments while preserving encapsulation.

```kotlin
// Extending String with a domain-specific validator
fun String.isValidEmail(): Boolean {
    return contains("@") && contains(".")
}

// Extending List with a safe reducer
fun <T> List<T>.secondOrNull(): T? = if (size >= 2) this[1] else null

fun main() {
    println("user@example.com".isValidEmail())  // true
    println("invalid".isValidEmail())            // false

    val items = listOf("a", "b", "c")
    println(items.secondOrNull())               // b
    println(emptyList<String>().secondOrNull()) // null
}
```

Prefer extension functions over utility classes (e.g., `StringUtils`). Top-level extension functions are imported explicitly, keeping namespaces clean.

---

### Sealed Classes + `when` Expressions

Sealed classes restrict a type hierarchy to a closed set of subclasses known at compile time. Combined with exhaustive `when` expressions, they eliminate unhandled-case bugs without an `else` branch.

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val error: Throwable) : Result<Nothing>()
    data object Loading : Result<Nothing>()
}

fun <T> handleResult(result: Result<T>): String = when (result) {
    is Result.Success -> "Got data: ${result.data}"
    is Result.Failure -> "Error: ${result.error.message}"
    Result.Loading    -> "Loading…"
    // No else needed — compiler verifies exhaustiveness
}

// Usage
val response: Result<String> = Result.Success("Hello")
println(handleResult(response))  // Got data: Hello
```

Adding a new subclass to `Result` causes a compile error at every `when` site that lacks the new branch — making refactoring safe.

---

### Coroutines — `launch` / `async` / `Flow`

Kotlin coroutines provide cooperative multitasking without threads. `launch` is fire-and-forget; `async` returns a `Deferred<T>` for parallel results; `Flow` is a cold, backpressure-aware stream.

```kotlin
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

// launch — fire-and-forget
fun CoroutineScope.sendNotificationAsync(userId: Long) {
    launch {
        delay(100)
        println("Notification sent to $userId")
    }
}

// async — parallel results
suspend fun fetchBothPages(): String = coroutineScope {
    val page1 = async { delay(50); "First page" }
    val page2 = async { delay(80); "Second page" }
    "${page1.await()} + ${page2.await()}"
}

// Flow — cold stream with operators
fun userEvents(): Flow<String> = flow {
    emit("login")
    delay(100)
    emit("click")
    delay(100)
    emit("logout")
}

suspend fun main() {
    coroutineScope {
        sendNotificationAsync(42L)
        println(fetchBothPages())
    }
    userEvents()
        .filter { it != "click" }
        .collect { println("Event: $it") }
}
```

---

### Scope Functions — `let` / `run` / `with` / `apply` / `also`

Scope functions execute a block within an object's context. The five differ on two axes: how the object is referenced inside the block (`this` or `it`) and what is returned (context object or lambda result).

```kotlin
data class Server(var host: String = "", var port: Int = 0)

// apply — configure an object; returns the object itself
val server = Server().apply {
    host = "api.example.com"
    port = 8080
}

// let — safe null execution; returns lambda result
val upperName: String? = "kotlin".let { it.uppercase() }
val nullSafe: Int = null?.let { 42 } ?: 0  // Elvis handles null

// run — combine initialization and computation; returns lambda result
val greeting = server.run {
    "Connecting to $host:$port"
}

// with — operations on a receiver without chaining; returns lambda result
val summary = with(server) {
    "Host=$host Port=$port"
}

// also — side effects (logging, validation) in a chain; returns the object
val verified = server
    .also { require(it.port > 0) { "Port must be positive" } }
    .also { println("Using ${it.host}") }
```

| Function | Context ref | Returns       | Best for                              |
|----------|-------------|---------------|---------------------------------------|
| `let`    | `it`        | Lambda result | Null checks, local variable scoping   |
| `run`    | `this`      | Lambda result | Init + compute in one block           |
| `with`   | `this`      | Lambda result | Multiple calls, non-extension context |
| `apply`  | `this`      | Context object| Object configuration / builder        |
| `also`   | `it`        | Context object| Side effects, debug logging in chains |

---

### Null Safety — `?.` / `?:` / `!!` / `let`

Kotlin's type system encodes nullability at compile time. The safe-call `?.`, Elvis `?:`, and non-null assertion `!!` are the primary tools.

```kotlin
data class Department(val head: Employee?)
data class Employee(val name: String, val email: String?)

fun getHeadEmail(dept: Department?): String {
    // Safe-call chain: returns null at the first null link
    return dept?.head?.email ?: "no-email@company.com"
}

// let for multiple operations on a non-null value
fun notifyHead(dept: Department?) {
    dept?.head?.let { head ->
        println("Notifying ${head.name}")
        sendEmail(head.email ?: "noreply@company.com")
    }
}

// Elvis with throw / return for early exit (guard clause pattern)
fun processOrder(order: Order?) {
    val id = order?.id ?: throw IllegalArgumentException("Order required")
    val customer = order.customer ?: return  // skip silently
    println("Processing order $id for ${customer.name}")
}

fun sendEmail(to: String) = println("Email → $to")
```

Reserve `!!` for situations where a null at that point is a programming error you want to surface immediately. Document every `!!` usage.

---

### Companion Objects

Companion objects provide class-scoped members (factory methods, constants) without the Java `static` keyword. They can implement interfaces, giving factories a polymorphic entry point.

```kotlin
interface EntityFactory<T> {
    fun create(data: Map<String, Any>): T
}

class User private constructor(
    val id: Long,
    val name: String
) {
    companion object : EntityFactory<User> {
        val ANONYMOUS = User(0L, "Anonymous")

        override fun create(data: Map<String, Any>): User {
            val id = (data["id"] as? Long)
                ?: throw IllegalArgumentException("id required")
            val name = data["name"] as? String ?: "Unknown"
            return User(id, name)
        }
    }
}

fun main() {
    val factory: EntityFactory<User> = User  // Companion as interface
    val user = factory.create(mapOf("id" to 1L, "name" to "Alice"))
    println(user.name)           // Alice
    println(User.ANONYMOUS.name) // Anonymous
}
```

For Java interop, annotate companion members with `@JvmStatic` to expose them as true static methods.

---

## Language Idioms

These are Kotlin-specific features — not just patterns in Kotlin clothing — that make code more expressive.

### String Templates
```kotlin
val host = "api.example.com"
val port = 8080
// Prefer templates over concatenation
val url = "Connecting to $host:$port at ${System.currentTimeMillis()}ms"
```

### Destructuring Declarations
```kotlin
data class Point(val x: Int, val y: Int)

val (x, y) = Point(3, 7)
for ((key, value) in mapOf("a" to 1, "b" to 2)) {
    println("$key → $value")
}
```

### Named and Default Arguments (Replaces Overload Chains)
```kotlin
fun drawRect(x: Int = 0, y: Int = 0, width: Int, height: Int, fill: Boolean = false) {
    println("rect($x,$y) ${width}x$height fill=$fill")
}
// Call only the parameters you care about
drawRect(width = 100, height = 50)
drawRect(x = 10, y = 10, width = 200, height = 100, fill = true)
```

### `when` as Expression
```kotlin
// when can be used as an expression — no need for a result variable
fun httpStatus(code: Int): String = when (code) {
    200 -> "OK"
    404 -> "Not Found"
    in 500..599 -> "Server Error"
    else -> "Unknown ($code)"
}
```

### `object` Declarations (Singletons)
```kotlin
object AppConfig {
    val baseUrl = "https://api.example.com"
    val timeout = 30_000L

    fun buildUrl(path: String) = "$baseUrl/$path"
}
// Access directly — no instantiation
println(AppConfig.buildUrl("users"))
```

### Inline Value Classes (Type-Safe Primitives)
```kotlin
@JvmInline value class UserId(val value: Long)
@JvmInline value class OrderId(val value: Long)

fun getUser(id: UserId) = println("User $id")
fun getOrder(id: OrderId) = println("Order $id")

// Compiler prevents mixing:
// getUser(OrderId(5L))  // ← compile error
getUser(UserId(42L))
```

### `lateinit var` for DI-Injected Properties
```kotlin
class UserService {
    lateinit var repository: UserRepository  // Injected by DI framework

    fun findAll() = repository.findAll()
}
```

### `lazy` for Expensive Computed Properties
```kotlin
class Config {
    val schema: JsonSchema by lazy {
        // Loaded only once, on first access
        JsonSchema.load("schema.json")
    }
}
```

---

## Real-World Gotchas [community]

**`!!` Operator Abuse** [community] — Developers migrating from Java use `!!` everywhere to silence null warnings. This defeats Kotlin's null-safety guarantees and re-introduces `NullPointerException` at runtime. WHY it causes problems: every `!!` is a loaded gun; when the nullable precondition is violated (usually due to Java interop or race conditions), the stack trace points inside Kotlin code rather than the actual source. Fix: use `?:`, `?.let`, or explicit `if` guards. Reserve `!!` for genuinely impossible nulls and add a comment explaining why.

**`GlobalScope.launch` Leaks** [community] — Using `GlobalScope` decouples coroutines from any lifecycle, so they keep running after the component (Activity, ViewModel, service) that started them is destroyed. WHY it causes problems: leaked coroutines hold references to their captured variables, causing memory leaks and spurious state mutations. Fix: always launch coroutines in a `CoroutineScope` tied to the component's lifecycle (e.g., `viewModelScope`, `lifecycleScope`). Only use `GlobalScope` for application-wide background tasks where you explicitly accept the unbounded lifetime.

**`runBlocking` in Production Code** [community] — `runBlocking` is a bridge from synchronous to suspending code, intended only for tests and `main()`. Developers sometimes use it to call suspend functions from non-suspend callbacks. WHY it causes problems: it blocks the calling thread for the entire duration of the coroutine, which can starve thread pools (especially the Android main thread or a web-server worker thread). Fix: propagate `suspend` upward or redesign the callback to accept a coroutine scope.

**`withContext` Inside `flow { }` Builder** [community] — Switching dispatchers inside a `flow { }` block with `withContext` throws `IllegalStateException: Flow invariant is violated`. WHY it causes problems: the Flow API requires emissions to come from a single coroutine context to guarantee sequential ordering. Fix: use `flowOn(Dispatchers.IO)` at the end of the flow chain to run upstream emissions on a different dispatcher transparently.

**Data Class With Mutable Properties** [community] — Declaring a `data class` with `var` properties and then storing instances in a `HashSet` or as `HashMap` keys causes silent corruption. WHY it causes problems: `hashCode()` is computed from the current property values; mutating a property after insertion changes the hash code, making the entry unreachable and uncollectable. Fix: keep `data class` properties `val`-only; if mutation is genuinely needed, use a regular class and implement `equals`/`hashCode` manually with an immutable identity key.

**Sealed Class `else` in Multiplatform `when`** [community] — In Kotlin Multiplatform, if a sealed class is an `expect` declaration, the compiler cannot verify exhaustiveness in common code because platform-specific `actual` implementations can add subclasses. WHY it causes problems: adding a new platform-specific subclass silently falls through without the `else` branch at runtime. Fix: always add an `else` branch in common-code `when` expressions on `expect sealed` classes.

**Scope Function Nesting and Shadowed `this`** [community] — Nesting `apply { run { with ... } }` blocks makes it impossible to reason about which `this` or `it` refers to which object. WHY it causes problems: the inner lambda's `this` shadows the outer one; a single misread causes properties to be set on the wrong object with no compile-time warning. Fix: use at most one scope function per object; introduce an explicit named variable for the outer object if nesting is unavoidable.

**Extension Functions on Nullable Receivers Without Explicit Check** [community] — Extension functions can be declared on nullable types (`fun String?.orEmpty()`), but callers may not realise the receiver can be null, leading to logic bugs. WHY it causes problems: `"".isNullOrEmpty()` calls the same function as `null.isNullOrEmpty()` — the semantics differ, but the call site looks identical. Fix: make the receiver type non-nullable unless null is a meaningful case; prefer `?.` call sites to make nullability visible.

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `var` for non-mutating values | Misleads readers; prevents optimizations | Use `val` by default; `var` only when reassignment is required |
| `!!` instead of null-safe operators | Reintroduces `NullPointerException` at runtime | Use `?.`, `?:`, `?.let { }`, or `if (x != null)` smart cast |
| `GlobalScope.launch` | Leaks coroutines past component lifecycle | Use `viewModelScope`, `lifecycleScope`, or a custom scoped `CoroutineScope` |
| `runBlocking` in service code | Blocks thread, starves thread pools | Make call sites `suspend`; use `coroutineScope { }` for structured child coroutines |
| `withContext` inside `flow { }` | Throws `IllegalStateException` at runtime | Use `.flowOn(Dispatcher)` on the flow chain |
| Mutable `var` in `data class` | Keys in sets/maps silently break after mutation | Use `val` properties; implement `equals`/`hashCode` with immutable key if mutation needed |
| Utility class (`StringUtils`, `ObjectHelper`) | Forces static call style; hard to extend | Use extension functions on the relevant type |
| Overloaded constructors instead of defaults | Combinatorial explosion of overloads | Use default parameter values and named arguments |
| Type-unsafe primitive aliases (`Long` for ID, email, order) | Wrong ID type accepted silently | Use `@JvmInline value class` wrappers |
| Nesting scope functions 3+ levels deep | Shadowed `this`/`it`, impossible to read | Flatten with named variables; limit scope function chains to 2 |
