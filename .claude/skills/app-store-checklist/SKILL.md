---
name: app-store-checklist
description: "Runs the App Store submission readiness gate for a Shopify app: listing assets, pricing, permissions and scopes, install and uninstall behaviour, billing, support surface, and policy compliance. Produces a pass/fail checklist with evidence per line."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# App Store Checklist — Submission Readiness Gate

## Purpose

App Store rejection is slow and public. This skill checks the things reviewers
check, against the built app, before the submission is filed. Every line is a
pass or a fail with evidence — a checklist of "looks fine" is worthless.

## When to use

- Before `gate-4-release`, always.
- Before re-submitting after a rejection.
- When scopes, pricing, or the listing copy changed after the last check.
- After `/app-page-materials` authors or updates `production/apps/<app>/app-store-listing.md` — this skill verifies what that step produced.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `apps/<app>/README.md` | yes | Purpose, the promise the listing must match |
| `apps/<app>/approvals.json` | yes | Which gates are already approved |
| `apps/<app>/` (app source) | yes | Scopes, billing calls, install and uninstall handling |
| `docs/shopify-api-reference/` | yes | Current requirements for scopes and billing |
| `production/apps/<app>/prototype-review.md` | optional | The flow the listing screenshots should show |

## Steps

1. **Confirm prerequisites.** `gate-2-prototype` and `gate-3-scope` must be
   approved in `apps/<app>/approvals.json`. If not, stop — the checklist is
   meaningless for an unscoped app.
2. **Scopes** — list every scope the app requests and the code path that needs
   it. Any scope without a call site is a fail: excess scopes are the most common
   rejection reason and the easiest to fix. Confirm the scope is the least
   privileged that works.
3. **Billing** — confirm the plan tiers, that the charge is created through the
   platform billing surface (not an external payment processor), that the trial
   is declared, and that a declined charge is handled with a merchant-readable
   state rather than a dead screen.
4. **Install path** — a fresh install must reach a working state with no manual
   step: no "contact us to activate", no empty dashboard. Confirm onboarding
   copy exists and that scopes are requested at the moment they are needed, with
   a reason a merchant understands.
5. **Uninstall path** — confirm the app responds to the uninstall signal, marks
   the record inactive, and stops charging. A merchant who uninstalls and is
   still billed is a policy violation, not a bug.
6. **Data handling** — confirm what is stored, where, for how long, and that the
   privacy statement matches. Confirm customer data is not stored beyond what the
   feature needs.
7. **Listing assets** — name, tagline, description in merchant language, at least
   three screenshots showing the real flow, a support URL, and a pricing summary
   that matches the billing step exactly. A price mismatch is an automatic
   rejection.
8. **Support surface** — a reachable support path (email or help page) and a
   documented response expectation. Reviewers test it.
9. **Performance and errors** — load the main screen on a cold start and confirm
   no unhandled error reaches the merchant; confirm rate-limit handling degrades
   with a message instead of a crash.
10. **Write the verdict.** One line per check: `PASS` with the file or command
    that proves it, or `FAIL` with the exact fix. Overall verdict is `ready` only
    when zero fails.

## Outputs

`production/apps/<app>/app-store-checklist.md`:

```markdown
## App Store Readiness — <app> — <date>
Verdict: ready | not-ready (N fails)

| # | Check | Result | Evidence / fix |
|---|-------|--------|----------------|
| 1 | Scopes minimal | PASS | apps/<app>/shopify.app.toml requests read_products only |
```

## Ownership

Owned by **app-store-reviewer**. `security-specialist` signs off data handling,
`billing-specialist` signs off the charge path, `api-lead` confirms scope
requests against the current API requirements, `release-manager` consumes the
verdict at `gate-4-release`.

## Rules

- **Evidence per line.** "Verified by reading `src/...`" beats "looks correct".
- **A fail blocks the gate.** Do not soften a fail to `ready-with-notes`.
- **Re-check after fixes.** Change the line's result, keep the old failure in the
  history section.
- **No submission from this skill.** It gates the release; `/release` files it.

Template: `.claude/docs/templates/app-store-listing.md` — the listing fields each checklist line verifies.
