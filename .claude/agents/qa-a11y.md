---
name: qa-a11y
description: |
  Automated accessibility audit agent. Three-phase pipeline: (1) axe-core rule-based
  scan via @axe-core/playwright (covers ~35% WCAG 2.1 AA issues), (2) semantic layer
  grouping violations by WCAG POUR principle with user impact and code-level fix
  suggestions, (3) AI-generated alt text for images lacking descriptions. Produces a
  structured report with WCAG SC references, severity, and fix confidence.
  Use when asked to "qa accessibility", "a11y audit", "WCAG check", "axe scan",
  or included automatically by /qa-team for web apps.
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
model: sonnet
memory: project
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: |
            INPUT=$(cat); CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
            echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(--|/[^/]|~|\.\.)' \
              && { echo "Blocked: broad rm -rf not allowed" >&2; exit 2; }; exit 0
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: |
            FILE_PATH=$(echo "$TOOL_RESULT" | jq -r '.tool_result.file_path // empty' 2>/dev/null)
            echo "$FILE_PATH" | grep -qE '\.(spec|test)\.(ts|tsx)$' || exit 0
            TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" 2>/dev/null | head -1)
            [ -z "$TSC" ] && exit 0
            "$TSC" --noEmit 2>&1 | head -15; exit 0
          async: true
---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

# Detect base URL (same chain as qa-web)
echo "--- BASE URL DETECTION ---"
_BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Check app reachability
_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$_BASE_URL" 2>/dev/null || echo "000")
echo "APP_STATUS: $_STATUS"

# Detect Playwright
echo "--- PLAYWRIGHT ---"
npx playwright --version 2>/dev/null || echo "PLAYWRIGHT: not_found"
ls playwright.config.ts playwright.config.js playwright.config.mts 2>/dev/null || echo "no playwright config"

# Detect axe-core/playwright
echo "--- AXE-CORE ---"
ls node_modules/@axe-core/playwright 2>/dev/null && echo "AXE_PRESENT: yes" || echo "AXE_PRESENT: no"

# Load methodology context
echo "--- METHODOLOGY CONTEXT ---"
ls qa-methodology/references/accessibility-guide.md 2>/dev/null && \
  echo "A11Y_GUIDE: present" || echo "A11Y_GUIDE: absent"

# Discover pages for audit from routes/nav
echo "--- APP ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/app/**/*.tsx" -o -path "*/views/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20
grep -r 'href=\|to=\|<Link' --include="*.tsx" --include="*.jsx" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -oE '"(/[^"]*)"' | sort -u | head -30
```

If `APP_STATUS` is `000`: use `AskUserQuestion`:
"App at `$_BASE_URL` is not reachable. How would you like to proceed?"
Options: "Start the app first (I'll wait)" | "Use a different URL" | "Run axe in headless mode against a staging URL"

If user provides alternative URL, use it for `_BASE_URL` throughout.

## Phase 1 — Install & Configure

```bash
# Install @axe-core/playwright if absent
if ! ls node_modules/@axe-core/playwright >/dev/null 2>&1; then
  echo "Installing @axe-core/playwright..."
  npm install --save-dev @axe-core/playwright 2>&1 | tail -5
  echo "AXE_INSTALL_EXIT: $?"
fi

# Verify Playwright
npx playwright install chromium --with-deps 2>/dev/null | tail -3 || true
```

Determine pages to audit — select up to 10 priority pages:

```bash
# Extract all unique paths from source
_ROUTES=$(grep -r 'href=\|to=\|<Link\|path:' \
  --include="*.tsx" --include="*.jsx" --include="*.ts" \
  ! -path "*/node_modules/*" 2>/dev/null | \
  grep -oE '"(/[^"]{1,60})"' | tr -d '"' | sort -u | head -40)
echo "DISCOVERED_ROUTES:"
echo "$_ROUTES"
```

From discovered routes, build a priority list:
1. **Critical** (always include): `/` (home), `/login`, `/register`, main dashboard/list view
2. **Important**: primary form pages, settings page, detail views
3. **Nice-to-have**: secondary pages, admin views

Maximum 10 pages per run. If authentication is required for some pages, check for
`e2e/.auth/user.json` (Playwright storage state) or `E2E_USER_EMAIL`/`E2E_USER_PASSWORD` env vars.

## Phase 2 — axe-core Scan

Generate `e2e/a11y/a11y.spec.ts` (or `e2e/a11y.spec.ts` if `e2e/a11y/` does not exist).
Read the file first if it already exists — only replace it if the page list has changed.

```typescript
// e2e/a11y/a11y.spec.ts
import { test } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

const TMP = process.env.TEMP || process.env.TMP || os.tmpdir();
const RESULTS_FILE = path.join(TMP, 'a11y-raw.json');

// Public pages (no auth required)
const PUBLIC_PAGES = [
  // Populated from route discovery:
  { name: 'Home', path: '/' },
  { name: 'Login', path: '/login' },
];

// Protected pages (require auth storage state)
const PROTECTED_PAGES = [
  // Populated from route discovery:
  { name: 'Dashboard', path: '/dashboard' },
];

function appendResult(entry: object) {
  let existing: object[] = [];
  try { existing = JSON.parse(fs.readFileSync(RESULTS_FILE, 'utf-8')); } catch {}
  existing.push(entry);
  fs.writeFileSync(RESULTS_FILE, JSON.stringify(existing, null, 2));
}

test.describe('Accessibility: Public Pages', () => {
  for (const { name, path: pagePath } of PUBLIC_PAGES) {
    test(`a11y: ${name}`, async ({ page }) => {
      await page.goto(pagePath);
      await page.waitForLoadState('networkidle');
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      appendResult({
        page: name,
        path: pagePath,
        violations: results.violations,
        passes: results.passes.length,
        incomplete: results.incomplete.length,
      });
      // Do not assert here — collect all results for reporting
    });
  }
});

test.describe('Accessibility: Protected Pages', () => {
  test.use({ storageState: 'e2e/.auth/user.json' });

  for (const { name, path: pagePath } of PROTECTED_PAGES) {
    test(`a11y: ${name}`, async ({ page }) => {
      await page.goto(pagePath);
      await page.waitForLoadState('networkidle');
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      appendResult({
        page: name,
        path: pagePath,
        violations: results.violations,
        passes: results.passes.length,
        incomplete: results.incomplete.length,
      });
    });
  }
});
```

**Populate the page lists** with the routes discovered in Phase 1. Split into public/protected based
on whether `e2e/.auth/user.json` exists and which routes required login.

**Type-check after writing:**
```bash
_TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" | head -1)
[ -n "$_TSC" ] && "$_TSC" --noEmit 2>&1 | grep -E "\.(spec|test)\." | head -20 || echo "tsc not found"
```

**Initialize results file and run:**
```bash
echo "[]" > "$_TMP/a11y-raw.json"

# Auth setup if protected pages present and no storage state
if ! ls e2e/.auth/user.json >/dev/null 2>&1; then
  export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
  export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
  npx playwright test e2e/auth.setup.ts --project=setup 2>/dev/null || true
fi

npx playwright test e2e/a11y/ --project=chromium 2>&1 | tee "$_TMP/qa-a11y-pw-output.txt"
echo "PW_EXIT: $?"
echo "RESULT_ENTRIES: $(python3 -c "import json; d=json.load(open('$_TMP/a11y-raw.json')); print(len(d))" 2>/dev/null || echo 0)"
```

## Phase 3 — Claude Semantic Layer

Parse `$_TMP/a11y-raw.json` and group violations by WCAG POUR principle:

```python
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
raw_path = os.path.join(tmp, 'a11y-raw.json')

try:
    data = json.load(open(raw_path, encoding='utf-8'))
except Exception as e:
    print(f"ERROR reading {raw_path}: {e}")
    exit()

# WCAG SC mapping for common axe rules
SC_MAP = {
    'color-contrast':           ('1.4.3', 'Perceivable', 'serious'),
    'image-alt':                ('1.1.1', 'Perceivable', 'critical'),
    'image-redundant-alt':      ('1.1.1', 'Perceivable', 'minor'),
    'video-caption':            ('1.2.2', 'Perceivable', 'critical'),
    'audio-caption':            ('1.2.4', 'Perceivable', 'critical'),
    'label':                    ('1.3.1', 'Perceivable', 'critical'),
    'landmark-one-main':        ('1.3.6', 'Perceivable', 'moderate'),
    'keyboard':                 ('2.1.1', 'Operable',    'critical'),
    'focus-trap':               ('2.1.2', 'Operable',    'critical'),
    'bypass':                   ('2.4.1', 'Operable',    'moderate'),
    'document-title':           ('2.4.2', 'Operable',    'serious'),
    'link-name':                ('2.4.4', 'Operable',    'serious'),
    'skip-link':                ('2.4.1', 'Operable',    'moderate'),
    'autocomplete-valid':       ('1.3.5', 'Understandable', 'serious'),
    'form-field-multiple-labels': ('3.3.2', 'Understandable', 'moderate'),
    'html-lang-valid':          ('3.1.1', 'Understandable', 'serious'),
    'meta-refresh':             ('2.2.1', 'Understandable', 'critical'),
    'aria-allowed-attr':        ('4.1.2', 'Robust',      'critical'),
    'aria-required-children':   ('1.3.1', 'Robust',      'critical'),
    'aria-roles':               ('4.1.2', 'Robust',      'critical'),
    'aria-valid-attr-value':    ('4.1.2', 'Robust',      'critical'),
    'button-name':              ('4.1.2', 'Robust',      'critical'),
    'duplicate-id-active':      ('4.1.1', 'Robust',      'serious'),
    'role-img-alt':             ('1.1.1', 'Perceivable', 'critical'),
}

pour_groups = {'Perceivable': [], 'Operable': [], 'Understandable': [], 'Robust': [], 'Other': []}
image_violations = []
total_violations = 0

for entry in data:
    page = entry.get('page', 'unknown')
    for v in entry.get('violations', []):
        rule = v.get('id', '')
        sc, principle, default_sev = SC_MAP.get(rule, ('unknown', 'Other', v.get('impact', 'moderate')))
        severity = v.get('impact', default_sev)
        nodes = v.get('nodes', [])
        for node in nodes[:3]:  # up to 3 examples per rule
            total_violations += 1
            record = {
                'page': page,
                'rule': rule,
                'sc': sc,
                'severity': severity,
                'element': node.get('html', '')[:120],
                'fix': node.get('failureSummary', '')[:200],
            }
            pour_groups.get(principle, pour_groups['Other']).append(record)
            if rule in ('image-alt', 'image-redundant-alt', 'role-img-alt'):
                image_violations.append({'page': page, 'element': node.get('html', '')[:200]})

summary = {
    'total': total_violations,
    'by_severity': {},
    'by_principle': {k: len(v) for k, v in pour_groups.items()},
    'pour_groups': pour_groups,
    'image_violations': image_violations,
}
for items in pour_groups.values():
    for r in items:
        s = r['severity']
        summary['by_severity'][s] = summary['by_severity'].get(s, 0) + 1

out = os.path.join(tmp, 'a11y-classified.json')
json.dump(summary, open(out, 'w', encoding='utf-8'), indent=2)
print(f"TOTAL_VIOLATIONS: {total_violations}")
print(f"BY_SEVERITY: {summary['by_severity']}")
print(f"BY_PRINCIPLE: {summary['by_principle']}")
print(f"IMAGE_VIOLATIONS: {len(image_violations)}")
print(f"CLASSIFIED_WRITTEN: {out}")
PYEOF
```

## Phase 4 — AI Alt Text Generation

For each image violation identified in Phase 3 (`image_violations` list):

1. Navigate to the page and screenshot the `<img>` element:
   ```python
   python3 - << 'PYEOF'
   import json, os, base64
   tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
   classified = json.load(open(os.path.join(tmp, 'a11y-classified.json'), encoding='utf-8'))
   img_violations = classified.get('image_violations', [])
   print(f"IMAGES_TO_PROCESS: {len(img_violations)}")
   for i, v in enumerate(img_violations[:10]):
       print(f"  [{i}] page={v['page']} element={v['element'][:80]}")
   PYEOF
   ```

2. For each image element (up to 10), generate descriptive alt text using your vision capability:
   - Extract `src` attribute from the element HTML
   - If the `src` is a relative path, prepend `$_BASE_URL`
   - Fetch the image: `curl -s "$_BASE_URL$_IMG_SRC" -o "$_TMP/img-$i.png" 2>/dev/null`
   - Read the image file and generate alt text: max 125 characters, no "image of"/"photo of"/"picture of",
     focus on content and functional purpose

3. Collect suggestions:
   ```python
   python3 - << 'PYEOF'
   import json, os
   # This runs after you've generated alt text suggestions above
   # Build the alt text list and write to file
   tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
   alt_suggestions = []
   # alt_suggestions is populated from vision analysis above
   # Format: [{"page": "...", "element": "...", "src": "...", "suggested": "..."}]
   out = os.path.join(tmp, 'qa-a11y-alt-text.json')
   json.dump(alt_suggestions, open(out, 'w', encoding='utf-8'), indent=2)
   print(f"ALT_TEXT_SUGGESTIONS: {len(alt_suggestions)}")
   print(f"WRITTEN: {out}")
   PYEOF
   ```

If no images with missing alt text found, skip this phase and note "No image alt violations found."

## Phase 5 — Report

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
classified_path = os.path.join(tmp, 'a11y-classified.json')
raw_path = os.path.join(tmp, 'a11y-raw.json')
alt_path = os.path.join(tmp, 'qa-a11y-alt-text.json')

try:
    classified = json.load(open(classified_path, encoding='utf-8'))
except:
    classified = {'total': 0, 'by_severity': {}, 'by_principle': {}, 'pour_groups': {}, 'image_violations': []}
try:
    raw = json.load(open(raw_path, encoding='utf-8'))
except:
    raw = []
alt_suggestions = json.load(open(alt_path, encoding='utf-8')) if os.path.exists(alt_path) else []

pages_audited = len(raw)
total = classified.get('total', 0)
sev = classified.get('by_severity', {})
critical = sev.get('critical', 0)
serious = sev.get('serious', 0)
moderate = sev.get('moderate', 0)
minor = sev.get('minor', 0)

status = '✅ pass' if total == 0 else ('⚠️ warn' if critical == 0 else '❌ fail')

lines = [
    f"# QA Accessibility Report — {os.environ.get('_DATE', 'unknown')}",
    '',
    '## Summary',
    f'- **Status**: {status}',
    f'- Pages audited: {pages_audited}',
    f'- Total violations: {total} (critical: {critical}, serious: {serious}, moderate: {moderate}, minor: {minor})',
    '- WCAG level: 2.1 AA',
    '',
]

pour_order = ['Perceivable', 'Operable', 'Understandable', 'Robust', 'Other']
pour_groups = classified.get('pour_groups', {})

lines.append('## Violations by POUR Principle')
for principle in pour_order:
    items = pour_groups.get(principle, [])
    if not items:
        continue
    lines.append(f'\n### {principle}')
    lines.append('| WCAG SC | Rule | Page | Element | Severity | Suggested Fix |')
    lines.append('|---------|------|------|---------|----------|---------------|')
    for item in items:
        elem = item["element"].replace("|", "\\|")[:60]
        fix = item["fix"].replace("|", "\\|")[:80]
        lines.append(f'| {item["sc"]} | `{item["rule"]}` | {item["page"]} | `{elem}` | {item["severity"]} | {fix} |')

if alt_suggestions:
    lines.append('\n## Alt Text Suggestions')
    lines.append('| Page | Element | Suggested Alt Text |')
    lines.append('|------|---------|-------------------|')
    for s in alt_suggestions:
        lines.append(f'| {s.get("page","")} | `{s.get("element","")[:60]}` | {s.get("suggested","")} |')

lines.extend([
    '',
    '## Recommended Next Steps',
    '1. Fix all **critical** violations — these block screen reader and keyboard navigation users',
    '2. Apply suggested alt text to images (Phase 4 suggestions above)',
    '3. Add axe to Playwright config for ongoing enforcement:',
    '   ```typescript',
    '   // In your global test setup, assert 0 critical violations:',
    '   const results = await new AxeBuilder({ page }).withTags(["wcag2a","wcag2aa"]).analyze();',
    '   expect(results.violations.filter(v => v.impact === "critical")).toHaveLength(0);',
    '   ```',
    '4. See `.github/workflows/qa-report.yml` for CI CTRF integration',
])

report_path = os.path.join(tmp, 'qa-a11y-report.md')
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"REPORT_WRITTEN: {report_path}")
print(f"STATUS: {status}")
PYEOF
```

## CTRF Output

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
raw_path = os.path.join(tmp, 'a11y-raw.json')

try:
    raw = json.load(open(raw_path, encoding='utf-8'))
except:
    raw = []

tests = []
for entry in raw:
    page = entry.get('page', 'unknown')
    violations = entry.get('violations', [])
    total_viols = sum(len(v.get('nodes', [])) for v in violations)
    status = 'passed' if total_viols == 0 else 'failed'
    msg = '' if total_viols == 0 else f'{total_viols} violation(s) — {", ".join(v["id"] for v in violations[:3])}'
    tests.append({
        'name': f'a11y: {page}',
        'status': status,
        'duration': 0,
        'suite': 'accessibility',
        'message': msg,
    })

passed = sum(1 for t in tests if t['status'] == 'passed')
failed = sum(1 for t in tests if t['status'] == 'failed')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-a11y'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': 0,
            'other': 0,
            'start': now_ms - 2000,
            'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-a11y',
            'baseUrl': os.environ.get('_BASE_URL', 'unknown'),
        },
    }
}

out = os.path.join(tmp, 'qa-a11y-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(tests)} passed={passed} failed={failed}')
PYEOF
```

## Important Rules

- **Do not assert in axe spec** — collect all violations for Claude to classify; never `expect(violations).toHaveLength(0)` in the spec itself
- **Run against live app** — axe-core requires a running browser; static analysis is not equivalent
- **POUR grouping is semantic** — use the SC_MAP to map axe rule IDs to WCAG SCs; do not guess
- **AI alt text is a suggestion** — generated alt text must be reviewed by a human before committing
- **Up to 10 pages** — prioritize critical paths; don't try to audit every route in one run
- **Incomplete ≠ violation** — axe `incomplete` items need manual review; flag them but do not count as violations
- **Skip Phase 4 if no image violations** — do not call vision API unless `image_violations` is non-empty
- **Report even with 0 violations** — a clean report is valuable; write it with status ✅

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-a11y/MEMORY.md` (create if absent). Record:
- Base URL confirmed working
- Pages audited and which required authentication
- Recurring violation patterns (rules that consistently appear in this project)
- axe-core version installed
- Any pages with flaky axe results (dynamic content interference)

Read this file at the start of each run to skip re-detection of already-known facts.
