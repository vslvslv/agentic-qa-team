# Shift-Left Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: shift-left | iteration: 10 | score: 97/100 | date: 2026-04-26 -->

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
      /----------\ Unit Tests + Type Checks (pre-commit + CI, fast)
     /            \
    /--------------\ Static Analysis (SAST, lint, type checking — instantaneous)
```

- **Static analysis** (ESLint, TypeScript compiler): runs in milliseconds, no infrastructure, catches whole categories of bugs
- **Unit tests**: run in seconds, no external dependencies, verify logic in isolation
- **Integration / contract tests**: run in minutes, require services, verify interactions
- **E2E / DAST**: run in tens of minutes, require full deployment, verify end-to-end user flows and runtime security

Shift-left is the practice of **investing heavily in the bottom layers** — not eliminating the top layers.

### 4. SAST (Static Application Security Testing)
SAST tools analyze source code without running it. For TypeScript/Node.js stacks:
- **ESLint security plugins** (`eslint-plugin-security`, `eslint-plugin-no-secrets`) for common Node.js vulnerabilities
- **Semgrep** with community rulesets (`p/typescript`, `p/nodejs`, `p/owasp-top-ten`) for pattern-based code scanning
- **CodeQL** via GitHub Actions for deep data-flow and taint analysis

**WHY it matters**: SAST catches injection risks, unsafe `eval`, insecure deserialization, and secrets in code before they ever reach a branch. The earlier a security flaw is found, the simpler the fix — no CVE, no incident response, no customer notification required.

### 5. DAST (Dynamic Application Security Testing)
DAST runs against a live or containerized application instance:
- **OWASP ZAP** — open-source, scriptable, integrable with CI via `zaproxy/action-full-scan` or `zaproxy/action-baseline-scan`
- **Nuclei** — fast, template-based vulnerability scanner for common CVEs and misconfigurations
- Targets: XSS, CSRF, open redirects, broken auth headers, missing security headers (CSP, HSTS, X-Frame-Options)

**WHY it matters**: DAST validates runtime behavior that static analysis cannot see. A TypeScript application can pass every SAST check and still ship with: an insecure CORS wildcard (`Access-Control-Allow-Origin: *`), missing `HttpOnly` cookie flags, no Content Security Policy, or an outdated TLS cipher suite. DAST is the only automated mechanism that catches configuration-level vulnerabilities that live outside the codebase entirely — in web server config, reverse proxy headers, or infrastructure-as-code.

### 6. Pre-Commit Hooks
Husky + lint-staged intercept Git commits to run fast, file-scoped checks:
- TypeScript type checking (`tsc --noEmit --incremental`)
- ESLint (with security plugins)
- Prettier formatting
- Focused unit tests for changed files via vitest `--related`

**WHY it matters**: Developers get sub-10-second feedback on the exact files they changed, before code even leaves their machine. The feedback loop shrinks from "wait for CI" (minutes) to "before you commit" (seconds).

### 7. PR-Level Required Status Checks
GitHub / GitLab branch protection rules that must pass before merge:
- Full TypeScript type check (`tsc --noEmit`)
- All unit tests with coverage threshold enforcement
- SAST scan (ESLint security, CodeQL or Semgrep)
- `npm audit --audit-level=high --omit=dev` and/or Snyk scan
- Consumer-driven contract tests (Pact) for service API changes

**WHY it matters**: PR checks create a hard gate that prevents broken or insecure code from entering the main branch, independent of developer discipline or reviewer oversight. They are not bypassable without admin intervention (which creates an audit trail). Unlike pre-commit hooks (which developers can skip with `--no-verify`), PR status checks are enforced by the platform. They also surface issues to code reviewers contextually — a failing SAST check in the PR diff is immediately actionable.

**Contract testing note**: Consumer-driven contract tests (e.g., Pact for TypeScript) are particularly valuable at the PR level for microservice architectures. They verify that an API change in Service A does not break the contracts expected by consumers B and C — without requiring those services to be deployed. This is shift-left applied to integration testing.

### 8. Shift-Right Counterpart
Shift-right testing validates quality in or near production:
- **Feature flags** (LaunchDarkly, Unleash, Flagsmith) for gradual user-segment rollout
- **Canary deployments** (Argo Rollouts, Flagger, Spinnaker) with automated error-rate rollback
- **Synthetic monitoring** (Datadog Synthetics, Checkly, Pingdom) — automated browser flows against production
- **Real-user monitoring** (RUM via Datadog, New Relic, Sentry) — captures real performance and JS errors
- **Chaos engineering** (Gremlin, AWS Fault Injection Simulator) for resilience validation

Shift-left and shift-right are **complementary**, not competing strategies. A well-run engineering org has both: shift-left for fast feedback on correctness, shift-right for confidence that the system behaves as intended when real users, real data, and real infrastructure interact.

**WHY the counterpart matters**: Production is the only environment that has real data, real traffic distributions, real infrastructure failures, and real user behavior. Even the best-tested code can fail in production due to conditions that no pre-production test can replicate — network partitions, data skew, third-party API degradations, or concurrent user patterns that only appear at scale.

### 9. Type Safety as Shift-Left
TypeScript strict mode and runtime schema validation constitute a form of shift-left:
- `strict: true` in `tsconfig.json` catches null dereferences, implicit any, and incorrect function signatures at compile time
- `noUncheckedIndexedAccess: true` ensures array access returns `T | undefined`, preventing silent index-out-of-bounds
- **Zod** schema validation at API boundaries catches malformed external data before it propagates into business logic

**WHY it matters**: Type errors are caught by the compiler or at the first entry point rather than surfacing as `Cannot read properties of undefined` runtime exceptions in production — or worse, as data corruption from silently accepting the wrong type.

### 10. Dependency Vulnerability Scanning
- `npm audit` — built-in, runs in CI, reports CVEs from the npm advisory database
- **Snyk** — more granular than `npm audit`, provides fix advice, tracks license compliance
- **Dependabot** (GitHub) or **Renovate** — auto-creates PRs to update vulnerable dependencies on a schedule

**WHY it matters**: Third-party packages are the largest attack surface in modern Node.js applications. The average enterprise Node.js project has 500–1,000 transitive dependencies, most of which the team has never reviewed. Automated scanning stops known CVEs from shipping without requiring manual audits. The Log4Shell (CVE-2021-44228) and event-stream incidents are canonical examples of transitive dependency vulnerabilities that automated scanning would have flagged before deployment.

---

## When to Use

Shift-left is most valuable when:
- The codebase is under active development with frequent merges (daily or more)
- Security requirements exist (PCI-DSS, SOC 2 Type II, HIPAA, GDPR) or you are working toward a compliance certification
- The team is small and lacks a dedicated QA team — shift-left is how small teams maintain quality without a QA headcount
- Time-to-production speed is a critical business priority and you cannot afford long manual QA cycles
- You are onboarding new developers who need guardrails that catch mistakes early
- The product has a public API or processes sensitive user data
- You are migrating a JavaScript codebase to TypeScript — shift-left tooling (strict mode, lint) surfaces existing bugs during migration

Shift-left is **less appropriate** (or should be scoped carefully) when:
- The project is a short-lived prototype (< 4 weeks, no production users, no sensitive data): focus on delivering and add shift-left when it graduates to a real product
- Tests require complex infrastructure spin-up (databases, message queues, external APIs) that slows the commit loop beyond 5 minutes — isolate infrastructure tests to the CI layer only
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
    "typecheck": "tsc --noEmit --incremental",
    "lint": "eslint . --ext .ts,.tsx --max-warnings=0",
    "test:related": "vitest run --related"
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix --max-warnings=0",
      "prettier --write"
    ],
    "*.ts": [
      "bash -c 'tsc --noEmit --incremental 2>&1 | head -20'"
    ],
    "*.{ts,tsx,spec.ts}": [
      "vitest run --related --reporter=verbose"
    ]
  },
  "devDependencies": {
    "husky": "^9.1.0",
    "lint-staged": "^15.2.0",
    "@typescript-eslint/eslint-plugin": "^7.18.0",
    "@typescript-eslint/parser": "^7.18.0",
    "eslint-plugin-security": "^3.0.1",
    "eslint-plugin-no-secrets": "^1.0.2",
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

```typescript
// vitest.config.ts — configured for fast pre-commit related-file runs
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
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.spec.ts', 'src/**/*.d.ts', 'src/index.ts'],
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

> **Gotcha**: `tsc --noEmit` in a lint-staged hook runs the full compiler on every changed file. On a large monorepo this can take 30+ seconds, causing developers to use `--no-verify`. Use `--incremental` for faster subsequent runs, or scope to project references with `tsc -b --noEmit`.

### SAST in CI (ESLint Security / Semgrep / CodeQL)

```json
// .eslintrc.json — security-focused ESLint configuration for TypeScript
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "./tsconfig.json",
    "ecmaVersion": 2022,
    "sourceType": "module"
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended-type-checked",
    "plugin:security/recommended-legacy"
  ],
  "plugins": ["@typescript-eslint", "security", "no-secrets"],
  "rules": {
    "security/detect-object-injection": "warn",
    "security/detect-non-literal-regexp": "error",
    "security/detect-non-literal-require": "error",
    "security/detect-possible-timing-attacks": "error",
    "security/detect-unsafe-regex": "error",
    "security/detect-buffer-noassert": "error",
    "security/detect-child-process": "warn",
    "no-secrets/no-secrets": ["error", { "tolerance": 4.2 }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-call": "error",
    "@typescript-eslint/no-unsafe-return": "error",
    "no-eval": "error",
    "no-implied-eval": "error"
  }
}
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
          languages: javascript-typescript
          queries: security-and-quality
      - run: npm ci
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

  github-secret-scanning:
    # GitHub's native secret scanning runs automatically for all public repos
    # and GitHub Advanced Security private repos — no workflow needed.
    # Enable in: Settings → Code security → Secret scanning → Push protection
    # Push protection BLOCKS the push before the secret reaches remote.
    name: GitHub Push Protection (informational)
    runs-on: ubuntu-latest
    steps:
      - run: echo "GitHub Secret Scanning push protection is enabled at the org level."
```

```toml
# .gitleaks.toml — custom rules for project-specific secret patterns
[extend]
# Extend the default ruleset
useDefault = true

[[rules]]
id = "custom-internal-api-key"
description = "Internal API key pattern"
regex = '''MYAPP_[A-Z0-9]{32}'''
tags = ["internal", "api-key"]

[allowlist]
  description = "Allowed patterns (test fixtures, example values)"
  regexes = [
    '''EXAMPLE_KEY_[A-Z]{8}''',           # Placeholder values in docs
    '''test-secret-[a-z]{6}''',            # Test fixture tokens
  ]
  paths = [
    '''tests/fixtures/.*''',
    '''docs/examples/.*''',
  ]
  commits = [
    "abc123def456",   # Historical commit with false positive, cannot be rewritten
  ]
```

> [community] **Gotcha**: The most common secret leak pattern is `.env` files committed during initial project setup. Add `.env`, `.env.local`, `.env.*` to `.gitignore` before the first commit, and add a pre-commit check that rejects any file matching `^\.env`:

```typescript
// scripts/check-no-env-files.ts — run as a pre-commit check via lint-staged
import { execSync } from 'child_process';

const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf8' })
  .trim()
  .split('\n')
  .filter(Boolean);

const envFiles = stagedFiles.filter(f => /^\.env(\.|$)/.test(f.split('/').pop() ?? ''));

if (envFiles.length > 0) {
  console.error(`ERROR: Attempting to commit .env file(s):\n  ${envFiles.join('\n  ')}`);
  console.error('Remove from staging: git reset HEAD <file>');
  process.exit(1);
}
```

> [community] **Gotcha (GitGuardian State of Secrets Sprawl 2024)**: 12.8 million secrets were detected in public GitHub commits in 2023. The most commonly leaked secrets in Node.js/TypeScript projects are: Google API keys (committed via `.env` or hardcoded in tests), AWS credentials (from local `~/.aws/credentials` accidentally included), and JWT secrets (hardcoded in `config.ts` for "convenience"). **Pre-commit secret scanning and GitHub push protection together stop > 90% of accidental commits before they reach remote**.

### PR-Level Required Status Checks

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
    name: TypeScript Compile Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx tsc --noEmit
        # Fail on ANY type error — strict: true in tsconfig.json

  unit-tests:
    name: Unit Tests + Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx vitest run --coverage --reporter=junit --outputFile=test-results.xml
        env:
          VITEST_COVERAGE_THRESHOLD_LINES: '80'
          VITEST_COVERAGE_THRESHOLD_FUNCTIONS: '75'
          VITEST_COVERAGE_THRESHOLD_BRANCHES: '70'
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
      - run: npx eslint . --ext .ts,.tsx --max-warnings=0 --format=sarif --output-file=eslint.sarif || true
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

### Type Safety as Shift-Left (TypeScript strict + Zod)

```jsonc
// tsconfig.json — maximum shift-left via compiler strictness
{
  "compilerOptions": {
    // Core strict bundle
    "strict": true,                        // enables: strictNullChecks, noImplicitAny, strictFunctionTypes, strictBindCallApply, strictPropertyInitialization, strictBuiltinIteratorReturn
    // Beyond strict
    "noUncheckedIndexedAccess": true,      // arr[0] returns T | undefined — prevents silent index errors
    "exactOptionalPropertyTypes": true,    // { x?: string } won't accept { x: undefined }
    "noImplicitReturns": true,             // all code paths must return a value
    "noFallthroughCasesInSwitch": true,    // exhaustive switch cases
    "noPropertyAccessFromIndexSignature": true, // forces bracket notation for index signatures
    "useUnknownInCatchVariables": true,    // catch (e: unknown) instead of any
    // Output
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts"]
}
```

```typescript
// src/api/validators/user.schema.ts — Zod validation at the API boundary
import { z } from 'zod';
import type { Request, Response, NextFunction } from 'express';

// Define the schema with all business rules encoded
export const CreateUserSchema = z
  .object({
    email: z
      .string()
      .email('Must be a valid email address')
      .max(254, 'Email too long (RFC 5321 limit)'),
    name: z
      .string()
      .min(1, 'Name is required')
      .max(100, 'Name too long')
      .regex(/^[a-zA-Z\s'-]+$/, 'Name contains invalid characters'),
    role: z.enum(['admin', 'viewer', 'editor'], {
      errorMap: () => ({ message: 'Role must be admin, viewer, or editor' }),
    }),
    age: z.number().int().min(13, 'Must be at least 13').max(150).optional(),
    metadata: z.record(z.string(), z.unknown()).optional(),
  })
  .strict(); // Reject unknown fields — prevents prototype pollution

// Infer the TypeScript type from the Zod schema (single source of truth)
export type CreateUserInput = z.infer<typeof CreateUserSchema>;

// Reusable Express middleware for request validation
export function validateBody<T extends z.ZodTypeAny>(schema: T) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({
        error: 'Validation failed',
        issues: result.error.flatten().fieldErrors,
      });
      return;
    }
    // Attach typed, validated data — downstream handlers get T, not `any`
    (req as Request & { validatedBody: z.infer<T> }).validatedBody = result.data;
    next();
  };
}

// Usage in route definition
// router.post('/users', validateBody(CreateUserSchema), createUserHandler);
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
          # Wait for healthcheck
          timeout 60 sh -c 'until curl -sf http://localhost:3000/health; do sleep 2; done'

      - name: Run ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: '.zap/rules.tsv'  # Suppress known false positives
          cmd_options: '-a'                   # Include alpha passive rules
          fail_action: true                   # Fail the workflow on WARN+ findings

      - name: Upload ZAP report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report-${{ github.run_number }}
          path: report_html.html

      - name: Stop application
        if: always()
        run: docker compose -f docker-compose.test.yml down

  zap-full:
    name: ZAP Full Active Scan (weekly, ~30 min)
    runs-on: ubuntu-latest
    if: github.event.schedule == '0 2 * * 0'   # Sundays only
    needs: zap-baseline
    steps:
      - uses: actions/checkout@v4
      - name: Start isolated test environment
        run: docker compose -f docker-compose.dast.yml up -d
      - name: Run ZAP Full Scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-z "-config scanner.threadPerHost=5"'
      - name: Teardown
        if: always()
        run: docker compose -f docker-compose.dast.yml down -v
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
4. **Skipping type safety for "speed"**: Using `any` pervasively in TypeScript nullifies the type system's shift-left value. A codebase that is 90% `any` provides none of the compile-time safety benefits.
5. **Not tuning SAST false positives**: Untuned SAST produces noisy alerts that teams learn to ignore — recreating the exact alert-fatigue problem it was meant to solve. Spend one sprint tuning rules before enforcing them as hard gates. See the SAST Tuning Workflow below.
6. **Treating shift-left as shift-only**: Removing or skipping production monitoring because "we have 80% test coverage" leads to blind spots in real user behavior.
7. **Running DAST on every PR**: OWASP ZAP full-scan takes 15–45 minutes. Run it on schedule (nightly) or on merges to main, not every PR. Use SAST for PR gates.
8. **Shifting integration tests left into unit tests**: Some teams mock every external dependency in "unit" tests and then have no integration tests. Mocking a database client in every test makes unit tests fast but means no test ever validates the SQL queries, migrations, or connection pooling behavior. Keep a meaningful integration test layer.
9. **Security theater via checkbox compliance**: Installing SAST, secret scanning, and DAST tools but routing their findings to a separate "security backlog" that no one triages is not shift-left — it is shift-later with extra steps. Shift-left only works when findings block the pipeline AND developers act on them within the same sprint they are raised.

### SAST Tuning Workflow

Before making a SAST rule a hard gate (CI failure), follow this process to avoid alert fatigue:

1. **Audit mode first**: Run SAST in warn-only mode for 2 weeks. Collect all findings.
2. **Classify findings**: For each rule type, measure true-positive rate from a sample of 20 findings.
3. **Suppress noise with prejudice**: Rules with < 30% true-positive rate should be disabled or moved to informational. Document WHY in the ESLint config as a comment.
4. **Baseline suppression**: For legitimate false positives in specific contexts, use inline suppressions with justification:

```typescript
// eslint-disable-next-line security/detect-object-injection -- key is validated against allowlist above
const value = safeConfig[validatedKey];
```

5. **Hard gate only trusted rules**: Only rules with > 70% true-positive rate should block CI.
6. **Review quarterly**: As the codebase evolves, re-evaluate suppressed rules.

---

## Shift-Left vs Shift-Right Balance [community]

[community] **Lesson (Spotify engineering blog)**: Teams that go all-in on shift-left and remove production monitoring regress. Unit tests and type checks do not catch n-way integration failures, data migration edge cases, or real user behavior patterns that only appear at scale.

[community] **Lesson (Netflix tech blog, GitHub engineering)**: High-velocity organizations run both layers: shift-left gates (type check, unit test, lint, SAST) for speed and immediate feedback, and shift-right observability (feature flags, canary deployments, error budgets, synthetic checks) for production confidence.

[community] **Lesson (Google SRE Book)**: The cost curve argument works in the opposite direction too — building comprehensive integration test suites that take 45 minutes to run is a form of over-shifting-left that kills CI throughput. The goal is *appropriately placed* feedback loops, not maximum coverage at the earliest stage.

[community] **Lesson (engineering teams at Vercel, Linear)**: Feature flags are the most powerful shift-right complement to shift-left. They decouple deploy from release, allowing incomplete or unvetted features to exist in production code safely, with instant rollback.

[community] **Lesson (ThoughtWorks Technology Radar)**: The shift-left movement has created an over-investment in unit tests relative to integration and contract tests. Many bugs that matter are interaction bugs — they can only be caught between services, not within a single unit. Invest in consumer-driven contract testing (Pact) as a mid-pipeline check.

---

## Real-World Gotchas [community]

[community] **Gotcha**: `tsc --noEmit` in a lint-staged pre-commit hook runs the full compiler on every commit. On a large monorepo this can take 30–90 seconds, causing developers to use `git commit --no-verify`. Use `--incremental` to cache compiler state between runs, or switch to `ts-project-references` for scope isolation.

[community] **Gotcha**: ESLint `security/detect-object-injection` fires on nearly every `obj[key]` bracket access in TypeScript. Teams typically disable this specific rule and rely on TypeScript's index signature type checking instead. Always audit a SAST ruleset for false-positive rate before enforcing it as a gate.

[community] **Gotcha**: `npm audit` generates false positives for vulnerabilities in dev-only dependencies (test runners, build tools) that never reach production. Use `--omit=dev` in CI to scope audits to production dependencies. Separate the "report all" and "fail on high" commands.

[community] **Gotcha**: CodeQL requires all build artifacts to be produced during its analysis step. For projects with complex build pipelines (Nx, Turborepo, Bazel), the CodeQL "autobuild" step often fails silently and produces incomplete results. Use an explicit build command via `build-mode: manual`.

[community] **Gotcha**: Zod `.safeParse()` does not strip unknown fields by default — `{ name: 'a', __proto__: ... }` passes without `.strict()`. Add `.strict()` to all schemas at external trust boundaries (API routes, webhook handlers) to reject unexpected properties that could indicate prototype pollution attempts.

[community] **Gotcha (Snyk report 2023)**: Dependabot PR volume on active projects can reach 20–40 PRs per week, causing PR fatigue and ignored updates. Use Dependabot's `groups` configuration or switch to Renovate with `automerge: true` for patch-level non-security updates.

[community] **Gotcha**: OWASP ZAP active scan mode will attempt SQL injection, path traversal, and XSS payloads against your application — it **will mutate or corrupt test database data** if pointed at a shared environment. Always run DAST against an isolated, ephemeral environment.

[community] **Lesson (Stripe engineering)**: Shift-left pays the highest dividend when applied to the authorization layer. Authorization bugs (privilege escalation, IDOR) are systematically hard to catch with unit tests because they require cross-user context. Encode authorization rules as type-level constraints (branded user types, permission enums) and test them at the integration level with role-specific test fixtures — not as an afterthought.

[community] **Lesson (Airbnb TypeScript migration)**: The single highest-ROI shift-left investment on an existing JavaScript codebase is not adding SAST or security tools — it is enabling TypeScript's `strict` mode and fixing the compiler errors. Teams report catching 15–40% of existing production bugs before they ship when migrating incrementally with `// @ts-check` or `allowJs: true`. The type errors are a map of the existing defects.

[community] **Lesson (Atlassian microservices)**: Consumer-driven contract testing (Pact) eliminated an entire class of integration bugs in their microservice architecture: breaking API changes that only surfaced in staging or production. By running Pact contract verification as a PR check, teams caught breaking changes at the exact commit that introduced them — not two weeks later during integration testing. The key insight: contract tests are unit-test-speed checks that provide integration-test-level confidence.

[community] **Lesson (engineering teams)**: The single most actionable shift-left metric is "defect discovery phase distribution" — tracking where bugs are found (pre-commit / PR / staging / production) and watching the distribution shift left over time. Teams that track this metric improve it; teams that only track production bug counts do not. Instrument your issue tracker or use a JIRA workflow with a "discovery phase" field from day one.

---

## Tradeoffs & Alternatives

| Approach | Benefit | Cost | Recommendation |
|---|---|---|---|
| Pre-commit hooks (Husky) | Immediate, offline feedback; no CI wait | Slows commit (5–30s); devs bypass with `--no-verify` | Use for lint + format only; move type check to CI |
| PR status checks | Hard gate, cannot be bypassed; audit trail | Requires CI infrastructure; slows PR cycle by 3–10 min | Required for all production codebases |
| SAST (CodeQL) | Deep data-flow and taint analysis; finds subtle injection bugs | High false-positive rate; complex setup for monorepos; 5–20 min scan | Essential for security-sensitive code; tune rules first |
| SAST (Semgrep) | Fast (< 2 min); highly configurable; offline-capable | Community rules vary in quality; requires rule maintenance | Better default SAST choice than CodeQL for speed |
| DAST (OWASP ZAP) | Finds runtime security issues invisible to SAST | Requires running app; 15–45 min; corrupts test data if misconfigured | Nightly/schedule only; never on every PR |
| TypeScript strict mode | Compiler eliminates entire categories of runtime errors | Migration cost on existing large codebases (weeks to months) | Non-negotiable for new projects; phase in for legacy |
| Zod validation | Runtime safety + type inference from single schema source | Adds ~3–8 kB gzip; schema duplication if also using OpenAPI | Use `zod-to-openapi` or `@anatine/zod-openapi` to unify |
| Snyk vs npm audit | Snyk: richer data, fix PRs, license scan; audit: zero config | Snyk: requires account + token + cost at scale | Both: `npm audit` in CI, Snyk for deeper analysis |

**When not to shift left**: Exploratory testing, usability research, load testing, and chaos/resilience testing are inherently shift-right activities. Do not attempt to automate or pre-production-gate tests that require real user behavior, real traffic patterns, concurrent load, or stochastic failure modes. These require production-like conditions to be meaningful.

### Team-Size Adoption Guide

| Team Size | Recommended Starting Point | Add Next |
|---|---|---|
| 1–3 engineers | TypeScript strict mode + ESLint + Prettier (pre-commit) | Unit tests, `npm audit` in CI |
| 4–10 engineers | Above + Husky/lint-staged + PR status checks (typecheck, unit tests) | Vitest coverage thresholds, CodeQL on PRs |
| 11–30 engineers | Above + Semgrep or CodeQL SAST + Snyk dependency scanning | DAST (nightly), contract tests |
| 30+ engineers | Above + all patterns + DAST + consumer-driven contract tests (Pact) + SBOMs | Chaos engineering, error budgets |

**Pragmatic sequencing**: Do not attempt to implement all patterns simultaneously. Start with the cheapest, highest-ROI items (TypeScript strict + ESLint + pre-commit hooks) and add layers incrementally. A partially implemented shift-left strategy is better than a comprehensive one that never gets past the planning stage.

---

## Shift-Left Maturity Model

Use this model to assess and advance your team's shift-left posture. Each level builds on the previous — do not skip levels.

| Level | Name | Characteristics | Key Evidence |
|-------|------|----------------|--------------|
| **L1** | Ad-Hoc | Tests written after code or not at all; no pre-commit hooks; testing is a manual phase | No CI test gate; defects found in staging or production |
| **L2** | Established | Unit tests exist and run in CI; TypeScript strict mode; basic ESLint; PR requires CI to pass | CI green required to merge; coverage tracked (even if not thresholded) |
| **L3** | Automated | Pre-commit hooks with lint-staged; coverage thresholds enforced; SAST (ESLint security, Semgrep) running on PRs; `npm audit` as gate; secret scanning enabled | MTTD < 15 min for code bugs; pre-commit catches format/lint issues |
| **L4** | Security-Integrated | CodeQL or Semgrep with custom rules; Zod validation at all API boundaries; Snyk + license compliance; nightly DAST; contract tests for service interactions | SAST:production CVE ratio > 10:1; no unscanned PRs |
| **L5** | Comprehensive | IaC scanning (Checkov/Trivy); container image scanning; SBOM generation + attestation; error budgets defined; full shift-right complement (canary, feature flags, synthetic monitoring) | Defect escape rate measured and decreasing; `--no-verify` usage near zero; MTTD trending down quarter-over-quarter |

**Transition guidance:**
- **L1 → L2**: Enable TypeScript strict mode + ESLint + CI gate. Takes 1–3 sprints on an existing codebase; plan for fixing type errors.
- **L2 → L3**: Add Husky + lint-staged + Semgrep. Takes 1 sprint. The majority of shift-left ROI comes from L2→L3.
- **L3 → L4**: Add CodeQL + Zod + Snyk + DAST. Takes 2–3 sprints. Requires security champion on team to tune rules.
- **L4 → L5**: Add IaC/container scanning + SBOM + full observability. Ongoing investment; plan 1 sprint per tool.

> [community] **Lesson (engineering maturity research, DORA 2024)**: Teams at L3+ (automated gates, SAST, coverage thresholds) deploy 4× more frequently and have 7× lower change failure rates than L1–L2 teams. The L2→L3 transition is where most of the DORA elite performer gains come from — not from L4/L5 sophistication. Invest in getting everyone to L3 before optimizing beyond it.

---

## Quick Reference — Shift-Left Checklist

Use this checklist to audit a TypeScript/Node.js project's shift-left posture:

**Static Layer (pre-commit)**
- [ ] TypeScript `strict: true` + `noUncheckedIndexedAccess` enabled
- [ ] ESLint with `@typescript-eslint/recommended` + `eslint-plugin-security`
- [ ] Husky pre-commit hook with lint-staged (lint + format + type check)
- [ ] Conventional commits enforced via commit-msg hook
- [ ] `.env` files in `.gitignore` + pre-commit `.env` file guard
- [ ] Secret scanning pre-commit check (Gitleaks or custom script)

**PR Gate Layer (CI — must pass before merge)**
- [ ] `tsc --noEmit` in required status check
- [ ] Unit tests with coverage thresholds (≥ 80% lines)
- [ ] ESLint + security lint at `--max-warnings=0`
- [ ] `npm audit --audit-level=high --omit=dev`
- [ ] Semgrep or CodeQL SAST scan
- [ ] Gitleaks secret scanning (PR-level)
- [ ] GitHub Secret Scanning push protection enabled at org/repo level
- [ ] Zod validation at all external API boundaries

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

### Checkov (Terraform/CloudFormation/Kubernetes)

```yaml
# .github/workflows/iac-scan.yml — runs on changes to IaC files
name: IaC Security Scan
on:
  pull_request:
    paths:
      - 'infrastructure/**'
      - '**/*.tf'
      - '**/*.yaml'
      - '**/*.yml'
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
          soft_fail: false           # Hard fail on HIGH severity findings
          skip_check: CKV_AWS_18    # Example: skip specific check with documented reason
          output_format: sarif
          output_file_path: checkov.sarif

      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: checkov.sarif

  trivy-config:
    name: Trivy Misconfiguration Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-config.sarif'
          severity: 'HIGH,CRITICAL'
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-config.sarif
```

```yaml
# .github/workflows/container-scan.yml — scan Docker images before pushing
name: Container Image Scan
on:
  push:
    paths: ['Dockerfile*', 'docker-compose*.yml']

jobs:
  trivy-image:
    name: Trivy Container Vulnerability Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image for scanning (do not push yet)
        run: docker build -t app:scan-${{ github.sha }} .

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app:scan-${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-image.sarif'
          severity: 'HIGH,CRITICAL'
          # Exit code 1 on findings — stops the push
          exit-code: '1'
          ignore-unfixed: true    # Skip CVEs with no patch available
          vuln-type: 'os,library'

      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-image.sarif
```

> [community] **Gotcha**: IaC scanners have very high false-positive rates on resource-level checks (e.g., "S3 bucket has no access logs" is flagged even for intentionally public buckets). Maintain a `.checkov.yaml` or `.trivyignore` file that documents suppressed checks with reasons — treat it as a living security decision log, reviewed quarterly.

---

## Software Bill of Materials (SBOM)

An SBOM is a structured inventory of all software components in a project — first-party code, direct dependencies, and transitive dependencies. SBOM generation is a shift-left practice: producing it at build time, not after an incident.

**Why SBOMs matter**: When a new CVE drops (e.g., Log4Shell, XZ Utils backdoor), teams with SBOMs can answer "are we affected?" in minutes by querying the SBOM. Teams without them spend hours grepping dependency trees under incident pressure.

```yaml
# .github/workflows/sbom.yml — generate SBOM on every release build
name: Generate SBOM
on:
  push:
    tags: ['v*']
  release:
    types: [published]

jobs:
  sbom:
    name: Generate and Attest SBOM
    runs-on: ubuntu-latest
    permissions:
      contents: write
      id-token: write     # Required for OIDC-based attestation
      attestations: write

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci --omit=dev

      # Generate SBOM in CycloneDX format (preferred for vulnerability databases)
      - name: Generate SBOM (CycloneDX)
        run: npx @cyclonedx/cyclonedx-npm --output-file sbom.json --output-format JSON
        # Output includes: component name, version, purl, licenses, hashes, VEX data

      # Also generate SPDX for regulatory compliance (NTIA minimum elements)
      - name: Generate SBOM (SPDX)
        run: npx spdx-sbom-generator -p . -o sbom-spdx.spdx

      # Scan the generated SBOM for known vulnerabilities using Grype
      - name: Scan SBOM for vulnerabilities (Grype)
        uses: anchore/scan-action@v3
        with:
          sbom: 'sbom.json'
          fail-build: true
          severity-cutoff: high

      # Attach SBOM as a GitHub release asset and create a signed attestation
      - uses: actions/attest-sbom@v1
        with:
          subject-path: './dist'    # Attest the built artifact
          sbom-path: 'sbom.json'

      - uses: actions/upload-release-asset@v1
        env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}' }
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: sbom.json
          asset_name: sbom-${{ github.ref_name }}.json
          asset_content_type: application/json
```

> [community] **Gotcha (CISA SBOM guidance)**: Generating an SBOM without consuming it is security theater. Pair SBOM generation with a Grype or OSV-scanner scan in CI so the SBOM serves double duty: compliance artifact and vulnerability query surface.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| IBM: Shift-Left Testing | Official | https://www.ibm.com/topics/shift-left-testing | Foundational definitions and cost-of-defects curve |
| OWASP DevSecOps Guideline | Official | https://owasp.org/www-project-devsecops-guideline/ | Security testing pipeline integration patterns |
| OWASP ZAP | Official | https://www.zaproxy.org/ | DAST tool for runtime security testing |
| Semgrep Rules Registry | Tool | https://semgrep.dev/r | Curated SAST rulesets for TypeScript/Node.js/OWASP |
| CodeQL Documentation | Official | https://codeql.github.com/docs/ | Deep data-flow taint analysis for security bugs |
| Husky Documentation | Tool | https://typicode.github.io/husky/ | Pre-commit hook setup for Node.js projects |
| lint-staged | Tool | https://github.com/lint-staged/lint-staged | Run linters on staged files only (fast pre-commit) |
| Snyk for Node.js | Tool | https://docs.snyk.io/scan-using-snyk/snyk-open-source/snyk-open-source-supported-languages-and-package-managers/snyk-for-javascript-node.js | Dependency vulnerability + license scanning |
| Zod Documentation | Tool | https://zod.dev/ | Runtime schema validation + TypeScript type inference |
| TypeScript Strict Mode | Official | https://www.typescriptlang.org/tsconfig#strict | Compiler-level shift-left via strict type checking |
| Google SRE Book — Testing for Reliability | Book | https://sre.google/sre-book/testing-reliability/ | Production testing philosophy from Google |
| ThoughtWorks Technology Radar — Shift Left on Security | Community | https://www.thoughtworks.com/radar/techniques/shift-left-on-security | Industry adoption signal and maturity guidance |
| NIST: Cost Advantage of Early Defect Detection | Research | https://www.nist.gov/system/files/documents/director/planning/report02-3.pdf | Empirical data behind the cost-of-defects curve |
| Pact Consumer-Driven Contract Testing | Tool | https://docs.pact.io/ | Contract tests as mid-pipeline shift-left integration checks |
| Vitest Documentation | Tool | https://vitest.dev/guide/ | Fast TypeScript-native test runner for pre-commit and CI |
| eslint-plugin-security | Tool | https://github.com/eslint-community/eslint-plugin-security | ESLint rules for Node.js security vulnerabilities |
| Renovate Bot | Tool | https://docs.renovatebot.com/ | Automated dependency updates with configurable automerge |
| Gitleaks | Tool | https://github.com/gitleaks/gitleaks | Pre-commit and CI secret detection in git history |
| GitHub Secret Scanning | Official | https://docs.github.com/en/code-security/secret-scanning | Native push protection for committed secrets |
| Checkov (IaC Scanner) | Tool | https://www.checkov.io/ | Policy-as-code scanning for Terraform/K8s/Dockerfile |
| Trivy | Tool | https://aquasecurity.github.io/trivy/ | Container image + IaC misconfiguration vulnerability scanner |
| CycloneDX SBOM Generator | Tool | https://cyclonedx.org/ | SBOM generation standard for vulnerability querying |
| Grype (SBOM Vulnerability Scanner) | Tool | https://github.com/anchore/grype | Scan SBOMs for known CVEs against multiple vulnerability DBs |
