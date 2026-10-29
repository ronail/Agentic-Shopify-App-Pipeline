# Agent Test Spec: test-store-manager

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Owns the stores the pipeline tests against: which development store belongs to which app, what data it holds, who can reach it, and how it is reset or retired. Keeps the register under `production/stores/` as the source of truth so tests cannot pass for the wrong reason.

**Domain**: `production/stores/` register, store provisioning, seed data profiles, staff access, resets
**Escalates to**: `devops-engineer` (deploy), `qa-lead` (test plan)
**Delegates to**: tools-engineer (automation), qa-tester (store usage)
**Does not own**: the deploy, the test plan, the install flow, or submission review

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/test-store-manager.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Provision a store for a new app

**Scenario**: A new app needs a development store with a repeatable seed set before QA can run anything.

**Fixture**:
- Empty register
- Seed profile needed: products, variants, collections, orders, customers, discounts
- App scopes change during development

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Provisions the store, records handle, owner app, plan, scopes, seed profile and last reset in the register, loads the seed set, and re-installs the app after a scope change so consent is genuinely exercised
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] The register entry precedes use, seed data is reproducible, and no destructive action touches a store that is not in the register
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Deploy the new build to staging.

**Scenario**: A request that belongs to `devops-engineer`, not to this agent.

**Fixture**:
- Request: "Deploy the new build to staging."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `devops-engineer` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `devops-engineer`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Store Gate — store state before a test pass

**Scenario**: Agent is invoked at its gate: the store's registered state (seed profile, scopes, install status) against what the test plan assumes

**Fixture**:
- Project state presented for review
- Gate ID: `STORE-GATE`

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

### Case 4: Conflict Escalation — A test needs data the seed set does not have

**Scenario**: `qa-tester` wants to hand-create orders on the shared store; the register says the seed profile is the only sanctioned source.

**Fixture**:
- `qa-tester` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to qa-lead, to extend the seed profile instead of ad-hoc data
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Reset a store between passes

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `qa-lead`: the store register entry and the seed profile used by the last pass
- Sub-task: "reset the store to its registered state"

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
- [ ] Escalates conflicts to ``devops-engineer` (deploy), `qa-lead` (test plan)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Real store provisioning needs partner access; the spec covers register discipline, seed reproducibility and teardown safety.
