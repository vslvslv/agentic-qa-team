# TypeScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 24 | score: 100/100 | date: 2026-05-07 -->
<!-- iteration trace (latest):
     Iter 21 (2026-05-04): added Type Narrowing Deep-Dive (all 9 techniques from official narrowing docs),
       Conditional Types section (extends ternary, infer keyword, distributive types, built-in utilities),
       Declaration Files & Merging section, and expanded TSConfig reference table — sourced from
       typescriptlang.org/docs/handbook/2/narrowing.html, conditional-types.html,
       declaration-files/deep-dive.html, and typescriptlang.org/tsconfig/
     Iter 22 (2026-05-07): added TypeScript 5.8 features — granular return branch checks,
       require() of ESM in nodenext, --erasableSyntaxOnly for Node.js type-stripping,
       --module node18, --libReplacement, import attribute with keyword migration sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html
     Iter 23 (2026-05-07): added TypeScript 5.9 features — import defer, --module node20,
       minimal tsc --init defaults, noUncheckedSideEffectImports, ArrayBuffer/TypedArray
       breaking change, cache optimizations for Zod/tRPC-style libraries sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html
     Iter 24 (2026-05-07): added TypeScript 6.0 features — strict/esnext/es2025 defaults,
       deprecated outFile/baseUrl, Temporal API, RegExp.escape, Map.getOrInsert/getOrInsertComputed,
       --stableTypeOrdering migration flag, DOM lib consolidation, migration guide to TS 7.0 sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html
-->

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
| 5.8 | Granular return expression branch checks, `--erasableSyntaxOnly`, `require()` of ESM in `nodenext`, `--module node18`, `--libReplacement` | `"module": "node18"` or `"nodenext"` |
| 5.9 | `import defer`, `--module node20`, minimal `tsc --init`, `noUncheckedSideEffectImports`, `verbatimModuleSyntax`, DOM summary hovers | `"moduleDetection": "force"`, `"verbatimModuleSyntax": true` |
| 6.0 | **Breaking:** `strict`/`esnext`/`es2025` defaults; `types: []`; `outFile`, `baseUrl`, `module amd/umd` removed; Temporal API, `RegExp.escape`, `Map.getOrInsert`; `--stableTypeOrdering`; DOM lib consolidates `dom.iterable` | Update `tsconfig.json` — set `"types": ["node"]`, `"rootDir": "./src"`, migrate `baseUrl` → `paths` |

Keep `tsconfig.json` at `"strict": true` regardless of version; new strict sub-flags are only added to the umbrella flag after a deprecation period.

> **TypeScript 6.0 Migration Note:** TS 6.0 is a transition release — all deprecated options still work with `"ignoreDeprecations": "6.0"` in tsconfig. TypeScript 7.0 will remove them entirely. Address deprecations now:
> - Replace `--baseUrl` with explicit `paths` entries
> - Remove `--outFile`; use an external bundler (Webpack/Rollup/esbuild)
> - Add `"types": ["node"]` if your project targets Node.js (new default is `[]`)
> - Set `"rootDir": "./src"` if you relied on inferred root (now defaults to tsconfig directory)

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

### `noUncheckedIndexedAccess` — Safe Dictionary Access

The `noUncheckedIndexedAccess` compiler flag (TypeScript 4.1+, added to the 5.9 `tsc --init` baseline) adds `undefined` to the type returned by any index signature access where the key is not explicitly declared. Without it, TypeScript trusts that any string key produces a defined value — a common source of `TypeError: Cannot read properties of undefined` at runtime.

```typescript
// tsconfig: "noUncheckedIndexedAccess": true

interface Config {
  host: string;    // explicitly declared — still string, not string | undefined
  port: number;
  [key: string]: string | number; // index signature for dynamic keys
}

declare const config: Config;

// Explicitly declared properties: type unchanged
const host: string = config.host;   // string — OK, explicitly declared
const port: number = config.port;   // number — OK

// Index signature access: now includes undefined
const timeout = config.timeout;     // string | number | undefined (with flag)
// Without flag: string | number (false precision — crashes if key absent)

// Array element access is also guarded
const items: string[] = ['a', 'b', 'c'];
const first = items[0];             // string | undefined (with flag)
const safe = first?.toUpperCase();  // string | undefined — correct handling
// Without flag: first is string — potential crash on empty array

// Pattern: use nullish coalescing for array defaults
function head<T>(arr: T[]): T | undefined {
  return arr[0]; // returns T | undefined — honest about empty arrays
}

const DEFAULT_TIMEOUT = 5_000;
const t = config.timeout ?? DEFAULT_TIMEOUT; // number — safe default
```

[community] **Pitfall:** `noUncheckedIndexedAccess` makes `arr[0]` return `T | undefined` — including inside `for` loops where the index is *known* to be valid. Teams often disable the flag because loops like `for (let i = 0; i < arr.length; i++) arr[i].method()` now produce errors. The correct fix is to use `for...of` (which gives a definite `T`), or to add a null check inside the loop. Do not disable the flag to silence these; the check correctly warns that `arr[i]` can be undefined if the array is modified concurrently.

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

### Type Narrowing — Full Toolkit

TypeScript's narrowing system automatically tracks type constraints through control flow using nine distinct narrowing techniques. Understanding them all lets you avoid unsafe `as` casts.

| Technique | Syntax | What it narrows |
|---|---|---|
| `typeof` | `typeof x === "string"` | Primitive types (`string`, `number`, `boolean`, `bigint`, `symbol`, `undefined`, `object`, `function`) |
| Truthiness | `if (x)` | Removes `null`, `undefined`, `0`, `""`, `NaN`, `0n` |
| Equality | `x === y` | Narrows to common type; `==` also removes both `null` and `undefined` |
| `in` operator | `"prop" in obj` | Property presence (optional props appear in both branches) |
| `instanceof` | `x instanceof Date` | Prototype chain / constructor check |
| Assignment | `x = "hello"` | Narrows observed type after assignment |
| Control flow | Reachability analysis | Automatic — TypeScript infers through if/else/switch/return |
| Type predicates | `(x: T): x is S` | Custom user-defined type guard via `is` keyword |
| Discriminated unions | `kind: "circle"` | Literal discriminant property + union |

**`typeof` gotcha — `typeof null === "object"`:**
```typescript
function printAll(strs: string | string[] | null) {
  if (typeof strs === "object") {
    // strs is still string[] | null — typeof null === "object" in JS!
    for (const s of strs) {  // Error: strs is possibly null
      console.log(s);
    }
  }
}
// Fix: combine typeof with null check
if (strs !== null && typeof strs === "object") { ... }
```

**Truthiness narrowing — empty string is falsy:**
```typescript
// ANTI-PATTERN: filters out empty string ''
function processStr(s: string | null) {
  if (s) { /* '' never reaches here */ }
}
// FIX: explicit null check
function processStr(s: string | null) {
  if (s !== null) { /* '' is handled correctly */ }
}
```

**`in` operator with optional properties:**
```typescript
type Fish  = { swim: () => void };
type Bird  = { fly: () => void };
type Human = { swim?: () => void; fly?: () => void };

function move(animal: Fish | Bird | Human) {
  if ("swim" in animal) {
    animal; // Fish | Human (both have swim — optional counts)
  } else {
    animal; // Bird | Human
  }
}
```

**User-defined type predicates (`is` keyword):**
```typescript
function isFish(pet: Fish | Bird): pet is Fish {
  return (pet as Fish).swim !== undefined;
}

// Type predicate enables typed filter — array method returns Fish[]
const zoo: (Fish | Bird)[] = [getSmallPet(), getSmallPet()];
const fishOnly: Fish[] = zoo.filter(isFish);

// Inline predicate in filter
const underWater: Fish[] = zoo.filter((pet): pet is Fish => {
  return "swim" in pet;
});
```

**`never` exhaustiveness in discriminated unions:**
```typescript
interface Circle   { kind: 'circle';   radius: number; }
interface Square   { kind: 'square';   side: number; }
interface Triangle { kind: 'triangle'; base: number; height: number; }

type Shape = Circle | Square | Triangle;

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':   return Math.PI * shape.radius ** 2;
    case 'square':   return shape.side ** 2;
    case 'triangle': return 0.5 * shape.base * shape.height;
    default: {
      // TypeScript error if a new Shape variant is added without handling it
      const _exhaustive: never = shape;
      throw new Error(`Unhandled shape: ${JSON.stringify(_exhaustive)}`);
    }
  }
}
```

---

### Conditional Types

Conditional types use an extends ternary to select types based on type relationships. They are the basis for many of TypeScript's built-in utility types.

**Basic syntax:**
```typescript
// SomeType extends OtherType ? TrueType : FalseType
type IsString<T> = T extends string ? true : false;
type A = IsString<string>;  // true
type B = IsString<number>;  // false
```

**`infer` keyword — extract types from the condition:**
```typescript
// Extract element type from array
type Flatten<T> = T extends Array<infer Item> ? Item : T;
type Str = Flatten<string[]>;  // string
type Num = Flatten<number>;    // number

// Extract return type from function
type ReturnOf<T> = T extends (...args: never[]) => infer R ? R : never;
type R = ReturnOf<() => Promise<User>>;  // Promise<User>

// Extract the awaited value (equivalent to built-in Awaited<T>)
type Resolved<T> = T extends Promise<infer U> ? U : T;
type S = Resolved<Promise<string>>;  // string
type N = Resolved<number>;           // number (passthrough)
```

**Distributive conditional types — distribution over unions:**
```typescript
// When T is a naked (unwrapped) type param, distributes over every union member
type ToArray<T> = T extends any ? T[] : never;
type StrArrOrNumArr = ToArray<string | number>;
// → string[] | number[]  (distributed: ToArray<string> | ToArray<number>)

// PREVENT distribution by wrapping in square brackets:
type ToArrayNonDist<T> = [T] extends [any] ? T[] : never;
type ArrOfStrOrNum = ToArrayNonDist<string | number>;
// → (string | number)[]  (single array type, not distributed)
```

**Built-in conditional utility types:**
```typescript
// Exclude — remove U from T
type Status = 'active' | 'inactive' | 'deleted';
type LiveStatus = Exclude<Status, 'deleted'>;  // 'active' | 'inactive'

// Extract — keep only what extends U
type StringsOnly = Extract<string | number | boolean, string>;  // string

// NonNullable — remove null and undefined
type Safe = NonNullable<string | null | undefined>;  // string

// ReturnType, Parameters — reflect function signatures
function greet(name: string, times: number): string { return ''; }
type GreetReturn = ReturnType<typeof greet>;     // string
type GreetParams = Parameters<typeof greet>;     // [string, number]

// InstanceType — extract class instance type
class User { constructor(public name: string) {} }
type UserInstance = InstanceType<typeof User>;   // User
```

**Practical use — replace function overloads:**
```typescript
// Without conditional types — three overloads needed
function createLabel(id: number): IdLabel;
function createLabel(name: string): NameLabel;
function createLabel(idOrName: number | string): IdLabel | NameLabel { /* */ }

// With conditional types — single generic signature
type NameOrId<T extends number | string> = T extends number ? IdLabel : NameLabel;
function createLabel<T extends number | string>(idOrName: T): NameOrId<T> {
  // implementation
}
```

---

### Declaration Files & Declaration Merging

A declaration file (`.d.ts`) describes the shape of existing JavaScript code to TypeScript. Understanding the types/values/namespaces distinction and merging rules is essential for writing accurate `.d.ts` files and augmenting third-party types.

**Three declaration categories:**

| Category | Created by |
|---|---|
| **Type** | `type`, `interface`, `class`, `enum`, import referring to a type |
| **Value** | `let`/`const`/`var`, function, class, enum, import referring to a value |
| **Namespace** | `namespace`, module with exports |

The same name can mean all three: a `class Foo` creates both a type (the instance shape) and a value (the constructor). An `enum E` creates a type and a value.

**Interface merging — augmenting third-party types:**
```typescript
// Extend an existing interface in a third-party library
// In your project's types: globals.d.ts
interface Window {
  myAnalytics: AnalyticsClient;  // Merges with lib.dom.d.ts Window
}

// Multiple declarations merge automatically — order doesn't matter
interface Foo { x: number; }
interface Foo { y: number; }
const f: Foo = { x: 1, y: 2 };  // Both members required
```

**Declaration merging of class + namespace (static members):**
```typescript
class Moment {
  static now(): number { return Date.now(); }
}
namespace Moment {
  export type Duration = { value: number; unit: 'ms' | 's' | 'm' }
  export function fromDuration(d: Duration): Moment { /* */ return new Moment(); }
}

const d: Moment.Duration = { value: 30, unit: 's' };
const m = Moment.fromDuration(d);  // Static method via namespace merge
```

**Module augmentation — adding types to external packages:**
```typescript
// Augment an npm package's types in your project
// File: src/types/express.d.ts
import 'express';

declare module 'express' {
  interface Request {
    user?: { id: string; role: 'admin' | 'user' };
  }
}
```

**`type` aliases cannot be merged** — use `interface` when augmentation is needed:
```typescript
type Status = 'active';
type Status = 'inactive';  // ERROR: Duplicate identifier 'Status'

interface Config { debug: boolean; }
interface Config { timeout: number; }  // OK — merges to { debug, timeout }
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

### TypeScript 5.8 — `--erasableSyntaxOnly` and Node.js Type-Stripping

Node.js 23.6+ and the `--experimental-strip-types` flag allow TypeScript files to be run directly by stripping types at the JS engine level. However, this only works for **erasable** TypeScript syntax — constructs with no runtime semantics. TypeScript 5.8 adds `--erasableSyntaxOnly` to enforce this constraint at compile time.

**What counts as non-erasable (blocked by `--erasableSyntaxOnly`):**
- `enum` declarations (compile to object literals with reverse maps)
- `namespace`/`module` declarations with runtime code (compile to IIFEs)
- Parameter properties in constructors (compile to assignment statements)
- `import =` / `export =` assignments (legacy CommonJS bridging syntax)

```typescript
// tsconfig.json: "erasableSyntaxOnly": true  (+ targeting Node.js type-stripping)

// ❌ Non-erasable — enum has runtime code
enum Color { Red, Green, Blue }

// ✅ Erasable alternative — const object with as const
const Color = { Red: 0, Green: 1, Blue: 2 } as const;
type Color = typeof Color[keyof typeof Color];

// ❌ Non-erasable — parameter property in constructor
class Service {
  constructor(public readonly db: Database) {}
}

// ✅ Erasable alternative — explicit field + explicit assignment
class Service {
  readonly db: Database;
  constructor(db: Database) { this.db = db; }
}
```

**`--module node18` vs `--module nodenext`:** Use `node18` when targeting Node.js 18.x LTS (stable, won't gain new behaviors). Use `nodenext` for Node.js 22+ (supports `require()` of ESM modules). Under `nodenext`, import attributes use `with` not `assert`:

```typescript
// ❌ Deprecated — import assertion
import data from "./data.json" assert { type: "json" };

// ✅ Current — import attribute
import data from "./data.json" with { type: "json" };
```

**Granular return branch checks:** TypeScript 5.8 now checks each branch of a conditional expression in a `return` statement against the declared return type, catching bugs that were silently missed when one branch returned `any`:

```typescript
declare const cache: Map<string, unknown>;

function getUser(id: string): User {
  return cache.has(id)
    ? cache.get(id)  // ❌ Error: 'unknown' not assignable to 'User'
    : fetchUser(id);
}
// Fix: cast the cache hit or narrow before returning
```

---

### TypeScript 5.9 — `import defer` and Module Improvements

`import defer` delays module evaluation until the first property access on the namespace, improving application startup when expensive modules are only needed conditionally. This is a **TC39 Stage 3** proposal and requires either native runtime support or a bundler transformation.

```typescript
// Standard import: module evaluates immediately on import
import * as db from "./database.js";  // Database connection pool started here

// Deferred import: module body NOT evaluated until first property access
import defer * as db from "./database.js";  // Nothing happens yet

async function handleRequest(path: string): Promise<void> {
  if (path.startsWith("/db/")) {
    // Database module evaluated HERE — on first use
    const result = await db.query("SELECT ...");
    return result;
  }
  // On non-database paths, db module never evaluated — zero startup cost
}
```

Only namespace imports (`import defer * as name`) are supported — not named or default imports.

**`--module node20`:** A stable alias for Node.js v20 module semantics (unlike `nodenext`, it won't gain new behaviors in future TypeScript versions). Implies `--target es2023` and supports `require()` of ESM. Choose `node20` for explicit stability; choose `nodenext` to automatically track Node.js's evolving module system.

**Minimal `tsc --init` defaults (TypeScript 5.9+):** New projects initialized with `tsc --init` get a prescriptive, minimal config reflecting modern best practices:

```json
{
  "compilerOptions": {
    "strict": true,
    "module": "nodenext",
    "target": "esnext",
    "jsx": "react-jsx",
    "types": [],
    "moduleDetection": "force",
    "verbatimModuleSyntax": true
  }
}
```

`"types": []` means no `@types/*` packages are auto-included — add them explicitly (e.g., `"types": ["node"]`). `"verbatimModuleSyntax": true` enforces that `import type` is always used for type-only imports, keeping bundlers informed.

**`ArrayBuffer`/`TypedArray` breaking change (TypeScript 5.9):** `ArrayBuffer` is no longer a supertype of typed array types. Code that passes `Uint8Array` where `ArrayBufferLike` is expected now errors:

```typescript
// ❌ Error in TypeScript 5.9+
function process(buf: ArrayBufferLike): void { /* ... */ }
const arr = new Uint8Array([1, 2, 3]);
process(arr);  // Error: Uint8Array<ArrayBuffer> not assignable to ArrayBufferLike

// ✅ Fix option 1: use the .buffer property
process(arr.buffer);

// ✅ Fix option 2: accept explicit type
function process(buf: Uint8Array<ArrayBuffer>): void { /* ... */ }

// ✅ Fix option 3: update @types/node to pick up corrected overloads
// npm update @types/node --save-dev
```

---

### TypeScript 6.0 — New Defaults and Breaking Changes

TypeScript 6.0 is a **breaking transition release**. All deprecated options work with `"ignoreDeprecations": "6.0"` in tsconfig, but TypeScript 7.0 will remove them. Understand the new defaults before upgrading.

**New compiler defaults:**

| Option | Old Default | New Default | Impact |
|--------|------------|-------------|--------|
| `strict` | `false` | `true` | All code gets full strict checking |
| `module` | `commonjs` | `esnext` | ESM output by default |
| `target` | `es5` | `es2025` | Modern JavaScript assumed; no downleveling |
| `types` | `["*"]` (all @types) | `[]` (none) | Must add `"types": ["node"]` etc. explicitly |
| `rootDir` | inferred | `.` (tsconfig dir) | May shift output directory structure |

**New ECMAScript APIs added in TS 6.0 (`"target": "es2025"`):**

```typescript
// Temporal API (Stage 4 ECMAScript — built-in types now included)
const tomorrow = Temporal.Now.instant().add({ hours: 24 });
const date = Temporal.PlainDate.from({ year: 2026, month: 5, day: 7 });

// RegExp.escape — safely escape strings for use in RegExp
const userInput = "Hello.World+Foo?";
const safeRegex = new RegExp(RegExp.escape(userInput));
// Previously required: userInput.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

// Map.getOrInsert / Map.getOrInsertComputed — atomic lookup-or-add
const cache = new Map<string, string[]>();
const list = cache.getOrInsert("key", []);        // returns existing or inserts []
const computed = cache.getOrInsertComputed("key2", k => [k]); // lazy computation
```

**Removed / deprecated options requiring action:**

```json
// ❌ Removed — use an external bundler instead:
//   "outFile": "dist/bundle.js"

// ❌ Deprecated — merge into paths:
//   "baseUrl": "./src"
// ✅ Replace with:
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}

// ❌ Deprecated — always enabled now; remove:
//   "esModuleInterop": false
//   "allowSyntheticDefaultImports": false

// ❌ Deprecated module resolution — use nodenext or bundler:
//   "moduleResolution": "node"     (was "node10")
//   "moduleResolution": "classic"
```

**DOM library consolidation:** `lib.dom` now includes `dom.iterable` and `dom.asynciterable` by default — remove explicit entries if present:

```json
// ❌ Redundant in TS 6.0+
{ "lib": ["dom", "dom.iterable", "dom.asynciterable", "esnext"] }

// ✅ Simplified
{ "lib": ["dom", "esnext"] }
```

**`--stableTypeOrdering` flag (migration bridge to TS 7.0):** TypeScript 7.0 will introduce deterministic union type ordering. Enable this flag in TypeScript 6.0 to match TS 7.0 behavior now (at up to 25% compile slowdown). Useful for catching declaration emit ordering differences before upgrading.

---

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
| `import` assertions (`assert {}`) instead of attributes (`with {}`) | Disallowed in `--module nodenext` (TS 5.8+); deprecated in Node 22 | Use `import data from "./f.json" with { type: "json" }` |
| `import defer` for code splitting | `import defer` defers evaluation, not loading; bundle size unchanged | Use dynamic `import()` for true code splitting |
| Missing `verbatimModuleSyntax` | Implicit type-import elision causes hard-to-diagnose circular import issues | Enable `verbatimModuleSyntax: true`; use `import type` for all type-only imports |
| `moduleDetection: "auto"` (default) | Files without `import`/`export` are treated as scripts, polluting global scope | Set `"moduleDetection": "force"` to treat all files as modules |
| `types: []` not set | Every installed `@types/*` package is auto-included, causing duplicate globals | Explicitly list only needed `@types` in `"types": [...]` |



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

---

## TypeScript 5.8 Language Additions

### Granular Return Branch Checks (TypeScript 5.8)

TypeScript 5.8 adds per-branch type checking on conditional expressions directly inside `return` statements. Previously, if a ternary returned `any` on one branch, the `any` silently satisfied the declared return type and masked the type error on the other branch. Now each branch is checked independently.

```typescript
declare const cache: Map<any, any>;

// Before 5.8: no error — the any from cache.get() hid the type mismatch
// After  5.8: Error on the false branch: 'string' is not assignable to 'URL'
function getUrlObject(urlString: string): URL {
  return cache.has(urlString)
    ? cache.get(urlString)    // any — TypeScript defers checking
    : urlString;              // Error: string is not assignable to URL
}

// Fix: explicitly assert or convert the any-typed value
function getUrlObjectSafe(urlString: string): URL {
  return cache.has(urlString)
    ? (cache.get(urlString) as URL)
    : new URL(urlString);
}
```

[community] **Pitfall:** Code that worked under 5.7 may now surface latent type errors after upgrading to 5.8 — especially when caches, registries, or `any`-typed maps are used in ternary return expressions. These are real bugs exposed by tighter checking, not false positives; fix by adding runtime validation or explicit casts with a comment.

---

### `--erasableSyntaxOnly` Flag (TypeScript 5.8)

Node.js 23.6+ supports stripping TypeScript type annotations natively via `--experimental-strip-types`. However, the native stripper only handles erasable syntax — constructs that produce no JavaScript output. `--erasableSyntaxOnly` makes TypeScript error on non-erasable constructs, ensuring your source is safe to run with Node's type-stripping mode.

Non-erasable constructs disallowed under `--erasableSyntaxOnly`:
- `enum` declarations (produce JavaScript objects)
- `namespace` blocks with runtime code (produce IIFEs)
- Parameter properties in class constructors (`constructor(public x: number)`)
- Legacy `import =` and `export =` assignments

```typescript
// ❌ Error under --erasableSyntaxOnly: enum produces runtime JS
enum Direction { Up, Down, Left, Right }
// Fix: use string literal union
type Direction = 'up' | 'down' | 'left' | 'right';

// ❌ Error: parameter property produces runtime code
class Point {
  constructor(public x: number, public y: number) {}
}
// Fix: explicit field declarations
class Point {
  x: number; y: number;
  constructor(x: number, y: number) { this.x = x; this.y = y; }
}

// ❌ Error: namespace with runtime code
namespace Utils {
  export function parse(s: string): number { return parseInt(s, 10); }
}
// Fix: plain ES module exports
export function parse(s: string): number { return parseInt(s, 10); }
```

Use `--erasableSyntaxOnly` when your deployment pipeline relies on Node.js native type-stripping, Deno's built-in TypeScript support, or any tool (esbuild, swc) that does comment-removal-only transpilation.

---

### `--module node18` and Import Attributes (TypeScript 5.8)

TypeScript 5.8 adds `--module node18` as a stable flag targeting Node.js 18 semantics, in contrast to `--module nodenext` which tracks the latest Node.js stable release.

Under `--module nodenext` (TypeScript 5.8+), the legacy `assert` import syntax is disallowed in favour of `with` (import attributes):

```typescript
// ❌ Disallowed under --module nodenext (TypeScript 5.8+)
import data from "./data.json" assert { type: "json" };

// ✅ Use import attributes (TC39 Stage 3 / Node.js 22+)
import data from "./data.json" with { type: "json" };
```

---

## TypeScript 5.9 Language Additions

### `import defer` — Lazy Module Evaluation (TypeScript 5.9)

`import defer` defers the evaluation of a module's side effects until the first time you access an export from it. The module is still resolved and parsed eagerly, but its top-level code does not run until the namespace is first accessed.

```typescript
// Module imported but NOT yet evaluated — no side effects yet
import defer * as analytics from "./analytics.js";

function trackEvent(name: string): void {
  // analytics is evaluated here on first access
  analytics.record(name); // ← module code runs now, on first call
}

// Useful for optional/heavy modules whose cost should be deferred
import defer * as heavyPdf from "./pdf-renderer.js";

async function exportReport(data: ReportData, format: 'csv' | 'pdf'): Promise<Blob> {
  if (format === 'csv') {
    return buildCsv(data); // heavyPdf never evaluated
  }
  return heavyPdf.render(data); // evaluated here, on first use
}
```

Constraints:
- Only namespace imports allowed (`import defer * as name`)
- No named imports (`import defer { foo }` is invalid)
- Requires `--module preserve` or `--module esnext`
- TypeScript does NOT downlevel `import defer` — it requires a runtime that supports the proposal

[community] **Pitfall:** `import defer` does NOT defer network/disk loading — the module file is still fetched eagerly. The only thing deferred is execution. Teams expecting reduced initial load size should use dynamic `import()` instead; `import defer` is for controlling side-effect timing, not code splitting.

---

### Recommended `tsconfig.json` Baseline (TypeScript 5.9+)

TypeScript 5.9's updated `tsc --init` generates a more opinionated baseline. The key additions versus earlier defaults:

```json
{
  "compilerOptions": {
    "strict": true,
    "module": "nodenext",
    "target": "esnext",
    "moduleDetection": "force",
    "verbatimModuleSyntax": true,
    "noUncheckedIndexedAccess": true,
    "noUncheckedSideEffectImports": true,
    "exactOptionalPropertyTypes": true,
    "isolatedModules": true,
    "types": [],
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "skipLibCheck": true
  }
}
```

Key new defaults explained:
- **`verbatimModuleSyntax`** — Replaces the older `importsNotUsedAsValues` and `preserveValueImports` flags. Enforces that `import type` must be used for type-only imports; value imports are preserved as-is in output. Eliminates the confusion about when TypeScript silently drops imports.
- **`moduleDetection: "force"`** — Treats every file as a module (has `import`/`export`), preventing TypeScript from treating files as scripts and accidentally merging declarations into the global scope.
- **`noUncheckedSideEffectImports`** — Errors on `import "./module"` side-effect imports that TypeScript cannot resolve, catching typos in polyfill or CSS import paths.
- **`types: []`** — Disables auto-inclusion of all `@types/*` packages; list only what you need explicitly.

[community] **Pitfall:** `verbatimModuleSyntax` is stricter than `importsNotUsedAsValues: "error"` — it requires `import type` for ALL type-only imports, not just unused ones. Migrating an existing codebase requires a one-time pass to add `type` to all type-only import lines. Use `tsc --verbatimModuleSyntax --noEmit` as a migration check before enabling it permanently.

---

### TSConfig Module & Target Selection

Choosing the wrong `module`/`moduleResolution` pair is the most common tsconfig misconfiguration. Always keep them in sync.

| Project type | `module` | `moduleResolution` | `target` |
|---|---|---|---|
| Node.js 16+ (ESM) | `nodenext` | `nodenext` | `ES2022` |
| Node.js with bundler | `preserve` | `bundler` | `ES2020`+ |
| Legacy CommonJS | `commonjs` | `node10` | `ES2017`+ |
| Browser SPA (bundler) | `preserve` | `bundler` | `ES2020`+ |
| Library (dual CJS+ESM) | `nodenext` | `nodenext` | `ES2020` |

**`nodenext` key behaviour:** automatically selects CJS or ESM output based on the file extension (`.cjs`/`.mjs`) and the `"type"` field in `package.json`. Relative imports in ESM must include the `.js` extension even when the source is `.ts`.

**Commonly misconfigured options and consequences:**

| Misconfiguration | Consequence | Fix |
|---|---|---|
| `"module": "commonjs"` + `"moduleResolution": "node16"` | Mismatched pair — resolution errors on ESM-only packages | Keep module/moduleResolution in sync |
| `"declaration": false` in a library | Consumers receive no type information; IDE shows `any` | Set `"declaration": true` and `"declarationMap": true` |
| `"rootDir"` set but files outside it included | Build failure: file not under rootDir | Use `"composite": true` or adjust `include` |
| `"skipLibCheck": false` | Much slower type-checking; fails on bad third-party `.d.ts` files | Use `"skipLibCheck": true` in app projects |
| Missing `"noUnusedLocals"`/`"noUnusedParameters"` | Dead code accumulates silently | Add both flags to catch cleanup opportunities |
| `"noPropertyAccessFromIndexSignature": false` | Dot notation allowed on index signatures — hides typos | Enable to enforce bracket notation for dynamic keys |

---

### Type-Safe Mocks with `vi.mocked` / `jest.mocked`

When using Vitest or Jest with TypeScript, the `vi.mocked()` / `jest.mocked()` helpers wrap a value with `jest.Mock<T>` / `vi.Mock<T>` type information, giving you fully-typed access to `mockResolvedValue`, `mockImplementation`, and mock call tracking.

```typescript
// src/users/user-service.ts
import type { UserRepository } from './user-repository';

export class UserService {
  constructor(private readonly repo: UserRepository) {}
  async getUser(id: string) { return this.repo.findById(id); }
}

// src/users/user-service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UserService } from './user-service';
import type { UserRepository } from './user-repository';

// Type-safe partial mock: satisfies the interface without implementing every method
function createMockRepo(): vi.Mocked<UserRepository> {
  return {
    findById: vi.fn(),
    save:     vi.fn(),
    delete:   vi.fn(),
  } as vi.Mocked<UserRepository>;
}

describe('UserService', () => {
  let repo: vi.Mocked<UserRepository>;
  let service: UserService;

  beforeEach(() => {
    repo = createMockRepo();
    service = new UserService(repo);
  });

  it('returns user from repository', async () => {
    const user = { id: 'u1', name: 'Alice', email: 'alice@example.com' };
    repo.findById.mockResolvedValue(user);  // fully typed: User | null
    const result = await service.getUser('u1');
    expect(result).toEqual(user);
    expect(repo.findById).toHaveBeenCalledWith('u1');
  });
});
```

[community] **Pitfall:** Casting mock objects with `as unknown as UserRepository` bypasses TypeScript's structural check — the mock silently misses a method when the interface grows and the test still compiles. Use `satisfies` or an explicit interface-implementing object to get a compile error when the interface is updated but the mock is not.

---

### Testing Discriminated Unions — Exhaustiveness in Tests

Use a `never`-typed helper to write tests that fail at compile time when a new union variant is added but no test case handles it.

```typescript
type ApiEvent =
  | { type: 'request';  method: string; url: string }
  | { type: 'response'; status: number; body: string }
  | { type: 'error';    code: number;   message: string };

function processEvent(event: ApiEvent): string {
  switch (event.type) {
    case 'request':  return `${event.method} ${event.url}`;
    case 'response': return `HTTP ${event.status}`;
    case 'error':    return `Error ${event.code}: ${event.message}`;
    default:
      const _never: never = event; // compile error if case added without handler
      throw new Error(`Unhandled event type: ${String(_never)}`);
  }
}

// Test: covers all variants — will fail to compile if ApiEvent gains a new variant
const cases: ApiEvent[] = [
  { type: 'request',  method: 'GET', url: '/api' },
  { type: 'response', status: 200,   body: 'ok' },
  { type: 'error',    code: 404,     message: 'Not found' },
];

describe('processEvent', () => {
  it.each(cases)('handles %j', (event) => {
    expect(() => processEvent(event)).not.toThrow();
  });
});
```

---

### Branded Error Types for Domain Error Hierarchies

Combining branded types with error classes creates a nominally-typed error hierarchy that the compiler can narrow precisely.

```typescript
// Domain error base: branded for nominal identity
type DomainError<Code extends string> = Error & { readonly code: Code };

function createDomainError<Code extends string>(
  code: Code,
  message: string
): DomainError<Code> {
  const err = new Error(message) as DomainError<Code>;
  Object.defineProperty(err, 'code', { value: code, enumerable: true });
  return err;
}

// Specific error factories
const NotFoundError     = (msg: string) => createDomainError('NOT_FOUND', msg);
const ValidationError   = (msg: string) => createDomainError('VALIDATION', msg);
const UnauthorizedError = (msg: string) => createDomainError('UNAUTHORIZED', msg);

// Union of all domain errors — exhaustive matching
type AppError =
  | DomainError<'NOT_FOUND'>
  | DomainError<'VALIDATION'>
  | DomainError<'UNAUTHORIZED'>;

function handleAppError(error: AppError): { status: number; message: string } {
  switch (error.code) {
    case 'NOT_FOUND':     return { status: 404, message: error.message };
    case 'VALIDATION':    return { status: 400, message: error.message };
    case 'UNAUTHORIZED':  return { status: 401, message: error.message };
    // compile error if a new code is added to AppError without a case here
  }
}
```

[community] **Pitfall:** Extending `Error` in TypeScript compiles correctly but `instanceof` checks can fail when transpiling to ES5 — the prototype chain is not correctly set for subclasses. Fix: call `Object.setPrototypeOf(this, new.target.prototype)` in the constructor when targeting ES5, or set `"target": "ES2015"` or higher and rely on native class semantics.

---

## Suppression Pragmas: `@ts-expect-error` vs `@ts-ignore`

TypeScript provides two suppression comments. `@ts-ignore` is the older form; `@ts-expect-error` is always preferred in new code because it self-documents intent AND errors if the suppression becomes unnecessary.

```typescript
// @ts-ignore: silent — will never warn you that the error was fixed
// @ts-ignore
const x: string = 123; // Suppressed. If you later fix this, the comment stays silently.

// @ts-expect-error: loud — compile error if the next line is now valid
// @ts-expect-error TS2322 — TODO: fix when User type is updated
const y: string = 456;
// If you later fix the type mismatch, TypeScript surfaces:
// "Unused '@ts-expect-error' directive."
// This forces cleanup of stale suppressions.

// Best practice: always include the error code and a brief explanation
// @ts-expect-error TS2339 — third-party lib missing .customMethod in its .d.ts
thirdPartyObj.customMethod();
```

[community] **Pitfall:** `@ts-ignore` accumulates silently in codebases undergoing refactoring — after a type is fixed, the suppression persists as dead code and creates confusion ("why was this suppressed?"). Always use `@ts-expect-error` with a TS error code and comment. Configure ESLint rule `@typescript-eslint/prefer-ts-expect-error` to enforce this automatically.

---

## Path Aliases: TypeScript Compile-Time vs Runtime Resolution

`compilerOptions.paths` in `tsconfig.json` tells the TypeScript language service how to resolve paths — but it has NO effect on the JavaScript runtime or Node.js module resolution. Path aliases require additional tooling to work at runtime.

```json
// tsconfig.json — compile-time alias mapping only
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@utils/*": ["utils/*"],
      "@services/*": ["services/*"]
    }
  }
}
```

```typescript
// ✅ TypeScript compiles this without errors
import { formatDate } from '@utils/date';

// ❌ Node.js runtime: "Cannot find module '@utils/date'"
//    The paths mapping is stripped at emit — JS has no knowledge of it
```

Runtime resolution options by build tool:
- **Vite / esbuild** — Use the `paths` object in `vite.config.ts` or `esbuild` alias config
- **Webpack** — `resolve.alias` in `webpack.config.js`  
- **Jest / Vitest** — `moduleNameMapper` in `jest.config.ts` / `resolve.alias` in `vitest.config.ts`
- **Pure Node.js (no bundler)** — Use `tsconfig-paths/register` or Node `--import` with a custom resolver

[community] **Pitfall:** Teams often discover that path aliases work in development (because Vite/webpack resolves them) but break in Jest tests or standalone Node scripts where the bundler is absent. The fix is to configure `moduleNameMapper` in Jest to mirror the `tsconfig.json` paths object — they must be kept in sync manually, or use a helper like `jest-tsconfig-paths` to derive the mapping automatically.

---

## TypeScript Go Port (tsgo) — Preview and Future Direction

Microsoft is rewriting the TypeScript compiler in Go (`@typescript/native-preview`, `npx tsgo`). The Go port aims for **10× faster build times** compared to the Node.js compiler. Understanding its implications helps teams make forward-compatible choices today.

```json
// Try the preview without changing your project
// No tsconfig changes needed — tsgo is a drop-in replacement for tsc
```

```typescript
// package.json scripts — evaluate tsgo alongside tsc
{
  "scripts": {
    "typecheck":         "tsc --noEmit",
    "typecheck:preview": "tsgo --noEmit"  // npx @typescript/native-preview
  }
}
```

**Status (as of mid-2026):** Type checking and program creation are feature-complete. Language service, JSDoc inference, and the public Compiler API are still in progress. The repo will eventually merge into the main `microsoft/TypeScript` repository.

**Forward-compatible practices today:**
- Use `--erasableSyntaxOnly` mode — the Go compiler only supports type-erasable syntax natively
- Avoid `const enum` in library code (inlining is not supported by the native stripper)
- Prefer interfaces over complex intersection types (caching benefits apply to both compilers)
- Write explicit return type annotations on exported functions (`isolatedDeclarations`) to maximize parallelism in the new compiler architecture

[community] **Pitfall:** Teams that rely on TypeScript's compiler API (`ts.createProgram`, language service) for custom tooling (linters, codegen) will need to wait for the full API port before migrating. The Go compiler's public API is intentionally not yet stable — do not depend on `@typescript/native-preview`'s internal structures for production tooling.

---

## `satisfies` Operator — Advanced Patterns

The `satisfies` operator (TypeScript 4.9+) validates a value against a type without widening the inferred type. This enables patterns that previously required either unsafe `as` casts or noisy type annotations. Below are advanced use cases beyond the basic example in the Language Idioms section.

```typescript
// Pattern 1: Config objects with autocomplete + narrow literals
type AppConfig = {
  port: number;
  env: 'development' | 'production' | 'test';
  features: Record<string, boolean>;
};

// Without satisfies: config.port is number (wide) — or use 'as const' losing the type check
// With satisfies: config.port is 3000 (narrow) AND shape is verified
const config = {
  port: 3000,
  env: 'development',
  features: { darkMode: true, betaApi: false },
} satisfies AppConfig;

config.port; // 3000 (literal, not number)
config.env;  // 'development' (literal, not 'development' | 'production' | 'test')

// Pattern 2: Validated route map — keys checked + values narrow
type RouteHandler = (req: Request, res: Response) => void;

const routes = {
  '/users':        (req, res) => { /* ... */ },
  '/products':     (req, res) => { /* ... */ },
  '/health':       (req, res) => { res.send('ok'); },
} satisfies Record<string, RouteHandler>;

// routes['/users'] is (req: Request, res: Response) => void
// routes['/nonexistent'] would be a compile error if accessed via keyof typeof routes

// Pattern 3: Discriminated union validation without casting
type Event =
  | { type: 'click'; x: number; y: number }
  | { type: 'keydown'; key: string };

// satisfies ensures each element matches Event — compile error if shape is wrong
const events = [
  { type: 'click', x: 10, y: 20 },
  { type: 'keydown', key: 'Enter' },
] satisfies Event[];
// events[0].x is number (narrow), not unknown

// Pattern 4: Exhaustive record completion
type Status = 'active' | 'inactive' | 'pending';
type StatusLabel = Record<Status, string>;

// satisfies errors if a status key is missing — exhaustiveness enforced at definition
const statusLabels = {
  active: 'Active',
  inactive: 'Inactive',
  pending: 'Pending Review',
} satisfies StatusLabel;
```

[community] **Pitfall:** `satisfies` does not narrow type on assignment — the inferred type is based on the literal value, not the constraint type. So `const x = { a: 1 } satisfies { a: number }` gives `x.a` the type `1`, not `number`. This is the intended behavior but confuses teams expecting type narrowing. When you need the wider type for later assignment (`x.a = 2`), annotate explicitly: `const x: { a: number } = { a: 1 }`.

---

## React + TypeScript Patterns

### Component Props and Children

```tsx
// Use interface for component props — enables declaration merging and compiler caching
interface ButtonProps {
  /** Text label displayed inside the button */
  label: string;
  /** Disables interaction when true */
  disabled?: boolean;
  /** Called when the button is activated */
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  /** Renders arbitrary content inside the button */
  children?: React.ReactNode;
}

function Button({ label, disabled = false, onClick, children }: ButtonProps) {
  return (
    <button disabled={disabled} onClick={onClick}>
      {children ?? label}
    </button>
  );
}

// Discriminated union for polymorphic components
type LinkProps =
  | { variant: 'internal'; to: string }
  | { variant: 'external'; href: string; target?: string };

function Link({ variant, children, ...rest }: LinkProps & { children: React.ReactNode }) {
  return variant === 'internal'
    ? <a href={(rest as { to: string }).to}>{children}</a>
    : <a href={(rest as { href: string }).href} rel="noopener noreferrer">{children}</a>;
}
```

---

### `useRef` Typing Patterns

`useRef` has three overloads; the one you choose determines whether the ref is mutable or read-only.

```tsx
import { useRef, useEffect } from 'react';

// Read-only ref to a DOM element (initial value null, connected by React)
// Use this for refs passed to the ref prop on a JSX element
function AutoFocusInput() {
  const inputRef = useRef<HTMLInputElement>(null);  // RefObject<HTMLInputElement>
  useEffect(() => { inputRef.current?.focus(); }, []);
  return <input ref={inputRef} />;
}

// Mutable ref for holding a mutable value (not connected to DOM)
// Pass undefined (not null) to get MutableRefObject<T>
function Timer() {
  const intervalRef = useRef<ReturnType<typeof setInterval>>(undefined);
  const start = () => { intervalRef.current = setInterval(() => {}, 1000); };
  const stop  = () => { clearInterval(intervalRef.current); };
  return <><button onClick={start}>Start</button><button onClick={stop}>Stop</button></>;
}
```

[community] **Pitfall:** Passing `null` vs `undefined` as the initial value to `useRef` determines which overload TypeScript picks and therefore whether `current` is mutable. `useRef<HTMLElement>(null)` gives `RefObject<HTMLElement>` where `current` is `HTMLElement | null` (read-only). `useRef<number>(undefined)` gives `MutableRefObject<number | undefined>` where `current` is directly assignable. Using the wrong overload causes spurious `readonly` errors when trying to set the ref imperatively.

---

### Context API with Type Safety

```tsx
import { createContext, useContext, useState } from 'react';

interface AuthContext {
  user: User | null;
  login:  (credentials: { email: string; password: string }) => Promise<void>;
  logout: () => void;
}

// Use a non-null assertion in the default to avoid null-checks at every call site
// The actual null-guard lives in the provider pattern below
const AuthCtx = createContext<AuthContext | null>(null);

// Custom hook narrows null away — throws descriptively if used outside provider
function useAuth(): AuthContext {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}

// Provider implements the full contract
function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const login  = async ({ email, password }: { email: string; password: string }) => {
    const u = await apiLogin(email, password);
    setUser(u);
  };
  const logout = () => setUser(null);
  return <AuthCtx.Provider value={{ user, login, logout }}>{children}</AuthCtx.Provider>;
}
```

### `useState` with Union Types

```tsx
// Union state: always provide explicit type parameter — inference from initial value is too narrow
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error';   message: string };

function useFetch<T>(url: string) {
  const [state, setState] = useState<RequestState<T>>({ status: 'idle' });

  const fetch_ = async () => {
    setState({ status: 'loading' });
    try {
      const data = await globalThis.fetch(url).then(r => r.json() as Promise<T>);
      setState({ status: 'success', data });
    } catch (err) {
      setState({ status: 'error', message: err instanceof Error ? err.message : String(err) });
    }
  };

  return { state, fetch: fetch_ };
}
```

[community] **Pitfall:** `useState<Status>("idle")` where `type Status = "idle" | "loading"` works, but `useState("idle")` without the explicit generic infers `"idle"` as the literal type — `setStatus("loading")` then errors because `"loading"` is not assignable to `"idle"`. Always provide the explicit type parameter for union state.

---

## Concurrency Patterns — Typed `Promise.all` and `Promise.allSettled`

TypeScript infers precise tuple types from `Promise.all` and `Promise.allSettled` calls, provided you keep the array literal inline (not assigned to an intermediate `Promise[]` variable).

```typescript
// Promise.all — infers a tuple of resolved types, preserving position
async function loadDashboard(userId: string) {
  const [user, orders, settings] = await Promise.all([
    fetchUser(userId),      // Promise<User>
    fetchOrders(userId),    // Promise<Order[]>
    fetchSettings(userId),  // Promise<Settings>
  ]);
  // user: User — NOT (User | Order[] | Settings)
  // orders: Order[]
  // settings: Settings
  // Fails fast on first rejection — use only when all must succeed
  return { user, orders, settings };
}

// Promise.allSettled — each result is PromiseSettledResult<T>
// Use when partial success is acceptable (e.g., enrichment calls)
async function enrichProfile(userId: string) {
  const [userResult, activityResult, badgesResult] = await Promise.allSettled([
    fetchUser(userId),        // Promise<User>
    fetchActivity(userId),    // Promise<Activity[]>
    fetchBadges(userId),      // Promise<Badge[]>
  ]);
  // userResult: PromiseFulfilledResult<User> | PromiseRejectedResult

  const user     = userResult.status     === 'fulfilled' ? userResult.value     : null;
  const activity = activityResult.status === 'fulfilled' ? activityResult.value : [];
  const badges   = badgesResult.status   === 'fulfilled' ? badgesResult.value   : [];
  return { user, activity, badges };
}

// Promise.race — narrows to union of resolved types
async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
  );
  return Promise.race([promise, timeout]);
  // Type: T — because never is absorbed into T in a union
}
```

[community] **Pitfall:** Assigning the array to an intermediate variable before passing to `Promise.all` widens the element types to their common supertype, losing the tuple inference: `const tasks: Promise<unknown>[] = [fetchUser(), fetchOrders()]; const [u, o] = await Promise.all(tasks)` gives `[unknown, unknown]`. Always pass the array literal directly to `Promise.all` to preserve positional types.

---

## `Awaited<T>` — Unwrapping Nested Promises

`Awaited<T>` (built-in since TypeScript 4.5) recursively unwraps Promise types — including nested `Promise<Promise<T>>` chains that arise when composing async functions.

```typescript
// Basic: unwrap a single Promise
type A = Awaited<Promise<string>>;           // string
type B = Awaited<Promise<Promise<number>>>;  // number (recursive)
type C = Awaited<string>;                    // string (non-Promise passthrough)

// Practical: extract the resolved type from any async function
async function fetchUserOrNull(id: string): Promise<User | null> {
  return id ? fetchUser(id) : null;
}

// Derive the return type without re-stating it
type FetchResult = Awaited<ReturnType<typeof fetchUserOrNull>>;
// FetchResult: User | null

// Combining with mapped types: create a parallel sync version of an async API
type SyncApi<T extends Record<string, (...args: unknown[]) => Promise<unknown>>> = {
  [K in keyof T]: (...args: Parameters<T[K]>) => Awaited<ReturnType<T[K]>>;
};

interface AsyncUserService {
  findById(id: string): Promise<User>;
  create(data: CreateUserInput): Promise<User>;
}

type SyncUserService = SyncApi<AsyncUserService>;
// { findById(id: string): User; create(data: CreateUserInput): User }
```

---

## Enum Alternatives — When to Avoid TypeScript Enums

TypeScript enums have several surprising behaviors that lead practitioners to prefer alternatives. The table below summarizes the tradeoffs:

| Approach | Runtime Cost | Nominal | Reversible | Treeshakeable | Tooling |
|---|---|---|---|---|---|
| `enum Status { Active = 'active' }` | Yes (object) | Yes (string) | Yes | No | Excellent |
| `const enum Status { Active }` | No (inlined) | Numeric only | No | N/A | Breaks with Babel/esbuild |
| `type Status = 'active' \| 'inactive'` | No | No | N/A | N/A | Excellent |
| `const STATUS = { Active: 'active', Inactive: 'inactive' } as const` | Yes (tiny obj) | No | Yes | Yes | Excellent |
| Branded type | No | Yes | N/A | N/A | Good |

**When to use each:**

```typescript
// 1. String enum (safest general-purpose choice)
//    + nominal: Status.Active !== 'active' from another enum
//    + reversible: find label from value
//    - not tree-shakeable (emits a JS object)
enum HttpStatus {
  Ok         = 200,
  NotFound   = 404,
  InternalServerError = 500,
}

// 2. String literal union (most common for simple cases)
//    + zero runtime cost   + great inference   + tree-shakeable
//    - not reversible without iteration
type Severity = 'low' | 'medium' | 'high' | 'critical';

// 3. as-const object (best of both worlds for lookup tables)
//    + reversible   + tree-shakeable   + autocomplete on values
//    - structural, not nominal
const SEVERITY = {
  Low:      'low',
  Medium:   'medium',
  High:     'high',
  Critical: 'critical',
} as const;

type Severity = typeof SEVERITY[keyof typeof SEVERITY];
// 'low' | 'medium' | 'high' | 'critical'

// Reverse lookup: key from value
type SeverityKey = { [K in keyof typeof SEVERITY]: typeof SEVERITY[K] extends Severity ? K : never }[keyof typeof SEVERITY];
// 'Low' | 'Medium' | 'High' | 'Critical'
```

[community] **Pitfall:** Numeric enums allow reverse-mapping (`Status[0] === 'Active'`) but this creates a dual-key object (`{ Active: 0, 0: 'Active' }`). Iterating `Object.keys(Status)` returns both numeric strings and member names — doubling all keys. This breaks serialization and surprises `for..in` loops. Use string enums or `as const` objects unless you specifically need bidirectional lookup.

---

## Mapped Type Filtering — Deep Utilities

Complex mapped types can filter, reshape, and flatten type structures. These patterns appear in framework internals and utility libraries (type-fest, ts-toolbelt).

```typescript
// Filter properties by value type (string properties only)
type StringProperties<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};

interface Entity {
  id: string;
  name: string;
  count: number;
  active: boolean;
  tags: string[];
}

type EntityStringProps = StringProperties<Entity>;
// { id: string; name: string }

// Filter by required vs optional properties
type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K;
}[keyof T];

type OptionalKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? K : never;
}[keyof T];

type Req = RequiredKeys<Entity>;  // 'id' | 'name' | 'count' | 'active' | 'tags'

// Deep readonly — recursively apply readonly
type DeepReadonly<T> = T extends (infer U)[]
  ? ReadonlyArray<DeepReadonly<U>>
  : T extends object
  ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
  : T;

interface Config {
  server: { host: string; port: number };
  database: { url: string; pool: { min: number; max: number } };
}

type ImmutableConfig = DeepReadonly<Config>;
// { readonly server: { readonly host: string; readonly port: number }; ... }

// Flatten a union of objects to a single intersection
type UnionToIntersection<U> =
  (U extends unknown ? (x: U) => void : never) extends (x: infer I) => void
  ? I : never;

type A = { a: string };
type B = { b: number };
type C = { c: boolean };

type ABC = UnionToIntersection<A | B | C>;
// { a: string } & { b: number } & { c: boolean }
```

[community] **Pitfall:** `DeepReadonly` with circular types (e.g., a tree node referencing its own type) causes TypeScript to report "Type instantiation is excessively deep and possibly infinite." Fix: add a depth limit via a tuple counter type parameter, or switch to a non-recursive approach using `Readonly<T>` at each manually typed level for the known depth.

---

## Migrating to Strict Mode — Incremental Path

Enabling `strict: true` on an existing codebase of any size is painful if done all at once. The staged approach below lets you add strictness incrementally without blocking commits.

```json
// Stage 1: Enable only the lowest-friction flags first
// tsconfig.strict-migration.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

```typescript
// Step-by-step migration order (each step independent):
// 1. noImplicitAny            — force explicit types on all parameters
// 2. strictNullChecks         — handle null/undefined (biggest change)
// 3. strictFunctionTypes      — function parameter contravariance
// 4. strictPropertyInitialization — class field init in constructor
// 5. noImplicitReturns        — all code paths must return
// 6. noUnusedLocals           — remove dead variables
// 7. noUnusedParameters       — remove dead parameters
// 8. exactOptionalPropertyTypes — distinguish absent vs undefined
// 9. noImplicitOverride       — add override keyword
// 10. noUncheckedIndexedAccess — guard array/dict access

// Enable flags one at a time in tsconfig.json;
// use @ts-expect-error with a migration ticket number to suppress
// errors you plan to fix in a follow-up:
function legacyFunction(data: any) {  // will fix in PROJ-123
  // @ts-expect-error PROJ-123 — migrate to typed params
  return process(data);
}
```

**Practical migration commands:**

```bash
# Count errors per flag before enabling
npx tsc --noEmit --strictNullChecks 2>&1 | grep "error TS" | wc -l

# List all files with errors to prioritize
npx tsc --noEmit --strictNullChecks 2>&1 | grep "\.ts(" | sed 's/(.*//g' | sort -u

# Auto-fix some noImplicitAny issues with ts-migrate
npx ts-migrate migrate ./src
```

[community] **Pitfall:** Teams often try to fix `strictNullChecks` by adding `!` non-null assertions everywhere — `user!.name` becomes the new `any`. This silences the compiler without fixing the actual null-handling problem and creates runtime crashes that are harder to trace than TypeScript errors. Fix: use optional chaining (`user?.name ?? 'Anonymous'`) for access, and proper null guards at data ingestion points.

---

## Toolchain Summary — tsconfig Flag Evolution

The table below tracks key compiler flags and the TypeScript version that introduced them, for teams upgrading from older configs:

| Flag | Introduced | Recommended Setting | Replaces / Notes |
|---|---|---|---|
| `strict` | 2.3 | `true` | Umbrella: activates 8+ sub-flags |
| `strictNullChecks` | 2.0 | `true` (via `strict`) | — |
| `noUncheckedIndexedAccess` | 4.1 | `true` | Not in `strict` umbrella |
| `useUnknownInCatchVariables` | 4.4 | `true` (via `strict`) | Previously `any` in catch |
| `exactOptionalPropertyTypes` | 4.4 | `true` | Not in `strict` umbrella |
| `noImplicitOverride` | 4.3 | `true` | Not in `strict` umbrella |
| `satisfies` operator | 4.9 | Use explicitly | Not a flag — language feature |
| `override` keyword | 4.3 | Use with `noImplicitOverride` | Not a flag — language feature |
| `moduleResolution: "bundler"` | 5.0 | For bundler projects | Replaces `"node"` |
| `moduleResolution: "nodenext"` | 4.7 | For Node.js ESM | Replaces `"node16"` |
| `verbatimModuleSyntax` | 5.0 | `true` | Replaces `importsNotUsedAsValues` |
| `isolatedDeclarations` | 5.5 | `true` (monorepos) | Enables parallel `.d.ts` emit |
| `noUncheckedSideEffectImports` | 5.9 | `true` | New in TS 5.9 baseline |
| `moduleDetection: "force"` | 4.7 | `"force"` | Prevents implicit script mode |
| `erasableSyntaxOnly` | 5.8 | `true` (Node.js strips types) | For type-strip deployments |

---

## Performance Diagnostics — Investigate Before Optimising

TypeScript provides built-in tools to diagnose slow builds. Always measure before adding project references or refactoring types.

```bash
# Extended diagnostics: shows file counts, type instantiation time, output file sizes
npx tsc --extendedDiagnostics --noEmit

# Identify which files are included (use to catch accidental node_modules crawl)
npx tsc --listFiles --noEmit | head -50

# Generate a build trace for deep analysis in Chrome DevTools (Perfetto UI)
npx tsc --generateTrace ./trace-output --noEmit
# Open trace-output/trace.json in https://ui.perfetto.dev

# Find the 10 slowest type instantiations
npx tsc --extendedDiagnostics 2>&1 | grep "Instantiations" -A 20
```

**Common findings and fixes:**

| Symptom from `--extendedDiagnostics` | Root Cause | Fix |
|---|---|---|
| High `Files` count (>2× source count) | `include` crawls `node_modules` | Add `"exclude": ["**/node_modules", "**/.*/"]` |
| High `Types` count (>100k) | Complex mapped/conditional types | Name and cache intermediate types |
| High `Instantiations` count | Large union pairwise checks | Replace wide unions with interface hierarchy |
| Slow `Check time` despite few files | Missing `incremental` | Add `"incremental": true` + `.tsbuildinfo` |
| `Parse time` dominates | No file filtering | Explicit `"include"` list instead of directory scan |

[community] **Pitfall:** Teams run `tsc --generateTrace` once, see a complex trace, and immediately start refactoring types without reading the trace. The trace's "Heavy" nodes are not always in your own code — they are often in `node_modules/.d.ts` files. Check the **file column** in each heavy instantiation before assuming your types are the bottleneck.

---

## Production Checklist — TypeScript Project Health

A single-page reference for reviewing a TypeScript project's configuration and practices:

**tsconfig.json**
- [ ] `"strict": true` (and at least TypeScript 5.5+ for latest sub-flags)
- [ ] `"noUncheckedIndexedAccess": true`
- [ ] `"exactOptionalPropertyTypes": true`
- [ ] `"noImplicitOverride": true`
- [ ] `"moduleResolution": "bundler"` or `"nodenext"` (not the legacy `"node"`)
- [ ] `"moduleDetection": "force"` (TS 4.7+ — treat all files as modules)
- [ ] `"verbatimModuleSyntax": true` (TS 5.0+ — explicit `import type`)
- [ ] `"incremental": true` + `.tsbuildinfo` in `.gitignore`
- [ ] `"skipLibCheck": true`
- [ ] `"types": [...]` (explicit — no auto-inclusion)
- [ ] `"include": ["src"]` (explicit — no accidental crawl)

**Code quality**
- [ ] No bare `any` — use `unknown` + type guard at boundaries
- [ ] Runtime validation at external data boundaries (Zod/Valibot/io-ts)
- [ ] Explicit return types on all exported functions
- [ ] `import type` for all type-only imports
- [ ] Discriminated unions for all multi-state data
- [ ] Exhaustiveness check (`never`) in every discriminated union switch
- [ ] No `@ts-ignore` — use `@ts-expect-error` with ticket number
- [ ] `override` keyword on all subclass method overrides

**Architecture**
- [ ] Feature-module structure with controlled barrel exports (no `export *`)
- [ ] Interfaces for service contracts (enables DI + mocking)
- [ ] `interface X extends A, B` for composition (not `type X = A & B`)
- [ ] Branded types for all domain IDs (UserId, OrderId — not plain string)
- [ ] `using` / `await using` for all resource cleanup (TS 5.2+ targets)

**Monorepos (if applicable)**
- [ ] `"composite": true` per package
- [ ] `"references": [...]` at workspace root
- [ ] `"isolatedDeclarations": true` for parallel `.d.ts` emit
