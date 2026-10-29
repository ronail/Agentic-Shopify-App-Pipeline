# ADR-0001: Order Tag Writes Through `tagsAdd`/`tagsRemove` with a Per-Order Queue

## Status

Accepted

## Date

2026-10-29

## Last Verified

2026-10-29

## Decision Makers

`app-architect` (author), `graphql-specialist`, `api-lead`, `technical-director`

## Summary

The app adds and removes order tags only through the `tagsAdd` and `tagsRemove`
mutations, queued per order so writes for one order are serialised. Writing the
full `tags` array, or re-adding a tag that already exists, is forbidden: both
destroy merchant-managed tags.

## Shopify API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | `2026-10` |
| **Surface** | Admin GraphQL (`tagsAdd`, `tagsRemove`, order query) |
| **Knowledge risk** | LOW — tag mutations are stable, but `tagsAdd` on orders shares the global tag namespace and its cost is worth verifying |
| **References consulted** | `docs/shopify-api-reference/2026-10/admin-graphql.md` |
| **Recently introduced APIs used** | None — `tagsAdd`/`tagsRemove` are long-standing; deprecation of REST order tag endpoints is why we are here |
| **Verification required** | On a dev store: tag an order that already has merchant tags, confirm they survive; remove a tag, confirm only that tag is gone; re-run the same rule, confirm no duplicate tag |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | shared `ADR-0001` (API version policy) |
| **Enables** | ADR-0002 (webhooks call this write path) |
| **Blocks** | Every tagging story |
| **Ordering note** | The queue contract is fixed here; ADR-0002 only enqueues |

## Context

### Problem Statement

Tags on an order are a single string list. The obvious implementation — read the
order, append the rule's tags, write the list back — loses a concurrent merchant
edit and reorders tags. Under duplicate webhook delivery it also re-adds tags the
merchant deliberately removed.

### Current State

Research stage; no tagging code. The tag rule model (REQ-TAG-001) is designed but
no write path exists.

### Constraints

- Tag mutations are additive/subtractive; there is no "set" operation that is safe
  against concurrent edits.
- Rate limiting is cost-based; a bulk flash of orders can exhaust the bucket.
- Order data requires protected customer data approval; only ids and tags are
  needed.
- Order tags are visible to merchant automations (Shopify Flow, third-party
  apps), so duplicates and removals are user-visible events.

### Requirements

- Add/remove without touching other tags (REQ-TAG-003).
- Idempotent under duplicate deliveries (REQ-TAG-002).
- Stay inside the cost budget and recover from throttling (REQ-TAG-008).
- No customer PII read or stored (REQ-TAG-006).
- Plan-gated write volume (REQ-TAG-009).

## Decision

1. **Two mutations only**: `tagsAdd(id, tags)` and `tagsRemove(id, tags)`. No
   mutation that replaces the tag list.
2. **No-op check before write**: the queue item carries the tags to add; the worker
   reads the order's current tags (one cheap query) and drops tags already present.
   Removal mirrors this — removing an absent tag is a no-op, not an error.
3. **Per-order serialisation**: queue items are keyed `(shop_domain, order_gid)`.
   A unique partial index on in-flight items per order guarantees ordering; other
   orders proceed in parallel.
4. **Throttle handling**: on `THROTTLED`, read the returned cost and throttle
   status, sleep for the advertised restore time with jitter, and retry the same
   batch (max 5). Work is never dropped — a permanent failure marks the item
   `failed` and surfaces it on the dashboard.
5. **Write accounting**: one `tag_event` row per successful mutation batch, and one
   `usage_counter` increment per tag actually written (what billing counts).
6. **Plan gate**: before a batch is sent, the counter is checked in the same
   transaction that reserves the writes. At the allowance the item is parked as
   `paused_for_plan`, not failed; an upgrade resumes it.

### Architecture

```
  rule match (worker)           per-order queue                Shopify
  ┌───────────────┐    ┌──────────────────────────┐    ┌─────────────────┐
  │ evaluate()    │───>│ (shop, order) unique     │───>│ order.tags query│
  └───────────────┘    │  pending → inflight      │    │ tagsAdd/Remove  │
                       │  parked_for_plan         │    └─────────────────┘
                       └──────────────────────────┘            │
                              │  THROTTLED → backoff, retry    │
                              │  success → tag_event + usage   │
                              v                                v
                       usage_counter (plan gate)          merchant tags intact
```

### Key Interfaces

```
type TagWrite = {
  shopDomain: string;
  orderId: string;              // gid://shopify/Order/...
  add: string[];                // tags to ensure present
  remove: string[];             // tags to ensure absent
  ruleId: string;
};

// worker contract — returns what it actually changed, for accounting
async function applyTagWrite(w: TagWrite): Promise<{
  added: string[]; removed: string[]; skipped: string[];
  status: "applied" | "throttled_retry" | "parked_for_plan" | "failed";
}>;
```

### Implementation Guidelines

- Lower-case compare tags for the no-op check, but write the merchant's original
  casing from the rule.
- Never send more than 25 tags per mutation; chunk and keep per-order ordering.
- Record `ruleId` on `tag_event` so `/reverse-document` and support can explain
  why a tag appeared.
- Do not read line items on the order for tag logic — conditions are evaluated
  from the webhook payload or a narrow query.
- Log `{ shop, orderId, added, removed, status }`; never log the whole order.

## Alternatives Considered

### Alternative 1: Read-modify-write the `tags` array

- **Description**: query current tags, append, mutate the order.
- **Pros**: One mutation; no extra read.
- **Cons**: Races with merchant edits, drops tags added between read and write,
  possibly reorders tags that Flow automations match on.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Silent data loss of merchant state is unacceptable.

### Alternative 2: Tag through order metafields and mirror later

- **Description**: write intent to a metafield and reconcile tags on a schedule.
- **Pros**: Fully decoupled from the mutation cost.
- **Cons**: Tags appear late; merchants filtering by tag see stale results; two
  sources of truth.
- **Estimated Effort**: Higher.
- **Rejection Reason**: Tags are a filtering surface — latency defeats the feature.

## Consequences

### Positive

- Merchant tags are never collateral damage.
- Duplicate deliveries and repeated rule runs converge on the same state.
- Billing counts actual writes, not intents.

### Negative

- One extra read per order per write batch.
- Per-order serialisation limits throughput for pathological single-order bursts
  (rare; orders are independent).
- Paused-for-plan items add a state the dashboard must explain.

### Neutral

- Tag casing is preserved from the rule, not normalised.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Worker deployed mid-batch loses in-flight items | Medium | Medium | Items return to `pending` on lease expiry; the write is idempotent |
| Throttle storm during a flash sale | Medium | Medium | Backoff with jitter; queue absorbs, dashboard shows lag |
| Plan counter race double-reserves | Low | Low | Counter reservation and check in one transaction |
| Merchant automation fights the app (tag add/remove loop) | Low | Medium | Per-order write cap per hour; loop detected and surfaced |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | — | 400 ms per mutation | 1.5 s route p75 |
| GraphQL cost per request | — | ≤ 250 per batch | ≤ 500 |
| Webhook processing lag | — | 60 s p95 to tag visible | p95 < 500 ms handler |
| DB query time (p95) | — | 30 ms queue claim | 50 ms |

## Migration Plan

Greenfield.

1. Create `tag_rule`, `tag_rule_condition`, `tag_event`, `usage_counter`.
2. Deploy the worker with the queue; run with rules disabled.
3. Enable one rule on the dev store, verify merchant tags survive.
4. Enable backfill (ADR-0002) only after the write path passes on 100 orders.

**Rollback plan**: disable rule evaluation. Queued items drain as no-ops; no tag is
removed by a rollback.

## Validation Criteria

- [ ] An order with pre-existing merchant tags keeps them after a rule runs.
- [ ] Running the same rule twice produces no duplicate tag and no second write.
- [ ] A removed tag is gone; other tags unchanged.
- [ ] A throttled batch retries and eventually applies, with no lost tag.
- [ ] `usage_counter` equals the number of tags actually written.

## App Requirements Addressed

| Requirement | Requirement text | How this ADR satisfies it |
|-------------|------------------|---------------------------|
| REQ-TAG-001 | Define rules mapping conditions to tags | Rule evaluation produces the `TagWrite` this ADR applies |
| REQ-TAG-003 | Add/remove only, never replace | `tagsAdd`/`tagsRemove` with a no-op pre-check |
| REQ-TAG-007 | `read_orders`/`write_orders` only | Tag mutations need no additional scope |
| REQ-TAG-008 | Stay in cost budget, recover from throttling | Batch cost ≤ 250, backoff on `THROTTLED`, no dropped work |
| REQ-TAG-009 | Plan-gated write volume | Reservation in the same transaction; park, never drop |

## Related

- ADR-0002 — webhook and backfill paths that feed this queue.
- shared `docs/architecture/ADR-0001-admin-api-version-policy.md`.
- `docs/registry/architecture.yaml` — contract `order_tag_write`.
