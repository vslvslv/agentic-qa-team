---
name: qa-env-parity
description: |
  Environment configuration parity checker. Compares declared env vars, feature flags,
  and config keys across dev/staging/production environment files to detect silent drift
  that causes 'works in staging' failures. Generates a structured drift report with LLM
  classification of missing required keys, mismatched values, and stale orphaned entries.
  Env vars: PARITY_ENVIRONMENTS, PARITY_REQUIRED_KEYS.
model: sonnet
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

_ENV_FILES=""
for f in .env .env.local .env.development .env.staging .env.production .env.test .env.example .env.sample; do
  [ -f "$f" ] && _ENV_FILES="$_ENV_FILES $f" && echo "ENV_FILE: $f"
done
find config/environments -name "*.rb" 2>/dev/null | while read -r f; do echo "ENV_FILE: $f"; done
find src/config -name "*.ts" 2>/dev/null | xargs grep -l "export const ENV\|process\.env" 2>/dev/null \
  | while read -r f; do echo "ENV_FILE: $f"; done

_PARITY_ENVS="${PARITY_ENVIRONMENTS:-development,staging,production}"
echo "ENVIRONMENTS: $_PARITY_ENVS"

_REQUIRED_KEYS="${PARITY_REQUIRED_KEYS:-}"
echo "REQUIRED_KEYS: ${_REQUIRED_KEYS:-not set}"

_ENV_FILE_COUNT=$(echo "$_ENV_FILES" | wc -w | tr -d ' ')
echo "ENV_FILES_FOUND: $_ENV_FILE_COUNT"
```

If no `.env*` files found: emit WARN CTRF entry and exit gracefully.

## Phase 1 — Parse

For each discovered env file: extract KEY=VALUE pairs (ignore comments, blank lines). Build per-environment key sets `{env_name: set(keys)}`. Values are NEVER stored — use `<set>` or `<empty>`. Compute union of all keys.

`.env.example` and `.env.sample` are treated as documentation (key inventory source) but excluded from parity comparisons.

## Phase 2 — Diff Matrix

For each key in union: mark which environments define it and which don't. Identify:
- Keys present in all envs (pass)
- Keys missing from some envs (warn/fail)
- Keys unique to one env (info)

If `_REQUIRED_KEYS` is set: mark missing required keys as critical.

## Phase 3 — LLM Analysis

Classify each gap:
- `required-missing` — key looks critical (DATABASE_URL, API_KEY, SECRET, JWT, AUTH) but absent from some envs
- `expected-drift` — dev-only keys (DEBUG, LOG_LEVEL) not needed in prod (OK)
- `value-mismatch` — same key, suspicious presence/absence pattern between envs
- `stale-orphaned` — defined in prod but not referenced in codebase (git grep check)

Write `$_TMP/qa-env-parity-classified.json` with category, reason, and envs_missing for each key.

## Phase 4 — Report

Write `$_TMP/qa-env-parity-report-$_DATE.md`: drift matrix table, LLM-classified issues by category, remediation steps.

Write `$_TMP/qa-env-parity-ctrf.json`:
- `required-missing` → `"failed"`
- `expected-drift` / `intentional-override` → `"passed"`
- `stale-orphaned` / `value-mismatch` → `"skipped"`

## Important Rules

- **Never write actual env var values** — use `<set>`, `<empty>`, `<redacted>` only
- **Value comparison is structural** (present vs absent) — not value equality
- `.env.example` is the authoritative required-key source if it exists
- **Non-blocking if no env files found** — emit WARN and exit gracefully

## Agent Memory

After each run, update `.claude/agent-memory/qa-env-parity/MEMORY.md`. Record: known intentional overrides, explicitly required keys for this project, environment-to-file mappings.
