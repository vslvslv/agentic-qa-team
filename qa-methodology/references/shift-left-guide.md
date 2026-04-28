# Shift-Left Testing — QA Methodology Guide
<!-- lang: JavaScript | topic: shift-left | iteration: 4 | score: 100/100 | date: 2026-04-27 -->

## Core Principles

Shift-left testing is the practice of moving quality and security validation activities earlier (further "left") in the Software Development Life Cycle (SDLC). Rather than treating testing as a phase that follows development, shift-left embeds testing at every stage from requirements through design and code.

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

**WHY it matters**: When testing is a handoff to another team, developers write code that is not designed for testability — deep coupling, hidden side effects, opaque dependencies. When developers own tests, they build tighter feedback loops and naturally design for dependency injection, pure functions, and observable state. Testable architecture is better architecture. Additionally, only the developer who wrote the code understands the intended behavior precisely enough to write meaningful tests for edge cases; a QA engineer testing the same code two weeks later is testing against observed behavior, not intent.

### The Test Pyramid for Shift-Left

Shift-left maps directly onto the test pyramid. Higher-left tests are cheaper and faster — they should form the base.

```
           /\
          /  \  E2E / DAST (shift-right, slow, expensive)
         /    \
        /------\ Integration / Contract Tests (PR-level CI)
       /        \
      /----------\ Unit Tests + JSDoc type checks (pre-commit + CI, fast)
     /            \
    /--------------\ Static Analysis (SAST, ESLint, lint — instantaneous)
```

- **Static analysis** (ESLint, `node --check`): runs in milliseconds, no infrastructure, catches whole categories of bugs
- **Unit tests**: run in seconds, no external dependencies, verify logic in isolation
- **Integration / contract tests**: run in minutes, require services, verify interactions
- **E2E / DAST**: run in tens of minutes, require full deployment, verify end-to-end user flows and runtime security

Shift-left is the practice of **investing heavily in the bottom layers** — not eliminating the top layers.

### 4. SAST (Static Application Security Testing)
SAST tools analyze source code without running it. For JavaScript/Node.js stacks:
- **ESLint security plugins** (`eslint-plugin-security`, `eslint-plugin-no-secrets`) for common Node.js vulnerabilities
- **Semgrep** with community rulesets (`p/javascript`, `p/nodejs`, `p/owasp-top-ten`) for pattern-based code scanning
- **CodeQL** via GitHub Actions for deep data-flow and taint analysis

**WHY it matters**: SAST catches injection risks, unsafe `eval`, insecure deserialization, and secrets in code before they ever reach a branch. The earlier a security flaw is found, the simpler the fix — no CVE, no incident response, no customer notification required.

### 5. DAST (Dynamic Application Security Testing)
DAST runs against a live or containerized application instance:
- **OWASP ZAP** — open-source, scriptable, integrable with CI via `zaproxy/action-full-scan` or `zaproxy/action-baseline-scan`
- **Nuclei** — fast, template-based vulnerability scanner for common CVEs and misconfigurations
- Targets: XSS, CSRF, open redirects, broken auth headers, missing security headers (CSP, HSTS, X-Frame-Options)

**WHY it matters**: DAST validates runtime behavior that static analysis cannot see. A JavaScript application can pass every SAST check and still ship with: an insecure CORS wildcard (`Access-Control-Allow-Origin: *`), missing `HttpOnly` cookie flags, no Content Security Policy, or an outdated TLS cipher suite. DAST is the only automated mechanism that catches configuration-level vulnerabilities that live outside the codebase entirely — in web server config, reverse proxy headers, or infrastructure-as-code.

### 6. Pre-Commit Hooks
Husky + lint-staged intercept Git commits to run fast, file-scoped checks:
- ESLint (with security plugins)
- Prettier formatting
- `node --check` for syntax validation
- Focused unit tests for changed files via Jest `--findRelatedTests` or Vitest `--related`

**WHY it matters**: Developers get sub-10-second feedback on the exact files they changed, before code even leaves their machine. The feedback loop shrinks from "wait for CI" (minutes) to "before you commit" (seconds).

### 7. PR-Level Required Status Checks
GitHub / GitLab branch protection rules that must pass before merge:
- All unit tests with coverage threshold enforcement
- SAST scan (ESLint security, CodeQL or Semgrep)
- `npm audit --audit-level=high --omit=dev` and/or Snyk scan
- Consumer-driven contract tests (Pact) for service API changes

**WHY it matters**: PR checks create a hard gate that prevents broken or insecure code from entering the main branch, independent of developer discipline or reviewer oversight. They are not bypassable without admin intervention (which creates an audit trail). Unlike pre-commit hooks (which developers can skip with `--no-verify`), PR status checks are enforced by the platform.

**Contract testing note**: Consumer-driven contract tests (e.g., Pact for JavaScript) are particularly valuable at the PR level for microservice architectures. They verify that an API change in Service A does not break the contracts expected by consumers B and C — without requiring those services to be deployed.

### 8. Shift-Right Counterpart
Shift-right testing validates quality in or near production:
- **Feature flags** (LaunchDarkly, Unleash, Flagsmith) for gradual user-segment rollout
- **Canary deployments** (Argo Rollouts, Flagger, Spinnaker) with automated error-rate rollback
- **Synthetic monitoring** (Datadog Synthetics, Checkly, Pingdom) — automated browser flows against production
- **Real-user monitoring** (RUM via Datadog, New Relic, Sentry) — captures real performance and JS errors

Shift-left and shift-right are **complementary**, not competing strategies. A well-run engineering org has both.

### 9. JSDoc Type Checking as Shift-Left
For plain JavaScript projects, `tsc --checkJs --noEmit` with a `jsconfig.json` provides TypeScript-level type checking without requiring TypeScript compilation. This is the most cost-effective type safety shift for existing JavaScript codebases.

```json
// jsconfig.json — enable strict type checking on plain JavaScript files
{
  "compilerOptions": {
    "checkJs": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "allowJs": true,
    "outDir": "dist"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.js", "**/*.test.js"]
}
```

```javascript
// src/services/payment.service.js — JSDoc types catch errors at dev time
import { createHash } from 'node:crypto';

/**
 * @typedef {Object} PaymentIntent
 * @property {string} id
 * @property {number} amount      - Amount in cents
 * @property {'usd'|'eur'|'gbp'} currency
 * @property {'pending'|'succeeded'|'failed'} status
 */

/**
 * Creates a payment intent with idempotency key.
 * @param {number} amountCents - Must be a positive integer
 * @param {'usd'|'eur'|'gbp'} currency
 * @param {string} customerId
 * @returns {Promise<PaymentIntent>}
 * @throws {Error} If amountCents is not a positive integer
 */
export async function createPaymentIntent(amountCents, currency, customerId) {
  if (!Number.isInteger(amountCents) || amountCents <= 0) {
    throw new Error(`amountCents must be a positive integer, got: ${amountCents}`);
  }
  const idempotencyKey = createHash('sha256')
    .update(`${customerId}:${amountCents}:${currency}:${Date.now()}`)
    .digest('hex');

  // tsc --checkJs catches: wrong currency string, passing string for amountCents, etc.
  return fetchStripeAPI('/payment_intents', {
    amount: amountCents,
    currency,
    idempotency_key: idempotencyKey,
  });
}
```

**WHY it matters**: Without type checking, `createPaymentIntent('100', 'USD', id)` (string amount, wrong currency case) fails at runtime in production. With `tsc --checkJs`, it fails at edit time in the IDE and in CI. This is shift-left applied to a JavaScript codebase without requiring a TypeScript migration.

Add to CI pipeline:
```yaml
# In pr-quality-gate.yml — add as a required check alongside ESLint
  jscheck:
    name: JSDoc Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx tsc --project jsconfig.json --noEmit
        # Zero-install type checking: tsc is included in typescript package
```

### 10. Runtime Validation as Shift-Left
Runtime schema validation at API boundaries catches malformed external data before it propagates into business logic.
- **Joi** (`@hapi/joi`) — feature-rich schema validation for Node.js
- **Ajv** — JSON Schema validator, fast for high-throughput APIs
- **Zod** (works in plain JS too) — schema-first validation with `.parse()` / `.safeParse()`

**WHY it matters**: Errors are caught at the first entry point rather than surfacing as `Cannot read properties of undefined` runtime exceptions in production — or worse, as data corruption from silently accepting the wrong type.

### 11. Dependency Vulnerability Scanning
- `npm audit` — built-in, runs in CI, reports CVEs from the npm advisory database
- **Snyk** — more granular than `npm audit`, provides fix advice, tracks license compliance
- **Dependabot** (GitHub) or **Renovate** — auto-creates PRs to update vulnerable dependencies on a schedule

**WHY it matters**: Third-party packages are the largest attack surface in modern Node.js applications. The average enterprise Node.js project has 500–1,000 transitive dependencies, most of which the team has never reviewed. Automated scanning stops known CVEs from shipping without requiring manual audits.

---

## When to Use

Shift-left is most valuable when:
- The codebase is under active development with frequent merges (daily or more)
- Security requirements exist (PCI-DSS, SOC 2 Type II, HIPAA, GDPR) or you are working toward a compliance certification
- The team is small and lacks a dedicated QA team — shift-left is how small teams maintain quality without a QA headcount
- Time-to-production speed is a critical business priority and you cannot afford long manual QA cycles
- You are onboarding new developers who need guardrails that catch mistakes early
- The product has a public API or processes sensitive user data

Shift-left is **less appropriate** (or should be scoped carefully) when:
- The project is a short-lived prototype (< 4 weeks, no production users, no sensitive data): focus on delivering and add shift-left when it graduates to a real product
- Tests require complex infrastructure spin-up that slows the commit loop beyond 5 minutes — isolate infrastructure tests to the CI layer only
- The team is in an emergency release crunch: defer tooling setup, but schedule it for the sprint immediately following. Do not defer indefinitely.
- The codebase is read-only legacy with no active development: maintain existing tests but do not invest in new shift-left tooling

---

## Patterns

### Pre-Commit Hooks (Husky + lint-staged)

```json
// package.json — complete configuration for Husky v9 + lint-staged v15
{
  "scripts": {
    "prepare": "husky",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "test:related": "vitest run --related"
  },
  "lint-staged": {
    "*.{js,mjs,cjs}": [
      "eslint --fix --max-warnings=0",
      "prettier --write"
    ],
    "*.{spec.js,test.js}": [
      "vitest run --related --reporter=verbose"
    ]
  },
  "devDependencies": {
    "husky": "^9.1.0",
    "lint-staged": "^15.2.0",
    "eslint": "^9.0.0",
    "@eslint/js": "^9.0.0",
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
# Runs lint-staged on all staged files before allowing commit.
# To skip in emergencies only: git commit --no-verify (creates audit log entry)
npx lint-staged
```

```sh
#!/bin/sh
# .husky/commit-msg — validates conventional commits format
# Enforces: feat:, fix:, chore:, docs:, test:, refactor:, perf:, ci:
npx --no -- commitlint --edit "$1"
```

```javascript
// vitest.config.js — configured for fast pre-commit related-file runs
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Environment
    environment: 'node',
    globals: true,

    // Coverage collection (used by PR gate, not pre-commit)
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.js'],
      exclude: ['src/**/*.spec.js', 'src/index.js'],
      thresholds: {
        lines: 80,
        functions: 75,
        branches: 70,
        statements: 80,
      },
    },

    // Pre-commit: run with `vitest run --related` to only test changed files
    // CI: run with `vitest run --coverage` for full suite + coverage report
    reporters: process.env.CI ? ['junit', 'verbose'] : ['verbose'],
    outputFile: process.env.CI ? 'test-results.xml' : undefined,

    // Performance: isolate tests but share vm context for speed
    isolate: true,
    pool: 'forks',
    poolOptions: {
      forks: { singleFork: false },
    },
  },
});
```

> **Gotcha**: `vitest run --related` requires a test file naming convention (e.g., `user.spec.js` next to `user.js`) for the related-file heuristic to work. Without it, all tests run on every commit.

### SAST in CI (ESLint Security / Semgrep / CodeQL)

```javascript
// eslint.config.js — security-focused ESLint flat config for Node.js (ESLint v9+)
// ESLint v9 uses flat config (eslint.config.js), NOT .eslintrc.json
import js from '@eslint/js';
import security from 'eslint-plugin-security';
import noSecrets from 'eslint-plugin-no-secrets';
import globals from 'globals';

export default [
  // Base recommended rules
  js.configs.recommended,

  // Security plugin rules
  security.configs['recommended-legacy'],

  {
    // Apply to all JavaScript source files
    files: ['src/**/*.js', 'src/**/*.mjs'],

    plugins: {
      security,
      'no-secrets': noSecrets,
    },

    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.node,
        ...globals.es2022,
      },
    },

    rules: {
      // Security rules
      'security/detect-object-injection': 'warn',
      // False-positive rate is high on bracket access; tune before hard-gate
      'security/detect-non-literal-regexp': 'error',
      'security/detect-non-literal-require': 'error',
      'security/detect-possible-timing-attacks': 'error',
      'security/detect-unsafe-regex': 'error',
      'security/detect-buffer-noassert': 'error',
      'security/detect-child-process': 'warn',

      // Secret detection
      'no-secrets/no-secrets': ['error', { tolerance: 4.2 }],

      // Dangerous built-ins
      'no-eval': 'error',
      'no-implied-eval': 'error',

      // Code quality rules that catch real bugs
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'eqeqeq': ['error', 'always'],
      'no-console': 'warn', // Use structured logger (Pino/Winston) in production
    },
  },

  {
    // Test files: relax some rules
    files: ['**/*.spec.js', '**/*.test.js', 'tests/**/*.js'],
    rules: {
      'no-unused-vars': 'warn',
      'security/detect-non-literal-regexp': 'warn',
    },
  },
];
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
  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript
          queries: security-and-quality
      - run: npm ci
      - uses: github/codeql-action/analyze@v3
        with:
          category: '/language:javascript'

  semgrep:
    name: Semgrep OWASP Scan
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep
    steps:
      - uses: actions/checkout@v4
      - run: semgrep scan --config=p/javascript --config=p/nodejs --config=p/owasp-top-ten --sarif --output=semgrep.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: semgrep.sarif
```

### Secret Scanning (Gitleaks / GitHub Secret Scanning)

Secret scanning is a distinct shift-left category from SAST. It detects API keys, tokens, passwords, and private keys accidentally committed to the repository — a class of vulnerability SAST tools do not target.

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
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}  # Optional: for enterprise features
        # Scans diff between base and HEAD for all commits in the PR
        # Config: .gitleaks.toml in repo root allows custom rules and allowlisting
```

```toml
# .gitleaks.toml — custom rules for project-specific secret patterns
[extend]
useDefault = true

[[rules]]
id = "custom-internal-api-key"
description = "Internal API key pattern"
regex = '''MYAPP_[A-Z0-9]{32}'''
tags = ["internal", "api-key"]

[allowlist]
  description = "Allowed patterns (test fixtures, example values)"
  regexes = [
    '''EXAMPLE_KEY_[A-Z]{8}''',
    '''test-secret-[a-z]{6}''',
  ]
  paths = [
    '''tests/fixtures/.*''',
    '''docs/examples/.*''',
  ]
```

> [community] **Gotcha**: The most common secret leak pattern is `.env` files committed during initial project setup. Add `.env`, `.env.local`, `.env.*` to `.gitignore` before the first commit, and add a pre-commit check that rejects any file matching `^\.env`:

```javascript
// scripts/check-no-env-files.js — run as a pre-commit check via lint-staged
import { execSync } from 'node:child_process';

const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf8' })
  .trim()
  .split('\n')
  .filter(Boolean);

const envFiles = stagedFiles.filter(f => {
  const basename = f.split('/').pop() ?? '';
  return /^\.env(\.|$)/.test(basename);
});

if (envFiles.length > 0) {
  console.error(`ERROR: Attempting to commit .env file(s):\n  ${envFiles.join('\n  ')}`);
  console.error('Remove from staging: git reset HEAD <file>');
  process.exit(1);
}
```

> [community] **Gotcha (GitGuardian State of Secrets Sprawl 2024)**: 12.8 million secrets were detected in public GitHub commits in 2023. The most commonly leaked secrets in Node.js projects are: Google API keys (committed via `.env` or hardcoded in tests), AWS credentials (from local `~/.aws/credentials` accidentally included), and JWT secrets (hardcoded in `config.js` for "convenience"). **Pre-commit secret scanning and GitHub push protection together stop > 90% of accidental commits before they reach remote**.

### PR-Level Required Status Checks

```yaml
# .github/workflows/pr-quality-gate.yml — comprehensive PR gate for Node.js/JavaScript projects
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
  syntax-check:
    name: Node.js Syntax Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # node --check validates JS syntax without executing — catches parse errors fast
      # ESLint also catches syntax errors, so this is a belt-and-suspenders check
      # that runs before the full lint step for immediate feedback
      - name: Syntax check all JS source files
        run: npx --yes glob-exec 'src/**/*.js' -- node --check
        # glob-exec maps a glob pattern to a command per file
        # Alternative for projects without glob-exec: run ESLint with --rule 'no-undef: off'
        # or rely on ESLint as the sole syntax gate

  unit-tests:
    name: Unit Tests + Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # Coverage thresholds are defined in vitest.config.js (thresholds.lines: 80, etc.)
      # --coverage flag enables collection; vitest exits with code 1 if any threshold fails
      - run: npx vitest run --coverage --reporter=junit --outputFile=test-results.xml
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results.xml

  lint-security:
    name: ESLint + Security Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # ESLint v9 flat config — file patterns defined in eslint.config.js, not --ext
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

### Runtime Schema Validation with Joi (Node.js)

Runtime validation at API boundaries catches malformed input before it propagates deeper. Joi is the most widely adopted Node.js validation library for plain JavaScript projects.

```javascript
// src/api/validators/user.validator.js
import Joi from 'joi';

// Schema definition — single source of truth for validation rules
export const createUserSchema = Joi.object({
  email: Joi.string()
    .email({ tlds: { allow: false } })
    .max(254)
    .required()
    .messages({
      'string.email': 'Must be a valid email address',
      'string.max': 'Email too long (RFC 5321 limit)',
    }),
  name: Joi.string()
    .min(1)
    .max(100)
    .pattern(/^[a-zA-Z\s'-]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Name contains invalid characters',
    }),
  role: Joi.string()
    .valid('admin', 'viewer', 'editor')
    .required()
    .messages({
      'any.only': 'Role must be admin, viewer, or editor',
    }),
  age: Joi.number().integer().min(13).max(150).optional(),
  metadata: Joi.object().pattern(Joi.string(), Joi.any()).optional(),
}).options({ stripUnknown: true }); // Silently strip extra fields

// Reusable Express middleware factory
export function validateBody(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        error: 'Validation failed',
        issues: error.details.map(d => ({ field: d.path.join('.'), message: d.message })),
      });
    }
    req.validatedBody = value; // Downstream handlers receive validated, stripped data
    next();
  };
}

// Usage: router.post('/users', validateBody(createUserSchema), createUserHandler);
```

```javascript
// src/api/validators/user.validator.test.js — test the validator directly (shift-left)
import { describe, it, expect } from 'vitest';
import { createUserSchema } from './user.validator.js';

describe('createUserSchema', () => {
  it('accepts a valid user payload', () => {
    const { error, value } = createUserSchema.validate({
      email: 'alice@example.com',
      name: 'Alice',
      role: 'viewer',
      age: 25,
    });
    expect(error).toBeUndefined();
    expect(value.email).toBe('alice@example.com');
  });

  it('rejects an invalid email', () => {
    const { error } = createUserSchema.validate({ email: 'not-an-email', name: 'Bob', role: 'viewer' });
    expect(error).toBeDefined();
    expect(error.details[0].message).toMatch(/valid email/);
  });

  it('rejects unknown roles', () => {
    const { error } = createUserSchema.validate({ email: 'a@b.com', name: 'Bob', role: 'superuser' });
    expect(error).toBeDefined();
    expect(error.details[0].message).toMatch(/admin, viewer, or editor/);
  });

  it('strips unknown fields (prevents prototype pollution)', () => {
    const { value } = createUserSchema.validate({
      email: 'a@b.com',
      name: 'Bob',
      role: 'viewer',
      __proto__: { isAdmin: true },
      extra: 'ignored',
    });
    expect(value).not.toHaveProperty('extra');
    expect(value).not.toHaveProperty('__proto__');
  });
});
```

### Dependency Vulnerability Scanning (npm audit / Snyk)

```yaml
# .github/workflows/dependency-scan.yml
on:
  push:
    paths: ['package-lock.json', 'package.json']
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'   # Weekly on Monday at 09:00 UTC

jobs:
  npm-audit:
    name: npm audit (production deps)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # Report all severities to artifact, but only fail on high/critical
      - run: npm audit --json --omit=dev > npm-audit-report.json || true
      - uses: actions/upload-artifact@v4
        with:
          name: npm-audit-report
          path: npm-audit-report.json
      # Hard fail gate — high or critical stops the merge
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
            --project-name=${{ github.repository }}
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
      - run: npx license-checker --production --onlyAllow 'MIT;ISC;BSD-2-Clause;BSD-3-Clause;Apache-2.0;CC0-1.0' --excludePrivatePackages
```

### DAST with OWASP ZAP (Scheduled / Nightly)

```yaml
# .github/workflows/dast-scan.yml — run nightly on main, NOT on every PR
name: DAST — OWASP ZAP Scan
on:
  schedule:
    - cron: '0 2 * * *'    # Nightly at 02:00 UTC
  workflow_dispatch:        # Allow manual trigger for ad-hoc scans

jobs:
  zap-baseline:
    name: ZAP Baseline Scan (passive, fast, ~5 min)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start application in Docker
        run: |
          docker compose -f docker-compose.test.yml up -d app
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

---

## Measuring Shift-Left Effectiveness

Track these metrics to quantify whether your shift-left investment is working:

| Metric | How to Measure | Good Signal |
|---|---|---|
| **Defect escape rate** | Production bugs ÷ total bugs found | Decreasing over time |
| **Mean time to detect (MTTD)** | Time from commit to defect found | < 15 minutes for code bugs |
| **Pre-commit failure rate** | Commits blocked by hooks ÷ total commits | 5–15% (too low = rules not catching anything; too high = rules too noisy) |
| **PR gate failure rate** | PRs failing CI ÷ total PRs | 10–25% expected; track trend per check type |
| **Security finding rate by phase** | SAST/PR findings vs production CVEs | SAST:production ratio should be > 10:1 |
| **`--no-verify` usage** | Count of commits with `--no-verify` flag | Should be near zero |
| **Test feedback loop time** | Time from `git push` to first test result | Target < 5 minutes for unit, < 15 for full gate |
| **False positive rate** | SAST alerts dismissed as false positive ÷ total alerts | < 20% means rules are well-tuned |

---

## Anti-Patterns

1. **Gate everything on every commit**: Running the full test suite + SAST + DAST on pre-commit destroys developer velocity. Reserve heavy checks for CI/PR gates; keep pre-commit under 15 seconds.
2. **Suppressing lint warnings instead of fixing them**: Teams add `// eslint-disable` comments as a default response to lint errors, defeating the purpose of the rule.
3. **100% line coverage as the goal**: High coverage of trivial getters and constructors gives false confidence. Focus on critical paths, error boundaries, and authorization logic.
4. **Not tuning SAST false positives**: Untuned SAST produces noisy alerts that teams learn to ignore — recreating the exact alert-fatigue problem it was meant to solve. Spend one sprint tuning rules before enforcing them as hard gates.
5. **Treating shift-left as shift-only**: Removing or skipping production monitoring because "we have 80% test coverage" leads to blind spots in real user behavior.
6. **Running DAST on every PR**: OWASP ZAP full-scan takes 15–45 minutes. Run it on schedule (nightly) or on merges to main, not every PR. Use SAST for PR gates.
7. **Shifting integration tests left into unit tests**: Mocking every external dependency in "unit" tests makes them fast but means no test ever validates the real SQL queries, migrations, or connection behavior. Keep a meaningful integration test layer.
8. **Security theater via checkbox compliance**: Installing SAST, secret scanning, and DAST tools but routing their findings to a separate "security backlog" that no one triages is not shift-left — it is shift-later with extra steps. Shift-left only works when findings block the pipeline AND developers act on them within the same sprint they are raised.

### SAST Tuning Workflow

Before making a SAST rule a hard gate (CI failure), follow this process to avoid alert fatigue:

1. **Audit mode first**: Run SAST in warn-only mode for 2 weeks. Collect all findings.
2. **Classify findings**: For each rule type, measure true-positive rate from a sample of 20 findings.
3. **Suppress noise with prejudice**: Rules with < 30% true-positive rate should be disabled or moved to informational. Document WHY in the ESLint config as a comment.
4. **Baseline suppression**: For legitimate false positives in specific contexts, use inline suppressions with justification:

```javascript
// eslint-disable-next-line security/detect-object-injection -- key is validated against allowlist above
const value = safeConfig[validatedKey];
```

5. **Hard gate only trusted rules**: Only rules with > 70% true-positive rate should block CI.
6. **Review quarterly**: As the codebase evolves, re-evaluate suppressed rules.

---

## Shift-Left vs Shift-Right Balance [community]

[community] **Lesson (Spotify engineering blog)**: Teams that go all-in on shift-left and remove production monitoring regress. Unit tests and lint checks do not catch n-way integration failures, data migration edge cases, or real user behavior patterns that only appear at scale.

[community] **Lesson (Netflix tech blog, GitHub engineering)**: High-velocity organizations run both layers: shift-left gates (unit test, lint, SAST) for speed and immediate feedback, and shift-right observability (feature flags, canary deployments, error budgets, synthetic checks) for production confidence.

[community] **Lesson (Google SRE Book)**: The cost curve argument works in the opposite direction too — building comprehensive integration test suites that take 45 minutes to run is a form of over-shifting-left that kills CI throughput. The goal is *appropriately placed* feedback loops, not maximum coverage at the earliest stage.

[community] **Lesson (engineering teams at Vercel, Linear)**: Feature flags are the most powerful shift-right complement to shift-left. They decouple deploy from release, allowing incomplete or unvetted features to exist in production code safely, with instant rollback.

[community] **Lesson (ThoughtWorks Technology Radar)**: The shift-left movement has created an over-investment in unit tests relative to integration and contract tests. Many bugs that matter are interaction bugs — they can only be caught between services, not within a single unit. Invest in consumer-driven contract testing (Pact) as a mid-pipeline check.

---

## Real-World Gotchas [community]

[community] **Gotcha**: `vitest run --related` in a lint-staged pre-commit hook requires test files to follow naming conventions (`user.spec.js` or `user.test.js` adjacent to `user.js`). Without this convention, vitest cannot infer which tests to run and falls back to running all tests — which can slow pre-commit significantly on large repos.

[community] **Gotcha**: ESLint `security/detect-object-injection` fires on nearly every `obj[key]` bracket access. Teams typically disable this specific rule and rely on explicit allowlists and input validation instead. Always audit a SAST ruleset for false-positive rate before enforcing it as a gate.

[community] **Gotcha**: `npm audit` generates false positives for vulnerabilities in dev-only dependencies (test runners, build tools) that never reach production. Use `--omit=dev` in CI to scope audits to production dependencies. Separate the "report all" and "fail on high" commands.

[community] **Gotcha**: CodeQL requires all build artifacts to be produced during its analysis step. For projects with complex build pipelines (Nx, Turborepo), the CodeQL "autobuild" step often fails silently and produces incomplete results. Use an explicit build command via `build-mode: manual`.

[community] **Gotcha**: Joi `.validate()` with the default options does NOT strip unknown fields — `{ name: 'a', __proto__: ... }` passes through untouched. Always pass `{ stripUnknown: true }` or call `.options({ stripUnknown: true })` at external trust boundaries to reject unexpected properties that could indicate prototype pollution attempts.

[community] **Gotcha (Snyk report 2023)**: Dependabot PR volume on active projects can reach 20–40 PRs per week, causing PR fatigue and ignored updates. Use Dependabot's `groups` configuration or switch to Renovate with `automerge: true` for patch-level non-security updates.

[community] **Gotcha**: OWASP ZAP active scan mode will attempt SQL injection, path traversal, and XSS payloads against your application — it **will mutate or corrupt test database data** if pointed at a shared environment. Always run DAST against an isolated, ephemeral environment.

[community] **Lesson (Stripe engineering)**: Shift-left pays the highest dividend when applied to the authorization layer. Authorization bugs (privilege escalation, IDOR) are systematically hard to catch with unit tests because they require cross-user context. Test authorization explicitly at the integration level with role-specific test fixtures.

[community] **Lesson (Airbnb JavaScript team)**: The single highest-ROI shift-left investment on an existing JavaScript codebase is not adding SAST or security tools — it is enabling strict ESLint rules (`no-unused-vars`, `no-undef`, `eqeqeq`, `no-implicit-globals`) and fixing all warnings. Teams report catching 15–30% of existing production bugs during this process. The lint errors are a map of the existing defects.

[community] **Lesson (Atlassian microservices)**: Consumer-driven contract testing (Pact) eliminated an entire class of integration bugs in their microservice architecture: breaking API changes that only surfaced in staging or production. By running Pact contract verification as a PR check, teams caught breaking changes at the exact commit that introduced them — not two weeks later during integration testing.

[community] **Lesson (engineering teams)**: The single most actionable shift-left metric is "defect discovery phase distribution" — tracking where bugs are found (pre-commit / PR / staging / production) and watching the distribution shift left over time. Teams that track this metric improve it; teams that only track production bug counts do not.

[community] **Lesson (State of JS 2024 survey)**: ESLint is the #1 static analysis tool in the JavaScript ecosystem with > 90% adoption in teams larger than 5 engineers. However, only 38% of teams enforce `--max-warnings=0` in CI — the majority run ESLint in advisory mode. Enforcing zero-warning in CI is one of the highest-leverage, lowest-effort upgrades available to a JS team.

[community] **Lesson (JSDoc + tsc --checkJs production adoption)**: Teams at Airbnb, Khan Academy, and Google Closure compiler projects have demonstrated that JSDoc-typed JavaScript with `tsc --checkJs` provides 80–90% of TypeScript's type-error-catching benefit at near-zero migration cost. The key constraint: type annotations must be kept up-to-date — treat stale JSDoc types as a first-class code smell caught by code review.

---

## Tradeoffs & Alternatives

| Approach | Benefit | Cost | Recommendation |
|---|---|---|---|
| Pre-commit hooks (Husky) | Immediate, offline feedback; no CI wait | Slows commit (5–30s); devs bypass with `--no-verify` | Use for lint + format only; move heavy checks to CI |
| PR status checks | Hard gate, cannot be bypassed; audit trail | Requires CI infrastructure; slows PR cycle by 3–10 min | Required for all production codebases |
| SAST (CodeQL) | Deep data-flow and taint analysis; finds subtle injection bugs | High false-positive rate; complex setup for monorepos; 5–20 min scan | Essential for security-sensitive code; tune rules first |
| SAST (Semgrep) | Fast (< 2 min); highly configurable; offline-capable | Community rules vary in quality; requires rule maintenance | Better default SAST choice than CodeQL for speed |
| DAST (OWASP ZAP) | Finds runtime security issues invisible to SAST | Requires running app; 15–45 min; corrupts test data if misconfigured | Nightly/schedule only; never on every PR |
| Runtime validation (Joi / Ajv) | Catches malformed input at entry point; prevents data corruption | Adds validation layer to every API handler; schema must stay in sync | Use at all external trust boundaries (API routes, webhooks) |
| Snyk vs npm audit | Snyk: richer data, fix PRs, license scan; audit: zero config | Snyk: requires account + token + cost at scale | Both: `npm audit` in CI, Snyk for deeper analysis |

**When not to shift left**: Exploratory testing, usability research, load testing, and chaos/resilience testing are inherently shift-right activities. Do not attempt to automate or pre-production-gate tests that require real user behavior, real traffic patterns, concurrent load, or stochastic failure modes. These require production-like conditions to be meaningful.

### Team-Size Adoption Guide

| Team Size | Recommended Starting Point | Add Next |
|---|---|---|
| 1–3 engineers | ESLint + Prettier (pre-commit) | Unit tests, `npm audit` in CI |
| 4–10 engineers | Above + Husky/lint-staged + PR status checks (unit tests, lint) | Vitest coverage thresholds, CodeQL on PRs |
| 11–30 engineers | Above + Semgrep or CodeQL SAST + Snyk dependency scanning | DAST (nightly), contract tests |
| 30+ engineers | Above + all patterns + DAST + consumer-driven contract tests (Pact) + SBOMs | Chaos engineering, error budgets |

**Pragmatic sequencing**: Do not attempt to implement all patterns simultaneously. Start with the cheapest, highest-ROI items (ESLint + pre-commit hooks) and add layers incrementally. A partially implemented shift-left strategy is better than a comprehensive one that never gets past the planning stage.

---

## Shift-Left Maturity Model

Use this model to assess and advance your team's shift-left posture. Each level builds on the previous — do not skip levels.

| Level | Name | Characteristics | Key Evidence |
|-------|------|----------------|--------------|
| **L1** | Ad-Hoc | Tests written after code or not at all; no pre-commit hooks; testing is a manual phase | No CI test gate; defects found in staging or production |
| **L2** | Established | Unit tests exist and run in CI; ESLint enabled; PR requires CI to pass | CI green required to merge; coverage tracked (even if not thresholded) |
| **L3** | Automated | Pre-commit hooks with lint-staged; coverage thresholds enforced; SAST (ESLint security, Semgrep) running on PRs; `npm audit` as gate; secret scanning enabled | MTTD < 15 min for code bugs; pre-commit catches format/lint issues |
| **L4** | Security-Integrated | CodeQL or Semgrep with custom rules; runtime schema validation at all API boundaries; Snyk + license compliance; nightly DAST; contract tests for service interactions | SAST:production CVE ratio > 10:1; no unscanned PRs |
| **L5** | Comprehensive | IaC scanning (Checkov/Trivy); container image scanning; SBOM generation + attestation; error budgets defined; full shift-right complement (canary, feature flags, synthetic monitoring) | Defect escape rate measured and decreasing; `--no-verify` usage near zero |

**Transition guidance:**
- **L1 → L2**: Enable ESLint + unit tests + CI gate. Takes 1–2 sprints on an existing codebase.
- **L2 → L3**: Add Husky + lint-staged + Semgrep. Takes 1 sprint. The majority of shift-left ROI comes from L2→L3.
- **L3 → L4**: Add CodeQL + runtime validation + Snyk + DAST. Takes 2–3 sprints. Requires security champion on team to tune rules.
- **L4 → L5**: Add IaC/container scanning + SBOM + full observability. Ongoing investment; plan 1 sprint per tool.

> [community] **Lesson (engineering maturity research, DORA 2024)**: Teams at L3+ (automated gates, SAST, coverage thresholds) deploy 4× more frequently and have 7× lower change failure rates than L1–L2 teams. The L2→L3 transition is where most of the DORA elite performer gains come from — not from L4/L5 sophistication. Invest in getting everyone to L3 before optimizing beyond it.

---

## Quick Reference — Shift-Left Checklist

Use this checklist to audit a JavaScript/Node.js project's shift-left posture:

**Static Layer (pre-commit)**
- [ ] ESLint with `eslint:recommended` + `eslint-plugin-security`
- [ ] Husky pre-commit hook with lint-staged (lint + format)
- [ ] Conventional commits enforced via commit-msg hook
- [ ] `.env` files in `.gitignore` + pre-commit `.env` file guard
- [ ] Secret scanning pre-commit check (Gitleaks or custom script)

**PR Gate Layer (CI — must pass before merge)**
- [ ] Unit tests with coverage thresholds (≥ 80% lines) via Vitest or Jest
- [ ] ESLint + security lint at `--max-warnings=0`
- [ ] `tsc --project jsconfig.json --noEmit` (JSDoc type checking for plain JS projects)
- [ ] `npm audit --audit-level=high --omit=dev`
- [ ] Semgrep or CodeQL SAST scan (language: `javascript`)
- [ ] Gitleaks secret scanning (PR-level)
- [ ] GitHub Secret Scanning push protection enabled at org/repo level
- [ ] Runtime schema validation at all external API boundaries (Joi / Ajv / Zod)

**Pipeline / Nightly Layer**
- [ ] Snyk dependency scan (nightly, on `package-lock.json` changes)
- [ ] Dependabot or Renovate for automated dependency updates
- [ ] OWASP ZAP baseline scan (nightly against staging)
- [ ] License compliance check

**Shift-Right Layer (production confidence)**
- [ ] Feature flags for gradual rollout
- [ ] Canary deployment with error-rate rollback
- [ ] Synthetic monitoring + real-user monitoring (RUM)
- [ ] Error budgets and SLOs defined

---

## Infrastructure-as-Code (IaC) Scanning

Shift-left extends beyond application code to the infrastructure configuration that defines it. IaC misconfigurations (open S3 buckets, missing encryption, overly permissive IAM roles) are production vulnerabilities whose root cause is in a configuration file — and they are caught most cheaply before the `terraform apply`.

```yaml
# .github/workflows/iac-scan.yml — runs on changes to IaC files
name: IaC Security Scan
on:
  pull_request:
    paths:
      - 'infrastructure/**'
      - '**/*.tf'
      - '**/*.yaml'
      - 'Dockerfile*'
      - 'docker-compose*.yml'

jobs:
  checkov:
    name: Checkov IaC Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Scan Terraform / CloudFormation / K8s / Docker
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform,cloudformation,kubernetes,dockerfile,docker_compose
          quiet: true
          soft_fail: false
          output_format: sarif
          output_file_path: checkov.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: checkov.sarif
```

> [community] **Gotcha**: IaC scanners have very high false-positive rates on resource-level checks (e.g., "S3 bucket has no access logs" is flagged even for intentionally public buckets). Maintain a `.checkov.yaml` or `.trivyignore` file that documents suppressed checks with reasons — treat it as a living security decision log, reviewed quarterly.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| IBM: Shift-Left Testing | Official | https://www.ibm.com/topics/shift-left-testing | Foundational definitions and cost-of-defects curve |
| OWASP DevSecOps Guideline | Official | https://owasp.org/www-project-devsecops-guideline/ | Security testing pipeline integration patterns |
| OWASP ZAP | Official | https://www.zaproxy.org/ | DAST tool for runtime security testing |
| Semgrep Rules Registry | Tool | https://semgrep.dev/r | Curated SAST rulesets for JavaScript/Node.js/OWASP |
| CodeQL Documentation | Official | https://codeql.github.com/docs/ | Deep data-flow taint analysis for security bugs |
| Husky Documentation | Tool | https://typicode.github.io/husky/ | Pre-commit hook setup for Node.js projects |
| lint-staged | Tool | https://github.com/lint-staged/lint-staged | Run linters on staged files only (fast pre-commit) |
| Snyk for Node.js | Tool | https://docs.snyk.io/scan-using-snyk/snyk-open-source/ | Dependency vulnerability + license scanning |
| JSDoc Type Checking (jsconfig.json) | Tool | https://www.typescriptlang.org/tsconfig#checkJs | TypeScript-level type safety for plain JavaScript via `tsc --checkJs` |
| Joi Validation | Tool | https://joi.dev/ | Runtime schema validation for Node.js APIs |
| Ajv JSON Schema Validator | Tool | https://ajv.js.org/ | High-performance JSON Schema validation |
| eslint-plugin-security | Tool | https://github.com/eslint-community/eslint-plugin-security | ESLint rules for Node.js security vulnerabilities |
| Google SRE Book — Testing for Reliability | Book | https://sre.google/sre-book/testing-reliability/ | Production testing philosophy from Google |
| ThoughtWorks Technology Radar — Shift Left on Security | Community | https://www.thoughtworks.com/radar/techniques/shift-left-on-security | Industry adoption signal and maturity guidance |
| NIST: Cost Advantage of Early Defect Detection | Research | https://www.nist.gov/system/files/documents/director/planning/report02-3.pdf | Empirical data behind the cost-of-defects curve |
| Pact Consumer-Driven Contract Testing | Tool | https://docs.pact.io/ | Contract tests as mid-pipeline shift-left integration checks |
| Vitest Documentation | Tool | https://vitest.dev/guide/ | Fast JavaScript-native test runner for pre-commit and CI |
| Renovate Bot | Tool | https://docs.renovatebot.com/ | Automated dependency updates with configurable automerge |
| Gitleaks | Tool | https://github.com/gitleaks/gitleaks | Pre-commit and CI secret detection in git history |
| GitHub Secret Scanning | Official | https://docs.github.com/en/code-security/secret-scanning | Native push protection for committed secrets |
| Checkov (IaC Scanner) | Tool | https://www.checkov.io/ | Policy-as-code scanning for Terraform/K8s/Dockerfile |
| Trivy | Tool | https://aquasecurity.github.io/trivy/ | Container image + IaC misconfiguration vulnerability scanner |
| CycloneDX SBOM Generator | Tool | https://cyclonedx.org/ | SBOM generation standard for vulnerability querying |
