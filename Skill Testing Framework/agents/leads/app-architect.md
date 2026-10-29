# Agent Test Spec: app-architect

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-10-29

## Agent Summary

Owns the architecture of a single app inside `apps/<app-name>/` and the per-app record set: how the app server, embedded admin, webhook consumers, theme extension and checkout extension divide responsibility, plus the ADRs, `requirements.yaml` and `control-manifest.md` that record it.

**Domain**: `docs/architecture/apps/<app>/` (ADRs, `requirements.yaml`, `control-manifest.md`), module boundaries inside `apps/<app>/`
**Escalates to**: technical-director
**Delegates to**: lead-engineer, api-lead, auth-specialist, billing-specialist
**Does not own**: API version pin, OAuth mechanics, query shape, billing mechanics, or merchant-facing UX

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/app-architect.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Record the app's surface split

**Scenario**: A new app needs its responsibilities assigned across the app server, embedded admin, webhook consumers and a theme app extension before any code is written.

**Fixture**:
- Empty `apps/app-x/` scaffold
- `requirements.yaml` with five `REQ-<AREA>-NNN` entries derived from the request

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Writes the ADR with Title, Status, Context, Decision, Consequences, ADR Dependencies, Shopify API Surface and App Requirements Addressed, names the specialist for each detailed concern, and leaves the ADR `Proposed` until the user accepts it
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Requirement IDs are referenced, not renumbered, each surface has one owning module, and no specialist's mechanics are decided in the ADR
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Implement the queue consumer the ADR describes.

**Scenario**: A request that belongs to `lead-engineer`, not to this agent.

**Fixture**:
- Request: "Implement the queue consumer the ADR describes."
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

### Case 3: Gate Verdict — ADR Gate — Proposed to Accepted

**Scenario**: Agent is invoked at its gate: an ADR is checked for a complete required-section set, a `Proposed`/`Accepted`/`Superseded` status that matches its state, and whether stories depend on it

**Fixture**:
- Project state presented for review
- Gate ID: `ADR-GATE`

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

### Case 4: Conflict Escalation — Where the API version pin lives

**Scenario**: `api-lead` treats the version pin as part of the API surface; `app-architect` treats it as app configuration that belongs in the app's control manifest.

**Fixture**:
- `api-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, and the answer is recorded as an ADR rather than a convention
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Per-app architecture for a new app

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `technical-director`: the accepted request, the platform constraints, and the two in-flight ADRs from other apps
- Sub-task: "produce the ADR set and `requirements.yaml` for the new app"

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

Long-lived ADR hygiene (supersession over time) is only partly observable in one pass; the spec asserts status discipline and ID append-only behaviour.
