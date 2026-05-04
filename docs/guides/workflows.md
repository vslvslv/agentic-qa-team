# Workflow Recipes

Common patterns for running the qa-agentic-team skills in real development scenarios.

---

## Pre-PR quick check

Run a fast, impact-scoped check before opening a pull request. Only tests affected by your changes run.

```bash
# In Claude Code, inside your project:
/qa-team
```

The orchestrator detects changed files via `git diff --name-only origin/main`, maps them to impacted test domains, and runs only the relevant agents. On a typical feature PR this takes 2–5 minutes instead of the full 15–30.

To skip the scope prompt and run all domains:
```
/qa-team QA_FAST_MODE=0
```

---

## Full nightly suite

Run the complete QA fleet against main — all agents, all domains, full deep mode.

Add to `.github/workflows/nightly.yml`:

```yaml
- name: Full QA Suite
  env:
    QA_DEEP_MODE: "1"
    WEB_URL: ${{ secrets.STAGING_URL }}
    API_URL: ${{ secrets.API_URL }}
    E2E_USER_EMAIL: ${{ secrets.TEST_EMAIL }}
    E2E_USER_PASSWORD: ${{ secrets.TEST_PASSWORD }}
  run: claude -p "/qa-team" --output-format stream-json | tee qa-output.jsonl
```

Or interactively from Claude Code:
```
/qa-team
```
Then select all domains when prompted.

---

## Sprint kickoff — Figma to TCMS

At the start of each sprint, generate test cases from Figma designs before implementation starts.

**Prerequisites**: `JIRA_URL`, `JIRA_TOKEN`, `FIGMA_TOKEN` env vars set. Active sprint in JIRA.

```
/qa-manager
```

Select **"Figma → Test Cases"**. The skill:
1. Fetches active sprint tickets from JIRA
2. Extracts all Figma URLs from ticket descriptions
3. Downloads each frame as a PNG via Figma API
4. Runs Claude vision analysis → structured test cases (Title, Preconditions, Steps, Expected Result)
5. Pushes to TestRail/Xray (or saves `test-specs/figma_testcases_sprint_<date>.md` if no TCMS configured)

---

## Epic → Playwright pipeline

Convert a JIRA Epic into Playwright spec skeletons with full traceability.

**Prerequisites**: `JIRA_URL`, `JIRA_TOKEN`, `JIRA_EPIC_ID` env vars set.

```
/qa-manager
```

Select **"Epic → Playwright pipeline"**. At each stage you confirm before proceeding:

1. Epic fetched → `test-specs/01_epic_<id>.confirmed.v1.json`
2. Features extracted → `test-specs/02_features_<id>.confirmed.v1.json`
3. Test plan generated → `test-specs/03_testplan_<id>.confirmed.v1.json`
4. Playwright skeletons written to `e2e/<feature>.spec.ts` with `// TC-001` traceability comments
5. Traceability matrix → `test-specs/04_traceability_<id>.json`

Run `/qa-web` after to execute the generated specs.

---

## Self-healing on CI failure

When a PR fails CI with broken selectors, `/qa-heal` classifies and fixes them automatically.

**Option A — interactive**: paste the CI output into Claude Code and type `/qa-heal`.

**Option B — automated**: configure as a GitHub Actions step after your test run:

```yaml
- name: Auto-heal on failure
  if: failure()
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    CI_FAILURE_LOG: test-results/failure.log
  run: claude -p "/qa-heal"
```

The skill classifies the failure type (broken-selector, assertion-drift, timing-issue, etc.) and routes the fix:
- Confidence ≥ 0.87 → auto-commits a fix commit
- Confidence 0.62–0.87 → opens a review PR
- Confidence < 0.62 → files a GitHub issue

---

## Visual regression review

Capture baselines on main, then compare on PRs.

**First run (capture baselines)**:
```
/qa-visual
```
Writes baseline screenshots to `visual-baselines/`. Commit these.

**On each PR**:
```
/qa-visual
```
The skill compares against the committed baselines. Diffs in the 0.1–20% range are sent to Claude Vision for semantic judgment — "is this a real regression or just dynamic content?".

Approve acceptable changes: the skill writes new baselines and creates a commit.

---

## Performance regression check

Run a load test and get a trend-based regression narrative.

```
/qa-perf
```

With Bencher configured (`BENCHER_API_TOKEN`), the skill:
1. Runs the k6 load test
2. Pushes results to Bencher trend store
3. Pulls 30-run history for the same branch
4. Claude writes: "This endpoint's p99 has drifted +12% over the last 8 PRs — inflection at SHA abc123. Check this commit for the regression."

Without Bencher: still gets you p50/p95/p99 report and threshold pass/fail.

---

## Chaos resilience test

Combine a load test with a pod kill experiment to find the resilience threshold.

```bash
export QA_CHAOS=1
# Then in Claude Code:
/qa-perf
```

The skill:
1. Auto-generates a `ChaosEngine` YAML from your k6 thresholds
2. Runs `litmusctl run chaosengine` and `k6 run` concurrently
3. Reports: "System held p99 < 200ms during 30% pod kill but breached at 50% instance loss — resilience threshold is 30–50%"

Requires `litmusctl` in PATH and a running Kubernetes cluster.

---

## Adversarial skill quality check

Verify that the QA skills themselves handle edge cases correctly.

```
/qa-meta-eval
```

Runs 8 adversarial scenarios: no-test-files, no-OpenAPI-spec, broken selector, hollow tests, zero accessibility elements, server unreachable, high-complexity routing, timing flakiness.

To check only one skill:
```bash
export QA_META_TARGET=qa-heal
/qa-meta-eval
```

---

## Learning sources update (nightly)

Keep the best-practice catalogs fresh by searching for new sources across all domains.

```
/learning-sources-refinement
```

Searches for new official docs, GitHub repos, and high-quality blog posts across:
- QA tools (Playwright, Cypress, k6, etc.)
- QA methodology (testing pyramid, BDD, contract testing, etc.)
- Programming languages
- Security, accessibility, AI testing

New sources are appended to `learning-sources/*.md`; stale entries are flagged.

Run after to regenerate the reference guides with the new sources:
```
/qa-refine playwright
/qa-methodology-refine test-isolation
```
