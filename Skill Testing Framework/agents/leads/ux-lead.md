# Agent Test Spec: ux-lead

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-10-29

## Agent Summary

Owns how the app feels inside the embedded admin: information architecture, the install-to-activation flow, onboarding, empty and error states, and interaction patterns. Merchants arrive mid-task, so every screen is judged on how fast it returns them to their store.

**Domain**: flow specs, IA, onboarding and state design for the embedded admin; `production/ux/<app-slug>/`
**Escalates to**: technical-director (feasibility), product-director (scope)
**Delegates to**: polaris-specialist, accessibility-specialist, localization-lead
**Does not own**: Polaris component implementation, visual styling, or backend behaviour

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/ux-lead.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Design the install-to-activation flow

**Scenario**: A merchant installs from the App Store and must reach their first useful action — a synced catalog — without reading documentation.

**Fixture**:
- App with a mandatory scope consent screen and a one-time catalog sync
- Merchant arrives from the admin sidebar with a specific task
- No onboarding screens exist

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Produces the flow as screens and states, names the activation event, specifies the empty, loading, error and no-permission states, and flags the step that can be dropped
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every screen names its next action and its failure state, and the flow defines what happens when a merchant lands mid-flow from the sidebar
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Which Polaris component should the variants table use?

**Scenario**: A request that belongs to `polaris-specialist`, not to this agent.

**Fixture**:
- Request: "Which Polaris component should the variants table use?"
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

### Case 3: Gate Verdict — UX Gate — flow review

**Scenario**: Agent is invoked at its gate: a flow spec is reviewed against the mid-task merchant constraint, state coverage, and consistency with the admin's own patterns

**Fixture**:
- Project state presented for review
- Gate ID: `UX-GATE`

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

### Case 4: Conflict Escalation — A designed layout is infeasible in the iframe

**Scenario**: `polaris-specialist` reports the two-column layout the flow depends on cannot be built with the available Polaris layout primitives inside the embedded frame.

**Fixture**:
- `polaris-specialist` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the flow re-cut or the constraint accepted explicitly
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Onboarding scope passed down from product

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `product-director`: the accepted problem statement and the activation definition from `growth-lead`
- Sub-task: "specify the onboarding flow that reaches that activation event"

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
- [ ] Escalates conflicts to `technical-director (feasibility), product-director (scope)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Visual judgement (does it feel native?) needs a live invocation against a running admin; the spec covers states, transitions and failure handling.
