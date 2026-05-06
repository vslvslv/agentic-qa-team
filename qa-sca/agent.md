---
name: qa-sca
description: |
  Software composition analysis gate using Syft (SBOM generation) and Grype (CVE scanning)
  plus license compliance checking. Generates a CycloneDX SBOM, scans for CVEs in all
  direct and transitive dependencies, flags denied license types (GPL, AGPL), and diffs
  against the previous SBOM to surface only new findings per run. Env vars:
  SCA_FAIL_ON_CRITICAL, SCA_LICENSE_DENY_LIST.
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

_SYFT_AVAILABLE=0
command -v syft >/dev/null 2>&1 && _SYFT_AVAILABLE=1
echo "SYFT_AVAILABLE: $_SYFT_AVAILABLE"

_GRYPE_AVAILABLE=0
command -v grype >/dev/null 2>&1 && _GRYPE_AVAILABLE=1
echo "GRYPE_AVAILABLE: $_GRYPE_AVAILABLE"

_SCA_FAIL_ON_CRITICAL="${SCA_FAIL_ON_CRITICAL:-1}"
echo "SCA_FAIL_ON_CRITICAL: $_SCA_FAIL_ON_CRITICAL"

_LICENSE_DENY="${SCA_LICENSE_DENY_LIST:-GPL-2.0,GPL-3.0,AGPL-3.0}"
echo "LICENSE_DENY_LIST: $_LICENSE_DENY"

_MANIFEST_TYPE="unknown"
[ -f "package.json" ]    && _MANIFEST_TYPE="npm"
[ -f "go.mod" ]          && _MANIFEST_TYPE="go"
[ -f "requirements.txt" ] && _MANIFEST_TYPE="python"
[ -f "pom.xml" ]         && _MANIFEST_TYPE="maven"
[ -f "Cargo.toml" ]      && _MANIFEST_TYPE="cargo"
[ -f "Gemfile" ]         && _MANIFEST_TYPE="ruby"
echo "MANIFEST_TYPE: $_MANIFEST_TYPE"
```

If neither `_SYFT_AVAILABLE` nor `_GRYPE_AVAILABLE`: emit install hints for both tools; continue in degraded mode.

## Phase 1 — Generate SBOM

If `_SYFT_AVAILABLE=1`: `syft . -o cyclonedx-json=1.4 > $_TMP/qa-sca-sbom.json`. Else: use `npm list --json` (npm) or `pip list --format=json` (python) as fallback. Print component count.

## Phase 2 — CVE Scan

If `_GRYPE_AVAILABLE=1`: `grype sbom:$_TMP/qa-sca-sbom.json -o json > $_TMP/qa-sca-vulns.json`. Parse results by severity: Critical, High, Medium, Low. Track `_CRITICAL_COUNT` and `_HIGH_COUNT`.

## Phase 3 — License Scan

Parse SBOM component licenses. Flag any component whose license matches `_LICENSE_DENY` list. Track `_LICENSE_VIOLATIONS`.

## Phase 4 — Delta

If `$_TMP/qa-sca-sbom-prev.json` exists: compare component lists; identify NEW components since last run. Save current SBOM as `$_TMP/qa-sca-sbom-prev.json` for next run.

## Phase 5 — Report

Write `$_TMP/qa-sca-report-$_DATE.md`: CVE table (Package | CVE | Severity | Fix Version), license violations, delta summary.

Write `$_TMP/qa-sca-ctrf.json`:
- Critical CVEs → `"failed"`
- High CVEs → `"failed"` if `SCA_FAIL_ON_CRITICAL=1`, else `"skipped"`
- License violations → `"failed"` regardless of severity setting
- No findings → `"passed"`

## Important Rules

- **Only report NEW findings vs. previous SBOM** — suppress existing CVEs to reduce noise
- **Critical CVEs always fail**; High CVEs fail only when `SCA_FAIL_ON_CRITICAL=1`
- **License violations always block** regardless of CVE fail settings
- **Always save current SBOM as prev** for delta comparison on next run

## Agent Memory

After each run, update `.claude/agent-memory/qa-sca/MEMORY.md`. Record: packages with accepted risk, license exceptions approved by legal, SBOM baseline date, CVEs under active remediation.
