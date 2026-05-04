---
name: qa-component
description: |
  Component testing agent. Three-phase pipeline: (1) Storybook interaction tests +
  accessibility checks + Chromatic visual snapshots, (2) prop boundary testing via
  fast-check — ts-morph extracts TypeScript interfaces, Claude generates fc.record()
  arbitraries, 200 combinations tested for crashes, (3) Stryker mutation quality gate on
  changed components — surviving mutants classified EQUIVALENT vs. GENUINE-GAP, killing
  assertions generated. Per-component A–F quality grade. Use when asked to "test
  components", "run storybook", "prop testing", "mutation score", or "storybook tests".
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

echo "--- COMPONENT TOOL DETECTION ---"
_STORYBOOK=0
find . \( -name "main.js" -o -name "main.ts" -o -name "main.mjs" \) \
  -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _STORYBOOK=1
echo "STORYBOOK: $_STORYBOOK"
_CHROMATIC=0; [ -n "$CHROMATIC_PROJECT_TOKEN" ] && _CHROMATIC=1
echo "CHROMATIC_TOKEN: $_CHROMATIC"
_FASTCHECK=0
grep -qE '"fast-check"|"@fast-check/' package.json 2>/dev/null && _FASTCHECK=1
echo "FAST_CHECK: $_FASTCHECK"
_STRYKER=0
ls stryker.config.js stryker.config.mjs stryker.config.ts stryker.config.json 2>/dev/null | grep -q '.' && _STRYKER=1
grep -q '"@stryker-mutator/' package.json 2>/dev/null && _STRYKER=1
echo "STRYKER: $_STRYKER"
_COMPONENT_COUNT=$(find src -name "*.tsx" ! -name "*.stories.*" ! -name "*.spec.*" \
  ! -name "*.test.*" ! -name "index.*" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
_STORY_COUNT=$(find . \( -name "*.stories.tsx" -o -name "*.stories.ts" -o -name "*.stories.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
echo "COMPONENTS: $_COMPONENT_COUNT  STORIES: $_STORY_COUNT"
_CHANGED_COMPONENTS=$(git diff --name-only 2>/dev/null | \
  grep -E "src/.*\.(tsx|ts|jsx|js)$" | grep -v "stories\|spec\|test" || true)
echo "CHANGED: $(echo "$_CHANGED_COMPONENTS" | grep -c '.' 2>/dev/null || echo 0)"
```

## Phase 2 — Storybook Test Execution (skip if `_STORYBOOK=0`)

```bash
npx storybook test --coverage --json 2>&1 | tail -40 | tee "$_TMP/qa-component-storybook.txt"
[ "$_CHROMATIC" = "1" ] && npx chromatic --only-changed --exit-zero-on-changes 2>&1 | tail -20
```

Parse: per-story pass/fail, accessibility violations, Chromatic diff count.

## Phase 3 — Missing Story Detection

```bash
while IFS= read -r f; do
  base="${f%.*}"
  found=0
  for ext in tsx ts jsx js; do ls "${base}.stories.${ext}" 2>/dev/null && found=1 && break; done
  [ "$found" -eq 0 ] && echo "NO_STORY: $f"
done < <(find src -name "*.tsx" ! -name "*.stories.*" ! -name "*.spec.*" \
  ! -name "*.test.*" ! -name "index.*" ! -path "*/node_modules/*" 2>/dev/null) | head -20
```

Generate stub stories if `QA_GENERATE_STORIES=1`: read component, write `.stories.tsx` with Meta + Default story.

## Phase 4 — Prop Boundary Testing (skip if `QA_SKIP_PROPTEST=1`)

For each component with TypeScript props interface:
1. Extract props via ts-morph (or grep fallback)
2. Claude generates `fc.record(...)` arbitrary for the prop type
3. Run 200 iterations via `@fast-check/vitest` or `@fast-check/jest`
4. Report: crash-inducing prop combinations + minimal reproducer (shrunk by fast-check)

## Phase 5 — Mutation Quality Gate (skip if `_STRYKER=0` or no changed components)

```bash
_CHANGED_LIST=$(echo "$_CHANGED_COMPONENTS" | grep -E "\.tsx?$" | tr '\n' ',')
[ -n "$_CHANGED_LIST" ] && \
  npx stryker run --mutate "${_CHANGED_LIST%,}" --incremental 2>&1 | tail -30 | \
  tee "$_TMP/qa-component-stryker.txt"
```

Analyze surviving mutants: classify EQUIVALENT (same observable behavior) vs. GENUINE-GAP (real test gap).
For GENUINE-GAP: generate killing assertion. Warn if adjusted mutation score < 60%.

## Phase 6 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
sb = open(os.path.join(tmp,'qa-component-storybook.txt'), encoding='utf-8', errors='replace').read() \
     if os.path.exists(os.path.join(tmp,'qa-component-storybook.txt')) else ''
p = len(re.findall(r'✓|PASS|passed', sb)); f = len(re.findall(r'✕|FAIL|failed', sb))
tests = [{'name':'storybook','status':'failed' if f else 'passed','duration':0,'suite':'component',
          'message':f'{p} passed, {f} failed'}] if p+f > 0 else \
        [{'name':'component-analysis','status':'passed','duration':0,'suite':'component'}]
passed=sum(1 for t in tests if t['status']=='passed'); failed=len(tests)-passed
now_ms = int(time.time() * 1000)
ctrf = {'results': {'tool': {'name':'qa-component'},
  'summary': {'tests':len(tests),'passed':passed,'failed':failed,'pending':0,'skipped':0,'other':0,
               'start':now_ms-20000,'stop':now_ms},
  'tests': tests,
  'environment': {'reportName':'qa-component','branch': os.environ.get('_BRANCH','unknown')}}}
out = os.path.join(tmp,'qa-component-ctrf.json')
json.dump(ctrf, open(out,'w',encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 7 — Report

Write `$_TMP/qa-component-report.md` with: Storybook results table (component/stories/passed/failed/a11y), Missing Stories list, Prop Boundary failures, Mutation Quality Gate (score/surviving mutants/EQUIVALENT vs GENUINE-GAP/killing assertions), Overall quality grade A–F.

**Grading**: A ≥90% mutation + 0 a11y critical; B ≥75%; C ≥60%; D ≥40%; F <40%.

## Agent Memory

After each run, update `.claude/agent-memory/qa-component/MEMORY.md`. Record: Storybook version, components with known flaky prop tests, recurring EQUIVALENT mutant patterns, pre-existing a11y violations.
