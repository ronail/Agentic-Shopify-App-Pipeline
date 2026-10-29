---
name: smoke-check
description: "Post-deploy smoke test on the dev store: walk the critical merchant flows of one Shopify app — install, embedded admin load, primary action, billing, webhook ack, uninstall — and produce a PASS/FAIL report. A failed smoke check blocks release and blocks handing the app to anyone else."
argument-hint: "[app: <slug>] [quick | full] [--after-deploy]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: qa-lead
---

# Smoke Check

The gate between "deployed" and "safe to show a merchant". Ten to fifteen
minutes, one dev store, the flows that break first in real installs.

The rule: **an app that fails smoke check does not go to the test store demo,
does not go to `gate-4-release`, and does not get shown to a merchant.**

**Output:** `production/apps/<app>/sprints/smoke-<date>.md`

**Run it after:** every deploy to the test environment, every dependency or API
version bump, every change to auth, billing, or webhook routes, and immediately
before `gate-4-release`.

---

## 1. Parse Arguments

- `quick` — skip the deep checks (billing lifecycle, uninstall cleanup,
  §4 Groups C and E). For a rapid re-check of a fix.
- `full` (default) — every group.
- `--after-deploy` — record the deployed commit and the deploy target in the
  report header; required when the smoke is release evidence.
- `app: <slug>` — required unless exactly one app exists in
  `docs/registry/apps.json`.

---

## 2. Establish the Environment

1. Read `apps/<app>/status.md` and `apps/<app>/approvals.json` — know the stage
   before testing, so a research-stage app is not judged on release criteria.
2. Read `apps/<app>/shopify.app.toml` — record the app handle, embedded setting,
   `application_url`, redirect URLs, scopes, and webhook subscriptions. Every
   one of these is something the smoke run verifies against reality.
3. Read `.claude/docs/technical-preferences.md` for the environment ladder:
   local (CLI tunnel) → dev store → production.
4. Confirm the dev store: it must be a development store that the app is
   installed on, or one where installation can be performed. If no store
   exists, stop and point at `/create-test-store` rather than improvising
   credentials.
5. Record the commit under test (`git rev-parse --short HEAD`) and the deploy
   target. A smoke report without a commit hash is not evidence.

Never test against a merchant's live store. If the only installed store is a
real merchant, stop and escalate.

---

## 3. Test Groups

### Group A — Install and OAuth
- [ ] Fresh install from the app's install link completes without an error page.
- [ ] Redirect lands inside the embedded admin, not on a blank or 404 route.
- [ ] Granted scopes on the store match `shopify.app.toml` exactly — no extra
      scope was silently requested, none that the app needs is missing.
- [ ] Session row written; the app renders after a hard refresh (session
      survives, not just in-memory state).
- [ ] Re-install over an existing install reuses the stored session and does not
      create duplicate install records.

### Group B — Embedded admin surface
- [ ] Primary route loads inside the Shopify admin iframe with App Bridge
      initialized — no "refused to frame" or session-token 401 loop.
- [ ] Navigation between the app's routes works via App Bridge (no full page
      reload losing context).
- [ ] Primary list/table view renders real store data, and the empty state is
      correct for a store with no matching records.
- [ ] One create → edit → delete cycle on the app's primary resource succeeds
      and the change is visible on the store (verify via the admin API, not just
      the app's own cache).
- [ ] Error path: a deliberately invalid input shows an inline Polaris error,
      not a crash or a silent no-op.

### Group C — Billing (full mode only)
- [ ] Plan selection opens the Shopify-hosted confirmation; the charge is
      approved in test mode.
- [ ] After approval, the app's plan gate flips and the paid feature is usable.
- [ ] `app_subscriptions/update` webhook is received and reconciled — the app's
      stored plan matches Shopify's active subscription.
- [ ] Declining the charge leaves the app usable at the free tier and does not
      leave a dangling pending subscription.
- [ ] Downgrade/cancel path returns the app to the free tier without a stale
      entitlement.

### Group D — Webhooks
- [ ] Trigger a subscribed topic from the store admin (e.g. create an order or
      edit a product) and confirm a 2xx ack within 500 ms.
- [ ] Invalid-signature delivery is rejected with 401 and produces **no** side
      effect — no row written, no job queued.
- [ ] Duplicate delivery of the same event id is handled idempotently (second
      delivery does not double-apply).
- [ ] The mandatory compliance topics are reachable: `customers/data_request`,
      `customers/redact`, `shop/redact` respond 2xx with a stub-safe handler.
- [ ] Any queued follow-up work actually drains (check queue depth returns to 0).

### Group E — Uninstall and cleanup (full mode only)
- [ ] Uninstalling from the store admin leaves the app's admin surface
      unreachable and clears the session.
- [ ] `app/uninstalled` is received; stored tokens for that shop are invalidated.
- [ ] Reinstalling after uninstall works and does not resurrect stale data that
      the merchant expected to be gone.

### Group F — Cross-cutting
- [ ] No uncaught exception in the app server log during the run.
- [ ] No secret printed to logs (token, webhook secret, session token).
- [ ] Admin console clean of React key/hydration warnings on the primary route.
- [ ] If a previous smoke report exists, every S1/S2 issue in it is verified
      fixed or explicitly carried forward with an owner.

---

## 4. Produce the Report

```markdown
# Smoke Check — <app>

> Date: <date> | Commit: <sha> | Deploy target: <url/env>
> Store: <dev store> | Mode: quick | full | Generated by: /smoke-check

## Environment
- API version (toml): <v> | Scopes granted: <list | matches toml: Y/N>
- Webhook topics subscribed: <list>

## Results

| Group | Check | Result | Evidence |
|-------|-------|--------|----------|
| A | Fresh install completes | PASS/FAIL | screenshot/log line |
| ... | | | |

## Failures

| ID | Group | Severity | What happened | Repro steps | Owner |
|----|-------|----------|---------------|-------------|-------|
| SMOKE-001 | B | S1 | | | |

## Carried forward (from prior smoke)
| Prior ID | Status | Owner |

## Verdict: PASS / FAIL
```

Severity guidance:
- **S1** — install, OAuth, session, or webhook signature broken; billing
  entitlement wrong. Blocks everything.
- **S2** — primary merchant action broken in a specific case; blocks release,
  does not block a scoped demo of the working path.
- **S3** — cosmetic, copy, or a warning with no functional impact.

---

## 5. Write and Close Out

Ask before writing: *"May I write this smoke report to
`production/apps/<app>/sprints/smoke-<date>.md`?"*

After writing, report:

1. Verdict, and the S1/S2 list with owners.
2. If PASS: the app is eligible for the next step — `/regression-suite` for
   full confidence, or straight to `/gate-check gate-4-release <app>` when the
   regression suite already ran on this commit.
3. If FAIL: the release gate is closed. Route the fixes: auth/session →
   `auth-specialist`, billing → `billing-specialist`, webhook → 
   `webhooks-specialist`, embedded context → `app-bridge-specialist`, rendering
   → `polaris-specialist`.

---

## Rules

- **Re-run after the fix, on the fixed commit.** A PASS from an earlier commit
  is not evidence for the current one.
- **Verify on the store, not in the app's own UI.** "The app says it saved" is
  not proof; read it back through the Admin API or the store admin.
- **Do not silently skip a group.** If billing is not implemented yet, mark the
  group `N/A — not built` and state it in the verdict; do not mark it PASS.
- **Never touch production credentials** to make a smoke check pass.
