#!/usr/bin/env bash
# scripts/gen-skill-docs.sh — Generate SKILL.md from SKILL.md.tmpl for each skill.
# SKILL.md.tmpl is the source of truth. Never edit SKILL.md directly.
# Usage: bash scripts/gen-skill-docs.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${1:-}"
GENERATED=0
SKIPPED=0

echo "Generating SKILL.md from SKILL.md.tmpl..."
echo ""

while IFS= read -r tmpl_file; do
  skill_dir="$(dirname "$tmpl_file")"
  out_file="$skill_dir/SKILL.md"

  # Check if already up to date
  if [ -f "$out_file" ] && diff -q "$tmpl_file" "$out_file" > /dev/null 2>&1; then
    skill_name="$(basename "$skill_dir")"
    echo "  OK    $skill_name (up to date)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  skill_name="$(basename "$skill_dir")"
  if [ -n "$DRY_RUN" ]; then
    echo "  WOULD_GEN $skill_name"
  else
    cp "$tmpl_file" "$out_file"
    echo "  GEN   $skill_name"
    GENERATED=$((GENERATED + 1))
  fi
done < <(
  find "$REPO_DIR" -maxdepth 2 -name "SKILL.md.tmpl" \
    ! -path "*/node_modules/*" ! -path "*/.git/*" | sort
)

echo ""
echo "Done. Generated: $GENERATED  Skipped (up to date): $SKIPPED"
