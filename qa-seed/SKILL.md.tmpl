---
name: qa-seed
version: 1.0.0
description: |
  Schema-aware test data seeding skill. Ingests SQL DDL, Prisma schema, TypeORM
  entities, or Django ORM models, performs a topological sort by FK dependency, and
  generates relationship-aware synthetic data that respects constraints, unique keys,
  and realistic value distributions. Optionally seeds a TEST database (TEST_DATABASE_URL
  only, never DATABASE_URL) via psql, mysql, sqlite3 or a generated Prisma Client script,
  behind an approval gate with a production check. Chaos mode injects nulls, boundary
  values, and duplicates.
when_to_use: |
  Use when asked to "seed test data", "generate fixtures", "populate test database",
  "seed DB", or "create test data".

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
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: first show what would change with `git -C "$HOME/.claude/qa-agentic-team" fetch -q && git -C "$HOME/.claude/qa-agentic-team" log --oneline HEAD..@{u} | head -20`, then run `git -C "$HOME/.claude/qa-agentic-team" pull --ff-only && bash "$HOME/.claude/qa-agentic-team/bin/setup" --no-hook`. Continue regardless.

---

## Approval gates

Every database write in this skill is a gate. Run interactively (`/qa-seed`), ask with
`AskUserQuestion`. Run as a subagent (spawned by `/qa-team`), you cannot ask: a gated step
runs only if the brief's `APPROVALS:` line contains the named key. The brief never carries
the URL itself (it says `TEST_DATABASE_URL: from environment`): the database is only ever
`$TEST_DATABASE_URL` read from the environment — never `DATABASE_URL`. Never echo the full
URL anywhere (output, report, memory): show scheme, host, port, user and db name, password
redacted. Any skipped step goes under "Needs a decision" in the report. Default = not
granted: without approval, generate the seed files and stop there.

Installing anything (`npm install`, `pip install`, `brew install`, an `npx --yes` that
downloads, a missing `psql`/`mysql`/`sqlite3`/`node`) is also a gate: **Gate (ALLOW_INSTALL):**
install `<tool>` into `<project/environment>`. Interactive: ask with AskUserQuestion and proceed
only on yes. As a subagent: proceed only if the brief's `APPROVALS:` line contains
`ALLOW_INSTALL`; otherwise skip and list the step under "Needs a decision" in the report. A tool
that is already available runs without this gate.

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

# DB connection — TEST_DATABASE_URL only. DATABASE_URL is the app's own database:
# it is never a seed target, and is read below only to detect TEST_DATABASE_URL == DATABASE_URL.
_DB_URL="${TEST_DATABASE_URL:-}"
[ -z "$_DB_URL" ] && [ -n "${DATABASE_URL:-}" ] && \
  echo "NOTE: DATABASE_URL is set but ignored — qa-seed writes only to TEST_DATABASE_URL"

# URL helper: parses the URL without ever printing its password
cat > "$_TMP/qa-seed-dburl.py" << 'PYEOF'
# Parses QA_SEED_DB_URL without ever printing its password.
#   describe    -> shell-safe KEY=value lines (password redacted), incl. DB_CLASS
#   field NAME  -> one raw field: scheme|host|port|user|password|db|path|schema|libpq_url
import os, re, sys, shlex
from urllib.parse import urlsplit, unquote, parse_qsl, urlencode, urlunsplit

url = os.environ.get('QA_SEED_DB_URL', '').strip()
app = os.environ.get('APP_DB_URL', '').strip()
u = urlsplit(url)
scheme = (u.scheme or '').lower()
q = dict(parse_qsl(u.query))
f = {'scheme': scheme, 'host': u.hostname or '', 'port': str(u.port or ''),
     'user': unquote(u.username or ''), 'password': unquote(u.password or ''),
     'db': '', 'path': '', 'schema': q.get('schema', '')}
if scheme == 'sqlite':
    f['path'] = u.path[1:] if u.path.startswith('/') else u.path   # sqlite:///rel.db, sqlite:////abs.db
elif scheme == 'file':
    f['path'] = u.path                                             # Prisma: relative to prisma/
else:
    f['db'] = unquote(u.path.lstrip('/'))
# libpq rejects Prisma-only query params (schema, connection_limit, ...); the password is
# left out of the URL (passed as PGPASSWORD) so it never appears in argv / the process list
_PRISMA_ONLY = {'schema', 'connection_limit', 'pool_timeout', 'pgbouncer',
                'socket_timeout', 'statement_cache_size'}
_netloc = u.netloc.rsplit('@', 1)[-1]
if u.username:
    _netloc = u.username + '@' + _netloc
f['libpq_url'] = urlunsplit((u.scheme, _netloc, u.path,
                             urlencode([(k, v) for k, v in parse_qsl(u.query) if k not in _PRISMA_ONLY]), ''))

tokens = [t for t in re.split(r'[^a-z0-9]+', ' '.join([f['host'], f['db'], f['path']]).lower()) if t]
PROD = re.compile(r'^(prod|production|prd|live)\d*$')
SAFE = re.compile(r'^(test|tests|testing|staging|stage|stg|dev|development|qa|ci|e2e|sandbox|local|localhost)\d*$')
MANAGED = ('rds.amazonaws.com', 'database.azure.com', 'database.windows.net', 'cloudsql',
           'neon.tech', 'supabase.co', 'psdb.cloud', 'cockroachlabs.cloud', 'mongodb.net')
safe = any(SAFE.match(t) for t in tokens) or f['host'] in ('127.0.0.1', '::1', 'host.docker.internal')
if app and url == app:
    cls, why = 'prod-like', 'TEST_DATABASE_URL is identical to the app DATABASE_URL'
elif any(PROD.match(t) for t in tokens):
    cls, why = 'prod-like', 'host/db name contains a production marker'
elif any(m in f['host'].lower() for m in MANAGED) and not safe:
    cls, why = 'prod-like', 'managed cloud host with no test/staging/dev marker'
elif safe:
    cls, why = 'test-like', 'host/db name contains a test/dev/local marker'
else:
    cls, why = 'unverified', 'no production marker, but no test/dev/local marker either'

if sys.argv[1:2] == ['field']:
    print(f.get(sys.argv[2], ''))
else:
    out = {'DB_SCHEME': scheme or 'unknown', 'DB_HOST': f['host'], 'DB_PORT': f['port'],
           'DB_USER': f['user'], 'DB_NAME': f['db'], 'DB_PATH': f['path'],
           'DB_PASSWORD': '(set, redacted)' if f['password'] else '(none)',
           'DB_CLASS': cls, 'DB_REASON': why}
    for k, v in out.items():
        print(f'{k}={shlex.quote(v)}')
PYEOF

if [ -n "$_DB_URL" ]; then
  QA_SEED_DB_URL="$_DB_URL" APP_DB_URL="${DATABASE_URL:-}" python3 "$_TMP/qa-seed-dburl.py" describe
else
  echo "DB_TARGET: none — seed files only"
fi

# Seed configuration
_SEED_ROWS="${QA_SEED_ROWS:-50}"
_SEED_MODE="${QA_SEED_MODE:-clean}"
_SEED_RESET="${QA_SEED_RESET:-0}"
echo "SEED_ROWS: $_SEED_ROWS"
echo "SEED_MODE: $_SEED_MODE  (clean = well-formed rows, insert-only | chaos = adds edge cases; neither deletes)"
echo "SEED_RESET: $_SEED_RESET  (1 = delete existing rows from the seeded tables first — destructive, gated)"
```

If `_SCHEMA_TYPE` is `none`: use `AskUserQuestion`: "No schema file found automatically. Which type do you have?" Options: "Prisma schema" | "SQL DDL file" | "TypeORM entities" | "Django models.py". Then ask for the file path and set `_SCHEMA_FILE` accordingly. As a subagent: use a schema path from the brief if one is given; otherwise stop and report that no schema was found.

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

Generate SQL INSERT statements into `$_TMP/qa-seed-data.sql` (or a Prisma Client script if
`_SCHEMA_TYPE=prisma`, see Phase 4d). Also write `$_TMP/qa-seed-rollback.sql`: `DELETE`s, in
reverse seed order, of **only the rows this run generated**, identified by the primary key or a
unique column the generator set (e.g. `email`, `slug`). Where a table has neither, say so in the
report — never fall back to deleting the whole table.

## Phase 4 — DB Write

Generating files never needs approval. Writing to a database always does. If no
`TEST_DATABASE_URL` exists, stop after the files: report `$_TMP/qa-seed-data.sql` and
`$_TMP/qa-seed-rollback.sql`.

Interactive only, when `TEST_DATABASE_URL` is unset: you may ask with `AskUserQuestion`
"No TEST_DATABASE_URL is set. Seed a database?" Options: "Generate SQL files only (recommended)" |
"I'll give you a test database URL". Use only a URL the user types here, as `TEST_DATABASE_URL` for
the commands below, and do not repeat it back in output. Never substitute `DATABASE_URL`. If the URL the user gives is the same as
`DATABASE_URL`, the check in 4a classifies it `prod-like`.

### 4a — Pre-write production check (always, before any write)

```bash
_DB_URL="${TEST_DATABASE_URL:-}"
if [ -z "$_DB_URL" ]; then
  echo "DB_WRITE: skipped — no TEST_DATABASE_URL"
else
  eval "$(QA_SEED_DB_URL="$_DB_URL" APP_DB_URL="${DATABASE_URL:-}" python3 "$_TMP/qa-seed-dburl.py" describe)"
  echo "TARGET: $DB_SCHEME host=${DB_HOST:-n/a} port=${DB_PORT:-default} db=${DB_NAME:-$DB_PATH} user=${DB_USER:-n/a} password=$DB_PASSWORD"
  echo "DB_CLASS: $DB_CLASS — $DB_REASON"
fi
```

Act on `DB_CLASS`:
- **`prod-like`** (production marker such as `prod`/`production`/`prd`/`live` in host or db name,
  a managed cloud host such as `*.rds.amazonaws.com` without a `test`/`staging`/`dev` marker, or
  the URL equals the app's `DATABASE_URL`):
  - Interactive: refuse by default. Proceed only if the user explicitly confirms through
    `AskUserQuestion` with the host and db shown: "`<host>/<db>` looks like production. Seed it
    anyway?" Options: "No — files only (recommended)" | "Yes — I confirm `<host>/<db>` is NOT
    production". Anything else = no.
  - As a subagent: **refuse, even if `ALLOW_DB_WRITE` is granted.** List it under "Needs a decision"
    with the target line above (password redacted).
- **`unverified`** (no marker either way): the gate below must show the target and the words
  "could not confirm this is a test database".
- **`test-like`**: continue to the gate.

**Gate (ALLOW_DB_WRITE):** insert the generated rows into `<scheme> <host>/<db>` (password
redacted) in one transaction, `<N>` tables, `<M>` rows. Interactive: ask with AskUserQuestion and
proceed only on yes. As a subagent: proceed only if the brief's `APPROVALS:` line contains
`ALLOW_DB_WRITE` and `$TEST_DATABASE_URL` is set in the environment (the brief says
`TEST_DATABASE_URL: from environment`); otherwise skip and list the step under "Needs a decision"
in the report.

### 4b — Optional reset (destructive; separate gate)

Only when `_SEED_RESET=1` or the user explicitly asked to empty the tables before seeding.
`clean` mode does **not** mean reset: it means well-formed rows, insert-only.

Write `$_TMP/qa-seed-reset.sql` as `DELETE FROM <table>;` for each seeded table, in **reverse**
seed order. Use `DELETE`, not `TRUNCATE`: TRUNCATE commits implicitly in MySQL, does not exist in
SQLite and can cascade in PostgreSQL, so it cannot be rolled back with the seed transaction.

**Gate (ALLOW_DB_WRITE):** DELETE ALL existing rows from `<table list>` in `<host>/<db>` before
seeding. This removes data qa-seed did not create, and it is asked separately from the insert.
Interactive: ask with AskUserQuestion and proceed only on yes. As a subagent: proceed only if the
brief's `APPROVALS:` line contains `ALLOW_DB_WRITE` **and** the brief explicitly asks for a reset
(`QA_SEED_RESET=1`); otherwise skip and list the step under "Needs a decision" in the report.

Set `_RESET_APPROVED=1` only when this gate passed.

### 4c — Execute (SQL schemas, only after 4a and the gate passed)

```bash
_DB_URL="${TEST_DATABASE_URL:?TEST_DATABASE_URL is not set — not writing}"
_field() { QA_SEED_DB_URL="$_DB_URL" python3 "$_TMP/qa-seed-dburl.py" field "$1"; }

# One transaction: optional reset + inserts
{
  echo "BEGIN;"
  [ "${_RESET_APPROVED:-0}" = "1" ] && cat "$_TMP/qa-seed-reset.sql"
  cat "$_TMP/qa-seed-data.sql"
  echo "COMMIT;"
} > "$_TMP/qa-seed-transaction.sql"

echo "=== SEED EXECUTION ==="
_RC=2
case "$(_field scheme)" in
  postgres|postgresql)
    # psql takes a URI but rejects Prisma-only params such as ?schema= — strip them,
    # and apply a Prisma schema as search_path instead. ON_ERROR_STOP aborts on the first
    # error, so the transaction is never committed half-done.
    _PG_SCHEMA=$(_field schema)
    PGPASSWORD="$(_field password)" PGOPTIONS="${_PG_SCHEMA:+-c search_path=$_PG_SCHEMA}" \
      psql "$(_field libpq_url)" -v ON_ERROR_STOP=1 -q -f "$_TMP/qa-seed-transaction.sql" \
      > "$_TMP/qa-seed-exec.log" 2>&1
    _RC=$?
    ;;
  mysql|mariadb)
    # The mysql client does not accept URLs: pass host/port/user/db as options and the
    # password via MYSQL_PWD (never on the command line). In batch mode mysql stops at the
    # first error and exits non-zero.
    _PORT=$(_field port)
    MYSQL_PWD="$(_field password)" mysql --protocol=TCP -h "$(_field host)" -P "${_PORT:-3306}" \
      -u "$(_field user)" "$(_field db)" < "$_TMP/qa-seed-transaction.sql" \
      > "$_TMP/qa-seed-exec.log" 2>&1
    _RC=$?
    ;;
  sqlite|file)
    # Prisma file: paths are relative to the prisma/ directory, not the project root
    sqlite3 -bail "$(_field path)" < "$_TMP/qa-seed-transaction.sql" > "$_TMP/qa-seed-exec.log" 2>&1
    _RC=$?
    ;;
  *)
    echo "DB_TYPE_UNSUPPORTED: $(_field scheme) — use $_TMP/qa-seed-data.sql manually" \
      > "$_TMP/qa-seed-exec.log"
    ;;
esac
tail -10 "$_TMP/qa-seed-exec.log"
echo "SEED_EXIT_CODE: $_RC"
[ "$_RC" -eq 0 ] && echo "DB_WRITTEN: yes" || echo "DB_WRITTEN: no — nothing committed, see $_TMP/qa-seed-exec.log"
```

Report `DB_WRITTEN` exactly as printed — never "yes" when the exit code was non-zero. Exit code
127 means the client is not installed: do not install it except through Gate (ALLOW_INSTALL) above;
otherwise report which client is missing and leave the SQL files for manual use.

### 4d — Execute (Prisma schemas, only after 4a and the gate passed)

Do **not** run `npx prisma db seed`: it runs the project's own configured seed, not the generated
one. Run the generated script directly, with the Prisma datasource variable pointed at the test URL
for that one command only. The script goes under `node_modules/.cache/qa-seed/` (git-ignored with
`node_modules`) so that `@prisma/client` resolves from the project; it is never written to
`prisma/seed.ts`. Plain `.mjs` needs no TypeScript runner (no `tsx` install). It needs
`@prisma/client` already installed and generated; if it is not, do not run `npm install` or
`npx prisma generate` except through Gate (ALLOW_INSTALL) — otherwise report it as missing.

```bash
_DB_URL="${TEST_DATABASE_URL:?TEST_DATABASE_URL is not set — not writing}"
# Name of the env var the datasource reads, e.g. url = env("DATABASE_URL")
_PRISMA_ENV=$(grep -oE 'url[[:space:]]*=[[:space:]]*env\("[A-Za-z_][A-Za-z0-9_]*"\)' "$_SCHEMA_FILE" \
  | head -1 | sed -E 's/.*env\("([^"]+)"\).*/\1/')
_PRISMA_ENV="${_PRISMA_ENV:-DATABASE_URL}"
_SEED_DIR="node_modules/.cache/qa-seed"
mkdir -p "$_SEED_DIR"
cat > "$_SEED_DIR/prisma-seed.mjs" << 'SEEDEOF'
// (Claude writes the generated Prisma Client seed script here:
//  import pkg from '@prisma/client'; const { PrismaClient } = pkg;
//  run every create in seed order inside one prisma.$transaction(...), optional reset
//  deleteMany() calls first only if _RESET_APPROVED=1, then prisma.$disconnect())
SEEDEOF
cp "$_SEED_DIR/prisma-seed.mjs" "$_TMP/qa-seed-prisma-seed.mjs"
# An explicitly set variable wins over the project's .env, so only the test URL is used
env "$_PRISMA_ENV=$_DB_URL" node "$_SEED_DIR/prisma-seed.mjs" > "$_TMP/qa-seed-exec.log" 2>&1
_RC=$?
tail -10 "$_TMP/qa-seed-exec.log"
echo "SEED_EXIT_CODE: $_RC"
[ "$_RC" -eq 0 ] && echo "DB_WRITTEN: yes" || echo "DB_WRITTEN: no — see $_TMP/qa-seed-exec.log"
```

Interactive only: if the user wants a reusable seed in the project, ask with `AskUserQuestion`
before copying the script to `prisma/seed.ts` (or wiring `package.json`'s `prisma.seed`). As a
subagent: never write into the project's source; mention it under "Needs a decision".

### 4e — Rollback

`$_TMP/qa-seed-rollback.sql` removes only this run's rows. Running it is a database write: the
same 4a check and **Gate (ALLOW_DB_WRITE)** apply, executed with the same commands as 4c.

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
- **Target**: <scheme> <host>/<db> (password redacted) — DB_CLASS: test-like / unverified / prod-like
- **DB written**: yes (psql / mysql / sqlite3 / prisma script) / no (files only) / refused (prod-like) / failed (exit code N)
- **Reset before seeding**: no / yes (tables listed)

## Needs a decision
<every gated step that was skipped: the step, the target (password redacted), and the approval key it needs>

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
`$_TMP/qa-seed-rollback.sql` deletes only the rows this run inserted (reverse seed order). Running
it is a database write behind the same check and gate. <tables with no PK/unique key to target, if any>

## Output Files
- `$_TMP/qa-seed-data.sql` — raw INSERT statements
- `$_TMP/qa-seed-rollback.sql` — deletes this run's rows only
- `$_TMP/qa-seed-transaction.sql` — wrapped in transaction (only if a write ran)
- `$_TMP/qa-seed-prisma-seed.mjs` — generated Prisma Client script (Prisma schemas)
- `$_TMP/qa-seed-exec.log` — database client output
```

## Important Rules

- **Never seed production** — enforced by the Phase 4a check before every write, not by this note: `prod-like` targets are refused (subagent) or need an explicit confirmation naming host and db (interactive)
- **TEST_DATABASE_URL only** — never `DATABASE_URL`, never a URL guessed from `.env` files
- **Every write is gated** — inserts, the reset and the rollback all need `ALLOW_DB_WRITE`; the reset is asked separately
- **Never print the password** — show scheme, host, port, user and db only
- **Transaction-wrapped** — always wrap DB writes in `BEGIN`/`COMMIT`, stop on the first error, and report the client's exit code
- **FK integrity** — never generate FK values that don't reference valid parent rows
- **PII-safe** — all generated values are clearly fictional (example.com emails, 555- phone numbers, "Sample" names)

## Agent Memory

After each run, update `.claude/agent-memory/qa-seed/MEMORY.md` (create if absent). Record:
- Schema type and file path confirmed
- Table dependency graph (stable across runs)
- Any FK cycles and how they were resolved
- DB type and connection string format (scheme and host only — never the URL, user password or token)
