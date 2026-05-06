#!/usr/bin/env bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_SKILL_DIR="${CLAUDE_SKILL_DIR:-$(dirname "$0")/..}"
# Resolve symlinks so short-names installs (~/.claude/skills/qa-team -> repo/qa-team)
# yield the repo root from `dirname`, not ~/.claude/skills.
_RESOLVED_SKILL_DIR=$(realpath "$_SKILL_DIR" 2>/dev/null \
  || readlink -f "$_SKILL_DIR" 2>/dev/null \
  || echo "$_SKILL_DIR")
_QA_ROOT=$(dirname "$_RESOLVED_SKILL_DIR" 2>/dev/null)
# Fallback for namespaced install (single symlink at ~/.claude/skills/qa-agentic-team).
[ ! -f "$_QA_ROOT/VERSION" ] && _QA_ROOT=$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null) || true
_QA_VER=$( [ -n "$_QA_ROOT" ] && bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
  || echo "UPDATE_CHECK_FAILED: not found" )
echo "VERSION_STATUS: $_QA_VER"
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
_QA_SKIP_ASK=0
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(cat "$_QA_ASK_COOLDOWN" | tr -d ' ') ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
echo "SKIP_UPDATE_ASK: $_QA_SKIP_ASK"
