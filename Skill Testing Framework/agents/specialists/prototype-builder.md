# Agent Test Spec: prototype-builder

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Answers product questions with running software: throwaway merchant-facing prototypes inside `apps/<app>/prototype/` that test whether a workflow is worth building. Standards are deliberately relaxed; the isolation is not — nothing is promoted by copy-paste.

**Domain**: `apps/<app>/prototype/` only
**Escalates to**: product-director (whether to build), lead-engineer (promotion)
**Delegates to**: polaris-specialist (real implementation after the decision)
**Does not own**: production code, architecture, or shipping behaviour

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/prototype-builder.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Test a bulk-edit workflow before committing

**Scenario**: `product-director` is unsure merchants will use a multi-step bulk editor instead of per-product edits.

**Fixture**:
- Isolated worktree
- Existing app shell to copy from
- One merchant workflow to exercise

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Builds a clickable prototype in `prototype/` that exercises the real workflow, states what it deliberately fakes, and returns a recommendation with the observed friction
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Everything lives under `apps/<app>/prototype/`, faked behaviour is labelled, and no production module is modified
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Implement this flow for real in the admin app.

**Scenario**: A request that belongs to `polaris-specialist`, not to this agent.

**Fixture**:
- Request: "Implement this flow for real in the admin app."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `polaris-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `polaris-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Prototype Gate — decision or discard

**Scenario**: Agent is invoked at its gate: whether the prototype answered the product question, what it fakes, and that nothing leaked into production paths

**Fixture**:
- Project state presented for review
- Gate ID: `PROTO-GATE`

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

### Case 4: Conflict Escalation — Prototype code that 'is nearly good enough'

**Scenario**: `lead-engineer` suggests lifting the prototype's table straight into production to save a day.

**Fixture**:
- `lead-engineer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to product-director, with the rework cost of promotion stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Prototype one workflow

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `product-director`: the product question, the merchant workflow, and the existing app shell
- Sub-task: "build the throwaway prototype and report what it showed"

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
- [ ] Escalates conflicts to `product-director (whether to build), lead-engineer (promotion)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Merchant reaction cannot be tested from a spec; the assertions cover isolation, labelling and the returned recommendation.
