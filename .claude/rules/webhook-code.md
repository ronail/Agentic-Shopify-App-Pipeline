---
paths:
  - "apps/**"
---

# Webhook Handling Rules

- Owner agent: `webhooks-specialist` — subscription registration, verification, idempotency, and backfill
- Verify the HMAC over the raw body before parsing or any side effect; a failed check returns 401 and does nothing else
- Handlers are idempotent: dedupe on the delivery/event ID and key writes by the Shopify resource ID so replays converge
- Acknowledge within 500 ms p95 — validate, enqueue, return 200; slow work runs in the worker, never in the request
- Handle topics as separate modules named `kebab-case`, one file per topic (`orders-create.ts`)
- Registration is declarative in the app config (compliance topics included); reconcile subscriptions on install and on version change
- Retries are expected: on failure let Shopify redeliver, and provide a backfill job that replays a topic from the API for missed windows
- Log shop, topic, and delivery ID on failure — never the payload body or tokens
