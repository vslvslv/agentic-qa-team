# qa-agentic-team — Developer Notes

## Architecture

- **Skills** (`*/SKILL.md.tmpl`): User-facing slash commands loaded into the main conversation context. Never edit `.md` directly — edit `.tmpl` and run `npm run gen:skill-docs`.
- **Subagents** (`.claude/agents/*.md`): Context-isolated execution environments installed at `~/.claude/agents/` by `bin/setup`. Each agent runs with `model: sonnet`, `memory: project`, and inline safety hooks. Keep in sync with the corresponding `SKILL.md.tmpl` body.
- **Hook scripts** (`bin/hooks/`): Deterministic guardrails invoked by skill and agent frontmatter hooks. `qa-pre-bash-safety.sh` blocks broad `rm -rf` commands; `qa-post-write-typecheck.sh` runs an async `tsc --noEmit` after spec files are written.
- **Version check helper** (`bin/qa-version-check-inline.sh`): Used by `!bash` injection in all skill preambles. Runs `bin/qa-team-update-check` and emits `VERSION_STATUS` + `SKIP_UPDATE_ASK` for the skill to act on.

## Build

```bash
npm run gen:skill-docs   # regenerate all SKILL.md from .tmpl
npm run check:skill-docs # validate freshness (used in CI)
```

## Installation

```bash
bash bin/setup           # installs skills + agents + Stop hook (interactive)
bash bin/setup --with-hook  # unattended install
```

## Version bumping

Edit `VERSION`, add entry to `CHANGELOG.md`. Format: `MAJOR.MINOR.PATCH.MICRO`.
- **Minor** bump (1.5 → 1.6): architectural changes, new features
- **Patch** bump (1.5.x): content improvements, bug fixes
- **Micro** bump (1.5.10.x): nightly refinement runs

## Adding a new skill/agent

1. Create `qa-<domain>/SKILL.md.tmpl` following the existing frontmatter pattern (include `disable-model-invocation: true`, `model: sonnet`, `effort: high`, and the hooks block)
2. Create `.claude/agents/qa-<domain>.md` — same frontmatter as above but with `memory: project` instead of `disable-model-invocation`; body mirrors the skill body (without the version check section)
3. Update `qa-team/SKILL.md.tmpl` to include the new agent in Phase 2 dispatch
4. Add the skill directory to `bin/setup` discovery (automatic — any dir with a `SKILL.md` is picked up)
5. Run `npm run gen:skill-docs` to generate the `.md` from `.tmpl`
6. Run `npm run check:skill-docs` to confirm freshness
