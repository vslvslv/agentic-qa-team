# TypeScript Patterns & Best Practices
<!-- sources: official | community | mixed | iteration: 38 | score: 97/100 | date: 2026-05-12 -->
<!-- iteration trace (latest):
     Iter 38 (2026-05-12): added TypeScript 5.8 — Preserved Computed Property Names in Declaration
       Files (entity-name computed keys no longer produce errors under --declaration, .d.ts no longer
       collapses to broad index signature, isolatedDeclarations incompatibility, backward-compat warning
       for consumers on TS 5.7 and earlier, unique symbol workaround); added TypeScript 5.6 — --build
       with Intermediate Errors (continue-on-error new default, --stopOnBuildErrors opt-out, .tsbuildinfo
       always emitted in build mode, monorepo upgrade workflow benefit); added TypeScript 5.6 — Editor
       Tooling additions (Region-Prioritized Diagnostics: visible-region first at 143ms vs 3330ms full,
       no config required; Auto-Import Exclusion Patterns: autoImportSpecifierExcludeRegexes, regex flags,
       vs. ESLint no-restricted-imports for enforcement); added 3 new rows to TS 5.6-5.7 Anti-Patterns
       table — sourced from typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html and
       typescriptlang.org/docs/handbook/release-notes/typescript-5-6.html (verified 2026-05-12)
     Iter 37 (2026-05-12): added TypeScript 5.7 — Checks for Never-Initialized Variables
       (closure-captured variable use before assignment, with fix patterns);
       added TypeScript 5.7 — ES2024 Target and TypedArray Generic Change (Object.groupBy,
       Map.groupBy, Promise.withResolvers, Promise.withResolvers pattern, Uint8Array<ArrayBuffer>
       generic breaking change and 3 fix options); added TypeScript 5.7 — Validated JSON Imports
       in nodenext (with {type:"json"} required, named imports error, dynamic import pattern) and
       V8 Compile Caching (Node.js 22 + TS 5.7 → 2.5x cold startup, transparent/automatic);
       added TypeScript 5.6 — --strictBuiltinIteratorReturn (strict sub-flag not in umbrella,
       BuiltinIteratorReturn = undefined vs any, iterator done-check example) and Arbitrary Module
       Identifiers (string-keyed exports/imports, WebAssembly use case, CJS compatibility pitfall);
       added 6 new rows to Anti-Patterns table for TS 5.6-5.7 additions — sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-5-7.html and
       typescriptlang.org/docs/handbook/release-notes/typescript-5-6.html (verified 2026-05-12)
-->
<!-- iteration trace (latest):
     Iter 36 (2026-05-12): added TypeScript 5.5 RegExp Syntax Checking section (4 validation types:
       syntax errors, invalid backreferences, named group references, ECMAScript version mismatch;
       gotcha: only checks regex literals, not `new RegExp()` constructor calls; testing relevance:
       regex-based matchers and validation schemas); added TypeScript 5.5 Constant Indexed Access
       Narrowing section (`obj[key]` now narrows when both are const, testing relevance for fixture
       property access by computed key); added TypeScript 5.6 Always-Truthy/Nullish Detection section
       (broader than the version table "Disallow NaN equality" entry — covers regex literals, arrow
       functions, unreachable ?? right operand; testing gotchas for conditional test guards);
       added TypeScript 5.5 `${configDir}` tsconfig template variable section (monorepo path
       portability, contrast with `baseUrl` anti-pattern); added 4 new rows to Anti-Patterns table
       for always-truthy checks, `new RegExp(str)` for regex validation, computed-key narrowing,
       and `${configDir}` vs hardcoded paths — sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html and
       typescriptlang.org/docs/handbook/release-notes/typescript-5-6.html (verified 2026-05-12)
     Iter 35 (2026-05-12): added `using` declaration for test resource cleanup (Disposable interface in
       beforeEach/afterEach), type-safe `expect.extend` custom matchers (Jest MatcherFunction + declare module
       augmentation, Vitest CustomMatcherResult), Vitest 2.x `vi.fn` generic type parameter change
       (single generic vs old two-generic signature, MockedFunction vs Mock), `satisfies` operator for
       exhaustive test fixture type-checking (fixtures validated against discriminated union schema without
       widening), and `Awaited<ReturnType<...>>` pattern for typing async mock return values — sourced from
       jestjs.io/docs/expect, vitest.dev/api/vi.html, vitest.dev/guide/mocking.html (verified 2026-05-12);
       added four new rows to the Anti-Patterns Quick Reference table for the above patterns
     Iter 34 (2026-05-12): added `rootDir` inference removal migration with directory tree example
       (concrete before/after showing dist/src/index.js vs dist/index.js output path shift);
       added `types: ["*"]` anti-pattern with 20-50% build degradation warning (sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html); added `PartialExcept<T,K>`
       combined utility type pattern for update APIs that require some keys mandatory; added community
       pitfall about `tsc --init` TS 5.9 minimal defaults including `"jsx": "react-jsx"` for non-React
       projects; sourced from typescriptlang.org release notes and github.com/microsoft/TypeScript/wiki/Performance
     Iter 33 (2026-05-12): added Generic Parameter Defaults as Overload Replacement section
       (rules, patterns, team pitfalls — replaces multi-overload APIs with single typed declaration);
       added TypeScript 7.0 — Parallel Type Checking and Deterministic Ordering section
       (stableTypeOrdering code example showing ordering divergence, migration timeline, recommended
       practices for preparing today); added community pitfall: variance annotation does not change
       structural type behavior (official docs' own warning, practitioners frequently misapply);
       sourced from typescriptlang.org/docs/handbook/2/generics.html,
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html, and
       github.com/microsoft/typescript-go
     Iter 32 (2026-05-12): added two missing TS 6.0 default changes to the defaults table
<!-- iteration trace (latest):
     Iter 32 (2026-05-12): added two missing TS 6.0 default changes to the defaults table
       (noUncheckedSideEffectImports → true by default; libReplacement → false by default);
       added pprof-it CPU profiling tool to Performance Diagnostics; added TSServer editor
       tracing setting ("typescript.tsserver.enableTracing") to editor performance flags section;
       sourced from typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html and
       github.com/microsoft/TypeScript/wiki/Performance (re-verified 2026-05-12)
     Iter 31 (2026-05-12): added TypeScript 6.0 Removed vs Deprecated precision table — clarifies
       which options are fully removed vs only deprecated (es5 target removed, moduleResolution classic
       removed, esModuleInterop false/allowSyntheticDefaultImports false removed, no-default-lib removed,
       downlevelIteration deprecated, alwaysStrict false deprecated); added --downlevelIteration
       deprecation note; added community pitfall on import assert removal vs import with; sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html (re-verified 2026-05-12)
     Iter 30 (2026-05-12): added Zod v4 Migration Patterns section — new APIs (z.toJSONSchema,
       z.registry, z.file, z.prefault, z.interface), breaking changes from v3 (tuple defaults,
       z.undefined() behavior, stricter string validation), and community pitfall about upgrading
       without running parse() on all data paths; added WeakMap.getOrInsert/getOrInsertComputed
       (ES2025, complementing Map section); added TypeScript 5.9 DOM API Summary Descriptions
       (MDN-based hover summaries for DOM types); added community pitfall: fork-ts-checker vs
       --noCheck parallelization pitfall — sourced from github.com/colinhacks/zod/releases,
       typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html, and
       github.com/microsoft/TypeScript/wiki/Performance
     Iter 29 (2026-05-12): added TypeScript 5.9 — Type Argument Inference Fixes (type variable leak fix,
       may surface new errors on upgrade); added TypeScript 5.9 Expandable Hovers (VS Code preview feature)
       and Configurable Hover Length (js/ts.hover.maximumLength); added TypeScript 6.0 —
       --moduleResolution bundler + --module commonjs migration path as upgrade bridge from deprecated node
       resolution; added community pitfall: isolatedModules vs isolatedDeclarations confusion; added community
       pitfall: tsconfig glob changes invalidating incremental build cache — sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html and
       github.com/microsoft/TypeScript/wiki/Performance
     Iter 28 (2026-05-12): added --explainFiles and --traceResolution to Performance Diagnostics;
       added disableReferencedProjectLoad + disableSolutionSearching editor performance flags;
       added module Foo {} → namespace Foo {} TS 6.0 syntax breaking change with note on declare module;
       added --ignoreConfig flag (TS 6.0 CLI change for file-only compilation);
       added ts5to6 automated migration tool for baseUrl/rootDir changes;
       added staged annotation strategy community insight from TypeScript Performance wiki —
       sourced from github.com/microsoft/TypeScript/wiki/Performance and
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html
     Iter 27 (2026-05-12): added TypeScript 6.0 language features — Subpath Imports starting with `#/`,
       Less Context-Sensitivity on `this`-less Functions (improved inference for method-syntax callbacks),
       `--moduleResolution bundler` + `--module commonjs` combination as a migration path, and ES2025
       Set composition methods (union/intersection/difference/symmetricDifference/isSubsetOf/isSupersetOf/
       isDisjointFrom) and `Promise.try` — sourced from
       typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html and
       developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set
     Iter 26 (2026-05-12): added Template Literal Types deep-dive (type-safe property event source pattern,
       cross-multiplication, intrinsic string utilities with examples, performance anti-pattern for large unions)
       and Utility Types complete reference (ConstructorParameters, ThisParameterType, OmitThisParameter,
       ThisType, and full function/this-type utilities table) — sourced from
       typescriptlang.org/docs/handbook/2/template-literal-types.html and
       typescriptlang.org/docs/handbook/utility-types.html (both new learning-sources catalog entries 2026-05-12)
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
     Iter 25 (2026-05-08): added Mapped Types deep-dive — basic syntax, mapping modifiers (+/- readonly/?)
       key remapping with `as`, template literal property transforms, filtering with `never`,
       union-of-objects remapping, combining with conditional types, built-in utility types implementation
       reference, and anti-patterns table — sourced from
       typescriptlang.org/docs/handbook/2/mapped-types.html
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
| 5.6 | Disallow NaN equality check, iterator helper types, `--strictBuiltinIteratorReturn`, arbitrary module identifiers | — |
| 5.7 | `--noCheck`, path rewriting (`--rewriteRelativeImportExtensions`), never-initialized variable checks, ES2024 target, `TypedArray` generic change, JSON import validation in `nodenext`, V8 compile caching (Node 22+) | — |
| 5.8 | Granular return expression branch checks, `--erasableSyntaxOnly`, `require()` of ESM in `nodenext`, `--module node18`, `--libReplacement` | `"module": "node18"` or `"nodenext"` |
| 5.9 | `import defer`, `--module node20`, minimal `tsc --init`, `noUncheckedSideEffectImports`, `verbatimModuleSyntax`, DOM summary hovers | `"moduleDetection": "force"`, `"verbatimModuleSyntax": true` |
| 6.0 | **Breaking:** `strict`/`esnext`/`es2025` defaults; `types: []`; `outFile`, `baseUrl`, `module amd/umd` removed; Temporal API, `RegExp.escape`, `Map.getOrInsert`; `--stableTypeOrdering`; DOM lib consolidates `dom.iterable`; Subpath imports `#/`; `this`-less function inference; ES2025 `Set` composition methods; `Promise.try` | Update `tsconfig.json` — set `"types": ["node"]`, `"rootDir": "./src"`, migrate `baseUrl` → `paths` |

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

[community] **Staged annotation strategy (from TypeScript Performance wiki):** Adding explicit return types *everywhere* is a blunt instrument. In practice, annotation bottlenecks appear only under specific conditions: deeply nested generics, declaration emit with cross-module references, or incremental builds with expensive `.d.ts` regeneration. The TypeScript Performance wiki recommends a profile-first approach: run `tsc --extendedDiagnostics` and look for high `Check time` paired with high `Types` count. If found, annotate return types on the modules that appear most in the `.d.ts` chain — not across the whole codebase. For new projects, enable `isolatedDeclarations: true` from the start instead, which enforces annotations on all exports without the performance penalty of retrofitting them.

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
| `target` | `es5` | `es2025` | Modern JavaScript assumed; no downleveling. **Note: `"target": "es5"` is fully removed (hard error), not just deprecated.** |
| `types` | `["*"]` (all @types) | `[]` (none) | Must add `"types": ["node"]` etc. explicitly |
| `rootDir` | inferred | `.` (tsconfig dir) | May shift output directory structure |
| `noUncheckedSideEffectImports` | `false` | `true` | Side-effect imports (`import "./polyfill"`) that TypeScript cannot resolve now error by default — catches typos in CSS/polyfill imports |
| `libReplacement` | `true` | `false` | In TS 5.8 `libReplacement: true` let tools swap `lib.*.d.ts` files; TS 6.0 now defaults to `false` (opt-in). Most projects unaffected. |

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

// Set composition methods (ES2025 — requires "target": "es2025" or "esnext")
const setA = new Set([1, 2, 3, 4]);
const setC = new Set([3, 4, 5, 6]);

const union           = setA.union(setC);             // Set {1, 2, 3, 4, 5, 6}
const intersection    = setA.intersection(setC);      // Set {3, 4}
const difference      = setA.difference(setC);        // Set {1, 2}
const symDiff         = setA.symmetricDifference(setC); // Set {1, 2, 5, 6}

const setB = new Set([2, 3]);
const isSubset        = setB.isSubsetOf(setA);        // true  (B ⊆ A)
const isSuperset      = setA.isSupersetOf(setB);      // true  (A ⊇ B)
const isDisjoint      = setA.isDisjointFrom(new Set([10, 11])); // true

// Promise.try — wrap a potentially-throwing sync function as a Promise (ES2025)
// Avoids the split between `new Promise()` for async and try/catch for sync
async function loadConfig(path: string): Promise<Config> {
  return Promise.try(() => JSON.parse(fs.readFileSync(path, 'utf-8')) as Config);
  // If JSON.parse throws, Promise.try returns a rejected promise — no separate try/catch
}
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

// ❌ Deprecated — now **removed** (hard error in TS 6.0, not just deprecated):
//   "esModuleInterop": false    → always-on; remove the flag entirely
//   "allowSyntheticDefaultImports": false → always-on; remove the flag entirely

// ❌ Deprecated module resolution — removed or deprecated:
//   "moduleResolution": "classic"   → REMOVED in TS 6.0 (hard error)
//   "moduleResolution": "node"      → Deprecated (was "node10"); use "bundler" or "nodenext"
```

**DOM library consolidation:** `lib.dom` now includes `dom.iterable` and `dom.asynciterable` by default — remove explicit entries if present:

```json
// ❌ Redundant in TS 6.0+
{ "lib": ["dom", "dom.iterable", "dom.asynciterable", "esnext"] }

// ✅ Simplified
{ "lib": ["dom", "esnext"] }
```

**`--stableTypeOrdering` flag (migration bridge to TS 7.0):** TypeScript 7.0 will introduce deterministic union type ordering. Enable this flag in TypeScript 6.0 to match TS 7.0 behavior now (at up to 25% compile slowdown). Useful for catching declaration emit ordering differences before upgrading.

**`module Foo {}` → `namespace Foo {}` (TypeScript 6.0 syntax error):** The legacy `module` keyword for declaring internal namespaces now produces a hard error in TypeScript 6.0. It was deprecated in favor of `namespace` years ago, but was silently accepted. TypeScript 6.0 enforces the correct spelling:

```typescript
// ❌ Error in TypeScript 6.0+
module Utils {
  export function parse(s: string): number { return parseInt(s, 10); }
}

// ✅ Correct
namespace Utils {
  export function parse(s: string): number { return parseInt(s, 10); }
}
```

Note: `declare module` (ambient module declarations for `.d.ts` files) is NOT affected — only the inline runtime form `module Foo {}` is deprecated. `declare module "express"` in augmentation files continues to work.

**`--ignoreConfig` flag (TypeScript 6.0):** Running `tsc file.ts` directly alongside a `tsconfig.json` now produces an error — TypeScript 6.0 requires either a project config or an explicit opt-out:

```bash
# ❌ Error in TypeScript 6.0 when tsconfig.json exists in the directory
tsc foo.ts

# ✅ Opt out of project config explicitly
tsc --ignoreConfig foo.ts

# ✅ Or use a dedicated tsconfig for ad-hoc compilation
tsc -p tsconfig.scripts.json
```

**`ts5to6` automated migration tool:** The community-maintained [`ts5to6`](https://github.com/andrewbranch/ts5to6) tool can automatically migrate `baseUrl` into `paths` entries and update `rootDir` across your `tsconfig.json` files — the two most tedious manual changes required for TypeScript 6.0.

```bash
# Run in your project root — rewrites tsconfig.json files in-place
npx ts5to6
```

Always review the diff before committing — the tool makes mechanical changes but may not understand custom `baseUrl` patterns in monorepo root configs.

---

### TypeScript 6.0 — Subpath Imports `#/` and `this`-less Function Inference

**Subpath imports starting with `#/` (TypeScript 6.0 + Node.js 20+):**

Node.js supports a shorthand form for subpath imports — `"#/*"` — that maps all paths directly under `#/` without requiring an extra named segment. TypeScript 6.0 supports this under `--moduleResolution nodenext` and `--moduleResolution bundler`.

```json
// package.json — before: required named segment (e.g., #root/)
{
  "name": "my-package",
  "type": "module",
  "imports": {
    "#root/*": "./dist/*.js"
  }
}
```

```typescript
// Before: import * as utils from "#root/utils.js";
```

```json
// package.json — after: simpler #/ prefix (Node.js 20 + TypeScript 6.0)
{
  "name": "my-package",
  "type": "module",
  "imports": {
    "#/*": "./dist/*.js"
  }
}
```

```typescript
// After: shorter path, same effect
import * as utils from "#/utils.js";
import { createLogger } from "#/logger.js";
```

This also provides a clean alternative to `paths`-based aliases — `#/` imports are part of the Node.js module resolution spec, so they work without additional bundler configuration, unlike `tsconfig.json` `paths` entries.

**Less context-sensitivity on `this`-less functions (TypeScript 6.0):**

Previously, when you wrote method-syntax functions inside object literals passed to generic APIs, TypeScript treated those methods as "contextually sensitive" (because they could reference `this`). This blocked contextual type inference for sibling methods — even when `this` was never actually used.

TypeScript 6.0 detects when a method does not reference `this` and skips the contextual sensitivity restriction, enabling full bidirectional type inference across the object's properties.

```typescript
declare function callIt<T>(obj: {
  produce: (x: number) => T;
  consume: (y: T) => void;
}): void;

// ❌ TypeScript 5.x error: 'y' implicitly has type 'unknown'
//    because consume's method syntax made it contextually sensitive,
//    blocking inference of T from produce
callIt({
  produce(x: number) { return x * 2; },
  consume(y) { return y.toFixed(); },  // y: unknown in 5.x
});

// ✅ TypeScript 6.0: 'y' is correctly inferred as 'number'
//    Because consume() never references 'this', TypeScript treats it
//    the same as an arrow function — enabling full inference
callIt({
  produce(x: number) { return x * 2; },
  consume(y) { return y.toFixed(); },  // y: number ✓
});
```

[community] **Pitfall:** This change can surface previously-suppressed type errors. Code that previously compiled with `this`-using methods inside object literals may now have those methods correctly identified as contextually sensitive — and their sibling methods correctly typed. If `y` was silently `unknown` before and your code operated on it unsafely, TypeScript 6.0 will now surface the error. This is a correctness improvement, not a regression.

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

**Variance annotations do not change structural type behavior.** [community]
TypeScript's `in`/`out`/`in out` variance annotations on generic parameters are widely misunderstood. They are a documentation and performance tool — they do NOT change structural assignability. The official handbook states: _"Don't try to use variance annotations to change typechecking behavior; this is not what they are for."_ Developers add `<out T>` expecting it to block writes, then discover that object-literal structural comparison ignores the annotation entirely:

```typescript
interface ReadOnlyBox<out T> {
  get(): T;
}

// ❌ Does NOT enforce read-only behavior structurally
const box: ReadOnlyBox<string | number> = {
  get(): number { return 42; }
  // This compiles despite the 'out' annotation — structural comparison wins
};

// 'out' only affects instantiation-based comparison (not structural literal comparison)
// The annotation is useful for:
// (a) explicit documentation of variance intent
// (b) performance: bypasses the full structural walk for known covariant positions
//     in large union hierarchies where TypeScript's structural check is expensive
// It does NOT enforce read/write constraints at runtime or compile time.
```

**When they DO help:** On interfaces with large union hierarchies, adding `out T` lets the compiler short-circuit the structural walk and use the declared variance instead. This is a pure build-performance optimization, not a correctness guarantee. Measure with `tsc --extendedDiagnostics` before adding annotations — they add annotation complexity for no benefit in most codebases. **Fix:** Only add variance annotations after profiling confirms a type-checking bottleneck in that specific interface, and document WHY the annotation was added. Never add them to "make code cleaner" or "enforce immutability."

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
| `import` assertions (`assert {}`) instead of attributes (`with {}`) | **Removed** (not just deprecated) in TS 6.0 — hard error under `--module nodenext`; also deprecated in Node 22 | Use `import data from "./f.json" with { type: "json" }` |
| `import defer` for code splitting | `import defer` defers evaluation, not loading; bundle size unchanged | Use dynamic `import()` for true code splitting |
| Missing `verbatimModuleSyntax` | Implicit type-import elision causes hard-to-diagnose circular import issues | Enable `verbatimModuleSyntax: true`; use `import type` for all type-only imports |
| `moduleDetection: "auto"` (default) | Files without `import`/`export` are treated as scripts, polluting global scope | Set `"moduleDetection": "force"` to treat all files as modules |
| `types: []` not set | Every installed `@types/*` package is auto-included, causing duplicate globals | Explicitly list only needed `@types` in `"types": [...]` |
| Manual set operations (filter/reduce) instead of Set composition methods | Verbose, allocation-heavy, error-prone compared to built-in ES2025 Set methods | Use `.union()`, `.intersection()`, `.difference()` etc. (`"target": "es2025"+`) |
| `new Promise()` wrapper around sync throw instead of `Promise.try()` | Requires try/catch inside the constructor callback; error propagation is non-obvious | Use `Promise.try(() => syncThrowingFn())` to convert sync throws to rejected promises (ES2025) |
| `#root/*` subpath import pattern when `#/*` is available | Extra naming indirection; `#root/` is a legacy Node.js workaround | Use `"#/*": "./dist/*.js"` in `package.json` imports with `--moduleResolution nodenext/bundler` |
| `"types": ["*"]` to restore TS 6.0 defaults | Wildcard re-enables auto-inclusion of all `@types/*` packages — 20–50% build performance degradation | Explicitly list only needed packages: `"types": ["node"]`, add `"jest"` etc. in test-only tsconfig |
| Using `tsc --init` output as-is | TS 5.9+ generates opinionated defaults (`jsx: react-jsx`, `noUncheckedIndexedAccess`, etc.) that require project-specific review | Treat `tsc --init` as a menu — review and remove inapplicable options before committing |
| `Partial<T>` for update payloads when primary key must always be present | Makes identity key optional; database update can silently omit the required row identifier | Use `PartialExcept<T, 'id'>` (`Partial<T> & Required<Pick<T, 'id'>>`) to keep the key required |
| Variance annotations (`in`/`out`) to enforce immutability or change behavior | Annotations only affect instantiation-based comparison; structural comparisons ignore them | Use `Readonly<T>` / `readonly` modifiers for actual read-only enforcement; add variance annotations only after profiling confirms a type-check bottleneck |
| Multiple overloads for the same generic function | Overload sprawl; each overload must be maintained separately | Use generic parameter defaults (`<T = DefaultType>`) to make parameters optional while preserving type inference |
| `"stableTypeOrdering": true` in production `tsconfig.json` | Adds ~25% compile overhead; intended only as a TS 7.0 migration diagnostic | Keep in a separate `tsconfig.check-7.0.json`; remove before merging to main |



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
| Migrating from `node` → modern (TS 6.0+) | `commonjs` | `bundler` | `ES2020`+ |

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
| `"moduleResolution": "node"` (legacy) | Deprecated in TS 6.0; silently resolves paths that bundlers won't | Migrate to `"bundler"` (with `"module": "commonjs"` or `"preserve"`) as the first step |

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

# Explain WHY each file was included — gives the import chain responsible
# (more actionable than --listFiles: tells you which tsconfig glob or import pulled it in)
npx tsc --explainFiles --noEmit 2>&1 | head -100

# Trace module resolution for a specific import — diagnose "cannot find module" failures
npx tsc --traceResolution --noEmit 2>&1 | grep "myModule" | head -20

# Generate a build trace for deep analysis in Chrome DevTools (Perfetto UI)
npx tsc --generateTrace ./trace-output --noEmit
# Open trace-output/trace.json in https://ui.perfetto.dev
# Prefer @typescript/analyze-trace for a text summary: npx @typescript/analyze-trace ./trace-output

# Alternative: pprof-it — smaller, more readable CPU profiles than --generateCpuProfile
# Produces a pprof-format profile viewable in https://profiler.firefox.com or pprof CLI
npx pprof-it tsc --noEmit
# pprof-it wraps the TypeScript compiler and captures a V8 CPU profile in pprof format.
# Use when analyze-trace shows a hot path inside the compiler itself (not in your types).

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
| Unexpected file included | Implicit glob or `import` chain | Run `tsc --explainFiles` to see the import chain responsible |
| Module resolution failure | Path alias or extension mismatch | Run `tsc --traceResolution` to see each resolution step |

[community] **Pitfall:** Teams run `tsc --generateTrace` once, see a complex trace, and immediately start refactoring types without reading the trace. The trace's "Heavy" nodes are not always in your own code — they are often in `node_modules/.d.ts` files. Check the **file column** in each heavy instantiation before assuming your types are the bottleneck.

**Editor-specific performance flags (add to `tsconfig.json` for large monorepos):**

```json
{
  "compilerOptions": {
    // Prevents the editor from loading ALL referenced projects at startup.
    // Only load a project when you open a file in it — dramatically reduces
    // VS Code memory usage in repos with 10+ projects.
    "disableReferencedProjectLoad": true,

    // Prevents the language service from searching the full solution tree
    // for go-to-definition / find-references across project boundaries.
    // Use when inter-project navigation is not needed or is handled by monorepo tooling.
    "disableSolutionSearching": true
  }
}
```

These two flags have zero effect on `tsc --build` (command-line compilation) — they only control editor behavior. They are safe to add to any `tsconfig.json` in a multi-project workspace.

**TSServer tracing — diagnose editor-specific performance issues:**

When VS Code feels slow (slow completions, delayed type-checking overlays) rather than slow builds, the problem is in `tsserver` rather than `tsc`. Enable TSServer tracing in VS Code to capture a detailed log of what the language service is doing:

```json
// .vscode/settings.json — enable TSServer tracing for one session
{
  "typescript.tsserver.enableTracing": true
}
```

After enabling, reproduce the slowdown, then open the output panel → "TypeScript" to find the trace file path. The trace logs every request the editor sends to `tsserver` and how long each response took. Look for `completions`, `getSemanticDiagnostics`, or `references` calls that take >500ms — those indicate which language service operation is the bottleneck. Disable tracing after investigation; the log files are large.

[community] **Pitfall:** Teams debugging editor slowness often immediately reach for `--generateTrace` (a build-time tool) when the real bottleneck is in `tsserver`'s language service. Build traces capture type-checking during `tsc --build`; TSServer traces capture the different code path that runs during interactive editing. If your build is fast but your IDE is slow, use TSServer tracing, not `--generateTrace`.

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

---

## Mapped Types Deep-Dive

Mapped types create new types by iterating over the properties of an existing type and transforming them. They are the foundation of TypeScript's built-in utility types and enable powerful type-level transformations without code duplication.

### Basic Syntax

```typescript
// Iterate over all properties of Type and change each value type to boolean
type OptionsFlags<Type> = {
  [Property in keyof Type]: boolean;
};

type Features = {
  darkMode: () => void;
  newUserProfile: () => void;
};

type FeatureOptions = OptionsFlags<Features>;
// Result: { darkMode: boolean; newUserProfile: boolean }
```

The `[Property in keyof Type]` construct is the mapped type loop:
- `keyof Type` produces a union of all property name literals
- `in` iterates over each member of that union
- `Type[Property]` indexes into the original type to access each property's value type

### Mapping Modifiers: `+/-readonly` and `+/-?`

You can add or remove `readonly` and `?` (optional) modifiers with `+` (add, default) and `-` (remove):

```typescript
// Remove readonly from every property
type Mutable<Type> = {
  -readonly [P in keyof Type]: Type[P];
};

// Remove optional — make all properties required
type Concrete<Type> = {
  [P in keyof Type]-?: Type[P];
};

// Add readonly to every property (same as built-in Readonly<T>)
type ImmutableSnapshot<Type> = {
  +readonly [P in keyof Type]: Type[P];
};

// Practical example: API response DTO (all optional) → internal domain object (all required)
type ApiUser = {
  id?: string;
  name?: string;
  email?: string;
};

type User = Concrete<ApiUser>;
// Result: { id: string; name: string; email: string }
```

**Modifier cheat sheet:**

| Syntax | Effect |
|---|---|
| `[P in keyof T]` | Preserves existing modifiers |
| `[P in keyof T]+?` | Makes all optional |
| `[P in keyof T]-?` | Removes optional (makes required) |
| `+readonly [P in keyof T]` | Makes all readonly |
| `-readonly [P in keyof T]` | Removes readonly |

### Key Remapping with `as` (TypeScript 4.1+)

Use `as` after the type parameter to transform property names at the type level:

```typescript
// Generate getter methods from data properties
type Getters<Type> = {
  [P in keyof Type as `get${Capitalize<string & P>}`]: () => Type[P];
};

interface Person {
  name: string;
  age: number;
  location: string;
}

type PersonGetters = Getters<Person>;
// Result: { getName: () => string; getAge: () => number; getLocation: () => string }
```

### Filtering Keys with `never`

Map a property to `never` in the `as` clause to exclude it from the output type:

```typescript
// Remove properties matching a name
type OmitKind<Type> = {
  [P in keyof Type as Exclude<P, "kind">]: Type[P];
};

interface Circle {
  kind: "circle";
  radius: number;
}

type KindlessCircle = OmitKind<Circle>;
// Result: { radius: number }

// Remove all non-string-valued properties
type StringProperties<Type> = {
  [P in keyof Type as Type[P] extends string ? P : never]: string;
};

interface Mixed {
  name: string;
  age: number;
  status: string;
}

type StringOnly = StringProperties<Mixed>;
// Result: { name: string; status: string }
```

### Remapping Union-of-Objects

Mapped types work on union types, enabling discriminated-union-based dispatch tables:

```typescript
type SquareEvent = { kind: "square"; x: number; y: number };
type CircleEvent = { kind: "circle"; radius: number };

// Remap union of events to a handler map keyed by discriminant
type EventHandlers<Events extends { kind: string }> = {
  [E in Events as E["kind"]]: (event: E) => void;
};

type Handlers = EventHandlers<SquareEvent | CircleEvent>;
// Result: {
//   square: (event: SquareEvent) => void;
//   circle: (event: CircleEvent) => void;
// }
```

### Mapped Types + Conditional Types

Combine mapped and conditional types for property-level type branching:

```typescript
// Classify each property as PII-sensitive or not
type ExtractPII<Type> = {
  [P in keyof Type]: Type[P] extends { pii: true } ? true : false;
};

type DBFields = {
  id:   { format: "incrementing" };
  name: { type: string; pii: true };
};

type PIIMap = ExtractPII<DBFields>;
// Result: { id: false; name: true }

// Make only nullable properties optional
type OptionalNullable<T> = {
  [K in keyof T]: null extends T[K] ? T[K] | undefined : T[K];
};
```

### Built-in Utility Types as Mapped Types

The standard library utility types are all implemented as mapped types. Understanding their implementations helps diagnose edge cases:

| Utility | Implementation |
|---|---|
| `Partial<T>` | `{ [P in keyof T]?: T[P] }` |
| `Required<T>` | `{ [P in keyof T]-?: T[P] }` |
| `Readonly<T>` | `{ readonly [P in keyof T]: T[P] }` |
| `Record<K, V>` | `{ [P in K]: V }` |
| `Pick<T, K>` | `{ [P in K]: T[P] }` |
| `Omit<T, K>` | `Pick<T, Exclude<keyof T, K>>` |
| `Mutable<T>` (custom) | `{ -readonly [P in keyof T]: T[P] }` |

### Mapped Type Anti-Patterns

| Anti-Pattern | Why It's Harmful | What to Do Instead |
|---|---|---|
| `type X = { [k: string]: any }` | Too broad — accepts any string key with any value | Use `Record<string, V>` with a concrete value type, or an index signature with explicit type |
| Layering multiple mapped types for one transform | Creates intermediate anonymous types that slow down the checker | Combine modifiers and `as` in a single mapped type |
| Using `Partial<T>` for update payloads with `exactOptionalPropertyTypes` | `Partial` uses `?` which allows explicit `undefined`; with `exactOptionalPropertyTypes` this breaks update logic | Use `{ [K in keyof T]+?: T[K] \| undefined }` or a custom `DeepPartial` |
| Mapping over `any` | `[P in keyof any]` resolves to `string \| number \| symbol`, collapsing all type information | Only map over concrete types or constrained type parameters |
| Forgetting `string &` before `Capitalize` | `Capitalize<K>` fails when `K` is `string \| number \| symbol` | Always intersect: `Capitalize<string & K>` |

---

## Template Literal Types — Deep Dive

Template literal types build on string literal types using the same backtick syntax as JavaScript template literals. They can combine unions (cross-multiplying them), enforce naming conventions on event/property names, and are the foundation of the intrinsic string manipulation utility types.

### Type-Safe Property Event Source (Inference in Template Position)

The canonical advanced pattern: capture a literal type in a generic parameter, validate it against an object's keyof union, then use indexed access to wire the callback's parameter type:

```typescript
// Enforce "Changed"-suffix event names + keep callback type in sync with property type
type PropEventSource<Type> = {
  on<Key extends string & keyof Type>(
    eventName: `${Key}Changed`,           // literal constraint: only "<prop>Changed" accepted
    callback: (newValue: Type[Key]) => void // indexed access: callback type follows property type
  ): void;
};

declare function makeWatchedObject<Type>(obj: Type): Type & PropEventSource<Type>;

const person = makeWatchedObject({
  firstName: 'Alice',
  lastName: 'Smith',
  age: 30,
});

// ✅ Correct: "firstNameChanged" matches Key="firstName"; callback infers (string) => void
person.on('firstNameChanged', newName => {
  console.log(newName.toUpperCase()); // newName: string
});

// ✅ Correct: Key="age"; callback infers (number) => void
person.on('ageChanged', newAge => {
  if (newAge < 0) console.warn('negative age');
});

// ❌ Error: "firstName" does not match "${Key}Changed" pattern
// person.on('firstName', () => {});

// ❌ Error: "frstNameChanged" is a typo — not in the valid union
// person.on('frstNameChanged', () => {});
```

**Key insight:** TypeScript captures the literal type of the first argument (e.g., `"firstNameChanged"`), infers `Key = "firstName"` by stripping the suffix, validates it against `keyof Type`, then uses `Type[Key]` for the callback parameter. This chain gives you compile-time typo detection AND correct callback types — both from a single signature.

### String Union Cross-Multiplication

When two or more union types are interpolated in a template literal type, TypeScript generates the Cartesian product of all combinations:

```typescript
type EmailLocaleIDs  = 'welcome_email' | 'email_heading';
type FooterLocaleIDs = 'footer_title'  | 'footer_sendoff';

// 2 × 2 = 4 combinations
type AllLocaleIDs = `${EmailLocaleIDs | FooterLocaleIDs}_id`;
// "welcome_email_id" | "email_heading_id" | "footer_title_id" | "footer_sendoff_id"

type Lang = 'en' | 'ja' | 'pt';

// 3 × 4 = 12 combinations — routes, keys, or enum values generated at the type level
type LocaleMessageIDs = `${Lang}_${AllLocaleIDs}`;
// "en_welcome_email_id" | "en_email_heading_id" | ... (12 total)
```

[community] **Pitfall — unbounded cross-multiplied unions degrade performance.** TypeScript docs explicitly warn: *"We generally recommend that people use ahead-of-time generation for large string unions."* A pattern like `` `${Day}_${Hour}_${Minute}` `` with 7 × 24 × 60 = 10,080 members causes type-checker slowdown and IDE lag. Use build-time codegen (e.g., a script that generates the union and writes it to a `.d.ts`) for unions that exceed ~100 members.

### Intrinsic String Manipulation Utilities

TypeScript ships four built-in string manipulation utilities implemented inside the compiler (not expressible as TypeScript code). They apply **at the type level only** — no runtime cost. They are not locale-aware; they use JavaScript's default `toUpperCase()`/`toLowerCase()`.

```typescript
type Greeting = 'Hello, World';

type Shouted      = Uppercase<Greeting>;       // "HELLO, WORLD"
type Whispered    = Lowercase<Greeting>;       // "hello, world"
type Capitalized  = Capitalize<'hello world'>; // "Hello world"
type Decapitalized = Uncapitalize<'HELLO'>; // "hELLO"

// Practical: enforce cache key format at the type level
type ASCIICacheKey<Str extends string> = `ID-${Uppercase<Str>}`;
type MainID = ASCIICacheKey<'my_app'>; // "ID-MY_APP"

// Combine with mapped types to generate getter names
type Getters2<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
interface Point { x: number; y: number }
type PointGetters = Getters2<Point>; // { getX: () => number; getY: () => number }
```

**Why `string &` is required before `Capitalize`:** `keyof T` returns `string | number | symbol`. `Capitalize` only accepts `string`. Intersecting with `string` narrows to just the string keys — without it, TypeScript emits an error about `symbol` not being assignable to `string`.

---

## Utility Types — Complete Reference

TypeScript ships utility types that cover five categories: property transformation, property selection, union manipulation, function reflection, and `this`-type manipulation. Most teams know `Partial`/`Pick`/`Omit` but miss the function and `this` utilities.

### Function Type Reflection

```typescript
// Parameters<T> — tuple of parameter types (uses last overload for overloaded fns)
type T0 = Parameters<() => string>;                     // []
type T1 = Parameters<(s: string) => void>;              // [s: string]
type T2 = Parameters<<T>(arg: T) => T>;                 // [arg: unknown]
declare function greet(name: string, times: number): string;
type GreetParams = Parameters<typeof greet>;             // [string, number]

// ReturnType<T> — return type (uses last overload)
type R0 = ReturnType<() => string>;                     // string
type R1 = ReturnType<(s: string) => void>;              // void
type R2 = ReturnType<typeof greet>;                     // string

// ConstructorParameters<T> — constructor parameter tuple
class Connection {
  constructor(public host: string, public port: number) {}
}
type ConnParams = ConstructorParameters<typeof Connection>; // [host: string, port: number]
type ErrParams  = ConstructorParameters<ErrorConstructor>;  // [message?: string]

// InstanceType<T> — class instance type
type ConnInstance = InstanceType<typeof Connection>;     // Connection
```

### `this`-Type Utilities

These three utilities are rarely documented in team guides but are essential when working with `this`-typed functions:

```typescript
// ThisParameterType<T> — extracts the 'this' parameter type; 'unknown' if absent
function toHex(this: Number): string {
  return this.toString(16);
}
type HexThis = ThisParameterType<typeof toHex>; // Number

// Useful: pass a 'this'-dependent function to a utility that needs the this type
function applyToNumber(n: ThisParameterType<typeof toHex>): string {
  return toHex.call(n);
}

// OmitThisParameter<T> — strips the 'this' parameter; useful for bind() results
type BoundHex = OmitThisParameter<typeof toHex>; // () => string
const fiveHex: BoundHex = toHex.bind(5);         // no 'this' needed at call site
console.log(fiveHex()); // "5"

// ThisType<T> — marks the contextual 'this' type for methods in an object literal
// Requires noImplicitThis: true; does NOT return a transformed type — it's a marker
type ObjectDescriptor<D, M> = {
  data?: D;
  methods?: M & ThisType<D & M>; // 'this' inside methods is typed as D & M
};

function makeObject<D, M>(desc: ObjectDescriptor<D, M>): D & M {
  return { ...desc.data, ...desc.methods } as D & M;
}

const counter = makeObject({
  data: { count: 0 },
  methods: {
    increment() { this.count++; },    // 'this' is { count: number } & { increment, decrement }
    decrement() { this.count--; },
    reset()     { this.count = 0; },
  },
});
counter.increment();
```

[community] **Pitfall — `ThisType<T>` has no effect without `noImplicitThis: true` in tsconfig.** The marker is silently ignored in permissive mode, which makes `this` inside the methods `any` — the same as if you hadn't used `ThisType` at all. Enable `"noImplicitThis": true` (part of `"strict": true` from TypeScript 2.0+) to get the contextual `this` binding.

### Full Utility Type Reference Table

| Utility | Category | What it produces | TS version |
|---------|----------|-----------------|------------|
| `Partial<T>` | Property | All properties optional | 2.1 |
| `Required<T>` | Property | All properties required | 2.8 |
| `Readonly<T>` | Property | All properties readonly | 2.1 |
| `Record<K,V>` | Property | Object with keys `K` and values `V` | 2.1 |
| `Pick<T,K>` | Selection | Keep only keys `K` from `T` | 2.1 |
| `Omit<T,K>` | Selection | Drop keys `K` from `T` | 3.5 |
| `Exclude<T,U>` | Union | Remove union members assignable to `U` | 2.8 |
| `Extract<T,U>` | Union | Keep only members assignable to `U` | 2.8 |
| `NonNullable<T>` | Union | Remove `null` and `undefined` | 2.8 |
| `Parameters<T>` | Function | Tuple of parameter types | 3.1 |
| `ConstructorParameters<T>` | Function | Tuple of constructor parameter types | 3.1 |
| `ReturnType<T>` | Function | Return type | 2.8 |
| `InstanceType<T>` | Function | Class instance type | 2.8 |
| `ThisParameterType<T>` | this | Type of `this` parameter | 3.3 |
| `OmitThisParameter<T>` | this | Function type with `this` removed | 3.3 |
| `ThisType<T>` | this | Contextual `this` marker (requires `noImplicitThis`) | 2.3 |
| `Awaited<T>` | Async | Recursively unwrap Promise | 4.5 |
| `NoInfer<T>` | Inference | Block inference from this position | 5.4 |
| `Uppercase<S>` | String | Uppercase string literal | 4.1 |
| `Lowercase<S>` | String | Lowercase string literal | 4.1 |
| `Capitalize<S>` | String | Capitalize first character | 4.1 |
| `Uncapitalize<S>` | String | Uncapitalize first character | 4.1 |

---

## TypeScript 5.9 — Type Argument Inference Fixes

TypeScript 5.9 corrects a class of bugs where type variables could "leak" across inference boundaries, causing the compiler to infer an unexpectedly broad type. This is a correctness improvement — previously suppressed errors may now surface in existing code.

**What changed:** When TypeScript infers type arguments during a generic function call, it previously allowed early-bound type variables to escape into inferences for other parameters. The fix constrains each type variable to its declared scope, meaning some code that previously compiled silently now produces errors.

```typescript
// Example pattern that may produce new errors after upgrading to 5.9
// (simplified illustration of the category of fix)

declare function pair<A, B>(a: A, b: B): [A, B];

// Before 5.9: TypeScript may infer A = string from context, then "leak" it
// to B's inference position in chained calls
// After 5.9: each type variable inferred independently — explicit annotation required

// Fix: add explicit type arguments when 5.9 reports a new type mismatch
declare function transform<T, U>(
  value: T,
  fn: (t: T) => U
): U;

// If 5.9 surfaces a new error here, provide explicit type arguments:
const result = transform<string, number>('hello', s => s.length); // explicit — safe
```

**Upgrade path:** When upgrading to TypeScript 5.9, run `tsc --noEmit` and inspect any new errors around generic function calls. The fix is almost always to add explicit type arguments to the call site rather than changing logic. These are genuine type errors that were silently permitted before — they represent real correctness improvements.

[community] **Pitfall:** Teams that upgrade TypeScript minor versions without a `tsc --noEmit` step in CI miss inference-tightening changes. TypeScript 5.x "minor" releases can introduce new errors in previously-clean code when the compiler's inference becomes more correct. Always run a dedicated type-check step (`"typecheck": "tsc --noEmit"`) as a separate CI job — never rely on "it builds with esbuild" as a proxy for type correctness.

---

## TypeScript 5.9 — Editor Tooling Improvements

### Expandable Hovers (Preview)

TypeScript 5.9 introduces interactive hover tooltips in VS Code that allow you to expand and collapse type information inline, without navigating to a type definition. This is especially useful for complex generic return types and utility type compositions.

**Behaviour:**
- Hovering over a value shows the standard compact type
- A `+` button expands the type inline to show all members  
- A `-` button collapses it back
- Particularly useful for inspecting `Partial<User & Settings>` without a "go to definition"

**Status:** This is a **preview** feature as of TypeScript 5.9. It is available in VS Code with the TypeScript 5.9 language service but behaviour may change before stabilisation. Provide feedback via the [TypeScript GitHub issue tracker](https://github.com/microsoft/TypeScript/issues).

### Configurable Maximum Hover Length

TypeScript 5.9 also adds a VS Code setting to control hover tooltip truncation:

```json
// VS Code settings.json
{
  "js/ts.hover.maximumLength": 500
}
```

The default hover length was substantially increased in 5.9, preventing important type information from being cut off in complex types. If you still see truncated hovers on very large types (e.g., deeply inlined record types), increase this setting. Setting it to `0` disables truncation entirely — useful temporarily for debugging type shapes, but can make hovers unwieldy.

[community] **Pitfall:** Teams debugging complex type errors often open the `.d.ts` file to inspect types because hover tooltips were truncated. With TypeScript 5.9's longer default and the configurable limit, "go to definition" is now a last resort rather than a first step. Configure `js/ts.hover.maximumLength` early in your team's VS Code settings (committed to `.vscode/settings.json`) so everyone sees complete type information from the start.

---

## TypeScript 6.0 — `--moduleResolution bundler` + `--module commonjs` Migration Path

TypeScript 6.0 allows the previously-rejected combination of `--moduleResolution bundler` with `--module commonjs`. This provides a clean incremental upgrade path for projects migrating away from the deprecated `--moduleResolution node` (now renamed `node10`) without requiring a full ESM conversion.

```json
// Migration step 1: swap deprecated node resolution for bundler resolution
// while keeping CommonJS output — no application code changes needed
{
  "compilerOptions": {
    "module": "commonjs",            // unchanged: still emits CommonJS
    "moduleResolution": "bundler",   // new: replaces deprecated "node" / "node10"
    "target": "ES2020"
  }
}

// Migration step 2 (later): move to ESM output when ready
{
  "compilerOptions": {
    "module": "nodenext",            // ESM output
    "moduleResolution": "nodenext"   // consistent pair
  }
}
```

**Why this matters:** `moduleResolution: "node"` (now `"node10"`) is deprecated in TypeScript 6.0 and removed in TypeScript 7.0. It silently resolves paths in ways that bundlers (Webpack, Rollup, esbuild) do not replicate — leading to `Cannot find module` errors at runtime that TypeScript never caught. The `bundler` resolution strategy matches how modern bundlers actually resolve modules. Previously, `module: commonjs` and `moduleResolution: bundler` were an incompatible pair; TypeScript 6.0 lifts this restriction to lower the migration cost.

[community] **Pitfall:** Many teams running CJS builds with `"moduleResolution": "node"` will hit deprecation warnings when upgrading to TypeScript 6.0. The temptation is to suppress with `"ignoreDeprecations": "6.0"` and move on. This defers a real problem — TypeScript 7.0 removes the option entirely. Use the two-step migration above: first swap to `bundler` with `commonjs` output, run your full test suite to verify no resolution regressions, then plan the ESM transition separately.

---

## Community Pitfall: `isolatedModules` vs `isolatedDeclarations` — Different Flags, Different Purposes

[community] **Pitfall:** Teams frequently confuse `isolatedModules` and `isolatedDeclarations`, enabling the wrong flag for their use case — or enabling both under the impression they compound.

| Flag | What it does | Who it's for | Performance impact |
|------|-------------|--------------|-------------------|
| `isolatedModules: true` | Errors on patterns unsafe for single-file transpilation (e.g., `const enum`, `export = x`, ambient modules without `declare`) | Teams using Babel, esbuild, or SWC to transpile TypeScript without running `tsc` | None — only validates, no emit change |
| `isolatedDeclarations: true` | Requires explicit return type annotations on all exported functions so that `.d.ts` files can be emitted in parallel without cross-file inference | Monorepos using tools like Rollup, Vite, or Rspack to generate `.d.ts` files in parallel | Enforces annotation discipline; enables parallel builds |

```typescript
// isolatedModules: catches patterns Babel/esbuild cannot handle
// ❌ Error under isolatedModules: const enum requires full TypeScript compilation
const enum Direction { Up, Down }

// isolatedDeclarations: requires explicit return types for exports
// ❌ Error under isolatedDeclarations: inferred return type prevents parallel .d.ts emit
export function compute(x: string) {
  return x.length * 2;  // Error: needs explicit ': number'
}
// ✅ Correct
export function compute(x: string): number {
  return x.length * 2;
}
```

**Rule of thumb:**
- Use `isolatedModules: true` if any file in your repo is transpiled by a non-TypeScript tool
- Use `isolatedDeclarations: true` if you have a monorepo that needs fast parallel `.d.ts` generation
- You may need **both** in a large monorepo using Vite (which uses esbuild for dev, Rollup for prod): `isolatedModules` ensures Vite's esbuild can transpile safely; `isolatedDeclarations` enables parallel type declaration emit

---

## Community Pitfall: `tsconfig.json` Glob Changes Invalidate Incremental Cache

[community] **Pitfall:** Developers treat `.tsbuildinfo` as a persistent acceleration — once set up, always fast. In reality, any change to `tsconfig.json` that affects the file set invalidates the entire cache. Common cache-busting changes include:

- Adding or removing entries in `include`/`exclude`
- Changing `rootDir`, `outDir`, or `baseUrl`
- Adding a new `paths` entry
- Upgrading TypeScript itself (different compiler version = full rebuild)
- Changing `target` or `module` (affects output shape)

```bash
# Diagnose a cache miss — tsc reports why the cache was invalidated
npx tsc --extendedDiagnostics --noEmit 2>&1 | grep -i "build info"

# Common output when cache is invalidated:
# Project '.../tsconfig.json' is out of date because output '.tsbuildinfo' is older than input 'tsconfig.json'
# → Full rebuild triggered

# Manual cache clear (safe — forces fresh build):
rm .tsbuildinfo
# Or for project references:
find . -name "*.tsbuildinfo" -not -path "*/node_modules/*" -delete
```

**Best practice for CI:** Never rely on incremental cache across CI runs without a cache key that includes both the `tsconfig.json` hash AND the TypeScript version. Use your CI cache system's key feature:

```yaml
# GitHub Actions example
- uses: actions/cache@v4
  with:
    path: .tsbuildinfo
    key: tsbuildinfo-${{ hashFiles('tsconfig.json', 'package.json') }}-${{ runner.os }}
    restore-keys: |
      tsbuildinfo-
```

Without the content-based key, a stale `.tsbuildinfo` from a previous branch causes spurious type errors or false clean builds — both worse than a full rebuild.

---

## Zod v4 — Migration Patterns and New APIs

Zod v4 (released 2025) is a significant rewrite with a cleaner API surface, stricter validation defaults, and new capabilities for schema metadata and JSON schema generation. The TypeScript integration improved substantially — fewer `z.infer<typeof ...>` footguns and better error messages.

### New APIs in Zod v4

```typescript
import { z } from 'zod';

// --- z.interface: cleaner open-ended object schema (no .strip() needed) ---
// z.object() in v3/v4 strips extra keys by default.
// z.interface() creates an open schema — extra properties are allowed and preserved.
const UserBaseSchema = z.interface({
  id: z.string().uuid(),
  name: z.string(),
});
// type UserBase = { id: string; name: string } — extra keys allowed at runtime

// --- z.toJSONSchema(): built-in JSON Schema generation (no zod-to-json-schema package needed) ---
const AddressSchema = z.object({
  street: z.string(),
  city:   z.string(),
  zip:    z.string().regex(/^\d{5}$/),
});

// First-party JSON schema generation with z.toJSONSchema()
const jsonSchema = z.toJSONSchema(AddressSchema);
// { type: "object", properties: { street: { type: "string" }, ... }, required: ["street", "city", "zip"] }

// --- z.registry(): schema registries for metadata and documentation ---
// Attach metadata (OpenAPI, form labels, descriptions) without polluting TypeScript types
const schemaRegistry = z.registry<{ description?: string; example?: unknown }>();

const EmailSchema = z.string().email();
schemaRegistry.add(EmailSchema, {
  description: 'A valid email address',
  example: 'user@example.com',
});

// Later: generate OpenAPI docs from the registry
const metadata = schemaRegistry.get(EmailSchema);
// { description: 'A valid email address', example: 'user@example.com' }

// --- z.file(): validated File/Blob schema for form inputs ---
const FileUploadSchema = z.object({
  name:     z.string(),
  document: z.file().max(5 * 1024 * 1024, 'Max 5MB').mime(['application/pdf']),
});

// --- z.prefault(): set a default that applies BEFORE validation (not after) ---
// z.default() applies after parsing; z.prefault() applies before — useful for normalizing input
const ConfigSchema = z.object({
  timeout: z.number().min(1).prefault(30_000),  // applied before min() check
  retries: z.number().min(0).default(3),         // applied after parsing (v3-style)
});
```

### Breaking Changes from Zod v3

```typescript
// 1. Tuple defaults now appear in parsed output
//    v3: optional tuple elements with defaults stayed absent
//    v4: defaults materialize in the output
const PairSchema = z.tuple([z.string(), z.number().default(0)]);
const v4Result = PairSchema.parse(['hello']);
// v3: ['hello']           (default did NOT appear)
// v4: ['hello', 0]        (default DOES appear — matches user expectation)

// 2. z.undefined() on object keys is now REQUIRED (key must be present)
//    Use .optional() when the key itself may be absent
const v3Behavior = z.object({ x: z.undefined() }); // v3: x?: undefined (key optional)
const v4Correct  = z.object({ x: z.optional(z.undefined()) }); // v4: same runtime behavior

// 3. Stricter string validators
//    z.string().base64() now rejects whitespace
//    z.string().url() renamed to z.string().httpUrl() and rejects malformed URLs
const UrlSchema = z.string().httpUrl();  // v4 — rejects 'https:/example.com'
// v3 equivalent: z.string().url()

// 4. .merge() throws if receiver has refinements (was silently ambiguous in v3)
const BaseSchema = z.object({ id: z.string() }).refine(v => v.id.length > 0);
// BaseSchema.merge(z.object({ name: z.string() })); // v4 ERROR: cannot merge schema with refinements
// Fix: move the refinement to after the merge:
const MergedSchema = z.object({ id: z.string() })
  .merge(z.object({ name: z.string() }))
  .refine(v => v.id.length > 0);
```

### Zod v4 TypeScript Inference Improvements

```typescript
// z.infer<T> still works identically — no migration needed for basic usage
const ProductSchema = z.object({
  id:    z.string().uuid(),
  price: z.number().positive(),
  tags:  z.array(z.string()),
});

type Product = z.infer<typeof ProductSchema>;
// { id: string; price: number; tags: string[] }

// New: z.input<T> and z.output<T> — separate input (before coercion) and output types
const FlexDateSchema = z.object({
  createdAt: z.coerce.date(),  // accepts string | number | Date as input, produces Date
  updatedAt: z.string().datetime().pipe(z.coerce.date()),
});

type FlexDateInput  = z.input<typeof FlexDateSchema>;
// { createdAt: string | number | Date; updatedAt: string }   — input before coercion

type FlexDateOutput = z.output<typeof FlexDateSchema>;
// { createdAt: Date; updatedAt: Date }                       — output after coercion

// This distinction matters for form handlers and API route validators
// where the incoming data type differs from the validated type
```

[community] **Pitfall: upgrading to Zod v4 without running `parse()` on ALL data paths.** Zod v4's stricter defaults (tighter base64, stricter URL validation, tuple default materialization) can cause previously-passing schemas to throw at runtime on data that v3 silently accepted. The safest upgrade path: (1) upgrade the package, (2) run your full test suite — not just unit tests but integration tests that exercise real API payloads, (3) audit every schema that uses `.url()` (now `.httpUrl()`), `.base64()`, or tuple defaults. Do not assume a passing TypeScript build means runtime-safe schemas — Zod's runtime validation runs on data shapes that TypeScript cannot inspect.

---

## TypeScript 5.9 — DOM API Summary Descriptions

TypeScript 5.9 adds MDN-sourced summary descriptions to DOM type declarations. These descriptions appear inline in editor hover tooltips without requiring a separate MDN lookup.

**What this means in practice:**

When you hover over `document.querySelector`, `fetch`, `navigator.clipboard.writeText`, or any built-in DOM API in VS Code with TypeScript 5.9's language service, you now see:

- A one-line summary of what the API does
- The MDN compatibility status
- A link to the full MDN documentation
- Deprecation warnings for legacy APIs

```typescript
// Example: hovering over fetch() in VS Code with TypeScript 5.9 shows:
// fetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response>
// Fetches a resource from the network. [MDN Reference]
//
// Example: hovering over document.write() shows:
// document.write(text: string): void
// [Deprecated] Writes HTML expressions or JavaScript code to a document. [MDN Reference]

// Practical benefit: you can see deprecation warnings without leaving your editor
document.write('<p>deprecated API</p>'); // hover shows [Deprecated] — no MDN lookup needed

// Combine with the configurable hover length to see full descriptions on complex APIs
// VS Code settings.json:
// { "js/ts.hover.maximumLength": 500 }
```

[community] **Pitfall:** Teams running the TypeScript 5.9 language service in VS Code may see unfamiliar deprecation markers on DOM APIs they use regularly (e.g., `document.write`, `document.execCommand`, `XMLHttpRequest` CORS methods). These are real deprecations from MDN — the TypeScript team is surfacing existing MDN metadata that was previously invisible. If you see `[Deprecated]` on an API you rely on, investigate the modern replacement rather than suppressing the warning.

---

## ES2025 — `WeakMap.getOrInsert` and `WeakMap.getOrInsertComputed`

TypeScript 6.0 added types for `WeakMap.getOrInsert` and `WeakMap.getOrInsertComputed` alongside the same methods on `Map`. These enable atomic lookup-or-insert on `WeakMap` — particularly useful for caching computed values keyed by object identity without leaking memory.

```typescript
// WeakMap.getOrInsert: insert a default if key absent, return existing or new value
const cache = new WeakMap<object, string[]>();

function getTagsFor(obj: object): string[] {
  return cache.getOrInsert(obj, []);
  // Equivalent to (but atomic, no separate has/set call):
  // if (!cache.has(obj)) cache.set(obj, []);
  // return cache.get(obj)!;
}

// WeakMap.getOrInsertComputed: lazy computation — only called if key absent
const expensiveCache = new WeakMap<Element, DOMRect>();

function getBoundingRect(el: Element): DOMRect {
  return expensiveCache.getOrInsertComputed(el, e => e.getBoundingClientRect());
  // The arrow function is only called if `el` is not in the WeakMap
}

// Practical pattern: memoize expensive per-object computations without memory leaks
// WeakMap holds weak references — when the key object is GC'd, the entry is removed automatically
class ComponentAnalyzer {
  private readonly styleCache = new WeakMap<Element, CSSStyleDeclaration>();

  getComputedStyle(el: Element): CSSStyleDeclaration {
    return this.styleCache.getOrInsertComputed(el, e => window.getComputedStyle(e));
  }
}
```

Requires `"target": "es2025"` or `"target": "esnext"` in `tsconfig.json`. Both `Map` and `WeakMap` gain these methods in the ES2025 standard library, and they share the same signature semantics — `getOrInsert(key, defaultValue)` and `getOrInsertComputed(key, computeFn)`.

[community] **Pitfall:** `WeakMap.getOrInsertComputed` is only safe to use when the compute function has no side effects that depend on the WeakMap state. The spec does not define reentrancy behavior — if `computeFn` triggers a call to `getOrInsertComputed` on the same WeakMap with the same key, the result is implementation-defined. Use a guard variable or convert to an explicit `has`/`set` pattern in reentrant scenarios.

---

## Community Pitfall: `fork-ts-checker` vs `--noCheck` — CI Parallelization Strategy

[community] **Pitfall:** Teams that adopt `tsc --noCheck` for faster builds (TypeScript 5.7+) often disable or remove `fork-ts-checker-webpack-plugin` from their Webpack/Vite setup without replacing the type check step. The result: type errors are never caught in CI because `--noCheck` emits JavaScript without type-checking, and the build "succeeds" with invalid TypeScript.

```json
// package.json — INCORRECT: type checking removed from CI entirely
{
  "scripts": {
    "build": "tsc --noCheck",     // emits JS fast — no type check
    "ci": "npm run build"         // ❌ type errors never caught!
  }
}

// package.json — CORRECT: type check runs in parallel with build
{
  "scripts": {
    "typecheck": "tsc --noEmit",  // type check only (no emit)
    "build":     "tsc --noCheck", // emit only (no type check) — 2-3x faster
    "ci": "npm run typecheck & npm run build"
    // Both run in parallel; CI fails if EITHER fails
  }
}
```

The same pitfall applies when using `transpileOnly: true` in `ts-loader` or `babel-loader` — fast transpilation without type checking. The fix is always the same: add a dedicated `tsc --noEmit` step that runs on every CI push, even if it takes 30 seconds. Type checking and JavaScript emit are separate concerns that should be explicitly scheduled.

**With `fork-ts-checker-webpack-plugin` (Webpack projects):**

```typescript
// webpack.config.ts — type check runs in a worker process in parallel with webpack compilation
import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin';

export default {
  module: {
    rules: [{
      test: /\.tsx?$/,
      use: {
        loader: 'ts-loader',
        options: {
          transpileOnly: true,  // fast: no type check in the main thread
        },
      },
    }],
  },
  plugins: [
    new ForkTsCheckerWebpackPlugin(),  // type check in a separate worker
  ],
};
// Result: webpack compilation is fast (transpileOnly); type errors still caught (fork-ts-checker)
```

---

## TypeScript 6.0 — Removed vs Deprecated: Precision Reference

TypeScript 6.0 draws a hard line between **deprecated** (still works with `"ignoreDeprecations": "6.0"`, removed in TS 7.0) and **removed** (errors immediately regardless of `ignoreDeprecations`). Teams upgrading need to distinguish between the two to avoid unexpected build failures.

### Fully Removed in TypeScript 6.0 (no escape hatch)

| Option / Syntax | Removed Reason | Migration |
|---|---|---|
| `"target": "es5"` | IE is gone; no modern runtime needs ES5 output | Use `"target": "es2015"` or higher; pipe through Babel/SWC if ES5 output is truly required |
| `"moduleResolution": "classic"` | Never matched real Node or bundler resolution; caused phantom module finds | Use `"bundler"` or `"nodenext"` |
| `"esModuleInterop": false` | Caused `import * as X` vs `import X` inconsistencies across tools | Remove the flag; interop is always enabled; update `import * as X` to `import X` |
| `"allowSyntheticDefaultImports": false` | Logically superseded by `esModuleInterop` | Remove the flag |
| `"outFile"` | Never worked with ESM; bundlers are the correct tool | Use an external bundler (esbuild, Rollup, Webpack) |
| `module Foo {}` (inline runtime namespace) | Pre-ES-module-era syntax that compiles to IIFEs | Change to `namespace Foo {}`; `declare module "..."` in `.d.ts` files is unaffected |
| `import X from "f.json" assert { type: "json" }` | TC39 replaced `assert` with `with` | Use `import X from "f.json" with { type: "json" }` |
| `/// <reference no-default-lib="true"/>` directive | Superseded by `--noLib` / `--libReplacement` flags | Use `"noLib": true` in tsconfig, or the `--libReplacement` flag introduced in TS 5.8 |

```typescript
// ❌ All of these are hard errors in TypeScript 6.0 — ignoreDeprecations does NOT help

// 1. target: es5 removed
// { "target": "es5" }  →  error TS5023: Unknown compiler option 'target: es5'

// 2. import assert removed (TC39 replaced it with 'with')
import data from "./config.json" assert { type: "json" };
// Error: Import assertions have been removed; use 'with' keyword instead
// ✅ Fix:
import data from "./config.json" with { type: "json" };

// 3. module Foo {} removed for runtime namespaces
module Utils {                   // ❌ Error in TS 6.0
  export const VERSION = "1.0";
}
// ✅ Fix:
namespace Utils {
  export const VERSION = "1.0";
}
// Note: `declare module "express" {}` in .d.ts files is UNAFFECTED — only the
// inline runtime form `module Foo {}` without `declare` is removed.

// 4. esModuleInterop: false removed — always-on interop
// Old code requiring the false setting:
import * as express from "express";  // Only way under esModuleInterop: false
// ✅ Modern code (always works now):
import express from "express";
```

### Deprecated in TypeScript 6.0 (work now, removed in TS 7.0)

These options still compile with `"ignoreDeprecations": "6.0"` in tsconfig but will become hard errors in TypeScript 7.0:

| Option | Deprecated Reason | Migration |
|---|---|---|
| `"baseUrl"` | Replaced by explicit `paths` entries | Move each alias into `paths` with a concrete prefix |
| `"downlevelIteration"` | Only useful for ES5 targets, which are now removed | Remove; modern targets (`es2015+`) iterate correctly without it |
| `"alwaysStrict": false` | Strict mode is universally adopted; turning it off encourages unsafe code | Remove; all code is treated as strict mode |
| `"module": "amd"` / `"umd"` / `"system"` / `"none"` | Module formats for pre-bundler era | Use ESM (`esnext`/`nodenext`) with an external bundler |

```json
// Temporary escape hatch (TS 6.x only):
{
  "compilerOptions": {
    "ignoreDeprecations": "6.0",
    "baseUrl": "./src",         // still works, but deprecated
    "downlevelIteration": true  // still works, but deprecated
  }
}

// ✅ Migration target for TS 7.0 compatibility:
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
    // downlevelIteration: removed (not needed for es2015+ targets)
    // alwaysStrict: removed (always true now)
  }
}
```

[community] **Pitfall: relying on `ignoreDeprecations: "6.0"` as a long-term strategy.** The flag was designed for a 6-month migration window, not permanent suppression. Teams that set it and move on will hit a wall when TypeScript 7.0 ships and removes every deprecated option simultaneously — a much larger migration than addressing one option at a time. Best practice: set `"ignoreDeprecations": "6.0"` as a temporary measure, then create a migration ticket for each deprecated option, and remove the flag before upgrading to TypeScript 7.0.

---

## Community Pitfall: `import assert` Was Removed, Not Deprecated

[community] **Pitfall:** Teams that read "import assertions are deprecated" in earlier TypeScript docs sometimes assume `assert { type: "json" }` still works with a deprecation warning. It does **not** — `import assert` (the `assert` keyword in import attributes) was completely removed in TypeScript 6.0 as a hard error. There is no `"ignoreDeprecations"` escape hatch.

```typescript
// ❌ Hard error in TypeScript 6.0 — no warning, no workaround flag
import data from "./data.json" assert { type: "json" };
// error TS1552: Import assertions have been replaced by import attributes.
//              Use 'with' instead of 'assert'.

// ✅ Correct syntax — import attributes with 'with' keyword
import data from "./data.json" with { type: "json" };

// ❌ Also removed: the asserts keyword in module-level position
//    (NOT to be confused with the 'asserts' keyword in assertion functions, which is unchanged)
//    This refers only to the import syntax 'assert { type: ... }', not function assertions.

// ✅ Function-level 'asserts' keyword is completely unaffected:
function assert(condition: unknown): asserts condition {
  if (!condition) throw new Error('Assertion failed');
}
```

**Disambiguation:** TypeScript has two unrelated uses of `asserts`/`assert`:
1. **`import X from "f" assert { ... }`** — the import assertion syntax (REMOVED in TS 6.0)
2. **`function foo(x: T): asserts x is S`** — the assertion function return type keyword (UNCHANGED)

These are visually similar but completely different language features. Only #1 was removed.

---

## `--downlevelIteration` Deprecation — Understanding Why

The `--downlevelIteration` flag (TypeScript 2.3+) enabled correct ES5-compatible iteration of generators, spread on iterables, and `for...of` on non-array iterables by emitting helper functions. It was deprecated in TypeScript 6.0 alongside the removal of ES5 as a `target`.

```typescript
// Code that required --downlevelIteration under ES5 target:
function* range(start: number, end: number): Generator<number> {
  for (let i = start; i < end; i++) yield i;
}

// With target: es5 + downlevelIteration: produced helper-based spread
const values = [...range(0, 5)]; // emitted complex __spreadIterable helper

// With target: es2015+ (current baseline) — native generators, no helpers needed
// The spread compiles to Array.from() or native spread — no downlevelIteration required
```

**When you still need ES5 output in 2026:** Use an external transpiler (Babel `@babel/plugin-transform-regenerator`, SWC `jsc.target: "es5"`) as a post-TypeScript step. TypeScript's job is now type checking and modern-JS emit; downleveling to ES5 is the bundler/transpiler's responsibility.

```json
// ✅ Modern split-responsibility pipeline:
// tsconfig.json — TypeScript type checks and emits modern JS
{
  "compilerOptions": {
    "target": "es2022",    // modern output for TS
    "module": "esnext"
  }
}
// babel.config.json — Babel handles ES5 downleveling if needed
// { "presets": [["@babel/preset-env", { "targets": "defaults" }]] }
```

---

## Generic Parameter Defaults — Replacing Overload Sprawl

TypeScript supports default types on generic type parameters (`T = DefaultType`), letting you make type parameters optional without writing multiple function overloads. This pattern is underused in team codebases but dramatically reduces API surface area in libraries and shared utilities.

### Rules (enforced by the compiler)

1. **Required parameters must precede optional ones** — a generic parameter with a default cannot appear before one without a default.
2. **Defaults must satisfy any constraint** — `<T extends string = 123>` is a compiler error; the default must be assignable to the constraint.
3. **Inference takes precedence over defaults** — when TypeScript can infer `T` from arguments, the default is not used.
4. **When inference cannot choose a candidate, the default applies** — calling a function with no arguments triggers the default.

### Replacing overloads with a single declaration

```typescript
// ❌ Before: three overloads, duplicated return type, maintenance burden
declare function createElement(): Container<HTMLDivElement, HTMLDivElement[]>;
declare function createElement<T extends HTMLElement>(
  element: T
): Container<T, T[]>;
declare function createElement<T extends HTMLElement, U extends HTMLElement[]>(
  element: T,
  children: U
): Container<T, U>;

// ✅ After: one declaration with defaults — all three overload cases work
declare function createElement<
  T extends HTMLElement = HTMLDivElement,
  U extends HTMLElement[] = T[]
>(
  element?: T,
  children?: U
): Container<T, U>;

const div = createElement();
// Container<HTMLDivElement, HTMLDivElement[]>  — defaults applied

const para = createElement(new HTMLParagraphElement());
// Container<HTMLParagraphElement, HTMLParagraphElement[]>  — T inferred, U derived

const custom = createElement(new HTMLSpanElement(), [new HTMLButtonElement()]);
// Container<HTMLSpanElement, HTMLButtonElement[]>  — both inferred
```

### Practical query/state pattern (React Query style)

```typescript
// Generic defaults make library APIs dramatically easier to use
interface AsyncState<
  TData   = unknown,
  TError  = Error,
  TMeta   = Record<string, never>
> {
  data:    TData    | undefined;
  error:   TError   | null;
  meta:    TMeta;
  status:  'idle' | 'loading' | 'success' | 'error';
}

// Consumer code for the 80% case — no type arguments needed
function createState(): AsyncState { /* ... */ }

// Consumer code when specific types matter
function createTypedState(): AsyncState<User[], ApiError, RequestMeta> { /* ... */ }
```

### Cascading defaults (dependent type parameters)

```typescript
// Second default references the first type parameter
interface KeyedSet<
  TKey   = string,
  TValue = TKey[]   // defaults to an array of the key type
> {
  get(key: TKey): TValue | undefined;
  set(key: TKey, value: TValue): void;
}

// Usage without arguments uses cascading defaults: TKey=string, TValue=string[]
declare const store: KeyedSet;
store.set('tags', ['alpha', 'beta']); // TValue is string[] — correct
```

[community] **Pitfall: defaults apply only when inference fails — not when you omit the type argument.** If TypeScript can infer `T` from a function argument, it will use the inferred type even if the inference is narrower than you intended. Example: `function wrap<T = string>(value: T): T { return value; }` — calling `wrap(123)` gives `T = 123` (literal number), not `T = string`. The default only kicks in when the compiler has no other evidence. If your intention is to widen `123` to `number`, you must annotate explicitly: `wrap<number>(123)`.

[community] **Pitfall: merging declarations can silently introduce a default on a previously required parameter.** If a library's `interface Plugin<T> {}` is augmented in a `.d.ts` file with `interface Plugin<T = any> {}`, TypeScript merges the declarations and `T` becomes optional in all code that uses `Plugin`. This can hide bugs where consumers relied on `T` being required for correct type checking. Always check augmentation `.d.ts` files when debugging unexpected `any` types in generic interfaces.

---

## TypeScript 7.0 — Parallel Type Checking and Deterministic Ordering

TypeScript 7.0 (in development as of mid-2026) introduces two architectural changes that teams should prepare for now.

### 1. Deterministic Union Type Ordering

Currently, TypeScript's union type member ordering depends on **when** types are encountered during the type check pass — a non-deterministic artifact of traversal order. TypeScript 7.0 will sort union members canonically by their type structure, making declaration emit stable across compiler runs and machines.

```typescript
// Illustration of ordering divergence between TS 6.x and TS 7.0
// (simplified — actual ordering depends on many internal factors)

export function getStatus(active: boolean) {
  return active ? 'online' : 'offline';
}
// TS 6.0 emitted: 'online' | 'offline'
// TS 7.0 emitted: 'offline' | 'online'  (lexicographic, stable)

// Why it matters for your team:
// 1. snapshot tests that assert on emitted .d.ts content may change
// 2. tools that consume compiler API output expecting a fixed union order will break
// 3. teams using --declaration + tsc to generate API docs may see reshuffled output

// To test your codebase against TS 7.0 ordering now (TS 6.0+):
// Add "stableTypeOrdering": true to tsconfig.json
// Warning: adds ~25% compile time — use only for migration validation, not production builds
```

**Migration actions:**

```json
// tsconfig.json — enable 7.0 type ordering in TS 6.x to catch issues early
{
  "compilerOptions": {
    "stableTypeOrdering": true   // matches TS 7.0 behavior; ~25% slower
  }
}
```

Steps:
1. Enable `"stableTypeOrdering": true` on a branch.
2. Run `tsc --noEmit` and fix any new inference errors (these are real correctness issues).
3. Audit snapshot tests and CI scripts that assert on `.d.ts` content.
4. Disable the flag before merging — it is a migration diagnostic, not a production flag.
5. Remove the flag and upgrade to TypeScript 7.0 when it releases.

### 2. Parallel Type Checking Architecture

TypeScript 7.0 will parallelize type checking across project references, enabling each package in a composite project to be checked concurrently. This is the main performance goal of the TypeScript Go rewrite (`typescript-go` / `@typescript/native-preview`).

**What it requires of your code:**

- **`isolatedDeclarations: true`** becomes more important: parallel checking cannot cross package boundaries without pre-computed `.d.ts` files. Packages without `isolatedDeclarations` become serial bottlenecks.
- **Explicit return type annotations on all exported functions** — required by `isolatedDeclarations` and essential for the parallel checker to work without waiting for cross-file inference.
- **No circular `import` chains across project references** — parallel checking breaks on cycles between composite packages.

```typescript
// ✅ Parallel-checker-friendly: explicit annotation, no cross-module inference needed
export function parseConfig(raw: string): AppConfig {
  return JSON.parse(raw) as AppConfig;
}

// ❌ Serial bottleneck: inference requires reading the full function body
//    The parallel checker must wait for this file to complete before .d.ts is emitted
export function parseConfig(raw: string) {
  return JSON.parse(raw) as AppConfig;  // return type must be inferred
}
```

---

## TypeScript 6.0 — `rootDir` Inference Removal: Output Path Migration

TypeScript 6.0 changed the default value of `rootDir` from _inferred_ to the directory containing the `tsconfig.json`. Before this change, TypeScript inferred `rootDir` by finding the longest common ancestor of all included files. After this change, it defaults to `.` (the tsconfig directory). This shifts the output structure for projects that relied on inference without an explicit `rootDir`.

**Concrete example — before/after the TS 6.0 default:**

```
project/
  tsconfig.json          ← compilerOptions.outDir = "dist"
  src/
    index.ts
    utils/
      helpers.ts
```

```typescript
// TypeScript 5.9 (inferred rootDir = "src"):
// dist/
//   index.js            ← previously: dist/index.js (rootDir inferred as ./src)
//   utils/
//     helpers.js

// TypeScript 6.0 (default rootDir = "." — the tsconfig directory):
// dist/
//   src/                ← NEW extra level introduced by the default change
//     index.js
//     utils/
//       helpers.js

// ✅ Fix: add explicit rootDir to restore the TS 5.9 behavior
// tsconfig.json:
// {
//   "compilerOptions": {
//     "rootDir": "./src",   // explicit — no longer inferred
//     "outDir": "./dist"
//   }
// }
```

**Why this breaks CI and deployment:** Most projects deploy artifacts by looking for files at hardcoded paths (`dist/index.js`, `dist/server.js`). When the extra `src/` level appears, Docker `COPY`, deployment scripts, and `"main"` entries in `package.json` silently point to the wrong path — the build succeeds but the application fails to start.

**Migration checklist:**
1. Add `"rootDir": "./src"` (or wherever your source lives) to all `tsconfig.json` files.
2. Verify `"main"` in `package.json` still resolves after the rootDir change.
3. Check Dockerfile `COPY dist/index.js` paths and CI artifact upload steps.
4. Use `tsc --listEmittedFiles --noEmit` to preview where files will land before committing.

[community] **Pitfall: `ts5to6` migrates `baseUrl` and `paths` but does NOT automatically add `rootDir`.** The automated migration tool handles the `baseUrl` → `paths` transformation well, but `rootDir` inference removal requires a manual audit of each `tsconfig.json`. Run `tsc --listEmittedFiles` after upgrading to detect the extra directory level before it reaches production.

---

## `types: ["*"]` — Anti-Pattern: Restoring the TS 6.0 Legacy Default

TypeScript 6.0 changed the default value of `types` from auto-including all `@types/*` packages to an empty list (`[]`). When projects hit "Cannot find name 'process'" or "Cannot find name 'describe'" after upgrading, the first impulse is to restore the old behavior with `"types": ["*"]`.

**Do not use `"types": ["*"]`:** The wildcard syntax re-enables auto-inclusion of every `@types/*` package in `node_modules`, which carries a **20–50% build performance penalty** compared to an explicit list. The TypeScript compiler must parse and type-check every ambient declaration file it discovers, whether or not your code uses it.

```json
// ❌ Tempting but harmful — restores old behavior but degrades build time 20-50%
{
  "compilerOptions": {
    "types": ["*"]
  }
}

// ✅ Correct — list only the @types packages your project actually uses
{
  "compilerOptions": {
    "types": ["node"]                  // Node.js project
  }
}

// ✅ Correct — test-framework globals scoped to test tsconfig
// tsconfig.test.json — extends base, adds test framework types
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": ["node", "jest"]          // add jest only in test context
  }
}
```

**How to audit what `@types` packages you need:**
1. Run `tsc --noEmit` with `"types": []` and read every "Cannot find name X" error.
2. For each missing global, find which `@types/*` package declares it (`@types/node` → `process`, `Buffer`; `@types/jest` → `describe`, `it`, `expect`).
3. Add only those packages to `"types"`.

[community] **Pitfall:** Splitting `types` between a root `tsconfig.json` and a `tsconfig.test.json` is the correct pattern, but teams often forget to update both files when adding a new test framework. If `@types/vitest` or `@types/jest` is added to the root config, it pollutes production code with test globals — `describe` and `it` will be available everywhere. The fix is to keep test-framework types exclusively in a test-scoped tsconfig and never in the production config.

---

## `PartialExcept<T, K>` — Required Keys with Optional Rest

A common update-API pattern requires that some keys must always be provided (primary key, discriminant) while all other fields are optional for partial updates. TypeScript's built-in `Partial<T>` makes _everything_ optional; `Required<T>` makes everything required. Neither model an update payload where the identity key is mandatory and everything else is optional.

```typescript
// Custom utility: make K required, rest optional
type PartialExcept<T, K extends keyof T> = Partial<T> & Required<Pick<T, K>>;

interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user';
  createdAt: Date;
}

// Update payload: id is required, everything else is optional
type UserUpdate = PartialExcept<User, 'id'>;
// Equivalent to: { id: number } & { name?: string; email?: string; role?: ...; createdAt?: Date }

function updateUser(patch: UserUpdate): Promise<User> {
  // patch.id is always present — no need to guard
  return db.update('users', patch.id, patch);
}

// ✅ Valid: only id required
updateUser({ id: 42, name: 'Alice' });
updateUser({ id: 42 });

// ❌ Error: id is missing — TypeScript correctly rejects this
// updateUser({ name: 'Alice' });

// Variant: require multiple keys (e.g., composite key)
type CommentUpdate = PartialExcept<Comment, 'postId' | 'commentId'>;
```

**When to use vs `Partial<T>`:**
- Use `Partial<T>` for configuration objects where nothing is required.
- Use `PartialExcept<T, 'id'>` for update/patch payloads where the primary key must be present.
- Use `Required<Pick<T, K>>` alone when you need an extract of required-only fields.

[community] **Pitfall:** `PartialExcept<T, K>` combined with `exactOptionalPropertyTypes: true` behaves differently from `Partial<T>`. The `Partial` intersection makes remaining fields `T[K] | undefined` (optional key), while `Required<Pick<T, K>>` makes the primary key required but NOT `undefined`. If you use `exactOptionalPropertyTypes`, test that `undefined` values in `Partial` fields are intentional — they will be encoded differently from absent keys in JSON serialization.

---

## Community Pitfall: `tsc --init` (TS 5.9+) Generates Opinionated Defaults

TypeScript 5.9 changed `tsc --init` from a verbose commented template to a minimal, prescriptive `tsconfig.json`. The new defaults include settings that are inappropriate for many projects.

```json
// What `tsc --init` generates in TS 5.9+:
{
  "compilerOptions": {
    "module": "nodenext",
    "target": "esnext",
    "types": [],
    "sourceMap": true,
    "declaration": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "strict": true,
    "jsx": "react-jsx",           // ← included even for non-React projects
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "noUncheckedSideEffectImports": true,
    "moduleDetection": "force",
    "skipLibCheck": true
  }
}
```

**Problematic defaults to review:**

| Setting | Problem for non-React/Node projects | Fix |
|---|---|---|
| `"jsx": "react-jsx"` | Errors on `.tsx` files unless `react-jsx` transform is available; dead config for non-React projects | Remove entirely if not using JSX |
| `"module": "nodenext"` | Requires `.js` extensions on imports — surprising for new projects expecting `import './utils'` | Use `"bundler"` for Vite/webpack projects; keep `nodenext` for Node-only |
| `"noUncheckedIndexedAccess": true` | Makes array/object index lookups return `T | undefined` — correct but breaks existing code using indexes without null-checks | Keep enabled on new projects; disable temporarily when migrating |
| `"exactOptionalPropertyTypes": true` | Prevents `undefined` from being explicitly assigned to optional fields — correct but a breaking change for existing Partial-based update patterns | Address `PartialExcept` pattern before enabling |
| `"isolatedModules": true` | Errors on `const enum` and `namespace` — correct for bundler builds but breaks some legacy code patterns | Enable on all new projects; may require enum-to-string migration |

[community] **Pitfall:** Teams running `tsc --init` on a new project in TS 5.9+ then immediately starting to write code hit a wall of errors from `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`. These are _correct_ flags but they should be adopted deliberately with team buy-in, not silently enabled by a scaffolding command. Always review each flag in the generated `tsconfig.json` before committing it — treat `tsc --init` output as a _menu of options_, not a ready-to-use config.

[community] **Pitfall: enabling `stableTypeOrdering` in a production `tsconfig.json` accidentally.** Teams test with this flag and forget to remove it before shipping. The 25% compile slowdown is invisible in small projects but significant in large monorepos — it appears as a regression in CI build time with no obvious cause. Keep `stableTypeOrdering` in a separate `tsconfig.check-7.0.json` and never merge it into the main `tsconfig.json`.

---

## Testing-Specific TypeScript Patterns

### `using` Declaration for Test Resource Cleanup (TypeScript 5.2+)

The `using` keyword (explicit resource management, TypeScript 5.2) works natively inside test hooks, replacing `try/finally` and `afterEach` cleanup boilerplate. Any value that implements `Symbol.dispose` is automatically cleaned up when the `using` variable goes out of scope — including at the end of a `beforeEach` or `it` block.

```typescript
import { beforeEach, it, describe, expect } from 'vitest';
import { DatabaseConnection } from '../db';

// Test-scoped disposable: database transaction rolled back on scope exit
class TestTransaction implements Disposable {
  private rolledBack = false;
  constructor(private readonly db: DatabaseConnection) {
    db.beginTransaction();
  }
  [Symbol.dispose](): void {
    if (!this.rolledBack) {
      this.db.rollback();  // automatic cleanup — no afterEach needed
    }
  }
}

describe('OrderRepository', () => {
  it('creates an order and rolls back', async () => {
    using _tx = new TestTransaction(db);  // rollback fires when 'it' block exits
    const order = await orderRepo.create({ items: ['a'], total: 100 });
    expect(order.id).toBeDefined();
    // No afterEach needed — transaction rolled back automatically on scope exit
  });
});

// Async variant: use 'await using' for async teardown
class TestServer implements AsyncDisposable {
  constructor(private readonly server: http.Server) {}
  async [Symbol.asyncDispose](): Promise<void> {
    await new Promise<void>(resolve => this.server.close(() => resolve()));
  }
}

describe('API integration', () => {
  it('handles requests', async () => {
    await using _server = new TestServer(createServer(app));
    const res = await fetch('http://localhost:3000/health');
    expect(res.status).toBe(200);
    // server.close() awaited automatically when 'it' block exits
  });
});
```

[community] **Pitfall:** Using `using` inside `beforeEach` disposes the resource at the END of `beforeEach`, not at the end of each `it` block — the opposite of what most teams expect. The `using` scope is the function body it appears in. To share a resource across `beforeEach` + test + `afterEach`, use `DisposableStack` and manage disposal explicitly in `afterEach`, or use a test-scoped `using` inside each `it` block directly.

---

### Type-Safe `expect.extend` Custom Matchers (Jest / Vitest)

Extending `expect` with custom matchers in TypeScript requires two steps: implementing the matcher with a typed function signature, then augmenting the `expect` module to register the new matcher in the type system.

**Jest implementation:**

```typescript
// matchers/toBeValidUuid.ts
import { expect } from '@jest/globals';
import type { MatcherFunction } from 'expect';

// MatcherFunction<[...args]> types the custom matcher's extra arguments
const toBeValidUuid: MatcherFunction<[]> = function (received) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const pass = typeof received === 'string' && uuidRegex.test(received);
  return {
    pass,
    message: () =>
      pass
        ? `expected ${this.utils.printReceived(received)} NOT to be a valid UUID`
        : `expected ${this.utils.printReceived(received)} to be a valid UUID`,
  };
};

expect.extend({ toBeValidUuid });

// Step 2: augment the module so TypeScript knows about the new matcher
declare module 'expect' {
  interface Matchers<R> {
    toBeValidUuid(): R;            // for expect(value).toBeValidUuid()
  }
  interface AsymmetricMatchers {
    toBeValidUuid(): void;         // for expect.toBeValidUuid() inside toEqual()
  }
}
```

**Vitest implementation (same structure, different import):**

```typescript
// matchers/toBeValidUuid.ts
import { expect } from 'vitest';
import type { CustomMatcherResult } from '@vitest/expect';

// Vitest uses the same MatcherFunction / CustomMatcherResult contract as jest
expect.extend({
  toBeValidUuid(received: unknown): CustomMatcherResult {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const pass = typeof received === 'string' && uuidRegex.test(received);
    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} NOT to be a valid UUID`
          : `expected ${received} to be a valid UUID`,
    };
  },
});

// Augment Vitest's Assertion interface
declare module 'vitest' {
  interface Assertion<T = unknown> {
    toBeValidUuid(): T;
  }
  interface AsymmetricMatchersContaining {
    toBeValidUuid(): void;
  }
}
```

**Usage in tests — fully typed:**

```typescript
import '../matchers/toBeValidUuid';   // register both runtime and types

it('creates a user with a valid UUID', async () => {
  const user = await createUser({ name: 'Alice' });
  expect(user.id).toBeValidUuid();  // ✅ TypeScript knows this matcher exists
  expect({ id: expect.toBeValidUuid() }).toMatchObject({ id: user.id }); // asymmetric
});
```

[community] **Pitfall:** Placing `declare module 'expect' {}` augmentation in a file that doesn't `import` anything makes TypeScript treat the file as a **script** (not a module), causing the declaration to merge into the global scope rather than augmenting the module. Always add `export {};` at the bottom of augmentation-only `.d.ts` files to ensure the file is treated as a module.

[community] **Pitfall:** Vitest 2.x changed the `Assertion` interface name — earlier versions of `@vitest/expect` used `Matchers<R>` (same as Jest). If you copy Jest matcher type augmentations into a Vitest project, you may get a "namespace not found" error. Use `interface Assertion<T>` for Vitest (≥2.x) and `interface Matchers<R>` for Jest.

---

### Vitest 2.x `vi.fn()` Generic Type Parameter Change

Vitest 2.x changed the generic signature of `vi.fn()`. In Vitest 1.x, `vi.fn` accepted two generic parameters: `vi.fn<Args extends unknown[], Return>()`. In Vitest 2.x (and aligned with Jest's `jest.fn()`), the signature changed to a single function type parameter: `vi.fn<T extends (...args: unknown[]) => unknown>()`.

```typescript
// ❌ Vitest 1.x style — two-tuple generic (breaks in Vitest 2.x)
const mockFn = vi.fn<[string, number], Promise<User>>();

// ✅ Vitest 2.x style — single function type generic
const mockFn = vi.fn<(id: string, count: number) => Promise<User>>();

// ✅ Alternative: let inference do the work via mockImplementation
const mockFn = vi.fn().mockImplementation(async (id: string, count: number): Promise<User> => ({
  id,
  name: 'Alice',
  count,
}));
// mockFn is correctly typed as Mock<(id: string, count: number) => Promise<User>>

// vi.Mocked<T> — deep mock wrapping with typed .mock.calls, .mockReturnValue, etc.
import type { UserRepository } from './user-repository';

const mockRepo = {
  findById: vi.fn<(id: string) => Promise<User | null>>(),
  save:     vi.fn<(user: User) => Promise<User>>(),
} satisfies vi.Mocked<UserRepository>;   // satisfies verifies all interface methods are present

// ✅ mockRepo.findById.mockResolvedValue(null)  — fully typed
// ✅ mockRepo.save.mockResolvedValue({ id: '1', name: 'Alice' })
```

**`Awaited<ReturnType<...>>` for async mock return type inference:**

```typescript
// Extract the resolved type from an async function to type mockResolvedValue correctly
async function fetchOrder(id: string): Promise<Order> { /* ... */ }

type FetchOrderResult = Awaited<ReturnType<typeof fetchOrder>>;  // Order

const mockFetch = vi.fn<typeof fetchOrder>();
const sampleOrder: FetchOrderResult = {
  id: 'ord_123',
  total: 99.99,
  status: 'pending',
};

mockFetch.mockResolvedValue(sampleOrder);  // type-checked against Order
```

[community] **Pitfall:** `vi.fn<[string], Promise<User>>()` (Vitest 1.x syntax) silently compiles in Vitest 2.x but produces a `Mock<unknown>` type — TypeScript infers the wrong function shape because the two-generic form is no longer the primary overload. The result: `mockFn.mockResolvedValue(user)` stops type-checking the argument, and `mockFn.mock.calls[0][0]` is typed `unknown` instead of `string`. Upgrade all two-generic `vi.fn<Args, Return>` calls to the single function-type form after upgrading to Vitest 2.x.

---

### `satisfies` for Exhaustive Test Fixture Type-Checking

The `satisfies` operator (TypeScript 4.9+) is especially powerful in test suites: it validates that a test fixture conforms to the expected type without widening literal values, AND it errors at compile time when a new discriminant variant is added to a union but the fixture doesn't cover it.

```typescript
type ApiEvent =
  | { type: 'request';  method: string; url: string }
  | { type: 'response'; status: number; body: unknown }
  | { type: 'error';    code: string;   message: string };

// ✅ satisfies: each fixture is narrowly typed AND the array is validated
//    against ApiEvent[] — compile error if a new union variant is added
//    without a matching fixture
const TEST_FIXTURES = [
  { type: 'request',  method: 'GET',  url: '/api/users' },
  { type: 'response', status: 200,    body: { id: 1 } },
  { type: 'error',    code: 'E_AUTH', message: 'Unauthorized' },
] satisfies ApiEvent[];

// TEST_FIXTURES[0].url is string (narrow), not unknown
// TEST_FIXTURES[0].method is string, not 'GET' | ... (exact string, not literal — use as const for literals)

// ✅ Combine with as const for fully narrow fixtures
const FIXTURES_NARROW = [
  { type: 'request',  method: 'GET',  url: '/api/users' } as const,
  { type: 'response', status: 200,    body: { id: 1 } } as const,
  { type: 'error',    code: 'E_AUTH', message: 'Unauthorized' } as const,
] satisfies readonly ApiEvent[];

// FIXTURES_NARROW[0].method is 'GET' (literal), not string

// ❌ When a new variant is added to ApiEvent without a fixture:
type ApiEvent2 =
  | { type: 'request';  method: string; url: string }
  | { type: 'response'; status: number; body: unknown }
  | { type: 'error';    code: string;   message: string }
  | { type: 'timeout';  durationMs: number };  // NEW — fixture array is now incomplete

// const fixtures = [...] satisfies ApiEvent2[];
// ❌ Error: Type '{ type: "request"; ... }[]' does not satisfy 'ApiEvent2[]'
//    because it's missing a { type: 'timeout'; ... } variant
// This is intentional — tests are forced to cover new variants at compile time
```

[community] **Pitfall:** `satisfies ApiEvent[]` validates that every element matches one member of the union — it does NOT validate that every union member has a corresponding fixture. For exhaustive fixture coverage, combine `satisfies` with a separate object keyed by discriminant (like `Record<ApiEvent['type'], ApiEvent>`) — that enforces a key for every union member. The `satisfies ApiEvent[]` approach above only validates that existing fixtures have correct shapes; adding a new discriminant to the union does NOT cause a compile error on the array.

---

### `satisfies` for Complete `Record<UnionKey, ...>` Fixture Maps

When you want compile-time exhaustiveness — a fixture or handler for every member of a union — use `satisfies Record<Union, V>` (not `satisfies Union[]`):

```typescript
type Status = 'idle' | 'loading' | 'success' | 'error';

// ✅ Record keyed by union: MUST have an entry for every Status member
//    Adding a new Status member causes a compile error here — exhaustive by design
const STATUS_LABELS = {
  idle:    'Idle',
  loading: 'Loading...',
  success: 'Done',
  error:   'Something went wrong',
} satisfies Record<Status, string>;

// ❌ If 'cancelled' is added to Status:
// type Status = 'idle' | 'loading' | 'success' | 'error' | 'cancelled';
// satisfies Record<Status, string> → Error: Property 'cancelled' is missing
// This is correct — the test fixture must be updated to cover the new state

// Same pattern for route handlers in test suites
type Route = '/users' | '/products' | '/orders';
type HandlerFn = (req: MockRequest) => MockResponse;

const MOCK_HANDLERS = {
  '/users':    (req) => ({ status: 200, body: [] }),
  '/products': (req) => ({ status: 200, body: [] }),
  '/orders':   (req) => ({ status: 200, body: [] }),
} satisfies Record<Route, HandlerFn>;
// Adding a new Route type forces the mock handlers map to be updated
```

---

## Anti-Patterns Quick Reference (continued additions)

The following rows extend the Anti-Patterns table earlier in this guide with testing-specific entries:

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| `const` instead of `using` for test resources | Cleanup only runs if code reaches the `afterEach`/teardown call — early returns and exceptions skip it | Implement `Disposable` / `AsyncDisposable` and declare with `using` / `await using` inside each `it` block |
| `declare module 'expect'` in a script (no `export {}`) | File treated as a script, merging augmentation into global scope rather than the module | Add `export {};` to all module-augmentation-only files |
| `vi.fn<[Args], Return>()` two-generic form in Vitest 2.x | Returns `Mock<unknown>` — type checking on `.mockResolvedValue`, `.mock.calls` is silently disabled | Use single function-type generic: `vi.fn<(arg: T) => R>()` |
| `satisfies ApiEvent[]` expecting exhaustiveness over union variants | Array satisfies validates element shapes, not union coverage — new discriminants are not caught | Use `satisfies Record<Union['discriminant'], Union>` for exhaustive keyed coverage |
| Casting test fixtures with `as MyType` | Type cast bypasses shape validation — adding a field to `MyType` doesn't error on the stale fixture | Use `satisfies MyType` for validation without widening, or `const x: MyType = { ... }` for full assignment checking |
| Always-truthy condition on regex literal (`if (/pattern/)`) | Regex literals are always truthy — the condition never branches correctly; TS 5.6 now errors | Use `.test(str)` to evaluate the regex against a value: `if (/pattern/.test(str))` |
| `new RegExp(str)` for validated regex patterns | Dynamic `RegExp` constructor calls are NOT syntax-checked by TypeScript 5.5 — invalid patterns fail only at runtime | Use a regex literal so TypeScript validates syntax, backreferences, and ES version compatibility at compile time |
| Using computed key access `obj[key]` without narrowing (pre-5.5) | TypeScript previously widened `obj[key]` to the full index type even after a `typeof` check — losing the narrowing | TypeScript 5.5+ narrows `obj[key]` when both `obj` and `key` are effectively constant; explicit annotation required for truly dynamic keys |
| Hardcoded relative paths in monorepo `tsconfig.json` `paths` | `"../../shared/*"` breaks if the config file is moved or the repo structure changes | Use `"${configDir}/*"` (TS 5.5+) to make paths relative to the tsconfig file's own directory, not the build root |

---

## TypeScript 5.5 — RegExp Syntax Checking

TypeScript 5.5 introduced compile-time syntax validation of regular expression literals. The compiler now catches four categories of errors that previously failed silently at runtime.

### 1. Syntax Errors

```typescript
// ❌ Extra closing parenthesis — unbalanced group
let re1 = /@robot(\s+(please|immediately)))? do task/;
//                                         ~
// Error: Unexpected ')'. Did you mean to escape it with backslash?

// ❌ Dangling quantifier with no preceding atom
let re2 = /*/;
// Error: Nothing to repeat.
```

### 2. Invalid Backreferences

```typescript
// ❌ \3 references a group that doesn't exist (only groups 1 and 2 are present)
let re3 = /@typedef \{import\((.+)\)\.([a-zA-Z_]+)\} \3/u;
//                                                    ~~
// Error: This backreference refers to a group that does not exist.
//        There are only 2 capturing groups in this regular expression.
```

### 3. Invalid Named Group References

```typescript
// ❌ \k<namedImport> names a group that doesn't exist
let re4 = /(?<importPath>.+)\.(?<importedEntity>[a-zA-Z_]+) \k<namedImport>/;
//                                                              ~~~~~~~~~~~
// Error: There is no capturing group named 'namedImport' in this regular expression.

// ✅ Correct: reference the actual group name
let re5 = /(?<importPath>.+)\.(?<importedEntity>[a-zA-Z_]+) \k<importedEntity>/;
```

### 4. ECMAScript Version Compatibility

```typescript
// ❌ Named capturing groups require ES2018 — error when targeting older versions
// tsconfig: "target": "ES2015"
let re6 = /(?<year>\d{4})-(?<month>\d{2})/;
//          ~~~~~~~~~~      ~~~~~~~~~~~~~
// Error: Named capturing groups are only available when targeting 'ES2018' or later.
// Fix: Update target to 'ES2018'+, or use positional groups: /(\d{4})-(\d{2})/

// ❌ The 'v' (unicode sets) flag requires ES2024
let re7 = /[\p{Script=Greek}&&\p{Letter}]/v;
// Error: This regular expression flag is only available when targeting 'ES2024' or later.
```

### Testing Relevance

RegExp validation is especially valuable for testing utilities that use regex patterns for matching, fixture filtering, or schema validation:

```typescript
// ❌ Subtle bug in a test helper: extra ) causes wrong match behavior
function assertMatchesPattern(value: string, pattern: string): void {
  // Using new RegExp() — NOT checked by TypeScript 5.5
  const re = new RegExp(pattern);  // runtime error if pattern is invalid
  expect(value).toMatch(re);
}

// ✅ Safer: use a regex literal in the test — TypeScript validates at compile time
it('matches expected format', () => {
  const re = /^usr_[0-9a-f]{8}$/;  // ← syntax validated at compile time
  expect(userId).toMatch(re);
});
```

[community] **Pitfall: TypeScript 5.5 ONLY validates regex literals — not `new RegExp(string)` calls.** When a regex pattern is passed as a string (e.g., `new RegExp(userInput)`, `new RegExp(PATTERN_CONSTANT)`), TypeScript performs no validation. This is intentional — the pattern may be constructed dynamically at runtime. If you have complex regex logic that must be validated at compile time, extract the literal form and assign to a `const` first:

```typescript
// ❌ No compile-time validation
const PATTERN = "^usr_[0-9a-f]{8}$";
const re = new RegExp(PATTERN);  // TypeScript does not check PATTERN

// ✅ Compile-time validation via literal
const re = /^usr_[0-9a-f]{8}$/;  // TypeScript checks this

// If you need the string form too:
const re = /^usr_[0-9a-f]{8}$/;  // validates here
const PATTERN = re.source;        // extract string after validation
```

---

## TypeScript 5.5 — Constant Indexed Access Narrowing

TypeScript 5.5 added narrowing support for `obj[key]` expressions where both `obj` and `key` are effectively constant within a control flow branch. Previously, index access was always widened to the full index signature type — even after a `typeof` check.

```typescript
// Before TypeScript 5.5: obj[key] not narrowed
function processRecord(obj: Record<string, unknown>, key: string) {
  if (typeof obj[key] === 'string') {
    obj[key].toUpperCase();  // ❌ Error before 5.5: 'unknown' not narrowed to 'string'
  }
}

// TypeScript 5.5+: obj[key] narrows correctly when both obj and key are const in the branch
function processRecord(obj: Record<string, unknown>, key: string) {
  if (typeof obj[key] === 'string') {
    obj[key].toUpperCase();  // ✅ TypeScript 5.5: 'unknown' narrows to 'string'
  }
}
```

**Testing relevance — accessing fixture properties by computed key:**

```typescript
// Common test pattern: iterate over fixture keys and validate types
interface Fixture {
  name: string;
  count: number;
  active: boolean;
}

const fixture: Fixture = { name: 'Alice', count: 5, active: true };
const key = 'name' as keyof Fixture;

// Before 5.5: string | number | boolean (widened)
// After 5.5: string (narrowed because typeof check is narrowing-compatible)
if (typeof fixture[key] === 'string') {
  fixture[key].toUpperCase();  // ✅ TypeScript 5.5+ — correctly narrowed to string
}

// TS 5.5 constraint: BOTH obj and key must be effectively constant in the branch
// If key is reassigned inside the if block, narrowing is lost
function narrowingLost(obj: Record<string, unknown>, key: string) {
  if (typeof obj[key] === 'string') {
    key = 'other';           // reassignment invalidates narrowing
    obj[key].toUpperCase();  // ❌ Error: 'unknown', narrowing was broken by key reassignment
  }
}
```

[community] **Pitfall:** Narrowing of `obj[key]` still requires that neither `obj` nor `key` are mutated inside the narrowing block. Assigning to either variable after the `typeof` check will widen the type back. In test loops that reassign the iteration variable, add explicit non-null assertions or move the assertion logic to a helper with an immutable key parameter.

---

## TypeScript 5.6 — Always-Truthy and Always-Nullish Detection

TypeScript 5.6 added compile-time detection of conditions that always evaluate the same way — catching common bugs caused by typos, logic errors, and misuse of JavaScript operators.

### Always-Truthy Conditions

```typescript
// ❌ Regex literal as a condition — ALWAYS truthy (the regex object, not the match result)
if (/0x[0-9a-f]/) {
  // Error: This kind of expression is always truthy.
  // FIX: if (/0x[0-9a-f]/.test(input))
}

// ❌ Arrow function as a condition — ALWAYS truthy (functions are truthy objects)
const isPositive = (n: number) => n > 0;
if (isPositive) {
  // Error: This kind of expression is always truthy.
  // FIX: if (isPositive(value))
}

// ❌ Class as a condition — ALWAYS truthy (class constructors are truthy)
class Validator {}
if (Validator) {
  // Error: This kind of expression is always truthy.
  // FIX: if (new Validator().isValid(input)) — or compare to null/undefined explicitly
}
```

**Intentional patterns that are allowed:** TypeScript 5.6 explicitly permits `while (true)`, `if (false)`, and other idioms that programmers use deliberately. The check targets expressions where the truthy/falsy behavior is almost certainly unintentional.

### Unreachable `??` Right Operand

```typescript
// ❌ Right operand of ?? is unreachable — left side is never nullish
function clamp(value: number, max: number): number {
  return value < max ?? 100;
  //               ~~~~~~~
  // Error: Right operand of '??' is unreachable because the left operand is never nullish.
  // 'value < max' is a boolean — it can never be null or undefined.
  // FIX: return (value < max ? value : max) ?? 100;
  //      Or:   return value < max ? value : 100;
}

// ❌ Nullish coalescing on a value that's already non-null by type
function getLabel(status: 'active' | 'inactive'): string {
  return status ?? 'unknown';
  //             ~~~~~~~~~~
  // Error: Right operand of '??' is unreachable because 'status' is never nullish.
  // 'active' | 'inactive' cannot be null or undefined.
  // FIX: Remove the ?? fallback — it's dead code.
}
```

### Testing Relevance

These checks are especially valuable in test files where conditional guards and fixture logic are common:

```typescript
// ❌ Common test anti-pattern: calling the mock instead of checking the mock
const mockSend = vi.fn();
if (mockSend) {
  // Error: This kind of expression is always truthy.
  // The mock function object is always truthy — this test guard always passes.
  // FIX: if (mockSend.mock.calls.length > 0) — check that it was actually called
}

// ❌ Regex literal in assertion helper — always truthy, never validates
function assertMatches(value: string): void {
  const pattern = /^[a-z]+$/;
  if (pattern) {   // ← Error: always truthy! The regex object, not a match.
    console.log('matches');
  }
  // FIX: if (pattern.test(value)) { ... }
}

// ✅ Correct: check the result of .test(), not the regex itself
function assertLowercase(value: string): void {
  if (/^[a-z]+$/.test(value)) {
    console.log('valid lowercase');
  }
}
```

[community] **Pitfall: TS 5.6's always-truthy check on `if (fn)` catches a real class of bugs in test files.** It's common to write `if (mockFn)` thinking it checks whether the mock was called, or `if (MyClass)` thinking it checks whether the class is defined. Both are always truthy. The fix pattern: for mocks, check `mockFn.mock.calls.length > 0` or use `expect(mockFn).toHaveBeenCalled()`; for class existence, use `if (typeof MyClass !== 'undefined')`. TypeScript 5.6 makes these silent logic bugs into hard compiler errors.

---

## TypeScript 5.5 — `${configDir}` Template Variable in tsconfig Paths

TypeScript 5.5 added a `${configDir}` template variable for use in `tsconfig.json` values (specifically `paths` and `baseUrl`). It expands to the absolute directory containing the `tsconfig.json` file, making path mappings portable across monorepo structures.

### The Problem It Solves

In a monorepo with a root `tsconfig.json` and per-package configs that extend it, `paths` entries using relative paths are relative to the **root config**, not the **extending config**. This means paths break when a package is nested at a different depth:

```
monorepo/
  tsconfig.base.json     ← shared config
  packages/
    api/
      tsconfig.json      ← extends ../../tsconfig.base.json
    admin/ui/
      tsconfig.json      ← extends ../../../tsconfig.base.json
```

```json
// tsconfig.base.json — PROBLEM: relative path is resolved from where it's used, not defined
{
  "compilerOptions": {
    "paths": {
      "@shared/*": ["../../shared/src/*"]  // ← relative to tsconfig.base.json's location
    }
  }
}
// For packages/api/ → resolves to monorepo/shared/src/* ✅
// For packages/admin/ui/ → resolves to monorepo/packages/shared/src/* ❌ (wrong depth)
```

### Solution: `${configDir}`

```json
// tsconfig.base.json — CORRECT: ${configDir} always resolves to the directory
// of the CONSUMING config file (the one that `extends` this one), not the base
{
  "compilerOptions": {
    "paths": {
      "@shared/*": ["${configDir}/../../shared/src/*"]
    }
  }
}
// For packages/api/tsconfig.json:      → packages/api/../../shared/src/* = monorepo/shared/src/*
// For packages/admin/ui/tsconfig.json: → packages/admin/ui/../../shared/src/* = packages/shared/src/* ✅

// Or in a root config that references its own siblings:
{
  "compilerOptions": {
    "paths": {
      "@utils/*":   ["${configDir}/src/utils/*"],
      "@services/*": ["${configDir}/src/services/*"]
    }
  }
}
// Always correct regardless of cwd or how the project is referenced
```

**Combining with `extends` chains:**

```json
// packages/api/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    // ${configDir} here refers to packages/api/ — the directory of THIS file
    // ${configDir} in tsconfig.base.json will also expand to packages/api/
    // (the consuming file's directory, not the base file's directory)
  }
}
```

[community] **Pitfall: `${configDir}` was added in TypeScript 5.5 and has no effect in earlier versions.** Tools that read `tsconfig.json` without using TypeScript's own parser (some webpack plugins, older editors) may not expand the variable. If your build tooling uses an older parser, the `${configDir}` literal appears as-is and path resolution silently fails. Verify your build tool's TypeScript version before adopting this feature.

[community] **Pitfall: `${configDir}` is only supported in `paths` and `baseUrl` — NOT in `rootDir`, `outDir`, `include`, or `exclude`.** Teams discovering `${configDir}` sometimes apply it to other tsconfig fields expecting uniform path resolution. Outside of `paths`/`baseUrl`, the literal `${configDir}` appears verbatim and is NOT expanded.

---

## TypeScript 5.7 — Checks for Never-Initialized Variables

TypeScript 5.7 added detection of variables that are declared but never assigned in any reachable code path — a class of bug where a variable is used in a nested closure or callback before it has been given a value.

```typescript
// ❌ Before TypeScript 5.7: no error — TypeScript couldn't see that 'result' was
//    used inside printResult before it was ever assigned in the enclosing function
function computeAndPrint(): void {
  let result: number;
  // Imagine complex logic here that forgets to assign 'result'
  function printResult() {
    console.log(result);  // TS 5.7 Error: Variable 'result' is used before being assigned.
  }
  printResult();
}

// ✅ Fix: assign a default value at declaration
function computeAndPrint(): void {
  let result: number = 0;  // initialized — no error
  function printResult() {
    console.log(result);
  }
  printResult();
}

// ✅ Alternative: assign in all code paths before the closure is called
function computeWithPaths(condition: boolean): void {
  let result: number;
  if (condition) {
    result = 42;
  } else {
    result = 0;
  }
  function printResult() {
    console.log(result);  // TypeScript knows result is assigned in all paths
  }
  printResult();
}
```

**Why closures are the key pattern:** TypeScript's existing definite-assignment analysis handles direct use of variables well (`let x: number; console.log(x)` always errored). TypeScript 5.7 extended the analysis to variables captured by nested functions and closures, where the use is deferred to a later invocation rather than appearing inline.

[community] **Pitfall:** If you upgrade to TypeScript 5.7 and see new "Variable used before being assigned" errors in functions that use callbacks or closures, resist the urge to add `!` non-null assertions. The error is real — the variable genuinely may not be assigned when the closure executes. Fix by initializing at declaration, or by restructuring the code so assignment is guaranteed before the nested function runs.

---

## TypeScript 5.7 — ES2024 Target and `TypedArray` Generic Change

### ES2024 Target Support

TypeScript 5.7 added `--target es2024` and `--lib es2024`, including built-in types for:
- `Object.groupBy` and `Map.groupBy` — group iterables by a computed key
- `Promise.withResolvers` — create a Promise with externally-accessible resolve/reject functions
- `ArrayBuffer.prototype.transfer` — zero-copy transfer of ArrayBuffer ownership

```typescript
// Object.groupBy — ES2024 built-in (requires "target": "es2024" or lib: ["es2024"])
const people = [
  { name: 'Alice', dept: 'eng' },
  { name: 'Bob',   dept: 'design' },
  { name: 'Carol', dept: 'eng' },
];

const byDept = Object.groupBy(people, p => p.dept);
// { eng: [{ name: 'Alice', ... }, { name: 'Carol', ... }], design: [{ name: 'Bob', ... }] }
// TypeScript knows: byDept['eng'] is Array<{ name: string; dept: string }> | undefined

// Promise.withResolvers — cleaner externalized promise pattern
function createDeferredTask<T>() {
  const { promise, resolve, reject } = Promise.withResolvers<T>();
  // No need for: let resolve!: (v: T) => void; let reject!: ...
  return { promise, resolve, reject };
}

const task = createDeferredTask<string>();
setTimeout(() => task.resolve('done'), 1000);
const result = await task.promise; // string
```

### `TypedArray` Generic Change (TypeScript 5.7 / 5.9 — Breaking)

TypeScript 5.7 began a multi-release transition making `TypedArray` types generic over their underlying buffer type. The full breaking change landed in TypeScript 5.9: `ArrayBuffer` is no longer a structural supertype of typed array types like `Uint8Array`.

```typescript
// ❌ Error in TypeScript 5.9+ (change started in 5.7)
function process(buf: ArrayBufferLike): void { /* ... */ }
const arr = new Uint8Array([1, 2, 3]);
process(arr);
// Error: Type 'Uint8Array<ArrayBuffer>' is not assignable to type 'ArrayBufferLike'

// ✅ Fix option 1: access the buffer property explicitly
process(arr.buffer);

// ✅ Fix option 2: accept Uint8Array directly in the function signature
function process(buf: Uint8Array<ArrayBuffer>): void { /* ... */ }
process(arr);  // OK

// ✅ Fix option 3: update @types/node — it ships corrected Buffer overloads
// npm update @types/node --save-dev
```

[community] **Pitfall:** The `TypedArray` generic change is the most common source of new errors when upgrading to TypeScript 5.7–5.9. Errors typically appear as `Type 'Buffer' is not assignable to type 'Uint8Array<ArrayBufferLike>'` in Node.js projects. The root cause is outdated `@types/node` — updating the package resolves most cases. For custom functions that accept `ArrayBufferLike`, prefer accepting the typed array directly (`Uint8Array`, `Int16Array`, etc.) rather than the abstract `ArrayBufferLike`.

---

## TypeScript 5.7 — Validated JSON Imports in `--module nodenext` and V8 Compile Caching

### Validated JSON Imports

Under `--module nodenext`, TypeScript 5.7 added strict validation of JSON imports. JSON imports now require the `with { type: "json" }` import attribute and only support default imports — named exports are not allowed.

```typescript
// ❌ Missing import attribute — required under --module nodenext in TypeScript 5.7+
import myConfig from "./myConfig.json";
// Error: Import of JSON files requires attribute with 'with { type: "json" }' in nodenext

// ❌ Named import — JSON modules only export a default
import { version } from "./package.json" with { type: "json" };
// Error: JSON modules only support a default export

// ✅ Correct: default import with type attribute
import pkg from "./package.json" with { type: "json" };
const version = pkg.version;  // string (TypeScript infers the JSON shape)

// ✅ Dynamic import with attribute
const config = await import("./config.json", { with: { type: "json" } });
const port = config.default.port;  // typed from the JSON file's structure
```

[community] **Pitfall:** Teams upgrading to `--module nodenext` with TypeScript 5.7 often hit these JSON import errors in scripts that load configuration files. The `assert {}` syntax was already deprecated; the 5.7 change also adds the named-export restriction. If you need multiple values from a JSON file, import the default and destructure: `const { host, port } = await import("./config.json", { with: { type: "json" } }).then(m => m.default)`.

### V8 Compile Caching (TypeScript 5.7 + Node.js 22)

TypeScript 5.7 leverages Node.js 22's `module.enableCompileCache()` API to cache V8-compiled bytecode for the TypeScript compiler itself. This produces approximately a **2.5× speedup** on cold `tsc` startup in environments that have previously run TypeScript once.

```bash
# First run: compiler is JIT-compiled and cache is saved
npx tsc --noEmit
# Subsequent runs: bytecode loaded from cache — ~2.5x faster startup
npx tsc --noEmit

# Cache location (Node.js 22 default):
# $XDG_CACHE_HOME/node/v8-compile-cache-<hash>/ (Linux/macOS)
# %LOCALAPPDATA%\node\v8-compile-cache-<hash>\ (Windows)
```

This is **transparent** — no configuration required. It activates automatically when TypeScript 5.7 is run on Node.js 22+. The benefit is most noticeable in watch-mode restarts, CI runs on warm machines, and repeated `tsc --noCheck` builds in development.

[community] **Pitfall:** V8 compile caching only applies when using the Node.js 22 runtime. Teams running TypeScript on Node.js 18 or 20 do not see this improvement. As an incentive to upgrade, V8 caching is a concrete performance argument for adopting Node.js 22 LTS in your build pipeline.

---

## TypeScript 5.6 — `--strictBuiltinIteratorReturn` and Arbitrary Module Identifiers

### `--strictBuiltinIteratorReturn`

TypeScript 5.6 added a new strict mode option `--strictBuiltinIteratorReturn` (also settable as `"strictBuiltinIteratorReturn": true` in tsconfig). When enabled, the `done` value type of built-in iterators changes from `any` to `undefined`, catching a class of bugs where iterator results were used without checking the `done` field.

```typescript
// Without --strictBuiltinIteratorReturn:
// BuiltinIteratorReturn = any — masks errors in iterator result handling

// With --strictBuiltinIteratorReturn:
// BuiltinIteratorReturn = undefined — forces correct done-check

function* uppercase(iter: Iterator<string, BuiltinIteratorReturn>): Generator<string> {
  while (true) {
    const { value, done } = iter.next();
    if (done) break;
    yield value.toUpperCase(); // ✅ TypeScript knows 'value' is string here (done is false)
  }
}

// Without the flag:
// BuiltinIteratorReturn = any → value.toUppercase() compiles even with a typo
// With the flag:
// BuiltinIteratorReturn = undefined → value is string only after done-check, catches typos
```

Add to tsconfig when using the iterator helper pattern from TypeScript 5.6:

```json
{
  "compilerOptions": {
    "lib": ["ES2025"],
    "strictBuiltinIteratorReturn": true
  }
}
```

[community] **Pitfall:** `--strictBuiltinIteratorReturn` is not part of the `strict` umbrella flag — it must be added explicitly. Teams enabling `strict: true` and assuming all strict sub-flags are covered will miss this. It is most valuable in codebases that use custom iterator pipelines or call `.next()` directly.

### Arbitrary Module Identifiers

TypeScript 5.6 supports non-identifier export and import names using string literals. This feature enables WebAssembly interoperability and import/export of identifiers that are not valid JavaScript identifier names (such as emoji, hyphenated names, or language keywords).

```typescript
// Export with a non-identifier name
export { banana as "🍌" };
export { handler as "content-type-handler" };

// Import the non-identifier name and bind to a valid JS identifier
import { "🍌" as banana } from "./emoji-exports.js";
import { "content-type-handler" as contentTypeHandler } from "./handlers.js";

// Use case: consuming WebAssembly modules with non-JS export names
import { "memory" as wasmMemory, "table" as wasmTable } from "./module.wasm";
```

**Testing relevance:** When writing integration tests for modules that export WebAssembly functions or bridge to non-JS runtimes, this feature allows direct import of the actual export names rather than requiring a JavaScript wrapper layer.

[community] **Pitfall:** Arbitrary module identifiers are a TypeScript type-system feature, but runtime support depends on the JavaScript engine and module system. Node.js ESM supports string-keyed exports in `.mjs` files, but CommonJS (`require()`) does not — attempting to `require()` a module with non-identifier exports will produce a runtime error. Always test both import and require paths when authoring modules with non-identifier exports.

---

## TypeScript 5.8 — Preserved Computed Property Names in Declaration Files

TypeScript 5.8 fixed a long-standing limitation where class properties with computed entity-name keys (bare variables or dotted names) caused compile errors under `--declaration` emit and were silently replaced by broad index signatures in the emitted `.d.ts`. TypeScript 5.8 now preserves the computed name directly.

```typescript
// Before TypeScript 5.8: ERROR under --declaration
export let propName = "theAnswer";

export class MyClass {
  [propName] = 42;
  // ❌ Error: A computed property name in a class property declaration must have
  //    a simple literal type or a 'unique symbol' type.
}

// TypeScript 5.7 workaround: broad index signature in .d.ts (information lost)
// declare class MyClass { [x: string]: number; }
```

```typescript
// TypeScript 5.8+: compiles and emits the computed name correctly in .d.ts
export let propName = "theAnswer";

export class MyClass {
  [propName] = 42;  // ✅ No error
}

// Emitted .d.ts (TypeScript 5.8+):
// export declare let propName: string;
// export declare class MyClass {
//   [propName]: number;  // ← preserved, not collapsed to an index signature
// }
```

**Important caveats:**
- The preserved declaration still behaves as an index signature at the type level — it does **not** create a statically-named property. Consumers see the same structural type as before.
- This feature is **not compatible with `--isolatedDeclarations`**: a computed entity-name property in a class requires cross-file inference (the value of `propName` at declaration-emit time), which `isolatedDeclarations` forbids. Under `isolatedDeclarations`, use `unique symbol` instead.
- Declaration files generated by TypeScript 5.8 with this pattern are **not backward-compatible** with TypeScript 5.7 and earlier — older compilers reject the preserved computed name syntax in `.d.ts` files.

```typescript
// isolatedDeclarations-compatible alternative: unique symbol
export const propName: unique symbol = Symbol("theAnswer");

export class MyClass {
  [propName] = 42;  // ✅ Works under isolatedDeclarations — unique symbol, not an entity-name
}
```

[community] **Pitfall:** Teams upgrading to TypeScript 5.8 may find that declaration files they generate are consumed by downstream packages still on TypeScript 5.7 or earlier. If your library's `.d.ts` files contain class properties with computed entity-name keys (the feature TypeScript 5.8 now supports), those `.d.ts` files are not parseable by older TypeScript versions. Pin your `--declaration` emit target to TypeScript 5.8+ if adopting this pattern in library code, or use `unique symbol` keys for maximum compatibility.

---

## TypeScript 5.6 — `--build` with Intermediate Errors

Before TypeScript 5.6, `--build` mode (`tsc --build`) stopped the entire build immediately when any upstream package in a project reference graph reported errors. Downstream packages that had no errors of their own could not build at all — even if the upstream error was in an unrelated module.

TypeScript 5.6 changed this behavior: `--build` now continues building downstream packages even when upstream packages have errors, reporting all errors at the end. This unblocks incremental upgrade workflows in monorepos.

```bash
# Before TypeScript 5.6: build stops at first error in any upstream package
# tsc --build packages/core packages/api packages/web
# → Error in packages/core — packages/api and packages/web never built

# TypeScript 5.6+: build continues through errors, reports all at once
# tsc --build packages/core packages/api packages/web
# → Error in packages/core, but packages/api and packages/web still build
# → All errors reported at the end

# Restore old fail-fast behavior with --stopOnBuildErrors
tsc --build --stopOnBuildErrors
```

**Practical benefit:** When upgrading a large codebase to a new TypeScript version, you can run `tsc --build` and see errors in all packages simultaneously — not just the first one. This makes it practical to create a single "upgrade to TS X.Y" PR that addresses all new errors across the monorepo at once.

**Additional `--build` change:** TypeScript 5.6 now always emits `.tsbuildinfo` files in `--build` mode, even for packages that don't have `"incremental": true` in their tsconfig. This is required for the new intermediate-error behavior (the build system needs per-package state to track which outputs are stale after upstream errors).

```json
// tsconfig.json — no change needed; .tsbuildinfo is now always emitted in --build mode
// But add .tsbuildinfo to .gitignore if not already there:
// *.tsbuildinfo
```

[community] **Pitfall:** Teams who relied on `tsc --build` failing fast as a "does upstream still compile?" CI gate now need `--stopOnBuildErrors` to restore that behavior. Without it, TypeScript 5.6's new default silently continues despite upstream errors, and the CI job reports "all errors" at the end rather than failing at the first bad package. Evaluate whether your CI workflow wants fail-fast or accumulate-all behavior, and be explicit.

---

## TypeScript 5.6 — Region-Prioritized Diagnostics and Auto-Import Exclusion

### Region-Prioritized Diagnostics

TypeScript 5.6 introduced region-prioritized diagnostics to dramatically improve editor responsiveness for large files. When the editor requests semantic diagnostics, TypeScript now checks the **visible region** first and returns those results immediately, then completes the full-file check in the background.

The performance impact is substantial on large files:

| Scenario | Time |
|---|---|
| TypeScript's own `checker.ts` — full semantic diagnostics | ~3,330 ms |
| TypeScript's own `checker.ts` — region diagnostics (visible viewport) | ~143 ms |

This feature is **automatic** in VS Code with TypeScript 5.6+. No configuration is required. The visible region is determined by the editor's viewport; TypeScript prioritizes type errors in the lines you can currently see, then expands to the full file asynchronously.

[community] **Pitfall:** Region-prioritized diagnostics means you may not see type errors in code below the fold immediately after opening a large file. Errors appear after the full-file check completes in the background. This is intentional — the interactive experience is faster — but it can be confusing if you scroll down expecting to see previously-known errors and they haven't rendered yet. Waiting 2–3 seconds (or scrolling to that region) will trigger the background check to complete.

### Auto-Import Exclusion Patterns

TypeScript 5.6 added a VS Code setting to filter auto-import suggestions using regular expressions. This is useful for excluding deep imports from libraries you only want to use through their top-level API, suppressing deprecated modules, or hiding platform-specific subpaths.

```json
// .vscode/settings.json — exclude auto-import suggestions by regex
{
  "typescript.preferences.autoImportSpecifierExcludeRegexes": [
    "^lodash/.*$",        // Exclude deep lodash imports (e.g., lodash/cloneDeep)
    "^node:",             // Exclude node: protocol imports if using browser target
    "^@internal/.*$"     // Exclude internal monorepo packages from auto-complete
  ]
}
```

For case-insensitive or unicode-aware patterns, wrap in slashes with flags:

```json
{
  "typescript.preferences.autoImportSpecifierExcludeRegexes": [
    "/^lodash/i"
  ]
}
```

Commit these settings to `.vscode/settings.json` (in source control) so the whole team shares the same exclusion list — especially valuable when migrating away from a deprecated library and you want to prevent accidental new imports from appearing in auto-complete suggestions.

[community] **Pitfall:** `autoImportSpecifierExcludeRegexes` only affects **auto-import suggestions** — it does not prevent manually typed imports, and it does not cause TypeScript to error on matching imports. If you need to actually enforce that a module cannot be imported, use an ESLint rule (`no-restricted-imports`) in addition to the exclusion pattern.

---

## Anti-Patterns Quick Reference (TS 5.6–5.7 Additions)

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| Missing `with { type: "json" }` on JSON imports in `nodenext` | TypeScript 5.7+ errors; Node.js 22 also requires it at runtime | Always use `import cfg from "./f.json" with { type: "json" }` |
| Named imports from JSON modules (`import { x } from "f.json"`) | JSON modules only support default exports — named imports error | Destructure from the default: `import cfg from "f.json" with { type: "json" }; const { x } = cfg` |
| `Uint8Array` passed as `ArrayBufferLike` (TS 5.7+) | Typed arrays are no longer structural subtypes of ArrayBufferLike — compile error after upgrading | Use `.buffer` property, update `@types/node`, or accept typed array directly |
| Skipping V8 compile cache by running TypeScript on Node 18/20 | Missing 2.5× startup speedup available on Node.js 22 + TypeScript 5.7 | Upgrade build pipeline to Node.js 22 LTS |
| `strict: true` without `strictBuiltinIteratorReturn` in iterator-heavy code | Built-in iterator return type remains `any`, masking done-check bugs | Add `"strictBuiltinIteratorReturn": true` explicitly; not included in `strict` umbrella |
| Non-identifier module exports consumed via `require()` | CommonJS cannot handle non-identifier export keys at runtime | Only use arbitrary module identifiers in ESM (`.mjs`) code paths; keep CJS exports JS-identifier-safe |
| Computed entity-name class property in library `.d.ts` targeting TS 5.7 consumers | TypeScript 5.8 preserves computed names in `.d.ts` but older compilers reject the syntax | Use `unique symbol` keys for maximum backward compatibility in library declaration files |
| `tsc --build` fail-fast behavior missing after TS 5.6 upgrade | TS 5.6 changed default to continue-on-error; previously stopped at first upstream error | Add `--stopOnBuildErrors` to restore old behavior; omit it in upgrade-mode CI to see all errors simultaneously |
| `autoImportSpecifierExcludeRegexes` as an import enforcement mechanism | The setting only hides suggestions — manually typed imports still work and pass type-checking | Use ESLint `no-restricted-imports` rule alongside the VS Code setting to actually block imports |
