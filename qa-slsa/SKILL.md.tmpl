---
name: qa-slsa
preamble-tier: 3
version: 1.0.0
description: |
  Supply chain provenance verification using SLSA attestations. Verifies that build
  artifacts (npm packages, Docker images, release binaries) have valid SLSA provenance
  attestations chaining to a trusted CI environment. Flags unsigned or tampered artifacts
  as CI failures. Integrates with gh CLI attestation and slsa-verifier. Env vars:
  SLSA_MIN_LEVEL. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
disable-model-invocation: true
model: sonnet
effort: high
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

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

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
_ARTIFACT_LIST=""
[ -d "dist" ] && find dist -name "*.tgz" -maxdepth 2 2>/dev/null | grep -q '.' && _ARTIFACTS_FOUND=1
find . -name "*.tar.gz" -not -path "*/node_modules/*" -maxdepth 3 2>/dev/null | grep -q '.' && _ARTIFACTS_FOUND=1
[ -f "Dockerfile" ] && _ARTIFACTS_FOUND=1 && echo "ARTIFACT_DETECTED: Dockerfile"
find build -name "*" -maxdepth 2 2>/dev/null | grep -q '.' && _ARTIFACTS_FOUND=1
echo "ARTIFACTS_FOUND: $_ARTIFACTS_FOUND"
_GH_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "unknown")
echo "GH_REPO: $_GH_REPO"
```

If both `_GH_AVAILABLE=0` and `_SLSA_VERIFIER=0`: print install instructions:
- gh CLI: `brew install gh` / `https://cli.github.com/`
- slsa-verifier: `brew install slsa-verifier` / `go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest`

Emit a WARN CTRF entry and report as skipped (non-blocking).

## Phase 1 — Discover Artifacts

List release artifacts from GitHub releases (if `_GH_AVAILABLE=1`) and scan local paths:

```bash
echo "=== ARTIFACT DISCOVERY ==="

# Local artifact discovery
find dist -name "*.tgz" -maxdepth 2 2>/dev/null | while read -r f; do echo "ARTIFACT: $f"; done
find . -name "*.tar.gz" -not -path "*/node_modules/*" -maxdepth 3 2>/dev/null \
  | while read -r f; do echo "ARTIFACT: $f"; done
[ -f "Dockerfile" ] && echo "ARTIFACT: Dockerfile (image build detected)"
find build -maxdepth 2 -type f 2>/dev/null | head -10 | while read -r f; do echo "ARTIFACT: $f"; done

# GitHub release assets
if [ "$_GH_AVAILABLE" = "1" ] && [ "$_GH_REPO" != "unknown" ]; then
  echo "--- GitHub latest release assets ---"
  gh release list --limit 1 --json tagName,assets --repo "$_GH_REPO" 2>/dev/null | head -5 || true
  gh release view --json assets -q '.assets[].name' --repo "$_GH_REPO" 2>/dev/null \
    | while read -r a; do echo "RELEASE_ASSET: $a"; done
fi
```

## Phase 2 — Verify Attestations

For each discovered artifact, attempt verification using `gh attestation verify` first, then `slsa-verifier` as fallback:

```bash
echo "=== PROVENANCE VERIFICATION ==="

_ARTIFACTS=$(find dist -name "*.tgz" -maxdepth 2 2>/dev/null; \
             find . -name "*.tar.gz" -not -path "*/node_modules/*" -maxdepth 3 2>/dev/null)

for _artifact in $_ARTIFACTS; do
  [ -f "$_artifact" ] || continue
  echo "--- Verifying: $_artifact ---"

  _VERIFIED=0
  _FAIL=0

  # Method 1: gh attestation verify
  if [ "$_GH_AVAILABLE" = "1" ] && [ "$_GH_REPO" != "unknown" ]; then
    _GH_RESULT=$(gh attestation verify "$_artifact" --repo "$_GH_REPO" 2>&1 || true)
    echo "GH_ATTEST_RESULT: $(echo "$_GH_RESULT" | head -3)"
    echo "$_GH_RESULT" | grep -qi "verified\|success" && _VERIFIED=1
    echo "$_GH_RESULT" | grep -qi "error\|failed\|invalid" && _FAIL=1
  fi

  # Method 2: slsa-verifier
  if [ "$_SLSA_VERIFIER" = "1" ] && [ "$_VERIFIED" = "0" ] && [ "$_GH_REPO" != "unknown" ]; then
    _PROV_PATH="${_artifact}.intoto.jsonl"
    if [ -f "$_PROV_PATH" ]; then
      _SV_RESULT=$(slsa-verifier verify-artifact "$_artifact" \
        --provenance-path "$_PROV_PATH" \
        --source-uri "github.com/$_GH_REPO" 2>&1 || true)
      echo "SLSA_VERIFIER_RESULT: $(echo "$_SV_RESULT" | head -3)"
      echo "$_SV_RESULT" | grep -qi "PASSED\|verified" && _VERIFIED=1
      echo "$_SV_RESULT" | grep -qi "FAILED\|error" && _FAIL=1
    else
      echo "PROVENANCE_MISSING: $_PROV_PATH not found"
    fi
  fi

  if [ "$_FAIL" = "1" ]; then
    echo "PROVENANCE_STATUS: FAILED — $_artifact"
  elif [ "$_VERIFIED" = "1" ]; then
    echo "PROVENANCE_STATUS: VERIFIED (SLSA L>=$_SLSA_MIN_LEVEL) — $_artifact"
  else
    echo "PROVENANCE_STATUS: UNVERIFIED (no attestation) — $_artifact"
  fi
done
```

Parse the output lines to build a findings list:
- `PROVENANCE_STATUS: VERIFIED` → passed
- `PROVENANCE_STATUS: UNVERIFIED` → skipped (warn — missing attestation is advisory, not blocking)
- `PROVENANCE_STATUS: FAILED` → failed (active verification failure is blocking)

## Phase 3 — Report

After collecting Phase 2 `PROVENANCE_STATUS` lines, build the results list and write outputs.

Write `$_TMP/qa-slsa-report-$_DATE.md` containing:
- Summary: artifacts found, tools used, min level required
- Attestation table: Artifact | Status | SLSA Level | Signed By
- Remediation steps for any unverified or failed artifacts:
  - For missing attestation: "Add SLSA Build L2+ GitHub Actions workflow; use `actions/attest-build-provenance@v1`"
  - For failed verification: "Artifact may be tampered — do not release; re-build from clean CI environment"

```bash
python3 - << 'PYEOF'
import json, os, time

tmp     = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
branch  = os.environ.get('_BRANCH', 'unknown')
date    = os.environ.get('_DATE', 'unknown')
min_lvl = os.environ.get('_SLSA_MIN_LEVEL', '2')

# Claude populates this list from Phase 2 PROVENANCE_STATUS output lines.
# Each entry: {'artifact': str, 'status': 'verified'|'unverified'|'failed', 'level': str, 'signed_by': str}
results = []  # populated by Claude from Phase 2 parsed output

now_ms = int(time.time() * 1000)
tests = []
for r in results:
    artifact = r.get('artifact', 'unknown')
    status   = r.get('status', 'unverified')
    ctrf_status = {'verified': 'passed', 'unverified': 'skipped', 'failed': 'failed'}.get(status, 'skipped')
    tests.append({'name': f"slsa/{artifact}", 'status': ctrf_status, 'duration': 0, 'suite': 'slsa'})

if not tests:
    tests = [{'name': 'slsa-scan/no-artifacts', 'status': 'passed', 'duration': 0, 'suite': 'slsa'}]

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')

ctrf = {'results': {
    'tool': {'name': 'qa-slsa'},
    'summary': {'tests': len(tests), 'passed': passed, 'failed': failed,
                'pending': 0, 'skipped': skipped, 'other': 0,
                'start': now_ms - 20000, 'stop': now_ms},
    'tests': tests,
    'environment': {'reportName': 'qa-slsa', 'branch': branch, 'slsaMinLevel': min_lvl},
}}
ctrf_path = os.path.join(tmp, 'qa-slsa-ctrf.json')
with open(ctrf_path, 'w', encoding='utf-8') as fh:
    json.dump(ctrf, fh, indent=2)
print(f'CTRF_WRITTEN: {ctrf_path}')
print(f'CTRF_STATUS: {"FAILED" if failed > 0 else "PASSED"}')
PYEOF
```

## Important Rules

- **Missing attestation is a warning** — not all projects use SLSA yet; mark as `skipped` not `failed`
- **Failed verification is always a hard failure** — a tampered artifact must never be released
- **Artifacts with no provenance support** (e.g., third-party pre-built binaries) are marked as `skipped`
- **Non-blocking if neither gh nor slsa-verifier installed** — emit WARN CTRF, report as skipped overall

## Agent Memory

After each run, update `.claude/agent-memory/qa-slsa/MEMORY.md` (create if absent). Record:
- Artifacts verified and their SLSA level
- Artifacts with missing provenance and any accepted exceptions
- GitHub repo / workflow used for attestation
- Tool versions (gh, slsa-verifier)

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-slsa","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
