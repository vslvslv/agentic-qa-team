---
name: qa-intent-assert
preamble-tier: 3
version: 1.0.0
description: |
  Natural-language code property assertions via LLM judge. Reads *.intent.yaml files from the project defining plain-English properties that code must satisfy ('This function must never return a negative balance'), then evaluates each assertion against the target code using an LLM judge. Novel assertion paradigm that catches semantic intent violations that unit tests miss. Env vars: INTENT_STRICT, INTENT_DIR. (qa-agentic-team)
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

# Configurable search root
_INTENT_DIR="${INTENT_DIR:-.}"

# Discover intent files
_INTENT_FILES=$(find $_INTENT_DIR -name "*.intent.yaml" ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)
_INTENT_FILE_COUNT=$(echo "$_INTENT_FILES" | grep -c . 2>/dev/null || echo 0)
echo "INTENT_FILES_FOUND: $_INTENT_FILE_COUNT"
echo "$_INTENT_FILES"

# Strict mode: 0=warn on violations, 1=fail CI on violations
_INTENT_STRICT="${INTENT_STRICT:-0}"
echo "INTENT_STRICT: $_INTENT_STRICT (0=advisory, 1=fail on violations)"
echo "--- DONE ---"
```

If no intent files found: print the following guidance and exit gracefully (non-blocking):

```
No *.intent.yaml files found. Create intent assertion files to enable this gate. Example:

# example.intent.yaml
assertions:
  - id: "INT-001"
    assertion: "This function must never return a negative balance"
    target: "src/billing/calculate.ts:calculateBalance"
    severity: critical  # critical|major|minor
  - id: "INT-002"
    assertion: "All API endpoints must validate user authentication before processing"
    target: "src/api/**/*.ts"  # glob supported
    severity: major
```

Write `$_TMP/qa-intent-assert-ctrf.json` with a single `skipped` test and exit cleanly.

## Intent File Format

Each `*.intent.yaml` file follows this schema:

```yaml
# example.intent.yaml
assertions:
  - id: "INT-001"
    assertion: "This function must never return a negative balance"
    target: "src/billing/calculate.ts:calculateBalance"
    severity: critical  # critical|major|minor
  - id: "INT-002"
    assertion: "All API endpoints must validate user authentication before processing"
    target: "src/api/**/*.ts"  # glob supported — reads all matching files as combined context
    severity: major
```

Fields:
- `id`: unique identifier for the assertion (e.g., `INT-001`)
- `assertion`: plain-English property statement the code must satisfy
- `target`: file path, `file:function` pair, or glob pattern
- `severity`: `critical` (always blocks regardless of INTENT_STRICT) | `major` | `minor`

## Phase 1 — Parse Intent Files

For each `.intent.yaml` file in `$_INTENT_FILES`:

```bash
for _if in $_INTENT_FILES; do
  echo "=== PARSING: $_if ==="
  python3 - "$_if" << 'PYEOF'
import yaml, sys
try:
    data = yaml.safe_load(open(sys.argv[1]))
    assertions = data.get('assertions', [])
    print(f"ASSERTIONS: {len(assertions)}")
    for a in assertions:
        print(f"  ID={a.get('id','?')}  severity={a.get('severity','minor')}  target={a.get('target','?')}")
        print(f"    assertion: {str(a.get('assertion',''))[:100]}")
except Exception as e:
    print(f"PARSE_ERROR: {e}")
PYEOF
done
```

Build a flat list: `{id, assertion, target, severity}`. Count total: `_ASSERTION_COUNT`.

For each `target`:
- If it contains `*` (glob): expand with `find` + pattern matching, read all matching files as combined context
- If it contains `:` (file:function): read file, then isolate the function body via Grep
- Otherwise: treat as a file path and read the full file

If a target resolves to zero files: emit `WARN: target not found — {target}` and mark assertion as `skipped`.

## Phase 2 — Evaluate Each Assertion

For each assertion with a resolved target:

1. Read target file(s) content using the Read tool (or Grep for function isolation)
2. Build LLM judge prompt:

```
Code property assertion: '<assertion>'

Target code:
<code>

Does this code satisfy the stated property? Respond with:
VERDICT: PASS or FAIL
CONFIDENCE: HIGH/MEDIUM/LOW
REASONING: <1-2 sentences>
If FAIL: VIOLATION: <what specifically violates it>
```

3. Parse LLM response:
   - Extract `VERDICT: PASS` or `VERDICT: FAIL`
   - Extract `CONFIDENCE: HIGH/MEDIUM/LOW`
   - Extract `REASONING:` text
   - Extract `VIOLATION:` text (if FAIL)

4. Apply confidence filter:
   - `LOW` confidence → mark as `skipped` with note "LOW confidence — assertion requires manual review"
   - `MEDIUM` or `HIGH` confidence → proceed with PASS/FAIL verdict

5. Record: `{id, assertion, target, verdict, confidence, reasoning, violation}`

Evaluate each assertion independently — do not share code context between assertions.

## Phase 3 — Report + CTRF

Write `$_TMP/qa-intent-assert-report-$_DATE.md`:

```markdown
# QA Intent Assertions Report — <date> (<branch>)

> **Note**: These are LLM-judged assertions, not deterministic tests.
> Results reflect the LLM judge's confidence-weighted evaluation of code properties.
> Only HIGH and MEDIUM confidence verdicts are recorded as PASS/FAIL.

## Summary
- Total assertions: <n>
- Passed: <n> | Failed: <n> | Skipped (low confidence or missing target): <n>
- Strict mode: <INTENT_STRICT>
- Overall status: PASS / FAIL / WARN

## Assertion Results

| ID | Assertion | Target | Verdict | Confidence | Reasoning |
|----|-----------|--------|---------|------------|-----------|

## Violations

<For each FAIL with HIGH/MEDIUM confidence: assertion ID, full text, target, violation detail, recommended fix>

## Skipped (Low Confidence or Missing Targets)

<For each skipped: ID, assertion, reason for skip>
```

Write `$_TMP/qa-intent-assert-ctrf.json`:
- PASS verdict (HIGH/MEDIUM confidence) = `passed`
- FAIL verdict + `severity: critical` = `failed` (always, regardless of INTENT_STRICT)
- FAIL verdict + `INTENT_STRICT=1` = `failed`
- FAIL verdict + `INTENT_STRICT=0` = `skipped` with note "advisory violation"
- LOW confidence verdict = `skipped` with note "LOW confidence — requires manual review"
- Missing target = `skipped`

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
strict = os.environ.get('INTENT_STRICT', '0') == '1'
date = os.environ.get('_DATE', 'unknown')
report_path = os.path.join(tmp, f'qa-intent-assert-report-{date}.md')

tests = []
if os.path.exists(report_path):
    import re
    content = open(report_path, encoding='utf-8', errors='replace').read()
    # Extract from assertion table: | ID | Assertion | Target | Verdict | Confidence | Reasoning |
    for line in content.splitlines():
        m = re.match(r'\|\s*(\S+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(PASS|FAIL)\s*\|\s*(HIGH|MEDIUM|LOW)\s*\|\s*(.+?)\s*\|', line)
        if m:
            aid, assertion, target, verdict, confidence, reasoning = m.groups()
            if confidence == 'LOW':
                status = 'skipped'
                msg = f'LOW confidence — requires manual review'
            elif verdict == 'FAIL':
                # critical severity always fails; else respect INTENT_STRICT
                status = 'failed' if strict else 'skipped'
                msg = f'Violation: {reasoning}'
            else:
                status = 'passed'
                msg = ''
            tests.append({
                'name': f'{aid}: {assertion[:60]}',
                'status': status,
                'duration': 0,
                'suite': 'qa-intent-assert',
                'message': msg,
            })

if not tests:
    tests.append({
        'name': 'intent-assert-gate', 'status': 'skipped', 'duration': 0,
        'suite': 'qa-intent-assert', 'message': 'No intent assertions evaluated',
    })

p = sum(1 for t in tests if t['status'] == 'passed')
f = sum(1 for t in tests if t['status'] == 'failed')
s = sum(1 for t in tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {
            'name': 'qa-intent-assert',
            'custom': {'strict_mode': strict, 'assertion_paradigm': 'llm-judge'},
        },
        'summary': {
            'tests': len(tests), 'passed': p, 'failed': f,
            'pending': 0, 'skipped': s, 'other': 0,
            'start': now_ms - 10000, 'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-intent-assert',
            'intentStrict': strict,
        },
    }
}
out = os.path.join(tmp, 'qa-intent-assert-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  passed={p} failed={f} skipped={s}  strict={strict}')
PYEOF
```

## Important Rules

- **Only report HIGH or MEDIUM confidence violations** — LOW confidence verdicts are skipped with a note; do not surface them as failures
- **Glob targets**: expand all matching files and pass them as combined context to the LLM judge
- **INTENT_STRICT=0 (default)** — violations are advisory (skipped in CTRF); useful for gradual adoption
- **Novel paradigm disclaimer** — be explicit in the report that these are LLM-judged assertions, not deterministic tests; results may vary
- **severity: critical overrides strict mode** — critical assertions always fail regardless of INTENT_STRICT setting
- **Never modify intent files** — qa-intent-assert is read-only with respect to `.intent.yaml` files
- **Target not found = WARN not FAIL** — target files may have been moved or renamed; suggest updating the intent file

## Agent Memory

After each run, update `.claude/agent-memory/qa-intent-assert/MEMORY.md` (create if absent). Record:
- Intent file paths found and the assertion counts
- Any assertions that consistently FAIL across runs (candidates for code fix or intent update)
- Any target files that no longer exist (stale intents)
- Whether strict mode is in use for this project
