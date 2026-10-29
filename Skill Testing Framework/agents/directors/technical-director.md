# Agent Test Spec: technical-director

> **Tier**: directors
> **Category**: director
> **Spec written**: 2026-10-29

## Agent Summary

Owns architecture and technical risk across `apps/<app>/`: service boundaries, data model, API version policy, tech-debt trade-offs, and when a new Shopify platform capability is worth adopting. Authority is architectural — it sets constraints, not implementations.

**Domain**: architecture and service boundaries under `apps/<app>/`, `docs/architecture/`, shared code under `src/`
**Escalates to**: the user
**Delegates to**: app-architect, lead-engineer, api-lead, security-specialist
**Does not own**: implementation detail, per-screen merchant UX, test strategy, pricing, or release mechanics

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/technical-director.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `opus`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Take webhook processing off the request path

**Scenario**: A merchant with a large catalog times out during an import because webhook handling and the admin request share one process.

**Fixture**:
- Current single-process app under `apps/app-x/`
- Webhook topics: `products/update`, `orders/create`, `app/uninstalled`
- No queue in the stack today

**Expected behavior**:
1. Agent accepts the request as in-domain
2. States the constraint set (durable queue, at-least-once delivery, idempotency-key ownership, uninstall ordering) and records it as an ADR-ready decision, leaving module layout to `app-architect`
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] The trade-off accepted is named explicitly (operational complexity vs. request latency) and the ADR references the webhook delivery semantics it depends on
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Make the paywall screen less intimidating.

**Scenario**: A request that belongs to `ux-lead`, not to this agent.

**Fixture**:
- Request: "Make the paywall screen less intimidating."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `ux-lead` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `ux-lead`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Architecture Gate — ADR acceptance

**Scenario**: Agent is invoked at its gate: a `Proposed` ADR is reviewed for a complete Shopify API Surface section, its consequences, and whether it contradicts an accepted ADR

**Fixture**:
- Project state presented for review
- Gate ID: `ARCH-GATE`

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

### Case 4: Conflict Escalation — Lead Engineer disagrees with the imposed pattern

**Scenario**: `lead-engineer` argues the mandated repository layer will not fit the app's existing resolver structure and wants an exception.

**Fixture**:
- `lead-engineer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with the ADR amended or superseded rather than silently waived
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Milestone decision on the queue refactor

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `producer`: the milestone scope, the risk register, and the two ADRs in flight
- Sub-task: "decide whether the queue refactor lands this milestone or the next"

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
- [ ] Escalates conflicts to `the user`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Adoption calls for brand-new platform capabilities (e.g. a newly shipped extension target) depend on docs that move quarterly; the spec asserts the agent checks the pinned snapshot rather than recalling an API.
