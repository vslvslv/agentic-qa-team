#!/usr/bin/env bash
# scripts/check-guide-size.sh — CI gate: no reference guide may exceed the line cap.
# Guides are read by skills at run time; a guide the Read tool cannot load in one
# pass is not a guide. The refine skills must replace and condense, not append.
# Usage: bash scripts/check-guide-size.sh [max_lines]   (default 3000)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX="${1:-${GUIDE_MAX_LINES:-3000}}"
OVER=0

while IFS= read -r f; do
  lines=$(wc -l < "$f" | tr -d ' ')
  if [ "$lines" -gt "$MAX" ]; then
    echo "  OVER  ${f#"$REPO_DIR"/} ($lines lines > $MAX)"
    OVER=$((OVER + 1))
  fi
done < <(
  find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f -name '*.md' \
    \( -path '*/references/*' -o -path '*/guides/*' -o -path '*/tools/*' \) -print | sort
)

if [ "$OVER" -gt 0 ]; then
  echo ""
  echo "FAIL: $OVER guide(s) exceed $MAX lines. Condense them; do not append."
  exit 1
fi
echo "All guides are within $MAX lines."
