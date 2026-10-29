# Agent Test Spec: api-lead

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-10-29

## Agent Summary

Owns the Shopify API surface, not the query shape: which Admin GraphQL and Storefront API version each app pins, what that version deprecates, and when a migration is scheduled. Maintains the append-only schema snapshots under `docs/shopify-api-reference/`.

**Domain**: `docs/shopify-api-reference/<version>/`, the `api_version` pin in each `apps/<app>/shopify.app.toml`
**Escalates to**: technical-director
**Delegates to**: graphql-specialist, webhooks-specialist, billing-specialist, auth-specialist
**Does not own**: query cost, pagination, webhook delivery, charge mechanics, or OAuth flow

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/api-lead.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Plan a version migration

**Scenario**: App-x is pinned to a version Shopify retires in two quarters, and the snapshot shows three fields the app uses.

**Fixture**:
- `apps/app-x/shopify.app.toml` pinning the retiring version
- Snapshot of the target version under `docs/shopify-api-reference/`
- Deprecated-field list for the pinned version

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Names the fields that break, the scopes affected, the migration order, and the date the pin must move; writes the plan rather than editing historical snapshots
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every deprecation cited exists in the pinned snapshot, the snapshot for the old version is untouched, and the migration is scheduled with an owner
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Rewrite this catalog export query so it stays under the cost limit.

**Scenario**: A request that belongs to `graphql-specialist`, not to this agent.

**Fixture**:
- Request: "Rewrite this catalog export query so it stays under the cost limit."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `graphql-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `graphql-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — API Version Gate — pin reviewed before release

**Scenario**: Agent is invoked at its gate: each app's `api_version` pin against the snapshot and deprecation list for that version, and whether a migration is scheduled

**Fixture**:
- Project state presented for review
- Gate ID: `API-VERSION-GATE`

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

### Case 4: Conflict Escalation — A field only exists in an unstable version

**Scenario**: `growth-lead` wants a feature that requires a field shipped only in an unstable API version; `api-lead` will not pin unstable for a public app.

**Fixture**:
- `growth-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the feature deferred or the field approximated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — State the pin and its exposure

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `technical-director`: the target app, its current pin, and the snapshot directory listing
- Sub-task: "report the pin, the deprecations it faces, and the migration deadline"

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
- [ ] Escalates conflicts to `technical-director`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Snapshot freshness depends on Shopify's release cadence; the spec asserts the agent reads the snapshot rather than writing version numbers from memory.
