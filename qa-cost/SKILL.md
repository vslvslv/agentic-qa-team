---
name: qa-cost
preamble-tier: 3
version: 1.0.0
description: |
  AI API cost tracking and budget gate. Reads token usage metadata from CTRF output files produced by qa-* skills, computes estimated cost per skill using current Claude model pricing, and can block CI if the total run cost exceeds a configured budget. Provides financial observability alongside functional QA observability. Env vars: QA_COST_BUDGET, QA_COST_MODEL. (qa-agentic-team)
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

# Discover CTRF output files (exclude qa-cost itself)
_CTRF_FILES=$(ls $_TMP/qa-*-ctrf.json 2>/dev/null | grep -v "qa-cost")
_CTRF_COUNT=$(echo "$_CTRF_FILES" | grep -c . 2>/dev/null || echo 0)
echo "CTRF_FILES_FOUND: $_CTRF_COUNT"

# Budget gate configuration
_COST_BUDGET="${QA_COST_BUDGET:-}"
_COST_MODEL="${QA_COST_MODEL:-claude-sonnet-4-6}"
echo "COST_BUDGET: ${_COST_BUDGET:-unset (gate disabled)}"
echo "COST_MODEL: $_COST_MODEL"

# Model pricing (USD per million tokens): input / output
# claude-opus-4-7:   $15 / $75
# claude-sonnet-4-6: $3  / $15
# claude-haiku-4-5:  $0.80 / $4
echo "PRICING_REFERENCE: opus-4-7=$15/$75  sonnet-4-6=$3/$15  haiku-4-5=$0.80/$4 per M tokens"

# Check for separate usage log files produced by skills that emit token counts
_USAGE_FILES=$(ls $_TMP/qa-*-usage.json 2>/dev/null || true)
echo "USAGE_LOG_FILES: ${_USAGE_FILES:-none}"
echo "--- DONE ---"
```

## Phase 1 — Extract Token Usage

For each CTRF file in `$_CTRF_FILES`:
- Look for custom `usage` metadata in the CTRF `results.tool` object or in individual test `metadata` fields
- If token data is present: extract `input_tokens`, `output_tokens`, `model`
- If token data is not present: estimate based on skill type using conservative defaults:
  - `qa-explore`: ~50,000 tokens (input) / ~10,000 tokens (output)
  - `qa-web`: ~30,000 tokens (input) / ~8,000 tokens (output)
  - `qa-api`: ~20,000 tokens (input) / ~5,000 tokens (output)
  - `qa-visual`: ~25,000 tokens (input) / ~6,000 tokens (output)
  - `qa-perf`: ~15,000 tokens (input) / ~4,000 tokens (output)
  - `qa-security`: ~20,000 tokens (input) / ~5,000 tokens (output)
  - All other qa-* skills: ~15,000 tokens (input) / ~4,000 tokens (output)
- Clearly label estimated rows as `[ESTIMATED]` in the output table

## Phase 2 — Compute Cost

Apply the pricing map from the preamble:
- Cost per skill = (input_tokens / 1,000,000) x input_price + (output_tokens / 1,000,000) x output_price
- Default model assumption when not specified in CTRF: `claude-sonnet-4-6` ($3.00/$15.00 per MTok)
- Total run cost = sum across all skills

Present:

| Skill | Model | Input Tokens | Output Tokens | Cost (USD) | Source |
|-------|-------|-------------|--------------|-----------|--------|
| ...   | ...   | ...         | ...          | ...       | actual / [ESTIMATED] |
| **Total** | | | | **$X.XX** | |

## Phase 3 — Budget Check

- If `_QA_COST_BUDGET` is set: compare total cost against budget
  - Under budget: print `COST_GATE: OK ($X.XX <= $Y.YY)`
  - Over budget: print `COST_GATE: OVER BUDGET ($X.XX > $Y.YY)`
  - If `_QA_COST_FAIL_ON_OVER=1`: the gate test is marked failed in CTRF output
  - If `_QA_COST_FAIL_ON_OVER=0` (default): over budget is a warning, not a failure
- If `_QA_COST_BUDGET` is not set: skip gate check, report is informational only

## Phase 4 — Report + CTRF

Write `$_TMP/qa-cost-report-$_DATE.md`:

```markdown
# QA Cost Report — <date> (<branch>)

## Summary
- Budget: <QA_COST_BUDGET or "not set">
- Total cost: $<X.XX>
- Gate status: OK / OVER BUDGET / INFORMATIONAL

## Cost Breakdown

| Skill | Model | Input Tokens | Output Tokens | Cost (USD) | Source |
|-------|-------|-------------|--------------|-----------|--------|

## Notes
- Estimated rows are marked [ESTIMATED] and use conservative token counts
- Actual token usage requires CTRF files with `usage` metadata populated by the skill
- Set QA_COST_BUDGET=<dollars> to enable budget gate
- Set QA_COST_FAIL_ON_OVER=1 to block CI when over budget
```

Write `$_TMP/qa-cost-ctrf.json`:

```python
python3 - << 'PYEOF'
import json, os, time, glob as glob_mod

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
budget_str = os.environ.get('QA_COST_BUDGET', '')
fail_on_over = os.environ.get('QA_COST_FAIL_ON_OVER', '0') == '1'

# Pricing map: model -> (input_price_per_mtok, output_price_per_mtok)
pricing = {
    'claude-sonnet-4-6': (3.00, 15.00),
    'claude-haiku-4-5': (0.80, 4.00),
    'claude-opus-4-7': (15.00, 75.00),
}
# Estimation defaults per skill (input_tokens, output_tokens)
skill_estimates = {
    'qa-explore': (50000, 10000),
    'qa-web': (30000, 8000),
    'qa-api': (20000, 5000),
    'qa-visual': (25000, 6000),
    'qa-perf': (15000, 4000),
    'qa-security': (20000, 5000),
}
default_estimate = (15000, 4000)
default_model = 'claude-sonnet-4-6'

total_cost = 0.0
tests = []

for f in sorted(glob_mod.glob(os.path.join(tmp, 'qa-*-ctrf.json'))):
    if f.endswith('qa-cost-ctrf.json'):
        continue
    try:
        data = json.load(open(f, encoding='utf-8', errors='replace'))
        tool_name = data.get('results', {}).get('tool', {}).get('name', os.path.basename(f).replace('-ctrf.json', ''))
        usage = data.get('results', {}).get('tool', {}).get('usage', {})
        model = usage.get('model', default_model)
        input_tok = usage.get('input_tokens', 0)
        output_tok = usage.get('output_tokens', 0)
        estimated = False
        if input_tok == 0 and output_tok == 0:
            est = skill_estimates.get(tool_name, default_estimate)
            input_tok, output_tok = est
            estimated = True
        ip, op = pricing.get(model, pricing[default_model])
        cost = (input_tok / 1_000_000) * ip + (output_tok / 1_000_000) * op
        total_cost += cost
        label = f'${cost:.4f}' + (' [ESTIMATED]' if estimated else '')
        tests.append({'name': f'cost-{tool_name}', 'status': 'passed', 'duration': 0,
                      'suite': 'qa-cost', 'message': label})
    except Exception as e:
        tests.append({'name': f'cost-{os.path.basename(f)}', 'status': 'skipped', 'duration': 0,
                      'suite': 'qa-cost', 'message': f'parse error: {e}'})

# Budget gate test
gate_status = 'passed'
gate_msg = f'Total: ${total_cost:.4f} — no budget set'
if budget_str:
    try:
        budget = float(budget_str)
        if total_cost > budget:
            gate_msg = f'OVER BUDGET: ${total_cost:.4f} > ${budget:.2f}'
            gate_status = 'failed' if fail_on_over else 'skipped'
        else:
            gate_msg = f'OK: ${total_cost:.4f} <= ${budget:.2f}'
    except ValueError:
        gate_msg = f'Invalid QA_COST_BUDGET value: {budget_str}'
tests.append({'name': 'cost-budget-gate', 'status': gate_status, 'duration': 0,
              'suite': 'qa-cost', 'message': gate_msg})

p = sum(1 for t in tests if t['status'] == 'passed')
f_count = sum(1 for t in tests if t['status'] == 'failed')
s = sum(1 for t in tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-cost'},
        'summary': {
            'tests': len(tests), 'passed': p, 'failed': f_count,
            'pending': 0, 'skipped': s, 'other': 0,
            'start': now_ms - 5000, 'stop': now_ms,
            'total_cost_usd': round(total_cost, 4),
        },
        'tests': tests,
    }
}
out = os.path.join(tmp, 'qa-cost-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  total_cost=${total_cost:.4f}  gate={gate_status}')
PYEOF
```

## Important Rules

- **Token estimation is clearly labeled** — rows showing `[ESTIMATED]` are not exact; actual usage requires skills to embed `usage` metadata in their CTRF output
- **Cost gate is opt-in** — `QA_COST_FAIL_ON_OVER=0` by default; informational reporting never blocks CI
- **Never expose credentials** — do not print `ANTHROPIC_API_KEY`, account IDs, or billing details in any output
- **Read-only** — qa-cost never re-runs skills or modifies other CTRF files

## Agent Memory

After each run, update `.claude/agent-memory/qa-cost/MEMORY.md` (create if absent). Record:
- Typical cost per skill observed across runs
- Whether token data was actual or estimated for each skill
- Any budget thresholds configured by the project
