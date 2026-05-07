# Kotlin Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 3 | score: 100/100 | date: 2026-05-07 -->
<!-- iteration trace:
     Iter 0: 100/100 — initial draft (2026-04-26)
     Iter 1 (2026-05-04): added Kotlin Flow deep-dive (cold streams, builders, operators, backpressure,
       exception handling, flowOn, StateFlow/SharedFlow, cancellation, anti-patterns) sourced from
       kotlinlang.org/docs/flow.html; added Flow-related gotchas and anti-pattern rows
     Iter 2 (2026-05-07): added Kotlin 2.0 features — K2 compiler stable, smart cast improvements
       (local variables, ||, inline functions, property types, exception handling, inc/dec),
       Kotlin Multiplatform stable, Power-Assert plugin, lambda invokedynamic, enumEntries<T>();
       sourced from kotlinlang.org/docs/whatsnew20.html
     Iter 3 (2026-05-07): added Kotlin 2.1.20 features — K2 kapt default, common Atomic types,
       UUID improvements (Comparable + new parse formats), kotlin.time.Clock/Instant stdlib,
       Gradle Isolated Projects support, executable {} DSL for KMP JVM targets;
       sourced from kotlinlang.org/docs/whatsnew2120.html
-->

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

### Kotlin Flow — Cold Async Streams

`Flow<T>` is a cold, asynchronous stream that emits multiple values sequentially and cooperates with coroutine cancellation. Unlike a `suspend` function (one value) or `Sequence` (blocking), Flow is non-blocking and lazy — it does not start until `collect` is called, and each `collect` starts the stream fresh.

| Approach | Values | Blocking | Lazy | Use case |
|---|---|---|---|---|
| Regular function | Multiple (list) | Yes (eager) | No | Small, in-memory results |
| `Sequence` | Multiple | Yes (CPU) | Yes | CPU-bound iteration |
| `suspend` function | Single | No | Yes | Single async result |
| `Flow` | Multiple | No | Yes | Async event/data streams |

**Flow builders:**

```kotlin
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.*

// flow { } — primary builder; body can suspend; values emitted with emit()
fun countDown(from: Int): Flow<Int> = flow {
    for (i in from downTo 1) {
        delay(100)
        emit(i)
    }
}

// flowOf() — wrap a fixed set of values
val letters: Flow<String> = flowOf("a", "b", "c")

// .asFlow() — convert any Iterable or Sequence
val numbers: Flow<Int> = (1..5).asFlow()
```

**Intermediate operators (lazy — return a new Flow):**

```kotlin
// map, filter, transform, take
(1..10).asFlow()
    .filter { it % 2 == 0 }
    .map { it * it }
    .take(3)
    .collect { println(it) }  // 4, 16, 36

// transform — general; can emit 0, 1, or N times per input
(1..3).asFlow()
    .transform { n ->
        emit("start $n")
        delay(50)
        emit("end $n")
    }
    .collect { println(it) }

// zip — pair corresponding values from two flows (stops at shorter)
val nums  = (1..3).asFlow()
val names = flowOf("one", "two", "three")
nums.zip(names) { n, s -> "$n=$s" }
    .collect { println(it) }  // "1=one", "2=two", "3=three"

// combine — emit whenever *either* flow emits, pairing with latest from the other
val a = (1..3).asFlow().onEach { delay(300) }
val b = flowOf("x", "y", "z").onEach { delay(400) }
a.combine(b) { n, s -> "$n+$s" }.collect { println(it) }
```

**Flattening (flow of flows):**

```kotlin
// flatMapConcat — sequential: finish inner flow before next outer value
// flatMapMerge  — concurrent: collect all inner flows in parallel  
// flatMapLatest — cancel previous inner flow when outer emits a new value

// flatMapLatest is ideal for search-as-you-type:
fun searchResults(query: String): Flow<List<Result>> = flow { /* db query */ emit(emptyList()) }

queryFlow                              // user typing emits queries
    .debounce(300)                     // wait for pause
    .flatMapLatest { query ->          // cancel previous search
        searchResults(query)
    }
    .collect { updateUI(it) }
```

**Terminal operators (suspend, start collection):**

```kotlin
val nums = (1..5).asFlow()

// collect — most common; processes each value
nums.collect { println(it) }

// toList / toSet — materialise to a collection
val list: List<Int> = nums.toList()

// first / single — get one value
val first = nums.first()                    // 1
val only  = flowOf(42).single()             // 42

// reduce / fold — aggregate
val sum = nums.reduce { acc, n -> acc + n } // 15
val sumFrom10 = nums.fold(10) { acc, n -> acc + n } // 25
```

**Backpressure — handling a slow collector:**

```kotlin
// Problem: emitter is fast, collector is slow → sequential bottleneck
fun fastEmitter(): Flow<Int> = flow {
    for (i in 1..5) { emit(i); delay(100) }   // emits every 100ms
}

// buffer(): run emitter and collector in separate coroutines (ring buffer)
fastEmitter()
    .buffer()        // emitter runs ahead; collector processes at its own pace
    .collect { delay(300); println(it) }   // ~1300ms instead of 2000ms

// conflate(): skip intermediate values — keep only the latest
fastEmitter()
    .conflate()      // 1, 3, 5 (2 and 4 skipped because collector was busy)
    .collect { delay(300); println(it) }

// collectLatest { }: cancel the current block when a new value arrives
fastEmitter()
    .collectLatest { value ->
        println("Starting $value")
        delay(300)              // cancelled if next value arrives before 300ms
        println("Done $value")  // only prints for the last value
    }
```

**Exception handling:**

```kotlin
// catch operator: catches upstream exceptions; can emit a fallback value
flowOf(1, 2, 3)
    .map { if (it == 2) throw RuntimeException("bad value") else it }
    .catch { e -> emit(-1) }   // emit fallback; downstream continues
    .collect { println(it) }   // 1, -1, 3... wait: catch only covers upstream

// onCompletion: always-runs callback; knows if completed normally or with error
flowOf(1, 2, 3)
    .onCompletion { cause ->
        if (cause != null) println("Flow failed: $cause")
        else               println("Flow completed")
    }
    .collect { println(it) }

// Declare all exception handling BEFORE collect (exception transparency rule)
// The catch operator does NOT catch exceptions thrown in the collect block:
flowOf(1)
    .catch { println("Won't catch collect errors") }
    .collect { throw RuntimeException("in collect") }  // crashes
// Fix: move logic to onEach before catch, then use parameterless .collect()
flowOf(1)
    .onEach { if (it > 0) throw RuntimeException("in onEach") }
    .catch { println("Caught: $it") }   // now this works
    .collect()                           // parameterless
```

**`flowOn` — change the dispatcher of upstream emissions:**

```kotlin
// WRONG: withContext inside flow {} throws IllegalStateException
fun badFlow(): Flow<Int> = flow {
    withContext(Dispatchers.IO) { emit(fetchFromDb()) }  // ERROR
}

// CORRECT: flowOn shifts upstream to the specified dispatcher
fun goodFlow(): Flow<Int> = flow {
    emit(fetchFromDb())          // runs on IO (set below)
}.flowOn(Dispatchers.IO)         // collect runs on caller's dispatcher

// The operator creates a buffer between dispatchers automatically
goodFlow().collect { value ->    // this runs on the Main / calling dispatcher
    updateUI(value)
}
```

**`StateFlow` and `SharedFlow` — hot flows:**

```kotlin
import kotlinx.coroutines.flow.*

// StateFlow: always has a current value; replays it to new collectors (hot)
class CounterViewModel : ViewModel() {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()   // read-only public face

    fun increment() { _count.value++ }
}

// SharedFlow: configurable replay and buffer; for one-off events
class EventBus {
    private val _events = MutableSharedFlow<String>(
        replay = 0,         // don't replay to late subscribers
        extraBufferCapacity = 64
    )
    val events: SharedFlow<String> = _events.asSharedFlow()

    suspend fun publish(event: String) { _events.emit(event) }
}
```

**Flow cancellation:**

```kotlin
// Flow is automatically cancelled when its collecting coroutine is cancelled
val job = launch {
    (1..10).asFlow()
        .onEach { delay(200) }
        .collect { println("Collected $it") }
}
delay(500)
job.cancel()   // cancels collection cleanly after ~2-3 values

// .cancellable(): add cooperative cancellation checks to flows that don't suspend
(1..Int.MAX_VALUE).asFlow()
    .cancellable()   // checks cancellation on each emission
    .collect { value ->
        if (value == 5) cancel()
        println(value)
    }
```

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

**Collecting a `StateFlow` without `lifecycleScope`/`repeatOnLifecycle`** [community] — Launching `viewModelScope.launch { stateFlow.collect { } }` in an Android Activity/Fragment leaks the coroutine when the app goes to the background. WHY it causes problems: the coroutine keeps receiving updates and doing UI work while the screen is off, wasting resources and causing crashes. Fix: use `lifecycleScope.launch { lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) { stateFlow.collect { } } }` to automatically stop collection when the UI is in the background.

**`flow { }` being collected multiple times without realising it** [community] — Unlike `StateFlow`, a regular `Flow` is cold — each `collect` call restarts the entire chain from scratch, including any network requests or database queries inside. WHY it causes problems: calling `flowOf(...).count()` then `.first()` hits the database twice. Fix: use `stateIn()` to share a single upstream execution across multiple collectors, or materialise to a list when the data is needed more than once.

**`conflate()` instead of `collectLatest { }` for UI updates** [community] — Using `conflate()` drops intermediate values but still runs the collector block for the first value before accepting the next. `collectLatest` cancels the current block and immediately restarts it for the new value — which is usually what UI update code needs. WHY it causes problems: with `conflate()`, if a slow render finishes, it picks up the value that was buffered, not necessarily the latest. Fix: use `collectLatest { updateUI(it) }` for UI rendering; use `conflate()` for stateless processing where dropping intermediate values is intentional.

**Data Class With Mutable Properties** [community] — Declaring a `data class` with `var` properties and then storing instances in a `HashSet` or as `HashMap` keys causes silent corruption. WHY it causes problems: `hashCode()` is computed from the current property values; mutating a property after insertion changes the hash code, making the entry unreachable and uncollectable. Fix: keep `data class` properties `val`-only; if mutation is genuinely needed, use a regular class and implement `equals`/`hashCode` manually with an immutable identity key.

**Sealed Class `else` in Multiplatform `when`** [community] — In Kotlin Multiplatform, if a sealed class is an `expect` declaration, the compiler cannot verify exhaustiveness in common code because platform-specific `actual` implementations can add subclasses. WHY it causes problems: adding a new platform-specific subclass silently falls through without the `else` branch at runtime. Fix: always add an `else` branch in common-code `when` expressions on `expect sealed` classes.

**Scope Function Nesting and Shadowed `this`** [community] — Nesting `apply { run { with ... } }` blocks makes it impossible to reason about which `this` or `it` refers to which object. WHY it causes problems: the inner lambda's `this` shadows the outer one; a single misread causes properties to be set on the wrong object with no compile-time warning. Fix: use at most one scope function per object; introduce an explicit named variable for the outer object if nesting is unavoidable.

**Extension Functions on Nullable Receivers Without Explicit Check** [community] — Extension functions can be declared on nullable types (`fun String?.orEmpty()`), but callers may not realise the receiver can be null, leading to logic bugs. WHY it causes problems: `"".isNullOrEmpty()` calls the same function as `null.isNullOrEmpty()` — the semantics differ, but the call site looks identical. Fix: make the receiver type non-nullable unless null is a meaningful case; prefer `?.` call sites to make nullability visible.

---

## Kotlin 2.0 — K2 Compiler and Smart Cast Improvements

### K2 Compiler Stable

Kotlin 2.0 ships with the **K2 compiler enabled by default** for all platforms (JVM, Native, Wasm, JS). K2 provides a unified compilation architecture with major performance improvements. Existing code is fully compatible; check your build plugins for compatibility before upgrading.

**Migration checklist:**
- Verify all compiler plugins support K2: `all-open`, `no-arg`, `serialization`, `kapt`, `parcelize`, Compose 2.0.0+, KSP2
- Lambda serialization behavior changed: lambdas now use `invokedynamic` by default (smaller bytecode). Add `@JvmSerializableLambda` if you need serializable lambdas, or pass `-Xlambdas=class`
- `kotlinOptions` DSL deprecated — replace with `compilerOptions {}` DSL:

```kotlin
// Deprecated (Kotlin 2.0)
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        allWarningsAsErrors = true
        jvmTarget = "17"
    }
}

// Current (Kotlin 2.0+)
kotlin {
    compilerOptions {
        allWarningsAsErrors.set(true)
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
```

---

### K2 Smart Cast Improvements

The K2 compiler performs smart casts in significantly more scenarios. Code that required explicit null checks or casts in Kotlin 1.x now compiles cleanly.

```kotlin
// 1. Boolean variables used as type-check proxies
class Cat { fun purr() = println("Purr") }

fun petAnimal(animal: Any) {
    val isCat = animal is Cat
    if (isCat) {
        animal.purr()  // ✅ Smart-cast to Cat (required explicit cast in 1.x)
    }
}

// 2. Type checks combined with || operator
interface Status { fun signal() {} }
interface Ok : Status
interface Postponed : Status
interface Declined : Status

fun check(status: Any) {
    if (status is Postponed || status is Declined) {
        status.signal()  // ✅ Smart-cast to common supertype Status
        // In 1.x: compiler could not infer the supertype from || chains
    }
}

// 3. Variables captured in inline lambdas
inline fun inlineAction(f: () -> Unit) = f()

fun runProcessor(): Any? {
    var processor: Any? = null
    inlineAction {
        if (processor != null) {
            processor.toString()  // ✅ No safe-call needed in K2 (required in 1.x)
        }
    }
    return processor
}

// 4. Properties with function types
class Holder(val provider: (() -> Unit)?) {
    fun execute() {
        if (provider != null) {
            provider()  // ✅ Smart-cast works; required !!() in 1.x
        }
    }
}

// 5. After increment/decrement: result type is narrowed
interface Rho { operator fun inc(): Sigma = TODO() }
interface Sigma : Rho { fun sigma() = Unit }
interface Tau : Rho

fun demo(input: Rho) {
    var obj: Rho = input
    if (obj is Tau) {
        ++obj           // obj is now Sigma (return type of Rho::inc)
        obj.sigma()     // ✅ Smart-cast to Sigma; ERROR in 1.x
    }
}
```

---

### Kotlin Multiplatform — Strict Source Set Separation

Kotlin 2.0 enforces **strict separation of common and platform sources**. Common code can no longer accidentally call platform-specific functions — output is now consistent across all platforms.

```kotlin
// BEFORE Kotlin 2.0: common source calling platform function was ambiguous
// common code:
fun foo(x: Any) = println("common foo")
fun example() { foo(42) }  // Called platform foo() on JVM, common foo() on JS!

// AFTER Kotlin 2.0: common code can only call common functions
// foo(42) now consistently calls common foo() everywhere

// CORRECT pattern: use expect/actual for platform-specific implementations
expect fun platformInfo(): String

// JVM actual:
actual fun platformInfo(): String = System.getProperty("os.name") ?: "JVM"

// JS actual:
actual fun platformInfo(): String = js("navigator.platform") as String
```

---

### Power-Assert Compiler Plugin (Kotlin 2.0)

The Power-Assert plugin rewrites assertion calls to include intermediate expression values in failure messages — eliminating the need to write manual assertion messages.

```kotlin
// build.gradle.kts
plugins {
    kotlin("plugin.power-assert") version "2.0.0"
}

powerAssert {
    functions = listOf(
        "kotlin.assert",
        "kotlin.test.assertTrue",
        "kotlin.test.assertEquals",
    )
}

// Test code
val name = "Kotlin"
val greeting = "Hello, $name!"

assert(greeting == "Hello, World!")
// Power-Assert output on failure:
// assert(greeting == "Hello, World!")
//        |         |
//        |         false
//        "Hello, Kotlin!"
// Instead of just: "Assertion failed"
```

---

### `enumEntries<T>()` — Stable Replacement for `enumValues<T>()`

```kotlin
// DEPRECATED: enumValues<T>() creates a new array on every call
inline fun <reified T : Enum<T>> printAll() {
    for (entry in enumValues<T>()) println(entry.name)  // New array each time!
}

// PREFERRED (Kotlin 2.0, Stable): enumEntries<T>() returns a cached list
inline fun <reified T : Enum<T>> printAll() {
    for (entry in enumEntries<T>()) println(entry.name)  // Stable List<T>, cached
}

// Same applies to Enum.entries property (Kotlin 1.9+) for concrete enums:
enum class Direction { NORTH, SOUTH, EAST, WEST }
Direction.entries.forEach { println(it) }  // Preferred over Direction.values()
```

---

## Kotlin 2.1.20 — Common Atomics, UUID, and Clock

### Common Atomic Types (Experimental)

Kotlin 2.1.20 introduces platform-independent atomic types in `kotlin.concurrent.atomics`, enabling multiplatform atomic operations without conditional `expect/actual` code.

```kotlin
import kotlin.concurrent.atomics.*

@OptIn(ExperimentalAtomicApi::class)
class SafeCounter {
    private val count = AtomicInt(0)

    fun increment(): Int = count.incrementAndFetch()
    fun decrement(): Int = count.decrementAndFetch()
    fun get(): Int = count.load()
    fun reset() = count.store(0)

    // compareAndSwap — atomic conditional update
    fun resetIfZero(): Boolean = count.compareAndSwap(expected = 0, newValue = 0)
}

// Interop with java.util.concurrent.atomic
@OptIn(ExperimentalAtomicApi::class)
fun interopExample() {
    val kotlinAtomic = AtomicInt(42)
    val javaAtomic: java.util.concurrent.atomic.AtomicInteger = kotlinAtomic.asJavaAtomic()
    val backToKotlin: AtomicInt = javaAtomic.asKotlinAtomic()
}

// Available types: AtomicInt, AtomicLong, AtomicBoolean, AtomicReference<T>
```

---

### UUID Improvements — Comparable and Multi-Format Parsing

```kotlin
import kotlin.uuid.Uuid

// UUID is now Comparable — sort, compare, use in sorted data structures
val uuids = listOf(
    Uuid.parse("550e8400-e29b-41d4-a716-446655440000"),
    Uuid.parse("6ba7b810-9dad-11d1-80b4-00c04fd430c8"),
)
val sorted = uuids.sorted()  // ✅ New in 2.1.20

// New parsing formats:
val fromHexDash = Uuid.parseHexDash("550e8400-e29b-41d4-a716-446655440000")  // Canonical
val fromHex     = Uuid.parse("550e8400e29b41d4a716446655440000")              // Compact hex
val asHexDash   = fromHex.toHexDashString()                                   // → canonical

// Canonical form is the default for display:
println(Uuid.random())  // e.g., "550e8400-e29b-41d4-a716-446655440000"
```

---

### `kotlin.time.Clock` and `kotlin.time.Instant` — Stdlib Time API

```kotlin
import kotlin.time.*

// System clock — use for production code
val now: Instant = Clock.System.now()

// Arithmetic with Duration
val tomorrow: Instant = now + 24.hours
val yesterday: Instant = now - 1.days

// Interval between two instants
val elapsed: Duration = tomorrow - now  // 24h exactly

// Comparison
println(now < tomorrow)  // true

// Interop with kotlinx-datetime and Java time
val javaInstant: java.time.Instant = now.toJavaInstant()
val kotlinInstant: Instant = javaInstant.toKotlinInstant()

// Testable clock — inject Clock for deterministic tests
class EventScheduler(private val clock: Clock = Clock.System) {
    fun isEventDue(scheduledAt: Instant): Boolean = clock.now() >= scheduledAt
}

// In tests: provide a fixed clock
class TestClock(private val fixed: Instant) : Clock {
    override fun now() = fixed
}
val testScheduler = EventScheduler(TestClock(Instant.parse("2026-01-01T00:00:00Z")))
```

---

### Gradle Isolated Projects Support (Kotlin 2.1.20)

Kotlin Gradle plugins now work with Gradle's **Isolated Projects** feature (enabled with `-Dorg.gradle.unsafe.isolated-projects=true`). No additional configuration is needed — just enable the flag. Isolated Projects configures each project in parallel, improving build configuration time for large multi-project builds.

```kotlin
// Works automatically with Kotlin 2.1.20+ — no special setup needed:
// gradle.properties:
// org.gradle.unsafe.isolated-projects=true

// KMP executable DSL — new in 2.1.20 (replaces deprecated Gradle Application plugin)
kotlin {
    jvm {
        @OptIn(ExperimentalKotlinGradlePluginApi::class)
        binaries {
            executable {
                mainClass.set("com.example.MainKt")
                // Produces runnable JVM artifact without the Application plugin
            }
        }
    }
}
```

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `var` for non-mutating values | Misleads readers; prevents optimizations | Use `val` by default; `var` only when reassignment is required |
| `!!` instead of null-safe operators | Reintroduces `NullPointerException` at runtime | Use `?.`, `?:`, `?.let { }`, or `if (x != null)` smart cast |
| `GlobalScope.launch` | Leaks coroutines past component lifecycle | Use `viewModelScope`, `lifecycleScope`, or a custom scoped `CoroutineScope` |
| `runBlocking` in service code | Blocks thread, starves thread pools | Make call sites `suspend`; use `coroutineScope { }` for structured child coroutines |
| `withContext` inside `flow { }` | Throws `IllegalStateException` at runtime | Use `.flowOn(Dispatcher)` on the flow chain |
| Collecting a `Flow` multiple times from different collectors | Cold flow restarts from scratch each time (DB hit per collector) | Convert to hot flow with `.stateIn(scope, ...)` or `.shareIn(scope, ...)` |
| `conflate()` for UI rendering | Drops intermediate values but finishes slow collector block first | Use `collectLatest { }` to cancel-and-restart on every new value |
| `flow { }` collect without cancellation in Android | Coroutine keeps running in background, wasting resources | Use `repeatOnLifecycle(Lifecycle.State.STARTED)` to auto-stop on background |
| Mutable `var` in `data class` | Keys in sets/maps silently break after mutation | Use `val` properties; implement `equals`/`hashCode` with immutable key if mutation needed |
| Utility class (`StringUtils`, `ObjectHelper`) | Forces static call style; hard to extend | Use extension functions on the relevant type |
| Overloaded constructors instead of defaults | Combinatorial explosion of overloads | Use default parameter values and named arguments |
| Type-unsafe primitive aliases (`Long` for ID, email, order) | Wrong ID type accepted silently | Use `@JvmInline value class` wrappers |
| Nesting scope functions 3+ levels deep | Shadowed `this`/`it`, impossible to read | Flatten with named variables; limit scope function chains to 2 |
| `kotlinOptions {}` DSL (Kotlin 2.0+) | Deprecated; removed in a future Kotlin version | Use `compilerOptions {}` in the new Gradle DSL |
| `enumValues<T>()` | Creates a new array on every call | Use `enumEntries<T>()` (Kotlin 2.0, stable) or `.entries` on concrete enums |
| Lambdas that must be serializable without `@JvmSerializableLambda` | K2 uses `invokedynamic` by default; lambdas are not serializable | Annotate with `@JvmSerializableLambda` or pass `-Xlambdas=class` |
| `expect sealed` class `when` without `else` in multiplatform | New platform-specific subclasses fall through silently | Always add `else` branch in common-code `when` on `expect sealed` |
| Manual `java.util.UUID` in multiplatform code | Only available on JVM; breaks JS/Native/Wasm targets | Use `kotlin.uuid.Uuid` (Kotlin 2.0+ common stdlib) |
| Not injecting `Clock` in time-dependent code | Code coupled to `Clock.System.now()` is not unit-testable | Accept `Clock` as a constructor parameter; default to `Clock.System` in production |
