---
name: qa-env-parity
preamble-tier: 3
version: 1.0.0
description: |
  Environment configuration parity checker. Compares declared env vars, feature flags,
  and config keys across dev/staging/production environment files to detect silent drift
  that causes 'works in staging' failures. Generates a structured drift report with LLM
  classification of missing required keys, mismatched values, and stale orphaned entries.
  Env vars: PARITY_ENVIRONMENTS, PARITY_REQUIRED_KEYS. (qa-agentic-team)
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
_ENV_FILES=""
for f in .env .env.local .env.development .env.staging .env.production .env.test .env.example .env.sample; do
  [ -f "$f" ] && _ENV_FILES="$_ENV_FILES $f" && echo "ENV_FILE: $f"
done
# Also check Rails-style and TypeScript config files
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

If no `.env*` files found: suggest the user check for a `.env.example` or `.env.sample` template, emit a WARN CTRF entry, and exit gracefully — no further phases needed.

## Phase 1 — Parse Env Files

Read and parse each discovered `.env*` file into a key map, redacting actual values:

```python
python3 - << 'PYEOF'
import os, json, re

env_files_str = os.environ.get('_ENV_FILES', '').strip()
env_files = env_files_str.split() if env_files_str else []

# Files treated as documentation only (not environment configs)
DOC_FILES = {'.env.example', '.env.sample'}

def infer_env_name(filename):
    """Map filename to logical environment name."""
    mapping = {
        '.env': 'development',
        '.env.local': 'local',
        '.env.development': 'development',
        '.env.staging': 'staging',
        '.env.production': 'production',
        '.env.test': 'test',
    }
    return mapping.get(filename, filename.lstrip('.'))

def parse_env_file(filepath):
    """Parse a .env file, returning {KEY: '<set>'|'<empty>'} (values redacted)."""
    result = {}
    try:
        with open(filepath, encoding='utf-8', errors='replace') as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, _, val = line.partition('=')
                    key = key.strip()
                    val = val.strip().strip('"').strip("'")
                    if key:
                        result[key] = '<set>' if val else '<empty>'
    except Exception as e:
        print(f"PARSE_ERROR: {filepath} — {e}")
    return result

env_map = {}  # { env_name: { KEY: '<set>'|'<empty>' } }

for f in env_files:
    basename = os.path.basename(f)
    if basename in DOC_FILES:
        print(f"DOC_FILE_SKIPPED: {f} (treated as documentation, not environment config)")
        continue
    env_name = infer_env_name(basename)
    keys = parse_env_file(f)
    env_map[env_name] = keys
    print(f"PARSED: {f} -> env={env_name}, keys={len(keys)}")

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
out = os.path.join(tmp, 'qa-env-parity-map.json')
json.dump(env_map, open(out, 'w', encoding='utf-8'), indent=2)
print(f"ENV_MAP_WRITTEN: {out}  environments={list(env_map.keys())}")
PYEOF
```

## Phase 2 — Compute Diff Matrix

Build a cross-environment key matrix to identify missing and orphaned keys:

```python
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
map_file = os.path.join(tmp, 'qa-env-parity-map.json')

if not os.path.exists(map_file):
    print("ENV_MAP: not found — skipping diff"); exit(0)

env_map = json.load(open(map_file, encoding='utf-8'))
required_keys_str = os.environ.get('_REQUIRED_KEYS', '').strip()
required_keys = set(k.strip() for k in required_keys_str.split(',') if k.strip()) if required_keys_str else set()

# Collect all keys across all environments
all_keys = set()
for keys in env_map.values():
    all_keys.update(keys.keys())

envs = list(env_map.keys())

# Build diff matrix
matrix = {}  # { KEY: { env: '<set>'|'<empty>'|'<missing>' } }
for key in sorted(all_keys):
    row = {}
    for env in envs:
        row[env] = env_map[env].get(key, '<missing>')
    matrix[key] = row

# Categorise
present_all = [k for k, r in matrix.items() if '<missing>' not in r.values()]
missing_some = [k for k, r in matrix.items() if '<missing>' in r.values() and '<missing>' != list(r.values())[0] or
                (len(set(r.values())) > 1 and '<missing>' in r.values())]
unique_to_one = [k for k, r in matrix.items() if list(r.values()).count('<missing>') == len(envs) - 1]

print(f"KEYS_IN_ALL_ENVS: {len(present_all)}")
print(f"KEYS_MISSING_SOMEWHERE: {len(missing_some)}")
print(f"KEYS_UNIQUE_TO_ONE_ENV: {len(unique_to_one)}")

for key in missing_some:
    missing_envs = [e for e, v in matrix[key].items() if v == '<missing>']
    print(f"MISSING_KEY: {key} absent from {missing_envs}")

# Required key check
for key in required_keys:
    for env in envs:
        if env_map.get(env, {}).get(key, '<missing>') == '<missing>':
            print(f"REQUIRED_KEY_MISSING: {key} not in {env}")

out = os.path.join(tmp, 'qa-env-parity-matrix.json')
json.dump({'matrix': matrix, 'envs': envs, 'all_keys': sorted(all_keys),
           'required_keys': sorted(required_keys)},
          open(out, 'w', encoding='utf-8'), indent=2)
print(f"MATRIX_WRITTEN: {out}")
PYEOF
```

## Phase 3 — LLM Classification

Read the diff matrix from `$_TMP/qa-env-parity-matrix.json` and classify each discrepancy using your knowledge of common env var patterns:

For each key that appears in at least one environment but is missing from or differs across others, apply these classification rules:

- **`required-missing`** (ERROR): A key is absent from staging or production but present in dev/local, and its name suggests it is critical for runtime (e.g., contains `DATABASE_URL`, `API_KEY`, `SECRET`, `JWT`, `AUTH`, `PORT`, `HOST`, `REDIS`, `SMTP`)
- **`value-mismatch-suspicious`** (WARN): The key is present in all environments but the presence/absence pattern suggests a misconfiguration — e.g., a key is `<empty>` in production but `<set>` in dev
- **`stale-orphaned`** (INFO): The key exists only in dev/local/test and not in staging or production — likely leftover from development
- **`intentional-override`** (OK): The key differs across environments in a predictable way — e.g., `DATABASE_URL`, `APP_URL`, `NEXT_PUBLIC_API_URL` — these are expected to vary per environment

Print each classification on a separate line:
```
CLASSIFIED: <KEY> | <category> | <brief reason>
```

Then write `$_TMP/qa-env-parity-classified.json` with structure:
```json
[
  { "key": "DATABASE_URL", "category": "intentional-override", "reason": "URL expected to differ per env", "envs_missing": [] },
  { "key": "JWT_SECRET", "category": "required-missing", "reason": "Security key absent from production", "envs_missing": ["production"] }
]
```

## Phase 4 — Report

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
branch = os.environ.get('_BRANCH', 'unknown')
date = os.environ.get('_DATE', 'unknown')

classified_file = os.path.join(tmp, 'qa-env-parity-classified.json')
matrix_file = os.path.join(tmp, 'qa-env-parity-matrix.json')

classified = json.load(open(classified_file, encoding='utf-8')) if os.path.exists(classified_file) else []
matrix_data = json.load(open(matrix_file, encoding='utf-8')) if os.path.exists(matrix_file) else {}
envs = matrix_data.get('envs', [])

# Group by category
from collections import defaultdict
by_cat = defaultdict(list)
for item in classified:
    by_cat[item['category']].append(item)

def table_rows(items):
    if not items:
        return "| — | — | — |"
    return "\n".join(
        f"| `{i['key']}` | {', '.join(i.get('envs_missing', []))} | {i.get('reason', '')} |"
        for i in items
    )

report_md = f"""# QA Environment Parity Report — {date}

**Branch:** {branch}
**Environments compared:** {', '.join(envs) or 'none'}

## Summary

| Category | Count |
|----------|-------|
| required-missing (ERROR) | {len(by_cat['required-missing'])} |
| value-mismatch-suspicious (WARN) | {len(by_cat['value-mismatch-suspicious'])} |
| stale-orphaned (INFO) | {len(by_cat['stale-orphaned'])} |
| intentional-override (OK) | {len(by_cat['intentional-override'])} |

## Required-Missing (ERROR)

| Key | Missing From | Reason |
|-----|-------------|--------|
{table_rows(by_cat['required-missing'])}

## Value-Mismatch-Suspicious (WARN)

| Key | Affected Envs | Reason |
|-----|--------------|--------|
{table_rows(by_cat['value-mismatch-suspicious'])}

## Stale-Orphaned (INFO)

| Key | Present Only In | Reason |
|-----|----------------|--------|
{table_rows(by_cat['stale-orphaned'])}

---
*No actual env var values are recorded. Only key presence/absence is analysed.*
"""

report_path = os.path.join(tmp, f'qa-env-parity-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write(report_md)
print(f"REPORT_WRITTEN: {report_path}")

# CTRF
now_ms = int(time.time() * 1000)
tests = []

for item in classified:
    cat = item['category']
    key = item['key']
    if cat == 'required-missing':
        status = 'failed'
    elif cat in ('intentional-override', 'value-mismatch-suspicious'):
        # intentional-override = expected drift = passed;
        # value-mismatch-suspicious = warn = skipped per spec
        status = 'passed' if cat == 'intentional-override' else 'skipped'
    elif cat == 'stale-orphaned':
        status = 'skipped'
    else:
        status = 'passed'
    tests.append({'name': f"env-parity: {key} ({cat})", 'status': status,
                  'duration': 0, 'suite': 'env-parity'})

if not tests:
    tests = [{'name': 'env-parity-scan', 'status': 'passed', 'duration': 0, 'suite': 'env-parity'}]

failed = sum(1 for t in tests if t['status'] == 'failed')
passed = sum(1 for t in tests if t['status'] == 'passed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')

ctrf = {
    'results': {
        'tool': {'name': 'qa-env-parity'},
        'summary': {'tests': len(tests), 'passed': passed, 'failed': failed,
                    'pending': 0, 'skipped': skipped, 'other': 0,
                    'start': now_ms - 15000, 'stop': now_ms},
        'tests': tests,
        'environment': {'reportName': 'qa-env-parity', 'branch': branch}
    }
}
ctrf_path = os.path.join(tmp, 'qa-env-parity-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
PYEOF
```

## Important Rules

- **Never write actual env var values** to any output file — use `<set>`, `<empty>`, or `<redacted>` throughout
- **Missing keys are WARN not ERROR by default** unless the key appears in `PARITY_REQUIRED_KEYS`
- **`.env.example` and `.env.sample` are treated as documentation** — they are parsed for the key inventory but excluded from parity comparisons
- **Classification is heuristic** — review `intentional-override` results and use `PARITY_REQUIRED_KEYS` to promote specific keys to required
- **Non-blocking if no env files found** — emit WARN CTRF entry and exit gracefully

## Agent Memory

After each run, update `.claude/agent-memory/qa-env-parity/MEMORY.md` (create if absent). Record:
- Known intentional overrides (so Claude doesn't re-flag them each run)
- Explicitly required keys for this project
- Environments tracked and which files map to which env

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-env-parity","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
