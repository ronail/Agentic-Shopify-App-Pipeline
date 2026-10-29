# Agent Test Spec: release-manager

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Owns the path from a green build to a live listing: versioning, listing assets and copy, review requirements, release gates, staged rollout, and release-day coordination. Nothing should reach the reviewer twice — a rejection costs days.

**Domain**: versioning, listing assets, `production/release/<app-slug>/`, submission and rollout
**Escalates to**: producer (schedule), app-store-reviewer (readiness)
**Delegates to**: app-store-reviewer, devops-engineer, community-manager (changelog)
**Does not own**: the technical fixes behind a rejection, readiness judgement, or the store used to test

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/release-manager.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Prepare a first submission

**Scenario**: The app is green in a dev store and `app-store-reviewer` has not yet signed off; the listing copy is half written.

**Fixture**:
- Green CI on the release branch
- Listing draft with an unsubstantiated claim
- No version tag

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Builds the submission checklist (version, listing assets, screenshots, privacy policy, mandatory webhooks, test instructions), sequences it against the reviewer sign-off, and holds the submission while a blocker is open
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every checklist item names its owner and evidence, the unsubstantiated claim is removed, and submission is blocked until `app-store-reviewer` passes it
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Fix the OAuth callback that fails on reinstall.

**Scenario**: A request that belongs to `auth-specialist`, not to this agent.

**Fixture**:
- Request: "Fix the OAuth callback that fails on reinstall."
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

### Case 3: Gate Verdict — Release Gate — submission readiness

**Scenario**: Agent is invoked at its gate: version bump, listing assets, reviewer test instructions, and whether every blocking finding from `app-store-reviewer` is closed

**Fixture**:
- Project state presented for review
- Gate ID: `RELEASE-GATE`

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

### Case 4: Conflict Escalation — Ship date pressure vs. an open blocker

**Scenario**: `producer` wants the submission to go out today; one blocking review finding is still open.

**Fixture**:
- `producer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with the rejection risk and the delay cost stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Cut a release

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `producer`: the milestone scope, the release branch, and the reviewer's readiness report
- Sub-task: "prepare and submit the release"

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
- [ ] Escalates conflicts to `producer (schedule), app-store-reviewer (readiness)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Review latency and rejection reasons are outside the repo; the spec covers checklist completeness and gate discipline.
