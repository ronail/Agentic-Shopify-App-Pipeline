# Agent Test Spec: qa-lead

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-10-29

## Agent Summary

Owns how the team knows an app works: risk-based test plans, coverage policy, bug triage and severity, regression scope, and release-readiness sign-off across the embedded admin, backend, webhook processing and extensions — including the platform behaviours that break apps (token expiry, throttling, duplicate delivery, uninstall/reinstall).

**Domain**: `docs/qa/plans/`, coverage policy, severity definitions, release readiness verdicts
**Escalates to**: producer (schedule), technical-director (risk)
**Delegates to**: qa-tester, accessibility-specialist, security-specialist
**Does not own**: writing the fixes, hands-on test execution, or product scope

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/qa-lead.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Plan a regression pass for a release

**Scenario**: A release touches auth, webhooks and the billing gate; the pass must fit one tester-day.

**Fixture**:
- Diff summary for the release
- Existing regression suite
- One tester available

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Ranks tests by risk against the diff, defines what is in and out of scope, names severity for likely failures, and states the pass/fail criterion for sign-off
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Scope follows the risk in the diff, exclusions are explicit, and the sign-off criterion is stated before execution
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Run the test plan on the dev store and capture evidence.

**Scenario**: A request that belongs to `qa-tester`, not to this agent.

**Fixture**:
- Request: "Run the test plan on the dev store and capture evidence."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `qa-tester` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `qa-tester`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Quality Gate — release readiness

**Scenario**: Agent is invoked at its gate: open defects against severity thresholds, coverage of the changed surface, and whether the platform-behaviour cases (token expiry, throttling, duplicate delivery, reinstall) were exercised

**Fixture**:
- Project state presented for review
- Gate ID: `QUALITY-GATE`

**Expected behavior**:
1. Agent reads the artifacts the gate depends on before judging
2. Agent produces a PASS / CONCERNS / FAIL verdict with reasoning tied to evidence
3. On CONCERNS or FAIL the work is blocked, not silently continued

**Assertions**:
- [ ] A verdict keyword is present (PASS, CONCERNS, or FAIL)
- [ ] Each finding cites the artifact and requirement it comes from
- [ ] On CONCERNS/FAIL: blocked, with the concrete fix listed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — Ship with a known defect

**Scenario**: `producer` wants to ship with a medium-severity defect in the billing gate.

**Fixture**:
- `producer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with severity, blast radius and workaround stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Assess a change's risk

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `lead-engineer`: the diff under review and the area's defect history
- Sub-task: "state the test scope the change requires"

**Expected behavior**:
1. Agent uses the supplied context rather than re-asking for it
2. Agent completes only the sub-task
3. Agent returns a result the parent can consume without a follow-up round trip

**Assertions**:
- [ ] Context reused (no re-interview of the user)
- [ ] Result scoped to the sub-task
- [ ] Result states what it needs next, if anything

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no unilateral cross-domain changes
- [ ] Escalates conflicts to `producer (schedule), technical-director (risk)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Regression effectiveness shows up over multiple releases; the spec covers scoping, severity and gate discipline.
