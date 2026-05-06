---
name: qa-test-docs
preamble-tier: 3
version: 1.0.0
description: |
  Test documentation generator. Reads existing test files and generates human-readable
  Markdown documentation summarizing what each test suite covers, which business rules
  it guards, which edge cases are addressed, and notable gaps. Groups tests by feature
  domain. Output is suitable for compliance audits, sprint reviews, and onboarding.
  Env vars: TEST_DOCS_OUTPUT, TEST_DOCS_FORMAT. (qa-agentic-team)
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

# Discover test files (same patterns as qa-test-lint)
_TEST_FILES=$(find . -type f \( \
  -name "*.test.ts" -o -name "*.spec.ts" \
  -o -name "*.test.js" -o -name "*.spec.js" \
  -o -name "*_test.py" -o -name "*_test.go" \
  -o -name "*Test.java" -o -name "*Spec.rb" \
\) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)
_TEST_FILE_COUNT=$(echo "$_TEST_FILES" | grep -c . 2>/dev/null || echo 0)
echo "TEST_FILE_COUNT: $_TEST_FILE_COUNT"

# Output config
_TEST_DOCS_OUTPUT="${TEST_DOCS_OUTPUT:-./test-docs}"
echo "OUTPUT_DIR: $_TEST_DOCS_OUTPUT"
_TEST_DOCS_FORMAT="${TEST_DOCS_FORMAT:-markdown}"
echo "FORMAT: $_TEST_DOCS_FORMAT  (markdown|confluence)"

# Cluster by parent directory
echo "--- DOMAIN DETECTION ---"
echo "$_TEST_FILES" | xargs -I{} dirname {} 2>/dev/null | sort -u | \
  grep -v "^\.$" | head -20 | while read dir; do
    _count=$(echo "$_TEST_FILES" | grep -c "^$dir" 2>/dev/null || echo 0)
    echo "  DOMAIN: $(basename $dir) ($dir) — $_count files"
  done

echo "$_TEST_FILES" > "$_TMP/qa-docs-test-files.txt"
echo "FILE_LIST_WRITTEN: $_TMP/qa-docs-test-files.txt"
```

If `_TEST_FILE_COUNT` is 0: print "No test files found — nothing to document." and stop.

---

## Phase 1 — Cluster

Group test files by domain:

```bash
python3 - << 'PYEOF'
import os, json, re
from collections import defaultdict

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
file_list = os.path.join(tmp, 'qa-docs-test-files.txt')
files = [l.strip() for l in open(file_list).readlines() if l.strip()]

clusters = defaultdict(list)

for fpath in files:
    parts = fpath.replace('\\', '/').split('/')
    # Find meaningful directory (skip ., src, test, tests, __tests__, spec)
    skip_dirs = {'.', 'src', 'test', 'tests', '__tests__', 'spec', 'specs', 'e2e'}
    domain = None
    for part in reversed(parts[:-1]):  # dirs from deepest to shallowest
        if part.lower() not in skip_dirs:
            domain = part
            break
    if domain is None:
        # Fall back to filename prefix (e.g., auth.spec.ts -> auth)
        fname = os.path.basename(fpath)
        m = re.match(r'^([a-zA-Z][a-zA-Z0-9_-]+?)[\._]', fname)
        domain = m.group(1) if m else 'miscellaneous'
    clusters[domain].append(fpath)

out = os.path.join(tmp, 'qa-docs-clusters.json')
json.dump(dict(clusters), open(out, 'w', encoding='utf-8'), indent=2)
print(f"DOMAINS_DETECTED: {len(clusters)}")
for domain, files in sorted(clusters.items()):
    print(f"  {domain}: {len(files)} file(s)")
print(f"CLUSTERS_WRITTEN: {out}")
PYEOF
```

## Phase 2 — LLM Documentation per Cluster

For each cluster, read all test files in the cluster and generate documentation. Use the following prompt structure:

**For each cluster `<domain>`**, read the test files and produce a documentation section:

```markdown
## <Domain Name>

**Test files:** `<file1>`, `<file2>`

**What this suite tests:**
<2–3 sentences describing the feature/component under test>

**Business rules guarded:**
- <Rule inferred from test names and assertions>
- <Rule 2>

**Edge cases covered:**
- <Edge case 1, e.g., empty input, null values, boundary conditions>
- <Edge case 2>

**Notable gaps or TODOs:**
- <Gap 1, e.g., "No tests for unauthenticated access">
- <Gap 2>

**Key test files:**
- `<path/to/file.spec.ts>` — <one-line summary of what this file tests>
```

Rules for LLM analysis:
- Infer intent from `describe`, `it`, `test` block names and assertion values
- Do not invent coverage claims — if unclear from test names, say "intent unclear from test name alone"
- Gap analysis is informational only — do not suggest blocking CI based on gaps
- For Confluence format: use `h2.`, `h3.`, and `*` markup instead of Markdown headings and bullets

## Phase 3 — Assemble Output

```bash
mkdir -p "$_TEST_DOCS_OUTPUT"
```

Write one `<domain>-tests.md` per cluster to `$_TEST_DOCS_OUTPUT/`.

Write `$_TEST_DOCS_OUTPUT/index.md` with:
- Introduction: project name, total test files, domains covered, generation date
- Summary table: `| Domain | Files | Business Rules | Edge Cases | Gaps |`
- Links to each `<domain>-tests.md`

## Phase 4 — Report

```bash
python3 - << 'PYEOF'
import json, os, time, glob

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
output_dir = os.environ.get('_TEST_DOCS_OUTPUT', './test-docs')
branch = os.environ.get('_BRANCH', 'unknown')

# Count generated files
doc_files = glob.glob(os.path.join(output_dir, '*-tests.md'))
clusters = {}
try:
    clusters = json.load(open(os.path.join(tmp, 'qa-docs-clusters.json'), encoding='utf-8'))
except Exception:
    pass

lines = [
    f"# QA Test Documentation Report — {date}",
    "",
    "## Summary",
    f"- Branch: {branch}",
    f"- Domains documented: {len(doc_files)}",
    f"- Total clusters found: {len(clusters)}",
    f"- Output directory: `{output_dir}`",
    "",
    "## Clusters",
    "",
    "| Domain | Files | Doc Generated |",
    "|---|---|---|",
]
for domain, files in sorted(clusters.items()):
    doc_path = os.path.join(output_dir, f"{domain}-tests.md")
    generated = "yes" if os.path.exists(doc_path) else "no"
    lines.append(f"| {domain} | {len(files)} | {generated} |")

report_path = os.path.join(tmp, f"qa-test-docs-report-{date}.md")
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"REPORT_WRITTEN: {report_path}")

# CTRF
tests = []
for domain, files_list in clusters.items():
    doc_path = os.path.join(output_dir, f"{domain}-tests.md")
    status = 'passed' if os.path.exists(doc_path) else 'failed'
    tests.append({
        'name': f'docs: {domain}',
        'status': status,
        'duration': 0,
        'suite': 'test-docs',
        'message': f'{len(files_list)} test file(s)',
    })

if not tests:
    tests.append({'name': 'test-docs generation', 'status': 'passed', 'duration': 0, 'suite': 'test-docs'})

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')
now_ms  = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-test-docs'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': skipped,
            'other': 0,
            'start': now_ms - 5000,
            'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-test-docs',
            'outputDir': output_dir,
            'format': os.environ.get('_TEST_DOCS_FORMAT', 'markdown'),
        },
    }
}

ctrf_path = os.path.join(tmp, 'qa-test-docs-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
print(f"  tests={len(tests)} passed={passed} failed={failed} skipped={skipped}")
PYEOF
```

## Important Rules

- **Generate docs for what IS tested** — not what should be tested
- **Gap analysis is informational only** — never block CI based on gaps
- **Confluence format** uses `h2.`, `h3.`, `*` markup instead of Markdown headings and bullets
- **Read test files only, never execute them**
- **Infer intent from test names** — if unclear, say so rather than guessing

## Agent Memory

After each run, update `.claude/agent-memory/qa-test-docs/MEMORY.md` (create if absent). Record:
- Cluster structure discovered (domain names and directories)
- Test naming conventions used in this codebase
- Output directory location
- Any files skipped due to context overflow

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-test-docs","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
