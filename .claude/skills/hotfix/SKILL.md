---
name: hotfix
description: "Use when a shipped app is broken in production. Runs the emergency path: assess severity, mitigate, branch from the released tag, make the minimum fix with a reproducing test, verify on a test store, get sign-offs, deploy with a rollback plan, and record the incident."
argument-hint: "[app] [incident description or bug id]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for `/hotfix`.
> Do not auto-invoke it from context matching.

A hotfix bypasses sprint process but never bypasses verification. The audit trail is
the price of skipping the queue: every hotfix has a record, a reproducing test, a
named approver, and a rollback plan **before** it deploys.

---

## Phase 1: Assess Severity

Read the incident description, then classify:

- **S1 (Critical)** — the app is down or unusable for merchants; merchant or customer
  data is lost, corrupted, or exposed; access tokens or secrets are leaked; billing
  charges the wrong amount; a theme app extension or checkout extension is breaking a
  live storefront
- **S2 (Major)** — a significant feature is broken with a workaround; webhook backlog
  growing but recoverable; degraded performance inside budget breach
- **S3 or lower** — cosmetic or edge-case defect: normal flow applies

Confirm with `AskUserQuestion`, `request_user_input` or `clarify`:

- `[A]` S1 (Critical) — down, data loss/exposure, wrong charge, broken storefront
- `[B]` S2 (Major) — significant feature broken, workaround exists
- `[C]` S3 or lower — redirect to the normal fix path

If `[C]`: stop. Verdict **REDIRECTED** — use `/bug-report` then `/bug-triage`.

Resolve the app slug from `docs/registry/apps.json` if not supplied.

---

## Phase 2: Mitigate Before You Fix

Ask one question before writing any code: **can the damage be stopped without a
deploy?**

Consider, in order of preference:

1. Turn the feature off behind its flag
2. Revert to the previous deployed version
3. Pause the affected webhook subscription or background job
4. Rate-limit or disable the failing endpoint
5. Only then: ship a code fix

Record which mitigation was used. A mitigation that stops merchant harm in two minutes
beats a correct fix in two hours, and the fix still happens afterwards.

---

## Phase 3: Open the Incident Record

Draft, then ask to write it to
`production/apps/<app>/incidents/hotfix-<date>-<slug>.md`:

```markdown
# Hotfix — [short description]

App: [app]   Date: [date]   Severity: [S1/S2]
Detected by: [monitoring / merchant report / internal]
Status: IN PROGRESS

## Impact
[What merchants or their customers experienced, in merchant terms.]
- Merchants affected: [count or estimate]
- Surfaces affected: [admin | storefront | checkout | webhooks | billing]
- Revenue or data at risk: [statement]

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| [HH:MM] | Detected via [source] |
| [HH:MM] | Mitigation: [flag off / revert / subscription paused] |

## Root cause
[Filled during investigation — the actual cause, not the symptom.]

## Fix
[Filled during implementation — what changed and why this is the minimum change.]

## Verification
[Tests run, test store used, surfaces exercised.]

## Approvals
- [ ] lead-engineer — fix reviewed
- [ ] qa-lead — verification scope agreed and passed
- [ ] release-manager — deploy and rollback ready
- [ ] security-specialist — required if data, tokens, or permissions are involved

## Rollback plan
[How to revert, how long it takes, who decides.]
```

If a merchant-facing incident message is needed, `community-manager` drafts it from the
Impact section; keep it factual and free of internal detail.

---

## Phase 4: Branch from the Release

Check git first: `git rev-parse --is-inside-work-tree`. If this is not a repository,
note it and skip branch creation.

Ask before branching:

- `[A]` create `hotfix/<app>-<slug>` from the tag of the currently deployed version
- `[B]` use a different base ref (ask which)
- `[C]` skip — the branch already exists

Branch from the **deployed** tag, not from `main`. A hotfix cut from unreleased work
carries unrelated changes into production.

---

## Phase 5: Reproduce, Then Fix

1. **Write the failing test first.** It must fail for the reported reason. A fix with no
   reproducing test is a guess that happens to deploy.
2. **Make the minimum change.** No refactors, no dependency upgrades, no opportunistic
   cleanups, no new features — every extra line is extra rollback risk.
3. **Run the targeted suite** plus the suites that cover anything the change touches
   (billing and webhook signature verification are at 100% coverage by project rule).
4. **Update the incident record** with root cause, the diff summary, and test results.

If the honest fix needs more than four hours or touches the data model, stop and
escalate to `technical-director` — a rushed schema change during an incident is how a
short outage becomes a long one.

---

## Phase 6: Verification Gate

Spawn `qa-lead` via Task with the incident summary, the failing-then-passing test, and
the list of call sites for the changed modules (Grep for importers). Ask: what scope is
required before this deploys?

- **Smoke check sufficient** → run `/smoke-check <app>` and require PASS
- **Targeted regression required** → run `/regression-suite` scoped to the affected area
- **Full regression required** → S1 fixes touching auth, billing, webhooks, or data

Any surface a merchant touches must also be exercised on a real store: theme app
extension or checkout extension changes require `/deploy-to-test-store <app>` and a
walkthrough recorded under `production/apps/<app>/qa/evidence/`.

Do not skip this gate. A hotfix that breaks something else is worse than the original
defect, because it arrives with the merchant's trust already spent.

---

## Phase 7: Approvals

Spawn in parallel via Task and require APPROVE from all that apply:

- `lead-engineer` — correctness and side effects of the fix
- `qa-lead` — verification scope and results
- `release-manager` — deploy window, monitoring, and rollback readiness
- `security-specialist` — only when data, tokens, scopes, or permissions are involved

Any CONCERNS or REJECT: do not deploy. Surface the objection, resolve it, re-run the
gate. Record each verdict in the incident record.

---

## Phase 8: Deploy and Watch

Before deploying, state the rollback trigger explicitly: which metric, error, or
merchant report means "revert now". Ambiguity here is what turns a five-minute rollback
into a two-hour debate.

Output:

```
## Hotfix Ready: [app] — [short description]

Severity: [S1/S2]
Root cause: [one line]
Fix: [one line]
Verification: [smoke PASS / targeted regression PASS / full regression PASS]
Surfaces exercised: [admin | storefront | checkout | webhooks | billing]
Approvals: lead-engineer ✓ / qa-lead ✓ / release-manager ✓ [/ security-specialist ✓]
Rollback: [method, time to revert, decision owner]

Branches: merge the hotfix into the release branch AND the development branch.
```

After deploy, watch for the agreed window. Verify against production behaviour, not
against a local run: repeat the original reproduction steps on a test store and confirm
the symptom is gone.

- Fixed → record `Status: Fixed — verified` and close the incident
- Still present → roll back immediately, reopen, escalate to `technical-director`

---

## Phase 9: Close Out

1. Update `apps/<app>/status.md` if the incident changed the stage or introduced a blocker.
2. Add a **PATCH** entry to `apps/<app>/CHANGELOG.md` via `/changelog <app> <version>`.
3. If merchants saw it, generate merchant-facing notes with `/patch-notes <app> <version>`.
4. Schedule a post-incident review within 48 hours with `/retrospective hotfix`.
5. Ask what next: `[A]` `/smoke-check <app>` · `[B]` `/patch-notes <app> <version>` ·
   `[C]` `/regression-suite` to widen coverage · `[D]` stop here

---

## Rules

- Minimum change only — a hotfix is not the place for the cleanup you have been putting off
- Every hotfix has a reproducing test and a rollback plan before it deploys
- Branches merge into both the release branch and the development branch, or the defect returns
- Merchant communication goes out only after the fix is verified, and never promises a cause before the review confirms it
- An outage is not closed until the record names what allowed it to happen — that is the input to the next `/security-audit` or `/regression-suite` run
