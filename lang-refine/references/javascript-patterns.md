# JavaScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 39 | score: 100/100 | date: 2026-05-03 -->

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

### Module Aggregation and Import Maps

**Module aggregation** (barrel files) centralises re-exports, allowing consumers to import from one path instead of many deep paths. **Import maps** (browser) let you use bare specifiers without a bundler.

```javascript
// ── Barrel file / module aggregation ────────────────────────────────
// src/shapes/index.js — re-exports everything from child modules
export { Square }   from './square.js';
export { Circle }   from './circle.js';
export { Triangle } from './triangle.js';

// Consumer imports from one place — no deep paths leaking into calling code
import { Square, Circle } from './shapes/index.js';

// ── Import Maps (browser, ES2024+) ───────────────────────────────────
// In HTML — maps bare specifiers to real URLs (no bundler needed in dev)
// <script type="importmap">
// {
//   "imports": {
//     "lodash":  "/node_modules/lodash-es/lodash.js",
//     "lodash/": "/node_modules/lodash-es/"
//   }
// }
// </script>

import { debounce } from 'lodash';           // resolves via import map
import { cloneDeep } from 'lodash/cloneDeep.js';

// ── Import Attributes (ES2025) — explicitly type non-JS imports ─────
import config from './config.json' with { type: 'json' };
import styles from './styles.css'  with { type: 'css' };  // Safari/Chrome

// ── Cyclic dependency safeguard ────────────────────────────────────
// Cyclic imports (a imports b, b imports a) work in ESM but the imported
// binding is undefined on the first pass. Avoid shared mutable state
// across a cycle; prefer dependency injection to break the cycle.
```

**Barrel file pitfall:** large barrel files that re-export everything prevent tree-shaking because bundlers may not be able to determine which exports are used statically. Keep barrel files for public APIs; don't create them for every internal directory.

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

// Error.isError() — robust error detection across realms (ES2027, polyfill available)
// Unlike `instanceof Error`, works across iframe boundaries and rejects prototype-faked objects
Error.isError(new Error());    // true
Error.isError(new TypeError()); // true
Error.isError({ __proto__: Error.prototype }); // false — prototype spoofing rejected
// Cross-realm: error from iframe
const xError = new iframeWindow.Error();
Error.isError(xError);         // true  — instanceof Error would return false!

// Normalize caught values (libraries may throw strings)
function toError(e) {
  return Error.isError(e) ? e : new Error(String(e));
}
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

// Array.findLast / findLastIndex (ES2023) — search from end
const nums = [1, 2, 3, 4, 5];
const lastEven      = nums.findLast(n => n % 2 === 0);      // 4
const lastEvenIndex = nums.findLastIndex(n => n % 2 === 0); // 3
// Compare: arr.findIndex() + arr.lastIndexOf() don't accept predicates

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


### Structured Error Handling with Custom Error Classes

Throwing strings or generic `Error` loses type information and makes catch blocks unable to distinguish error types. Extend `Error` for structured error handling. Use `cause` (ES2022) to preserve error chain context without losing stack traces.

A key production distinction [community]: **operational errors** are expected scenarios (user not found, validation failure, rate-limit exceeded) that can be handled gracefully. **Programmer errors** are unexpected bugs (null dereference, logic flaw) that should restart the process — handling them risks the app running in a corrupted state. Flag this distinction explicitly in your error hierarchy.

```javascript
// Custom error hierarchy with operational vs programmer error distinction
class AppError extends Error {
  constructor(message, options = {}) {
    super(message, options); // Forwards { cause } to built-in Error
    this.name = this.constructor.name;
    // isOperational: true = expected; false = bug → restart the process
    this.isOperational = options.isOperational ?? true;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} with id=${id} not found`, { isOperational: true });
    this.resource = resource;
    this.id = id;
  }
}

class ValidationError extends AppError {
  constructor(field, message) {
    super(`Validation failed on '${field}': ${message}`, { isOperational: true });
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

// Global last-resort handler — only safe to recover from operational errors
process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'uncaughtException');
  if (!err.isOperational) {
    // Programmer error: state may be corrupted — shut down and let process manager restart
    process.exit(1);
  }
  // Operational error: log and continue (optional — many teams always exit for simplicity)
});

process.on('unhandledRejection', (reason) => {
  // Treat all unhandled rejections as programmer errors — throw to trigger uncaughtException
  throw reason;
});
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

### Web Workers and worker_threads — CPU-Bound Off-Thread Work
The event loop is single-threaded. CPU-intensive work (image processing, encryption, parsing large files) blocks it for all concurrent requests. Move that work to Web Workers (browser) or `worker_threads` (Node.js).

```javascript
// ── Browser: Web Worker ──────────────────────────────────────────────
// main.js — spawn worker, transfer data without copy
const worker = new Worker(new URL('./fib.worker.js', import.meta.url));
const bigBuffer = new Uint8Array(1024 * 1024 * 32);

// Transferable: ownership moves to worker — zero-copy, bigBuffer unusable here after
worker.postMessage(bigBuffer.buffer, [bigBuffer.buffer]);

worker.addEventListener('message', ({ data }) => {
  console.log('Result from worker:', data.result);
  worker.terminate();
});

// fib.worker.js — runs on a background thread (no DOM access)
self.onmessage = ({ data }) => {
  const view = new Uint8Array(data);
  // ... heavy computation with view ...
  self.postMessage({ result: view.byteLength });
};

// ── Node.js: worker_threads ───────────────────────────────────────────
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

if (isMainThread) {
  const worker = new Worker(import.meta.filename, {
    workerData: { input: [1, 2, 3, 4, 5] },
  });
  worker.once('message', result => console.log('Sum:', result));
  worker.once('error', err  => console.error(err));
} else {
  // Worker thread code — same file, different branch
  const sum = workerData.input.reduce((a, b) => a + b, 0);
  parentPort.postMessage(sum);
}
```

**Key rules:**
- Workers have **no DOM access** (browser) and **no shared event loop** (Node).
- Pass data by **structured clone** (copy) or **transfer** (zero-copy, source becomes detached).
- Use `SharedArrayBuffer` + `Atomics` for true shared memory, but only when you need synchronisation primitives — complexity is high.
- Always call `worker.terminate()` or the worker exits when `postMessage` closes.

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

## GoF Design Patterns in JavaScript

The classic Gang of Four patterns adapt naturally to JavaScript's first-class functions and prototype system. These are the four most common in production JS codebases.

### Observer Pattern (EventTarget)
Extend `EventTarget` to get a standards-compliant event bus. All browser APIs and many Node.js APIs implement this pattern — prefer it over ad-hoc callback registries.

```javascript
class DataStore extends EventTarget {
  #data = null;

  set data(value) {
    this.#data = value;
    this.dispatchEvent(new CustomEvent('change', { detail: { data: value } }));
  }

  get data() { return this.#data; }
}

const store = new DataStore();
store.addEventListener('change', ({ detail }) => {
  console.log('Updated:', detail.data);
});
store.data = { userId: 1, name: 'Alice' }; // Triggers observer
```

### Strategy Pattern
Functions are first-class in JavaScript — the Strategy pattern is naturally expressed as a map of functions. No abstract base class needed.

```javascript
const serializers = {
  json: data => JSON.stringify(data),
  csv:  data => Object.values(data).join(','),
  tsv:  data => Object.values(data).join('\t'),
};

class DataExporter {
  #format;
  constructor(format = 'json') { this.#format = format; }
  setFormat(format) {
    if (!serializers[format]) throw new Error(`Unknown format: ${format}`);
    this.#format = format;
  }
  export(data) { return serializers[this.#format](data); }
}

const exporter = new DataExporter('json');
exporter.export({ name: 'Alice', age: 30 }); // '{"name":"Alice","age":30}'
exporter.setFormat('csv');
exporter.export({ name: 'Alice', age: 30 }); // 'Alice,30'
```

### Factory Pattern
Centralise object construction to decouple consumers from concrete implementations. In JS, static methods or plain functions work equally well.

```javascript
class Logger {
  log(msg) { throw new Error('Not implemented'); }
}

class ConsoleLogger extends Logger {
  log(msg) { console.log(`[CONSOLE] ${msg}`); }
}

class RemoteLogger extends Logger {
  constructor(url) { super(); this.url = url; }
  log(msg) { fetch(this.url, { method: 'POST', body: JSON.stringify({ msg }) }); }
}

// Factory — consumers never call `new` directly
function createLogger(type, options = {}) {
  switch (type) {
    case 'console': return new ConsoleLogger();
    case 'remote':  return new RemoteLogger(options.url);
    default:        throw new Error(`Unknown logger type: ${type}`);
  }
}

const logger = createLogger('console');
logger.log('App started');
```

### Singleton Pattern
Module-level constants are the simplest Singleton in ESM: modules are executed once and cached. The explicit `#instance` class pattern is useful when lazy initialization is required.

```javascript
// ESM singleton — simplest form (preferred in modern JS)
// db.js
const pool = createConnectionPool({ max: 10 }); // runs once per process
export { pool }; // same pool object wherever db.js is imported

// Class-based singleton with lazy init (use when init is expensive/async)
class ConfigManager {
  static #instance = null;
  #config = {};

  static getInstance() {
    if (!ConfigManager.#instance) {
      ConfigManager.#instance = new ConfigManager();
    }
    return ConfigManager.#instance;
  }

  load(data) { this.#config = { ...this.#config, ...data }; }
  get(key)   { return this.#config[key]; }
}

const c1 = ConfigManager.getInstance();
const c2 = ConfigManager.getInstance();
console.log(c1 === c2); // true
```

---

## Dependency Injection and Testability

JavaScript's closures and first-class functions make dependency injection natural — no framework required.

### Factory Functions for Injectable Services
Prefer factory functions over imported singletons for any code that you need to test or run in multiple configurations. The factory receives dependencies; the consumer never hard-codes `import` calls to concrete implementations.

```javascript
// HARD TO TEST — module-level singleton; impossible to swap logger in tests
import logger from './logger.js';
export function createUser(name) {
  logger.info(`Creating user: ${name}`);
  return { name };
}

// TESTABLE — factory receives dependencies as parameters
export function createUserService({ logger, db, cache }) {
  return {
    async create(name) {
      logger.info(`Creating user: ${name}`);
      const user = await db.insert({ name });
      cache.set(user.id, user);
      return user;
    },
    async findById(id) {
      return cache.get(id) ?? await db.findById(id);
    },
  };
}

// Production wiring
const userService = createUserService({ logger, db, cache });

// Test wiring — all dependencies are stubs
const testDeps = {
  logger: { info: vi.fn() },
  db:     { insert: vi.fn().mockResolvedValue({ id: 1, name: 'Alice' }),
             findById: vi.fn() },
  cache:  { get: vi.fn().mockReturnValue(null), set: vi.fn() },
};
const svc = createUserService(testDeps);
```

### Inversion of Control via Callback Injection
When you need to inject behaviour (not just data), pass functions as parameters. This eliminates branching and coupling to specific side-effect implementations.

```javascript
// HARD TO TEST — side effects hard-coded
async function placeOrder(order) {
  await db.save(order);
  await sendEmail(order.userEmail, 'Order confirmed');
  await auditLog.write({ type: 'ORDER_PLACED', order });
}

// TESTABLE — inject all side-effecting actions
async function placeOrder(order, { persist, notify, audit }) {
  await persist(order);
  await notify(order.userEmail, 'Order confirmed');
  await audit({ type: 'ORDER_PLACED', order });
}

// Test: all effects are captured, none actually fire
const effects = { calls: [] };
const spyFn = label => async (...args) => effects.calls.push({ label, args });

await placeOrder(order, {
  persist: spyFn('persist'),
  notify:  spyFn('notify'),
  audit:   spyFn('audit'),
});
expect(effects.calls).toHaveLength(3);
expect(effects.calls[0].label).toBe('persist');
```

---

## Functional Patterns in JavaScript

JavaScript's first-class functions make functional patterns idiomatic without libraries. These are practical, production-proven patterns.

### Pipe and Compose
`pipe` chains functions left-to-right (data flows in reading order). `compose` chains right-to-left. Both are zero-dependency utility functions that enable declarative data transformation.

```javascript
// pipe: left-to-right (most readable for data transformation pipelines)
const pipe = (...fns) => x => fns.reduce((v, f) => f(v), x);

// compose: right-to-left (mathematical function composition)
const compose = (...fns) => x => fns.reduceRight((v, f) => f(v), x);

// Example: normalise a user-submitted tag
const normaliseTag = pipe(
  s => s.trim(),
  s => s.toLowerCase(),
  s => s.replace(/\s+/g, '-'),
  s => s.replace(/[^a-z0-9-]/g, ''),
);

normaliseTag('  Hello World! '); // 'hello-world'

// async pipe — handles async stages cleanly
const pipeAsync = (...fns) => x => fns.reduce((p, f) => p.then(f), Promise.resolve(x));

const processOrder = pipeAsync(
  validateOrder,
  applyDiscount,
  chargePayment,
  sendConfirmation,
);
await processOrder(orderData);
```

### Maybe Pattern (Null-Safety without Guards)
Wrap potentially-null values in a `Maybe` container. All operations short-circuit on `null`/`undefined` without scattered guard clauses.

```javascript
class Maybe {
  #value;
  constructor(value) { this.#value = value; }

  static of(value) { return new Maybe(value); }
  isNothing()       { return this.#value == null; }

  map(fn)    { return this.isNothing() ? this  : Maybe.of(fn(this.#value)); }
  flatMap(fn){ return this.isNothing() ? this  : fn(this.#value); }
  filter(fn) { return this.isNothing() || fn(this.#value) ? this : Maybe.of(null); }
  getOrElse(def) { return this.isNothing() ? def : this.#value; }
}

// Compare:
// Guard-clause style
const city = user && user.address && user.address.city
  ? user.address.city.toLowerCase()
  : 'unknown';

// Maybe style — chain of transforms, single fallback
const city2 = Maybe.of(user)
  .map(u  => u.address)
  .map(a  => a.city)
  .map(c  => c.toLowerCase())
  .getOrElse('unknown');
```

### Either Pattern (Typed Error Handling)
`Either` models a computation that may fail. `Right` holds success; `Left` holds an error. Unlike try-catch, the error is a value — it can be mapped, logged, or forwarded without side effects.

```javascript
class Either {
  #value; #isRight;
  constructor(value, isRight) { this.#value = value; this.#isRight = isRight; }

  static right(v) { return new Either(v, true);  }
  static left(e)  { return new Either(e, false); }

  map(fn)       { return this.#isRight ? Either.right(fn(this.#value)) : this; }
  flatMap(fn)   { return this.#isRight ? fn(this.#value) : this; }
  fold(lFn, rFn){ return this.#isRight ? rFn(this.#value) : lFn(this.#value); }
}

const safeParseJSON = str => {
  try { return Either.right(JSON.parse(str)); }
  catch (e) { return Either.left(e.message); }
};

safeParseJSON('{"name":"Alice"}')
  .map(obj => obj.name.toUpperCase())
  .fold(
    err  => console.error('Parse error:', err),
    name => console.log('User:', name),  // 'ALICE'
  );
```

### Currying and Partial Application
Currying transforms a multi-argument function into a chain of single-argument functions, enabling reusable specialisations without wrapper functions.

```javascript
// Generic curry — works with any arity
const curry = fn => {
  const arity = fn.length;
  return function curried(...args) {
    return args.length >= arity ? fn(...args) : (...more) => curried(...args, ...more);
  };
};

const add = (a, b, c) => a + b + c;
const curriedAdd = curry(add);
const add5  = curriedAdd(5);
const add5to3 = curriedAdd(5)(3);
curriedAdd(1)(2)(3); // 6
curriedAdd(1, 2)(3); // 6

// Partial application — fix early arguments, leave the rest open
const partial = (fn, ...fixed) => (...rest) => fn(...fixed, ...rest);

const log = (level, message, data) => console.log({ level, message, data });
const logError = partial(log, 'ERROR');
const logWarn  = partial(log, 'WARN');

logError('DB connection failed', { host: 'db1' }); // level: ERROR
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

### Set Methods — Set Algebra (ES2025 / Baseline 2024)

`Set` now ships with algebraic operations: `union`, `intersection`, `difference`, `symmetricDifference`, `isSubsetOf`, `isSupersetOf`, and `isDisjointFrom`. All methods accept any _set-like_ object (anything with a `size`, `has()`, and `keys()`) and return a new `Set` without mutating either operand.

```javascript
const frontend = new Set(['Alice', 'Bob', 'Carol']);
const backend  = new Set(['Bob', 'David', 'Eve']);

// union — all members of either group
frontend.union(backend);
// Set { 'Alice', 'Bob', 'Carol', 'David', 'Eve' }

// intersection — members in both groups
frontend.intersection(backend);
// Set { 'Bob' }

// difference — in frontend but NOT in backend
frontend.difference(backend);
// Set { 'Alice', 'Carol' }

// symmetricDifference — in either group but not both
frontend.symmetricDifference(backend);
// Set { 'Alice', 'Carol', 'David', 'Eve' }

// Subset / superset checks
const core = new Set(['Alice', 'Bob']);
core.isSubsetOf(frontend);    // true — core ⊆ frontend
frontend.isSupersetOf(core);  // true — frontend ⊇ core
frontend.isDisjointFrom(new Set(['Zoe'])); // true — no overlap

// Works with any set-like object — e.g., a Map's keys
const roleMap = new Map([['Alice', 'admin'], ['Bob', 'viewer']]);
frontend.intersection(roleMap); // Set { 'Alice', 'Bob' }
```

**Why it matters:** before ES2025 you had to write these manually with `filter` + `has` calls; now they are O(min(|A|,|B|)) built-ins, and the intent is self-documenting.

### `Promise.try()` — Uniform Sync/Async Wrapping (ES2025)

`Promise.try(fn)` calls `fn` synchronously and wraps the return value (or thrown error) in a Promise. It closes the longstanding gap where mixing sync-throwing and async-rejecting code required manual `try/new Promise` scaffolding.

```javascript
// Without Promise.try — awkward wrapping needed
function callbackToPromise(maybeAsync) {
  return new Promise((resolve) => resolve(maybeAsync()))
    .catch(handleError);
}

// With Promise.try — concise, handles sync throws + async rejects uniformly
function callbackToPromise(maybeAsync) {
  return Promise.try(maybeAsync).catch(handleError);
}

// Practical: wrapping a route handler that might be sync or async
function wrapHandler(fn) {
  return (req, res, next) => Promise.try(fn, req, res).catch(next);
}

// All four behaviours handled identically:
Promise.try(() => 'sync value').then(console.log);         // 'sync value'
Promise.try(() => { throw new Error('sync throw'); }).catch(console.error);
Promise.try(async () => 'async value').then(console.log);  // 'async value'
Promise.try(async () => { throw new Error('async'); }).catch(console.error);
```

**Key distinction from `Promise.resolve().then(fn)`:** `Promise.try` calls `fn` _synchronously_ in the current microtask; `Promise.resolve().then(fn)` schedules it as a microtask. This matters when `fn` has side effects that must happen before the next tick.

### `RegExp.escape()` — Safe Dynamic Patterns (ES2025 / Baseline May 2025)

`RegExp.escape(str)` returns a copy of `str` with all regex-special characters escaped, making user-supplied strings safe to embed into dynamic `RegExp` patterns without injection risk.

```javascript
// BAD — user input treated as regex syntax (injection risk)
function highlight(text, searchTerm) {
  return text.replace(new RegExp(searchTerm, 'gi'), '<mark>$&</mark>');
}
// highlight('foo.bar', '.') — '.' matches ANY char, not just literal dot

// GOOD — RegExp.escape prevents special chars from acting as operators
function highlight(text, searchTerm) {
  return text.replace(
    new RegExp(RegExp.escape(searchTerm), 'gi'),
    '<mark>$&</mark>',
  );
}
highlight('foo.bar baz', '.');  // marks only the actual dots

// Practical: safe URL domain matching
function stripDomain(text, domain) {
  const escaped = RegExp.escape(domain); // e.g. 'example.com' → 'example\\.com'
  return text.replace(new RegExp(`https?://${escaped}`, 'g'), '');
}
stripDomain('Visit https://my.site.io/page', 'my.site.io');
// → 'Visit /page'
```

---

## Internationalisation (Intl) Patterns

The `Intl` namespace provides locale-aware formatting with zero external dependencies. Always prefer `Intl` over manual string concatenation for dates, numbers, lists, and relative time — manual approaches miss locale nuance and are a maintenance burden.

```javascript
// ── Intl.NumberFormat — currency, compact notation, unit formatting ──
const usd = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
usd.format(1234567.89);  // "$1,234,567.89"

// Compact notation — display large numbers concisely
const compact = new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 });
compact.format(1_500_000); // "1.5M"
compact.format(25_000);    // "25K"

// formatToParts — extract components for custom rendering
const parts = new Intl.NumberFormat('en-US', {
  style: 'currency', currency: 'EUR',
}).formatToParts(1234.56);
// [ {type:'currency',value:'€'}, {type:'integer',value:'1,234'}, ... ]

// ── Intl.DateTimeFormat ───────────────────────────────────────────────
const dtf = new Intl.DateTimeFormat('en-GB', {
  dateStyle: 'full', timeStyle: 'short',
});
dtf.format(new Date()); // "Saturday, 2 May 2026 at 10:30"

// formatRange — date range in one call
const fmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' });
fmt.formatRange(new Date('2026-05-01'), new Date('2026-05-07')); // "May 1–7"

// ── Intl.RelativeTimeFormat — human-friendly "time ago" ──────────────
const rtf = new Intl.RelativeTimeFormat('en-US', { numeric: 'auto' });
rtf.format(-1, 'day');   // "yesterday"
rtf.format(-3, 'month'); // "3 months ago"
rtf.format(2, 'week');   // "in 2 weeks"

function timeAgo(date) {
  const seconds = Math.round((date - Date.now()) / 1000);
  const thresholds = [
    [60,     'second'],
    [3600,   'minute'],
    [86400,  'hour'],
    [604800, 'day'],
    [2592000,'week'],
    [Infinity,'month'],
  ];
  for (const [limit, unit] of thresholds) {
    const divisor = unit === 'second' ? 1 : thresholds.find(([l]) => l === limit)?.[0] / 60 || 1;
    if (Math.abs(seconds) < limit) {
      return rtf.format(Math.round(seconds / (limit / thresholds.length)), unit);
    }
  }
}

// ── Intl.ListFormat — grammatical list joining ────────────────────────
const list = new Intl.ListFormat('en-US', { style: 'long', type: 'conjunction' });
list.format(['Alice', 'Bob', 'Carol']); // "Alice, Bob, and Carol"

const disjunction = new Intl.ListFormat('en-US', { type: 'disjunction' });
disjunction.format(['cash', 'card', 'crypto']); // "cash, card, or crypto"

// ── Intl.Segmenter — locale-aware text segmentation ──────────────────
// Correctly counts visual characters in multilingual text (handles emoji, CJK)
const seg = new Intl.Segmenter('en', { granularity: 'grapheme' });
const graphemes = [...seg.segment('🏳️‍🌈')].length; // 1 (not 6 code points)

// Word segmentation — more accurate than splitting on \s
const wordSeg = new Intl.Segmenter('ja', { granularity: 'word' }); // Japanese has no spaces
const words = [...wordSeg.segment('日本語テキスト')]
  .filter(s => s.isWordLike)
  .map(s => s.segment);

// ── Intl.PluralRules — language-aware pluralisation ──────────────────
const pr = new Intl.PluralRules('en-US');
const messages = { one: '1 item', other: '%d items' };
function itemCount(n) {
  return messages[pr.select(n)].replace('%d', n);
}
itemCount(1); // "1 item"
itemCount(5); // "5 items"
// Russian: pr.select(2) → 'few', pr.select(5) → 'many' — handled automatically
```

**Rule of thumb:** build-time i18n libraries (i18next, formatjs) manage translation strings; `Intl` handles the _format_ of dates, numbers, and lists within those strings. They complement each other.

---

## Security Patterns

### XSS Prevention — textContent over innerHTML
Never insert user-controlled data as HTML. Use `textContent` for plain text. Use a sanitization library (DOMPurify) when HTML rendering is unavoidable.

```javascript
// BAD — arbitrary HTML injection; executes attacker scripts
document.getElementById('output').innerHTML = userInput;

// GOOD — text is never parsed as HTML
document.getElementById('output').textContent = userInput;

// GOOD — when HTML is genuinely needed, sanitize first
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput, { ALLOWED_TAGS: ['b', 'i', 'em'] });
document.getElementById('output').innerHTML = clean;
```

### Prototype Pollution Prevention
Avoid recursive merge of untrusted objects. If a user-controlled payload contains `__proto__`, `constructor`, or `prototype` keys, a naive merge poisons every subsequent object creation.

```javascript
// BAD — merging untrusted JSON directly onto an object
function merge(target, source) {
  for (const key in source) target[key] = source[key]; // allows __proto__ injection
}

// GOOD — block dangerous keys and use hasOwnProperty
function safeMerge(target, source) {
  for (const key in source) {
    if (!Object.prototype.hasOwnProperty.call(source, key)) continue;
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue;
    target[key] = source[key];
  }
  return target;
}

// BEST — use Map for untrusted key-value data (not subject to prototype pollution)
const safe = new Map(Object.entries(untrustedData));

// ALSO GOOD — Object.create(null) has no prototype at all
const bare = Object.assign(Object.create(null), trustedDefaults);
```

### eval / Function Constructor Avoidance
`eval()`, `new Function(code)`, `setTimeout(string, ...)`, and `setInterval(string, ...)` execute arbitrary strings as code. They bypass CSP, are impossible to statically analyse, and open RCE vectors in Node.js.

```javascript
// BAD — eval is essentially an injection sink
const result = eval(userExpression);

// BAD — equivalent to eval; bypasses CSP 'unsafe-eval' in browsers
const fn = new Function('x', userCode);

// GOOD — use a sandboxed interpreter for user expressions, or whitelist operations
const ALLOWED_OPS = { add: (a, b) => a + b, mul: (a, b) => a * b };
function safeEval(op, a, b) {
  const fn = ALLOWED_OPS[op];
  if (!fn) throw new Error(`Disallowed operation: ${op}`);
  return fn(a, b);
}
```

### Content Security Policy (CSP) + Trusted Types

CSP limits which scripts, styles, and resources a page can load. **Trusted Types** (Chrome 83+, Firefox 130+) enforce that only policy-processed values reach dangerous DOM sinks (`innerHTML`, `eval`, etc.), eliminating a whole class of DOM XSS at the platform level.

```javascript
// Server-side: nonce-based strict CSP (better than allowlists)
// Express middleware
import { randomUUID } from 'crypto';

app.use((req, res, next) => {
  res.locals.nonce = randomUUID();
  res.setHeader(
    'Content-Security-Policy',
    // script-src: only scripts with the matching nonce are executed
    // require-trusted-types-for: enforcement for DOM injection sinks
    `script-src 'nonce-${res.locals.nonce}'; ` +
    `object-src 'none'; base-uri 'none'; ` +
    `require-trusted-types-for 'script'; ` +
    `trusted-types myPolicy empty`,
  );
  next();
});

// HTML template: render nonce into every script tag
// <script nonce="<%= nonce %>">...</script>

// Browser: Trusted Types policy — sanitize before any DOM injection
const domPolicy = trustedTypes.createPolicy('myPolicy', {
  createHTML(input) {
    // Only allow through DOMPurify-sanitized HTML
    return DOMPurify.sanitize(input, { RETURN_TRUSTED_TYPE: true });
  },
  createScript(input) {
    throw new Error('Inline scripts not allowed via Trusted Types');
  },
  createScriptURL(input) {
    const allowed = ['https://cdn.example.com'];
    const url = new URL(input);
    if (!allowed.includes(url.origin)) throw new Error(`Blocked script URL: ${input}`);
    return input;
  },
});

// Safe DOM injection: Trusted Types enforces policy is called
element.innerHTML = domPolicy.createHTML(userContent); // ✅ sanitized
element.innerHTML = userContent;                        // ❌ throws TypeError under Trusted Types CSP
```

**Why this matters:** Trusted Types + strict CSP provides defense-in-depth that survives library upgrades introducing new injection sinks. When a dependency silently adds `innerHTML` calls, your CSP catches it in CI before production.

---

## Testing Patterns

### Async Test Patterns (Jest / Vitest / Node Test Runner)
Always `return` or `await` promises in tests. Without it, tests complete before the assertion runs, giving false passes.

```javascript
import { describe, it, expect, vi, beforeEach } from 'vitest';

// GOOD — await the async function under test
it('returns user profile', async () => {
  const profile = await fetchUserProfile(42);
  expect(profile).toMatchObject({ id: 42 });
});

// GOOD — .resolves / .rejects matchers (cleaner for simple cases)
it('rejects on missing user', async () => {
  await expect(fetchUserProfile(999)).rejects.toThrow('Not Found');
});

// GOOD — mock fetch with vi.fn() to control HTTP in tests
it('calls /api/users/:id', async () => {
  const mockFetch = vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({ id: 1, name: 'Alice' }),
  });
  vi.stubGlobal('fetch', mockFetch);

  await fetchUserProfile(1);

  expect(mockFetch).toHaveBeenCalledWith('/api/users/1');
  vi.unstubAllGlobals();
});

// GOOD — fake timers to test debounce / throttle without real waits
it('debounced search fires after 300ms quiet period', async () => {
  vi.useFakeTimers();
  const handler = vi.fn();
  const debounced = debounce(handler, 300);

  debounced('a');
  debounced('ab');
  debounced('abc');         // fires once after quiet period
  expect(handler).not.toHaveBeenCalled();

  vi.advanceTimersByTime(300);
  expect(handler).toHaveBeenCalledOnce();
  expect(handler).toHaveBeenCalledWith('abc');
  vi.useRealTimers();
});
```

### Test Isolation — No Shared Mutable State
Tests that share global state or DB seeds become order-dependent. One failing test corrupts state for all subsequent tests.

```javascript
// BAD — shared counter bleeds between tests
let counter = 0;
it('increments', () => { counter++; expect(counter).toBe(1); });
it('increments again', () => { counter++; expect(counter).toBe(2); }); // breaks if order changes

// GOOD — each test creates its own state
it('increments from 0', () => {
  const c = createCounter(0);
  c.increment();
  expect(c.value()).toBe(1);
});

// GOOD — DB tests: each test creates and cleans up its own data
beforeEach(async () => { await db.deleteWhere({ testRun: testId }); });
afterEach( async () => { await db.deleteWhere({ testRun: testId }); });
```

### Node.js Built-in Test Runner (`node:test`)

Node.js 18+ ships a full-featured test runner requiring zero external dependencies. Use it for server-side code, CLI tools, and packages that need minimal dependency footprint.

```javascript
import { describe, it, before, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';

// Basic describe/it structure with lifecycle hooks
describe('UserService', () => {
  let service;

  beforeEach(() => {
    service = createUserService({
      db: { findById: mock.fn().mockResolvedValue({ id: 1, name: 'Alice' }) },
      cache: new Map(),
    });
  });

  afterEach(() => mock.reset()); // Restore all mocks after each test

  it('returns user from DB on cache miss', async () => {
    const user = await service.findById(1);
    assert.equal(user.name, 'Alice');
  });

  it('caches user after first fetch', async () => {
    await service.findById(1);
    await service.findById(1); // second call should hit cache
    // DB was only called once — second was served from cache
    const dbCalls = service.db.findById.mock.callCount();
    assert.equal(dbCalls, 1);
  });
});

// Timer mocking — test debounce/throttle without real waits
it('debounced handler fires once after quiet period', (context) => {
  context.mock.timers.enable({ apis: ['setTimeout'] });
  const handler = context.mock.fn();
  const debounced = debounce(handler, 300);

  debounced('a'); debounced('ab'); debounced('abc');
  assert.equal(handler.mock.callCount(), 0);
  context.mock.timers.tick(300);
  assert.equal(handler.mock.callCount(), 1);
  assert.deepEqual(handler.mock.calls[0].arguments, ['abc']);
});
```

**Running tests:**
```bash
node --test                              # auto-discovers test files
node --test "**/*.test.js"               # glob pattern
node --test --experimental-test-coverage # with coverage
node --test --watch                      # watch mode
```

**Key advantage over Jest/Vitest:** zero install, always available in Node.js 18+, no config files needed for simple projects. Use Jest/Vitest when you need snapshot testing, JSX transforms, or richer ecosystem integrations.

---

## Performance Patterns

### Memory Management and Object Lifecycle
JavaScript uses mark-and-sweep garbage collection. Objects are collected when unreachable from root. Understanding this prevents subtle memory leaks in long-lived applications.

```javascript
// GOOD — WeakMap for DOM-associated data: entries collected when node is GC'd
const nodeMetadata = new WeakMap();
function annotate(domNode, data) {
  nodeMetadata.set(domNode, data); // No cleanup needed — auto-released with node
}

// GOOD — break large object references early in long functions
async function processLargeDataset() {
  let data = await loadHugeDataset();  // 200 MB
  const summary = computeSummary(data);
  data = null;  // eligible for GC immediately — don't wait for function return
  await longRunningNotify(summary);   // GC can collect data here
  return summary;
}

// GOOD — object pooling for hot paths (avoid allocations in tight loops)
class ObjectPool {
  #free = [];
  acquire()    { return this.#free.pop() ?? {}; }
  release(obj) { Object.keys(obj).forEach(k => delete obj[k]); this.#free.push(obj); }
}

const pool = new ObjectPool();
for (const item of millionItems) {
  const ctx = pool.acquire();
  ctx.id = item.id;
  processWithContext(ctx);
  pool.release(ctx);  // Reused instead of allocated each iteration
}
```

### Efficient Data Structures — TypedArrays for Numeric Data
For numeric computations, `TypedArray` views (`Float64Array`, `Int32Array`, etc.) store data in contiguous memory, enabling CPU vectorisation and avoiding V8 boxing overhead.

```javascript
// SLOW — plain array of numbers (V8 must box each value)
function dotProductSlow(a, b) {
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += a[i] * b[i];
  return sum;
}

// FAST — Float64Array (contiguous, unboxed, vectorisable by JIT)
function dotProductFast(a, b) {
  // a, b are Float64Array instances
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += a[i] * b[i];
  return sum;
}

const size = 1_000_000;
const a = new Float64Array(size).fill(1.5);
const b = new Float64Array(size).fill(2.5);
dotProductFast(a, b); // 2-10× faster than plain array on large inputs

// Shared memory between workers (no copy overhead)
const sharedBuffer = new SharedArrayBuffer(size * Float64Array.BYTES_PER_ELEMENT);
const shared = new Float64Array(sharedBuffer);

// Float16Array (ES2025 / Baseline April 2025) — half the memory of Float32Array
// Ideal for WebGPU, WebGL, and ML inference workloads (Stable Diffusion weights, etc.)
const weights = new Float16Array(1024); // 2 bytes/element vs 4 bytes for Float32
weights[0] = 0.5;
console.log(weights.BYTES_PER_ELEMENT); // 2 — half the size of Float32Array

// DataView for explicit byte-order control with Float16
const buf = new ArrayBuffer(2);
const view = new DataView(buf);
view.setFloat16(0, 3.14);
console.log(view.getFloat16(0)); // ~3.14 (float16 precision)

// Math.f16round — round to nearest float16 value (useful for quantization checks)
console.log(Math.f16round(5.5));    // 5.5
console.log(Math.f16round(5.0005)); // 5 (float16 loses precision at this scale)
```

### Debounce and Throttle for Event-Driven Performance
High-frequency events (scroll, resize, input) should not fire expensive handlers on every event. Debounce delays execution until the user stops; throttle caps the call rate.

```javascript
// Debounce — wait for 300ms of silence before firing (search inputs)
function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

// Throttle — fire at most once per interval (scroll handlers, resize)
function throttle(fn, interval) {
  let lastRun = 0;
  return (...args) => {
    const now = Date.now();
    if (now - lastRun >= interval) {
      lastRun = now;
      return fn(...args);
    }
  };
}

const onInput   = debounce(search, 300);   // fires 300ms after last keystroke
const onScroll  = throttle(updateUI, 100); // fires at most 10× per second
input.addEventListener('input', onInput);
window.addEventListener('scroll', onScroll);
```

### requestAnimationFrame for Smooth Animations

Use `requestAnimationFrame` (rAF) for all DOM animations. Unlike `setTimeout`, rAF synchronises with the browser's paint cycle, preventing jank (dropped frames) and pausing automatically in hidden tabs.

```javascript
// ❌ Bad — setTimeout doesn't sync with refresh rate; causes jank
let x = 0;
function animateBad() {
  x += 1;
  element.style.transform = `translateX(${x}px)`;
  if (x < 300) setTimeout(animateBad, 16); // ~60fps but drifts
}

// ✅ Good — rAF runs once per paint frame; exact timing, auto-paused when hidden
function animateGood(timestamp) {
  const progress = (timestamp - startTime) / duration; // 0.0 → 1.0
  const x = easeInOut(progress) * 300;
  element.style.transform = `translateX(${x}px)`;
  if (progress < 1) requestAnimationFrame(animateGood);
}
const startTime = performance.now();
requestAnimationFrame(animateGood);

// Cancel animation (e.g., on component unmount)
const rafId = requestAnimationFrame(animateGood);
cancelAnimationFrame(rafId);
```

### Performance API for Precise Measurement

Use `performance.mark` / `performance.measure` instead of `Date.now()` for high-resolution timing. `PerformanceObserver` captures entries asynchronously without blocking the thread.

```javascript
// Mark + Measure pattern — microsecond precision
performance.mark('db-query-start');
const rows = await db.query('SELECT * FROM users');
performance.mark('db-query-end');
performance.measure('db-query', 'db-query-start', 'db-query-end');

const [entry] = performance.getEntriesByName('db-query');
console.log(`Query took ${entry.duration.toFixed(2)}ms`);

// Clear to prevent memory accumulation in long-lived processes
performance.clearMarks('db-query-start');
performance.clearMarks('db-query-end');
performance.clearMeasures('db-query');

// PerformanceObserver — non-blocking, continuous measurement
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.duration > 100) {
      console.warn(`Slow operation: ${entry.name} (${entry.duration.toFixed(0)}ms)`);
    }
  }
});
observer.observe({ entryTypes: ['measure', 'longtask', 'navigation'] });
// Disconnect when no longer needed:
// observer.disconnect();
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

**14. `return promise` Without `await` Truncates Stack Traces** [community] — Returning a Promise directly from an `async` function (without `await`) removes that function from the async stack trace. WHY it causes problems: in production you lose the call site from the trace; debugging becomes significantly harder because the function that "caused" the error simply doesn't appear in the stack. Fix: always `return await promise` inside `async` functions so the function stays in the call stack — the performance difference is negligible, and the debugging benefit is enormous.

```javascript
// BAD — fetchUser disappears from stack traces on error
async function fetchUser(id) {
  return fetch(`/api/users/${id}`).then(r => r.json()); // no await
}

// GOOD — fetchUser appears in stack traces, enabling root-cause debugging
async function fetchUser(id) {
  return await fetch(`/api/users/${id}`).then(r => r.json());
}
```

**15. Environment Variables Accessed Lazily, Not Validated at Startup** [community] — Reading `process.env.DATABASE_URL` deep inside a module function means missing config isn't discovered until that code path executes. WHY it causes problems: the app starts successfully but fails minutes (or hours) later when the first request hits the unconfigured path, leaving the system in a partially-started state. Fix: validate all required environment variables at startup (before the server starts accepting requests), and fail fast with a clear error if any are missing.

```javascript
// BAD — validation deferred until first use
async function saveUser(user) {
  const db = await connect(process.env.DATABASE_URL); // crashes later
  return db.save(user);
}

// GOOD — fail fast at startup before accepting any traffic
const REQUIRED_ENV = ['DATABASE_URL', 'JWT_SECRET', 'PORT'];
for (const key of REQUIRED_ENV) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}
// Only start listening after validation passes
app.listen(process.env.PORT);
```

**16. Barrel Files That Block Tree-Shaking** [community] — Re-exporting everything through a large `index.js` barrel file is convenient but prevents bundlers from statically determining which exports are actually used. WHY it causes problems: what appears to be a clean import (`import { one } from './utils'`) actually includes the entire module graph in the bundle because static analysis fails on wildcard re-exports. Fix: use barrel files only for public package APIs; never create deep internal barrel files; prefer direct deep imports for internal use.

**17. Requiring Modules Inside Functions** [community] — Calling `require()` (or dynamic `import()`) inside a function body rather than at the module top level defers the synchronous disk read to request-handling time. WHY it causes problems: first-request latency spikes; if the module has a syntax error or missing dependency, the failure surfaces mid-request rather than at startup, bypassing your crash detection. Fix: always place `require()` calls at the top of the file; use static `import` declarations in ESM; only use dynamic `import()` for genuine lazy-load scenarios (code splitting by route/feature).

**18. Prototype Pollution via `__proto__` in User-Supplied JSON** [community] — Merging untrusted input objects onto application objects without checking for prototype-polluting keys (`__proto__`, `constructor`, `prototype`) lets attackers inject properties onto `Object.prototype`, making them appear on every subsequent object in the process. WHY it causes problems: authentication bypasses, unexpected truthy checks, and hard-to-trace crashes across completely unrelated code paths. Fix: use `safeMerge` with an explicit blocklist, use `Map` for untrusted data, or use `JSON.parse` with a reviver that rejects dangerous keys.

**19. Using `innerHTML` with User Input** [community] — Setting `element.innerHTML = userContent` executes any script tags or event-handler attributes in `userContent`. WHY it causes problems: stored or reflected XSS allows attackers to steal session cookies, perform actions as the victim, or exfiltrate data. Fix: use `textContent` for plain text; when HTML rendering is required, pass through DOMPurify before assignment.

**20. Forgetting to Null Large Objects After Use in Long Functions** [community] — Holding a reference to a large object in a local variable keeps it alive until the function returns, even if all useful work with it is done. WHY it causes problems: in async functions that `await` long operations after processing the large data, the GC cannot collect it during the wait period, causing sustained memory pressure and GC pauses. Fix: explicitly set the variable to `null` as soon as you're done with it.

**21. Premature Performance Micro-Optimisations** [community] — Caching `array.length` in a loop variable (`for (let i=0, len=arr.length; i<len; i++)`) or avoiding `for...of` out of habit were valid 2012-era tricks. WHY it causes problems: modern V8 performs these optimisations automatically, but writing non-idiomatic code reduces readability and confuses reviewers without yielding measurable gains. Fix: write idiomatic, readable code first; profile and optimise only bottlenecks identified by measurement.

**22. No Graceful Shutdown Handler** [community] — Node.js processes that don't handle `SIGTERM` / `SIGINT` terminate immediately, mid-request. WHY it causes problems: in-flight HTTP requests are dropped, database transactions left open, and message queue jobs lost. Kubernetes and Docker send `SIGTERM` before forcibly killing a container — an ignored signal means every deploy drops active requests. Fix: listen for `SIGTERM`, stop accepting new connections, wait for active requests to complete, then exit.

```javascript
// Graceful shutdown pattern — required for containerised Node.js
const server = app.listen(3000);

async function shutdown(signal) {
  console.log(`Received ${signal}; starting graceful shutdown`);
  server.close(async () => {           // Stop accepting new connections
    await db.end();                    // Flush DB connection pool
    await messageQueue.close();        // Drain queue consumer
    console.log('Shutdown complete');
    process.exit(0);
  });
  // Force-kill if shutdown takes > 10s (stuck connections)
  setTimeout(() => { console.error('Forced shutdown'); process.exit(1); }, 10_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));
```

**23. Running CPU-Intensive Work on the Event Loop Thread** [community] — Synchronous loops over large datasets, encryption, image processing, or JSON parsing of large payloads all block the V8 event loop. WHY it causes problems: while one request is hashing a 5 MB payload synchronously, every other concurrent request waiting for I/O also stalls — the server appears non-responsive under load even though the CPU is busy. Fix: offload CPU-bound work to Web Workers (browser) or `worker_threads` (Node.js), or use a worker pool library (`Piscina`).

**24. Not Returning or Awaiting Promises in Tests** [community] — Writing `it('works', () => fetchData().then(expect...))` without a `return` statement (or without making the test function `async` with `await`) causes the test to finish before the assertion executes — giving a false pass even when the tested code is broken. WHY it causes problems: CI stays green while production fails; the bug is only discovered when the feature visibly breaks in the field. Fix: always `return` promise chains in test functions, or use `async/await` consistently.

**25. Module-Level Singleton Imports That Prevent Test Isolation** [community] — Importing a concrete dependency (logger, DB client, HTTP client) at the module top level and calling it directly makes unit tests impossible without patching the module system (`jest.mock`, `vi.mock`). WHY it causes problems: tests become order-dependent, slow (real network calls), and fragile (environment-dependent). Mock setup in test files becomes a maintenance burden as the import chain grows. Fix: use factory functions that accept dependencies as parameters; inject stubs in tests without needing module-level patching.

**26. Accidentally Mutating Shared Arrays with `.sort()` and `.reverse()`** [community] — `Array.prototype.sort()` and `.reverse()` mutate the array in place and return the same reference. WHY it causes problems: when the same array reference is used in multiple places (component state, cache, a closed-over variable), a sort in one place changes what every other consumer sees, producing subtle, hard-to-reproduce bugs. Fix: prefer `arr.toSorted()` and `arr.toReversed()` (ES2023); they return a new array and leave the original unchanged.

```javascript
// BAD — mutates the original; all references to users now see sorted order
const sorted = users.sort((a, b) => a.name.localeCompare(b.name));
displayTable(sorted);
// Somewhere else: users is now sorted — surprising if you passed it by reference

// GOOD — original users array is unchanged
const sorted = users.toSorted((a, b) => a.name.localeCompare(b.name));
```

---

## JSDoc Type Checking (Plain JS + TypeScript Checker)

For projects that want type safety without a TypeScript build pipeline, `@ts-check` + JSDoc gives you the same static analysis the TS compiler provides, with zero compilation step.

```javascript
// @ts-check  ← add to top of any JS file to enable TS type checking in editor + tsc

/**
 * @typedef {Object} User
 * @property {string} id
 * @property {string} name
 * @property {string} email
 * @property {boolean} [isActive]   Optional field
 */

/**
 * Fetch a user by ID. Returns null if not found.
 * @param {string} userId
 * @returns {Promise<User | null>}
 */
async function getUser(userId) {
  const res = await fetch(`/api/users/${userId}`);
  if (!res.ok) return null;
  return /** @type {User} */ (await res.json());
}

/**
 * Generic cache factory.
 * @template K, V
 * @param {(key: K) => Promise<V>} fetcher
 * @returns {{ get: (key: K) => Promise<V> }}
 */
function createCache(fetcher) {
  const map = /** @type {Map<K, V>} */ (new Map());
  return {
    async get(key) {
      if (!map.has(key)) map.set(key, await fetcher(key));
      return /** @type {V} */ (map.get(key));
    },
  };
}
```

**Enabling project-wide checking without compiling:**
```json
// tsconfig.json — zero emit, type-check JS files only
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true,
    "noEmit": true,
    "strict": true,
    "target": "ES2022",
    "module": "NodeNext"
  },
  "include": ["src/**/*.js"]
}
```

```bash
npx tsc --noEmit        # type-check; no output files
npx tsc --noEmit --watch # live checking
```

**When to use JSDoc vs TypeScript:**
- Use JSDoc + `@ts-check` for: scripts, libraries that ship plain JS, teams that can't add a build step
- Use TypeScript for: larger codebases, teams that value `interface`/`enum`/decorator syntax, frameworks that expect `.ts` source

---

## Web Platform APIs

### Web Crypto API — Secure Randomness and Cryptography

The Web Crypto API (`crypto.subtle` + `crypto.randomUUID()`) is available in both browsers and Node.js 18+. Use it instead of `Math.random()` for security-sensitive work and instead of the `uuid` npm package for UUID generation.

```javascript
// crypto.randomUUID() — cryptographically random UUID v4 (no package needed)
const id = crypto.randomUUID();
// 'f47ac10b-58cc-4372-a567-0e02b2c3d479'

// Hashing with SHA-256 (browser + Node.js)
async function sha256(message) {
  const encoded = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoded);
  // Convert ArrayBuffer to hex string
  return Array.from(new Uint8Array(hashBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}
const hash = await sha256('Hello, World!');

// Symmetric encryption: AES-GCM (authenticated encryption)
async function encryptAES(plaintext, key) {
  const iv = crypto.getRandomValues(new Uint8Array(12)); // 96-bit IV
  const encoded = new TextEncoder().encode(plaintext);
  const ciphertext = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    encoded,
  );
  return { ciphertext, iv };
}

// Generate an AES-GCM key (use CryptoKeyPair for asymmetric)
const key = await crypto.subtle.generateKey(
  { name: 'AES-GCM', length: 256 },
  true,   // extractable
  ['encrypt', 'decrypt'],
);

// HMAC for message authentication
async function hmacSign(message, secret) {
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    new TextEncoder().encode(message),
  );
  return Buffer.from(signature).toString('base64');
}
```

**Security notes:**
- `crypto.getRandomValues()` is cryptographically secure; `Math.random()` is not — never use `Math.random()` for tokens, IDs, or keys.
- `crypto.subtle` operations are async (Promise-based) to allow off-main-thread execution.
- Use AES-GCM (authenticated) not AES-CBC (unauthenticated) — GCM detects tampering.
- In Node.js, `crypto.subtle` is available as `globalThis.crypto.subtle` (Node 18+) or via `import { webcrypto } from 'node:crypto'`.

### URL and URLSearchParams — Parse, Build, and Modify URLs

The `URL` and `URLSearchParams` classes provide a standards-compliant, cross-environment (browser + Node.js) API for working with URLs. Never manually concatenate URL strings.

```javascript
// Parse and read URL components
const url = new URL('https://api.example.com/v1/users?page=2&limit=10#section');
url.hostname;   // 'api.example.com'
url.pathname;   // '/v1/users'
url.searchParams.get('page');   // '2'
url.searchParams.get('limit');  // '10'
url.hash;       // '#section'

// Safely build URLs — no string concatenation (no injection risk)
function buildEndpoint(base, userId, query = {}) {
  const url = new URL(`/api/users/${userId}`, base);
  for (const [key, value] of Object.entries(query)) {
    url.searchParams.set(key, value);
  }
  return url.toString();
}
buildEndpoint('https://api.example.com', 42, { page: '1', limit: '20' });
// 'https://api.example.com/api/users/42?page=1&limit=20'

// URLSearchParams — parse query strings standalone
const params = new URLSearchParams('page=1&tags=js&tags=ts&sort=desc');
params.get('page');          // '1'
params.get('sort');          // 'desc'
params.getAll('tags');       // ['js', 'ts']
params.has('page');          // true

// Append, set, delete
params.append('page', '2');  // adds second page= entry
params.set('sort', 'asc');   // replaces existing sort
params.delete('tags');
[...params];                 // [['page','1'],['page','2'],['sort','asc']]
params.toString();           // 'page=1&page=2&sort=asc'

// Build a fetch URL cleanly — no manual encoding
async function searchUsers(query, options = {}) {
  const params = new URLSearchParams({ q: query, ...options });
  const res = await fetch(`/api/search?${params}`);
  return res.json();
}
```

**Why it matters:** manual URL string building with template literals doesn't encode special characters correctly (`+`, `&`, `=`, `%`), causing broken requests or accidental parameter injection. `URLSearchParams` handles encoding automatically.

### TextEncoder / TextDecoder — String ↔ Binary Conversion

`TextEncoder` and `TextDecoder` are the standard cross-environment APIs for converting between JavaScript strings and `Uint8Array` binary data. They replace Node.js-only `Buffer.from(str, 'utf8')` patterns in code that must run in both environments.

```javascript
// String → Uint8Array (UTF-8 bytes)
const encoder = new TextEncoder(); // always UTF-8
const bytes = encoder.encode('Hello, 🌍');
// Uint8Array [72, 101, 108, 108, 111, 44, 32, 240, 159, 140, 141]

// Single-use convenience
const { written, read } = encoder.encodeInto('Hello', new Uint8Array(16));
// Writes directly into a pre-allocated buffer — avoids intermediate allocation

// Uint8Array → String (specify encoding)
const decoder = new TextDecoder('utf-8');
decoder.decode(bytes);  // 'Hello, 🌍'

// Stream decoding — process chunks that may split multibyte characters
const streamDecoder = new TextDecoder('utf-8', { fatal: true }); // throws on invalid bytes
for (const chunk of byteChunks) {
  const partial = streamDecoder.decode(chunk, { stream: true }); // true = more chunks coming
  process(partial);
}
const final = streamDecoder.decode(); // flush remaining state

// Cross-environment hex utility using TextEncoder
function toHex(str) {
  return [...new TextEncoder().encode(str)]
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}
toHex('ABC'); // '414243'

// Detect encoding boundary issues — byte length ≠ string length for non-ASCII
const emoji = '🌍';
new TextEncoder().encode(emoji).length; // 4 bytes
emoji.length;                           // 2 code units (surrogate pair in JS)
[...emoji].length;                      // 1 grapheme
```

**Common pitfall:** `string.length` counts UTF-16 code units, not bytes or characters. For accurate byte budgets (e.g., Kafka message limits, HTTP header size), always use `new TextEncoder().encode(str).length`.

### Web Streams API — Browser-Native Streaming

The Web Streams API (`ReadableStream`, `WritableStream`, `TransformStream`) is supported in all modern browsers and Node.js 18+. It provides a standard, cross-environment streaming model with backpressure built in.

```javascript
// ReadableStream — produce data lazily with backpressure
function numberStream(start, end) {
  return new ReadableStream({
    start(controller) {
      for (let i = start; i <= end; i++) {
        controller.enqueue(i); // push value into the stream
      }
      controller.close();
    },
  });
}

// Consume with pipeTo (applies backpressure automatically)
const writable = new WritableStream({
  write(chunk) { console.log('Received:', chunk); },
  close()      { console.log('Done'); },
});
await numberStream(1, 5).pipeTo(writable);

// TransformStream — transform chunks in transit (e.g., gzip, JSON parse)
function csvToJSON(headers) {
  return new TransformStream({
    transform(chunk, controller) {
      const values = chunk.split(',');
      const obj = Object.fromEntries(headers.map((h, i) => [h, values[i]]));
      controller.enqueue(obj);
    },
  });
}

// Pipe through a transform
const csv = new ReadableStream({ /* yields CSV rows */ });
const transform = csvToJSON(['name', 'age', 'city']);
const output = csv.pipeThrough(transform);
for await (const record of output) {
  console.log(record); // { name: '...', age: '...', city: '...' }
}

// fetch() response body IS a ReadableStream — stream large responses without buffering
async function streamLargeDownload(url, onChunk) {
  const response = await fetch(url);
  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    onChunk(decoder.decode(value, { stream: true }));
  }
}
```

**Backpressure:** unlike Node.js EventEmitter streams, Web Streams apply backpressure by default. A slow `WritableStream` automatically slows down the producer — no risk of unbounded memory growth.

---

## Additional Language Idioms

### `Object.fromEntries()` — Transform Maps and Arrays to Objects

`Object.fromEntries()` is the inverse of `Object.entries()`. Together they form a powerful pair for transforming object shapes without intermediate variables.

```javascript
// Map → Object
const map = new Map([['a', 1], ['b', 2], ['c', 3]]);
const obj = Object.fromEntries(map); // { a: 1, b: 2, c: 3 }

// Transform object values — rename/filter keys without lodash
const prices = { apple: 1.0, banana: 0.5, cherry: 2.5 };

// Double every price
const doubled = Object.fromEntries(
  Object.entries(prices).map(([k, v]) => [k, v * 2])
);
// { apple: 2.0, banana: 1.0, cherry: 5.0 }

// Filter object entries
const expensive = Object.fromEntries(
  Object.entries(prices).filter(([, v]) => v > 1)
);
// { apple: 1.0, cherry: 2.5 }

// Rename keys via lookup
const keyMap = { apple: 'APPLE', banana: 'BANANA', cherry: 'CHERRY' };
const renamed = Object.fromEntries(
  Object.entries(prices).map(([k, v]) => [keyMap[k] ?? k, v])
);

// URLSearchParams → Object (useful for form parsing)
const params = new URLSearchParams('name=Alice&age=30&active=true');
const formData = Object.fromEntries(params); // { name: 'Alice', age: '30', active: 'true' }
```

### Regex Named Capture Groups and the `d` Flag

Named capture groups (`(?<name>...)`) make regex matches self-documenting. The `d` flag (ES2022) adds `indices` to the match result — the start/end position of each capture group, enabling precise string manipulation.

```javascript
// Named capture groups — self-documenting regex
const ISO_DATE = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/;
const match = '2026-05-03'.match(ISO_DATE);
const { year, month, day } = match.groups;
// year='2026', month='05', day='03'

// Named backreferences — same group referenced later in the pattern
const HTML_TAG = /<(?<tag>[a-z]+)>.*?<\/\k<tag>>/i; // \k<tag> = same tag name
HTML_TAG.test('<div>Hello</div>');  // true
HTML_TAG.test('<div>Hello</span>'); // false

// 'd' flag — capture group indices (ES2022)
const dMatch = /(?<word>\w+)/d.exec('hello world');
dMatch.indices;          // [[0, 5], [0, 5]] — full match + first group
dMatch.indices.groups;   // { word: [0, 5] }
// Use for precise editor highlighting, diff tooling, code formatting

// Replace with named groups
const swapDate = '2026-05-03'.replace(
  /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/,
  '$<month>/$<day>/$<year>'  // Named group reference in replacement
);
// '05/03/2026'

// Regex hasIndices check
const re = /\d+/d;
re.hasIndices; // true — tells you the 'd' flag is set
```

### `globalThis` — Cross-Environment Global Object Access

`globalThis` provides a universal reference to the global object that works in browsers (`window`), Node.js (`global`), Web Workers (`self`), and any future runtime. Use it for cross-environment polyfills and detection.

```javascript
// Before globalThis: environment-specific hacks
const global = (typeof window !== 'undefined') ? window
             : (typeof self   !== 'undefined') ? self
             : (typeof global !== 'undefined') ? global
             : {}; // fragile — misses Deno, Bun, edge runtimes

// With globalThis — always correct, no hacks
console.log(globalThis === window); // true in browsers
console.log(globalThis === global); // true in Node.js

// Safe feature detection without environment guards
if (typeof globalThis.fetch === 'function') {
  // Native fetch is available (browser, Node 18+, Deno, Bun)
}

// Polyfill a global — attaches to the correct object in any environment
if (!globalThis.structuredClone) {
  globalThis.structuredClone = obj => JSON.parse(JSON.stringify(obj));
}

// Cross-environment global configuration store (use sparingly)
globalThis.__APP_CONFIG__ ??= { version: '1.0.0', debug: false };
```

**Caution:** polluting `globalThis` causes the same module-isolation problems as `window.foo` in browser code. Prefer explicit imports/exports or dependency injection. Use `globalThis` only for polyfills and cross-environment compatibility layers.

### `Array.flat()` and `Array.flatMap()` — Flatten Nested Arrays

`flat()` flattens one or more levels of nested arrays. `flatMap()` combines a `map()` and a `flat(1)` in a single pass — more efficient than calling them separately, and useful for transformations that produce variable numbers of output elements.

```javascript
// flat() — flatten one level by default
[1, [2, 3], [4, [5, 6]]].flat();     // [1, 2, 3, 4, [5, 6]]
[1, [2, [3, [4]]]].flat(2);          // [1, 2, 3, [4]]  — 2 levels
[1, [2, [3, [4]]]].flat(Infinity);   // [1, 2, 3, 4] — fully flatten

// Remove empty slots in sparse arrays
[1, , , 2, , 3].flat(); // [1, 2, 3]

// flatMap() — map then flatten one level (single pass, more efficient)
const sentences = ['Hello World', 'Goodbye Moon'];
sentences.flatMap(s => s.split(' ')); // ['Hello', 'World', 'Goodbye', 'Moon']

// Key superpower: return 0 or 2+ elements per input (impossible with map alone)
const orders = [
  { id: 1, items: ['apple', 'banana'] },
  { id: 2, items: [] },              // empty — filtered out naturally
  { id: 3, items: ['cherry'] },
];
const allItems = orders.flatMap(o => o.items);
// ['apple', 'banana', 'cherry'] — order 2 disappears without a filter step

// Conditional inclusion via flatMap (replace item or skip)
const data = [1, -2, 3, -4, 5];
const positiveDoubled = data.flatMap(n => n > 0 ? [n * 2] : []);
// [2, 6, 10]
```

### BigInt for Exact Integer Arithmetic

`BigInt` handles integers larger than `Number.MAX_SAFE_INTEGER` (2^53 − 1) without precision loss. Use it for cryptographic keys, high-precision timestamps, database IDs from 64-bit systems, and financial calculations that exceed the safe integer range.

```javascript
// Number precision failure — silent corruption
Number.MAX_SAFE_INTEGER;          // 9007199254740991
9007199254740991 + 1;             // 9007199254740992 ✓
9007199254740991 + 2;             // 9007199254740992 ✗ — wrong! same as +1
9007199254740992 === 9007199254740993; // true — silently equal!

// BigInt — exact arithmetic for any magnitude
const big = 9007199254740991n;   // 'n' suffix creates BigInt literal
big + 1n;                        // 9007199254740992n ✓
big + 2n;                        // 9007199254740993n ✓ — correct

// BigInt with large IDs from 64-bit databases (e.g., Twitter Snowflakes)
const tweetId = 1234567890123456789n; // No precision loss

// Arithmetic: BigInt only mixes with other BigInts (no implicit conversion)
5n + 3n;   // 8n
5n * 3n;   // 15n
5n ** 2n;  // 25n
5n / 2n;   // 2n — integer division (truncates, no fractions)
5n % 2n;   // 1n

// ❌ Can't mix BigInt and Number
// 5n + 3;  // TypeError: Cannot mix BigInt and other types

// Convert carefully
const n = 42n;
Number(n);     // 42  — safe if n ≤ Number.MAX_SAFE_INTEGER
String(n);     // '42'
parseInt('42') === Number(42n); // true — only if in safe range

// Check at runtime
function safeBigIntToNumber(n) {
  if (n > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new RangeError(`BigInt ${n} exceeds MAX_SAFE_INTEGER`);
  }
  return Number(n);
}

// JSON doesn't support BigInt — use a replacer
JSON.stringify(42n); // TypeError: Do not know how to serialize a BigInt
const safeJSON = {
  stringify: (v) => JSON.stringify(v, (_, val) =>
    typeof val === 'bigint' ? val.toString() : val
  ),
};
```

**Note:** numeric separators (`1_000_000n`, `0xFF_FF`) work with BigInt literals too, and apply to all numeric literals in ES2021+ for readability without affecting the value.

---

## Additional Community Pitfalls

**27. Not Using `crypto.randomUUID()` for Secure IDs** [community] — Developers still reach for `Math.random()` or short `Math.random().toString(36)` snippets for ID generation. WHY it causes problems: `Math.random()` is not cryptographically secure — attackers who observe a few IDs can predict future ones. For session tokens, CSRF tokens, and document IDs, this is an exploitable vulnerability. Fix: use `crypto.randomUUID()` (built-in, no package needed) or `crypto.getRandomValues()` for custom formats.

**28. Forgetting `TextEncoder` Byte Length ≠ String Length** [community] — Using `string.length` to budget message sizes (Kafka limits, Redis key sizes, HTTP header caps) gives byte counts only for pure ASCII. WHY it causes problems: non-ASCII characters (emoji, CJK, accented letters) occupy 2–4 bytes in UTF-8; `string.length` counts UTF-16 code units — a 10-character emoji string can be 40 bytes. Messages silently exceed byte limits at runtime, causing dropped messages or truncation. Fix: use `new TextEncoder().encode(str).length` for accurate byte counts.

**29. Building URLs via String Template Literals** [community] — Constructing query strings with template literals (`\`/api?q=${userInput}\``) fails to encode special characters and creates injection vectors. WHY it causes problems: if `userInput` contains `&`, `=`, `+`, or `%`, the URL is malformed or injects additional parameters. Fix: use `new URL()` + `URLSearchParams` to construct URLs programmatically — encoding is automatic and correct.

**30. `BigInt` Silently Not Serializing to JSON** [community] — Calling `JSON.stringify()` on an object containing `BigInt` values throws a `TypeError: Do not know how to serialize a BigInt` at runtime, not at the `BigInt` assignment. WHY it causes problems: the code works fine during development (where BigInt values are small enough to fit in `Number`), but fails in production when IDs from 64-bit databases or large counters arrive as BigInt. Fix: use a `replacer` function in `JSON.stringify` to convert BigInt to string, or use a library like `superjson`.

**31. Mutating `globalThis` in Libraries** [community] — Library code that writes to `globalThis` (e.g., `globalThis.myLib = ...`) pollutes the global scope for every consumer. WHY it causes problems: two libraries writing to the same global key silently overwrite each other, and consumers have no way to scope or version-control globals. Conflicts surface as mysterious errors far from the mutation site. Fix: libraries must never write to `globalThis`; use ESM exports and let consumers manage scope. Acceptable exceptions: polyfills that check `typeof globalThis.feature !== 'undefined'` before assigning.

**32. Timing-Sensitive Comparisons with `===`** [community] — Comparing secret tokens, HMAC signatures, or passwords with `===` is vulnerable to timing attacks. WHY it causes problems: JavaScript's strict equality short-circuits on the first differing character — an attacker who measures response time can deduce how many leading characters of their guess match the secret. Fix: always use a constant-time comparison function (`crypto.timingSafeEqual` in Node.js) for secret data. Never use `===` to validate tokens.

```javascript
import { timingSafeEqual } from 'node:crypto';

// BAD — short-circuit leaks information via timing
function verifyToken(provided, expected) {
  return provided === expected; // timing-vulnerable
}

// GOOD — constant-time comparison
function verifyTokenSafe(provided, expected) {
  const a = Buffer.from(provided,  'utf8');
  const b = Buffer.from(expected,  'utf8');
  // Lengths must match before comparing content
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
```

**33. Regex Without Timeout on User-Supplied Patterns** [community] — Running `new RegExp(userInput)` on untrusted patterns with backtracking (like `(a+)+$`) causes catastrophic backtracking (ReDoS — Regular Expression Denial of Service). WHY it causes problems: a single malicious pattern can pin a Node.js thread at 100% CPU for seconds or minutes, starving all other requests. Fix: validate user regex patterns against a safe subset before executing (no nested quantifiers, bounded lengths), or run them in a worker thread with a timeout that kills the thread if exceeded. Never execute untrusted regex in the main event loop.

**34. The "Zalgo" Anti-Pattern — Inconsistent Sync/Async Callbacks** [community] — Writing a function that sometimes calls its callback synchronously and sometimes asynchronously produces non-deterministic behavior. WHY it causes problems: callers cannot reason about execution order; code that works in one code path silently breaks in another. The same function behaves differently depending on an internal condition (e.g., cache hit vs. miss), making it impossible to write correct calling code without reading the implementation. Fix: always be either consistently synchronous or consistently asynchronous. If unsure, `Promise.resolve(value).then(cb)` guarantees async delivery. Promises eliminate this problem entirely — a promise's `then` handler is always called asynchronously (in the next microtask), never synchronously, regardless of when the promise was settled.

```javascript
// BAD — "Zalgo": callback is synchronous on cache hit, async on miss
function getUser(id, callback) {
  if (cache.has(id)) {
    callback(cache.get(id)); // synchronous!
  } else {
    db.find(id).then(user => {
      cache.set(id, user);
      callback(user);        // asynchronous!
    });
  }
}

// GOOD — always async (wraps sync result in resolved Promise)
async function getUser(id) {
  if (cache.has(id)) {
    return cache.get(id);  // Promise.resolve() wrapping is automatic in async fn
  }
  const user = await db.find(id);
  cache.set(id, user);
  return user;
}
```

**35. Not Using `EventEmitter.captureRejections` for Async Event Handlers** [community] — When you attach an `async` function as an event listener on a Node.js `EventEmitter`, any unhandled rejection inside that handler is NOT automatically forwarded to the emitter's `'error'` event. WHY it causes problems: the rejection becomes an unhandled promise rejection that crashes the process in Node.js ≥ 15, and the error bypasses all your emitter-level error handling. Fix: create emitters with `captureRejections: true`, which makes Node.js automatically route async handler rejections to the emitter's `'error'` event, keeping error handling in one place.

```javascript
import { EventEmitter } from 'events';

// BAD — async handler rejections bypass the 'error' listener
const emitter = new EventEmitter();
emitter.on('data', async (payload) => {
  const result = await processData(payload); // If this throws, it's an unhandled rejection
});
emitter.on('error', err => console.error('Caught:', err)); // NEVER called for async rejections

// GOOD — captureRejections: true routes async rejections to 'error'
const safeEmitter = new EventEmitter({ captureRejections: true });
safeEmitter.on('data', async (payload) => {
  const result = await processData(payload); // If this throws, goes to 'error' below
});
safeEmitter.on('error', err => console.error('Caught:', err)); // Called for async rejections too

// OR set globally for all new emitters in the process:
EventEmitter.captureRejections = true;
```

**36. Hardcoded Test Ports Causing Flaky CI** [community] — Tests that spawn HTTP servers on a fixed port (e.g., `app.listen(3000)`) fail with `EADDRINUSE` when multiple test processes run concurrently in CI (watch mode, parallel workers, or multiple jobs on the same machine). WHY it causes problems: flaky test failures that only occur under CI parallelism — the tests pass locally but fail randomly in pipelines. Fix: always bind to port `0` in tests (the OS assigns a free port), then read the actual port from `server.address().port` after the server starts.

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
| Mixing ESM and CJS imports | Interop edge-cases; `require()` cannot load ESM synchronously; dual-package hazard with shared state | Standardise on ESM; set `"type": "module"` in package.json; use `createRequire()` for legacy |
| `console.log` in production | Unstructured, unsearchable output; leaks sensitive data | Use a structured logger (Pino / Winston) |
| Modifying function parameters directly | Surprise side-effects for callers; referential equality breaks | Return new values; copy with `structuredClone` or spread |
| Using `==` instead of `===` | Implicit type coercion produces surprising truthy/falsy results | Always use `===` and `!==` |
| Missing `return` in `.then()` handler | Breaks promise chain; subsequent handlers receive `undefined` | Always `return` the next promise from `.then()` |
| Catching and re-throwing without `cause` | Original stack trace is lost; root cause debugging is hard | Use `throw new Error('context', { cause: err })` |
| `using` with non-disposable object | Deferred `TypeError` at block exit, not assignment — unexpected and hard to locate | Only bind disposable objects (or `null`) to `using` |
| Sharing base iterator across helper chains | Two helpers from the same base interleave consumption silently | Call `.values()` independently for each chain |
| `Array.fromAsync` for concurrent Promises | Awaits each element sequentially; 5× slower than `Promise.all` for 5 items | Use `Promise.all([...])` for concurrent; `Array.fromAsync` for sequential async streams |
| `return promise` without `await` in async fn | Removes the function from async stack traces; debugging in production is severely hampered | Use `return await promise` so the function stays in the call stack |
| Lazy `process.env` access in deep code paths | App starts successfully but crashes later on first use of unconfigured path | Validate all required env vars at startup; fail fast before accepting traffic |
| Oversized barrel files (`index.js` re-exports all) | Prevents tree-shaking; entire module graph bundled even when only one export is needed | Use barrel files only for public APIs; prefer direct deep imports internally |
| `require()` inside function bodies | First-request latency spikes; errors surface mid-request instead of at startup | Place `require()` at top of file; use static `import` in ESM |
| `innerHTML = userInput` without sanitization | XSS: attacker-controlled HTML executes scripts; session theft, CSRF | Use `textContent` for plain text; use DOMPurify when HTML is required |
| Merging untrusted objects without `__proto__` check | Prototype pollution: injects properties onto all objects; auth bypasses and unexpected crashes | Block `__proto__`, `constructor`, `prototype` keys; use `Map` for untrusted data |
| `eval()` / `new Function(code)` with user input | Arbitrary code execution; bypasses CSP; impossible to statically analyse | Whitelist operations; use sandboxed interpreters; never execute user strings as code |
| CPU work on the main thread | Blocks event loop; all concurrent requests/frames stall while computation runs | Offload to Web Workers (browser) or `worker_threads` (Node.js) |
| Not calling `worker.terminate()` after use | Worker thread stays alive consuming memory until process exits | Call `worker.terminate()` or confirm the worker exits naturally |
| `.sort()` / `.reverse()` on shared arrays | Mutates in place; all references to that array silently see the sorted/reversed order | Use `.toSorted()` / `.toReversed()` (ES2023) which return new arrays |
| Module-level singleton imports in testable code | Unit tests require module-system patching (`jest.mock`); creates fragile, order-dependent tests | Use factory functions with injected dependencies; pass stubs at test time |
| `Math.random()` for security tokens or IDs | Not cryptographically secure; future values predictable from observed outputs | Use `crypto.randomUUID()` or `crypto.getRandomValues()` |
| `string.length` for byte budgets | Counts UTF-16 code units, not bytes; emoji and CJK overflow byte limits silently | Use `new TextEncoder().encode(str).length` for accurate byte counts |
| Template literals to build URLs with user input | Does not encode special chars; injects extra query params or breaks URL | Use `new URL()` + `URLSearchParams` for automatic encoding |
| `===` to compare secret tokens/HMACs | Short-circuits on first differing char; timing leaks leading characters to attackers | Use `crypto.timingSafeEqual` (Node.js) for constant-time comparison |
| `JSON.stringify` on objects with `BigInt` values | Throws `TypeError` at runtime; not caught at build time or by static analysis | Use a replacer: `JSON.stringify(v, (_, val) => typeof val === 'bigint' ? val.toString() : val)` |
| `new RegExp(userInput)` without safeguards | ReDoS: backtracking patterns can pin the event loop at 100% CPU | Validate pattern safety or run in a worker thread with timeout |
| Inconsistent sync/async callbacks ("Zalgo") | Non-deterministic execution order; calling code cannot reason about when side effects happen | Always be consistently async; use `async`/Promises which guarantee microtask delivery |
| `async` handlers on `EventEmitter` without `captureRejections` | Async handler rejections bypass the emitter's `'error'` event; become unhandled rejections that crash the process | Use `new EventEmitter({ captureRejections: true })` or set `EventEmitter.captureRejections = true` |
| Fixed port in tests (`app.listen(3000)`) | Port collisions under parallel CI workers or watch mode cause `EADDRINUSE` flakiness | Bind to port `0` in tests; read actual port from `server.address().port` after start |
