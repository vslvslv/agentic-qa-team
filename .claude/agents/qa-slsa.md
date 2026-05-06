---
name: qa-slsa
description: |
  Supply chain provenance verification using SLSA attestations. Verifies that build
  artifacts (npm packages, Docker images, release binaries) have valid SLSA provenance
  attestations chaining to a trusted CI environment. Flags unsigned or tampered artifacts
  as CI failures. Integrates with gh CLI attestation and slsa-verifier. Env vars:
  SLSA_MIN_LEVEL.
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

_GH_AVAILABLE=0
command -v gh >/dev/null 2>&1 && _GH_AVAILABLE=1
echo "GH_AVAILABLE: $_GH_AVAILABLE"

_SLSA_VERIFIER=0
command -v slsa-verifier >/dev/null 2>&1 && _SLSA_VERIFIER=1
echo "SLSA_VERIFIER_AVAILABLE: $_SLSA_VERIFIER"

_SLSA_MIN_LEVEL="${SLSA_MIN_LEVEL:-2}"
echo "SLSA_MIN_LEVEL: $_SLSA_MIN_LEVEL"

_ARTIFACTS_FOUND=0
[ -d "dist" ] && find dist -name "*.tgz" -maxdepth 2 2>/dev/null | grep -q '.' && _ARTIFACTS_FOUND=1
find . -name "*.tar.gz" -not -path "*/node_modules/*" -maxdepth 3 2>/dev/null | grep -q '.' && _ARTIFACTS_FOUND=1
[ -f "Dockerfile" ] && _ARTIFACTS_FOUND=1
echo "ARTIFACTS_FOUND: $_ARTIFACTS_FOUND"

_GH_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "unknown")
echo "GH_REPO: $_GH_REPO"
```

If both `_GH_AVAILABLE=0` and `_SLSA_VERIFIER=0`: emit install hints, report as skipped (non-blocking).

## Phase 1 — Discover Artifacts

Scan local paths (dist/*.tgz, *.tar.gz, build/, Dockerfile) and list GitHub release assets via `gh release view` if available.

## Phase 2 — Verify Attestations

For each artifact:
1. Try: `gh attestation verify <artifact> --repo <owner/repo>` → parse pass/fail
2. Fallback: `slsa-verifier verify-artifact <artifact> --provenance-path <path> --source-uri github.com/<repo>`

Record: artifact name, status (verified|unverified|failed), SLSA level if available.

```bash
# Example for one artifact:
gh attestation verify "$_artifact" --repo "$_GH_REPO" 2>&1 | head -5
```

## Phase 3 — Report

Write `$_TMP/qa-slsa-report-$_DATE.md` with: attestation table (Artifact | Status | SLSA Level | Signed By), remediation steps.

Write `$_TMP/qa-slsa-ctrf.json`:
- Verified at/above min level → `"passed"`
- Missing attestation → `"skipped"` (warn — not all projects use SLSA yet)
- Failed verification (tampered) → `"failed"` (hard failure)

## Important Rules

- **Missing attestation is a warning** — mark `skipped`, not `failed`
- **Failed verification is always a hard failure** — tampered artifacts must never be released
- **Artifacts with no provenance support** are marked `skipped`
- **Non-blocking if neither gh nor slsa-verifier installed**

## Agent Memory

After each run, update `.claude/agent-memory/qa-slsa/MEMORY.md`. Record: artifacts verified and their SLSA level, missing provenance exceptions, GitHub repo/workflow used, tool versions.
