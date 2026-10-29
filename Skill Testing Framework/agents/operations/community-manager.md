# Agent Test Spec: community-manager

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Owns everything a merchant reads from us: support replies, App Store review responses, changelog entries, launch announcements, and the honest explanation when something breaks. Also routes merchant-reported bugs and feature requests to the agents that own them.

**Domain**: support and review replies, changelog and announcements, feedback intake and routing
**Escalates to**: producer (unroutable feedback), product-director (feature requests)
**Delegates to**: qa-tester (bug reproduction), release-manager (release notes)
**Does not own**: technical fixes, roadmap decisions, or release scheduling

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/community-manager.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `haiku`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Answer a merchant whose sync failed

**Scenario**: A merchant writes that the catalog sync stopped yesterday and they have not heard back.

**Fixture**:
- Support thread with no incident link
- App status page showing a partial outage
- Known workaround documented internally

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Replies in the merchant's terms, states what happened and what to do now, gives a dated next update, and files the underlying bug for triage
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] The reply states impact and next step without internals or blame, the bug is routed with reproduction info, and no timeline is promised that has not been agreed
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Fix the sync job that times out on large catalogs.

**Scenario**: A request that belongs to `lead-engineer`, not to this agent.

**Fixture**:
- Request: "Fix the sync job that times out on large catalogs."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `lead-engineer` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `lead-engineer`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Comms Gate — release and review copy

**Scenario**: Agent is invoked at its gate: changelog and announcement copy against what actually shipped, and review replies against the App Store's response rules

**Fixture**:
- Project state presented for review
- Gate ID: `COMMS-GATE`

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

### Case 4: Conflict Escalation — A merchant asks for a feature we will not build

**Scenario**: The request is reasonable but outside `product-director`'s accepted scope.

**Fixture**:
- `product-director` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to product-director, as a logged request — no commitment is made in the reply
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Write the changelog for a release

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `release-manager`: the release's merged changes and the version tag
- Sub-task: "write the merchant-facing changelog entry"

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
- [ ] Escalates conflicts to `producer (unroutable feedback), product-director (feature requests)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Tone and trust are judgement calls; the spec covers accuracy, routing and commitment discipline.
