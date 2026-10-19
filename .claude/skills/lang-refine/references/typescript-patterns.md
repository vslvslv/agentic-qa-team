# TypeScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 6 | score: 100/100 | date: 2026-04-27 -->

## Core Philosophy

1. **Type safety as a design tool, not a constraint.** TypeScript's type system is a tool to communicate intent and catch mistakes at compile time. The goal is not to appease the compiler but to express program logic so precisely that entire classes of bugs become impossible.

2. **Prefer strictness from the start.** Retrofitting `strict: true` onto a large codebase is painful. Enabling `"strict": true` plus additional safeguards (`noImplicitReturns`, `noUnusedLocals`, `exactOptionalPropertyTypes`) on day one pays dividends throughout the project lifetime.

3. **Favour types that narrow automatically.** Discriminated unions and literal types let TypeScript narrow what a value can be as it flows through control-flow branches. Reaching for `as` casts or `any` stops narrowing dead in its tracks.

4. **Keep types DRY — derive don't duplicate.** Utility types (`Partial`, `Pick`, `Omit`, `Record`, `ReturnType`) and mapped types let you derive related types from a single source of truth. Maintaining two parallel type definitions is a recipe for drift.

5. **Community experience over textbook defaults.** The official docs show you _what_ the language can do. Experienced teams add hard-won lessons: prefer interfaces over intersection types for composition (they're cached by the compiler), annotate return types explicitly on public APIs, and treat `unknown` rather than `any` as the safe escape hatch.

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

### Assertion Functions (`asserts`)
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

## Language Idioms

TypeScript provides several features that go beyond "just typed JavaScript." These idioms express ideas more clearly than equivalent workarounds.

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

**`import type` for zero-cost type imports.** Using `import type` tells TypeScript (and your bundler) that the import carries no runtime code. This is not just a stylistic preference — without it, circular imports can cause runtime `undefined` values in CommonJS modules, and bundlers may include unnecessary modules in the bundle.

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

**Branded (opaque) types for domain safety.** TypeScript's structural type system means `type UserId = string` and `type ProductId = string` are interchangeable. Branded types add a phantom property that makes them nominally distinct — the compiler rejects mixing them even though the underlying runtime type is identical.

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

**Using `any` instead of `unknown` for unknown data.** [community]
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
