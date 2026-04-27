# JavaScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 2 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Asynchronous by design** — JavaScript's single-threaded event loop is a feature, not a limitation. Design code around non-blocking I/O; never stall the event loop with CPU-intensive synchronous work.
2. **Functions as first-class citizens** — Functions are values. Closures, higher-order functions, and callbacks are idiomatic, not clever tricks.
3. **Progressive disclosure of complexity** — Modules, closures, and the prototype chain make it possible to keep public APIs simple while hiding implementation detail.
4. **ES2022+ is the baseline** — Modern JavaScript (async/await, optional chaining, nullish coalescing, ESM, private class fields, `Error.cause`) is universally supported. Write modern syntax; transpile only when your deploy target demands it.
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
    // Re-throw with context so callers know the origin (ES2022 Error.cause)
    throw new Error(`fetchUserProfile failed for ${userId}`, { cause: error });
  }
}

// Usage — caller can inspect the root cause
try {
  const profile = await fetchUserProfile(42);
} catch (err) {
  console.error(err.message);       // fetchUserProfile failed for 42
  console.error(err.cause.message); // HTTP 404: Not Found
}
```

### Concurrent Promises with Promise.all / Promise.allSettled
Running independent async operations sequentially is the most common performance mistake in JS code. Use `Promise.all` when all operations must succeed; use `Promise.allSettled` when partial results are acceptable; use `Promise.any` when you need the first success.

```javascript
// BAD: sequential awaits on independent operations (2 + 1 = 3 seconds)
async function slowFetch() {
  const user  = await fetchUser(1);    // waits 2s
  const posts = await fetchPosts(1);   // waits 1s after user is done
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

// GOOD: partial results acceptable (Promise.allSettled never rejects)
async function dashboardData() {
  const results = await Promise.allSettled([
    fetchUser(1),
    fetchPosts(1),
    fetchMetrics(1),
  ]);
  return results.map(r => (r.status === 'fulfilled' ? r.value : null));
}

// GOOD: first successful result wins (Promise.any)
async function fetchFromMirror(mirrors) {
  return Promise.any(mirrors.map(url => fetch(url).then(r => r.json())));
}
```

### Async Iteration with for await...of
ES2018 async iteration lets you consume async generators and readable streams idiomatically — without manual `.next()` calls or event listeners.

```javascript
// Async generator producing items lazily
async function* paginate(endpoint) {
  let page = 1;
  while (true) {
    const { items, hasMore } = await fetch(`${endpoint}?page=${page}`)
      .then(r => r.json());
    yield* items;
    if (!hasMore) break;
    page += 1;
  }
}

// Consume with for await...of — clean, break-able, error-catchable
async function processAll(endpoint) {
  for await (const item of paginate(endpoint)) {
    await processItem(item);
  }
}

// Node.js readable stream is an async iterable (Node 10+)
import { createReadStream } from 'fs';
async function readLines(file) {
  const lines = [];
  for await (const chunk of createReadStream(file, { encoding: 'utf8' })) {
    lines.push(chunk);
  }
  return lines.join('');
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

// Dynamic import for lazy-loading (code-splitting)
async function loadChart() {
  const { default: Chart } = await import('./chart.js');
  return new Chart(document.getElementById('canvas'));
}

// Top-level await (ESM only) — replace init() patterns
const config = await loadConfig('./config.json');
export { config };
```

### ES2022+ Language Features
Modern JavaScript has rich syntactic sugar that reduces boilerplate and improves intent clarity. These features are part of the language baseline — no polyfills needed in modern engines.

```javascript
// Optional chaining — safe deep property access, short-circuits on null/undefined
const city = user?.address?.city ?? 'Unknown';

// Nullish coalescing — default only on null/undefined, not 0 or ''
const timeout = config.timeout ?? 3000;

// Logical assignment (ES2021)
settings.debug   ??= false;    // Set if null/undefined
settings.verbose ||= false;    // Set if falsy
settings.enabled &&= validate(settings.enabled); // Update only if truthy

// Array.at() — negative indexing (ES2022)
const last = items.at(-1);     // Same as items[items.length - 1]
const second = items.at(1);

// Object.hasOwn() — safer than obj.hasOwnProperty() (ES2022)
if (Object.hasOwn(user, 'email')) { /* ... */ }

// Class private fields and methods (ES2022)
class EventEmitter {
  #listeners = new Map();   // Private field — inaccessible outside class
  #emit(event, data) {      // Private method
    this.#listeners.get(event)?.forEach(fn => fn(data));
  }
  on(event, fn) {
    const list = this.#listeners.get(event) ?? [];
    this.#listeners.set(event, [...list, fn]);
  }
}

// structuredClone — deep clone without JSON round-trip (ES2022)
const original = { dates: [new Date()], map: new Map([['key', 1]]) };
const clone = structuredClone(original); // Preserves Date, Map, Set, etc.
```

### Error Handling — Extending Error Classes with Cause
Throwing strings or generic `Error` loses type information and makes catch blocks unable to distinguish error types. Extend `Error` for structured error handling. Use `cause` (ES2022) to preserve error chain context without losing stack traces.

```javascript
// Custom error hierarchy
class AppError extends Error {
  constructor(message, options) {
    super(message, options); // Forwards { cause } to built-in Error
    this.name = this.constructor.name;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} with id=${id} not found`);
    this.resource = resource;
    this.id = id;
  }
}

class ValidationError extends AppError {
  constructor(field, message) {
    super(`Validation failed on '${field}': ${message}`);
    this.field = field;
  }
}

// Consumer can discriminate by type
async function handleRequest(req, res) {
  try {
    const user = await getUser(req.params.id);
    res.json(user);
  } catch (err) {
    if (err instanceof NotFoundError) {
      return res.status(404).json({ error: err.message });
    }
    if (err instanceof ValidationError) {
      return res.status(400).json({ error: err.message, field: err.field });
    }
    throw err; // Unknown error — re-throw for global handler
  }
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
console.log(Object.hasOwn(dog, 'speak'));  // false — on prototype
console.log(Object.hasOwn(dog, 'name'));   // true — instance property

// Prototype chain lookup order: instance → Dog.prototype → Animal.prototype → Object.prototype → null
```

### Event Loop Understanding
The event loop processes a call stack, microtask queue (Promises, `queueMicrotask`), and macrotask queue (`setTimeout`, `setInterval`, I/O) in that strict order per iteration. Understanding this prevents ordering surprises in async code.

```javascript
console.log('1 - synchronous');

setTimeout(() => console.log('4 - macrotask'), 0);

Promise.resolve()
  .then(() => console.log('2 - microtask 1'))
  .then(() => console.log('3 - microtask 2'));

console.log('1b - still synchronous');

// Output order: 1, 1b, 2, 3, 4
// Rule: ALL microtasks drain before the next macrotask runs.
// queueMicrotask() also runs before setTimeout(fn, 0)

queueMicrotask(() => console.log('microtask via queueMicrotask'));
```

### AbortController for Cancellable Async Operations
`AbortController` is the standard way to cancel fetch requests, async operations, and event listeners. Always pass a signal through async call chains so callers can cancel work in progress.

```javascript
// Cancel a fetch after a timeout
async function fetchWithTimeout(url, ms = 5000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);

  try {
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    return await response.json();
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new Error(`Request to ${url} timed out after ${ms}ms`);
    }
    throw err;
  }
}

// Reusable: pass signal through layers so any layer can cancel
async function loadUserData(userId, signal) {
  const [profile, posts] = await Promise.all([
    fetch(`/api/users/${userId}`, { signal }).then(r => r.json()),
    fetch(`/api/users/${userId}/posts`, { signal }).then(r => r.json()),
  ]);
  return { profile, posts };
}

// Caller controls cancellation
const ac = new AbortController();
someButton.addEventListener('click', () => ac.abort());
const data = await loadUserData(42, ac.signal);
```

### Node.js Streams and Buffers
Streams process data in chunks without loading entire files into memory. Use `pipeline` (not `pipe`) in modern Node.js for proper error propagation. `Buffer` is Node's fixed-length binary container — use it for binary data, not string manipulation.

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

// Buffer — binary data handling
const buf = Buffer.from('Hello World', 'utf8');
console.log(buf.toString('hex'));    // Hex encoding
console.log(buf.toString('base64')); // Base64 encoding
console.log(buf.length);             // Byte length (may differ from char length)

// Allocate a safe zeroed buffer (never use Buffer.allocUnsafe in user-facing paths)
const safe = Buffer.alloc(16);
```

### WeakMap / WeakRef for Memory-Safe Caches
Use `WeakMap` to associate data with objects without preventing garbage collection. Use `WeakRef` + `FinalizationRegistry` only in long-running cache scenarios where you want automatic eviction when the GC collects keys.

```javascript
// WeakMap — object-keyed side data that doesn't prevent GC
const metaCache = new WeakMap();

function getMetadata(domNode) {
  if (!metaCache.has(domNode)) {
    metaCache.set(domNode, computeExpensiveMetadata(domNode));
  }
  return metaCache.get(domNode);
}
// When domNode is removed from DOM and dereferenced, metaCache entry
// is automatically eligible for GC — no manual cleanup needed.

// WeakRef + FinalizationRegistry — voluntary eviction cache
function makeWeakCache(getter) {
  const cache = new Map();
  const registry = new FinalizationRegistry(key => {
    if (!cache.get(key)?.deref()) cache.delete(key);
  });
  return async key => {
    const ref = cache.get(key);
    const hit = ref?.deref();
    if (hit !== undefined) return hit;
    const value = await getter(key);
    cache.set(key, new WeakRef(value));
    registry.register(value, key);
    return value;
  };
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

// Function parameter destructuring with defaults
function renderUser({ name, role = 'viewer', active = true } = {}) {
  return `${name} (${role}) — ${active ? 'active' : 'inactive'}`;
}

// Nested destructuring
const { address: { city, zip = 'N/A' } = {} } = user;
```

### Tagged Template Literals
```javascript
// SQL query builder example — prevents injection by separating strings from values
function sql(strings, ...values) {
  return {
    text:   strings.reduce((acc, str, i) => `${acc}$${i}${str}`),
    values, // Values are never interpolated into the string
  };
}

const userId = 42;
const query = sql`SELECT * FROM users WHERE id = ${userId} AND active = ${true}`;
// query.text   → "SELECT * FROM users WHERE id = $1 AND active = $2"
// query.values → [42, true]
```

### Iterators and Generators
```javascript
// Generator as lazy sequence — only computes values on demand
function* range(start, end, step = 1) {
  for (let i = start; i < end; i += step) {
    yield i;
  }
}

for (const n of range(0, 10, 2)) {
  console.log(n);  // 0, 2, 4, 6, 8
}

// Spread consumes any iterable
const evens = [...range(0, 10, 2)];  // [0, 2, 4, 6, 8]

// Infinite sequence with early break
function* naturals() {
  let n = 1;
  while (true) yield n++;
}
const first5 = [...take(5, naturals())]; // [1, 2, 3, 4, 5]
```

### Computed Properties and Symbol Keys
```javascript
// Symbols as unique, non-enumerable property keys — never collide
const _secret = Symbol('secret');

class Service {
  constructor() {
    this[_secret] = { token: 'hidden-value' };
  }
  getInfo() {
    return `Service uses: ${this[_secret].token}`;
  }
}

const s = new Service();
console.log(Object.keys(s));          // [] — symbol keys hidden
console.log(JSON.stringify(s));       // {} — symbol keys not serialised
```

### Proxy for Meta-programming
```javascript
// Validation proxy — intercepts property assignment
function createValidated(target, rules) {
  return new Proxy(target, {
    set(obj, prop, value) {
      if (rules[prop] && !rules[prop](value)) {
        throw new TypeError(`Invalid value for "${prop}": ${JSON.stringify(value)}`);
      }
      Reflect.set(obj, prop, value);
      return true;
    },
  });
}

const user = createValidated({}, {
  age:   v => Number.isInteger(v) && v >= 0 && v <= 150,
  email: v => typeof v === 'string' && v.includes('@'),
});

user.age = 25;            // OK
user.email = 'a@b.com';   // OK
user.age = -1;            // Throws TypeError
```

### Optional Chaining and Nullish Coalescing in Combination
```javascript
// Read deeply nested config with safe fallbacks
function getEndpoint(config, service) {
  return config?.services?.[service]?.endpoint
    ?? `https://api.default.com/${service}`;
}

// Call optional methods safely
const result = obj?.transform?.() ?? defaultValue;

// Optional chaining with dynamic keys
const value = data?.[dynamicKey]?.nested ?? fallback;
```

---

## Real-World Gotchas  [community]

**1. Floating Promises** [community] — Calling an async function without `await` or `.catch()` creates a "floating" promise. The operation runs but errors are silently discarded. WHY it causes problems: in production this hides failed operations (DB writes, API calls) that callers assume succeeded. Fix: always `await` or chain `.catch()`.

```javascript
// BAD — fire and forget, errors vanish
saveUser(user);  // Promise ignored; if it rejects, nobody knows

// GOOD — await in async context
await saveUser(user);

// GOOD — explicit fire-and-forget with error logging
saveUser(user).catch(err => logger.error('saveUser failed', err));
```

**2. Sequential Awaits on Independent Operations** [community] — Using multiple `await` statements in a row for operations that don't depend on each other is a common performance anti-pattern. WHY it causes problems: it serialises work that could run in parallel, multiplying total latency proportionally to the number of calls. Fix: use `Promise.all` for concurrent independent operations.

```javascript
// BAD: ~3 seconds total
const user    = await fetchUser(1);
const posts   = await fetchPosts(1);
const metrics = await fetchMetrics(1);

// GOOD: ~1 second (limited by slowest)
const [user, posts, metrics] = await Promise.all([
  fetchUser(1), fetchPosts(1), fetchMetrics(1),
]);
```

**3. `var` Leaking Through Block Scopes** [community] — Using `var` in loops or `if` blocks creates function-scoped (or global) variables instead of block-scoped ones. WHY it causes problems: closures over `var` in loops capture the final loop value, not the per-iteration value, breaking event handlers and callbacks set up in loops. Fix: use `const` by default, `let` when reassignment is needed, never `var`.

**4. Unhandled Promise Rejections** [community] — In Node.js ≥15, an unhandled promise rejection terminates the process with a non-zero exit code. In browsers it fires a global `unhandledrejection` event. WHY it causes problems: entire services crash or go silent when a single async operation lacks a rejection handler. Fix: attach `process.on('unhandledRejection', handler)` as a last-resort safety net, but the real fix is handling errors at the call site.

**5. Mutating Shared State in Async Callbacks** [community] — Updating a shared array or object inside multiple async callbacks without coordination is a race condition. WHY it causes problems: JS is single-threaded but async callbacks interleave between awaits, so reads and writes to shared state can produce inconsistent intermediate results. Fix: collect results through `Promise.all` into a new value rather than mutating a shared variable.

**6. `this` Context Lost in Callbacks** [community] — Passing a class method as a callback loses its `this` binding. WHY it causes problems: `this` inside the callback becomes `undefined` (strict mode) or the global object, causing property-access errors that are hard to trace. Fix: use arrow functions (which capture `this` lexically) or explicit `.bind(this)`.

```javascript
class Timer {
  tick() { console.log('tick', this.count); }

  start() {
    // BAD: this becomes undefined in strict mode
    setTimeout(this.tick, 1000);

    // GOOD: arrow function captures this from enclosing scope
    setTimeout(() => this.tick(), 1000);
  }
}
```

**7. JSON.parse / JSON.stringify Silently Corrupts Special Types** [community] — `JSON.stringify` throws on `BigInt` values and silently converts `Date` objects to ISO strings. On parse, those strings are not re-hydrated as `Date` instances. Maps, Sets, and `undefined` values are also lost. WHY it causes problems: silent data corruption in serialised state, API payloads, and caches. Fix: use a custom replacer/reviver or a library like `superjson` / `devalue`.

**8. Event Emitter Errors Bypass try-catch** [community] — Error events on Node.js `EventEmitter` instances are NOT caught by try-catch. WHY it causes problems: if no `'error'` listener is registered, Node throws the error and may crash the process — yet there is no surrounding catch block that would catch it. Fix: always attach `.on('error', handler)` to streams, sockets, and child processes.

```javascript
import { createReadStream } from 'fs';
const stream = createReadStream('/nonexistent');

// BAD — try-catch will not catch the 'error' event
try {
  stream.on('data', chunk => console.log(chunk));
} catch (e) { /* Never runs */ }

// GOOD — register an error listener
stream
  .on('data', chunk => console.log(chunk))
  .on('error', err => console.error('Stream error:', err));
```

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
| Modifying function parameters directly | Surprise side-effects for callers; referential equality breaks | Return new values; copy with `structuredClone` or spread |
| Using `==` instead of `===` | Implicit type coercion produces surprising truthy/falsy results | Always use `===` and `!==` |
| Missing `return` in `.then()` handler | Breaks promise chain; subsequent handlers receive `undefined` | Always `return` the next promise from `.then()` |
| Catching and re-throwing without `cause` | Original stack trace is lost; root cause debugging is hard | Use `throw new Error('context', { cause: err })` |
