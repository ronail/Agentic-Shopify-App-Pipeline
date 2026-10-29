# Agent Test Spec: webhooks-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns every event an app receives and every event it misses: topic declaration, HMAC verification over the raw body, idempotent handlers, retry behaviour, mandatory compliance topics, and the backfill that reconciles state after a gap.

**Domain**: webhook declarations in `shopify.app.toml`, handler code, reconciliation jobs
**Escalates to**: lead-engineer (code review), security-specialist (verification defects)
**Delegates to**: graphql-specialist (backfill queries), devops-engineer (queue and retries)
**Does not own**: API version pins, the auth handshake, charge state, or the admin screen that shows webhook health

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/webhooks-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Handle orders/create idempotently

**Scenario**: Shopify delivers the same `orders/create` twice, 30 seconds apart, and a third time after a retry window.

**Fixture**:
- Subscription declared in `shopify.app.toml`
- Existing handler that writes an order row and sends a merchant email
- No dedupe key stored

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Verifies HMAC over the raw body, derives an idempotency key from the payload, acknowledges fast, and moves slow work off the request path
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Verification happens before parsing, the duplicate delivery produces no second write and no second email, and the ack does not wait on slow work
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Where does the offline access token get stored and rotated?

**Scenario**: A request that belongs to `auth-specialist`, not to this agent.

**Fixture**:
- Request: "Where does the offline access token get stored and rotated?"
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `auth-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `auth-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Webhook Gate — subscription and handler review

**Scenario**: Agent is invoked at its gate: every declared topic against the handlers that exist, mandatory compliance topics, HMAC verification placement, and idempotency

**Fixture**:
- Project state presented for review
- Gate ID: `WEBHOOK-GATE`

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

### Case 4: Conflict Escalation — Retry policy vs. platform retry window

**Scenario**: `devops-engineer` wants a 24-hour internal retry queue; the agent argues the platform's own retry window and a reconciliation job are the correct recovery path.

**Fixture**:
- `devops-engineer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the delivery guarantees of each option
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Add a compliance webhook

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `api-lead`: the app's current subscriptions and the mandatory compliance topic list for the pinned version
- Sub-task: "declare and implement the required compliance topic"

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
- [ ] Escalates conflicts to `lead-engineer (code review), security-specialist (verification defects)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Delivery loss and duplicate timing are platform behaviours that need a dev store to exercise; the spec covers verification, idempotency and backfill design.
