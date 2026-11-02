---
name: release-checklist
description: "Use before submitting an app to the Shopify App Store. Generates the submission-readiness checklist for one app — scopes, billing, webhooks and compliance topics, privacy, Polaris and performance budgets, extension surfaces — and returns a READY / NOT READY verdict that feeds /release."
argument-hint: "[app] [--version x.y.z] [--scope admin|extension|checkout|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for `/release-checklist`.
> Do not auto-invoke it from context matching.

## Phase 1: Parse Arguments

- `app` — the slug from `docs/registry/apps.json`; default to the app named in `request.md`
  or the most recently modified `production/apps/<app>/session-state/active.md`
- `--version` — the version being submitted; default to the newest entry in
  `apps/<app>/CHANGELOG.md` or ask
- `--scope` — `admin` (embedded admin app only), `extension` (adds theme app extension
  checks), `checkout` (adds checkout extension checks), or `all` (default)

---

## Phase 2: Load App Context

- `apps/<app>/shopify.app.toml` — `api_version`, `access_scopes`, webhook subscriptions,
  extension registrations
- `apps/<app>/status.md` — stage, blockers, last approved gate
- `docs/architecture/apps/<app>/control-manifest.md` — the guardrails this release must meet
- Latest sprint record in `production/apps/<app>/sprints/` — what this release contains
- `apps/<app>/CHANGELOG.md` — the entry for `--version` must already exist
- `.claude/docs/technical-preferences.md` — budgets and forbidden patterns

If `shopify.app.toml` is missing, stop. Verdict: **BLOCKED** — the app has no pinned
API version, so nothing below can be verified.

---

## Phase 3: Scan the App

Static checks over `apps/<app>/` only:

- `TODO`, `FIXME`, `HACK` counts, with the top locations named
- `console.log`, `console.debug`, and debug flags left in production paths
- Hardcoded API version strings outside `shopify.app.toml` and the ADR
- Hardcoded dev values: `localhost`, tunnel hostnames, test shop domains, test tokens
- `.env` files tracked in git (must be zero)
- Access tokens written to logs or stored unencrypted
- Admin API calls reachable from browser code
- Scopes requested in `shopify.app.toml` that no code path uses

---

## Phase 4: Generate the Checklist

````markdown
## Release Checklist — [app] [version]
Generated: [date]
API version: [from shopify.app.toml]
Scope: [admin | extension | checkout | all]

### Codebase Health
- TODO: [N] · FIXME: [N] (must be 0) · HACK: [N] (each justified)
- Debug output in production paths: [N] (must be 0)
- Hardcoded API versions outside config: [N] (must be 0)
- Tracked `.env` files: [N] (must be 0)

### Install, Auth, Uninstall
- [ ] Install completes from a clean store in one pass
- [ ] Reinstall on a previously uninstalled store works
- [ ] Session tokens verified on every embedded request; no cookie-only session
- [ ] Access token stored encrypted, never logged
- [ ] Uninstall triggers cleanup and the `shop/redact` path fires
- [ ] OAuth round trip under 5 s on the dev store

### Access Scopes
- [ ] Every requested scope has a code path that needs it
- [ ] Every scope is justified in the listing text where the merchant can see it
- [ ] Protected scopes (customer data, `read_all_orders`) have the review justification ready
- [ ] No scope is requested "for later"

### API Surface
- [ ] `api_version` is pinned in `shopify.app.toml` and still supported by Shopify
- [ ] No deprecated or removed field is used (checked against `docs/shopify-api-reference/[version]/`)
- [ ] No field or mutation is used that the snapshot does not contain
- [ ] GraphQL requested cost stays under 500 per request unless it is a bulk operation

### Billing
- [ ] Plan and pricing configured for the target market
- [ ] Test charges complete on the dev store for create, upgrade, downgrade, cancel
- [ ] Feature gating enforced server-side, not only hidden in the UI
- [ ] Trial and re-subscribe paths behave correctly
- [ ] Billing failures degrade to a clear merchant-facing message

### Webhooks
- [ ] HMAC verified over the raw body before any side effect; failures return 401 and do nothing
- [ ] Handlers are idempotent on the delivery/event ID
- [ ] `customers/data_request`, `customers/redact`, `shop/redact` registered and tested
- [ ] Subscriptions declared in config and reconciled on install and version change
- [ ] Handler p95 acknowledged under 500 ms; slow work queued
- [ ] A backfill path exists for missed deliveries

### Merchant Data and Privacy
- [ ] Privacy policy URL live and linked from the listing
- [ ] Data retention and deletion behaviour documented
- [ ] Customer PII never written to logs
- [ ] Data export/delete requests can be satisfied within the committed window

### Admin UI
- [ ] Renders embedded through App Bridge; no iframe-breaking navigation
- [ ] Built from Polaris components; loading, empty, and error states present
- [ ] Reachable and usable at 1280 px wide and at 100% zoom
- [ ] WCAG 2.1 AA: keyboard reachable, visible focus, labelled controls, 4.5:1 text contrast
- [ ] Admin route p75 under 1.5 s on a warm session
- [ ] Initial route bundle under 250 KB gzipped

### Theme App Extension
- [ ] App block installs on a clean unmodified theme and renders correctly
- [ ] Block settings schema is complete and merchant-readable
- [ ] No theme code edit is required from the merchant
- [ ] Uninstall removes the block without leaving broken markup

### Checkout Extension
- [ ] Extension target valid on the pinned API version
- [ ] Uses only APIs available to checkout extensions
- [ ] Full checkout walkthrough passed on the dev store
- [ ] Degrades safely when the extension cannot run

### Reliability
- [ ] Error monitoring and alerting connected and firing on a synthetic error
- [ ] Rate limits handled with backoff; no unbounded retry loop
- [ ] Bulk operations used for sets above the single-request page limit
- [ ] Job queue drains without manual intervention
- [ ] Rollback path is documented and was exercised once

### Listing and Review
- [ ] App name, icon, and screenshots current and accurate
- [ ] Pricing on the listing matches the billing configuration
- [ ] Support contact and documentation links resolve
- [ ] Review notes explain any unusual install or permission requirement
- [ ] No claim in the listing that the app does not do

### Engineering Hygiene
- [ ] Full test suite green on the release commit
- [ ] Billing and webhook signature verification at 100% line coverage
- [ ] No open S1 bug; S2 bugs documented and accepted
- [ ] `apps/<app>/CHANGELOG.md` has the `[version]` entry
- [ ] Merchant-facing notes drafted with `/patch-notes [version]`
````

Add the `### Theme App Extension` and `### Checkout Extension` sections only when the
scope or `shopify.app.toml` says those surfaces exist; otherwise write
`Not applicable — no [extension surface] in this app`.

---

## Phase 5: Verdict and Write

```
### Verdict: [READY / NOT READY]

Blocking items:
- [each unchecked BLOCKING item, with the owner agent that fixes it]

Accepted risks:
- [item, reason, who accepted it]

Next: /release runs the submission once this is READY.
```

Blocking by default: any install, auth, scope, billing, webhook-HMAC, compliance-topic,
privacy, or deprecated-API item. Polaris polish and listing copy are advisory.

Ask: "May I write this to `production/apps/<app>/release-checklist-<version>.md`?"
Write on approval, creating the directory if needed. On decline:
Verdict **COMPLETE** — checklist generated, not saved.

---

## Phase 6: Next Steps

- `/app-page-materials [app]` — author the listing page materials this checklist recommends (identity, copy, screenshots, pricing, scopes)
- `/app-store-checklist [app]` — the listing-level detail behind the review submission
- `/release [app] [version]` — the submission/publish flow, which consumes this file
- `/deploy-to-test-store [app]` — if any dev-store verification above is still ❌
- `/hotfix` — if a blocking defect is found after submission

Totals to report in conversation: total items, blocking items, advisory items, and the
surfaces that were out of scope.
