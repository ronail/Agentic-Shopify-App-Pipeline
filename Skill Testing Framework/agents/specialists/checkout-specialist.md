# Agent Test Spec: checkout-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns the checkout surface: checkout UI extensions, the targets they render into, what they are allowed to do, the declared network path, and whether the store's plan is even eligible. The retired checkout template path is named as a dead end, never implemented.

**Domain**: checkout UI extensions under `extensions/<name>/`, extension targets, network access declaration
**Escalates to**: lead-engineer (code review), technical-director (eligibility blockers)
**Delegates to**: graphql-specialist (network payload shape), growth-lead (upsell offer)
**Does not own**: the pricing decision behind an upsell, the charge flow, storefront theme blocks, or release submission

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/checkout-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Add a post-purchase upsell block

**Scenario**: The merchant wants an offer rendered on the checkout's thank-you step, on a plan that supports checkout extensibility.

**Fixture**:
- Store on a plan with checkout extensibility
- Extension scaffold absent
- Offer data available from the app server

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Checks eligibility first, picks the declared target, builds the extension's states (offer, declined, nothing to show), and declares the network access it uses
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Eligibility is verified before implementation, the target is one that exists for that surface, the empty state renders nothing, and no retired template customization is used
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Set the upsell price at 15% off the cart subtotal.

**Scenario**: A request that belongs to `growth-lead`, not to this agent.

**Fixture**:
- Request: "Set the upsell price at 15% off the cart subtotal."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `growth-lead` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `growth-lead`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Checkout Gate — extension readiness

**Scenario**: Agent is invoked at its gate: target validity, plan eligibility, network access declaration, and the extension's rendered states including the empty one

**Fixture**:
- Project state presented for review
- Gate ID: `CHECKOUT-GATE`

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

### Case 4: Conflict Escalation — A target that cannot do what the offer needs

**Scenario**: `growth-lead`'s offer needs cart mutation at a target that only receives read props.

**Fixture**:
- `growth-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the achievable targets listed
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Implement one checkout extension

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `app-architect`: the ADR's checkout module boundary and the eligible target list
- Sub-task: "build the extension and declare its network access"

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
- [ ] Escalates conflicts to `lead-engineer (code review), technical-director (eligibility blockers)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Extension behaviour requires a dev store with checkout extensibility enabled; the spec covers eligibility, target choice and state handling.
