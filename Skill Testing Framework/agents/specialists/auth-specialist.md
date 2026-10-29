# Agent Test Spec: auth-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-10-29

## Agent Summary

Owns the identity layer: OAuth install, scope consent, session-token verification for embedded requests, token exchange, token storage at rest, and the uninstall path that revokes and deletes credentials.

**Domain**: install and OAuth routes, session-token verification middleware, token storage, scope declarations in `shopify.app.toml`
**Escalates to**: security-specialist (threat model), lead-engineer (code review)
**Delegates to**: app-bridge-specialist (client token attach), tools-engineer (local OAuth harness)
**Does not own**: charge flow, API surface and version pin, App Bridge client wiring, or the app's broader threat model

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/auth-specialist.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Prove an embedded request is authenticated

**Scenario**: The embedded admin calls the app server; the request carries a session token issued by App Bridge.

**Fixture**:
- Embedded app with App Bridge mounted
- Session token in the `Authorization` header
- Token exchange enabled for online and offline tokens

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Verifies signature, issuer, audience, expiry and `shop` claim before trusting the request, exchanges for the access token it needs, and refuses the request otherwise
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] Verification precedes any `shop`-scoped read, failure returns 401 without leaking detail, and offline tokens are used for background work rather than the online token
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Which scopes should the app request for the products feature?

**Scenario**: A request that belongs to `api-lead`, not to this agent.

**Fixture**:
- Request: "Which scopes should the app request for the products feature?"
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

### Case 3: Gate Verdict — Auth Gate — install and token handling review

**Scenario**: Agent is invoked at its gate: requested scopes against used features, verification placement on every inbound path, storage encryption, and the uninstall revocation path

**Fixture**:
- Project state presented for review
- Gate ID: `AUTH-GATE`

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

### Case 4: Conflict Escalation — A scope the app does not use

**Scenario**: `app-architect`'s ADR lists `write_customers` for a feature that only reads customer tags.

**Fixture**:
- `app-architect` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to security-specialist, treated as a review finding until the scope is justified or removed
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Add auth to a new app

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `app-architect`: the app's surface list from the ADR and its declared scopes
- Sub-task: "implement the OAuth install and the session-token verification path"

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
- [ ] Escalates conflicts to `security-specialist (threat model), lead-engineer (code review)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Real consent screens and re-consent after a scope change need a dev store; the spec covers verification order, storage rules and uninstall handling.
