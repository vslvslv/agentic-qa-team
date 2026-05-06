---
name: qa-spec-to-test
description: |
  Converts Markdown PRD/spec documents into structured YAML test plans and optional Playwright
  skeleton spec files. Point it at docs/*.md, PRD*.md, SPEC*.md, or specs/ directories.
  Extracts testable acceptance criteria, tags by priority (P1/P2/P3), and generates skeleton
  .spec.ts files for P1 scenarios. Env vars: QA_SPEC_FILES, SPEC_OUTPUT, SPEC_GEN_PLAYWRIGHT.
model: sonnet
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

_SPEC_FILES="${QA_SPEC_FILES:-}"
_SPEC_OUTPUT="${SPEC_OUTPUT:-./test-specs}"
_GEN_PLAYWRIGHT="${SPEC_GEN_PLAYWRIGHT:-1}"

if [ -z "$_SPEC_FILES" ]; then
  _FOUND=$(find . -maxdepth 3 \( -name "PRD*.md" -o -name "SPEC*.md" -o -name "requirements*.md" -o -name "acceptance*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
  [ -d "docs" ] && _FOUND="$_FOUND $(find docs/ -name "*.md" -not -name "CHANGELOG*" -not -name "README*" 2>/dev/null)"
  [ -d "specs" ] && _FOUND="$_FOUND $(find specs/ -name "*.md" 2>/dev/null)"
  _SPEC_COUNT=$(echo "$_FOUND" | tr ' ' '\n' | grep -c '\.' 2>/dev/null || echo 0)
else
  _SPEC_COUNT=$(echo "$_SPEC_FILES" | tr ',' '\n' | wc -l | tr -d ' ')
fi

echo "SPEC_COUNT: $_SPEC_COUNT"
echo "SPEC_OUTPUT: $_SPEC_OUTPUT"
echo "GEN_PLAYWRIGHT: $_GEN_PLAYWRIGHT"
echo "--- DONE ---"
```

If no spec files found, use AskUserQuestion to ask for file paths.

## Phase 1 — Parse Spec Documents

For each spec file: extract feature name, user stories, acceptance criteria, business rules. Tag each criterion P1 (MUST/SHALL), P2 (SHOULD), P3 (MAY/nice-to-have).

## Phase 2 — Generate YAML Test Plans

Write `$_SPEC_OUTPUT/test-plan-{feature}-{date}.yaml`:
```yaml
feature: "<name>"
source: "<path>"
scenarios:
  - id: "TC-001"
    title: "<title>"
    priority: "P1"
    preconditions: [...]
    steps: [{ action: "...", expected: "..." }]
    tags: [...]
```

## Phase 3 — Generate Playwright Skeletons (if SPEC_GEN_PLAYWRIGHT=1)

For each P1 scenario: write `$_SPEC_OUTPUT/{feature}.spec.ts` with skeleton test body and TODO comments for each step.

## Phase N — Report

Write `$_TMP/qa-spec-to-test-report-{_DATE}.md`: generated plans summary, coverage gaps, skeleton count.

Write `$_TMP/qa-spec-to-test-ctrf.json` (each scenario = one test; P1 clear = passed, ambiguous = pending).

## Important Rules

- Never hallucinate test steps — derive only from explicit spec text
- Mark scenarios as `pending` if acceptance criterion is vague or untestable
- `QA_SPEC_FILES=path1.md,path2.md` overrides auto-discovery
