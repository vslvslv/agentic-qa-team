#!/usr/bin/env bash
# scripts/install-new-agents.sh — Copy new agent.md files to .claude/agents/
# Run this script manually to install the 4 new agents created in this session.
# Usage: bash scripts/install-new-agents.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$REPO_DIR/.claude/agents"
mkdir -p "$AGENTS_DIR"

INSTALLED=0
for skill in qa-secrets qa-sca qa-slsa qa-env-parity; do
  src="$REPO_DIR/$skill/agent.md"
  dst="$AGENTS_DIR/$skill.md"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    echo "  Installed: $dst"
    INSTALLED=$((INSTALLED + 1))
  else
    echo "  WARN: $src not found"
  fi
done

echo ""
echo "Done. Agents installed: $INSTALLED"
echo "Run 'bash bin/setup' to link agents to ~/.claude/agents/"
