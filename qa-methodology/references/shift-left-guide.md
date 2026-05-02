# Shift-Left — QA Methodology Guide
<!-- lang: TypeScript | topic: shift-left | iteration: 10 | score: 100/100 | date: 2026-05-02 -->

## Core Principles

Shift-left testing is the practice of moving quality and security validation activities earlier (further "left") in the Software Development Life Cycle (SDLC). Rather than treating testing as a phase that follows development, shift-left embeds testing at every stage from requirements through design and code.

> **Terminology note (ISTQB CTFL 4.0):** This guide uses standardized terminology: "defect" (not "bug" or "error"), "test case" (not "test"), "test level" (not "test layer"), "test basis" (not "test source"), and "test object" (not "thing under test"). Tool names (e.g., ZAP, ESLint) use their documented terminology regardless of this convention.
>
> **ISTQB CTFL 4.0 on shift-left:** The ISTQB Foundation Level 4.0 syllabus (2023) defines shift-left as a practice that includes: static testing (reviews and static analysis), component testing in isolation, and continuous integration of testing activities earlier in the development lifecycle. The term encompasses both the practice of writing tests before code (TDD) and integrating quality gates into the developer workflow.

### 1. Definition and Origin
The term was coined by Larry Smith in 2001, published in his column *"Shift Left Testing"* in STQE Magazine. The "left" metaphor references a traditional waterfall SDLC timeline drawn left-to-right: requirements → design → development → testing → deployment. "Shifting left" means moving testing activities toward the requirements and design phases, rather than reserving them for after code is written.

In agile and CI/CD contexts, shift-left is operationalized as automated quality gates that execute on every code change: pre-commit hooks fire before a commit lands, PR checks fire before a branch merges, and pipeline gates fire before an artifact is promoted. The developer gets feedback in the same context they wrote the code — while the mental model is fresh and the change is small.

### 2. The Cost-of-Defects Curve
IBM's Systems Sciences Institute established a widely cited data point: a defect found in production costs **10–100× more** to fix than one found during development. The multipliers by phase:

| Discovery Phase        | Relative Cost | Typical Actions Required |
|------------------------|---------------|--------------------------|
| Requirements / Design  | 1×            | Update spec, re-review   |
| Coding                 | 5×            | Fix code, re-run tests   |
| Integration Testing    | 10×           | Debug, fix, reintegrate  |
| System / UAT           | 25×           | Hotfix branch, regression pass |
| Production             | 100×          | Incident, rollback, postmortem, CVE disclosure |

**WHY it matters**: Every hour of automated test setup in the pre-commit or PR stage eliminates downstream investigation, hotfix branching, regression retesting, and potential incident response.

### 3. Developer Ownership
Shift-left requires developers — not a separate QA team — to write, own, and maintain tests. QA engineers shift from executing manual test passes to building tooling, test frameworks, coverage dashboards, and reviewing test quality.

**WHY it matters**: When testing is a handoff to another team, developers write code that is not designed for testability — deep coupling, hidden side effects, opaque dependencies. When developers own tests, they build tighter feedback loops and naturally design for dependency injection, pure functions, and observable state. Testable architecture is better architecture. TypeScript amplifies this: the type system itself is a form of executable specification that developers maintain alongside their code — the compiler is a shift-left tool that runs on every save.

### The Test Pyramid for Shift-Left

Shift-left maps directly onto the test pyramid. Higher-left tests are cheaper and faster — they should form the base.

```
           /\
          /  \  E2E / DAST (shift-right, slow, expensive)
         /    \
        /------\ Integration / Contract Tests (PR-level CI)
       /        \
      /----------\ Unit Tests + TypeScript type checks (pre-commit + CI, fast)
     /            \
    /--------------\ Static Analysis (SAST, ESLint, tsc --noEmit — instantaneous)
```

- **Static analysis** (`tsc --noEmit`, `@typescript-eslint`): runs in seconds, no infrastructure, catches whole categories of defects including type errors, unused code, and null dereferences
- **Unit tests**: run in seconds, no external dependencies, verify logic in isolation
- **Integration / contract tests**: run in minutes, require services, verify interactions
- **E2E / DAST**: run in tens of minutes, require full deployment, verify end-to-end user flows and runtime security

Shift-left is the practice of **investing heavily in the bottom layers** — not eliminating the top layers.

### 4. SAST (Static Application Security Testing) — TypeScript
SAST tools analyze source code without running it. For TypeScript stacks:
- **`@typescript-eslint`** — The TypeScript-aware ESLint parser and rule set. Catches type-unsafe patterns (unsafe any, unhandled promise rejections, missing type guards) that plain ESLint cannot see
- **`eslint-plugin-security`** — Common Node.js security vulnerability rules (object injection, non-literal regex, etc.)
- **Semgrep** with `p/typescript`, `p/nodejs`, `p/owasp-top-ten` rulesets for pattern-based code scanning
- **CodeQL** via GitHub Actions — deep data-flow and taint analysis for TypeScript/JavaScript
- **AI-assisted SAST** (GitHub Copilot Autofix, Semgrep Assistant) — AI models propose TypeScript-aware remediation inline with each finding

**TypeScript SAST tool comparison:**

| Tool | TypeScript-Aware? | Speed | Key Catches | When to Use |
|---|---|---|---|---|
| `tsc --noEmit` | Native | 2–30s | Null dereferences, type mismatches, unreachable code | Always; the foundational TypeScript gate |
| `@typescript-eslint` (type-checked) | Full type info | 5–60s | Unsafe any, floating promises, unbound methods, type narrowing | Default for all TS projects |
| Semgrep (`p/typescript`) | Partial (pattern-based) | < 2min | SQL injection patterns, hardcoded secrets, XSS sinks | Fast SAST; run on every PR |
| CodeQL (`javascript-typescript`) | Full AST + taint | 5–20min | Data-flow taint, injection chains, prototype pollution | Security-sensitive code; weekly or PR |
| Snyk Code | Deep TypeScript | 1–3min | OWASP Top 10, TypeScript-specific sinks | Add when CodeQL is too slow |

**WHY it matters**: TypeScript's type system eliminates entire vulnerability classes (null dereferences, wrong-type API calls) at compile time. Adding `@typescript-eslint` to your existing ESLint setup further catches unsafe any usage, unbound methods, and floating promises — patterns that produce runtime errors in JavaScript that TypeScript would normally prevent if strict mode is fully used.

### 5. TypeScript Strict Mode as Shift-Left
Enabling `"strict": true` in `tsconfig.json` activates a battery of compile-time checks that collectively eliminate large categories of runtime defects:

| Compiler Flag | Defect Class Eliminated |
|---|---|
| `strictNullChecks` | Null/undefined dereferences (the "billion dollar mistake") |
| `strictFunctionTypes` | Function parameter type variance errors |
| `strictPropertyInitialization` | Uninitialized class properties accessed at runtime |
| `noImplicitAny` | Silent any coercions that hide type mismatches |
| `noImplicitReturns` | Functions that sometimes forget to return a value |
| `noFallthroughCasesInSwitch` | Missing `break` in switch statements |
| `exactOptionalPropertyTypes` | Optional property assignments that include `undefined` explicitly |

**WHY it matters**: Every flag above is a category of runtime defect that TypeScript prevents before the code ever runs. This is the most literal implementation of shift-left: the compiler, not a test runner, catches the defect at authoring time.

### 6. DAST (Dynamic Application Security Testing)
DAST runs against a live or containerized application instance:
- **OWASP ZAP** — open-source, scriptable, integrable with CI via `zaproxy/action-full-scan` or `zaproxy/action-baseline-scan`
- **Nuclei** — fast, template-based vulnerability scanner for common CVEs and misconfigurations
- Targets: XSS, CSRF, open redirects, broken auth headers, missing security headers (CSP, HSTS, X-Frame-Options)

**WHY it matters**: DAST validates runtime behavior that static analysis cannot see. A TypeScript application can pass every SAST check and strict type check and still ship with: an insecure CORS wildcard, missing `HttpOnly` cookie flags, no Content Security Policy, or an outdated TLS cipher suite. DAST is the only automated mechanism that catches configuration-level vulnerabilities that live outside the codebase entirely.

### 7. Pre-Commit Hooks
Husky + lint-staged intercept Git commits to run fast, file-scoped checks:
- `@typescript-eslint` (with security plugins)
- Prettier formatting
- `tsc --noEmit` for type checking (staged or incremental)
- Focused unit tests for changed files via Vitest `--related`

**WHY it matters**: Developers get sub-30-second feedback on the exact files they changed, before code even leaves their machine. The feedback loop shrinks from "wait for CI" (minutes) to "before you commit" (seconds).

### 8. PR-Level Required Status Checks
GitHub / GitLab branch protection rules that must pass before merge:
- All unit tests with coverage threshold enforcement
- `tsc --noEmit` (full type check, not just staged files)
- SAST scan (`@typescript-eslint` security, CodeQL or Semgrep)
- `npm audit --audit-level=high --omit=dev` and/or Snyk scan
- Consumer-driven contract tests (Pact) for service API changes

**WHY it matters**: PR checks create a hard gate that prevents broken or insecure code from entering the main branch, independent of developer discipline or reviewer oversight. They are not bypassable without admin intervention (which creates an audit trail). Unlike pre-commit hooks (which developers can skip with `--no-verify`), PR status checks are enforced by the platform.

### 9. Shift-Right Counterpart
Shift-right testing validates quality in or near production:
- **Feature flags** (LaunchDarkly, Unleash, Flagsmith) for gradual user-segment rollout
- **Canary deployments** (Argo Rollouts, Flagger, Spinnaker) with automated error-rate rollback
- **Synthetic monitoring** (Datadog Synthetics, Checkly, Pingdom) — automated browser flows against production
- **Real-user monitoring** (RUM via Datadog, New Relic, Sentry) — captures real performance and JS/TS runtime errors

Shift-left and shift-right are **complementary**, not competing strategies.

### 10. Runtime Validation as Shift-Left
TypeScript types are erased at runtime. Runtime schema validation at API boundaries catches malformed external data before it propagates into business logic:
- **Zod** — TypeScript-first schema validation with `z.infer<typeof schema>` type derivation; schemas double as both runtime validators and TypeScript types
- **TypeBox** — JSON Schema-compatible with TypeScript types; highest throughput for JSON APIs
- **io-ts** — Functional runtime type codec library with decode/encode symmetry

**WHY it matters**: TypeScript's type system only protects code you control. The moment data arrives from an API endpoint, a database query, or `process.env`, it is `unknown` at runtime regardless of what TypeScript assumes. Zod validates external data and **derives the TypeScript type from the schema**, ensuring runtime validation and compile-time types stay in sync by construction.

---

## When to Use

Shift-left is most valuable when:
- The codebase is under active development with frequent merges (daily or more)
- TypeScript strict mode is not yet enabled — enabling it is a high-leverage shift-left first step
- Security requirements exist (PCI-DSS, SOC 2 Type II, HIPAA, GDPR) or you are working toward compliance certification
- The team is small and lacks a dedicated QA team — shift-left is how small teams maintain quality without a QA headcount
- Time-to-production speed is a critical business priority and you cannot afford long manual QA cycles
- You are onboarding new developers who need guardrails that catch mistakes early
- The product has a public API or processes sensitive user data

Shift-left is **less appropriate** (or should be scoped carefully) when:
- The project is a short-lived prototype (< 4 weeks, no production users, no sensitive data): focus on delivering and add shift-left when it graduates to a real product
- TypeScript strict mode migration is in progress: enable incrementally using `// @ts-nocheck` or per-file overrides rather than blocking CI on 200+ pre-existing type errors
- Tests require complex infrastructure spin-up that slows the commit loop beyond 5 minutes — isolate infrastructure tests to the CI layer only
- The team is in an emergency release crunch: defer tooling setup, but schedule it for the sprint immediately following
- The codebase is read-only legacy with no active development: maintain existing tests but do not invest in new shift-left tooling

---

## Patterns

### Pre-Commit Hooks (Husky + lint-staged) — TypeScript

```json
// package.json — complete configuration for TypeScript project with Husky v9 + lint-staged v15
{
  "scripts": {
    "prepare": "husky",
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "test:related": "vitest run --related"
  },
  "lint-staged": {
    "*.{ts,tsx,mts,cts}": [
      "eslint --fix --max-warnings=0",
      "prettier --write"
    ],
    "*.{spec.ts,test.ts}": [
      "vitest run --related --reporter=verbose"
    ]
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "husky": "^9.1.0",
    "lint-staged": "^15.2.0",
    "eslint": "^9.0.0",
    "@eslint/js": "^9.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint-plugin-security": "^3.0.1",
    "eslint-plugin-no-secrets": "^1.0.2",
    "globals": "^15.0.0",
    "vitest": "^2.0.0",
    "prettier": "^3.3.0"
  }
}
```

```sh
#!/bin/sh
# .husky/pre-commit — installed automatically by `npm run prepare`
# Runs lint-staged on staged files + incremental type check
npx lint-staged
# Run tsc on changed TS files only (incremental, uses tsconfig build cache)
# NOTE: tsc --noEmit --incremental is fast on unchanged files (~0.5s)
npx tsc --noEmit --incremental
```

```sh
#!/bin/sh
# .husky/commit-msg — validates conventional commits format
# Enforces: feat:, fix:, chore:, docs:, test:, refactor:, perf:, ci:
npx --no -- commitlint --edit "$1"
```

> **Gotcha**: Running `tsc --noEmit` in pre-commit on a large TypeScript project can take 10–30 seconds. Use `--incremental` to leverage the build cache, and consider only running the full type check in CI (PR gate), not pre-commit.

### TypeScript tsconfig.json — Strict Shift-Left Configuration

```json
// tsconfig.json — strict TypeScript config for maximum shift-left benefit
{
  "compilerOptions": {
    // Core strict checks — eliminate entire runtime defect classes at compile time
    "strict": true,                          // Enables all strict mode flags below
    "noImplicitAny": true,                   // No silent any coercions
    "strictNullChecks": true,                // Eliminates null/undefined dereferences
    "strictFunctionTypes": true,             // Catches function type variance errors
    "strictPropertyInitialization": true,    // Catches uninitialized class properties
    "noImplicitReturns": true,               // Functions must always return a value
    "noFallthroughCasesInSwitch": true,      // switch case fallthrough = error
    "exactOptionalPropertyTypes": true,      // `{a?: string}` cannot be set to undefined
    "noUncheckedIndexedAccess": true,        // array[n] returns T | undefined, not T
    "noPropertyAccessFromIndexSignature": true, // Must use bracket notation for index types

    // Additional safety
    "noUnusedLocals": true,                  // Unused variables = compile error
    "noUnusedParameters": true,              // Unused function params = compile error
    "useUnknownInCatchVariables": true,      // catch (e) types e as unknown, not any

    // Module / target
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts", "**/*.test.ts", "vitest.config.ts"]
}
```

```json
// tsconfig.test.json — separate config for test files (allows test-specific relaxations)
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noUnusedLocals": false,               // Test helpers may declare unused vars
    "noUnusedParameters": false,
    "outDir": "dist-test"
  },
  "include": ["src/**/*", "tests/**/*", "**/*.spec.ts", "**/*.test.ts", "vitest.config.ts"]
}
```

**WHY it matters**: `"noUncheckedIndexedAccess": true` is not part of `"strict": true` — it must be enabled explicitly. Without it, `const first = myArray[0]` has type `string` even if the array is empty, leading to a runtime crash. With it, `first` has type `string | undefined`, forcing the developer to handle the empty-array case. This single flag catches a large class of "cannot read property of undefined" production errors at compile time.

### SAST in CI — TypeScript ESLint Security Config

```typescript
// eslint.config.ts — security-focused ESLint flat config for TypeScript (ESLint v9+)
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import security from 'eslint-plugin-security';
import noSecrets from 'eslint-plugin-no-secrets';
import globals from 'globals';

export default tseslint.config(
  // Base JS recommended
  js.configs.recommended,

  // TypeScript recommended with type-checking (requires parserOptions.project)
  ...tseslint.configs.recommendedTypeChecked,

  // Security plugin
  security.configs['recommended-legacy'],

  {
    files: ['src/**/*.ts', 'src/**/*.tsx'],

    plugins: {
      security,
      'no-secrets': noSecrets,
    },

    languageOptions: {
      globals: { ...globals.node, ...globals.es2022 },
      parserOptions: {
        project: './tsconfig.json',          // Required for type-aware rules
        tsconfigRootDir: import.meta.dirname,
      },
    },

    rules: {
      // TypeScript-aware security rules (require type information)
      '@typescript-eslint/no-unsafe-assignment': 'error',   // No `any` spreading
      '@typescript-eslint/no-unsafe-member-access': 'error', // No any.property access
      '@typescript-eslint/no-unsafe-call': 'error',          // No calling any()
      '@typescript-eslint/no-unsafe-return': 'error',        // No returning any
      '@typescript-eslint/no-explicit-any': 'warn',          // Prefer unknown over any
      '@typescript-eslint/no-floating-promises': 'error',    // Unhandled promises = error
      '@typescript-eslint/no-misused-promises': 'error',     // Promise in boolean context
      '@typescript-eslint/await-thenable': 'error',          // Await non-promise = error
      '@typescript-eslint/no-non-null-assertion': 'warn',    // Discourage ! operator

      // Security rules
      'security/detect-object-injection': 'warn',
      'security/detect-non-literal-regexp': 'error',
      'security/detect-non-literal-require': 'error',
      'security/detect-possible-timing-attacks': 'error',
      'security/detect-unsafe-regex': 'error',
      'security/detect-buffer-noassert': 'error',

      // Secret detection
      'no-secrets/no-secrets': ['error', { tolerance: 4.2 }],

      // Dangerous built-ins
      'no-eval': 'error',
      'no-implied-eval': 'error',
    },
  },

  {
    // Test files: relax some rules
    files: ['**/*.spec.ts', '**/*.test.ts', 'tests/**/*.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',           // Test helpers may use any
      '@typescript-eslint/no-unsafe-assignment': 'off',
      'security/detect-non-literal-regexp': 'warn',
    },
  },
);
```

```yaml
# .github/workflows/sast.yml — runs on every PR against main or develop
name: SAST Security Scan
on:
  pull_request:
    branches: [main, develop, 'release/**']

permissions:
  security-events: write
  actions: read
  contents: read

jobs:
  typecheck:
    name: TypeScript Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # Full type check — not incremental in CI (no cache between runs)
      - run: npx tsc --noEmit
        # Fails on any type error: catches null dereferences, wrong arg types,
        # unhandled promise shapes, missing exhaustive checks, etc.

  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript   # Covers both JS and TS in same scan
          queries: security-and-quality
      - run: npm ci && npm run build
      - uses: github/codeql-action/analyze@v3
        with:
          category: '/language:javascript-typescript'

  semgrep:
    name: Semgrep OWASP Scan
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep
    steps:
      - uses: actions/checkout@v4
      - run: semgrep scan --config=p/typescript --config=p/nodejs --config=p/owasp-top-ten --sarif --output=semgrep.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: semgrep.sarif
```

### Zod Runtime Validation — TypeScript-First Schema Validation

```typescript
// src/api/validators/user.validator.ts — Zod schemas derive TypeScript types by construction
import { z } from 'zod';
import type { Request, Response, NextFunction } from 'express';

// Schema definition — the single source of truth for BOTH runtime validation AND TypeScript type
export const CreateUserSchema = z.object({
  email: z
    .string()
    .email({ message: 'Must be a valid email address' })
    .max(254, { message: 'Email too long (RFC 5321 limit)' }),
  name: z
    .string()
    .min(1)
    .max(100)
    .regex(/^[a-zA-Z\s'-]+$/, { message: 'Name contains invalid characters' }),
  role: z.enum(['admin', 'viewer', 'editor'], {
    errorMap: () => ({ message: 'Role must be admin, viewer, or editor' }),
  }),
  age: z.number().int().min(13).max(150).optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
});

// Derive the TypeScript type from the schema — no duplication, always in sync
export type CreateUserInput = z.infer<typeof CreateUserSchema>;
// Equivalent to: { email: string; name: string; role: 'admin'|'viewer'|'editor'; age?: number; metadata?: Record<string,unknown> }

// Reusable Express middleware factory — type-safe validated body
export function validateBody<T>(schema: z.ZodType<T>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({
        error: 'Validation failed',
        issues: result.error.issues.map(issue => ({
          field: issue.path.join('.'),
          message: issue.message,
        })),
      });
      return;
    }
    // req.body is now typed as T — TypeScript knows the shape
    (req as Request & { validatedBody: T }).validatedBody = result.data;
    next();
  };
}

// Environment variable validation — catches misconfiguration at startup
export const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32, { message: 'JWT_SECRET must be at least 32 characters' }),
  PORT: z.coerce.number().int().min(1024).max(65535).default(3000),
});

// Fail-fast: validate env at startup, not when first used
export const env = EnvSchema.parse(process.env);
// If any env var is missing or invalid, process exits with a descriptive error
// e.g.: "ZodError: [{ path: ['JWT_SECRET'], message: 'JWT_SECRET must be at least 32 characters' }]"
```

```typescript
// src/api/validators/user.validator.spec.ts — test the Zod schema directly (shift-left)
import { describe, it, expect } from 'vitest';
import { CreateUserSchema } from './user.validator.js';

describe('CreateUserSchema', () => {
  it('accepts a valid user payload', () => {
    const result = CreateUserSchema.safeParse({
      email: 'alice@example.com',
      name: 'Alice',
      role: 'viewer',
      age: 25,
    });
    expect(result.success).toBe(true);
    if (result.success) {
      // TypeScript knows result.data.role is 'admin' | 'viewer' | 'editor'
      expect(result.data.email).toBe('alice@example.com');
    }
  });

  it('rejects an invalid email', () => {
    const result = CreateUserSchema.safeParse({ email: 'not-an-email', name: 'Bob', role: 'viewer' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toMatch(/valid email/i);
    }
  });

  it('rejects unknown roles', () => {
    const result = CreateUserSchema.safeParse({ email: 'a@b.com', name: 'Bob', role: 'superuser' });
    expect(result.success).toBe(false);
  });

  it('strips no fields — use z.strip() for that behavior', () => {
    // Zod default behavior: extra fields are stripped in .parse() / .safeParse()
    const result = CreateUserSchema.safeParse({
      email: 'a@b.com', name: 'Bob', role: 'viewer', extraField: 'ignored',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).not.toHaveProperty('extraField');
    }
  });
});
```

**WHY Zod over Joi for TypeScript**: Joi requires separate TypeScript type declarations alongside schemas — they can drift. Zod derives the TypeScript type from the schema (`z.infer<typeof schema>`), so the runtime validation and compile-time types are always synchronized. This is the TypeScript-idiomatic approach and the de facto standard for new TypeScript projects as of 2025.

### PR-Level Required Status Checks — TypeScript

```yaml
# .github/workflows/pr-quality-gate.yml — comprehensive PR gate for TypeScript projects
name: PR Quality Gate
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  typecheck:
    name: TypeScript Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # tsc --noEmit: compile-check without emitting files.
      # Catches: null dereferences, wrong argument types, missing exhaustive type guards,
      # unhandled promise shapes, incorrect enum usage — none of which ESLint catches.
      - run: npx tsc --noEmit
      # Also check test files separately (tsconfig.test.json relaxes some rules)
      - run: npx tsc --project tsconfig.test.json --noEmit

  unit-tests:
    name: Unit Tests + Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx vitest run --coverage --reporter=junit --outputFile=test-results.xml
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results.xml

  lint-security:
    name: ESLint + TypeScript-Aware Security Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # ESLint with @typescript-eslint type-checking rules requires tsc to run first
      # (parserOptions.project triggers full type resolution)
      - run: npx eslint . --max-warnings=0 --format=sarif --output-file=eslint.sarif || true
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: eslint.sarif

  dependency-audit:
    name: Dependency Vulnerability Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm audit --audit-level=high --omit=dev
```

### Vitest Configuration — TypeScript

```typescript
// vitest.config.ts — configured for TypeScript pre-commit and CI
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,

    // Coverage — thresholds enforced in CI (not pre-commit)
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.spec.ts', 'src/**/*.test.ts', 'src/index.ts'],
      thresholds: {
        lines: 80,
        functions: 75,
        branches: 70,
        statements: 80,
      },
    },

    reporters: process.env.CI ? ['junit', 'verbose'] : ['verbose'],
    outputFile: process.env.CI ? 'test-results.xml' : undefined,

    // Isolation: forks mode is slower than threads but prevents shared state bugs
    // For pure TypeScript unit tests with no shared globals, threads is fine
    isolate: true,
    pool: 'forks',
  },
});
```

> **Gotcha**: `vitest run --related` requires test files to follow naming conventions (`user.spec.ts` next to `user.ts`) for the related-file heuristic to work. Without this convention, vitest cannot infer which tests to run and falls back to running all tests.

### Secret Scanning (Gitleaks / GitHub Secret Scanning)

```yaml
# .github/workflows/secret-scan.yml — runs on every push and PR
name: Secret Scan
on:
  push:
    branches: ['**']
  pull_request:

jobs:
  gitleaks:
    name: Gitleaks Secret Detection
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # Full history: scan all commits in the push, not just HEAD

      - name: Gitleaks scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}
```

```typescript
// scripts/check-no-env-files.ts — run as a pre-commit check via lint-staged
import { execSync } from 'node:child_process';

const stagedFiles: string[] = execSync('git diff --cached --name-only', { encoding: 'utf8' })
  .trim()
  .split('\n')
  .filter(Boolean);

const envFiles = stagedFiles.filter((f: string) => {
  const basename = f.split('/').pop() ?? '';
  return /^\.env(\.|$)/.test(basename);
});

if (envFiles.length > 0) {
  console.error(`ERROR: Attempting to commit .env file(s):\n  ${envFiles.join('\n  ')}`);
  console.error('Remove from staging: git reset HEAD <file>');
  process.exit(1);
}
```

> [community] **Gotcha (GitGuardian State of Secrets Sprawl 2024)**: 12.8 million secrets were detected in public GitHub commits in 2023. The most commonly leaked secrets in TypeScript/Node.js projects are: Google API keys (committed via `.env` or hardcoded in tests), AWS credentials, and JWT secrets (hardcoded in `config.ts` for "convenience"). **Pre-commit secret scanning and GitHub push protection together stop > 90% of accidental commits before they reach remote**.

### TypeScript Service with Shift-Left Ownership Pattern

This example shows a complete TypeScript service following shift-left principles: strict types enforce correctness at compile time, Zod validates external input at runtime, and the service is designed for testability (pure functions, injected dependencies, no hidden global state).

```typescript
// src/services/payment.service.ts — shift-left architecture: typed, validated, testable
import { z } from 'zod';
import type { Logger } from 'pino';

// Public types — single source of truth derived from runtime schema
export const PaymentIntentSchema = z.object({
  amountCents: z.number().int().positive({ message: 'Amount must be a positive integer (cents)' }),
  currency: z.enum(['usd', 'eur', 'gbp']),
  customerId: z.string().min(1),
  idempotencyKey: z.string().uuid().optional(),
});

export type PaymentIntentRequest = z.infer<typeof PaymentIntentSchema>;

export interface PaymentIntent {
  readonly id: string;
  readonly amountCents: number;
  readonly currency: 'usd' | 'eur' | 'gbp';
  readonly status: 'pending' | 'succeeded' | 'failed';
  readonly createdAt: Date;
}

// Dependency-injected interface — enables unit testing without real Stripe calls
export interface PaymentGateway {
  createIntent(request: PaymentIntentRequest): Promise<PaymentIntent>;
}

// Pure business logic — takes validated input, returns typed output
export class PaymentService {
  constructor(
    private readonly gateway: PaymentGateway,
    private readonly logger: Logger,
  ) {}

  // TypeScript: return type is explicit — callers know exactly what to expect
  async createPaymentIntent(rawInput: unknown): Promise<PaymentIntent> {
    // Zod validates at runtime — rawInput is unknown until validated
    const request = PaymentIntentSchema.parse(rawInput);
    // After .parse(), request is fully typed as PaymentIntentRequest

    this.logger.info({ amountCents: request.amountCents, currency: request.currency }, 'Creating payment intent');

    const intent = await this.gateway.createIntent(request);

    // TypeScript exhaustive check — if PaymentIntent.status gains a new value,
    // this will error at compile time, not silently fail at runtime
    if (intent.status !== 'pending' && intent.status !== 'succeeded' && intent.status !== 'failed') {
      const _exhaustive: never = intent.status;
      throw new Error(`Unhandled payment status: ${_exhaustive}`);
    }

    return intent;
  }
}
```

```typescript
// src/services/payment.service.spec.ts — unit test: no real network, fully typed mocks
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PaymentService, type PaymentGateway, type PaymentIntent } from './payment.service.js';
import pino from 'pino';

const mockGateway: PaymentGateway = { createIntent: vi.fn() };
const logger = pino({ level: 'silent' }); // Suppress logs in test output
const service = new PaymentService(mockGateway, logger);

describe('PaymentService.createPaymentIntent', () => {
  beforeEach(() => vi.clearAllMocks());

  it('creates a payment intent from valid input', async () => {
    const mockIntent: PaymentIntent = {
      id: 'pi_123', amountCents: 1000, currency: 'usd', status: 'pending', createdAt: new Date(),
    };
    vi.mocked(mockGateway.createIntent).mockResolvedValue(mockIntent);

    const result = await service.createPaymentIntent({ amountCents: 1000, currency: 'usd', customerId: 'cust_1' });

    expect(result.id).toBe('pi_123');
    expect(mockGateway.createIntent).toHaveBeenCalledOnce();
  });

  it('throws ZodError on invalid input — amount is string not number', async () => {
    await expect(
      service.createPaymentIntent({ amountCents: '100', currency: 'usd', customerId: 'cust_1' }),
    ).rejects.toThrow(/Expected number/);
    expect(mockGateway.createIntent).not.toHaveBeenCalled();
  });

  it('throws ZodError on non-positive amount', async () => {
    await expect(
      service.createPaymentIntent({ amountCents: -50, currency: 'usd', customerId: 'cust_1' }),
    ).rejects.toThrow(/positive/);
  });
});
```

**WHY this demonstrates developer ownership**: The developer who writes `PaymentService` also writes `payment.service.spec.ts` at the same time. The TypeScript interface `PaymentGateway` makes the service testable by construction — no "I can't unit test this because it calls Stripe directly." The type system and test runner are both shift-left tools the developer uses, not separate QA gatekeepers.

### Branch Protection Configuration (GitHub CLI)

```bash
# Configure branch protection for main via GitHub CLI (gh)
OWNER="your-org"
REPO="your-repo"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${OWNER}/${REPO}/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "TypeScript Type Check" },
      { "context": "Unit Tests + Coverage" },
      { "context": "ESLint + TypeScript-Aware Security Lint" },
      { "context": "Dependency Vulnerability Audit" },
      { "context": "CodeQL Analysis" },
      { "context": "Gitleaks Secret Detection" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
```

> [community] **Lesson (GitHub engineering, 2024)**: The single most common reason shift-left tooling fails in practice is not that the tools are broken — it is that branch protection was never configured, or was configured without `enforce_admins: true`. Admin users bypass all protection rules by default. A 5-minute CLI setup prevents years of accidental bypasses by well-meaning senior engineers who "just need to merge this one thing quickly."

### OpenSSF Scorecard — Supply Chain Shift-Left

```yaml
# .github/workflows/scorecard.yml — automated supply chain security scoring
name: OpenSSF Scorecard
on:
  push:
    branches: [main]
  schedule:
    - cron: '30 1 * * 6'   # Weekly on Saturday at 01:30 UTC

permissions: read-all

jobs:
  analysis:
    name: Scorecard analysis
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      id-token: write
      contents: read
      actions: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          persist-credentials: false

      - name: Run Scorecard analysis
        uses: ossf/scorecard-action@v2.4.0
        with:
          results_file: scorecard.sarif
          results_format: sarif
          publish_results: true

      - name: Upload SARIF results to code-scanning
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: scorecard.sarif
          category: ossf-scorecard
```

> [community] **Lesson (OSSF research, 2024)**: Projects that integrate Scorecard into their CI pipeline and publish scores publicly show a measurable improvement in security posture over 12 months. The public score acts as a lightweight SLA — teams respond to score drops the same way they respond to test failures.

### AI-Assisted SAST Remediation

```yaml
# .github/workflows/codeql-autofix.yml — CodeQL + Copilot Autofix (GHAS)
name: CodeQL with Autofix
on:
  pull_request:
    branches: [main, develop]

permissions:
  security-events: write
  pull-requests: write
  contents: read
  actions: read

jobs:
  codeql-with-autofix:
    name: CodeQL Analysis + Autofix
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
          queries: security-and-quality
      - run: npm ci && npm run build
      - uses: github/codeql-action/analyze@v3
        with:
          category: '/language:javascript-typescript'
```

> [community] **Lesson (GitHub security research, 2024)**: Teams using Copilot Autofix resolved SAST findings in an average of 1.7 days vs 9.3 days for teams using traditional SAST — a 5× faster remediation cycle. The primary driver was that developers accepted the suggested fix without needing to research the vulnerability independently.

---

## Anti-Patterns

1. **Gate everything on every commit**: Running the full test suite + SAST + type check on pre-commit destroys developer velocity. Reserve `tsc --noEmit` (full) and SAST for CI/PR gates; keep pre-commit under 15 seconds. Use `--incremental` for pre-commit type checks.

2. **Suppressing `@typescript-eslint` warnings instead of fixing them**: Teams add `// eslint-disable` and `// @ts-ignore` as a default response to type errors, defeating the purpose of strict mode. Each suppression should require a code review comment explaining WHY it is safe.

3. **Using `any` as the "I'll fix it later" type**: `any` propagates silently through the type system — `const x: any = untrustedInput; doSomething(x.user.id)` silences TypeScript warnings while deferring null-reference defects to runtime. Prefer `unknown` with an explicit type guard.

4. **100% line coverage as the goal**: High coverage of trivial getters and constructors gives false confidence. Focus on critical paths, error boundaries, and authorization logic.

5. **Not tuning SAST false positives**: Untuned SAST produces noisy alerts that teams learn to ignore — recreating the exact alert-fatigue problem it was meant to solve. TypeScript-aware rules (`@typescript-eslint/no-unsafe-*`) often have lower false-positive rates than generic SAST rules because they use type information. Spend one sprint tuning before enforcing as hard gates.

6. **Running DAST on every PR**: OWASP ZAP full-scan takes 15–45 minutes. Run it on schedule (nightly) or on merges to main, not every PR.

7. **Trusting TypeScript types at runtime API boundaries**: TypeScript types are erased at runtime. An API that receives `body: CreateUserInput` does NOT actually receive a validated `CreateUserInput` unless Zod (or equivalent) validates it first. The TypeScript type on `req.body` is `any` in Express — no runtime safety exists without an explicit validation step.

8. **Security theater via checkbox compliance**: Installing SAST, secret scanning, and type checking but routing their findings to a separate "security backlog" that no one triages is not shift-left — it is shift-later with extra steps. Shift-left only works when findings block the pipeline AND developers act on them within the same sprint they are raised.

### SAST Tuning Workflow

Before making a SAST rule a hard gate (CI failure), follow this process to avoid alert fatigue:

1. **Audit mode first**: Run in warn-only mode for 2 weeks. Collect all findings.
2. **Classify findings**: For each rule type, measure true-positive rate from a sample of 20 findings.
3. **Suppress noise with prejudice**: Rules with < 30% true-positive rate should be disabled or moved to informational. Document WHY in the ESLint config as a comment.
4. **Baseline suppression**: For legitimate false positives in specific contexts, use inline suppressions with justification:

```typescript
// eslint-disable-next-line security/detect-object-injection -- key is validated against allowlist above
const value = safeConfig[validatedKey];

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion -- id is guaranteed by DB constraint
const userId = session.user!.id;
```

5. **Hard gate only trusted rules**: Only rules with > 70% true-positive rate should block CI.
6. **Review quarterly**: As the codebase evolves, re-evaluate suppressed rules.

---

## Real-World Gotchas [community]

[community] **Gotcha**: TypeScript's `@typescript-eslint/recommended-type-checked` requires `parserOptions.project` to point to a `tsconfig.json`. On monorepos with multiple packages, this requires per-package `tsconfig.json` files and either per-directory ESLint configs or `parserOptions.projectFolderIgnorePattern` to exclude `node_modules`. The setup overhead is real but one-time; the type-aware rules are worth it.

[community] **Gotcha**: `vitest run --related` in a lint-staged pre-commit hook requires test files to follow naming conventions (`user.spec.ts` adjacent to `user.ts`). Without this convention, vitest cannot infer which tests to run and falls back to running all tests.

[community] **Gotcha**: ESLint `security/detect-object-injection` fires on nearly every `obj[key]` bracket access. Teams typically disable this specific rule and rely on explicit allowlists and input validation instead.

[community] **Gotcha**: `npm audit` generates false positives for vulnerabilities in dev-only dependencies. Use `--omit=dev` in CI to scope audits to production dependencies.

[community] **Gotcha**: CodeQL uses `javascript-typescript` as the language identifier for TypeScript projects (not just `javascript`). Using only `javascript` in older `codeql-action` configs causes TypeScript-specific patterns (type assertions bypassing checks, as-cast vulnerabilities) to be missed.

[community] **Gotcha**: Zod's `.parse()` throws on validation failure; `.safeParse()` returns a result object. In Express middleware, always use `.safeParse()` so validation failures return 400 responses rather than crashing the process with an unhandled exception.

[community] **Gotcha (Snyk report 2023)**: Dependabot PR volume on active projects can reach 20–40 PRs per week. Use Dependabot's `groups` configuration or switch to Renovate with `automerge: true` for patch-level non-security updates.

[community] **Gotcha**: OWASP ZAP active scan mode will attempt SQL injection, path traversal, and XSS payloads — it **will corrupt test database data** if pointed at a shared environment. Always run DAST against an isolated, ephemeral environment.

[community] **Lesson (Atlassian microservices)**: Consumer-driven contract testing (Pact) eliminated an entire class of integration defects in their microservice architecture: breaking API changes that only surfaced in staging or production. Running Pact contract verification as a PR check catches breaking changes at the exact commit that introduced them.

[community] **Lesson (State of JS 2024 survey)**: ESLint is the #1 static analysis tool in the JavaScript/TypeScript ecosystem with > 90% adoption in teams larger than 5 engineers. However, only 38% of teams enforce `--max-warnings=0` in CI — the majority run ESLint in advisory mode. Enforcing zero-warning in CI is one of the highest-leverage, lowest-effort upgrades available.

[community] **Lesson (DORA 2024 State of DevOps Report)**: The 2024 DORA survey found that technical debt and rework are the primary inhibitors of software delivery performance — teams spending > 30% of their time on rework had 2× worse change failure rates than elite teams. The DORA report explicitly identifies early defect detection (shift-left) as the intervention with the highest correlation to reduced rework.

[community] **Gotcha (AI-assisted SAST, 2024–2026)**: AI autofix tools propose semantically correct but contextually wrong fixes in ~15–20% of cases. Always require human review of AI-proposed security fixes before merging. Do not configure Copilot Autofix or Semgrep Assistant to auto-merge without code review.

[community] **Lesson (Stripe engineering)**: Shift-left pays the highest dividend when applied to the authorization layer. Authorization defects (privilege escalation, IDOR) are systematically hard to catch with unit test cases because they require cross-user context. Test authorization explicitly at the integration level with role-specific test fixtures.

[community] **Lesson (TypeScript strict mode adoption, 2024)**: Teams that enable `"strict": true` on an existing codebase report finding 20–40 pre-existing defects during the migration — bugs hiding in the codebase as implicit `any` types, unchecked null access, and dead code. The "migration pain" is actually a defect discovery phase. Run with `"noEmit": true` first to see all findings before enabling hard enforcement.

[community] **Lesson (Prisma / tRPC engineering, 2024)**: The highest-impact TypeScript shift-left practice is enabling `"exactOptionalPropertyTypes": true` and `"noUncheckedIndexedAccess": true` — the two strict flags NOT included in `"strict": true` by default. Both flags surface a disproportionate number of real bugs: `noUncheckedIndexedAccess` makes `array[0]` return `T | undefined` instead of `T`, forcing null checks that prevent "Cannot read property of undefined" crashes. WHY it matters: these flags are excluded from `"strict"` because they break too much existing code — but on a greenfield TypeScript project, enabling them from day 1 costs nothing and prevents an entire class of production crashes.

[community] **Gotcha (TypeScript + Express middleware, production)**: Typing Express `req.body` as `CreateUserInput` (a TypeScript interface) does NOT validate the input at runtime — TypeScript types are erased. Teams frequently add TypeScript types to `req.body` and believe they have validation, but any malformed JSON that matches the interface's shape at the TypeScript level (e.g., `age: "25"` instead of `age: 25` after JSON.parse) passes the type check silently. WHY: Always validate `req.body` with Zod or equivalent at the start of the handler — `const input = CreateUserSchema.parse(req.body)` — and use `input` (typed by Zod) rather than `req.body` (typed by TypeScript's inference) in all downstream logic.

[community] **Lesson (Microsoft TypeScript team, 2024)**: The TypeScript compiler itself is a shift-left tool used by > 10 million developers daily. The TSC team reports that the most common category of type errors caught by strict mode in real-world codebases is `strictNullChecks` violations — accounting for > 60% of all type errors surfaced during strict mode migration. This empirically validates the "billion dollar mistake" framing: null/undefined is the #1 source of preventable runtime defects in TypeScript projects that run without `strictNullChecks`.

[community] **Gotcha (Monorepo TypeScript, production)**: In NX or Turborepo monorepos, running `tsc --noEmit` at the root does not type-check all packages — each package has its own `tsconfig.json` and must be checked independently. Teams often configure only the root type check in CI and miss type errors in internal packages. WHY: Use `turbo run typecheck` or `nx run-many --target=typecheck` to type-check all packages in parallel, and configure each package's `tsconfig.json` with proper `references` for project-to-project type checking.

[community] **Gotcha (tsc performance in CI, production)**: `tsc --noEmit` in a cold CI environment (no cache) takes 30–120 seconds on large TypeScript projects (100k+ LOC). Teams are tempted to remove it from CI to speed up PRs. WHY you must keep it: the type check catches errors that ESLint and Vitest do not — specifically: incorrect generic type parameters, exhaustiveness check failures, and structural type incompatibilities between modules. Solution: use TypeScript project references (`tsconfig.json` `references` + `composite: true`) to enable incremental compilation across packages; this reduces `tsc --noEmit` from 120s to 5–15s by only re-checking changed packages.

---

## Shift-Left vs Shift-Right Balance [community]

[community] **Lesson (Spotify engineering blog)**: Teams that go all-in on shift-left and remove production monitoring regress. Unit tests and type checks do not catch n-way integration failures, data migration edge cases, or real user behavior patterns that only appear at scale.

[community] **Lesson (Netflix tech blog, GitHub engineering)**: High-velocity organizations run both layers: shift-left gates (unit test, lint, tsc --noEmit, SAST) for speed and immediate feedback, and shift-right observability (feature flags, canary deployments, error budgets, synthetic checks) for production confidence.

[community] **Lesson (Google SRE Book)**: The cost curve argument works in the opposite direction too — building comprehensive integration test suites that take 45 minutes to run kills CI throughput. The goal is *appropriately placed* feedback loops, not maximum coverage at the earliest stage.

[community] **Lesson (ThoughtWorks Technology Radar)**: The shift-left movement has created an over-investment in unit tests relative to integration and contract tests. Many bugs that matter are interaction bugs — they can only be caught between services. Invest in consumer-driven contract testing (Pact) as a mid-pipeline check.

---

## Tradeoffs & Alternatives

| Approach | Benefit | Cost | Recommendation |
|---|---|---|---|
| TypeScript strict mode (`"strict": true`) | Eliminates null dereferences, any coercions, unhandled returns at compile time | Migration overhead on existing JS codebases; 20–200 errors to fix | Enable on new projects from day 1; migrate incrementally on existing codebases |
| TypeScript project references (`composite: true`) | Incremental type-checking across packages: reduces `tsc --noEmit` from 120s to 5–15s on large repos | Requires `declaration: true` and `composite: true` in each package; setup overhead for monorepos | Required for monorepos where `tsc --noEmit` is too slow to be a PR gate |
| Pre-commit hooks (Husky) | Immediate, offline feedback; no CI wait | Slows commit (10–30s with tsc); devs bypass with `--no-verify` | Use for lint + format; use `--incremental` for tsc; move full type check to CI |
| `@typescript-eslint` type-checking rules | Catches unsafe-any, floating promises, misused awaits — TypeScript-aware | Requires `parserOptions.project`; 2–5× slower than plain ESLint | Essential for TypeScript projects; accept the speed cost |
| Zod runtime validation | TypeScript type derived from schema — no drift | Adds ~50KB bundle; `.parse()` throws | Use at all external trust boundaries; prefer `.safeParse()` in middleware |
| PR status checks | Hard gate, cannot be bypassed; audit trail | Requires CI infrastructure; slows PR cycle by 3–10 min | Required for all production codebases |
| SAST (CodeQL) | Deep data-flow taint analysis; TypeScript-aware | High false-positive rate; 5–20 min scan; complex for monorepos | Essential for security-sensitive code; tune rules first |
| SAST (Semgrep) | Fast (< 2 min); highly configurable; `p/typescript` ruleset | Community rules vary in quality | Better default SAST choice for speed |
| DAST (OWASP ZAP) | Finds runtime security issues invisible to SAST + TypeScript types | Requires running app; 15–45 min; corrupts test data if misconfigured | Nightly/schedule only; never on every PR |
| Snyk vs npm audit | Snyk: richer data, fix PRs, license scan; audit: zero config | Snyk: requires account + token + cost at scale | Both: `npm audit` in CI, Snyk for deeper analysis |

**When not to shift left**: Exploratory testing, usability research, load testing, and chaos/resilience testing are inherently shift-right activities. Do not attempt to automate or pre-production-gate tests that require real user behavior, real traffic patterns, or stochastic failure modes.

**Named alternative to shift-left**: **Shift-right testing** (production observability, feature flags, canary deployments, chaos engineering). The alternative philosophy is "make it safe to deploy to production frequently with fast rollback" rather than "block everything that is not perfect before it ships." Both are valid strategies; elite engineering organizations use both simultaneously.

**Known adoption cost**: Enabling TypeScript strict mode on an existing codebase typically surfaces 20–200 type errors that must be fixed before CI is green. On large codebases (100k+ LOC), this can be a multi-sprint effort. Use `// @ts-nocheck` or `tsconfig.json` `include`/`exclude` to migrate file-by-file.

### Team-Size Adoption Guide

| Team Size | Recommended Starting Point | Add Next |
|---|---|---|
| 1–3 engineers | TypeScript strict mode + ESLint + Prettier (pre-commit) | Unit tests, `npm audit` in CI |
| 4–10 engineers | Above + Husky/lint-staged + PR status checks (unit tests, tsc --noEmit, lint) | Vitest coverage thresholds, CodeQL on PRs |
| 11–30 engineers | Above + Semgrep or CodeQL SAST + Zod validation at API boundaries + Snyk | DAST (nightly), contract tests |
| 30+ engineers | Above + all patterns + DAST + consumer-driven contract tests (Pact) + SBOMs | Chaos engineering, error budgets |

---

## Shift-Left Maturity Model

| Level | Name | Characteristics | Key Evidence |
|-------|------|----------------|--------------|
| **L1** | Ad-Hoc | Tests written after code or not at all; TypeScript in "loose mode" (`"strict": false`); testing is a manual phase | No CI test gate; defects found in staging or production |
| **L2** | Established | TypeScript strict mode enabled; unit tests exist and run in CI; `@typescript-eslint` enabled; PR requires CI to pass | CI green required to merge; coverage tracked |
| **L3** | Automated | Pre-commit hooks with lint-staged; tsc --noEmit in CI; coverage thresholds enforced; Semgrep on PRs; `npm audit` as gate; secret scanning enabled | MTTD < 15 min for code defects |
| **L4** | Security-Integrated | CodeQL with TypeScript language; Zod runtime validation at all API boundaries; Snyk + license compliance; nightly DAST; contract tests | SAST:production CVE ratio > 10:1 |
| **L5** | Comprehensive | IaC scanning; container image scanning; SBOM generation + attestation; error budgets; full shift-right complement | Defect escape rate measured and decreasing |

> [community] **Lesson (engineering maturity research, DORA 2024)**: Teams at L3+ deploy 4× more frequently and have 7× lower change failure rates than L1–L2 teams. The L2→L3 transition is where most of the DORA elite performer gains come from — not from L4/L5 sophistication.

---

### DAST with OWASP ZAP — TypeScript API Testing (Scheduled / Nightly)

```yaml
# .github/workflows/dast-scan.yml — run nightly on main, NOT on every PR
name: DAST — OWASP ZAP Scan
on:
  schedule:
    - cron: '0 2 * * *'    # Nightly at 02:00 UTC
  workflow_dispatch:        # Allow manual trigger for ad-hoc scans

jobs:
  zap-baseline:
    name: ZAP Baseline Scan (passive, fast ~5 min)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start TypeScript app in Docker
        run: |
          docker compose -f docker-compose.test.yml up -d app
          # Wait for the TypeScript app to be ready (health endpoint)
          timeout 60 sh -c 'until curl -sf http://localhost:3000/health; do sleep 2; done'

      - name: Run ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
          fail_action: true

      - name: Upload ZAP report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report-${{ github.run_number }}
          path: report_html.html

      - name: Stop application
        if: always()
        run: docker compose -f docker-compose.test.yml down
```

```typescript
// src/app.ts — TypeScript Express app with security headers set for DAST compliance
// These headers are what ZAP checks for — set them explicitly to pass ZAP baseline scan
import express from 'express';
import helmet from 'helmet';
import type { Request, Response } from 'express';

export const app = express();

// helmet() sets: X-Frame-Options, X-Content-Type-Options, Referrer-Policy,
// X-XSS-Protection, HSTS (via hsts option), Content-Security-Policy (via contentSecurityPolicy)
// Without helmet, ZAP baseline scan will flag EVERY security header as missing
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],  // Adjust for your frontend framework
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:'],
    },
  },
  hsts: {
    maxAge: 31536000,        // 1 year in seconds
    includeSubDomains: true,
    preload: true,
  },
}));

app.use(express.json({ limit: '1mb' })); // Limit prevents DoS from large payloads

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

**WHY DAST is NOT a pre-commit or PR check**: ZAP scans a running application for runtime vulnerabilities (missing headers, actual XSS reflection, CORS misconfiguration, TLS issues). These can only be verified against a live server — no static analysis or type system can catch a missing `Content-Security-Policy` header. Run DAST nightly to keep the feedback window short (< 24 hours), but never block PR merges on it.

## Measuring Shift-Left Effectiveness

| Metric | How to Measure | Good Signal |
|---|---|---|
| **Defect escape rate** | Production defects ÷ total defects found | Decreasing over time |
| **Mean time to detect (MTTD)** | Time from commit to defect found | < 15 minutes for code defects |
| **Pre-commit failure rate** | Commits blocked by hooks ÷ total commits | 5–15% |
| **PR gate failure rate** | PRs failing CI ÷ total PRs | 10–25% expected |
| **`--no-verify` usage** | Count of commits with `--no-verify` flag | Should be near zero |
| **Type error discovery rate** | Type errors found during strict mode migration | Use as baseline for defect density |
| **False positive rate** | SAST alerts dismissed as false positive ÷ total | < 20% means rules are well-tuned |

---

### Dependency Vulnerability Scanning — TypeScript Projects

```yaml
# .github/workflows/dependency-scan.yml — runs on lock file changes and weekly
name: Dependency Vulnerability Scan
on:
  push:
    paths: ['package-lock.json', 'package.json']
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'   # Weekly Monday at 09:00 UTC

jobs:
  npm-audit:
    name: npm audit (production deps only)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # Report all severities to artifact, fail only on high/critical
      # --omit=dev: TypeScript devDependencies (tsc, @types/*) are excluded
      - run: npm audit --json --omit=dev > npm-audit-report.json || true
      - uses: actions/upload-artifact@v4
        with: { name: npm-audit-report, path: npm-audit-report.json }
      - run: npm audit --audit-level=high --omit=dev

  snyk:
    name: Snyk vulnerability + license scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - uses: snyk/actions/node@master
        with:
          args: >-
            --severity-threshold=high
            --sarif-file-output=snyk.sarif
            --org=${{ vars.SNYK_ORG_ID }}
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: snyk.sarif

  license-check:
    name: Dependency license compliance
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # TypeScript note: --production flag excludes @types/* and other devDeps
      - run: npx license-checker --production --onlyAllow 'MIT;ISC;BSD-2-Clause;BSD-3-Clause;Apache-2.0;CC0-1.0' --excludePrivatePackages
```

> [community] **Gotcha (TypeScript projects)**: `npm audit --omit=dev` excludes devDependencies from the audit. For TypeScript projects, this means `typescript`, `@types/*`, `ts-node`, `vitest`, and all other build/test tools are excluded. This is correct — they don't ship to production. However, if your `tsconfig.json` uses `"paths"` aliases that require a runtime helper (like `tsconfig-paths`), ensure that package is in `dependencies` not `devDependencies`, or it will be excluded from the audit and potentially from production installs.

## Quick Reference — TypeScript Shift-Left Checklist

Use this checklist to audit a TypeScript/Node.js project's shift-left posture:

**TypeScript Compiler Layer (instantaneous — runs on save)**
- [ ] `"strict": true` in `tsconfig.json`
- [ ] `"noUncheckedIndexedAccess": true` (not in strict by default)
- [ ] `"exactOptionalPropertyTypes": true` (not in strict by default)
- [ ] `"useUnknownInCatchVariables": true` (enabled by `strict` in TS 4.4+)
- [ ] `"noUnusedLocals": true` and `"noUnusedParameters": true`
- [ ] Separate `tsconfig.test.json` with relaxed rules for test files

**Static Layer (pre-commit)**
- [ ] `@typescript-eslint/eslint-plugin` v8+ with `recommendedTypeChecked`
- [ ] `eslint-plugin-security` for Node.js security rules
- [ ] Husky pre-commit hook with lint-staged (lint + format)
- [ ] `tsc --noEmit --incremental` in pre-commit (fast via build cache)
- [ ] Conventional commits enforced via commit-msg hook
- [ ] `.env` files in `.gitignore` + pre-commit `.env` file guard
- [ ] Secret scanning pre-commit check (Gitleaks or custom script)

**PR Gate Layer (CI — must pass before merge)**
- [ ] `tsc --noEmit` (full, non-incremental) as required status check
- [ ] Unit tests with coverage thresholds (≥ 80% lines) via Vitest
- [ ] `@typescript-eslint` at `--max-warnings=0`
- [ ] `npm audit --audit-level=high --omit=dev`
- [ ] Semgrep with `p/typescript` ruleset
- [ ] CodeQL with `javascript-typescript` language
- [ ] Gitleaks secret scanning (PR-level)
- [ ] Zod (or equivalent) runtime validation at all external API boundaries
- [ ] Branch protection configured with `enforce_admins: true` + required status checks

**Pipeline / Nightly Layer**
- [ ] Snyk dependency scan (nightly, on `package-lock.json` changes)
- [ ] Dependabot or Renovate for automated dependency updates
- [ ] OWASP ZAP baseline scan (nightly against staging)
- [ ] License compliance check (`license-checker`)
- [ ] OpenSSF Scorecard (weekly)
- [ ] Container image scan (Trivy) on `Dockerfile` changes

**Shift-Right Layer (production confidence)**
- [ ] Feature flags for gradual rollout
- [ ] Canary deployment with error-rate rollback
- [ ] Synthetic monitoring + real-user monitoring (RUM)
- [ ] Error budgets and SLOs defined

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| IBM: Shift-Left Testing | Official | https://www.ibm.com/topics/shift-left-testing | Foundational definitions and cost-of-defects curve |
| OWASP DevSecOps Guideline | Official | https://owasp.org/www-project-devsecops-guideline/ | Security testing pipeline integration patterns |
| OWASP ZAP | Official | https://www.zaproxy.org/ | DAST tool for runtime security testing |
| TypeScript Handbook — Strict Mode | Official | https://www.typescriptlang.org/tsconfig#strict | All strict compiler flags and what they catch |
| TypeScript Compiler Options Reference | Official | https://www.typescriptlang.org/tsconfig | Full tsconfig.json reference |
| `@typescript-eslint` Documentation | Tool | https://typescript-eslint.io/rules/ | TypeScript-aware ESLint rules |
| Zod Documentation | Tool | https://zod.dev/ | TypeScript-first schema validation and type derivation |
| Semgrep Rules Registry | Tool | https://semgrep.dev/r | Curated SAST rulesets including `p/typescript` |
| CodeQL Documentation | Official | https://codeql.github.com/docs/ | Deep taint analysis for TypeScript/JavaScript |
| Husky Documentation | Tool | https://typicode.github.io/husky/ | Pre-commit hook setup for Node.js/TypeScript projects |
| lint-staged | Tool | https://github.com/lint-staged/lint-staged | Run linters on staged files only (fast pre-commit) |
| Snyk for Node.js | Tool | https://docs.snyk.io/scan-using-snyk/snyk-open-source/ | Dependency vulnerability + license scanning |
| eslint-plugin-security | Tool | https://github.com/eslint-community/eslint-plugin-security | ESLint security rules for Node.js |
| Google SRE Book — Testing for Reliability | Book | https://sre.google/sre-book/testing-reliability/ | Production testing philosophy from Google |
| ThoughtWorks Technology Radar — Shift Left on Security | Community | https://www.thoughtworks.com/radar/techniques/shift-left-on-security | Industry adoption signal and maturity guidance |
| NIST: Cost Advantage of Early Defect Detection | Research | https://www.nist.gov/system/files/documents/director/planning/report02-3.pdf | Empirical data behind the cost-of-defects curve |
| Pact Consumer-Driven Contract Testing | Tool | https://docs.pact.io/ | Contract tests as mid-pipeline shift-left integration checks |
| Vitest Documentation | Tool | https://vitest.dev/guide/ | Fast TypeScript-native test runner |
| Renovate Bot | Tool | https://docs.renovatebot.com/ | Automated dependency updates with configurable automerge |
| Gitleaks | Tool | https://github.com/gitleaks/gitleaks | Pre-commit and CI secret detection |
| GitHub Secret Scanning | Official | https://docs.github.com/en/code-security/secret-scanning | Native push protection for committed secrets |
| OpenSSF Scorecard | Tool | https://securityscorecards.dev/ | Automated supply chain security scoring |
| DORA 2024 State of DevOps Report | Research | https://dora.dev/research/2024/dora-report/ | Empirical data linking shift-left to elite engineering performance |
| CISA: Framing Software Component Transparency | Official | https://www.cisa.gov/resources-tools/resources/framing-software-component-transparency | SBOM guidance for supply chain security |
| GitHub Copilot Autofix | Tool | https://github.blog/2024-03-20-found-means-fixed-introducing-autofix-for-github-advanced-security/ | AI-assisted SAST remediation with TypeScript awareness |
| Semgrep Assistant | Tool | https://semgrep.dev/docs/semgrep-assistant/overview/ | AI-powered triage and remediation for Semgrep findings |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Standardized shift-left terminology and test levels |
