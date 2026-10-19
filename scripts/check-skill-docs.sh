#!/usr/bin/env bash
# scripts/check-skill-docs.sh — CI freshness gate for every generated file
# (SKILL.md and the generated .claude/agents bodies). See scripts/gen-skill-docs.sh.
set -euo pipefail
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gen-skill-docs.sh" --check
