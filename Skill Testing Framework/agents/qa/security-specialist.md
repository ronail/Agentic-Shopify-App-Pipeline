# Agent Test Spec: security-specialist

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-10-29

## Agent Summary

Protects merchant data, app integrity and store trust, with veto power over data handling and auth flows. In an embedded app the threat model is concrete: leaked access tokens, over-broad scopes, unverified webhooks, and merchant data retained longer than disclosed.

**Domain**: threat model, scope minimisation, secret handling, data retention and deletion, security review verdicts
**Escalates to**: technical-director (risk acceptance), the user (a veto)
**Delegates to**: auth-specialist, webhooks-specialist for the fixes
**Does not own**: the implementation of a flow, product scope, or submission logistics

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/security-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Audit handling of merchant data

**Scenario**: The app stores customer emails for a feature that needs only a customer ID, with no retention limit.

**Fixture**:
- Data model storing customer email and order history
- Privacy policy claiming minimal retention
- Mandatory data-request webhooks implemented

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Maps each stored field to the feature that needs it, flags the email and the missing retention window as findings with severity, and states the deletion path the data-request webhook must take
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every retained field has a stated purpose, retention and deletion are defined, and findings cite the claim they contradict
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Add the consent screen styling to match the new admin design.

**Scenario**: A request that belongs to `polaris-specialist`, not to this agent.

**Fixture**:
- Request: "Add the consent screen styling to match the new admin design."
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

### Case 3: Gate Verdict — Security Gate — veto on data handling and auth

**Scenario**: Agent is invoked at its gate: scope minimisation against used features, token storage and logging, webhook verification, retention and deletion paths

**Fixture**:
- Project state presented for review
- Gate ID: `SECURITY-GATE`

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

### Case 4: Conflict Escalation — A finding that blocks the release date

**Scenario**: `release-manager` argues an unverified webhook endpoint is low risk because the topic is only used internally.

**Fixture**:
- `release-manager` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with the exposure and the fix cost — a veto is used with evidence and a fix, not as a stall
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Review an auth flow change

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `auth-specialist`: the proposed token exchange flow, storage plan, and the app's threat model
- Sub-task: "review it and give a verdict"

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
- [ ] Escalates conflicts to `technical-director (risk acceptance), the user (a veto)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Exploitable defects need adversarial testing; the spec covers the review criteria and veto discipline.
