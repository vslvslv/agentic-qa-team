---
name: qa-heal
version: 1.0.0
description: |
  Self-healing test maintenance skill. Given CI failure output or a failing test suite,
  classifies the failure type, applies the repair strategy, validates via re-run, and
  uses a confidence score to RECOMMEND commit (>=0.87), review PR (0.62-0.87), or
  GitHub issue (<0.62). Every commit, push, PR and issue is an approval gate, and only
  the files qa-heal itself changed are ever staged.
when_to_use: |
  Use when asked to "fix broken tests", "heal tests", "repair
  selectors", or when CI shows test failures on a PR.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
disable-model-invocation: true
model: sonnet
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: first show what would change with `git -C "$HOME/.claude/qa-agentic-team" fetch -q && git -C "$HOME/.claude/qa-agentic-team" log --oneline HEAD..@{u} | head -20`, then run `git -C "$HOME/.claude/qa-agentic-team" pull --ff-only && bash "$HOME/.claude/qa-agentic-team/bin/setup" --no-hook`. Continue regardless.

---

## Approval gates

Run interactively (`/qa-heal`), you ask with `AskUserQuestion`. Run as a subagent (spawned by
`/qa-team`), you cannot ask: a gated step runs only if the brief's `APPROVALS:` line contains
the named key. Keys used here: `ALLOW_COMMIT` (stage + commit), `ALLOW_PR` (push + open PR),
`ALLOW_ISSUE` (file a GitHub issue), `ALLOW_INSTALL` (install a package or tool). Default = not
granted: repair and validate in the working tree, then list every skipped step under
"Needs a decision" in the report.

Tools run only if already installed: use `npx --no <tool>` (fails instead of downloading).
**Gate (ALLOW_INSTALL):** install `<package/tool>` (e.g. `@playwright/test`, `inline-snapshot`)
into the project or environment. Interactive: ask with AskUserQuestion and proceed only on yes.
As a subagent: proceed only if the brief's `APPROVALS:` line contains `ALLOW_INSTALL`; otherwise
skip and list the step under "Needs a decision" in the report.

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

# Snapshot the working tree BEFORE any repair. qa-heal may only ever stage files it changed
# itself; anything already modified, staged or untracked now belongs to someone else.
{ git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } \
  2>/dev/null | sort -u > "$_TMP/qa-heal-prestate.txt"
: > "$_TMP/qa-heal-touched.txt"   # every file qa-heal modifies is appended here (Phase 3)
echo "PRE_EXISTING_CHANGES: $(grep -c . "$_TMP/qa-heal-prestate.txt")"

# Detect CI context
echo "--- CI CONTEXT ---"
echo "GITHUB_ACTIONS: ${GITHUB_ACTIONS:-0}"
echo "GITHUB_RUN_ID: ${GITHUB_RUN_ID:-none}"
echo "GITHUB_PR_NUMBER: ${GITHUB_PR_NUMBER:-none}"
gh pr view --json number,headRefName,statusCheckRollup 2>/dev/null || echo "PR_VIEW: not_available"

# Detect on a PR with failing checks?
_PR_FAILING=0
if command -v gh >/dev/null 2>&1; then
  gh pr view --json statusCheckRollup 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); \
      checks=d.get('statusCheckRollup',[]) or []; \
      failing=[c for c in checks if c.get('conclusion') in ('FAILURE','ERROR','TIMED_OUT')]; \
      print(f'FAILING_CHECKS: {len(failing)}'); \
      [print(f'  - {c[\"name\"]}: {c[\"conclusion\"]}') for c in failing[:5]]" 2>/dev/null \
    || echo "FAILING_CHECKS: unknown"
fi

# Detect test framework
echo "--- TEST FRAMEWORK ---"
_FRAMEWORK="unknown"
[ -f playwright.config.ts ] || [ -f playwright.config.js ] && _FRAMEWORK="playwright"
grep -q '"jest"' package.json 2>/dev/null && _FRAMEWORK="jest"
grep -q '"vitest"' package.json 2>/dev/null && _FRAMEWORK="vitest"
grep -q '"cypress"' package.json 2>/dev/null && [ "$_FRAMEWORK" = "unknown" ] && _FRAMEWORK="cypress"
[ -f pytest.ini ] || [ -f pyproject.toml ] && python3 -m pytest --version 2>/dev/null | grep -q pytest && _FRAMEWORK="pytest"
echo "FRAMEWORK: $_FRAMEWORK"

# Detect language
_LANG="unknown"
[ -f package.json ] && _LANG="typescript"
[ -f pyproject.toml ] || [ -f requirements.txt ] && _LANG="python"
[ -f Gemfile ] && _LANG="ruby"
[ -f pom.xml ] || [ -f build.gradle ] && _LANG="java"
echo "LANG: $_LANG"

# Check for existing failure log from CI
echo "--- EXISTING FAILURE ARTIFACTS ---"
find . \( -name "test-results.xml" -o -name "junit*.xml" -o -name "results.json" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5
ls "$_TMP/qa-*-report.md" 2>/dev/null | head -5
```

## Phase 0.5 — Test Impact Scoping (BL-063)

Before acquiring the full failure log, scope the repair to tests impacted by the current
PR change set. This bounds `qa-heal` cost from O(all tests) to O(impacted tests per PR).

```bash
echo "=== IMPACT SCOPING ==="
_CHANGED_FILES=$(git diff --name-only origin/main 2>/dev/null || \
  git diff --name-only HEAD~1 2>/dev/null | head -30)
_CHANGED_COUNT=$(echo "$_CHANGED_FILES" | grep -c '.' 2>/dev/null || echo 0)
echo "CHANGED_FILES: $_CHANGED_COUNT"
echo "$_CHANGED_FILES" | head -20

# Map changed source files → likely co-located test files
_IMPACTED_TESTS=""
while IFS= read -r file; do
  [ -z "$file" ] && continue
  stem=$(basename "$file" | sed 's/\.[^.]*$//')
  match=$(find . \( \
    -name "${stem}.spec.ts" -o -name "${stem}.spec.js" \
    -o -name "${stem}.test.ts" -o -name "${stem}.test.js" \
    -o -name "${stem}Test.java" -o -name "test_${stem}.py" \
    -o -name "${stem}_spec.rb" \
    \) ! -path "*/node_modules/*" 2>/dev/null | head -3)
  [ -n "$match" ] && _IMPACTED_TESTS="$_IMPACTED_TESTS
$match"
done <<< "$_CHANGED_FILES"

_IMPACTED_TESTS=$(echo "$_IMPACTED_TESTS" | grep -v '^$' | sort -u)
_IMPACTED_COUNT=$(echo "$_IMPACTED_TESTS" | grep -c '.' 2>/dev/null || echo 0)
echo "IMPACTED_TEST_FILES: $_IMPACTED_COUNT"
[ "$_IMPACTED_COUNT" -gt 0 ] && echo "$_IMPACTED_TESTS" | head -10
```

**Scope rule:**
- `_IMPACTED_COUNT > 0` → run Phase 1 test commands only on `_IMPACTED_TESTS` files
  (not the full suite); saves time and reduces false-positive repairs
- `_IMPACTED_COUNT = 0` → fall back to full suite failure detection in Phase 1

**Phase 4 validation always runs the full spec file** (not just impacted tests) to ensure
no regressions were introduced by the repair.

## Phase 1 — Acquire Failure Log

**Source priority** (try each in order, stop at first success):

1. **CI via `gh`**: if `GITHUB_RUN_ID` is set or `gh pr view` shows failing checks:
   ```bash
   # Get recent failed run ID
   _RUN_ID=$(gh run list --limit 5 --json databaseId,conclusion,event \
     2>/dev/null | python3 -c "
   import sys, json
   runs = json.load(sys.stdin)
   failed = [r for r in runs if r.get('conclusion') == 'failure']
   print(failed[0]['databaseId'] if failed else '')
   " 2>/dev/null)

   if [ -n "$_RUN_ID" ]; then
     gh run view "$_RUN_ID" --log-failed 2>/dev/null \
       > "$_TMP/qa-heal-failures.txt" || true
     echo "CI_LOG_LINES: $(wc -l < "$_TMP/qa-heal-failures.txt")"
   fi
   ```

2. **Local junit/test-results XML**:
   ```bash
   find . \( -name "test-results*.xml" -o -name "junit*.xml" \) \
     ! -path "*/node_modules/*" 2>/dev/null | head -3 | while read -r f; do
     python3 -c "
   import xml.etree.ElementTree as ET, sys
   tree = ET.parse('$f')
   for tc in tree.iter('testcase'):
     for child in tc:
       if child.tag in ('failure','error'):
         print(f'FAIL: {tc.attrib.get(\"classname\",\"\")}.{tc.attrib.get(\"name\",\"\")}')
         print(f'  MSG: {(child.text or \"\")[:200]}')
   " 2>/dev/null
   done | tee -a "$_TMP/qa-heal-failures.txt"
   ```

3. **Run tests directly and capture failures**:
   ```bash
   if [ ! -s "$_TMP/qa-heal-failures.txt" ]; then
     echo "No existing failure log — running tests to detect failures"
     case "$_FRAMEWORK" in
       playwright) npx --no playwright test --reporter=json 2>&1 \
         | python3 -c "
   import sys,json
   try:
     data=json.load(sys.stdin)
     def walk(s):
       for t in s.get('tests',[]):
         r=t.get('results',{})
         last=(r[-1] if isinstance(r,list) and r else {})
         if last.get('status')=='failed':
           print(f'FAIL: {t[\"title\"]}')
           for e in last.get('errors',[]):
             print(f'  MSG: {e.get(\"message\",\"\")[:200]}')
       for ss in s.get('suites',[]):
         walk(ss)
     [walk(s) for s in data.get('suites',[])]
   except: pass
   " 2>/dev/null | tee "$_TMP/qa-heal-failures.txt" ;;
       jest|vitest) npx --no "${_FRAMEWORK}" --json 2>/dev/null \
         | python3 -c "
   import sys,json
   try:
     data=json.load(sys.stdin)
     for suite in data.get('testResults',[]):
       for t in suite.get('testResults',[]):
         if t.get('status')=='failed':
           print(f'FAIL: {t[\"fullName\"]}')
           print(f'  FILE: {suite[\"testFilePath\"]}')
           for m in t.get('failureMessages',[]):
             print(f'  MSG: {m[:200]}')
   except: pass
   " 2>/dev/null | tee "$_TMP/qa-heal-failures.txt" ;;
       pytest) python3 -m pytest --tb=short -q 2>&1 \
         | grep -A5 "FAILED\|ERROR" | tee "$_TMP/qa-heal-failures.txt" ;;
     esac
   fi
   ```

4. **Ask user** if still empty:
   If `$_TMP/qa-heal-failures.txt` is missing or empty after all above attempts, use `AskUserQuestion`:
   "Could not find failure log automatically. Please paste your CI failure output or test error messages."
   Write the response to `$_TMP/qa-heal-failures.txt`.
   As a subagent: use a failure log path or text from the brief if one is given; otherwise stop
   and report "no failure log found".

After acquiring: extract failing test identifiers (file path + test name):
```bash
echo "=== FAILING TESTS ==="
cat "$_TMP/qa-heal-failures.txt" 2>/dev/null | \
  grep -E "FAIL:|●|FAILED|Error:|✕" | head -20
echo "FAILURE_LOG_LINES: $(wc -l < "$_TMP/qa-heal-failures.txt" 2>/dev/null || echo 0)"
```

## Phase 2 — Classify Failures

For each failing test identified in Phase 1, read the test spec file and the failure message.
Assign exactly one classification from this taxonomy:

| Signal pattern | Classification |
|---|---|
| `No element found`, `locator.click: Timeout`, `Unable to locate element`, `getBy*: resolved to N elements`, `strict mode violation` | `broken-selector` |
| `ElementNotInteractableException`, `StaleElementReferenceException`, `element is not attached` | `stale-element` |
| Selector resolves but interaction acts on wrong element, wrong text matched, unexpected count | `moved-element` |
| Status/body/text mismatch — value changed (not element missing): `expected 200 received 404`, `Expected: "X", Received: "Y"` | `assertion-drift` |
| `Expected URL`, `toHaveURL`, unexpected redirect, `Cannot navigate to` | `navigation-change` |
| `waitForSelector timeout`, `net::ERR_CONNECTION_REFUSED`, `Timeout exceeded`, race condition, flaky | `timing-issue` |
| `inline-snapshot mismatch`, `snapshot does not match`, `AssertionError: snapshot`, pytest `--inline-snapshot` diff | `snapshot-drift` |

Build classification list:
```
CLASSIFICATIONS:
  - <test name> | <spec file>:<line> | <classification>
  - ...
```

## Phase 3 — Repair

Apply repair strategy based on classification. Read the spec file before editing.

**broken-selector / stale-element / moved-element**:
1. Read the page source or run a brief browser probe to observe the current DOM structure:
   ```bash
   # If Playwright available, inspect element
   _URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts .env 2>/dev/null \
     | grep -o 'http[s]*://[^"'"'"' ]*' | head -1 || echo "http://localhost:3000")
   ```
2. Propose replacement using stable selector hierarchy:
   - `getByRole` (best — semantic, resilient)
   - `getByLabel` (form elements)
   - `getByTestId` (data-testid attribute)
   - `data-cy` attribute (Cypress projects)
   - `aria-label` attribute
   - CSS class (last resort — fragile)
3. Apply edit to spec file using `Edit` tool.

**assertion-drift**:
1. Read the current page state or API response to understand what the actual value is now.
2. Update expected values in the test to match current reality.
3. If the change is suspiciously large (e.g., HTTP 200→500, complete response schema change),
   flag in the report as `[NEEDS REVIEW]` rather than silently updating.

**navigation-change**:
1. Trace redirect chain:
   ```bash
   curl -L -I "$_URL/old-path" --max-time 10 2>/dev/null | grep -i "location:"
   ```
2. Update navigation paths in test to match current routing.

**timing-issue**:
1. Identify `waitForTimeout(N)` or bare `sleep` calls in the failing test.
2. Replace with event-based waits:
   - `await page.waitForResponse(url)` for network-triggered updates
   - `await page.waitForSelector('[data-ready]')` for DOM state
   - `await page.waitForLoadState('networkidle')` for page transitions
   - `await expect(locator).toBeVisible()` with retry built in

**snapshot-drift**:
1. Run the snapshot update command on the affected test files:
   - Python: `python3 -m pytest --inline-snapshot=fix <spec-file>` (requires `inline-snapshot`; if it is not installed, Gate (ALLOW_INSTALL))
   - JavaScript/TypeScript: `npx --no jest --updateSnapshot <spec-file>` or `npx --no vitest --update-snapshots <spec-file>`
   - Then record what the command wrote (see "Record every file you change" below)
2. Inspect the diff: if ≤5 files changed and no structural schema change (only value updates) → auto-apply
3. If >5 files or structural change detected → flag `[SNAPSHOT REVIEW NEEDED]`; do not auto-apply
4. After applying: re-read the updated snapshot values and verify they represent valid/expected output (not a regression masked as a snapshot update)

Apply all edits via `Edit` tool. After each edit, re-read the changed section to verify correctness.

**Record every file you change.** After each `Edit`, append the path (repo-relative) to the
manifest: `echo "<path>" >> "$_TMP/qa-heal-touched.txt"`. After a command that writes files
itself (snapshot update, Keploy re-record), record only what it newly changed, limited to the
files it was meant to write — anything else that changed meanwhile is not qa-heal's:
```bash
# <pattern> = the spec files passed to the command and their snapshot files, e.g.
#   'tests/login\.spec\.ts|__snapshots__/login\.spec\.ts\.snap'   or   '^keploy/'
{ git diff --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u \
  | comm -23 - "$_TMP/qa-heal-prestate.txt" | grep -E '<pattern>' >> "$_TMP/qa-heal-touched.txt"
```
The manifest is the ONLY source for validation and for anything staged later. Never derive the
file list from `git diff` or `git status`.

### Keploy eBPF API Traffic Re-Recording (BL-064)

When `_KEPLOY_AVAILABLE=1` and the failure classification is `api-schema-change`:

**Re-record mode**: re-run Keploy to capture the new API behavior and update stored mocks.
```bash
if [ "$_KEPLOY_AVAILABLE" = "1" ] && echo "$_FAILURE_TYPES" | grep -q "api-schema-change"; then
  echo "KEPLOY_RERECORD: API schema changed — re-recording mocks"
  keploy record --command "$_START_CMD" --delay 5 \
    2>&1 | tee "$_TMP/qa-heal-keploy-record.txt"
  _NEW_CAPTURES=$(ls keploy/*.yaml 2>/dev/null | wc -l | tr -d ' ')
  echo "KEPLOY_NEW_CAPTURES: $_NEW_CAPTURES"
fi
```

**Schema delta analysis**: diff new captures against stored baseline.
```bash
if [ "$_KEPLOY_FIXTURES" -gt 0 ] && [ "$_NEW_CAPTURES" -gt 0 ]; then
  echo "KEPLOY_DELTA: comparing new vs baseline captures"
  git diff keploy/ 2>/dev/null | head -50
fi
```

**Update rule**: record the re-recorded captures in the manifest (pattern `'^keploy/'`). If
`delta ≤ 5 files` AND the PR description mentions the changed endpoints, they travel with the
test repairs through the Phase 5 recommendation and its gates — there is no separate commit.
Otherwise: flag `[KEPLOY REVIEW NEEDED]` and include the diff in the report (posting it as a PR
comment is part of Gate (ALLOW_PR)).

## Phase 4 — Validate

Re-run only the previously failing tests:

```bash
echo "=== VALIDATION RUN ==="
_VALIDATION_PASS=0
_REGRESSION_FREE=0

case "$_FRAMEWORK" in
  playwright)
    # Collect spec files qa-heal modified (manifest, not git diff — that includes other people's work)
    _SPEC_FILES=$(sort -u "$_TMP/qa-heal-touched.txt" | grep -E "\.(spec|test)\.(ts|tsx|js)$" | tr '\n' ' ')
    [ -z "$_SPEC_FILES" ] && _SPEC_FILES=$(cat "$_TMP/qa-heal-failures.txt" \
      | grep -oE '[^ ]+\.(spec|test)\.(ts|tsx|js)' | sort -u | tr '\n' ' ')
    if [ -n "$_SPEC_FILES" ]; then
      npx --no playwright test $_SPEC_FILES --project=chromium 2>&1 | tee "$_TMP/qa-heal-validate.txt"
      grep -qE "passed|✓" "$_TMP/qa-heal-validate.txt" && ! grep -qE "failed|✕" "$_TMP/qa-heal-validate.txt" \
        && _VALIDATION_PASS=1
    fi
    ;;
  jest|vitest)
    _SPEC_FILES=$(cat "$_TMP/qa-heal-failures.txt" | grep "FILE:" | sed 's/.*FILE: //' | sort -u | tr '\n' ' ')
    [ -n "$_SPEC_FILES" ] && \
      npx --no "${_FRAMEWORK}" $_SPEC_FILES 2>&1 | tee "$_TMP/qa-heal-validate.txt"
    grep -q "Tests:.*0 failed" "$_TMP/qa-heal-validate.txt" && _VALIDATION_PASS=1
    ;;
  pytest)
    python3 -m pytest -x -q 2>&1 | tee "$_TMP/qa-heal-validate.txt"
    grep -q "passed" "$_TMP/qa-heal-validate.txt" && ! grep -q "failed" "$_TMP/qa-heal-validate.txt" \
      && _VALIDATION_PASS=1
    ;;
esac

echo "VALIDATION_PASS: $_VALIDATION_PASS"
```

If `_VALIDATION_PASS=0`: retry repair once (re-read the spec file, try an alternative strategy).
If still failing after retry: keep `_VALIDATION_PASS=0` and document in report.

Check for regressions — run the full spec file (not just failing tests):
```bash
# Run full file to ensure no previously-passing tests broke
_FULL_SPEC=$(cat "$_TMP/qa-heal-failures.txt" | grep -oE '[^ ]+\.(spec|test)\.(ts|tsx|js)' | sort -u | head -1)
if [ -n "$_FULL_SPEC" ] && [ "$_FRAMEWORK" = "playwright" ]; then
  npx --no playwright test "$_FULL_SPEC" --project=chromium 2>&1 | tee "$_TMP/qa-heal-regression.txt"
  grep -qE "failed|✕" "$_TMP/qa-heal-regression.txt" && \
    echo "REGRESSION_DETECTED: yes" || { echo "REGRESSION_DETECTED: no"; _REGRESSION_FREE=1; }
fi
```

## Phase 5 — Confidence Gate

Calculate confidence score (0.00–1.00):

```python
# Run inline to compute score
python3 - << 'PYEOF'
import os, re

validate_log = open(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                  'qa-heal-validate.txt'), encoding='utf-8', errors='replace').read() \
               if os.path.exists(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                               'qa-heal-validate.txt')) else ''
regression_log = open(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                    'qa-heal-regression.txt'), encoding='utf-8', errors='replace').read() \
                 if os.path.exists(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                                 'qa-heal-regression.txt')) else ''
failures_log = open(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                  'qa-heal-failures.txt'), encoding='utf-8', errors='replace').read() \
               if os.path.exists(os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                                               'qa-heal-failures.txt')) else ''

score = 0.0
breakdown = []

# +0.40 if all previously failing tests now pass
all_pass = bool(re.search(r'passed|✓', validate_log)) and not bool(re.search(r'failed|✕', validate_log))
if all_pass:
    score += 0.40
    breakdown.append('+0.40 all failing tests now pass')

# +0.20 if no new regressions
no_regression = not bool(re.search(r'failed|✕', regression_log)) or regression_log == ''
if no_regression:
    score += 0.20
    breakdown.append('+0.20 no regressions detected')

# +0.15 if selector replacement uses highest-priority stable strategy
if re.search(r'getByRole|getByLabel|getByTestId', failures_log, re.IGNORECASE):
    score += 0.15
    breakdown.append('+0.15 used stable selector strategy')

# +0.12 if validation passed on first attempt (no retry pattern in log)
if all_pass and 'retry' not in validate_log.lower():
    score += 0.12
    breakdown.append('+0.12 validation passed on first attempt')

# +0.08 if only one classification type present
classifications = re.findall(r'\b(broken-selector|stale-element|moved-element|assertion-drift|navigation-change|timing-issue|snapshot-drift)\b', failures_log)
if len(set(classifications)) <= 1:
    score += 0.08
    breakdown.append('+0.08 single classification type')

# +0.05 if PR is small
try:
    import subprocess
    changed = subprocess.check_output(['git', 'diff', '--name-only', 'origin/main'], text=True, errors='replace').splitlines()
    if len(changed) < 10:
        score += 0.05
        breakdown.append('+0.05 small PR (< 10 changed files)')
except:
    pass

# +0.10 if snapshot-drift classification and ≤3 files changed
if classifications and all(c == 'snapshot-drift' for c in classifications):
    try:
        touched = os.path.join(os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp',
                               'qa-heal-touched.txt')
        changed_specs = sorted({f.strip() for f in open(touched, encoding='utf-8', errors='replace')
            if re.search(r'\.(spec|test)\.(ts|tsx|js|py|rb)$', f.strip())})
        if len(changed_specs) <= 3:
            score += 0.10
            breakdown.append('+0.10 snapshot-drift with ≤3 files changed (low-risk mechanical fix)')
    except:
        pass

print(f'CONFIDENCE_SCORE: {score:.2f}')
for b in breakdown:
    print(f'  {b}')

if score >= 0.87:
    print('RECOMMENDATION: commit')
elif score >= 0.62:
    print('RECOMMENDATION: pr')
else:
    print('RECOMMENDATION: issue')
PYEOF
```

**The score is a recommendation, not a trigger.** It picks which action to propose; every
action below is a gate, and nothing is committed, pushed or posted without approval.

### 5a — Commit set and safety check (before any commit or PR)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
# The commit set is the manifest of files qa-heal changed — nothing else, ever
grep -v '^$' "$_TMP/qa-heal-touched.txt" | sort -u > "$_TMP/qa-heal-commit-files.txt"
echo "HEALED_FILES: $(grep -c . "$_TMP/qa-heal-commit-files.txt")"
sed 's/^/  /' "$_TMP/qa-heal-commit-files.txt"

# Refuse if any of them already had changes (modified/staged/untracked) before qa-heal ran
_CONFLICTS=$(comm -12 "$_TMP/qa-heal-commit-files.txt" "$_TMP/qa-heal-prestate.txt")
echo "PRE_EXISTING_CHANGES_IN_HEALED_FILES: ${_CONFLICTS:-none}"

# Never commit on the default branch: main, master, origin's HEAD, or a detached HEAD
_CUR=$(git branch --show-current)
_DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
case "$_CUR" in main|master|"$_DEFAULT"|"") _ON_DEFAULT=1 ;; *) _ON_DEFAULT=0 ;; esac
echo "CURRENT_BRANCH: ${_CUR:-detached}  ON_DEFAULT_BRANCH: $_ON_DEFAULT"
tr '\n' '\0' < "$_TMP/qa-heal-commit-files.txt" | xargs -0 git --literal-pathspecs diff --stat --
```

- `HEALED_FILES: 0` → nothing to commit; go to CTRF.
- `_CONFLICTS` not `none` → **do not commit or open a PR.** Staging those files would sweep the
  user's own uncommitted work into qa-heal's commit. Report the files and the repair under
  "Needs a decision" and leave the working tree as it is.
- Read `git diff` of the commit set. If any hunk is not one of your repairs (another process
  edited the same file during the run), do not commit; report it.

### 5b — Commit (recommended at score >= 0.87)

**Gate (ALLOW_COMMIT):** commit exactly the files listed in `qa-heal-commit-files.txt` — on the
current branch if it is not the default branch, otherwise on a new branch
`qa-heal/fix-tests-<date>`. Show the file list, the diff stat and the score breakdown.
Interactive: ask with AskUserQuestion and proceed only on yes. As a subagent: proceed only if the
brief's `APPROVALS:` line contains `ALLOW_COMMIT`; otherwise skip and list the step under
"Needs a decision" in the report.

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"; _DATE=$(date +%Y-%m-%d)
# Recomputed here on purpose: an unset variable must never mean "commit on main"
_CUR=$(git branch --show-current)
_DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
case "$_CUR" in main|master|"$_DEFAULT"|"") _ON_DEFAULT=1 ;; *) _ON_DEFAULT=0 ;; esac
if [ "$_ON_DEFAULT" = "1" ]; then
  _HEAL_BRANCH="qa-heal/fix-tests-$_DATE"
  git rev-parse -q --verify "refs/heads/$_HEAL_BRANCH" >/dev/null && _HEAL_BRANCH="$_HEAL_BRANCH-$(date +%H%M%S)"
  # Other uncommitted changes in the tree come along untouched; they are not staged
  git switch -c "$_HEAL_BRANCH" || { echo "BRANCH_CREATE: failed — not committing"; exit 1; }
fi
# Pathspecs on the commit itself = only these paths are committed, even if other files are staged
git --literal-pathspecs add --pathspec-from-file="$_TMP/qa-heal-commit-files.txt" && \
git --literal-pathspecs commit -m "fix: heal test selectors and assertions (qa-heal)" \
  --pathspec-from-file="$_TMP/qa-heal-commit-files.txt"
_RC=$?
[ "$_RC" -eq 0 ] && echo "COMMITTED: yes on $(git branch --show-current)" || echo "COMMITTED: no (git exit $_RC)"
```

### 5c — Review PR (recommended at score 0.62–0.87)

The PR always comes from a dedicated branch, so the user's branch is never pushed.

**Gate (ALLOW_COMMIT):** create `qa-heal/fix-tests-<date>` from the current branch and commit
exactly the files in `qa-heal-commit-files.txt` there. Interactive: ask with AskUserQuestion and
proceed only on yes. As a subagent: proceed only if the brief's `APPROVALS:` line contains
`ALLOW_COMMIT`; otherwise skip and list the step under "Needs a decision" in the report.

**Gate (ALLOW_PR):** push `qa-heal/fix-tests-<date>` to `origin` and open a PR into the branch
qa-heal started on. Interactive: ask with AskUserQuestion and proceed only on yes. As a subagent:
proceed only if the brief's `APPROVALS:` line contains `ALLOW_PR`; otherwise skip and list the step
under "Needs a decision" in the report.

Interactively, one `AskUserQuestion` may cover both gates: "Commit N files to
`qa-heal/fix-tests-<date>`, push it and open a PR into `<base>`?" Options: "Commit, push and open
PR" | "Commit only (no push)" | "Neither".

Commit (only with ALLOW_COMMIT):
```bash
_TMP="${TEMP:-${TMP:-/tmp}}"; _DATE=$(date +%Y-%m-%d)
_BASE_BRANCH=$(git branch --show-current)
[ -z "$_BASE_BRANCH" ] && _BASE_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
echo "$_BASE_BRANCH" > "$_TMP/qa-heal-pr-base.txt"
_HEAL_BRANCH="qa-heal/fix-tests-$_DATE"
git rev-parse -q --verify "refs/heads/$_HEAL_BRANCH" >/dev/null && _HEAL_BRANCH="$_HEAL_BRANCH-$(date +%H%M%S)"
git switch -c "$_HEAL_BRANCH" || { echo "BRANCH_CREATE: failed — not committing"; exit 1; }
git --literal-pathspecs add --pathspec-from-file="$_TMP/qa-heal-commit-files.txt" && \
git --literal-pathspecs commit -m "fix: heal broken test selectors and assertions (qa-heal)" \
  --pathspec-from-file="$_TMP/qa-heal-commit-files.txt" \
  || { echo "COMMITTED: no — stopping before push"; exit 1; }
echo "COMMITTED: yes on $_HEAL_BRANCH (PR base: $_BASE_BRANCH)"
```

Push and open the PR (only with ALLOW_PR, and only after `COMMITTED: yes`):
```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_HEAL_BRANCH=$(git branch --show-current)
_BASE_BRANCH=$(cat "$_TMP/qa-heal-pr-base.txt")
case "$_HEAL_BRANCH" in qa-heal/fix-tests-*) ;; *) echo "NOT_ON_HEAL_BRANCH: $_HEAL_BRANCH — not pushing"; exit 1 ;; esac
git push -u origin "$_HEAL_BRANCH" || { echo "PUSHED: no — PR not opened"; exit 1; }
_PR_URL=$(gh pr create --base "$_BASE_BRANCH" --head "$_HEAL_BRANCH" \
  --title "fix: heal broken tests (qa-heal)" \
  --body "$(cat <<'PRBODY'
## Summary
- Automated test repair by qa-heal
- Repaired selectors, assertions, and navigation paths
- See the qa-heal report for validation results and the confidence breakdown

## Changes
Only the files qa-heal modified. See diff for per-file repair details.

## Test plan
- [ ] All previously failing tests pass
- [ ] No regressions in existing tests
PRBODY
)")
_RC=$?
[ "$_RC" -eq 0 ] && echo "PR_CREATED: yes $_PR_URL" || echo "PR_CREATED: no (gh exit $_RC)"
```

### 5d — GitHub issue (recommended at score < 0.62)

Failure logs can carry tokens, passwords and connection strings. Never post the raw log: build
a redacted body first, then read it yourself before the gate.

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
python3 - "$_TMP/qa-heal-failures.txt" "$_TMP/qa-heal-issue-body.md" << 'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = '\n'.join(open(src, encoding='utf-8', errors='replace').read().splitlines()[:50])
RULES = [
    (r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?(-----END [A-Z ]*PRIVATE KEY-----|\Z)', '[REDACTED_PRIVATE_KEY]'),
    (r'\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})', '[REDACTED_GITHUB_TOKEN]'),
    (r'\b(AKIA|ASIA)[0-9A-Z]{16}\b', '[REDACTED_AWS_KEY]'),
    (r'\bxox[abprs]-[A-Za-z0-9-]{10,}', '[REDACTED_SLACK_TOKEN]'),
    (r'\bsk-[A-Za-z0-9_-]{20,}', '[REDACTED_API_KEY]'),
    (r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}', '[REDACTED_JWT]'),
    (r'(?i)\b(bearer|basic|token)\s+[A-Za-z0-9._~+/=-]{8,}', r'\1 [REDACTED]'),
    (r'([a-zA-Z][a-zA-Z0-9+.-]*://[^/\s:@]+):[^@\s/]+@', r'\1:[REDACTED]@'),
    (r'(?i)\b([a-z0-9_.-]*(?:password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key|auth)[a-z0-9_.-]*)(["\']?\s*[:=]\s*["\']?)[^\s"\',;&]+',
     r'\1\2[REDACTED]'),
]
n = 0
for pat, rep in RULES:
    text, k = re.subn(pat, rep, text)
    n += k
open(dst, 'w', encoding='utf-8').write(text + '\n')
print(f'REDACTIONS: {n}')
PYEOF
```

Read `$_TMP/qa-heal-issue-body.md`. If anything secret-looking survived the patterns (internal
hostnames with credentials, customer data, cookies), redact it by hand before the gate.

**Gate (ALLOW_ISSUE):** create a GitHub issue "qa-heal: N unresolved test failure(s)" in this
repository, body = the redacted log (first 50 lines). Interactive: show the body, ask with
AskUserQuestion and proceed only on yes. As a subagent: proceed only if the brief's `APPROVALS:`
line contains `ALLOW_ISSUE`; otherwise skip and list the step under "Needs a decision" in the
report.

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_UNRESOLVED=$(grep -c "FAIL:" "$_TMP/qa-heal-failures.txt" 2>/dev/null || echo 0)
_TITLE="qa-heal: $_UNRESOLVED unresolved test failure(s) — manual review required"
_ISSUE_URL=$(gh issue create --title "$_TITLE" --body-file "$_TMP/qa-heal-issue-body.md" \
  --label "qa,test-failure" 2>"$_TMP/qa-heal-issue-err.txt")
_RC=$?
if [ "$_RC" -ne 0 ] && grep -qi "label" "$_TMP/qa-heal-issue-err.txt"; then
  # Labels missing in this repo — retry without them rather than creating labels
  _ISSUE_URL=$(gh issue create --title "$_TITLE" --body-file "$_TMP/qa-heal-issue-body.md" \
    2>"$_TMP/qa-heal-issue-err.txt")
  _RC=$?
fi
if [ "$_RC" -eq 0 ]; then echo "ISSUE_FILED: yes $_ISSUE_URL"
else echo "ISSUE_FILED: no (gh exit $_RC): $(head -3 "$_TMP/qa-heal-issue-err.txt")"; fi
```

Report `COMMITTED` / `PR_CREATED` / `ISSUE_FILED` exactly as printed — never "yes" after a
non-zero exit code. Always continue to CTRF and Report regardless of routing path.

## CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
failures_log = open(os.path.join(tmp, 'qa-heal-failures.txt'), encoding='utf-8', errors='replace').read() \
               if os.path.exists(os.path.join(tmp, 'qa-heal-failures.txt')) else ''
validate_log = open(os.path.join(tmp, 'qa-heal-validate.txt'), encoding='utf-8', errors='replace').read() \
               if os.path.exists(os.path.join(tmp, 'qa-heal-validate.txt')) else ''

# Extract test names from failure log
failing = re.findall(r'FAIL:\s*(.+)', failures_log)

tests = []
for name in failing:
    name = name.strip()
    healed = bool(re.search(re.escape(name[:30]), validate_log)) or \
             (bool(re.search(r'passed', validate_log)) and not bool(re.search(r'failed', validate_log)))
    tests.append({
        'name': name,
        'status': 'passed' if healed else 'failed',
        'duration': 0,
        'suite': 'heal',
        'message': '' if healed else 'Could not heal — see qa-heal-report.md for details'
    })

passed = sum(1 for t in tests if t['status'] == 'passed')
failed = sum(1 for t in tests if t['status'] == 'failed')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-heal'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': 0,
            'other': 0,
            'start': now_ms - 1000,
            'stop': now_ms
        },
        'tests': tests,
        'environment': {'reportName': 'qa-heal', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}

out = os.path.join(tmp, 'qa-heal-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(tests)} passed={passed} failed={failed}')
PYEOF
```

## Report

Write `$_TMP/qa-heal-report.md`:

```markdown
# QA Heal Report — <date>

## Summary
- **Status**: ✅ / ⚠️ / ❌
- Tests healed: N / N attempted
- Confidence score: 0.XX — recommendation: commit / pr / issue
- Action taken: committed on <branch> / PR opened <url> / issue filed <url> / none required / none — needs a decision
- Files changed by qa-heal: <list from qa-heal-commit-files.txt>

## Needs a decision
<every gated step that was skipped: what it would do, the files/branch/target, and the approval key it needs; also any healed file that had pre-existing changes and was therefore not committed>

## Repairs Applied
| Test | File | Classification | Strategy | Outcome |
|------|------|----------------|----------|---------|
| <test name> | <spec:line> | broken-selector | getByRole | ✅ healed |

## Unresolved Failures
<tests that could not be healed — include exact error messages and reasoning for why automated repair was not possible>

## Confidence Gate Details
| Factor | Points |
|--------|--------|
| All failing tests now pass | +0.40 |
| No regressions detected | +0.20 |
| Used stable selector (role/label/testid) | +0.15 |
| Passed on first attempt | +0.12 |
| Single classification type | +0.08 |
| Small PR (< 10 files) | +0.05 |
| **Total** | **0.XX** |

Note: snapshot-drift classification adds +0.10 when ≤3 spec files changed (7th factor).

## Next Steps
<recommended manual actions for unresolved failures>
```

## Important Rules

- **Read before editing** — always read the full spec file before making any edits
- **Prefer stable selectors** — `getByRole` > `getByLabel` > `getByTestId` > CSS class; never use auto-generated class names
- **Flag suspicious assertion drift** — if an expected value changes significantly (status code, schema), add `[NEEDS REVIEW]` annotation rather than silently updating
- **No force-pushes** — only use standard `git commit`; never `--force` or `--no-verify`
- **Stage only what qa-heal changed** — the commit set is the `qa-heal-touched.txt` manifest; never `git add` from `git diff`/`git status`, never `git add -A` or `.`
- **Never touch the user's work** — if a healed file already had uncommitted changes before the run, do not commit it; report it
- **Never commit on main/master/the default branch** — create `qa-heal/fix-tests-<date>` first
- **Every commit, push, PR and issue is a gate** — `ALLOW_COMMIT`, `ALLOW_PR`, `ALLOW_ISSUE`; the confidence score only picks the recommendation
- **Redact before posting** — no tokens, passwords or connection strings from logs in an issue or PR
- **Validate before routing** — always run the repaired tests before computing confidence score
- **One classification per test** — assign the most specific matching type; don't assign multiple
- **Continue regardless of routing** — always produce CTRF and report even if routing action fails

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-heal/MEMORY.md` (create if absent). Record:
- Test framework and version confirmed
- Recurring selector patterns that break (DOM structure notes)
- Common repair strategies that succeeded or failed in this project
- Confidence score history, recommendations and which gates were granted
- Any project-specific locator conventions discovered

Read this file at the start of each run to skip re-detection and apply known good strategies first.
