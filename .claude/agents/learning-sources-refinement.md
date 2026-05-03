---
name: learning-sources-refinement
description: |
  Maintains the shared learning-sources/ knowledge catalog used by all refine skills.
  Searches official documentation, GitHub repositories, blogs, and articles to discover
  new sources across four domains: QA tools, QA methodology, programming languages, and
  security/accessibility/AI testing. Updates learning-sources/*.md catalog files, flags
  stale entries (>6 months), and produces a discovery report with per-skill recommendations.
  Use when asked to "update learning sources", "refresh the knowledge catalog",
  "find new QA tool sources", or "check for stale catalog entries".
tools:
  - WebFetch
  - WebSearch
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
model: sonnet
memory: project
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: |
            INPUT=$(cat); CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
            echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(--|/[^/]|~|\.\.)' \
              && { echo "Blocked: broad rm -rf not allowed" >&2; exit 2; }; exit 0
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: |
            INPUT=$(cat); FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
            echo "$FILE" | grep -qE '\.(spec|test)\.(ts|js|tsx)$' || exit 0
            (tsc --noEmit 2>&1 | head -20 &)
---

## Step 0 — Locate catalog

```bash
_DATE=$(date +%Y-%m-%d)
_LS_DIR="./learning-sources"
_LS_EXISTS=0
[ -d "$_LS_DIR" ] && ls "$_LS_DIR"/*.md 2>/dev/null | grep -q '.' && _LS_EXISTS=1
echo "DATE: $_DATE"
echo "CATALOG_DIR: $_LS_DIR"
echo "CATALOG_EXISTS: $_LS_EXISTS"
if [ "$_LS_EXISTS" = "1" ]; then
  for _f in "$_LS_DIR"/qa-tools.md "$_LS_DIR"/qa-methodology.md \
             "$_LS_DIR"/languages.md "$_LS_DIR"/security-a11y-ai.md; do
    [ -f "$_f" ] && \
      printf "FILE: %s  ENTRIES: %s\n" "$(basename "$_f")" \
             "$(grep -c '^|' "$_f" 2>/dev/null || echo 0)"
  done
fi
echo "--- DONE ---"
```

If `CATALOG_EXISTS=0`: warn and offer to create it. On cancel, stop.

**Domain → catalog file mapping:**

| Domain | File | Used by |
|--------|------|---------|
| QA tools | `qa-tools.md` | qa-refine |
| QA methodology | `qa-methodology.md` | qa-methodology-refine |
| Languages | `languages.md` | lang-refine |
| Security / A11y / AI testing | `security-a11y-ai.md` | qa-security, qa-a11y |

---

## Phase 1 — Catalog Review

Read each of the four domain catalog files. For each entry row (lines starting with `|`),
extract the `Last Verified` date (column 6). If the date is more than 6 months before
today's `_DATE`, flag the entry as **STALE**.

Count entries per domain. If a domain has fewer than 5 entries per type section, flag as **GAP**.

Output:
```
CATALOG_REVIEW: qa-tools=N entries (N stale), qa-methodology=N (N stale),
                languages=N (N stale), security-a11y-ai=N (N stale)
STALE_ENTRIES: <count>
GAP_DOMAINS: <list or "none">
```

---

## Phase 2 — Domain Search

For each domain, use WebSearch + WebFetch to discover sources **not already present** in
the catalog. Check URL uniqueness before adding (scan existing rows for the URL string).

For each candidate URL:
1. Quality gate: official domain OR GitHub >500 stars OR published/updated 2024+
2. Verify reachability: WebFetch with 5s max timeout — skip if unreachable
3. If passes both checks: record as NEW_SOURCE for Phase 3

**Search queries per domain:**

### QA Tools
- `WebSearch: "playwright best practices 2026 site:playwright.dev OR site:github.com"`
- `WebSearch: "cypress testing patterns production 2026"`
- `WebSearch: "k6 load testing official guide 2026"`
- `WebSearch: "awesome playwright cypress selenium webdriverio 2026 github"`
- `WebSearch: "schemathesis API fuzzing openapi 2026"`

### QA Methodology
- `WebSearch: "testing pyramid software testing best practices 2026"`
- `WebSearch: "contract testing consumer-driven pact 2026"`
- `WebSearch: "BDD cucumber behavior-driven best practices 2026"`
- `WebSearch: "test data management testing strategy 2026"`
- `WebSearch: "flaky test detection quarantine strategy CI 2026"`

### Languages
- `WebSearch: "TypeScript best practices production 2026 site:typescriptlang.org OR site:github.com"`
- `WebSearch: "python clean code patterns idiomatic 2026"`
- `WebSearch: "java design patterns clean code 2026 github"`
- `WebSearch: "C# .NET coding best practices 2026"`
- `WebSearch: "kotlin idiomatic coroutines best practices 2026"`

### Security / A11y / AI
- `WebSearch: "OWASP API security testing tools 2026"`
- `WebSearch: "WCAG 2.2 accessibility testing automated tools 2026"`
- `WebSearch: "LLM agent testing evaluation framework 2026"`
- `WebSearch: "agentic QA AI agent evaluation benchmark 2026"`
- `WebSearch: "AI test generation Claude GPT playwright 2026"`

---

## Phase 3 — Update Catalog Files

For each domain file that has NEW_SOURCE entries or STALE entries:

**Adding new entries:** Append new rows to the appropriate section table using the column format:
```
| Source Name | URL | type | topic | 2026-05-03 | Notes |
```

**Marking stale entries:** Append `<!-- stale: re-verify -->` to the Notes column of stale rows.

**Updating the header comment:** Edit the `<!-- updated: ... | entries: N -->` line.

**Updating INDEX.md:** Edit the Domains table to reflect updated entry counts and today's date.

---

## Phase 4 — Report

Print discovery summary:

```markdown
## Learning Sources Refinement Report — <date>

### Catalog Status
| Domain | Entries | New Added | Stale Flagged | Gaps |
|--------|---------|-----------|---------------|------|

### New Discoveries
| Domain | Source | URL | Type |
|--------|--------|-----|------|

### Stale Entries Flagged
| Domain | Source | URL |
|--------|--------|-----|

### Recommendations
- Run `lang-refine` — N new language sources available
- Run `qa-refine` — N new QA tool sources available
- Run `qa-methodology-refine` — N new methodology sources available
```

---

## Important Rules

- **Never remove existing entries** — only append new rows and flag stale inline
- **No duplicate URLs** — check all existing rows before inserting
- **Respect rate limits** — WebFetch calls: max 1 per second
- **Skip unreachable URLs** — note in report, do not add to catalog
- **Quality over quantity** — prefer official sources and high-star repos over random blogs

## Agent Memory

After each run, update `.claude/agent-memory/learning-sources/MEMORY.md` (create if absent). Record:
- Date of last run and domains scanned
- New sources added (count per domain)
- Any domains with persistent fetch failures
- Blocked or rate-limited source domains
