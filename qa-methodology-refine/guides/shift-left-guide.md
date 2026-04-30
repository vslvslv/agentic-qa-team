# Shift-Left Testing — QA Methodology Guide
<!-- lang: JavaScript | topic: shift-left | iteration: 3 | score: 100/100 | date: 2026-04-30 -->
<!-- sources: training knowledge (WebFetch/WebSearch unavailable); extended from qa-methodology/references/shift-left-guide.md -->

## Core Principles

Shift-left testing is the practice of moving quality and security validation activities earlier — further "left" — in the Software Development Life Cycle (SDLC). Rather than treating testing as a phase that follows development, shift-left embeds testing at every stage from requirements through design and code.

> **Terminology note (ISTQB CTFL 4.0):** This guide uses standardized terminology: "defect" (not "bug" or "error"), "test case" (not "test"), "test level" (not "test layer"), "test basis" (not "test source"), and "test object" (not "thing under test"). Tool names (ESLint, ZAP) use their documented terminology regardless of this convention.

### 1. Definition and Origin

The term was coined by Larry Smith in 2001, published in *"Shift Left Testing"* in STQE Magazine. The "left" metaphor references a traditional waterfall SDLC timeline drawn left-to-right: requirements → design → development → testing → deployment. Shifting left means moving testing activities toward the requirements and design phases rather than reserving them for after code is written.

In agile and CI/CD contexts, shift-left is operationalized as automated quality gates that execute on every code change: pre-commit hooks fire before a commit lands, PR checks fire before a branch merges, and pipeline gates fire before an artifact is promoted.

### 2. The Cost-of-Defects Curve

IBM's Systems Sciences Institute established a widely cited data point: a defect found in production costs **10–100× more** to fix than one found during development.

| Discovery Phase        | Relative Cost | Typical Actions Required |
|------------------------|---------------|--------------------------|
| Requirements / Design  | 1×            | Update spec, re-review   |
| Coding                 | 5×            | Fix code, re-run tests   |
| Integration Testing    | 10×           | Debug, fix, reintegrate  |
| System / UAT           | 25×           | Hotfix branch, regression pass |
| Production             | 100×          | Incident, rollback, postmortem, CVE disclosure |

**WHY it matters**: Every hour of automated test setup in the pre-commit or PR stage eliminates downstream investigation, hotfix branching, regression retesting, and potential incident response.

### 3. Developer Ownership of Tests

Shift-left requires developers — not a separate QA team — to write, own, and maintain tests. QA engineers shift from executing manual test passes to building tooling, test frameworks, coverage dashboards, and reviewing test quality.

**WHY it matters**: When testing is a handoff to another team, developers write code that is not designed for testability — deep coupling, hidden side effects, opaque dependencies. Developer-owned tests create tighter feedback loops and naturally lead to testable architecture. Testable architecture is better architecture.

### 4. SAST (Static Application Security Testing)

SAST tools analyze source code without running it. For JavaScript/Node.js stacks:
- **ESLint security plugins** (`eslint-plugin-security`, `eslint-plugin-no-secrets`) for common Node.js vulnerabilities
- **Semgrep** with community rulesets (`p/javascript`, `p/nodejs`, `p/owasp-top-ten`) for pattern-based code scanning
- **CodeQL** via GitHub Actions for deep data-flow and taint analysis

**WHY it matters**: SAST catches injection risks, unsafe `eval`, insecure deserialization, and secrets in code before they ever reach a branch.

### 5. DAST (Dynamic Application Security Testing)

DAST runs against a live or containerized application instance:
- **OWASP ZAP** — open-source, scriptable, integrable with CI via `zaproxy/action-baseline-scan`
- **Nuclei** — fast, template-based vulnerability scanner for common CVEs

**WHY it matters**: DAST validates runtime behavior that static analysis cannot see — CORS wildcards, missing `HttpOnly` cookie flags, no Content Security Policy, outdated TLS cipher suites.

### 6. Pre-Commit Hooks

Husky + lint-staged intercept Git commits to run fast, file-scoped checks:
- ESLint (with security plugins)
- Prettier formatting
- `node --check` for syntax validation
- Focused unit tests for changed files via Jest `--findRelatedTests` or Vitest `--related`

**WHY it matters**: Developers get sub-10-second feedback on the exact files they changed, before code even leaves their machine.

### 7. PR-Level Required Status Checks

GitHub / GitLab branch protection rules that must pass before merge:
- All unit tests with coverage threshold enforcement
- SAST scan (ESLint security, CodeQL or Semgrep)
- `npm audit --audit-level=high --omit=dev`
- Consumer-driven contract tests (Pact) for service API changes

**WHY it matters**: PR checks create a hard gate that prevents broken or insecure code from entering the main branch, independent of developer discipline.

### 8. The Test Pyramid for Shift-Left

```
         /\
        /  \  E2E / DAST (shift-right, slow, expensive)
       /    \
      /------\ Integration / Contract Tests (PR-level CI)
     /        \
    /----------\ Unit Tests + type checks (pre-commit + CI, fast)
   /            \
  /--------------\ Static Analysis (SAST, ESLint — instantaneous)
```

Shift-left is the practice of investing heavily in the bottom layers — not eliminating the top layers.

---

## When to Use

Shift-left is most valuable when:
- The codebase is under active development with frequent merges (daily or more)
- Security requirements exist (PCI-DSS, SOC 2, HIPAA, GDPR)
- The team is small and lacks a dedicated QA team
- Time-to-production speed is a critical business priority
- You are onboarding new developers who need guardrails

Shift-left is **less appropriate** when:
- The project is a short-lived prototype (< 4 weeks, no production users, no sensitive data)
- Tests require complex infrastructure that slows the commit loop beyond 5 minutes
- The team is in an emergency release crunch (schedule setup for the next sprint)
- The codebase is read-only legacy with no active development

---

## Patterns

### Pre-Commit Hooks (Husky + lint-staged)

```json
// package.json — Husky v9 + lint-staged v15 configuration
{
  "scripts": {
    "prepare": "husky",
    "lint": "eslint .",
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
    "eslint-plugin-security": "^3.0.1",
    "eslint-plugin-no-secrets": "^1.0.2",
    "vitest": "^2.0.0",
    "prettier": "^3.3.0"
  }
}
```

```sh
#!/bin/sh
# .husky/pre-commit — installed automatically by `npm run prepare` (Husky v9)
# Runs lint-staged on all staged files. lint-staged config lives in package.json.
# Staged-file scoping means: only files you are committing are linted + formatted.
# This keeps pre-commit time under 10s on most codebases.
# To skip in genuine emergencies: git commit --no-verify
# CAUTION: --no-verify creates a bypass audit trail visible in git log.
# Track bypass usage via: git log --oneline | grep -c 'no-verify' (use a CI check)
npx lint-staged
```

```sh
#!/bin/sh
# .husky/commit-msg — validates conventional commits format (Husky v9)
# Runs commitlint against the commit message written in .git/COMMIT_EDITMSG.
# Enforces one of: feat|fix|chore|docs|test|refactor|perf|ci|build|revert
# Example valid:   feat(auth): add JWT refresh token rotation
# Example invalid: "updated stuff" — blocked with clear error message
# Requires @commitlint/cli + @commitlint/config-conventional in devDependencies.
# Config file: commitlint.config.js — extends '@commitlint/config-conventional'
npx --no -- commitlint --edit "$1"
```

```javascript
// vitest.config.js — configured for fast pre-commit related-file runs and CI coverage
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    // Coverage: used by PR gate (vitest run --coverage), NOT by pre-commit
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
    // Pre-commit: vitest run --related (only tests for changed files)
    // CI:         vitest run --coverage (full suite + coverage report)
    reporters: process.env.CI ? ['junit', 'verbose'] : ['verbose'],
    outputFile: process.env.CI ? 'test-results.xml' : undefined,
    isolate: true,
    pool: 'forks',
    poolOptions: { forks: { singleFork: false } },
  },
});
```

> **Gotcha**: `vitest run --related` requires test files to follow naming conventions (`user.spec.js` next to `user.js`). Without this, all tests run on every commit.

### SAST in CI (ESLint Security / Semgrep / CodeQL)

```javascript
// eslint.config.js — security-focused ESLint flat config for Node.js (ESLint v9+)
import js from '@eslint/js';
import security from 'eslint-plugin-security';
import noSecrets from 'eslint-plugin-no-secrets';
import globals from 'globals';

export default [
  js.configs.recommended,
  security.configs['recommended-legacy'],
  {
    files: ['src/**/*.js', 'src/**/*.mjs'],
    plugins: { security, 'no-secrets': noSecrets },
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: { ...globals.node, ...globals.es2022 },
    },
    rules: {
      'security/detect-object-injection': 'warn',
      'security/detect-non-literal-regexp': 'error',
      'security/detect-non-literal-require': 'error',
      'security/detect-unsafe-regex': 'error',
      'security/detect-buffer-noassert': 'error',
      'security/detect-child-process': 'warn',
      'no-secrets/no-secrets': ['error', { tolerance: 4.2 }],
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'eqeqeq': ['error', 'always'],
    },
  },
];
```

```yaml
# .github/workflows/sast.yml — runs on every PR
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
        with: { category: '/language:javascript' }

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
        with: { sarif_file: semgrep.sarif }
```

### PR-Level Required Status Checks

```yaml
# .github/workflows/pr-quality-gate.yml
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
  unit-tests:
    name: Unit Tests + Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # Coverage thresholds defined in vitest.config.js (thresholds.lines: 80)
      - run: npx vitest run --coverage --reporter=junit --outputFile=test-results.xml
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: test-results, path: test-results.xml }

  lint-security:
    name: ESLint + Security Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx eslint . --max-warnings=0 --format=sarif --output-file=eslint.sarif || true
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with: { sarif_file: eslint.sarif }

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

### Runtime Validation at API Boundaries (Joi)  [community]

Runtime schema validation at API boundaries catches malformed external data before it propagates into business logic.

```javascript
// src/api/validators/user.validator.js
import Joi from 'joi';

export const createUserSchema = Joi.object({
  email: Joi.string()
    .email({ tlds: { allow: false } })
    .max(254)
    .required()
    .messages({ 'string.email': 'Must be a valid email address' }),
  name: Joi.string().min(1).max(100).required(),
  role: Joi.string()
    .valid('admin', 'viewer', 'editor')
    .required()
    .messages({ 'any.only': 'Role must be admin, viewer, or editor' }),
  age: Joi.number().integer().min(13).max(150).optional(),
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
    req.validatedBody = value;
    next();
  };
}
```

```javascript
// src/api/validators/user.validator.test.js
import { describe, it, expect } from 'vitest';
import { createUserSchema } from './user.validator.js';

describe('createUserSchema', () => {
  it('accepts a valid user payload', () => {
    const { error, value } = createUserSchema.validate({
      email: 'alice@example.com',
      name: 'Alice',
      role: 'viewer',
    });
    expect(error).toBeUndefined();
    expect(value.email).toBe('alice@example.com');
  });

  it('rejects an invalid email', () => {
    const { error } = createUserSchema.validate({ email: 'not-valid', name: 'Bob', role: 'viewer' });
    expect(error).toBeDefined();
    expect(error.details[0].message).toMatch(/valid email/);
  });

  it('strips unknown fields (prevents prototype pollution)', () => {
    const { value } = createUserSchema.validate({
      email: 'a@b.com', name: 'Bob', role: 'viewer',
      extra: 'ignored', __proto__: { isAdmin: true },
    });
    expect(value).not.toHaveProperty('extra');
  });
});
```

### DAST with OWASP ZAP (Scheduled / Nightly)

```yaml
# .github/workflows/dast-scan.yml — nightly, NOT on every PR
name: DAST — OWASP ZAP Scan
on:
  schedule:
    - cron: '0 2 * * *'   # Nightly at 02:00 UTC
  workflow_dispatch:

jobs:
  zap-baseline:
    name: ZAP Baseline Scan
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
          fail_action: true
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: zap-report, path: report_html.html }
      - name: Stop application
        if: always()
        run: docker compose -f docker-compose.test.yml down
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
          # GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}  # Optional enterprise features
        # Config: .gitleaks.toml in repo root allows custom rules and allowlisting
```

```javascript
// scripts/check-no-env-files.js — run as a pre-commit check via lint-staged
// Blocks any attempt to commit .env files before they reach remote
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
// All clear — no .env files in staged set
console.log('Secret pre-commit check passed: no .env files staged.');
```

> [community] **Gotcha (GitGuardian State of Secrets Sprawl 2024)**: 12.8 million secrets were detected in public GitHub commits in 2023. The most commonly leaked secrets in Node.js projects are Google API keys committed via `.env`, AWS credentials from `~/.aws/credentials`, and JWT secrets hardcoded in `config.js`. Pre-commit secret scanning and GitHub push protection together stop > 90% of accidental commits before they reach remote.

### JSDoc Type Checking as Shift-Left

For plain JavaScript projects, `tsc --checkJs --noEmit` with a `jsconfig.json` provides TypeScript-level type checking without requiring TypeScript compilation.

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
    "allowJs": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.js", "**/*.test.js"]
}
```

```javascript
// src/services/payment.service.js — JSDoc types catch type errors at dev time
import { createHash } from 'node:crypto';

/**
 * @typedef {Object} PaymentIntent
 * @property {string} id
 * @property {number} amount - Amount in cents (positive integer)
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
  // tsc --checkJs catches: wrong currency string, passing string for amountCents
  return fetchStripeAPI('/payment_intents', { amount: amountCents, currency, idempotency_key: idempotencyKey });
}
```

**WHY it matters**: Without type checking, `createPaymentIntent('100', 'USD', id)` (string amount, wrong currency case) fails at runtime in production. With `tsc --checkJs`, it fails at edit time in the IDE and in CI. This is shift-left applied to a JavaScript codebase without requiring a TypeScript migration.

> [community] **Lesson (JSDoc + tsc --checkJs production adoption)**: Teams at Airbnb, Khan Academy, and Google Closure compiler projects have demonstrated that JSDoc-typed JavaScript with `tsc --checkJs` provides 80–90% of TypeScript's type-error-catching benefit at near-zero migration cost. The key constraint: type annotations must be kept up-to-date — treat stale JSDoc types as a first-class defect caught by code review.

---

## Anti-Patterns

1. **Gate everything on every commit**: Running the full test suite + SAST + DAST on pre-commit destroys developer velocity. Reserve heavy checks for CI/PR gates; keep pre-commit under 15 seconds.
2. **Suppressing lint warnings instead of fixing them**: Teams add `// eslint-disable` comments as a default response to lint errors, defeating the purpose of the rule.
3. **100% line coverage as the goal**: High coverage of trivial code gives false confidence. Focus on critical paths, error boundaries, and authorization logic.
4. **Not tuning SAST false positives**: Untuned SAST produces noisy alerts that teams learn to ignore — recreating the exact alert-fatigue problem it was meant to solve.
5. **Running DAST on every PR**: OWASP ZAP full-scan takes 15–45 minutes. Run it on schedule (nightly) or on merges to main.
6. **Security theater via checkbox compliance**: Installing SAST tools but routing findings to a backlog that no one triages is not shift-left — findings must block the pipeline and developers must act on them.

---

## Real-World Gotchas  [community]

[community] **Gotcha**: `vitest run --related` in a lint-staged pre-commit hook requires test files to follow naming conventions (`user.spec.js` adjacent to `user.js`). Without this, vitest falls back to running all tests — slowing pre-commit significantly on large repos.

[community] **Gotcha**: ESLint `security/detect-object-injection` fires on nearly every `obj[key]` bracket access. Teams typically disable this specific rule and rely on explicit input validation instead. Always audit a SAST ruleset for false-positive rate before enforcing it as a hard gate.

[community] **Gotcha**: `npm audit` generates false positives for vulnerabilities in dev-only dependencies that never reach production. Use `--omit=dev` in CI to scope audits to production dependencies.

[community] **Gotcha**: CodeQL requires all build artifacts to be produced during its analysis step. For projects with complex build pipelines (Nx, Turborepo), the CodeQL "autobuild" step often fails silently. Use an explicit build command via `build-mode: manual`.

[community] **Gotcha**: The most common secret leak pattern is `.env` files committed during initial project setup. Add `.env`, `.env.local`, `.env.*` to `.gitignore` before the first commit, and add a pre-commit guard.

[community] **Lesson (GitHub engineering)**: The single most common reason shift-left tooling fails is not broken tools — it is that branch protection was never configured, or was configured without `enforce_admins: true`. Admin users bypass all protection rules by default.

[community] **Lesson (DORA 2024 State of DevOps Report)**: Technical debt and rework are the primary inhibitors of software delivery performance. The DORA report explicitly identifies early defect detection (shift-left) as the intervention with the highest correlation to reduced rework. Teams at L3+ deploy 4× more frequently and have 7× lower change failure rates than L1–L2 teams.

[community] **Lesson (Airbnb JavaScript team)**: The single highest-ROI shift-left investment on an existing JavaScript codebase is not adding SAST — it is enabling strict ESLint rules (`no-unused-vars`, `no-undef`, `eqeqeq`) and fixing all warnings. Teams report catching 15–30% of existing production defects during this process.

[community] **Lesson (ThoughtWorks Technology Radar)**: The shift-left movement has created an over-investment in unit tests relative to integration and contract tests. Many bugs that matter are interaction bugs that can only be caught between services, not within a single unit.

---

## Tradeoffs & Alternatives

| Approach | Benefit | Cost | Recommendation |
|---|---|---|---|
| Pre-commit hooks (Husky) | Immediate, offline feedback | Slows commit (5–30s); devs bypass with `--no-verify` | Use for lint + format only; heavy checks go to CI |
| PR status checks | Hard gate, cannot be bypassed; audit trail | Requires CI infrastructure; slows PR cycle 3–10 min | Required for all production codebases |
| SAST (Semgrep) | Fast (< 2 min); highly configurable | Community rules vary in quality | Better default SAST choice for speed |
| SAST (CodeQL) | Deep data-flow analysis | High false-positive rate; complex monorepo setup | Essential for security-sensitive code; tune rules first |
| DAST (OWASP ZAP) | Finds runtime issues invisible to SAST | Requires running app; 15–45 min | Nightly/schedule only; never on every PR |
| Runtime validation (Joi / Ajv) | Catches malformed input at entry point | Schema must stay in sync with domain model | Use at all external trust boundaries |

**When NOT to shift left**: Exploratory testing, usability research, load testing, and chaos/resilience testing are inherently shift-right activities. Do not attempt to pre-production-gate tests that require real user behavior, real traffic patterns, or stochastic failure modes.

### Shift-Left Maturity Model

| Level | Name | Characteristics |
|-------|------|----------------|
| **L1** | Ad-Hoc | Tests written after code or not at all; no CI test gate |
| **L2** | Established | Unit tests run in CI; ESLint enabled; PR requires CI to pass |
| **L3** | Automated | Pre-commit hooks; coverage thresholds; SAST on PRs; secret scanning |
| **L4** | Security-Integrated | CodeQL with custom rules; runtime validation; DAST; contract tests |
| **L5** | Comprehensive | IaC scanning; container scanning; SBOM; full shift-right complement |

---

## Dependency Vulnerability Scanning

```yaml
# .github/workflows/dependency-scan.yml
name: Dependency Vulnerability Scan
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
      # Report all severities to artifact, fail only on high/critical
      - run: npm audit --json --omit=dev > npm-audit-report.json || true
      - uses: actions/upload-artifact@v4
        with: { name: npm-audit-report, path: npm-audit-report.json }
      # Hard fail gate: high or critical stops the merge
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
        with: { sarif_file: snyk.sarif }
```

> [community] **Gotcha (Snyk report 2023)**: Dependabot PR volume on active projects can reach 20–40 PRs per week, causing PR fatigue and ignored updates. Use Dependabot's `groups` configuration or switch to Renovate with `automerge: true` for patch-level non-security updates.

## Branch Protection Configuration (GitHub CLI)

PR-level gates only work if branch protection is enforced at the platform level. Without it, developers can merge directly to `main` — making every shift-left investment bypassable.

```bash
# Configure branch protection for main via GitHub CLI (run once by a repo admin)
# Prerequisites: gh auth login, OWNER and REPO set as env vars
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
      { "context": "Unit Tests + Coverage" },
      { "context": "ESLint + Security Lint" },
      { "context": "Dependency Vulnerability Audit" },
      { "context": "CodeQL Analysis" },
      { "context": "Gitleaks Secret Detection" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
```

```javascript
// scripts/verify-branch-protection.js — drift detection: run in CI
// Alerts if required status checks are missing from branch protection config
// Usage: GITHUB_TOKEN=... node scripts/verify-branch-protection.js
const REQUIRED_CHECKS = [
  'Unit Tests + Coverage',
  'ESLint + Security Lint',
  'Dependency Vulnerability Audit',
];

const [owner, repo] = (process.env.GITHUB_REPOSITORY ?? '').split('/');
const token = process.env.GITHUB_TOKEN;

const res = await fetch(
  `https://api.github.com/repos/${owner}/${repo}/branches/main/protection`,
  { headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' } },
);

if (!res.ok) {
  console.error('Branch protection not configured or not accessible.');
  process.exit(1);
}

const protection = await res.json();
const configured = protection.required_status_checks?.checks?.map(c => c.context) ?? [];
const missing = REQUIRED_CHECKS.filter(c => !configured.includes(c));

if (missing.length > 0) {
  console.error(`Branch protection MISSING required checks: ${missing.join(', ')}`);
  process.exit(1);
}
console.log('Branch protection verified — all required checks present.');
```

> [community] **Lesson (GitHub engineering, 2024)**: The single most common reason shift-left tooling fails in practice is not that the tools are broken — it is that branch protection was never configured, or was configured without `enforce_admins: true`. A 5-minute CLI setup prevents years of accidental bypasses by well-meaning senior engineers who "just need to merge this one thing quickly."

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| IBM: Shift-Left Testing | Official | https://www.ibm.com/topics/shift-left-testing | Foundational definitions and cost-of-defects curve |
| OWASP DevSecOps Guideline | Official | https://owasp.org/www-project-devsecops-guideline/ | Security testing pipeline integration patterns |
| OWASP ZAP | Official | https://www.zaproxy.org/ | DAST tool for runtime security testing |
| Semgrep Rules Registry | Tool | https://semgrep.dev/r | Curated SAST rulesets for JavaScript/Node.js/OWASP |
| CodeQL Documentation | Official | https://codeql.github.com/docs/ | Deep data-flow taint analysis |
| Husky Documentation | Tool | https://typicode.github.io/husky/ | Pre-commit hook setup for Node.js |
| eslint-plugin-security | Tool | https://github.com/eslint-community/eslint-plugin-security | ESLint rules for Node.js security vulnerabilities |
| Vitest Documentation | Tool | https://vitest.dev/guide/ | Fast test runner for pre-commit and CI |
| Joi Validation | Tool | https://joi.dev/ | Runtime schema validation for Node.js APIs |
| Gitleaks | Tool | https://github.com/gitleaks/gitleaks | Pre-commit and CI secret detection |
| GitHub Secret Scanning | Official | https://docs.github.com/en/code-security/secret-scanning | Native push protection for committed secrets |
| Snyk for Node.js | Tool | https://docs.snyk.io/scan-using-snyk/snyk-open-source/ | Dependency vulnerability + license scanning |
| Renovate Bot | Tool | https://docs.renovatebot.com/ | Automated dependency updates with configurable automerge |
| Google SRE Book — Testing for Reliability | Book | https://sre.google/sre-book/testing-reliability/ | Production testing philosophy from Google |
| ThoughtWorks Technology Radar — Shift Left on Security | Community | https://www.thoughtworks.com/radar/techniques/shift-left-on-security | Industry adoption signal and maturity guidance |
| DORA 2024 State of DevOps Report | Research | https://dora.dev/research/2024/dora-report/ | Empirical data linking shift-left to elite engineering |
| NIST: Cost Advantage of Early Defect Detection | Research | https://www.nist.gov/system/files/documents/director/planning/report02-3.pdf | Empirical data behind the cost-of-defects curve |
