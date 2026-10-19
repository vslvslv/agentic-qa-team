#!/usr/bin/env bash
# bin/hooks/qa-post-write-typecheck.sh — PostToolUse(Write|Edit) typecheck for TS specs.
#
# Reads the hook JSON on stdin. When the written file is a *.spec|test.ts(x), runs
# the project's own tsc (--noEmit) from the nearest directory holding a tsconfig.json
# and prints the first errors. Never blocks: always exits 0. Runs async.
# With --plugin-agents-only (hooks/hooks.json) it acts only inside the qa plugin's
# subagents (agent_type "qa:*"); skill frontmatter hooks call it without the flag.
set -u

INPUT=$(cat)

if [ "${1:-}" = "--plugin-agents-only" ]; then
  if command -v jq >/dev/null 2>&1; then
    AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null)
  else
    AGENT_TYPE=$(printf '%s' "$INPUT" | python3 -I -c \
      'import json,sys; print(json.load(sys.stdin).get("agent_type") or "")' 2>/dev/null)
  fi
  case "$AGENT_TYPE" in
    qa:*) ;;
    *) exit 0 ;;
  esac
fi

if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$INPUT" | python3 -I -c \
    'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
else
  exit 0
fi

printf '%s' "$FILE_PATH" | grep -qE '\.(spec|test)\.(ts|tsx|mts|cts)$' || exit 0
[ -f "$FILE_PATH" ] || exit 0

STOP="${CLAUDE_PROJECT_DIR:-/}"
dir="$(cd "$(dirname "$FILE_PATH")" && pwd)"
while [ "$dir" != "/" ]; do
  [ -f "$dir/tsconfig.json" ] && break
  [ "$dir" = "$STOP" ] && exit 0
  dir="$(dirname "$dir")"
done
[ -f "$dir/tsconfig.json" ] || exit 0

# Prefer the tsc installed in this project (walk up for node_modules/.bin/tsc).
TSC=""
d="$dir"
while [ "$d" != "/" ]; do
  if [ -x "$d/node_modules/.bin/tsc" ]; then TSC="$d/node_modules/.bin/tsc"; break; fi
  [ "$d" = "$STOP" ] && break
  d="$(dirname "$d")"
done
[ -z "$TSC" ] && exit 0

OUT=$(cd "$dir" && "$TSC" --noEmit -p . 2>&1 | head -15)
[ -n "$OUT" ] && printf 'tsc --noEmit (%s):\n%s\n' "$dir" "$OUT"
exit 0
