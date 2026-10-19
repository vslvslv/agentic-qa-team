#!/usr/bin/env bash
# bin/qa-version-check-inline.sh — run by the `!` line at the top of every skill.
# Prints VERSION_STATUS and SKIP_UPDATE_ASK for the skill to act on. Never fails.
# Set QA_TEAM_NO_UPDATE_CHECK=1 to skip the network check entirely.
_TMP="${TEMP:-${TMP:-/tmp}}"

# Repo root: the stable link bin/setup creates, else this script's own repo.
_QA_ROOT="$HOME/.claude/qa-agentic-team"
if [ ! -f "$_QA_ROOT/VERSION" ]; then
  _QA_ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)"
fi

if [ "${QA_TEAM_NO_UPDATE_CHECK:-0}" = "1" ]; then
  _QA_VER="UP_TO_DATE: check disabled (QA_TEAM_NO_UPDATE_CHECK=1)"
elif [ -f "$_QA_ROOT/bin/qa-team-update-check" ]; then
  _QA_VER=$(bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
    || echo "UPDATE_CHECK_FAILED: script error")
else
  _QA_VER="UPDATE_CHECK_FAILED: not found"
fi
echo "VERSION_STATUS: $_QA_VER"

# Ask at most once per 10 minutes (qa-team may start several skills at once).
_QA_SKIP_ASK=0
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(tr -d ' ' < "$_QA_ASK_COOLDOWN" 2>/dev/null || echo 0) ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
# Start the cooldown only when this run will prompt.
case "$_QA_VER" in
  UPGRADE_AVAILABLE*) [ "$_QA_SKIP_ASK" = "0" ] && date +%s > "$_QA_ASK_COOLDOWN" 2>/dev/null ;;
esac
echo "SKIP_UPDATE_ASK: $_QA_SKIP_ASK"
exit 0
