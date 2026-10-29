# Storefront API — 2026-10

The Storefront API is a separate GraphQL surface from Admin: read-mostly,
cart/checkout oriented, and safe to call from a buyer-facing client.

## Endpoint

```
POST https://{shop}.myshopify.com/api/2026-10/graphql.json
```

Note the path: `/api/`, not `/admin/api/`. Same versioned-URL rule — pin the
literal `2026-10`.

## Access

- **Public access token** — created as a custom app or a Headless channel's
  storefront token; scoped to specific `unauthenticated_read_*` permissions.
  Safe to ship to the browser (scoped, revocable), but prefer a server-side
  proxy when the token is broad.
- **Private/authenticated access** — server-to-server token created for a
  specific shop, used when the API call must not be exposed to buyers.
- **Customer-scoped access** — buyer tokens for logged-in customer data
  (`customerAccessTokenCreate` flow). Never mix customer-scoped calls with the
  public token.

Tokens are per shop and per app; never reuse an Admin API token here.

## Rate limits

Cost-based, but the bucket is per IP + token rather than per shop the way Admin
is, and capacity differs by plan. Track `extensions.cost.throttleStatus` in the
response and back off; a browser client spread across many buyers gets its own
buckets, a server-side proxy does not — so a server proxy needs real queuing.
Current numbers: https://shopify.dev/docs/api/storefront/2026-10 (Rate limits).

## Common shape

Top-level query roots cover products/collections, search, the cart object
(`cart` + the `cartCreate`/`cartLinesAdd`/`cartLinesUpdate`/`cartDiscountCodesUpdate`
mutations), menus, and shop metafields. Field and connection names are versioned
— look them up at https://shopify.dev/docs/api/storefront/2026-10 rather than
reusing a snippet from an older version.

## Practical rules

- Storefront API has no webhooks; product/price freshness comes from caching
  policy, not push. Cache aggressively client-side and revalidate.
- `@inContext(country:, language:)` controls localization of prices/translations
  — omit it and you get the shop's default market, a frequent source of
  wrong-currency bugs.
- Cart IDs are the durable handle to a cart; persist them (localStorage /
  cookie) or the buyer's cart is lost on navigation.
- Pagination is cursor-based (`pageInfo { hasNextPage endCursor }`); never
  offset-page.
