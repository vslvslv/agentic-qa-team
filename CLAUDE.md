# qa-agentic-team — Developer Notes

## Architecture

- **Skills** (`*/SKILL.md.tmpl`): user-facing slash commands. The `.tmpl` is the single source of truth; `SKILL.md` is a generated copy. Every QA skill has `disable-model-invocation: true` (run only when the user types it).
- **Subagents** (`.claude/agents/<skill>.md`): what `/qa-team` dispatches (`Agent` tool, `subagent_type: "<skill>"`). The frontmatter is hand-maintained; the **body is generated** from `<skill>/SKILL.md.tmpl` by `scripts/gen-skill-docs.sh` (adds a "Running as a subagent" preamble, drops the version check, maps `${CLAUDE_SKILL_DIR}` to `$HOME/.claude/qa-agentic-team/<skill>`). Never edit an agent body by hand. `learning-sources-refinement.md` has no template and is hand-maintained.
- **Gates**: risky steps are written as `**Gate (KEY):**`. Interactively the skill asks with AskUserQuestion; as a subagent it proceeds only if the brief's `APPROVALS:` line contains the key. Keys: `TARGET=<url>` (the only URL that may be probed), `ALLOW_ACTIVE_SCAN` (intrusive security scans, chaos), `ALLOW_FORM_SUBMIT` (forms or POST/PUT/PATCH/DELETE to TARGET), `ALLOW_DB_WRITE` (writes to `TEST_DATABASE_URL` only), `ALLOW_INSTALL` (install packages/tools), `ALLOW_COMMIT`, `ALLOW_PR`, `ALLOW_ISSUE`. Nothing is granted by default.
- **Stable path**: `bin/setup` links the repo at `~/.claude/qa-agentic-team`. Hooks and agents reach scripts only through it, because Claude Code does not expose `${CLAUDE_SKILL_DIR}` to hook processes or agents.
- **Hook scripts** (`bin/hooks/`): `qa-pre-bash-safety.sh` blocks recursive `rm` of broad paths; `qa-post-write-typecheck.sh` runs the project's `tsc --noEmit` after a TS spec is written. Both read the hook JSON on stdin. Tests: `tests/hooks.test.sh`.
- **Version check** (`bin/qa-version-check-inline.sh`): run by the `!` line at the top of each skill. `QA_TEAM_NO_UPDATE_CHECK=1` disables it.
- **Reference guides** (`*/references/`, `*/tools/`): capped at 3,000 lines by CI (`scripts/check-guide-size.sh`). Skills grep headings and read sections, never whole files. The refine skills replace and condense guides; they never append, and they never edit skill templates.

## Build and check

```bash
npm run gen:skill-docs    # regenerate SKILL.md and agent bodies from .tmpl
npm run check:skill-docs  # CI: generated files are fresh
npm run check:guides      # CI: guide size cap
npm run test:hooks        # CI: hook table tests
```

## Installation

```bash
bash bin/setup             # link skills + agents; asks before adding the Stop hook
bash bin/setup --with-hook # unattended, with the Stop hook
bash bin/uninstall         # remove every link into this repo + the Stop hook
```

`bin/setup` never deletes existing files; `--force` moves conflicting ones to a backup folder.

## Version bumping

Edit `VERSION`, add an entry to `CHANGELOG.md`. Format: `MAJOR.MINOR.PATCH.MICRO`.
- **Minor** (1.5 → 1.6): architectural changes, new features
- **Patch** (1.5.x): content improvements, bug fixes
- **Micro** (1.5.10.x): guide-only refreshes

## Adding a new skill/agent

See `docs/contributing/adding-a-skill.md`. In short: write `qa-<domain>/SKILL.md.tmpl` (gates for anything risky), create `.claude/agents/qa-<domain>.md` with **frontmatter only**, decide whether `/qa-team` should propose it, then `npm run gen:skill-docs`.
