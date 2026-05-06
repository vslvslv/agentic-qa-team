---
name: qa-secrets
description: |
  Secrets scanning gate using TruffleHog. Scans full git history and staged diff for
  leaked credentials, API keys, and tokens, validating detected secrets against live APIs
  to distinguish verified (active) from unverified. Blocks CI if verified secrets are
  found. Env vars: TRUFFLEHOG_MODE (history|staged|both), SECRETS_FAIL_ON_VERIFIED.
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

_TRUFFLEHOG_AVAILABLE=0
command -v trufflehog >/dev/null 2>&1 && _TRUFFLEHOG_AVAILABLE=1
echo "TRUFFLEHOG_AVAILABLE: $_TRUFFLEHOG_AVAILABLE"

_TRUFFLEHOG_MODE="${TRUFFLEHOG_MODE:-both}"
echo "TRUFFLEHOG_MODE: $_TRUFFLEHOG_MODE"

_SECRETS_FAIL_ON_VERIFIED="${SECRETS_FAIL_ON_VERIFIED:-1}"
echo "SECRETS_FAIL_ON_VERIFIED: $_SECRETS_FAIL_ON_VERIFIED"

_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
echo "REPO_ROOT: $_REPO_ROOT"
```

If `_TRUFFLEHOG_AVAILABLE=0`: emit install hint (`brew install trufflehog` / `go install github.com/trufflesecurity/trufflehog/v3@latest`) and run regex fallback scan instead.

## Phase 1 — Scan

Run based on `_TRUFFLEHOG_MODE`. If TruffleHog unavailable, use regex fallback for common patterns (AKIA*, ghp_*, sk_live_*, xoxb-*, etc.).

```bash
# History scan (mode: history or both)
trufflehog git "file://$_REPO_ROOT" --json --no-update 2>/dev/null \
  > "$_TMP/qa-secrets-history.json" || printf '' > "$_TMP/qa-secrets-history.json"

# Staged scan (mode: staged or both)
git diff --cached 2>/dev/null \
  | trufflehog stdin --json --no-update 2>/dev/null \
  > "$_TMP/qa-secrets-staged.json" || printf '' > "$_TMP/qa-secrets-staged.json"
```

Combine both JSONL outputs into `$_TMP/qa-secrets-all.json`, tagging each item with `_source: history|staged`.

## Phase 2 — Classify

Parse `$_TMP/qa-secrets-all.json`. For each finding extract: DetectorName, Raw (redact to first4+last4 chars), SourceMetadata File/Line, Commit SHA (first 12 chars).

Group into:
- `verified` — `Verified: true` or `VerificationResult: "Verified"` → active secrets, must rotate
- `unverified` — all others → likely false positives, warnings only

Print `VERIFIED_COUNT: N` and `UNVERIFIED_COUNT: N`. Write counts to `$_TMP/qa-secrets-counts.env` and structured list to `$_TMP/qa-secrets-parsed.json`.

## Phase 3 — Report

Write `$_TMP/qa-secrets-report-$_DATE.md` with:
- Summary table: Overall Status, Verified count, Unverified count, Mode, TruffleHog available
- Verified secrets table: Detector | Redacted Value | File | Line | Commit | Source
- Unverified findings table: Detector | File | Source
- Remediation steps: rotate credential, purge with `git filter-repo`, force-push, re-clone, add to `.gitignore`

Write `$_TMP/qa-secrets-ctrf.json`:
- Verified secrets → `"failed"` tests (when `SECRETS_FAIL_ON_VERIFIED=1`)
- Unverified findings → `"skipped"` tests
- No findings → single `"passed"` test

## Important Rules

- **Never print full secret values** — redact all secrets to first 4 + last 4 chars
- **Verified secrets always fail** when `SECRETS_FAIL_ON_VERIFIED=1` (default)
- **Unverified findings are warnings only** — `skipped` in CTRF, do not block CI
- **Degrade gracefully** — use pattern fallback if TruffleHog not installed; never exit early

## Agent Memory

After each run, update `.claude/agent-memory/qa-secrets/MEMORY.md`. Record: TruffleHog version, known false positives (path + detector + reason), previously rotated secrets (branch/commit only, not values).
