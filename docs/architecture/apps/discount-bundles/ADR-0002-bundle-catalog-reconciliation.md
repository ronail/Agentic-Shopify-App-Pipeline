# ADR-0002: Bundle Catalogue Reconciliation from Product Webhooks

## Status

Accepted

## Date

2026-10-29

## Last Verified

2026-10-29

## Decision Makers

`app-architect` (author), `webhooks-specialist`, `devops-engineer`, `technical-director`

## Summary

Bundle definitions are the app's source of truth, but the catalog they reference
moves without us. Product webhooks drive an idempotent reconciliation job that
keeps the bundle product, its `$app:bundle/config` metafield, and each bundle's
enabled state in step with the merchant's catalog, instead of trusting data
captured when the bundle was saved.

## Shopify API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | `2026-10` |
| **Surface** | Admin GraphQL (`productCreate`, `productUpdate`, `productVariantsBulkUpdate`, `metafieldsSet`, `webhookSubscriptionCreate`), Webhooks |
| **Knowledge risk** | MEDIUM — product mutation arguments and `metafieldsSet` limits must be read from the snapshot; webhook payload field names drift between versions |
| **References consulted** | `docs/shopify-api-reference/2026-10/webhooks.md`, `.../admin-graphql.md` |
| **Recently introduced APIs used** | `metafieldsSet` batching limits at the pinned version; `products/delete` payload `id` shape |
| **Verification required** | On a dev store: delete a component variant → bundle disabled within 5 minutes; replay the same webhook twice → one reconciliation; uninstall → soft delete, `shop/redact` → hard delete |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (the metafield contract and bundle product shape) |
| **Enables** | Bundle lifecycle stories (disable/restore), compliance stories (redaction) |
| **Blocks** | Any story that claims a bundle stays correct as the catalog changes |
| **Ordering note** | The metafield shape is fixed by ADR-0001; this ADR must not change it without superseding both |

## Context

### Problem Statement

A bundle references variants by GID. Merchants rename products, change variant
prices, unpublish, and delete. Without reconciliation the app either keeps
serving a broken bundle (cart transform returns early, merchant sees no sales) or
keeps stale prices in the `$app:bundle/config` metafield (buyer pays the wrong
amount).

### Current State

Bundle rows and components exist in the app database (ADR-0002 owns them). The
function from ADR-0001 consumes a metafield that nothing writes yet.

### Constraints

- Webhook delivery is at-least-once and unordered; duplicates are normal.
- Payloads are thin — a `products/delete` payload carries an id, not the previous
  state. Anything else must be read back from the API.
- Scope is `read_products`/`write_products` only; no order-scoped data at all.
- The app must satisfy Shopify's mandatory compliance webhooks.

### Requirements

- Reconcile within 5 minutes of a catalog change (REQ-BUNDLE-006).
- Shop-scoped persistence, 30-day recovery then redaction (REQ-BUNDLE-002).
- No customer PII, redaction verified in the test store (REQ-BUNDLE-008).
- Bundle product + metafield stay consistent with the bundle definition
  (REQ-BUNDLE-001, REQ-BUNDLE-005).

## Decision

1. **One reconciliation job**, keyed by `(shop_domain, kind, target_id)`, stored in
   `sync_job` with a unique constraint. Webhook handlers only enqueue; they never
   do catalog I/O inline.
2. **Idempotency key** `(shop, topic, payload.id, payload.updated_at)` is inserted
   before enqueueing. A duplicate delivery violates the unique key and exits 200.
3. **Reconcile pass** per bundle referencing the affected variant:
   - re-read the variant + product (title, status, price, availability),
   - rewrite `$app:bundle/config` via a single `metafieldsSet`,
   - set `bundle.disabled_reason` when any component is deleted, unpublished, or
     `null` in the read-back, else clear it.
4. **Bundle product ownership**: the app creates one product per bundle and keeps
   its title and price aligned with the definition on every reconcile. A merchant
   deleting that product triggers a recreate, and the admin flags it.
5. **Lifecycle**: `app/uninstalled` → soft delete (`deleted_at`) and cancel queued
   jobs. `shop/redact` → hard delete of `shop`, `bundle`, `bundle_component`,
   `sync_job`, verified by a count query in the test store.
6. **Failure policy**: a reconcile that fails on a transient API error retries
   with exponential backoff (max 5, jittered). Persistent failure marks the job
   `failed`, surfaces a banner in the admin, and does not block other bundles.

### Architecture

```
 products/* webhook ──> verify HMAC ──> insert idempotency key
                                              │ duplicate → 200
                                              v
                                        sync_job (unique per shop+kind+target)
                                              │
                                        worker (queue drain)
                                              │
                              ┌───────────────┴───────────────┐
                              v                               v
                   read variant/product back            metafieldsSet
                              │                               │
                    component missing?                config rewritten
                     yes → bundle.disabled_reason
                     no  → clear reason
```

### Key Interfaces

```
type SyncJob = {
  shopDomain: string;
  kind: "variant" | "product" | "bundle";
  targetId: string;          // GID
  attempts: number;
  runAfter: Date;            // backoff schedule
};

// enqueue is the only thing a webhook handler does
async function enqueue(shop: string, kind: SyncJob["kind"], targetId: string) {
  await db.insert("sync_job")
    .values({ shopDomain: shop, kind, targetId })
    .onConflictDoNothing();     // unique (shop, kind, target) → idempotent
}
```

### Implementation Guidelines

- Verify HMAC against the **raw** body before JSON parsing; reject with 401.
- Never infer state from a delete payload beyond the id; read the catalog back.
- Batch `metafieldsSet` by owner; never one call per metafield.
- Log `{ shop, topic, id, jobId, outcome }` — no tokens, no customer data.
- A reconcile must be safe to run twice concurrently; take a per-bundle advisory
  lock or rely on the unique job row.

## Alternatives Considered

### Alternative 1: Sync on read (validate when the merchant opens the editor)

- **Description**: Check the catalog only when the admin page loads.
- **Pros**: No webhooks, no worker.
- **Cons**: Checkout uses the metafield, not the admin page; a stale bundle keeps
  selling a deleted component until someone opens the editor.
- **Estimated Effort**: Lower.
- **Rejection Reason**: The failure mode is a broken cart with no signal.

### Alternative 2: Scheduled full sweep every 15 minutes

- **Description**: Poll the catalog for every bundle on a timer.
- **Pros**: No webhook plumbing; self-healing.
- **Cons**: 100 bundles × 10 variants = 1000 API calls per shop per sweep; burns
  the rate-limit budget and still lags 15 minutes.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Cost grows with catalog size; webhooks are cheaper and
  faster. A weekly sweep is kept only as a safety net for missed deliveries.

## Consequences

### Positive

- A deleted component disables the bundle instead of silently breaking the cart.
- Duplicate deliveries are provably no-ops.
- Compliance webhooks have one home and one deletion path.

### Negative

- A worker process and queue table are now part of the deployment.
- Webhook registration must match the topics the reconciliation depends on; a
  missing subscription degrades to the weekly sweep.

### Neutral

- The bundle product is app-owned, so merchant edits to it are overwritten;
  documented in the admin.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Worker down → silent drift | Medium | High | Job lag alert; admin banner when `sync_job` age > 15 min |
| Webhook flood on bulk catalog import | Medium | Medium | Enqueue is a single insert; unique key collapses repeats |
| Redaction racing an in-flight reconcile | Low | High | Redact cancels jobs and deletes in one transaction |
| Metafield write conflicts with a second app instance | Low | Medium | Writes only under `$app:` namespace |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | 400 ms | 450 ms on reconcile | 1.5 s route p75 |
| GraphQL cost per request | ≤ 500 | ≤ 500 | ≤ 500 |
| Webhook processing lag | — | 5 min to reconcile | p95 < 500 ms handler |
| DB query time (p95) | 50 ms | 50 ms | 50 ms |

## Migration Plan

Greenfield, but the order matters because the function from ADR-0001 needs the
metafield to exist.

1. Create `shop`, `bundle`, `bundle_component`, `sync_job` tables.
2. Register webhook topics in `shopify.app.toml`, deploy, install on dev store.
3. Run a one-off backfill job that writes `$app:bundle/config` for existing bundles.
4. Verify delete → disabled within 5 minutes, and a replayed payload → one job.

**Rollback plan**: disable the worker and the cart transform together
(`cartTransformDelete`). Bundles stop expanding; no data is lost.

## Validation Criteria

- [ ] Deleting a component variant disables the bundle within 5 minutes.
- [ ] Replaying an identical webhook delivery creates no second job.
- [ ] Uninstall soft-deletes; `shop/redact` removes every row (count query = 0).
- [ ] A reconcile failure retries 5 times with backoff, then surfaces a banner.
- [ ] No customer-identifying column exists in the schema.

## App Requirements Addressed

| Requirement | Requirement text | How this ADR satisfies it |
|-------------|------------------|---------------------------|
| REQ-BUNDLE-001 | Create/edit/duplicate/delete bundles from the admin | Bundle product + metafield maintained by the reconcile pass |
| REQ-BUNDLE-002 | Shop-scoped persistence, 30-day recovery | `shop_domain` on every row; soft delete then redact |
| REQ-BUNDLE-005 | Theme block renders bundle contents | Block reads the reconciled config, not a stale snapshot |
| REQ-BUNDLE-006 | Catalogue changes reconcile, bundle disables | Webhook → job → `disabled_reason` |
| REQ-BUNDLE-008 | No PII; redaction within 30 days | Compliance topics + transactional hard delete |

## Related

- ADR-0001 — defines the metafield contract this ADR writes.
- shared `docs/architecture/ADR-0001-admin-api-version-policy.md`.
- `docs/registry/architecture.yaml` — stance `bundle_config_metafield` and
  contract `catalog_reconciliation`.
