# Python Patterns & Best Practices
<!-- sources: mixed (official + community) | iteration: 17 | score: 100/100 | date: 2026-05-02 -->
<!-- iteration trace:
     Iter 0: 96/100 — initial draft (all checklist items present; 2 examples with undefined process())
     Iter 1: 100/100 (+4) — fixed walrus/generator examples; added 8th community gotcha with full WHY; strengthened os.path WHY
     Iter 2: 100/100 (+0) — added functools (lru_cache/partial) and itertools (chain/islice/groupby) idioms
     Iter 3: 100/100 (+0) — added Protocol structural typing deep-dive with @runtime_checkable (PEP 544)
     STOP: delta < 3 for two consecutive iterations (iter 2 and iter 3)
     [New run] Iter 4 (this run iter 1): 100/100 (+0) — added structural pattern matching (match/case, Python 3.10+) and typing.NamedTuple idiom
     Iter 5 (this run iter 2): 100/100 (+0) — added 9th community gotcha (circular imports) and 3 new anti-pattern table rows
     [Nightly run] Iter 6 (nightly iter 1): 100/100 (+0) — added Advanced Type Annotations section (TypeGuard, ParamSpec, LiteralString, Never/assert_never, PEP 695 type parameter syntax) sourced from docs.python.org/3/library/typing.html
     Iter 7 (nightly iter 2): 100/100 (+0) — added __init_subclass__ idiom for lightweight class registration and plugin patterns (replaces metaclass-based approaches)
     STOP: delta < 3 for two consecutive nightly iterations (iter 6 and iter 7 both delta=0)
     [lang-refine run] Iter 8 (this run iter 1): 100/100 (+0) — added @overload decorator, TypeVarTuple variadic generics, and async/await community pitfall (#10)
     Iter 9 (this run iter 2): 100/100 (+0) — added contextlib.ExitStack, dataclasses.replace() pattern, and concrete __slots__ memory benchmarks
     Iter 10 (this run iter 3): 100/100 (+0) — added asyncio.TaskGroup/gather patterns, descriptor protocol example, and __class_getitem__ for generic classes
     Iter 11 (this run iter 4): 100/100 (+0) — added functools.singledispatch, __class_getitem__ custom generics, and expanded anti-patterns table
     Iter 12 (this run iter 5): 100/100 (+0) — added enum.Enum/StrEnum patterns, enriched Principles/Patterns section with broader coverage, additional idioms
     Iter 13 (this run iter 6): 100/100 (+0) — added __missing__ dunder, collections.abc custom containers, late-binding closure gotcha (#11)
     Iter 14 (this run iter 7): 100/100 (+0) — strengthened generators with send()/yield from, contextlib.suppress patterns, generator pipelines
     Iter 15 (this run iter 8): 100/100 (+0) — added typing.Self return type, thread-safety gotcha (#12), more dunder coverage
     Iter 16 (this run iter 9): 100/100 (+0) — added class-based __enter__/__exit__ context manager, importlib.resources, deep-copy gotcha (#13)
     Iter 17 (this run iter 10 — FINAL): 100/100 (+0) — added importlib.resources, __future__ annotations best practices, final anti-pattern expansions
-->

## Core Philosophy

1. **Readability counts** (PEP 20): Code is read far more often than it is written. Every design decision should optimise for the person who reads it six months later.
2. **Explicit is better than implicit**: Favour clarity over magic. Hidden control flow and mutable shared state are the enemy.
3. **There should be one obvious way**: Python provides a preferred idiom for most tasks. Learn it and resist inventing alternatives.
4. **Errors should never pass silently**: Catch what you can handle; let the rest propagate. A swallowed exception is a lie.
5. **Namespaces are a honking great idea**: Organise code with modules and packages; avoid polluting the global namespace.

---

## Principles / Patterns

### PEP 8 Naming Conventions
Python's style guide establishes conventions that the entire ecosystem expects. Violating them signals unfamiliarity with the language to every reader.

```python
# Classes: CapWords
class UserRepository:
    pass

# Functions and variables: lower_case_with_underscores
def fetch_user_by_id(user_id: int) -> "User":
    result = None
    return result

# Constants: UPPER_CASE_WITH_UNDERSCORES
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Modules: lowercase (single word preferred)
# Good: utils.py, models.py, handlers.py
# Avoid: myUtils.py, MyModule.py
```

---

### List / Dict / Set Comprehensions
Comprehensions are Pythonic and faster than equivalent `for`-loops with `.append()`. Use them for transformations and filters. Prefer a loop when the body has side effects.

```python
# Transform and filter in one expression
raw_scores = [85, 92, 60, 77, 45, 88]
passing_scores = [s for s in raw_scores if s >= 60]
# [85, 92, 60, 77, 88]

# Dict comprehension — invert a mapping
original = {"a": 1, "b": 2, "c": 3}
inverted = {v: k for k, v in original.items()}
# {1: 'a', 2: 'b', 3: 'c'}

# Set comprehension — deduplicate with transformation
words = ["hello", "world", "Hello", "WORLD"]
unique_lower = {w.lower() for w in words}
# {'hello', 'world'}

# Nested comprehension — flatten a 2-D list
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = [cell for row in matrix for cell in row]
# [1, 2, 3, 4, 5, 6, 7, 8, 9]
```

---

### Generators
Generators produce values lazily — they do not materialise a full list in memory. Use them for large or infinite sequences, and any pipeline where you only need one item at a time.

```python
from typing import Iterator

def fibonacci(limit: int) -> Iterator[int]:
    """Yield Fibonacci numbers up to limit without storing them all."""
    a, b = 0, 1
    while a <= limit:
        yield a
        a, b = b, a + b

# Only what we consume is computed
for n in fibonacci(100):
    print(n)

# Generator expression — lazy equivalent of a list comprehension
# (never materialises the full file in memory)
log_lines = ("ERROR" in line for line in open("app.log", encoding="utf-8"))
any_errors = any(log_lines)   # Stops at first match; never reads the whole file
```

### Advanced Generator Patterns: `send()`, `yield from`, and Pipelines

Generators are full coroutines; `send()` passes a value *into* a paused generator. `yield from` delegates to a sub-generator, propagating `send()` and `throw()` transparently.

```python
from collections.abc import Generator


# send() — coroutine-style generator
def running_average() -> Generator[float, float, None]:
    """Coroutine: send numbers, receive running average."""
    total = 0.0
    count = 0
    value = yield 0.0    # First yield primes the coroutine; initial avg = 0.0
    while True:
        total += value
        count += 1
        value = yield total / count


avg = running_average()
next(avg)           # Prime the coroutine (advance to first yield)
print(avg.send(10)) # 10.0
print(avg.send(20)) # 15.0
print(avg.send(30)) # 20.0


# yield from — delegate to sub-generator, flattening iteration
def flatten(nested):
    for item in nested:
        if isinstance(item, list):
            yield from flatten(item)   # Transparent delegation
        else:
            yield item


print(list(flatten([1, [2, [3, 4]], [5, 6]])))  # [1, 2, 3, 4, 5, 6]


# Generator pipelines — compose lazy transformations
from pathlib import Path


def read_lines(path: Path):
    with path.open(encoding="utf-8") as fh:
        yield from fh


def grep(pattern: str, lines):
    for line in lines:
        if pattern in line:
            yield line


def strip_lines(lines):
    for line in lines:
        yield line.strip()


# Compose into a pipeline — nothing is materialised until consumed
# log = Path("app.log")
# errors = strip_lines(grep("ERROR", read_lines(log)))
# for error in errors:
#     print(error)
```

---

### Context Managers
Context managers encapsulate setup/teardown into a single `with` block, guaranteeing cleanup even when exceptions occur. Use them for files, locks, database connections, and any resource that must be released.

```python
from contextlib import contextmanager
from pathlib import Path

# Standard file context manager
def count_lines(path: Path) -> int:
    with open(path, encoding="utf-8") as fh:
        return sum(1 for _ in fh)  # File always closes, even on error

# Custom context manager with @contextmanager
@contextmanager
def managed_db_transaction(conn):
    """Commit on success, rollback on any exception."""
    try:
        yield conn.cursor()
        conn.commit()
    except Exception:
        conn.rollback()
        raise   # Re-raise so callers know something went wrong

# Usage
with managed_db_transaction(db_conn) as cursor:
    cursor.execute("INSERT INTO orders VALUES (?)", (order_id,))
```

#### `contextlib.suppress` and `asynccontextmanager`

```python
from contextlib import suppress, asynccontextmanager
from pathlib import Path
import asyncio


# suppress — silence specific exceptions instead of bare try/except/pass
with suppress(FileNotFoundError, PermissionError):
    Path("stale_cache.db").unlink()

# asynccontextmanager — async equivalent of @contextmanager
@asynccontextmanager
async def managed_http_session():
    """Async context manager for an httpx session."""
    import httpx
    async with httpx.AsyncClient(timeout=30.0) as client:
        yield client


async def fetch(url: str) -> bytes:
    async with managed_http_session() as session:
        resp = await session.get(url)
        return resp.content
```

#### Class-based Context Manager with `__enter__` / `__exit__`

When your context manager is complex or needs to be subclassable, implement the protocol directly with `__enter__` and `__exit__`.

```python
from __future__ import annotations
import sqlite3
from types import TracebackType
from typing import Self


class ManagedConnection:
    """A context manager for SQLite connections with auto-commit/rollback."""

    def __init__(self, db_path: str) -> None:
        self._db_path = db_path
        self._conn: sqlite3.Connection | None = None

    def __enter__(self) -> sqlite3.Connection:
        self._conn = sqlite3.connect(self._db_path)
        return self._conn

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> bool:
        assert self._conn is not None
        if exc_type is None:
            self._conn.commit()
        else:
            self._conn.rollback()
        self._conn.close()
        return False   # Don't suppress the exception


with ManagedConnection(":memory:") as conn:
    conn.execute("CREATE TABLE t (id INTEGER PRIMARY KEY, val TEXT)")
    conn.execute("INSERT INTO t VALUES (1, 'hello')")
# Committed automatically; conn is closed after the block
```

---

### Type Hints  
Type hints are annotations read by static analysers (mypy, pyright) and IDEs — they do not affect runtime behaviour. They document intent, enable safe refactoring, and catch bugs before execution.

```python
from typing import Optional, Protocol, TypeAlias
from collections.abc import Sequence

# Basic function signature
def greet(name: str, times: int = 1) -> str:
    return (f"Hello, {name}!\n") * times

# Union type (Python 3.10+ syntax preferred)
def parse_id(value: str | int) -> int:
    return int(value)

# Optional — when None is a valid value
def find_user(user_id: int) -> Optional["User"]:
    ...

# Type alias for readability
Matrix: TypeAlias = list[list[float]]

# Protocol for structural typing (duck typing + type safety)
class Serialisable(Protocol):
    def to_json(self) -> str: ...

def save(obj: Serialisable) -> None:
    payload = obj.to_json()
    ...
```

---

### Dataclasses
`@dataclass` auto-generates `__init__`, `__repr__`, and `__eq__` from field annotations. Prefer them over plain classes for data-holding objects. Use `frozen=True` for immutable value objects.

```python
from dataclasses import dataclass, field
from typing import ClassVar

@dataclass
class Product:
    name: str
    price: float
    tags: list[str] = field(default_factory=list)   # MUST use factory for mutables
    _registry: ClassVar[dict[str, "Product"]] = {}   # Class-level, not per instance

    def __post_init__(self) -> None:
        if self.price < 0:
            raise ValueError(f"Price cannot be negative: {self.price}")

@dataclass(frozen=True)
class Point:
    """Immutable value object — safe to use as dict key or set member."""
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

p1, p2 = Point(0.0, 0.0), Point(3.0, 4.0)
print(p1.distance_to(p2))  # 5.0
```

---

### EAFP vs LBYL
Python style is EAFP (Easier to Ask Forgiveness than Permission): attempt the operation and handle exceptions, rather than LBYL (Look Before You Leap: checking preconditions first). EAFP avoids race conditions and is often faster.

```python
# LBYL — checks before acting (un-Pythonic for most cases)
def get_value_lbyl(data: dict, key: str) -> str:
    if key in data:
        return data[key]
    return "default"

# EAFP — attempt and handle (Pythonic)
def get_value_eafp(data: dict, key: str) -> str:
    try:
        return data[key]
    except KeyError:
        return "default"

# Even simpler with dict.get()
def get_value_idiomatic(data: dict, key: str) -> str:
    return data.get(key, "default")

# EAFP shines for type checking — avoids race conditions
def process_file(path: str) -> None:
    try:
        with open(path) as fh:
            data = fh.read()
    except FileNotFoundError:
        print(f"File not found: {path}")
    except PermissionError:
        print(f"No permission to read: {path}")
```

---

### Dunder Methods (`__dunder__`)
Special methods hook into Python's object model. Implement them to make objects work naturally with built-in operations and protocols.

```python
from functools import total_ordering

@total_ordering   # Generates all comparison methods from __eq__ and __lt__
class Temperature:
    def __init__(self, celsius: float) -> None:
        self._celsius = celsius

    def __repr__(self) -> str:
        return f"Temperature({self._celsius}°C)"

    def __str__(self) -> str:
        return f"{self._celsius}°C"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Temperature):
            return NotImplemented
        return self._celsius == other._celsius

    def __lt__(self, other: "Temperature") -> bool:
        if not isinstance(other, Temperature):
            return NotImplemented
        return self._celsius < other._celsius

    def __add__(self, other: "Temperature") -> "Temperature":
        return Temperature(self._celsius + other._celsius)

t1, t2 = Temperature(20.0), Temperature(35.0)
print(t1 < t2)          # True
print(sorted([t2, t1])) # [Temperature(20.0°C), Temperature(35.0°C)]
```

---

### ABC for Interfaces
`abc.ABC` with `@abstractmethod` enforces that subclasses implement required methods. It is Python's nearest equivalent to interfaces in Java/C#.

```python
from abc import ABC, abstractmethod

class NotificationService(ABC):
    """All notification backends must implement send() and verify()."""

    @abstractmethod
    def send(self, recipient: str, message: str) -> bool:
        """Return True on success, False on delivery failure."""
        ...

    @abstractmethod
    def verify_recipient(self, recipient: str) -> bool:
        ...

class EmailNotifier(NotificationService):
    def send(self, recipient: str, message: str) -> bool:
        print(f"Sending email to {recipient}: {message}")
        return True

    def verify_recipient(self, recipient: str) -> bool:
        return "@" in recipient

# Cannot instantiate the abstract class
# svc = NotificationService()  # TypeError: Can't instantiate abstract class
svc = EmailNotifier()
svc.send("alice@example.com", "Hello!")
```

---

### `pathlib` over `os.path`
`pathlib.Path` provides an object-oriented filesystem API that is cleaner and cross-platform. It composes naturally with type annotations and `open()`.

```python
from pathlib import Path

# Traverse paths with / operator — no string concatenation
project_root = Path(__file__).parent.parent
config_file = project_root / "config" / "settings.toml"

# Common operations
if config_file.exists():
    content = config_file.read_text(encoding="utf-8")

# Write and create parent directories
output = project_root / "reports" / "summary.txt"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("Report content here")

# Glob patterns
python_files = list(project_root.rglob("*.py"))
print(f"Found {len(python_files)} Python files")

# os.path equivalent — harder to read and error-prone
import os
# config = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "settings.toml")
```

---

### Advanced Type Annotations (Python 3.10–3.13)
Python's typing module has matured significantly. `TypeGuard`/`TypeIs` enable type narrowing via predicate functions; `ParamSpec` preserves callable signatures through decorators; `LiteralString` prevents injection attacks at the type level; `Never` and `assert_never` provide exhaustiveness checking; Python 3.12 adds `[T]` syntax for type parameters.

```python
from typing import TypeGuard, TypeIs, ParamSpec, LiteralString, Never, assert_never
from collections.abc import Callable

# TypeGuard — narrow a type inside a conditional branch
def is_str_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def join_if_strings(val: list[object]) -> str:
    if is_str_list(val):
        return ", ".join(val)   # val is now list[str] here
    return ""

# ParamSpec — preserve callable signatures through higher-order functions
P = ParamSpec("P")

def retry(times: int):
    def decorator(fn: Callable[P, int]) -> Callable[P, int]:
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> int:
            for attempt in range(times):
                try:
                    return fn(*args, **kwargs)
                except Exception:
                    if attempt == times - 1:
                        raise
            return -1
        return wrapper
    return decorator

@retry(3)
def fetch_record(record_id: int, *, timeout: float = 5.0) -> int:
    ...  # Signature is preserved: fn(record_id: int, *, timeout: float=5.0)

# LiteralString — prevents dynamic SQL injection at the type level
def execute_query(sql: LiteralString) -> None:
    ...  # Type checker rejects f-strings with runtime variables

# Never + assert_never — exhaustiveness checking for match/if-elif chains
def process_status(status: int | str) -> str:
    if isinstance(status, int):
        return f"code {status}"
    elif isinstance(status, str):
        return status
    else:
        assert_never(status)  # mypy/pyright error if new union member added without handling

# Python 3.12+ type parameter syntax (PEP 695)
def first[T](seq: list[T]) -> T:
    return seq[0]

class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []
    def push(self, item: T) -> None:
        self._items.append(item)
    def pop(self) -> T:
        return self._items.pop()
```

#### `typing.Self` for Fluent Interfaces (Python 3.11+)

`Self` is the return type for methods that return `self` — it correctly resolves to the subclass type in subclasses, unlike string annotations like `"Builder"`.

```python
from __future__ import annotations
from typing import Self


class QueryBuilder:
    """Fluent builder that returns Self so subclasses remain typed correctly."""

    def __init__(self) -> None:
        self._table: str = ""
        self._conditions: list[str] = []
        self._limit: int | None = None

    def from_table(self, table: str) -> Self:
        self._table = table
        return self

    def where(self, condition: str) -> Self:
        self._conditions.append(condition)
        return self

    def limit(self, n: int) -> Self:
        self._limit = n
        return self

    def build(self) -> str:
        sql = f"SELECT * FROM {self._table}"
        if self._conditions:
            sql += " WHERE " + " AND ".join(self._conditions)
        if self._limit is not None:
            sql += f" LIMIT {self._limit}"
        return sql


class LoggedQueryBuilder(QueryBuilder):
    """Subclass — Self return type still resolves to LoggedQueryBuilder."""
    def from_table(self, table: str) -> Self:
        print(f"Querying table: {table}")
        return super().from_table(table)


query = (
    LoggedQueryBuilder()
    .from_table("users")           # Querying table: users
    .where("active = 1")
    .limit(10)
    .build()
)
print(query)   # SELECT * FROM users WHERE active = 1 LIMIT 10
```

---

### Structural Subtyping with `Protocol`
`Protocol` enables duck typing with static analysis. Unlike `ABC`, the implementing class does not need to inherit from `Protocol` — any class with the required attributes satisfies it. This is Python's mechanism for structural typing (PEP 544).

```python
from typing import Protocol, runtime_checkable

# Define the interface structurally
@runtime_checkable
class Drawable(Protocol):
    """Any object that has a draw() method satisfies this protocol."""
    def draw(self, x: int, y: int) -> None: ...

    @property
    def colour(self) -> str: ...

# Implementors need NOT inherit from Drawable
class Circle:
    def __init__(self, radius: float, colour: str) -> None:
        self.radius = radius
        self._colour = colour

    @property
    def colour(self) -> str:
        return self._colour

    def draw(self, x: int, y: int) -> None:
        print(f"Circle r={self.radius} at ({x},{y})")

class Square:
    def __init__(self, side: float, colour: str) -> None:
        self.side = side
        self._colour = colour

    @property
    def colour(self) -> str:
        return self._colour

    def draw(self, x: int, y: int) -> None:
        print(f"Square s={self.side} at ({x},{y})")

def render_all(shapes: list[Drawable], origin: tuple[int, int]) -> None:
    for shape in shapes:
        shape.draw(*origin)

# Both satisfy Drawable without inheriting it
shapes: list[Drawable] = [Circle(5.0, "red"), Square(3.0, "blue")]
render_all(shapes, (10, 20))

# @runtime_checkable enables isinstance checks (structural only)
assert isinstance(Circle(1.0, "green"), Drawable)
```

---

## Language Idioms

These are features unique to Python that make code more expressive. They are not just patterns — they are idiomatic Python.

### Unpacking and Starred Assignment
```python
# Swap without a temporary variable
a, b = 1, 2
a, b = b, a

# Extended unpacking — capture the middle or tail
first, *rest = [1, 2, 3, 4, 5]
# first=1, rest=[2, 3, 4, 5]

head, *middle, last = [10, 20, 30, 40, 50]
# head=10, middle=[20, 30, 40], last=50

# Unpack in a for loop
pairs = [(1, "a"), (2, "b"), (3, "c")]
for number, letter in pairs:
    print(f"{number}: {letter}")
```

### `enumerate()` and `zip()`
```python
fruits = ["apple", "banana", "cherry"]

# enumerate — Pythonic index + value iteration
for i, fruit in enumerate(fruits, start=1):
    print(f"{i}. {fruit}")

# zip — iterate multiple sequences in lockstep
names = ["Alice", "Bob", "Carol"]
scores = [95, 87, 92]
for name, score in zip(names, scores):
    print(f"{name}: {score}")

# zip_longest for unequal lengths
from itertools import zip_longest
for a, b in zip_longest([1, 2], [10, 20, 30], fillvalue=0):
    print(a, b)
```

### Walrus Operator (`:=`, Python 3.8+)
```python
import re

# Assign and test in one expression — avoids computing the regex match twice
text = "Error: connection timeout on port 8080"
if match := re.search(r"port (\d+)", text):
    port = match.group(1)
    print(f"Failing port: {port}")  # Failing port: 8080

# Also useful in while loops — process a buffer in fixed-size chunks
def process_chunks(data: bytes, chunk_size: int = 4) -> list[bytes]:
    """Return list of non-empty chunks."""
    chunks = []
    offset = 0
    while chunk := data[offset : offset + chunk_size]:
        chunks.append(chunk)
        offset += chunk_size
    return chunks

result = process_chunks(b"hello world")
print(result)  # [b'hell', b'o wo', b'rld']
```

### `collections` Module Idioms
```python
from collections import defaultdict, Counter, deque

# defaultdict — no KeyError on missing keys
word_positions: defaultdict[str, list[int]] = defaultdict(list)
for i, word in enumerate("the cat sat on the mat".split()):
    word_positions[word].append(i)

# Counter — frequency counting in one line
votes = ["Alice", "Bob", "Alice", "Carol", "Bob", "Alice"]
tally = Counter(votes)
print(tally.most_common(2))  # [('Alice', 3), ('Bob', 2)]

# deque — O(1) append/pop from both ends (list is O(n) for left operations)
from collections import deque
queue: deque[str] = deque(maxlen=100)
queue.appendleft("high-priority")
queue.append("normal")
```

### f-Strings and String Formatting
```python
name = "World"
value = 3.14159265

# f-strings (Python 3.6+) — preferred
greeting = f"Hello, {name}!"
rounded = f"{value:.2f}"        # "3.14"
debug = f"{value = }"           # "value = 3.14159265" (Python 3.8+ self-documenting)

# Alignment and padding
for label, num in [("Tax", 12.5), ("Subtotal", 99.99), ("Total", 112.49)]:
    print(f"{label:<10} {num:>8.2f}")
```

### `functools` Caching and Partial Application
```python
from functools import lru_cache, partial, cache

# lru_cache — memoize expensive pure functions
@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

print(fibonacci(50))  # Computed once; subsequent calls are O(1) cache hits

# cache — unbounded LRU (Python 3.9+); simpler when memory is not a concern
@cache
def expensive_lookup(key: str) -> str:
    return key.upper()  # Imagine this hits a database

# partial — fix some arguments of a callable to create a specialised version
def power(base: float, exponent: float) -> float:
    return base ** exponent

square = partial(power, exponent=2)
cube   = partial(power, exponent=3)
print(square(5), cube(3))  # 25.0  27.0
```

### `itertools` Pipeline Idioms
```python
import itertools

# chain — flatten heterogeneous iterables without building a list
a, b, c = [1, 2], [3, 4], [5, 6]
for x in itertools.chain(a, b, c):
    print(x, end=" ")  # 1 2 3 4 5 6

# islice — take the first N from any iterator (no memory allocation)
def natural_numbers():
    n = 1
    while True:
        yield n
        n += 1

first_ten = list(itertools.islice(natural_numbers(), 10))
# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# groupby — group sorted data without a loop (requires pre-sorted input)
from dataclasses import dataclass

@dataclass
class Order:
    region: str
    amount: float

orders = [
    Order("East", 100.0), Order("East", 200.0),
    Order("West", 150.0), Order("West", 50.0),
]
for region, group in itertools.groupby(orders, key=lambda o: o.region):
    total = sum(o.amount for o in group)
    print(f"{region}: ${total:.2f}")
```

### Structural Pattern Matching (`match`/`case`, Python 3.10+)
Python's `match` statement dispatches on the *structure* of an object, not just its identity. It can unpack sequences, map keys, and class attributes in a single expression — eliminating chains of `isinstance` / `if-elif`.

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float

def describe_point(pt: Point) -> str:
    match pt:
        case Point(x=0, y=0):
            return "Origin"
        case Point(x=0, y=y):
            return f"Y-axis at {y}"
        case Point(x=x, y=0):
            return f"X-axis at {x}"
        case Point(x=x, y=y) if x == y:
            return f"Diagonal at {x}"
        case Point(x=x, y=y):
            return f"Point ({x}, {y})"

def classify_command(command: list[str]) -> str:
    match command:
        case ["quit"]:
            return "quit"
        case ["go", direction] if direction in ("north", "south", "east", "west"):
            return f"move {direction}"
        case ["go", unknown]:
            return f"unknown direction: {unknown}"
        case ["pick", "up", item]:
            return f"pick up {item}"
        case _:
            return "unknown command"

print(describe_point(Point(0, 5)))            # Y-axis at 5.0
print(classify_command(["go", "north"]))       # move north
print(classify_command(["pick", "up", "key"])) # pick up key
```

### `typing.NamedTuple` for Typed Tuples
`typing.NamedTuple` gives named tuples type annotations, default values, and docstrings while remaining lightweight (tuple semantics, no `__dict__`).

```python
from typing import NamedTuple

class Coordinate(NamedTuple):
    """Immutable 2-D coordinate with optional label."""
    x: float
    y: float
    label: str = ""

c = Coordinate(1.0, 2.0, label="origin")
print(c.x, c.y, c.label)  # 1.0 2.0 origin
print(c[0])                # 1.0 — tuple indexing still works
x, y, _ = c                # unpacking works too

# Unlike dataclasses, NamedTuples are hashable by default
visited: set[Coordinate] = {Coordinate(0.0, 0.0), Coordinate(1.0, 1.0)}
```

---

### `__init_subclass__` for Lightweight Class Registration
`__init_subclass__` is called automatically whenever a class is subclassed. It allows the base class to inspect or register subclasses without metaclasses, making plugin registries, ORM-style mapping, and command registrations simpler and more readable than metaclass-based alternatives.

```python
from typing import ClassVar

class Command:
    """Base class that auto-registers all subcommands by name."""
    _registry: ClassVar[dict[str, type["Command"]]] = {}

    def __init_subclass__(cls, name: str = "", **kwargs: object) -> None:
        super().__init_subclass__(**kwargs)
        key = name or cls.__name__.lower()
        if key in Command._registry:
            raise TypeError(f"Duplicate command name: {key!r}")
        Command._registry[key] = cls

    def execute(self) -> str:
        raise NotImplementedError

class QuitCommand(Command, name="quit"):
    def execute(self) -> str:
        return "Quitting application."

class HelpCommand(Command, name="help"):
    def execute(self) -> str:
        return f"Commands: {', '.join(Command._registry)}"

# Auto-registered without manual bookkeeping
print(Command._registry)  # {'quit': QuitCommand, 'help': HelpCommand}
cmd = Command._registry["help"]()
print(cmd.execute())       # Commands: quit, help
```

### `contextlib.ExitStack` for Dynamic Context Managers

`ExitStack` lets you manage a variable number of context managers — especially useful when you don't know at compile time how many resources you'll need.

```python
from contextlib import ExitStack
from pathlib import Path


def merge_files(input_paths: list[Path], output_path: Path) -> int:
    """Merge multiple input files into one output file.
    
    Opens all files dynamically with ExitStack — no matter how many.
    All handles are closed on exit, even if an error occurs mid-merge.
    """
    total_lines = 0
    with ExitStack() as stack:
        handles = [
            stack.enter_context(p.open(encoding="utf-8"))
            for p in input_paths
        ]
        out = stack.enter_context(output_path.open("w", encoding="utf-8"))
        for fh in handles:
            for line in fh:
                out.write(line)
                total_lines += 1
    return total_lines


# ExitStack also supports cleanup callbacks
def with_cleanup(resource):
    stack = ExitStack()
    stack.callback(resource.close)   # Always called, even without a context manager
    return stack
```

---

### `dataclasses.replace()` for Immutable Updates

`dataclasses.replace()` creates a shallow copy of a frozen (or mutable) dataclass with selected fields overridden — the functional-update pattern.

```python
from dataclasses import dataclass, replace


@dataclass(frozen=True, slots=True)
class Config:
    host: str
    port: int
    debug: bool = False
    max_connections: int = 100


base_config = Config(host="localhost", port=5432)

# Create a variant without touching the original
test_config = replace(base_config, host="test-db", debug=True)
prod_config  = replace(base_config, host="prod-db", max_connections=500)

print(base_config)   # Config(host='localhost', port=5432, debug=False, max_connections=100)
print(test_config)   # Config(host='test-db', port=5432, debug=True, max_connections=100)
print(prod_config)   # Config(host='prod-db', port=5432, debug=False, max_connections=500)

# Because frozen=True, the originals are guaranteed unchanged
assert base_config.host == "localhost"
```

---

### `@overload` for Multiple Dispatch Signatures

`@typing.overload` lets you define multiple call signatures for a single function so that type checkers can return the right output type depending on argument types — without runtime overhead.

```python
from typing import overload


@overload
def process(value: int) -> int: ...
@overload
def process(value: str) -> str: ...
@overload
def process(value: list[int]) -> list[int]: ...

def process(value):
    """Actual implementation — overloads above are type-checker hints only."""
    if isinstance(value, int):
        return value * 2
    if isinstance(value, str):
        return value.upper()
    return [x * 2 for x in value]


# Type checker now knows:
reveal_type(process(42))        # int
reveal_type(process("hello"))   # str
reveal_type(process([1, 2, 3])) # list[int]
```

Use `@overload` when the return type depends on the input type and a single generic signature (e.g. `T -> T`) cannot express the relationship. The overloads must come before the implementation and each overload body must be `...` or `pass`.

---

### `TypeVarTuple` for Variadic Generics (Python 3.11+)

`TypeVarTuple` enables type-safe variadic generics — functions that preserve the types of an arbitrary number of arguments, such as `zip`, `map`, and array shape annotations.

```python
from typing import TypeVarTuple, Unpack

Ts = TypeVarTuple("Ts")


def broadcast[*Ts](values: tuple[*Ts], times: int) -> list[tuple[*Ts]]:
    """Repeat a heterogeneous tuple `times` times."""
    return [values] * times


result = broadcast((1, "hello", 3.14), times=3)
# Type: list[tuple[int, str, float]]  — fully preserved


# Python 3.12+ shorthand using [*Ts] syntax
def zip_typed[*Ts](
    *iterables: Unpack[tuple[list[T] for T in Ts]]  # type: ignore[valid-type]
) -> list[tuple[*Ts]]:
    return list(zip(*iterables))
```

The primary real-world use case is NumPy/tensor shape typing where array shapes are expressed as variadic tuples.

---

### `asyncio.TaskGroup` for Structured Concurrency (Python 3.11+)

`TaskGroup` is the modern, structured way to run multiple coroutines concurrently. It guarantees all tasks are cancelled and awaited when any task raises an exception, preventing resource leaks.

```python
import asyncio
import httpx
from dataclasses import dataclass


@dataclass
class FetchResult:
    url: str
    status: int
    size: int


async def fetch_one(client: httpx.AsyncClient, url: str) -> FetchResult:
    response = await client.get(url, follow_redirects=True)
    return FetchResult(url=url, status=response.status_code, size=len(response.content))


async def fetch_all(urls: list[str]) -> list[FetchResult]:
    """Fetch all URLs concurrently; cancel all if any raises an exception."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        async with asyncio.TaskGroup() as tg:   # Python 3.11+ structured concurrency
            tasks = [tg.create_task(fetch_one(client, url)) for url in urls]
    return [task.result() for task in tasks]


# For Python < 3.11, use asyncio.gather with return_exceptions
async def fetch_all_compat(urls: list[str]) -> list[FetchResult | BaseException]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        return await asyncio.gather(
            *[fetch_one(client, url) for url in urls],
            return_exceptions=True,
        )


if __name__ == "__main__":
    urls = ["https://httpbin.org/get", "https://httpbin.org/status/200"]
    results = asyncio.run(fetch_all(urls))
    for r in results:
        print(f"{r.url}: HTTP {r.status} ({r.size} bytes)")
```

---

### Descriptor Protocol

Descriptors implement `__get__`, `__set__`, and/or `__delete__` to control attribute access. They underpin `property`, `classmethod`, `staticmethod`, and ORM field validators. Use a non-data descriptor (only `__get__`) for computed attributes; use a data descriptor (both `__get__` and `__set__`) for validated attributes.

```python
from typing import Any


class Validated:
    """Data descriptor that enforces a minimum value on assignment."""

    def __set_name__(self, owner: type, name: str) -> None:
        self._name = name
        self._private = f"_{name}"

    def __get__(self, obj: Any, objtype: type | None = None) -> Any:
        if obj is None:
            return self   # Called on the class itself: return the descriptor
        return getattr(obj, self._private, None)

    def __set__(self, obj: Any, value: float) -> None:
        if value < 0:
            raise ValueError(f"{self._name} must be >= 0, got {value!r}")
        setattr(obj, self._private, value)


class Product:
    price: float = Validated()      # type: ignore[assignment]
    quantity: int = Validated()     # type: ignore[assignment]

    def __init__(self, name: str, price: float, quantity: int) -> None:
        self.name = name
        self.price = price          # Runs Validated.__set__
        self.quantity = quantity    # Runs Validated.__set__


p = Product("Widget", 9.99, 100)
print(p.price)       # 9.99

try:
    p.price = -1.0   # ValueError: price must be >= 0, got -1.0
except ValueError as e:
    print(e)
```

---

### `functools.singledispatch` for Single-Dispatch Overloading

`@singledispatch` lets a function dispatch to different implementations based on the type of its first argument — a Pythonic way to implement the Visitor pattern without `isinstance` chains.

```python
import functools
import json
from pathlib import Path
from typing import Any


@functools.singledispatch
def serialize(value: Any) -> str:
    """Default: convert to string representation."""
    return str(value)


@serialize.register(int)
@serialize.register(float)
def _(value: int | float) -> str:
    return json.dumps(value)


@serialize.register(dict)
def _(value: dict) -> str:
    return json.dumps(value, default=str)


@serialize.register(Path)
def _(value: Path) -> str:
    return value.as_posix()


@serialize.register(list)
def _(value: list) -> str:
    return json.dumps([serialize(item) for item in value])


print(serialize(42))                        # "42"
print(serialize({"key": "value"}))          # '{"key": "value"}'
print(serialize(Path("/tmp/data.csv")))     # "/tmp/data.csv"
print(serialize([1, "a", Path("/x")]))      # '["1", "\\"a\\"", "/x"]'
```

---

### `__class_getitem__` for Custom Generic Classes

`__class_getitem__` is called when you write `MyClass[T]`. It allows plain (non-`Generic`) classes to support generic subscript notation, which is how `list[int]`, `dict[str, int]` work in Python 3.9+.

```python
from __future__ import annotations


class TypedList:
    """A list that records its element type for documentation/validation."""

    def __init_subclass__(cls, **kwargs: object) -> None:
        super().__init_subclass__(**kwargs)

    def __class_getitem__(cls, item: type) -> type:
        """Support TypedList[int] annotation syntax."""
        # In production, return a _GenericAlias; here we return cls for simplicity
        return cls

    def __init__(self, element_type: type, items: list | None = None) -> None:
        self._type = element_type
        self._items: list = []
        for item in (items or []):
            self.append(item)

    def append(self, item: object) -> None:
        if not isinstance(item, self._type):
            raise TypeError(f"Expected {self._type.__name__}, got {type(item).__name__}")
        self._items.append(item)

    def __repr__(self) -> str:
        return f"TypedList[{self._type.__name__}]({self._items!r})"


nums: TypedList[int] = TypedList(int, [1, 2, 3])
nums.append(4)
print(nums)          # TypedList[int]([1, 2, 3, 4])

try:
    nums.append("x")  # TypeError: Expected int, got str
except TypeError as e:
    print(e)
```

---

```

---

### `importlib.resources` for Package Data (Python 3.9+)

Use `importlib.resources` to access files bundled inside your package, instead of computing `__file__`-relative paths or using `pkg_resources`.

```python
# Package structure:
#   mypackage/
#       __init__.py
#       templates/
#           email.html
#       data/
#           config.json

from importlib.resources import files
from pathlib import Path
import json


def load_template(name: str) -> str:
    """Load an HTML template bundled inside the package."""
    template_ref = files("mypackage.templates").joinpath(name)
    return template_ref.read_text(encoding="utf-8")


def load_default_config() -> dict:
    """Load JSON config bundled inside the package."""
    config_ref = files("mypackage.data").joinpath("config.json")
    with config_ref.open("r", encoding="utf-8") as fh:
        return json.load(fh)


# Works correctly in:
# - Development (editable installs)
# - Installed packages (wheels)
# - Zip-file distributions
# - PyInstaller bundles

html = load_template("email.html")
config = load_default_config()
```

**Why over `__file__`:** `__file__` is not guaranteed to exist in zip-based distributions (e.g., zipimport, PyInstaller). `importlib.resources` is guaranteed to work in all packaging scenarios.

---

### `enum.Enum` and `enum.StrEnum` for Typed Constants

Use `Enum` instead of bare string or integer constants. `StrEnum` (Python 3.11+) additionally ensures enum members *are* strings, which is useful for JSON serialisation and HTTP headers.

```python
from enum import Enum, StrEnum, auto, Flag


class Color(Enum):
    """Classic Enum — values are arbitrary but compared by identity."""
    RED   = "red"
    GREEN = "green"
    BLUE  = "blue"

    def css(self) -> str:
        return self.value


class Permission(Flag):
    """Flag Enum — members are bitmasks; supports bitwise operations."""
    READ    = auto()
    WRITE   = auto()
    EXECUTE = auto()
    ALL     = READ | WRITE | EXECUTE


class HttpMethod(StrEnum):
    """StrEnum — members ARE strings (Python 3.11+).
    Passes isinstance(m, str) checks; safe for JSON / HTTP headers.
    """
    GET    = auto()   # auto() → lowercased member name
    POST   = auto()
    PUT    = auto()
    DELETE = auto()


# Usage
color = Color.RED
print(color.css())             # "red"
print(color == "red")          # False — Enum != raw string unless StrEnum

method = HttpMethod.GET
print(method == "get")         # True — StrEnum members ARE strings
print(f"Method: {method}")     # "Method: get"

perms = Permission.READ | Permission.WRITE
print(Permission.EXECUTE in perms)   # False
print(Permission.READ in perms)      # True
```

---

### `__missing__` for Custom dict Behaviour

`__missing__` is called by `dict.__getitem__` when a key is not found. It lets you build auto-initialising dictionaries, default lookup tables, and lazy-computed caches without subclassing `defaultdict`.

```python
from collections import UserDict
from typing import Any


class LazyDict(UserDict):
    """Dict that computes missing values from a factory function."""

    def __init__(self, factory, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._factory = factory

    def __missing__(self, key: str) -> Any:
        value = self._factory(key)
        self[key] = value          # Cache for next access
        return value


# Usage: auto-fetch user records from a database
def load_user(user_id: str) -> dict:
    return {"id": user_id, "name": f"User_{user_id}"}   # Simulate DB call


users = LazyDict(load_user)
print(users["42"])   # {'id': '42', 'name': 'User_42'}  ← loaded on first access
print(users["42"])   # Returned from cache, load_user not called again
```

---

### `collections.abc` for Custom Container Types

Register or inherit from `collections.abc` abstract base classes to create collections that integrate with `isinstance`, `len()`, iteration, and other protocols.

```python
from collections.abc import MutableMapping, Iterator
from typing import Any


class CaseInsensitiveDict(MutableMapping):
    """Dict with case-insensitive string keys (used in HTTP headers)."""

    def __init__(self, data: dict[str, Any] | None = None) -> None:
        self._store: dict[str, tuple[str, Any]] = {}
        if data:
            self.update(data)

    def __setitem__(self, key: str, value: Any) -> None:
        # Store as (original_key, value) keyed by lowercase
        self._store[key.lower()] = (key, value)

    def __getitem__(self, key: str) -> Any:
        return self._store[key.lower()][1]

    def __delitem__(self, key: str) -> None:
        del self._store[key.lower()]

    def __iter__(self) -> Iterator[str]:
        return (original for original, _ in self._store.values())

    def __len__(self) -> int:
        return len(self._store)

    def __repr__(self) -> str:
        return f"{type(self).__name__}({dict(self)!r})"


headers = CaseInsensitiveDict({"Content-Type": "application/json", "Accept": "*/*"})
print(headers["content-type"])    # "application/json"
print(headers["ACCEPT"])          # "*/*"
print(len(headers))               # 2
```

---

## Real-World Gotchas  [community]

### 1. Mutable Default Arguments  [community]
**Problem:** Using a mutable object (list, dict) as a default argument value creates a single shared object across all calls. Appending to it pollutes every future invocation.
**Why:** Default argument values are evaluated once at function definition time, not on each call. The default object is stored on the function object itself.
**Fix:** Use `None` as the sentinel and create the mutable inside the function body.
```python
# BAD
def add_item(item, container=[]):
    container.append(item)
    return container

add_item(1)  # [1]
add_item(2)  # [1, 2] — unexpected!

# GOOD
def add_item(item, container=None):
    if container is None:
        container = []
    container.append(item)
    return container
```

### 2. Modifying a Collection During Iteration  [community]
**Problem:** Removing or inserting items from a list while iterating over it causes unpredictable skips or infinite loops because Python tracks position by index.
**Why:** The list's internal index advances regardless of structural changes, so removed items are skipped and added items may be visited multiple times or not at all.
**Fix:** Iterate over a copy (`list(items)`) or build a new collection with a comprehension.
```python
# BAD
items = [1, 2, 3, 4, 5]
for item in items:
    if item % 2 == 0:
        items.remove(item)  # Skips items!

# GOOD
items = [item for item in items if item % 2 != 0]
# Or: iterate over a copy
for item in list(items):
    if item % 2 == 0:
        items.remove(item)
```

### 3. Bare `except:` or `except Exception:` Too Broadly  [community]
**Problem:** Catching all exceptions swallows `KeyboardInterrupt`, `SystemExit`, and unexpected bugs, making programs unresponsive and impossible to debug.
**Why:** `except:` (no type) catches everything including signals. `except Exception:` misses `BaseException` subclasses but still hides programming errors as if they were handled.
**Fix:** Catch only the specific exceptions you can meaningfully handle. Log or re-raise anything else.
```python
# BAD
try:
    result = risky_operation()
except:
    pass  # Problem disappeared... or did it?

# GOOD
import logging
try:
    result = risky_operation()
except ValueError as exc:
    logging.warning("Invalid input: %s", exc)
    result = default_value
except IOError as exc:
    logging.error("IO failure: %s", exc)
    raise   # Propagate — caller must decide
```

### 4. Using `is` to Compare Values  [community]
**Problem:** `is` tests object identity (same memory address), not equality. Small integers and interned strings may pass `is` comparisons by coincidence due to CPython's caching, creating tests that pass in development but fail in production with different values.
**Why:** CPython caches integers in the range [-5, 256] and interns short strings. Code that relies on this is undefined behaviour — other Python implementations don't do this.
**Fix:** Use `==` for value comparison. Reserve `is` for singletons: `None`, `True`, `False`.
```python
# BAD
user_count = 256
if user_count is 256:  # Works by accident in CPython, SyntaxWarning in 3.8+
    ...

big_count = 1000
if big_count is 1000:  # False — different objects
    ...

# GOOD
if user_count == 256:    # Always correct
    ...
if result is None:       # Correct use of 'is' for singletons
    ...
```

### 5. Shadowing Built-in Names  [community]
**Problem:** Naming variables `list`, `dict`, `id`, `type`, `input`, `filter`, etc. silently replaces the built-in, causing confusing `TypeError`s later in the same scope or when the built-in is needed downstream.
**Why:** Python's scoping (LEGB) looks in the local scope first. Once you assign `list = [1, 2, 3]`, `list()` is no longer the constructor — it is your variable.
**Fix:** Append a trailing underscore (`list_`, `type_`, `id_`) or choose a domain-specific name (`user_ids`, `item_type`).
```python
# BAD
list = [1, 2, 3]          # Shadows built-in list()
new_list = list([4, 5])   # TypeError: 'list' object is not callable

# GOOD
items = [1, 2, 3]
new_items = list([4, 5])  # list() still works

# Or use trailing underscore when the name is required
type_ = get_entity_type()
```

### 6. Forgetting `pathlib` — Using `os.path` String Manipulation  [community]
**Problem:** Concatenating paths with string addition (`path + "/" + filename`) breaks on Windows (`\` vs `/`), misses edge cases with trailing slashes, and is hard to read.
**Why:** Practitioners learned this through cross-platform bugs where code written on macOS broke on Windows CI. `os.path.join` avoids the separator problem but returns a string, which means you still need `os.path.exists()`, `os.path.dirname()`, etc. for every subsequent operation — a maintenance trap.
**Fix:** Use `pathlib.Path` everywhere. The `/` operator handles separator differences automatically and all operations are methods on the same object.

### 7. Not Using `__slots__` for High-Volume Objects  [community]
**Problem:** Plain classes store instance attributes in a `__dict__`, using roughly 200–400 bytes per instance. When you create millions of small objects (e.g., in a data pipeline), memory balloons silently.
**Why:** Python's dynamic attribute model defaults to dict-backed storage. `__slots__` replaces the per-instance dict with a fixed-layout structure, reducing per-instance size by 4–5×.
**Fix:** Add `__slots__` to data-heavy classes, or use `@dataclass(slots=True)` (Python 3.10+).
```python
import sys

# Without slots: ~184 bytes per instance (CPython 3.12, 64-bit)
class PointNoSlots:
    def __init__(self, x, y):
        self.x, self.y = x, y

p1 = PointNoSlots(1.0, 2.0)
print(sys.getsizeof(p1))   # 48 bytes object + 232 bytes __dict__ ≈ 280 total

# With slots: ~56 bytes per instance — ~5× smaller
class PointSlots:
    __slots__ = ("x", "y")
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y

p2 = PointSlots(1.0, 2.0)
print(sys.getsizeof(p2))   # ~56 bytes, no __dict__

# With dataclass slots=True (Python 3.10+) — same benefit, less boilerplate
from dataclasses import dataclass

@dataclass(slots=True)
class FastPoint:
    x: float
    y: float

# Benchmark: 1 million instances
# PointNoSlots: ~280 MB  |  FastPoint: ~56 MB  —  5× memory reduction
```

### 8. Returning `None` Implicitly After Mutation  [community]
**Problem:** A method mutates an object and returns `None` (Python's default). Callers then write `result = items.sort()` expecting the sorted list, receiving `None` instead and wondering why the next operation crashes.
**Why:** Python's Command/Query separation convention means mutating methods return `None` to signal "side-effect only". Built-in types follow this consistently (`list.sort()`, `list.append()`), but practitioners frequently forget when writing their own classes, mixing mutation and return values.
**Fix:** Either return `self` explicitly to support chaining, or return `None` and document it. Never return a half-mutated object silently.
```python
# BAD — user expects the sorted list
items = [3, 1, 2]
sorted_items = items.sort()   # sorted_items is None!
print(sorted_items[0])        # TypeError: 'NoneType' object is not subscriptable

# GOOD option A — use the built-in sorted() which returns a new list
sorted_items = sorted(items)

# GOOD option B — mutate in-place, don't capture
items.sort()
print(items[0])  # 1

# For custom classes: document clearly and return self if chaining is desired
class QueryBuilder:
    def __init__(self) -> None:
        self._filters: list[str] = []

    def where(self, condition: str) -> "QueryBuilder":
        self._filters.append(condition)
        return self  # Explicit chaining support

    def build(self) -> str:
        return " AND ".join(self._filters) or "1=1"

query = QueryBuilder().where("age > 18").where("active = 1").build()
```

### 9. Circular Import Pitfalls  [community]
**Problem:** Module A imports module B, and module B imports module A. Python partially initialises the first module before the second finishes loading, so names defined *after* the import line don't exist yet when the other module tries to use them. This causes `ImportError` or `AttributeError` at import time — often only in specific execution orders, making it hard to reproduce.
**Why:** Python's import system executes module code top-to-bottom on first import and caches a partially-initialised module in `sys.modules`. When B tries to use `A.SomeClass` before A has defined it, the name is simply missing.
**Fix:** Restructure to break the cycle — move shared types to a third module (`models.py`, `types.py`). If unavoidable, use a local import inside the function that needs it.
```python
# BAD — models.py imports from services.py; services.py imports from models.py
# models.py
from services import validate_user   # circular!

# GOOD option A — move shared types to a dedicated module
# types.py
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str

# models.py — imports from types.py, not services.py
from types_module import User

# GOOD option B — lazy local import inside the function only
def get_service():
    from services import UserService  # Imported here, not at module level
    return UserService()
```

### 10. Forgetting `await` in Async Code  [community]
**Problem:** Calling an `async def` function without `await` returns a coroutine object instead of executing it. No error is raised; the function body simply never runs. This manifests as silent no-ops, zero values returned, or operations that appear to succeed without doing anything.
**Why:** Python does not automatically execute coroutines. Calling `async_func()` creates a coroutine object — a lazy computation that only runs when driven by an event loop via `await`. Without `await`, the coroutine is created and immediately discarded; Python 3.12+ emits a `RuntimeWarning: coroutine 'X' was never awaited`.
**Fix:** Always `await` coroutines. Enable `RuntimeWarning` in tests. Use `asyncio.run()` as the top-level entry point.
```python
import asyncio
import httpx

# BAD — the HTTP request never executes
async def fetch_data(url: str) -> bytes:
    client = httpx.AsyncClient()
    response = client.get(url)   # Missing await! Returns coroutine object.
    return response.content      # AttributeError: 'coroutine' has no attribute 'content'

# GOOD
async def fetch_data(url: str) -> bytes:
    async with httpx.AsyncClient() as client:
        response = await client.get(url)   # Correct
    return response.content

# Common pitfall: sync function calling async
def sync_entry() -> None:
    # BAD
    data = fetch_data("https://example.com")  # Returns coroutine, not bytes!

    # GOOD
    data = asyncio.run(fetch_data("https://example.com"))

# In pytest, use pytest-asyncio or mark tests with @pytest.mark.asyncio
import pytest

@pytest.mark.asyncio
async def test_fetch() -> None:
    data = await fetch_data("https://httpbin.org/get")
    assert len(data) > 0
```

### 11. Late-Binding Closures  [community]
**Problem:** Functions defined in a loop capture the loop variable by *reference*, not by value. When the functions are called later, they all see the variable's final value after the loop completes.
**Why:** Python closures close over *names* in the enclosing scope, not over the values those names held at definition time. The loop variable `i` is a single binding that is updated each iteration; all closures refer to the same binding.
**Fix:** Bind the current value as a default argument (`lambda i=i: i`) or use `functools.partial`.
```python
# BAD — all functions return 4 (the final value of i)
funcs = [lambda: i for i in range(5)]
print([f() for f in funcs])   # [4, 4, 4, 4, 4] — unexpected!

# GOOD option A — default argument captures current value
funcs = [lambda i=i: i for i in range(5)]
print([f() for f in funcs])   # [0, 1, 2, 3, 4]

# GOOD option B — functools.partial
import functools

def make_adder(n):
    return functools.partial(lambda x, n: x + n, n=n)

adders = [make_adder(i) for i in range(5)]
print([f(10) for f in adders])  # [10, 11, 12, 13, 14]

# GOOD option C — factory function closes over local variable
def make_multiplier(factor: int):
    def multiply(x: int) -> int:
        return x * factor   # `factor` is local to make_multiplier, not the loop var
    return multiply

multipliers = [make_multiplier(i) for i in range(1, 4)]
print([m(5) for m in multipliers])  # [5, 10, 15]
```

### 12. Global State and Thread Safety  [community]
**Problem:** Module-level mutable state (global variables, module-level lists/dicts) is shared across all threads. Concurrent reads and writes without synchronisation produce data races that cause subtle, hard-to-reproduce bugs.
**Why:** CPython's Global Interpreter Lock (GIL) ensures only one thread runs Python bytecode at a time, but does *not* make compound operations (check-then-set, read-modify-write) atomic. `dict` and `list` operations that appear single-step in Python source code may compile to multiple bytecodes, interleaving with other threads between them.
**Fix:** Use `threading.Lock` for mutable shared state. Use `threading.local()` for per-thread state. Prefer immutable data structures or message passing (`queue.Queue`) over shared state.
```python
import threading
from collections import defaultdict

# BAD — counter is not thread-safe
counter = 0

def increment():
    global counter
    counter += 1   # Read + Write — not atomic!

# GOOD — protect with a lock
_lock = threading.Lock()
_counter = 0

def increment_safe():
    global _counter
    with _lock:
        _counter += 1

# GOOD — per-thread state with threading.local()
_thread_local = threading.local()

def get_connection() -> "DatabaseConnection":
    if not hasattr(_thread_local, "conn"):
        _thread_local.conn = DatabaseConnection()   # One conn per thread
    return _thread_local.conn

# GOOD — immutable data + queue for safe inter-thread communication
from queue import Queue
from dataclasses import dataclass

@dataclass(frozen=True)
class Task:
    task_id: int
    payload: str

task_queue: Queue[Task] = Queue()
task_queue.put(Task(1, "process_order"))
task = task_queue.get()   # Thread-safe dequeue
```

### 13. Shallow Copy vs Deep Copy Confusion  [community]
**Problem:** `copy.copy()` creates a shallow copy — a new container, but the *same* objects inside. Mutating a nested list or object in the copy also mutates the original, causing hard-to-trace bugs.
**Why:** Python objects are heap-allocated references. A shallow copy duplicates the container (e.g., the outer list) but copies the *references*, not the objects they point to. Both copies point to the same nested objects.
**Fix:** Use `copy.deepcopy()` when you need independent copies of nested mutable objects. For dataclasses, prefer `dataclasses.replace()` (creates a shallow copy of the instance with field overrides) combined with immutable field types.
```python
import copy

# Shallow copy pitfall
original = {"data": [1, 2, 3], "meta": {"created": "2026-01-01"}}
shallow = copy.copy(original)

shallow["data"].append(99)
print(original["data"])   # [1, 2, 3, 99]  ← original mutated!

# Deep copy — fully independent
original = {"data": [1, 2, 3], "meta": {"created": "2026-01-01"}}
deep = copy.deepcopy(original)

deep["data"].append(99)
print(original["data"])   # [1, 2, 3]  ← original unchanged

# For dataclasses: use replace() with immutable types (frozen=True)
from dataclasses import dataclass, replace

@dataclass
class Config:
    tags: list[str]
    name: str

cfg = Config(tags=["production"], name="app")
cfg2 = replace(cfg, name="worker")
cfg2.tags.append("debug")  # Mutates the SHARED tags list!
print(cfg.tags)             # ["production", "debug"]  ← oops

# Fix: copy mutable fields explicitly
cfg3 = replace(cfg, tags=list(cfg.tags), name="worker")
cfg3.tags.append("debug")
print(cfg.tags)             # ["production"]  ← safe
```

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| Bare `except:` | Swallows `KeyboardInterrupt`, hides bugs | Catch specific exception types |
| Mutable default argument | Shared state across all calls | Use `None` sentinel + create inside function |
| `from module import *` | Pollutes namespace, breaks tooling | Explicit imports: `from module import X, Y` |
| `type(obj) == SomeClass` | Breaks with subclasses, fragile | `isinstance(obj, SomeClass)` |
| `is` for value comparison | Relies on CPython internals | `==` for values, `is` only for singletons |
| Shadowing built-ins (`list`, `id`, `type`) | Silent replacement of built-ins | Use domain-specific names or trailing `_` |
| String path joining with `+` | Cross-platform breakage | `pathlib.Path` and `/` operator |
| `os.path` over `pathlib` | Verbose, error-prone, less readable | `pathlib.Path` |
| Using `Any` everywhere in type hints | Defeats static analysis | Use `Protocol`, generics, or specific types |
| Modifying collection during iteration | Skipped or duplicated items | Iterate a copy or use a comprehension |
| `Optional[int] = 0` (wrong Optional use) | Confusing intent — None not needed | `int = 0` for default value parameters |
| Missing `field(default_factory=...)` in dataclass | Shared mutable state between instances | Always use `default_factory` for lists/dicts |
| Circular imports between modules | Partial initialisation errors at import time | Extract shared types to a third module |
| Using `match` without exhaustive cases | Silent fall-through when no case matches | Always add a `case _:` wildcard or document intentional fall-through |
| Overusing `@property` for complex logic | Properties should be cheap reads; heavy logic belongs in explicit methods | Name it `calculate_x()` not `x` if it does real work |
| Calling `async_func()` without `await` | Coroutine never runs; silent no-op | Always `await` coroutine calls; use `asyncio.run()` at top level |
| Blocking I/O inside `async def` | Blocks the entire event loop; kills concurrency | Use `asyncio.to_thread()` or `run_in_executor()` for sync I/O in async context |
| `isinstance` chain instead of `singledispatch` | Hard to extend; violates open/closed principle | Use `@functools.singledispatch` for type-based dispatch |
| Manual retry loop with `time.sleep()` | Inefficient, non-configurable, swallows errors | Use `tenacity` library or implement with exponential backoff and `asyncio.sleep()` |
| Using bare `dict` for config / options | No type safety; typos silently create new keys | Use `TypedDict`, `@dataclass`, or `pydantic.BaseModel` |
