---
name: create-architecture
description: "Author the per-app architecture document at docs/architecture/apps/<app>/architecture.md — boundaries, Shopify API surface, auth and session model, data and webhook flow, billing, performance and security budgets. Reads requirements, control manifest, UX specs, and existing ADRs."
argument-hint: "[app] [full|boundaries|data-flow|api-surface|adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify, Task
model: sonnet
agent: technical-director
---

# Create Architecture

Turns approved requirements into one concrete technical blueprint per app, before
any story is written. Every app gets its own document — there is no master
cross-app architecture doc, because the isolation contract forbids shared app
state.

Output: `docs/architecture/apps/<app>/architecture.md`.

## Phase 0 — Parse

1. **App** — required. Validate against `docs/registry/apps.json` and
   `apps/<app>/`. Unknown slug → list the registry and stop.
2. **Focus** — `full` (default), `boundaries`, `data-flow`, `api-surface`,
   `adr-audit`. Focus only re-runs those sections; the rest of an existing
   document stays untouched.
3. **Review mode** — `--review` override, else `production/review-mode.txt`,
   else `lean`.

## Phase 1 — Gather inputs

| Input | Needed for |
|-------|-----------|
| `docs/architecture/apps/<app>/requirements.yaml` | Requirement IDs, rules, edge cases, acceptance criteria |
| `docs/architecture/apps/<app>/control-manifest.md` | Conventions, naming, error shape, limits |
| `docs/architecture/apps/<app>/ADR-*.md` | Decisions already made; these win over your preference |
| `apps/<app>/design/concept.md` | Merchant job, surface map, monetisation, MVP scope |
| `apps/<app>/design/ux/*.md` | Routes, screens, states, data needs |
| `docs/shopify-api-reference/<version>/` | Real operations, fields, scopes, limits |
| `docs/registry/architecture.yaml` | Stances shared across apps (data ownership, API conventions) |
| `apps/<app>/status.md` | Stage — warn if architecture is being written before gate-1 approval |
| `production/apps/<app>/session-state/` | Prior decisions worth not re-litigating |

If `requirements.yaml` is missing, stop: architecture without requirements is
fiction. If the API reference has no pinned version, stop and pin one — say
"nothing in this document can be verified against an unpinned API".

## Phase 2 — Read the ADRs first

List every ADR in the app's directory with its status. Any **Accepted** ADR is a
constraint: the architecture must conform or produce a superseding ADR through
`/architecture-decision`. Do not silently diverge.

Report the list before writing, so the user can see what is already fixed.

## Phase 3 — Sections, one at a time

Write incrementally; confirm each section before the next. Skip sections that
`focus` excludes.

### 1. App boundaries

- One paragraph: what the app does, for whom, and what it explicitly does not do
  (mirror the concept's out-of-scope).
- The isolation contract in practice: what lives in `apps/<app>/`, what lives in
  `production/apps/<app>/`, and what (nothing) is shared with other apps.
- The only shared mutable file this app touches: its own entry in
  `docs/registry/apps.json`.

### 2. Stack and runtime

- Shopify app template and framework version (for example Remix-based embedded
  app), language, package manager.
- Hosting target and the request lifecycle there (serverless vs long-running
  process matters for queue work and webhook handling).
- Session storage choice and why (database sessions vs token exchange).
- Build output: admin bundle, extension bundles, Function builds.

Pin versions. "Latest" is not an answer.

### 3. Shopify API surface matrix

A table per operation — this is the section `/design-review` checks hardest:

| Surface | Operation / topic | Direction | Scopes | Rate / cost note |
|---------|-------------------|-----------|--------|------------------|
| Admin GraphQL | `query products(...)` | read | `read_products` | paginated 50/page |
| Admin GraphQL | `mutation discountCodeBasicCreate` | write | `write_discounts` | cost-based budget |
| Webhook | `orders/create` | in | none | must be idempotent |
| Admin action extension | order detail block | out | — | rendered in admin frame |
| Theme app extension | product block | out | `read_products` | merchant must add it |
| Shopify Function | cart transform | out | — | no network access |
| Storefront API | product read | out | — | storefront token |

Rules:

- Every operation exists in `docs/shopify-api-reference/<version>/`. Mark any
  operation you could not verify as `UNVERIFIED` and list it in open questions.
- State pagination and cost handling for any list that can grow with the
  merchant's catalog.
- Name REST usage explicitly if you use it, with the reason (some endpoints have
  no GraphQL equivalent).
- Protected customer data access is called out per field, not per endpoint.

### 4. Auth and session model

- Embedded app auth: token exchange or OAuth callback, and where the access token
  is stored per shop.
- Session tokens for every request from the admin frame; server-side verification
  and the 401 path.
- Offline vs online tokens: which operations use which, and why.
- Scope strategy: which scopes are requested at install, which on demand, and how
  a re-auth prompt is triggered when a scope is missing.
- Webhook verification: HMAC on every request, plus the replay window.
- Secret storage: environment variables, never the repo; name each one without
  printing a value.

### 5. Data model and retention

- Tables or collections, all shop-scoped, with the shop identifier in every
  unique key.
- Migration strategy and how a new column reaches existing installs.
- Retention per data class, and the deletion path for the three mandatory GDPR
  webhooks (customer data request, customer redact, shop redact).
- What is cached and where (per-shop cache keys, TTL, invalidation trigger).

### 6. Request and data flow

One ASCII diagram, plus a short walkthrough of the primary merchant action:

```text
Admin iframe (Polaris page)
  → route loader/action (session token)
    → service layer (validation, plan gate)
      → Admin GraphQL (paginated)
    ← normalised view model
  ← rendered Page / IndexTable / Banner
```

Then the asynchronous path: what is queued, what retries, what the merchant sees
while it runs, and where the result lands.

### 7. Billing and plan gating

- Charge type (recurring, usage, or both), trial length, and the exact merchant
  action that starts a charge.
- Where the plan gate is enforced — server side, at the service layer, never only
  in the UI.
- Behaviour on downgrade, cancel, uninstall, and reinstall (data kept or cleared,
  and for how long).
- Test charge path with the dev store.

### 8. Webhook processing

For each topic: handler, verification, idempotency key, retry and backoff,
dead-letter path, and whether ordering matters. Duplicate delivery is normal —
say what makes each handler safe to run twice.

### 9. Performance budgets

- Admin route: initial payload under 250 KB gzipped, perceived load under 1.5 s
  p75.
- Admin API: stay inside the cost budget for a 100k-variant store; state the
  batching and paging approach.
- Webhook handler: respond fast, work off the request path.
- Storefront extension: added weight to the merchant's theme, and the ceiling.

Numbers, not adjectives. `/perf-profile` will hold you to them.

### 10. Security and compliance

- Input validation points, and the rule that no customer data reaches logs.
- HMAC verification, session-token verification, and CSRF/same-origin posture.
- Least-privilege scopes with a reason per scope.
- App Store review risks specific to this app (data use disclosure, billing
  claims, misleading listing copy).
- Dependency and secret hygiene: lockfile committed, no secrets in the repo.

### 11. Observability

- Structured logs with shop id and request id, never customer personal data.
- Error tracking, alert thresholds, and who reads them.
- Metrics that map to the success metric in the concept.

### 12. Testing strategy

- Unit scope (calculations, plan gates, normalisers).
- Integration scope (route loaders and actions against a mocked Admin API).
- End-to-end scope on the dev store (`/create-test-store`, `/deploy-to-test-store`).
- What must be covered before `/qa-plan` signs off: money math, auth paths,
  webhook idempotency, GDPR handlers.
- Test data strategy for a large catalog — say how you get 100k variants without
  a real merchant.

### 13. ADR index

Table of ADRs for this app: number, title, status, one-line stance. This is the
reading order for anyone joining the app.

### 14. Open questions

Each with an owner and the decision it blocks. Anything marked `UNVERIFIED` in
section 3 belongs here. Do not bury uncertainty in prose.

## Phase 4 — Compress and check

After the sections are written:

1. Re-read the whole document for contradictions with Accepted ADRs — fix or
   open an ADR.
2. Check every requirement ID in `requirements.yaml` is served by at least one
   section. Orphans mean the architecture is incomplete; report them.
3. Confirm every operation in the API matrix resolves against
   `docs/shopify-api-reference/<version>/`.
4. Keep the document under roughly 400 lines. Detail that belongs to one story
   goes in the story, not here.

## Phase 5 — Review gate

Unless `solo`:

- `technical-director` — is this buildable and does it respect the boundaries?
- `app-architect` — surface choice, data model, extension strategy.
- `security-specialist` when the app touches customer data, billing, or webhooks.
- `api-lead` / `graphql-specialist` when the API matrix is large — cost,
  pagination, and rate-limit handling.
- `performance-analyst` when budgets are aggressive or the catalog is large.

`lean` runs technical-director plus security-specialist only when the app touches
customer data or billing.

For each verdict: **APPROVED** → mark the doc's status `approved`;
**NEEDS REVISION** → fix the named sections and re-run those only; **MAJOR
REVISION NEEDED** → return to sections 3–6 with the objection quoted.

## Phase 6 — Hand off

- Decisions not yet made → `/architecture-decision <app> "<title>"` — one ADR per
  genuine choice, not one per section.
- Architecture approved → `/architecture-review <app>` for the cross-document
  pass, then `/create-epics <app>`.
- Conventions the code must follow → `/create-control-manifest <app>`.

Verdict: **COMPLETE** — `docs/architecture/apps/<app>/architecture.md` written,
requirement coverage stated, unverified API operations listed.
