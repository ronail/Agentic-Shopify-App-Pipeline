# Agent Test Spec: lead-engineer

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-10-29

## Agent Summary

Turns ADRs into code structure, holds the blocking code-review gate, and keeps patterns consistent across admin, backend and webhook code so an engineer can move between apps without relearning the world.

**Domain**: code structure under `apps/<app>/` and `src/`, review verdicts, shared patterns
**Escalates to**: technical-director
**Delegates to**: polaris-specialist, graphql-specialist, webhooks-specialist, tools-engineer
**Does not own**: architecture decisions, API version pins, test strategy, or merchant UX

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/lead-engineer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `opus`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Review a webhook handler diff

**Scenario**: A diff adds an `orders/create` handler that acknowledges immediately but re-parses the body after acknowledging.

**Fixture**:
- Diff touching one handler and one test
- ADR-0007 requires idempotent handlers and HMAC verification over the raw body
- Existing handler pattern in the same module

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Reviews against the ADR and the existing pattern, gives a blocking verdict with file-and-line findings, and names the owning specialist for the substantive fix
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Verdict is explicit (approve / block), findings reference the ADR or pattern they violate, and no code is rewritten inside the review
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Decide whether app-x moves to the 2026-01 API version.

**Scenario**: A request that belongs to `api-lead`, not to this agent.

**Fixture**:
- Request: "Decide whether app-x moves to the 2026-01 API version."
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

### Case 3: Gate Verdict — Code Review Gate — blocking

**Scenario**: Agent is invoked at its gate: a diff is checked against the in-force ADRs, established patterns, idempotency and error-handling rules, and whether tests cover the change

**Fixture**:
- Project state presented for review
- Gate ID: `CODE-REVIEW`

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

### Case 4: Conflict Escalation — Module boundary dispute with App Architect

**Scenario**: `app-architect` has put webhook consumers inside the app server module; `lead-engineer` wants them extracted so a handler failure cannot take the admin down.

**Fixture**:
- `app-architect` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the ADR amended rather than the code diverging quietly
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Implement an accepted ADR

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `app-architect`: ADR-0007 (accepted) with its module list, the app's current layout, and the pattern doc
- Sub-task: "turn the ADR into a module skeleton and assign the implementation slices"

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

Review quality depends on real diffs; the spec asserts the verdict and finding structure, not the reviewer's taste.
