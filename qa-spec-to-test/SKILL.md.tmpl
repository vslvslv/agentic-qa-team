---
name: qa-spec-to-test
preamble-tier: 3
version: 1.0.0
description: |
  Converts Markdown PRD/spec documents into structured YAML test plans and optional Playwright
  skeleton spec files. Point it at docs/*.md, PRD*.md, SPEC*.md, or specs/ directories.
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
# Spec file sources
_SPEC_FILES="${QA_SPEC_FILES:-}"
_SPEC_OUTPUT="${SPEC_OUTPUT:-./test-specs}"
_GEN_PLAYWRIGHT="${SPEC_GEN_PLAYWRIGHT:-1}"

# Discover spec documents if not provided
if [ -z "$_SPEC_FILES" ]; then
  _FOUND=$(find . -maxdepth 3 \( -name "PRD*.md" -o -name "SPEC*.md" -o -name "requirements*.md" -o -name "acceptance*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
  # Also check docs/ and specs/ directories
  if [ -d "docs" ]; then
    _DOCS=$(find docs/ -name "*.md" -not -name "CHANGELOG*" -not -name "README*" 2>/dev/null)
    _FOUND="$_FOUND $(_DOCS)"
  fi
  if [ -d "specs" ]; then
    _SPECS=$(find specs/ -name "*.md" 2>/dev/null)
    _FOUND="$_FOUND $_SPECS"
  fi
  _SPEC_COUNT=$(echo "$_FOUND" | tr ' ' '\n' | grep -c '\.' 2>/dev/null || echo 0)
else
  _SPEC_COUNT=$(echo "$_SPEC_FILES" | tr ',' '\n' | wc -l | tr -d ' ')
fi

echo "SPEC_COUNT: $_SPEC_COUNT"
echo "SPEC_OUTPUT: $_SPEC_OUTPUT"
echo "GEN_PLAYWRIGHT: $_GEN_PLAYWRIGHT"
[ -n "$_FOUND" ] && echo "SPEC_FILES_FOUND: $_FOUND" || echo "SPEC_FILES_FOUND: (none auto-detected)"
echo "--- DONE ---"
```

---

## Phase 1 — Discover and Parse Spec Documents

Read all discovered spec files. If none found and `QA_SPEC_FILES` is empty, use `AskUserQuestion` to ask the user to provide spec file paths.

For each spec file:
- Extract: feature name, user stories, acceptance criteria, business rules, constraints, edge cases
- Identify testable assertions (MUST, SHALL, SHOULD clauses; Given/When/Then if present; numbered acceptance criteria)
- Tag each criterion with priority (P1=must-have, P2=should-have, P3=nice-to-have) based on language signals:
  - P1: "must", "shall", "required", "critical", "mandatory"
  - P2: "should", "expected", "needs to", "will"
  - P3: "may", "nice to have", "optional", "could"

## Phase 2 — Structure into YAML Test Plan

Generate a structured YAML test plan for each spec document:

```yaml
# test-plan-{feature}-{date}.yaml
feature: "<feature name>"
source: "<spec file path>"
generated: "<date>"
scenarios:
  - id: "TC-001"
    title: "<scenario title>"
    priority: "P1|P2|P3"
    preconditions:
      - "<precondition>"
    steps:
      - action: "<step>"
        expected: "<expected outcome>"
    tags: ["<tag1>", "<tag2>"]
```

Write to `$_SPEC_OUTPUT/test-plan-{feature}-{_DATE}.yaml`.

Create the output directory first:
```bash
mkdir -p "$_SPEC_OUTPUT"
```

## Phase 3 — Generate Playwright Skeletons (if SPEC_GEN_PLAYWRIGHT=1)

For each P1 scenario in the YAML test plan, generate a Playwright skeleton spec file:

```typescript
// test-specs/{feature}.spec.ts
import { test, expect } from '@playwright/test';

test.describe('<feature>', () => {
  // TC-001: <scenario title>
  // Priority: P1 | Source: <spec file>
  test('<scenario title>', async ({ page }) => {
    // Preconditions: <preconditions>
    // TODO: implement setup

    // Steps:
    // 1. <step 1> → expected: <expected 1>
    await page.goto('/'); // TODO: replace with correct URL
    // TODO: implement test body

    // Assertions:
    // TODO: assert <expected outcome>
  });
});
```

Write to `$_SPEC_OUTPUT/{feature}.spec.ts`.

## Phase N — Report

Write `$_TMP/qa-spec-to-test-report-{_DATE}.md`:
- Table of all generated test plans (feature, scenario count by priority, output files)
- Coverage gaps: acceptance criteria that couldn't be mapped to clear test scenarios
- Playwright skeleton count (if generated)
- Recommendations for manual/exploratory testing of P3 scenarios

Write `$_TMP/qa-spec-to-test-ctrf.json`:
```json
{
  "results": {
    "tool": { "name": "qa-spec-to-test", "version": "1.0.0" },
    "summary": { "tests": N, "passed": N, "failed": 0, "pending": N, "skipped": 0, "other": 0, "start": 0, "stop": 0 },
    "tests": [{ "name": "TC-001: <scenario title>", "status": "passed", "duration": 0 }]
  }
}
```

Each scenario = one CTRF test. P1 scenarios with clear steps = passed. Ambiguous/unmappable criteria = pending.

## Important Rules

- Never hallucinate test steps — only derive from explicit spec text
- Mark scenarios as `pending` if the acceptance criterion is vague or untestable
- If no spec files found after discovery, prompt user rather than generating empty output
- Keep YAML test plans as single source of truth; Playwright skeletons are optional scaffolding
- Use `QA_SPEC_FILES=path1.md,path2.md` to override auto-discovery
- Use `SPEC_OUTPUT=./custom-dir` to override output directory
- Use `SPEC_GEN_PLAYWRIGHT=0` to skip Playwright skeleton generation

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-spec-to-test/MEMORY.md` (create if absent). Record:
- Spec files discovered and processed
- Feature names extracted and YAML test plan paths
- Recurring patterns in spec language (e.g., Given/When/Then vs numbered AC)
- Any spec files that were too vague to generate test scenarios from

Read this file at the start of each run to skip re-processing already-converted specs.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-spec-to-test","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
