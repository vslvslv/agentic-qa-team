---
name: qa-deps
preamble-tier: 3
version: 1.0.0
description: |
  Service dependency smoke test. Spins up all declared service dependencies from test-env.yml or
  docker-compose.yml using Docker Compose or Testcontainers, runs a lightweight health check against
  each service (database connection, cache ping, HTTP health endpoint, message queue connectivity),
  then tears down. Catches infrastructure drift before full integration tests run.
  Env vars: DEPS_TIMEOUT, DEPS_KEEP_RUNNING. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

# Docker availability
_DOCKER=0
command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && _DOCKER=1
echo "DOCKER_AVAILABLE: $_DOCKER"

# Find compose config (preference order)
_CONFIG_FILE=""
for f in test-env.yml docker-compose.yml docker-compose.test.yml compose.yml; do
  [ -f "$f" ] && _CONFIG_FILE="$f" && break
done
echo "CONFIG_FILE: ${_CONFIG_FILE:-none}"

# Parse service list
_SERVICES_COUNT=0
if [ -n "$_CONFIG_FILE" ]; then
  _SERVICES_COUNT=$(grep -c '^  [a-zA-Z]' "$_CONFIG_FILE" 2>/dev/null || echo 0)
fi
echo "SERVICES_COUNT: $_SERVICES_COUNT"

# Env vars
_DEPS_TIMEOUT="${DEPS_TIMEOUT:-30}"
_KEEP_RUNNING="${DEPS_KEEP_RUNNING:-0}"
echo "DEPS_TIMEOUT: $_DEPS_TIMEOUT  KEEP_RUNNING: $_KEEP_RUNNING"
```

If `_DOCKER=0`: emit the following and stop gracefully:
```
Docker not available. To use qa-deps:
1. Install Docker Desktop: https://docs.docker.com/get-docker/
2. Ensure Docker daemon is running: docker info
3. Re-run qa-deps
```

If `_CONFIG_FILE` is empty: emit "No compose config found. Create one of: test-env.yml, docker-compose.yml, docker-compose.test.yml, compose.yml" and stop gracefully.

## Phase 1 — Start Services

```bash
echo "--- STARTING SERVICES ---"
timeout 90 docker compose -f "$_CONFIG_FILE" up -d --wait 2>&1
COMPOSE_EXIT=$?
echo "COMPOSE_UP_EXIT: $COMPOSE_EXIT"

# List running services
docker compose -f "$_CONFIG_FILE" ps 2>&1
```

If `COMPOSE_EXIT` is non-zero: emit error details and ask user if they want to continue with health checks anyway (some services may still have started).

## Phase 2 — Health Checks

Parse service list from compose config and run type-specific health checks:

```python
python3 - << 'PYEOF'
import json, os, subprocess, time

config_file = os.environ.get('_CONFIG_FILE', '')
timeout = int(os.environ.get('_DEPS_TIMEOUT', '30'))
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

# Parse services from compose YAML (simple grep-based approach)
services = []
if config_file and os.path.exists(config_file):
    in_services = False
    current = None
    image = None
    for line in open(config_file, encoding='utf-8'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
        elif in_services and stripped.startswith('  ') and not stripped.startswith('    ') and stripped.endswith(':'):
            if current:
                services.append({'name': current, 'image': image or ''})
            current = stripped.strip().rstrip(':')
            image = None
        elif in_services and current and 'image:' in stripped:
            image = stripped.split('image:')[-1].strip().strip("'\"")
    if current:
        services.append({'name': current, 'image': image or ''})

print(f"SERVICES: {[s['name'] for s in services]}")

def detect_type(image):
    img = image.lower()
    if any(x in img for x in ('postgres', 'pgvector', 'pg:')): return 'postgres'
    if any(x in img for x in ('mysql', 'mariadb')): return 'mysql'
    if 'redis' in img: return 'redis'
    if 'mongo' in img: return 'mongodb'
    if 'kafka' in img: return 'kafka'
    if 'rabbitmq' in img: return 'rabbitmq'
    if any(x in img for x in ('elastic', 'opensearch')): return 'elasticsearch'
    return 'http'

def run_check(svc, svc_type, config_file, timeout):
    start = time.time()
    cmd = ['docker', 'compose', '-f', config_file, 'exec', '-T', svc]
    try:
        if svc_type == 'postgres':
            r = subprocess.run(cmd + ['pg_isready', '-U', os.environ.get('POSTGRES_USER', 'postgres')],
                               capture_output=True, text=True, timeout=timeout)
            if r.returncode == 0:
                # Also run SELECT 1
                subprocess.run(cmd + ['psql', '-U', os.environ.get('POSTGRES_USER', 'postgres'),
                                       '-c', 'SELECT 1'],
                               capture_output=True, timeout=timeout)
            return r.returncode == 0, r.stdout.strip() or r.stderr.strip()

        elif svc_type == 'mysql':
            r = subprocess.run(cmd + ['mysqladmin', 'ping', '-h', 'localhost', '--silent'],
                               capture_output=True, text=True, timeout=timeout)
            return r.returncode == 0, r.stdout.strip() or r.stderr.strip()

        elif svc_type == 'redis':
            r = subprocess.run(cmd + ['redis-cli', 'ping'],
                               capture_output=True, text=True, timeout=timeout)
            return 'PONG' in r.stdout, r.stdout.strip()

        elif svc_type == 'mongodb':
            r = subprocess.run(cmd + ['mongosh', '--eval', 'db.runCommand({ ping: 1 })'],
                               capture_output=True, text=True, timeout=timeout)
            return r.returncode == 0 and 'ok' in r.stdout.lower(), r.stdout.strip()[:200]

        elif svc_type == 'kafka':
            r = subprocess.run(cmd + ['kafka-topics.sh', '--bootstrap-server', 'localhost:9092', '--list'],
                               capture_output=True, text=True, timeout=timeout)
            return r.returncode == 0, r.stdout.strip()[:100]

        elif svc_type == 'rabbitmq':
            r = subprocess.run(
                ['curl', '-sf', 'http://guest:guest@localhost:15672/api/overview'],
                capture_output=True, text=True, timeout=timeout)
            return r.returncode == 0, r.stdout.strip()[:100]

        elif svc_type == 'elasticsearch':
            r = subprocess.run(
                ['curl', '-sf', 'http://localhost:9200/_cluster/health'],
                capture_output=True, text=True, timeout=timeout)
            return r.returncode == 0, r.stdout.strip()[:100]

        else:  # http fallback
            for port in (8080, 3000, 8000, 8081, 9000):
                r = subprocess.run(
                    ['curl', '-sf', '--max-time', '5', f'http://localhost:{port}/health'],
                    capture_output=True, text=True, timeout=timeout)
                if r.returncode == 0:
                    return True, f'HTTP 200 on port {port}'
            return False, 'No reachable HTTP health endpoint found'

    except subprocess.TimeoutExpired:
        return False, f'Timeout after {timeout}s'
    except Exception as e:
        return False, str(e)[:120]

results = []
for svc in services:
    name = svc['name']
    image = svc['image']
    svc_type = detect_type(image)
    print(f"  Checking {name} ({svc_type} / {image or 'unknown image'})...")
    latency_start = time.time()
    healthy, detail = run_check(name, svc_type, config_file, timeout)
    latency_ms = int((time.time() - latency_start) * 1000)
    status = 'healthy' if healthy else 'unhealthy'
    results.append({'name': name, 'type': svc_type, 'image': image, 'status': status,
                    'latency_ms': latency_ms, 'detail': detail})
    print(f"    {status.upper():10s} {latency_ms}ms — {detail[:80]}")

out = os.path.join(tmp, 'qa-deps-results.json')
json.dump(results, open(out, 'w', encoding='utf-8'), indent=2)
healthy_ct = sum(1 for r in results if r['status'] == 'healthy')
unhealthy_ct = sum(1 for r in results if r['status'] == 'unhealthy')
print(f"HEALTHY: {healthy_ct}  UNHEALTHY: {unhealthy_ct}")
print(f"RESULTS_WRITTEN: {out}")
PYEOF
```

## Phase 3 — Teardown

```bash
if [ "$_KEEP_RUNNING" = "0" ]; then
  echo "--- TEARING DOWN ---"
  docker compose -f "$_CONFIG_FILE" down --remove-orphans 2>&1
  echo "TEARDOWN_EXIT: $?"
else
  echo "KEEP_RUNNING=1 — services left running (docker compose -f $_CONFIG_FILE down to stop)"
fi
```

## Phase 4 — Report

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
config_file = os.environ.get('_CONFIG_FILE', 'unknown')

try:
    results = json.load(open(os.path.join(tmp, 'qa-deps-results.json'), encoding='utf-8'))
except Exception:
    results = []

healthy = [r for r in results if r['status'] == 'healthy']
unhealthy = [r for r in results if r['status'] == 'unhealthy']

lines = [
    f'# QA Service Dependencies Report — {date}',
    '',
    '## Summary',
    f'- Config file: `{config_file}`',
    f'- Services checked: {len(results)}',
    f'- Healthy: {len(healthy)}  Unhealthy: {len(unhealthy)}',
    f'- Status: {"PASS" if not unhealthy else "FAIL"}',
    '',
    '## Service Health',
    '',
    '| Service | Type | Status | Response Time | Notes |',
    '|---------|------|--------|---------------|-------|',
]

for r in results:
    icon = 'healthy' if r['status'] == 'healthy' else 'UNHEALTHY'
    detail = r.get('detail', '')[:60].replace('|', '\\|')
    lines.append(f'| {r["name"]} | {r["type"]} | {icon} | {r["latency_ms"]}ms | {detail} |')

if unhealthy:
    lines += ['', '## Failures', '']
    for r in unhealthy:
        lines.append(f'### {r["name"]} ({r["type"]})')
        lines.append(f'- Image: `{r.get("image", "unknown")}`')
        lines.append(f'- Error: {r.get("detail", "no detail")}')
        lines.append(f'- Suggestion: Check docker compose logs: `docker compose -f {config_file} logs {r["name"]}`')
        lines.append('')

report_path = os.path.join(tmp, f'qa-deps-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f'REPORT_WRITTEN: {report_path}')

# CTRF
ctrf_tests = []
for r in results:
    ctrf_tests.append({
        'name': f'{r["name"]} ({r["type"]})',
        'status': 'passed' if r['status'] == 'healthy' else 'failed',
        'duration': r.get('latency_ms', 0),
        'suite': 'deps',
        'message': r.get('detail', '')[:200] if r['status'] == 'unhealthy' else '',
    })

passed = sum(1 for t in ctrf_tests if t['status'] == 'passed')
failed_ct = sum(1 for t in ctrf_tests if t['status'] == 'failed')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-deps'},
        'summary': {
            'tests': len(ctrf_tests), 'passed': passed, 'failed': failed_ct,
            'pending': 0, 'skipped': 0, 'other': 0,
            'start': now_ms - 30000, 'stop': now_ms,
        },
        'tests': ctrf_tests,
        'environment': {'reportName': 'qa-deps', 'configFile': config_file, 'date': date},
    }
}

out = os.path.join(tmp, 'qa-deps-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(ctrf_tests)} passed={passed} failed={failed_ct}')
PYEOF
```

## Important Rules

- **Always teardown unless DEPS_KEEP_RUNNING=1** — never leave orphaned containers; use `--remove-orphans`
- **Health check failures must include actual error** — never emit a generic "unhealthy" without the real error message
- **Port conflicts** — if a health check fails because port is occupied by a host service, detect and report this clearly
- **Timeout per service** — use `_DEPS_TIMEOUT` (default 30s) for each individual check; do not wait indefinitely
- **No Docker = graceful stop** — emit setup instructions if Docker is not available; never error out silently

## Agent Memory

After each run, update `.claude/agent-memory/qa-deps/MEMORY.md` (create if absent). Record:
- Compose config file used
- Services found and their detected types
- Services that consistently fail (infrastructure drift patterns)
- Port numbers that conflict with host services

Read this file at the start of each run.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-deps","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
