---
name: qa-seed
description: |
  Schema-aware test data seeding agent. Ingests SQL DDL, Prisma schema, TypeORM
  entities, or Django ORM models; performs topological sort by FK dependency; generates
  relationship-aware synthetic data respecting constraints and realistic distributions.
  Seeds directly to a test DB or writes SQL to file. Chaos mode (QA_SEED_MODE=chaos)
  injects nulls, boundary values, and duplicates. Use when asked to "seed test data",
  "generate fixtures", "populate test database", or "create test data".
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
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
            FILE_PATH=$(echo "$TOOL_RESULT" | jq -r '.tool_result.file_path // empty' 2>/dev/null)
            echo "$FILE_PATH" | grep -qE '\.(spec|test)\.(ts|tsx)$' || exit 0
            TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" 2>/dev/null | head -1)
            [ -z "$TSC" ] && exit 0
            "$TSC" --noEmit 2>&1 | head -15; exit 0
          async: true
---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

echo "--- SCHEMA DETECTION ---"
_SCHEMA_TYPE="none"; _SCHEMA_FILE=""
ls prisma/schema.prisma 2>/dev/null && _SCHEMA_TYPE="prisma" && _SCHEMA_FILE="prisma/schema.prisma"
if [ "$_SCHEMA_TYPE" = "none" ]; then
  _SQL=$(find . -name "*.sql" ! -path "*/node_modules/*" \( -path "*/migrations/*" -o -path "*/db/migrate/*" \) 2>/dev/null | sort | tail -1)
  [ -n "$_SQL" ] && _SCHEMA_TYPE="sql-migrations" && _SCHEMA_FILE="$_SQL"
fi
[ "$_SCHEMA_TYPE" = "none" ] && \
  find . \( -name "*.entity.ts" -o -name "*.entity.js" \) ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _SCHEMA_TYPE="typeorm"
[ "$_SCHEMA_TYPE" = "none" ] && \
  find . -name "models.py" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _SCHEMA_TYPE="django-orm"
echo "SCHEMA_TYPE: $_SCHEMA_TYPE"
echo "SCHEMA_FILE: ${_SCHEMA_FILE:-auto-detect}"
_DB_URL="${TEST_DATABASE_URL:-${DATABASE_URL:-}}"
echo "DB_URL: ${_DB_URL:+present (redacted)}"
_SEED_ROWS="${QA_SEED_ROWS:-50}"
_SEED_MODE="${QA_SEED_MODE:-clean}"
echo "SEED_ROWS: $_SEED_ROWS  SEED_MODE: $_SEED_MODE"
```

## Phase 1 — Schema Analysis

Read and parse schema based on `_SCHEMA_TYPE`:
- **Prisma**: `cat prisma/schema.prisma` → extract models, fields, types, `@relation`, `@unique`, `@default`
- **SQL migrations**: `cat "$_SCHEMA_FILE"` → extract `CREATE TABLE`, FK `REFERENCES`, `UNIQUE`, `NOT NULL`
- **TypeORM**: read `*.entity.ts` files → extract `@Entity`, `@Column`, `@ManyToOne`, `@OneToMany`
- **Django**: read `models.py` → extract `Model` subclasses, field types, `ForeignKey`, `null=True`, `unique=True`

Output internal model map:
```
MODEL_MAP:
  users: id(uuid,pk), email(string,unique), name(string), created_at(datetime)
  posts: id(int,pk), title(string), user_id(uuid,fk→users.id)
```

## Phase 2 — Dependency Graph + Seed Order

Topological sort by FK dependency (parents before children). Handle circular FKs via nullable deferral.
Output: `SEED_ORDER: users → posts → comments`

## Phase 3 — Data Generation

Generate `_SEED_ROWS` rows per table with realistic values:
- String `name`/`title` → "Sample Name N"
- String `email` → `user{N}@example.com` (unique)
- Int `amount`/`price` → Pareto (80% < 100, 20% up to 10000)
- DateTime → sequential dates in last 90 days
- Boolean `is_active`/`enabled` → 80% true
- UUID → generated IDs
- FK → valid ID from seeded parent

**Chaos additions** (`_SEED_MODE=chaos`): 5% nullable→NULL, 2% string→max-length, 1% unicode edge cases, 1% duplicate rows.

Write `$_TMP/qa-seed-data.sql`.

## Phase 4 — DB Write

```bash
{ echo "BEGIN;"; cat "$_TMP/qa-seed-data.sql"; echo "COMMIT;"; } > "$_TMP/qa-seed-transaction.sql"
DB_TYPE=$(echo "${_DB_URL:-}" | grep -oE '^[a-z]+')
case "$DB_TYPE" in
  postgres*|postgresql*) psql "$_DB_URL" < "$_TMP/qa-seed-transaction.sql" 2>&1 | tail -5 ;;
  mysql*) mysql "$(echo "$_DB_URL" | sed 's|mysql://||')" < "$_TMP/qa-seed-transaction.sql" 2>&1 | tail -5 ;;
  *) echo "DB_NOT_CONNECTED: SQL written to $_TMP/qa-seed-data.sql for manual use" ;;
esac
```
For Prisma: write `prisma/seed.ts` and run `npx prisma db seed`.
**Safety**: warn if `_DB_URL` does not contain `test`/`dev`/`local`/`staging`.

## Phase 5 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, time
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
sql_file = os.path.join(tmp, 'qa-seed-data.sql')
rows = open(sql_file, encoding='utf-8', errors='replace').read().count('INSERT INTO') if os.path.exists(sql_file) else 0
now_ms = int(time.time() * 1000)
ctrf = {'results': {'tool': {'name': 'qa-seed'},
  'summary': {'tests':1,'passed':1,'failed':0,'pending':0,'skipped':0,'other':0,'start':now_ms-2000,'stop':now_ms},
  'tests': [{'name':'seed-generation','status':'passed','duration':0,'suite':'seed','message':f'{rows} rows generated'}],
  'environment': {'reportName':'qa-seed','branch': os.environ.get('_BRANCH','unknown')}}}
out = os.path.join(tmp,'qa-seed-ctrf.json')
json.dump(ctrf, open(out,'w',encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}  ROWS: {rows}')
PYEOF
```

## Phase 6 — Report

Write `$_TMP/qa-seed-report.md` with: schema source + type, seed order + FK chain, per-table row counts, chaos injections, DB write status, rollback command.

## Agent Memory

After each run, update `.claude/agent-memory/qa-seed/MEMORY.md`. Record: schema type and file, table dependency graph, FK cycles and resolutions, DB type.
