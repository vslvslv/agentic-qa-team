# Adding a New Skill

The checklist for adding a skill to the `qa` plugin. Follow the steps in order.

---

## 1. Create the skill directory

```bash
mkdir skills/<name>
```

The skill becomes `/qa:<name>`, and its agent `qa:<name>`. Use a short name without a `qa-` prefix.

---

## 2. Write `skills/<name>/SKILL.md.tmpl`

The template is the single source of truth. `SKILL.md` and the agent body are generated from it (step 5).

```yaml
---
name: <name>
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
          command: 'bash "${CLAUDE_PLUGIN_ROOT}/bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_PLUGIN_ROOT}/bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---
```

Paths in the body: `${CLAUDE_SKILL_DIR}/references/...` for the skill's own files, `${CLAUDE_PLUGIN_ROOT}/...` for shared ones (e.g. `${CLAUDE_PLUGIN_ROOT}/qa-methodology/references/`). Claude Code substitutes both in the text; neither exists as an environment variable in Bash calls.

### Gates for anything risky

The same body runs interactively and as a subagent dispatched by `/qa:team`. Subagents cannot ask the user, so write every risky step as a gate:

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

## 3. Create `agents/<name>.md` — frontmatter only

```yaml
---
name: <name>
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
---
```

Leave out `AskUserQuestion` and `Agent` (subagents can use neither) and `hooks` (ignored for plugin agents; the plugin's `hooks/hooks.json` covers `qa:*` agents). The body is generated in step 5; never write it by hand.

---

## 4. Decide whether `/qa:team` proposes it

In `skills/team/SKILL.md.tmpl` Phase 0, add the skill as **Core** (always useful when its precondition is detected), **Proposed** (shown in the plan, needs the user's yes or approvals), or **Available on request** (listed with its trigger). Add a cheap detection for its precondition to the Preamble, and give it only the approval keys it needs in the brief rules.

---

## 5. Regenerate and verify

```bash
npm run gen:skill-docs      # SKILL.md + the agent body
npm run check:skill-docs    # must pass (CI runs it)
npm run check:guides        # guide size cap
npm run test:hooks          # hook table tests
claude plugin validate .
claude --plugin-dir .       # try /qa:<name> for real
```

---

## 6. Update VERSION and CHANGELOG.md

New skill = minor bump:

```bash
bash bin/qa-team-next-version minor > VERSION
npm run gen:skill-docs      # copies VERSION into .claude-plugin/plugin.json
```

Add an entry to `CHANGELOG.md`:

```markdown
## v1.X.0.0 — YYYY-MM-DD — /qa:<name> skill

### /qa:<name> (new skill)
- What it does
- Gates it uses
- Env vars / opt-in flags
```

---

## 7. Open the PR

CI runs `checks.yml` (manifests, generated files, plugin version, guide size, hook tests, shell syntax) and `version-gate.yml` (VERSION bumped and a CHANGELOG entry). Both must pass.

---

## Checklist

- [ ] `skills/<name>/SKILL.md.tmpl` with frontmatter, `disable-model-invocation: true`, `${CLAUDE_PLUGIN_ROOT}` hook paths
- [ ] Every risky step written as a `**Gate (KEY):**`
- [ ] Bash blocks self-contained (no state carried between calls)
- [ ] Report and CTRF written to `$_TMP` (or the brief's paths)
- [ ] `agents/<name>.md` with frontmatter only
- [ ] `/qa:team` placement decided (Core / Proposed / On request)
- [ ] `npm run gen:skill-docs`, all checks and `claude plugin validate .` pass
- [ ] VERSION bumped (minor) and CHANGELOG entry added
