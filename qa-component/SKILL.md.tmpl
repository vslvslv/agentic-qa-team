---
name: qa-component
preamble-tier: 3
version: 1.0.0
description: |
  Component testing skill. Three-phase pipeline: (1) Storybook interaction tests +
  accessibility checks + Chromatic visual snapshots, (2) prop boundary testing via
  fast-check — ts-morph extracts TypeScript interfaces, Claude generates fc.record()
  arbitraries, 200 combinations tested for crashes, (3) Stryker mutation quality gate
  on changed components — surviving mutants classified EQUIVALENT vs. GENUINE-GAP,
  killing assertions generated. Reports per-component A–F quality grade. Use when asked
  to "test components", "run storybook", "component qa", "prop testing", "mutation
  score components", or "storybook tests". (qa-agentic-team)
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
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

echo "--- COMPONENT TOOL DETECTION ---"
_STORYBOOK=0
find . -name "main.js" -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _STORYBOOK=1
find . -name "main.ts" -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _STORYBOOK=1
find . -name "main.mjs" -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _STORYBOOK=1
echo "STORYBOOK: $_STORYBOOK"

_CHROMATIC=0
[ -n "$CHROMATIC_PROJECT_TOKEN" ] && _CHROMATIC=1
echo "CHROMATIC_TOKEN: $_CHROMATIC"

_FASTCHECK=0
grep -q '"fast-check"' package.json 2>/dev/null && _FASTCHECK=1
grep -q '"@fast-check/' package.json 2>/dev/null && _FASTCHECK=1
echo "FAST_CHECK: $_FASTCHECK"

_STRYKER=0
ls stryker.config.js stryker.config.mjs stryker.config.ts stryker.config.json 2>/dev/null | grep -q '.' && _STRYKER=1
grep -q '"@stryker-mutator/' package.json 2>/dev/null && _STRYKER=1
echo "STRYKER: $_STRYKER"

_TSMORPH=0
grep -q '"ts-morph"' package.json 2>/dev/null && _TSMORPH=1
echo "TS_MORPH: $_TSMORPH"

# Count components and stories
echo "--- COMPONENT INVENTORY ---"
_COMPONENT_COUNT=$(find src -name "*.tsx" ! -name "*.stories.*" ! -name "*.spec.*" \
  ! -name "*.test.*" ! -name "index.*" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
_STORY_COUNT=$(find . \( -name "*.stories.tsx" -o -name "*.stories.ts" \
  -o -name "*.stories.jsx" -o -name "*.stories.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
echo "COMPONENT_FILES: $_COMPONENT_COUNT"
echo "STORY_FILES: $_STORY_COUNT"

# Changed components (for mutation gate scoping)
_CHANGED_COMPONENTS=$(git diff --name-only 2>/dev/null | \
  grep -E "src/.*\.(tsx|ts|jsx|js)$" | grep -v "stories\|spec\|test" || true)
echo "CHANGED_COMPONENTS: $(echo "$_CHANGED_COMPONENTS" | grep -c '.' 2>/dev/null || echo 0) files"
echo "$_CHANGED_COMPONENTS" | head -10
```

If `_STORYBOOK=0` and `_FASTCHECK=0` and `_STRYKER=0`: report "No component testing tools detected" and use `AskUserQuestion`:
"No Storybook, fast-check, or Stryker found. Should I (A) install Storybook, (B) just analyze component coverage gaps, or (C) cancel?" Options: "Analyze coverage gaps only" | "Exit — I'll set up tools first" | "Install Storybook (npx storybook@latest init)".

## Phase 2 — Storybook Test Execution (skip if `_STORYBOOK=0`)

```bash
echo "=== STORYBOOK TEST RUN ==="
npx storybook test --coverage --json 2>&1 | tail -40 \
  | tee "$_TMP/qa-component-storybook.txt"
echo "STORYBOOK_EXIT: $?"
```

Parse `$_TMP/qa-component-storybook.txt`:
- Extract total stories, passed, failed, accessibility violations
- For each failed story: story name, component file, error message

If `_CHROMATIC=1`:
```bash
echo "=== CHROMATIC VISUAL SNAPSHOTS ==="
npx chromatic --only-changed --exit-zero-on-changes 2>&1 | tail -20 \
  | tee "$_TMP/qa-component-chromatic.txt"
echo "CHROMATIC_EXIT: $?"
```
Parse: number of snapshots, visual diffs found.

## Phase 3 — Missing Story Detection

```bash
echo "=== MISSING STORIES ==="
_MISSING_STORIES=""
while IFS= read -r f; do
  base="${f%.*}"
  # Check for any story variant
  found=0
  for ext in tsx ts jsx js; do
    ls "${base}.stories.${ext}" 2>/dev/null && found=1 && break
  done
  [ "$found" -eq 0 ] && echo "NO_STORY: $f" && _MISSING_STORIES="$_MISSING_STORIES $f"
done < <(find src -name "*.tsx" ! -name "*.stories.*" ! -name "*.spec.*" \
  ! -name "*.test.*" ! -name "index.*" ! -path "*/node_modules/*" 2>/dev/null)
_MISSING_COUNT=$(echo "$_MISSING_STORIES" | tr ' ' '\n' | grep -c '.' 2>/dev/null || echo 0)
echo "MISSING_STORY_COUNT: $_MISSING_COUNT"
```

If `QA_GENERATE_STORIES=1`: for each component without a story, read the component file and generate a stub story:

```typescript
// Auto-generated stub — review and customize
import type { Meta, StoryObj } from '@storybook/react';
import { <ComponentName> } from './<ComponentName>';

const meta: Meta<typeof <ComponentName>> = {
  title: '<ComponentPath>/<ComponentName>',
  component: <ComponentName>,
  parameters: { layout: 'centered' },
  tags: ['autodocs'],
};
export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    // TODO: fill in realistic default props
  },
};
```

Write stub stories via Write tool. Note: "Stub stories generated — review and add meaningful args before committing."

## Phase 4 — Prop Boundary Testing via fast-check (skip if `QA_SKIP_PROPTEST=1`)

For each component file that has a story, extract the TypeScript props interface:

```bash
# Use ts-morph if available, otherwise grep
if [ "$_TSMORPH" = "1" ]; then
  node -e "
const { Project } = require('ts-morph');
const p = new Project({ tsConfigFilePath: './tsconfig.json', skipAddingFilesFromTsConfig: true });
// Find all component files with Props interface
const files = require('glob').sync('src/**/*.tsx', { ignore: ['**/*.stories.*','**/*.spec.*'] });
files.slice(0,10).forEach(f => {
  const sf = p.addSourceFileAtPath(f);
  const iface = sf.getInterfaces().find(i => i.getName().includes('Props'));
  if (iface) {
    console.log('PROPS_INTERFACE: ' + f);
    iface.getProperties().forEach(p => console.log('  ' + p.getName() + ': ' + p.getType().getText()));
  }
});
" 2>/dev/null | head -50
else
  # Grep fallback
  grep -rn "interface.*Props\|type.*Props" src --include="*.tsx" ! -path "*stories*" 2>/dev/null | head -20
fi
```

For each extracted props interface, Claude generates a `fast-check` arbitrary. Example output:
```typescript
// fast-check arbitrary for ButtonProps
const buttonPropsArb = fc.record({
  label: fc.string({ minLength: 0, maxLength: 200 }),
  disabled: fc.boolean(),
  variant: fc.constantFrom('primary', 'secondary', 'danger'),
  onClick: fc.constant(() => {}),
  size: fc.option(fc.constantFrom('sm', 'md', 'lg'), { nil: undefined }),
});
```

Write a test file to `$_TMP/qa-component-proptest.test.ts` and run:
```bash
if grep -q '"vitest"' package.json 2>/dev/null; then
  npx vitest run "$_TMP/qa-component-proptest.test.ts" 2>&1 | tail -20
elif grep -q '"jest"' package.json 2>/dev/null; then
  npx jest "$_TMP/qa-component-proptest.test.ts" 2>&1 | tail -20
fi
```

Report: components tested, any prop combinations that caused crashes with the minimal failing case (fast-check shrinks automatically).

## Phase 5 — Mutation Quality Gate via Stryker (skip if `_STRYKER=0` or no changed components)

```bash
echo "=== STRYKER MUTATION TESTING ==="
_CHANGED_COMP_LIST=$(echo "$_CHANGED_COMPONENTS" | grep -E "\.tsx?$" | tr '\n' ',')
if [ -n "$_CHANGED_COMP_LIST" ]; then
  npx stryker run \
    --mutate "${_CHANGED_COMP_LIST%,}" \
    --incremental \
    --reporters json,clear-text \
    2>&1 | tail -30 | tee "$_TMP/qa-component-stryker.txt"
  echo "STRYKER_EXIT: $?"
else
  echo "STRYKER_SKIP: no changed component files"
fi
```

Parse mutation report from `$_TMP/qa-component-stryker.txt`:
- Extract: mutation score %, total mutants, killed, survived, timed out, equivalent
- List surviving mutants with location (file:line) and mutation description

Claude analyzes each surviving mutant:
- **EQUIVALENT**: the mutated code has the same observable behavior (e.g., `x <= 0` vs `x < 1` for integers) — exclude from score
- **GENUINE-GAP**: a real test gap — tests should catch this but don't

For each GENUINE-GAP mutant, generate a killing assertion:
```typescript
// Kills mutant at Button.tsx:23 — disabled prop check
expect(screen.getByRole('button')).toBeDisabled(); // when disabled={true}
expect(screen.getByRole('button')).not.toBeDisabled(); // when disabled={false}
```

Report adjusted mutation score (excluding EQUIVALENT mutants). Threshold: warn if < 60%.

## Phase 6 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

# Parse storybook results
sb_file = os.path.join(tmp, 'qa-component-storybook.txt')
sb_content = open(sb_file, encoding='utf-8', errors='replace').read() if os.path.exists(sb_file) else ''
sb_passed = len(re.findall(r'✓|PASS|passed', sb_content))
sb_failed = len(re.findall(r'✕|FAIL|failed', sb_content))

tests = []
if sb_passed + sb_failed > 0:
    tests.append({'name': 'storybook-tests', 'status': 'passed' if sb_failed == 0 else 'failed',
                  'duration': 0, 'suite': 'component',
                  'message': f'{sb_passed} passed, {sb_failed} failed'})
else:
    tests.append({'name': 'component-analysis', 'status': 'passed', 'duration': 0, 'suite': 'component'})

passed = sum(1 for t in tests if t['status'] == 'passed')
failed = sum(1 for t in tests if t['status'] == 'failed')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-component'},
        'summary': {'tests': len(tests), 'passed': passed, 'failed': failed,
                    'pending': 0, 'skipped': 0, 'other': 0,
                    'start': now_ms - 20000, 'stop': now_ms},
        'tests': tests,
        'environment': {'reportName': 'qa-component', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}
out = os.path.join(tmp, 'qa-component-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 7 — Report

Write `$_TMP/qa-component-report.md`:

```markdown
# QA Component Report — <date>

## Summary
- **Component files**: N
- **Story files**: N (N missing)
- **Storybook tests**: N passed / N failed
- **Prop boundary**: N components tested, N crashes found
- **Mutation score**: N% (adjusted: N% after equivalent filtering)
- **Quality grade**: A/B/C/D/F

## Storybook Results
| Component | Stories | Passed | Failed | A11y Violations |
|-----------|---------|--------|--------|-----------------|
| Button | 4 | 4 | 0 | 0 |
| Modal | 3 | 2 | 1 | 1 |

## Missing Stories
<list of component files with no stories — add stubs with QA_GENERATE_STORIES=1>

## Prop Boundary Failures
| Component | Failing Prop Combination | Minimal Reproducer |
|-----------|--------------------------|-------------------|
| Input | `{ value: "", maxLength: -1 }` | `fc.record({value: fc.constant(""), maxLength: fc.constant(-1)})` |

## Mutation Quality Gate
| File | Mutation Score | Survived | EQUIVALENT | GENUINE-GAP | Status |
|------|---------------|----------|------------|-------------|--------|
| Button.tsx | 75% | 3 | 2 | 1 | ⚠️ gap found |

## Killing Assertions
<generated assertions for GENUINE-GAP mutants>

## Quality Grade Explanation
- A (≥90% mutation, 0 a11y critical): excellent
- B (≥75%): good
- C (≥60%): acceptable, gaps flagged
- D (≥40%): significant quality gaps
- F (<40%): major quality issues requiring immediate attention
```

## Important Rules

- **Incremental mutation only** — never run full-codebase Stryker without `QA_FULL_MUTATION=1`; always scope to `_CHANGED_COMPONENTS`
- **Equivalent mutant judgment** — only classify as EQUIVALENT when certain; when in doubt, classify as GENUINE-GAP
- **Story stubs need review** — generated stubs are starting points; always note they need human review
- **Fast-check side effects** — prop test components must be rendered in isolation; do not call real APIs

## Agent Memory

After each run, update `.claude/agent-memory/qa-component/MEMORY.md` (create if absent). Record:
- Storybook version and test runner confirmed
- Components with known flaky prop boundary failures
- Recurring EQUIVALENT mutant patterns (to skip in future)
- A11y violations that are pre-existing vs. newly introduced

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-component","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
