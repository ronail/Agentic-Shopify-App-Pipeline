# Agent Test Spec: analytics-engineer

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Turns merchant behaviour into decisions: install funnel, activation and feature-usage events, retention and churn signals, billing metrics and dashboards. Owns the event schema and the metric definitions — if two people disagree about 'active merchant', that is fixed in writing here.

**Domain**: event schema, instrumentation code, metric definitions, dashboards, `production/analytics/`
**Escalates to**: lead-engineer (instrumentation review), growth-lead (what to measure)
**Delegates to**: polaris-specialist (client events), graphql-specialist (server-side events)
**Does not own**: what the funnel should be, pricing, or the product roadmap

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/analytics-engineer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Define and instrument the activation event

**Scenario**: `growth-lead` names 'first successful catalog sync' as activation; nothing emits it today.

**Fixture**:
- Funnel definition from `production/growth/<app-slug>/`
- App with install and sync paths
- No event pipeline

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Defines the event name, properties, identity key and where it fires, instruments both client and server paths without double counting, and writes the metric definition alongside
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] The event fires once per merchant activation, its properties match the written schema, and the definition disambiguates the ambiguous case
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Decide which tier the activation event should sit in.

**Scenario**: A request that belongs to `growth-lead`, not to this agent.

**Fixture**:
- Request: "Decide which tier the activation event should sit in."
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

### Case 3: Gate Verdict — Analytics Gate — schema review

**Scenario**: Agent is invoked at its gate: event names and properties against the written schema, identity handling, and whether a metric has one definition

**Fixture**:
- Project state presented for review
- Gate ID: `ANALYTICS-GATE`

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

### Case 4: Conflict Escalation — Two definitions of an active merchant

**Scenario**: `growth-lead` counts any install as active; the dashboard counts weekly sync activity.

**Fixture**:
- `growth-lead` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to product-director, with both definitions and their effect on the funnel
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Instrument one funnel step

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `growth-lead`: the funnel definition and the app's current events
- Sub-task: "add the event and the metric definition for that step"

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
- [ ] Escalates conflicts to `lead-engineer (instrumentation review), growth-lead (what to measure)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Real event volume and identity resolution need production traffic; the spec covers schema, placement and definition.
