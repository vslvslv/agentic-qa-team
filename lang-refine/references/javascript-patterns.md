# JavaScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 7 | score: 100/100 | date: 2026-04-28 -->

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

### CommonJS (CJS) vs ES Modules (ESM)

Node.js supports two module systems. ESM is the modern standard for new code; CJS is legacy but still pervasive in the npm ecosystem. Understanding both is essential for Node.js developers.

```javascript
// ── CommonJS (CJS) ──────────────────────────────────────────────────
// File: math.cjs  (or any .js with no "type": "module" in package.json)
function add(a, b) { return a + b; }
const PI = 3.14159;

module.exports = { add, PI };        // Named exports via object
// or: exports.add = add;            // Shorthand (not the same as module.exports = fn)

// Consuming CJS:
const { add, PI } = require('./math.cjs');

// ── ES Modules (ESM) ────────────────────────────────────────────────
// File: math.mjs  (or .js with "type": "module" in package.json)
export function add(a, b) { return a + b; }
export const PI = 3.14159;

// Consuming ESM:
import { add, PI } from './math.mjs';

// ── Interoperability rules ───────────────────────────────────────────
// ESM CAN import CJS — Node.js wraps CJS exports as the default export:
import cjsModule from './legacy.cjs';  // module.exports becomes default
import { namedExport } from './legacy.cjs'; // static analysis extracts named exports

// CJS CANNOT synchronously require() an ESM file:
// const esm = require('./modern.mjs'); // ERR_REQUIRE_ESM

// CJS workaround — dynamic import (returns a Promise):
async function loadESM() {
  const { add } = await import('./modern.mjs');
  return add(1, 2);
}

// ── Dual-package hazard ──────────────────────────────────────────────
// If a package ships both CJS and ESM entry points and holds shared state,
// consumers may get two separate instances (CJS instance ≠ ESM instance).
// Mitigation: stateless code in the shared layer; single ESM entry preferred.
```

**Key decision table:**

| Situation | Use |
|-----------|-----|
| New Node.js project | ESM — set `"type": "module"` in package.json |
| Legacy codebase on `require()` | CJS — migrate incrementally |
| Publishing an npm package | ESM primary + CJS compatibility layer via `exports` field |
| Need `__dirname` / `__filename` | CJS, or ESM: `import.meta.dirname` / `import.meta.filename` (Node 21+) |
| Top-level `await` | ESM only |
| Synchronous config loading | CJS `require()` or `createRequire()` workaround in ESM |

---

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

// ── ES2023 / ES2024 additions ────────────────────────────────────────

// Array immutable change methods (ES2023) — return new arrays, no mutation
const arr = [3, 1, 4, 1, 5];
const sorted   = arr.toSorted();               // [1, 1, 3, 4, 5] — arr unchanged
const reversed = arr.toReversed();             // [5, 1, 4, 1, 3] — arr unchanged
const updated  = arr.with(2, 99);             // [3, 1, 99, 1, 5] — arr unchanged
const spliced  = arr.toSpliced(1, 2, 9, 8);  // [3, 9, 8, 1, 5]  — arr unchanged

// Object.groupBy (ES2024) — group array items into an object by key
const people = [
  { name: 'Alice', dept: 'eng' },
  { name: 'Bob',   dept: 'design' },
  { name: 'Carol', dept: 'eng' },
];
const byDept = Object.groupBy(people, p => p.dept);
// { eng: [Alice, Carol], design: [Bob] }

// Promise.withResolvers (ES2024) — expose resolve/reject outside the executor
// Useful for wrapping event-driven APIs
function waitForEvent(emitter, event) {
  const { promise, resolve, reject } = Promise.withResolvers();
  emitter.once(event,  resolve);
  emitter.once('error', reject);
  return promise;
}
const data = await waitForEvent(stream, 'data');

// Array.fromAsync (ES2024) — materialise an async iterable into an array
// Equivalent to: const arr = []; for await (const v of iter) arr.push(v);
async function collectPages(endpoint) {
  async function* getPages() {
    let page = 1;
    while (true) {
      const { items, hasMore } = await fetch(`${endpoint}?page=${page}`).then(r => r.json());
      yield* items;
      if (!hasMore) break;
      page++;
    }
  }
  return Array.fromAsync(getPages()); // [ ...all items across all pages ]
}

// Array.fromAsync with mapFn — transform each awaited element
const doubled = await Array.fromAsync(
  [Promise.resolve(1), Promise.resolve(2), Promise.resolve(3)],
  async v => v * 2,
); // [2, 4, 6]

// NOTE: Array.fromAsync awaits elements SEQUENTIALLY (unlike Promise.all which is concurrent)
// Use Promise.all when concurrency matters; use Array.fromAsync for ordered async streams
```

### Date Handling — `Date` Today, `Temporal` Tomorrow
The built-in `Date` object is mutable, timezone-limited, and millisecond-precision. For new projects, use `date-fns` or `luxon` today; adopt the `Temporal` API (ES2025 proposal, limited browser support as of 2026 — polyfill required) for robust, immutable date handling.

```javascript
// Current production reality: date-fns (tree-shakeable, immutable)
import { format, addDays, differenceInCalendarDays } from 'date-fns';

const today   = new Date();
const nextWeek = addDays(today, 7);
console.log(format(nextWeek, 'yyyy-MM-dd'));  // "2026-05-05"
console.log(differenceInCalendarDays(nextWeek, today)); // 7

// Future-proof: Temporal API (use @js-temporal/polyfill until native support)
// import { Temporal } from '@js-temporal/polyfill';

const date = Temporal.PlainDate.from({ year: 2026, month: 5, day: 5 });
const nextMonth = date.add({ months: 1 });
console.log(nextMonth.toString()); // "2026-06-05" — immutable; date unchanged

// ZonedDateTime — correct timezone-aware arithmetic
const meeting = Temporal.ZonedDateTime.from({
  year: 2026, month: 5, day: 15, hour: 9, timeZone: 'America/New_York',
});
const londonTime = meeting.withTimeZone('Europe/London');

// Why Temporal over Date:
// - Immutable: all operations return new values
// - Timezone-correct: DST transitions handled properly
// - Nanosecond precision
// - Multiple calendar systems
// - Clear separation: PlainDate (no time), Instant (no tz), ZonedDateTime (all)
```

**Recommendation:** For production code in 2026, use `date-fns` (immutable, tree-shakeable) or `luxon` for timezone-rich apps. Use `Temporal` with `@js-temporal/polyfill` in new projects — the API is stable even if native support is incomplete.


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

### Explicit Resource Management — `using` and `await using` (ES2025)
ES2025 introduces deterministic, lexically-scoped resource cleanup via `using` and `await using` declarations. Any object that implements `[Symbol.dispose]()` (or `[Symbol.asyncDispose]()` for async) is automatically cleaned up when the block exits — even on exception. This is JavaScript's RAII pattern and replaces fragile `try-finally` chains.

```javascript
// Define a disposable resource (implements Symbol.dispose)
class DatabaseConnection {
  #conn;
  #isOpen = true;

  constructor(url) {
    this.#conn = openConnection(url); // hypothetical
  }

  query(sql) {
    if (!this.#isOpen) throw new Error('Connection is closed');
    return this.#conn.execute(sql);
  }

  [Symbol.dispose]() {
    this.#isOpen = false;
    this.#conn.close();
    console.log('DB connection closed');
  }
}

// 'using' guarantees disposal even if processRows() throws
async function runQuery(url) {
  using db = new DatabaseConnection(url);
  const rows = db.query('SELECT * FROM users');
  processRows(rows);
  // db[Symbol.dispose]() called automatically here
}

// 'await using' for async cleanup (e.g., flush buffers, async close)
class AsyncFileWriter {
  #handle;
  constructor(path) { this.#handle = openFile(path); }
  write(data) { return this.#handle.write(data); }
  async [Symbol.asyncDispose]() {
    await this.#handle.flush();
    await this.#handle.close();
  }
}

async function writeReport(path) {
  await using writer = new AsyncFileWriter(path);
  await writer.write('line 1\n');
  await writer.write('line 2\n');
  // writer[Symbol.asyncDispose]() awaited automatically here
}

// DisposableStack — manage a group of resources acquired at different times
async function processWithStack() {
  await using stack = new AsyncDisposableStack();
  const db  = stack.use(new DatabaseConnection('/db1'));
  const db2 = stack.use(new DatabaseConnection('/db2'));
  // ... both disposed in reverse order when scope exits
}
```

**Why it matters over `try-finally`:** with `try-finally` a throw inside `finally` silently suppresses the original error. `using` aggregates all errors into a `SuppressedError` chain so nothing is lost, and cleanup order is guaranteed to be reverse-declaration.

### Iterator Helpers (ES2025)
`Iterator.prototype` now ships with `map`, `filter`, `take`, `drop`, `flatMap`, `reduce`, `toArray`, `forEach`, `some`, `every`, and `find` — the same operations you know from arrays, but **lazy**: no intermediate arrays are allocated, and evaluation stops as soon as possible.

```javascript
// Array approach: creates 3 intermediate arrays
const result1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  .filter(n => n % 2 === 0)   // [2,4,6,8,10] — full pass
  .map(n => n * n)             // [4,16,36,64,100] — full pass
  .slice(0, 3);                // [4,16,36]

// Iterator approach: single lazy pass, stops after 3 items
const result2 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].values()
  .filter(n => n % 2 === 0)   // lazy — computes on demand
  .map(n => n * n)             // lazy
  .take(3)                     // stops early
  .toArray();                  // [4, 16, 36]

// Works with infinite generators — never creates the full sequence in memory
function* fibonacci() {
  let [a, b] = [1, 1];
  while (true) { yield a; [a, b] = [b, a + b]; }
}

const firstFibOver1000 = fibonacci().find(n => n > 1000); // 1597

const top5EvenSquares = fibonacci()
  .filter(n => n % 2 === 0)   // even Fibonacci numbers
  .map(n => n * n)             // square them
  .take(5)                     // only first 5
  .toArray();                  // [4, 16, 196, 1444, 9604]

// Iterator.from() wraps any iterable/iterator with helper methods
const mapIter = Iterator.from(new Map([['a', 1], ['b', 2], ['c', 3]]));
const keys = mapIter.map(([k]) => k).toArray(); // ['a', 'b', 'c']
```

**Pitfall — shared data source:** iterator helpers share the underlying iterator. Consuming the original also advances the helper.
```javascript
const base = [1, 2, 3].values();
const doubled = base.map(n => n * 2);

console.log(base.next().value);    // 1 — advances shared state
console.log(doubled.next().value); // 4 — sees element 2 (not 1!)
// Fix: create independent iterators from the source array each time
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

### Custom Iterables with Symbol.iterator
Any object that implements `[Symbol.iterator]()` integrates with `for...of`, spread, destructuring, and `Array.from()`. Generators are the most concise implementation.

```javascript
// Class-based iterable — paginated dataset backed by an API
class PagedCollection {
  #items;
  constructor(items) { this.#items = items; }

  // Makes the class work with for...of, spread, destructuring
  [Symbol.iterator]() {
    let index = 0;
    const items = this.#items;
    return {
      next() {
        return index < items.length
          ? { value: items[index++], done: false }
          : { done: true, value: undefined };
      },
      [Symbol.iterator]() { return this; }, // self-referential: also an iterator
    };
  }
}

const collection = new PagedCollection([10, 20, 30, 40]);
const [first, second] = collection;           // destructuring
const doubled = [...collection].map(x => x * 2); // spread
for (const item of collection) {               // for...of
  console.log(item); // 10, 20, 30, 40
}

// Generator shorthand — preferred when state is simple
class Range {
  constructor(start, end, step = 1) {
    this.start = start; this.end = end; this.step = step;
  }
  *[Symbol.iterator]() {
    for (let i = this.start; i < this.end; i += this.step) yield i;
  }
}
console.log([...new Range(0, 10, 2)]); // [0, 2, 4, 6, 8]
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

### Map and Set for Typed Collections

`Map` and `Set` are purpose-built collection types. Use them instead of plain objects/arrays when the semantics fit — they are faster for membership checks, cannot have accidental prototype properties, and iterate in guaranteed insertion order.

```javascript
// Set — O(1) membership check, deduplication
const seen = new Set();
function processOnce(items) {
  return items.filter(item => {
    if (seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });
}

// Array deduplication
const unique = [...new Set([1, 2, 2, 3, 3, 3])]; // [1, 2, 3]

// Map — any key type, insertion-order iteration, O(1) get/set/has/delete
const cache = new Map();
cache.set('key', { data: 'value', ttl: Date.now() + 60_000 });
cache.get('key');        // { data: 'value', ttl: ... }
cache.has('key');        // true
cache.size;              // 1

// Map with object keys (impossible with plain objects)
const roleMap = new Map();
const adminRole = { name: 'admin' };
roleMap.set(adminRole, ['read', 'write', 'delete']);
roleMap.get(adminRole); // ['read', 'write', 'delete']

// DON'T use bracket notation on Map — it bypasses Map methods
// map['key'] = 'val';    // ❌ sets JS property, not Map entry
// map.set('key', 'val'); // ✅ correct

// Map.groupBy / Object.groupBy (ES2024)
const people = [
  { name: 'Alice', dept: 'eng' },
  { name: 'Bob',   dept: 'design' },
  { name: 'Carol', dept: 'eng' },
];
const byDept = Map.groupBy(people, p => p.dept);
// Map { 'eng' => [Alice, Carol], 'design' => [Bob] }
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

**9. CJS `require()` Can't Load ESM Synchronously** [community] — Trying to `require()` a `.mjs` file or a package with `"type": "module"` throws `ERR_REQUIRE_ESM`. WHY it causes problems: the error only surfaces at runtime, not at build time, and can surprise teams mid-migration. Entire dependency chains must be audited when introducing a pure-ESM package (like `node-fetch@3`, `chalk@5`). Fix: use dynamic `await import()` as the workaround, or stay on CJS-compatible versions until full ESM migration.

```javascript
// BAD — throws ERR_REQUIRE_ESM at runtime
const fetch = require('node-fetch'); // node-fetch@3 is ESM-only

// GOOD — dynamic import in an async context
const { default: fetch } = await import('node-fetch');

// BETTER — migrate the whole file to ESM
// package.json: "type": "module"
import fetch from 'node-fetch';
```

**10. Event Listener Memory Leaks** [community] — Adding event listeners without removing them is one of the most common memory leak sources in long-lived browser apps and Node.js servers. WHY it causes problems: each listener holds a closure reference to its surrounding scope; if the target element or emitter stays alive (e.g., `document`, a global singleton), the entire closure chain is never collected, gradually consuming memory. Fix: always pair `addEventListener` with `removeEventListener`, use `{ once: true }` for single-fire listeners, and `AbortSignal` for bulk cleanup.

```javascript
// BAD — listener accumulates every time the function is called
function setup() {
  document.addEventListener('click', handleClick); // never removed
}

// GOOD — { once: true } for single-fire listeners
document.addEventListener('click', handleClick, { once: true });

// GOOD — AbortSignal for coordinated cleanup of multiple listeners
function attachListeners(element) {
  const controller = new AbortController();
  const { signal } = controller;
  element.addEventListener('mouseenter', onEnter, { signal });
  element.addEventListener('mouseleave', onLeave, { signal });
  element.addEventListener('click',      onClick,  { signal });
  // Remove ALL listeners at once:
  return () => controller.abort();
}

const cleanup = attachListeners(myButton);
// Later: cleanup(); — removes all three listeners simultaneously
```

**11. `using` with Null/Non-Disposable Values** [community] — Assigning a non-disposable object (one without `[Symbol.dispose]`) to a `using` binding throws a `TypeError` at the point of disposal, not at assignment. WHY it causes problems: the error is deferred and unexpected — you write `using conn = maybeGetConnection()` thinking it's safe, but if `maybeGetConnection()` returns a plain object, the block exits with a confusing TypeError. Fix: only use `using` with objects that implement `[Symbol.dispose]`, or explicitly check `using conn = result ?? null` (null is allowed and is a no-op).

**12. Iterator Helpers Share the Underlying Iterator** [community] — Two helper chains created from the same base iterator share state; consuming one advances the other. WHY it causes problems: code that looks like two independent streams silently reads from the same source, producing interleaved or missing data. Fix: call `.values()` (or equivalent) on the source collection independently for each chain.

**13. `Array.fromAsync` is Sequential, Not Concurrent** [community] — Developers reaching for `Array.fromAsync` to collect a set of Promises expect concurrent execution (like `Promise.all`), but `Array.fromAsync` awaits each element in sequence. WHY it causes problems: what would take 100 ms with `Promise.all` takes 500 ms with `Array.fromAsync` on 5 items, silently multiplying latency. Fix: use `Promise.all` for a fixed set of concurrent Promises; use `Array.fromAsync` only for sequential async iterables where order of production matters.



| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Floating Promise | Errors silently discarded; operation status unknown | Always `await` or `.catch()` |
| Sequential `await` on independent ops | Multiplies latency; serialises parallelisable work | Use `Promise.all` |
| `var` in loops with closures | All closures share one binding; captures final loop value | Use `const`/`let` |
| Throwing strings (`throw 'error'`) | No stack trace; `instanceof` checks fail | Extend `Error` class |
| Ignoring `catch` with empty block | Swallows exceptions silently | Log or re-throw; never `catch(e) {}` |
| Defining methods in constructor | Each instance gets its own function copy; wastes memory | Define methods on `prototype` / use `class` syntax |
| Mixing ESM and CJS imports | Interop edge-cases; `require()` cannot load ESM synchronously; dual-package hazard with shared state | Standardise on ESM; set `"type": "module"` in package.json; use `createRequire()` for legacy |
| `console.log` in production | Unstructured, unsearchable output; leaks sensitive data | Use a structured logger (Pino / Winston) |
| Modifying function parameters directly | Surprise side-effects for callers; referential equality breaks | Return new values; copy with `structuredClone` or spread |
| Using `==` instead of `===` | Implicit type coercion produces surprising truthy/falsy results | Always use `===` and `!==` |
| Missing `return` in `.then()` handler | Breaks promise chain; subsequent handlers receive `undefined` | Always `return` the next promise from `.then()` |
| Catching and re-throwing without `cause` | Original stack trace is lost; root cause debugging is hard | Use `throw new Error('context', { cause: err })` |
| `using` with non-disposable object | Deferred `TypeError` at block exit, not assignment — unexpected and hard to locate | Only bind disposable objects (or `null`) to `using` |
| Sharing base iterator across helper chains | Two helpers from the same base interleave consumption silently | Call `.values()` independently for each chain |
| `Array.fromAsync` for concurrent Promises | Awaits each element sequentially; 5× slower than `Promise.all` for 5 items | Use `Promise.all([...])` for concurrent; `Array.fromAsync` for sequential async streams |
