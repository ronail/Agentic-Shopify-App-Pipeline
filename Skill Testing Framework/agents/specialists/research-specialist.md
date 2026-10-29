# Agent Test Spec: research-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns Stage 1: proves a merchant problem is worth an app, maps the apps already solving it, and sizes the wedge before anyone creates `apps/<app-name>/`. Every claim carries a source URL and an access date; anything unverified goes under open questions.

**Domain**: `production/research/<app-slug>/` — findings and competitor matrix
**Escalates to**: product-director
**Delegates to**: growth-lead (pricing and funnel), app-store-reviewer (listing claims)
**Does not own**: product scope, app code, ADRs, listing copy, or pricing decisions

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/research-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Validate a merchant problem

**Scenario**: `request.md` proposes an app for bulk variant pricing; nobody has checked whether merchants ask for it or which apps already do it.

**Fixture**:
- `request.md` and `request-history.md` at HEAD
- App Store category listing for the relevant category
- No `apps/` directory for this slug

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Re-reads the current request files, builds a sourced claim table, maps competing apps with their review complaints, and states whether the evidence supports an original app or a competitor killer
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Every factual claim has a URL and access date, unverified items sit under open questions, and the recommendation names which framing the evidence supports
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Amend request.md to include this problem.

**Scenario**: A request that belongs to `product-director`, not to this agent.

**Fixture**:
- Request: "Amend request.md to include this problem."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `product-director` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `product-director`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Research Gate — findings before scaffolding

**Scenario**: Agent is invoked at its gate: the findings document's sourcing, the competitor matrix coverage, and whether the recommendation follows from the claim table

**Fixture**:
- Project state presented for review
- Gate ID: `RESEARCH-GATE`

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

### Case 4: Conflict Escalation — Evidence points at a different problem than the accepted one

**Scenario**: The research suggests merchants care about a related pain the accepted request does not mention.

**Fixture**:
- `product-director` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to product-director, as a request amendment — never an edit to `request.md` by this agent
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Research one candidate problem

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `product-director`: the problem statement under consideration and the repository's accepted request
- Sub-task: "produce the findings and competitor matrix for it"

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
- [ ] Escalates conflicts to `product-director`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Market size and demand estimates are inherently unverifiable; the spec asserts sourcing discipline and the open-questions separation.
