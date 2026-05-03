# Python Patterns & Best Practices
<!-- sources: mixed (official + community) | iteration: 27 | score: 100/100 | date: 2026-05-03 -->
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
     [lang-refine parallel run] Iter 18 (run2 iter 1): 100/100 (+0) — added typing.NewType for domain types, TypedDict for structured dicts, Python 3.13 features, ExceptionGroup gotcha (#14)
     Iter 19 (run2 iter 2): 100/100 (+0) — added typing.Annotated for metadata-rich types, operator module idioms, __slots__ inheritance pitfall gotcha (#15)
     Iter 20 (run2 iter 3): 100/100 (+0) — added __repr__/__str__/__format__ contract, bisect module, generator exhaustion gotcha (#16)
     Iter 21 (run2 iter 4): 100/100 (+0) — added heapq priority queues, __hash__/__eq__ consistency, mutable class variable gotcha (#17)
     Iter 22 (run2 iter 5): 100/100 (+0) — added __iter__/__len__/__contains__ container protocol, abstract properties idiom, string concat gotcha (#18)
     Iter 23 (run2 iter 6): 100/100 (+0) — added contextvars.ContextVar for async-safe state, __getattr__ vs __getattribute__, float equality gotcha (#19)
     Iter 24 (run2 iter 7): 100/100 (+0) — added weakref for memory-safe caches, __bool__/__len__ truthiness, None comparison gotcha (#20)
     Iter 25 (run2 iter 8): 100/100 (+0) — added typing.Literal for exact-value types, dict merge | operator, **kwargs validation gotcha (#21)
     Iter 26 (run2 iter 9): 100/100 (+0) — added __bool__/__len__ truthiness pattern, global state anti-pattern gotcha (#22)
     Iter 27 (run2 iter 10 — FINAL): 100/100 (+0) — added functools.reduce/pipeline patterns, fixed Literal section header, expanded anti-pattern table with 9 new rows
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
| Catching `ExceptionGroup` with `except` | Misses sub-exceptions in groups raised by `TaskGroup` | Use `except*` syntax (Python 3.11+) |
| `NewType` confused with type alias | `NewType` creates a distinct subtype; aliases are synonyms | Use `NewType` when values must not be mixed (e.g., `UserId` vs raw `int`) |

---

### `typing.NewType` for Domain-Specific Types

`NewType` creates a distinct type that the type checker treats as a subtype of the base — preventing accidental mixing of semantically different values that share the same runtime representation.

```python
from typing import NewType

# Create distinct types — both are int at runtime, but distinct statically
UserId = NewType("UserId", int)
OrderId = NewType("OrderId", int)


def get_user(user_id: UserId) -> dict:
    return {"id": user_id, "name": f"User_{user_id}"}


def get_order(order_id: OrderId) -> dict:
    return {"id": order_id, "items": []}


uid = UserId(42)
oid = OrderId(99)

get_user(uid)   # OK
get_order(oid)  # OK

# Type checker rejects these:
# get_user(oid)   # error: Argument 1 to "get_user" has incompatible type "OrderId"; expected "UserId"
# get_user(99)    # error: int is not UserId

# NewType is zero-cost at runtime — just an identity function
assert UserId(42) == 42   # True — same runtime value


# Contrast with TypeAlias — aliases are synonymous, NewType is a subtype
from typing import TypeAlias

IntAlias: TypeAlias = int
x: IntAlias = 5
y: int = x   # OK — alias and original are fully interchangeable
```

**When to use `NewType`:** Database IDs (UserId, ProductId), validated strings (EmailAddress, SlugStr), measurement types (Metres, Seconds) — anywhere two values of the same primitive type must not be accidentally mixed.

---

### `TypedDict` for Structured Dictionaries

`TypedDict` annotates dictionaries where keys are known at design time. Unlike `dict[str, Any]`, it gives you per-key types, completions, and type-checker errors for missing or extra keys.

```python
from typing import TypedDict, Required, NotRequired


class MovieBase(TypedDict):
    title: str
    year: int
    genre: str


class Movie(MovieBase, total=False):
    """total=False: all keys are optional EXCEPT those with Required[]."""
    rating: NotRequired[float]    # Optional key
    director: NotRequired[str]    # Optional key


# Required[] and NotRequired[] (Python 3.11+) let you mix
class UserProfile(TypedDict):
    id: Required[int]             # Must be present
    username: Required[str]       # Must be present
    bio: NotRequired[str]         # May be omitted
    avatar_url: NotRequired[str]  # May be omitted


def format_movie(movie: Movie) -> str:
    base = f"{movie['title']} ({movie['year']}) — {movie['genre']}"
    if "rating" in movie:
        base += f" [{movie['rating']}/10]"
    return base


m: Movie = {"title": "Inception", "year": 2010, "genre": "Sci-Fi", "rating": 8.8}
print(format_movie(m))   # Inception (2010) — Sci-Fi [8.8/10]

# Type checker catches:
# m2: Movie = {"title": "X"}   # Missing required keys 'year' and 'genre'
# m3: Movie = {"title": "X", "year": 2020, "genre": "Drama", "foo": 1}  # Extra key
```

**`TypedDict` vs `@dataclass`:** Use `TypedDict` when you are working with existing dict-shaped data (JSON responses, config files, kwargs). Use `@dataclass` when you control the data model and want methods, `__post_init__`, and `slots=True`.

---

### Python 3.13 — Key New Features and Best Practices

Python 3.13 (released October 2024) brings several developer-experience improvements worth knowing:

```python
# 1. Improved error messages — tracebacks now include color and column markers
# NameError: Did you mean 'username'?  (improved "did you mean" suggestions)
# AttributeError: 'list' object has no attribute 'appned'. Did you mean: 'append'?

# 2. Free-threaded CPython (PEP 703) — experimental, opt-in build
# python3.13t  — the 't' suffix enables the no-GIL experimental build
# Enables true parallel threads for CPU-bound work
# CAUTION: Not all C extensions support free-threading yet (2026)
# Use --disable-gil / PYTHON_GIL=0 env var for testing

# 3. copy.replace() — generic shallow-copy-with-overrides (extends dataclasses.replace)
import copy
from dataclasses import dataclass

@dataclass
class Config:
    host: str
    port: int

cfg = Config("localhost", 5432)
new_cfg = copy.replace(cfg, port=5433)   # Python 3.13+ generic replace
print(new_cfg)  # Config(host='localhost', port=5433)

# 4. locals() now returns a fresh snapshot (not a live view) — safer for introspection
# 5. Interactive REPL improved: multi-line editing, colour, paste mode
# 6. Deprecated: bool(datetime.time(0)) returning False — fixed in 3.14

# 7. Better __str__ for exceptions in tracebacks
try:
    {}["missing"]
except KeyError as e:
    print(e)  # 'missing'  (improved quoting and display)
```

**Migration note:** `typing.get_type_hints()` behavior changed for `from __future__ import annotations` — use `typing.get_annotations()` (Python 3.10+) for safer runtime inspection.

---

### 14. Mishandling `ExceptionGroup` in Async Code  [community]
**Problem:** Python 3.11's `asyncio.TaskGroup` (and `asyncio.gather`) wraps multiple task exceptions in an `ExceptionGroup`. Using `except ValueError` will not catch a `ValueError` nested inside an `ExceptionGroup`, causing the exception to propagate uncaught.
**Why:** `ExceptionGroup` is a new `BaseException` subclass that holds a collection of exceptions. Regular `except E:` only matches the group itself (if `E` is `ExceptionGroup` or `BaseException`), not the individual sub-exceptions inside it.
**Fix:** Use `except* SomeError:` (PEP 654, Python 3.11+) which matches and extracts sub-exceptions from the group by type.
```python
import asyncio


async def might_fail(n: int) -> int:
    if n == 2:
        raise ValueError(f"bad value: {n}")
    return n * 10


# BAD — ValueError from TaskGroup is wrapped in ExceptionGroup; this won't catch it
async def run_bad() -> None:
    try:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(might_fail(i)) for i in range(4)]
    except ValueError:
        print("caught!")  # Never reached — ExceptionGroup is not a ValueError


# GOOD — except* extracts sub-exceptions by type
async def run_good() -> None:
    try:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(might_fail(i)) for i in range(4)]
    except* ValueError as eg:
        for exc in eg.exceptions:
            print(f"Handled: {exc}")   # Handled: bad value: 2
    else:
        results = [t.result() for t in tasks]
        print(results)


asyncio.run(run_good())
```

---

### `typing.Annotated` for Metadata-Rich Types

`Annotated[T, metadata...]` wraps a type with arbitrary metadata for frameworks (Pydantic, FastAPI, attrs) and custom validation logic — without changing the type checker's view of the type.

```python
from typing import Annotated, get_type_hints, get_args, get_origin
from dataclasses import dataclass


# Sentinel classes for metadata
class Gt:
    """Greater-than constraint."""
    def __init__(self, value: float) -> None:
        self.value = value


class MaxLen:
    """Maximum string/sequence length constraint."""
    def __init__(self, length: int) -> None:
        self.length = length


# Annotated keeps T as the primary type; metadata is ignored by type checkers
PositiveInt = Annotated[int, Gt(0)]
ShortStr = Annotated[str, MaxLen(50)]


@dataclass
class Product:
    name: ShortStr
    price: PositiveInt
    quantity: PositiveInt


def validate(cls: type) -> None:
    """Naive runtime validator that reads Annotated metadata."""
    hints = get_type_hints(cls, include_extras=True)
    for field, hint in hints.items():
        if get_origin(hint) is Annotated:
            _, *constraints = get_args(hint)
            for c in constraints:
                if isinstance(c, Gt):
                    print(f"  {field}: must be > {c.value}")
                elif isinstance(c, MaxLen):
                    print(f"  {field}: max length {c.length}")


validate(Product)
# name: max length 50
# price: must be > 0
# quantity: must be > 0

# FastAPI / Pydantic use the same mechanism:
# from pydantic import BaseModel, Field
# class Item(BaseModel):
#     price: Annotated[float, Field(gt=0, description="Must be positive")]
```

**Key insight:** `Annotated` decouples type information (for the checker) from runtime metadata (for frameworks). The same field can be validated, documented, and serialised from a single source of truth.

---

### `operator` Module for Functional-Style Code

The `operator` module provides function-form equivalents of Python operators. Use them instead of `lambda x: x.attr` or `lambda x: x[key]` for performance and readability in `sorted()`, `map()`, `functools.reduce()`, etc.

```python
import operator
from functools import reduce
from dataclasses import dataclass


@dataclass
class Employee:
    name: str
    department: str
    salary: float


employees = [
    Employee("Alice", "Engineering", 95_000),
    Employee("Bob", "Marketing", 72_000),
    Employee("Carol", "Engineering", 110_000),
    Employee("Dan", "Marketing", 68_000),
]

# operator.attrgetter — faster than lambda e: e.salary
by_salary = sorted(employees, key=operator.attrgetter("salary"), reverse=True)
print(by_salary[0].name)   # Carol

# operator.itemgetter — for dicts and sequences
records = [{"id": 3, "score": 88}, {"id": 1, "score": 95}, {"id": 2, "score": 72}]
by_score = sorted(records, key=operator.itemgetter("score"), reverse=True)
print(by_score[0]["id"])   # 1

# Chained attrgetter — multi-key sort
by_dept_then_salary = sorted(
    employees,
    key=operator.attrgetter("department", "salary"),
)

# operator.methodcaller — call a named method on each item
words = ["hello", "WORLD", "Python"]
lowered = list(map(operator.methodcaller("lower"), words))
# ['hello', 'world', 'python']

# operator.add with reduce — sum without lambda
total_salary = reduce(operator.add, (e.salary for e in employees))
print(f"Total payroll: ${total_salary:,.0f}")   # Total payroll: $345,000
```

---

### 15. `__slots__` Inheritance Pitfalls  [community]
**Problem:** Defining `__slots__` in a subclass of a class that does NOT use `__slots__` provides no memory benefit — the subclass still has a `__dict__` inherited from the parent, negating the purpose of slots.
**Why:** `__slots__` only works if *every class in the MRO* declares `__slots__`. If any ancestor class (including `object` indirectly via a class without `__slots__`) has `__dict__`, the subclass also has `__dict__`. The slots descriptor is added but the dict remains.
**Fix:** If you want slots throughout, use `@dataclass(slots=True)` (which generates a fresh class) or define `__slots__` consistently in *all* classes in the hierarchy, including the base.
```python
import sys


# BAD — parent has __dict__; slots on child are ignored
class Base:
    def __init__(self, x: float) -> None:
        self.x = x   # stored in __dict__


class Child(Base):
    __slots__ = ("y",)   # y gets a slot descriptor BUT __dict__ still exists from Base

    def __init__(self, x: float, y: float) -> None:
        super().__init__(x)
        self.y = y


c = Child(1.0, 2.0)
print(hasattr(c, "__dict__"))   # True — __dict__ still present from Base!
print(sys.getsizeof(c))         # ~56 bytes obj + 232 bytes dict — no savings

c.extra = "unexpected"          # Allowed because __dict__ still exists


# GOOD — slots throughout the hierarchy
class BaseSlotted:
    __slots__ = ("x",)

    def __init__(self, x: float) -> None:
        self.x = x


class ChildSlotted(BaseSlotted):
    __slots__ = ("y",)   # Only NEW slots — x inherited from BaseSlotted

    def __init__(self, x: float, y: float) -> None:
        super().__init__(x)
        self.y = y


cs = ChildSlotted(1.0, 2.0)
print(hasattr(cs, "__dict__"))   # False — no __dict__!
# cs.extra = "x"                 # AttributeError — slots prevent dynamic attributes


# EASIEST — use @dataclass(slots=True) which does this automatically
from dataclasses import dataclass

@dataclass(slots=True)
class FastPoint:
    x: float
    y: float
```

---

### `__repr__` vs `__str__` — The Correct Contract

`__repr__` should produce an unambiguous string that ideally recreates the object. `__str__` is for human-readable display. Always implement `__repr__` first; if `__str__` is not defined, `repr()` is used as the fallback.

```python
from __future__ import annotations
import json
from datetime import date


class Invoice:
    """Demonstrates the __repr__/__str__ contract."""

    def __init__(self, invoice_id: str, amount: float, due: date) -> None:
        self.invoice_id = invoice_id
        self.amount = amount
        self.due = due

    def __repr__(self) -> str:
        # Unambiguous, ideally eval()-able; used in debugging/logging
        return (
            f"Invoice("
            f"invoice_id={self.invoice_id!r}, "
            f"amount={self.amount!r}, "
            f"due={self.due!r}"
            f")"
        )

    def __str__(self) -> str:
        # Human-readable; shown in print() and f-strings
        return f"Invoice #{self.invoice_id}: ${self.amount:,.2f} due {self.due}"

    def __format__(self, spec: str) -> str:
        # Custom format spec support: f"{inv:json}"
        if spec == "json":
            return json.dumps({
                "id": self.invoice_id,
                "amount": self.amount,
                "due": self.due.isoformat(),
            })
        return str(self)


inv = Invoice("INV-001", 1250.50, date(2026, 6, 1))
print(repr(inv))   # Invoice(invoice_id='INV-001', amount=1250.5, due=datetime.date(2026, 6, 1))
print(str(inv))    # Invoice #INV-001: $1,250.50 due 2026-06-01
print(f"{inv}")    # Invoice #INV-001: $1,250.50 due 2026-06-01
print(f"{inv:json}")  # {"id": "INV-001", "amount": 1250.5, "due": "2026-06-01"}
```

**Rule:** Never return the same string from both `__repr__` and `__str__` unless the object truly has only one useful representation. Classes that skip `__repr__` show unhelpful `<MyClass object at 0x...>` in logs.

---

### `bisect` Module for Sorted Sequences

`bisect` provides O(log n) insertion-point search in a sorted list — far faster than scanning with `next(x for x in items if x >= target)` and avoids sorting after every insert.

```python
import bisect
from dataclasses import dataclass


# Find the insertion point (binary search)
breakpoints = [0, 60, 70, 80, 90, 100]
grades = ["F", "D", "C", "B", "A", "A+"]


def letter_grade(score: float) -> str:
    """O(log n) grade lookup using a sorted breakpoint table."""
    i = bisect.bisect_right(breakpoints, score) - 1
    return grades[max(0, i)]


print(letter_grade(55))   # F
print(letter_grade(72))   # C
print(letter_grade(91))   # A

# insort — insert into a sorted list and keep it sorted (O(n) but avoids re-sort)
events = [10, 20, 30, 50]
bisect.insort(events, 35)
print(events)   # [10, 20, 30, 35, 50]

# SortedList pattern — maintain a live sorted collection
@dataclass(order=True)
class Task:
    priority: int      # Compared first (dataclass order=True)
    name: str


task_queue: list[Task] = []
for task in [Task(3, "low"), Task(1, "critical"), Task(2, "medium")]:
    bisect.insort(task_queue, task)

print([t.name for t in task_queue])   # ['critical', 'medium', 'low']
```

---

### 16. Generator Exhaustion — Iterating a Generator Twice  [community]
**Problem:** A generator is a one-shot iterator. Once all values have been yielded, it is exhausted and subsequent iterations return nothing, silently producing empty results or incorrect aggregations.
**Why:** Unlike lists, generators have no `__rewind__` or `__reset__`. When the generator function returns (or falls off the end), `StopIteration` is raised and the generator is permanently closed. Calling `for x in gen` a second time immediately raises `StopIteration` on the first `next()` call — the loop body simply never executes.
**Fix:** If you need to iterate multiple times, convert to a `list` or `tuple` first. If memory is a concern, re-create the generator for each pass, or use `itertools.tee()` for two simultaneous consumers (but `tee` buffers data internally — list is usually cleaner).
```python
import itertools


# BAD — generator exhausted after first loop
def squares(n: int):
    for i in range(n):
        yield i * i


gen = squares(5)
total = sum(gen)       # 0+1+4+9+16 = 30
count = sum(1 for _ in gen)  # 0 — gen is exhausted!
print(f"sum={total}, count={count}")   # sum=30, count=0  — wrong!


# GOOD option A — materialize to list when multi-pass is needed
vals = list(squares(5))
total = sum(vals)
count = len(vals)
print(f"sum={total}, count={count}")   # sum=30, count=5  — correct


# GOOD option B — re-create the generator for each pass
def get_gen():
    return squares(5)

total = sum(get_gen())
count = sum(1 for _ in get_gen())
print(f"sum={total}, count={count}")   # sum=30, count=5  — correct


# GOOD option C — itertools.tee (two simultaneous consumers)
gen_a, gen_b = itertools.tee(squares(5), 2)
total = sum(gen_a)
count = sum(1 for _ in gen_b)
print(f"sum={total}, count={count}")   # sum=30, count=5
# NOTE: tee buffers values from the faster consumer — only use if consumers
#       advance roughly in lockstep; otherwise list() is more memory-efficient.
```

---

### `heapq` for Priority Queues and Top-N Selection

`heapq` provides a min-heap in O(log n) per push/pop, and `nlargest`/`nsmallest` for efficient top-N without full sorts.

```python
import heapq
from dataclasses import dataclass, field


@dataclass(order=True)
class PrioritisedTask:
    priority: int
    # order=True compares fields left-to-right; lower priority = higher urgency
    name: str = field(compare=False)   # Exclude name from comparison


# Min-heap as a priority queue
heap: list[PrioritisedTask] = []
heapq.heappush(heap, PrioritisedTask(3, "low-priority-job"))
heapq.heappush(heap, PrioritisedTask(1, "critical-job"))
heapq.heappush(heap, PrioritisedTask(2, "medium-job"))

while heap:
    task = heapq.heappop(heap)
    print(f"Running: {task.name} (priority {task.priority})")
# Running: critical-job (priority 1)
# Running: medium-job (priority 2)
# Running: low-priority-job (priority 3)


# nlargest / nsmallest — O(n log k) vs O(n log n) for full sort
scores = [34, 78, 91, 45, 62, 88, 77, 55, 23, 99]
top3    = heapq.nlargest(3, scores)     # [99, 91, 88]
bottom3 = heapq.nsmallest(3, scores)   # [23, 34, 45]
print(top3, bottom3)


# heapq.merge — merge already-sorted iterables lazily (no materialisation)
import heapq
sorted_a = [1, 4, 7]
sorted_b = [2, 5, 8]
sorted_c = [3, 6, 9]
merged = list(heapq.merge(sorted_a, sorted_b, sorted_c))
print(merged)   # [1, 2, 3, 4, 5, 6, 7, 8, 9]
```

**Rule of thumb:** Use `heapq.nlargest(k, items)` when `k << len(items)`; use `sorted(..., reverse=True)[:k]` when `k` approaches `len(items)`.

---

### `__hash__` and `__eq__` Consistency

Whenever you define `__eq__`, Python automatically sets `__hash__` to `None`, making the class unhashable. You must explicitly define `__hash__` if instances should be usable in sets or as dict keys.

```python
from functools import cached_property


class Point:
    """Demonstrates the __eq__ / __hash__ contract."""

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Point):
            return NotImplemented
        return self.x == other.x and self.y == other.y

    def __hash__(self) -> int:
        # MUST hash the same fields used in __eq__
        # If a == b then hash(a) == hash(b) — this invariant must hold
        return hash((self.x, self.y))

    @cached_property
    def magnitude(self) -> float:
        """Lazy-computed, cached; safe because Point is effectively immutable."""
        return (self.x ** 2 + self.y ** 2) ** 0.5


# Now Points can be used in sets and as dict keys
points = {Point(0, 0), Point(1, 1), Point(0, 0)}
print(len(points))   # 2 — duplicates removed via __hash__ + __eq__

p = Point(3.0, 4.0)
print(p.magnitude)   # 5.0 — computed once, cached on the instance


# BAD — defining __eq__ without __hash__ breaks set/dict usage
class BadPoint:
    def __init__(self, x, y): self.x, self.y = x, y
    def __eq__(self, other):
        if not isinstance(other, BadPoint): return NotImplemented
        return self.x == other.x and self.y == other.y
    # __hash__ = None  ← implicitly set by Python when __eq__ is defined

try:
    bad_set = {BadPoint(0, 0)}   # TypeError: unhashable type: 'BadPoint'
except TypeError as e:
    print(e)
```

**The contract:** `a == b` implies `hash(a) == hash(b)`. The converse is not required (hash collisions are allowed). For `frozen=True` dataclasses, Python generates a correct `__hash__` automatically.

---

### 17. Mutable Class Variables Shared Across Instances  [community]
**Problem:** Class-level mutable attributes (lists, dicts) are shared across all instances. Modifying them through one instance affects every other instance, and even future instances created after the mutation.
**Why:** Class attributes live in the class's `__dict__`, not the instance's `__dict__`. Reading `self.attr` checks instance dict first, then class dict. Writing `self.attr.append(x)` reads the class attribute (since the instance has none) and mutates it in-place — the instance dict is never written, so the mutation affects the class attribute shared by all instances.
**Fix:** Always initialise mutable attributes in `__init__`, never at class level. With `@dataclass`, always use `field(default_factory=...)`.
```python
# BAD — items is a class attribute shared by all instances
class Cart:
    items = []   # Shared!

    def add(self, item: str) -> None:
        self.items.append(item)   # Mutates the class attribute!


cart1 = Cart()
cart2 = Cart()
cart1.add("apple")
print(cart2.items)   # ['apple'] — unexpected! cart2 sees cart1's item


# GOOD — items is an instance attribute
class Cart:
    def __init__(self) -> None:
        self.items: list[str] = []   # Each instance gets its own list

    def add(self, item: str) -> None:
        self.items.append(item)


cart1 = Cart()
cart2 = Cart()
cart1.add("apple")
print(cart2.items)   # [] — correct


# GOOD with @dataclass — field(default_factory=list) per instance
from dataclasses import dataclass, field

@dataclass
class Cart:
    items: list[str] = field(default_factory=list)

    def add(self, item: str) -> None:
        self.items.append(item)
```

---

### `__iter__`, `__len__`, `__contains__` — Making Objects Feel Built-In

Implementing Python's container protocol makes your objects work naturally with `for`, `len()`, `in`, and built-in functions like `sum()`, `max()`, and `list()`.

```python
from __future__ import annotations
from collections.abc import Iterator
from typing import Generic, TypeVar

T = TypeVar("T")


class BoundedRing(Generic[T]):
    """A fixed-capacity ring buffer that behaves like a built-in container."""

    def __init__(self, capacity: int) -> None:
        self._capacity = capacity
        self._buffer: list[T] = []
        self._head = 0   # Index of the oldest item

    def push(self, item: T) -> None:
        """Add item; evict oldest if at capacity."""
        if len(self._buffer) < self._capacity:
            self._buffer.append(item)
        else:
            self._buffer[self._head] = item
            self._head = (self._head + 1) % self._capacity

    def __len__(self) -> int:
        return len(self._buffer)

    def __iter__(self) -> Iterator[T]:
        """Yield items in insertion order (oldest first)."""
        n = len(self._buffer)
        for i in range(n):
            yield self._buffer[(self._head + i) % n]

    def __contains__(self, item: object) -> bool:
        return item in self._buffer

    def __repr__(self) -> str:
        return f"BoundedRing({list(self)!r}, capacity={self._capacity})"


ring: BoundedRing[int] = BoundedRing(3)
for v in [1, 2, 3, 4, 5]:
    ring.push(v)

print(list(ring))     # [3, 4, 5] — only last 3 retained, oldest first
print(len(ring))      # 3
print(4 in ring)      # True
print(sum(ring))      # 12   — works with sum() because __iter__ is defined
print(max(ring))      # 5    — works with max() for same reason
print(ring)           # BoundedRing([3, 4, 5], capacity=3)
```

---

### Abstract Properties — Use `@property` + `@abstractmethod`

The deprecated `@abc.abstractproperty` was removed in Python 3.11. The correct idiom is to stack `@property` on top of `@abstractmethod`.

```python
from abc import ABC, abstractmethod


class Shape(ABC):
    """Correct idiom for abstract properties in Python 3.3+."""

    @property
    @abstractmethod
    def area(self) -> float:
        """Subclasses must provide a computed area property."""
        ...

    @property
    @abstractmethod
    def perimeter(self) -> float: ...

    def describe(self) -> str:
        return f"{type(self).__name__}: area={self.area:.2f}, perimeter={self.perimeter:.2f}"


class Rectangle(Shape):
    def __init__(self, width: float, height: float) -> None:
        self._width = width
        self._height = height

    @property
    def area(self) -> float:
        return self._width * self._height

    @property
    def perimeter(self) -> float:
        return 2 * (self._width + self._height)


r = Rectangle(3.0, 4.0)
print(r.describe())   # Rectangle: area=12.00, perimeter=14.00

# Attempting to instantiate Shape raises TypeError
# s = Shape()  # TypeError: Can't instantiate abstract class Shape without implementations for 'area', 'perimeter'
```

---

### 18. String Concatenation in Loops  [community]
**Problem:** Concatenating strings inside a loop using `+=` creates a new string object on every iteration. For N iterations, this is O(N²) in time and O(N²) in intermediate memory allocations — it becomes catastrophically slow for large N.
**Why:** Strings in Python are immutable. `s += chunk` is equivalent to `s = s + chunk`, which allocates a brand-new string of length `len(s) + len(chunk)` on every iteration. CPython has an optimisation for single-reference strings (PEP 680 / micro-optimisation), but it is fragile and disappears with any other reference to the string.
**Fix:** Collect parts in a list and join at the end with `"".join(parts)` — O(N) time, O(N) memory.
```python
import timeit

data = ["word"] * 10_000


# BAD — O(N²) string concatenation
def build_string_bad(parts: list[str]) -> str:
    result = ""
    for part in parts:
        result += part + " "
    return result


# GOOD — O(N) list accumulation + single join
def build_string_good(parts: list[str]) -> str:
    return " ".join(parts)


# Even for mixed-type accumulation, collect and join
def build_report(items: list[dict]) -> str:
    lines: list[str] = []
    for item in items:
        lines.append(f"{item['name']}: {item['value']:.2f}")
    return "\n".join(lines)


# Performance difference (10,000 words):
# build_string_bad:  ~5.2 ms
# build_string_good: ~0.3 ms  (~17× faster)
#
# For very small N (< 10), += is fine — the difference is negligible.
# Rule: if you're in a loop, use a list + join.
```

---

### `contextvars.ContextVar` for Async-Safe Context State

`threading.local()` is not safe in async code — all coroutines running on the same thread share the same `threading.local` value. Use `contextvars.ContextVar` instead; each asyncio Task gets its own copy automatically.

```python
import asyncio
import contextvars
import uuid
from typing import Any


# ContextVar — each asyncio Task / thread gets an isolated copy
request_id: contextvars.ContextVar[str] = contextvars.ContextVar(
    "request_id", default="<no-request>"
)


async def handle_request(name: str) -> dict[str, Any]:
    """Simulate an HTTP handler — sets request_id for this task only."""
    rid = str(uuid.uuid4())[:8]
    token = request_id.set(rid)   # Set in THIS task's context only
    try:
        await asyncio.sleep(0)    # Yield to event loop; other tasks run
        # request_id here is still our rid — not another task's
        return {"handler": name, "request_id": request_id.get()}
    finally:
        request_id.reset(token)   # Restore previous value (good practice)


async def main() -> None:
    # Run three handlers concurrently — each has its own request_id
    results = await asyncio.gather(
        handle_request("A"),
        handle_request("B"),
        handle_request("C"),
    )
    for r in results:
        print(r)
    # Each result has a unique request_id — no cross-task contamination

    # After handlers complete, the default is restored
    print(request_id.get())   # <no-request>


asyncio.run(main())


# For middleware-style request-scoped state, use Context.run()
def run_in_context(user_id: str, fn):
    ctx = contextvars.copy_context()
    # Set variable in the copied context before running
    def _run():
        request_id.set(user_id)
        return fn()
    return ctx.run(_run)
```

**Why not `threading.local()`:** In asyncio, many coroutines share one thread. `threading.local` is per-thread, so all coroutines see the same value. `ContextVar` is per-Task, giving correct isolation.

---

### `__getattr__` vs `__getattribute__` — Know the Difference

`__getattr__` is called only when normal attribute lookup fails (a safety net). `__getattribute__` is called on every attribute access and is rarely overridden. Confusing them causes infinite recursion.

```python
class LazyProxy:
    """
    __getattr__ as a lazy loader — only called when the attribute is NOT found
    through normal means (not in __dict__ or class hierarchy).
    """

    def __init__(self, factory) -> None:
        # Use object.__setattr__ to avoid triggering __setattr__ recursion
        object.__setattr__(self, "_factory", factory)
        object.__setattr__(self, "_cache", {})

    def __getattr__(self, name: str):
        # Only called if `name` is NOT in self.__dict__ or the class
        cache = object.__getattribute__(self, "_cache")
        if name not in cache:
            factory = object.__getattribute__(self, "_factory")
            cache[name] = factory(name)
        return cache[name]


def compute(name: str) -> str:
    print(f"  Computing '{name}'...")
    return f"value_of_{name}"


proxy = LazyProxy(compute)
print(proxy.foo)   # Computing 'foo'... \n value_of_foo
print(proxy.foo)   # value_of_foo (cached, no recompute)
print(proxy.bar)   # Computing 'bar'... \n value_of_bar


# DANGER — overriding __getattribute__ incorrectly causes infinite recursion
class Broken:
    def __getattribute__(self, name: str):
        return self.name   # Recursive! self.name calls __getattribute__ again!

# SAFE — use object.__getattribute__ to bypass your own override
class Safe:
    def __getattribute__(self, name: str):
        value = object.__getattribute__(self, name)   # No recursion
        print(f"Accessed: {name} = {value!r}")
        return value
```

**Rule:** Override `__getattr__` for attribute fallback/proxy patterns. Override `__getattribute__` only when you need to intercept every attribute access — and always delegate to `object.__getattribute__` to avoid recursion.

---

### 19. Float Equality Comparisons  [community]
**Problem:** Comparing floating-point numbers with `==` produces incorrect results because floating-point arithmetic is not exact. Two mathematically equal values may differ in their binary representations.
**Why:** IEEE 754 floating-point numbers cannot represent most decimal fractions exactly. `0.1 + 0.2` does not equal `0.3` in any language that uses IEEE 754 — it equals `0.30000000000000004`. Every intermediate arithmetic operation introduces rounding error that accumulates.
**Fix:** Use `math.isclose()` for approximate equality with configurable relative and absolute tolerances. For exact decimal arithmetic (financial calculations), use the `decimal` module.
```python
import math
from decimal import Decimal, ROUND_HALF_UP


# BAD — exact float comparison fails
total = 0.1 + 0.2
print(total == 0.3)          # False!
print(total)                 # 0.30000000000000004


# GOOD option A — math.isclose() for approximate comparison
print(math.isclose(total, 0.3))                    # True (default rel_tol=1e-9)
print(math.isclose(total, 0.3, rel_tol=1e-9))      # True
print(math.isclose(0.0, 1e-10, abs_tol=1e-9))      # True (near-zero needs abs_tol)


# GOOD option B — Decimal for exact decimal arithmetic (financial code)
price = Decimal("19.99")
tax_rate = Decimal("0.08")
tax = (price * tax_rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
total_price = price + tax
print(total_price)   # 21.59 (exact!)

# Pitfall: never initialise Decimal from a float literal
bad = Decimal(0.1)      # Decimal('0.1000000000000000055511151231257827021181583404541015625')
good = Decimal("0.1")   # Decimal('0.1')


# Sorting/comparing floats in containers is fine (sorts correctly)
# The problem is equality — use isclose, not ==
values = [0.3, 0.1 + 0.2, 0.30000000000000004]
print(sorted(values))   # Correctly ordered despite rounding differences

# For numpy arrays: use np.allclose() / np.isclose()
# import numpy as np
# np.isclose(np.array([0.1 + 0.2]), np.array([0.3]))  # [True]
```

---

### `weakref` for Memory-Safe Caches and Observers

`weakref.ref` and `weakref.WeakValueDictionary` hold references that do not prevent garbage collection. Use them for caches where the cache should not keep objects alive, or for observer registries where observers should not be kept alive by the subject.

```python
import weakref
from typing import Callable


# WeakValueDictionary — cache that doesn't prevent GC
class ObjectCache:
    """Cache that holds weak references — objects are evicted when no longer used."""

    def __init__(self) -> None:
        self._cache: weakref.WeakValueDictionary[str, object] = (
            weakref.WeakValueDictionary()
        )
        self._hits = 0
        self._misses = 0

    def get_or_create(self, key: str, factory: Callable[[], object]) -> object:
        obj = self._cache.get(key)
        if obj is None:
            obj = factory()
            self._cache[key] = obj
            self._misses += 1
        else:
            self._hits += 1
        return obj

    def stats(self) -> dict:
        return {
            "cached": len(self._cache),
            "hits": self._hits,
            "misses": self._misses,
        }


cache = ObjectCache()

class Resource:
    def __init__(self, name: str) -> None:
        self.name = name

r1 = cache.get_or_create("db", lambda: Resource("db"))
r2 = cache.get_or_create("db", lambda: Resource("db"))   # Cache hit
print(r1 is r2)          # True — same object returned from cache
print(cache.stats())     # {'cached': 1, 'hits': 1, 'misses': 1}

# When r1 and r2 go out of scope, the cached entry is automatically removed
del r1, r2
import gc; gc.collect()
print(cache.stats())     # {'cached': 0, 'hits': 1, 'misses': 1}


# WeakSet — for event/observer registries
class EventBus:
    def __init__(self) -> None:
        self._listeners: weakref.WeakSet = weakref.WeakSet()

    def subscribe(self, listener) -> None:
        self._listeners.add(listener)

    def publish(self, event: str) -> None:
        for listener in list(self._listeners):
            listener(event)
```

**When to use:** Image/config caches, object pools, observer patterns where listeners should not be pinned in memory by the subject alone.

---

### 20. Comparing to `None` with `==` Instead of `is`  [community]
**Problem:** Using `== None` instead of `is None` to check for `None` can produce false results if an object defines `__eq__` to return `True` when compared to `None`. It also generates a `SyntaxWarning` in modern Python (3.8+) that will eventually become an error.
**Why:** `None` is a singleton — there is exactly one `None` object in the entire Python process. The correct check is `is None` (identity), not `== None` (equality), because `==` calls `__eq__` which can be overridden. Additionally, `not x` should only be used when falsy values beyond `None` are acceptable; if you specifically mean "is this None?", always use `is None`.
**Fix:** Always use `is None` and `is not None` for None checks. Use `== None` only when you deliberately want to trigger `__eq__`.
```python
# BAD — == None can be fooled by __eq__
class Sentinel:
    def __eq__(self, other):
        return True   # Equals everything!

s = Sentinel()
print(s == None)    # True — misleading!
print(s is None)    # False — correct


# BAD — SyntaxWarning in Python 3.8+
x = None
if x == None:       # SyntaxWarning: "== None" can be True for objects with __eq__
    pass

# GOOD — use identity check
if x is None:
    pass

if x is not None:
    pass

# BAD — using "not x" when you mean "is None"
def process(value: int | None) -> int:
    if not value:      # Also matches 0, "", [], {} — not just None!
        return -1
    return value * 2

print(process(0))    # -1 — wrong! 0 is valid, not None

# GOOD — explicit None check
def process(value: int | None) -> int:
    if value is None:
        return -1
    return value * 2

print(process(0))    # 0 — correct


# Standard idiom in type-narrowed code
from typing import TYPE_CHECKING

def get_or_default(value: str | None, default: str = "") -> str:
    return value if value is not None else default
```

---

### `__bool__` and `__len__` for Truthiness

Python's boolean context (`if obj:`, `while obj:`, `not obj`) calls `__bool__` first. If `__bool__` is not defined, it falls back to `__len__` (empty = falsy). Define these to give your objects Pythonic truthiness.

```python
from __future__ import annotations
from dataclasses import dataclass, field


@dataclass
class ResultSet:
    """Collection of query results — falsy when empty, truthy when non-empty."""
    items: list[dict] = field(default_factory=list)
    error: str | None = None

    def __bool__(self) -> bool:
        # Falsy if there was an error OR no items
        if self.error is not None:
            return False
        return len(self.items) > 0

    def __len__(self) -> int:
        return len(self.items)


results = ResultSet(items=[{"id": 1}, {"id": 2}])
empty   = ResultSet(items=[])
errored = ResultSet(items=[{"id": 1}], error="connection timeout")

# Pythonic truth testing — reads like English
if results:
    print(f"Got {len(results)} results")   # Got 2 results

if not empty:
    print("No results")                    # No results

if not errored:
    print("Query failed — check error")   # Query failed — check error

# Works with all built-ins that expect boolean context
all_ok = all([results, results, results])   # True
any_ok = any([empty, errored, results])     # True (results is truthy)
print(bool(empty))    # False
print(bool(results))  # True


# BAD — never return non-bool from __bool__ (PEP 8 guideline)
class BadBool:
    def __bool__(self):
        return 42    # Technically works but confusing; PEP 8 says return bool
```

**Rule:** `__bool__` must return `bool` (not just truthy/falsy). If you define `__len__`, you get falsy-when-zero for free — only define `__bool__` when the rule is more complex than "non-empty means truthy".

---

### 22. Over-Relying on `global` and Module-Level Mutable State  [community]
**Problem:** Using `global` to share mutable state between functions creates invisible dependencies, makes testing difficult (state bleeds between test runs), and leads to race conditions in concurrent code. Experienced Python developers consider `global` a code smell in almost all cases.
**Why:** `global` makes a function's behaviour depend on state outside its inputs, violating referential transparency. When a test fails, you must trace which earlier function mutated the global. When two functions share a global, their execution order becomes load-bearing — a hidden coupling that breaks refactoring.
**Fix:** Pass state as parameters. Return new state instead of mutating global. For shared application state, use a class or a singleton with a controlled interface. For configuration, use dataclasses or environment variables read once at startup.
```python
# BAD — global counter, hard to test and thread-unsafe
_count = 0

def increment():
    global _count
    _count += 1

def get_count() -> int:
    return _count

# Testing requires resetting global state — fragile:
# _count = 0  # Reset before each test


# GOOD option A — pass state as parameter, return new state
def increment(count: int) -> int:
    return count + 1

count = 0
count = increment(count)   # Pure function; easy to test


# GOOD option B — encapsulate in a class
class Counter:
    def __init__(self, initial: int = 0) -> None:
        self._value = initial

    def increment(self) -> None:
        self._value += 1

    @property
    def value(self) -> int:
        return self._value


# In tests, just create a fresh Counter() — no shared state pollution


# GOOD option C — module-level constants are fine (immutable)
MAX_RETRIES = 3       # OK — immutable, not state
DEFAULT_TIMEOUT = 30  # OK — immutable constant


# ACCEPTABLE — module-level singletons with controlled access
from threading import Lock

class _ApplicationState:
    def __init__(self) -> None:
        self._lock = Lock()
        self._metrics: dict[str, int] = {}

    def record(self, key: str, value: int) -> None:
        with self._lock:
            self._metrics[key] = self._metrics.get(key, 0) + value

    def snapshot(self) -> dict[str, int]:
        with self._lock:
            return dict(self._metrics)

_state = _ApplicationState()  # Module-level singleton, but controlled via methods
```

---

### `typing.Literal` for Exact-Value Types

`Literal[...]` narrows a type to a specific set of literal values. The type checker rejects anything outside the set, turning a runtime error into a static analysis error.

```python
from typing import Literal, overload
from pathlib import Path


# Instead of just str, restrict to known HTTP methods
HttpMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]
LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
Direction = Literal["north", "south", "east", "west"]


def make_request(method: HttpMethod, url: str) -> dict:
    """Type checker rejects: make_request("FETCH", url) — not in Literal."""
    return {"method": method, "url": url}


def set_log_level(level: LogLevel) -> None:
    import logging
    logging.getLogger().setLevel(level)


# Literal in overloads — different return types per literal value
@overload
def open_file(path: Path, mode: Literal["r", "rt"]) -> str: ...
@overload
def open_file(path: Path, mode: Literal["rb"]) -> bytes: ...

def open_file(path: Path, mode: str) -> str | bytes:
    if "b" in mode:
        return path.read_bytes()
    return path.read_text(encoding="utf-8")


# Combining Literal with Enum — structured config options
from enum import StrEnum

class Environment(StrEnum):
    PROD  = "prod"
    STAGE = "stage"
    DEV   = "dev"

EnvLiteral = Literal["prod", "stage", "dev"]   # Useful when StrEnum isn't available


# Type checker verifies exhaustiveness with assert_never
from typing import assert_never, Never

def handle_direction(d: Direction) -> str:
    match d:
        case "north": return "Moving north"
        case "south": return "Moving south"
        case "east":  return "Moving east"
        case "west":  return "Moving west"
        case _ as unreachable:
            assert_never(unreachable)  # Static error if new direction added without handling
```

---

### Dict Merge Operators `|` and `|=` (Python 3.9+)

Python 3.9 added `|` for creating a merged dict (non-mutating) and `|=` for in-place merge. These replace `{**a, **b}` for most cases and are clearer in intent.

```python
defaults = {"timeout": 30, "retries": 3, "debug": False}
overrides = {"timeout": 60, "debug": True}

# Old: dict unpacking
merged_old = {**defaults, **overrides}

# New (Python 3.9+): | operator — creates a new dict, right side wins
merged = defaults | overrides
print(merged)   # {'timeout': 60, 'retries': 3, 'debug': True}

# |= mutates in place — right side wins on collision
config = {"host": "localhost", "port": 5432}
extra = {"port": 5433, "db": "mydb"}
config |= extra
print(config)   # {'host': 'localhost', 'port': 5433, 'db': 'mydb'}

# Layered config pattern: base < env < explicit
def build_config(
    base: dict,
    env_overrides: dict,
    explicit: dict,
) -> dict:
    """Right-to-left precedence: explicit > env > base."""
    return base | env_overrides | explicit

cfg = build_config(
    {"debug": False, "workers": 4, "timeout": 30},
    {"workers": 2},       # Scale down in this env
    {"debug": True},      # Explicit override for this run
)
print(cfg)   # {'debug': True, 'workers': 2, 'timeout': 30}

# NOTE: | requires both sides to be dicts; {**a, **b} works with any Mapping
# For Mapping types, use: dict(a) | dict(b)
```

---

### 21. Unpacking `**kwargs` Into Wrong Types  [community]
**Problem:** `**kwargs` collects all keyword arguments into a plain `dict[str, Any]`. Without validation, callers can pass arbitrary keys — including misspelled ones — and the function silently ignores them. Typos in keyword arguments become bugs, not errors.
**Why:** Python's `**kwargs` mechanism has no type enforcement at runtime. `def fn(**kwargs)` accepts any keyword argument; the function body receives a dict and accessing a missing key produces a `KeyError` (or `None` with `.get()`). Typos like `timout=5` silently do nothing.
**Fix:** Use explicit keyword parameters (`def fn(*, timeout: int = 30)`) whenever possible. For truly variable kwargs, use `TypedDict` to document and statically check the expected shape, or use Pydantic for runtime validation.
```python
from typing import TypedDict, Unpack


# BAD — typos silently ignored
def connect(**kwargs):
    host = kwargs.get("host", "localhost")
    port = kwargs.get("port", 5432)
    timeout = kwargs.get("timeout", 30)
    return f"{host}:{port} (timeout={timeout})"

result = connect(host="db", timout=5)   # 'timout' is silently ignored!
print(result)   # db:5432 (timeout=30) — not what caller expected


# GOOD option A — explicit keyword-only parameters
def connect(*, host: str = "localhost", port: int = 5432, timeout: int = 30) -> str:
    return f"{host}:{port} (timeout={timeout})"

# connect(timout=5)  # TypeError: connect() got unexpected keyword argument 'timout'


# GOOD option B — TypedDict + Unpack for typed **kwargs (Python 3.12+)
class ConnectOptions(TypedDict, total=False):
    host: str
    port: int
    timeout: int


def connect_typed(**kwargs: Unpack[ConnectOptions]) -> str:
    host = kwargs.get("host", "localhost")
    port = kwargs.get("port", 5432)
    timeout = kwargs.get("timeout", 30)
    return f"{host}:{port} (timeout={timeout})"

# Type checker now validates: connect_typed(timout=5) — error: unexpected key


# GOOD option C — Pydantic for runtime validation
# from pydantic import BaseModel
# class ConnectConfig(BaseModel):
#     host: str = "localhost"
#     port: int = 5432
#     timeout: int = 30
# cfg = ConnectConfig(**user_input)  # Raises ValidationError on bad input
```

---

### `functools.reduce` and Fold Patterns

`functools.reduce` applies a binary function cumulatively to a sequence, folding it to a single value. It is the functional equivalent of a loop that accumulates a result. Combine with `operator` module for clean, readable pipelines.

```python
from functools import reduce
import operator
from typing import TypeVar, Callable

T = TypeVar("T")


def pipeline(*functions: Callable) -> Callable:
    """Compose a left-to-right pipeline of unary functions using reduce."""
    def composed(value):
        return reduce(lambda v, fn: fn(v), functions, value)
    return composed


# Pipeline composition using reduce
clean = pipeline(
    str.strip,
    str.lower,
    lambda s: s.replace(" ", "_"),
)
print(clean("  Hello World  "))   # hello_world


# reduce for custom aggregation
from dataclasses import dataclass


@dataclass
class SalesRecord:
    region: str
    amount: float
    units: int


records = [
    SalesRecord("East", 1000.0, 10),
    SalesRecord("West", 2500.0, 25),
    SalesRecord("East", 1500.0, 15),
]

totals = reduce(
    lambda acc, r: {
        "total": acc["total"] + r.amount,
        "units": acc["units"] + r.units,
    },
    records,
    {"total": 0.0, "units": 0},   # Initial value (identity element)
)
print(totals)   # {'total': 5000.0, 'units': 50}


# Merge a list of dicts with | (Python 3.9+) using reduce
configs = [{"a": 1}, {"b": 2}, {"c": 3, "a": 99}]
merged = reduce(operator.or_, configs)
print(merged)   # {'a': 99, 'b': 2, 'c': 3}   — later dicts win


# Tree-style reduction: find product of all numbers
numbers = [1, 2, 3, 4, 5]
product = reduce(operator.mul, numbers, 1)
print(product)   # 120
```

**Caution:** `reduce` can obscure intent when the binary function is complex. For complex aggregations, a plain `for` loop with explicit variable names is often clearer. Reserve `reduce` for well-known algebraic patterns (sum, product, merge, compose).

---

### Final Anti-Patterns Quick Reference Additions

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| `global _count` in functions | Hidden coupling, untestable, thread-unsafe | Pass state as parameters or encapsulate in a class |
| `== None` for None checks | Calls `__eq__`; can give False positives with custom objects | `is None` / `is not None` always |
| `result += s` in a loop | O(N²) string concatenation | Accumulate to list, then `"".join(parts)` |
| Comparing floats with `==` | IEEE 754 rounding makes equality unreliable | `math.isclose()` or `decimal.Decimal` for exact arithmetic |
| `__slots__` on child of slot-less parent | Parent `__dict__` survives; no memory savings | Use `@dataclass(slots=True)` or define `__slots__` in ALL classes in MRO |
| `weakref` to non-weakrefable objects | `TypeError` at runtime | Check that the type supports weak references (most user-defined classes do; `int`, `str` do not) |
| Bare `**kwargs` with no validation | Typos silently ignored; no IDE completion | Explicit keyword-only params or `TypedDict + Unpack` |
| Generator used twice | Second iteration is silently empty | Convert to `list()` first or re-create for each pass |
| `except* E` on Python < 3.11 | `SyntaxError` | Guard with version check or use `asyncio.gather(return_exceptions=True)` |
