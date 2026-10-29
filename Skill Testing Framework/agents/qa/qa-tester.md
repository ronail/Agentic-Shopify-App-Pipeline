# Agent Test Spec: qa-tester

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-10-29

## Agent Summary

Executes the passes that prove a build works on a real development store: follows approved plans, reproduces defects, captures evidence, and writes bug reports precise enough that someone can fix the problem without asking a single question.

**Domain**: test execution, `production/qa/evidence/`, bug reports
**Escalates to**: qa-lead
**Delegates to**: test-store-manager (store state)
**Does not own**: test strategy, acceptance criteria, or fixes

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/qa-tester.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `haiku`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Execute a plan case and report a failure

**Scenario**: The plan says reinstalling the app after a scope change must re-prompt consent; it does not.

**Fixture**:
- Approved plan case with expected result
- Registered dev store with the app installed
- Evidence directory

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Follows the case exactly, records actual vs. expected, captures evidence (screenshot, request log), and files a bug with steps, build, store and severity
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Steps are reproducible by someone else, actual and expected are separated, evidence is attached, and no fix is attempted
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Decide whether this build is ready to release.

**Scenario**: A request that belongs to `qa-lead`, not to this agent.

**Fixture**:
- Request: "Decide whether this build is ready to release."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `qa-lead` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `qa-lead`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Execution Gate — evidence completeness

**Scenario**: Agent is invoked at its gate: each executed case against its plan record, evidence attachment, and whether a failure was filed rather than worked around

**Fixture**:
- Project state presented for review
- Gate ID: `EVIDENCE-GATE`

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

### Case 4: Conflict Escalation — A case that cannot be executed as written

**Scenario**: The plan assumes seed data the store does not have.

**Fixture**:
- `test-store-manager` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to qa-lead, as a plan gap — the case is not silently reinterpreted
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Run one plan case

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `qa-lead`: the case, the target build, the store register entry
- Sub-task: "execute the case and report the result"

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
- [ ] Escalates conflicts to `qa-lead`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Evidence quality needs a live store; the spec covers step fidelity, reporting structure and escalation.
