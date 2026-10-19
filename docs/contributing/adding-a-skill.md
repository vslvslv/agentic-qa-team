# Adding a New Skill

The checklist for adding a skill to qa-agentic-team. Follow the steps in order.

---

## 1. Create the skill directory

```bash
mkdir qa-<name>
```

The directory must be a **direct child of the repo root**: `bin/setup` links every `*/SKILL.md` it finds there.

---

## 2. Write `qa-<name>/SKILL.md.tmpl`

The template is the single source of truth. `SKILL.md` and the agent body are generated from it (step 5).

```yaml
---
name: qa-<name>
version: 1.0.0
description: |
  One or two sentences describing what the skill does.
  Include the trigger phrases users would say ("fix broken tests", "run load test", etc.).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent          # only if the skill spawns sub-agents
  - WebFetch       # only if the skill fetches URLs
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
```

Hooks must use the `$HOME/.claude/qa-agentic-team` path: Claude Code does not expose `${CLAUDE_SKILL_DIR}` to hook processes. In the **body**, `${CLAUDE_SKILL_DIR}` is fine (Claude Code substitutes it; the generator maps it for agents).

### Version check section (always first; stripped from the agent)

```markdown
## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: first show what would change with `git -C "$HOME/.claude/qa-agentic-team" fetch -q && git -C "$HOME/.claude/qa-agentic-team" log --oneline HEAD..@{u} | head -20`, then run `git -C "$HOME/.claude/qa-agentic-team" pull --ff-only && bash "$HOME/.claude/qa-agentic-team/bin/setup" --no-hook`. Continue regardless.

---
```

### Gates for anything risky

The same body runs interactively and as a subagent dispatched by `/qa-team`. Subagents cannot ask the user, so write every risky step as a gate:

```markdown
**Gate (ALLOW_COMMIT):** <what will happen>. Interactive: ask with AskUserQuestion and proceed only on yes. As a subagent: proceed only if the brief's `APPROVALS:` line contains `ALLOW_COMMIT`; otherwise skip and list the step under "Needs a decision" in the report.
```

| Key | Covers |
|---|---|
| `TARGET=<url>` | the only URL the skill may probe; with no target, run nothing against an app |
| `ALLOW_ACTIVE_SCAN` | intrusive security scans, fuzzing, chaos experiments |
| `ALLOW_FORM_SUBMIT` | submitting forms or sending POST/PUT/PATCH/DELETE to the target |
| `ALLOW_DB_WRITE` | writes to the database in `$TEST_DATABASE_URL` (never `DATABASE_URL`) |
| `ALLOW_INSTALL` | installing packages or tools (`npm install`, `pip install`, `npx --yes`, image pulls) |
| `ALLOW_COMMIT` / `ALLOW_PR` / `ALLOW_ISSUE` | git commits, pushing + opening a PR, filing issues or PR comments |

Nothing is granted by default. If the skill spawns sub-agents, add a sentence saying that as a subagent it does that work itself, sequentially.

### Preamble, phases, report

```markdown
## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"
# Detect prerequisites; print KEY: value for everything discovered
```

## Phase 1 — <name>
...
## Phase N — Report

Write `$_TMP/qa-<name>-report.md` and `$_TMP/qa-<name>-ctrf.json`
(as a subagent, use the brief's `REPORT:` and `CTRF:` paths).

## Important Rules
- ...
```

Each Bash tool call starts a fresh shell: a block must not rely on variables set in an earlier block (recompute them, or save them to a file under `$_TMP`). To use a reference guide, grep its headings and read only the sections you need; never read a whole guide.

---

## 3. Create `.claude/agents/qa-<name>.md` — frontmatter only

```yaml
---
name: qa-<name>
description: |
  Same description as the skill.
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
model: sonnet
color: blue
memory: project
hooks:
  # same hooks block as the skill
---
```

Leave out `AskUserQuestion` and `Agent`: subagents can use neither. The body is generated in step 5; never write it by hand.

---

## 4. Decide whether `/qa-team` proposes it

In `qa-team/SKILL.md.tmpl` Phase 0, add the skill as **Core** (always useful when its precondition is detected), **Proposed** (shown in the plan, needs the user's yes or approvals), or **Available on request** (listed with its trigger). Add a cheap detection for its precondition to the Preamble, and give it only the approval keys it needs in the brief rules. Intent-driven skills (like `/qa-manager`) belong under "Available on request".

---

## 5. Regenerate and verify

```bash
npm run gen:skill-docs      # SKILL.md + the agent body
npm run check:skill-docs    # must pass (CI runs it)
npm run check:guides        # guide size cap
npm run test:hooks          # hook table tests
```

---

## 6. Update VERSION and CHANGELOG.md

New skill = minor bump:

```bash
bash bin/qa-team-next-version minor > VERSION
```

Add an entry to `CHANGELOG.md`:

```markdown
## v1.X.0.0 — YYYY-MM-DD — qa-<name> skill

### qa-<name> (new skill)
- What it does
- Gates it uses
- Env vars / opt-in flags
```

---

## 7. Open the PR

CI runs `checks.yml` (generated files, guide size, hook tests, shell syntax) and `version-gate.yml` (VERSION bumped and a CHANGELOG entry). Both must pass.

---

## Checklist

- [ ] `qa-<name>/SKILL.md.tmpl` with frontmatter, `disable-model-invocation: true`, `$HOME/.claude/qa-agentic-team` hook paths
- [ ] Version check section first
- [ ] Every risky step written as a `**Gate (KEY):**`
- [ ] Bash blocks self-contained (no state carried between calls)
- [ ] Report and CTRF written to `$_TMP` (or the brief's paths)
- [ ] `.claude/agents/qa-<name>.md` with frontmatter only
- [ ] `/qa-team` placement decided (Core / Proposed / On request)
- [ ] `npm run gen:skill-docs` and all checks pass
- [ ] VERSION bumped (minor) and CHANGELOG entry added
