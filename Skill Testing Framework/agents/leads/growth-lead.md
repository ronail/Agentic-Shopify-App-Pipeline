# Agent Test Spec: growth-lead

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-10-29

## Agent Summary

Owns everything between 'the app works in a dev store' and 'merchants install it, keep it, and pay for the right plan': the install funnel, pricing and packaging, the listing's value proposition, and the retention signals that justify another quarter of work.

**Domain**: `production/growth/<app-slug>/` — pricing and packaging, onboarding spec, funnel definition
**Escalates to**: product-director (scope), the user (pricing)
**Delegates to**: analytics-engineer, billing-specialist, app-store-reviewer
**Does not own**: charge mechanics, admin screen design, submission requirements, or product scope

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/growth-lead.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Price a new app in tiers

**Scenario**: An app with one core feature and one advanced feature needs a pricing model a solo founder can operate.

**Fixture**:
- Feature list with the two candidate gates
- Competitor pricing from the research competitor matrix
- Billing API supports subscription and usage charges

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Proposes tiers with the gate per tier, the trial length, the usage metric if any, and the activation event the funnel will measure; names what each claim requires the app to prove
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every tier maps to a feature the app actually has, the pricing document states which claims are unsubstantiated, and no charge mechanic is specified
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Implement the subscription charge and plan gating.

**Scenario**: A request that belongs to `billing-specialist`, not to this agent.

**Fixture**:
- Request: "Implement the subscription charge and plan gating."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `billing-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `billing-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Pricing Gate — packaging before submission

**Scenario**: Agent is invoked at its gate: the pricing and packaging document against substantiated listing claims, the Shopify billing rule, and the funnel's defined activation event

**Fixture**:
- Project state presented for review
- Gate ID: `PRICING-GATE`

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

### Case 4: Conflict Escalation — A growth idea needs a feature nobody scoped

**Scenario**: The funnel would convert better with a bulk-edit screen that is not in the accepted scope.

**Fixture**:
- `product-director` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to product-director, as a written feature request — not a quiet scope expansion
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Define the funnel for an app

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `product-director`: the accepted problem statement and the app's feature list
- Sub-task: "define the install funnel, the activation event, and the pricing proposal"

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
- [ ] Escalates conflicts to `product-director (scope), the user (pricing)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Retention and churn numbers need real installs; the spec asserts the definitions and event names, not realised revenue.
