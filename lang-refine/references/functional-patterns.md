# Functional Patterns & Best Practices
<!-- sources: mixed (training knowledge + community: awesome-fp-js) | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Functions are values**: First-class functions are the foundation. Pass them, return them, store them — this is what unlocks composition, currying, and higher-order abstractions.
2. **Data does not change — it transforms**: Immutability eliminates an entire class of bugs (shared mutable state, race conditions, unexpected aliasing). Instead of mutating, produce a new value.
3. **Referential transparency**: A pure function called with the same arguments always returns the same result and has no observable side effects. This makes code trivially testable, cacheable, and parallelisable.
4. **Composition over conditionals**: Complex logic is assembled from small, single-purpose functions chained together. The pipeline replaces deeply nested if/else trees.
5. **Errors are values, not exceptions**: Represent failure explicitly in the return type (Either/Result) rather than relying on throw/catch for control flow. Callers are forced to handle both cases.

---

## Principles / Patterns

### Pure Functions
A pure function produces output solely from its inputs and causes no side effects (no I/O, no mutation of shared state, no random values). Purity makes functions independently testable and safe to compose.

```python
# Python example — pure vs impure

# IMPURE: depends on external state, mutates the list
items = []
def add_item_impure(item: str) -> None:
    items.append(item)   # Side effect: mutates global

# PURE: same inputs → same output, no side effects
def add_item_pure(existing: list[str], item: str) -> list[str]:
    return [*existing, item]   # Returns a new list

# Testing pure functions is trivial — no setup/teardown needed
assert add_item_pure(["a", "b"], "c") == ["a", "b", "c"]
assert add_item_pure([], "x") == ["x"]
```

```javascript
// JavaScript example

// IMPURE: relies on Date.now() — different result every call
function createTimestampedRecord(name) {
  return { name, createdAt: Date.now() };   // Not pure
}

// PURE: inject the clock dependency so tests can control it
function createRecord(name, timestamp) {
  return { name, createdAt: timestamp };
}

// Deterministic, testable
const record = createRecord("Alice", 1000);
console.assert(record.createdAt === 1000);
```

---

### Immutability
Never mutate data that already exists. Instead, produce a new version of the data with the desired change applied. This eliminates aliasing bugs and makes state changes explicit and traceable.

```javascript
// JavaScript — spread to produce new objects/arrays

const user = { id: 1, name: "Alice", role: "viewer" };

// MUTABLE — dangerous: caller's reference now sees the change
function promoteUser_bad(u) {
  u.role = "admin";   // mutates the original
  return u;
}

// IMMUTABLE — returns a new object; original is untouched
function promoteUser(u) {
  return { ...u, role: "admin" };
}

const promoted = promoteUser(user);
console.log(user.role);     // "viewer" — unchanged
console.log(promoted.role); // "admin"

// For arrays: prefer map/filter/reduce over push/splice/sort
const scores = [5, 3, 8, 1];
const sorted = [...scores].sort((a, b) => a - b); // new array
console.log(scores);  // [5, 3, 8, 1] — original intact
```

```kotlin
// Kotlin — data classes + copy()
data class User(val id: Int, val name: String, val role: String)

val alice = User(id = 1, name = "Alice", role = "viewer")
val promoted = alice.copy(role = "admin")

println(alice.role)    // viewer
println(promoted.role) // admin
```

---

### Referential Transparency
An expression is referentially transparent if it can be replaced with its evaluated value without changing the program's behaviour. Only pure functions with immutable data guarantee this property.

```python
# Python — demonstrating referential transparency

def tax(amount: float, rate: float) -> float:
    """Referentially transparent: result depends only on args."""
    return round(amount * rate, 2)

# These two programs are identical in meaning:
total = tax(100.0, 0.2) + tax(50.0, 0.2)
# Is equivalent to:
total = 20.0 + 10.0   # Values can substitute the calls safely

# Contrast with a non-RT function:
import random
def random_discount(amount: float) -> float:
    return amount * random.random()   # NOT RT — result changes each call
```

---

### First-Class and Higher-Order Functions
Functions are first-class values: they can be passed as arguments, returned from other functions, and stored in data structures. A higher-order function (HOF) takes one or more functions as arguments or returns a function.

```python
# Python — higher-order function examples

from typing import Callable, TypeVar

T = TypeVar("T")
U = TypeVar("U")

# HOF: accepts a function as a parameter
def apply_twice(fn: Callable[[T], T], value: T) -> T:
    return fn(fn(value))

double = lambda x: x * 2
print(apply_twice(double, 3))   # 12  (3 → 6 → 12)

# HOF: returns a function
def make_multiplier(factor: int) -> Callable[[int], int]:
    def multiply(x: int) -> int:
        return x * factor
    return multiply

triple = make_multiplier(3)
print(triple(7))   # 21
print(list(map(triple, [1, 2, 3, 4])))  # [3, 6, 9, 12]
```

---

### map / filter / reduce / flatMap
The core triumvirate of functional data transformation. They replace imperative loops with declarative expressions of intent.

```python
# Python

from functools import reduce

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# map — transform every element
squares = list(map(lambda x: x ** 2, numbers))
# [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

# filter — keep elements matching a predicate
evens = list(filter(lambda x: x % 2 == 0, numbers))
# [2, 4, 6, 8, 10]

# reduce — fold a sequence into a single value
total = reduce(lambda acc, x: acc + x, numbers, 0)
# 55

# flatMap equivalent — flatten a list of lists
nested = [[1, 2], [3, 4], [5, 6]]
flat = [item for sublist in nested for item in sublist]
# or:
flat = list(reduce(lambda acc, xs: acc + xs, nested, []))
# [1, 2, 3, 4, 5, 6]
```

```javascript
// JavaScript — chained map/filter/reduce
const orders = [
  { id: 1, amount: 50,  status: "paid" },
  { id: 2, amount: 200, status: "pending" },
  { id: 3, amount: 75,  status: "paid" },
];

const paidTotal = orders
  .filter(o => o.status === "paid")
  .map(o => o.amount)
  .reduce((sum, amt) => sum + amt, 0);
// 125

// flatMap — flatten one level after mapping
const sentences = ["hello world", "foo bar"];
const words = sentences.flatMap(s => s.split(" "));
// ["hello", "world", "foo", "bar"]
```

---

### Function Composition (pipe / compose)
Composition assembles a pipeline of single-purpose functions where the output of one becomes the input of the next. `pipe` applies left-to-right; `compose` applies right-to-left.

```javascript
// JavaScript — manual pipe and compose implementations

// pipe: f1 → f2 → f3 (data flows left to right)
const pipe = (...fns) => (x) => fns.reduce((v, f) => f(v), x);

// compose: f3 ← f2 ← f1 (data flows right to left — mathematical order)
const compose = (...fns) => (x) => fns.reduceRight((v, f) => f(v), x);

// Single-purpose building blocks
const trim      = (s) => s.trim();
const toLower   = (s) => s.toLowerCase();
const slugify   = (s) => s.replace(/\s+/g, "-");

// Compose a URL slug transformation
const toSlug = pipe(trim, toLower, slugify);

console.log(toSlug("  Hello World  ")); // "hello-world"
console.log(toSlug("  Functional Programming 101  ")); // "functional-programming-101"
```

```python
# Python — compose utility

from functools import reduce
from typing import Callable, Any

def pipe(*fns: Callable) -> Callable:
    """Apply functions left-to-right."""
    return lambda x: reduce(lambda v, f: f(v), fns, x)

trim    = str.strip
to_lower = str.lower
slugify = lambda s: s.replace(" ", "-")

to_slug = pipe(trim, to_lower, slugify)
print(to_slug("  Hello World  "))  # "hello-world"
```

---

### Currying and Partial Application
**Currying** transforms a multi-argument function into a chain of single-argument functions. **Partial application** fixes some arguments of a function, returning a new function that accepts the rest. Both enable reusable, configurable building blocks.

```javascript
// JavaScript — manual curry implementation

function curry(fn) {
  return function curried(...args) {
    if (args.length >= fn.length) {
      return fn(...args);
    }
    return (...more) => curried(...args, ...more);
  };
}

// Curried add — each call fixes one argument
const add = curry((a, b) => a + b);
const add10 = add(10);       // partial application: b still needed
console.log(add10(5));       // 15
console.log(add10(20));      // 30

// Practical example: curried data filter
const filterBy = curry((key, value, items) =>
  items.filter(item => item[key] === value)
);
const filterByStatus = filterBy("status");
const getPaid = filterByStatus("paid");

const orders = [{ status: "paid" }, { status: "pending" }, { status: "paid" }];
console.log(getPaid(orders)); // [{ status: "paid" }, { status: "paid" }]
```

```python
# Python — functools.partial

from functools import partial

def log_message(level: str, component: str, message: str) -> str:
    return f"[{level}][{component}] {message}"

# Partial application fixes the first argument(s)
log_error = partial(log_message, "ERROR")
log_db_error = partial(log_message, "ERROR", "Database")

print(log_error("Auth", "Login failed"))         # [ERROR][Auth] Login failed
print(log_db_error("Connection timeout"))        # [ERROR][Database] Connection timeout
```

---

### Maybe / Option Pattern for Null Safety
The Maybe (or Option) type wraps a value that may or may not be present. Instead of returning `null` and forcing callers to null-check before every use, you represent absence explicitly and chain operations safely.

```python
# Python — simple Maybe implementation

from typing import Callable, Generic, TypeVar, Optional

T = TypeVar("T")
U = TypeVar("U")

class Maybe(Generic[T]):
    """Wraps a possibly-absent value. Chain .map() safely without null checks."""
    def __init__(self, value: Optional[T]) -> None:
        self._value = value

    @classmethod
    def of(cls, value: Optional[T]) -> "Maybe[T]":
        return cls(value)

    def map(self, fn: Callable[[T], U]) -> "Maybe[U]":
        if self._value is None:
            return Maybe(None)
        return Maybe(fn(self._value))

    def get_or_else(self, default: T) -> T:
        return self._value if self._value is not None else default

    def __repr__(self) -> str:
        return f"Maybe({self._value!r})"

# Usage: chain transformations without repeated None checks
user_db = {1: {"name": "Alice", "address": {"city": "Berlin"}}}

def get_user(uid: int):
    return user_db.get(uid)

def get_address(user: dict):
    return user.get("address")

def get_city(addr: dict):
    return addr.get("city")

city = (
    Maybe.of(get_user(1))
    .map(get_address)
    .map(get_city)
    .get_or_else("Unknown")
)
print(city)   # "Berlin"

missing = (
    Maybe.of(get_user(999))   # user 999 doesn't exist
    .map(get_address)
    .map(get_city)
    .get_or_else("Unknown")
)
print(missing)  # "Unknown"  — no AttributeError or NoneType error
```

---

### Either for Error Handling
Either represents a computation that can succeed (`Right`) or fail (`Left`). Unlike exceptions, errors become values that callers must explicitly handle, making the failure path visible in the type signature.

```python
# Python — Either / Result type

from typing import Generic, TypeVar, Callable, Union

L = TypeVar("L")  # Left = failure
R = TypeVar("R")  # Right = success

class Left(Generic[L]):
    def __init__(self, value: L) -> None:
        self.value = value
    def map(self, fn):       return self          # propagate failure
    def flat_map(self, fn):  return self
    def get_or_else(self, default):  return default
    def __repr__(self): return f"Left({self.value!r})"

class Right(Generic[R]):
    def __init__(self, value: R) -> None:
        self.value = value
    def map(self, fn: Callable[[R], any]) -> "Right":
        return Right(fn(self.value))
    def flat_map(self, fn: Callable[[R], Union[Left, "Right"]]):
        return fn(self.value)
    def get_or_else(self, default):  return self.value
    def __repr__(self): return f"Right({self.value!r})"

# Domain functions return Either instead of raising exceptions
def parse_int(s: str) -> Union[Left, Right]:
    try:
        return Right(int(s))
    except ValueError:
        return Left(f"Cannot parse {s!r} as integer")

def safe_divide(a: int, b: int) -> Union[Left, Right]:
    if b == 0:
        return Left("Division by zero")
    return Right(a // b)

# Chain: parse two strings, divide them
result = (
    parse_int("100")
    .flat_map(lambda a: parse_int("5").map(lambda b: (a, b)))
    .flat_map(lambda pair: safe_divide(*pair))
)
print(result)            # Right(20)

failed = (
    parse_int("abc")
    .flat_map(lambda a: parse_int("5").map(lambda b: (a, b)))
    .flat_map(lambda pair: safe_divide(*pair))
)
print(failed)            # Left("Cannot parse 'abc' as integer")
```

---

## Language Idioms

Functional idioms that appear across languages in idiomatic form — not just OOP patterns in functional clothing.

### Destructuring in Pipelines (JavaScript/TypeScript)
```javascript
// Destructuring lets you extract only what a step needs
const users = [
  { id: 1, name: "Alice", score: 88 },
  { id: 2, name: "Bob",   score: 42 },
  { id: 3, name: "Carol", score: 95 },
];

const topNames = users
  .filter(({ score }) => score >= 80)       // destructure in predicate
  .map(({ name }) => name.toUpperCase())    // destructure in transform
  .sort();
// ["ALICE", "CAROL"]
```

### Generator-Based Lazy Sequences (Python)
```python
# Infinite sequences without memory cost
def natural_numbers():
    n = 0
    while True:
        yield n
        n += 1

def take(n, iterable):
    it = iter(iterable)
    return [next(it) for _ in range(n)]

print(take(5, natural_numbers()))   # [0, 1, 2, 3, 4]

# Compose lazy pipelines with generator expressions
from itertools import islice

evens = (n for n in natural_numbers() if n % 2 == 0)
first_ten_evens = list(islice(evens, 10))
# [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
```

### Sealed Classes + when as Pattern Matching (Kotlin)
```kotlin
// Kotlin sealed class acts as algebraic data type
sealed class Result<out T>
data class Success<T>(val value: T) : Result<T>()
data class Failure(val error: String) : Result<Nothing>()

fun parseInt(s: String): Result<Int> = try {
    Success(s.toInt())
} catch (e: NumberFormatException) {
    Failure("Cannot parse '$s' as Int")
}

// Exhaustive when — compiler forces you to handle all cases
fun handleResult(r: Result<Int>): String = when (r) {
    is Success -> "Got: ${r.value}"
    is Failure -> "Error: ${r.error}"
}

println(handleResult(parseInt("42")))    // Got: 42
println(handleResult(parseInt("xyz")))   // Error: Cannot parse 'xyz' as Int
```

### Discriminated Unions (TypeScript)
```typescript
// TypeScript — union type with literal discriminant
type Success<T> = { readonly kind: "success"; readonly value: T };
type Failure    = { readonly kind: "failure"; readonly error: string };
type Result<T>  = Success<T> | Failure;

function parseNumber(s: string): Result<number> {
  const n = Number(s);
  return isNaN(n)
    ? { kind: "failure", error: `Cannot parse "${s}" as number` }
    : { kind: "success", value: n };
}

function describeResult(r: Result<number>): string {
  switch (r.kind) {
    case "success": return `Value: ${r.value}`;
    case "failure": return `Error: ${r.error}`;
    // TypeScript enforces exhaustiveness — missing case is a type error
  }
}
```

### Memoization (cross-language)
```javascript
// JavaScript — generic memoize decorator
function memoize(fn) {
  const cache = new Map();
  return function(...args) {
    const key = JSON.stringify(args);
    if (cache.has(key)) return cache.get(key);
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
}

const fib = memoize(function(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
});

console.log(fib(40)); // 102334155 — fast because results are cached
```

---

## Real-World Gotchas  [community]

### 1. Purity Theatre — Hiding Side Effects in "Pure" Functions  [community]
**What it is:** A function looks pure (no explicit mutation) but actually performs I/O or reads from a closure over mutable state, making it non-deterministic.
**WHY it causes problems:** Tests pass in isolation, but production behaviour diverges because the function secretly depends on external state. The function cannot be safely parallelised, memoised, or replayed.
**How to fix it:** Push all side-effectful operations (I/O, logging, random) to the outer edges. Accept impure dependencies as explicit parameters (dependency injection). Distinguish between pure compute functions and impure orchestrators.

### 2. Composing Async Functions in a Sync Pipeline  [community]
**What it is:** Chaining `.map()` or `pipe()` over functions where some return Promises/Futures without accounting for the async boundary.
**WHY it causes problems:** `[1,2,3].map(asyncFn)` returns `[Promise, Promise, Promise]` — not values. Downstream steps operate on unresolved Promises and produce silent `[object Promise]` strings or NaN.
**How to fix it:** Use `Promise.all(array.map(asyncFn))` for parallel async maps. For sequential async pipelines, `reduce` with `async/await` or use a library that provides async-aware pipe (e.g., `fp-ts`'s `TaskEither`).

### 3. Mutating Inside map / filter / reduce  [community]
**What it is:** Developers use `.map()` but modify external state or mutate the element inside the callback — treating it as a `forEach` with a return value.
**WHY it causes problems:** The function that "maps" values becomes impure. Any memoisation or lazy evaluation breaks. Code reviewers are misled about the function's intent; the pipeline no longer reads as a pure transformation.
**How to fix it:** If you need a side effect, use `forEach`. If you need a transform, return a new value from `map` and do not touch external state.

### 4. Overusing Currying / Point-Free Style  [community]
**What it is:** Writing every function in point-free style (omitting named parameters) and currying all multi-argument functions to satisfy a purity ideal.
**WHY it causes problems:** Stack traces become unreadable (`fn3 → fn2 → fn1 → <anonymous>`). Team members unfamiliar with the style cannot debug or extend the code. Performance suffers from many intermediate closures.
**How to fix it:** Apply currying where it genuinely creates reusable building blocks (e.g., `filterByStatus`). Keep named parameters for functions with 3+ arguments or any function that will appear in stack traces.

### 5. Treating Either/Maybe as an Exception Wrapper  [community]
**What it is:** Wrapping `try/catch` inside a `Right/Left` constructor, then using `Left` anywhere an exception might surface — including programming errors like `TypeError`.
**WHY it causes problems:** Bugs (wrong property name, missing argument) are silently absorbed into `Left` and treated as domain failures. The `Left` channel becomes a black box that swallows unrelated errors.
**How to fix it:** Only use `Either` for **expected, recoverable domain failures** (validation, not-found, permission denied). Let genuine programming errors (null dereference, contract violations) propagate as exceptions so they fail fast and visibly.

### 6. Naive Deep Clone for Immutability  [community]
**What it is:** Using `JSON.parse(JSON.stringify(obj))` or a custom recursive clone before every state update instead of structural sharing.
**WHY it causes problems:** Deep clone is O(n) in object size. On large nested objects it blocks the main thread, causes GC pressure, and drops non-JSON-serialisable values (Date, undefined, circular refs).
**How to fix it:** Use libraries designed for efficient immutable updates: Immer (structural sharing + proxy), Immutable.js (persistent data structures), or at minimum spread only the changed subtree.

### 7. Ignoring Performance of Persistent Closures  [community]
**What it is:** Creating deeply nested closures or long-lived partial applications that hold references to large argument objects.
**WHY it causes problems:** The closure's scope chain prevents the captured objects from being garbage collected. This is a common source of memory leaks in long-running Node.js services and React applications.
**How to fix it:** Be explicit about what a closure captures. Extract large objects to a narrower scope. Use `WeakRef` or `WeakMap` when a closure must reference a large object but should not prevent its collection.

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| Mutation inside map/filter | Breaks the transform contract; misleads readers | Use `forEach` for side effects; keep `map` pure |
| `any` return type on composed pipelines | Type safety lost at composition boundary | Use generic HOF signatures or typed `Result<T>` |
| `null`/`undefined` in pipeline chains | `null.property` crashes at runtime, deep in the pipe | Use Maybe/Option to represent absence explicitly |
| Deep cloning for immutability | O(n) cost, drops non-JSON values, causes GC pressure | Spread only changed subtree; use Immer or Immutable.js |
| Async map without `Promise.all` | Downstream steps receive unresolved Promises | `Promise.all(arr.map(asyncFn))` for parallel; reduce for sequential |
| Exception-driven control flow | Exceptions are invisible in the type system | Use Either/Result for expected failures |
| Point-free everything | Stack traces unreadable; onboarding cost soars | Reserve point-free for simple two-arg compositions |
| Currying 3+-arg functions always | Hard to read, hard to debug, closures pile up | Partial-apply selectively; prefer named parameters at 3+ args |
| Memoizing impure functions | Cache returns stale/wrong results | Memoize only pure, referentially transparent functions |
| Using `reduce` for everything | Misuse as a general loop obscures intent | Use `map`, `filter`, `flatMap` for their named semantics |
