# Agent Test Spec: graphql-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns how an app talks to the Admin API: query and mutation shape, cost-based throttling, cursor pagination, bulk operations, and reading `userErrors` instead of assuming a 200 means success.

**Domain**: GraphQL documents, client code that issues them, cost and pagination behaviour
**Escalates to**: api-lead (version surface), lead-engineer (code review)
**Delegates to**: tools-engineer (codegen), performance-analyst (latency measurement)
**Does not own**: API version pins, auth and token retrieval, webhook delivery, or charge mutations

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/graphql-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Export a 40k-product catalog

**Scenario**: The app must export the whole catalog nightly without tripping the throttle.

**Fixture**:
- Store with 40k products and 90k variants
- Cost-based throttle bucket, refilling per second
- Pinned API version with `bulkOperationRunQuery` available

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Chooses a bulk operation over paged queries, handles the operation's async lifecycle and the resulting JSONL, and states the cost reasoning rather than guessing
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Bulk operation is used (not offset paging), the poll/complete path is handled, and throttle state is read from the response rather than assumed
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Is `productVariantsBulkUpdate` available in our pinned version?

**Scenario**: A request that belongs to `api-lead`, not to this agent.

**Fixture**:
- Request: "Is `productVariantsBulkUpdate` available in our pinned version?"
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

### Case 3: Gate Verdict — Query Review Gate — before a query ships

**Scenario**: Agent is invoked at its gate: requested cost against the app's budget on a busy store, pagination strategy, and whether `userErrors` are read and surfaced

**Fixture**:
- Project state presented for review
- Gate ID: `QUERY-GATE`

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

### Case 4: Conflict Escalation — Correct query vs. an unaffordable one

**Scenario**: `performance-analyst` wants one large query to cut round trips; the query's requested cost exceeds the bucket on a busy store.

**Fixture**:
- `performance-analyst` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to lead-engineer, with the measured cost of both shapes
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Fix a slow catalog read

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `lead-engineer`: the failing query, its response cost, and the app's throttle budget
- Sub-task: "rewrite the query to fit the budget without changing its result set"

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
- [ ] Escalates conflicts to `api-lead (version surface), lead-engineer (code review)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Throttle behaviour under real merchant load needs a live store; the spec asserts cost awareness, pagination choice and error handling.
