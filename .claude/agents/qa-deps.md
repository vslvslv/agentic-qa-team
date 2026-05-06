---
name: qa-deps
description: |
  Service dependency smoke test. Spins up all declared service dependencies from test-env.yml
  or docker-compose.yml using Docker Compose, runs a lightweight health check against each
  service (database connection, cache ping, HTTP health endpoint, message queue connectivity),
  then tears down. Catches infrastructure drift before full integration tests run.
  Env vars: DEPS_TIMEOUT, DEPS_KEEP_RUNNING.
model: sonnet
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

command -v docker >/dev/null 2>&1 && echo "DOCKER_AVAILABLE: 1" || echo "DOCKER_AVAILABLE: 0"
docker compose version >/dev/null 2>&1 && echo "COMPOSE_AVAILABLE: 1" || echo "COMPOSE_AVAILABLE: 0"

_COMPOSE_FILE=""
for f in docker-compose.yml docker-compose.yaml test-env.yml compose.yml compose.yaml docker-compose.test.yml; do
  [ -f "$f" ] && _COMPOSE_FILE="$f" && break
done
echo "COMPOSE_FILE: ${_COMPOSE_FILE:-(not found)}"

[ -n "$_COMPOSE_FILE" ] && docker compose -f "$_COMPOSE_FILE" config --services 2>/dev/null | tr '\n' ' ' | xargs echo "SERVICES:"

_DEPS_TIMEOUT="${DEPS_TIMEOUT:-30}"
_KEEP_RUNNING="${DEPS_KEEP_RUNNING:-0}"
echo "DEPS_TIMEOUT: ${_DEPS_TIMEOUT}s  KEEP_RUNNING: $_KEEP_RUNNING"
echo "--- DONE ---"
```

If `DOCKER_AVAILABLE: 0` or no compose file found, report and exit.

## Phase 1 — Start Services

`docker compose -f "$_COMPOSE_FILE" up -d 2>&1 | tee $_TMP/qa-deps-startup.log`

## Phase 2 — Health Check Each Service

For each service, detect type from image name and run appropriate check:
- **postgres**: `docker compose exec -T $SVC pg_isready`
- **mysql/mariadb**: `docker compose exec -T $SVC mysqladmin ping`
- **redis**: `docker compose exec -T $SVC redis-cli ping`
- **kafka**: `docker compose exec -T $SVC kafka-topics.sh --bootstrap-server localhost:9092 --list`
- **rabbitmq**: `docker compose exec -T $SVC rabbitmqctl status`
- **HTTP service**: `curl -sf --max-time 5 "http://localhost:$(docker compose port $SVC 80 | cut -d: -f2)/health"`

Retry every 2s up to `$DEPS_TIMEOUT` seconds.

## Phase 3 — Teardown

`[ "$_KEEP_RUNNING" != "1" ] && docker compose -f "$_COMPOSE_FILE" down`

## Phase N — Report

Write `$_TMP/qa-deps-report-{_DATE}.md`: service health table with response times; startup log excerpts for failures.

Write `$_TMP/qa-deps-ctrf.json` (each service = one test; unhealthy = failed).

## Important Rules

- Each service = one CTRF test case
- Use `DEPS_KEEP_RUNNING=1` to preserve services (useful when sharing across test suites)
- Port mapping is dynamic — always use `docker compose port` not hardcoded ports
- Run this before `qa-api` or integration tests to ensure dependencies are healthy
