# Billing API — 2026-10

Billing is modelled in the Admin GraphQL API through the `AppSubscription` /
`AppPurchase` types and a small set of mutations. Charges are per shop.

## Charge types

- **Recurring (subscription)** — `appSubscriptionCreate`: a plan name, price,
  currency, and a `lineItems` list of `appRecurringPricingDetails` (interval
  `EVERY_30_DAYS` / `ANNUAL`). Optional `trialDays`.
- **Usage-based** — added to a subscription whose line item has
  `appUsagePricingDetails` (capped amount + terms). Record usage with
  `appUsageRecordCreate` against the subscription line item.
- **One-time** — `appPurchaseOneTimeCreate` for a single charge.

Field names and required arguments change more than most surfaces — confirm the
current input shape at
https://shopify.dev/docs/api/admin-graphql/2026-10 (search `appSubscriptionCreate`).

## Flow

1. Merchant clicks upgrade → app calls `appSubscriptionCreate`.
2. Response returns `confirmationUrl` plus a `AppSubscription` in `PENDING`.
3. Redirect the merchant to `confirmationUrl`; Shopify shows its approval page
   and returns them to the app's `returnUrl`.
4. Poll or re-query the subscription; it becomes `ACTIVE` once approved. Grant
   the paid features only on `ACTIVE`, never on the redirect alone.
5. To cancel/downgrade: `appSubscriptionCancel`, or create a replacement
   subscription (Shopify prorates). Handle `APP_SUBSCRIPTIONS_UPDATE` webhooks
   so out-of-band cancellations from the admin are reflected.

## Rules and gotchas

- Prices must be in the shop's billing currency; amount is a decimal string
  (e.g. `"9.99"`), not a float.
- Test charges in a development store behave like real ones but are not billed;
  use the test-mode path documented on shopify.dev rather than stubbing the
  mutation.
- Usage records have a reporting window and are rejected outside it — check the
  recorded-at constraint before batching usage.
- Never gate features on cached subscription state indefinitely: subscriptions
  are cancelled outside the app (admin, uninstall, fraud). Re-check
  `appSubscription` when it matters.
- A shop that uninstalls keeps its subscription record; reconcile on reinstall
  before creating a second one.
