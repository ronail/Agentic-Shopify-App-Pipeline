# Agent Test Spec: producer

> **Tier**: directors
> **Category**: director
> **Spec written**: 2026-10-29

## Agent Summary

Owns the delivery pipeline: board, milestones, sequencing, risk register, and handoffs between architecture, implementation, QA and release. Owns the board, not the content on it — scope belongs to `product-director` and technical calls to `technical-director`.

**Domain**: kanban board, milestone files, risk register, `production/planning/`
**Escalates to**: the user (scheduling and scope decisions)
**Delegates to**: lead-engineer, qa-lead, release-manager
**Does not own**: what gets built, how it is architected, or whether a build passes

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/producer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `opus`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Sequence the remaining checkout-upsell work

**Scenario**: Five tasks remain before submission: the extension target, the network-access declaration, the regression pass, the listing copy, and the store reset.

**Fixture**:
- Board with the five tasks unsequenced
- `qa-lead` capacity: one tester
- Submission window in two weeks

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Produces the ordered plan with owners, dependencies, and the two tasks that can slip without moving the submission date; adds blocking risks to the register
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every task has one owner from the roster, dependencies are explicit, and nothing is scheduled before its upstream gate
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Review this resolver for N+1 queries and refactor it.

**Scenario**: A request that belongs to `lead-engineer`, not to this agent.

**Fixture**:
- Request: "Review this resolver for N+1 queries and refactor it."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `lead-engineer` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `lead-engineer`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Milestone Gate — exit criteria

**Scenario**: Agent is invoked at its gate: board state is checked against the milestone's exit criteria, open blockers, and unowned tasks

**Fixture**:
- Project state presented for review
- Gate ID: `MILESTONE-GATE`

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

### Case 4: Conflict Escalation — Scope vs. schedule at the same tier

**Scenario**: `product-director` wants one more screen in the milestone; the schedule cannot absorb it without dropping the regression pass.

**Fixture**:
- `product-director` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with the two concrete options and what each costs
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Turn accepted scope into a plan

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `product-director`: the accepted problem statement, its acceptance criteria, and the current board
- Sub-task: "produce the sequenced milestone plan for it"

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
- [ ] Escalates conflicts to `the user (scheduling and scope decisions)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Estimation accuracy is not testable from a spec; the assertions cover sequencing, ownership and gate ordering instead.
