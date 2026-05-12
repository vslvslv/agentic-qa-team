# JavaScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 47 | score: 100/100 | date: 2026-05-12 -->

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

The `Intl` namespace provides locale-aware formatting with zero external dependencies. Always prefer `Intl` over manual string concatenation for dates, numbers, durations, lists, and relative time — manual approaches miss locale nuance and are a maintenance burden.

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

```javascript
// ── Intl.DurationFormat — human-readable durations (Baseline March 2025) ─
const dur = new Intl.DurationFormat('en', { style: 'long' });
dur.format({ hours: 1, minutes: 46, seconds: 40 });
// "1 hour, 46 minutes, and 40 seconds"

const shortDur = new Intl.DurationFormat('en', { style: 'short' });
shortDur.format({ hours: 1, minutes: 46, seconds: 40 });
// "1 hr, 46 min, and 40 sec"

// Narrow style — compact, for tight UI spaces
const narrowDur = new Intl.DurationFormat('pt', { style: 'narrow' });
narrowDur.format({ hours: 1, minutes: 46, seconds: 40 });
// "1 h 46 min 40 s"

// formatToParts — get each component separately for custom rendering
const parts = new Intl.DurationFormat('en').formatToParts({ hours: 2, minutes: 30 });
// [ {type:'integer',value:'2',unit:'hour'}, {type:'literal',value:' hr, '},
//   {type:'integer',value:'30',unit:'minute'}, {type:'literal',value:' min'} ]

// Practical: "time remaining" countdown display
function formatCountdown(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  return new Intl.DurationFormat(navigator.language, { style: 'long' })
    .format({ hours: h, minutes: m, seconds: s });
}
formatCountdown(3720); // "1 hour, 2 minutes, and 0 seconds"
```

**Rule of thumb:** build-time i18n libraries (i18next, formatjs) manage translation strings; `Intl` handles the _format_ of dates, numbers, lists, and durations within those strings. They complement each other.

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

## ES2026 and Emerging Features

### `Math.sumPrecise()` — Floating-Point Safe Summation (ES2026 / Baseline April 2026)

`Math.sumPrecise()` sums an iterable of numbers using a high-precision algorithm that avoids the intermediate rounding errors that accumulate in a naive `+` loop. It accepts any iterable (arrays, generators, `Set`) and returns the nearest representable 64-bit float of the mathematically exact sum.

```javascript
// Classic floating-point pitfall — order of addition loses precision
let sum = 0;
const nums = [1e20, 0.1, -1e20];
for (const n of nums) sum += n;
console.log(sum); // 0 — WRONG (1e20 + 0.1 rounds to 1e20 mid-loop)

// Math.sumPrecise — treats each intermediate result at full mathematical precision
console.log(Math.sumPrecise([1e20, 0.1, -1e20])); // 0.1 — CORRECT

// Works with any iterable
console.log(Math.sumPrecise(new Set([1, 2, 3, 4, 5]))); // 15

// Generator input — lazy; no intermediate array allocated
function* measurements() {
  yield 1.1; yield 2.2; yield 3.3;
}
console.log(Math.sumPrecise(measurements())); // 6.6

// Still cannot overcome inherent float representation limits
console.log(Math.sumPrecise([0.1, 0.2])); // 0.30000000000000004
// 0.1 and 0.2 are already imprecise as 64-bit floats; sumPrecise sums
// their precise IEEE 754 values exactly, but the values themselves are approximations.

// Empty iterable returns -0 (consistent with the spec)
console.log(Math.sumPrecise([]));   // -0
console.log(1 / Math.sumPrecise([])); // -Infinity — confirms -0, not +0
```

**When to use it:** scientific / financial computations where you accumulate many floating-point values and the accumulation order depends on runtime data (e.g., reducing over a stream). For the `0.1 + 0.2 === 0.3` problem, use a decimal library — `sumPrecise` can't fix inherent representation limits of 64-bit floats.

---

### `Uint8Array` Base64 and Hex Methods (Baseline September 2025)

The `Uint8Array` class now ships with built-in base64 and hex encoding/decoding. These replace the notoriously awkward `btoa`/`atob` + `String.fromCharCode` dance, and remove the need for the `buffer` npm package in the browser.

```javascript
// ── Encoding: binary → base64 ────────────────────────────────────────
const bytes = new Uint8Array([202, 254, 208, 13]); // "cafed00d" in hex

// Standard base64 (A-Z a-z 0-9 + /)
console.log(bytes.toBase64()); // "yv7QDQ=="

// URL-safe base64 (A-Z a-z 0-9 - _) — safe in URLs and filenames, no + or /
console.log(bytes.toBase64({ alphabet: 'base64url' })); // "yv7QDQ"

// Without padding characters (useful when the length is known or transmitted separately)
console.log(bytes.toBase64({ omitPadding: true })); // "yv7QDQ"

// ── Decoding: base64 → binary ────────────────────────────────────────
const decoded = Uint8Array.fromBase64('yv7QDQ==');
console.log(decoded); // Uint8Array [202, 254, 208, 13]

// URL-safe variant — match alphabet to the encoding
const urlDecoded = Uint8Array.fromBase64('yv7QDQ', { alphabet: 'base64url', lastChunkHandling: 'stop-before-partial' });

// Strict mode — ensures no non-zero overflow bits (cryptographic use)
Uint8Array.fromBase64('yv7QDQ==', { lastChunkHandling: 'strict' });

// ── Hex encoding/decoding ─────────────────────────────────────────────
const hex = bytes.toHex();         // "cafed00d"
const back = Uint8Array.fromHex('cafed00d'); // Uint8Array [202, 254, 208, 13]

// Practical: hashing with crypto.subtle + toHex (replaces manual Array.map)
async function sha256hex(message) {
  const encoded = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoded);
  return new Uint8Array(hashBuffer).toHex(); // "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
}

// ── Streaming: setFromBase64 writes into an existing buffer ──────────
// Useful when receiving base64-encoded chunks from a network stream
const buffer = new Uint8Array(1024);
let offset = 0;

for (const chunk of base64Chunks) {
  const { written } = buffer.setFromBase64(chunk, { lastChunkHandling: 'stop-before-partial' });
  // Or: buffer.subarray(offset).setFromBase64(chunk, {...}) to write at current offset
  offset += written;
}
```

**Why it matters:** `btoa(String.fromCharCode(...bytes))` silently fails for buffers larger than ~65k bytes (stack overflow from spread into `String.fromCharCode`). The new methods handle any size, support URL-safe alphabet, and are available in browsers, Node.js 22+, Deno, and Bun — no `Buffer` polyfill or npm package needed.

---

### `Iterator.concat()` — Sequence Multiple Iterables (Baseline March 2026)

`Iterator.concat()` is a static method that produces a single lazy iterator by yielding all values from each input iterable in order. It extends the Iterator Helpers suite (already in the file) with a clean concatenation primitive.

```javascript
// ── Basic concatenation ───────────────────────────────────────────────
const combined = Iterator.concat([1, 2, 3], new Set([4, 5]), 'abc');
console.log([...combined]); // [1, 2, 3, 4, 5, 'a', 'b', 'c']

// ── Mix any iterable type ─────────────────────────────────────────────
function* odds() { yield 1; yield 3; yield 5; }
const mixed = Iterator.concat(
  [0, 2, 4],         // Array
  odds(),             // Generator
  new Set([6, 8]),    // Set
);
console.log(mixed.toArray()); // [0, 2, 4, 1, 3, 5, 6, 8]

// ── Chain with other Iterator Helpers ────────────────────────────────
// Find the first even number across multiple lazy sources
const sources = Iterator.concat(
  [1, 3, 5, 7],
  [9, 10, 11, 12],
);
const firstEven = sources.find(n => n % 2 === 0); // 10 — stops early

// ── Merge two Maps ────────────────────────────────────────────────────
// Later entries win on key collision (right-hand side overwrites left)
const defaults = new Map([['timeout', 3000], ['retries', 3]]);
const overrides = new Map([['timeout', 5000], ['debug', true]]);
const merged = new Map(Iterator.concat(defaults, overrides));
// Map { timeout: 5000, retries: 3, debug: true }

// ── Non-iterable iterators need Iterator.from() wrapper ───────────────
const rawIter = { next: () => ({ value: 42, done: false }) }; // iterator, not iterable
// Iterator.concat(rawIter);                   // ❌ TypeError
Iterator.concat(Iterator.from(rawIter));       // ✅ wrap with Iterator.from
```

**`concat()` vs `flatMap()` for merging:**

| Situation | Use |
|-----------|-----|
| Fixed list of iterables to join | `Iterator.concat(a, b, c)` |
| Infinite number of iterables | `iter.flatMap(x => x)` — `concat` can't spread ∞ args |
| Need to transform while concatenating | `iter.flatMap(fn)` |
| Simple sequential read with early exit | `Iterator.concat(...)` + `.find()` / `.take()` |

---

### Decorators — TC39 Stage 3 (Transpiler-Ready, Native Landing)

JavaScript Decorators are functions that annotate and modify class declarations and their members. They reached Stage 3 with a final, stable API that differs from legacy `experimentalDecorators` in TypeScript/Babel. The Stage 3 spec is implemented in Babel (`@babel/plugin-proposal-decorators` with `"version": "2023-11"`) and TypeScript 5.0+.

```javascript
// ── Method decorator: logging wrapper ────────────────────────────────
function logged(fn, { kind, name }) {
  if (kind !== 'method') return fn;
  return function (...args) {
    console.log(`${name}(${args.map(JSON.stringify).join(', ')})`);
    const result = fn.call(this, ...args);
    console.log(`${name} → ${JSON.stringify(result)}`);
    return result;
  };
}

class Calculator {
  @logged
  add(a, b) { return a + b; }
}

new Calculator().add(2, 3);
// "add(2, 3)"
// "add → 5"

// ── Auto-accessor decorator: reactive property ────────────────────────
// 'accessor' is a new keyword that generates a private backing field
// plus a getter/setter pair — perfect for intercepting reads/writes.
function reactive(_, { kind, name, addInitializer }) {
  if (kind !== 'accessor') throw new Error('@reactive only works on accessors');
  return {
    get() { return this[`#${name}Backing`]; },
    set(value) {
      const old = this[`#${name}Backing`];
      this[`#${name}Backing`] = value;
      this.dispatchEvent?.(new CustomEvent('change', { detail: { name, old, value } }));
    },
  };
}

class Store extends EventTarget {
  @reactive accessor count = 0; // generates private #count backing field
}

const store = new Store();
store.addEventListener('change', e => console.log('changed:', e.detail));
store.count = 5; // fires 'change' event

// ── Class decorator: registration ────────────────────────────────────
function customElement(tagName) {
  return (Class, { addInitializer }) => {
    addInitializer(function () {
      customElements.define(tagName, this);
    });
    return Class;
  };
}

@customElement('my-button')
class MyButton extends HTMLElement {
  connectedCallback() { this.textContent = 'Click me'; }
}
// customElements.get('my-button') === MyButton

// ── Field decorator: validation ───────────────────────────────────────
function nonNegative(_, { kind, name }) {
  if (kind !== 'field') return;
  return function (initialValue) {
    if (initialValue < 0) throw new RangeError(`${name} must be >= 0`);
    return initialValue;
  };
}

class Inventory {
  @nonNegative quantity = 10;   // OK
  // @nonNegative quantity = -1; // RangeError at construction time
}

// ── bind decorator: auto-bind methods ────────────────────────────────
// Solves `this` loss when passing class methods as callbacks (gotcha #6 above)
function bind(fn, { name, addInitializer }) {
  addInitializer(function () {
    this[name] = fn.bind(this);
  });
}

class Button {
  @bind
  handleClick() { console.log('clicked', this); }
}

const btn = new Button();
document.addEventListener('click', btn.handleClick); // 'this' is the Button instance
```

**Key differences from legacy (`experimentalDecorators`):**
- Decorators receive the element they decorate — not a property descriptor.
- The `accessor` keyword is new language syntax (no legacy equivalent).
- Decorators cannot modify the class while it's being constructed — only after.
- Multiple decorators apply outermost-first for initialization, innermost-first for wrapping.

**Community signal [community]:** Legacy TypeScript `experimentalDecorators` and Stage 3 decorators are **not** interchangeable. Migrating a large codebase requires carefully auditing all decorator usage — Angular and NestJS have specific migration guides. Do not mix both in the same project.

---

### `import defer` — Deferred Module Evaluation (Stage 3 / TypeScript 5.9+)

`import defer` is a static import that loads the module from disk/network immediately but **defers execution** (and its side effects) until you first access a property of the namespace. It fills the gap between static `import` (loads + executes immediately) and dynamic `import()` (loads + executes on demand, returns a Promise).

```javascript
// ── Syntax — namespace import only ───────────────────────────────────
import defer * as analytics from './analytics.js';
import defer * as heavyLib  from './heavy-computation.js';
// Module files are resolved and pre-loaded (bundlers can split them),
// but their top-level code has NOT run yet.

// App starts fast — no side effects from deferred modules yet
startApp();

// Side effects execute the first time any property is accessed
button.addEventListener('click', () => {
  heavyLib.compute(data); // ← analytics.js and heavy-computation.js execute NOW
});

// ── Practical: platform-conditional initialisation ─────────────────────
import defer * as nodeUtils    from './platform/node.js';
import defer * as browserUtils from './platform/browser.js';

function init() {
  if (typeof window !== 'undefined') {
    browserUtils.setup(); // only browser module executes
  } else {
    nodeUtils.setup();    // only Node module executes
  }
}

// ── Practical: feature flags (A/B variants) ────────────────────────────
import defer * as variantA from './features/checkout-v1.js';
import defer * as variantB from './features/checkout-v2.js';

function loadCheckout(flag) {
  const mod = flag === 'v2' ? variantB : variantA;
  return mod.CheckoutComponent; // executes the chosen variant
}
```

**`import defer` vs `import()` vs static `import`:**

| | static `import` | `import defer` | `import()` |
|---|---|---|---|
| Load from disk/network | At parse time | At parse time | On `await import()` call |
| Module execution | Immediately | On first property access | After `await` |
| Returns | Binding | Namespace object | Promise\<namespace\> |
| Works with bundlers | ✅ | ✅ (code-split) | ✅ (code-split) |
| Top-level `await` in consumer | n/a | Not needed | Required |

**Limitation:** Only namespace syntax (`* as name`) is allowed — named and default imports are not supported. Runtime support requires Node.js 22+, or TypeScript `--module preserve` / `esnext` plus a bundler.

---

## Stage 3 Proposals — Production-Ready with Transpilers

These proposals have reached TC39 Stage 3 (specification complete, awaiting browser/runtime implementations to stabilise). All are available today via Babel or TypeScript 5.x.

### `Iterator.zip` / `Iterator.zipKeyed` — Joint Iteration (Stage 3)

`Iterator.zip()` combines positional elements from multiple iterables into arrays. `Iterator.zipKeyed()` combines them into named-key objects. Both support `"shortest"` (default), `"longest"`, and `"strict"` modes. This is the TC39 Joint Iteration proposal.

```javascript
// Iterator.zip — positional pairing (like Python's zip())
const zipped = Iterator.zip([0, 1, 2], [3, 4, 5]).toArray();
// [[0, 3], [1, 4], [2, 5]]

// Works with any iterable — generators, Sets, Maps, etc.
function* odds() { yield 1; yield 3; yield 5; }
const mixed = Iterator.zip([0, 2, 4], odds()).toArray();
// [[0, 1], [2, 3], [4, 5]]

// 'longest' mode — pads shorter iterables with undefined
Iterator.zip([1, 2, 3], [10, 20], { longest: true }).toArray();
// [[1, 10], [2, 20], [3, undefined]]

// 'strict' mode — throws if iterables have different lengths
try {
  Iterator.zip([1, 2, 3], [10, 20], { mode: 'strict' }).toArray();
} catch (e) {
  console.error('Iterables must be same length'); // thrown because lengths differ
}

// Iterator.zipKeyed — named-key objects (much more readable than positional tuples)
const result = Iterator.zipKeyed({
  name:  ['Alice', 'Bob',   'Carol'],
  score: [95,      87,      92],
  rank:  [1,       3,       2],
}).toArray();
// [
//   { name: 'Alice', score: 95, rank: 1 },
//   { name: 'Bob',   score: 87, rank: 3 },
//   { name: 'Carol', score: 92, rank: 2 },
// ]

// Chain with Iterator Helpers — find first pair where Alice outscores Bob
const allRounds = Iterator.zipKeyed({ alice: aliceScores, bob: bobScores });
const firstAliceWin = allRounds.find(({ alice, bob }) => alice > bob);
```

**Why it matters:** before `Iterator.zip`, zipping iterables required a manual for loop accumulating an index — and it required materialising both iterables into arrays first if you wanted lazy evaluation. `Iterator.zip` is lazy (stops at shortest by default) and composes with the full Iterator Helpers chain (`.filter()`, `.map()`, `.take()`, etc.).

---

### `Atomics.pause` — Spin-Loop Micro-Wait (Stage 3)

`Atomics.pause(n)` performs a very short CPU-level yield without blocking the thread or relinquishing the core. It is specifically designed for spinlock patterns where a thread polls a shared flag in a tight loop — using it reduces power consumption and improves scheduling behavior compared to a bare `while(true)` loop.

```javascript
// Context: SharedArrayBuffer + Int32Array shared across workers
const sharedBuf  = new SharedArrayBuffer(4);
const lockArray  = new Int32Array(sharedBuf);
// lockArray[0] === 0 means "unlocked"; 1 means "locked"

// Acquire a spinlock with exponential back-off using Atomics.pause
function acquireLock(lockArr, index, maxSpins = 1000) {
  let spins = 0;

  while (true) {
    // Atomically compare-and-swap: only succeeds if current value is 0
    if (Atomics.compareExchange(lockArr, index, 0, 1) === 0) {
      return; // Lock acquired
    }

    // Micro-wait: larger n = slightly longer pause (still nanosecond scale)
    Atomics.pause(spins);

    spins++;
    if (spins >= maxSpins) {
      // Fall back to Atomics.wait (yields the thread entirely, unlike pause)
      Atomics.wait(lockArr, index, 1, 5); // wait up to 5ms
      spins = 0;
    }
  }
}

function releaseLock(lockArr, index) {
  Atomics.store(lockArr, index, 0);   // Release lock
  Atomics.notify(lockArr, index, 1);  // Wake one waiting worker
}

// Worker thread usage
acquireLock(lockArray, 0);
try {
  // Critical section — only one worker executes here at a time
  sharedData.counter++;
} finally {
  releaseLock(lockArray, 0);
}
```

**Key rules:**
- `Atomics.pause` can run on the **main thread** (unlike `Atomics.wait`, which is main-thread-forbidden in browsers).
- The argument `n` is advisory — the engine interprets it as "relative pause duration"; `0` is the shortest hint.
- Only use this when you need actual shared-memory synchronisation via `SharedArrayBuffer`. If you don't have `SharedArrayBuffer`, you don't need `Atomics.pause`.

---

### `import source` — Source Phase Imports (Stage 3)

Source phase imports load a module's source representation without executing it. The primary use case is WebAssembly: `import source Foo from './foo.wasm'` returns a `WebAssembly.Module` you can instantiate with custom imports — without the awkward `fetch` + `WebAssembly.instantiateStreaming` ceremony.

```javascript
// ── WebAssembly integration (primary use case) ────────────────────────
import source FooModule from './foo.wasm';
// FooModule is a WebAssembly.Module — not yet instantiated

const instance = await WebAssembly.instantiate(FooModule, {
  env: { memory: new WebAssembly.Memory({ initial: 1 }) },
  wasi_snapshot_preview1: wasi.wasiImport,
});
instance.exports.main();

// ── Compare with the old fetch approach ──────────────────────────────
// Before: manual fetch + compile + instantiate (3 steps)
const response = await fetch('./foo.wasm');
const module   = await WebAssembly.compileStreaming(response);
const inst     = await WebAssembly.instantiate(module, imports);

// After: static source import (1 line; statically analysable by bundlers)
import source FooModule from './foo.wasm';
const inst = await WebAssembly.instantiate(FooModule, imports);

// ── Dynamic form ─────────────────────────────────────────────────────
// Dynamic source import — deferred, returns AbstractModuleSource
const mod = await import.source('./heavy.wasm');

// ── Security benefit: CSP + static analysis ──────────────────────────
// Bundlers and CSP can track source imports statically — impossible with
// dynamic fetch() calls that construct URLs at runtime.
```

**Comparison table:**

| | `import foo` | `import defer * as foo` | `import source foo` |
|---|---|---|---|
| Load from network | Parse time | Parse time | Parse time |
| Module execution | Immediately | On first access | Never (source only) |
| Returns | Bindings | Namespace | `AbstractModuleSource` |
| Main use case | Normal modules | Deferred init | Wasm, custom instantiation |
| Works in browsers | ✅ | Stage 3 | Stage 3 |

**Limitation:** Only the default import form is supported (`import source x from '...'`). Named imports and unbound declarations are not supported.

---

### Decorator Metadata (`Symbol.metadata`) — Stage 3

The Decorator Metadata proposal extends Stage 3 Decorators with a shared `metadata` object available in every decorator's context. After class definition completes, the metadata is frozen onto `ClassName[Symbol.metadata]`, making it available for runtime introspection by frameworks.

```javascript
// Metadata decorator factory — attaches key/value to any decorated element
function meta(key, value) {
  return (_, context) => {
    context.metadata[key] = value;
  };
}

// Class and method metadata in one pass
@meta('route', '/users')
@meta('auth',  'required')
class UserController {
  @meta('method', 'GET')
  @meta('path',   '/:id')
  getUser(id) { /* ... */ }
}

UserController[Symbol.metadata].route;  // '/users'
UserController[Symbol.metadata].auth;   // 'required'
UserController[Symbol.metadata].method; // 'GET' (from method decorator)

// Framework-style: validation metadata for serialization
function validate(schema) {
  return (_, { metadata, name }) => {
    metadata.validators ??= {};
    metadata.validators[name] = schema;
  };
}

class CreateUserDto {
  @validate({ type: 'string', minLength: 1, maxLength: 50 })
  name;

  @validate({ type: 'string', format: 'email' })
  email;

  @validate({ type: 'integer', minimum: 0, maximum: 150 })
  age;
}

// Validator runtime reads metadata without knowing about the class
function validateDto(dto) {
  const validators = dto.constructor[Symbol.metadata]?.validators ?? {};
  const errors = [];
  for (const [field, schema] of Object.entries(validators)) {
    const value = dto[field];
    if (schema.type === 'string' && typeof value !== 'string') {
      errors.push(`${field}: expected string`);
    }
    if (schema.minLength && value.length < schema.minLength) {
      errors.push(`${field}: too short`);
    }
    // ... additional schema checks
  }
  return errors;
}

// Inheritance — child class inherits parent metadata via prototype chain
class AdminDto extends CreateUserDto {
  @validate({ type: 'string', enum: ['superadmin', 'moderator'] })
  adminRole;
}
// AdminDto[Symbol.metadata] inherits CreateUserDto's validators and adds adminRole
```

**Key differences from framework-level metadata approaches:**
- `reflect-metadata` (used by Angular, NestJS, TypeORM) is a third-party polyfill that monkey-patches `Reflect`. `Symbol.metadata` is built into the language spec.
- Metadata is stored per-class, not per-instance — it's for schema/type information, not per-object state.
- Inheritance is prototype-chain based: child class metadata shadows (not replaces) parent metadata.

**Community signal [community]:** Do not use `Symbol.metadata` with `reflect-metadata` simultaneously — the two metadata systems are independent and will produce confusing double-registration. NestJS and Angular have migration timelines to adopt `Symbol.metadata`; check your framework's docs before combining.

---

## ES2025 / ES2026 Additions

### RegExp Inline Modifiers — Per-Group Flag Control (ES2025 / Baseline September 2025)

RegExp inline modifiers (`(?flags:pattern)`) let you enable or disable the `i`, `m`, or `s` flags for a specific part of a pattern without applying them globally. This solves the longstanding problem of needing case-insensitive matching in one part of a pattern but case-sensitive matching in another.

```javascript
// ── Selective case-insensitivity ─────────────────────────────────────
// Match a keyword case-sensitively but the identifier case-insensitively
const pattern = /(?:var|let|const) (?i:myVar)\b/;
pattern.test('let myVar');   // true  — keyword lowercase, identifier any case
pattern.test('let MYVAR');   // true  — identifier matched case-insensitively
pattern.test('Let myVar');   // false — keyword must be lowercase

// ── Practical: date parser accepting multiple formats ─────────────────
// ISO: 2026-05-12 or US: 05/12/2026 — year captured either way
const DATE = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})|(?<month>\d{2})\/(?<day>\d{2})\/(?<year>\d{4})/;
// (Note: duplicate named groups require ES2025 — covered in next section)

// ── dotAll in one group only ──────────────────────────────────────────
// Match a header block strictly (. doesn't cross lines) then
// match the body loosely (. crosses lines via s modifier)
const MARKDOWN = /^# (?<title>[^\n]+)\n(?s:(?<body>.+))$/m;
const text = `# Title\nbody line 1\nbody line 2`;
const m = text.match(MARKDOWN);
// m.groups.title = 'Title'
// m.groups.body  = 'body line 1\nbody line 2'

// ── Disabling a globally-set flag in one subgroup ─────────────────────
// Pattern has the global 's' (dotAll) flag but one group should NOT match newlines
const STRICT = /(?-s:^HEADER$).*/s;
```

**Supported flags in modifiers:** `i` (case-insensitive), `m` (multiline), `s` (dotAll). The `g`, `y`, `d`, `u`, `v` flags cannot be used inline.

**Syntax rules:**
- `(?i:...)` — enable flag(s)
- `(?-i:...)` — disable flag(s)
- `(?i-m:...)` — enable `i`, disable `m`
- Only the *bounded* form (pattern inside the group) is supported; `(?i)pattern` is a syntax error in JS.

### Duplicate Named Capture Groups — Same Name in Regex Alternatives (ES2025)

ES2025 relaxes the restriction on duplicate named capturing groups when they appear in separate alternatives of a disjunction. Before ES2025, reusing a group name in the same pattern was always a `SyntaxError`. Now, if only one alternative can match, two branches may share a name — unifying the result under a single `.groups.name` key.

```javascript
// Before ES2025 — you had to use different names and merge them at runtime
const OLD = /(?<yearFirst>\d{4})-\d{2}-\d{2}|\d{2}-\d{2}-(?<yearLast>\d{4})/;
const m1 = '2026-05-12'.match(OLD);
const year1 = m1.groups.yearFirst ?? m1.groups.yearLast; // manual merge

// ES2025 — same group name in each alternative
const NEW = /(?<year>\d{4})-\d{2}-\d{2}|\d{2}-\d{2}-(?<year>\d{4})/;
const m2 = '2026-05-12'.match(NEW);
m2.groups.year; // '2026' — unified, no manual merge needed

const m3 = '12-05-2026'.match(NEW);
m3.groups.year; // '2026' — from the second alternative

// Practical: flexible date-of-birth parsing (multiple regional formats)
const DOB = /(?<year>\d{4})[-/](?<month>\d{2})[-/](?<day>\d{2})|(?<day>\d{2})[-/](?<month>\d{2})[-/](?<year>\d{4})/;
function parseDOB(input) {
  const { year, month, day } = input.match(DOB)?.groups ?? {};
  if (!year) throw new Error(`Unrecognised date: ${input}`);
  return new Date(`${year}-${month}-${day}`);
}
parseDOB('2000-01-15'); // ISO
parseDOB('15/01/2000'); // UK day-first

// ── Gotcha: unmatched groups are still present (as undefined) ─────────
const m4 = /(?<ab>ab)|(?<cd>cd)/.exec('cd');
m4.groups;
// { ab: undefined, cd: 'cd' } — both keys present; only matched one is non-undefined
// Check: m4.groups.ab !== undefined, not just truthiness (empty string would be falsy)
```

**Rule:** both duplicate group names must appear in alternatives separated by `|` — they cannot be in the same sequential branch. The spec guarantees only one can match for any input.

### Map.getOrInsert / Map.getOrInsertComputed — Upsert Pattern (ES2026 / Baseline February 2026)

`Map.prototype.getOrInsert(key, defaultValue)` returns the existing value for `key`, or inserts `defaultValue` and returns it. `getOrInsertComputed(key, callbackFn)` is the lazy variant — `callbackFn` is called only when the key is absent, avoiding unnecessary computation for expensive defaults.

```javascript
// ── Problem: the multimap pattern (pre-ES2026) ────────────────────────
const map = new Map();

// Old way — verbose; requires two lookups + branch
function addToGroup(map, key, value) {
  if (!map.has(key)) {
    map.set(key, []);
  }
  map.get(key).push(value);
}

// ── New way: getOrInsert ──────────────────────────────────────────────
function addToGroupNew(map, key, value) {
  map.getOrInsert(key, []).push(value);
  // Single atomic operation: get existing array, or create and store a new one
}

const groups = new Map();
addToGroupNew(groups, 'frontend', 'Alice');
addToGroupNew(groups, 'backend',  'Bob');
addToGroupNew(groups, 'frontend', 'Carol');
// Map { 'frontend' => ['Alice', 'Carol'], 'backend' => ['Bob'] }

// ── getOrInsertComputed — only compute if key is missing ──────────────
const cache = new Map();

// Expensive computation only runs on cache miss
function cachedQuery(id) {
  return cache.getOrInsertComputed(id, (key) => {
    console.log(`Cache miss for ${key}`);
    return fetchExpensiveData(key); // hypothetical
  });
}

// ── Default configuration / option merging ───────────────────────────
const options = new Map(Object.entries(userConfig));
options.getOrInsert('theme',    'light');  // set only if absent
options.getOrInsert('fontSize', 14);
options.getOrInsert('lang',     'en-US');

// ── Counting occurrences — classic use case ──────────────────────────
const wordCount = new Map();
for (const word of text.split(/\s+/)) {
  wordCount.getOrInsert(word, 0);          // ensure key exists with 0
  wordCount.set(word, wordCount.get(word) + 1);
}
// Or with a counter object and getOrInsertComputed:
const counters = new Map();
const inc = (key) => {
  const counter = counters.getOrInsertComputed(key, () => ({ count: 0 }));
  counter.count++;
};
```

**Why `getOrInsert` beats `map.get(key) ?? defaultValue`:** `??` always evaluates `defaultValue` eagerly; it also doesn't store the default back into the map, requiring a manual `map.set()`. `getOrInsert` is a single atomic read-or-write with one lookup.

**Availability:** Baseline February 2026 — Chrome 131, Firefox 134, Safari 18.2, Node.js 24. Polyfill: `map.prototype.getorinsert` on npm (es-shims).

### JSON.parse with Source Text Access — Lossless Number Parsing (ES2025)

The `reviver` function in `JSON.parse` now receives a third `context` parameter with a `source` property: the raw JSON source string for the value being revived. This solves the longstanding problem of JavaScript silently losing precision when parsing JSON numbers that exceed `Number.MAX_SAFE_INTEGER` (2^53 − 1).

```javascript
// ── The problem: JSON.parse silently corrupts large numbers ───────────
const json = '{"tweetId": 1800000000000000001}';
JSON.parse(json).tweetId; // 1800000000000000000 — wrong! precision lost

// ── ES2025 solution: read the raw source before JS converts it ────────
const parsed = JSON.parse(json, (key, value, context) => {
  // context.source is the raw JSON text for this value (only for primitives)
  if (typeof value === 'number' && !Number.isSafeInteger(value)) {
    return BigInt(context.source); // parse raw text as BigInt instead
  }
  return value;
});
parsed.tweetId; // 1800000000000000001n — exact! No precision lost

// ── Parse ALL numbers as BigInt (for financial/ID-heavy APIs) ────────
function parseJSONExact(jsonString) {
  return JSON.parse(jsonString, (key, value, context) => {
    if (typeof value === 'number' && context?.source !== undefined) {
      const src = context.source;
      // Use BigInt for integers, keep Number for floats
      if (/^-?\d+$/.test(src)) return BigInt(src);
    }
    return value;
  });
}
parseJSONExact('{"id": 9999999999999999999, "score": 98.6}');
// { id: 9999999999999999999n, score: 98.6 }

// ── Use case: Decimal string preservation ────────────────────────────
// Financial APIs often send money as strings to avoid float issues,
// but some send raw numbers. With context.source, you can detect overflow:
function safeMoneyReviver(key, value, context) {
  if (key.endsWith('Amount') || key.endsWith('Price')) {
    if (context?.source && !context.source.includes('.')) {
      return BigInt(context.source); // integer money value — use BigInt
    }
    // Float money value — warn and use a decimal library
  }
  return value;
}

// ── context is only passed for primitives, not objects/arrays ─────────
JSON.parse('{"a": 1}', (key, value, context) => {
  if (key === '') console.log(context); // undefined — root object has no source
  if (key === 'a') console.log(context.source); // '1'
  return value;
});
```

**When `context` is provided:** only when reviving a primitive value (number, string, boolean, null). Arrays and objects don't get `context` — their primitives do.

---

## Additional Language Idioms (2026)

### `node:` Protocol Prefix for Built-in Imports [community]

Since Node.js 14.18+ / 16+, you can prefix built-in module specifiers with `node:`. This is now the **recommended pattern** and is enforced by many linters. It makes it unambiguous that the import is a Node.js built-in (not an npm package with the same name) and provides a stable path forward as the Node.js module system evolves.

```javascript
// ❌ Old style — ambiguous; a malicious npm package named 'path' could shadow this
import path from 'path';
import { readFile } from 'fs/promises';
const { createServer } = require('http');

// ✅ New style — explicit, unambiguous, lint-friendly
import path from 'node:path';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { pipeline } from 'node:stream/promises';
import { webcrypto } from 'node:crypto';
import { Worker, isMainThread } from 'node:worker_threads';
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

// ESLint rule to enforce this:
// "n/prefer-node-protocol": "error"  (from eslint-plugin-n)
```

**Why it matters:** a package named `events`, `path`, or `http` on npm can shadow the built-in when you use bare specifiers. The `node:` prefix is immune to this shadowing. It also makes `import` / `require` origin instantly readable in code review.

---

## Additional Community Pitfalls (2026)

**37. Parsing Large JSON Numbers Without `context.source`** [community] — Using `JSON.parse` directly on API responses containing 64-bit integer IDs (Twitter/X snowflakes, database BIGINT PKs, financial amounts) silently truncates numbers above 2^53 − 1. WHY it causes problems: the truncated ID is used for subsequent API calls that return "not found" errors, or worse, accidentally matches a different record at a truncated boundary. Fix: use `JSON.parse(text, (key, value, context) => typeof value === 'number' && !Number.isSafeInteger(value) ? BigInt(context.source) : value)` to intercept overflow numbers before JS truncates them.

**38. Not Using the `node:` Prefix for Built-in Imports** [community] — Using bare specifiers (`import from 'path'`, `require('events')`) instead of `node:path` and `node:events` leaves code vulnerable to npm package shadowing attacks. WHY it causes problems: an attacker who can place a package named `http` or `path` in your dependency tree (via a transitive dependency) could silently replace the Node.js built-in with malicious code. The `node:` prefix is the only way to guarantee the built-in is loaded. Fix: migrate all built-in imports to use the `node:` protocol prefix; enable `n/prefer-node-protocol` in ESLint.

**39. Accessing `context.source` in Non-Primitive Reviver Calls** [community] — The `context.source` property is only provided when the reviver is called for a primitive value (number, string, boolean, null). When the reviver is called for an object or array key, `context` is `undefined`. WHY it causes problems: developers write a reviver that accesses `context.source` without checking `typeof context !== 'undefined'`, then get a TypeError when the reviver fires for an object-valued key. Fix: always guard: `if (context?.source !== undefined)` before accessing `source`.

**40. Using Duplicate Named Capture Groups Without Checking the Matched Alternative** [community] — ES2025 allows the same capture group name in different regex alternatives, but unmatched alternatives still populate `groups` with `undefined`. WHY it causes problems: code checks `if (match.groups.year)` and incorrectly treats an empty-string match `''` (falsy) as a non-match, or iterates over `Object.entries(match.groups)` and processes `undefined` values as if they were matches. Fix: use `!== undefined` for presence checks (`match.groups.year !== undefined`), not truthiness, since a matched group can legitimately be an empty string.

**41. Calling `getOrInsert` with a Mutable Default Without `getOrInsertComputed`** [community] — Calling `map.getOrInsert(key, [])` creates a new empty array every time, even on cache hits. The unnecessary allocation is trivial for sparse maps, but in hot loops over millions of keys it adds GC pressure. WHY it causes problems: while `getOrInsert` doesn't use the default value on a hit, the `[]` literal is still allocated before being passed in — unlike `getOrInsertComputed` which passes a factory that is only called on a miss. Fix: use `map.getOrInsertComputed(key, () => [])` for any default value whose construction is non-trivial (large objects, arrays, result of expensive computation).

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
| `btoa(String.fromCharCode(...bytes))` for large buffers | Stack overflow on buffers > ~65 k bytes; silent failure on non-ASCII input | Use `Uint8Array.toBase64()` / `Uint8Array.fromBase64()` (Baseline 2025) |
| Legacy `experimentalDecorators` mixed with Stage 3 decorators | Two incompatible decorator semantics in one project; Angular/NestJS migrations break | Decide on one: Stage 3 (TS 5.0+ with `"experimentalDecorators": false`) or legacy; never mix |
| `import defer` named/default imports | Syntax error — only namespace import (`* as`) is supported | Use `import defer * as name from '...'`; for named access use `name.export` |
| `Math.sumPrecise` for `0.1 + 0.2 === 0.3` | sumPrecise sums IEEE 754 values precisely, but 0.1 and 0.2 are already imprecise; result is still 0.30000000000000004 | Use a decimal library (decimal.js, big.js) for base-10 precision; sumPrecise solves magnitude-cancellation, not representation |
| `Iterator.zip` with iterables of different lengths without a mode | Stops at shortest silently (default `"shortest"` mode); data from longer iterables is dropped without warning | Pass `{ mode: 'strict' }` to throw if lengths differ, or `{ mode: 'longest' }` to pad with `undefined` |
| `Atomics.pause` outside SharedArrayBuffer spinlock patterns | Using `Atomics.pause` in code that doesn't have concurrent workers sharing memory provides no benefit and obscures intent | Only use `Atomics.pause` inside tight spinlock loops on `Int32Array` backed by `SharedArrayBuffer` |
| `import source` named imports | Syntax error — only default import form is supported | Use `import source Foo from './foo.wasm'`; access exports via the instantiated instance |
| Mixing `reflect-metadata` with `Symbol.metadata` | Two independent metadata systems — double-registration and confusing reads | Pick one; check your framework's migration guide before combining both |
| `JSON.parse` on responses with 64-bit integer IDs | Numbers above 2^53−1 are silently truncated — wrong IDs used for subsequent calls | Use `reviver` with `context.source` to parse as `BigInt` before JS truncates |
| Bare specifiers for Node.js built-ins (`'path'`, `'fs'`) | Vulnerable to npm package shadowing attacks; dependency hijack possible | Always use `node:` prefix: `import from 'node:path'`, `node:fs/promises` |
| Duplicate named regex groups without `!== undefined` checks | Unmatched alternatives set groups to `undefined`; falsy check misidentifies empty-string match | Use `match.groups.year !== undefined` — empty string `''` is a valid match |
| `map.getOrInsert(key, [])` in hot loops | `[]` is allocated every call even on cache hits; adds GC pressure in tight loops | Use `map.getOrInsertComputed(key, () => [])` — factory only called on cache miss |
| `(?i)pattern` unbounded modifier syntax | JavaScript only supports bounded form `(?i:pattern)`; unbounded form is a SyntaxError | Always use `(?i:subpattern)` to scope the modifier to the intended portion |

---

## Faker.js — Realistic Fake Test Data

Faker.js generates realistic fake data for testing — names, emails, addresses, dates, UUIDs, product data, and much more. It replaces hard-coded strings like `"test@test.com"` with statistically realistic values that catch format-assumption bugs.

**Install:** `npm install --save-dev @faker-js/faker` (requires Node 20+; also runs in the browser).

### Basic Usage

```javascript
import { faker } from '@faker-js/faker';

// Each call produces a new random value
const name     = faker.person.fullName();       // "Raquel Jacobson"
const email    = faker.internet.email();         // "raquel.jacobson@gmail.com"
const uuid     = faker.string.uuid();            // "110ec58a-a0f4-4ac4-8ec2-c5b67b6e8a1e"
const price    = faker.commerce.price({ min: 1, max: 500, dec: 2 }); // "142.78"
const pastDate = faker.date.past({ years: 2 }); // Date object — ~2 years ago

// Build a full fake user record
function buildUser(overrides = {}) {
  return {
    id:        faker.string.uuid(),
    firstName: faker.person.firstName(),
    lastName:  faker.person.lastName(),
    email:     faker.internet.email(),
    phone:     faker.phone.number(),
    birthDate: faker.date.birthdate({ min: 18, max: 70, mode: 'age' }),
    address: {
      street: faker.location.streetAddress(),
      city:   faker.location.city(),
      state:  faker.location.state({ abbreviated: true }),
      zip:    faker.location.zipCode(),
    },
    ...overrides,    // caller can pin specific fields
  };
}

const user = buildUser({ email: 'fixed@example.com' });
```

### Seeding for Reproducible Tests

Use a seed to produce the same sequence of values on every run — essential for snapshot tests and CI consistency:

```javascript
import { faker } from '@faker-js/faker';

// Set seed once per test suite (or per test for full isolation)
faker.seed(42);

const user1 = faker.person.fullName(); // always "Ida Tromp" with seed 42
const user2 = faker.person.fullName(); // always "Grady Larkin"

// Per-test seeding pattern (Jest/Vitest)
beforeEach(() => {
  faker.seed(12345);
});

test('renders user card', () => {
  const user = buildUser();   // deterministic — same every time
  render(<UserCard user={user} />);
  expect(screen.getByText(user.firstName)).toBeInTheDocument();
});
```

### Locales

Faker.js ships with 70+ locale-specific datasets. Locale determines names, addresses, phone formats, etc.:

```javascript
import { fakerDE as faker } from '@faker-js/faker';   // German locale
const name = faker.person.fullName();  // "Friedrich Becker"

import { fakerJA as faker } from '@faker-js/faker';   // Japanese
const name = faker.person.fullName();  // "田中 一郎"

// Or switch locale on a shared instance
faker.locale = 'fr';
const city = faker.location.city();    // "Lyon", "Marseille", ...
```

### Key Module Categories

| Module | Example Methods |
|---|---|
| `faker.person` | `firstName()`, `lastName()`, `fullName()`, `jobTitle()`, `gender()` |
| `faker.internet` | `email()`, `url()`, `userName()`, `domainName()`, `password()`, `ipv4()` |
| `faker.location` | `streetAddress()`, `city()`, `state()`, `country()`, `zipCode()`, `latitude/longitude()` |
| `faker.date` | `past()`, `future()`, `recent()`, `birthdate()`, `between()` |
| `faker.number` | `int()`, `float()`, `bigInt()`, `binary()`, `hex()` |
| `faker.string` | `uuid()`, `alphanumeric()`, `nanoid()`, `fromCharacters()` |
| `faker.commerce` | `productName()`, `price()`, `department()`, `productDescription()` |
| `faker.lorem` | `word()`, `sentence()`, `paragraph()`, `lines()` |
| `faker.image` | `url()`, `avatar()`, `personPortrait()` |
| `faker.helpers` | `arrayElement()`, `shuffle()`, `multiple()`, `fake()` (template strings) |

### `faker.helpers` Patterns

```javascript
// Pick a random element from an array
const status = faker.helpers.arrayElement(['active', 'inactive', 'pending']);

// Build N records
const users = faker.helpers.multiple(buildUser, { count: 50 });

// Shuffle and pick N
const tags   = faker.helpers.shuffle(['web', 'api', 'mobile', 'cli', 'data']);
const subset = tags.slice(0, faker.number.int({ min: 1, max: 3 }));

// Template string interpolation
const sentence = faker.helpers.fake('Hello {{person.firstName}}! Your code is {{string.alphanumeric(6)}}.');
// "Hello Raquel! Your code is aB3x9Z."
```

### Factory Function Pattern (Zero Dependencies)

Combine Faker with a factory function to produce test objects with sane defaults and per-test overrides — no external library needed:

```javascript
// factories/userFactory.js
import { faker } from '@faker-js/faker';

export const createUser = (overrides = {}) => ({
  id:        faker.string.uuid(),
  name:      faker.person.fullName(),
  email:     faker.internet.email(),
  role:      'user',
  createdAt: faker.date.recent({ days: 30 }),
  ...overrides,
});

export const createAdmin = (overrides = {}) =>
  createUser({ role: 'admin', ...overrides });

// In tests
const user     = createUser();
const admin    = createAdmin({ email: 'ceo@acme.com' });
const inactive = createUser({ role: 'inactive', createdAt: faker.date.past({ years: 2 }) });
```

### Faker.js Anti-Patterns

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| Hard-coding test data strings (`"test@test.com"`) | Misses format-assumption bugs; tests pass for the wrong reasons | Use `faker.internet.email()` to generate realistic, varied values |
| No seed for snapshot tests | Different values each run make snapshots brittle | Call `faker.seed(42)` in `beforeEach` for reproducible snapshots |
| Generating data inside describe() / module scope | Data generated once at import time; no per-test isolation | Generate inside `beforeEach` or inside the test function |
| `faker.internet.email()` for security-sensitive ids | Email format not globally unique across test runs | Use `faker.string.uuid()` for unique IDs |
| Using locale-sensitive data without locale set | Default (en) names/addresses fail locale-specific format validations | Set `faker.locale` to match the domain under test |
| Building large object graphs with Faker inline | Tests become cluttered and hard to read | Extract into a `factories/` directory with composable factory functions |

---

## Node.js Platform Features (v22–v24)

### `require()` of Synchronous ESM — Node.js 22+ (Stable in v23+)

Node.js 22 introduced (as experimental) and Node.js 23 enabled by default the ability to `require()` ES modules from CommonJS, as long as the ESM file has no top-level `await`. This finally bridges the gap for gradual CJS→ESM migrations.

```javascript
// ── Before Node.js 22: ERR_REQUIRE_ESM every time ────────────────────
// const { greet } = require('./greeter.mjs'); // throws ERR_REQUIRE_ESM

// ── Node.js 22 (with flag) / Node.js 23+ (default) ───────────────────
// greeter.mjs — synchronous ESM (no top-level await)
export function greet(name) {
  return `Hello, ${name}!`;
}

// index.cjs — CJS file requiring the synchronous ESM module
const { greet } = require('./greeter.mjs');
console.log(greet('World')); // "Hello, World!"

// ── Check at runtime whether require(ESM) is supported ───────────────
if (process.features.require_module) {
  console.log('require(esm) is available — Node.js 22+');
}

// ── STILL THROWS: ESM with top-level await cannot be required ─────────
// async-mod.mjs:  export const data = await fetch('https://...');
// const { data } = require('./async-mod.mjs'); // ERR_REQUIRE_ASYNC_MODULE

// ── Dual-package pattern: "module-sync" exports condition ─────────────
// package.json — support both require() and import with the same ESM source
// {
//   "exports": {
//     ".": {
//       "module-sync": "./index.mjs",  // CJS require() of ESM — sync only
//       "import":      "./index.mjs",  // Native ESM import
//       "require":     "./index.cjs"   // CJS fallback for older Node.js
//     }
//   }
// }
```

**Key rules:**
- Enabled by default in Node.js 23+; use `--no-experimental-require-module` to opt out.
- Only works if the ESM module (and all of its ESM dependencies) is fully synchronous.
- Returns the ESM namespace object — same as dynamic `import()` but synchronous.
- The `module-sync` exports condition (Node.js 22+) lets packages expose one ESM file for both `require()` and `import` paths.

### `fs.glob` and `fs.globSync` — Built-in Glob API (Node.js 22+)

Node.js 22 ships `fs.glob` and `fs.globSync` in `node:fs`. No more `glob` or `fast-glob` npm packages for standard file discovery.

```javascript
import { glob, globSync } from 'node:fs';
import { glob as globPromise } from 'node:fs/promises';

// Async callback style
glob('src/**/*.test.js', (err, files) => {
  if (err) throw err;
  console.log(files); // ['src/auth/auth.test.js', 'src/users/users.test.js', ...]
});

// Promise style (node:fs/promises)
const testFiles = await globPromise('**/*.spec.{js,ts}', {
  cwd: '/project/src',
  exclude: (entry) => entry.name.startsWith('_'), // filter function
});

// Sync — useful in config files / scripts
const configs = globSync('**/.eslintrc.*');

// Glob with exclude patterns
const srcFiles = await globPromise('src/**/*.js', {
  exclude: (entry) => entry.name.includes('.min.'),
});
```

**Limitations vs. npm `fast-glob`:** `node:fs/promises glob` does not support negation patterns (e.g., `!**/*.test.js`) or `ignore` string arrays (only an `exclude` callback). Use `fast-glob` when you need full negation and ignore-glob syntax; use `node:fs` glob for simple project tooling scripts.

### `path.matchGlob()` — Single-Path Glob Test (Node.js 23+)

`path.matchGlob(path, pattern)` tests whether a single path string matches a glob pattern. It replaces `minimatch` for simple yes/no glob checks without iterating a directory.

```javascript
import { matchGlob } from 'node:path';

// Basic matching
matchGlob('src/index.js', '**/*.js');          // true
matchGlob('src/index.test.js', '**/*.js');     // true
matchGlob('src/index.ts', '**/*.js');          // false

// File filter in a build pipeline
const sourceFiles = files.filter(f => matchGlob(f, 'src/**/*.js'));
const testFiles   = files.filter(f => matchGlob(f, '**/*.{test,spec}.js'));

// Works with absolute paths (match from the path's own components)
matchGlob('/home/user/project/src/app.js', '**/src/**/*.js'); // true
```

### `v8.queryObjects()` — Memory Leak Regression Testing (Node.js 22+)

`v8.queryObjects(constructor)` counts live instances of a class, enabling heap regression tests without a full profiler. Use it to verify that objects are collected after expected lifecycle events.

```javascript
import { queryObjects } from 'node:v8';

class Request {
  constructor(url) { this.url = url; }
}

const r1 = new Request('/api/users');
const r2 = new Request('/api/posts');

// Count all live instances (forces GC before counting)
console.log(queryObjects(Request, { format: 'count' }));   // 2

// Get summaries for inspection
console.log(queryObjects(Request, { format: 'summary' }));
// [ "Request { url: '/api/users' }", "Request { url: '/api/posts' }" ]

// ── Test pattern: assert no leaks after cleanup ──────────────────────
async function test_requestsCollectedAfterHandler() {
  let handler = createRequestHandler();
  handler.process(new Request('/api/test'));
  handler = null; // drop the reference

  // Force GC (requires --expose-gc flag or test framework integration)
  if (global.gc) global.gc();

  const leaks = queryObjects(Request, { format: 'count' });
  console.assert(leaks === 0, `Leaked ${leaks} Request instances`);
}
```

**Important notes:**
- `queryObjects` triggers a full GC before counting — don't call it in hot paths.
- Only counts instances created after the last GC. In practice, run it at the end of a test after dropping all references.
- Requires `node:v8` (not V8 the global). Available in Node.js 22+.
- Child-class instances are counted in the parent class query (prototype chain).

### `SuppressedError` — Error Chains in `using` Blocks (ES2025)

When a `using` block exits with an error AND a disposer also throws, JavaScript wraps both into a `SuppressedError`. Unlike `AggregateError` (parallel errors), `SuppressedError` represents a sequential chain: a cleanup error that happened while handling an original error.

```javascript
// Structure of SuppressedError:
// SuppressedError {
//   error:      // the error from the disposer (what happened during cleanup)
//   suppressed: // the original error (what caused the block to exit)
//   message:    // "An error was suppressed during disposal"
// }

class BrokenConnection {
  [Symbol.dispose]() {
    throw new Error('close() failed: connection already dead');
  }
}

try {
  using conn = new BrokenConnection();
  throw new Error('query failed: timeout');    // original error
  // conn[Symbol.dispose]() throws during cleanup
} catch (e) {
  if (e instanceof SuppressedError) {
    // Cleanup error (what happened during disposal)
    console.error('Cleanup error:', e.error.message);
    // "close() failed: connection already dead"

    // Original error (what caused the using block to exit)
    console.error('Original error:', e.suppressed.message);
    // "query failed: timeout"
  }
}

// Multiple nested using with multiple disposer errors chains recursively:
// SuppressedError {
//   error: Error("disposer 1 failed"),
//   suppressed: SuppressedError {
//     error: Error("disposer 2 failed"),
//     suppressed: Error("original trigger error")
//   }
// }

// Helper to extract the root cause of a SuppressedError chain
function getRootCause(err) {
  while (err instanceof SuppressedError) {
    err = err.suppressed;
  }
  return err;
}

function getAllDisposalErrors(err, acc = []) {
  if (!(err instanceof SuppressedError)) return acc;
  acc.push(err.error);
  return getAllDisposalErrors(err.suppressed, acc);
}
```

**Why this matters over `try-finally`:** with `try-finally`, if `finally` throws it silently replaces the original error. `SuppressedError` preserves both — the original error and every cleanup error in the chain — ensuring nothing is lost during debugging.

### `node --run` — Run package.json Scripts Without npm (Node.js 22+ stable in v23)

`node --run <script>` executes a script from `package.json` directly without spawning npm or another package manager. It's measurably faster because it skips the npm CLI startup overhead.

```bash
# Equivalent to: npm run build
node --run build

# Equivalent to: npm run test
node --run test

# Works in CI — no npm bootstrap needed if Node.js is already available
```

```javascript
// package.json
{
  "scripts": {
    "build": "esbuild src/index.ts --bundle --outfile=dist/index.js",
    "test":  "node --test",
    "lint":  "eslint src/"
  }
}
```

**Differences from `npm run`:**
- Only runs exactly one script — no pre/post hooks (`pretest`, `postbuild`).
- Does NOT add `node_modules/.bin` to PATH automatically (use full paths or `npx` for that).
- Useful in Docker-based CI layers or scripts that know Node.js is available but want lighter startup.

---

## Additional Community Pitfalls (Node.js Platform)

**42. `require(ESM)` Still Fails for Modules with Top-Level `await`** [community] — Node.js 22/23's new `require(esm)` capability is limited to *synchronous* ESM modules. If any file in the imported graph uses `export const x = await fetch(...)` or any other top-level `await`, `require()` throws `ERR_REQUIRE_ASYNC_MODULE`. WHY it causes problems: a CJS→ESM migration that works locally on simple modules silently breaks when the imported ESM transitively depends on a module that uses top-level await (common in config loaders, DB connection pools, etc.). Fix: audit the full import graph for top-level `await`; use dynamic `import()` for any async ESM.

**43. `url.parse()` Removed in Node.js 24** [community] — `url.parse(urlString)` is removed in Node.js 24 (runtime-deprecated since Node.js 11, EOL since Node.js 22). WHY it causes problems: code that worked fine on Node.js 22 LTS throws `TypeError: url.parse is not a function` when upgraded to Node.js 24, often in legacy middleware or older npm packages. Fix: replace all uses with `new URL(urlString)` (WHATWG URL API); for relative URLs, use `new URL(path, base)`.

```javascript
// REMOVED in Node.js 24 — do not use
const parsed = require('url').parse('https://example.com/path?q=1');
parsed.hostname; // 'example.com'
parsed.query;    // 'q=1' (string, not object)

// REPLACEMENT — WHATWG URL API (works in Node.js 10+, all browsers)
const url = new URL('https://example.com/path?q=1');
url.hostname;                    // 'example.com'
url.searchParams.get('q');       // '1' (proper typed access)
```

**44. `v8.queryObjects` Counts Child-Class Instances in Parent Queries** [community] — Calling `queryObjects(ParentClass)` returns instances of `ParentClass` AND all subclasses, because the query uses the prototype chain. WHY it causes problems: a memory leak test that creates `AdminUser extends User` and checks `queryObjects(User)` counts both `User` and `AdminUser` instances — your baseline count is wrong, making leak detection unreliable. Fix: call `queryObjects` on the specific constructor you want to count, not the base class; compare before/after counts rather than expecting exact totals.

**45. `fs.glob` Exclude Callback vs. String Patterns** [community] — `node:fs` `glob()` accepts an `exclude` *function* (not a glob string). Developers expecting `exclude: ['**/*.test.js']` (like `fast-glob`'s `ignore` array) get a `TypeError` or silently no exclusion. WHY it causes problems: a reasonable assumption based on other glob libraries leads to no files being excluded at all — the error is silent if the `exclude` value is ignored instead of validated. Fix: pass a function: `exclude: (entry) => entry.name.endsWith('.test.js')`; for complex ignore patterns, use `fast-glob` which supports negation globs natively.

---

## Additional Anti-Patterns (Node.js Platform)

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `require('./module.mjs')` on async ESM | Throws `ERR_REQUIRE_ASYNC_MODULE` — top-level `await` blocks synchronous require | Use `await import('./module.mjs')` for any ESM with top-level await |
| `require('url').parse(urlString)` | Removed in Node.js 24; runtime-deprecated since Node.js 11 | Replace with `new URL(urlString)` from the WHATWG URL API |
| `queryObjects(BaseClass)` expecting only base instances | Counts subclasses too due to prototype chain; baseline counts are inflated | Query the specific leaf constructor; compare before/after deltas instead of absolutes |
| `glob(pattern, { exclude: ['**/*.test.js'] })` (array) | `exclude` takes a function, not an array — likely a no-op or TypeError | Use `exclude: (entry) => entry.name.endsWith('.test.js')` |
| Catching `SuppressedError` as a plain `Error` | Only checks `instanceof Error` — misses the cleanup error in `e.error`; original error in `e.suppressed` | Check `e instanceof SuppressedError`; traverse the chain with `getRootCause()` to find the original trigger |

---

## URLPattern — URL Routing Without a Framework (Baseline 2025 / Node.js 24 Global)

`URLPattern` provides express-style URL pattern matching natively in the browser and in Node.js 24+ (where it is a global). No external routing library needed for route matching, middleware guards, or URL extraction. The syntax is based on `path-to-regexp` — the same library Express uses.

```javascript
// ── Basic route matching ──────────────────────────────────────────────
const route = new URLPattern({ pathname: '/users/:id' });

route.test('https://api.example.com/users/42');   // true
route.test('https://api.example.com/users');       // false
route.test('https://api.example.com/users/42/posts'); // false

// exec() returns null or a match object with captured groups
const match = route.exec('https://api.example.com/users/42');
match?.pathname.groups.id; // '42'

// ── Constrain with regex ──────────────────────────────────────────────
// Only numeric IDs
const numericId = new URLPattern({ pathname: '/products/:id(\\d+)' });
numericId.test('https://api.example.com/products/123'); // true
numericId.test('https://api.example.com/products/abc'); // false

// ── Multi-component matching ──────────────────────────────────────────
const fullPattern = new URLPattern({
  protocol: 'https{+}?',                  // http or https
  hostname: '{:subdomain.}?example.com',  // optional subdomain
  pathname: '/api/:version/:resource',
  search: '*',                             // any query string
});

const result = fullPattern.exec('https://v2.example.com/api/v2/users?page=1');
result?.hostname.groups.subdomain;  // 'v2'
result?.pathname.groups.version;    // 'v2'
result?.pathname.groups.resource;   // 'users'

// ── Optional trailing slash ──────────────────────────────────────────
const withSlash = new URLPattern({ pathname: '/docs{/}?' });
withSlash.test('https://example.com/docs');   // true
withSlash.test('https://example.com/docs/');  // true

// ── Case-insensitive matching ─────────────────────────────────────────
const ci = new URLPattern('https://example.com/files/*', { ignoreCase: true });
ci.test('https://example.com/files/README.md'); // true
ci.test('https://example.com/files/readme.md'); // true

// ── Wildcard path capture ─────────────────────────────────────────────
const catchAll = new URLPattern({ pathname: '/docs/:path*' });
catchAll.exec('https://example.com/docs/api/getting-started')
  ?.pathname.groups.path;  // 'api/getting-started'

// ── Service Worker use case — match CDN assets ──────────────────────
// In a service worker, test against request.url to decide caching strategy
const imagePattern = new URLPattern({ hostname: 'cdn-*.example.com', pathname: '/*.{png,jpg,webp}' });
self.addEventListener('fetch', event => {
  if (imagePattern.test(event.request.url)) {
    // Apply cache-first strategy for CDN images
    event.respondWith(cacheFirst(event.request));
  }
});
```

**Key differences from `new URL()` + manual checks:**
- `URLPattern` handles named groups, optional segments, wildcards, and regex constraints declaratively.
- `test()` is O(1) per pattern — no manual string splitting or regex construction.
- Works in Web Workers and Service Workers.

**Node.js 24 note:** `URLPattern` became a global in Node.js 24, so `import { URLPattern } from 'node:url'` is no longer needed — it behaves like `URL` and `URLSearchParams`.

---

## AsyncLocalStorage — Request-Scoped Context Without Prop Drilling

`AsyncLocalStorage` provides thread-local-style storage that flows automatically through `async/await` chains, Promises, `setTimeout`, and `setImmediate`. The canonical use case is request-scoped data (request IDs, user identity, trace spans) that would otherwise require passing a context object through every function call.

```javascript
import { AsyncLocalStorage } from 'node:async_hooks';

// ── Basic setup: one store per concern ───────────────────────────────
const requestContext = new AsyncLocalStorage();

// Middleware: attach a request ID to the context for this request
function requestIdMiddleware(req, res, next) {
  const ctx = { requestId: req.headers['x-request-id'] ?? crypto.randomUUID() };
  requestContext.run(ctx, next);  // 'next' and everything it calls inherits ctx
}

// Deep in a service — no req/ctx parameter needed
function logQuery(sql) {
  const ctx = requestContext.getStore();
  console.log({ requestId: ctx?.requestId, sql });
}

// ── HTTP server example with Express ─────────────────────────────────
import express from 'express';

const app = express();
app.use(requestIdMiddleware);

app.get('/users/:id', async (req, res) => {
  const user = await UserService.findById(req.params.id);
  // logQuery inside findById logs with the request ID automatically
  res.json(user);
});

// ── Multiple stores for different cross-cutting concerns ─────────────
const authStore  = new AsyncLocalStorage(); // who is making the request
const traceStore = new AsyncLocalStorage(); // OpenTelemetry span

// Compose: nest run() calls to layer contexts
authStore.run({ userId: '123', roles: ['admin'] }, () => {
  traceStore.run({ spanId: 'abc', traceId: 'xyz' }, async () => {
    await doWork(); // doWork and its callees see both stores
  });
});

// ── withScope() — disposable store (Node.js v25.9.0+) ────────────────
// Works with 'using' for lexically-scoped context — synchronous sections only
{
  using _ = requestContext.withScope({ requestId: 'test-123' });
  syncProcess();  // sees { requestId: 'test-123' }
  // context automatically reset at end of block
}
// Do NOT use withScope() with await inside the block — scope leaks across awaits
// Use run() for async functions

// ── Nesting: inner run() overrides outer store for that call tree ─────
const outer = { level: 'outer', requestId: 'req-1' };
requestContext.run(outer, async () => {
  // Override just one property for a sub-operation
  const inner = { ...outer, level: 'inner' };
  await requestContext.run(inner, async () => {
    requestContext.getStore().level;  // 'inner'
  });
  requestContext.getStore().level;    // back to 'outer'
});
```

**Production patterns:**
- One `AsyncLocalStorage` per cross-cutting concern (request context, trace, auth) — do not put everything in one store.
- Always use `run()` for async code; reserve `withScope()` for short synchronous blocks.
- In Node.js 24, `AsyncLocalStorage` defaults to `AsyncContextFrame` — measurably more efficient for high-concurrency servers.

**Community gotcha [community]:** `enterWith()` sets the store for the current execution context **and all sibling event handlers registered after it**. Unlike `run()`, which is scoped to a callback, `enterWith()` contaminates unrelated handlers sharing the same event loop tick. Always prefer `run()` unless you explicitly need to transition the ambient context.

---

## Import Attributes — Typed Non-JS Module Imports (Baseline 2025)

Import attributes (`with { type: "json" }`) tell the runtime how a non-JavaScript module should be loaded and parsed. The `type` attribute validates the server-sent MIME type before executing, preventing MIME-confusion attacks where a CDN accidentally serves a different content type.

**Note:** An earlier `assert` keyword was non-standard and removed. Only `with` is standard.

```javascript
// ── JSON modules — typed static import ──────────────────────────────
import config from './config.json' with { type: 'json' };
// config is parsed as JSON — no eval, no side effects
// Fails if server sends Content-Type != application/json

console.log(config.version); // "1.2.0"

// JSON modules have ONLY a default export (no named exports)
// This is a SyntaxError:
// import { version } from './config.json' with { type: 'json' }; // ❌

// ── Dynamic import with attribute ────────────────────────────────────
const data = await import('./data.json', {
  with: { type: 'json' },
});
console.log(data.default); // the JSON content

// ── CSS modules (browser only, Chrome/Safari/Edge) ───────────────────
import styles from './button.css' with { type: 'css' };
// styles is a CSSStyleSheet — can be adopted into shadow DOM or document
document.adoptedStyleSheets.push(styles);

// Component shadow DOM adoption:
class MyButton extends HTMLElement {
  constructor() {
    super();
    const shadow = this.attachShadow({ mode: 'open' });
    shadow.adoptedStyleSheets = [styles];
    shadow.innerHTML = `<button><slot></slot></button>`;
  }
}

// ── Re-export a JSON module ───────────────────────────────────────────
export { default as config } from './config.json' with { type: 'json' };

// ── import.meta.resolve() — resolve without importing ────────────────
// Useful for passing paths to Worker without evaluating the module
const workerURL = import.meta.resolve('./worker.js');
const worker = new Worker(workerURL, { type: 'module' });
```

**Security model:** when the `type` attribute is present and the server returns a mismatched MIME type, the import is rejected with a `TypeError` before any code runs — this blocks an attacker from tricking the browser into parsing a JSON file as a script (or vice versa). Without the `type` attribute, only the file extension guides the runtime.

**Comparison: `type: "json"` vs. `fetch().json()` vs. `createRequire()`:**

| | `import with { type: "json" }` | `fetch().json()` | `require('./file.json')` |
|---|---|---|---|
| Static analysis | ✅ bundler-visible | ❌ | ✅ CJS only |
| Cached per module graph | ✅ | ❌ | ✅ |
| Works in ESM | ✅ | ✅ | ❌ |
| MIME validation | ✅ | ❌ | ❌ |
| Dynamic path | ❌ (static only) | ✅ | ✅ |

---

## Node.js 24 — Platform Changes Summary

Node.js 24 (released April 2026, LTS October 2026) brings several runtime-level changes that affect everyday JavaScript.

```javascript
// ── URLPattern is now a global (no import needed) ─────────────────────
// Before Node.js 24:
// import { URLPattern } from 'node:url';
// After:
const pattern = new URLPattern({ pathname: '/api/:version/:resource' });

// ── Permission Model stable (was --experimental-permission) ──────────
// Process-level capability flags — limit what a Node.js process can access
// package.json script or CLI:
// node --permission --allow-fs-read=./src --allow-net=api.example.com server.js

// At runtime: check granted permissions
process.permission.has('fs.read', './config.json');  // true/false
process.permission.has('net');                        // depends on flags

// ── dirent.path REMOVED — use dirent.parentPath ───────────────────────
// Node.js 22 deprecated dirent.path; Node.js 24 removes it
for await (const dirent of fs.opendir('./src', { recursive: true })) {
  // BEFORE (deprecated/removed):
  // const fullPath = path.join(dirent.path, dirent.name);
  // AFTER (correct):
  const fullPath = path.join(dirent.parentPath, dirent.name);
}

// ── Error.isError() — cross-realm error detection ─────────────────────
// Part of V8 13.6; available natively in Node.js 24+
// (polyfill available via core-js / es-shims for older environments)
Error.isError(new Error());         // true
Error.isError(new TypeError());     // true
Error.isError(new DOMException());  // true (cross-realm!)
Error.isError({ message: 'fake' }); // false
Error.isError({ __proto__: Error.prototype }); // false — spoofing rejected

// Unlike instanceof, works across iframe/realm boundaries:
const xError = new iframeWindow.Error('from iframe');
Error.isError(xError);             // true
xError instanceof Error;           // false — different realm!

// Idiomatic: normalize anything thrown to an Error
function toError(val) {
  return Error.isError(val) ? val : new Error(String(val));
}
```

**Summary of Node.js 24 breaking changes / removals:**

| What changed | Impact | Migration |
|---|---|---|
| `url.parse()` removed | Throws at runtime on Node.js 24 | Replace with `new URL()` |
| `dirent.path` removed | Throws on directory iteration | Use `dirent.parentPath` |
| `tls.createSecurePair()` removed | TLS code using it fails | Use `tls.createSecureContext()` + streams |
| `SlowBuffer` removed | Binary code fails | Use `Buffer.alloc()` or `Buffer.from()` |
| `--experimental-permission` renamed | Scripts using the old flag fail | Use `--permission` |
| `URLPattern` is a global | Positive — one fewer import | Delete `import { URLPattern } from 'node:url'` |
| `AsyncLocalStorage` uses `AsyncContextFrame` | Performance improvement | No code changes needed |

---

## Additional Community Pitfalls (2026 — Platform & Standards)

**46. Using `import assert` Instead of `import with`** [community] — The `assert` keyword for import attributes was a Chrome-only non-standard draft that was replaced by `with` before standardization. WHY it causes problems: `import data from './data.json' assert { type: 'json' }` is a SyntaxError in Firefox, Safari, and Node.js 22+ (which only supports `with`), causing import failures in cross-browser code. Fix: replace all `assert` with `with`; run a codemod or ESLint rule to catch stragglers.

```javascript
// REMOVED — non-standard; SyntaxError in Firefox, Safari, Node.js 22+
import data from './data.json' assert { type: 'json' };

// CORRECT — standard 'with' keyword (Baseline 2025)
import data from './data.json' with { type: 'json' };
```

**47. `AsyncLocalStorage.enterWith()` Contaminating Sibling Handlers** [community] — Calling `asyncLocalStorage.enterWith(store)` inside an event handler sets the store for that handler AND every subsequent synchronous listener registered on the same emitter tick. WHY it causes problems: unrelated event handlers registered after the one calling `enterWith()` see a context they did not set up — unexpected user IDs, request IDs, or trace spans appear in code that should have no context. Fix: always use `run(store, callback)` for isolated, scoped context; reserve `enterWith()` only when you intentionally want the context to persist for the rest of the current synchronous execution.

**48. Named JSON Imports from JSON Modules** [community] — Attempting to use named imports from a JSON module (`import { version } from './package.json' with { type: 'json' }`) is a `SyntaxError`. WHY it causes problems: TypeScript and bundlers like Webpack have historically supported named JSON imports as a non-standard extension — developers accustomed to this pattern are surprised when native ESM rejects it. Fix: use the default import and destructure: `import pkg from './package.json' with { type: 'json' }; const { version } = pkg;`.

**49. `URLPattern` Constructor Accepts String OR Object — Not Both** [community] — `new URLPattern('https://example.com/users/:id', { ignoreCase: true })` works as expected, but `new URLPattern({ pathname: '/users/:id' }, 'https://example.com', { ignoreCase: true })` does not exist — the third parameter is not a valid overload. WHY it causes problems: developers mix the two constructor signatures and get unexpected behavior or a `TypeError`. Fix: use string form for full URL patterns with options (`new URLPattern(str, options)`); use object form for component-by-component patterns where `ignoreCase` is set on the object itself.

**50. `process.permission.has()` Only Reflects Startup Flags** [community] — `process.permission.has('fs.read', '/etc/passwd')` does NOT perform a runtime access check — it only checks whether the flag `--allow-fs-read=/etc/passwd` (or a pattern covering it) was passed at startup. WHY it causes problems: developers use it as a dynamic guard expecting it to reflect OS-level permissions, but it is purely a Node.js permission model check. An `--allow-fs-read=*` flag would make `has('fs.read', anything)` return `true` even for files the OS would deny. Fix: treat `process.permission.has()` as "was this capability granted at launch?" — not as a substitute for OS file permission checks.

---

## Additional Anti-Patterns (Platform & Standards 2026)

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `import ... assert { type: 'json' }` | Non-standard; SyntaxError in Firefox, Safari, Node.js 22+ | Replace `assert` with `with`: `import ... with { type: 'json' }` |
| Named imports from JSON modules | SyntaxError in native ESM — JSON has only a default export | Use `import pkg from '...' with { type: 'json' }` then destructure |
| `asyncLocalStorage.enterWith()` in shared event handlers | Contaminates sibling handlers registered in the same tick | Use `run(store, fn)` for isolated, scoped context |
| `process.permission.has()` as a runtime access guard | Only reflects startup flags — not OS-level permissions | Use it to check Node.js permission model grants; rely on OS/RBAC for security |
| `dirent.path` in Node.js 24+ | Removed — throws `TypeError` on directory iteration | Use `dirent.parentPath` (available since Node.js 21.4) |
| `new URLPattern({ pathname })` with positional `ignoreCase` | Wrong overload — `ignoreCase` in object form needs different syntax | String form: `new URLPattern(str, { ignoreCase: true })`; object form: set `ignoreCase` per component |
| `Promise.all([])` with object literals requiring named results | Array indices are fragile — adding/removing a promise shifts all indices | Use `Promise.allKeyed({ ... })` (Stage 2.7) for object-shaped concurrent awaiting with named keys |
| `.chunks(0)` or `.windows(0)` on an iterator | Size-0 chunk/window is undefined behaviour in some runtimes; throws in others | Always pass a positive integer ≥ 1; validate before calling |

---

## `Promise.allKeyed` / `Promise.allSettledKeyed` — Named Concurrent Awaiting (Stage 2.7)

`Promise.allKeyed(object)` accepts an object whose values are Promises, awaits them concurrently, and resolves to an object with the same keys and resolved values. It is the object-shaped counterpart to `Promise.all(array)` and removes the index-coupling fragility of array-based concurrent patterns.

`Promise.allSettledKeyed(object)` is the non-rejecting variant — analogous to `Promise.allSettled()` — where each value in the result is `{ status: 'fulfilled', value }` or `{ status: 'rejected', reason }`.

```javascript
// ── Problem with array-based Promise.all ─────────────────────────────
// Adding a third fetch shifts all indices — easy to introduce off-by-one bugs
const [user, posts] = await Promise.all([fetchUser(id), fetchPosts(id)]);
// later: const [user, posts, metrics] = ... — adding at end is safe,
//        but inserting in the middle silently shifts assignments

// ── Promise.allKeyed — object-shaped, named, concurrent ──────────────
const { user, posts, metrics } = await Promise.allKeyed({
  user:    fetchUser(id),
  posts:   fetchPosts(id),
  metrics: fetchMetrics(id),
});
// All three run concurrently; keys make intent self-documenting

// ── Promise.allSettledKeyed — partial results, named ──────────────────
const results = await Promise.allSettledKeyed({
  user:    fetchUser(id),
  posts:   fetchPosts(id),
  metrics: fetchMetrics(id),   // might fail without affecting the others
});

// results.user    → { status: 'fulfilled', value: { id, name, ... } }
// results.metrics → { status: 'rejected',  reason: Error('503') }

const user    = results.user.status    === 'fulfilled' ? results.user.value    : null;
const metrics = results.metrics.status === 'fulfilled' ? results.metrics.value : null;

// ── Practical: dashboard data with graceful degradation ───────────────
async function loadDashboard(userId) {
  const { profile, activity, recommendations } = await Promise.allSettledKeyed({
    profile:         fetchProfile(userId),
    activity:        fetchActivityFeed(userId),
    recommendations: fetchRecommendations(userId),  // non-critical
  });

  return {
    profile:         profile.status === 'fulfilled' ? profile.value : null,
    activity:        activity.status === 'fulfilled' ? activity.value : [],
    recommendations: recommendations.status === 'fulfilled' ? recommendations.value : [],
    errors:          Object.entries({ profile, activity, recommendations })
                       .filter(([, r]) => r.status === 'rejected')
                       .map(([key, r]) => ({ key, reason: r.reason.message })),
  };
}
```

**Key differences from existing combinators:**

| Method | Input | Output | Rejects on failure? |
|---|---|---|---|
| `Promise.all([...])` | Array of Promises | Array of values (same order) | Yes — first rejection |
| `Promise.allSettled([...])` | Array of Promises | Array of `{status, value/reason}` | Never |
| `Promise.allKeyed({...})` | Object of Promises | Object of values (same keys) | Yes — first rejection |
| `Promise.allSettledKeyed({...})` | Object of Promises | Object of `{status, value/reason}` | Never |

**Availability:** Stage 2.7 as of 2026 — not yet in browsers or Node.js natively. Use a polyfill or a helper:
```javascript
// Tiny polyfill until Stage 4 lands
Promise.allKeyed = async (obj) => {
  const entries = Object.entries(obj);
  const values  = await Promise.all(entries.map(([, p]) => p));
  return Object.fromEntries(entries.map(([k], i) => [k, values[i]]));
};
```

---

## Iterator Chunking — `.chunks()` and `.windows()` (Stage 2.7)

The Iterator Chunking proposal adds two new methods to `Iterator.prototype`:
- `.chunks(n)` — splits the iterator into non-overlapping arrays of size `n` (last chunk may be shorter)
- `.windows(n)` — produces overlapping windows of size `n`, advancing by one element each step

Both are **lazy** — they compose with the full Iterator Helpers chain without materialising the source.

```javascript
// ── .chunks() — non-overlapping batches ───────────────────────────────
function* digits() {
  for (let i = 0; i < 10; i++) yield i;
}

digits().chunks(3).toArray();
// [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]   ← last chunk shorter than 3

// Batch API requests — stay under rate-limit per request
async function batchFetch(ids) {
  const BATCH_SIZE = 100;
  for (const batch of ids.values().chunks(BATCH_SIZE)) {
    const results = await Promise.all(batch.map(id => fetchItem(id)));
    await processBatch(results);
  }
}

// Paginate database rows — 50 rows per page
async function* pageRows(query) {
  const rows = await db.queryAll(query);
  yield* rows.values().chunks(50);
}

// Grid layout — group items into rows of 4 columns
function gridRows(items, cols = 4) {
  return items.values().chunks(cols).toArray();
}
// gridRows([1..9], 4) → [[1,2,3,4], [5,6,7,8], [9]]

// ── .windows() — overlapping sliding windows ─────────────────────────
// Running average of last 3 values in a stream
function* temperatures() {
  yield* [20, 21, 23, 22, 25, 24, 26];
}

const averages = temperatures().windows(3).map(w => {
  const sum = w.reduce((a, b) => a + b, 0);
  return sum / w.length;
}).toArray();
// [21.33, 22, 23.33, 23.67, 25]

// Pairwise comparison — detect consecutive duplicates
function hasDuplicate(iter) {
  return iter.windows(2).some(([a, b]) => a === b);
}
hasDuplicate([1, 2, 3].values());     // false
hasDuplicate([1, 2, 2, 3].values());  // true

// N-gram generation (NLP preprocessing)
function ngrams(tokens, n) {
  return tokens.values().windows(n).toArray();
}
ngrams(['the', 'quick', 'brown', 'fox'], 2);
// [['the', 'quick'], ['quick', 'brown'], ['brown', 'fox']]

// ── Compose with other Iterator Helpers ──────────────────────────────
// Process only the first 5 chunks of a large dataset
largeDataset.values()
  .chunks(1000)
  .take(5)
  .forEach(batch => processBatch(batch));
```

**Key rules:**
- Size must be a **positive integer ≥ 1**; passing `0` is a `RangeError`.
- `.chunks()`: final chunk contains remaining elements even if fewer than `n`.
- `.windows()`: stops when fewer than `n` elements remain — no padding by default.
- Both return iterators, so `.toArray()` materialises them; composing with `.take()` keeps them lazy.

**Availability:** Stage 2.7 as of 2026. Available via `@tc39/iterator-helpers` polyfill or in the `core-js` iterator helpers package.

```javascript
// Polyfill for .chunks() until Stage 4 ships natively:
Iterator.prototype.chunks = function* (size) {
  if (!Number.isInteger(size) || size < 1) throw new RangeError('size must be a positive integer');
  let chunk = [];
  for (const item of this) {
    chunk.push(item);
    if (chunk.length === size) { yield chunk; chunk = []; }
  }
  if (chunk.length > 0) yield chunk;
};
```

---

## Additional Community Pitfalls (2026 — Near-Future APIs)

**51. Using `Promise.all([])` for Object-Shaped Concurrent Awaiting** [community] — Destructuring the result of `Promise.all` by array position is fragile: inserting a new promise in the middle silently shifts all downstream variable assignments. WHY it causes problems: adding `const [user, newThing, posts] = await Promise.all([...])` after code already assumed `posts` was index 1 is a silent data-wiring bug that no type checker catches unless you're on TypeScript with `as const` tuples. Fix: use `Promise.allKeyed` (Stage 2.7) for named concurrent awaiting; or at minimum destructure into explicit variable names via a named array: `const [userResult, postsResult] = await Promise.all([fetchUser(), fetchPosts()])`.

**52. Calling `.windows(n)` Expecting Padding on Short Trailing Sequences** [community] — When fewer than `n` elements remain at the end of an iterator, `.windows(n)` silently stops — it does NOT yield a padded window. WHY it causes problems: code expecting `[1,2,3].values().windows(2).toArray()` to yield `[[1,2],[2,3],[3,undefined]]` is surprised to get `[[1,2],[2,3]]` with no trailing window. Fix: if you need trailing padded windows, post-process with a `.flatMap` that adds padding, or use a custom generator.

---
