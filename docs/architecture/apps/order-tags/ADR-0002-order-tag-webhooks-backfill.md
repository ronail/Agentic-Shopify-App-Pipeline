# ADR-0002: Order Webhooks for Live Tagging and Bulk Backfill

## Status

Accepted

## Date

2026-10-29

## Last Verified

2026-10-29

## Decision Makers

`app-architect` (author), `webhooks-specialist`, `graphql-specialist`, `technical-director`

## Summary

Order tags are applied live from `orders/create` and `orders/updated` webhooks,
and historically from a resumable bulk-operation backfill. Webhooks are verified,
deduplicated and only enqueue; the backfill reads via a bulk operation and writes
in checkpoints so a 250k-order shop can be tagged without exhausting the API
budget.

## Shopify API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | `2026-10` |
| **Surface** | Webhooks (`orders/create`, `orders/updated`, `orders/cancelled`, compliance topics), Admin GraphQL (`bulkOperationRunQuery`, bulk result polling, order query), Job queue |
| **Knowledge risk** | MEDIUM — bulk operation result shape and polling fields must be read from the snapshot; order webhook payload fields vary by version |
| **References consulted** | `docs/shopify-api-reference/2026-10/webhooks.md`, `.../admin-graphql.md` |
| **Recently introduced APIs used** | `bulkOperationRunQuery` polling fields at the pinned version |
| **Verification required** | On a dev store: create an order matching a rule → tag appears within 60 s; replay the delivery → no second tag; run backfill over 500 seeded orders → progress accurate and resumable after a worker restart |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (the tag write path and its queue) |
| **Enables** | Backfill and compliance stories |
| **Blocks** | Any story claiming historical orders get tagged |
| **Ordering note** | Backfill writes through ADR-0001's queue; do not add a second write path |

## Context

### Problem Statement

A merchant enabling the app expects existing orders to be tagged, and new orders
to be tagged immediately. Naively, that is "loop over all orders and tag them" —
which times out, exhausts the cost bucket, and dies halfway with no record of
where it stopped. Webhook delivery is at-least-once and unordered, so live tagging
must dedupe.

### Current State

Rule evaluation exists as a pure module (ADR-0001). Nothing feeds it orders yet.

### Constraints

- A synchronous request cannot process a 250k-order shop; work must be a job.
- Bulk operations are the only practical way to read a large order set; they are
  asynchronous and their JSONL result is fetched after completion.
- Compliance webhooks (`shop/redact`, `customers/*`) are mandatory and must be
  handled by the same verified pipeline.
- No PII may be stored, so the backfill may not persist order payloads.

### Requirements

- Tag within 60 s p95 of order creation (REQ-TAG-002).
- Backfill up to 250k orders, resumable (REQ-TAG-004).
- Idempotent under duplicate delivery (REQ-TAG-002).
- Log 90 days, shop-scoped (REQ-TAG-005).
- Redaction honoured, including mid-backfill (REQ-TAG-006).

## Decision

1. **Live path**: `orders/create` and `orders/updated` are verified (HMAC on the raw
   body), deduplicated on `(shop, topic, payload.id, payload.updated_at)`, and
   enqueued. The worker evaluates rules against the narrow fields the payload
   carries; if a condition needs data absent from the payload (for example a
   discount code list), one narrow query fetches it.
2. **`orders/updated` scope**: only rules whose conditions could have changed are
   re-evaluated — a shipping-address change does not re-run a total-based rule.
3. **Backfill**: `bulkOperationRunQuery` selects order id + the fields the enabled
   rules need, over the merchant's chosen date range. The JSONL result is streamed,
   evaluated in memory, and written through ADR-0001's queue in batches.
4. **Checkpointing**: `backfill_job` stores `bulk_operation_id`, `cursor` (last
   processed line), and counts (`processed`, `matched`, `written`). A restart
   resumes from the cursor; writes are idempotent so a re-run costs no duplicates.
5. **Cancellation and redaction**: `shop/redact` or `customers/redact` cancels the
   job, deletes log rows in the same transaction, and marks the job
   `cancelled_by_redaction`. It cannot be resumed.
6. **Cancelled orders**: `orders/cancelled` re-evaluates removal rules only; the app
   never strips tags it did not write.

### Architecture

```
 orders/create|updated ──> verify HMAC ──> dedupe key ──> queue (ADR-0001)
                                                              │
                                           worker evaluates rules (narrow query
                                           only when the payload lacks a field)
                                                              │
                                                     tagsAdd / tagsRemove

 backfill (merchant-triggered)
   bulkOperationRunQuery(orders in range)
        │ poll until COMPLETED → JSONL url
        v
   stream lines → evaluate → enqueue batches → checkpoint cursor
        │  restart → resume from cursor
        v
   backfill_job: processed / matched / written   (shown in admin)
```

### Key Interfaces

```
type BackfillJob = {
  shopDomain: string;
  bulkOperationId: string | null;
  cursor: number;                 // last processed JSONL line
  rangeFrom: Date; rangeTo: Date;
  processed: number; matched: number; written: number;
  status: "queued" | "running" | "paused_for_plan" | "completed"
        | "failed" | "cancelled_by_redaction";
};

async function runBackfill(job: BackfillJob): Promise<void>;
```

### Implementation Guidelines

- Poll the bulk operation with backoff; do not exceed one poll per 2 s.
- Stream the JSONL result — never load the whole file into memory.
- A rule disabled mid-backfill is skipped from that point on; do not fail the job.
- Counters are updated per batch so progress survives a crash.
- Never persist the order payload; evaluate and discard.
- Compliance handlers must respond 200 even when the payload references an unknown
  shop — log and continue.

## Alternatives Considered

### Alternative 1: Paged synchronous sweep

- **Description**: paginate `orders` with `first: 250` and tag inline.
- **Pros**: Simpler; progress is obvious.
- **Cons**: Shares the cost bucket with the merchant's other apps; a 250k shop takes
  hours of wall clock and a deploy kills it.
- **Estimated Effort**: Lower.
- **Rejection Reason**: No resumability, no isolation from the live cost budget.

### Alternative 2: Backfill on read (tag when the merchant filters orders)

- **Description**: tag lazily as orders are viewed.
- **Pros**: Zero upfront cost.
- **Cons**: Tags exist only for orders someone looked at; merchant automations and
  exports see an incomplete set.
- **Estimated Effort**: Lower.
- **Rejection Reason**: The feature's value is complete, queryable tags.

## Consequences

### Positive

- Existing orders get tagged with accurate, resumable progress.
- Live tagging is decoupled from webhook latency.
- One verified pipeline also covers compliance webhooks.

### Negative

- A backfill competes with live tagging for the same queue; live work is prioritised
  and backfill may visibly pause.
- Bulk results are transient URLs — a long outage can require restarting a job.

### Neutral

- Backfill is opt-in per merchant, over a chosen date range.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Bulk result URL expires before processing | Low | Medium | Restart the bulk operation from the last checkpoint; counters preserved |
| Live tagging starved by backfill | Medium | Medium | Separate queues; live is higher priority |
| Redaction races the worker | Low | High | Redaction cancels the job in the same transaction as the deletes |
| Webhook subscription missing after a version bump | Medium | High | Boot assertion on the registered topic list; `/smoke-check` replays one topic |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | — | 400 ms per call | 1.5 s route p75 |
| GraphQL cost per request | — | ≤ 250 per batch | ≤ 500 |
| Webhook processing lag | — | 60 s p95 to tag visible | p95 < 500 ms handler |
| DB query time (p95) | — | 50 ms checkpoint write | 50 ms |

## Migration Plan

Greenfield.

1. Register the webhook topics and compliance handlers; deploy.
2. Verify live tagging on the dev store with one rule.
3. Seed 500 orders, run backfill, kill the worker mid-run, confirm resume.
4. Only then expose backfill in the admin.

**Rollback plan**: stop the worker and disable rule evaluation. Tags already written
remain unless the merchant removes them; no destructive rollback exists by design.

## Validation Criteria

- [ ] Order matching a rule shows the tag within 60 s p95.
- [ ] Replaying an `orders/create` delivery produces no duplicate tag.
- [ ] Backfill over 500 orders reports accurate counts and resumes after a restart.
- [ ] `shop/redact` mid-backfill cancels the job and deletes its log rows.
- [ ] No order payload is persisted anywhere (schema inspection).

## App Requirements Addressed

| Requirement | Requirement text | How this ADR satisfies it |
|-------------|------------------|---------------------------|
| REQ-TAG-002 | Tag within 60 s p95, re-tag on update | Verified webhook → queue → ADR-0001 write path |
| REQ-TAG-004 | Resumable backfill up to 250k orders | Bulk read + streamed evaluation + checkpointed writes |
| REQ-TAG-005 | 90-day shop-scoped log | `tag_event` written by the queue, pruned nightly |
| REQ-TAG-006 | No PII, honour redaction | Payloads never persisted; redaction cancels jobs transactionally |

## Related

- ADR-0001 — the only tag write path.
- shared `docs/architecture/ADR-0001-admin-api-version-policy.md`.
- `docs/registry/architecture.yaml` — contract `order_tag_ingress`.
