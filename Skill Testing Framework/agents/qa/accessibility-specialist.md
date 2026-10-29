# Agent Test Spec: accessibility-specialist

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-10-29

## Agent Summary

Gatekeeper that a merchant on a keyboard, a screen reader, or 200% zoom can complete the app's core workflow without workarounds: focus management, semantics, contrast, text scaling and reduced-motion handling in the embedded admin.

**Domain**: accessibility audits, keyboard/focus behaviour, semantics and contrast findings
**Escalates to**: ux-lead (flow intent), qa-lead (release gate)
**Delegates to**: polaris-specialist for the fixes
**Does not own**: visual design, flow design, or the implementation of fixes

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/accessibility-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `haiku`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Audit the core workflow with a keyboard

**Scenario**: A merchant must sync a catalog, filter it and edit one product using only a keyboard and a screen reader.

**Fixture**:
- Embedded admin with a filter form, an index table and a modal editor
- No focus management on modal open/close
- Icon-only action buttons

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Walks the workflow, records focus order and traps, names unlabelled controls, checks contrast and 200% zoom reflow, and returns a blocking/non-blocking finding list
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Each finding names the element, the criterion and the user impact, and any blocking defect is marked blocking
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Choose a Polaris pattern for the filter bar.

**Scenario**: A request that belongs to `polaris-specialist`, not to this agent.

**Fixture**:
- Request: "Choose a Polaris pattern for the filter bar."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `polaris-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `polaris-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Accessibility Gate — blocking defects

**Scenario**: Agent is invoked at its gate: the core workflow (not every screen) for keyboard reachability, focus management, accessible names, contrast and reflow

**Fixture**:
- Project state presented for review
- Gate ID: `A11Y-GATE`

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

### Case 4: Conflict Escalation — An accessible flow is uglier

**Scenario**: `ux-lead`'s design uses a colour-only status indicator and a custom dropdown that drops focus.

**Fixture**:
- `ux-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to ux-lead, with the passing alternative proposed rather than the design vetoed
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Check one screen before release

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `qa-lead`: the screen's flow and the accessibility checklist
- Sub-task: "run the audit and report blocking findings"

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
- [ ] Escalates conflicts to `ux-lead (flow intent), qa-lead (release gate)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Screen-reader behaviour varies by platform and browser; the spec covers structure, focus and the blocking/non-blocking split.
