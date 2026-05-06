---
name: qa-test-lint
preamble-tier: 3
version: 1.0.0
description: |
  Test smell and anti-pattern linter. Statically scans test files for known quality issues:
  assertion-free tests, sleep() calls, magic numbers, permanently skipped tests, empty
  describe blocks, console.log leakage, and copy-paste test bodies. LLM categorizes each
  smell by type and severity and generates inline fix suggestions.
  Env vars: TEST_LINT_SEVERITY. (qa-agentic-team)
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

# Discover all test files
_TEST_FILES=$(find . -type f \( \
  -name "*.test.ts" -o -name "*.spec.ts" \
  -o -name "*.test.js" -o -name "*.spec.js" \
  -o -name "*_test.py" -o -name "*_test.go" \
  -o -name "*Test.java" -o -name "*Spec.rb" \
\) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)
_TEST_FILE_COUNT=$(echo "$_TEST_FILES" | grep -c . 2>/dev/null || echo 0)
echo "TEST_FILE_COUNT: $_TEST_FILE_COUNT"

# Lint severity mode
_LINT_SEVERITY="${TEST_LINT_SEVERITY:-warn}"
echo "LINT_SEVERITY: $_LINT_SEVERITY  (warn=non-blocking, error=blocking)"

# Detect test file patterns present
echo "--- TEST FILE PATTERN DETECTION ---"
echo "$_TEST_FILES" | grep -c "\.test\.\(ts\|js\)" 2>/dev/null | xargs -I{} echo "jest/vitest style (.test.*): {}" || true
echo "$_TEST_FILES" | grep -c "\.spec\.\(ts\|js\)" 2>/dev/null | xargs -I{} echo "playwright/jest style (.spec.*): {}" || true
echo "$_TEST_FILES" | grep -c "_test\.py" 2>/dev/null | xargs -I{} echo "pytest style (*_test.py): {}" || true
echo "$_TEST_FILES" | grep -c "_test\.go" 2>/dev/null | xargs -I{} echo "go test style (*_test.go): {}" || true
echo "$_TEST_FILES" | grep -c "Test\.java" 2>/dev/null | xargs -I{} echo "JUnit style (*Test.java): {}" || true
echo "$_TEST_FILES" | grep -c "Spec\.rb" 2>/dev/null | xargs -I{} echo "RSpec style (*Spec.rb): {}" || true

# Save file list for phases
echo "$_TEST_FILES" > "$_TMP/qa-lint-test-files.txt"
echo "FILE_LIST_WRITTEN: $_TMP/qa-lint-test-files.txt"
```

If `_TEST_FILE_COUNT` is 0: print "No test files found — nothing to lint. Exiting." and stop.

---

## Phase 1 — Static Scan

For each test file discovered in the preamble, run grep-based smell detection. Collect all findings into `$_TMP/qa-lint-smells.json`.

```bash
python3 - << 'PYEOF'
import subprocess, json, os, re, hashlib

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
file_list_path = os.path.join(tmp, 'qa-lint-test-files.txt')

try:
    test_files = [l.strip() for l in open(file_list_path).readlines() if l.strip()]
except Exception as e:
    print(f"ERROR reading file list: {e}")
    test_files = []

smells = []

def grep_file(path, pattern):
    try:
        result = subprocess.run(
            ['grep', '-n', '-E', pattern, path],
            capture_output=True, text=True
        )
        matches = []
        for line in result.stdout.splitlines():
            parts = line.split(':', 1)
            if len(parts) == 2:
                try:
                    matches.append((int(parts[0]), parts[1].strip()))
                except ValueError:
                    pass
        return matches
    except Exception:
        return []

def read_lines(path):
    try:
        return open(path, encoding='utf-8', errors='replace').readlines()
    except Exception:
        return []

def add_smell(file, lineno, smell_type, snippet, extra=None):
    smells.append({
        'file': file,
        'line': lineno,
        'type': smell_type,
        'snippet': snippet[:120],
        'extra': extra or '',
    })

def normalize_body(lines):
    return re.sub(r'\s+', ' ', ' '.join(lines)).strip()

function_bodies = {}  # hash -> [(file, lineno)]

for fpath in test_files:
    lines = read_lines(fpath)

    # SMELL: timing-dependency — sleep() / time.Sleep() / setTimeout
    for lineno, line in grep_file(fpath, r'sleep\s*\(|time\.Sleep\s*\(|setTimeout\s*\(|asyncio\.sleep\s*\('):
        add_smell(fpath, lineno, 'timing-dependency', line)

    # SMELL: trivial-assertion — .toBe(true) or assert True
    for lineno, line in grep_file(fpath, r'\.toBe\(\s*true\s*\)|assert\s+True\b|assertEquals\s*\(\s*true'):
        add_smell(fpath, lineno, 'trivial-assertion', line)

    # SMELL: permanent-skip — skipped tests
    for lineno, line in grep_file(fpath, r'it\.skip\s*\(|describe\.skip\s*\(|xit\s*\(|xdescribe\s*\(|@pytest\.mark\.skip|@Ignore|pending\s*\('):
        extra = ''
        try:
            result = subprocess.run(
                ['git', 'log', '-1', '--format=%ar', '--', fpath],
                capture_output=True, text=True, timeout=5
            )
            extra = result.stdout.strip() or 'unknown'
        except Exception:
            extra = 'git-unavailable'
        add_smell(fpath, lineno, 'permanent-skip', line, extra=f'last_modified={extra}')

    # SMELL: empty-suite — describe block with no it/test inside
    content = ''.join(lines)
    for m in re.finditer(r'(?:describe|context)\s*\([^,)]+,\s*\(\s*\)\s*=>\s*\{([^}]*)\}', content):
        body = m.group(1)
        if not re.search(r'\bit\s*\(|\btest\s*\(', body):
            lineno = content[:m.start()].count('\n') + 1
            add_smell(fpath, lineno, 'empty-suite', m.group(0)[:80])

    # SMELL: debug-leak — console.log / print inside test functions
    for lineno, line in grep_file(fpath, r'console\.\s*log\s*\(|System\.out\.print|puts\s+|fmt\.Print'):
        add_smell(fpath, lineno, 'debug-leak', line)

    # SMELL: magic-number — hardcoded numbers in assertions
    for lineno, line in grep_file(fpath, r'\.toBe\s*\(\s*[0-9]{2,}\s*\)|assertEqual\s*\([^,]*,\s*[0-9]{2,}|assertEquals\s*\([0-9]{2,}'):
        add_smell(fpath, lineno, 'magic-number', line)

    # SMELL: assertion-free — test function with no expect/assert
    in_test = False
    brace_depth = 0
    test_start = 0
    test_body_lines = []
    has_assertion = False
    for i, line_text in enumerate(lines):
        if not in_test:
            if re.search(r'^\s*(?:it|test)\s*\(', line_text):
                in_test = True
                brace_depth = 0
                test_start = i + 1
                test_body_lines = []
                has_assertion = False
        if in_test:
            test_body_lines.append(line_text)
            brace_depth += line_text.count('{') - line_text.count('}')
            if re.search(r'expect\s*\(|assert\s*\(|should\.|assertEqual|assertThat|toBe|toEqual|toContain|assert_', line_text):
                has_assertion = True
            if brace_depth <= 0 and len(test_body_lines) > 1:
                in_test = False
                if not has_assertion and len(test_body_lines) > 2:
                    add_smell(fpath, test_start, 'assertion-free',
                              test_body_lines[0].strip()[:80])
                # Duplicate body detection (>10 lines)
                if len(test_body_lines) > 10:
                    normalized = normalize_body(test_body_lines)
                    body_hash = hashlib.md5(normalized.encode()).hexdigest()
                    if body_hash not in function_bodies:
                        function_bodies[body_hash] = []
                    function_bodies[body_hash].append((fpath, test_start))

# SMELL: duplicate-body — same function body in 2+ tests
for body_hash, locations in function_bodies.items():
    if len(locations) >= 2:
        for fpath, lineno in locations:
            add_smell(fpath, lineno, 'duplicate-body',
                      f'Duplicate test body shared with {len(locations)} tests',
                      extra=f'hash={body_hash[:8]} copies={len(locations)}')

out = os.path.join(tmp, 'qa-lint-smells.json')
json.dump(smells, open(out, 'w', encoding='utf-8'), indent=2)
print(f"SMELLS_FOUND: {len(smells)}")
print(f"SMELLS_WRITTEN: {out}")

by_type = {}
for s in smells:
    by_type[s['type']] = by_type.get(s['type'], 0) + 1
for t, count in sorted(by_type.items(), key=lambda x: -x[1]):
    print(f"  {t}: {count}")
PYEOF
```

---

## Phase 2 — LLM Analysis

Read `$_TMP/qa-lint-smells.json`. For each smell instance, apply severity rules and generate fix suggestions.

Severity classification:

| Smell Type | Severity | Why It's a Problem |
|---|---|---|
| `assertion-free` | critical | Test always passes regardless of code behavior — provides zero coverage value |
| `timing-dependency` | major | Makes suite flaky; CI failures increase with parallelism |
| `permanent-skip` | major (>30 days), minor otherwise | Dead test code; business rules no longer verified |
| `duplicate-body` | major | Copy-paste tests miss edge cases; break identically |
| `empty-suite` | minor | Placeholder never filled in; silently adds 0 coverage |
| `debug-leak` | minor | Pollutes CI output; can expose PII in logs |
| `magic-number` | minor | Intent unclear; breaks silently when the value changes |
| `trivial-assertion` | minor | Tests `true === true`; don't verify real behavior |

Fix suggestion examples per type:
- **assertion-free**: `expect(result).toBeDefined()` or appropriate domain assertion
- **timing-dependency**: Replace `sleep(100)` with `await waitFor(() => expect(element).toBeVisible())`
- **permanent-skip**: Delete the test or re-enable with a TODO issue link
- **debug-leak**: Remove or replace with a suppressed test logger
- **magic-number**: `const EXPECTED_STATUS = 404; expect(res.status).toBe(EXPECTED_STATUS)`
- **duplicate-body**: Extract shared setup to `beforeEach` or a helper factory function

```bash
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
smells = json.load(open(os.path.join(tmp, 'qa-lint-smells.json'), encoding='utf-8'))

SEVERITY_MAP = {
    'assertion-free':     'critical',
    'timing-dependency':  'major',
    'permanent-skip':     'major',
    'empty-suite':        'minor',
    'debug-leak':         'minor',
    'magic-number':       'minor',
    'trivial-assertion':  'minor',
    'duplicate-body':     'major',
}

for s in smells:
    s['severity'] = SEVERITY_MAP.get(s['type'], 'minor')
    # Downgrade permanent-skip if recently modified (<30 days)
    if s['type'] == 'permanent-skip' and 'last_modified=' in s.get('extra', ''):
        age_str = s['extra'].replace('last_modified=', '')
        if any(x in age_str for x in ['hours', 'minutes'] + [f'{n} day' for n in range(1, 31)]):
            s['severity'] = 'minor'

enriched_path = os.path.join(tmp, 'qa-lint-enriched.json')
json.dump(smells, open(enriched_path, 'w', encoding='utf-8'), indent=2)

by_severity = {}
for s in smells:
    by_severity[s['severity']] = by_severity.get(s['severity'], 0) + 1
print(f"ENRICHED_WRITTEN: {enriched_path}")
print(f"BY_SEVERITY: {by_severity}")
PYEOF
```

---

## Phase 3 — Report

```bash
python3 - << 'PYEOF'
import json, os, time
from collections import defaultdict

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
severity_mode = os.environ.get('_LINT_SEVERITY', 'warn')

try:
    smells = json.load(open(os.path.join(tmp, 'qa-lint-enriched.json'), encoding='utf-8'))
except Exception:
    smells = []

by_type = defaultdict(lambda: {'count': 0, 'severity': 'minor'})
for s in smells:
    by_type[s['type']]['count'] += 1
    by_type[s['type']]['severity'] = s['severity']

by_file = defaultdict(list)
for s in smells:
    by_file[s['file']].append(s)

lines = [
    f"# QA Test Lint Report — {date}",
    "",
    "## Summary",
    f"- Total smells: {len(smells)}",
    f"- Severity mode: {severity_mode}",
    "",
    "## Smell Summary Table",
    "",
    "| Smell Type | Count | Severity |",
    "|---|---|---|",
]
sev_order = {'critical': 0, 'major': 1, 'minor': 2}
for smell_type, info in sorted(by_type.items(), key=lambda x: sev_order.get(x[1]['severity'], 9)):
    lines.append(f"| `{smell_type}` | {info['count']} | {info['severity']} |")

lines += ["", "## Per-File Findings", ""]

FIX_MAP = {
    'assertion-free':    'Add `expect(result).toBeDefined()` or a domain-specific assertion',
    'timing-dependency': 'Replace sleep with `await waitFor(() => expect(el).toBeVisible())`',
    'permanent-skip':    'Delete the test or re-enable with a tracking issue link',
    'empty-suite':       'Add at least one `it()` test or remove the empty describe block',
    'debug-leak':        'Remove `console.log` or replace with a suppressed test logger',
    'magic-number':      'Extract to `const EXPECTED_VALUE = N; expect(x).toBe(EXPECTED_VALUE)`',
    'trivial-assertion': 'Replace with a meaningful assertion about the actual behavior',
    'duplicate-body':    'Extract shared setup to `beforeEach` or a helper factory function',
}

for fpath in sorted(by_file.keys()):
    file_smells = by_file[fpath]
    lines.append(f"### `{fpath}`")
    lines.append("")
    lines.append("| Line | Smell Type | Severity | Snippet | Suggested Fix |")
    lines.append("|---|---|---|---|---|")
    for s in sorted(file_smells, key=lambda x: x['line']):
        snippet = s['snippet'].replace("|", "\\|").replace("\n", " ")[:60]
        fix = FIX_MAP.get(s['type'], 'Review and refactor')
        lines.append(f"| {s['line']} | `{s['type']}` | {s['severity']} | `{snippet}` | {fix} |")
    lines.append("")

report_path = os.path.join(tmp, f"qa-test-lint-report-{date}.md")
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"REPORT_WRITTEN: {report_path}")

# CTRF
tests = []
for s in smells:
    status = 'failed' if (severity_mode == 'error' or s['severity'] == 'critical') else 'skipped'
    tests.append({
        'name': f"{s['type']}: {s['file']}:{s['line']}",
        'status': status,
        'duration': 0,
        'suite': 'test-lint',
        'message': s['snippet'][:200],
        'extra': {'severity': s['severity'], 'type': s['type']},
    })

if not tests:
    tests.append({'name': 'test-lint scan', 'status': 'passed', 'duration': 0, 'suite': 'test-lint', 'message': 'No smells found'})

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')
now_ms  = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-test-lint'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': skipped,
            'other': 0,
            'start': now_ms - 1000,
            'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-test-lint',
            'branch': os.environ.get('_BRANCH', 'unknown'),
            'lintSeverity': severity_mode,
        },
    }
}

ctrf_path = os.path.join(tmp, 'qa-test-lint-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
print(f"  tests={len(tests)} passed={passed} failed={failed} skipped={skipped}")
PYEOF
```

Print a final summary to the conversation:
- Total smells found, broken down by type and severity
- Path to the full report
- If `_LINT_SEVERITY=error` and any critical/major smells exist: print "LINT STATUS: FAIL"
- Otherwise: "LINT STATUS: WARN" or "LINT STATUS: PASS"

## Important Rules

- **Never modify test files** — this skill is report-only; treat all test files as read-only
- **Permanent-skip detection requires git** — if not in a git repo, skip the age check and classify all skips as `major`
- **Duplicate-body detection uses MD5 hash** of normalized (whitespace-collapsed) function bodies >10 lines
- **`assertion-free` detection is heuristic** — parameterized tests may produce false positives; flag but note they may be intentional
- **Empty-suite regex is simplified** — only catches single-level empty describe blocks; nested empties may be missed

## Agent Memory

After each run, update `.claude/agent-memory/qa-test-lint/MEMORY.md` (create if absent). Record:
- Test file patterns detected (extensions, naming conventions)
- Most common smell categories in this codebase
- Any false-positive patterns to skip in future runs

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-test-lint","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
