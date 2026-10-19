# Troubleshooting

## `/qa:*` commands not found

**Fixes**:

1. Check the plugin is installed and enabled: `/plugin` → Installed. Install with `/plugin install qa@agentic-qa-team`.
2. After installing or updating, run `/reload-plugins` or start a new session.
3. `/qa:team` says a subagent type is unknown: the plugin is disabled or outdated — update it (`/plugin marketplace update agentic-qa-team`).
4. Old symlink install still present (skills named `/qa-web` etc.): run `bash bin/uninstall` from the old clone.

---

## Stop hook

The re-run nudge ships in the plugin's `hooks/hooks.json`; nothing is written to `~/.claude/settings.json`. Claude Code cannot disable a single plugin hook; to silence it, disable the plugin or set `"disableAllHooks": true`. If an old install left a Stop entry pointing at `qa-team-suggest-rerun` in `~/.claude/settings.json`, `bash bin/uninstall` removes it.

---

## Only one agent ran when using `/qa:team`

**Symptom**: `/qa:team` runs but only spawns qa-web, skipping qa-api, qa-mobile, etc.

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

## `npm run gen:skill-docs` generates no files

**Symptom**: Running `npm run gen:skill-docs` outputs `Done. Generated: 0`.

**Cause**: All SKILL.md files are already up to date (checksums match). This is correct behaviour.

If you edited a `.tmpl` and still get 0: verify you saved the file and check the script isn't caching an old checksum:
```bash
bash scripts/gen-skill-docs.sh --check   # lists anything stale
# or:
touch skills/web/SKILL.md.tmpl && npm run gen:skill-docs
```

---

## qa-api skips contract testing

**Symptom**: `/qa:api` runs but skips Dredd / Pact / Schemathesis.

**Cause**: These phases require specific files or tools to be present.

- **Dredd**: requires `openapi.yaml` or `swagger.json` at project root, and `npx @dredd/dredd` available
- **Pact**: requires `*.pact.json` files (checked via `find . -name "*.pact.json"`)
- **Schemathesis**: requires `pip install schemathesis` and `command -v st` to succeed

Check the preamble output — it prints `DREDD_AVAILABLE: 0` etc. for each skipped integration.

---

## Visual baseline mismatch on first CI run

**Symptom**: `/qa:visual` fails on first CI run with "no baseline found" errors.

**Fix**: Run once on main branch to capture baselines, then commit them:
```bash
/qa:visual
git add visual-baselines/
git commit -m "chore: capture visual baselines"
```

After that, CI compares against these committed baselines.

---

## Mobile skill can't find device

**Symptom**: `/qa:mobile` exits with "no simulator/emulator detected".

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

## JIRA auth fails in `/qa:manager`

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
