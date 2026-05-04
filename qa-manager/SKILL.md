---
name: qa-manager
preamble-tier: 3
version: 1.0.0
description: |
  Requirements-to-tests bridge: two modes in one skill (BL-050 + BL-051).
  Mode A (Epic → Playwright): fetches a JIRA Epic, extracts Features and User Stories,
  generates a Test Plan, produces Playwright spec skeletons with traceability comments
  linking each test back to JIRA. Versioned JSON artifacts at every stage with
  AskUserQuestion confirmation gates before proceeding. Final artifact: committed
  Playwright specs + traceability matrix. Mode B (Figma → TCMS): at sprint kickoff,
  parses Figma URLs from JIRA ticket bodies, fetches frame PNGs via Figma API, runs
  Claude vision analysis, produces structured test cases, and pushes them to TestRail
  or Xray. Env vars: JIRA_URL, JIRA_TOKEN, FIGMA_TOKEN, TESTRAIL_URL / XRAY_URL,
  JIRA_EPIC_ID, TEST_SPECS_DIR. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - WebFetch
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
echo "BRANCH: $_BRANCH  DATE: $_DATE"

echo "--- INTEGRATION CHECKS ---"

# JIRA
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

# Figma
_FIGMA_TOKEN="${FIGMA_TOKEN:-}"
_FIGMA_AVAILABLE=0
[ -n "$_FIGMA_TOKEN" ] && _FIGMA_AVAILABLE=1
echo "FIGMA_AVAILABLE: $_FIGMA_AVAILABLE"

# TCMS
_TCMS_TYPE="none"
[ -n "${TESTRAIL_URL:-}" ] && _TCMS_TYPE="testrail"
[ -n "${XRAY_URL:-}" ] && _TCMS_TYPE="xray"
_TCMS_URL="${TESTRAIL_URL:-${XRAY_URL:-not set}}"
echo "TCMS_TYPE: $_TCMS_TYPE"
echo "TCMS_URL: $_TCMS_URL"

# Test specs dir
_TEST_SPECS_DIR="${TEST_SPECS_DIR:-./test-specs}"
mkdir -p "$_TEST_SPECS_DIR"
echo "TEST_SPECS_DIR: $_TEST_SPECS_DIR"

# Epic ID (for Mode A)
_EPIC_ID="${JIRA_EPIC_ID:-}"
echo "EPIC_ID: ${_EPIC_ID:-not set}"

echo "--- DONE ---"
```

---

## Mode Selection

Use `AskUserQuestion`: "Which qa-manager mode?"
Options:
1. "Epic → Playwright pipeline — JIRA Epic to Playwright skeletons with full audit trail"
2. "Figma → Test Cases — sprint kickoff: parse Figma frames from JIRA tickets, generate test cases, push to TCMS"

Proceed to the selected mode below.

---

## Mode A: Epic → Playwright Auditable Pipeline (BL-050)

### Phase 1 — Fetch Epic and Stories

If `_JIRA_AVAILABLE=1`:
- If `_EPIC_ID` is set: `curl -s -H "Authorization: Bearer $JIRA_TOKEN" -H "Accept: application/json" "$JIRA_URL/rest/api/3/issue/$_EPIC_ID"` → parse `fields.summary`, `fields.description`, linked story keys from `fields.subtasks` or `fields.issuelinks`.
- For each story key: `GET $JIRA_URL/rest/api/3/issue/{key}` → extract `fields.summary`, `fields.description`, `fields.acceptance_criteria` (custom field or description), `fields.priority.name`.
- If `_EPIC_ID` not set: AskUserQuestion to provide the Epic ID.
- Save artifact: `$_TEST_SPECS_DIR/01_epic_${_EPIC_ID}.confirmed.v1.json`:
  ```json
  { "epic_id": "...", "title": "...", "description": "...", "stories": [ { "key": "PROJ-123", "title": "...", "acceptance_criteria": "...", "priority": "High" } ] }
  ```

If `_JIRA_AVAILABLE=0`: AskUserQuestion to provide Epic title + story descriptions manually; structure them into the same JSON format and save.

Use `AskUserQuestion`: "Epic: <title>, <N> stories loaded. Confirm and proceed to feature extraction?"

### Phase 2 — Extract Features

Group stories by domain/component (infer from labels, component fields, or summary keywords like "auth", "billing", "user", "dashboard").

For each feature group: `{ "name": "...", "description": "...", "story_keys": [...], "estimated_test_cases": N }`.

Save: `$_TEST_SPECS_DIR/02_features_${_EPIC_ID}.confirmed.v1.json`.

Use `AskUserQuestion`: "Extracted <N> feature groups: <list>. Confirm structure and proceed to test plan?"

### Phase 3 — Generate Test Plan

For each feature, generate test cases covering:
- Happy path (primary user flow)
- Edge cases (empty input, boundary values, concurrent access)
- Negative tests (invalid data, missing auth, rate limits)
- Priority: Critical / High / Medium

For each test case: `{ "id": "TC-001", "feature": "...", "title": "...", "preconditions": [...], "steps": [...], "expected_result": "...", "priority": "Critical|High|Medium" }`.

Save: `$_TEST_SPECS_DIR/03_testplan_${_EPIC_ID}.confirmed.v1.json`.

Use `AskUserQuestion`: "Generated <N> test cases across <N> features. Review and confirm before Playwright generation?"

### Phase 4 — Generate Playwright Skeletons

Detect existing Playwright convention:
- Check for `e2e/`, `playwright/`, `tests/e2e/` directories
- Read `playwright.config.ts` if present for `testDir`
- Default to `e2e/` if none found

For each feature, write `<testDir>/<feature-kebab-case>.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

// Feature: <feature name>
// Epic: <epic_id> — <epic_title>

test.describe('<feature name>', () => {
  // TC-001: <test case title>
  // Story: <JIRA-KEY> — <story title>
  // Priority: Critical
  test('<test case title>', async ({ page }) => {
    // Preconditions: <precondition list>
    // TODO: Set up preconditions

    // Step 1: <step>
    // TODO: await page.goto('...');

    // Step 2: <step>
    // TODO: await page.getByRole('...').click();

    // Expected: <expected_result>
    // TODO: Replace placeholder assertion with real check
    await expect(page.getByRole('heading')).toBeVisible();
  });
```

After writing all spec files:
- Build traceability matrix: `{ "epic_id": "...", "generated": "<date>", "mappings": [ { "tc_id": "TC-001", "story_key": "PROJ-123", "spec_file": "e2e/auth.spec.ts", "test_name": "..." } ] }`
- Save: `$_TEST_SPECS_DIR/04_traceability_${_EPIC_ID}.json`

If `_TCMS_TYPE = "testrail"`:
- For each test case: `POST $TESTRAIL_URL/index.php?/api/v2/add_case/{section_id}` with `{ title, refs: "$_EPIC_ID", steps_separated: [...] }` (use `Authorization: Basic` with base64-encoded credentials from `TESTRAIL_USER:TESTRAIL_TOKEN` env vars).

If `_TCMS_TYPE = "xray"`:
- `POST $XRAY_URL/rest/raven/1.0/import/test` with test case payload.

Write report: "Epic → Playwright Pipeline Complete":
- N Playwright spec files written to `<testDir>/`
- N test cases generated (breakdown by priority)
- Traceability matrix: `$_TEST_SPECS_DIR/04_traceability_${_EPIC_ID}.json`
- TCMS push status (N pushed / not configured)
- Next step: "Run /qa-web to execute the generated specs"

---

## Mode B: Figma → Test Cases at Sprint Kickoff (BL-051)

### Phase 1 — Discover Figma URLs

If `_JIRA_AVAILABLE=1`:
- Determine active sprint: `GET $JIRA_URL/rest/agile/1.0/board` → find board ID, then `GET .../board/{id}/sprint?state=active` → sprint ID.
- Fetch sprint tickets: `GET $JIRA_URL/rest/agile/1.0/board/{id}/sprint/{sprintId}/issue?maxResults=50`
- For each ticket: search `fields.description` and `fields.comment.comments[].body` for URLs matching pattern `figma\.com/(file|design)/([A-Za-z0-9]+)` and optional `node-id` query param.
- Collect: `[{ "ticket_key": "PROJ-123", "ticket_title": "...", "figma_url": "...", "figma_file_key": "...", "figma_node_id": "..." }]`
- If no Figma URLs found in JIRA: AskUserQuestion "No Figma URLs found in sprint tickets. Paste Figma URLs manually (one per line)?"

If `_JIRA_AVAILABLE=0`: AskUserQuestion to paste Figma URLs with their associated ticket keys.

Log: `FIGMA_URLS_FOUND: N`.

### Phase 2 — Fetch Figma Frame Images

For each discovered Figma URL (if `_FIGMA_AVAILABLE=1`):
- Parse `figma_file_key` and `figma_node_id` from URL (node-id may be URL-encoded, e.g. `0%3A1` → `0:1`).
- `GET https://api.figma.com/v1/images/{figma_file_key}?ids={figma_node_id}&format=png&scale=2` with header `X-Figma-Token: $FIGMA_TOKEN`.
- Download the returned image URL to `$_TMP/figma-{figma_node_id_safe}.png` using `curl -L -o`.
- If download fails: log `FIGMA_FETCH_FAILED: {ticket_key} — {reason}` and continue.

If `_FIGMA_AVAILABLE=0`: AskUserQuestion to share screenshots directly; save them to `$_TMP/figma-manual-{n}.png`.

### Phase 3 — Vision Analysis

For each downloaded frame PNG, use the Read tool to view the image, then analyze:

Prompt for each frame:
> "Analyze this Figma design frame for ticket {ticket_key}: '{ticket_title}'.
> Identify all interactive elements, user flows, input fields, buttons, and states visible.
> Generate structured test cases covering: (1) Happy path user flow, (2) Input validation, (3) Error states shown in the design, (4) Navigation flows.
> For each test case provide: Title, Preconditions (array), Steps (numbered array), Expected Result, Priority (Critical/High/Medium).
> Output as a JSON array of test case objects."

Parse the Claude response into structured test cases. Save:
`$_TEST_SPECS_DIR/figma_{ticket_key}_{figma_node_id_safe}_testcases.json`:
```json
{ "ticket_key": "PROJ-123", "figma_file_key": "...", "generated": "<date>", "test_cases": [...] }
```

### Phase 4 — Push to TCMS and Report

If `_TCMS_TYPE = "testrail"`:
- For each test case: `POST $TESTRAIL_URL/index.php?/api/v2/add_case/{section_id}`:
  ```json
  { "title": "...", "refs": "{ticket_key}", "type_id": 1, "steps_separated": [{"content": "...", "expected": "..."}] }
  ```
- Auth: `Authorization: Basic <base64(TESTRAIL_USER:TESTRAIL_TOKEN)>`

If `_TCMS_TYPE = "xray"`:
- `POST $XRAY_URL/rest/raven/1.0/import/test` with Xray test format payload.

If `_TCMS_TYPE = "none"`:
- Write `$_TEST_SPECS_DIR/figma_testcases_sprint_${_DATE}.md`:
  ```markdown
  # Sprint Test Cases from Figma — <date>
  ## <ticket_key>: <ticket_title>
  ### TC-001: <title>
  **Priority:** Critical
  **Preconditions:** ...
  **Steps:** 1. ...
  **Expected:** ...
  ```

Write sprint kickoff report:
- N Figma frames analyzed
- N test cases generated (breakdown: Critical / High / Medium)
- TCMS push status (N pushed to <TCMS_TYPE> / saved to markdown)
- Any frames that failed analysis or download
- Next step: "Review generated test cases in TCMS / test-specs/ before sprint execution"

---

## Important Rules

- Never expose JIRA_TOKEN, FIGMA_TOKEN, or TESTRAIL_TOKEN in output or logs
- All versioned artifacts in `$_TEST_SPECS_DIR/` are the primary deliverables — write them even if TCMS push is skipped
- If JIRA is unavailable, the skill runs in manual-input mode — do not exit
- Generated Playwright specs are skeletons (// TODO: stubs) — they pass `tsc --noEmit` but are not complete implementations; clearly label them as such
- Figma node IDs in URLs may be URL-encoded — always decode before API calls
- AskUserQuestion confirmation gates are mandatory between Mode A pipeline stages; do not skip them even in non-interactive mode
