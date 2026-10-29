# Shopify API 2026-10 — Surface Notes

Snapshot of the Shopify APIs at version `2026-10` (latest stable as of
2026-10-01, supported until 2027-10-16). Read the relevant file before writing
against that surface.

| Surface | File | Covers |
| --- | --- | --- |
| Admin GraphQL | [admin-graphql.md](admin-graphql.md) | versioned endpoint, cost-based throttling, bulk operations |
| Webhooks | [webhooks.md](webhooks.md) | topics, HMAC verification, `X-Shopify-Api-Version` |
| Billing | [billing.md](billing.md) | subscriptions, usage charges, charge lifecycle |
| Checkout extensions | [checkout-extensions.md](checkout-extensions.md) | checkout UI extension targets and config |
| Storefront | [storefront.md](storefront.md) | Storefront API, tokens, rate limits |

Canonical source for anything not recorded here:
https://shopify.dev/docs/api — check the `2026-10` section of the surface in
question and add the finding to the right file rather than guessing a field
name.
