# Troubleshooting

## Skill not found after setup

**Symptom**: Claude Code doesn't recognise `/qa-web` or other commands.

**Fixes**:

1. Verify symlinks were created:
   ```bash
   ls ~/.claude/skills/ | grep qa
   ```
   If empty: `bash bin/setup` again.

2. Verify the symlink target is correct:
   ```bash
   readlink ~/.claude/skills/qa-web
   # Should point to: /path/to/qa-agentic-team/qa-web
   ```

3. Restart Claude Code after setup — skills are loaded at session start.

---

## Stop hook not firing / malformed settings.json

**Symptom**: Re-running `bash bin/setup` keeps adding duplicate hook entries, or Claude reports `Expected array, but received unidentified`.

**Diagnosis**:
```bash
jq '.hooks.Stop' ~/.claude/settings.json
```

The correct shape is:
```json
[
  {
    "matcher": "main-agent",
    "hooks": [{ "type": "command", "command": "/path/to/qa-team-suggest-rerun" }]
  }
]
```

If you see `{ "matcher": "...", "command": "..." }` without the nested `hooks` array, the old (broken) schema was written. Fix it:

```bash
bash bin/setup --hook-only
```

This strips stale flat-shape entries and re-installs with the correct nested schema.

---

## Only one agent ran when using `/qa-team`

**Symptom**: `/qa-team` runs but only spawns qa-web, skipping qa-api, qa-mobile, etc.

**Causes**:
- Complexity score < 3 → fast-path (only qa-web). Override: `QA_FAST_MODE=0` or `QA_DEEP_MODE=1`.
- Required services not running: qa-api skips if `API_URL` is unreachable; qa-mobile skips if no emulator detected.
- The orchestrator asked you to confirm domains and you deselected some.

**Check the preamble output** — it lists which domains were detected and why others were skipped.

---

## CTRF file not found

**Symptom**: CI step that reads `/tmp/qa-*-ctrf.json` finds no files.

**Causes**:
- The skill errored out before reaching the report phase — check the Claude Code output for the error.
- `$TEMP` is set to a non-`/tmp` path on the runner. CTRF files land in `${TEMP:-/tmp}`.

**Fix**: Use a wildcard path: `/tmp/qa-*-ctrf.json` — or set `TEMP=/tmp` explicitly in CI.

---

## Version check fails / `UPDATE_CHECK_FAILED`

**Symptom**: Skills print `VERSION_STATUS: UPDATE_CHECK_FAILED` at the start.

**Cause**: The version check script can't find `CLAUDE_SKILL_DIR`. This happens if the skill was invoked from a path where symlinks don't resolve correctly, or if `git` is not in PATH.

**Fix**: Ensure `git` is installed and the symlink target exists:
```bash
ls -la ~/.claude/skills/qa-web
# → /path/to/qa-agentic-team/qa-web
git -C /path/to/qa-agentic-team status
```

The skill continues regardless — version check failure is non-blocking.

---

## `npm run gen:skill-docs` generates no files

**Symptom**: Running `npm run gen:skill-docs` outputs `Done. Generated: 0`.

**Cause**: All SKILL.md files are already up to date (checksums match). This is correct behaviour.

If you edited a `.tmpl` and still get 0: verify you saved the file and check the script isn't caching an old checksum:
```bash
bash scripts/gen-skill-docs.sh --force   # if supported
# or:
touch qa-web/SKILL.md.tmpl && npm run gen:skill-docs
```

---

## qa-api skips contract testing

**Symptom**: `/qa-api` runs but skips Dredd / Pact / Schemathesis.

**Cause**: These phases require specific files or tools to be present.

- **Dredd**: requires `openapi.yaml` or `swagger.json` at project root, and `npx @dredd/dredd` available
- **Pact**: requires `*.pact.json` files (checked via `find . -name "*.pact.json"`)
- **Schemathesis**: requires `pip install schemathesis` and `command -v st` to succeed

Check the preamble output — it prints `DREDD_AVAILABLE: 0` etc. for each skipped integration.

---

## Visual baseline mismatch on first CI run

**Symptom**: `/qa-visual` fails on first CI run with "no baseline found" errors.

**Fix**: Run once on main branch to capture baselines, then commit them:
```bash
/qa-visual
git add visual-baselines/
git commit -m "chore: capture visual baselines"
```

After that, CI compares against these committed baselines.

---

## Mobile skill can't find device

**Symptom**: `/qa-mobile` exits with "no simulator/emulator detected".

**Fix**: Ensure a device is running before invoking the skill:
```bash
# Android
adb devices                          # should show a device
# iOS (macOS)
xcrun simctl list devices booted     # should show a booted simulator
```

Or set `DEVICE_ID` and `PLATFORM` explicitly:
```bash
export DEVICE_ID=emulator-5554
export PLATFORM=android
```

---

## JIRA auth fails in `/qa-manager`

**Symptom**: "JIRA_AVAILABLE: 0" despite setting `JIRA_URL` and `JIRA_TOKEN`.

**Checks**:
1. Token format: Jira Cloud uses Personal API tokens (not passwords). Generate at `id.atlassian.com` → Security → API tokens.
2. URL format: should be `https://yourorg.atlassian.net` (no trailing slash, no `/rest/api`).
3. Test manually:
   ```bash
   curl -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Accept: application/json" \
        "$JIRA_URL/rest/api/3/myself"
   ```

If JIRA is unavailable, the skill falls back to manual input mode — you can still run Mode A by entering Epic/story data when prompted.

---

## Getting more help

- Open an issue: [github.com/vslvslv/agentic-qa-team/issues](https://github.com/vslvslv/agentic-qa-team/issues)
- Check the CHANGELOG for recent changes: [CHANGELOG.md](../CHANGELOG.md)
