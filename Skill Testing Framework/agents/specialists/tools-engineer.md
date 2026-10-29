# Agent Test Spec: tools-engineer

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Builds the internal tooling that makes every other agent faster: app scaffolding, Shopify CLI workflows, dev-store automation, seeding, GraphQL type codegen, and the scripts that collapse a ten-step manual procedure into one command.

**Domain**: `scripts/`, `tools/`, scaffolding templates, local environment setup, codegen config
**Escalates to**: lead-engineer
**Delegates to**: devops-engineer (CI wiring), test-store-manager (store automation)
**Does not own**: app feature code, CI/CD pipeline ownership, or test strategy

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/tools-engineer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Collapse dev-store setup into one command

**Scenario**: Every new app needs a store, seeded data, an app install and a scope grant before anyone can test.

**Fixture**:
- Existing manual runbook with eleven steps
- Shopify CLI available
- `test-store-manager`'s register format

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Writes a single idempotent script that performs the steps, prints what it did, and fails loudly at the first step that cannot complete
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Re-running the script is safe, failures name the step, no secrets are echoed, and the runbook is updated to point at the script
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Set up the CI pipeline for the new app.

**Scenario**: A request that belongs to `devops-engineer`, not to this agent.

**Fixture**:
- Request: "Set up the CI pipeline for the new app."
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

### Case 3: Gate Verdict — Tooling Gate — script review

**Scenario**: Agent is invoked at its gate: idempotency, secret handling, discoverability (help text and README entry), and whether it duplicates an existing script

**Fixture**:
- Project state presented for review
- Gate ID: `TOOL-GATE`

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

### Case 4: Conflict Escalation — Two scripts that do the same thing

**Scenario**: `devops-engineer` has a deploy script that re-implements the store-reset logic the new tool also contains.

**Fixture**:
- `devops-engineer` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to lead-engineer, to pick one owner and delete the other
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Script a repetitive manual step

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `qa-tester`: the manual steps from a regression pass and the store register entry used
- Sub-task: "turn the repeated steps into one script"

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
- [ ] Escalates conflicts to `lead-engineer`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Local environment variance (shell, CLI version) needs a real machine; the spec covers idempotency, failure reporting and secret hygiene.
