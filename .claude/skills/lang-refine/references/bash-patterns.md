# Bash Patterns & Best Practices
<!-- sources: mixed (official: Google Shell Style Guide, ShellCheck wiki; community: awesome-shell, practitioner experience) | iteration: 0 | score: 100/100 | date: 2026-04-26 -->

## Core Philosophy

1. **Fail fast, fail loudly.** Bash's default behaviour is to silently ignore errors and continue. Every production script must opt into strict error handling so failures are surfaced immediately rather than silently corrupting state.
2. **Scripts are glue, not applications.** Bash excels at orchestrating other programs. When logic becomes complex (loops with arithmetic, heavy string manipulation, data structures), reach for Python or another language rather than fighting shell limitations.
3. **Portability is a deliberate choice.** Know whether you are writing `#!/bin/sh` (POSIX portable) or `#!/usr/bin/env bash` (bash-specific). Mixing them produces subtle, environment-dependent failures.
4. **Quoting is not optional.** Almost every shell security and correctness bug traces back to unquoted variable expansion. Always quote unless you have a specific reason not to.
5. **Functions over repetition.** Even short scripts benefit from named functions: they make intent clear, allow re-use, and make `set -x` trace output readable.

---

## Principles / Patterns

### Strict Mode: `set -euo pipefail`

Every script should begin with strict mode to catch errors early. `set -e` exits on non-zero return codes. `set -u` treats unset variables as errors. `set -o pipefail` ensures that a pipeline fails if any command in it fails (not just the last one).

```bash
#!/usr/bin/env bash
set -euo pipefail

# IFS prevents word-splitting on spaces/tabs/newlines when looping
# (optional but common in strict-mode setups)
IFS=$'\n\t'

main() {
  local input_file="${1:?Usage: $0 <input-file>}"
  local output_dir="${2:?Usage: $0 <input-file> <output-dir>}"

  [[ -f "$input_file" ]] || { echo "ERROR: $input_file not found" >&2; exit 1; }
  [[ -d "$output_dir" ]] || mkdir -p "$output_dir"

  process "$input_file" "$output_dir"
}

process() {
  local src="$1" dst="$2"
  echo "Processing $src → $dst"
  # ... real work here
}

main "$@"
```

### Local Variables in Functions

Bash variables are global by default. Failing to declare `local` leaks state between functions, causing subtle bugs especially when functions call other functions.

```bash
#!/usr/bin/env bash
set -euo pipefail

calculate_total() {
  local items=("$@")       # local array — won't pollute caller scope
  local total=0
  local item

  for item in "${items[@]}"; do
    (( total += item )) || true   # arithmetic can return 1 on zero result
  done

  echo "$total"
}

summarise() {
  local result
  result=$(calculate_total 10 20 30)   # capture output, not a global
  echo "Total: $result"
}

summarise
```

### Return Codes and Error Handling

Every command produces a return code. Functions should communicate success/failure through return codes, not output strings. Callers should test return codes explicitly.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Returns 0 on success, 1 with error message on failure
validate_env() {
  local required_vars=("$@")
  local missing=()
  local var

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then   # indirect expansion
      missing+=("$var")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    echo "ERROR: required variables not set: ${missing[*]}" >&2
    return 1
  fi
  return 0
}

# Caller tests the return code
if ! validate_env DATABASE_URL API_KEY LOG_LEVEL; then
  exit 1
fi
echo "Environment OK"
```

### `trap` for Cleanup

`trap` registers commands that run when the script exits or receives a signal. Use it to clean up temp files, release locks, and log on failure rather than scattering cleanup throughout the script.

```bash
#!/usr/bin/env bash
set -euo pipefail

TMPDIR_WORK=""

cleanup() {
  local exit_code=$?
  if [[ -n "$TMPDIR_WORK" && -d "$TMPDIR_WORK" ]]; then
    rm -rf "$TMPDIR_WORK"
    echo "Cleaned up $TMPDIR_WORK" >&2
  fi
  if (( exit_code != 0 )); then
    echo "Script failed with exit code $exit_code" >&2
  fi
}

trap cleanup EXIT          # runs on any exit (normal or error)
trap 'trap - EXIT; cleanup; exit 130' INT   # Ctrl-C → clean exit

TMPDIR_WORK=$(mktemp -d)
echo "Working in $TMPDIR_WORK"
# ... work here; cleanup runs automatically
```

### Quoting Rules

Word splitting and glob expansion happen on unquoted variables. Always double-quote variable expansions. Use `$'...'` for strings with escape sequences. Use single quotes for literal strings.

```bash
#!/usr/bin/env bash
set -euo pipefail

demonstrate_quoting() {
  local filename="my file with spaces.txt"

  # BAD: word-splits into three arguments
  # cp $filename /tmp/

  # GOOD: passes as single argument
  cp "$filename" /tmp/

  # BAD: may glob-expand if variable contains * or ?
  # for f in $filename; do

  # GOOD: array preserves elements with spaces
  local files=("first file.txt" "second file.txt")
  for f in "${files[@]}"; do
    echo "Processing: $f"
  done

  # Escape sequences: use $'...' not echo -e
  local msg=$'Line 1\nLine 2\tTabbed'
  echo "$msg"
}

demonstrate_quoting
```

### Functions with `readonly` and `declare`

Use `readonly` for constants and `declare` to enforce types. This catches accidental reassignment and makes script intent explicit.

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly MAX_RETRIES=3
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/deploy.log"

declare -i retry_count=0   # integer type — assignment validates

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date -u +%FT%TZ)" "$level" "$*" | tee -a "$LOG_FILE"
}

retry() {
  local cmd=("$@")
  retry_count=0
  until "${cmd[@]}"; do
    (( retry_count++ )) || true
    if (( retry_count >= MAX_RETRIES )); then
      log ERROR "Command failed after $MAX_RETRIES attempts: ${cmd[*]}"
      return 1
    fi
    log WARN "Attempt $retry_count failed, retrying..."
    sleep $(( 2 ** retry_count ))
  done
}

retry curl -sf "https://example.com/health"
```

### Subshells vs Forks — Process Substitution

A subshell `(...)` runs commands in a child process; assignments and `cd` there do not affect the parent. Process substitution `<(cmd)` feeds command output as a file path. Both avoid temp files.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Subshell: change directory without affecting parent
build_in_subdir() {
  local target_dir="$1"
  (                          # subshell — $PWD inside is independent
    cd "$target_dir"
    make clean all
  )
  # Back in original directory here
  echo "Still in: $PWD"
}

# Process substitution: compare two sorted streams without temp files
diff_sorted_files() {
  local file_a="$1" file_b="$2"
  diff <(sort "$file_a") <(sort "$file_b") || {
    echo "Files differ after sort" >&2
    return 1
  }
}

# Command substitution: capture output
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || git_branch="unknown"
echo "Branch: $git_branch"
```

### Portable vs Bash-Specific Constructs

Know which features require bash and which are POSIX sh. Use `[[ ]]` over `[ ]` in bash scripts (avoids word-splitting inside the test). Use `$(...)` over backticks. Use `(( ))` for arithmetic.

```bash
#!/usr/bin/env bash
set -euo pipefail

# POSIX sh: [ ] single-bracket — requires quoting, no regex, no &&/||
# Bash: [[ ]] double-bracket — safer, supports =~ regex and && ||

validate_semver() {
  local version="$1"
  # =~ regex match — bash-only, not POSIX sh
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Valid semver: $version"
    return 0
  fi
  echo "Invalid semver: $version" >&2
  return 1
}

# Arithmetic: (( )) is cleaner and bash-specific
count_files() {
  local dir="${1:-.}"
  local count
  count=$(find "$dir" -maxdepth 1 -type f | wc -l)
  if (( count > 100 )); then
    echo "WARNING: $count files in $dir" >&2
  fi
  echo "$count"
}

validate_semver "1.2.3"
validate_semver "bad.version"  || true
```

### `stderr` for Errors and Diagnostics

User-facing errors and diagnostic messages go to `stderr` (`>&2`). Parseable output (data, results) goes to `stdout`. This allows callers to capture stdout while still seeing errors.

```bash
#!/usr/bin/env bash
set -euo pipefail

die() {
  # Write to stderr; include script name and line number
  echo "${BASH_SOURCE[1]:-$0}:${BASH_LINENO[0]}: ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

fetch_config() {
  local config_file="$1"
  [[ -f "$config_file" ]] || die "Config file not found: $config_file"

  local value
  value=$(grep -m1 '^APP_PORT=' "$config_file" | cut -d= -f2) \
    || die "APP_PORT not set in $config_file"

  [[ -n "$value" ]] || die "APP_PORT is empty"
  warn "Using port $value from $config_file"
  echo "$value"   # stdout — caller can capture this
}

port=$(fetch_config "./app.env") || exit 1
echo "Will listen on port: $port"
```

---

## Language Idioms

These are features specific to Bash that make scripts more expressive and robust. They are not generic patterns transliterated into shell syntax.

### Parameter Expansion Modifiers

Bash's `${var:-default}`, `${var:?error}`, `${var:+value}`, `${var#prefix}`, `${var%suffix}`, `${var//find/replace}` handle default values, mandatory checks, and string manipulation without spawning a subshell.

```bash
#!/usr/bin/env bash
set -euo pipefail

demonstrate_param_expansion() {
  local input="${1:-}"

  # :? — exit with error if unset or empty
  local required="${BUILD_ENV:?BUILD_ENV must be set}"

  # :- — use default if unset or empty
  local env="${DEPLOY_ENV:-production}"

  # :+ — use alternate value if variable IS set
  local debug_flag="${DEBUG:+-v}"   # empty string if DEBUG unset, "-v" if set

  # Strip prefix/suffix
  local filename="build-output-20240101.tar.gz"
  local basename="${filename%.tar.gz}"   # → build-output-20240101
  local datestamp="${basename##*-}"       # → 20240101

  # Replace all occurrences
  local csv_line="a,b,c,d"
  local pipe_line="${csv_line//,/|}"   # → a|b|c|d

  echo "env=$env debug='${debug_flag}' date=$datestamp pipe=$pipe_line"
}

demonstrate_param_expansion
```

### Arrays and Associative Arrays

Bash arrays allow storing lists of items without delimiter hacks. Associative arrays (bash 4+) provide key-value stores.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Indexed array
services=("web" "api" "worker" "scheduler")

echo "All services: ${services[*]}"
echo "First: ${services[0]}"
echo "Count: ${#services[@]}"

# Iterate safely (preserves spaces in elements)
for svc in "${services[@]}"; do
  echo "Starting: $svc"
done

# Slice: elements 1 and 2
echo "Middle: ${services[@]:1:2}"

# Associative array (bash 4+)
declare -A config
config[host]="db.internal"
config[port]="5432"
config[name]="myapp"

for key in "${!config[@]}"; do
  printf '  %s = %s\n' "$key" "${config[$key]}"
done
```

### `BASH_SOURCE` and Script Directory Detection

`BASH_SOURCE[0]` gives the script's own path even when sourced. Combined with `dirname` and `cd`, it computes the script's directory portably.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolves symlinks and relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source sibling files relative to this script (not $PWD)
# shellcheck source=./lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"

echo "Script lives at: $SCRIPT_DIR"
```

### Here-Documents and Here-Strings

Heredocs pass multi-line strings to commands without temp files. Here-strings feed a single string. Both avoid echo piping.

```bash
#!/usr/bin/env bash
set -euo pipefail

generate_config() {
  local host="$1" port="$2" name="$3"

  # Heredoc: indented with <<-, tabs are stripped
  cat <<-EOF
	[database]
	host = ${host}
	port = ${port}
	name = ${name}
	EOF
}

# Here-string: single string as stdin
check_contains() {
  local needle="$1" haystack="$2"
  grep -q "$needle" <<<"$haystack"
}

generate_config "localhost" "5432" "myapp"

if check_contains "error" "no error found"; then
  echo "Found error"
else
  echo "Clean"
fi
```

### `mapfile` / `readarray` for Safe Line Reading

Reading a file into an array with `mapfile` avoids the classic `while read` loop pitfall of subshell variable loss when piping.

```bash
#!/usr/bin/env bash
set -euo pipefail

# BAD: piping to while creates a subshell — changes to 'count' are lost
bad_count() {
  local count=0
  cat /etc/hosts | while IFS= read -r line; do
    (( count++ )) || true
  done
  echo "count=$count"   # always 0 — subshell changes lost
}

# GOOD: mapfile reads lines into array in the current shell
good_count() {
  local -a lines
  mapfile -t lines < /etc/hosts
  echo "Lines: ${#lines[@]}"
  # Process each line
  for line in "${lines[@]}"; do
    [[ "$line" =~ ^# ]] && continue   # skip comments
    echo "  $line"
  done
}

good_count
```

---

## Real-World Gotchas  [community]

### 1. Missing `pipefail` Makes Pipelines Silently Succeed  [community]
**What it is:** Without `set -o pipefail`, a pipeline like `cmd1 | cmd2` returns the exit code of only the last command. If `cmd1` fails but `cmd2` succeeds, the pipeline returns 0. **WHY it causes problems:** Errors in data-generating commands are invisible; downstream processing continues on empty or corrupt data producing silent data loss or wrong results. **Fix:** Always include `pipefail` in `set -euo pipefail` at the top of every script.

### 2. Unquoted Variables Split and Glob  [community]
**What it is:** When `$var` is not double-quoted, bash splits its value on `IFS` characters (space, tab, newline) and expands glob characters (`*`, `?`, `[`). **WHY it causes problems:** `rm $file` where `file="my file.txt"` runs `rm my` and `rm file.txt` — wrong arguments, potential data loss. `cp $src /tmp/` where `src="*.txt"` may pass dozens of files. **Fix:** Always write `"$var"` and `"${array[@]}"`. ShellCheck (SC2086) will catch unquoted expansions.

### 3. Losing Variables After Pipe to `while read`  [community]
**What it is:** In bash (not zsh), the right-hand side of a pipe runs in a subshell. Variables set inside `cmd | while read line; do ...; done` are lost when the loop exits. **WHY it causes problems:** Counters, accumulators, and state collected in the loop silently reset to zero after the loop — a bug that only manifests when the logic needs to use the loop output. **Fix:** Use process substitution `while IFS= read -r line; do ...; done < <(cmd)` or `mapfile -t arr < <(cmd)` to keep everything in the current shell.

### 4. Using `exit` Inside Sourced Functions  [community]
**What it is:** A function that calls `exit` terminates the entire shell when the script is sourced (`. script.sh`). **WHY it causes problems:** Library scripts intended for sourcing kill the interactive session on errors. CI pipelines that source setup files can terminate the entire pipeline runner. **Fix:** Use `return` inside functions to indicate failure. Only call `exit` from `main` or top-level error handlers, and document whether a script is meant to be sourced or executed.

### 5. Arithmetic on Possibly-Zero with `set -e`  [community]
**What it is:** `(( expr ))` returns exit code 1 when the result is 0 (falsy in C arithmetic). With `set -e`, any exit code 1 terminates the script. So `(( count++ ))` where `count` starts at 0 exits the script immediately. **WHY it causes problems:** Silent script termination mid-loop, no error message, hard to diagnose — especially in CI pipelines where the issue only appears when a counter starts at 0. **Fix:** Use `(( count++ )) || true` or `(( count++ )) || :` to absorb the falsy return, or use `count=$(( count + 1 ))` which does not set an exit code.

### 6. `cd` Failure Not Caught, Subsequent Commands Run in Wrong Directory  [community]
**What it is:** If `cd "$dir"` fails because the directory does not exist (permissions, typo, race condition), and `set -e` is not in effect, subsequent commands run in the current directory instead of the intended one. **WHY it causes problems:** A script that `cd`s to a temp dir and then runs `rm -rf ./*` will wipe the wrong directory if `cd` silently failed. **Fix:** With `set -e` `cd` failures exit immediately. Additionally, combine: `cd "$dir" || { echo "Cannot cd to $dir" >&2; exit 1; }`. Or run in a subshell `( cd "$dir"; rm -rf ./* )`.

### 7. Forgetting `IFS= read -r` in `while` Loops  [community]
**What it is:** The default `while read line` has two bugs: (a) backslashes are interpreted as escape characters, mangling filenames; (b) leading/trailing whitespace is stripped. **WHY it causes problems:** File processing scripts silently mangle lines — especially config parsing and log processing where backslashes and indentation are meaningful. **Fix:** Always write `while IFS= read -r line` — `IFS=` prevents whitespace trimming, `-r` prevents backslash interpretation. ShellCheck (SC2162) warns about this.

---

## Anti-Patterns Quick Reference

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| `#!/bin/sh` with bash-isms | Script fails on systems where `/bin/sh` is `dash` or `busybox` | Use `#!/usr/bin/env bash` for bash scripts; keep `#!/bin/sh` only for strictly POSIX code |
| Parsing `ls` output | `ls` output is for humans; spaces/newlines in filenames break parsing | Use `find`, glob expansion `for f in *.txt`, or `mapfile` |
| `cat file | grep pattern` (useless cat) | Spawns an extra process; `grep` accepts file arguments directly | `grep pattern file` or `grep pattern < file` |
| Backticks for command substitution | Hard to nest, hard to read, backslash escaping differs | Use `$(...)` which nests cleanly |
| Unquoted `$@` | Merges all arguments into a single string, losing word boundaries | Always use `"$@"` to preserve individual arguments |
| Testing with `==` in `[ ]` | `[ $a == $b ]` is not POSIX; some sh implementations reject it | Use `[ "$a" = "$b" ]` (POSIX) or `[[ "$a" == "$b" ]]` (bash) |
| Hardcoded paths like `/home/user/` | Non-portable; breaks for different users or container environments | Use `$HOME`, `$XDG_CONFIG_HOME`, or derive from `BASH_SOURCE` |
| `echo` for binary/arbitrary data | `echo` is implementation-dependent with `-e`, `-n`, and backslashes | Use `printf` for precise control over output formatting |
| `while read` on piped input (variable loss) | Subshell loses all variable mutations after loop | Use process substitution `< <(cmd)` or `mapfile` |
| Silently ignoring `$?` return codes | Failures compound; later commands operate on bad state | Test return codes with `if`, `||`, or rely on `set -e` |
