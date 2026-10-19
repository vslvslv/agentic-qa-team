#!/usr/bin/env bash
# scripts/gen-skill-docs.sh — Generate SKILL.md files and subagent bodies from SKILL.md.tmpl.
#
# SKILL.md.tmpl is the single source of truth:
#   skills/<name>/SKILL.md.tmpl          → skills/<name>/SKILL.md          (verbatim copy)
#   skills/<name>/SKILL.md.tmpl          → agents/<name>.md body           (plugin agent qa:<name>)
#   .claude/skills/<name>/SKILL.md.tmpl  → .claude/skills/<name>/SKILL.md  (maintainer skills)
#   .claude/skills/<name>/SKILL.md.tmpl  → .claude/agents/<name>.md body   (if that agent exists)
#
# Agent frontmatter is hand-maintained; the body is regenerated with a "Running as a
# subagent" preamble. ${CLAUDE_SKILL_DIR} (substituted by Claude Code in skills only) is
# rewritten to ${CLAUDE_PLUGIN_ROOT}/skills/<name> for plugin agents (substituted by Claude
# Code in plugin agent bodies) and to .claude/skills/<name> for the repo's own agents.
#
# --check also verifies .claude-plugin/plugin.json "version" equals VERSION.
#
# Never edit SKILL.md or an agent body directly — edit the .tmpl, then run this.
#
# Usage: bash scripts/gen-skill-docs.sh [--check]
#   --check   write nothing; exit 1 if anything is stale (used in CI)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-write}"
STALE=0
GENERATED=0

_emit() {  # _emit <dest> <content-file>
  local dest="$1" src="$2" rel="${1#"$REPO_DIR"/}"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    return 0
  fi
  if [ "$MODE" = "--check" ]; then
    echo "  STALE  $rel"
    STALE=$((STALE + 1))
  else
    cp "$src" "$dest"
    echo "  GEN    $rel"
    GENERATED=$((GENERATED + 1))
  fi
}

_agent_body() {  # _agent_body <name> <tmpl> <skill-dir-replacement>
  local name="$1" tmpl="$2" skill_dir="$3" rel_tmpl="${2#"$REPO_DIR"/}"
  cat <<EOF

<!-- GENERATED from $rel_tmpl by scripts/gen-skill-docs.sh — edit the template, not this body. -->

## Running as a subagent

You were started by \`/qa:team\` (or another orchestrator) with a brief. In this mode:

- You cannot ask the user anything and cannot start other agents. Wherever this procedure says to use AskUserQuestion, use what the brief says instead.
- A gated step (\`**Gate (KEY):**\`) runs only if the brief's \`APPROVALS:\` line contains that KEY. Otherwise skip it and list it under **Needs a decision** in your report.
- Probe only the \`TARGET=\` URL given in the brief, if any. Never pick a target URL from \`.env\` or config files on your own.
- Where this procedure says to spawn sub-agents, do that work yourself, sequentially.
- Write your report and CTRF file to the brief's \`REPORT:\` and \`CTRF:\` paths, even where this procedure names other (e.g. dated) paths. With no \`TARGET=\`, run nothing against an app: write or review tests only. End your reply with the report path, a one-line status, and the **Needs a decision** list (or "none").

EOF
  # Template body: drop the frontmatter and any interactive version-check section,
  # then map ${CLAUDE_SKILL_DIR} for the agent context.
  awk '
    NR == 1 && /^---$/ { in_fm = 1; next }
    in_fm && /^---$/   { in_fm = 0; skip_blank = 1; next }
    in_fm              { next }
    /^## Version check/ { in_vc = 1; next }
    in_vc && /^---$/    { in_vc = 0; skip_blank = 1; next }
    in_vc               { next }
    skip_blank && /^[[:space:]]*$/ { next }
    { skip_blank = 0; print }
  ' "$tmpl" | SKILL_DIR="$skill_dir" perl -pe 's/\$\{CLAUDE_SKILL_DIR\}/$ENV{SKILL_DIR}/g'
}

_gen_agent() {  # _gen_agent <agent-file> <tmpl> <skill-dir-replacement>
  local agent="$1" tmpl="$2" skill_dir="$3" out
  out="$TMP_DIR/$(basename "$agent")"
  # Frontmatter: everything up to and including the second '---' line of the agent file.
  awk 'NR == 1 && /^---$/ { print; fm = 1; next } fm { print } fm && /^---$/ { exit }' "$agent" > "$out"
  _agent_body "$(basename "$agent" .md)" "$tmpl" "$skill_dir" >> "$out"
  _emit "$agent" "$out"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Skills (SKILL.md.tmpl → SKILL.md):"
for tmpl in "$REPO_DIR"/skills/*/SKILL.md.tmpl "$REPO_DIR"/.claude/skills/*/SKILL.md.tmpl; do
  [ -f "$tmpl" ] || continue
  _emit "$(dirname "$tmpl")/SKILL.md" "$tmpl"
done

echo "Plugin agents (agents/<name>.md ← skills/<name>/SKILL.md.tmpl):"
for agent in "$REPO_DIR"/agents/*.md; do
  name="$(basename "$agent" .md)"
  tmpl="$REPO_DIR/skills/$name/SKILL.md.tmpl"
  if [ ! -f "$tmpl" ]; then
    echo "  ERROR  agents/$name.md has no skills/$name/SKILL.md.tmpl"
    STALE=$((STALE + 1))
    continue
  fi
  _gen_agent "$agent" "$tmpl" "\${CLAUDE_PLUGIN_ROOT}/skills/$name"
done

echo "Repo agents (.claude/agents/<name>.md ← .claude/skills/<name>/SKILL.md.tmpl):"
for agent in "$REPO_DIR"/.claude/agents/*.md; do
  [ -f "$agent" ] || continue
  name="$(basename "$agent" .md)"
  tmpl="$REPO_DIR/.claude/skills/$name/SKILL.md.tmpl"
  [ -f "$tmpl" ] || { echo "  KEEP   .claude/agents/$name.md (no template)"; continue; }
  _gen_agent "$agent" "$tmpl" ".claude/skills/$name"
done

# plugin.json version must track VERSION (a pinned plugin version gates updates).
PLUGIN_VERSION=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
  "$REPO_DIR/.claude-plugin/plugin.json")
REPO_VERSION=$(tr -d '[:space:]' < "$REPO_DIR/VERSION")
if [ "$PLUGIN_VERSION" != "$REPO_VERSION" ]; then
  if [ "$MODE" = "--check" ]; then
    echo "  STALE  .claude-plugin/plugin.json version $PLUGIN_VERSION != VERSION $REPO_VERSION"
    STALE=$((STALE + 1))
  else
    python3 -I - "$REPO_DIR/.claude-plugin/plugin.json" "$REPO_VERSION" <<'PY'
import json, sys
path, version = sys.argv[1], sys.argv[2]
data = json.load(open(path))
data["version"] = version
open(path, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
PY
    echo "  GEN    .claude-plugin/plugin.json version → $REPO_VERSION"
    GENERATED=$((GENERATED + 1))
  fi
fi

echo ""
if [ "$MODE" = "--check" ]; then
  if [ "$STALE" -gt 0 ]; then
    echo "FAIL: $STALE generated file(s) are stale. Run 'bash scripts/gen-skill-docs.sh' and commit."
    exit 1
  fi
  echo "All generated files are up to date."
else
  echo "Done. Generated: $GENERATED"
fi
