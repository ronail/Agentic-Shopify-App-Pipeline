# Control Manifest — discount-bundles

> **API Version**: 2026-10
> **Manifest Version**: 2026-10-29
> **Last Updated**: 2026-10-29
> **ADRs Covered**: ADR-0001 (bundle cart transform), ADR-0002 (catalogue reconciliation), shared ADR-0001 (API version policy)
> **Access Scopes**: `read_products`, `write_products`
> **Status**: Active — regenerate with `/create-control-manifest discount-bundles update`

`Manifest Version` is the date this sheet was generated and always equals
`Last Updated`. Stories embed this value; `/story-readiness` refuses a story
whose embedded version is older, and `/story-done` re-checks it at close.

This is the quick reference for every programmer on this app. It is derived from
the Accepted ADRs above, `.claude/rules/`, and the 2026-10 API snapshot. For the
reasoning behind a rule, read the cited ADR.

---

## Admin UI

**Required**
- Polaris components only; no bespoke CSS framework, no inline style objects for
  layout. — ADR-0002
- App Bridge for navigation and toasts; session token on every admin request. — ADR-0002
- Every destructive action (delete bundle, remove component) confirms with the
  bundle name in the dialog. — ADR-0002
- Bundle editor validates before save and shows field-level errors, not a single
  banner. — REQ-BUNDLE-001
- Loading, empty, error and permission-denied states for every route. — ADR-0002

**Forbidden**
- Client-side Admin API calls — the browser never holds an access token. — ADR-0002
- Optimistic UI that claims a bundle saved before the loader revalidates. — ADR-0002
- Hiding a bundle that has an unavailable component; it must be shown as
  disabled with the reason. — REQ-BUNDLE-006

**Guardrails**
- Bundle editor route p75 < 1.5 s at 100 bundles. — REQ-BUNDLE-009
- Variant search: one query per typing pause, page size 20, never fetch-all. — REQ-BUNDLE-009
- WCAG 2.1 AA: keyboard reachable picker, visible focus, 4.5:1 contrast. — ADR-0002

---

## App server

**Required**
- Admin GraphQL through the app's authenticated client; version comes from
  `shopify.server`, never a literal. — shared ADR-0001, ADR-0001
- Shop-scoped access on every query: filter by the session shop's domain, never
  by an id from the request body alone. — ADR-0002
- Write path is `validate → persist → enqueue function-owner sync`; a failed sync
  leaves the bundle in `pending` and retries. — ADR-0001
- Every mutation returns the standard error envelope `{ ok, error | data }`. — ADR-0002

**Forbidden**
- REST Admin API. — shared ADR-0001
- A second hardcoded API version string anywhere in `app/**`. — shared ADR-0001
- Reading `process.env.SHOPIFY_API_SECRET` outside the auth/session module. — ADR-0002
- Unbounded `first:` without a documented page size. — ADR-0002

**Guardrails**
- GraphQL requested cost ≤ 500 per call; deeper work goes through a bulk
  operation. — shared ADR-0001
- No route handler holds a write transaction open across a network call. — ADR-0002
- Admin API latency p95 budget 400 ms per call; retry with backoff on `THROTTLED`. — ADR-0001

---

## Webhooks

**Required**
- Verify the HMAC on the raw body before parsing; respond 401 and log on failure. — ADR-0002
- Register `products/create`, `products/update`, `products/delete`,
  `app/uninstalled`, `shop/redact`, `customers/data_request`,
  `customers/redact` in `shopify.app.toml`. — ADR-0002
- Idempotency key `(shop, topic, payload.id, payload.updated_at)` recorded before
  side effects; duplicates exit early with 200. — ADR-0002
- Respond 200 within the handler, then reconcile in the background queue. — ADR-0002

**Forbidden**
- Assuming delivery order between `products/update` and `products/delete`. — ADR-0002
- Trusting `X-Shopify-Shop-Domain` without checking it matches an installed shop. — ADR-0002
- Deleting a bundle because a product webhook was malformed; mark it unavailable. — REQ-BUNDLE-006

**Guardrails**
- Handler p95 < 500 ms; anything slower moves to the queue. — ADR-0002
- Reconciliation completes within 5 minutes of the delivery. — REQ-BUNDLE-006
- Duplicate deliveries must be a no-op (tested with a replayed payload). — REQ-BUNDLE-006

---

## Theme app extensions

**Required**
- App block reads bundle data from an app-proxy/App Block endpoint, not from a
  hardcoded product metafield path. — ADR-0002
- Merchant-editable block settings for heading, image, and "show component list". — REQ-BUNDLE-005
- Schema-validated block settings; a missing setting falls back to a default. — REQ-BUNDLE-005

**Forbidden**
- Global CSS that leaks outside the block's own scope. — ADR-0002
- Rendering component prices separately from the bundle price in fixed-price
  mode — it contradicts the price the cart charges. — ADR-0001
- Calling the Admin API from Liquid. — ADR-0002

**Guardrails**
- Block markup < 15 KB and no blocking JS. — ADR-0002
- Unavailable bundle renders a disabled state, never a blank block. — REQ-BUNDLE-005

---

## Checkout extensions

**Required**
- Bundle expansion happens in the cart transform function, not in a checkout UI
  extension; checkout surfaces only display. — ADR-0001
- Function input query requests only the cart lines and bundle definitions it
  needs. — ADR-0001
- Fixed-price allocation rounds on the last component so the sum is exact. — REQ-BUNDLE-004

**Forbidden**
- Checkout UI extensions that mutate line items to build a bundle. — ADR-0001
- Network calls from the function. — ADR-0001
- Floating-point arithmetic on money; use integer minor units. — REQ-BUNDLE-004

**Guardrails**
- Function execution < 5 ms at 10 components; 10-component test fixture is
  mandatory. — REQ-BUNDLE-009
- No panics on missing input — return the cart unchanged. — ADR-0001

---

## Data

**Required**
- Tables: `shop`, `bundle`, `bundle_component`, `sync_job`. All carry
  `shop_domain`; foreign keys cascade within a shop only. — ADR-0002
- SQL migrations in `db/migrations/`, one concern per file, applied before deploy. — ADR-0002
- Soft delete (`deleted_at`) on uninstall; hard delete on `shop/redact`. — REQ-BUNDLE-002
- Money stored in integer minor units with an ISO currency column. — ADR-0001

**Forbidden**
- Customer PII columns of any kind. — REQ-BUNDLE-008
- Cross-shop aggregate queries in request paths. — REQ-BUNDLE-002
- Storing a bundle's rendered Liquid markup. — ADR-0002

**Guardrails**
- 30-day retention after uninstall, then redaction. — REQ-BUNDLE-002
- Query p95 < 50 ms at 10k bundles per shop. — ADR-0002
- Job queue drained by a worker; no in-request job execution. — ADR-0002

---

## Global

- **Naming**: types `PascalCase`, functions `camelCase`, files `kebab-case`,
  GraphQL operations one per file, webhook handlers named by topic
  (`products-update.ts`), requirements `REQ-BUNDLE-NNN`.
- **API version**: read from config; one pin per app; extensions must match it.
- **Forbidden APIs**: any field listed as deprecated in
  `docs/shopify-api-reference/2026-10/`, and any pre-cart-transform bundle
  approach (draft orders, script tags, cart mutation).
- **Secrets**: never logged, never sent to the client, never in a GraphQL
  variable.
