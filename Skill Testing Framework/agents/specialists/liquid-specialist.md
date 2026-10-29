# Agent Test Spec: liquid-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns what an app puts on the storefront: theme app extensions, app blocks and embed blocks, block schema settings, section rendering after cart changes, and the scoping that stops app output from leaking into the merchant's theme.

**Domain**: theme app extensions under `extensions/<name>/`, block Liquid, block schema, scoped CSS/JS
**Escalates to**: lead-engineer (code review), checkout-specialist (checkout boundary)
**Delegates to**: localization-lead (translated block copy), performance-analyst (block render cost)
**Does not own**: app server API calls, embedded admin screens, checkout-surface work, or localized copy decisions

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/liquid-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Ship an app block into the product page

**Scenario**: A merchant wants the app's recommendation widget placeable in the product template via the theme editor.

**Fixture**:
- Theme app extension scaffold with one app block
- Merchant on an Online Store 2.0 theme
- Widget data fetched from the app server at render time

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Defines the block schema (settings, presets, limits), renders inside the merchant's section, scopes CSS/JS, and degrades to nothing when the block is removed or the app uninstalled
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] No merchant theme file is edited, the block renders nothing when unconfigured, and styles are scoped to the block
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Change the storefront's product page layout to make room for the widget.

**Scenario**: A request that belongs to `ux-lead`, not to this agent.

**Fixture**:
- Request: "Change the storefront's product page layout to make room for the widget."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `ux-lead` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `ux-lead`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Storefront Gate — block review

**Scenario**: Agent is invoked at its gate: block schema validity, removal and uninstall behaviour, render cost, and whether anything depends on editing theme files

**Fixture**:
- Project state presented for review
- Gate ID: `STOREFRONT-GATE`

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

### Case 4: Conflict Escalation — Refresh a block after a cart change

**Scenario**: `performance-analyst` wants the block to poll for updates; the agent wants section rendering on the cart-change event.

**Fixture**:
- `performance-analyst` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to lead-engineer, with the measured cost of both approaches
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Add a configurable block setting

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `ux-lead`: the flow spec's merchant-facing options and the existing block schema
- Sub-task: "add the settings to the block schema and render them"

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
- [ ] Escalates conflicts to `lead-engineer (code review), checkout-specialist (checkout boundary)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Theme-editor behaviour across themes needs a real store and theme; the spec covers schema, scoping and degradation.
