---
name: qa-manager
description: |
  Requirements-to-tests bridge: two modes (BL-050 + BL-051).
  Mode A (Epic → Playwright): fetches JIRA Epic, extracts Features and User Stories,
  generates Test Plan with AskUserQuestion gates at each stage, produces Playwright
  spec skeletons with TC-{id}/Story-{key} traceability comments. Versioned JSON
  artifacts saved to test-specs/. Final output: Playwright specs + traceability matrix.
  Mode B (Figma → TCMS): parses Figma URLs from JIRA sprint tickets, fetches frame PNGs
  via Figma API, runs Claude vision analysis to generate structured test cases, pushes
  to TestRail or Xray TCMS (or saves markdown fallback).
  Env vars: JIRA_URL, JIRA_TOKEN, FIGMA_TOKEN, TESTRAIL_URL / XRAY_URL,
  JIRA_EPIC_ID, TEST_SPECS_DIR.
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
  - WebFetch
  - Agent
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

echo "--- INTEGRATION CHECKS ---"
_JIRA_URL="${JIRA_URL:-}"
_JIRA_TOKEN="${JIRA_TOKEN:-}"
_JIRA_AVAILABLE=0
if [ -n "$_JIRA_URL" ] && [ -n "$_JIRA_TOKEN" ]; then
  curl -s --max-time 5 \
    -H "Authorization: Bearer $_JIRA_TOKEN" \
    -H "Accept: application/json" \
    "$_JIRA_URL/rest/api/3/myself" >/dev/null 2>&1 && _JIRA_AVAILABLE=1
fi
echo "JIRA_AVAILABLE: $_JIRA_AVAILABLE"
echo "JIRA_URL: ${_JIRA_URL:-not set}"
_FIGMA_TOKEN="${FIGMA_TOKEN:-}"
_FIGMA_AVAILABLE=0
[ -n "$_FIGMA_TOKEN" ] && _FIGMA_AVAILABLE=1
echo "FIGMA_AVAILABLE: $_FIGMA_AVAILABLE"
_TCMS_TYPE="none"
[ -n "${TESTRAIL_URL:-}" ] && _TCMS_TYPE="testrail"
[ -n "${XRAY_URL:-}" ] && _TCMS_TYPE="xray"
echo "TCMS_TYPE: $_TCMS_TYPE"
_TEST_SPECS_DIR="${TEST_SPECS_DIR:-./test-specs}"
mkdir -p "$_TEST_SPECS_DIR"
echo "TEST_SPECS_DIR: $_TEST_SPECS_DIR"
_EPIC_ID="${JIRA_EPIC_ID:-}"
echo "EPIC_ID: ${_EPIC_ID:-not set}"
echo "--- DONE ---"
```

## Mode Selection

Use `AskUserQuestion`: "Which qa-manager mode?"
1. "Epic → Playwright pipeline — JIRA Epic to Playwright skeletons with audit trail"
2. "Figma → Test Cases — sprint kickoff: Figma frames to TCMS test cases"

---

## Mode A: Epic → Playwright Pipeline (BL-050)

### Phase 1 — Fetch Epic and Stories

If `_JIRA_AVAILABLE=1` and `_EPIC_ID` set:
- `GET $JIRA_URL/rest/api/3/issue/$_EPIC_ID` → epic title, description, linked story keys
- For each story key: `GET $JIRA_URL/rest/api/3/issue/{key}` → title, acceptance criteria, priority
- Save `$_TEST_SPECS_DIR/01_epic_${_EPIC_ID}.confirmed.v1.json`

If `_JIRA_AVAILABLE=0`: AskUserQuestion for epic title + story descriptions; save in same format.

AskUserQuestion: "Epic: <title>, <N> stories. Confirm and proceed to feature extraction?"

### Phase 2 — Extract Features

Group stories by domain/component (from labels, component field, or summary keywords).
Save `$_TEST_SPECS_DIR/02_features_${_EPIC_ID}.confirmed.v1.json`.
AskUserQuestion: "Extracted <N> features: <list>. Confirm and proceed to test plan?"

### Phase 3 — Generate Test Plan

For each feature: happy path + edge cases + negative tests with TC-{id} identifiers.
Save `$_TEST_SPECS_DIR/03_testplan_${_EPIC_ID}.confirmed.v1.json`.
AskUserQuestion: "<N> test cases generated. Review and confirm before Playwright generation?"

### Phase 4 — Generate Playwright Skeletons

Detect `testDir` from `playwright.config.ts` or default to `e2e/`. For each feature write `<testDir>/<feature>.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';
// Feature: <name> | Epic: <epic_id>
test.describe('<feature>', () => {
  // TC-001: <title> | Story: PROJ-123
  test('<title>', async ({ page }) => {
    // Preconditions: ...
    // TODO: implement steps
    await expect(page.getByRole('heading')).toBeVisible();
  });
});
```

Save traceability matrix: `$_TEST_SPECS_DIR/04_traceability_${_EPIC_ID}.json`.
If `_TCMS_TYPE != "none"`: push test cases via TCMS API.
Report: files created, test case count, traceability path, next step (`/qa-web`).

---

## Mode B: Figma → Test Cases (BL-051)

### Phase 1 — Discover Figma URLs

If `_JIRA_AVAILABLE=1`: fetch active sprint tickets, parse bodies for `figma\.com/(file|design)/([A-Za-z0-9]+)` pattern. Collect `[{ ticket_key, figma_url, figma_file_key, figma_node_id }]`.
If `_JIRA_AVAILABLE=0`: AskUserQuestion for URLs + ticket keys.

### Phase 2 — Fetch Figma Frames

For each URL (if `_FIGMA_AVAILABLE=1`): decode node ID (URL-encoded), `GET https://api.figma.com/v1/images/{fileKey}?ids={nodeId}&format=png&scale=2` with `X-Figma-Token: $FIGMA_TOKEN`, download PNG to `$_TMP/figma-{nodeId_safe}.png`.
If `_FIGMA_AVAILABLE=0`: AskUserQuestion for screenshots.

### Phase 3 — Vision Analysis

For each PNG (Read tool → view image): Claude vision prompt:
> "Analyze this Figma frame for ticket {ticket_key}: '{ticket_title}'. Identify interactive elements, flows, input fields, states. Generate test cases: (1) happy path, (2) input validation, (3) error states, (4) navigation. Each case: Title, Preconditions, Steps, Expected Result, Priority."

Save `$_TEST_SPECS_DIR/figma_{ticket_key}_{nodeId_safe}_testcases.json`.

### Phase 4 — Push to TCMS + Report

If `_TCMS_TYPE = "testrail"`: POST each test case to `/index.php?/api/v2/add_case/{section_id}` with refs field.
If `_TCMS_TYPE = "xray"`: POST to `/rest/raven/1.0/import/test`.
If `_TCMS_TYPE = "none"`: write `$_TEST_SPECS_DIR/figma_testcases_sprint_${_DATE}.md`.

Report: frames analyzed, test cases generated/pushed, failures, next steps.

## Important Rules

- Never log JIRA_TOKEN, FIGMA_TOKEN, or TESTRAIL_TOKEN values
- Write versioned JSON artifacts even if TCMS push is skipped
- Generated Playwright specs are `// TODO:` skeletons — label them clearly
- AskUserQuestion confirmation gates between Mode A stages are mandatory
- Figma node IDs may be URL-encoded — always decode before API calls
