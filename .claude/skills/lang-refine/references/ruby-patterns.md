# Ruby Patterns & Best Practices
<!-- sources: official rubystyle.guide + ruby-doc.org (Enumerable) + training knowledge [synthesis] | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Everything is an object.** Integers, strings, booleans — all are objects with methods. Write code that embraces this rather than treating Ruby like C with nice syntax.
2. **Expressive over terse.** Ruby's syntax lets you write code that reads like English. Prefer `unless` over `if !condition`, `until` over `while !condition`, and method names that reveal intent.
3. **Duck typing over type hierarchies.** If an object responds to the right messages, it works. Rely on `respond_to?` and `include` checks, not class ancestry.
4. **Blocks are first-class citizens.** The block/yield mechanism is Ruby's primary abstraction tool — lean on it for iterators, callbacks, and DSLs instead of reaching for inheritance.
5. **Convention over configuration.** Ruby practitioners follow community conventions (rubocop, rubystyle.guide) aggressively. Idiomatic code is expected — non-idiomatic code signals ignorance, not cleverness.

---

## Principles / Patterns

### Blocks, Procs, and Lambdas

Ruby has three callable objects. Understanding their differences prevents hard-to-diagnose bugs.

- **Block**: Syntactic construct (not an object), passed with `do...end` or `{...}`, captured via `yield` or `&block`.
- **Proc**: First-class object (`Proc.new` or `proc {}`). Returns from the *enclosing method*, not just the proc itself. Does NOT enforce argument count.
- **Lambda**: A Proc variant (`lambda {}` or `->`). Returns from the lambda only. DOES enforce argument count.

```ruby
# Block usage via yield
def repeat(n)
  n.times { yield }
end
repeat(3) { puts "hello" }

# Explicit block capture
def transform(value, &block)
  block.call(value)
end
transform(5) { |x| x * 2 }   # => 10

# Proc — returns from enclosing method (surprising!)
def proc_demo
  p = Proc.new { return "from proc" }
  p.call
  "after proc"  # never reached
end

# Lambda — returns from lambda itself (safe)
double = lambda { |x| x * 2 }
square = ->(x) { x ** 2 }
puts double.call(4)   # => 8
puts square.(3)       # => 9

# Arity enforcement
strict = ->(a, b) { a + b }
# strict.call(1)      # ArgumentError: wrong number of arguments (given 1, expected 2)
lenient = proc { |a, b| a.to_i + b.to_i }
lenient.call(1)       # => 1  (b is nil, not an error)
```

**Key rule:** Use lambdas when you want function-like behaviour. Use procs for DSL blocks and iterators.

---

### Modules as Mixins

Ruby has single inheritance but unlimited mixin inclusion. Modules replace multiple inheritance cleanly.

```ruby
module Greetable
  def greet
    "Hello, I am #{name}"
  end

  def farewell
    "Goodbye from #{name}"
  end
end

module Loggable
  def log(message)
    puts "[#{self.class}] #{message}"
  end
end

class User
  include Greetable
  include Loggable

  attr_reader :name

  def initialize(name)
    @name = name
    log("User #{name} created")
  end
end

alice = User.new("Alice")
puts alice.greet    # => Hello, I am Alice
puts alice.farewell # => Goodbye from Alice
```

**Method resolution order (MRO):** `include` inserts the module just above the including class in the ancestor chain. Later includes take precedence. Check with `User.ancestors`.

---

### Duck Typing

Depend on behaviour (methods), not type identity. Use `respond_to?` for explicit interface checks; prefer `rescue NoMethodError` as the duck-typing safety net.

```ruby
# Bad: checking class identity
def serialize(obj)
  if obj.is_a?(Hash)
    obj.to_json
  elsif obj.is_a?(String)
    obj
  end
end

# Good: duck typing
def serialize(obj)
  if obj.respond_to?(:to_json)
    obj.to_json
  else
    obj.to_s
  end
end

# Even better: let it fail, rescue explicitly
def process(obj)
  obj.call       # works on Proc, Method, anything callable
rescue NoMethodError => e
  raise ArgumentError, "Expected callable: #{e.message}"
end
```

---

### Enumerable

Include `Enumerable` in any class that represents a collection. Only requirement: implement `#each` that yields elements.

```ruby
class TodoList
  include Enumerable
  include Comparable

  def initialize
    @items = []
  end

  def add(item)
    @items << item
    self
  end

  # Required for Enumerable
  def each(&block)
    @items.each(&block)
  end
end

list = TodoList.new
list.add("Buy groceries").add("Write tests").add("Deploy app")

# Enumerable methods work for free
list.count                             # => 3
list.select { |t| t.start_with?("B") } # => ["Buy groceries"]
list.map(&:upcase)                     # => ["BUY GROCERIES", ...]
list.sort                              # => alphabetical order
list.min                               # => "Buy groceries"
list.group_by { |t| t.length > 10 }   # => {true => [...], false => [...]}
```

**Enumerable power methods to know:**
- `flat_map` — map + flatten one level
- `each_with_object` — accumulate without `inject`'s awkward final-value requirement
- `chunk_while` / `slice_when` — group adjacent elements by condition
- `tally` — frequency count (Ruby 2.7+)
- `lazy` — deferred evaluation for infinite or expensive chains

---

### Comparable

Include `Comparable` and define `<=>` to get `<`, `<=`, `>`, `>=`, `between?`, `clamp` for free.

```ruby
class Temperature
  include Comparable

  attr_reader :degrees

  def initialize(degrees)
    @degrees = degrees
  end

  # Required spaceship operator
  def <=>(other)
    degrees <=> other.degrees
  end

  def to_s
    "#{degrees}°"
  end
end

temps = [Temperature.new(100), Temperature.new(0), Temperature.new(37)]
temps.sort      # => [0°, 37°, 100°]
temps.min       # => 0°
temps.max       # => 100°
Temperature.new(37).between?(Temperature.new(36), Temperature.new(38))  # => true
Temperature.new(200).clamp(Temperature.new(0), Temperature.new(100))    # => 100°
```

---

### Symbol vs String

Symbols are immutable, interned identifiers — they live once in memory. Strings are mutable object instances.

```ruby
# Use symbols for: hash keys, method names, status codes, identifiers
config = { host: "localhost", port: 3000, env: :production }
config[:host]    # => "localhost"
config[:env]     # => :production

# Use strings for: text content, user input, file paths, anything that changes
name = "Alice"
name << " Smith"   # => "Alice Smith" (mutation)

# Symbol to proc shortcut — very common Ruby idiom
names = ["alice", "bob", "carol"]
names.map(&:capitalize)   # => ["Alice", "Bob", "Carol"]
names.select(&:frozen?)   # selects frozen strings

# Dynamic symbols: Symbol.all_symbols can grow memory if strings-to-symbols are
# created dynamically. Never do: user_input.to_sym
```

---

### frozen_string_literal

The magic comment `# frozen_string_literal: true` at the top of a file makes all string literals in that file immutable. Mandatory in performance-sensitive code and a best practice everywhere.

```ruby
# frozen_string_literal: true

# Strings created as literals are now frozen
GREETING = "Hello"
# GREETING << " World"   # => FrozenError (caught at runtime, not silently corrupted)

# String duplication when mutation is needed
mutable = +"Hello"      # unary + unfreezes a string copy (Ruby 2.3+)
mutable << " World"     # => "Hello World"

# Why it matters:
# - Every string literal becomes a single shared object instead of a new allocation
# - Immutable strings are thread-safe
# - Prevents accidental mutation of "constants" that are string literals
```

---

### method_missing and respond_to_missing?  [community]

`method_missing` enables powerful DSLs but creates invisible interfaces and hard-to-debug code. Always pair with `respond_to_missing?`.

```ruby
# BAD: method_missing without respond_to_missing?
class DynamicProxy
  def method_missing(name, *args)
    if name.to_s.start_with?("find_by_")
      attribute = name.to_s.sub("find_by_", "")
      @data.select { |item| item[attribute.to_sym] == args[0] }
    else
      super  # Always call super for unhandled cases!
    end
  end
  # Missing respond_to_missing? — breaks respond_to? checks
end

# GOOD: Pair method_missing with respond_to_missing?
class FlexibleRecord
  def initialize(attrs)
    @attrs = attrs
  end

  def method_missing(name, *args)
    key = name.to_s.chomp("=").to_sym
    if name.to_s.end_with?("=")
      @attrs[key] = args.first
    elsif @attrs.key?(key)
      @attrs[key]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    key = name.to_s.chomp("=").to_sym
    @attrs.key?(key) || super
  end
end

record = FlexibleRecord.new(name: "Alice", age: 30)
record.name           # => "Alice"
record.name = "Bob"   # => "Bob"
record.respond_to?(:name)  # => true (would be false without respond_to_missing?)
```

---

### Struct and Data Classes

Use `Struct` for simple value objects. Use `Data` (Ruby 3.2+) for immutable value objects.

```ruby
# Struct: mutable, quick value objects with comparison and serialization
Point = Struct.new(:x, :y) do
  def distance_to(other)
    Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end

  def to_s
    "(#{x}, #{y})"
  end
end

p1 = Point.new(0, 0)
p2 = Point.new(3, 4)
p1.distance_to(p2)  # => 5.0

# Data: immutable (Ruby 3.2+), better for value objects
Measure = Data.define(:amount, :unit) do
  def to_s
    "#{amount} #{unit}"
  end
end

m = Measure.new(amount: 100, unit: "kg")
# m.amount = 200  # NoMethodError — frozen by design
m2 = m.with(amount: 200)  # Non-destructive update returns new instance
```

---

### Keyword Arguments and Argument Patterns

Ruby 3.0+ enforces keyword argument separation. Use kwargs for clarity in methods with 2+ parameters.

```ruby
# Positional args — order-dependent, error-prone for callers
def create_user(name, email, admin)
  # caller must remember: name, email, admin — easy to mix up
end

# Keyword args — self-documenting, order-independent
def create_user(name:, email:, admin: false)
  User.new(name: name, email: email, admin: admin)
end

create_user(name: "Alice", email: "alice@example.com")
create_user(email: "bob@example.com", name: "Bob", admin: true)

# Double splat for flexible option forwarding
def log(message, **options)
  level = options.fetch(:level, :info)
  timestamp = options.fetch(:timestamp, Time.now)
  puts "[#{timestamp}][#{level.upcase}] #{message}"
end
```

---

## Language Idioms

Ruby-specific features that make code more expressive:

### Symbol-to-Proc shortcut
```ruby
# &:method_name converts a symbol to a block calling that method
[1, 2, 3].map(&:to_s)          # => ["1", "2", "3"]
["hello", "world"].map(&:upcase) # => ["HELLO", "WORLD"]
users.select(&:admin?)           # select admin users
```

### Conditional assignment operators
```ruby
# ||= — assign if nil or false (memoization pattern)
@cached_result ||= expensive_computation()

# &&= — assign only if already truthy (safe chained assignment)
user.name &&= user.name.strip   # only strips if name is not nil/false
```

### Safe navigation operator (&.)
```ruby
# Avoid nil guards cascading
user&.address&.city   # returns nil if any is nil, instead of NoMethodError

# vs the old way
city = user && user.address && user.address.city
```

### Tap and Then/Yield_self for pipelines
```ruby
# tap: for side-effects in a chain (debugging, logging)
User.new(name: "Alice")
  .tap { |u| puts "Before save: #{u.name}" }
  .save!
  .tap { |u| puts "Saved with id: #{u.id}" }

# then / yield_self: pass object into a block, return block result
"hello"
  .then { |s| s.upcase }
  .then { |s| "#{s}!" }
# => "HELLO!"
```

### Heredocs for multiline strings
```ruby
sql = <<~SQL
  SELECT users.*, posts.title
  FROM users
  JOIN posts ON posts.user_id = users.id
  WHERE users.active = true
SQL
# <<~ strips leading whitespace (squiggly heredoc, Ruby 2.3+)
```

### Array and Hash shorthand constructors
```ruby
# %w[] for word arrays, %i[] for symbol arrays
days = %w[monday tuesday wednesday thursday friday]
statuses = %i[pending active archived]

# Hash from pairs
keys = [:a, :b, :c]
values = [1, 2, 3]
Hash[keys.zip(values)]          # => {a: 1, b: 2, c: 3}
keys.zip(values).to_h           # same, more idiomatic
```

### Pattern Matching (Ruby 3.0+)
```ruby
# Find pattern in case/in
case user
in { role: "admin", name: String => name }
  puts "Admin: #{name}"
in { role: "user", verified: true }
  puts "Verified user"
in { role: "user", verified: false }
  puts "Unverified user"
end

# Deconstruct arrays
case coordinates
in [Float => lat, Float => lng] if lat.abs <= 90
  puts "Valid: #{lat}, #{lng}"
end
```

---

## Real-World Gotchas  [community]

### 1. **method_missing without respond_to_missing?** [community]
Implementing `method_missing` without its companion `respond_to_missing?` breaks the Ruby object protocol. Code that calls `object.respond_to?(:dynamic_method)` returns `false` even though the method works. Libraries like RSpec, serializers, and proxies rely on `respond_to?` — they will silently skip your dynamic methods. **Fix:** Always implement both together and always call `super` for unhandled cases.

### 2. **Proc return semantics in iterators** [community]
Using `Proc.new` or `proc {}` blocks inside iterators can cause the *enclosing method* to return unexpectedly. This is the most common source of "why did my method exit early?" bugs. Practitioners hit this when extracting `each` blocks into named procs. **Fix:** Use lambdas (`->`) when you need a callable that returns locally; use procs only when you explicitly want the enclosing-method-return behaviour (which is almost never in iterators).

### 3. **Frozen string literal mutation** [community]
Adding `# frozen_string_literal: true` (or upgrading gems that ship it) causes `FrozenError` when code does `string << "suffix"` or `string.gsub!`. This breaks silently in tests and loudly in production when third-party gems get updated. Root cause: developers habitually mutate strings with `<<` or bang methods. **Fix:** Use `+""` or `String.new` when mutation is required; switch to non-bang alternatives (`gsub` instead of `gsub!`).

### 4. **Symbol explosion from user input** [community]
Calling `.to_sym` on user-provided strings causes unbounded growth of the global symbol table in Ruby < 2.2 (symbols were not garbage-collected). Even in modern Ruby, interning thousands of symbols wastes memory. **Fix:** Never call `.to_sym` on data you don't control. If you need symbol keys from an API, use `transform_keys(&:to_sym)` only on known-bounded key sets (configuration hashes, not user content).

### 5. **Overusing method_missing for attribute accessors** [community]
Teams new to Ruby metaprogramming implement `method_missing`-based attribute access when `attr_accessor`, `Struct`, or `OpenStruct` would suffice. `method_missing` adds a full method-lookup overhead on every call (Ruby tries every ancestor first). **Fix:** Use `attr_accessor` for known attributes, `Struct` for value objects, and `method_missing` only for genuinely *dynamic* interfaces that can't be enumerated at class definition time.

### 6. **Modifying arrays during iteration** [community]
Calling `delete`, `push`, or `<<` on an array while iterating it with `each` causes elements to be skipped or double-processed — Ruby does not raise an error, it silently behaves incorrectly. **Fix:** Use `select` / `reject` / `map` to return new collections, or collect changes into a separate array and apply them after iteration completes.

### 7. **Integer#times vs Range#each performance on large sets** [community]
`(0...n).each` allocates a Range object and calls `each`. `n.times` avoids the Range allocation. For tight loops in hot paths this matters. More importantly, developers confuse `0.upto(n-1)` with `1.upto(n)` — off-by-one bugs masquerading as iteration bugs. **Fix:** Use `n.times` for counted loops, `array.each_with_index` when you need both element and index, and `(a..b).each` only when you explicitly need a range with meaningful endpoints.

### 8. **OpenStruct in performance-sensitive code** [community]
`OpenStruct` is convenient but dramatically slower than `Struct` or plain hashes. It uses `method_missing` and instance variable assignment internally. Ruby core team has considered deprecating it. **Fix:** Use `Struct.new(:field1, :field2)` for known-shape data, `Data.define` (Ruby 3.2+) for immutable value objects, or `Hash` with symbol keys for dynamic shapes.

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| `rescue Exception` | Catches `SignalException`, `Interrupt`, `NoMemoryError` — prevents Ctrl+C and crash recovery | `rescue StandardError` (default), or rescue specific exceptions |
| `for` loop | Doesn't create its own scope — loop variable leaks after the loop | `array.each`, `n.times`, `(a..b).each` |
| `unless ... else` | Double negation in the else branch is near-impossible to read | Rewrite as `if ... else` |
| Using `==` for type check | `obj == String` compares to the class object, always false | `obj.is_a?(String)` or duck-type with `respond_to?` |
| `Thread.new` without error handling | Unhandled exceptions in threads are silently swallowed in Ruby < 2.4 | Set `Thread.abort_on_exception = true` or use concurrent-ruby |
| Global variables (`$var`) | Shared mutable global state — race conditions in threaded code, hidden coupling | Instance variables, class variables with accessors, or dependency injection |
| Chaining bang methods (`sort!`, `map!`) | Mutates the receiver — callers who hold a reference see unexpected changes | Return new collections; use bang methods only on local variables |
| `Object#send` bypassing visibility | Calls private methods — breaks encapsulation silently | Redesign the interface; if testing privates, extract to a collaborator class |
| `puts nil.inspect` for debugging | Left in production code → noisy logs | Use a debugger (byebug/debug) or structured logging |
| Bareword method calls in modules | `method_name(arg)` inside a module calls Kernel methods if the instance method doesn't exist | Explicitly `self.method_name(arg)` or design the module to not rely on caller's method space |
