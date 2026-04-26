# JavaScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Asynchronous by design** — JavaScript's single-threaded event loop is a feature, not a limitation. Design code around non-blocking I/O; never stall the event loop with CPU-intensive synchronous work.
2. **Functions as first-class citizens** — Functions are values. Closures, higher-order functions, and callbacks are idiomatic, not clever tricks.
3. **Progressive disclosure of complexity** — Modules, closures, and the prototype chain make it possible to keep public APIs simple while hiding implementation detail.
4. **ES2020+ is the baseline** — Modern JavaScript (async/await, optional chaining, nullish coalescing, ESM) is universally supported. Write modern syntax; transpile only when your deploy target demands it.
5. **Errors are values too** — Treating errors as second-class citizens (ignoring Promise rejections, swallowing catch blocks) is the single most common source of silent failures in production.

---

## Principles / Patterns

### async/await for Asynchronous Control Flow
`async`/`await` is syntactic sugar over Promises that lets you write asynchronous code that reads like synchronous code. An `async` function always returns a Promise. `await` suspends execution of the current function until the awaited Promise settles; it does not block the thread.

```javascript
// Idiomatic async/await with proper error handling
async function fetchUserProfile(userId) {
  try {
    const response = await fetch(`/api/users/${userId}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    const profile = await response.json();
    return profile;
  } catch (error) {
    // Re-throw with context so callers know the origin
    throw new Error(`fetchUserProfile failed for ${userId}: ${error.message}`);
  }
}

// Usage
const profile = await fetchUserProfile(42);
```

### Concurrent Promises with Promise.all / Promise.allSettled
Running independent async operations sequentially is the most common performance mistake in JS code. Use `Promise.all` when all operations must succeed; use `Promise.allSettled` when partial results are acceptable.

```javascript
// BAD: sequential awaits on independent operations (2 + 1 = 3 seconds)
async function slowFetch() {
  const user = await fetchUser(1);      // waits 2s
  const posts = await fetchPosts(1);    // waits 1s after user is done
  return { user, posts };
}

// GOOD: concurrent execution (max(2, 1) = 2 seconds)
async function fastFetch() {
  const [user, posts] = await Promise.all([
    fetchUser(1),
    fetchPosts(1),
  ]);
  return { user, posts };
}

// GOOD: partial results acceptable (never rejects)
async function dashboardData() {
  const results = await Promise.allSettled([
    fetchUser(1),
    fetchPosts(1),
    fetchMetrics(1),
  ]);
  return results.map(r => (r.status === 'fulfilled' ? r.value : null));
}
```

### Closures for Data Encapsulation
A closure is a function that captures and retains access to variables from its enclosing scope after that scope has finished executing. This is the foundation of the module pattern and factory functions.

```javascript
// Factory function using closure for private state
function createCounter(initial = 0) {
  let count = initial;  // Private — not accessible outside

  return {
    increment() { count += 1; },
    decrement() { count -= 1; },
    reset()     { count = initial; },
    value()     { return count; },
  };
}

const counter = createCounter(10);
counter.increment();
counter.increment();
console.log(counter.value());  // 12
console.log(counter.count);    // undefined — truly private
```

### ESM Module Pattern
ECMAScript Modules (ESM) is the standard module system. Prefer named exports for better tooling (tree-shaking, refactoring); use default exports sparingly and only for clearly single-purpose modules.

```javascript
// utils/math.js — named exports
export function add(a, b) { return a + b; }
export function multiply(a, b) { return a * b; }
export const PI = Math.PI;

// main.js — tree-shakeable import
import { add, PI } from './utils/math.js';
console.log(add(2, PI));

// Dynamic import for lazy-loading
async function loadChart() {
  const { default: Chart } = await import('./chart.js');
  return new Chart(document.getElementById('canvas'));
}
```

### ES2022+ Features
Modern JavaScript has rich syntactic sugar that reduces boilerplate and improves intent clarity.

```javascript
// Optional chaining — safe deep property access
const city = user?.address?.city ?? 'Unknown';

// Nullish coalescing — default only on null/undefined, not 0 or ''
const timeout = config.timeout ?? 3000;

// Logical assignment
settings.debug ??= false;    // Set if null/undefined
settings.verbose ||= false;  // Set if falsy
settings.enabled &&= validate(settings.enabled); // Update only if truthy

// Array destructuring with rest
const [first, second, ...rest] = getItems();

// Object shorthand + computed keys
const key = 'id';
const obj = { [key]: 1, first, second };

// Top-level await (in ESM modules)
const config = await loadConfig();

// Class fields (ES2022)
class EventEmitter {
  #listeners = new Map();   // Private field

  on(event, fn) {
    const list = this.#listeners.get(event) ?? [];
    this.#listeners.set(event, [...list, fn]);
  }
}
```

### Error Handling — Extending Error Classes
Throwing strings or generic `Error` loses type information and makes catch blocks unable to distinguish error types. Extend `Error` for structured error handling.

```javascript
// Custom error hierarchy
class AppError extends Error {
  constructor(message, code) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} with id=${id} not found`, 'NOT_FOUND');
    this.resource = resource;
    this.id = id;
  }
}

class ValidationError extends AppError {
  constructor(field, message) {
    super(`Validation failed on '${field}': ${message}`, 'VALIDATION');
    this.field = field;
  }
}

// Consumer can discriminate
try {
  await getUser(id);
} catch (err) {
  if (err instanceof NotFoundError) {
    return res.status(404).json({ error: err.message });
  }
  if (err instanceof ValidationError) {
    return res.status(400).json({ error: err.message, field: err.field });
  }
  throw err; // Unknown error — re-throw
}
```

### Prototype Chain and Class Syntax
The prototype chain is JavaScript's inheritance mechanism. ES6 `class` syntax is syntactic sugar — under the hood, methods still live on `ClassName.prototype`. Understanding this matters for debugging and performance.

```javascript
class Animal {
  constructor(name) {
    this.name = name;
  }
  speak() {
    return `${this.name} makes a sound.`;
  }
}

class Dog extends Animal {
  speak() {
    return `${this.name} barks.`;
  }
}

const dog = new Dog('Rex');
console.log(dog.speak());             // "Rex barks."
console.log(dog instanceof Dog);      // true
console.log(dog instanceof Animal);   // true

// Verify methods live on the prototype, not the instance
console.log(Object.hasOwn(dog, 'speak'));      // false (on prototype)
console.log(Object.hasOwn(dog, 'name'));       // true (instance property)
```

### Event Loop Understanding
The event loop processes a call stack, microtask queue (Promises, queueMicrotask), and macrotask queue (setTimeout, setInterval) in that order per iteration. Understanding this prevents ordering surprises.

```javascript
console.log('1 - synchronous');

setTimeout(() => console.log('4 - macrotask'), 0);

Promise.resolve()
  .then(() => console.log('2 - microtask 1'))
  .then(() => console.log('3 - microtask 2'));

console.log('1b - still synchronous');

// Output order: 1, 1b, 2, 3, 4
// Rule: all microtasks drain before next macrotask runs
```

### Node.js Streams
Streams process data in chunks without loading entire files into memory. Use pipeline (not pipe) in modern Node.js for proper error propagation.

```javascript
import { createReadStream, createWriteStream } from 'fs';
import { createGzip } from 'zlib';
import { pipeline } from 'stream/promises';

// pipeline properly propagates errors and cleans up on failure
async function compressFile(input, output) {
  await pipeline(
    createReadStream(input),
    createGzip(),
    createWriteStream(output),
  );
  console.log('Compression complete');
}
```

---

## Language Idioms

These are features specific to JavaScript that make code more expressive — not generic OOP patterns rewritten in JS.

### Destructuring Assignment
```javascript
// Object destructuring with rename and default
const { name: userName = 'Anonymous', age = 0 } = getUser();

// Array destructuring — swap values without temp variable
let a = 1, b = 2;
[a, b] = [b, a];

// Function parameter destructuring
function renderUser({ name, role = 'viewer', active = true }) {
  return `${name} (${role}) — ${active ? 'active' : 'inactive'}`;
}
```

### Tagged Template Literals
```javascript
// SQL query builder example — prevents injection
function sql(strings, ...values) {
  return {
    text: strings.reduce((acc, str, i) => `${acc}$${i}${str}`),
    values,
  };
}

const query = sql`SELECT * FROM users WHERE id = ${userId} AND active = ${true}`;
```

### Iterators and Generators
```javascript
// Generator as lazy sequence — only computes on demand
function* range(start, end, step = 1) {
  for (let i = start; i < end; i += step) {
    yield i;
  }
}

for (const n of range(0, 10, 2)) {
  console.log(n);  // 0, 2, 4, 6, 8
}

// Spread consumes iterable
const evens = [...range(0, 10, 2)];  // [0, 2, 4, 6, 8]
```

### Computed Properties and Symbol Keys
```javascript
// Symbols as unique property keys — never collide
const _private = Symbol('private');

class Service {
  constructor() {
    this[_private] = { secret: 'hidden' };
  }
  getInfo() {
    return `Service: ${this[_private].secret}`;
  }
}
// Object.keys() won't reveal symbol-keyed properties
```

### Proxy for Meta-programming
```javascript
// Validation proxy — intercepts property set
function createValidated(target, rules) {
  return new Proxy(target, {
    set(obj, prop, value) {
      if (rules[prop] && !rules[prop](value)) {
        throw new TypeError(`Invalid value for ${prop}: ${value}`);
      }
      obj[prop] = value;
      return true;
    },
  });
}

const user = createValidated({}, {
  age: v => Number.isInteger(v) && v >= 0 && v <= 150,
});
user.age = 25;    // OK
user.age = -1;    // Throws TypeError
```

---

## Real-World Gotchas  [community]

**1. Floating Promises** [community] — Calling an async function without `await` or `.catch()` creates a "floating" promise. The operation runs but errors are silently discarded. WHY it causes problems: in production this hides failed operations (DB writes, API calls) that callers assume succeeded. Fix: always `await` or chain `.catch()`.

```javascript
// BAD — fire and forget, errors vanish
saveUser(user);  // Promise ignored

// GOOD — await in async context
await saveUser(user);

// GOOD — explicit fire-and-forget with error logging
saveUser(user).catch(err => logger.error('saveUser failed', err));
```

**2. Sequential Awaits on Independent Operations** [community] — Using multiple `await` statements in a row for operations that don't depend on each other is a common performance anti-pattern. WHY it causes problems: it serializes work that could run in parallel, multiplying total latency. Fix: use `Promise.all` for independent concurrent operations.

**3. `var` Leaking Through Block Scopes** [community] — Using `var` in loops or `if` blocks creates function-scoped (or global) variables instead of block-scoped ones. WHY it causes problems: closures over `var` in loops capture the final value, not the per-iteration value, breaking event handlers and callbacks set up in loops. Fix: use `const` by default, `let` when reassignment is needed, never `var`.

**4. Unhandled Promise Rejections** [community] — In Node.js ≥15, an unhandled promise rejection terminates the process. In browsers it fires a global event. WHY it causes problems: entire services crash or go silent when a single async operation is not handled. Fix: attach `process.on('unhandledRejection', ...)` as a safety net, but the real fix is handling errors at the call site.

**5. Mutating Shared State in Event Callbacks** [community] — Updating a shared array or object inside multiple async callbacks without synchronisation is a race condition. WHY it causes problems: JS is single-threaded but async callbacks interleave, so reads and writes to shared state can produce inconsistent results. Fix: collect results through `Promise.all` into a new array rather than pushing into a shared one.

**6. `this` Context Lost in Callbacks** [community] — Passing a class method as a callback loses its `this` binding. WHY it causes problems: `this` inside the callback becomes `undefined` (strict mode) or the global object, causing property-access errors that are hard to trace. Fix: use arrow functions (which capture `this` lexically) or explicit `.bind(this)`.

```javascript
class Timer {
  start() {
    // BAD: this is lost
    setTimeout(this.tick, 1000);

    // GOOD: arrow function preserves this
    setTimeout(() => this.tick(), 1000);
  }
  tick() { console.log('tick', this); }
}
```

**7. JSON.parse / JSON.stringify Swallowing BigInt and Dates** [community] — `JSON.stringify` throws on `BigInt` values and silently converts `Date` objects to ISO strings. On parse, those strings are not re-hydrated as `Date` objects. WHY it causes problems: silent data corruption in serialised state, API payloads, and caches. Fix: use a custom replacer/reviver or a library like `superjson`.

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Floating Promise | Errors silently discarded; operation status unknown | Always `await` or `.catch()` |
| Sequential `await` on independent ops | Multiplies latency; serialises parallelisable work | Use `Promise.all` |
| `var` in loops with closures | All closures share one binding; captures final loop value | Use `const`/`let` |
| Throwing strings (`throw 'error'`) | No stack trace; `instanceof` checks fail | Extend `Error` class |
| Ignoring `catch` with empty block | Swallows exceptions silently | Log or re-throw; never `catch(e) {}` |
| Defining methods in constructor | Each instance gets its own function copy; wastes memory | Define methods on `prototype` / use `class` syntax |
| Mixing ESM and CJS imports | Interop edge-cases; tooling confusion | Standardise on ESM; set `"type": "module"` in package.json |
| `console.log` in production | Unstructured, unsearchable output; leaks sensitive data | Use a structured logger (Pino / Winston) |
| Modifying function parameters directly | Surprise side-effects for callers; referential equality breaks | Return new values; copy with spread or `structuredClone` |
| Using `==` instead of `===` | Implicit type coercion produces surprising truthy/falsy results | Always use `===` and `!==` |
