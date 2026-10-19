#!/usr/bin/env bash
# scripts/gen-skill-docs.sh — Generate SKILL.md and subagent bodies from SKILL.md.tmpl.
#
# SKILL.md.tmpl is the single source of truth:
#   <skill>/SKILL.md.tmpl  →  <skill>/SKILL.md                 (verbatim copy)
#   <skill>/SKILL.md.tmpl  →  .claude/agents/<skill>.md body   (frontmatter kept from the
#                                                               agent file; body regenerated)
# Agent bodies get a "Running as a subagent" preamble, lose the interactive
# "## Version check" section, and have ${CLAUDE_SKILL_DIR} (substituted by Claude Code
# in skill bodies only) rewritten to the stable install path ~/.claude/qa-agentic-team.
#
# Never edit SKILL.md or an agent body directly — edit the .tmpl, then run this.
# Agents without a matching <skill>/SKILL.md.tmpl (e.g. learning-sources-refinement)
# are hand-maintained and left untouched.
#
# Usage: bash scripts/gen-skill-docs.sh [--check]
#   --check   write nothing; exit 1 if any generated file is stale (used in CI)
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

_agent_body() {  # _agent_body <skill-name> <tmpl>
  local name="$1" tmpl="$2"
  cat <<EOF

<!-- GENERATED from $name/SKILL.md.tmpl by scripts/gen-skill-docs.sh — edit the template, not this body. -->

## Running as a subagent

You were started by \`/qa-team\` (or another orchestrator) with a brief. In this mode:

- You cannot ask the user anything and cannot start other agents. Wherever this procedure says to use AskUserQuestion, use what the brief says instead.
- A gated step (\`**Gate (KEY):**\`) runs only if the brief's \`APPROVALS:\` line contains that KEY. Otherwise skip it and list it under **Needs a decision** in your report.
- Probe only the \`TARGET=\` URL given in the brief, if any. Never pick a target URL from \`.env\` or config files on your own.
- Where this procedure says to spawn sub-agents, do that work yourself, sequentially.
- Paths starting with \`\$HOME/.claude/qa-agentic-team\` point at this suite's install. The Read tool does not expand \`\$HOME\`: run \`echo "\$HOME"\` once and pass absolute paths.
- Write your report and CTRF file to the brief's \`REPORT:\` and \`CTRF:\` paths, even where this procedure names other (e.g. dated) paths. With no \`TARGET=\`, run nothing against an app: write or review tests only. End your reply with the report path, a one-line status, and the **Needs a decision** list (or "none").

EOF
  # Body of the template: drop the frontmatter and the interactive version-check section,
  # then map ${CLAUDE_SKILL_DIR} to the stable install path.
  awk '
    NR == 1 && /^---$/ { in_fm = 1; next }
    in_fm && /^---$/   { in_fm = 0; skip_blank = 1; next }
    in_fm              { next }
    /^## Version check/ { in_vc = 1; next }
    in_vc && /^---$/    { in_vc = 0; skip_blank = 1; next }
    in_vc               { next }
    skip_blank && /^[[:space:]]*$/ { next }
    { skip_blank = 0; print }
  ' "$tmpl" | NAME="$name" perl -pe '
    s/\$\{CLAUDE_SKILL_DIR\}\/\.\./\$HOME\/.claude\/qa-agentic-team/g;
    s/\$\{CLAUDE_SKILL_DIR\}/\$HOME\/.claude\/qa-agentic-team\/$ENV{NAME}/g;
  '
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Skills (SKILL.md.tmpl → SKILL.md):"
for tmpl in "$REPO_DIR"/*/SKILL.md.tmpl; do
  _emit "$(dirname "$tmpl")/SKILL.md" "$tmpl"
done

echo "Agents (.claude/agents/<skill>.md body ← <skill>/SKILL.md.tmpl):"
for agent in "$REPO_DIR"/.claude/agents/*.md; do
  name="$(basename "$agent" .md)"
  tmpl="$REPO_DIR/$name/SKILL.md.tmpl"
  [ -f "$tmpl" ] || { echo "  KEEP   .claude/agents/$name.md (hand-maintained: no $name/SKILL.md.tmpl)"; continue; }
  out="$TMP_DIR/$name.md"
  # Frontmatter: everything up to and including the second '---' line of the agent file.
  awk 'NR == 1 && /^---$/ { print; fm = 1; next } fm { print } fm && /^---$/ { exit }' "$agent" > "$out"
  _agent_body "$name" "$tmpl" >> "$out"
  _emit "$agent" "$out"
done

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
