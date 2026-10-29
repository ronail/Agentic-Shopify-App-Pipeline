# Pricing Plan: [App Name]

> **App**: `apps/<app>` · **Owner**: growth-lead + billing-specialist
> **Implemented with**: Shopify Billing API (`appSubscriptionCreate`, usage records)
> **Gate**: gate-4-release · **Verified by**: `/release` + `/app-store-checklist`

## Plans

| Plan | Price | Interval | Trial | Target merchant | Positioning |
|------|-------|----------|-------|-----------------|-------------|
| Free | $0 | — | — | Evaluating, < [N] orders/mo | Prove the core loop |
| Growth | $[X] | monthly | [N] days | [Segment] | The default choice |
| Pro | $[Y] | monthly | [N] days | [Segment] | Volume + automation |
| Usage add-on | $[Z] / [1,000 records] | — | — | Burst workloads | Pays for spikes |

Annual option: [yes/no — with the Shopify-supported interval]

## Feature Matrix

| Capability | Free | Growth | Pro |
|------------|------|--------|-----|
| [Core workflow] | [N records/mo] | [N] | Unlimited |
| [Automation] | — | ✓ | ✓ |
| [Multi-location] | — | — | ✓ |
| [Exports] | — | ✓ | ✓ |
| [Priority support] | — | — | ✓ |

**Rule**: every gate in the matrix is enforced server-side, not by hiding UI.

## Billing Implementation

| Concern | Approach |
|---------|----------|
| Plan creation | `appSubscriptionCreate` with `returnUrl` and `test: true` in dev |
| Trial | [N] days via `trialDays`; no charge during trial |
| Entitlement cache | Stored on the shop record; reconciled by `app_subscriptions/update` |
| Usage charges | `appUsageRecordCreate` with an idempotency key per record |
| Upgrade | New subscription created, old cancelled after the new one is active |
| Downgrade | Takes effect at period end; features gate immediately on next request |
| Cancellation | `appSubscriptionCancel`; reason captured |
| Failed payment | Shopify retries; app must not silently keep serving paid features forever |
| Uninstall | Subscription cancelled by Shopify; stop jobs, purge per policy |

## Merchant-Facing Rules

- The price is visible before the charge, in the admin and in the listing.
- No charge without an explicit merchant action.
- Trial expiry is communicated at least [N] days ahead.
- Downgrades never delete merchant data; they restrict features.
- Refunds: [policy — who approves, how it is issued].

## Economics

| Metric | Value | Assumption |
|--------|-------|------------|
| Target ARPU | $[X]/mo | |
| Estimated support cost | $[Y]/merchant/mo | [basis] |
| Gross margin target | [N]% | After hosting + API costs |
| Payback period | [N] months | |

## Testing

| Test | Method | Expected |
|------|--------|----------|
| Trial start | Install + approve plan in dev store | Subscription active, `trialDays` honoured |
| Trial to paid | Shorten trial flag in dev | Charge appears, entitlement stays |
| Upgrade | Growth → Pro | New subscription, old cancelled |
| Downgrade | Pro → Growth | Features gate at period end |
| Cancel | Cancel from admin | Access ends at period end, data retained |
| Usage charge | Emit [N] records | Single charge, deduplicated on retry |
| Uninstall | Uninstall | Subscription cancelled, no orphan charges |

## Listing Copy

[How pricing is described on the App Store listing — must match this document and
the Partner dashboard exactly. Mismatch is a review rejection.]

## Open Questions

| # | Question | Owner | Needed by |
|---|----------|-------|-----------|
| 1 | [e.g. is usage pricing understood by merchants?] | [growth-lead] | [date] |
