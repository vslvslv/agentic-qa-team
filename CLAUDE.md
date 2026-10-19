# agentic-qa-team — Developer Notes

This repo is the **`qa` Claude Code plugin** and its own marketplace (`agentic-qa-team`). Users install it with `/plugin install qa@agentic-qa-team`; skills are `/qa:<name>`, agents are `qa:<name>`.

## Layout

| Path | What |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (`name: qa`; `version` must equal `VERSION`) |
| `.claude-plugin/marketplace.json` | Marketplace manifest; the plugin source is the repo root |
| `skills/<name>/SKILL.md.tmpl` | **Source of truth** for skill `/qa:<name>`; `SKILL.md` is a generated copy |
| `agents/<name>.md` | Plugin subagent `qa:<name>`: frontmatter hand-maintained, **body generated** from `skills/<name>/SKILL.md.tmpl` |
| `hooks/hooks.json` | Plugin hooks: rm guard + typecheck (scoped to `qa:*` agents), Stop re-run nudge |
| `bin/hooks/` | Hook scripts; tests in `tests/hooks.test.sh` |
| `qa-methodology/`, `qa-refine-workspace/`, `learning-sources/` | Shared data shipped with the plugin |
| `.claude/skills/`, `.claude/agents/` | Maintainer-only skills (refine guides, learning sources) — loaded only when working in this repo, never shipped as plugin skills |

## Rules

- Paths: in skill bodies use `${CLAUDE_SKILL_DIR}` (the skill's own folder) or `${CLAUDE_PLUGIN_ROOT}` (plugin root). Both are substituted by Claude Code in skill text; agents get `${CLAUDE_PLUGIN_ROOT}/skills/<name>` from the generator. Neither is set in the environment of Bash tool calls, so never rely on them as shell variables.
- Plugin agents ignore `hooks`, `mcpServers` and `permissionMode` frontmatter. Agent guardrails live in `hooks/hooks.json`, which fires in every session, so hook scripts called from there get `--plugin-agents-only` and act only when `agent_type` is `qa:*`. Skill frontmatter hooks call the same scripts without the flag.
- Every QA skill has `disable-model-invocation: true`. `/qa:team` dispatches the agents with `subagent_type: "qa:<name>"`.
- **Gates**: risky steps are written as `**Gate (KEY):**`. Interactively the skill asks; as a subagent it proceeds only if the brief's `APPROVALS:` line has the key. Keys: `TARGET=<url>` (the only URL that may be probed), `ALLOW_ACTIVE_SCAN`, `ALLOW_FORM_SUBMIT` (forms or POST/PUT/PATCH/DELETE to TARGET), `ALLOW_DB_WRITE` (`$TEST_DATABASE_URL` only), `ALLOW_INSTALL`, `ALLOW_COMMIT`, `ALLOW_PR`, `ALLOW_ISSUE`. Nothing is granted by default.
- Reference guides (`*/references/`, `*/tools/`) are capped at 3,000 lines (`scripts/check-guide-size.sh`). Skills grep headings and read sections, never whole files. The maintainer refine skills replace and condense guides and never edit skill templates.

## Develop

```bash
claude --plugin-dir .      # load this checkout as the plugin (in place; /reload-plugins after edits)
npm run gen:skill-docs     # regenerate SKILL.md + agent bodies; syncs plugin.json version from VERSION
npm run check:skill-docs   # CI: generated files fresh, plugin.json version = VERSION
npm run check:guides       # CI: guide size cap
npm run test:hooks         # CI: hook table tests
claude plugin validate .   # manifest + component validation
```

## Version bumping

Edit `VERSION` (then `npm run gen:skill-docs` copies it into `plugin.json`) and add a `CHANGELOG.md` entry. Format `MAJOR.MINOR.PATCH.MICRO`. Installed users only receive an update when the version changes.
- **Minor**: architectural changes, new skills
- **Patch**: content improvements, bug fixes
- **Micro**: guide-only refreshes

## Adding a skill

See `docs/contributing/adding-a-skill.md`.
