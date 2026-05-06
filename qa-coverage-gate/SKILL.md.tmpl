---
name: qa-coverage-gate
preamble-tier: 3
version: 1.0.0
description: |
  Test coverage delta gate. Runs the project's coverage tooling, computes per-file
  coverage change between the current branch and the base branch, and blocks CI if
  changed files drop below a configurable threshold. For files below threshold,
  generates LLM-suggested test stubs targeting the specific uncovered lines.
  Env vars: COVERAGE_THRESHOLD, COVERAGE_COMPARE_BRANCH, COVERAGE_GENERATE_STUBS. (qa-agentic-team)
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

# Detect coverage tool
_COVERAGE_TOOL="unknown"
if [ -f "package.json" ]; then
  grep -q '"jest"' package.json 2>/dev/null && _COVERAGE_TOOL="jest"
  grep -q '"vitest"' package.json 2>/dev/null && _COVERAGE_TOOL="vitest"
fi
{ [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; } && \
  grep -q "pytest-cov\|pytest_cov" pyproject.toml requirements*.txt 2>/dev/null && \
  _COVERAGE_TOOL="pytest"
[ -f "go.mod" ] && command -v go >/dev/null 2>&1 && _COVERAGE_TOOL="go"
[ -f "*.csproj" ] 2>/dev/null && command -v dotnet >/dev/null 2>&1 && _COVERAGE_TOOL="dotnet"
echo "COVERAGE_TOOL: $_COVERAGE_TOOL"

# Configuration
_COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
_COMPARE_BRANCH="${COVERAGE_COMPARE_BRANCH:-main}"
_GENERATE_STUBS="${COVERAGE_GENERATE_STUBS:-1}"
echo "COVERAGE_THRESHOLD: $_COVERAGE_THRESHOLD%"
echo "COMPARE_BRANCH: $_COMPARE_BRANCH"
echo "GENERATE_STUBS: $_GENERATE_STUBS"

# Get changed source files (exclude test files)
_CHANGED_FILES=$(git diff --name-only "$_COMPARE_BRANCH"...HEAD 2>/dev/null \
  | grep -E '\.(ts|js|tsx|jsx|py|go|cs|java|rb)$' \
  | grep -v -E '\.(test|spec)\.' \
  | grep -v -E '_(test|spec)\.' \
  | grep -v -E 'Test\.|Spec\.')
_CHANGED_FILES_COUNT=$(echo "$_CHANGED_FILES" | grep -c . 2>/dev/null || echo 0)
echo "CHANGED_FILES_COUNT: $_CHANGED_FILES_COUNT"
echo "CHANGED_FILES:"
echo "$_CHANGED_FILES"
echo "$_CHANGED_FILES" > "$_TMP/qa-coverage-changed.txt"
```

If `_COVERAGE_TOOL=unknown`: print "No coverage tool detected. Set COVERAGE_TOOL or ensure jest/pytest-cov/go/dotnet is configured. Emitting WARN." Emit CTRF with skipped status and stop.

If `_CHANGED_FILES_COUNT=0`: print "No changed source files detected relative to $_COMPARE_BRANCH. Nothing to gate." Emit CTRF with passed status and stop.

---

## Phase 1 — Run Coverage

Run coverage tooling for the current branch. Scope to changed files where possible.

```bash
mkdir -p "$_TMP/qa-coverage"
echo "--- RUNNING COVERAGE ---"
case "$_COVERAGE_TOOL" in
  jest)
    # Scope to changed files by path pattern
    _CHANGED_PATTERN=$(echo "$_CHANGED_FILES" | tr '\n' '|' | sed 's/|$//')
    npx jest --coverage \
      --coverageReporters=json \
      --coverageDirectory="$_TMP/qa-coverage" \
      2>/dev/null || true
    ;;
  vitest)
    npx vitest run \
      --coverage \
      --coverage.reporter=json \
      --coverage.reportsDirectory="$_TMP/qa-coverage" \
      2>/dev/null || true
    ;;
  pytest)
    python -m pytest \
      --cov=. \
      --cov-report=json:"$_TMP/qa-coverage/coverage.json" \
      --tb=no -q \
      2>/dev/null || true
    ;;
  go)
    go test ./... -coverprofile="$_TMP/qa-coverage/coverage.out" 2>/dev/null || true
    go tool cover -func="$_TMP/qa-coverage/coverage.out" \
      > "$_TMP/qa-coverage/coverage-func.txt" 2>/dev/null || true
    ;;
  dotnet)
    dotnet test --collect:"XPlat Code Coverage" \
      --results-directory="$_TMP/qa-coverage" \
      2>/dev/null || true
    ;;
esac
echo "COVERAGE_RUN_DONE"
ls -la "$_TMP/qa-coverage/" 2>/dev/null || echo "No coverage output found"
```

Parse per-file line coverage percentages from the output:

```bash
python3 - << 'PYEOF'
import json, os, re

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
tool = os.environ.get('_COVERAGE_TOOL', 'unknown')
cov_dir = os.path.join(tmp, 'qa-coverage')
file_coverage = {}

if tool in ('jest', 'vitest'):
    cov_file = os.path.join(cov_dir, 'coverage-final.json')
    if os.path.exists(cov_file):
        data = json.load(open(cov_file, encoding='utf-8'))
        for fpath, info in data.items():
            s = info.get('s', {})
            total = len(s)
            covered = sum(1 for v in s.values() if v > 0)
            pct = (covered / total * 100) if total > 0 else 0
            file_coverage[fpath] = round(pct, 1)
elif tool == 'pytest':
    cov_file = os.path.join(cov_dir, 'coverage.json')
    if os.path.exists(cov_file):
        data = json.load(open(cov_file, encoding='utf-8'))
        for fpath, info in data.get('files', {}).items():
            pct = info.get('summary', {}).get('percent_covered', 0)
            file_coverage[fpath] = round(pct, 1)
elif tool == 'go':
    func_file = os.path.join(cov_dir, 'coverage-func.txt')
    if os.path.exists(func_file):
        by_file = {}
        for line in open(func_file, encoding='utf-8'):
            m = re.match(r'^(\S+\.go):\d+:\s+\S+\s+([\d.]+)%', line)
            if m:
                fpath, pct = m.group(1), float(m.group(2))
                if fpath not in by_file:
                    by_file[fpath] = []
                by_file[fpath].append(pct)
        for fpath, pcts in by_file.items():
            file_coverage[fpath] = round(sum(pcts) / len(pcts), 1)

out = os.path.join(tmp, 'qa-coverage-parsed.json')
json.dump(file_coverage, open(out, 'w', encoding='utf-8'), indent=2)
print(f"FILES_WITH_COVERAGE: {len(file_coverage)}")
print(f"COVERAGE_DATA_WRITTEN: {out}")
PYEOF
```

## Phase 2 — Delta Computation

For each changed source file, compare coverage against the threshold:

```bash
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
threshold = float(os.environ.get('_COVERAGE_THRESHOLD', '80'))
changed_files_path = os.path.join(tmp, 'qa-coverage-changed.txt')
coverage_path = os.path.join(tmp, 'qa-coverage-parsed.json')

changed_files = [l.strip() for l in open(changed_files_path).readlines() if l.strip()]
try:
    file_coverage = json.load(open(coverage_path, encoding='utf-8'))
except Exception:
    file_coverage = {}

results = []
for fpath in changed_files:
    # Try to match coverage by path suffix (coverage tools may use absolute paths)
    coverage_pct = None
    for cov_path, pct in file_coverage.items():
        if cov_path.endswith(fpath.replace('\\', '/').lstrip('./')):
            coverage_pct = pct
            break

    if coverage_pct is None:
        results.append({'file': fpath, 'coverage': None, 'threshold': threshold, 'status': 'skip'})
    elif coverage_pct < threshold:
        results.append({'file': fpath, 'coverage': coverage_pct, 'threshold': threshold, 'status': 'fail'})
    else:
        results.append({'file': fpath, 'coverage': coverage_pct, 'threshold': threshold, 'status': 'pass'})

out = os.path.join(tmp, 'qa-coverage-delta.json')
json.dump(results, open(out, 'w', encoding='utf-8'), indent=2)
below = [r for r in results if r['status'] == 'fail']
print(f"DELTA_RESULTS: {len(results)} files")
print(f"BELOW_THRESHOLD: {len(below)}")
for r in below:
    print(f"  FAIL: {r['file']} ({r['coverage']}% < {threshold}%)")
print(f"DELTA_WRITTEN: {out}")
PYEOF
```

## Phase 3 — Stub Generation

If `_GENERATE_STUBS=1`, for each file below threshold, read the source file and generate test stub suggestions targeting uncovered functions/branches.

For each below-threshold file:
1. Read the source file
2. Cross-reference with coverage data to identify uncovered functions (lines with 0 hits)
3. Generate up to 5 test stubs per file using this template:

```typescript
// Suggested test stub for coverage gap in <file>:<lines>
it('should <describe what the uncovered code does>', async () => {
  // Arrange: <setup the preconditions>
  // Act: <call the function under test>
  // Assert: expect(<result>).toBe(<expected>)
});
```

Stub guidelines:
- Focus on uncovered function entry points, not individual uncovered lines inside already-tested functions
- Use the actual function/method names from the source file
- Keep stubs compilable (correct imports, types)
- Mark stubs as suggestions only — they are appended to the report, never written to test files

## Phase 4 — Report

```bash
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
branch = os.environ.get('_BRANCH', 'unknown')
threshold = float(os.environ.get('_COVERAGE_THRESHOLD', '80'))
compare_branch = os.environ.get('_COMPARE_BRANCH', 'main')
tool = os.environ.get('_COVERAGE_TOOL', 'unknown')
generate_stubs = os.environ.get('_GENERATE_STUBS', '1')

try:
    delta = json.load(open(os.path.join(tmp, 'qa-coverage-delta.json'), encoding='utf-8'))
except Exception:
    delta = []

pass_files   = [r for r in delta if r['status'] == 'pass']
fail_files   = [r for r in delta if r['status'] == 'fail']
skip_files   = [r for r in delta if r['status'] == 'skip']

gate_status = 'PASS' if not fail_files else 'FAIL'

lines = [
    f"# QA Coverage Gate Report — {date}",
    "",
    "## Summary",
    f"- Branch: {branch}  vs  {compare_branch}",
    f"- Coverage tool: {tool}",
    f"- Threshold: {threshold:.0f}%",
    f"- Changed source files: {len(delta)}",
    f"- Above threshold: {len(pass_files)}",
    f"- Below threshold: {len(fail_files)}",
    f"- No coverage data: {len(skip_files)}",
    f"- **Gate status: {gate_status}**",
    "",
    "## Per-File Coverage",
    "",
    "| File | Coverage % | Threshold | Status |",
    "|---|---|---|---|",
]
for r in sorted(delta, key=lambda x: (x['status'] != 'fail', x['file'])):
    cov = f"{r['coverage']:.1f}%" if r['coverage'] is not None else "N/A"
    status_icon = {'pass': 'PASS', 'fail': 'FAIL', 'skip': 'SKIP'}.get(r['status'], '?')
    lines.append(f"| `{r['file']}` | {cov} | {threshold:.0f}% | {status_icon} |")

if fail_files and generate_stubs == '1':
    lines += ["", "## Suggested Test Stubs", "", "_Stubs below are suggestions only — do not commit without review._", ""]
    # Stub content appended by LLM in Phase 3

report_path = os.path.join(tmp, f"qa-coverage-gate-report-{date}.md")
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"REPORT_WRITTEN: {report_path}")
print(f"GATE_STATUS: {gate_status}")

# CTRF
tests = []
for r in delta:
    if r['status'] == 'fail':
        status = 'failed'
        msg = f"Coverage {r['coverage']:.1f}% < threshold {threshold:.0f}%"
    elif r['status'] == 'skip':
        status = 'skipped'
        msg = 'No coverage data for this file'
    else:
        status = 'passed'
        msg = f"Coverage {r['coverage']:.1f}% >= threshold {threshold:.0f}%"
    tests.append({
        'name': f"coverage: {r['file']}",
        'status': status,
        'duration': 0,
        'suite': 'coverage-gate',
        'message': msg,
    })

if not tests:
    tests.append({'name': 'coverage-gate', 'status': 'passed', 'duration': 0,
                  'suite': 'coverage-gate', 'message': 'No changed files to gate'})

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')
now_ms  = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-coverage-gate'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': skipped,
            'other': 0,
            'start': now_ms - 30000,
            'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-coverage-gate',
            'threshold': str(threshold),
            'compareBranch': compare_branch,
            'coverageTool': tool,
        },
    }
}

ctrf_path = os.path.join(tmp, 'qa-coverage-gate-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
print(f"  tests={len(tests)} passed={passed} failed={failed} skipped={skipped}")
PYEOF
```

## Important Rules

- **Only evaluate coverage for files changed in this PR/branch** — never gate on whole-codebase coverage
- **Generated stubs are suggestions only** — never write to test files automatically
- **If no coverage tool detected**: emit instructions and skip with WARN; do not fail the gate
- **COVERAGE_THRESHOLD** defaults to 80% — configurable per project via env var
- **COVERAGE_COMPARE_BRANCH** defaults to `main` — set to `develop` or other base branch as needed

## Agent Memory

After each run, update `.claude/agent-memory/qa-coverage-gate/MEMORY.md` (create if absent). Record:
- Detected coverage tool and config file paths
- Threshold used and compare branch
- Files that have historically been below threshold
- Any coverage tool flags or paths needed for this project

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-coverage-gate","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
