# Review Workflow

Four review passes run inside the pipeline: **code**, **security**, **UX**, and
**App Store**. QA is the execution layer that supplies evidence to all four.
Gate definitions and verdict semantics: `director-gates.md`. Handoffs:
`agent-coordination-map.md`.

A review that finds nothing because it checked nothing is a failed review. Every
pass cites the standard, the requirement, or the requirement id it judged
against.

---

## Which pass runs when

| Phase | Code | Security | UX | App Store | QA evidence |
|---|---|---|---|---|---|
| 1 Research | — | policy risk read | `UX-REVIEW` on specs | requirement set read early | — |
| 2 Architecture & Prototype | prototype only (not a merge gate) | threat model on ADRs | prototype walkthrough | scope/billing model read | — |
| 3 Scope | — | data-flow review of planned surface | — | submission requirements as stories | story readiness |
| 4 Build, Test, Store | `LP-CODE-REVIEW` per PR | `SEC-REVIEW` on auth/webhook/data paths | `UX-REVIEW` + `A11Y-REVIEW` per screen | `AS-CHECKLIST` before release | regression, smoke, a11y, perf |
| 5 Release & Operate | fixes only | `SEC-REVIEW` on hotfixes | — | `AS-CHECKLIST` re-run per submission | sign-off on the release commit |

---

## 1. Code review — `lead-engineer`

**Fires**: every story and every hotfix, before merge (`/story-done`,
`/code-review`). Gate id `LP-CODE-REVIEW`.

**Inputs**: diff and touched files, story acceptance criteria, the governing
ADR, `.claude/docs/coding-standards.md`, test files.

**Blocks merge on**
- Unverified webhook handling (no HMAC check, or verification after parsing).
- Unbounded or unpaginated Admin GraphQL calls; no throttling/retry on cost
  errors.
- Missing shop/tenant scoping on a query or mutation.
- Secrets in code, fixtures, or docs.
- Tests that assert nothing, or no test on new business logic.
- Business logic embedded in route handlers where it cannot be tested.
- Billing entitlement checked only in the UI.

**Also checks**: module boundary respected (`app/routes`, `app/webhooks`,
`app/services`), error taxonomy reused, one Shopify client abstraction, no
duplicated helper that already exists elsewhere in the repo.

**Verdict**: APPROVE / CONCERNS / REJECT. REJECT names each blocking line and
the standard it violates. The author fixes; `lead-engineer` re-reviews the diff,
not the whole file.

**Escalate** to `technical-director` when the fix requires an architecture
change, or to `security-specialist` when a finding is security-relevant (that
finding then also needs `SEC-REVIEW`).

---

## 2. Security review — `security-specialist`

**Fires**: any change to authentication, session/token handling, webhook
verification, scope declarations, merchant data handling or retention, or
secrets — and always before `gate-4-release` (`/security-audit`). Gate id
`SEC-REVIEW`.

**Inputs**: changed paths, `apps/<app>/shopify.app.toml` scope list, OAuth and
session-token flow, webhook verification code, data model and retention policy,
the control manifest's `Forbidden` list.

**Blocks on**
- **Critical**: missing or bypassable token verification; a route that trusts a
  client-supplied shop; cross-tenant data access; secrets committed; webhook
  handler that accepts unsigned requests.
- **High**: over-broad scopes with no use; protected customer data stored
  without a stated purpose; missing `customers/data_request`, `customers/redact`,
  or `shop/redact`; token persisted in a place the app cannot revoke; uninstall
  that orphans merchant data.
- **Medium**: missing rate limiting on a public endpoint; verbose error leaking
  internal detail; over-long retention with no deletion path.

**Verdict**: APPROVE / CONCERNS / REJECT. Each finding carries severity, path,
exploit sketch, owner, and fix. Critical and High are gate blockers; a waiver is
never granted for those by `gate-check`.

**Fix ownership**: `auth-specialist` (OAuth, tokens), `webhooks-specialist`
(signatures, retries, compliance topics), `billing-specialist` (entitlement
enforcement), `lead-engineer` (everything else). `security-specialist` verifies
the fix and closes the finding.

---

## 3. UX review — `ux-lead`

**Fires**: during research on specs (`/ux-design`, `/ux-review`), on each
implemented screen in build, and on any change to a merchant-facing flow. Gate
ids `UX-REVIEW` (design) and `A11Y-REVIEW` (implementation, owned by
`accessibility-specialist`).

**Inputs**: flow spec under `apps/<app>/design/ux/`, implemented screens, states
(empty, loading, partial, error, success), copy, App Bridge context.

**Blocks on**
- A flow that requires the merchant to leave the embedded admin to finish the
  job, with no App Bridge path.
- No empty state, or an empty state that does not explain value and the next
  step.
- A destructive bulk action with no confirmation and no undo path.
- A settings screen before the merchant has seen any value.
- State lost on navigation or tab close (unpersisted bulk edit).
- Error copy that does not name the next action.
- Non-Polaris components where a Polaris equivalent exists; layout that breaks
  in the Shopify iframe.

**Accessibility overlay** (`accessibility-specialist`, WCAG 2.1 AA): keyboard
reachability and focus order, focus visible, screen-reader labels on icon-only
controls, contrast, text scaling to 200%, reduced-motion handling. AA failures
block release; a11y findings go to `polaris-specialist` for the fix and back to
`accessibility-specialist` for verification.

**Verdict**: APPROVE / CONCERNS / REJECT. CONCERNS on UX may be accepted with a
recorded follow-up story; AA blockers may not.

---

## 4. App Store review — `app-store-reviewer`

**Fires**: requirement read in phase 1, requirement-to-story mapping in phase 3,
full readiness audit before `gate-4-release`, and again for every submitted
version (`/app-store-checklist`). Gate ids `AS-CHECKLIST`, then `gate-4-release`.

**Inputs**: `apps/<app>/shopify.app.toml` (scopes, URLs, webhook declarations),
billing implementation, listing draft, privacy policy, support contact, data
retention, the last readiness report, a clean test store.

**Checklist (each row PASS / FAIL / N/A with evidence)**
1. Scopes minimal and each one used.
2. Billing through the Shopify Billing API only; no off-platform charge.
3. Compliance webhooks implemented and subscribed.
4. Install works on a clean development store with no test data.
5. Uninstall removes merchant data or states what is retained and why.
6. Listing copy matches shipped behaviour; no claim the app does not deliver.
7. Screenshots and captions reflect the current UI.
8. Privacy policy and support contact reachable from the listing.
9. Review instructions let a reviewer exercise the paid feature on the review
   store.
10. Production config has no dev tunnel URL and no test-only flag.

**Verdict**: written to `production/apps/<app>/app-store-checklist.md` with a
`Verdict: ready` / `not-ready (N fails)` line. `app-store-gate.sh` blocks release
on anything but `ready`. Every FAIL names the owning specialist and the fix.

**Fix ownership**: `auth-specialist`, `billing-specialist`,
`webhooks-specialist`, `growth-lead` (pricing), `release-manager` (listing and
submission mechanics), `test-store-manager` (clean-store verification).
`app-store-reviewer` does not pass a submission because a deadline is close.

---

## 5. QA evidence — `qa-lead` and `qa-tester`

QA does not "review"; it supplies the evidence the other passes and gate 4
depend on.

| Activity | Owner | Evidence path |
|---|---|---|
| Test plan per story/epic | `qa-lead` | test plan in the story or epic |
| Story readiness (`QL-STORY-READY`) | `qa-lead` | verdict on the story file |
| Test coverage (`QL-TEST-COVERAGE`) | `qa-lead` | test files + evidence paths |
| Manual + regression execution | `qa-tester` | pass/fail per case with steps |
| Smoke after deploy | `qa-tester` | `/smoke-check --after-deploy` output |
| Full regression | `qa-lead` | `/regression-suite --full` result on the release commit |

Bug triage: `qa-lead` sets severity (S1 blocks release, S2 blocks the story, S3
schedules, S4 backlog). S1/S2 are fixed or waived by name; never quietly
downgraded.

---

## Ordering and conflicts

1. Code review runs before security review on the same change — there is no
   point auditing a diff that will be rewritten.
2. Security findings override code-review approval. A merged change with an open
   Critical is a release blocker regardless of who approved it.
3. UX and a11y review run on implemented screens, but a UX flow flaw found late
   escalates to `ux-lead` and `product-director` — fixing it in CSS hides it.
4. App Store review runs last, on the release commit, and can reject work the
   other three passed. A listing claim the app cannot deliver is a scope bug,
   not a copy bug.
5. Conflicting verdicts escalate per `coordination-rules.md` §4. The stricter
   verdict stands until the owner records a waiver with an expiry.

## Recording

- Review-gate verdicts are recorded in the reviewed document's header.
- Gate evidence is listed in the `evidence` array of the `approvals.json` entry.
- Every fix leaves a commit and a re-review note. A finding closed with no
  verification is still open.

## Anti-patterns

- Reviewing the summary instead of the diff.
- Approving with "minor nits" when a blocking issue is present — say REJECT.
- Running App Store review after the submission is prepared, instead of before
  the release gate.
- Treating a passing test suite as security evidence; tests do not verify a
  signature path they never exercise.
- Accessibility reviewed only at release. It is cheaper per screen than per app.
