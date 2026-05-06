---
name: qa-secrets
preamble-tier: 3
version: 1.0.0
description: |
  Secrets scanning gate using TruffleHog. Scans full git history and staged diff for
  leaked credentials, API keys, and tokens, validating detected secrets against live APIs
  to distinguish verified (active) from unverified. Blocks CI if verified secrets are
  found. Env vars: TRUFFLEHOG_MODE (history|staged|both), SECRETS_FAIL_ON_VERIFIED.
  (qa-agentic-team)
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

_TRUFFLEHOG_AVAILABLE=0
command -v trufflehog >/dev/null 2>&1 && _TRUFFLEHOG_AVAILABLE=1
echo "TRUFFLEHOG_AVAILABLE: $_TRUFFLEHOG_AVAILABLE"

_TRUFFLEHOG_MODE="${TRUFFLEHOG_MODE:-both}"
echo "TRUFFLEHOG_MODE: $_TRUFFLEHOG_MODE"

_SECRETS_FAIL_ON_VERIFIED="${SECRETS_FAIL_ON_VERIFIED:-1}"
echo "SECRETS_FAIL_ON_VERIFIED: $_SECRETS_FAIL_ON_VERIFIED"

_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
echo "REPO_ROOT: $_REPO_ROOT"

_COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "unknown")
echo "COMMIT_COUNT: $_COMMIT_COUNT"
```

If `_TRUFFLEHOG_AVAILABLE=0`: emit the following install hint, then continue with a limited regex-based fallback scan rather than exiting:
```
TruffleHog not found. Install with:
  brew install trufflehog
  OR: go install github.com/trufflesecurity/trufflehog/v3@latest
  OR: docker pull trufflesecurity/trufflehog:latest
Falling back to limited pattern-match scan.
```

## Phase 1 — Scan

Run scans according to `_TRUFFLEHOG_MODE`. Skip TruffleHog commands if `_TRUFFLEHOG_AVAILABLE=0` and use fallback regex scan instead.

### History scan (when mode is "history" or "both"):

```bash
if echo "$_TRUFFLEHOG_MODE" | grep -qE "history|both"; then
  echo "=== HISTORY SCAN ==="
  if [ "$_TRUFFLEHOG_AVAILABLE" = "1" ]; then
    trufflehog git "file://$_REPO_ROOT" --json --no-update 2>/dev/null \
      > "$_TMP/qa-secrets-history.json" || printf '' > "$_TMP/qa-secrets-history.json"
    echo "HISTORY_RAW_LINES: $(wc -l < "$_TMP/qa-secrets-history.json" | tr -d ' ')"
  else
    # Fallback: regex scan of full git log for common credential patterns
    git log --all -p --no-color 2>/dev/null \
      | grep -E "(AKIA[0-9A-Z]{16}|sk_live_[a-zA-Z0-9]{24}|ghp_[a-zA-Z0-9]{36}|xoxb-[0-9]{11}-|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY)" \
      | head -50 > "$_TMP/qa-secrets-history-fallback.txt" 2>/dev/null || true
    echo "FALLBACK_PATTERN_MATCHES: $(wc -l < "$_TMP/qa-secrets-history-fallback.txt" | tr -d ' ')"
    printf '' > "$_TMP/qa-secrets-history.json"
  fi
fi
```

### Staged diff scan (when mode is "staged" or "both"):

```bash
if echo "$_TRUFFLEHOG_MODE" | grep -qE "staged|both"; then
  echo "=== STAGED DIFF SCAN ==="
  if [ "$_TRUFFLEHOG_AVAILABLE" = "1" ]; then
    git diff --cached 2>/dev/null \
      | trufflehog stdin --json --no-update 2>/dev/null \
      > "$_TMP/qa-secrets-staged.json" || printf '' > "$_TMP/qa-secrets-staged.json"
    echo "STAGED_RAW_LINES: $(wc -l < "$_TMP/qa-secrets-staged.json" | tr -d ' ')"
  else
    git diff --cached 2>/dev/null \
      | grep -E "(AKIA[0-9A-Z]{16}|sk_live_[a-zA-Z0-9]{24}|ghp_[a-zA-Z0-9]{36}|xoxb-[0-9]{11}-)" \
      | head -20 > "$_TMP/qa-secrets-staged-fallback.txt" 2>/dev/null || true
    printf '' > "$_TMP/qa-secrets-staged.json"
  fi
fi
```

### Combine into unified findings file:

```bash
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

def load_jsonl(path):
    items = []
    if not os.path.exists(path):
        return items
    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    items.append(json.loads(line))
                except Exception:
                    pass
    return items

history = load_jsonl(os.path.join(tmp, 'qa-secrets-history.json'))
staged  = load_jsonl(os.path.join(tmp, 'qa-secrets-staged.json'))
for item in history:
    item['_source'] = 'history'
for item in staged:
    item['_source'] = 'staged'

all_findings = history + staged
out = os.path.join(tmp, 'qa-secrets-all.json')
with open(out, 'w', encoding='utf-8') as fh:
    json.dump(all_findings, fh, indent=2)
print(f'COMBINED_FINDINGS: {len(all_findings)} (history={len(history)}, staged={len(staged)})')
print(f'COMBINED_PATH: {out}')
PYEOF
```

## Phase 2 — Classify

Read `$_TMP/qa-secrets-all.json`, group findings by verification status, and emit counts. Extract DetectorName, redacted Raw value, and SourceMetadata File/Line for each finding.

```bash
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

def redact(raw):
    """Redact secret to first 4 + last 4 chars. Never expose the full value."""
    s = str(raw or '')
    if len(s) < 10:
        return '****'
    return s[:4] + ('*' * (len(s) - 8)) + s[-4:]

path = os.path.join(tmp, 'qa-secrets-all.json')
findings = json.load(open(path, encoding='utf-8')) if os.path.exists(path) else []

verified, unverified = [], []
for item in findings:
    is_ver = item.get('Verified') is True or item.get('VerificationResult') == 'Verified'
    detector = item.get('DetectorName') or item.get('detector_name') or 'Unknown'
    raw = item.get('Raw') or item.get('raw') or ''
    meta = item.get('SourceMetadata') or item.get('source_metadata') or {}
    data = meta.get('Data') or meta.get('data') or {}
    git_data = (data.get('Git') or data.get('git') or {}) if isinstance(data, dict) else {}
    file_p  = git_data.get('file') or (data.get('file') if isinstance(data, dict) else '') or ''
    line_n  = git_data.get('line') or (data.get('line') if isinstance(data, dict) else '') or ''
    commit  = str(git_data.get('commit') or '')[:12]
    rec = {'detector': detector, 'raw_redacted': redact(raw),
           'file': file_p, 'line': line_n, 'commit': commit,
           'source': item.get('_source', 'unknown')}
    (verified if is_ver else unverified).append(rec)

print(f'VERIFIED_COUNT: {len(verified)}')
print(f'UNVERIFIED_COUNT: {len(unverified)}')
for v in verified:
    print(f'VERIFIED_SECRET: [{v["detector"]}] {v["raw_redacted"]} | file:{v["file"]} line:{v["line"]} commit:{v["commit"]}')
for u in unverified[:10]:
    print(f'UNVERIFIED_SECRET: [{u["detector"]}] file:{u["file"]}')

counts_path = os.path.join(tmp, 'qa-secrets-counts.env')
with open(counts_path, 'w') as fh:
    fh.write(f'_VERIFIED_COUNT={len(verified)}\n')
    fh.write(f'_UNVERIFIED_COUNT={len(unverified)}\n')

parsed_path = os.path.join(tmp, 'qa-secrets-parsed.json')
with open(parsed_path, 'w', encoding='utf-8') as fh:
    json.dump({'verified': verified, 'unverified': unverified}, fh, indent=2)
print(f'PARSED_WRITTEN: {parsed_path}')
PYEOF

source "$_TMP/qa-secrets-counts.env" 2>/dev/null || true
echo "VERIFIED: $_VERIFIED_COUNT  UNVERIFIED: $_UNVERIFIED_COUNT"
```

## Phase 3 — Report

### Write Markdown report to `$_TMP/qa-secrets-report-$_DATE.md`:

```bash
python3 - << 'PYEOF'
import json, os

tmp    = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date   = os.environ.get('_DATE', 'unknown')
branch = os.environ.get('_BRANCH', 'unknown')
mode   = os.environ.get('_TRUFFLEHOG_MODE', 'both')
th_av  = os.environ.get('_TRUFFLEHOG_AVAILABLE', '0')
fail_on = os.environ.get('_SECRETS_FAIL_ON_VERIFIED', '1')

parsed_path = os.path.join(tmp, 'qa-secrets-parsed.json')
data = json.load(open(parsed_path, encoding='utf-8')) if os.path.exists(parsed_path) else {}
verified   = data.get('verified', [])
unverified = data.get('unverified', [])

overall = 'FAILED' if (verified and fail_on == '1') else 'PASSED'

lines = [
    f'# QA Secrets Scan Report — {date} — {branch}', '',
    '## Summary', '',
    '| Metric | Value |', '|--------|-------|',
    f'| Overall Status | **{overall}** |',
    f'| Verified Secrets | {len(verified)} |',
    f'| Unverified Findings | {len(unverified)} |',
    f'| Scan Mode | {mode} |',
    f'| TruffleHog Available | {"yes" if th_av == "1" else "no (pattern fallback used)"} |', '',
]

if verified:
    lines += [
        '## Verified Secrets — ACTIVE (rotate immediately)', '',
        '| Detector | Redacted Value | File | Line | Commit | Source |',
        '|----------|---------------|------|------|--------|--------|',
    ]
    for v in verified:
        lines.append(f'| {v["detector"]} | `{v["raw_redacted"]}` | {v["file"]} | {v["line"]} | {v["commit"]} | {v["source"]} |')
    lines.append('')

if unverified:
    lines += [
        '## Unverified Findings — warnings only', '',
        '| Detector | File | Source |', '|----------|------|--------|',
    ]
    for u in unverified:
        lines.append(f'| {u["detector"]} | {u["file"]} | {u["source"]} |')
    lines.append('')

lines += [
    '## Remediation Steps', '',
    '### Verified secrets — act immediately:',
    '1. **Rotate the credential** — treat as compromised regardless of exposure duration',
    '2. **Purge from git history** using git-filter-repo:',
    '   ```bash',
    '   pip install git-filter-repo',
    '   git filter-repo --replace-text <(echo "LITERAL_SECRET==>REDACTED")',
    '   git push --force --all && git push --force --tags',
    '   ```',
    '3. **Notify all collaborators** to re-clone — history rewrites invalidate existing clones',
    '4. **Add the file to .gitignore** and install a pre-commit hook (git-secrets / detect-secrets)',
    '',
    '### Prevention:',
    '- Store secrets in a vault: AWS SSM Parameter Store, HashiCorp Vault, or Doppler',
    '- Commit `.env.example` with placeholder values; never commit `.env`',
    '- Enable repository-level secret scanning in GitHub / GitLab settings', '',
    f'---',
    f'*Scan: {date} | Branch: {branch} | No secret values recorded in this report*',
]

report_path = os.path.join(tmp, f'qa-secrets-report-{date}.md')
with open(report_path, 'w', encoding='utf-8') as fh:
    fh.write('\n'.join(lines) + '\n')
print(f'REPORT_WRITTEN: {report_path}')
PYEOF
```

### Write CTRF JSON to `$_TMP/qa-secrets-ctrf.json`:

Verified secrets = `"failed"` tests; unverified = `"skipped"` tests. If `_VERIFIED_COUNT > 0` and `_SECRETS_FAIL_ON_VERIFIED=1`: overall status is failed.

```bash
python3 - << 'PYEOF'
import json, os, time

tmp     = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
branch  = os.environ.get('_BRANCH', 'unknown')
fail_on = os.environ.get('_SECRETS_FAIL_ON_VERIFIED', '1')

parsed_path = os.path.join(tmp, 'qa-secrets-parsed.json')
data = json.load(open(parsed_path, encoding='utf-8')) if os.path.exists(parsed_path) else {}
verified   = data.get('verified', [])
unverified = data.get('unverified', [])

now_ms = int(time.time() * 1000)
tests = []
for v in verified:
    tests.append({'name': f'secrets/{v["detector"]}/{v["file"] or "unknown"}',
                  'status': 'failed' if fail_on == '1' else 'other',
                  'duration': 0, 'suite': 'secrets'})
for u in unverified:
    tests.append({'name': f'secrets/{u["detector"]}/{u["file"] or "unknown"}',
                  'status': 'skipped', 'duration': 0, 'suite': 'secrets'})
if not tests:
    tests = [{'name': 'secrets/no-findings', 'status': 'passed', 'duration': 0, 'suite': 'secrets'}]

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')

ctrf = {'results': {
    'tool': {'name': 'qa-secrets'},
    'summary': {'tests': len(tests), 'passed': passed, 'failed': failed,
                'pending': 0, 'skipped': skipped, 'other': 0,
                'start': now_ms - 30000, 'stop': now_ms},
    'tests': tests,
    'environment': {'reportName': 'qa-secrets', 'branch': branch},
}}
out = os.path.join(tmp, 'qa-secrets-ctrf.json')
with open(out, 'w', encoding='utf-8') as fh:
    json.dump(ctrf, fh, indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'CTRF_STATUS: {"FAILED" if failed > 0 else "PASSED"}')
PYEOF
```

After writing reports, print a concise console summary: verified count, unverified count, report path, CTRF path, and gate status.

## Important Rules

- **Never print full secret values** — always redact to first 4 + last 4 chars; applies to console output, reports, and all tool outputs
- **Verified secrets always fail** regardless of detector type when `SECRETS_FAIL_ON_VERIFIED=1` (the default)
- **Unverified findings are warnings only** — marked `skipped` in CTRF; require manual review but do not block CI
- **Run on every PR as a blocking gate** — use `SECRETS_FAIL_ON_VERIFIED=1` in all CI environments
- **Never commit false positive suppressions** without a documented comment — use `# trufflehog:ignore` inline only for provably non-secret values (test fixtures, example placeholders)
- **Degrade gracefully** — if TruffleHog is not installed, run regex fallback and report `TRUFFLEHOG_AVAILABLE=0` in CTRF environment block

## Agent Memory

After each run, update `.claude/agent-memory/qa-secrets/MEMORY.md` (create if absent). Record:
- TruffleHog version and install path
- Detectors that produced verified vs. unverified findings historically
- Known false positives (file path + detector name + reason for suppression)
- Branches/commits where verified secrets were previously found and rotated

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-secrets","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'","verified":'"${_VERIFIED_COUNT:-0}"',"unverified":'"${_UNVERIFIED_COUNT:-0}"'}' \
  2>/dev/null || true
```
