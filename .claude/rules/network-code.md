---
paths:
  - "apps/**"
---

# Admin API & Webhook Network Rules

- All Admin GraphQL traffic goes through one typed client module per app; routes never inline a fetch
- The API version is read from `apps/<app>/shopify.app.toml` config — never hardcoded in a query, route, or test
- Retry only idempotent operations, with bounded exponential backoff and jitter; honour `Retry-After` on THROTTLED
- Inspect `errors` and `data.*.userErrors` on every response — a 200 with userErrors is a failure, not a success
- Webhook deliveries are verified (HMAC) before any side effect, acknowledged fast, and processed from the queue
- Log request/extensible cost and throttled status for every call that exceeds the app's budget
- Outbound calls to other services carry a timeout and a circuit-breaker style guard; a slow dependency must not stall the queue
- Never log access tokens, session tokens, or full merchant payloads
