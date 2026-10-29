# Agent Test Spec: devops-engineer

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Owns hosting, CI/CD, environments, secrets and deploys: build pipelines, preview and staging environments, deployment to Shopify development stores, and a rollback path that has been tested rather than imagined. A deploy is done when the app runs, the health check passes and rollback is available.

**Domain**: CI workflow files, hosting and environment config, secrets, deploy and rollback scripts
**Escalates to**: technical-director (infrastructure calls), producer (schedule)
**Delegates to**: tools-engineer (scripts), qa-tester (post-deploy smoke)
**Does not own**: application code behaviour, test strategy, or the store data itself

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/devops-engineer.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Make the deploy rollback-safe

**Scenario**: A deploy to the staging app broke the admin last week and recovery meant a manual rebuild.

**Fixture**:
- CI pipeline deploying on merge to `main`
- No rollback step
- Health endpoint exists but is unused

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Adds an artefact-based deploy, a post-deploy health check that fails the pipeline, and a rollback step that re-deploys the previous artefact; documents the secret layout without values
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Rollback is exercised once, not just documented, the health check gates the deploy, and no secret value appears in logs or the repo
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Change the app to retry the webhook with a backoff.

**Scenario**: A request that belongs to `webhooks-specialist`, not to this agent.

**Fixture**:
- Request: "Change the app to retry the webhook with a backoff."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `webhooks-specialist` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `webhooks-specialist`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — Deploy Gate — environment readiness

**Scenario**: Agent is invoked at its gate: pipeline steps, environment configuration parity, secret handling, health check and rollback availability

**Fixture**:
- Project state presented for review
- Gate ID: `DEPLOY-GATE`

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

### Case 4: Conflict Escalation — Retry logic at the wrong layer

**Scenario**: `webhooks-specialist` argues platform-level webhook retry plus a reconciliation job is correct; a 24-hour internal queue would hide failures.

**Fixture**:
- `webhooks-specialist` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to technical-director, with the delivery guarantees of each option
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Wire CI for a new app

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `lead-engineer`: the app's build commands, its target environments, and the existing pipeline template
- Sub-task: "add the app to CI with a staging deploy and a health check"

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
- [ ] Escalates conflicts to `technical-director (infrastructure calls), producer (schedule)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Hosting-specific behaviour needs a real deploy; the spec covers pipeline structure, secret hygiene and rollback.
