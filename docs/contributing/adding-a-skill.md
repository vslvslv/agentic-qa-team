# Adding a New Skill

This is the complete checklist for adding a new skill to qa-agentic-team. Follow each step in order.

---

## 1. Create the skill directory

```bash
mkdir qa-<name>
```

The directory must be a **direct child of the repo root** — `bin/setup` discovers skills by searching `$REPO_DIR -maxdepth 2 -name "SKILL.md"`.

---

## 2. Write `qa-<name>/SKILL.md.tmpl`

Use this frontmatter template:

```yaml
---
name: qa-<name>
preamble-tier: 3
version: 1.0.0
description: |
  One or two sentences describing what the skill does.
  Include the trigger phrases users would say ("fix broken tests", "run load test", etc.).
  End with: (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent          # include if skill spawns sub-agents
  - WebFetch       # include if skill fetches URLs
  - WebSearch      # include if skill searches the web
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
```

Then add the body sections:

### Version check section (always first)

```markdown
## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

---
```

### Preamble (detect environment)

```markdown
## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"

echo "--- DETECTION ---"
# Detect prerequisites, tools, env vars
# Print: KEY: value for everything discovered
echo "--- DONE ---"
```
```

### Phase sections

Number phases sequentially. Use descriptive names:

```markdown
## Phase 1 — <name>

## Phase 2 — <name>

## Phase N — Report

Write `$_TMP/qa-<name>-report-{_DATE}.md` with findings.

Write `$_TMP/qa-<name>-ctrf.json`:
```json
{
  "results": {
    "tool": { "name": "qa-<name>", "version": "1.0.0" },
    "summary": { "tests": N, "passed": N, "failed": N, "pending": 0, "skipped": 0, "other": 0, "start": <epoch>, "stop": <epoch> },
    "tests": [{ "name": "...", "status": "passed|failed", "duration": 0 }]
  }
}
```

## Important Rules

- Rule 1
- Rule 2
```

---

## 3. Create `.claude/agents/qa-<name>.md`

Agent files use `memory: project` instead of `disable-model-invocation: true`. The body mirrors the SKILL.md.tmpl but:
- Remove the Version check section
- Condense phases (keep all the logic, shorter prose is fine)
- Keep the same frontmatter hooks

```yaml
---
name: qa-<name>
description: |
  Same description as SKILL.md.tmpl (without the qa-agentic-team suffix).
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
  # add Agent/WebFetch/WebSearch if needed
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
...
## Phase 1 — <name>
...
```

---

## 4. Add to `qa-team/SKILL.md.tmpl` (if auto-dispatched)

If the skill should be invoked automatically by `/qa-team`, add it to Phase 2 dispatch in `qa-team/SKILL.md.tmpl`:

1. Add preamble detection for the skill's prerequisites
2. Add a dispatch line in Phase 2:
   ```
   - `/qa-<name>` → `$_TMP/qa-<name>-report.md`  (when <condition>)
   ```
3. Add CTRF aggregation in Phase 3:
   ```bash
   [ -f "$_TMP/qa-<name>-ctrf.json" ] && _CTRF_FILES="$_CTRF_FILES $_TMP/qa-<name>-ctrf.json"
   ```

Skills that are intent-driven (user invokes manually) — like `/qa-manager`, `/qa-meta-eval` — do **not** need to be added to `qa-team`.

---

## 5. Add to `bin/setup` available commands

Add a line in the "Available commands" section at the bottom of `bin/setup`:

```bash
echo "  /qa-<name>             — One-line description"
```

---

## 6. Regenerate and verify

```bash
npm run gen:skill-docs      # generates SKILL.md from SKILL.md.tmpl
npm run check:skill-docs    # verifies freshness — must show OK for new skill
```

---

## 7. Update VERSION and CHANGELOG.md

New skill = minor bump:

```bash
bash bin/qa-team-next-version minor > VERSION
```

Add entry to `CHANGELOG.md`:

```markdown
## v1.X.0.0 — YYYY-MM-DD — qa-<name> skill (BL-XXX)

### qa-<name> (new skill)
- What it does
- Key phases
- Env vars / opt-in flags
```

---

## 8. Mark backlog item as implemented

If this skill implements a backlog item, update `BACKLOG.md`:

```markdown
#### BL-XXX — <title> `[M]` ✅ **Implemented v1.X.0.0**
```

---

## 9. Open the PR

CI will check:
- `skill-docs` gate: `SKILL.md` freshness vs `.tmpl`
- `version-gate`: `VERSION` bumped + `CHANGELOG.md` entry

Both must pass.

---

## Checklist

- [ ] `qa-<name>/SKILL.md.tmpl` created with correct frontmatter
- [ ] Version check section present
- [ ] Preamble bash block prints `KEY: value` detection lines
- [ ] All phases present; Phase N (Report) emits `qa-<name>-ctrf.json`
- [ ] Important Rules section at end
- [ ] `.claude/agents/qa-<name>.md` created (mirrors skill, condensed, `memory: project`)
- [ ] Added to `qa-team/SKILL.md.tmpl` (if auto-dispatched)
- [ ] Added to `bin/setup` available commands footer
- [ ] `npm run gen:skill-docs` run — shows `GEN qa-<name>`
- [ ] `npm run check:skill-docs` run — shows `OK qa-<name>`
- [ ] VERSION bumped (minor)
- [ ] CHANGELOG.md entry added
- [ ] BACKLOG.md item marked implemented (if applicable)
