# Agent Test Spec: product-director

> **Tier**: directors
> **Category**: director
> **Spec written**: 2026-10-29

## Agent Summary

Owns the product vision and the master `request.md`: which merchant problems the pipeline solves next, and which it deliberately refuses to solve. The only roster agent allowed to amend the accepted request, and the arbiter when merchant value, scope and schedule conflict.

**Domain**: `request.md`, `request-history.md`, `production/requests/`
**Escalates to**: the user (final scope call)
**Delegates to**: research-specialist, producer, growth-lead
**Does not own**: API version policy, app architecture, test strategy, or the mechanics of any Shopify surface

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/product-director.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `opus`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Prioritise the next app against request.md

**Scenario**: `request.md` lists three accepted merchant problems. A cluster of App Store reviews suggests a fourth. Ask which one the pipeline builds next.

**Fixture**:
- `request.md` with three accepted problems and their evidence
- A review digest naming the fourth candidate, unsourced
- No app scaffolded yet

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Ranks the candidates against the evidence already accepted, names the one to build, names the deferred ones as explicit non-scope, and amends `request.md` only after approval
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] The choice cites evidence in `request.md` or a merchant signal, and every rejected candidate is recorded with the reason it lost
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Which Admin API version should app-x pin, and what does 2026-01 deprecate?

**Scenario**: A request that belongs to `api-lead`, not to this agent.

**Fixture**:
- Request: "Which Admin API version should app-x pin, and what does 2026-01 deprecate?"
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `api-lead` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `api-lead`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Scope Gate — new problem accepted into request.md

**Scenario**: Agent is invoked at its gate: a proposed problem statement is checked for evidence, merchant value, overlap with accepted scope, and whether it belongs to an existing app rather than a new one

**Fixture**:
- Project state presented for review
- Gate ID: `SCOPE-GATE`

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

### Case 4: Conflict Escalation — Growth asks for a feature mid-milestone

**Scenario**: `growth-lead` argues a new upsell screen will lift installs and wants it in the current milestone; the milestone is already at its scope ceiling.

**Fixture**:
- `growth-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, after presenting the funnel evidence against the scope cost
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Research handoff into a scope decision

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `research-specialist`: the findings document, the sourced claim table, and the competitor matrix for one app slug
- Sub-task: "decide whether this problem becomes an accepted request"

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
- [ ] Escalates conflicts to `the user (final scope call)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

How much evidence is 'enough' is a judgement call that needs a live invocation; the spec asserts the decision is evidenced and the rejected options recorded, not that a particular threshold is met.
