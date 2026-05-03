# TypeScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 10 | score: 100/100 | date: 2026-05-03 -->

## Core Philosophy

1. **Type safety as a design tool, not a constraint.** TypeScript's type system is a tool to communicate intent and catch mistakes at compile time. The goal is not to appease the compiler but to express program logic so precisely that entire classes of bugs become impossible.

2. **Prefer strictness from the start.** Retrofitting `strict: true` onto a large codebase is painful. Enabling `"strict": true` plus additional safeguards (`noImplicitReturns`, `noUnusedLocals`, `exactOptionalPropertyTypes`) on day one pays dividends throughout the project lifetime.

3. **Favour types that narrow automatically.** Discriminated unions and literal types let TypeScript narrow what a value can be as it flows through control-flow branches. Reaching for `as` casts or `any` stops narrowing dead in its tracks.

4. **Keep types DRY — derive don't duplicate.** Utility types (`Partial`, `Pick`, `Omit`, `Record`, `ReturnType`) and mapped types let you derive related types from a single source of truth. Maintaining two parallel type definitions is a recipe for drift.

5. **Community experience over textbook defaults.** The official docs show you _what_ the language can do. Experienced teams add hard-won lessons: prefer interfaces over intersection types for composition (they're cached by the compiler), annotate return types explicitly on public APIs, and treat `unknown` rather than `any` as the safe escape hatch.

---

## TypeScript Version Feature Quick Reference

| Version | Key Feature | Minimum tsconfig |
|---|---|---|
| 4.1 | Template literal types, key remapping in mapped types | `"target": "ES2015"` |
| 4.3 | `override` keyword, separate write types for getters/setters | add `noImplicitOverride: true` |
| 4.5 | `Awaited<T>` built-in, `import type { X }` inline, tail recursion elimination | — |
| 4.7 | `infer` variance bounds (`infer X extends string`), ESM support in Node | `"module": "nodenext"` |
| 4.9 | `satisfies` operator, auto-accessors | — |
| 5.0 | `const` type parameters, decorator support (Stage 3), multiple extends | — |
| 5.1 | Decoupled getter/setter types, unrelated types for JSX | — |
| 5.2 | `using`/`await using` (explicit resource management) | `"target": "ES2022"`, `"lib": ["esnext.disposable"]` |
| 5.4 | `NoInfer<T>` built-in utility type | — |
| 5.5 | Inferred type predicates, `isolatedDeclarations`, RegExp `v` flag | `"isolatedDeclarations": true` |
| 5.6 | Disallow NaN equality check, iterator helper types | — |
| 5.7 | `--noCheck`, path rewriting, relative import completions | — |

Keep `tsconfig.json` at `"strict": true` regardless of version; new strict sub-flags are only added to the umbrella flag after a deprecation period.

---

## Principles / Patterns

### Strict Mode Configuration
Enabling `"strict": true` in `tsconfig.json` activates all strict type-checking options as a group. Without it, TypeScript allows implicit `any`, silently accepts `null` where values are expected, and skips important runtime-hazard detection. The options below are the recommended production baseline:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true,
    "moduleResolution": "bundler"
  }
}
```

Add `exactOptionalPropertyTypes` to prevent accidentally treating `{ prop?: string }` as having an explicit `undefined` value — a common source of subtle bugs in update payloads. Use `moduleResolution: "bundler"` (TypeScript 5+) or `"nodenext"` for modern projects instead of the legacy `"node"` strategy, which silently resolves paths in ways that bundlers won't replicate.

What each strict sub-flag catches:
- `noImplicitAny` — prevents untyped function parameters from silently becoming `any`
- `strictNullChecks` — forces you to handle `null`/`undefined` before accessing properties
- `strictFunctionTypes` — enforces correct function parameter contravariance
- `strictPropertyInitialization` — ensures class fields are initialized in the constructor
- `useUnknownInCatchVariables` — makes caught values `unknown` instead of `any`, requiring a narrow before use

Executable examples showing what strict sub-flags catch:

```typescript
// strictNullChecks: accessing a property that may be null
function getLength(s: string | null): number {
  // Without strict: TypeScript allows this — runtime crash on null
  // With strictNullChecks: Error: Object is possibly 'null'
  return s.length; // ERROR under strict
  // Fix: return s?.length ?? 0;
}

// noImplicitAny: untyped parameter becomes any without annotation
function double(x) { // ERROR: parameter 'x' implicitly has an 'any' type
  return x * 2;
}
// Fix: function double(x: number): number { return x * 2; }

// strictPropertyInitialization: class field used before assignment
class Config {
  apiUrl: string; // ERROR: not definitely assigned in constructor
  constructor(env: 'prod' | 'dev') {
    if (env === 'prod') this.apiUrl = 'https://api.example.com';
    // dev branch never assigns — TypeScript catches the missing path
  }
}
// Fix: apiUrl: string = ''; OR use definite assignment assertion (apiUrl!: string)
//      OR initialize in every constructor branch.
```

---

### `interface` vs `type` — Decision Guide

Both `interface` and `type` can describe object shapes, but they behave differently in two important ways: **declaration merging** and **compiler performance**.

| Capability | `interface` | `type` |
|---|---|---|
| Object shapes | Yes | Yes |
| Primitive / union / tuple aliases | No | Yes |
| Declaration merging (augmentation) | Yes — multiple declarations merge | No — duplicate = error |
| Extends other interfaces/types | `extends` keyword | `&` intersection |
| Compiler cache | Relations cached between checks | Re-evaluated each use |
| Error messages | Shows interface name | May show full expanded type |

**Rule of thumb:**
- Use `interface` for object shapes that describe a contract (classes, services, DI tokens, API shapes). This enables library consumers to extend via declaration merging and gives the compiler cache benefits.
- Use `type` for everything else: union types, tuple aliases, mapped type transformations, conditional types, and primitive aliases.

```typescript
// interface: public contract — consumers can extend
interface Logger {
  log(level: 'info' | 'warn' | 'error', msg: string): void;
}

// Consumers can augment via declaration merging
interface Logger {
  child(name: string): Logger;
}

// type: union/conditional/primitive alias — cannot be merged
type LogLevel = 'info' | 'warn' | 'error';
type MaybeLogger = Logger | null;
type LoggerKeys = keyof Logger;  // 'log' | 'child'

// type: for complex computed shapes (cannot use interface here)
type PickedLogger = Pick<Logger, 'log'>;
type ReadonlyLogger = Readonly<Logger>;
```

[community] **Pitfall:** Using `type X = A & B` for all composition loses declaration-merging capability and slows the compiler. Use `interface X extends A, B {}` for object composition wherever merging might be needed.

---

### Type Annotations on Public APIs
Annotate return types on exported functions even when TypeScript can infer them. Inference on deeply composed return types generates large anonymous types in `.d.ts` files, which slows down incremental builds. Explicit annotations also act as documentation.

```typescript
// Without annotation: compiler must infer and re-verify every call-site
function buildUrl(base: string, path: string, params: Record<string, string>) {
  const query = new URLSearchParams(params).toString();
  return `${base}${path}?${query}`;
}

// With explicit return annotation: faster compilation, clearer contract
function buildUrl(
  base: string,
  path: string,
  params: Record<string, string>
): string {
  const query = new URLSearchParams(params).toString();
  return `${base}${path}?${query}`;
}
```

---

### Generics — Preserve Type Information Without `any`
Use generics to write functions that work across types while preserving type identity. A generic parameter acts as a placeholder that the compiler resolves at call-site, maintaining precise types instead of erasing them to `any`.

```typescript
// Bad: Loses type information — caller gets `any` back
function first(arr: any[]): any {
  return arr[0];
}

// Good: Caller gets back the exact element type
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

// Constrain when capabilities are required
interface HasId {
  id: number;
}

function findById<T extends HasId>(items: T[], id: number): T | undefined {
  return items.find(item => item.id === id);
}
```

---

### Utility Types — Partial, Required, Pick, Omit, Record
Utility types derive new types from existing ones, eliminating duplication and making intent explicit.

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Partial: All fields optional — use for update/patch payloads
function patchUser(id: number, updates: Partial<User>): Promise<User> {
  return fetch(`/users/${id}`, { method: 'PATCH', body: JSON.stringify(updates) })
    .then(r => r.json());
}

// Required: All optional fields become required — enforce complete objects at
// system boundaries where every field must be present (e.g., after validation)
interface FormDraft {
  name?: string;
  email?: string;
  age?: number;
}

function submitForm(data: Required<FormDraft>): void {
  // data.name, data.email, data.age are all guaranteed to be present
  console.log(`Submitting ${data.name} <${data.email}>, age ${data.age}`);
}

// Pick + Omit: Shape types for API boundaries
type UserDTO = Omit<User, 'password'>;
type UserSummary = Pick<User, 'id' | 'name'>;

// Record: Type-safe lookup tables
type StatusColor = Record<'success' | 'warning' | 'error', string>;
const colors: StatusColor = { success: '#22c55e', warning: '#f59e0b', error: '#ef4444' };
```

---

### Union and Intersection Types
Union types (`A | B`) model values that can be one of several types. Intersection types (`A & B`) model values that satisfy all constituent types. Prefer interfaces over intersection types for performance.

```typescript
// Union types for flexible inputs
type StringOrNumber = string | number;

function formatValue(value: StringOrNumber): string {
  if (typeof value === 'number') {
    return value.toFixed(2);
  }
  return value.trim();
}

// Intersection — use sparingly, prefer interface extension
type Named = { name: string };
type Aged = { age: number };

// Less efficient (intersection, not cached by compiler)
type Person = Named & Aged;

// More efficient for composition
interface Person extends Named, Aged {}
```

---

### Discriminated Unions
A discriminated union (also called a tagged union or algebraic data type) is a union of types that share a common literal property — the _discriminant_. TypeScript can exhaustively narrow the type inside switch statements and if-chains.

```typescript
interface LoadingState {
  kind: 'loading';
}

interface SuccessState<T> {
  kind: 'success';
  data: T;
}

interface ErrorState {
  kind: 'error';
  message: string;
  code: number;
}

type AsyncState<T> = LoadingState | SuccessState<T> | ErrorState;

function renderState<T>(state: AsyncState<T>): string {
  switch (state.kind) {
    case 'loading': return 'Loading...';
    case 'success': return `Data: ${JSON.stringify(state.data)}`;
    case 'error':   return `Error ${state.code}: ${state.message}`;
    // TypeScript will error here if a new variant is added without handling it
  }
}
```

Add a `never` exhaustiveness check to ensure all branches are handled:
```typescript
default:
  const _exhaustive: never = state; // compile error if case missed
  throw new Error('Unhandled state');
```

---

### Type Narrowing Techniques — Full Toolkit

TypeScript's narrowing system automatically tracks type constraints through control flow. Understanding all narrowing techniques lets you avoid unsafe `as` casts.

```typescript
type Payload =
  | string
  | number
  | null
  | { type: 'user'; id: string }
  | { type: 'product'; sku: string };

function processPayload(payload: Payload): string {
  // typeof narrowing
  if (typeof payload === 'string') return payload.toUpperCase();
  if (typeof payload === 'number') return payload.toFixed(2);

  // null check (equality narrowing)
  if (payload === null) return '(null)';

  // 'in' operator narrowing — checks property existence
  if ('id' in payload) return `User: ${payload.id}`;

  // Discriminant narrowing via literal property
  switch (payload.type) {
    case 'product': return `SKU: ${payload.sku}`;
  }

  // TypeScript knows this is unreachable
  const _never: never = payload;
  return _never;
}

// instanceof narrowing for class hierarchies
class ApiError extends Error {
  constructor(public readonly status: number, message: string) {
    super(message);
  }
}

function handleError(err: unknown): string {
  if (err instanceof ApiError) return `API ${err.status}: ${err.message}`;
  if (err instanceof Error)    return `Error: ${err.message}`;
  return `Unknown: ${String(err)}`;
}

// Truthiness narrowing + assignment narrowing
function processName(name: string | null | undefined): string {
  // Truthiness: eliminates null and undefined (but also '' and 0)
  if (!name) return 'Anonymous';
  // Here name is string (non-empty due to truthiness)
  return name.trim();
}
```

---

### Async/Await with Typed Errors
TypeScript 4.0+ defaults catch variables to `unknown` when `useUnknownInCatchVariables` is enabled (included in `strict`). Always narrow the error before using it.

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

async function fetchUser(id: number): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return {
        ok: false,
        error: new Error(`HTTP ${response.status}: ${response.statusText}`)
      };
    }
    const data: User = await response.json();
    return { ok: true, value: data };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return { ok: false, error: new Error(message) };
  }
}

// Usage — no try/catch needed at call site
const result = await fetchUser(42);
if (result.ok) {
  console.log(result.value.name);
} else {
  console.error(result.error.message);
}
```

---

### Module Organization
Structure TypeScript projects around feature modules with a clear barrel export pattern. Avoid re-exporting everything with wildcard `export *` as it makes tree-shaking harder and obscures the public API.

```typescript
// src/users/types.ts — pure types, no runtime code
export interface User { id: number; name: string; email: string; }
export type CreateUserInput = Omit<User, 'id'>;

// src/users/repository.ts — data access
import type { User, CreateUserInput } from './types';

export class UserRepository {
  async findById(id: number): Promise<User | null> { /* ... */ }
  async create(input: CreateUserInput): Promise<User> { /* ... */ }
}

// src/users/index.ts — controlled barrel (name what you export)
export type { User, CreateUserInput } from './types';
export { UserRepository } from './repository';
```

Use `import type` for type-only imports; this is stripped at emit time and prevents accidental runtime dependencies.

---

### Dependency Injection via Interfaces
TypeScript's structural typing makes constructor injection natural. Define service contracts as interfaces, inject via constructor, and swap implementations in tests without a DI framework.

```typescript
interface Logger {
  info(msg: string): void;
  error(msg: string, err?: unknown): void;
}

interface HttpClient {
  get<T>(url: string): Promise<T>;
}

class OrderService {
  constructor(
    private readonly http: HttpClient,
    private readonly logger: Logger
  ) {}

  async getOrder(id: string): Promise<Order> {
    this.logger.info(`Fetching order ${id}`);
    try {
      return await this.http.get<Order>(`/orders/${id}`);
    } catch (err) {
      this.logger.error(`Failed to fetch order ${id}`, err);
      throw err;
    }
  }
}

// Production
const service = new OrderService(new FetchHttpClient(), new ConsoleLogger());

// Test — swap implementation with no DI framework needed
const service = new OrderService(mockHttpClient, mockLogger);
```

---

### Callback Types: `void` Return, Non-Optional Parameters, and Overload Arity
Official TypeScript declaration guidelines specify three rules for callback types that are frequently violated in the wild.

```typescript
// Rule 1: Use void (not any) for ignored callback return values
// void prevents accidental use of the return value; any disables all checking

// WRONG
function forEach<T>(items: T[], callback: (item: T) => any): void {
  items.forEach(callback);
}

// CORRECT
function forEach<T>(items: T[], callback: (item: T) => void): void {
  items.forEach(callback);
}

// Rule 2: Write callback parameters as non-optional
// Callers CAN ignore extra parameters (JS feature); marking them optional
// creates ambiguity about whether the callback itself is optional.

// WRONG
interface DataFetcher {
  fetch(done: (data: unknown, elapsed?: number) => void): void;
}

// CORRECT
interface DataFetcher {
  fetch(done: (data: unknown, elapsed: number) => void): void;
}

// Rule 3: For callbacks with varying arity, use a single max-arity overload
// TypeScript's first-match rule means shorter overloads would shadow longer ones.

// WRONG — shorter overload matches first, longer is unreachable
declare function beforeAll(action: () => void, timeout?: number): void;
declare function beforeAll(action: (done: DoneFn) => void, timeout?: number): void;

// CORRECT — single overload with max parameters
declare function beforeAll(
  action: (done: DoneFn) => void,
  timeout?: number
): void;
```

---

### Function Overloads — Most Specific First, Prefer Union Types
TypeScript resolves overloads by matching the _first_ compatible signature. Poorly ordered or unnecessarily split overloads produce wrong return types and hide valid call patterns.

```typescript
// WRONG: general overload first — specific signatures are unreachable
declare function process(x: unknown): unknown;
declare function process(x: HTMLElement): number;
declare function process(x: HTMLDivElement): string;

// CORRECT: specific to general
declare function process(x: HTMLDivElement): string;
declare function process(x: HTMLElement): number;
declare function process(x: unknown): unknown;

// Prefer optional parameters over multiple trailing overloads
// WRONG
interface Formatter {
  format(value: string): string;
  format(value: string, locale: string): string;
  format(value: string, locale: string, precision: number): string;
}

// CORRECT — fewer overloads, same expressiveness
interface Formatter {
  format(value: string, locale?: string, precision?: number): string;
}

// Prefer union types over same-shape overloads
// WRONG — breaks pass-through functions
interface Clock {
  setOffset(offset: number): void;
  setOffset(offset: string): void;
}

// CORRECT — works transparently with union inputs
interface Clock {
  setOffset(offset: number | string): void;
}
```

---

### Primitive Types: Use Lowercase, Avoid Boxed Wrappers
TypeScript's `String`, `Number`, `Boolean`, `Symbol`, and `Object` are JavaScript's boxed object types — they are almost never what you want. Always use the lowercase counterparts.

```typescript
// WRONG: Boxed type — a String object, not a string primitive
function reverseWrong(s: String): String {
  return s.split('').reverse().join('');
  // Error: Property 'split' does not exist on type 'String' (in strict mode)
}

// CORRECT: string primitive
function reverse(s: string): string {
  return s.split('').reverse().join('');
}

// WRONG: Object is not the same as object (non-primitive)
declare function accept(value: Object): void;

// CORRECT: object (lowercase) excludes primitives
declare function accept(value: object): void;

// Or more specifically, use a descriptive interface
declare function accept(value: Record<string, unknown>): void;
```

Boxed types (`String`, `Number`) are assignable to their primitive counterparts but NOT vice versa — using them as parameter types silently rejects primitive literals unless narrowed first.

---

### Assertion Functions — Encode Invariants in the Type System

Assertion functions are a first-class TypeScript pattern for expressing runtime invariants in the type system. Unlike type predicates (`pet is Fish`), assertion functions use the `asserts` keyword and narrow the *calling scope* when they return normally — or throw if the assertion fails.

```typescript
// asserts condition — narrows after call
function assert(condition: unknown, msg?: string): asserts condition {
  if (!condition) throw new Error(msg ?? 'Assertion failed');
}

// asserts param is Type — narrows type of param after call
function assertIsString(val: unknown): asserts val is string {
  if (typeof val !== 'string') {
    throw new TypeError(`Expected string, got ${typeof val}`);
  }
}

function processInput(input: string | undefined) {
  assert(input !== undefined, 'input must be provided');
  // TypeScript now knows: input is string (not string | undefined)
  assertIsString(input);
  console.log(input.toUpperCase()); // safe — both assertions passed
}
```

Use assertion functions to encode invariants at layer boundaries (e.g., after parsing config, after deserializing JSON) rather than sprinkling `!` non-null assertions or `as` casts.

---

### Decorators (TypeScript 5.0+ / ECMAScript Stage 3)
TypeScript 5.0 shipped full support for the ECMAScript decorator proposal. Decorators are a composable, type-safe way to augment class methods, fields, and accessors. Prefer typed decorator signatures over `any`-based implementations.

```typescript
// Typed method decorator: logs entry/exit without any-casts
function loggedMethod<This, Args extends unknown[], Return>(
  target: (this: This, ...args: Args) => Return,
  context: ClassMethodDecoratorContext<This, (this: This, ...args: Args) => Return>
): (this: This, ...args: Args) => Return {
  const methodName = String(context.name);
  return function (this: This, ...args: Args): Return {
    console.log(`→ ${methodName}(${args.map(String).join(', ')})`);
    const result = target.call(this, ...args);
    console.log(`← ${methodName} returned ${String(result)}`);
    return result;
  };
}

// Auto-bind decorator (replaces class-properties arrow-function workaround)
function bound<This, Args extends unknown[], Return>(
  target: (this: This, ...args: Args) => Return,
  context: ClassMethodDecoratorContext<This, (this: This, ...args: Args) => Return>
): void {
  context.addInitializer(function (this: This) {
    (this as Record<string | symbol, unknown>)[context.name] =
      target.bind(this);
  });
}

class Counter {
  private count = 0;

  @loggedMethod
  increment(by: number): number {
    this.count += by;
    return this.count;
  }

  @bound
  reset(): void {
    this.count = 0;
  }
}
```

---

### Explicit Resource Management — `using` / `await using` (TypeScript 5.2)
TypeScript 5.2 introduced the `using` and `await using` declarations, which automatically call `Symbol.dispose()` (or `Symbol.asyncDispose()`) when the variable goes out of scope — eliminating manual `try/finally` cleanup for files, database connections, locks, and timers.

```typescript
// Implement the Disposable interface
class DatabaseConnection implements Disposable {
  private handle: number;
  constructor(private readonly dsn: string) {
    this.handle = openConnection(dsn); // hypothetical
  }
  query<T>(sql: string): T[] {
    return runQuery(this.handle, sql);
  }
  [Symbol.dispose](): void {
    closeConnection(this.handle);
    console.log('Connection closed automatically');
  }
}

// No try/finally needed — disposal runs even on early return or throw
function processOrders(): Order[] {
  using db = new DatabaseConnection(process.env.DB_URL!);
  const orders = db.query<Order>('SELECT * FROM orders WHERE pending = true');
  if (orders.length === 0) return []; // disposal fires here automatically
  return enrichOrders(db, orders);
} // disposal fires here too

// Async variant for async cleanup (e.g., closing network streams)
async function readStream(): Promise<string> {
  await using reader = await openAsyncReader('file.txt');
  return reader.readAll(); // reader[Symbol.asyncDispose]() called on exit
}
```

Requires `"target": "ES2022"` or higher and `"lib": ["es2022", "esnext.disposable"]` in `tsconfig.json`.

---

### `DisposableStack` and `AsyncDisposableStack` — Composing Multiple Disposables

When you need to acquire multiple resources and dispose them all as a unit — in reverse acquisition order — `DisposableStack` and `AsyncDisposableStack` (TypeScript 5.2+ with `esnext.disposable`) provide a container that automatically tracks and disposes each resource. This is cleaner than chaining `using` declarations when resources are conditionally acquired.

```typescript
// Compose multiple disposables in a single stack
function processFiles(paths: string[]): string[] {
  using stack = new DisposableStack();

  // register resources imperatively — disposed in LIFO order
  const readers = paths.map(p => {
    const reader = stack.use(openFileReader(p)); // openFileReader implements Disposable
    return reader;
  });

  // all readers disposed when stack goes out of scope
  return readers.map(r => r.readAll());
}

// defer() registers an arbitrary cleanup function (no Disposable needed)
function withTempDirectory(): string {
  using stack = new DisposableStack();
  const dir = createTempDir();
  stack.defer(() => fs.rmSync(dir, { recursive: true }));
  doWork(dir);
  return dir; // cleanup runs automatically
}

// AsyncDisposableStack for async cleanup
async function runMigration(): Promise<void> {
  await using stack = new AsyncDisposableStack();
  const db  = stack.use(await connectDatabase());       // AsyncDisposable
  const log = stack.use(await openAuditLog('migrate')); // Disposable
  await db.runMigrations();
  await log.flush();
} // both disposed in reverse order, awaiting async dispose
```

[community] **Pitfall:** Forgetting that `DisposableStack` itself is `Disposable` — it MUST be declared with `using`, not `const`, or its accumulated cleanup callbacks never fire. Assigning to `const stack = new DisposableStack()` is a silent no-op for all registered disposals.

---

### Type-Safe Builder Pattern

The classic builder pattern can be made fully type-safe in TypeScript by tracking which fields have been set using a phantom type parameter. The `build()` method is only available once all required fields are set — the compiler catches incomplete builds at compile time, not runtime.

```typescript
// Track set fields as a union in a phantom type parameter
type BuilderState = { [K: string]: unknown };

class QueryBuilder<TSet extends BuilderState = Record<never, never>> {
  private params: Partial<{ table: string; limit: number; offset: number }> = {};

  table<T extends string>(name: T): QueryBuilder<TSet & { table: T }> {
    this.params.table = name;
    return this as QueryBuilder<TSet & { table: T }>;
  }

  limit(n: number): QueryBuilder<TSet & { limit: number }> {
    this.params.limit = n;
    return this as QueryBuilder<TSet & { limit: number }>;
  }

  offset(n: number): QueryBuilder<TSet & { offset: number }> {
    this.params.offset = n;
    return this as QueryBuilder<TSet & { offset: number }>;
  }

  // build() only callable when 'table' has been set
  build(this: QueryBuilder<TSet & { table: string }>): string {
    const { table, limit, offset } = this.params;
    let q = `SELECT * FROM ${table}`;
    if (limit)  q += ` LIMIT ${limit}`;
    if (offset) q += ` OFFSET ${offset}`;
    return q;
  }
}

const query = new QueryBuilder()
  .table('users')
  .limit(10)
  .build(); // OK: table is set

// const bad = new QueryBuilder().limit(5).build();
// Error: 'this' parameter type QueryBuilder<{ limit: number }>
//        is not assignable to QueryBuilder<{ table: string } & { limit: number }>
```

---

### Abstract Constructors and Mixin Pattern

TypeScript supports abstract constructor types for mixins — composable behavior units that work without full class inheritance chains.

```typescript
// Abstract constructor type
type AbstractConstructor<T = object> = abstract new (...args: unknown[]) => T;
type Constructor<T = object> = new (...args: unknown[]) => T;

// Mixin factory: adds timestamp tracking to any class
function Timestamped<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    readonly createdAt = new Date();
    readonly updatedAt = new Date();
  };
}

// Mixin factory: adds serialisation
function Serializable<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    serialize(): string {
      return JSON.stringify(this);
    }
  };
}

// Compose mixins — order matters (left-to-right application)
class Entity {
  constructor(public readonly id: string) {}
}

class TimestampedSerializableEntity extends Serializable(Timestamped(Entity)) {}

const e = new TimestampedSerializableEntity('e_001');
console.log(e.createdAt); // Date
console.log(e.serialize()); // JSON string
```

---

### Runtime Validation and Type Safety — Zod/Valibot Integration Pattern

TypeScript types are erased at runtime — `JSON.parse()` returns `any`, and `fetch().json()` returns `any`. Use a runtime schema library to parse and validate data at system boundaries, deriving the TypeScript type from the schema (single source of truth).

```typescript
// Schema-first: define once, get both runtime validation AND TypeScript type
// Using Zod (most popular runtime schema library for TypeScript)
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  email: z.string().email(),
  role: z.enum(['admin', 'viewer', 'editor']),
  createdAt: z.coerce.date(),
});

// Derive TypeScript type from schema — no duplication
type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  const raw = await fetch(`/api/users/${id}`).then(r => r.json());
  // parse() throws ZodError with detailed path-based error messages if invalid
  return UserSchema.parse(raw);
  // Or: UserSchema.safeParse(raw) → { success, data } | { success: false, error }
}

// Partial schemas for update payloads — derived automatically
type UpdateUserInput = z.infer<typeof UserSchema.partial().omit({ id: true })>;
```

**Why this matters:** Without runtime validation, `as User` on an API response is a lie — the type is `any` under the hood and any missing/wrong field causes a runtime crash. With a schema library, the parse step is the only `as` cast needed, and it's guarded by real validation.

---

## Language Idioms

**`satisfies` operator (TypeScript 4.9+).** Validates an expression against a type without widening the inferred type. Useful when you want the compiler to check shape but still keep literal types narrow.

```typescript
type Colors = Record<string, [number, number, number] | string>;

// Without satisfies: palette.red is (string | [number,number,number]) — too wide
const palette: Colors = { red: [255, 0, 0], green: '#00ff00' };

// With satisfies: palette.red is [number,number,number] — narrow and safe
const palette = {
  red: [255, 0, 0],
  green: '#00ff00',
} satisfies Colors;

palette.red[0]; // OK — TypeScript knows it's a tuple, not string | tuple
```

**Template literal types.** Generate union types from combinations of string literals — great for typed event names, CSS property names, or API route prefixes.

```typescript
type EventName = 'click' | 'focus' | 'blur';
type HandlerName = `on${Capitalize<EventName>}`; // 'onClick' | 'onFocus' | 'onBlur'

function registerHandler(event: EventName, handler: () => void): void { /* ... */ }
```

**Conditional types with `infer`.** Extract type information from complex types — the backbone of `ReturnType`, `Parameters`, `Awaited`, and many custom utility types.

```typescript
// Extract the resolved value type from any Promise
type Resolved<T> = T extends Promise<infer U> ? U : T;

type A = Resolved<Promise<string>>;   // string
type B = Resolved<number>;            // number (not a Promise, returns T)

// TypeScript 4.7: constrained infer — infer with extends bound
// Infer U but only accept string subtypes (avoids an extra Exclude)
type GetStringKeys<T> = {
  [K in keyof T]: T[K] extends infer V extends string ? K : never;
}[keyof T];

interface Config {
  host: string;
  port: number;
  env: 'prod' | 'dev';
}
type StringKeys = GetStringKeys<Config>; // 'host' | 'env'

// Multiple infer positions: extract function argument and return types
type FunctionShape<F> = F extends (...args: infer A) => infer R
  ? { args: A; returnType: R }
  : never;

type Shape = FunctionShape<(id: string, count: number) => boolean>;
// { args: [string, number]; returnType: boolean }

// Recursive conditional: deeply unwrap nested Promises
type DeepAwaited<T> = T extends Promise<infer U> ? DeepAwaited<U> : T;

type Nested = DeepAwaited<Promise<Promise<string>>>; // string
```

**`as const` for immutable literal inference.** Prevents TypeScript from widening literals to their base types.

```typescript
// Without as const: status is type string
const status = 'active';

// With as const: status is type 'active'
const status = 'active' as const;

// Freeze entire objects
const ROLES = ['admin', 'editor', 'viewer'] as const;
type Role = typeof ROLES[number]; // 'admin' | 'editor' | 'viewer'
```

**`keyof` and `typeof` for type extraction.** Derive types from runtime values, keeping types in sync automatically.

```typescript
const CONFIG = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  retries: 3,
} as const;

type ConfigKey = keyof typeof CONFIG;   // 'apiUrl' | 'timeout' | 'retries'
type ConfigValue = typeof CONFIG[ConfigKey]; // string | number
```

**Mapped types for transformations.** Apply an operation to every property of a type — the foundation of all built-in utility types.

```typescript
// Custom utility: make specific keys optional
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

interface Config {
  host: string;
  port: number;
  timeout: number;
}

type OptionalTimeout = PartialBy<Config, 'timeout'>;
// { host: string; port: number; timeout?: number }
```

**`Extract<T, U>` and `Exclude<T, U>` for union filtering.** These built-in utility types let you extract or remove specific members from a union. Combined with `NonNullable<T>`, they are essential for working with union types without manual narrowing.

```typescript
type Status = 'idle' | 'loading' | 'success' | 'error';

// Keep only the failure states
type FailureStatus = Extract<Status, 'loading' | 'error'>;
// 'loading' | 'error'

// Remove null/undefined from a type
type MaybeUser = User | null | undefined;
type DefiniteUser = NonNullable<MaybeUser>;  // User

// Exclude specific members
type NonErrorStatus = Exclude<Status, 'error'>;
// 'idle' | 'loading' | 'success'

// Extract object types from a union by shape
type UnionType = string | number | { id: string } | { name: string };
type ObjectTypes = Extract<UnionType, object>;
// { id: string } | { name: string }

// Deep utility: make specific nested keys optional
type DeepPartialBy<T, K extends PropertyKey> = {
  [P in keyof T]: P extends K
    ? T[P] | undefined
    : T[P] extends object
    ? DeepPartialBy<T[P], K>
    : T[P];
};
```

**`PropertyKey` type.** The built-in `PropertyKey = string | number | symbol` represents all valid object key types. Use it instead of `string` when writing generic utilities that work with any valid key.

```typescript
function hasKey<T extends object>(obj: T, key: PropertyKey): key is keyof T {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

// Type-safe object pick by array of keys
function pick<T extends object, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  return Object.fromEntries(
    keys.filter(k => k in obj).map(k => [k, obj[k]])
  ) as Pick<T, K>;
}
```

 Using `import type` tells TypeScript (and your bundler) that the import carries no runtime code. This is not just a stylistic preference — without it, circular imports can cause runtime `undefined` values in CommonJS modules, and bundlers may include unnecessary modules in the bundle.

```typescript
// Without import type: bundler may include user module at runtime
import { User } from './user';
type UserMap = Map<string, User>;

// With import type: zero runtime cost, explicit intent
import type { User } from './user';
type UserMap = Map<string, User>;

// Inline import type (TypeScript 4.5+): mix type and value imports
import { createUser, type User } from './user';
```

**Tuple types for fixed-length heterogeneous arrays.** Prefer tuple types over `any[]` or `unknown[]` when a function returns or accepts a fixed sequence of differently-typed values — common in React hooks and custom iterators.

```typescript
// Function that returns two values of different types
function useCounter(initial: number): [number, (delta: number) => void] {
  let count = initial;
  const update = (delta: number) => { count += delta; };
  return [count, update];
}

const [count, increment] = useCounter(0);
increment(1); // type-safe: (delta: number) => void
```

**Mapped type modifiers (`+/-readonly`, `+/-?`).** Use `-?` to strip all optionality from a type and `-readonly` to remove immutability constraints. These modifiers make mapped types precise — you can add or remove both modifiers independently rather than always adding them.

```typescript
// -? strips optional modifiers (makes all fields required)
type Concrete<T> = {
  [K in keyof T]-?: T[K];
};

// -readonly strips readonly modifiers (makes all fields mutable)
type Mutable<T> = {
  -readonly [K in keyof T]: T[K];
};

interface FormState {
  readonly id: string;
  name?: string;
  email?: string;
}

type WritableForm = Mutable<Concrete<FormState>>;
// { id: string; name: string; email: string } — mutable and required
```

**Key remapping via `as` in mapped types (TypeScript 4.1+).** Rename or filter keys during a mapped type transformation, enabling auto-generated accessor names and structural filtering.

```typescript
// Auto-generate getter method names from interface properties
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Config { host: string; port: number; }
type ConfigGetters = Getters<Config>;
// { getHost: () => string; getPort: () => number }

// Filter keys by value type using Exclude
type StringProps<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};
```

**`override` keyword for safe method overriding (TypeScript 4.3+).** When a subclass method overrides a base class method, TypeScript can lose track of the relationship if the base is renamed or removed. The `override` keyword makes the intent explicit — the compiler errors if the named method doesn't exist in the base class, preventing "ghost overrides" that silently become new methods.

```typescript
class Animal {
  speak(): string {
    return 'generic sound';
  }

  move(distance: number): void {
    console.log(`Moved ${distance}m`);
  }
}

class Dog extends Animal {
  override speak(): string {  // Compiler verifies Animal.speak exists
    return 'woof';
  }

  // override moveTo(): void { ... }  // ERROR: 'moveTo' does not exist in Animal
  // Without override: this silently creates a NEW method Dog.moveTo
}

// Enable noImplicitOverride: true in tsconfig to REQUIRE the override keyword
// on all overriding methods — makes implicit overrides a compile error
```

Use `noImplicitOverride: true` in `tsconfig.json` alongside `override` declarations to close the hole: without the flag, forgetting `override` is still legal.

**Module augmentation for extending third-party types.** When a library's types are missing a method your runtime polyfill adds, use `declare module` to extend the types without modifying the library source. This keeps vendor types separate from your additions and avoids casting.

```typescript
// extend-observable.ts
import { Observable } from 'rxjs';

declare module 'rxjs' {
  interface Observable<T> {
    /** Our custom retry-with-backoff operator */
    retryWithBackoff(maxAttempts: number): Observable<T>;
  }
}

Observable.prototype.retryWithBackoff = function (maxAttempts) {
  // implementation
  return this.pipe(/* retry logic */);
};
```

**Type-safe event emitter using generics.** The standard `EventEmitter` API is stringly-typed — any string is accepted as an event name and the callback is `any`. Use a generic map type to get full type safety for events, payloads, and listeners.

```typescript
type EventMap = Record<string, unknown[]>; // event name → tuple of payload types

class TypedEventEmitter<TEvents extends EventMap> {
  private listeners = new Map<keyof TEvents, ((...args: unknown[]) => void)[]>();

  on<K extends keyof TEvents>(
    event: K,
    listener: (...args: TEvents[K]) => void
  ): this {
    const handlers = this.listeners.get(event) ?? [];
    handlers.push(listener as (...args: unknown[]) => void);
    this.listeners.set(event, handlers);
    return this;
  }

  emit<K extends keyof TEvents>(event: K, ...args: TEvents[K]): void {
    this.listeners.get(event)?.forEach(h => h(...args));
  }
}

// Define your event schema once
interface AppEvents extends EventMap {
  userCreated: [userId: string, email: string];
  orderPlaced: [orderId: number, total: number];
}

const emitter = new TypedEventEmitter<AppEvents>();
emitter.on('userCreated', (id, email) => console.log(id, email)); // correctly typed
emitter.emit('userCreated', 'u_123', 'alice@example.com'); // args type-checked
```

**Recursive types for self-referential data.** TypeScript supports recursive type aliases, which enables precise modelling of trees, nested configuration, and JSON-like structures.

```typescript
// JSON-compatible value type (recursive)
type JsonValue =
  | string | number | boolean | null
  | JsonValue[]
  | { [key: string]: JsonValue };

function stringify(val: JsonValue): string {
  return JSON.stringify(val);
}

// Recursive tree node
interface TreeNode<T> {
  value: T;
  children?: TreeNode<T>[];
}

function traverseTree<T>(node: TreeNode<T>, visit: (v: T) => void): void {
  visit(node.value);
  node.children?.forEach(child => traverseTree(child, visit));
}
```

**`const` type parameters (TypeScript 5.0).** Add `const` before a type parameter to tell TypeScript to infer the narrowest literal type — the same effect as `as const` at the call site, but built into the function signature.

```typescript
// Without const modifier: infers string[] (widened)
function toReadonlyArray<T>(items: T[]): readonly T[] {
  return items;
}
const arr = toReadonlyArray(['a', 'b']); // readonly string[]

// With const modifier: infers readonly ['a', 'b'] (literal tuple)
function toReadonlyArray2<const T extends readonly unknown[]>(items: T): T {
  return items;
}
const arr2 = toReadonlyArray2(['a', 'b']); // readonly ["a", "b"]
// arr2[0] has type "a", not string
```

This removes the need to pepper call sites with `as const` for lookup tables, configuration arrays, and route definitions.

**`NoInfer<T>` utility type (TypeScript 5.4+).** Prevents TypeScript from using a specific parameter as a source for type argument inference. Useful when one parameter should be the authoritative source and others should be validated against it rather than expanding it.

```typescript
// Without NoInfer: "blue" expands C to string | "red" | "yellow" | "green"
function createStreetLight<C extends string>(
  colors: C[],
  defaultColor?: C
): void {}
createStreetLight(['red', 'yellow', 'green'], 'blue'); // No error — unexpected!

// With NoInfer: inference only from colors[], defaultColor checked against it
function createStreetLight<C extends string>(
  colors: C[],
  defaultColor?: NoInfer<C>  // Not a source for inferring C
): void {}
createStreetLight(['red', 'yellow', 'green'], 'blue');
// Error: Argument of type '"blue"' is not assignable to parameter of type '"red" | "yellow" | "green"'
```

**Variance annotations (`in`, `out`, `in out`) on generic parameters.** Explicitly mark how a type parameter varies — covariant (`out`), contravariant (`in`), or invariant (`in out`). This enables faster assignability checks (the compiler can short-circuit structural comparison) and makes the type intent self-documenting.

```typescript
// Covariant: only produced (readable) — Producer<Dog> is assignable to Producer<Animal>
interface Producer<out T> {
  make(): T;
}

// Contravariant: only consumed (writable) — Consumer<Animal> is assignable to Consumer<Dog>
interface Consumer<in T> {
  consume(item: T): void;
}

// Invariant: both produced and consumed — must be exact type
interface Container<in out T> {
  get(): T;
  set(item: T): void;
}

// Practical example: ReadonlyArray is covariant, Array is invariant
// This is why ReadonlyArray<Dog>[] is assignable to ReadonlyArray<Animal>[]
// but Array<Dog>[] is NOT assignable to Array<Animal>[]
```

Use variance annotations on interfaces with large union hierarchies where TypeScript's structural check is slow — the explicit annotation bypasses the full structural walk.

**Inferred type predicates (TypeScript 5.5+).** TypeScript 5.5 automatically infers type predicates for simple filtering functions, eliminating the need for manual `value is T` annotations on `filter` callbacks and similar utilities. The inference works when: (1) the function has no explicit return type, (2) it has a single `return` statement, (3) it doesn't mutate its parameter, and (4) it returns a boolean tied to parameter refinement.

```typescript
// Before TypeScript 5.5: filter loses type information
const items: Array<string | undefined> = ['a', undefined, 'b', undefined, 'c'];

// Manual predicate required — easy to forget or get wrong
const withManual = items.filter((x): x is string => x !== undefined);

// TypeScript 5.5+: predicate inferred automatically
const withInferred = items.filter(x => x !== undefined);
// Type: string[] — no manual predicate needed

// Also works for inline helper predicates
const isNumber = (x: unknown) => typeof x === 'number';
// Inferred as: (x: unknown) => x is number

const mixed: Array<string | number> = [1, 'a', 2, 'b', 3];
const numbers = mixed.filter(isNumber); // Type: number[] (not (string | number)[])
```

Conditions that PREVENT inference: explicit return type annotation, multiple return paths, any mutation of the narrowed parameter.

**`isolatedDeclarations` (TypeScript 5.5+) for fast parallel builds.** When enabled, TypeScript requires explicit type annotations on all exported functions and variables, making declaration emit deterministic without cross-file inference. This unblocks third-party build tools (esbuild, swc, Rollup) from emitting `.d.ts` files in parallel — dramatically speeding up monorepo builds.

```typescript
// With isolatedDeclarations: true, exported functions need explicit return types
// ❌ Error: Function must have explicit return type annotation with isolatedDeclarations
export function computeHash(input: string) {
  return input.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
}

// ✅ Correct: explicit annotation makes declaration emit deterministic
export function computeHash(input: string): number {
  return input.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
}

// Trivial literals are still inferred (no annotation needed)
export const MAX_RETRIES = 3;       // number — OK
export const BASE_URL = '/api/v1';  // string — OK
```

Enable in `tsconfig.json`: `"isolatedDeclarations": true` (requires `"declaration": true`). Combine with `noImplicitOverride` and explicit return types for the highest build performance in monorepos.

---

### Named Complex Types for Compiler Caching

Conditional types and mapped type expressions are re-evaluated every time they appear inline. Extracting them into a named `type` alias allows the compiler to cache the evaluation result and reuse it. This is the type-level equivalent of extracting a computed value into a variable.

```typescript
// SLOW: inline conditional type re-evaluated at every call site
function processItems<T>(
  items: Array<T extends Promise<infer U> ? U : T>
): void { /* ... */ }

// FAST: named alias is computed once and cached
type Awaited<T> = T extends Promise<infer U> ? U : T;

function processItems<T>(items: Array<Awaited<T>>): void { /* ... */ }

// Same pattern for complex mapped types
// SLOW: re-evaluated at every use
type Slow = {
  [K in keyof SomeHugeType as SomeHugeType[K] extends string ? K : never]: SomeHugeType[K];
};

// FAST: name the transformation, reference the name
type StringKeysOf<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};
type Fast = StringKeysOf<SomeHugeType>; // evaluated once, then cached

// Also: avoid deeply nested inline generics
// SLOW: chained inline expressions each re-evaluated
function transform<T>(x: Readonly<Partial<Pick<T, keyof T>>>): void {}

// FAST: name the intermediate type
type SafePartial<T> = Readonly<Partial<T>>;
function transform<T>(x: SafePartial<T>): void {}
```

[community] **Pitfall:** Teams writing performance-critical type utilities often miss that `type Foo<T> = T extends Bar<infer U> ? U : never` is re-evaluated every time `Foo<Something>` appears in the code — unless it becomes part of a cached structural relationship (which only happens with interfaces, not type aliases). Name your complex utility types, and where possible replace a mapped+conditional combination with an interface hierarchy.

---

### Build Performance: `incremental`, `skipLibCheck`, and `composite`

TypeScript provides three complementary compiler flags that dramatically reduce cold-start and warm build times. Most projects use none of them by default.

```json
{
  "compilerOptions": {
    // incremental: saves a .tsbuildinfo file after each build.
    // On subsequent runs, only files that have changed (and their transitive
    // dependents) are re-checked. For a medium project (500 files), this
    // typically reduces warm build time from ~15s to ~2s.
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo",

    // skipLibCheck: skips type-checking .d.ts files from node_modules.
    // Safe for most projects because library authors are responsible for
    // their own .d.ts correctness. Avoids costly re-checking of all vendor
    // types on every build (saves 1-5s depending on @types package count).
    "skipLibCheck": true,

    // composite: required for project references (--build mode).
    // Enables per-project incremental caching in monorepos.
    // Each package is checked once; changes only re-check dependent packages.
    "composite": true,
    "declaration": true  // required when composite is true
  }
}
```

Recommended adoption order:
1. Add `"incremental": true` immediately — zero downside for any project.
2. Add `"skipLibCheck": true` unless you specifically rely on type checking library `.d.ts` files.
3. Add `"composite": true` + `"references"` only in monorepos where you need per-package caching.

[community] **Pitfall:** Setting `"incremental": true` but committing `.tsbuildinfo` to git. The build info file is large, binary-ish, and changes on every build — it belongs in `.gitignore`. On CI, either delete it before each run or cache it by branch using your CI cache key strategy.

---

### Branded / Nominal Types — Prevent Primitive Confusion

TypeScript's structural type system means `type UserId = string` and `type ProductId = string` are interchangeable. Branded types add a phantom property that makes them nominally distinct — the compiler rejects mixing them even though the underlying runtime type is identical.

```typescript
// Create brands with an intersection and a unique phantom property
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId    = Brand<string, 'UserId'>;
type ProductId = Brand<string, 'ProductId'>;

// Smart constructors validate and brand at the boundary
function createUserId(raw: string): UserId {
  if (!raw.startsWith('usr_')) throw new Error('Invalid user id');
  return raw as UserId;
}

function createProductId(raw: string): ProductId {
  if (!raw.startsWith('prd_')) throw new Error('Invalid product id');
  return raw as ProductId;
}

function getUser(id: UserId): Promise<User> { /* ... */ return Promise.resolve({} as User); }

const uid = createUserId('usr_123');
const pid = createProductId('prd_456');

getUser(uid);  // OK
getUser(pid);  // Error: ProductId is not assignable to UserId
```

This pattern is especially valuable for IDs, currency amounts, validated email addresses, and any primitive where two values of the same base type must never be interchangeable.

---

## Real-World Gotchas  [community]

**`namespace` keyword in modern TypeScript code.** [community]
The TypeScript `namespace` (and the legacy `module`) keyword was introduced before ES modules existed. It compiles to an IIFE-based pattern that bundlers and native ESM runtimes do not understand. Teams new to TypeScript sometimes use `namespace Foo {}` for code organisation, which produces confusing runtime behaviour when mixed with ESM. **Fix:** Use ES module `import`/`export` for all code organization. Reserve `declare namespace` (ambient declaration) only in `.d.ts` files for declaring global APIs that cannot use ES modules.

**`any` at data boundaries silently poisons type inference.** [community]
When you receive data from external sources (API responses, `JSON.parse`, event payloads), reaching for `any` silences all type errors instead of requiring you to narrow safely. `unknown` forces a type guard or assertion before use. The root cause is that `any` is bidirectional — it's assignable to and from everything — so it silently poisons every downstream type inference. **Fix:** Replace `any` with `unknown` in catch blocks, JSON parse results, and external data boundaries, then use `instanceof` or type predicates before accessing fields.

**Intersection types instead of interface extension.** [community]
Teams often write `type Foo = Bar & Baz & { extra: string }` thinking it's equivalent to `interface Foo extends Bar, Baz`. It isn't: interface relationships are cached by the compiler; intersection types are re-evaluated on every use. In large codebases this causes measurable slowdowns in type checking (the TypeScript Performance wiki explicitly documents this). **Fix:** Replace `type X = A & B` with `interface X extends A, B {}` wherever composition is the goal.

**Misconfigured `include`/`exclude` patterns.** [community]
Writing `"exclude": ["node_modules"]` does not recursively exclude nested folders. TypeScript's glob patterns require `**/node_modules` to match at any depth. The result is that TypeScript silently crawls test fixtures, generated files, and `node_modules` sub-trees, dramatically inflating compilation time. **Fix:** Use `"exclude": ["**/node_modules", "**/.*/"]` and verify with `tsc --listFiles`.

**Automatic `@types` inclusion causing global conflicts.** [community]
By default, TypeScript auto-includes every `@types/*` package found under `node_modules`. Installing both `@types/jest` and `@types/mocha` causes `it`, `describe`, and `expect` to be declared twice, leading to confusing "duplicate identifier" errors that look like a TypeScript bug. **Fix:** Set `"types": ["node", "jest"]` in `compilerOptions` to explicitly list only the globals your project uses.

**Truthiness checks on primitives masking bugs.** [community]
Writing `if (count)` to guard a number silently skips the zero case. Writing `if (str)` skips empty strings. These patterns feel natural but create logic bugs that are never caught by TypeScript because `number` is a valid truthy/falsy value. **Fix:** Use explicit comparisons — `if (count !== undefined)`, `if (str.length > 0)`, or `if (str !== '')`. Enable `strictNullChecks` so TypeScript errors on nullable values used without a guard.

**`as` casts defeating exhaustiveness checks.** [community]
Type assertions (`value as SomeType`) are escape hatches that compile away entirely. Developers often use them to "fix" a type error without understanding why it was raised — bypassing the discriminated union exhaustiveness check, silencing null-narrowing, or hiding an incorrect type assignment. The cast succeeds at compile time but crashes at runtime. **Fix:** Treat every `as` cast as a code review flag. If a cast is necessary, document _why_ with a comment. For external data, use a runtime validation library (Zod, Valibot) instead of casting.

**`const enum` causing broken builds across compilation boundaries.** [community]
`const enum` inlines enum values at every call site during compilation, making them zero-cost at runtime. However, this inlining only works within a single `tsc` compilation. When a `const enum` is defined in a library (or a separate `tsconfig` project) and consumed by another, the values are absent in the emitted `.d.ts` — consuming packages get `undefined` instead of the expected number. Babel, esbuild, and SWC do not support `const enum` at all and silently emit broken code. **Fix:** Use string literal union types (`type Status = 'active' | 'inactive'`) or regular `enum` (not `const`) in any code that crosses a compilation boundary. Reserve `const enum` only for types used within a single compilation unit where full `tsc` is always used.

**Distributive conditional types producing unexpected unions.** [community]
When a conditional type is written as `T extends U ? X : Y` and `T` is a naked (unwrapped) type parameter, TypeScript distributes over every member of a union — each union member is evaluated separately, then the results are unioned together. This is intentional but frequently surprises teams. `type ToArray<T> = T extends any ? T[] : never; type R = ToArray<string | number>` gives `string[] | number[]`, not `(string | number)[]`. **Fix:** Wrap the type parameter in a single-element tuple to prevent distribution: `type ToArrayNonDist<T> = [T] extends [any] ? T[] : never` gives `(string | number)[]`. Always ask: "should this conditional distribute over union members or treat the union as a whole?"


**Overloaded function signatures in wrong order.** [community]
TypeScript resolves overloads by matching the _first_ compatible signature. When a general overload appears before a specific one, the specific signature is unreachable and type narrowing breaks at call-sites. **Fix:** Always order overloads from most specific to most general.

**Large monorepos without project references.** [community]
In multi-package repositories, running `tsc` at the root causes the compiler to type-check every package in a single pass, sharing a single module cache that grows unbounded. Teams report 30–60 second incremental builds even for small changes because one modified file invalidates the shared cache. The root cause is that TypeScript has no concept of "already checked this package" without project references. **Fix:** Add `tsconfig.json` with `"composite": true` to each package and `"references": [...]` at the root to enable per-package incremental caching (`--build` mode). Changes in one package only re-check packages that depend on it.

**Using boxed types (`String`, `Number`, `Boolean`) instead of primitives.** [community]
Developers from Java or C# backgrounds occasionally write `function fn(x: String)` thinking it's the same as `string`. It isn't: `String` is the object wrapper type and does not accept string primitives in every context. Worse, `Object` is not the same as `object` — the uppercase version accepts primitives. This creates confusing type errors at assignability boundaries. **Fix:** Use lowercase primitives exclusively: `string`, `number`, `boolean`, `symbol`. Use `object` (lowercase) for non-primitive values, or define a specific interface.

**Optional callback parameters.** [community]
Marking callback parameters as optional (`(data: T, error?: Error) => void`) seems more flexible, but it breaks TypeScript's ability to type-check the callback invocation. The official declaration guidelines note that JS callers can always ignore extra parameters — making them optional on the type creates a false impression that the second argument might not be passed, which then prevents pass-through functions from working correctly. **Fix:** Declare all callback parameters as required even if callers typically ignore some of them.

**Numeric enum assignability across namespaces.** [community]
TypeScript allows assigning numeric enum values across different enum types — `First.SomeEnum.A = 0` is assignable to `Second.SomeEnum` even if the enums are unrelated, as long as the underlying values match. This is surprising structural typing behavior for a feature that most developers expect to be nominally typed. Since TypeScript 5.4, enums must have identical member values to be cross-assignable, but older codebases silently allow this. **Fix:** Prefer string enums (`enum Status { Active = 'active' }`) over numeric enums — string enums are not structurally assignable across types, giving you the nominal isolation you expect.

**`readonly` does not mean immutable.** [community]
`readonly` prevents reassignment of a property but does NOT prevent mutation of the object that property points to. `home.resident = x` errors, but `home.resident.age++` silently succeeds. Furthermore, a `readonly` property accessed through an aliased mutable reference can change at any time — TypeScript does not track mutation across variable aliases. Developers who use `readonly` as a correctness guarantee are surprised when values change unexpectedly. **Fix:** Use `Object.freeze()` for runtime immutability, or `as const` on literal objects. For deep immutability, model data as `Readonly<DeepReadonly<T>>` or use Immer for immutable update patterns.

**Excess property checking only applies to object literals.** [community]
TypeScript enforces extra-property checking only when you pass an object literal directly to a typed assignment target. As soon as the object is assigned to an intermediate variable first, excess property checking is bypassed — the variable's structural type is wider and passes validation. Teams sometimes exploit this inadvertently for mocks or test fixtures, then wonder why inline code errors but variable code does not. **Fix:** Be aware of the asymmetry. When you want shape validation without losing literal inference, use `satisfies` — it checks shape against a type without widening the value, and still catches excess properties on assignment.

**Structural typing allows "accidental interface implementation".** [community]
Because TypeScript is structurally typed, any object with the right shape satisfies an interface — even if it was created by a completely unrelated module. This means a `DatabaseConnection` object might accidentally satisfy a `Logger` interface if both happen to have matching method signatures. In tests this can mask missing implementations: `mockLogger = db as unknown as Logger` compiles but the mock methods do nothing useful. **Fix:** For critical interfaces (loggers, repositories, event buses), use the explicit `implements` keyword — TypeScript will verify the full contract and surface missing members at the class definition. For tests, use a real mock or stub that explicitly implements the interface.

**`exactOptionalPropertyTypes` changes what `undefined` means.** [community]
Without `exactOptionalPropertyTypes`, TypeScript treats `{ name?: string }` as equivalent to `{ name: string | undefined }` — you can explicitly set `name: undefined`. With the flag enabled, `name?: string` means "the key may be absent" but you cannot set it to `undefined` explicitly. This matters for JSON serialisation (`JSON.stringify` omits absent keys but includes `undefined`-valued keys as nothing) and for `Object.assign` / spread operations that treat absent vs `undefined` differently. **Fix:** Enable `exactOptionalPropertyTypes: true` in `tsconfig.json` and use `Partial<T>` explicitly only when you mean "might be absent"; use `T | undefined` only when you mean "present but undefined".

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| `any` type | Disables all type checking; infects downstream types | Use `unknown`, then narrow with type guards |
| Intersection types for composition | Not cached; slows incremental compilation | `interface Foo extends Bar, Baz {}` |
| Truthiness checks on primitives | Silently fails for `0`, `""`, `NaN` | Explicit `!== undefined`, `!== null` checks |
| `as` cast without a comment | Hides invalid type assumptions; runtime crash risk | Narrow with type guard or validate at runtime |
| Missing `strict: true` | Allows implicit `any`, skips null checks | Enable `strict` and additional safeguards from day one |
| Wildcard barrel exports (`export *`) | Obscures public API; prevents tree-shaking | Named explicit re-exports only |
| Large union types (10+ members) | Pairwise comparison is O(n²) for type checking | Extract a base interface, use `extends` |
| Catch block `error: any` | Masks error type; skips null/property checks | Use `error: unknown` then `instanceof Error` |
| `@types` auto-inclusion | Duplicate globals from multiple test frameworks | Set `"types": [...]` explicitly in tsconfig |
| No return type on public functions | Compiler infers large anonymous types; slow build | Annotate return types on all exported functions |
| Legacy `moduleResolution: "node"` | Silent path resolution mismatches with bundlers | Use `"bundler"` or `"nodenext"` for modern projects |
| No project references in monorepos | Single-pass type check; unbounded cache growth | Add `"composite": true` + `"references"` per package |
| `any`-based decorator implementations | Loses all type safety in decorators | Use typed `ClassMethodDecoratorContext<This, Method>` signatures |
| Manual `try/finally` for resource cleanup | Cleanup silently omitted on early returns | Use `using` / `await using` with `Disposable` interface (TS 5.2+) |
| Naked type params in conditional types | Unexpected distribution over unions | Wrap in `[T] extends [U]` when non-distributive behavior is needed |
| `const enum` in library code | Inlining breaks across compilation boundaries and Babel/esbuild | Use string literal union types or regular `enum` at boundaries |
| Stringly-typed `EventEmitter` | Any event name / any payload; errors only at runtime | Use `TypedEventEmitter<TEvents>` pattern with a `Record<string, unknown[]>` map |
| Boxed types (`String`, `Number`, `Boolean`) | Not assignable to primitive counterparts; causes confusing errors | Use lowercase primitives: `string`, `number`, `boolean` |
| Optional callback parameters | Breaks pass-through typing; implies argument might not be provided | Declare all callback parameters as required |
| General overload before specific | Specific signatures become unreachable; wrong return type | Order overloads from most specific to most general |
| Numeric enums across namespaces | Structurally assignable to unrelated enums; nominality not enforced | Use string enums or branded types for nominal identity |
| Missing `override` on subclass methods | Base method rename turns override into ghost new method silently | Add `override` + enable `noImplicitOverride: true` |
| `readonly` used for runtime immutability | Only prevents property reassignment; nested mutation allowed | Use `Object.freeze()` or `as const` for runtime safety |
| Passing object literal to bypass excess check | Use intermediate variable to widen type | Use `satisfies` to validate shape while preserving literal inference |
| TypeScript `namespace` in new code | `namespace`/`module` keywords are legacy, pre-ESM TypeScript constructs — bundlers and runtimes do not understand them | Use ES module `import`/`export`; reserve `declare namespace` only for global augmentation in `.d.ts` files |
| Inferring complex return types on hot paths | Large anonymous inferred types inflate `.d.ts` size and slow incremental compilation | Add explicit return type annotations to all exported functions; use `isolatedDeclarations` to enforce it |
| Inline conditional/mapped types on hot paths | Re-evaluated at every call site; no compiler caching | Extract into a named `type` alias so the compiler can cache the result |
| `DisposableStack` declared with `const` | Resource cleanup callbacks never fire — `const` prevents disposal | Always use `using stack = new DisposableStack()` |
| Committing `.tsbuildinfo` to git | File is large, changes every build, and pollutes diffs | Add `*.tsbuildinfo` to `.gitignore`; cache by branch on CI |
| Missing `incremental: true` on any project | Full type-check on every `tsc` run even for unchanged files | Add `"incremental": true` to `tsconfig.json` immediately |

---

## TypeScript 5.6 / 5.7 Language Additions

### Iterator Helper Types (TypeScript 5.6+)

TypeScript 5.6 added built-in type support for the ECMAScript iterator helpers proposal — `.map()`, `.filter()`, `.take()`, `.drop()`, `.flatMap()`, `.reduce()`, and `.forEach()` on `Iterator<T>` objects. This lets you write lazy pipelines over custom iterables with full type safety, without pulling in a library.

```typescript
// Any class implementing Iterator<T> gains .map(), .filter(), etc.
function* range(start: number, end: number): Iterator<number> {
  for (let i = start; i < end; i++) yield i;
}

// chain iterator helpers lazily — no intermediate arrays
const result = range(0, 100)
  .filter(n => n % 2 === 0)   // Iterator<number>
  .map(n => n * n)             // Iterator<number>
  .take(5);                    // Iterator<number>

// spread or for..of to materialise
const squares = [...result]; // [0, 4, 16, 36, 64]

// Type-safe custom iterator
class InfiniteCounter implements Iterator<number> {
  private n = 0;
  next(): IteratorResult<number> {
    return { value: this.n++, done: false };
  }
}

const counter = new InfiniteCounter();
const firstFive = counter.take(5); // Iterator<number>
```

[community] **Pitfall:** Iterator helpers require `"lib": ["ES2025"]` or `"esnext"` in `tsconfig.json` and a runtime that supports the proposal (Node 22+, modern browsers). Polyfills exist but add bundle weight — check your target environment before relying on them.

---

### `--noCheck` Flag (TypeScript 5.7+)

TypeScript 5.7 introduced `--noCheck`, which skips type-checking entirely and only emits JavaScript. This is useful in CI pipelines where you want to separate the "type check" job from the "build" job — type checking runs once in parallel while the build proceeds without waiting for it.

```json
// package.json scripts — split type check and build for faster CI
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build":     "tsc --noCheck",
    "ci":        "npm run typecheck & npm run build"
  }
}
```

[community] **Pitfall:** Using `--noCheck` as the primary build script in development environments defeats the purpose of TypeScript. It should only appear in CI parallelisation strategies or in tools (like esbuild/swc wrappers) where a separate type-check pass is explicitly scheduled.

---

### Relative Import Completions and Path Rewriting (TypeScript 5.7+)

TypeScript 5.7 added support for rewriting relative import paths when emitting JavaScript — solving a long-standing ergonomic pain point in projects that write `.ts` source but need `.js` extensions in output. Combined with `allowImportingTsExtensions`, you can now write `.ts` extensions in source and have them rewritten to `.js` in emit without requiring a bundler.

```typescript
// tsconfig.json for native ESM Node projects (no bundler)
{
  "compilerOptions": {
    "module": "nodenext",
    "rewriteRelativeImportExtensions": true,
    "allowImportingTsExtensions": true,
    "noEmit": false,
    "outDir": "dist"
  }
}

// Source: src/server.ts
import { createApp } from './app.ts'; // write .ts — emitted as ./app.js

// Emitted: dist/server.js
// import { createApp } from './app.js'; — automatically rewritten
```

This eliminates the previously common workaround of writing `.js` extensions in `.ts` source files, which confused editors and was invisible to new contributors.
