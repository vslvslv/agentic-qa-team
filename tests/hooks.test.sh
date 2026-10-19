#!/usr/bin/env bash
# tests/hooks.test.sh — table tests for bin/hooks/*. Run: bash tests/hooks.test.sh
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$REPO_DIR/bin/hooks/qa-pre-bash-safety.sh"
TYPECHECK="$REPO_DIR/bin/hooks/qa-post-write-typecheck.sh"
FAIL=0
PASS=0

_json_cmd() { python3 -I -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"; }

_expect() {  # _expect <want_exit> <command>
  local want="$1" cmd="$2" got
  _json_cmd "$cmd" | bash "$GUARD" 2>/dev/null
  got=$?
  if [ "$got" = "$want" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL guard: want $want got $got: $cmd"
  fi
}

# --- must block -------------------------------------------------------------
for c in \
  'rm -rf /' 'rm -rf /*' 'rm -fr ~' 'rm -rf ~/' 'rm -rf ~/.claude' 'rm -rf $HOME' \
  'rm -rf "$HOME"' 'rm -rf ${HOME}/' 'rm -rf .' 'rm -rf ./' 'rm -rf ..' 'rm -rf ../other' \
  'rm -rf *' 'rm -rf .*' 'rm -r -f /' 'rm --recursive --force /etc' 'rm -R /usr/local' \
  'rm -rf "$DIR"' 'rm -rf $BUILD_DIR/' 'cd x && rm -rf /' 'echo hi; rm -rf ~' \
  'sudo rm -rf /var' 'FOO=1 rm -rf .' '/bin/rm -rf /' 'rm -rf -- /' 'rm --no-preserve-root -rf /x/y/z' \
  'true | rm -rf ..' 'rm -rf /Users/me'
do _expect 2 "$c"; done

# --- must allow -------------------------------------------------------------
for c in \
  'ls -la' 'rm file.txt' 'rm -f /tmp/qa-web-report.md' 'rm -rf node_modules' \
  'rm -rf ./playwright-report' 'rm -rf "$_TMP/qa-web-results"' 'rm -rf /tmp/qa-run/output' \
  'rm -rf test-results/screens' 'rm -rf e2e/.auth/state' 'git rm -r --cached dist' \
  'echo "rm -rf /" > notes.txt' 'npm run clean'
do _expect 0 "$c"; done

# 'echo "rm -rf /"' is a known false-positive risk; it is allowed because the
# segment's program is echo, not rm. Keep it in the allow list as a regression check.

# --- typecheck hook: never blocks, ignores non-spec files ---------------------
printf '{"tool_input":{"file_path":"/nonexistent/a.ts"}}' | bash "$TYPECHECK" >/dev/null 2>&1
[ $? = 0 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "  FAIL typecheck: non-spec"; }
printf 'not json' | bash "$TYPECHECK" >/dev/null 2>&1
[ $? = 0 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "  FAIL typecheck: bad json"; }

echo "hooks: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
