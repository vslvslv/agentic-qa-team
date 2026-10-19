#!/usr/bin/env bash
# bin/hooks/qa-pre-bash-safety.sh — PreToolUse(Bash) guard for qa-* skills and agents.
#
# Reads the hook JSON on stdin and blocks (exit 2) a recursive `rm` whose target
# is a broad path: / or a top-level dir, ~ or $HOME (or one level below it),
# . / .. / * / .* , a bare variable that may be empty, or --no-preserve-root.
# No qa-* skill needs a recursive rm, so anything ambiguous is blocked.
#
# Exit codes: 0 allow · 2 block (stderr is shown to the model)
set -u

INPUT=$(cat)

_extract_command() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null && return
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -I -c \
      'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null \
      && return
  fi
  # Last resort: scan the raw JSON text.
  printf '%s' "$INPUT"
}

CMD=$(_extract_command)
[ -z "$CMD" ] && exit 0

_block() {
  echo "Blocked by qa-agentic-team: recursive rm of a broad path ($1). Delete specific files or a named subdirectory instead." >&2
  exit 2
}

_is_broad_target() {
  local t="$1"
  # Strip surrounding quotes.
  t="${t%\"}"; t="${t#\"}"; t="${t%\'}"; t="${t#\'}"
  case "$t" in
    /|/\*|/.\*|'~'|'~/'|'~/*'|.|./|./\*|..|../|..\*|../\*|\*|.\*) return 0 ;;
    '$HOME'|'$HOME/'|'$HOME/*'|'${HOME}'|'${HOME}/'|'${HOME}/*') return 0 ;;
  esac
  # Bare variable (may expand to empty → rm -rf /something or cwd).
  [[ "$t" =~ ^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/?\*?$ ]] && return 0
  # Absolute path with at most two components (/etc, /Users/me).
  [[ "$t" =~ ^/[^/]+/?$ || "$t" =~ ^/[^/]+/[^/]+/?$ ]] && return 0
  # One level below home (~/.claude, $HOME/work).
  local home_re='^(~|\$HOME|\$\{HOME\})/[^/]+/?$'
  [[ "$t" =~ $home_re ]] && return 0
  # Anything that climbs out of the working directory.
  [[ "$t" == ../* ]] && return 0
  return 1
}

# Split into simple commands on ; && || | and newlines, then inspect each `rm`.
SEGMENTS=$(printf '%s\n' "$CMD" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')
while IFS= read -r seg; do
  # Disable globbing so targets like * stay literal while splitting words.
  set -f
  # shellcheck disable=SC2206 # word-splitting is the point here
  words=($seg)
  set +f
  i=0
  # Skip sudo / env assignments / command / exec / xargs prefixes.
  while [ $i -lt ${#words[@]} ]; do
    w="${words[$i]}"
    case "$w" in
      sudo|command|exec|xargs|nohup|time) i=$((i + 1)) ;;
      *=*) if [[ "$w" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then i=$((i + 1)); else break; fi ;;
      *) break ;;
    esac
  done
  [ $i -lt ${#words[@]} ] || continue
  prog="${words[$i]}"
  [ "$prog" = "rm" ] || [[ "$prog" == */rm ]] || continue

  recursive=0
  targets=()
  end_of_opts=0
  for w in "${words[@]:$((i + 1))}"; do
    if [ $end_of_opts -eq 0 ]; then
      case "$w" in
        --) end_of_opts=1; continue ;;
        --no-preserve-root) _block "--no-preserve-root" ;;
        --recursive) recursive=1; continue ;;
        --*) continue ;;
        -*) [[ "$w" =~ [rR] ]] && recursive=1; continue ;;
      esac
    fi
    targets+=("$w")
  done
  [ $recursive -eq 1 ] || continue
  for t in ${targets[@]+"${targets[@]}"}; do
    _is_broad_target "$t" && _block "$t"
  done
done <<< "$SEGMENTS"

exit 0
