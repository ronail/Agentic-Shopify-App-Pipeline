# Agent Test Spec: billing-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns how an app charges a merchant: subscription and usage charges, trials, plan replacement and cancellation, and feature gating on the plan Shopify reports rather than a cached row that drifted. External checkout for app features is a submission blocker and is named as such.

**Domain**: billing code, charge mutations, plan gating reads, `apps/<app>/shopify.app.toml` billing config
**Escalates to**: lead-engineer (code review), growth-lead (pricing)
**Delegates to**: graphql-specialist (charge mutations), app-store-reviewer (compliance check)
**Does not own**: what plans are worth, OAuth that authorizes a charge, the API version pin, or the paywall design

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/billing-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Add a 14-day trial with a usage cap

**Scenario**: The app needs a trial, a capped usage charge for overage, and a gate that hides the advanced feature while on trial.

**Fixture**:
- `growth-lead`'s pricing doc: one plan, 14-day trial, capped usage at 1,000 units
- Development charge available for testing
- Existing subscription created with `appSubscriptionCreate`

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Implements create/replace with trial days, the capped usage record path, and a gate that reads the active subscription from Shopify; tests with a development charge first
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Plan state is read from Shopify, not a local column; upgrade replaces rather than stacks charges; the cap is enforced server-side
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Which plan should cost $19 and which $49?

**Scenario**: A request that belongs to `growth-lead`, not to this agent.

**Fixture**:
- Request: "Which plan should cost $19 and which $49?"
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

### Case 3: Gate Verdict — Billing Gate — charge flow before submission

**Scenario**: Agent is invoked at its gate: every paid feature against a Shopify charge, the confirmation and cancellation paths, and whether the merchant can be double-charged or locked out

**Fixture**:
- Project state presented for review
- Gate ID: `BILLING-GATE`

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

### Case 4: Conflict Escalation — The paywall screen vs. the plan state

**Scenario**: `polaris-specialist` renders the paywall from a local `plan` field for speed; the field can lag the actual subscription after a cancellation.

**Fixture**:
- `polaris-specialist` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to lead-engineer, with the stale-read failure mode spelled out
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Gate a feature on the active plan

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `lead-engineer`: the feature flag, the app's subscription state source, and the pricing doc's tier mapping
- Sub-task: "implement the server-side gate and the paywall trigger"

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
- [ ] Escalates conflicts to `lead-engineer (code review), growth-lead (pricing)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Real charge settlement needs a live app listing; the spec covers the flows, gating source and failure paths.
