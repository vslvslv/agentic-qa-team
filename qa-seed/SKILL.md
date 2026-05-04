---
name: qa-seed
preamble-tier: 3
version: 1.0.0
description: |
  Schema-aware test data seeding skill. Ingests SQL DDL, Prisma schema, TypeORM
  entities, or Django ORM models, performs a topological sort by FK dependency, and
  generates relationship-aware synthetic data that respects constraints, unique keys,
  and realistic value distributions. Optionally seeds directly to a test DB via psql
  or prisma db seed. Chaos mode injects nulls, boundary values, and duplicates.
  Use when asked to "seed test data", "generate fixtures", "populate test database",
  "seed DB", or "create test data". (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
disable-model-invocation: true
model: sonnet
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

echo "--- SCHEMA DETECTION ---"
_SCHEMA_TYPE="none"
_SCHEMA_FILE=""

# Prisma (highest priority)
if ls prisma/schema.prisma 2>/dev/null; then
  _SCHEMA_TYPE="prisma"
  _SCHEMA_FILE="prisma/schema.prisma"
fi

# SQL migrations
if [ "$_SCHEMA_TYPE" = "none" ]; then
  _SQL_MIGRATION=$(find . -name "*.sql" ! -path "*/node_modules/*" \
    \( -path "*/migrations/*" -o -path "*/db/migrate/*" \) 2>/dev/null | sort | tail -1)
  [ -n "$_SQL_MIGRATION" ] && _SCHEMA_TYPE="sql-migrations" && _SCHEMA_FILE="$_SQL_MIGRATION"
fi

# TypeORM entities
if [ "$_SCHEMA_TYPE" = "none" ]; then
  _TYPEORM_COUNT=$(find . \( -name "*.entity.ts" -o -name "*.entity.js" \) \
    ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [ "$_TYPEORM_COUNT" -gt 0 ] && _SCHEMA_TYPE="typeorm"
fi

# Django ORM
if [ "$_SCHEMA_TYPE" = "none" ]; then
  find . -name "models.py" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' \
    && _SCHEMA_TYPE="django-orm"
fi

# Drizzle ORM
if [ "$_SCHEMA_TYPE" = "none" ]; then
  find . -name "schema.ts" ! -path "*/node_modules/*" 2>/dev/null | \
    xargs grep -l "drizzle-orm\|pgTable\|mysqlTable\|sqliteTable" 2>/dev/null | grep -q '.' \
    && _SCHEMA_TYPE="drizzle"
fi

echo "SCHEMA_TYPE: $_SCHEMA_TYPE"
echo "SCHEMA_FILE: ${_SCHEMA_FILE:-auto-detect}"

# DB connection
_DB_URL="${TEST_DATABASE_URL:-${DATABASE_URL:-}}"
echo "DB_URL: ${_DB_URL:+present (redacted)}"
echo "DB_TYPE: $(echo "${_DB_URL:-}" | grep -oE '^[a-z]+' || echo "unknown")"

# Seed configuration
_SEED_ROWS="${QA_SEED_ROWS:-50}"
_SEED_MODE="${QA_SEED_MODE:-clean}"
echo "SEED_ROWS: $_SEED_ROWS"
echo "SEED_MODE: $_SEED_MODE  (clean | chaos)"
```

If `_SCHEMA_TYPE` is `none`: use `AskUserQuestion`: "No schema file found automatically. Which type do you have?" Options: "Prisma schema" | "SQL DDL file" | "TypeORM entities" | "Django models.py". Then ask for the file path and set `_SCHEMA_FILE` accordingly.

## Phase 1 — Schema Analysis

Read and parse the schema based on `_SCHEMA_TYPE`:

**Prisma** (`_SCHEMA_TYPE=prisma`):
```bash
cat "$_SCHEMA_FILE" 2>/dev/null
```
Extract: model names, field names, scalar types (`String`, `Int`, `Boolean`, `DateTime`, `Float`), optional markers (`?`), `@relation` directives, `@unique`, `@default`, `@id`. Build model map.

**SQL migrations** (`_SCHEMA_TYPE=sql-migrations`):
```bash
cat "$_SCHEMA_FILE" 2>/dev/null | grep -A 20 "CREATE TABLE" | head -200
```
Extract: table names, column names + SQL types (`VARCHAR`, `INT`, `BOOLEAN`, `TIMESTAMP`, `UUID`), `NULL`/`NOT NULL`, `DEFAULT`, `REFERENCES` (FK), `UNIQUE`, `PRIMARY KEY`.

**TypeORM** (`_SCHEMA_TYPE=typeorm`):
```bash
find . \( -name "*.entity.ts" -o -name "*.entity.js" \) ! -path "*/node_modules/*" 2>/dev/null | \
  head -10 | while read -r f; do echo "=== $f ==="; cat "$f"; done
```
Extract: `@Entity()` class names, `@Column()` types, `@PrimaryGeneratedColumn()`, `@ManyToOne`, `@OneToMany`, `@JoinColumn`, optional (no `!` annotation).

**Django ORM** (`_SCHEMA_TYPE=django-orm`):
```bash
find . -name "models.py" ! -path "*/node_modules/*" 2>/dev/null | \
  head -5 | while read -r f; do echo "=== $f ==="; cat "$f"; done
```
Extract: class names inheriting `models.Model`, field types (`CharField`, `IntegerField`, `ForeignKey`, etc.), `null=True`, `unique=True`, `default=`.

**Drizzle** (`_SCHEMA_TYPE=drizzle`):
```bash
find . -name "schema.ts" ! -path "*/node_modules/*" 2>/dev/null | head -3 | \
  while read -r f; do echo "=== $f ==="; cat "$f"; done
```
Extract: table definitions (`pgTable`, `mysqlTable`), column types, FK references.

After parsing, output internal model map summary:
```
MODEL_MAP:
  users: id(uuid,pk), email(string,unique), name(string), created_at(datetime), active(boolean,default=true)
  posts: id(int,pk), title(string), user_id(uuid,fk→users.id), published(boolean)
  ...
```

## Phase 2 — Dependency Graph + Seed Order

Compute topological seed order:
1. Build directed graph: FK from child → parent
2. Find tables with no outgoing FK edges (root tables) → seed first
3. BFS/topological sort for remaining tables
4. Circular FK handling: if circular dependency detected, seed the FK-nullable side first with `NULL`, then update after both tables are seeded

```
SEED_ORDER: users → categories → products → orders → order_items
CIRCULAR_FKS: none detected
```

If circular FKs exist: explain the deferral strategy used.

## Phase 3 — Data Generation

For each table in seed order, Claude generates `_SEED_ROWS` rows of synthetic data following these rules:

**Type mapping** (generate realistic values):
- `String` / `VARCHAR` for `name`, `title`, `label` → realistic names ("Alice Johnson", "Product A")
- `String` / `VARCHAR` for `email` → `user{N}@example.com` (unique per row)
- `String` / `VARCHAR` for `slug`, `username` → lowercase alphanumeric (unique)
- `String` / `VARCHAR` for `phone` → `555-0{N:03d}`
- `String` / `VARCHAR` for `url` → `https://example.com/item/{N}`
- `String` / `VARCHAR` other → `sample-{fieldname}-{N}`
- `Int` / `INTEGER` for `amount`, `price`, `cost` → Pareto: 80% values < 100, 20% up to 10000
- `Int` / `INTEGER` for `count`, `quantity` → uniform 1–50
- `Int` / `INTEGER` for `age` → normal distribution 18–80
- `Boolean` / `BOOL` for `is_active`, `enabled`, `published` → 80% `true`
- `Boolean` other → 50% `true`
- `DateTime` / `TIMESTAMP` → sequential dates in last 90 days
- `UUID` / `CUID` → generated unique IDs
- `Float` / `DECIMAL` → 2 decimal places, range appropriate to field name
- FK fields → valid ID from already-seeded parent table (cycle through available IDs)
- `NULL`able fields with no special role → 10% chance `NULL`

**Chaos mode** additions (when `_SEED_MODE=chaos`):
- 5% of nullable fields → force `NULL` even if normally filled
- 2% of string fields → inject max-length boundary value (255 `x` characters for VARCHAR(255))
- 1% of string fields → inject unicode edge case: `'​​​'` (zero-width spaces)
- 1% of rows → duplicate an existing row (with new PK)
- Include at least 1 row with minimum values and 1 row with maximum values per table

Generate SQL INSERT statements (or Prisma seed script if `_SCHEMA_TYPE=prisma`).

## Phase 4 — DB Write

**If `_DB_URL` is set** — write to database:

For SQL schemas:
```bash
# Write seed SQL wrapped in transaction
{
  echo "BEGIN;"
  cat "$_TMP/qa-seed-data.sql"
  echo "COMMIT;"
} > "$_TMP/qa-seed-transaction.sql"

echo "=== SEED EXECUTION ==="
DB_TYPE=$(echo "${_DB_URL:-}" | grep -oE '^[a-z]+')
case "$DB_TYPE" in
  postgres*|postgresql*)
    psql "$_DB_URL" < "$_TMP/qa-seed-transaction.sql" 2>&1 | tail -10
    ;;
  mysql*)
    mysql "$(echo "$_DB_URL" | sed 's|mysql://||')" < "$_TMP/qa-seed-transaction.sql" 2>&1 | tail -10
    ;;
  sqlite*)
    sqlite3 "$(echo "$_DB_URL" | sed 's|file:||; s|?.*||')" < "$_TMP/qa-seed-transaction.sql" 2>&1 | tail -10
    ;;
  *)
    echo "DB_TYPE_UNSUPPORTED: $DB_TYPE — writing SQL to $_TMP/qa-seed-data.sql for manual use"
    ;;
esac
```

For Prisma schemas:
```bash
# Write prisma/seed.ts and run
cat > "$_TMP/prisma-seed.ts" << 'SEEDEOF'
# (Claude writes generated Prisma Client seed script here)
SEEDEOF
npx prisma db seed 2>&1 | tail -10
```

**If `_DB_URL` is not set** — write SQL to `$_TMP/qa-seed-data.sql` and report the path. Include rollback instructions.

## Phase 5 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
sql_file = os.path.join(tmp, 'qa-seed-data.sql')
rows_generated = 0
if os.path.exists(sql_file):
    content = open(sql_file, encoding='utf-8', errors='replace').read()
    rows_generated = content.count('INSERT INTO')

now_ms = int(time.time() * 1000)
ctrf = {
    'results': {
        'tool': {'name': 'qa-seed'},
        'summary': {'tests': 1, 'passed': 1, 'failed': 0,
                    'pending': 0, 'skipped': 0, 'other': 0,
                    'start': now_ms - 2000, 'stop': now_ms},
        'tests': [{'name': 'seed-data-generation', 'status': 'passed', 'duration': 0,
                   'suite': 'seed', 'message': f'{rows_generated} rows generated'}],
        'environment': {'reportName': 'qa-seed', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}
out = os.path.join(tmp, 'qa-seed-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'ROWS_GENERATED: {rows_generated}')
PYEOF
```

## Phase 6 — Report

Write `$_TMP/qa-seed-report.md`:

```markdown
# QA Seed Report — <date>

## Summary
- **Schema**: <type> — <file>
- **Mode**: clean / chaos
- **Tables seeded**: N
- **Total rows**: N
- **DB written**: yes (psql) / no (SQL file only)

## Seed Order
<topological order with FK chain explanation>

## Per-Table Summary
| Table | Rows | FK Dependencies | Notes |
|-------|------|-----------------|-------|
| users | 50 | — | baseline table |
| posts | 50 | users.id | FKs distributed across 50 users |

## Chaos Mode Injections
<list of edge cases injected, if _SEED_MODE=chaos>

## Rollback
To undo: `psql $DB_URL -c "BEGIN; DELETE FROM <tables in reverse order>; COMMIT;"`

## Output Files
- `$_TMP/qa-seed-data.sql` — raw INSERT statements
- `$_TMP/qa-seed-transaction.sql` — wrapped in transaction
```

## Important Rules

- **Never seed production** — always check `_DB_URL` contains `test`, `dev`, `local`, or `staging` before writing; warn and ask for confirmation if not
- **Transaction-wrapped** — always wrap DB writes in `BEGIN`/`COMMIT` for rollback capability
- **FK integrity** — never generate FK values that don't reference valid parent rows
- **PII-safe** — all generated values are clearly fictional (example.com emails, 555- phone numbers, "Sample" names)

## Agent Memory

After each run, update `.claude/agent-memory/qa-seed/MEMORY.md` (create if absent). Record:
- Schema type and file path confirmed
- Table dependency graph (stable across runs)
- Any FK cycles and how they were resolved
- DB type and connection string format

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-seed","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
