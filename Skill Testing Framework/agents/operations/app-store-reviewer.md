# Agent Test Spec: app-store-reviewer

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

The role that says 'this is not ready' before a Shopify reviewer says it: audits the app against current App Store requirements, the listing as written, and the behaviour a reviewer actually exercises — mandatory privacy webhooks, billing through Shopify, unused scopes, clean-install behaviour, uninstall data handling.

**Domain**: `production/review/<app-slug>/` readiness report and listing copy
**Escalates to**: release-manager (submission), the user (a finding that blocks)
**Delegates to**: auth-specialist, billing-specialist, webhooks-specialist for the fixes
**Does not own**: the technical fix, the pricing model, the release mechanics, or the store used to test

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/app-store-reviewer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Audit a listing before submission

**Scenario**: The listing claims a feature the app has and a second one it half-has; the app requests a scope it never uses.

**Fixture**:
- Listing draft with two claims
- `shopify.app.toml` scopes including `write_customers`
- Dev store where the reviewer will install clean

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Checks each claim against the app, names the unused scope as a finding, verifies mandatory compliance webhooks exist, and produces a readiness report citing the requirement behind each finding
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every finding cites a requirement, the halved claim is removed or the feature finished, and the verdict is explicit (ready / not ready)
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Change the pricing to a usage-based model.

**Scenario**: A request that belongs to `growth-lead`, not to this agent.

**Fixture**:
- Request: "Change the pricing to a usage-based model."
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

### Case 3: Gate Verdict — Submission Gate — readiness verdict

**Scenario**: Agent is invoked at its gate: the app against the current requirements list, the listing as written, and a clean-install walkthrough on a dev store

**Fixture**:
- Project state presented for review
- Gate ID: `SUBMISSION-GATE`

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

### Case 4: Conflict Escalation — Deadline vs. an unresolved finding

**Scenario**: `release-manager` wants to submit despite an open finding about uninstall leaving merchant data orphaned.

**Fixture**:
- `release-manager` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to the user, with the rejection risk stated — the finding is not waived
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Review the submission package

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `release-manager`: the listing draft, the scope list, and the reviewer test instructions
- Sub-task: "produce the readiness report"

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
- [ ] Escalates conflicts to `release-manager (submission), the user (a finding that blocks)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Shopify's requirements list changes; the spec asserts the agent re-reads it per submission rather than recalling it.
