#!/usr/bin/env bash
# scripts/check-skill-docs.sh — CI freshness gate.
# Verifies that every SKILL.md is identical to its SKILL.md.tmpl source.
# Exits non-zero if any SKILL.md is stale (diverged from its .tmpl).
# Run after gen-skill-docs.sh in CI; fail merge if stale.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STALE=()

while IFS= read -r tmpl_file; do
  skill_dir="$(dirname "$tmpl_file")"
  out_file="$skill_dir/SKILL.md"
  skill_name="$(basename "$skill_dir")"

  if [ ! -f "$out_file" ]; then
    echo "  MISSING $skill_name/SKILL.md"
    STALE+=("$skill_name")
    continue
  fi

  if ! diff -q "$tmpl_file" "$out_file" > /dev/null 2>&1; then
    echo "  STALE   $skill_name/SKILL.md (differs from .tmpl)"
    STALE+=("$skill_name")
  else
    echo "  OK      $skill_name"
  fi
done < <(
  find "$REPO_DIR" -maxdepth 2 -name "SKILL.md.tmpl" \
    ! -path "*/node_modules/*" ! -path "*/.git/*" | sort
)

echo ""

if [ "${#STALE[@]}" -gt 0 ]; then
  echo "FAIL: ${#STALE[@]} skill(s) have stale SKILL.md:"
  for s in "${STALE[@]}"; do echo "  - $s"; done
  echo ""
  echo "Run 'bash scripts/gen-skill-docs.sh' and commit the result."
  exit 1
fi

echo "All SKILL.md files are up to date."
