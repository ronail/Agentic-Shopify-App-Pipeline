# Control Manifest — order-tags

> **API Version**: 2026-10
> **Manifest Version**: 2026-10-29
> **Last Updated**: 2026-10-29
> **ADRs Covered**: ADR-0001 (tag write path), ADR-0002 (order webhooks and backfill), shared ADR-0001 (API version policy)
> **Access Scopes**: `read_orders`, `write_orders`
> **Status**: Active — regenerate with `/create-control-manifest order-tags update`

`Manifest Version` is the date this sheet was generated and always equals
`Last Updated`. Stories embed this value; `/story-readiness` refuses a story
whose embedded version is older, and `/story-done` re-checks it at close.

Derived from the Accepted ADRs above, `.claude/rules/`, and the 2026-10 API
snapshot. For the reasoning behind a rule, read the cited ADR.

---

## Admin UI

**Required**
- Polaris components only; `IndexTable` for the rule list, `ChoiceList` for
  conditions, `Banner` for usage/throttle states. — ADR-0001
- App Bridge session token on every request; no cookie-based session. — ADR-0001
- Save validates the whole rule and shows field-level errors before writing. — REQ-TAG-001
- Backfill progress and plan usage are visible on the dashboard, refreshed by
  revalidation — never a fake progress bar. — REQ-TAG-004, REQ-TAG-009

**Forbidden**
- Client-side Admin API calls. — ADR-0001
- Editing tags on an order from the app UI (the app writes tags by rule, not by
  hand). — REQ-TAG-003
- Hiding a rule that stopped writing because the plan allowance is exhausted;
  show it as paused with the reason. — REQ-TAG-009

**Guardrails**
- Admin route p75 < 1.5 s with 50 rules. — ADR-0001
- WCAG 2.1 AA: rule editor usable by keyboard alone; error text tied to the field. — ADR-0001

---

## App server

**Required**
- Admin GraphQL through the authenticated client; version from `shopify.server`. — shared ADR-0001
- Every query and write is shop-scoped by the session shop's domain. — ADR-0002
- Tag writes serialised per order, parallel across orders, through one queue. — ADR-0001
- Standard response envelope `{ ok, error | data }` from every loader/action. — ADR-0001

**Forbidden**
- REST Admin API. — shared ADR-0001
- Writing the full `tags` array on an order (replaces merchant tags). — REQ-TAG-003
- `first:` without a page size; unbounded result sets. — ADR-0002
- Business logic in a route module — rules evaluation lives in a pure module with
  unit tests. — ADR-0001

**Guardrails**
- GraphQL requested cost per batch ≤ 250; total bucket usage kept under 50%. — REQ-TAG-008
- Retry on `THROTTLED` using the returned cost, max 5 attempts with jitter. — REQ-TAG-008
- Admin API latency p95 400 ms per call. — ADR-0001

---

## Webhooks

**Required**
- HMAC verified against the raw body before parsing; 401 on mismatch. — ADR-0002
- Register `orders/create`, `orders/updated`, `orders/cancelled`,
  `app/uninstalled`, `shop/redact`, `customers/data_request`,
  `customers/redact` in `shopify.app.toml`. — ADR-0002
- Idempotency key `(shop, topic, payload.id, payload.updated_at)` inserted before
  enqueue; duplicates return 200 with no work. — ADR-0002
- Handler enqueues and returns; tagging happens in the worker. — REQ-TAG-002

**Forbidden**
- Calling the Admin API inline in the handler beyond the minimum read. — ADR-0002
- Assuming `orders/updated` arrives after `orders/create`. — ADR-0002
- Trusting the shop domain header without matching an installed shop. — ADR-0002

**Guardrails**
- Handler p95 < 500 ms. — REQ-TAG-002
- Tag visible on the order within 60 s p95 of creation. — REQ-TAG-002
- Replayed payload creates no second write (tested). — ADR-0002

---

## Theme app extensions

**Required**
- None shipped in v1. The app has no storefront surface. — ADR-0001

**Forbidden**
- Any storefront script or app block that exposes order data. — REQ-TAG-006

**Guardrails**
- If a storefront surface is ever added, it requires a new ADR and its own
  scopes justification. — ADR-0001

---

## Checkout extensions

**Required**
- None shipped in v1. Tags are an admin/back-office concern. — ADR-0001

**Forbidden**
- Checkout UI extensions that read or write order tags. — ADR-0001

**Guardrails**
- Adding one requires a new ADR plus a checkout-specialist review. — ADR-0001

---

## Data

**Required**
- Tables: `shop`, `tag_rule`, `tag_rule_condition`, `tag_event`, `backfill_job`,
  `usage_counter`. All carry `shop_domain`. — ADR-0002
- `tag_event` stores order id, rule id, tags written, timestamp — nothing else. — REQ-TAG-005
- SQL migrations in `db/migrations/`; forward-only, one concern per file. — ADR-0002
- Nightly retention job for `tag_event` older than 90 days. — REQ-TAG-005

**Forbidden**
- Customer name, email, phone, address, note, or line-item text in any table. — REQ-TAG-006
- Storing the raw webhook payload. — REQ-TAG-006
- Cross-shop aggregate queries in request paths. — ADR-0002

**Guardrails**
- 90-day log retention, then delete. — REQ-TAG-005
- Backfill checkpoint row per job so a restart resumes. — REQ-TAG-004
- Query p95 < 50 ms at 100k `tag_event` rows per shop. — ADR-0002

---

## Global

- **Naming**: types `PascalCase`, functions `camelCase`, files `kebab-case`,
  GraphQL operations one per file, webhook handlers by topic (`orders-create.ts`),
  requirements `REQ-TAG-NNN`.
- **API version**: read from config; extensions (none today) must match the pin.
- **Forbidden APIs**: deprecated fields listed in
  `docs/shopify-api-reference/2026-10/`; REST order endpoints; `orderUpdate`
  tag-array writes.
- **Secrets**: never logged or sent to the client.
