# Webhooks — 2026-10

## Structure

A webhook is a `POST` to the app's endpoint with a JSON body (the resource, in
the shape of the subscribed topic) plus identifying headers. Payload shape and
available topics follow the API version the subscription was created under, so
the version a webhook was registered with is part of its contract.

## Topics

- Named `RESOURCE_ACTION` in UPPER_SNAKE, e.g. `ORDERS_CREATE`,
  `PRODUCTS_UPDATE`, `APP_UNINSTALLED`, `CUSTOMERS_DATA_REQUEST`,
  `CUSTOMERS_REDACT`, `SHOP_REDACT`.
- Newer resources can be subscribed with the GraphQL subscription type using a
  lowercase `resource/action` form (e.g. `products/update`) — the exact
  supported set differs per topic; check the topic list at
  https://shopify.dev/docs/api/webhooks/2026-10 rather than assuming a topic
  exists for a resource.
- GDPR/mandatory topics (`CUSTOMERS_DATA_REQUEST`, `CUSTOMERS_REDACT`,
  `SHOP_REDACT`) must be handled for app review; they cannot be opted out of.
- Subscriptions are declared in `shopify.app.toml` where possible, and at
  runtime via the `webhookSubscriptionCreate` mutation when the app needs
  dynamic subscriptions.

## HMAC verification

Every request is signed; verify before parsing the body:

- Header `X-Shopify-Hmac-Sha256` holds a base64-encoded HMAC-SHA256 of the
  **raw request body bytes** using the app's client secret (API secret key).
- Compare in constant time against the raw body — parsing and re-serializing
  JSON changes the bytes and breaks the check.
- Reject with 401 on mismatch. Respond 200 quickly (Shopify's timeout is short,
  on the order of seconds) and do the real work asynchronously; a non-2xx or
  timeout triggers retries with backoff.

Other useful headers: `X-Shopify-Topic`, `X-Shopify-Shop-Domain`,
`X-Shopify-Webhook-Id` (use for dedupe — delivery is at-least-once),
`X-Shopify-Event-Id`, `X-Shopify-Triggered-At`.

## X-Shopify-Api-Version

Requests carry `X-Shopify-Api-Version: 2026-10`. That header states which
version's payload shape the body uses. Log it on every delivery and branch on it
when a payload field changed between versions — do not assume every delivery is
the pinned version while an older subscription is still live.

## Dialect

Two delivery dialects exist: the classic HTTP webhook (as above, one resource
per request) and event-bridge style payloads used by some newer topics. If a
body doesn't look like a single resource, check the topic's docs at
https://shopify.dev/docs/api/webhooks/2026-10 before writing a parser.
