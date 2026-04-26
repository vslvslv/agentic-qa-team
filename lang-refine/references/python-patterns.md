# Python Patterns & Best Practices
<!-- sources: mixed (official + community) | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

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
log_lines = ("ERROR" in line for line in open("app.log"))
any_errors = any(log_lines)   # Stops at first match; never reads the whole file
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
    print(f"Failing port: {port}")

# Also useful in while loops
data = b"initial"
while chunk := data[:4]:
    process(chunk)
    data = data[4:]
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
**Why:** Practitioners learned this through cross-platform bugs where code written on macOS broke on Windows CI.
**Fix:** Use `pathlib.Path` everywhere. The `/` operator handles separator differences automatically.

### 7. Not Using `__slots__` for High-Volume Objects  [community]
**Problem:** Plain classes store instance attributes in a `__dict__`, using roughly 200–400 bytes per instance. When you create millions of small objects (e.g., in a data pipeline), memory balloons silently.
**Why:** Python's dynamic attribute model defaults to dict-backed storage. `__slots__` replaces the per-instance dict with a fixed-layout structure.
**Fix:** Add `__slots__` to data-heavy classes, or use `@dataclass(slots=True)` (Python 3.10+).
```python
# Without slots: ~280 bytes per instance
class PointNoSlots:
    def __init__(self, x, y):
        self.x, self.y = x, y

# With slots: ~56 bytes per instance
class Point:
    __slots__ = ("x", "y")
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y

# Or with dataclass (Python 3.10+)
from dataclasses import dataclass

@dataclass(slots=True)
class FastPoint:
    x: float
    y: float
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
