# Python Patterns & Best Practices
<!-- sources: mixed (official + community) | iteration: 2 | score: 100/100 | date: 2026-04-30 -->
<!-- iteration trace:
     Iter 0: 100/100 — initial draft (all checklist items + 10 idioms + 10 community gotchas)
     Iter 1: 100/100 (+0) — added Advanced Type Annotations (TypeGuard/TypeIs/ParamSpec/NewType/Self; official docs.python.org/3/library/typing.html); Protocol structural subtyping deep-dive
     Iter 2: 100/100 (+0) — added dataclass utility functions (asdict/astuple/replace/fields; official dataclasses docs); added TypedDict and Annotated patterns; added descriptor-based validation idiom
     STOP: delta < 3 for two consecutive iterations (iter 1 delta=0, iter 2 delta=0)
-->

## Core Philosophy

1. **Readability counts** (PEP 20): Code is read far more often than written. Every decision should optimise for the reader six months later.
2. **Explicit is better than implicit**: Favour clarity over magic. Hidden control flow and mutable shared state are enemies of maintainability.
3. **There should be one obvious way**: Python provides a preferred idiom for most tasks. Learn it and resist inventing alternatives.
4. **Errors should never pass silently**: Catch only what you can handle; let the rest propagate. A swallowed exception is a lie to the codebase.
5. **Namespaces are a honking great idea**: Organise code with modules and packages; avoid polluting the global namespace.

---

## Principles / Patterns

### PEP 8 Naming Conventions
Python's official style guide establishes naming conventions that the entire ecosystem expects. Violating them signals unfamiliarity with the language and hinders collaboration across teams.

```python
# Classes: CapWords (PascalCase)
class UserRepository:
    pass

# Functions and variables: lower_case_with_underscores (snake_case)
def fetch_user_by_id(user_id: int) -> "User":
    result = None
    return result

# Constants: UPPER_CASE_WITH_UNDERSCORES
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Modules: lowercase (single word preferred)
# Good: utils.py, models.py, handlers.py
# Avoid: myUtils.py, MyModule.py

# Private by convention: single leading underscore
class Config:
    def __init__(self) -> None:
        self._internal_state = {}   # "don't touch unless you know what you're doing"
        self.__really_private = 42  # name-mangled to _Config__really_private
```

---

### List / Dict / Set Comprehensions
Comprehensions are Pythonic and faster than equivalent `for`-loops with `.append()`. Use them for transformations and filters. Prefer a loop when the body involves side effects or complex multi-step logic.

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
Generators produce values lazily — they do not materialise a full sequence in memory. Use them for large or infinite sequences, and any pipeline where you only need one item at a time.

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
any_errors = any(log_lines)   # Stops at first match
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
Type hints are annotations read by static analysers (mypy, pyright) and IDEs — they do not affect runtime behaviour by default. They document intent, enable safe refactoring, and catch bugs before execution.

```python
from typing import Optional, Protocol, TypeAlias, TypeGuard, ParamSpec
from collections.abc import Callable, Sequence

# Basic function signature
def greet(name: str, times: int = 1) -> str:
    return (f"Hello, {name}!\n") * times

# Union type (Python 3.10+ preferred syntax)
def parse_id(value: str | int) -> int:
    return int(value)

# Optional — when None is a valid value
def find_user(user_id: int) -> Optional["User"]:
    ...

# Type alias for readability (Python 3.12+ type statement)
Matrix: TypeAlias = list[list[float]]

# Protocol for structural typing (duck typing + type safety)
class Serialisable(Protocol):
    def to_json(self) -> str: ...

def save(obj: Serialisable) -> None:
    payload = obj.to_json()
    ...

# TypeGuard — enable type narrowing via predicate function
def is_str_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def join_strings(val: list[object]) -> str:
    if is_str_list(val):
        return ", ".join(val)   # val is now list[str]
    return ""
```

---

### Dataclasses
`@dataclass` auto-generates `__init__`, `__repr__`, and `__eq__` from field annotations. Prefer them over plain classes for data-holding objects. Use `frozen=True` for immutable value objects and `slots=True` for memory efficiency.

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

@dataclass(slots=True)   # Python 3.10+ — ~4x less memory per instance
class Particle:
    x: float
    y: float
    z: float
    velocity: float

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

# EAFP shines for filesystem ops — avoids time-of-check/time-of-use race
def process_file(path: str) -> None:
    try:
        with open(path, encoding="utf-8") as fh:
            data = fh.read()
    except FileNotFoundError:
        print(f"File not found: {path}")
    except PermissionError:
        print(f"No permission to read: {path}")
```

---

### Dunder Methods (`__dunder__`)
Special methods hook into Python's object model. Implement them to make objects work naturally with built-in operations, operators, and protocols.

```python
from functools import total_ordering

@total_ordering   # Generates <=, >, >= from __eq__ and __lt__
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
`abc.ABC` with `@abstractmethod` enforces that subclasses implement required methods — Python's nearest equivalent to interfaces in Java/C#.

```python
from abc import ABC, abstractmethod

class NotificationService(ABC):
    """All notification backends must implement send() and verify_recipient()."""

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

### Advanced Type Annotations (Python 3.10–3.13)
Python's typing module has matured significantly. `TypeGuard`/`TypeIs` enable type narrowing via predicate functions; `ParamSpec` preserves callable signatures through decorators; `NewType` creates lightweight distinct types; `Self` enables accurate return types in subclasses; Python 3.12 adds `[T]` syntax for type parameters.

```python
from typing import TypeGuard, TypeIs, ParamSpec, NewType, Self
from collections.abc import Callable

# TypeGuard — narrow a type inside a conditional branch
def is_str_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def join_if_strings(val: list[object]) -> str:
    if is_str_list(val):
        return ", ".join(val)   # val is now list[str]
    return ""

# TypeIs — subtype-safe narrowing (Python 3.13+; preferred over TypeGuard for subtype checks)
class Animal: pass
class Dog(Animal): pass

def is_dog(val: object) -> TypeIs[Dog]:
    return isinstance(val, Dog)

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
    ...  # Signature preserved: fetch_record(record_id: int, *, timeout: float = 5.0)

# NewType — distinct type for type safety at zero runtime cost
UserId = NewType("UserId", int)
ProUserId = NewType("ProUserId", UserId)

def get_user_name(user_id: UserId) -> str: ...

user = get_user_name(UserId(42351))  # type-safe
# get_user_name(42351)  # Type error: plain int is not UserId

# Self — accurate return type for fluent interfaces and subclasses
class Builder:
    def set_name(self, name: str) -> Self:
        self._name = name
        return self   # Type checker infers the actual subclass type, not just Builder

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

---

### Structural Subtyping with `Protocol`
`Protocol` enables duck typing with static analysis. Unlike `ABC`, implementing classes need not inherit from the protocol — any class with the required attributes satisfies it structurally (PEP 544). Use `@runtime_checkable` only when `isinstance()` checks are needed at runtime.

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Drawable(Protocol):
    """Any object with draw() + colour satisfies this protocol."""
    def draw(self, x: int, y: int) -> None: ...

    @property
    def colour(self) -> str: ...

# Neither class inherits from Drawable — they satisfy it structurally
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

shapes: list[Drawable] = [Circle(5.0, "red"), Square(3.0, "blue")]
render_all(shapes, (10, 20))

# @runtime_checkable enables isinstance() checks (structural, not nominal)
assert isinstance(Circle(1.0, "green"), Drawable)
```

---

### `pathlib` over `os.path`
`pathlib.Path` provides an object-oriented, cross-platform filesystem API. Use the `/` operator for path joining and chain method calls for all path operations.

```python
from pathlib import Path

# Traverse paths with / operator — no string concatenation, no separator bugs
project_root = Path(__file__).parent.parent
config_file = project_root / "config" / "settings.toml"

# Common operations
if config_file.exists():
    content = config_file.read_text(encoding="utf-8")

# Write and create parent directories in one step
output = project_root / "reports" / "summary.txt"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("Report content here", encoding="utf-8")

# Glob patterns
python_files = list(project_root.rglob("*.py"))
print(f"Found {len(python_files)} Python files")

# What NOT to do — os.path is verbose and error-prone
import os
# BAD: os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "settings.toml")
```

---

## Language Idioms

These are features unique to Python that make code more expressive — not just generic OOP patterns expressed in Python syntax.

### Unpacking and Starred Assignment
```python
# Swap without a temporary variable
a, b = 1, 2
a, b = b, a

# Extended unpacking — capture head, middle, or tail
first, *rest = [1, 2, 3, 4, 5]       # first=1, rest=[2, 3, 4, 5]
head, *middle, last = [10, 20, 30, 40, 50]  # head=10, middle=[20,30,40], last=50

# Unpack in a for loop
pairs = [(1, "a"), (2, "b"), (3, "c")]
for number, letter in pairs:
    print(f"{number}: {letter}")
```

### `enumerate()` and `zip()`
```python
fruits = ["apple", "banana", "cherry"]

# enumerate — Pythonic index + value iteration; avoid range(len(...))
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

# Assign and test in one expression — avoids computing twice
text = "Error: connection timeout on port 8080"
if match := re.search(r"port (\d+)", text):
    port = match.group(1)
    print(f"Failing port: {port}")  # Failing port: 8080

# Useful in while loops — process a buffer in fixed-size chunks
def process_chunks(data: bytes, chunk_size: int = 4) -> list[bytes]:
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
queue: deque[str] = deque(maxlen=100)
queue.appendleft("high-priority")
queue.append("normal")
```

### f-Strings and String Formatting
```python
name = "World"
value = 3.14159265

# f-strings (Python 3.6+) — preferred for most formatting
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

# lru_cache — memoize expensive pure functions (bounded)
@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# cache — unbounded LRU (Python 3.9+); simpler when memory is not a concern
@cache
def expensive_lookup(key: str) -> str:
    return key.upper()   # Imagine this hits a database

# partial — fix some arguments to create a specialised callable
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

# islice — take the first N from any (possibly infinite) iterator
def natural_numbers():
    n = 1
    while True:
        yield n
        n += 1

first_ten = list(itertools.islice(natural_numbers(), 10))
# [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# groupby — group sorted data (requires pre-sorted input)
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
Python's `match` statement dispatches on the *structure* of an object — sequences, mapping keys, class attributes — in a single expression, eliminating chains of `isinstance` / `if-elif`.

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
        case ["pick", "up", item]:
            return f"pick up {item}"
        case _:
            return "unknown command"

print(describe_point(Point(0, 5)))             # Y-axis at 5.0
print(classify_command(["go", "north"]))        # move north
print(classify_command(["pick", "up", "key"]))  # pick up key
```

### `typing.NamedTuple` for Typed Tuples
`typing.NamedTuple` gives named tuples type annotations and default values while remaining lightweight (tuple semantics, no per-instance `__dict__`).

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
x, y, _ = c                # unpacking works

# NamedTuples are hashable by default — usable in sets and as dict keys
visited: set[Coordinate] = {Coordinate(0.0, 0.0), Coordinate(1.0, 1.0)}
```

### `TypedDict` for Typed Dictionaries
`TypedDict` creates dict subclasses with type-checked key/value pairs. Use it for JSON payloads, configuration blobs, or any place you'd otherwise use `dict[str, Any]`.

```python
from typing import TypedDict, Required, NotRequired

class MovieBase(TypedDict):
    title: str
    year: int

class Movie(MovieBase, total=False):
    """total=False makes all fields optional by default."""
    director: str    # Optional
    rating: float    # Optional

class StrictMovie(TypedDict):
    title: Required[str]          # Always required
    rating: NotRequired[float]    # Explicitly optional (Python 3.11+)

def display_movie(movie: Movie) -> str:
    director = movie.get("director", "Unknown")
    return f"{movie['title']} ({movie['year']}) — {director}"

film: Movie = {"title": "Inception", "year": 2010, "director": "Nolan"}
print(display_movie(film))
```

### Dataclass Utility Functions (`asdict`, `astuple`, `replace`, `fields`)
The `dataclasses` module provides helpers for serialisation, copying, and introspection of dataclass instances.

```python
from dataclasses import dataclass, field, asdict, astuple, replace, fields

@dataclass
class Address:
    street: str
    city: str
    country: str = "US"

@dataclass
class Person:
    name: str
    age: int
    address: Address
    tags: list[str] = field(default_factory=list)

p = Person("Alice", 30, Address("123 Main St", "Springfield"))

# asdict — deep-converts to nested dicts (for JSON serialisation)
print(asdict(p))
# {'name': 'Alice', 'age': 30, 'address': {'street': '123 Main St', ...}, 'tags': []}

# astuple — deep-converts to nested tuples
print(astuple(p))
# ('Alice', 30, ('123 Main St', 'Springfield', 'US'), [])

# replace — create a modified copy without mutation (like frozen but works on mutable too)
senior = replace(p, age=65)
promoted = replace(p, address=replace(p.address, city="Capital City"))

# fields — introspect field names and metadata at runtime
for f in fields(p):
    print(f"{f.name}: {f.type}")
```

### `Annotated` for Metadata-Enriched Types
`Annotated` attaches runtime metadata to types without affecting static type checking. Use it for validation libraries (Pydantic, attrs), documentation generators, or custom tooling.

```python
from typing import Annotated
from dataclasses import dataclass

# Metadata is accessible at runtime via __metadata__
PositiveInt = Annotated[int, "must be positive"]
Email = Annotated[str, "must contain @"]

@dataclass
class UserInput:
    age: PositiveInt
    email: Email

# Validation library can inspect the metadata
import typing

def validate(cls) -> None:
    hints = typing.get_type_hints(cls, include_extras=True)
    for field_name, hint in hints.items():
        if typing.get_origin(hint) is Annotated:
            constraint = typing.get_args(hint)[1]
            print(f"{field_name}: {constraint}")

validate(UserInput)
# age: must be positive
# email: must contain @
```

### `__init_subclass__` for Lightweight Class Registration
`__init_subclass__` is called automatically whenever a class is subclassed, enabling plugin registries without metaclasses.

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

print(Command._registry)   # {'quit': QuitCommand, 'help': HelpCommand}
cmd = Command._registry["help"]()
print(cmd.execute())        # Commands: quit, help
```

---

## Real-World Gotchas  [community]

### 1. Mutable Default Arguments  [community]
**Problem:** Using a mutable object (list, dict, set) as a default argument value creates a single shared object across all calls.
**Why:** Default argument values are evaluated once at function *definition* time, not on each call. The default object is stored on the function object itself. Every call that uses the default mutates the same shared container.
**Fix:** Use `None` as the sentinel and create the mutable object inside the function body.
```python
# BAD
def add_item(item, container=[]):
    container.append(item)
    return container

add_item(1)  # [1]
add_item(2)  # [1, 2] — unexpected shared state!

# GOOD
def add_item(item, container=None):
    if container is None:
        container = []
    container.append(item)
    return container
```

### 2. Modifying a Collection During Iteration  [community]
**Problem:** Removing or inserting items from a list while iterating over it causes unpredictable skips or infinite loops.
**Why:** Python tracks iteration position by index. Removing an element shifts indices, causing items to be skipped. Adding elements can cause infinite loops.
**Fix:** Iterate over a copy (`list(items)`) or build a new collection with a comprehension.
```python
# BAD
items = [1, 2, 3, 4, 5]
for item in items:
    if item % 2 == 0:
        items.remove(item)  # Skips items silently!

# GOOD — build a new list
items = [item for item in items if item % 2 != 0]
# Or iterate over a copy
for item in list(items):
    if item % 2 == 0:
        items.remove(item)
```

### 3. Bare `except:` or Overly Broad `except Exception:`  [community]
**Problem:** Catching all exceptions swallows `KeyboardInterrupt`, `SystemExit`, and unexpected bugs, making programs unresponsive and impossible to debug.
**Why:** `except:` catches everything including signals and system exits. Even `except Exception:` hides programming errors as if they were handled.
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
**Problem:** `is` tests object identity (same memory address), not equality. Small integers and interned strings may pass `is` comparisons by coincidence due to CPython caching.
**Why:** CPython caches integers in the range [-5, 256] and interns short strings. Code relying on this is CPython-specific behaviour — other implementations (PyPy, Jython) behave differently, and future versions may change the cache bounds.
**Fix:** Use `==` for value comparison. Reserve `is` for singletons: `None`, `True`, `False`.
```python
# BAD — passes by accident in CPython but unreliable
big_count = 1000
if big_count is 1000:   # False outside CPython cache range
    ...

# GOOD
if big_count == 1000:   # Always correct
    ...
if result is None:      # Correct use of 'is' for singletons
    ...
```

### 5. Shadowing Built-in Names  [community]
**Problem:** Naming variables `list`, `dict`, `id`, `type`, `input`, `filter` silently replaces the built-in for the entire scope.
**Why:** Python's LEGB scoping looks in local scope first. Once you write `list = [1, 2, 3]`, calling `list()` later in that scope calls your variable, not the constructor — causing confusing `TypeError`s.
**Fix:** Append a trailing underscore (`list_`, `type_`, `id_`) or choose a domain-specific name.
```python
# BAD
list = [1, 2, 3]          # Shadows built-in list()
new_list = list([4, 5])   # TypeError: 'list' object is not callable

# GOOD
items = [1, 2, 3]
new_items = list([4, 5])  # list() still works

# Trailing underscore when the name must be similar
type_ = get_entity_type()
```

### 6. Not Using `pathlib` — Relying on `os.path` String Manipulation  [community]
**Problem:** Concatenating paths with string addition (`path + "/" + filename`) breaks on Windows (`\` vs `/`), misses edge cases with trailing slashes, and is verbose.
**Why:** Practitioners discovered this through cross-platform CI failures. `os.path.join` avoids the separator bug but returns a plain string, so every subsequent operation requires a different `os.path.*` call — a maintenance trap vs. method chaining on `Path`.
**Fix:** Use `pathlib.Path` everywhere. The `/` operator handles cross-platform separators automatically.

### 7. Not Using `__slots__` for High-Volume Objects  [community]
**Problem:** Plain classes store instance attributes in a per-instance `__dict__`, consuming ~200–400 bytes per instance. Millions of small objects silently exhaust memory.
**Why:** Python's dynamic attribute model defaults to dict-backed storage. `__slots__` replaces the per-instance dict with a fixed-layout structure, reducing size by 4–5×.
**Fix:** Add `__slots__` to data-heavy classes, or use `@dataclass(slots=True)` (Python 3.10+).
```python
# Without slots: ~280 bytes per instance
class PointNoSlots:
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y

# With slots: ~56 bytes per instance
class Point:
    __slots__ = ("x", "y")
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y

# Or with dataclass (Python 3.10+) — preferred
from dataclasses import dataclass

@dataclass(slots=True)
class FastPoint:
    x: float
    y: float
```

### 8. Returning `None` Implicitly After Mutation  [community]
**Problem:** A method mutates an object and returns `None`. Callers write `result = items.sort()` expecting the sorted list, receive `None`, then crash on the next operation.
**Why:** Python's Command/Query separation convention: mutating methods return `None` to signal "side-effect only". Built-in types follow this consistently, but it trips up developers writing their own classes who mix mutation and return values.
**Fix:** Use `sorted()` (returns new list) vs `list.sort()` (mutates in-place). Document clearly; return `self` explicitly for chaining.
```python
# BAD — user expects the sorted list
items = [3, 1, 2]
sorted_items = items.sort()   # None!
print(sorted_items[0])        # TypeError: 'NoneType' object is not subscriptable

# GOOD — use built-in sorted() for a new list
sorted_items = sorted(items)

# GOOD — mutate in-place, don't assign
items.sort()
print(items[0])  # 1

# For custom classes: return self explicitly if chaining is desired
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
**Problem:** Module A imports module B, and module B imports module A. Python partially initialises the first module, so names defined after the import line don't exist when the second module tries to use them.
**Why:** Python's import system executes module code top-to-bottom on first import and caches a partially-initialised module in `sys.modules`. When B tries to access `A.SomeClass` before A finishes loading, the name is simply missing.
**Fix:** Restructure to break the cycle — move shared types to a third module (`models.py`, `types.py`). If unavoidable, use a local import inside the function.
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
    from services import UserService  # Deferred; avoids circular load
    return UserService()
```

### 10. Mutable Default in `@dataclass` Field Without `default_factory`  [community]
**Problem:** Assigning a mutable default directly to a dataclass field causes a `ValueError` at class definition time — but many developers don't know why and try workarounds that introduce shared state.
**Why:** The dataclass decorator detects mutable defaults (list, dict, set) and raises `ValueError` to prevent the same shared-state bug that affects plain function defaults. If you bypass this with `field(default=some_list)`, all instances share one list.
**Fix:** Always use `field(default_factory=list)` / `field(default_factory=dict)` for container defaults.
```python
from dataclasses import dataclass, field

# BAD — raises ValueError at class definition
@dataclass
class BadConfig:
    allowed_hosts: list[str] = []   # ValueError: mutable default not allowed

# GOOD
@dataclass
class Config:
    allowed_hosts: list[str] = field(default_factory=list)
    metadata: dict[str, str] = field(default_factory=dict)
```

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| Bare `except:` | Swallows `KeyboardInterrupt`, hides bugs | Catch specific exception types |
| Mutable default argument | Shared state across all calls | Use `None` sentinel + create inside function |
| `from module import *` | Pollutes namespace, breaks static analysis | Explicit imports: `from module import X, Y` |
| `type(obj) == SomeClass` | Breaks with subclasses | `isinstance(obj, SomeClass)` |
| `is` for value comparison | Relies on CPython internals | `==` for values; `is` only for singletons |
| Shadowing built-ins (`list`, `id`, `type`) | Silent replacement of built-ins | Domain-specific names or trailing `_` |
| String path joining with `+` | Cross-platform breakage | `pathlib.Path` and `/` operator |
| `os.path` over `pathlib` | Verbose, error-prone, less readable | `pathlib.Path` |
| `Any` everywhere in type hints | Defeats static analysis | `Protocol`, generics, or specific types |
| Modifying collection during iteration | Skipped or duplicated items | Iterate a copy or use a comprehension |
| Mutable default in `@dataclass` without `default_factory` | `ValueError` or shared state | `field(default_factory=list)` |
| Circular imports between modules | Partial initialisation errors | Extract shared types to a third module |
| Using `match` without a `case _:` wildcard | Silent fall-through | Always add `case _:` or document intentional omission |
| `Optional[int] = 0` (wrong Optional use) | `None` not actually needed | `int = 0` for default value parameters |
| `order=True` with `eq=False` in `@dataclass` | `ValueError` at class definition | Keep both or use neither |
