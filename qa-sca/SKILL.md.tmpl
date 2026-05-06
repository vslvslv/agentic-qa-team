---
name: qa-sca
preamble-tier: 3
version: 1.0.0
description: |
  Software composition analysis gate using Syft (SBOM generation) and Grype (CVE scanning)
  plus license compliance checking. Generates a CycloneDX SBOM, scans for CVEs in all
  direct and transitive dependencies, flags denied license types (GPL, AGPL), and diffs
  against the previous SBOM to surface only new findings per run. Env vars:
  SCA_FAIL_ON_CRITICAL, SCA_LICENSE_DENY_LIST. (qa-agentic-team)
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
_SBOM_PREV="$_TMP/qa-sca-sbom-prev.json"
[ -f "$_SBOM_PREV" ] && echo "PREV_SBOM: found" || echo "PREV_SBOM: none (first run)"
echo "--- DONE ---"
```

If neither `_SYFT_AVAILABLE` nor `_GRYPE_AVAILABLE`: print install instructions:
- Syft: `brew install syft` / `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh`
- Grype: `brew install grype` / `curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh`

Continue in degraded mode — SBOM will be generated using fallback if possible; CVE scan requires Grype.

## Phase 1 — Generate SBOM

If `_SYFT_AVAILABLE=1`: run Syft to produce a CycloneDX SBOM. Else: use `npm list --json` or `pip list --format=json` as fallback depending on `_MANIFEST_TYPE`.

```bash
echo "=== SBOM GENERATION ==="
if [ "$_SYFT_AVAILABLE" = "1" ]; then
  syft . -o cyclonedx-json=1.4 2>/dev/null > "$_TMP/qa-sca-sbom.json"
  _SYFT_EXIT=$?
  echo "SYFT_EXIT: $_SYFT_EXIT"
else
  echo "SYFT_UNAVAILABLE: using fallback inventory"
  case "$_MANIFEST_TYPE" in
    npm)
      npm list --json --all 2>/dev/null > "$_TMP/qa-sca-npm-list.json" || true
      echo "NPM_LIST_GENERATED: $_TMP/qa-sca-npm-list.json"
      ;;
    python)
      pip list --format=json 2>/dev/null > "$_TMP/qa-sca-pip-list.json" || true
      echo "PIP_LIST_GENERATED: $_TMP/qa-sca-pip-list.json"
      ;;
    *)
      echo "SBOM_FALLBACK: no fallback available for $_MANIFEST_TYPE — install syft"
      ;;
  esac
  printf '{"bomFormat":"CycloneDX","specVersion":"1.4","components":[]}' > "$_TMP/qa-sca-sbom.json"
fi

# Count components
python3 -c "
import json, os, sys
f = '$_TMP/qa-sca-sbom.json'
if not os.path.exists(f): print('SBOM_COMPONENTS: 0'); sys.exit(0)
try:
    data = json.load(open(f, encoding='utf-8', errors='replace'))
    comps = data.get('components', [])
    print(f'SBOM_COMPONENTS: {len(comps)}')
except Exception as e:
    print(f'SBOM_PARSE_ERROR: {e}')
" 2>/dev/null
```

## Phase 2 — CVE Scan

Skip if `_GRYPE_AVAILABLE=0` or SBOM not generated.

```bash
echo "=== GRYPE CVE SCAN ==="
grype "sbom:$_TMP/qa-sca-sbom.json" -o json 2>/dev/null > "$_TMP/qa-sca-vulns.json"
echo "GRYPE_EXIT: $?"

python3 - << 'PYEOF'
import json, os, sys
from collections import Counter

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
f = os.path.join(tmp, 'qa-sca-vulns.json')
if not os.path.exists(f):
    print("GRYPE_RESULTS: file not found"); sys.exit(0)

try:
    data = json.load(open(f, encoding='utf-8', errors='replace'))
    matches = data.get('matches', [])
    by_severity = Counter()
    for m in matches:
        sev = m.get('vulnerability', {}).get('severity', 'Unknown')
        by_severity[sev] += 1
    for sev, cnt in sorted(by_severity.items()):
        print(f"CVE_{sev.upper()}: {cnt}")

    # Save parsed vulns for Phase 5
    out = os.path.join(tmp, 'qa-sca-vulns-parsed.json')
    parsed = [
        {
            'id': m.get('vulnerability', {}).get('id', ''),
            'severity': m.get('vulnerability', {}).get('severity', 'Unknown'),
            'package': m.get('artifact', {}).get('name', ''),
            'version': m.get('artifact', {}).get('version', ''),
            'fix': m.get('vulnerability', {}).get('fix', {}).get('versions', []),
        }
        for m in matches
    ]
    json.dump(parsed, open(out, 'w', encoding='utf-8'), indent=2)
    print(f"VULNS_PARSED: {len(parsed)}")
except Exception as e:
    print(f"GRYPE_PARSE_ERROR: {e}")
PYEOF
```

## Phase 3 — License Scan

Parse SBOM component licenses and check against the deny list:

```python
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
deny_list = os.environ.get('_LICENSE_DENY', 'GPL-2.0,GPL-3.0,AGPL-3.0').split(',')
deny_set = set(d.strip() for d in deny_list)

sbom_file = os.path.join(tmp, 'qa-sca-sbom.json')
violations = []

if os.path.exists(sbom_file):
    try:
        data = json.load(open(sbom_file, encoding='utf-8', errors='replace'))
        for comp in data.get('components', []):
            name = comp.get('name', '')
            version = comp.get('version', '')
            licenses = comp.get('licenses', [])
            for lic in licenses:
                lic_id = lic.get('license', {}).get('id', '') or lic.get('expression', '')
                for denied in deny_set:
                    if denied.lower() in lic_id.lower():
                        violations.append({'package': name, 'version': version, 'license': lic_id})
                        print(f"LICENSE_VIOLATION: {name}@{version} — {lic_id}")
    except Exception as e:
        print(f"LICENSE_PARSE_ERROR: {e}")

print(f"LICENSE_VIOLATIONS_COUNT: {len(violations)}")
out = os.path.join(tmp, 'qa-sca-license-violations.json')
json.dump(violations, open(out, 'w', encoding='utf-8'), indent=2)
PYEOF
```

## Phase 4 — Delta vs Previous SBOM

Compare against the previous run's SBOM (if it exists) to identify newly introduced components:

```python
python3 - << 'PYEOF'
import json, os, shutil

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
sbom_file = os.path.join(tmp, 'qa-sca-sbom.json')
sbom_prev = os.path.join(tmp, 'qa-sca-sbom-prev.json')

new_components = set()
all_components = set()

if os.path.exists(sbom_file):
    try:
        data = json.load(open(sbom_file, encoding='utf-8', errors='replace'))
        for comp in data.get('components', []):
            key = f"{comp.get('name','')}@{comp.get('version','')}"
            all_components.add(key)
    except Exception as e:
        print(f"SBOM_PARSE_ERROR: {e}")

if os.path.exists(sbom_prev):
    try:
        prev_data = json.load(open(sbom_prev, encoding='utf-8', errors='replace'))
        prev_components = set()
        for comp in prev_data.get('components', []):
            key = f"{comp.get('name','')}@{comp.get('version','')}"
            prev_components.add(key)
        new_components = all_components - prev_components
        removed_components = prev_components - all_components
        print(f"DELTA_NEW_COMPONENTS: {len(new_components)}")
        print(f"DELTA_REMOVED_COMPONENTS: {len(removed_components)}")
        for c in sorted(new_components):
            print(f"NEW_COMPONENT: {c}")
    except Exception as e:
        print(f"PREV_SBOM_PARSE_ERROR: {e}")
else:
    print("DELTA: first run — no baseline, all components treated as new")
    new_components = all_components

# Save new components list for Phase 5
out = os.path.join(tmp, 'qa-sca-new-components.json')
json.dump(sorted(new_components), open(out, 'w', encoding='utf-8'), indent=2)

# Rotate SBOM: current becomes previous
if os.path.exists(sbom_file):
    shutil.copy2(sbom_file, sbom_prev)
    print(f"SBOM_ROTATED: current saved as baseline for next run")
PYEOF
```

## Phase 5 — Report

Write the markdown report and CTRF:

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
branch = os.environ.get('_BRANCH', 'unknown')
date = os.environ.get('_DATE', 'unknown')

# Load parsed data
vulns_file = os.path.join(tmp, 'qa-sca-vulns-parsed.json')
license_file = os.path.join(tmp, 'qa-sca-license-violations.json')
new_comp_file = os.path.join(tmp, 'qa-sca-new-components.json')

vulns = json.load(open(vulns_file, encoding='utf-8')) if os.path.exists(vulns_file) else []
license_violations = json.load(open(license_file, encoding='utf-8')) if os.path.exists(license_file) else []
new_components = json.load(open(new_comp_file, encoding='utf-8')) if os.path.exists(new_comp_file) else []

# Filter vulns to new components only (when baseline exists)
new_comp_set = set(new_components)
# Map package@version
def pkg_key(v):
    return f"{v.get('package','')}@{v.get('version','')}"

new_vulns = [v for v in vulns if pkg_key(v) in new_comp_set] if new_comp_set else vulns
existing_vulns = [v for v in vulns if pkg_key(v) not in new_comp_set]

from collections import Counter
new_by_sev = Counter(v['severity'] for v in new_vulns)

# Markdown report
report_md = f"""# QA SCA Report — {date}

**Branch:** {branch}

## Summary

| Metric | Count |
|--------|-------|
| New CVEs (Critical) | {new_by_sev.get('Critical', 0)} |
| New CVEs (High) | {new_by_sev.get('High', 0)} |
| New CVEs (Medium) | {new_by_sev.get('Medium', 0)} |
| New CVEs (Low) | {new_by_sev.get('Low', 0)} |
| License violations | {len(license_violations)} |
| New components (this PR) | {len(new_components)} |
| Suppressed (existing baseline) | {len(existing_vulns)} |

## New CVE Findings

| CVE | Severity | Package | Version | Fix Available |
|-----|----------|---------|---------|---------------|
""" + "\n".join(
    f"| {v['id']} | {v['severity']} | {v['package']} | {v['version']} | {', '.join(v.get('fix',[])) or 'none'} |"
    for v in new_vulns
) + f"""

## License Violations

| Package | Version | License |
|---------|---------|---------|
""" + "\n".join(
    f"| {lv['package']} | {lv['version']} | {lv['license']} |"
    for lv in license_violations
) + """

---
*Only new findings vs. previous SBOM baseline are reported as failures.*
"""

report_path = os.path.join(tmp, f'qa-sca-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write(report_md)
print(f"REPORT_WRITTEN: {report_path}")

# CTRF
fail_on_critical = os.environ.get('_SCA_FAIL_ON_CRITICAL', '1') == '1'
now_ms = int(time.time() * 1000)
tests = []

for v in new_vulns:
    sev = v['severity']
    name = f"CVE {v['id']} in {v['package']}@{v['version']}"
    if sev == 'Critical':
        status = 'failed'
    elif sev == 'High' and fail_on_critical:
        status = 'failed'
    else:
        status = 'skipped'
    tests.append({'name': name, 'status': status, 'duration': 0, 'suite': 'sca-cve'})

for lv in license_violations:
    tests.append({'name': f"License {lv['license']} in {lv['package']}@{lv['version']}",
                  'status': 'failed', 'duration': 0, 'suite': 'sca-license'})

if not tests:
    tests = [{'name': 'sca-scan', 'status': 'passed', 'duration': 0, 'suite': 'sca'}]

failed = sum(1 for t in tests if t['status'] == 'failed')
passed = sum(1 for t in tests if t['status'] == 'passed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')

ctrf = {
    'results': {
        'tool': {'name': 'qa-sca'},
        'summary': {'tests': len(tests), 'passed': passed, 'failed': failed,
                    'pending': 0, 'skipped': skipped, 'other': 0,
                    'start': now_ms - 30000, 'stop': now_ms},
        'tests': tests,
        'environment': {'reportName': 'qa-sca', 'branch': branch}
    }
}
ctrf_path = os.path.join(tmp, 'qa-sca-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
PYEOF
```

## Important Rules

- **Only report NEW findings vs. previous SBOM** when a baseline exists — suppress known-existing CVEs to reduce noise
- **License violations are always reported** regardless of `SCA_FAIL_ON_CRITICAL` setting
- **Degraded mode** (no syft/grype): emit WARN CTRF entry, do not FAIL
- **Critical CVEs always fail**; High CVEs fail only when `SCA_FAIL_ON_CRITICAL=1`
- **Medium/Low CVEs are skipped** (informational) — review manually

## Agent Memory

After each run, update `.claude/agent-memory/qa-sca/MEMORY.md` (create if absent). Record:
- Packages with known false positives or accepted risk
- License exceptions approved by legal
- SBOM baseline date and component count
- CVEs under active remediation

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-sca","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
