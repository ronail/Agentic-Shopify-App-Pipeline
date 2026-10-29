# Agent Test Spec: app-bridge-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns the client half of the embedded admin: loading App Bridge correctly, attaching a session token to each request, navigating inside the admin without breaking the iframe, and using host surfaces (modal, toast, resource picker, title bar) instead of reimplementing them.

**Domain**: App Bridge script and meta setup, client-side navigation, host UI surfaces, iframe constraints
**Escalates to**: lead-engineer (code review), ux-lead (interaction intent)
**Delegates to**: auth-specialist (server-side verification), polaris-specialist (screen components)
**Does not own**: server-side token verification and scope consent, Polaris components, information architecture, or the API version pin

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/app-bridge-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Navigate and show a toast without reloading the frame

**Scenario**: After saving a settings form, the app must confirm success and move the merchant to the next screen without a full page reload.

**Fixture**:
- Embedded app with App Bridge loaded from the pinned script URL
- Save handler returning success
- Current code doing `window.location.assign` on save

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Replaces the reload with the host's navigation API, uses the host toast for the confirmation, and keeps a functional path when the app is loaded outside the admin
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] No top-level navigation or page reload is introduced, the host surface is used for the confirmation, and the non-embedded path still works
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Verify the session token on the server before trusting the shop.

**Scenario**: A request that belongs to `auth-specialist`, not to this agent.

**Fixture**:
- Request: "Verify the session token on the server before trusting the shop."
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

### Case 3: Gate Verdict — Embed Gate — App Bridge integration review

**Scenario**: Agent is invoked at its gate: script and meta setup, token attachment on every request, navigation primitives, and whether host UI is reimplemented by hand

**Fixture**:
- Project state presented for review
- Gate ID: `EMBED-GATE`

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

### Case 4: Conflict Escalation — Custom chrome vs. the host surface

**Scenario**: `polaris-specialist` wants a custom save bar to match the flow spec; the host already provides one that behaves correctly on unsaved changes.

**Fixture**:
- `polaris-specialist` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to ux-lead, with the behavioural cost of the custom bar stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Wire the embedded shell

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `polaris-specialist`: the app's route list and the host surfaces the flows depend on
- Sub-task: "wire App Bridge and the navigation/toast calls those routes need"

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
- [ ] Escalates conflicts to `lead-engineer (code review), ux-lead (interaction intent)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

App Bridge method names change between major versions; the spec asserts the agent checks the pinned docs rather than recalling the API.
