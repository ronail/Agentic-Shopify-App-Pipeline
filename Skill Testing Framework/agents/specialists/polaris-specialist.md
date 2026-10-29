# Agent Test Spec: polaris-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Implements the embedded admin UI with Polaris: components, layout, data tables, forms, modals, and the states around them. Does not invent visual language — Polaris is the design system, and the craft is using it precisely so the app feels native to the admin.

**Domain**: admin UI under `apps/<app>/app/routes/` and component files; Polaris usage
**Escalates to**: ux-lead (flow and IA), lead-engineer (code review)
**Delegates to**: app-bridge-specialist (host navigation), accessibility-specialist (audit)
**Does not own**: information architecture, host navigation and session tokens, API calls, or checkout/storefront surfaces

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/polaris-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Build the products index page

**Scenario**: A merchant needs to browse a synced catalog with search, filter, pagination and a bulk action.

**Fixture**:
- `ux-lead`'s flow spec naming the index as the post-onboarding landing screen
- Synced catalog of 12k products
- App Bridge already mounted

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Builds the page with Polaris `Page`, `IndexTable`, `Filters` and `EmptyState`, wires loading, empty and error states, and uses the host's bulk-action pattern instead of a custom toolbar
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Only Polaris components are used for structure and controls, all four states render, and bulk actions go through the documented Polaris pattern
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Get a session token for this fetch and redirect the merchant to the billing page.

**Scenario**: A request that belongs to `app-bridge-specialist`, not to this agent.

**Fixture**:
- Request: "Get a session token for this fetch and redirect the merchant to the billing page."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `app-bridge-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `app-bridge-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — UI Gate — admin screen review

**Scenario**: Agent is invoked at its gate: the screen against the flow spec, Polaris component choice, state coverage, and keyboard reachability

**Fixture**:
- Project state presented for review
- Gate ID: `UI-GATE`

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

### Case 4: Conflict Escalation — The flow spec needs a layout the design system does not have

**Scenario**: `ux-lead` wants a persistent side panel across the index; the Polaris layout primitives inside the iframe cannot express it without custom chrome.

**Fixture**:
- `ux-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to ux-lead, with the closest native pattern proposed and the visual cost stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Implement one screen from an approved flow

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `ux-lead`: the approved flow spec, the screen's states, and the component inventory in the app
- Sub-task: "implement the screen and its states"

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
- [ ] Escalates conflicts to `ux-lead (flow and IA), lead-engineer (code review)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Visual fidelity inside the real admin frame needs a live invocation; the spec covers component choice, states and interaction wiring.
