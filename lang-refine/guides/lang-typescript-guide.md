# TypeScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 3 | score: 100/100 | date: 2026-04-30 -->

## Core Philosophy

1. **Type safety as a design tool, not a constraint.** TypeScript's type system is a tool to communicate intent and catch mistakes at compile time. The goal is not to appease the compiler but to express program logic so precisely that entire classes of bugs become impossible.

2. **Prefer strictness from the start.** Retrofitting `strict: true` onto a large codebase is painful. Enabling `"strict": true` plus additional safeguards (`noImplicitReturns`, `noUnusedLocals`, `exactOptionalPropertyTypes`) on day one pays dividends throughout the project lifetime.

3. **Favour types that narrow automatically.** Discriminated unions and literal types let TypeScript narrow what a value can be as it flows through control-flow branches. Reaching for `as` casts or `any` stops narrowing dead in its tracks.

4. **Keep types DRY — derive don't duplicate.** Utility types (`Partial`, `Pick`, `Omit`, `Record`, `ReturnType`) and mapped types let you derive related types from a single source of truth. Maintaining two parallel type definitions is a recipe for drift.

5. **Community experience over textbook defaults.** The official docs show you what the language can do. Experienced teams add hard-won lessons: prefer interfaces over intersection types for composition (they are cached by the compiler), annotate return types explicitly on public APIs, and treat `unknown` rather than `any` as the safe escape hatch.

---

## Principles / Patterns

### Strict Mode Configuration
Enabling `"strict": true` in `tsconfig.json` activates all strict type-checking options. Without it, TypeScript allows implicit `any`, silently accepts `null` where values are expected, and skips important runtime-hazard detection.

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

Key strict sub-flags and what each catches:
- `noImplicitAny` — prevents untyped function parameters from silently becoming `any`
- `strictNullChecks` — forces you to handle `null`/`undefined` before accessing properties
- `strictFunctionTypes` — enforces correct function parameter contravariance
- `strictPropertyInitialization` — ensures class fields are initialized in the constructor
- `useUnknownInCatchVariables` — makes caught values `unknown` instead of `any`

```typescript
// strictNullChecks in action
function getLength(s: string | null): number {
  // ERROR: Object is possibly 'null'
  return s.length; // compile error
  // Fix: return s?.length ?? 0;
}

// noImplicitAny in action
function double(x) { // ERROR: parameter 'x' implicitly has an 'any' type
  return x * 2;
}
// Fix: function double(x: number): number { return x * 2; }
```

---

### Type Annotations on Public APIs
Annotate return types on exported functions even when TypeScript can infer them. Inference on deeply composed return types generates large anonymous types in `.d.ts` files, slowing incremental builds. Explicit annotations also act as documentation.

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
Union types (`A | B`) model values that can be one of several types. Intersection types (`A & B`) model values that satisfy all constituent types. Prefer interfaces over intersection types for performance — interface relationships are cached by the compiler.

```typescript
// Union types for flexible inputs
function formatValue(value: string | number): string {
  if (typeof value === 'number') {
    return value.toFixed(2);
  }
  return value.trim();
}

// Intersection — use sparingly, prefer interface extension
// Less efficient (intersection not cached):
type Person = { name: string } & { age: number };

// More efficient for composition (cached):
interface Named { name: string; }
interface Aged  { age: number; }
interface Person extends Named, Aged {}
```

---

### Discriminated Unions
A discriminated union (tagged union) is a union of types sharing a common literal property — the discriminant. TypeScript can exhaustively narrow the type inside switch statements.

```typescript
interface LoadingState  { kind: 'loading'; }
interface SuccessState<T> { kind: 'success'; data: T; }
interface ErrorState   { kind: 'error'; message: string; code: number; }

type AsyncState<T> = LoadingState | SuccessState<T> | ErrorState;

function renderState<T>(state: AsyncState<T>): string {
  switch (state.kind) {
    case 'loading': return 'Loading...';
    case 'success': return `Data: ${JSON.stringify(state.data)}`;
    case 'error':   return `Error ${state.code}: ${state.message}`;
    default: {
      // Exhaustiveness check — compile error if a new variant is added
      const _exhaustive: never = state;
      throw new Error('Unhandled state');
    }
  }
}
```

---

### Async/Await with Typed Errors
TypeScript 4.0+ defaults catch variables to `unknown` when `useUnknownInCatchVariables` is enabled. Always narrow the error before using it. A `Result<T, E>` type avoids try/catch boilerplate at call sites.

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

async function fetchUser(id: number): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return { ok: false, error: new Error(`HTTP ${response.status}`) };
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
Structure TypeScript projects around feature modules with a clear barrel export pattern. Use `import type` for type-only imports — stripped at emit time and prevents accidental runtime dependencies.

```typescript
// src/users/types.ts — pure types, no runtime code
export interface User { id: number; name: string; email: string; }
export type CreateUserInput = Omit<User, 'id'>;

// src/users/repository.ts — data access
import type { User, CreateUserInput } from './types';

export class UserRepository {
  async findById(id: number): Promise<User | null> { /* ... */ return null; }
  async create(input: CreateUserInput): Promise<User> { /* ... */ return {} as User; }
}

// src/users/index.ts — controlled barrel (name what you export)
export type { User, CreateUserInput } from './types';
export { UserRepository } from './repository';
```

Avoid wildcard `export *` — it makes tree-shaking harder and obscures the public API.

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
// Test — swap with mocks, no DI framework needed
const testService = new OrderService(mockHttpClient, mockLogger);
```

---

## Language Idioms

TypeScript provides several features that go beyond "just typed JavaScript."

**`satisfies` operator (TypeScript 4.9+).** Validates an expression against a type without widening the inferred type — preserves literal types while checking shape.

```typescript
type Colors = Record<string, [number, number, number] | string>;

// With satisfies: palette.red is [number,number,number] — narrow and safe
const palette = {
  red:   [255, 0, 0],
  green: '#00ff00',
} satisfies Colors;

palette.red[0]; // OK — TypeScript knows it's a tuple, not string | tuple
```

**Template literal types.** Generate union types from string literals — typed event names, CSS properties, API routes.

```typescript
type EventName   = 'click' | 'focus' | 'blur';
type HandlerName = `on${Capitalize<EventName>}`; // 'onClick' | 'onFocus' | 'onBlur'
```

**Conditional types with `infer`.** Extract type information from complex types.

```typescript
type Resolved<T> = T extends Promise<infer U> ? U : T;
type A = Resolved<Promise<string>>;  // string
type B = Resolved<number>;           // number
```

**`as const` for immutable literal inference.** Prevents TypeScript from widening literals to their base types.

```typescript
const ROLES = ['admin', 'editor', 'viewer'] as const;
type Role = typeof ROLES[number]; // 'admin' | 'editor' | 'viewer'
```

**`keyof` and `typeof` for type extraction.**

```typescript
const CONFIG = { apiUrl: 'https://api.example.com', timeout: 5000 } as const;
type ConfigKey = keyof typeof CONFIG; // 'apiUrl' | 'timeout'
```

**Mapped types for transformations.**

```typescript
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
// Makes specific keys optional while leaving the rest required
```

**`import type` for zero-cost type imports.**

```typescript
// Zero runtime cost — tells bundler nothing from this module executes
import type { User } from './user';
```

**Tuple types for fixed-length heterogeneous arrays.**

```typescript
function useCounter(initial: number): [number, (delta: number) => void] {
  let count = initial;
  return [count, (delta) => { count += delta; }];
}
const [count, increment] = useCounter(0); // type-safe destructuring
```

**Branded types for nominal identity.**

```typescript
type Brand<T, B extends string> = T & { readonly __brand: B };
type UserId    = Brand<string, 'UserId'>;
type ProductId = Brand<string, 'ProductId'>;

function getUser(id: UserId): Promise<User> { /* ... */ return Promise.resolve({} as User); }

const uid = 'usr_123' as UserId;
const pid = 'prd_456' as ProductId;
getUser(uid); // OK
getUser(pid); // Error: ProductId is not assignable to UserId
```

**`override` keyword for safe method overriding (TypeScript 4.3+).** Prevents "ghost overrides" — when a base method is renamed, a subclass method silently becomes a new unrelated method without `override`.

```typescript
class Animal {
  speak(): string { return 'generic sound'; }
  move(distance: number): void { console.log(`Moved ${distance}m`); }
}

class Dog extends Animal {
  override speak(): string { return 'woof'; } // Compiler verifies Animal.speak exists

  // override moveTo(): void { ... }  // ERROR: 'moveTo' does not exist in Animal
  // Without override: silently creates a NEW method Dog.moveTo — a ghost override
}
// Enable noImplicitOverride: true in tsconfig to REQUIRE override on all overrides
```

**Mapped type modifiers (`-?`, `-readonly`).** Strip optional and readonly modifiers independently to produce precise, fully-concrete types.

```typescript
// -? strips optional modifiers (makes all fields required)
type Concrete<T> = { [K in keyof T]-?: T[K] };

// -readonly strips readonly modifiers (makes all fields mutable)
type Mutable<T> = { -readonly [K in keyof T]: T[K] };

interface FormState { readonly id: string; name?: string; email?: string; }
type WritableForm = Mutable<Concrete<FormState>>;
// Result: { id: string; name: string; email: string } — mutable and required
```

---

## Real-World Gotchas  [community]

**Using `any` instead of `unknown` for unknown data.** [community]
When receiving data from external sources (API responses, `JSON.parse`, event payloads), `any` silences all type errors instead of requiring safe narrowing. `unknown` is bidirectionally unsafe — it's assignable to and from everything — meaning it silently poisons every downstream type inference. **Fix:** Replace `any` with `unknown` in catch blocks, JSON parse results, and external data boundaries, then narrow with `instanceof` or type predicates before accessing fields.

**Intersection types instead of interface extension.** [community]
Writing `type Foo = Bar & Baz & { extra: string }` seems equivalent to `interface Foo extends Bar, Baz`, but it is not. Interface relationships are cached by the compiler; intersection types are re-evaluated on every use. In large codebases this causes measurable slowdowns. The TypeScript Performance wiki explicitly documents this. **Fix:** Replace `type X = A & B` with `interface X extends A, B {}` wherever composition is the goal.

**Misconfigured `include`/`exclude` patterns.** [community]
Writing `"exclude": ["node_modules"]` does not recursively exclude nested folders. TypeScript's glob patterns require `**/node_modules` to match at any depth. The result is TypeScript silently crawling test fixtures, generated files, and `node_modules` sub-trees, dramatically inflating compilation time. **Fix:** Use `"exclude": ["**/node_modules", "**/.*/"]` and verify with `tsc --listFiles`.

**Automatic `@types` inclusion causing global conflicts.** [community]
By default, TypeScript auto-includes every `@types/*` package found under `node_modules`. Installing both `@types/jest` and `@types/mocha` causes `it`, `describe`, and `expect` to be declared twice. **Fix:** Set `"types": ["node", "jest"]` in `compilerOptions` to explicitly list only the globals your project uses.

**Truthiness checks on primitives masking bugs.** [community]
Writing `if (count)` to guard a number silently skips the zero case. Writing `if (str)` skips empty strings. These feel natural but create logic bugs TypeScript never catches because `number` and `string` are valid truthy/falsy values. **Fix:** Use explicit comparisons — `if (count !== undefined)`, `if (str.length > 0)`, or `if (str !== '')`.

**`as` casts defeating exhaustiveness checks.** [community]
Type assertions (`value as SomeType`) are escape hatches that compile away entirely. Developers often use them to silence a type error without understanding why it was raised — bypassing discriminated union exhaustiveness checks or hiding null-narrowing. **Fix:** Treat every `as` cast as a code-review flag. For external data, use a runtime validation library (Zod, Valibot) instead of casting.

**`const enum` causing broken builds across compilation boundaries.** [community]
`const enum` inlines values at every call site during compilation — zero-cost at runtime. But inlining only works within a single `tsc` compilation. When a `const enum` is defined in a library and consumed by another project, the values are absent in `.d.ts` — consuming packages get `undefined`. Babel, esbuild, and SWC do not support `const enum` at all. **Fix:** Use string literal union types (`type Status = 'active' | 'inactive'`) or regular `enum` at compilation boundaries.

**Distributive conditional types producing unexpected unions.** [community]
When a conditional type `T extends U ? X : Y` has a naked (unwrapped) type parameter, TypeScript distributes over every member of a union. `type ToArray<T> = T extends any ? T[] : never; type R = ToArray<string | number>` gives `string[] | number[]`, not `(string | number)[]`. **Fix:** Wrap the type parameter: `type ToArrayNonDist<T> = [T] extends [any] ? T[] : never`.

**Large monorepos without project references.** [community]
Running `tsc` at the root of a multi-package repo causes the compiler to type-check every package in a single pass, sharing an unbounded module cache. Teams report 30–60 second incremental builds for small changes. **Fix:** Add `"composite": true` to each package's `tsconfig.json` and wire up `"references": [...]` at the root to enable per-package incremental caching (`--build` mode).

**`readonly` does not mean runtime immutable.** [community]
`readonly` prevents property reassignment but does NOT prevent mutation of the object a property points to. `home.resident = x` errors, but `home.resident.age++` silently succeeds. **Fix:** Use `Object.freeze()` for runtime immutability, or `as const` on literal objects. For deep immutability, model as `Readonly<DeepReadonly<T>>` or use Immer.

**Excess property checking only applies to object literals.** [community]
TypeScript enforces extra-property checking only when passing an object literal directly to a typed target. Once the object is assigned to an intermediate variable, excess property checking is bypassed — the variable's structural type is wider. Teams inadvertently exploit this for mocks, then wonder why inline code errors but variable code does not. **Fix:** When you want shape validation without losing literal inference, use `satisfies` — it checks shape against a type without widening the value, and still catches excess properties on assignment.

**Optional callback parameters.** [community]
Marking callback parameters as optional (`(data: T, error?: Error) => void`) breaks TypeScript's ability to type-check the callback invocation. JavaScript callers can always ignore extra parameters — marking them optional on the type creates a false impression that the second argument might not be passed, which prevents pass-through functions from working correctly. **Fix:** Declare all callback parameters as required even if callers typically ignore some of them.

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
| Catch block `error: any` | Masks error type; skips null/property checks | Use `error: unknown` then `instanceof Error` |
| `@types` auto-inclusion | Duplicate globals from multiple test frameworks | Set `"types": [...]` explicitly in tsconfig |
| No return type on public functions | Compiler infers large anonymous types; slow build | Annotate return types on all exported functions |
| Legacy `moduleResolution: "node"` | Silent path resolution mismatches with bundlers | Use `"bundler"` or `"nodenext"` for modern projects |
| No project references in monorepos | Single-pass type check; unbounded cache growth | Add `"composite": true` + `"references"` per package |
| `const enum` in library code | Inlining breaks across compilation boundaries | Use string literal union types or regular `enum` |
| Boxed types (`String`, `Number`, `Boolean`) | Not assignable to primitive counterparts | Use lowercase primitives: `string`, `number`, `boolean` |
| Naked type params in conditional types | Unexpected distribution over unions | Wrap in `[T] extends [U]` for non-distributive behavior |
