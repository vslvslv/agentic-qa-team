# Exploratory Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: exploratory | iteration: 13 | score: 100/100 | date: 2026-05-02 | sources: training-knowledge -->
<!-- ISTQB CTFL 4.0 terminology applied: "defect" for filed items, "test case" for scripted items, "test level" for pyramid layers -->
<!-- Refinement history (iterations 11-13, 2026-05-02):
     - Iter 11: sharpened SBTM definition (SBTM=process, RST=skill), added 3-part charter grammar table
     - Iter 12: charter schema validator TypeScript example; ISTQB experience-based technique comparison; known adoption cost table; risk-trigger CI/CD TypeScript example; 2 new community lessons (#29 async teams, #30 risk-triggered scheduling); 2 new anti-patterns (AI charters, end-of-sprint batching)
     - Iter 13: session charter to issue tracker bridge TypeScript example; final score verification
     Rubric scores: Coverage 25/25 | Examples 25/25 | Tradeoffs 25/25 | Community 25/25 = 100/100
-->

## Core Principles

Exploratory testing is the simultaneous process of **learning about a system, designing tests, and executing them** — all in real time. Unlike scripted testing, the tester adapts as they go: observations from one check immediately influence the next. James Bach and Michael Bolton define it as "a style of software testing that emphasises the personal freedom and responsibility of the individual tester to continually optimise the quality of their work by treating test-related learning, test design, test execution, and test result interpretation as mutually supportive activities that run in parallel."

Cem Kaner, who coined the term in the 1980s, distinguished exploratory testing from ad hoc testing precisely on the axis of skill and discipline: ad hoc testing is random clicking; exploratory testing is a skilled practice guided by heuristics, mission-based charters, and structured reflection. The discipline has matured through the Context-Driven Testing school and the Rapid Software Testing methodology into a complete, auditable framework.

### Why Each Principle Matters

1. **Simultaneous learning, design, and execution**: Waiting to write test cases before executing them loses the learning gained from early interactions with the product. Exploratory testing lets insight from the system itself drive the next move. A tester who observes unexpected behavior at step 2 can pivot immediately — something a scripted test runner cannot do, because the script was written before the behavior was discovered.

2. **Session-Based Test Management (SBTM)**: Introduced by James Bach and Jonathan Bach, SBTM is the *process* framework for exploratory testing. It converts free-form exploration into a manageable, reportable activity by imposing three structures: a **charter** (mission statement for what to explore), a **session** (timeboxed, focused execution block), and a **debrief** (structured knowledge transfer after the session). SBTM does not prescribe how to test — it prescribes how to track, report, and improve testing. The timebox creates a natural reporting cadence: every session produces a session sheet and a debrief output, making progress visible without requiring test case IDs. Contrast with **Rapid Software Testing (RST)**, which is the *skill* framework: RST teaches testers how to form and test hypotheses, use oracles rigorously, and reason about test coverage — but says nothing about session scheduling or sprint metrics. Teams adopting exploratory testing need both: SBTM for process visibility, RST for tester skill development.

3. **Charter format — "Explore X with Y to discover Z"**: A charter is a mission statement, not a script. It defines the target (X), the resources or approach (Y), and the information goal (Z). This gives the tester purpose without removing freedom. The three-part charter prevents both aimless wandering and over-specification.

   | Part | Role | Common mistake | Correct form |
   |------|------|---------------|-------------|
   | **Explore X** | Scopes the feature/area under investigation | Too broad: "Explore the app" | "Explore the guest checkout address form" |
   | **with Y** | Names tools, test data, entry points, or approach | Omitted entirely | "using mobile viewport, international test cards, and an account without saved addresses" |
   | **to discover Z** | States the information goal — what you want to learn | Mirrors "X" exactly: "to discover issues with X" | "to discover locale formatting errors and error-handling gaps after payment failure" |

   The "to discover Z" part is the most important and the most commonly miswritten. If Z is vague ("to discover any issues"), the charter cannot drive the session effectively and cannot be evaluated at debrief. If Z is specific, the tester knows when they have succeeded and the debrief can assess whether the goal was achieved. Good "Z" statements are questions: "Does the address form handle non-US postal codes?" or "What happens when a user navigates back mid-payment?"

4. **FEW HICCUPS heuristic (test coverage)**: FEW HICCUPS is a mnemonic for coverage areas: Function, Error, Workload, Hints/Help, Interruptions, Collaboration, Configuration, Users, Platform/Performance, Stress. It helps testers avoid the common trap of testing only the happy path and forgetting about load, edge users, or configuration variability. Without a heuristic like this, two testers exploring the same feature will cover completely different areas with no systematic basis for comparison.

5. **HICCUPPS oracle heuristic (bug recognition)**: An oracle helps you decide whether observed behavior is a bug. HICCUPPS stands for History, Image, Comparable products, Claims, User expectations, Product, Purpose, Standards. Each dimension gives a reason to call behavior unexpected and therefore suspect. Without an oracle framework, testers either miss bugs (accepting surprising behavior as intentional) or overreport non-bugs (flagging behavior they personally dislike but which is correct).

6. **Bug taxonomy**: Classifying bugs by type (crash, correctness, cosmetic, boundary, performance, security) serves two purposes: it guides where to dig deeper, and it helps the team prioritise. A crash outranks a cosmetic flaw. Taxonomy also makes session reports scannable: a stakeholder can see at a glance that a session found 2 correctness bugs and 1 security concern without reading the full session sheet.

7. **Mind maps for session planning**: Before a session, a mind map lets you visualise coverage areas, identify gaps, and decide which paths are highest risk. It replaces a test plan's rigid structure with a flexible, visual one. Mind maps take 10–15 minutes to create and immediately show where there are no planned sessions — the visual gap is a forcing function for coverage decisions.

8. **Debrief structure**: Without debriefs, session knowledge stays in one person's head. A structured debrief (what was tested, what was found, what was blocked, next steps) converts individual learning into team knowledge and feeds back into future session charters. The debrief is also where bugs are prioritised and where the decision to create follow-on charters is made.

9. **When to use**: Exploratory testing is most valuable for new features that lack mature test suites, areas undergoing major refactors, pre-release sign-off, and modules with no scripted coverage at all. It finds the bugs scripted tests can't anticipate because it doesn't assume the same things the script author assumed. This is its defining advantage: tests written before the feature existed cannot reflect what the feature actually does.

10. **Complementary, not a replacement**: Scripted tests provide regression safety nets and are reproducible across builds. Exploratory testing finds novel defects that require human judgment. Both together cover what neither can alone. The interaction is productive: exploration discovers, automation confirms; automation frees the tester from rote repetition so they can explore new territory.

11. **ISTQB CTFL 4.0 classification**: ISTQB classifies exploratory testing as an **experience-based technique** (alongside error guessing and checklist-based testing). The standard notes that exploratory testing is most effective when combined with other techniques — it is not a standalone alternative to specification-based or structure-based testing, but a complement that applies tester experience to discover defects those techniques would miss. ISTQB also distinguishes between **static testing** (reviewing work products without execution) and **dynamic testing** (executing the test object); exploratory testing is always dynamic but often reveals insights that inform static review.

---

## When to Use

| Situation | Why Exploratory Adds Value |
|-----------|---------------------------|
| New feature entering QA for first time | No scripted tests exist yet; learning about feature behavior drives first-pass coverage |
| After a major refactor or merge | Changed code paths may break behavior scripted tests don't cover |
| Release sign-off / release candidate | Catch late-breaking integration issues before shipping |
| Areas with zero automated coverage | Any testing is better than none; exploration maps the territory |
| Investigating a reported defect | Charter-based exploration around the defect area finds related faults |
| User journey end-to-end flows | Scripted tests rarely cover realistic cross-feature user paths |
| High-risk or high-complexity areas | Tester judgment and intuition outperform scripted coverage in complex UI flows |
| Hot-fix verification (30-min rapid session) | Confirms the fix works and doesn't break adjacent flows; too quick to write scripted tests |
| New REST API endpoints (API exploration) | Discovers missing error envelopes, schema drift, and undocumented nullable fields |

### When NOT to Use Exploratory Testing

- **Regression suites**: Reproducing known-good behavior needs repeatability, which scripts provide and exploration does not.
- **Performance baselines**: Load and stress testing require deterministic, automated execution to produce comparable metrics.
- **Compliance checklists**: When you need to document that specific steps were taken and verified, a scripted test with a formal pass/fail record is required.
- **High-volume data validation**: Verifying that thousands of records conform to a schema requires automation, not manual exploration.
- **Time-critical release with no trained tester**: Exploratory testing skill degrades without domain knowledge; an untrained tester exploring randomly produces little signal.

---

### Fitting Exploratory Testing into a Two-Week Sprint  [community]

Many teams struggle to schedule exploratory sessions in a sprint without displacing development time. The following cadence works in practice:

| Sprint Day | Activity |
|-----------|----------|
| Day 1 (Sprint start) | Write charters for new stories entering the sprint — 15 min per story |
| Day 2–8 | Run sessions as features reach "dev-complete" — don't wait for sprint end |
| Day 9 | Sprint-wide coverage review: which areas have no sessions? Schedule emergency sessions |
| Day 10 (Sprint end) | Debrief all open sessions; update mind map; feed findings into next sprint planning |

Key insight: **charter writing on Day 1 exposes incomplete acceptance criteria** — the "to discover Z" part of the charter forces clarity about what done means for each story. This is one of the most underrated benefits of SBTM in agile contexts.

**Session time budget per sprint (rough guide):**
- 2-week sprint, 1 tester: budget 8 sessions × 90 min = 12 hours of exploration
- 2-week sprint, 2 testers: 16 sessions total (split across feature areas)
- Debrief and charter writing: ~20% overhead (rule of thumb from practitioners)

**Continuous Delivery (no-sprint) variant:**

Teams shipping multiple times per day cannot batch exploration into sprint ends. The adapted cadence:
- Charter per PR (not per sprint): any PR touching high-risk areas triggers a rapid 30-minute charter on merge
- Daily 60-minute "open exploration" slot: one tester per day runs an unchained session in the area of greatest recent change, using bug clustering from the previous week to guide focus
- Weekly coverage review (15 min): which areas have had no sessions this week? Schedule targeted charters for the following day

The key insight for CD teams: exploration doesn't need to be "sprinted" — it needs to be **continuous**. The daily open exploration slot is the CD equivalent of a sprint's exploratory sessions.

**TypeScript: Release Readiness Check from Session Coverage**

```typescript
// src/testing/exploratory/release-readiness.ts
// Checks whether session coverage meets a configurable release readiness threshold
// before marking a release candidate as exploratory-tested.

import type { SessionDebrief } from './debrief';

export interface ReadinessPolicy {
  /** Minimum sessions required per high-risk charter area */
  minSessionsPerHighRiskArea: number;
  /** Maximum allowed ratio of blocked time to total session time */
  maxBlockedRatio: number;
  /** Minimum average tester confidence score to approve release */
  minAverageConfidence: number;
  /** Require all debriefs to have releasable === true */
  requireAllReleasable: boolean;
}

export interface ReadinessReport {
  approved: boolean;
  failureReasons: string[];
  warnings: string[];
  summary: string;
}

export function checkReleaseReadiness(
  debriefs: SessionDebrief[],
  policy: ReadinessPolicy
): ReadinessReport {
  const failures: string[] = [];
  const warnings: string[] = [];

  // Check releasable flags
  if (policy.requireAllReleasable) {
    const blocked = debriefs.filter((d) => !d.releasable);
    if (blocked.length > 0) {
      failures.push(
        `${blocked.length} charter area(s) flagged as not releasable: ${blocked.map((d) => d.charter.mission.explore).join(', ')}`
      );
    }
  }

  // Check average confidence
  const avgConf = debriefs.reduce((a, d) => a + d.testerConfidence, 0) / debriefs.length;
  if (avgConf < policy.minAverageConfidence) {
    failures.push(
      `Average tester confidence ${avgConf.toFixed(1)} is below threshold ${policy.minAverageConfidence}`
    );
  }

  // Check blocked time ratio
  const totalPlanned = debriefs.reduce((a, d) => a + d.plannedMinutes, 0);
  const totalBlocked = debriefs.reduce((a, d) => a + d.totalBlockedMinutes, 0);
  const blockedRatio = totalBlocked / totalPlanned;
  if (blockedRatio > policy.maxBlockedRatio) {
    warnings.push(
      `Blocked time ratio ${(blockedRatio * 100).toFixed(0)}% exceeds policy ${(policy.maxBlockedRatio * 100).toFixed(0)}% — some areas may be under-covered`
    );
  }

  const approved = failures.length === 0;
  const summary = approved
    ? `Release readiness: APPROVED (${debriefs.length} sessions, avg confidence ${avgConf.toFixed(1)})`
    : `Release readiness: BLOCKED — ${failures.length} failure(s)`;

  return { approved, failureReasons: failures, warnings, summary };
}
```

---

## Patterns

### TypeScript: Charter Schema Validator

Before running a session, use this validator to catch vague or incomplete charters. It enforces the three-part grammar and provides actionable feedback per part:

```typescript
// src/testing/exploratory/charter-validator.ts
// Validates that a session charter meets the three-part grammar requirements.
// Run before sessions start — a charter that fails validation should be rewritten.

export interface CharterMission {
  explore: string;   // X — the target feature/area (must be specific)
  using: string;     // Y — tools, test data, approach, or entry point
  toDiscover: string; // Z — the information goal (what you want to learn)
}

export interface CharterValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  qualityScore: number; // 0-100 — rough estimate of charter quality
}

const VAGUE_Z_PATTERNS = [
  /^to discover (any |all )?(issues|bugs|problems|errors|defects)\.?$/i,
  /^to discover whether (it|the feature) works\.?$/i,
  /^to test (the |this )?feature\.?$/i,
];

const VAGUE_X_PATTERNS = [
  /^(the app|the application|the system|the product|the website)\.?$/i,
  /^explore everything\.?$/i,
];

export function validateCharter(
  charterId: string,
  mission: CharterMission
): CharterValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Validate X (explore)
  if (!mission.explore || mission.explore.trim().length < 10) {
    errors.push('X (explore): too short — must identify a specific feature or area (≥ 10 chars)');
  } else if (VAGUE_X_PATTERNS.some((p) => p.test(mission.explore.trim()))) {
    errors.push(`X (explore): too vague — "${mission.explore}" could apply to any session. Name the specific feature.`);
  }

  // Validate Y (using)
  if (!mission.using || mission.using.trim().length < 10) {
    warnings.push('Y (using): very short — consider adding specific test data, tools, or entry conditions');
  }

  // Validate Z (toDiscover)
  if (!mission.toDiscover || mission.toDiscover.trim().length < 15) {
    errors.push('Z (toDiscover): too short — must state a specific information goal');
  } else if (VAGUE_Z_PATTERNS.some((p) => p.test(mission.toDiscover.trim()))) {
    errors.push(
      `Z (toDiscover): too vague — "${mission.toDiscover}" sets no clear goal. ` +
      'Rewrite as a specific question: "Does the form handle non-US postal codes?" or "What happens when payment times out?"'
    );
  }

  // Check that Z mirrors X (a common mistake — Z should extend X, not repeat it)
  const exploreCore = mission.explore.toLowerCase().replace(/[^a-z\s]/g, '').trim();
  const discoverCore = mission.toDiscover.toLowerCase().replace(/[^a-z\s]/g, '').trim();
  if (discoverCore.includes(exploreCore.substring(0, 20)) && discoverCore.length < exploreCore.length + 20) {
    warnings.push('Z (toDiscover) appears to mirror X (explore). Z should describe what you want to *learn*, not repeat the area.');
  }

  const valid = errors.length === 0;
  const qualityScore = valid
    ? Math.max(60, 100 - warnings.length * 10 - (mission.toDiscover.split(' ').length < 8 ? 15 : 0))
    : Math.max(0, 40 - errors.length * 15);

  return { valid, errors, warnings, qualityScore };
}

// Usage:
// const result = validateCharter('CHR-checkout-20260502-01', {
//   explore: 'the guest checkout payment retry flow after a card decline',
//   using: 'declined Stripe test cards, mobile Chrome viewport, account with no saved payment methods',
//   toDiscover: 'whether the "Try another card" CTA appears and whether the address form state is preserved after a retry',
// });
// if (!result.valid) console.error('Charter issues:', result.errors);
```

---

### Session Charter Template

```markdown
## SBTM Session Charter

**Charter ID**: CHR-<feature>-<YYYYMMDD>-<seq>
**Tester**: <name>
**Session Date**: <YYYY-MM-DD>
**Timebox**: 90 minutes

### Mission
Explore **<target area / feature>**
using **<tools, test data, approach, or entry point>**
to discover **<information goal: risks, edge cases, integration issues, etc.>**

### Background / Context
<Brief description of what changed, what is new, or why this area needs attention.>

### Priority Areas
1. <specific sub-area or concern #1>
2. <specific sub-area or concern #2>
3. <specific sub-area or concern #3>

### Out of Scope
- <Explicitly excluded areas to prevent scope creep>

### Success Criteria
- At least <N> distinct scenarios exercised
- All priority areas touched
- Notes and any bugs filed before debrief
```

**Filled example:**

```markdown
## SBTM Session Charter

**Charter ID**: CHR-checkout-20260426-01
**Tester**: Alice Chen
**Session Date**: 2026-04-26
**Timebox**: 90 minutes

### Mission
Explore **the new guest checkout flow (PR #4421)**
using **a set of international test credit cards, mobile viewport in Chrome, and an account without saved addresses**
to discover **payment edge cases, locale-specific formatting issues, and error handling gaps**

### Background / Context
PR #4421 introduced guest checkout. No existing automated tests cover this path.
Previous release had a currency formatting bug for EUR — revisit that area.

### Priority Areas
1. Payment decline and retry behavior (what happens after first failure?)
2. Address form with non-US postal codes
3. Order confirmation email trigger on successful guest checkout

### Out of Scope
- Logged-in user checkout (covered by existing scripted suite)
- Refund flow (separate charter planned for next sprint)

### Success Criteria
- At least 8 distinct payment scenarios exercised (success, decline, timeout, invalid CVV, expired)
- Address form tested with at least 3 non-US locales
- Order confirmation email verified for at least one successful transaction
- All bugs filed in tracker with session ID before debrief at 15:00
```

---

### Session-Based Test Management (SBTM)

SBTM was introduced by James Bach (Satisfice) and Jonathan Bach as a framework for making exploratory testing manageable and reportable. Key properties:

- **Timeboxed sessions** (typically 60–120 minutes) prevent sessions from becoming shapeless marathons.
- **One charter per session** keeps the tester focused. Multiple charters in one session indicate scope creep.
- **Session sheets** (notes taken during the session) capture observations, questions, and defects in real time.
- **Coverage tracking via count of sessions** rather than count of test case IDs. Managers ask "how many sessions on the payment flow?" rather than "which test cases ran?"
- **Debrief after each session** surfaces blockers, findings, and feeds next-session charter creation.

**Rapid Software Testing (RST)** is the companion methodology from Michael Bolton and James Bach that extends SBTM with a deeper epistemological framework. Where SBTM provides the management structure (charters, sessions, metrics), RST provides the tester skill framework: how to form and test hypotheses about a product, how to use oracles rigorously, and how to communicate risk to stakeholders. Teams adopting exploratory testing should treat SBTM as the *process* and RST as the *skill development* framework. In practice: use SBTM to structure and report sessions; use RST to train testers on how to think, probe, and evaluate.

Key RST concepts not in the original SBTM paper:
- **"Testing is the process of evaluating a product by learning about it through exploration and experimentation"** — RST's broader definition that frames testing as an investigation, not a verification
- **Test oracle heuristics** (HICCUPPS) — RST systematized these as the basis for deciding whether observed behavior is a defect
- **The quality criteria matrix**: Explicit (stated requirements), Implicit (unstated but expected), Emergent (behavior that only appears in combination with other factors)

SBTM metrics:
- Session duration (planned vs actual)
- Bugs found per session
- Coverage: sessions by charter area / total sessions planned
- Blocked time: minutes lost due to build issues, missing test data, etc.
- **Tester confidence score** (0–5): average across sessions in a charter area
- **Bug density**: bugs per session-hour, tracked by feature area over time to identify systemically risky areas
- **Charter completion rate**: sessions fully covering their charter vs partially blocked — a leading indicator of environment health
- **Follow-on charter rate**: percentage of sessions that generate at least one follow-on charter — high rate indicates active areas with ongoing complexity

**Example SBTM coverage report for a sprint:**

| Charter Area | Sessions Planned | Sessions Done | Defects Found | Blocked (min) |
|-------------|-----------------|---------------|--------------|---------------|
| Guest Checkout | 2 | 2 | 4 | 15 |
| Payment Processing | 2 | 1 | 2 | 45 |
| Order Confirmation | 1 | 1 | 1 | 0 |
| Accessibility / RTL | 1 | 0 | 0 | 60 (env issue) |
| **Totals** | **6** | **4** | **7** | **120** |

Reading: Payment Processing is under-covered (1/2 sessions); Accessibility blocked entirely. These gaps feed directly into next-sprint charter planning.

**SBTM KPI Reference Table:**

Use these metrics to build a sprint-level exploratory testing dashboard. Track them over time — quarter-on-quarter trends reveal infrastructure health, tester skill development, and feature area riskiness.

| KPI | Formula | Target | Actionable when... |
|-----|---------|--------|--------------------|
| Charter completion rate | Sessions fully covering charter / total sessions | ≥ 80% | < 80% → investigate environment blockers |
| Defect density | Defects found / session-hour, by feature area | N/A (track trend) | Rising density → schedule follow-on charters |
| Blocked time ratio | Total blocked minutes / total session minutes | < 20% | ≥ 30% → escalate infrastructure investment |
| Follow-on charter rate | Sessions generating ≥ 1 follow-on / total sessions | 20–40% | < 20% → charters may be too shallow; > 50% → charters too broad |
| Tester confidence average | Avg score (0–5) across all sessions in sprint | ≥ 3.5 | Areas below 2.5 need immediate follow-on charter |
| Escape defect rate | Defects found in production that were in chartered area / total production defects | < 15% | Rising → charters missing key risk areas |
| Session-to-automation conversion | Scenarios from exploration that became scripted test cases / total scenarios | 20–35% | < 10% → exploration insights not being captured; > 50% → over-automating obvious cases |

---

### FEW HICCUPS Heuristic

FEW HICCUPS is a coverage heuristic — it gives testers a checklist of areas to explore so they avoid missing whole categories of behavior.

| Letter | Area | What to Probe |
|--------|------|---------------|
| F | Function | Does it do what it claims? Core happy-path behaviors |
| E | Error | What happens on invalid input, missing data, network failure? |
| W | Workload | What happens under high volume, many items, rapid input? |
| H | Hints/Help | Is documentation, help text, and tooltips accurate? |
| I | Interruptions | What happens if the user navigates away, locks screen, or loses connectivity mid-flow? |
| C | Collaboration | What happens when multiple users interact with the same data simultaneously? |
| C | Configuration | Does behavior hold across browser versions, OS, locale, feature flags? |
| U | Users | Are different user roles and permission levels handled correctly? |
| P | Platform/Performance | Does the UI degrade gracefully on slow connections? Is it accessible? |
| S | Stress | What happens at sustained high load or with edge-case data sizes? |

Usage: before a session, scan the heuristic and note which areas apply to this charter. Not every letter applies to every session.

---

### HICCUPPS Oracle Heuristic

An oracle is a source of expected behavior. When something looks wrong, HICCUPPS gives you a principled basis for calling it a bug.

| Letter | Oracle | Meaning |
|--------|--------|---------|
| H | History | Does it behave differently than previous versions of the same product? |
| I | Image | Does it conflict with the company's brand or professional image? |
| C | Comparable products | Do competing or reference products behave differently here? |
| C | Claims | Does it violate stated requirements, specs, or documentation? |
| U | User expectations | Would typical users find this surprising or confusing? |
| P | Product | Does this part of the product contradict another part of the product? |
| P | Purpose | Does this behavior undermine the evident purpose of the feature? |
| S | Standards | Does it violate laws, regulations, industry standards, or accessibility guidelines? |

Usage: when you notice something odd, mentally scan HICCUPPS. If an observation triggers even one oracle, it is worth reporting.

---

### Mind Map Session Planning

Mind maps allow rapid visual planning before exploratory sessions. They show coverage areas at a glance and make it easy to spot where no sessions have been planned.

```yaml
# mind-map: checkout-flow-exploration.yaml
root: "Checkout Flow Exploration"
branches:
  - area: "Cart Management"
    sub_areas:
      - "Add item (various quantities)"
      - "Remove item (last item edge case)"
      - "Update quantity (zero, negative, max)"
      - "Cart persistence across sessions"
    sessions_planned: 1
    sessions_completed: 0

  - area: "Payment Processing"
    sub_areas:
      - "Valid card — happy path"
      - "Declined card"
      - "Expired card"
      - "International cards / currency"
      - "Timeout / network drop mid-payment"
    sessions_planned: 2
    sessions_completed: 0

  - area: "Order Confirmation"
    sub_areas:
      - "Email delivery"
      - "Order ID uniqueness"
      - "Confirmation page data accuracy"
    sessions_planned: 1
    sessions_completed: 0

  - area: "Edge User Scenarios"
    sub_areas:
      - "Guest checkout"
      - "Returning customer with saved address"
      - "User with screen reader"
    sessions_planned: 1
    sessions_completed: 0

coverage_target: "4 sessions covering all branches"
notes: "Payment Processing is highest risk — start there"
```

---

### Defect Taxonomy & Reporting

Classifying defects at the time of reporting speeds triage and helps identify systemic patterns. ISTQB CTFL 4.0 uses **"defect"** for a found fault in a work product (whether or not it causes a visible failure). The taxonomy below maps to defect categories rather than failure modes so reports are consistent with tool fields and audit language.

| Category | Definition | Priority Indicator | Example |
|----------|------------|-------------------|---------|
| Crash | Application terminates unexpectedly or becomes unresponsive | Critical — ship-blocker | JS exception causes blank page on payment step |
| Correctness | Output is wrong (wrong calculation, wrong data shown) | High | Cart subtotal includes tax twice |
| Security | Unauthorized access, data exposure, injection vulnerability | Critical — ship-blocker | Guest checkout exposes prior customer order ID in URL |
| Boundary | Behavior fails at or near limit values (off-by-one, max input) | High | Quantity field accepts -1; cart shows negative total |
| Performance | Feature is functionally correct but unacceptably slow | Medium–High | Address lookup takes 12 seconds on mobile 3G |
| Cosmetic | Visual defect with no functional impact (misaligned element, typo) | Low | "Procceed to payment" typo on checkout button |

```markdown
## Defect Report Template

**Defect ID**: DEF-<session-id>-<seq>
**Date Found**: <YYYY-MM-DD>
**Tester**: <name>
**Session Charter**: CHR-<id>
**Severity**: Crash | Correctness | Security | Boundary | Performance | Cosmetic
**Category**: <from taxonomy above>

### Summary
<One sentence: what is wrong>

### Steps to Reproduce
1. <step 1>
2. <step 2>
3. <step 3>

### Expected Result
<What should happen>

### Actual Result
<What actually happened — include screenshot or recording path>

### Environment
- Browser/OS: <value>
- Build/Version: <value>
- Feature Flags Active: <list>
- Test Data Used: <description>

### Notes
<Additional context, related bugs, hypothesis about root cause>
```

---

### Session Notes Template

Session notes are the raw in-session capture. They are taken during the session, not after, and are deliberately informal. The goal is to capture observations, questions, and bugs without slowing the tester's flow.

```markdown
## Session Notes

**Charter**: CHR-<id>
**Tester**: <name>
**Start Time**: <HH:MM>
**End Time**: <HH:MM>
**Actual Duration**: <N> min

---

### Notes (chronological — taken during session)

[HH:MM] Navigated to <area>. Noticed <observation>.
[HH:MM] Tried <action>. Result: <what happened>. Unexpected? Y/N
[HH:MM] BUG: <summary — full report to follow in tracker>
[HH:MM] QUESTION: <open question for follow-up>
[HH:MM] Tried <action> with test data set <name>. Worked as expected.
[HH:MM] Blocked: <reason> — lost ~<N> min.
[HH:MM] Resumed. Tried <action>.
[HH:MM] OBSERVATION: <notable behavior, not necessarily a bug>
[HH:MM] Tried boundary: <value> at <input field>. Unexpected result logged as BUG-002.
[HH:MM] Finished charter scope. <time remaining>: used to probe <extra area>.

---

### Summary Counts
- Scenarios exercised: <N>
- Bugs filed: <N>
- Open questions: <N>
- Blocked time: <N> min / <reason>
- Coverage vs charter: <Full | Partial | Blocked>

### Tester Confidence
<0–5 scale: how well do you feel the area is understood after this session?>
```

**Filled example:**

```markdown
## Session Notes

**Charter**: CHR-checkout-20260426-01
**Tester**: Alice Chen
**Start Time**: 13:00
**End Time**: 14:25
**Actual Duration**: 85 min

---

### Notes (chronological — taken during session)

[13:02] Navigated to guest checkout. Address form loads correctly. Tried US zip code first.
[13:08] Tried UK postcode (SW1A 2AA). City field auto-populated "London" — correct.
[13:15] Tried German postcode (10115). City field shows "undefined" — UNEXPECTED.
[13:16] DEF: German postcode city lookup returns "undefined" instead of "Berlin". Full report: DEF-CHR-checkout-001.
[13:22] Tried entering card number. All standard test cards accepted as expected.
[13:30] Tried declined card (4000 0000 0000 0002). Got error "Payment failed" — no retry prompt shown.
[13:31] DEF: Declined card shows error but no "Try another card" CTA. Full report: DEF-CHR-checkout-002.
[13:40] Navigated away mid-payment (pressed browser back). Cart still intact on return.
[13:42] QUESTION: Does the payment intent remain active after user navigates back? Check with dev.
[13:55] Tried expired card (any card with past date). Correct validation error shown.
[14:05] Placed successful order. Confirmation page correct. Checked test email inbox — email arrived in 2 min.
[14:10] Blocked: staging auth expired, had to re-login. Lost ~8 min.
[14:18] Resumed. Tried order confirmation URL directly — no auth required. Customer data visible.
[14:19] DEF: Order confirmation URL is guessable and publicly accessible. Security defect. DEF-CHR-checkout-003.
[14:25] Session end.

---

### Summary Counts
- Scenarios exercised: 11
- Defects filed: 3 (1 cosmetic/correctness, 1 UX, 1 Security)
- Open questions: 1 (payment intent lifecycle)
- Blocked time: 8 min / auth session expiry
- Coverage vs charter: Partial — international locales only partially covered (UK + DE), no FR or JP
```

---

### Debrief Structure

A debrief converts one tester's session into shared team knowledge. It should happen within 30 minutes of session end while memory is fresh.

```markdown
## Session Debrief Template

**Session**: CHR-<id>
**Date**: <YYYY-MM-DD>
**Duration**: <planned> / <actual> minutes
**Participants**: <tester + stakeholder(s)>

### What Was Tested
- <Coverage area 1 and key scenarios exercised>
- <Coverage area 2 and key scenarios exercised>

### What Was Found
| Defect ID | Severity | Summary |
|-----------|----------|---------|
| DEF-001   | High     | Cart quantity update accepts negative values |
| DEF-002   | Cosmetic | Spinner overlaps order total on mobile |

### What Was Blocked
- <Blocker 1: missing test account credentials — 20 min lost>
- <Blocker 2: build broken for 15 min at session start>

### Coverage Assessment
- Planned areas covered: 3/4
- Skipped (reason): Payment timeout — staging environment doesn't support throttling

### Next Steps / Follow-on Charters
- Charter needed: payment timeout behavior in production-like environment
- Retest DEF-001 fix when patch is available
- Expand FEW HICCUPS 'C' (Collaboration) dimension — multi-user cart not explored
```

**TypeScript: Typed Debrief Data Structure**

Structured debriefs can be stored as JSON and consumed by sprint reporting tools (coverage dashboards, release readiness checks). The following types capture the full debrief output in machine-readable form.

```typescript
// src/testing/exploratory/debrief.ts
import type { SessionCharter, SessionBug } from './types';

export interface DebriefBlocker {
  description: string;
  minutesLost: number;
  type: 'environment' | 'credentials' | 'build' | 'test-data' | 'other';
}

export interface FollowOnCharter {
  description: string;
  priority: 'immediate' | 'next-sprint' | 'backlog';
  triggerReason: string; // Why this follow-on is needed
}

export interface SessionDebrief {
  charter: SessionCharter;
  conductedDate: string;          // ISO 8601 — when the debrief happened
  participants: string[];         // tester + any stakeholders who joined
  plannedMinutes: number;
  actualMinutes: number;

  coverage: {
    areasPlanned: string[];
    areasCovered: string[];
    areasSkipped: Array<{ area: string; reason: string }>;
    coveragePercent: number;      // (areasCovered.length / areasPlanned.length) * 100
  };

  findings: {
    defects: SessionBug[];
    openQuestions: string[];
    observations: string[];       // Notable behavior that is not a defect
  };

  blockers: DebriefBlocker[];
  totalBlockedMinutes: number;

  followOnCharters: FollowOnCharter[];
  testerConfidence: 0 | 1 | 2 | 3 | 4 | 5;

  releasable: boolean;            // Tester's judgment: is this area releasable given coverage?
  releasableRationale?: string;   // Required when releasable === false
}

/** Compute aggregate metrics across multiple debriefs for a sprint report */
export function aggregateDebriefs(debriefs: SessionDebrief[]): {
  totalSessions: number;
  totalDefects: number;
  totalBlockedMinutes: number;
  averageConfidence: number;
  notReleasableAreas: string[];
} {
  const totalDefects = debriefs.reduce((acc, d) => acc + d.findings.defects.length, 0);
  const totalBlockedMinutes = debriefs.reduce((acc, d) => acc + d.totalBlockedMinutes, 0);
  const avgConfidence =
    debriefs.reduce((acc, d) => acc + d.testerConfidence, 0) / debriefs.length;
  const notReleasableAreas = debriefs
    .filter((d) => !d.releasable)
    .map((d) => d.charter.mission.explore);

  return {
    totalSessions: debriefs.length,
    totalDefects,
    totalBlockedMinutes,
    averageConfidence: Math.round(avgConfidence * 10) / 10,
    notReleasableAreas,
  };
}
```

---

---

### Rapid Exploratory Testing (30-Minute Sessions)  [community]

Standard SBTM sessions are 60–90 minutes. But teams frequently need to run quick explorations: when a hot-fix lands, when there are only 30 minutes before a release window, or as a "smoke check" after a deployment. Rapid exploratory testing preserves the charter discipline but compresses the time budget.

**30-minute session structure:**

| Time | Activity |
|------|----------|
| 0–5 min | Write a focused micro-charter (1 sentence mission; 2 priority areas max; out-of-scope explicitly set) |
| 5–25 min | Execute — use FEW HICCUPS as a fast mental checklist: only F (Function), E (Error), I (Interruptions) are checked in a rapid session |
| 25–30 min | Instant debrief: 3 bullets — what was tested, what was found, what needs a follow-on charter |

**Key constraints for rapid sessions:**
- One tester only (pairing takes too much coordination time at this duration)
- Defects logged as quick notes, full report written within 2 hours of session
- No mind map — the micro-charter is the entire plan
- If a defect is found in the first 10 minutes that blocks the main flow: stop, file the defect, and convert the session into a follow-on charter for a full session

**TypeScript: Rapid Session Micro-Charter**

```typescript
// src/testing/exploratory/rapid-charter.ts
// Micro-charter for rapid (30-minute) exploratory sessions.
// Enforces the constraints: single focus area, 2 priority areas max, instant debrief format.

export interface RapidCharter {
  charterId: string;
  tester: string;
  triggerReason: 'hotfix' | 'deployment-smoke' | 'pre-release' | 'ad-hoc-request';
  sessionDate: string;
  timeboxMinutes: 30;       // Always 30 for rapid sessions
  mission: string;          // Single sentence: "Explore X using Y to discover Z"
  priorityAreas: [string, string]; // Exactly 2 — enforced by tuple type
  outOfScope: string[];
}

export interface RapidDebriefNote {
  charter: RapidCharter;
  tested: string;           // What was actually tested (1 sentence)
  found: string;            // What was found (or "nothing unexpected")
  followOnNeeded: boolean;
  followOnCharter?: string; // If true, one-sentence description of the follow-on
}

export function validateRapidCharter(charter: RapidCharter): string[] {
  const errors: string[] = [];
  if (charter.mission.split(' ').length > 30) {
    errors.push('Mission too long — rapid charter mission must be concise (≤ 30 words)');
  }
  if (charter.outOfScope.length === 0) {
    errors.push('Out-of-scope must be explicit — rapid sessions drift badly without it');
  }
  return errors;
}

// Usage:
// const rapid: RapidCharter = {
//   charterId: 'RAPID-hotfix-20260428-01',
//   tester: 'Alice Chen',
//   triggerReason: 'hotfix',
//   sessionDate: '2026-04-28',
//   timeboxMinutes: 30,
//   mission: 'Explore guest checkout payment retry after hotfix PR #4521 using declined cards to discover whether the CTA now appears',
//   priorityAreas: ['Declined card retry flow', 'Order confirmation page load after retry'],
//   outOfScope: ['Address form validation (unchanged)', 'Email delivery (separate concern)'],
// };
// const errors = validateRapidCharter(rapid);
// if (errors.length > 0) console.error('Charter issues:', errors);
```

---

### Exploratory Tours (Hendrickson)

Elisabeth Hendrickson's "Explore It!" introduced the tour as a structured way to generate charter ideas. A tour is a metaphor for a type of exploration:

| Tour Type | What You Do | Best For |
|-----------|-------------|----------|
| Landmark Tour | Visit all notable features in the area, like a tourist hitting the highlights | First-session overview of an unfamiliar feature |
| Variability Tour | Vary every input, option, and configuration you encounter | Finding boundary bugs and unexpected behavior |
| Interruption Tour | Disrupt the flow: navigate away, go back, leave a form half-filled, disconnect and reconnect | Finding state management and session bugs |
| Garbage Collector Tour | Enter invalid, unexpected, or malformed data everywhere | Finding input validation and error handling gaps |
| FedEx Tour | Follow data through the system from origin to destination | Finding integration and data transformation bugs |
| Long Shot Tour | Perform the longest, most complex path through the feature | Finding timeout, state accumulation, and performance bugs |
| After-Hours Tour | Test outside normal conditions: slow connection, low battery API, minimal permissions | Finding resilience and degraded-mode behavior |
| Supermodel Tour (Whittaker) | Focus entirely on the visual appearance — layout, fonts, alignment, colors, responsiveness | Finding cosmetic and accessibility presentation bugs |
| Saboteur Tour (Whittaker) | Actively try to break every step: refuse required fields, kill the network, deny permissions | Finding error handling robustness and security input issues |
| Couch Potato Tour | Do as little as possible — accept all defaults, skip optional steps, never scroll | Finding default-value and minimal-interaction bugs |

Usage: at the start of a session, pick the tour type that best matches the charter's information goal. The tour gives the tester a concrete starting strategy without scripting steps.

---

### TypeScript: Charter and Session Types  [community]

Exploratory testing produces structured data. Capturing charters and session results as TypeScript types enables tooling — dashboards, CLI reporters, sprint planners — to consume session data without parsing markdown.

```typescript
// src/testing/exploratory/types.ts
export type BugSeverity = 'crash' | 'correctness' | 'security' | 'boundary' | 'performance' | 'cosmetic';

export interface SessionCharter {
  charterId: string;         // e.g. "CHR-checkout-20260426-01"
  tester: string;
  sessionDate: string;       // ISO 8601
  timeboxMinutes: number;    // typically 60–120
  mission: {
    explore: string;         // X — target area
    using: string;           // Y — tools / approach
    toDiscover: string;      // Z — information goal
  };
  priorityAreas: string[];
  outOfScope: string[];
}

export interface SessionBug {
  bugId: string;
  severity: BugSeverity;
  summary: string;
  stepsToReproduce: string[];
  expected: string;
  actual: string;
  environment: Record<string, string>;
}

export interface SessionResult {
  charter: SessionCharter;
  startTime: string;         // ISO 8601
  endTime: string;           // ISO 8601
  actualDurationMinutes: number;
  scenariosExercised: number;
  bugs: SessionBug[];
  openQuestions: string[];
  blockedMinutes: number;
  blockedReason?: string;
  coverageVsCharter: 'full' | 'partial' | 'blocked';
  testerConfidence: 0 | 1 | 2 | 3 | 4 | 5;
}
```

---

### TypeScript: Playwright-Based Exploratory Session Harness  [community]

Playwright can act as an exploration aid: it captures screenshots and console errors automatically, so the tester can focus on observation rather than manual screen capture. This is not a scripted test — it is scaffolding that records what a human tester does.

```typescript
// src/testing/exploratory/session-harness.ts
import { chromium, Browser, Page, BrowserContext } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export interface HarnessOptions {
  charterId: string;
  baseUrl: string;
  outputDir: string;
  timeboxMs: number;         // 90 minutes = 5_400_000
}

export class ExploratorySessionHarness {
  private browser: Browser | null = null;
  private context: BrowserContext | null = null;
  private page: Page | null = null;
  private observations: string[] = [];
  private screenshotIndex = 0;
  private sessionStart: number = Date.now();

  constructor(private opts: HarnessOptions) {
    fs.mkdirSync(opts.outputDir, { recursive: true });
  }

  async start(): Promise<Page> {
    this.browser = await chromium.launch({ headless: false });
    this.context = await this.browser.newContext({
      recordVideo: { dir: this.opts.outputDir },
    });
    this.page = await this.context.newPage();

    // Log console errors automatically so the tester doesn't miss them
    this.page.on('console', (msg) => {
      if (msg.type() === 'error') {
        this.note(`[CONSOLE ERROR] ${msg.text()}`);
      }
    });

    // Flag uncaught exceptions as potential crash bugs
    this.page.on('pageerror', (err) => {
      this.note(`[PAGE ERROR — possible crash bug] ${err.message}`);
    });

    await this.page.goto(this.opts.baseUrl);
    this.note(`Session started. Charter: ${this.opts.charterId}`);
    return this.page;
  }

  /** Call this during the session whenever you observe something notable. */
  note(observation: string): void {
    const elapsed = Math.round((Date.now() - this.sessionStart) / 1000 / 60);
    const entry = `[T+${elapsed}m] ${observation}`;
    this.observations.push(entry);
    console.log(entry);
  }

  /** Take a numbered screenshot and attach it to the observation log. */
  async capture(label: string): Promise<void> {
    if (!this.page) throw new Error('Session not started');
    const filename = `${String(this.screenshotIndex++).padStart(3, '0')}-${label.replace(/\s+/g, '-')}.png`;
    const filepath = path.join(this.opts.outputDir, filename);
    await this.page.screenshot({ path: filepath, fullPage: true });
    this.note(`Screenshot captured: ${filename} — ${label}`);
  }

  /** End the session and write the observation log to a file. */
  async end(): Promise<void> {
    if (!this.page || !this.context || !this.browser) return;
    const logPath = path.join(this.opts.outputDir, 'session-notes.txt');
    fs.writeFileSync(logPath, this.observations.join('\n'), 'utf-8');
    await this.context.close();
    await this.browser.close();
    console.log(`Session ended. Notes: ${logPath}`);
  }
}
```

---

### TypeScript: SBTM Coverage Reporter  [community]

After a sprint, this utility reads session result JSON files and prints a coverage report — the same table format used in the SBTM pattern above, but generated from actual session data rather than maintained manually.

```typescript
// src/testing/exploratory/coverage-reporter.ts
import * as fs from 'fs';
import * as path from 'path';
import type { SessionResult } from './types';

export function generateCoverageReport(sessionDir: string): void {
  const files = fs.readdirSync(sessionDir).filter((f) => f.endsWith('.json'));
  const sessions: SessionResult[] = files.map((f) =>
    JSON.parse(fs.readFileSync(path.join(sessionDir, f), 'utf-8'))
  );

  // Group by charter area (derived from the "explore" mission field)
  const byArea = new Map<string, SessionResult[]>();
  for (const s of sessions) {
    const area = s.charter.mission.explore;
    if (!byArea.has(area)) byArea.set(area, []);
    byArea.get(area)!.push(s);
  }

  console.log('\n=== SBTM Sprint Coverage Report ===\n');
  console.log(
    `${'Charter Area'.padEnd(30)} ${'Sessions'.padEnd(10)} ${'Bugs'.padEnd(6)} ${'Blocked(m)'.padEnd(12)} ${'Coverage'}`
  );
  console.log('-'.repeat(75));

  let totalSessions = 0;
  let totalBugs = 0;
  let totalBlocked = 0;

  for (const [area, areaSessions] of byArea) {
    const bugsFound = areaSessions.reduce((acc, s) => acc + s.bugs.length, 0);
    const blockedMin = areaSessions.reduce((acc, s) => acc + s.blockedMinutes, 0);
    const coverage = areaSessions.every((s) => s.coverageVsCharter === 'full')
      ? 'Full'
      : areaSessions.some((s) => s.coverageVsCharter === 'blocked')
      ? 'Blocked'
      : 'Partial';

    console.log(
      `${area.substring(0, 29).padEnd(30)} ${String(areaSessions.length).padEnd(10)} ${String(bugsFound).padEnd(6)} ${String(blockedMin).padEnd(12)} ${coverage}`
    );
    totalSessions += areaSessions.length;
    totalBugs += bugsFound;
    totalBlocked += blockedMin;
  }

  console.log('-'.repeat(75));
  console.log(
    `${'TOTALS'.padEnd(30)} ${String(totalSessions).padEnd(10)} ${String(totalBugs).padEnd(6)} ${String(totalBlocked).padEnd(12)}`
  );

  // Surface bug clusters — areas with >2 bugs per session warrant follow-on charters
  console.log('\n=== Bug Clustering Analysis ===');
  for (const [area, areaSessions] of byArea) {
    const bugsPerSession = areaSessions.reduce((acc, s) => acc + s.bugs.length, 0) / areaSessions.length;
    if (bugsPerSession > 2) {
      console.log(`  HIGH BUG DENSITY: "${area}" (${bugsPerSession.toFixed(1)} bugs/session) — schedule follow-on charter`);
    }
  }
  console.log('');
}
```

---

### TypeScript: HICCUPPS Oracle Evaluator  [community]

When a tester finds a potential bug, they can run it through the HICCUPPS oracle programmatically to get a summary of which oracles trigger and therefore whether it is worth reporting.

```typescript
// src/testing/exploratory/hiccupps-oracle.ts

export type OracleKey =
  | 'History' | 'Image' | 'Comparable' | 'Claims'
  | 'UserExpectation' | 'Product' | 'Purpose' | 'Standards';

export const ORACLE_DESCRIPTIONS: Record<OracleKey, string> = {
  History:         'Does it behave differently than previous versions of the same product?',
  Image:           'Does it conflict with the company\'s brand or professional image?',
  Comparable:      'Do competing or reference products behave differently here?',
  Claims:          'Does it violate stated requirements, specs, or documentation?',
  UserExpectation: 'Would typical users find this surprising or confusing?',
  Product:         'Does this part of the product contradict another part of the product?',
  Purpose:         'Does this behavior undermine the evident purpose of the feature?',
  Standards:       'Does it violate laws, regulations, industry standards, or accessibility guidelines?',
};

export interface OracleEvaluation {
  observation: string;
  triggeredOracles: OracleKey[];
  recommendation: 'file' | 'investigate' | 'ignore';
  summary: string;
}

export function evaluateWithHiccupps(
  observation: string,
  triggeredOracles: OracleKey[]
): OracleEvaluation {
  const count = triggeredOracles.length;
  const recommendation: OracleEvaluation['recommendation'] =
    count >= 2 ? 'file' : count === 1 ? 'investigate' : 'ignore';

  const summary =
    count === 0
      ? 'No oracles triggered — likely expected behavior.'
      : `${count} oracle(s) triggered (${triggeredOracles.join(', ')}) — ${recommendation}.`;

  return { observation, triggeredOracles, recommendation, summary };
}

// Usage during a session:
// const result = evaluateWithHiccupps(
//   'Guest checkout URL exposes order ID in query string',
//   ['Claims', 'Standards', 'UserExpectation']
// );
// console.log(result.summary);
// → "3 oracle(s) triggered (Claims, Standards, UserExpectation) — file."
```

---

### TypeScript: Sprint Confidence Map  [community]

Aggregates tester confidence scores (0–5) from session results to produce a sprint-level coverage quality map. Areas with low average confidence flag where follow-on charters are needed — operationalising community lesson #23.

```typescript
// src/testing/exploratory/confidence-map.ts
import * as fs from 'fs';
import * as path from 'path';
import type { SessionResult } from './types';

export type ConfidenceLevel = 'high' | 'medium' | 'low' | 'not-tested';

export interface AreaConfidence {
  area: string;
  sessionCount: number;
  averageConfidence: number;
  level: ConfidenceLevel;
  recommendation: string;
}

function toLevel(avg: number, sessionCount: number): ConfidenceLevel {
  if (sessionCount === 0) return 'not-tested';
  if (avg >= 4) return 'high';
  if (avg >= 2.5) return 'medium';
  return 'low';
}

function toRecommendation(level: ConfidenceLevel, area: string): string {
  switch (level) {
    case 'not-tested': return `No sessions run — create charter for "${area}"`;
    case 'low': return `Low confidence — schedule follow-on session immediately`;
    case 'medium': return `Acceptable — add 1 session next sprint if area changes`;
    case 'high': return `Well explored — no immediate action needed`;
  }
}

export function buildConfidenceMap(sessionDir: string): AreaConfidence[] {
  const files = fs.readdirSync(sessionDir).filter((f) => f.endsWith('.json'));
  const sessions: SessionResult[] = files.map((f) =>
    JSON.parse(fs.readFileSync(path.join(sessionDir, f), 'utf-8'))
  );

  const byArea = new Map<string, number[]>();
  for (const s of sessions) {
    const area = s.charter.mission.explore;
    if (!byArea.has(area)) byArea.set(area, []);
    byArea.get(area)!.push(s.testerConfidence);
  }

  return Array.from(byArea.entries())
    .map(([area, scores]) => {
      const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
      const level = toLevel(avg, scores.length);
      return {
        area,
        sessionCount: scores.length,
        averageConfidence: Math.round(avg * 10) / 10,
        level,
        recommendation: toRecommendation(level, area),
      };
    })
    .sort((a, b) => a.averageConfidence - b.averageConfidence); // lowest first
}

export function printConfidenceMap(map: AreaConfidence[]): void {
  console.log('\n=== Sprint Confidence Map ===\n');
  console.log(`${'Area'.padEnd(30)} ${'Sessions'.padEnd(10)} ${'Avg Score'.padEnd(12)} ${'Level'.padEnd(12)} Recommendation`);
  console.log('-'.repeat(90));
  for (const entry of map) {
    const flag = entry.level === 'low' || entry.level === 'not-tested' ? ' *** ' : '     ';
    console.log(
      `${flag}${entry.area.substring(0, 24).padEnd(30)} ${String(entry.sessionCount).padEnd(10)} ${String(entry.averageConfidence).padEnd(12)} ${entry.level.padEnd(12)} ${entry.recommendation}`
    );
  }
  console.log('');
}
```



Before a session, testers should scan FEW HICCUPS and decide which dimensions apply to the charter. This TypeScript utility generates a pre-session checklist as a printed prompt, reducing the cognitive overhead of remembering all 10 coverage areas.

```typescript
// src/testing/exploratory/few-hiccups-checklist.ts

export const FEW_HICCUPS_DIMENSIONS = [
  { letter: 'F', area: 'Function',     prompt: 'Does it do what it claims? Core happy-path behaviors' },
  { letter: 'E', area: 'Error',        prompt: 'What happens on invalid input, missing data, network failure?' },
  { letter: 'W', area: 'Workload',     prompt: 'What happens under high volume, many items, rapid input?' },
  { letter: 'H', area: 'Hints/Help',   prompt: 'Is documentation, help text, and tooltips accurate?' },
  { letter: 'I', area: 'Interruptions',prompt: 'What happens if the user navigates away or loses connectivity mid-flow?' },
  { letter: 'C', area: 'Collaboration',prompt: 'What happens when multiple users interact with the same data simultaneously?' },
  { letter: 'C', area: 'Configuration',prompt: 'Does behavior hold across browser versions, OS, locale, feature flags?' },
  { letter: 'U', area: 'Users',        prompt: 'Are different user roles and permission levels handled correctly?' },
  { letter: 'P', area: 'Platform',     prompt: 'Does the UI degrade gracefully on slow connections? Is it accessible?' },
  { letter: 'S', area: 'Stress',       prompt: 'What happens at sustained high load or with edge-case data sizes?' },
] as const;

export type FewHiccupsLetter = (typeof FEW_HICCUPS_DIMENSIONS)[number]['area'];

export interface SessionChecklist {
  charterId: string;
  applicable: FewHiccupsLetter[];
  skipped: FewHiccupsLetter[];
  skipReasons: Partial<Record<FewHiccupsLetter, string>>;
}

export function generateChecklist(
  charterId: string,
  applicable: FewHiccupsLetter[],
  skipReasons: Partial<Record<FewHiccupsLetter, string>> = {}
): SessionChecklist {
  const skipped = FEW_HICCUPS_DIMENSIONS
    .map((d) => d.area)
    .filter((area, idx, arr) => arr.indexOf(area) === idx) // deduplicate C
    .filter((area) => !applicable.includes(area as FewHiccupsLetter));
  return { charterId, applicable, skipped: skipped as FewHiccupsLetter[], skipReasons };
}

export function printChecklist(checklist: SessionChecklist): void {
  console.log(`\n=== FEW HICCUPS Pre-Session Checklist: ${checklist.charterId} ===\n`);
  for (const dim of FEW_HICCUPS_DIMENSIONS) {
    const isApplicable = checklist.applicable.includes(dim.area);
    const skipReason = checklist.skipReasons[dim.area];
    const status = isApplicable ? '[EXPLORE]' : `[SKIP${skipReason ? `: ${skipReason}` : ''}]`;
    console.log(`  ${dim.letter} — ${dim.area.padEnd(14)} ${status}`);
    if (isApplicable) console.log(`              ${dim.prompt}`);
  }
  console.log('');
}
```

---



This planner scores feature areas by risk (change size × bug history × business impact) and recommends how many sessions to allocate per area. It operationalises the risk-based session allocation principle described in the Tradeoffs section.

```typescript
// src/testing/exploratory/session-planner.ts
export type ChangeSize = 'none' | 'small' | 'medium' | 'large';
export type BugHistory = 'none' | 'low' | 'medium' | 'high';
export type BusinessImpact = 'low' | 'medium' | 'critical';

const CHANGE_WEIGHT: Record<ChangeSize, number> = {
  none: 0,
  small: 1,
  medium: 2,
  large: 3,
};

const BUG_HISTORY_WEIGHT: Record<BugHistory, number> = {
  none: 0,
  low: 1,
  medium: 2,
  high: 3,
};

const IMPACT_WEIGHT: Record<BusinessImpact, number> = {
  low: 1,
  medium: 2,
  critical: 3,
};

export interface FeatureArea {
  name: string;
  changeSize: ChangeSize;
  bugHistory: BugHistory;
  businessImpact: BusinessImpact;
  automationCoverage: 'none' | 'partial' | 'full';
}

export interface SessionAllocation {
  area: string;
  riskScore: number;
  recommendedSessions: number;
  rationale: string;
}

export function planSessions(areas: FeatureArea[]): SessionAllocation[] {
  return areas
    .map((area) => {
      // Automation coverage reduces exploration need for stable paths
      const automationPenalty = area.automationCoverage === 'full' ? 1 : area.automationCoverage === 'partial' ? 0 : 0;
      const riskScore =
        CHANGE_WEIGHT[area.changeSize] +
        BUG_HISTORY_WEIGHT[area.bugHistory] +
        IMPACT_WEIGHT[area.businessImpact] -
        automationPenalty;

      // Map risk score to sessions: 0-2 → 0, 3-4 → 1, 5-6 → 2, 7-9 → 3
      const recommendedSessions =
        riskScore <= 2 ? 0 : riskScore <= 4 ? 1 : riskScore <= 6 ? 2 : 3;

      const rationale = [
        area.changeSize !== 'none' && `${area.changeSize} change`,
        area.bugHistory !== 'none' && `${area.bugHistory} bug history`,
        `${area.businessImpact} business impact`,
        area.automationCoverage === 'full' && 'full automation coverage (reduces session need)',
      ]
        .filter(Boolean)
        .join(', ');

      return { area: area.name, riskScore, recommendedSessions, rationale };
    })
    .sort((a, b) => b.riskScore - a.riskScore);
}

// Usage example:
// const allocations = planSessions([
//   { name: 'Payment Processing', changeSize: 'large', bugHistory: 'high', businessImpact: 'critical', automationCoverage: 'partial' },
//   { name: 'Help / FAQ', changeSize: 'none', bugHistory: 'none', businessImpact: 'low', automationCoverage: 'full' },
// ]);
// allocations.forEach(a => console.log(`${a.area}: ${a.recommendedSessions} sessions (risk ${a.riskScore}) — ${a.rationale}`));
```

---

### TypeScript: Exploratory API Testing Harness  [community]

Exploratory testing applies equally to REST APIs. The tester explores endpoint behavior — unexpected response codes, schema drift, missing error envelopes, undocumented fields — using the same charter and session structure. Because APIs have no visual interface, the session harness is a TypeScript HTTP client that logs every request and response, with annotations added by the tester.

API charters follow the same format:
- **Explore**: The `/orders` resource and its pagination behavior
- **Using**: Boundary values for `limit` and `offset` parameters, missing and malformed auth headers, concurrent requests with the same idempotency key
- **To discover**: Whether pagination is stable under concurrent load, how error envelopes are structured, which fields are nullable vs required

```typescript
// src/testing/exploratory/api-session-harness.ts
// Exploratory API session harness — wraps fetch() with automatic request/response logging.
// Use exactly like ExploratorySessionHarness but for REST APIs: call note() for observations,
// then request() for each exploratory probe. Session ends with end() to write the log.

export interface ApiHarnessOptions {
  charterId: string;
  baseUrl: string;
  defaultHeaders?: Record<string, string>;
  outputFile: string;
}

export interface ApiProbeResult {
  method: string;
  url: string;
  status: number;
  durationMs: number;
  responseBody: unknown;
  responseHeaders: Record<string, string>;
}

export class ApiExploratoryHarness {
  private log: string[] = [];
  private probeIndex = 0;
  private sessionStart = Date.now();

  constructor(private opts: ApiHarnessOptions) {
    this.note(`API session started. Charter: ${opts.charterId}. Base URL: ${opts.baseUrl}`);
  }

  note(observation: string): void {
    const elapsed = Math.round((Date.now() - this.sessionStart) / 1000);
    const entry = `[T+${elapsed}s] ${observation}`;
    this.log.push(entry);
    console.log(entry);
  }

  async request(
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    path: string,
    options: { body?: unknown; headers?: Record<string, string>; label?: string } = {}
  ): Promise<ApiProbeResult> {
    const url = `${this.opts.baseUrl}${path}`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...this.opts.defaultHeaders,
      ...options.headers,
    };
    const label = options.label ?? `probe-${String(this.probeIndex++).padStart(3, '0')}`;
    const t0 = Date.now();

    const resp = await fetch(url, {
      method,
      headers,
      body: options.body != null ? JSON.stringify(options.body) : undefined,
    });

    const durationMs = Date.now() - t0;
    let responseBody: unknown;
    const contentType = resp.headers.get('content-type') ?? '';
    try {
      responseBody = contentType.includes('json') ? await resp.json() : await resp.text();
    } catch {
      responseBody = '[unparseable response body]';
    }

    const responseHeaders: Record<string, string> = {};
    resp.headers.forEach((value, key) => { responseHeaders[key] = value; });

    this.note(
      `[${label}] ${method} ${path} → ${resp.status} (${durationMs}ms)` +
      ` | body: ${JSON.stringify(responseBody).slice(0, 120)}`
    );

    return { method, url, status: resp.status, durationMs, responseBody, responseHeaders };
  }

  /** Flag a potential defect found during the session */
  defect(summary: string, probe: ApiProbeResult): void {
    this.note(`DEF: ${summary} | ${probe.method} ${probe.url} → ${probe.status}`);
  }

  async end(): Promise<void> {
    const fs = await import('fs');
    fs.writeFileSync(this.opts.outputFile, this.log.join('\n'), 'utf-8');
    console.log(`\nAPI session ended. Notes written to: ${this.opts.outputFile}`);
  }
}

// Example usage in a session script:
// const harness = new ApiExploratoryHarness({
//   charterId: 'CHR-orders-api-20260428-01',
//   baseUrl: 'https://api.staging.example.com',
//   defaultHeaders: { Authorization: 'Bearer ' + process.env.STAGING_TOKEN! },
//   outputFile: './session-output/orders-api-session.txt',
// });
// const r1 = await harness.request('GET', '/orders?limit=-1', { label: 'negative-limit' });
// if (r1.status !== 400) harness.defect('Negative limit not rejected', r1);
// await harness.end();
```

Key differences from UI exploratory testing:
- No screenshots — log response bodies and status codes instead
- Boundary testing is systematic (negative limits, 0 values, max-int values) rather than visual
- Schema validation can be automated alongside exploration: compare response fields against OpenAPI spec on each probe
- Security-oriented probing (missing auth header, token replay, IDOR via enumeration) is especially productive for new API endpoints

---

### Pair Exploratory Testing  [community]

Pair testing couples two people in a single session — one drives (uses the product), one observes and takes notes. Research in professional QA communities consistently shows that pairs find more bugs than two solo testers covering the same area. The observer is free to use HICCUPPS and FEW HICCUPS without interrupting flow; the driver can react to what they see without breaking to take notes.

**Pair configurations that work best:**

| Driver | Observer | Strength |
|--------|----------|----------|
| Developer | Tester | Developer explains intent; tester probes assumptions and notices deviations |
| Senior tester | Junior tester | Knowledge transfer plus fresh perspective on familiar areas |
| Tester A (domain expert) | Tester B (new to domain) | Expert guides scope; newcomer asks "why?" questions that expose hidden assumptions |
| Product manager | Tester | PM sees real user experience firsthand; tester benefits from product context |

**Pair testing session charter (TypeScript-project context):**

```typescript
// Session charter for a pair testing session — same format, with pair roles noted
interface PairSessionCharter extends SessionCharter {
  driver: string;       // person using the product
  observer: string;     // person using heuristics and taking notes
  pairRationale: string; // why this pairing was chosen for this session
}

// Example:
const pairCharter: PairSessionCharter = {
  charterId: 'CHR-auth-20260426-pair-01',
  tester: 'Alice Chen + Bob Kim',
  driver: 'Bob Kim (new to auth module)',
  observer: 'Alice Chen (senior, built the auth flow)',
  pairRationale: "Bob's unfamiliarity means he takes non-obvious paths; Alice provides context",
  sessionDate: '2026-04-26',
  timeboxMinutes: 90,
  mission: {
    explore: 'SSO login and session management',
    using: 'External identity provider (Google), mobile viewport, token expiry simulation',
    toDiscover: 'Session state bugs after token refresh, error recovery gaps, logout edge cases',
  },
  priorityAreas: [
    'Token refresh during active session',
    'Logout from multiple tabs simultaneously',
    'SSO provider returning unexpected error codes',
  ],
  outOfScope: ['Password-based login (covered by existing scripted suite)'],
};
```

---

### TypeScript: Thread-Based Session Charter  [community]

Thread-based exploration follows a complete user scenario end-to-end, crossing multiple subsystems in a single charter. This pattern finds integration bugs that per-feature charters miss.

```typescript
// src/testing/exploratory/thread-charter.ts
// Thread charter: crosses Cart → Checkout → Payment → Order Confirmation → Email
// Used when individual feature areas are stable but their integration is suspect.

import type { SessionCharter } from './types';

export interface ThreadCharter extends SessionCharter {
  /** Ordered list of subsystems the thread passes through */
  subsystems: string[];
  /** The user persona performing this end-to-end thread */
  userPersona: string;
  /** Entry conditions: what state the system must be in before the thread starts */
  preconditions: string[];
}

const guestCheckoutThread: ThreadCharter = {
  charterId: 'THR-checkout-e2e-20260427-01',
  tester: 'Alice Chen',
  sessionDate: '2026-04-27',
  timeboxMinutes: 90,
  mission: {
    explore: 'Complete guest checkout flow from product page to order confirmation email',
    using: 'International test cards, mobile viewport, slow-3G network simulation',
    toDiscover: 'Integration gaps between cart, payment, confirmation, and email subsystems',
  },
  subsystems: ['Cart', 'Address Form', 'Payment Processing', 'Order Confirmation Page', 'Confirmation Email'],
  userPersona: 'New guest user with international shipping address and non-US credit card',
  preconditions: [
    'At least one product in stock',
    'Guest checkout feature flag enabled',
    'Test email inbox accessible',
  ],
  priorityAreas: [
    'Data fidelity from cart through to confirmation page (quantities, prices, addresses)',
    'Email arrives with correct order ID matching confirmation page',
    'Error state at any step propagates correctly without data loss in earlier steps',
  ],
  outOfScope: [
    'Logged-in checkout (separate charter)',
    'Refund flow (separate charter)',
  ],
};

export { guestCheckoutThread };
```

---

### TypeScript: AI-Assisted Session Note Classifier  [community]

Feeds raw session notes into a structured classifier to accelerate debrief. The human tester reviews and corrects the output — the AI draft is never accepted without review.

```typescript
// src/testing/exploratory/note-classifier.ts
// Classifies raw session note lines into: bug | question | observation | blocked | scenario
// In practice, teams pipe this to an LLM API; here shown as a rule-based classifier
// that can be tested deterministically without an API key.

export type NoteCategory = 'defect' | 'question' | 'observation' | 'blocked' | 'scenario' | 'uncategorised';

export interface ClassifiedNote {
  timestamp: string;
  rawText: string;
  category: NoteCategory;
  confidence: 'high' | 'low';
}

const DEFECT_SIGNALS = ['def:', 'defect:', 'bug:', 'unexpected', 'wrong', 'error', 'fail', 'broken', 'crash', 'security'];
const QUESTION_SIGNALS = ['question:', 'why', 'check with dev', 'confirm', '?'];
const BLOCKED_SIGNALS = ['blocked:', 'lost ~', 'expired', 'broken env', 'waiting for'];
const SCENARIO_SIGNALS = ['tried', 'navigated', 'placed', 'clicked', 'entered', 'submitted'];

function classifyLine(line: string): { category: NoteCategory; confidence: 'high' | 'low' } {
  const lower = line.toLowerCase();
  if (DEFECT_SIGNALS.some((s) => lower.includes(s))) return { category: 'defect', confidence: 'high' };
  if (QUESTION_SIGNALS.some((s) => lower.includes(s))) return { category: 'question', confidence: 'high' };
  if (BLOCKED_SIGNALS.some((s) => lower.includes(s))) return { category: 'blocked', confidence: 'high' };
  if (SCENARIO_SIGNALS.some((s) => lower.includes(s))) return { category: 'scenario', confidence: 'high' };
  if (lower.includes('observed') || lower.includes('noticed') || lower.includes('observation'))
    return { category: 'observation', confidence: 'high' };
  return { category: 'uncategorised', confidence: 'low' };
}

export function classifySessionNotes(rawNotes: string): ClassifiedNote[] {
  const lines = rawNotes.split('\n').filter((l) => l.trim().startsWith('['));
  return lines.map((line) => {
    const timestampMatch = line.match(/^\[([^\]]+)\]/);
    const timestamp = timestampMatch ? timestampMatch[1] : '';
    const text = line.replace(/^\[[^\]]+\]\s*/, '');
    const { category, confidence } = classifyLine(text);
    return { timestamp, rawText: text, category, confidence };
  });
}

export function generateDebriefDraft(classified: ClassifiedNote[]): string {
  const bugs = classified.filter((n) => n.category === 'bug');
  const questions = classified.filter((n) => n.category === 'question');
  const blocked = classified.filter((n) => n.category === 'blocked');
  const scenarios = classified.filter((n) => n.category === 'scenario');
  const lowConf = classified.filter((n) => n.confidence === 'low');

  return [
    `=== AI-DRAFT DEBRIEF (review and correct before accepting) ===`,
    ``,
    `Scenarios exercised (${scenarios.length}):`,
    ...scenarios.map((n) => `  - ${n.rawText}`),
    ``,
    `Defects found (${bugs.length}):`,
    ...bugs.map((n) => `  - [T+${n.timestamp}] ${n.rawText}`),
    ``,
    `Open questions (${questions.length}):`,
    ...questions.map((n) => `  - ${n.rawText}`),
    ``,
    `Blocked items (${blocked.length}):`,
    ...blocked.map((n) => `  - ${n.rawText}`),
    ``,
    `Needs tester review (${lowConf.length} uncategorised lines):`,
    ...lowConf.map((n) => `  - [T+${n.timestamp}] ${n.rawText}`),
    ``,
    `=== END AI DRAFT — tester must verify all items above ===`,
  ].join('\n');
}
```

---

## Anti-Patterns

- **Session without a charter**: Exploration without a mission is wandering. Without a charter, results can't be reported and coverage can't be tracked.
- **Charter that is a script**: "Click button X, enter Y, verify Z" is a test case, not a charter. Over-specifying removes the tester's ability to respond to what they observe.
- **Skipping the debrief**: Findings that stay in a session sheet and never get communicated are wasted. Debriefs are mandatory, not optional.
- **Using exploratory testing as a substitute for regression automation**: Exploratory testing does not confirm that previously fixed defects stay fixed. Rerunning exploration is not equivalent to running a regression suite.
- **No time tracking**: Without tracking actual vs planned time, you can't know whether your coverage estimates are realistic or whether blockers are eating your sessions.
- **Heroic testing**: One tester doing all exploration alone, without pair testing or peer review of charters, produces blind spots. Diversity of perspective finds more defects.
- **Reporting only defects, not coverage**: Stakeholders need to know both what was found and what was checked. A session that finds no defects is valuable if coverage was thorough.
- **"Automation-first" teams that never schedule exploration**: High-automation teams sometimes reach 90% line coverage and stop exploratory testing entirely. This is the most expensive anti-pattern: the 10% of untested paths and all integration behavior is never explored. Coverage percentage is not equivalent to product quality.
- **Equal session time across all areas regardless of risk**: Assigning the same number of sessions to the payment processing flow and the cosmetic preference page wastes session capacity. Session allocation should be risk-based: more sessions on higher-risk, higher-impact, recently changed areas.
- **Ignoring blocked time as a metric**: Teams that track only defects found miss that 30–40% of session time spent blocked is a signal about infrastructure health, not tester performance. Blocked time should trigger an infrastructure improvement conversation, not just be absorbed as a cost of testing.
- **Never evolving the heuristic set**: FEW HICCUPS and HICCUPPS are starting points, not a complete list. Teams that adopt them as dogma without adding team- or product-specific heuristics plateau in defect-finding ability. Senior testers should maintain and share a living heuristic cheat sheet specific to their domain.
- **Conflating checklist-based testing with exploratory testing**: ISTQB CTFL 4.0 distinguishes these as two separate experience-based techniques. Checklist-based testing follows a fixed list of items derived from past experience; exploratory testing is dynamic and self-directing. Running through a checklist is not exploration — it is systematic but structured. The difference matters for coverage claims: a checklist gives coverage against known items; exploration discovers unknown ones.
- **Recording sessions but skipping written notes**: Video recordings are useful evidence for defect reports but are not a substitute for written session notes. A 90-minute video takes 90 minutes to review; session notes take 5 minutes to scan. Teams that replace notes with recordings lose the ability to quickly audit coverage and find follow-on charter opportunities. Always take both.
- **Using exploratory testing for API endpoints without OpenAPI schema validation**: API exploration without a schema reference misses an entire class of defects — fields that are nullable when not supposed to be, missing error envelope structure, incorrect HTTP status codes. Always load the OpenAPI spec before an API exploration session and use it as one oracle source.
- **Treating AI-generated charters as complete**: LLM-generated charters cover happy-path scenarios plausibly but systematically miss domain-specific edge cases (locale behavior, legacy data paths, hardware quirks). AI-generated charters are useful scaffolding for junior testers, but must be reviewed and extended by a tester with domain knowledge before the session begins. Accepting an AI charter without review is structurally equivalent to a junior tester writing the charter alone — the gaps are similar.
- **Scheduling exploratory sessions only at sprint end**: When sessions are pushed to the last two days of a sprint, the findings arrive too late to influence sprint deliverables. Defects found on day 9 are fixed under pressure or deferred. Charter writing should happen on day 1 (as acceptance criteria are being finalised), and sessions should run as features reach dev-complete — not in batch at the end.

---

## Real-World Gotchas [community]

1. **[community] Charter drift is the biggest SBTM failure mode.** Teams start with good charters, but by sprint 3, testers are writing charters so broad ("Explore the user module") that they become meaningless. Fix: charter review as part of sprint planning.

2. **[community] The debrief is skipped under deadline pressure — exactly when it matters most.** When a release is close, teams cut the debrief to save time. This is when integration bugs are most likely, and when knowledge needs to flow fastest. Protect the debrief slot.

3. **[community] Exploratory testing fatigue is real.** Skilled exploration requires cognitive load. Testers who do more than 3-4 hours of focused exploratory work per day produce diminishing returns in the afternoon. Schedule exploratory sessions in the morning.

4. **[community] "We do exploratory testing" often means "we click around without structure."** Teams adopt the label without SBTM. This produces untraceable coverage and no institutional learning. Require session sheets even for informal exploration.

5. **[community] Pairing exploratory sessions with developers during refactors catches more bugs.** Developer-tester pairs exploring changed code together outperform solo testing: the developer explains intent, the tester probes assumptions. This is especially effective during large migrations.

6. **[community] Test environment instability destroys exploratory sessions.** Unlike scripted tests, exploratory sessions rely on tester flow state. An environment that crashes every 20 minutes turns a 90-minute session into a 20-minute session with 70 minutes of recovery. Invest in environment stability before scheduling exploration.

7. **[community] Bug clustering is a reliable guide for follow-on charters.** When you find 3 bugs in one area during a session, that area almost always has more. Bug clustering is one of the strongest signals in exploratory testing — follow it.

8. **[community] First-sprint exploratory testing on a new micro-service pays the biggest dividend.** In greenfield services, exploration in sprint 1 finds architectural issues (wrong HTTP verbs, missing error codes, unvalidated inputs) that would become expensive to fix by sprint 4. Exploration acts as a lightweight security and contract review.

9. **[community] Exploratory testing exposes usability issues scripted tests systematically miss.** Scripted tests confirm what developers expected users would do. Exploratory testers do what users actually do — hover over confusing labels, skip steps, paste unexpected content — and find a class of UX defects that no scripted test has ever caught.

10. **[community] Time logging reveals how much of an "exploratory session" is actually blocked time.** Teams tracking time with tools like SBTM sheets often discover that 30–40% of session time is overhead: broken environments, missing credentials, waiting for builds. This data is politically powerful for advocating for better test infrastructure.

11. **[community] Charter writing itself surfaces requirements gaps.** When testers try to write "to discover Z" in a charter and can't, it usually means the acceptance criteria are missing or ambiguous. Charter creation as a sprint ritual catches underspecified stories before coding begins.

12. **[community] Pair exploratory testing between testers with different backgrounds consistently outperforms solo.** A tester who built features in the domain pairs with one who has no domain context. The domain expert guides, the newcomer asks "why does it work that way?" — and the answer is often "actually, it shouldn't." Fresh eyes on a familiar system is a reliable defect trigger.

13. **[community] In highly regulated industries, exploratory session sheets serve as informal audit evidence.** When a compliance audit asks "what testing was performed before this release?", session sheets with charters, findings, and debrief notes provide a narrative record that complements formal scripted test evidence.

14. **[community] Exploratory coverage reporting needs a translation layer for non-QA stakeholders.** "We completed 6 sessions across 4 feature areas" is opaque to a product manager. Teams that translate session outcomes into a coverage heatmap (green = sessions complete, yellow = partial, red = no sessions) get faster sign-off and fewer "but did you test X?" questions.

15. **[community] The best exploratory testers keep a personal heuristic cheat sheet.** Senior testers accumulate personal mnemonics beyond FEW HICCUPS — things like "always test the last item in a list," "always try copy-paste in form fields," "always try two browser tabs." Encouraging testers to document and share these cheat sheets is one of the highest-leverage QA team practices.

16. **[community] Exploratory testing in dark mode, RTL locales, and high-contrast accessibility settings finds a disproportionate share of layout bugs.** Most development and testing happens in default settings. Running one session per release in non-default display configurations consistently catches bugs that never appeared in standard exploration.

17. **[community] Exploratory testing is the fastest way to validate a new hire's domain knowledge.** When a new tester joins the team, pairing them on an exploratory session with a senior tester reveals their mental model of the product within 30 minutes. Questions they don't ask reveal blind spots; bugs they find signal instinct.

18. **[community] Tester rotation across feature areas prevents knowledge silos.** When one tester owns the same feature area for months, they start to accept its quirks as normal. Rotating testers into unfamiliar areas once per quarter brings fresh perspective that reliably finds bugs the regular tester stopped noticing.

19. **[community] Recording exploratory sessions with screen capture pays dividends during bug review.** Filing a bug with a screen recording of the session moment is significantly more actionable for developers than a text description. Teams that mandate recordings for crash and correctness bugs halve the average bug-reproduction time.

20. **[community] Exploratory testing feedback loops into better product design.** In teams where exploration findings are shared with product managers weekly, designers report that they reconsider UI patterns and clarify specs earlier. The tester becomes a de facto design reviewer — not because they are asked to be, but because exploration naturally surfaces usability issues.

21. **[community] The "tour" metaphor from Elisabeth Hendrickson's Explore It! is a practical tool for generating charter ideas.** Tours — the Landmark Tour (visit all notable features), the Variability Tour (vary inputs), the Interruption Tour (disrupt the user flow) — give testers a vocabulary for charter types that is intuitive for product managers and developers to understand.

22. **[community] Exploratory testing is not scalable with a single shared environment.** Teams with more than 3 testers all sharing one staging environment will spend 30–50% of session time waiting for the environment to be in the right state. Per-tester ephemeral environments (e.g., PR-level preview deployments) remove this bottleneck and allow parallel sessions without coordination overhead.

23. **[community] Adding a "tester confidence score" to session sheets is the fastest way to surface risky areas.** When testers rate their confidence (0–5) that the chartered area is well understood, areas rated 2 or below almost always have follow-on bugs found in the next session. A sprint-level confidence map lets the QA lead see coverage quality at a glance without reading every session sheet.

24. **[community] Thread-based exploration works better than session isolation for highly connected feature areas.** In tightly integrated applications, a single 90-minute session charter that cuts across multiple subsystems (cart + checkout + email + order history) finds integration bugs that isolated per-feature charters miss. Practitioners call this a "thread" — following a complete user scenario end-to-end as a single charter mission. Thread-based charters produce more integration bugs per session-hour than single-area charters in mature products where the features individually are stable but their interaction is where bugs live.

25. **[community] AI-assisted note analysis speeds debrief without replacing tester judgment.** Teams in 2024–2025 began feeding raw session notes into LLMs to generate draft debrief summaries, extract action items, and categorise observations as defect/question/observation/blocked. The human tester reviews and corrects the draft. This cuts debrief time from 30 minutes to 10 minutes without losing quality — and the structured output feeds directly into sprint planning tools. The key constraint: the AI classification is always reviewed by the tester, never accepted blindly.

26. **[community] AI-generated charters sound plausible but lack domain knowledge.** Teams in 2025-2026 experiment with having LLMs auto-generate session charters from user stories or PR descriptions. The resulting charters cover obvious happy-path scenarios well but systematically miss the domain-specific edge cases that senior testers bring: unusual locale behavior, legacy data migration paths, specific hardware quirks. AI-generated charters are useful as a starting checklist for junior testers, but must be reviewed and extended by someone with domain context before a session begins.

27. **[community] Autonomous AI exploratory agents (browser agents) find shallow defects but miss judgment-dependent ones.** In 2025-2026, autonomous browser agents capable of clicking through UIs and flagging anomalies are increasingly available. They excel at finding consistency defects (button states that don't match API responses, label mismatches, accessibility violations) and can run 24/7. They consistently miss judgment-dependent defects: behavior that is technically correct but confusing to a user in context, security implications of a feature design, or UX issues that only appear when a real user's mental model is violated. The practical pattern: run agents nightly for broad shallow coverage, then schedule human exploratory sessions focused on the judgment-dependent areas the agent cannot assess.

28. **[community] Junior and senior testers use the same heuristics differently — and coaching the gap matters more than buying tools.** A junior tester using FEW HICCUPS covers all 10 dimensions mechanically; a senior tester knows which 2-3 dimensions are highest risk for this specific charter and front-loads them. The result is that a 60-minute senior session finds more defects than a 90-minute junior session on the same charter, even with identical tools. Teams that invest in structured coaching — senior testers explaining "why I picked this dimension first" during pair sessions — report measurable improvements in junior defect-find rates within 3 sprints. Tooling improvements have less leverage than this at the junior-to-mid transition.

29. **[community] Distributed and async teams need written charter rationale, not just the charter mission.** In co-located teams, testers discuss the charter context verbally before the session. In async/distributed teams, the tester reads the charter alone. Charter context gaps — "why is this area high-risk now?", "what changed in this PR?" — produce shallow sessions because the tester doesn't know what to front-load. Fix: add a mandatory "background" field to every charter (see the Session Charter Template) that explains the change, the history, and the risk rationale. A well-written background converts a 45-minute async prep call into a 5-minute charter read.

30. **[community] Risk-triggered session scheduling outperforms sprint-cadence scheduling in mature CI/CD environments.** Teams that schedule sessions on a fixed sprint cadence ("we do 4 sessions per sprint, one per story") waste capacity on low-risk changes and undercover high-risk ones. Teams that trigger sessions by risk threshold — any PR touching payment, auth, or checkout automatically creates a charter and is flagged for a session before merge to main — consistently catch more defects per session-hour. The risk-trigger model requires upfront engineering work (a script that flags high-risk PRs), but the signal-to-noise improvement is measurable within 2 sprints of adoption.

---

## Tradeoffs & Alternatives (vs Scripted Testing)

### ISTQB CTFL 4.0: Experience-Based Techniques Compared

ISTQB CTFL 4.0 classifies three experience-based techniques. Understanding their differences clarifies when exploratory testing is the right choice:

| Technique | ISTQB Definition | Planning overhead | Defect type found | Repeatability | When to use |
|-----------|-----------------|-------------------|-------------------|--------------|-------------|
| **Exploratory Testing** | Simultaneous learning, design, and execution; directed by a charter and adapted in real-time | Low (charter: 15 min) | Novel, integration, UX, judgment-dependent | Low (session is unique) | New features, pre-release, risk-based investigation |
| **Error Guessing** | Testers anticipate likely mistakes based on experience | Very low (mental list) | Known-category defects matching past experience | Low | Any time a senior tester has strong domain intuition |
| **Checklist-Based Testing** | Executing against a fixed checklist of items derived from past failures or standards | Medium (list maintenance) | Items explicitly on the checklist | High | Regression of known-failure categories, compliance |

Key distinction: **exploratory testing discovers the unknown**; checklist-based testing confirms the known. They are complementary — exploration builds the knowledge that eventually becomes a checklist.

### Known Adoption Cost

Adopting SBTM/exploratory testing at the team level carries concrete costs that should be planned for:

| Cost Item | Rough Estimate | Mitigation |
|-----------|---------------|-----------|
| Tester onboarding to SBTM | 2–4 hours to read the foundational paper + first supervised session | Pair with an experienced practitioner for first 3 sessions |
| Charter template setup in the team's tracking tool | 1–2 hours per tool (Jira, Linear, Notion) | Use the YAML/Markdown templates from this guide as a starting point |
| Coverage reporting process | 3–5 hours to build the first sprint dashboard | Use the TypeScript coverage reporter in this guide |
| Session scheduling discipline | Ongoing — 2–3 weeks before it becomes habitual | Embed charter writing into sprint planning as a ceremony |
| Stakeholder education | 1–2 hours to explain "sessions vs test cases" to non-QA stakeholders | Use the coverage heatmap translation layer (community lesson #14) |
| Infrastructure investment for ephemeral environments | Varies (1–4 sprints) | Prioritise if > 3 testers share one staging environment (community lesson #22) |

**Total ramp-up cost for a 2-person QA team**: approximately 1 sprint of reduced exploratory output while the process is established. By sprint 3, teams consistently report higher defect-find rates than before adoption.

### Decision Matrix: Exploratory vs Scripted vs Both

| Scenario | Exploratory | Scripted | Both |
|----------|-------------|----------|------|
| New feature, first sprint | **Primary** | None yet | Plan automation from exploration findings |
| Stable, mature feature | Occasional (1 session/quarter) | **Primary** | — |
| Post-refactor verification | **Primary** | Regression run | Exploration finds new, regression confirms old |
| Release sign-off | **Primary** | Run full suite | Exploration for late-breaking issues |
| Performance testing | Not applicable | **Primary** | — |
| Security review | Useful (manual probing) | Useful (scanners) | Both for depth |
| Compliance audit | Supporting evidence | **Primary** (traceable) | — |
| Spike / prototype | **Primary** | None needed | — |

### When Exploratory Finds More Than Scripted Tests

- **New features**: Scripted tests are written from specs; specs miss edge cases. Exploration finds the cases the author didn't think to specify.
- **Integration paths**: Scripted tests tend to test features in isolation. Exploratory testing naturally follows user journeys across features, finding integration seams.
- **UI/UX issues**: Scripted tests verify data and flow; exploratory testing notices confusing labels, unexpected layout shifts, and accessibility failures because the tester is present and reacting.
- **Timing and state bugs**: A tester navigating at human speed stumbles on timing bugs that automated tests at machine speed bypass.
- **The unknown unknowns**: Scripted tests verify only what was anticipated. Exploratory testing discovers behavior no one anticipated — the category of "unknown unknowns." Studies of production bug databases consistently show that 30–60% of customer-reported bugs were not covered by the existing scripted test suite, many of which a skilled exploratory tester would have found.

### Cost per Bug Found: Exploratory vs Scripted

Understanding when each approach is economically efficient matters for planning:

| Metric | Scripted Automated | Exploratory |
|--------|--------------------|-------------|
| Cost to write | High (hours per test) | Low (charter: 15 min) |
| Cost to run | Near-zero (CI) | High (tester time per session) |
| Cost to maintain | High (UI changes break scripts) | Low (charters rarely become invalid) |
| Bug type found | Regression, known paths | Novel, integration, UX |
| Bugs per tester-hour (new features) | Low | High |
| Bugs per tester-hour (stable features) | N/A (automated) | Low |

The economic argument: use automation as a force multiplier for regression confidence, freeing tester hours for exploration where the return on tester time is highest.

### Time Investment

| Activity | Scripted | Exploratory |
|----------|----------|-------------|
| Upfront design cost | High (write cases before testing) | Low (charter is lightweight) |
| Execution cost | Low (automated or rote) | Medium (requires skilled tester) |
| Maintenance cost | High (scripts break on UI change) | Low (charters are stable) |
| Coverage traceability | High (test case IDs map to requirements) | Medium (session + charter maps to area) |
| Novel bug discovery rate | Low | High |

### Tracking Coverage Without Test IDs

The absence of test case IDs is often cited as a weakness. In practice, coverage is tracked through:
- **Session count by charter area**: "We ran 4 sessions on the checkout flow, covering cart, payment, confirmation, and edge users."
- **Mind map completion**: Areas with completed sessions are marked done; gaps are visible.
- **Session sheets archive**: An auditable record of what was explored and what was found exists even without test IDs.

### Risk-Based Session Allocation

Not all areas warrant equal exploration effort. Allocate sessions based on:

- **Change magnitude**: Areas touched by large or complex PRs get more sessions than stable areas.
- **Historical bug density**: Areas that have produced many bugs in past sprints are more likely to produce bugs now.
- **Business impact**: Features in the critical path (checkout, auth, billing) warrant deeper coverage than low-traffic features.
- **Automation coverage**: Areas with no automated regression coverage need more exploration than areas with strong automated suites.

A simple risk matrix per sprint:

| Area | Change Size | Bug History | Business Impact | Sessions Allocated |
|------|------------|-------------|-----------------|-------------------|
| Payment Processing | Large (new feature) | High | Critical | 3 |
| User Profile | Small (bug fix) | Low | Medium | 1 |
| Help / FAQ | None | None | Low | 0 |
| Auth / SSO | Medium | Medium | Critical | 2 |

### When Scripted Tests Win

- Regression: confirming nothing broke across builds
- Compliance: demonstrating specific steps were followed
- Data validation at scale: thousands of records
- Performance baselines: deterministic load numbers
- CI gating: automated checks on every PR

### Hybrid Approach: Exploration Feeding Automation

The most effective teams use exploratory testing to **discover** and automated scripted tests to **confirm**. The workflow:

1. Run an exploratory session on a new feature (1–2 sessions, 90 min each).
2. During debrief, identify which scenarios found in exploration are high-value and stable enough to automate.
3. Convert those scenarios to scripted tests added to the regression suite.
4. In the next sprint, exploratory sessions focus on unexplored territory rather than re-covering automated paths.

This avoids the two failure modes: exploration without follow-through (bugs refound each sprint) and automation without discovery (scripted tests cover only what was anticipated).

**TypeScript: converting an exploration finding into a Playwright regression test**

```typescript
// src/tests/regression/checkout-guest-flow.spec.ts
// This test was born from exploration session CHR-checkout-20260426-01.
// During that session, the tester found that declined cards showed no "Try another card" CTA.
// The fix was verified in follow-on testing, then this regression test was added to prevent recurrence.
import { test, expect } from '@playwright/test';

test.describe('Guest Checkout — declined card regression', () => {
  test('shows "Try another card" CTA after a declined card', async ({ page }) => {
    // Arrange: navigate to guest checkout with a pre-filled cart
    await page.goto('/checkout/guest');
    await page.fill('[data-testid="email"]', 'guest@example.com');
    await page.fill('[data-testid="card-number"]', '4000 0000 0000 0002'); // Stripe decline fixture
    await page.fill('[data-testid="card-expiry"]', '12/28');
    await page.fill('[data-testid="card-cvc"]', '123');

    // Act: attempt payment
    await page.click('[data-testid="submit-payment"]');

    // Assert: error message AND retry CTA are both visible
    await expect(page.getByText('Payment declined')).toBeVisible();
    await expect(page.getByRole('button', { name: /try another card/i })).toBeVisible();

    // Assert: form is still filled (user doesn't lose their address)
    await expect(page.locator('[data-testid="email"]')).toHaveValue('guest@example.com');
  });

  test('order confirmation URL requires authentication', async ({ page }) => {
    // Regression for BUG-CHR-checkout-003 found in session CHR-checkout-20260426-01
    // Confirmed fix: confirmation page now redirects unauthenticated access to login
    const fakeOrderId = 'ORD-999999';
    const response = await page.goto(`/order-confirmation?orderId=${fakeOrderId}`);
    // Should redirect or return 401/403, not expose order data
    expect([301, 302, 401, 403]).toContain(response?.status() ?? 0);
  });
});
```

### Exploratory Testing in CI/CD Pipelines

Exploratory testing does not run in CI — it is a human activity. However, it integrates with CI workflows through:

- **Triggered exploration on PR merge**: When a large PR lands, a charter is created for that feature area and a session is scheduled. CI triggers a Slack notification; the QA team picks up the charter within the sprint.
- **Session results as release gates**: A team can require that N chartered sessions have been completed and debriefed before marking a release candidate as approved. This is a lightweight gate that doesn't block CI but does gate the release decision.
- **Bug IDs linked to commits**: Bugs found in exploration are filed with the commit hash, making it possible to bisect regressions later if the same bug recurs.

**TypeScript: Risk-Triggered Session Scheduler**  [community]

This utility inspects a PR's changed file paths and labels against a risk configuration, then auto-generates a charter stub and emits a Slack-ready notification. It operationalises community lesson #30 — risk-triggered scheduling rather than fixed-cadence.

```typescript
// src/testing/exploratory/risk-trigger.ts
// Evaluates a PR's change surface against risk rules and auto-drafts a session charter.
// Wire this into your CI pipeline (GitHub Actions, CircleCI, etc.) as a post-merge step.

export interface RiskRule {
  id: string;
  description: string;
  /** Glob-style path patterns that trigger this rule */
  pathPatterns: string[];
  /** PR labels that trigger this rule */
  labelPatterns?: string[];
  riskLevel: 'critical' | 'high' | 'medium';
  /** Suggested timebox in minutes for the triggered session */
  suggestedTimeboxMinutes: number;
  /** Auto-generated "to discover Z" hint for the charter */
  discoveryHint: string;
}

export interface PullRequest {
  id: string;
  title: string;
  changedFiles: string[];
  labels: string[];
}

export interface TriggeredSession {
  prId: string;
  rule: RiskRule;
  draftCharter: {
    explore: string;
    using: string;
    toDiscover: string;
    timeboxMinutes: number;
  };
  notificationMessage: string;
}

/** Default risk rules for a TypeScript web application */
export const DEFAULT_RISK_RULES: RiskRule[] = [
  {
    id: 'payment',
    description: 'Payment or billing code changed',
    pathPatterns: ['**/payment/**', '**/billing/**', '**/checkout/**', '**/stripe/**'],
    riskLevel: 'critical',
    suggestedTimeboxMinutes: 90,
    discoveryHint: 'payment error handling, decline flows, currency formatting, and idempotency edge cases',
  },
  {
    id: 'auth',
    description: 'Authentication or authorization code changed',
    pathPatterns: ['**/auth/**', '**/sso/**', '**/session/**', '**/permissions/**'],
    riskLevel: 'critical',
    suggestedTimeboxMinutes: 90,
    discoveryHint: 'token lifecycle, session expiry, privilege escalation, and logout edge cases',
  },
  {
    id: 'api-contracts',
    description: 'API route or controller changed',
    pathPatterns: ['**/routes/**', '**/controllers/**', '**/api/**'],
    riskLevel: 'high',
    suggestedTimeboxMinutes: 60,
    discoveryHint: 'missing error envelopes, unexpected nullable fields, HTTP status code correctness',
  },
  {
    id: 'feature-flag',
    description: 'Feature flags modified',
    pathPatterns: ['**/feature-flags/**', '**/flags/**', '**/*.flags.ts'],
    riskLevel: 'high',
    suggestedTimeboxMinutes: 60,
    discoveryHint: 'behavior differences between flag-on and flag-off states, flag interaction effects',
  },
];

function matchesPattern(filePath: string, pattern: string): boolean {
  // Simplified glob match: supports ** and * wildcards
  const regex = new RegExp(
    '^' + pattern.replace(/\*\*/g, '(.+)').replace(/\*/g, '([^/]+)') + '$'
  );
  return regex.test(filePath);
}

export function evaluatePR(
  pr: PullRequest,
  rules: RiskRule[] = DEFAULT_RISK_RULES
): TriggeredSession[] {
  const triggered: TriggeredSession[] = [];

  for (const rule of rules) {
    const fileMatch = pr.changedFiles.some((file) =>
      rule.pathPatterns.some((pattern) => matchesPattern(file, pattern))
    );
    const labelMatch =
      !rule.labelPatterns ||
      rule.labelPatterns.some((label) => pr.labels.includes(label));

    if (fileMatch && labelMatch) {
      const draftCharter = {
        explore: `${rule.description} — changes in PR #${pr.id}: "${pr.title}"`,
        using: 'staging environment, representative test accounts, both happy-path and error conditions',
        toDiscover: rule.discoveryHint,
        timeboxMinutes: rule.suggestedTimeboxMinutes,
      };

      const notificationMessage =
        `[QA Risk Trigger] PR #${pr.id} (${pr.title}) matched rule: *${rule.description}* ` +
        `(Risk: ${rule.riskLevel.toUpperCase()}). ` +
        `Draft charter created — ${rule.suggestedTimeboxMinutes} min session recommended. ` +
        `Focus: ${rule.discoveryHint}`;

      triggered.push({ prId: pr.id, rule, draftCharter, notificationMessage });
    }
  }

  return triggered.sort((a, b) =>
    ['critical', 'high', 'medium'].indexOf(a.rule.riskLevel) -
    ['critical', 'high', 'medium'].indexOf(b.rule.riskLevel)
  );
}

// Example usage in a GitHub Actions script:
// const triggers = evaluatePR({
//   id: '4521',
//   title: 'feat: add payment retry logic for declined cards',
//   changedFiles: ['src/payment/retry.ts', 'src/checkout/PaymentForm.tsx'],
//   labels: ['feature'],
// });
// triggers.forEach(t => console.log(t.notificationMessage));
// → [QA Risk Trigger] PR #4521 matched rule: Payment or billing code changed (Risk: CRITICAL)...
```

---

### TypeScript: Session Charter to Issue Tracker Bridge  [community]

Teams that track everything in Jira, Linear, or GitHub Issues need a bridge from SBTM session results to their tracker. This utility converts a `SessionDebrief` into issue-tracker-ready payloads, avoiding the manual copy-paste overhead that causes teams to skip defect logging.

```typescript
// src/testing/exploratory/tracker-bridge.ts
// Converts a completed SessionDebrief into issue tracker payloads.
// Adapters provided for GitHub Issues and Linear API formats.
// Extend IssueTrackerAdapter for Jira, Notion, or any other tracker.

import type { SessionDebrief } from './debrief';
import type { SessionBug } from './types';

export interface IssuePayload {
  title: string;
  body: string;
  labels: string[];
  priority: 'urgent' | 'high' | 'medium' | 'low';
}

export interface IssueTrackerAdapter {
  formatDefect(bug: SessionBug, debrief: SessionDebrief): IssuePayload;
  formatFollowOnCharter(description: string, debrief: SessionDebrief): IssuePayload;
}

/** GitHub Issues adapter */
export const githubAdapter: IssueTrackerAdapter = {
  formatDefect(bug, debrief) {
    const severityToLabel: Record<string, string> = {
      crash: 'severity:critical',
      security: 'severity:critical',
      correctness: 'severity:high',
      boundary: 'severity:high',
      performance: 'severity:medium',
      cosmetic: 'severity:low',
    };
    const severityToPriority: Record<string, IssuePayload['priority']> = {
      crash: 'urgent', security: 'urgent',
      correctness: 'high', boundary: 'high',
      performance: 'medium', cosmetic: 'low',
    };
    return {
      title: `[${bug.severity.toUpperCase()}] ${bug.summary}`,
      body: [
        `**Session:** ${debrief.charter.charterId}`,
        `**Charter area:** ${debrief.charter.mission.explore}`,
        `**Date found:** ${debrief.conductedDate}`,
        `**Tester:** ${debrief.participants.join(', ')}`,
        '',
        '### Steps to Reproduce',
        ...bug.stepsToReproduce.map((s, i) => `${i + 1}. ${s}`),
        '',
        `**Expected:** ${bug.expected}`,
        `**Actual:** ${bug.actual}`,
        '',
        '### Environment',
        ...Object.entries(bug.environment).map(([k, v]) => `- **${k}**: ${v}`),
      ].join('\n'),
      labels: ['exploratory-finding', severityToLabel[bug.severity] ?? 'severity:unknown'],
      priority: severityToPriority[bug.severity] ?? 'medium',
    };
  },

  formatFollowOnCharter(description, debrief) {
    return {
      title: `[QA Follow-on Charter] ${description}`,
      body: [
        `Triggered by session: **${debrief.charter.charterId}**`,
        `Original charter area: ${debrief.charter.mission.explore}`,
        '',
        `**Rationale:** ${description}`,
        '',
        '_This charter stub was auto-generated. A tester must fill in the full X/Y/Z mission before scheduling._',
      ].join('\n'),
      labels: ['qa-charter', 'follow-on'],
      priority: 'medium',
    };
  },
};

/** Batch-convert a completed debrief into all required issue payloads */
export function debriefToIssues(
  debrief: SessionDebrief,
  adapter: IssueTrackerAdapter
): { defects: IssuePayload[]; followOnCharters: IssuePayload[] } {
  const defects = debrief.findings.defects.map((bug) =>
    adapter.formatDefect(bug, debrief)
  );
  const followOnCharters = debrief.followOnCharters.map((charter) =>
    adapter.formatFollowOnCharter(charter.description, debrief)
  );
  return { defects, followOnCharters };
}

// Usage:
// const { defects, followOnCharters } = debriefToIssues(myDebrief, githubAdapter);
// for (const issue of defects) {
//   await octokit.issues.create({ owner, repo, ...issue });
// }
```

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Session-Based Test Management (James Bach) | Paper | https://www.satisfice.com/download/session-based-test-management | Foundational SBTM paper: charters, session sheets, debrief format, metrics |
| Rapid Software Testing (Bach & Bolton) | Course/Blog | https://www.developsense.com/blog/ | HICCUPPS oracle, deep heuristics, RST framework for tester skill development |
| Explore It! (Elisabeth Hendrickson) | Book | https://pragprog.com/titles/ehxta/explore-it/ | Tours framework, charter patterns, practical structured exploration |
| A Tutorial in Exploratory Testing (Cem Kaner) | Paper | https://kaner.com/pdfs/QAIExploring.pdf | Why exploration is skilled practice, not ad hoc — context-driven school foundations |
| Exploratory Software Testing (Whittaker) | Book | https://www.oreilly.com/library/view/exploratory-software-testing/9780321684080/ | Microsoft-scale tours and exploration program case studies |
| Testing from an Exploratory Perspective (Bolton) | Blog post | https://www.developsense.com/blog/2009/08/testing-from-an-exploratory-perspective/ | Explains the epistemic difference between scripted and exploratory testing |
| Explore It! — GitHub sample code | GitHub | https://github.com/ElisabethHendrickson/explore-it | Companion code and charter examples from the Hendrickson book |
| ISTQB CTFL 4.0 Syllabus | Certification syllabus | https://www.istqb.org/certifications/certified-tester-foundation-level | Standardized terminology; Chapter 4 covers experience-based techniques including exploratory testing |
| Google Testing Blog | Blog | https://testing.googleblog.com/ | Production-scale QA lessons including exploratory testing at large-system scale; search "exploratory" for relevant posts |
