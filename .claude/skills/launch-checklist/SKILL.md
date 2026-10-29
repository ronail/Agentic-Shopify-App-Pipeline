---
name: launch-checklist
description: "Use after an app is approved and before it goes live. Validates production deployment, live billing, monitoring, merchant communication, support readiness, and rollback, then records go/no-go sign-offs for that app."
argument-hint: "[app] [launch-date | dry-run]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for `/launch-checklist`.
> Do not auto-invoke it from context matching.

## Phase 1: Parse Arguments

- `app` — slug from `docs/registry/apps.json`; default to the app named in `request.md`
- `launch-date` or `dry-run` — dry-run generates the checklist without sign-off entries
  and writes nothing

This skill covers **go-live after approval**. Submission readiness is
`/release-checklist`; this one starts where that ends.

---

## Phase 2: Gather Context

- `apps/<app>/status.md` — stage and last approved gate
- `production/apps/<app>/release-checklist-<version>.md` — must be READY
- `apps/<app>/CHANGELOG.md` and the `/patch-notes` draft for this version
- Latest sprint and milestone records in `production/apps/<app>/`
- `apps/<app>/shopify.app.toml` — production URLs, scopes, extension registrations
- `.claude/docs/technical-preferences.md` — hosting, database, environments

If no READY release checklist exists, stop. Verdict: **BLOCKED** — run
`/release-checklist [app]` first; going live without it repeats checks manually.

---

## Phase 3: Scan Production Risk

- Debug output, test shop domains, tunnel URLs, or sandbox API keys in the production
  config paths
- Feature flags set to a test value
- Secrets referenced but absent from the production environment
- Pending database migrations not applied
- Test charges or sandbox billing mode left enabled

---

## Phase 4: Generate the Checklist

````markdown
# Launch Checklist — [app]
Target go-live: [date or DRY RUN]
Generated: [date]
Version: [version]

## 1. Deployment
- [ ] Production build from the tagged release commit, not a working tree
- [ ] Environment variables and secrets set in the production host
- [ ] Database migrations applied; schema version matches the release
- [ ] Session store reachable from every production instance
- [ ] Background worker running and draining the queue
- [ ] Production URL is the one registered in `shopify.app.toml`; no tunnel in config
- [ ] Extension versions built and deployed alongside the app

## 2. Commerce Path
- [ ] Live billing mode verified with a real charge on a test store, then refunded
- [ ] Plan gating correct for free, paid, and cancelled states
- [ ] Trial start and expiry behave as the listing states
- [ ] Pricing on the listing matches live billing configuration for every market
- [ ] Uninstall stops billing and cleans up per the documented behaviour

## 3. Data and Tenancy
- [ ] Every query is scoped by shop; no cross-shop read possible in production code
- [ ] Backups running, retention set, and a restore was tested once
- [ ] Compliance webhooks reachable in production and returning 200
- [ ] Log retention configured; no customer PII in logs or error reports

## 4. Monitoring and Alerts
- [ ] Error tracking receiving events from production
- [ ] Uptime check on the app URL and on the OAuth callback
- [ ] Alerts on: error rate, webhook failure rate, queue depth, p95 latency
- [ ] Dashboard bookmarked by the on-call owner
- [ ] A synthetic install on a test store is part of the smoke set

## 5. Merchant Communication
- [ ] Merchant-facing release notes published via `/patch-notes [version]`
- [ ] Listing description reflects what ships today
- [ ] Support inbox monitored, with an owner and a response-time expectation
- [ ] Documentation and FAQ cover install, pricing, and uninstall
- [ ] Known limitations written down where a merchant will find them
- [ ] Existing merchants notified of breaking changes before the deploy, if any

## 6. Support and Operations
- [ ] On-call owner named for the first 72 hours
- [ ] Incident path documented: who declares, who fixes, where updates are posted
- [ ] Rollback plan written: previous version, how to revert, who approves
- [ ] Hotfix path exercised at least once (`/hotfix`) with a dry-run fix
- [ ] Test store available for reproducing merchant reports

## 7. Rollback and Failure Modes
- [ ] Previous release still deployable
- [ ] Database migration has a tested down path, or is additive-only
- [ ] Shopify-side rollback understood: extension version revert, webhook subscription revert
- [ ] Decision rule agreed: which symptoms trigger rollback versus hotfix

## 8. Post-Launch Watch (first 72 hours)
- [ ] Install funnel reviewed daily: installs started vs completed
- [ ] Error rate and webhook failure rate reviewed daily
- [ ] Review responses and support volume triaged daily
- [ ] Metrics baseline recorded so a regression is visible next week
- [ ] Retrospective scheduled for day 3–5
````

---

## Go / No-Go Decision

```
**Overall status**: [READY / NOT READY / CONDITIONAL]

Blocking items:
- [item — owner — estimated resolution]

Conditional items (accepted risk):
- [item — workaround — who accepted it]

Sign-offs
- [ ] release-manager — deployment and rollback readiness
- [ ] technical-director — technical health and monitoring
- [ ] qa-lead — verification on the production build
- [ ] producer — schedule, comms, and overall readiness
```

If any blocking item is open, the verdict is NOT READY regardless of sign-offs.

---

## Phase 5: Write

Present the totals: total items, blocking, conditional, and the sections with open items.

In `dry-run` mode, stop after presenting — write nothing, record no sign-offs.

Otherwise ask: "May I write this to
`production/apps/<app>/launch-checklist-<date>.md`?" Write on approval.

After a READY write, append to `production/apps/<app>/session-state/active.md`:

```
## Session Extract — /launch-checklist [date]
- App: [app] [version]
- Verdict: [READY / NOT READY / CONDITIONAL]
- Sign-offs: [roles that signed]
- Blocking: [count]
```

---

## Phase 6: Next Steps

- `/release [app] [version]` — if the app is approved but not yet published
- `/deploy-to-test-store [app]` — if any production-path item cannot be verified yet
- `/hotfix` — for any S1 found during the first 72 hours
- `/retrospective launch` — after the watch window closes

---

## Rules

- No go-live without a READY release checklist — the two gates are sequential, not
  alternatives
- Every sign-off names a role from the agent roster; an unnamed "team" is not a sign-off
- Conditional items are written down with the accepting owner, never waved through verbally
- The rollback plan is written before deploy, not improvised during an incident
