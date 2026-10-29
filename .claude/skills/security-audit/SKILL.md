---
name: security-audit
description: "Audit one Shopify app's security posture: OAuth install flow, session-token verification, access-token storage, webhook HMAC, scope minimisation, protected customer data handling, and compliance webhooks. Produces severity-ranked findings with concrete exploit paths. Run before gate-4-release and after any auth, billing, or webhook change."
argument-hint: "[app: <slug>] [focus: auth | webhooks | data | scopes | all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: security-specialist
---

# Security Audit

The app holds a merchant's store data and a token that can act as the app on
that store. One leaked token or one unverified endpoint is a merchant-facing
incident, not a code smell.

**Output:** `production/apps/<app>/milestones/security-audit-<date>.md`
(sprint-scoped review → `production/apps/<app>/sprints/security-audit-<date>.md`)

**When to run:** before `gate-4-release`; after any change to auth, session,
webhook, billing, or data-export code; when a new scope is requested; when
App Store review feedback mentions security or data handling.

**Never** paste a live token, webhook secret, or customer record into the report.
Reference the field and the file, not the value.

---

## 1. Load Context

- `apps/<app>/shopify.app.toml` — scopes, redirect URLs, embedded setting,
  webhook subscriptions, API version.
- `apps/<app>/status.md`, `apps/<app>/approvals.json` — stage and prior gates.
- The app's OAuth/session modules, webhook routes, repository layer, and any
  export/report route.
- Documentation for the pinned Admin API version in
  `docs/shopify-api-reference/<version>/` — scope names, protected customer data
  fields, and compliance webhook contracts change between versions.
- `.claude/docs/technical-preferences.md` — hosting, DB, storage, and the
  forbidden-patterns list. Those forbidden patterns are mandatory checks here.

---

## 2. Attack Surface Checklist

### A. Install / OAuth
- [ ] `state` is generated per install, is unpredictable, is bound to the
      session, and is verified on callback. A static or absent state = CSRF.
- [ ] The callback verifies Shopify's HMAC over the query string with a
      timing-safe comparison before exchanging the code.
- [ ] The shop domain is validated against `*.myshopify.com` before it is used
      in a request or a DB key. Unvalidated `shop` = SSRF / token leak to an
      attacker domain.
- [ ] Redirect URIs in `shopify.app.toml` are exact-match allowlists — no
      wildcard, no open redirect parameter.
- [ ] The code exchange happens server-side only; app secret never reaches the
      browser.
- [ ] Re-install after uninstall re-runs OAuth rather than reusing a stale
      token.

### B. Session and tokens
- [ ] Every embedded request verifies the App Bridge session token: signature
      with the app secret, `aud` equals the app's client id, `iss`/`dest` match
      the shop, `exp`/`nbf` within tolerance. Decoding without verification is
      the most common failure in this codebase class.
- [ ] Session tokens are never trusted from headers other than the documented
      `Authorization` bearer, and never from a query parameter.
- [ ] Offline access tokens are stored encrypted at rest (DB column or KMS,
      not plaintext) and never logged.
- [ ] Token refreshes and rotations update storage; no token is written to a
      cookie, localStorage, or an error payload.
- [ ] Session rows are scoped by shop; a query that takes a shop id from the
      request cannot read another shop's session.
- [ ] Admin API calls originate server-side only — the forbidden pattern list
      bans browser-side Admin API calls and the check is real.

### C. Webhooks
- [ ] Every webhook route verifies HMAC-SHA256 over the **raw** body with a
      timing-safe compare, before any parsing side effect, and returns 401 on
      mismatch.
- [ ] Verification happens once, in shared middleware — not copy-pasted per
      route with one copy subtly wrong.
- [ ] Handler processing is idempotent on the delivery/event id, so a replayed
      delivery cannot double-apply.
- [ ] No webhook handler trusts `X-Shopify-Shop-Domain` without also verifying
      the signature.
- [ ] Payloads are validated (schema at the boundary) before they reach the
      query layer.

### D. Data and privacy
- [ ] The app requests only scopes it uses. Every scope in `shopify.app.toml`
      is justified by a code path; list any that are not.
- [ ] Protected customer data fields are only fetched where the merchant-facing
      feature genuinely needs them, and only the fields required.
- [ ] Compliance webhooks are implemented and reachable:
      `customers/data_request`, `customers/redact`, `shop/redact` — each with a
      real handler and an audit trail of what was deleted.
- [ ] Customer data is not written to logs, error trackers, or analytics
      payloads. Search for logging of request bodies on routes that touch orders
      or customers.
- [ ] Data retention: uninstall and `shop/redact` remove or anonymise stored
      merchant data per the documented policy.
- [ ] Exports (CSV/report downloads) are authorised per shop and not served
      from a predictable unauthenticated URL.

### E. Application-level
- [ ] SQL access goes through parameterised queries or the repository layer; no
      string-built SQL anywhere.
- [ ] The query layer scopes every read/write by shop id — a missing
      `where shop = ?` is a cross-tenant leak.
- [ ] Secrets come from environment/KMS; no secret literal in the repo, no
      secret in a committed `.env`-like file.
- [ ] Billing entitlements are re-checked server-side on every paid action; a
      client-supplied plan flag is not authorisation.
- [ ] Error responses do not leak stack traces, SQL, or token fragments to the
      browser.
- [ ] Dependencies: no unmaintained package on the auth/webhook path; check for
      known-vulnerable versions of the approved dependency set.

---

## 3. Verify, Do Not Assume

For each checklist item, record how it was confirmed:

- **Read the code path** and cite `file:line`.
- **Exercise the failure mode** where safe: send an unsigned webhook (expect
  401 and no side effect), send a session token with a wrong `aud` (expect
  rejection), request another shop's record id (expect 404/403, never data).
- A check that could not be verified gets status `UNVERIFIED` — never `PASS`.

Checks that are cheap and decisive — unsigned webhook, wrong-audience token,
cross-shop id — should always be exercised, not just read. Reading a middleware
file and concluding "looks fine" is how bypass paths survive.

---

## 4. Report

```markdown
# Security Audit — <app>

> Date: <date> | Commit: <sha> | API version: <v>
> Auditor: security-specialist | Scope: auth | webhooks | data | scopes | all

## Scope justification
| Scope in toml | Used by | Justified? |

## Findings

| ID | Area | Severity | Finding | Exploit path | Fix | Owner |
|----|------|----------|---------|--------------|-----|-------|
| SEC-001 | auth | Critical/High/Medium/Low | | | | auth-specialist |

## Verified controls
| Control | Status (PASS/FAIL/UNVERIFIED) | Evidence |
|---------|-------------------------------|----------|
| OAuth state verified | | file:line + exercised |
| Session token audience checked | | |
| Webhook HMAC verified | | |
| Raw body used for HMAC | | |
| Compliance webhooks implemented | | |
| Scopes minimal | | |
| Tokens encrypted at rest | | |
| Cross-shop access blocked | | |
| No PII in logs | | |

## Secrets hygiene
Literal scan result: <n matches | none>. Uncommitted `.env`-class files tracked
by git: <n | none>.

## Verdict: PASS / PASS WITH FINDINGS / FAIL
```

Severity:
- **Critical** — token/secret exposure, signature bypass, cross-tenant data
  access, or unauthenticated Admin API access. Blocks release unconditionally.
- **High** — exploitable with a crafted request from a merchant session; missing
  idempotency on a money path; scope overreach that touches customer data.
- **Medium** — defence-in-depth gap, verbose errors, log hygiene.
- **Low** — hardening, dependency freshness, documentation.

`gate-4-release` cannot pass with any open Critical or High finding. Medium and
Low need an owner and a date.

---

## 5. Write and Route

Ask: *"May I write this audit to
`production/apps/<app>/milestones/security-audit-<date>.md`?"*

Route by area:
- OAuth, session token, token storage → `auth-specialist`
- Webhook signature, replay, idempotency → `webhooks-specialist`
- Scope minimisation, API version behaviour → `api-lead`
- Entitlement enforcement → `billing-specialist`
- Query scoping, migrations, secret handling → `devops-engineer`
- PII in UI, error surfaces → `polaris-specialist` / `ux-lead`

Every Critical/High finding must come back for re-verification on the fixed
commit — a fix without a re-audit is a claim, not a control.

---

## Rules

- Do not fix code in this skill. Findings go to the owning specialist.
- Do not run exploit traffic against a production store. Dev store only.
- Do not downgrade a severity because "the merchant would have to try". The
  attacker is the one trying.
