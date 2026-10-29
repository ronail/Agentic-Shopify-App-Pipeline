# ADR-0001: Bundle Expansion and Pricing in a Cart Transform Function

## Status

Accepted

## Date

2026-10-29

## Last Verified

2026-10-29

## Decision Makers

`app-architect` (author), `checkout-specialist`, `api-lead`, `technical-director`

## Summary

A bundle is sold as one merchant-facing product whose cart line is expanded into
its component lines by a cart transform function, with the bundle price
allocated across components. The alternative — pre-built variants or discount
codes per bundle — cannot keep inventory at component level while showing a
single bundle price.

## Shopify API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | `2026-10` |
| **Surface** | Admin GraphQL (`cartTransformCreate`, `cartTransformDelete`, product + variant queries), Cart Transform Function (Rust/Wasm), Storefront cart |
| **Knowledge risk** | HIGH — function input/output shape and `cartTransformCreate` arguments change faster than the Admin schema; verify against the snapshot, never memory |
| **References consulted** | `docs/shopify-api-reference/2026-10/admin-graphql.md`, `.../checkout-extensions.md`, `shopify.dev/docs/api/functions/cart-transform` |
| **Recently introduced APIs used** | `CartTransform` API `expand`/`update` operations at the pinned version; `cartTransformCreate` binding to the app's function |
| **Verification required** | Add the bundle to a real cart on a dev store: one parent line expands to N components, fixed-price total equals the configured price, inventory decrements per component, removing the parent removes all components |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | shared `ADR-0001` (API version policy) |
| **Enables** | ADR-0002 (reconciliation owns the component data this function reads) |
| **Blocks** | Bundle checkout stories — no cart behaviour ships before this is Accepted |
| **Ordering note** | The function's config metafield shape is fixed here before ADR-0002 writes to it |

## Context

### Problem Statement

Merchants want to sell "3 for $30" style bundles. Shopify has no native bundle
line: either the merchant creates a duplicated bundle product (inventory desyncs
from components) or the storefront fakes it with a discount code (checkout shows
the components at full price until the code applies). Both break the moment a
component's inventory, price, or availability changes.

### Current State

The app is at the research stage. The bundle data model (ADR-0002) stores a
bundle and its components; nothing yet defines how a cart learns about them.

### Constraints

- Cart transform functions run in a sandbox: no network, no database, bounded
  execution time. Input must come from function input, not a fetch.
- Inventory and fulfilment must stay per component — merchants fulfil components.
- The merchant's storefront theme is not under our control; no theme edits are
  assumed beyond one app block.
- One bundle product per bundle definition, because the theme shows a product.

### Requirements

- One bundle line at checkout, N component lines after expansion (REQ-BUNDLE-003).
- Fixed-price mode sums to exactly the configured price (REQ-BUNDLE-004).
- Function execution inside the platform budget (REQ-BUNDLE-009).
- Only `read_products` and `write_products` scopes (REQ-BUNDLE-007).
- A bundle with an unavailable component stops expanding (REQ-BUNDLE-006).

## Decision

1. Each bundle definition has one **bundle product** with one variant, created
   and owned by the app; its price mirrors the bundle price.
2. A **cart transform function** registered once per app (`cartTransformCreate`)
   holds an `expand` operation. Its input query selects the bundle product's
   metafield `$app:bundle/config` (a JSON blob written by ADR-0002) plus the
   component variant ids and prices.
3. On a cart line for a bundle product, the function returns one
   `ExpandedItem` per component with:
   - `quantity = bundle quantity × component quantity`,
   - a `price` set in **fixed-price** mode by proportional allocation of the
     bundle price, or unset in **percentage-off** mode where the component's own
     price already reflects the discount.
4. Allocation uses integer minor units. The running remainder is added to the
   last component so the sum is exact; a zero-price component is allocated 0 and
   excluded from the divisor.
5. If any component variant is missing, unpublished, or out of stock, the
   function returns the cart unchanged. The cart shows the bundle product; a
   `cart transform` diagnostic is not surfaced to the buyer, so the admin disables
   the bundle (ADR-0002) instead of relying on a checkout message.

### Architecture

```
  Admin (embedded)                    Shop DB                  Shopify
  ┌────────────────┐   save bundle   ┌──────────────┐   write metafield
  │ Bundle editor  │ ──────────────> │ bundle       │ ─────────────────┐
  └────────────────┘                 │ bundle_comp. │                  │
                                     └──────────────┘                  v
                                                          bundle product
                                                          $app:bundle/config
                                                                 │
   Storefront cart ── line: bundle product ──────────────────────┘
            │
            v
   Cart Transform Function (expand)
            │  components available? no  → cart unchanged
            │  yes
            v
   N expanded component lines (quantity × component qty, price allocated)
```

### Key Interfaces

```
// metafield shape written by ADR-0002, read by the function
type BundleConfig = {
  version: 1;
  bundleId: string;
  pricingMode: "fixed" | "percentage_off";
  bundlePrice: { amount: string; currencyCode: string };  // minor units in `amount`
  components: { variantId: string; quantity: number; listPrice: string }[];
};

// allocation (integer minor units)
function allocate(total: number, weights: number[]): number[] {
  const sum = weights.reduce((a, b) => a + b, 0);
  if (sum === 0) return weights.map(() => 0);
  const out = weights.map((w) => Math.floor((total * w) / sum));
  out[out.length - 1] += total - out.reduce((a, b) => a + b, 0);
  return out;
}
```

### Implementation Guidelines

- The function reads only selected input; never request the whole cart.
- Do not throw. A missing config metafield means "not a bundle we manage" —
  return the operation unchanged.
- Log a structured line per expansion (`shop`, `bundleId`, `componentCount`) in the
  app server, not the function.
- Re-register the cart transform idempotently on install; `cartTransformCreate`
  is not idempotent by itself — check existing transforms first.

## Alternatives Considered

### Alternative 1: Duplicated bundle product with computed inventory

- **Description**: Synthesise a bundle variant whose quantity is derived from the
  minimum of its components.
- **Pros**: No function; works on any plan.
- **Cons**: Inventory is a lie whenever components move independently; Shopify
  has no per-variant computed inventory; fulfilment must be split manually.
- **Estimated Effort**: Lower to build, permanent support cost.
- **Rejection Reason**: Component inventory accuracy is the merchant's main
  reason to install a bundle app.

### Alternative 2: Discount code applied to components

- **Description**: Buyer adds all components; a code discounts the cart to the
  bundle price.
- **Pros**: Uses the Discount API only; no function deployment.
- **Cons**: The buyer must add N products and remember a code; the cart total
  before the code is wrong; A/B and stacking rules collide with merchant codes.
- **Estimated Effort**: Lower.
- **Rejection Reason**: The cart must show the bundle price before any code is
  entered.

## Consequences

### Positive

- One bundle line, real component inventory, per-component fulfilment.
- Price allocation is deterministic and testable with integer arithmetic.
- The same function serves every bundle in every shop — one deployment.

### Negative

- A function deployment is now part of every release; a bad build breaks cart
  expansion for all shops.
- Function input cost counts against the storefront's cart query budget.
- Merchants cannot hand-edit the bundle product without the app rewriting it.

### Neutral

- The bundle product's own inventory is not tracked; components are.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Function regression breaks checkout across shops | Medium | Critical | Canary on the internal dev store; `/smoke-check` runs a real cart before release |
| Metafield config grows past function input limits at 50 components | Low | High | 50-component ceiling in REQ-BUNDLE-001; measure input size in the test fixture |
| Allocation rounding dispute with merchant accounting | Low | Medium | Exact-sum test with 3 component price shapes per currency |
| Merchant deletes the bundle product | Medium | Medium | ADR-0002 recreates it and flags the bundle in the admin |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | n/a | 400 ms per call | 1.5 s route p75 |
| GraphQL cost per request | n/a | ≤ 500 | ≤ 500 |
| Webhook processing lag | n/a | < 5 min reconcile | p95 < 500 ms handler |
| Function execution | n/a | < 3 ms at 10 components | 5 ms |

## Migration Plan

Greenfield — `cartTransformCreate` runs on install and on the first bundle save.

1. Deploy the function with the app version that introduces bundles.
2. On install, detect an existing transform for this app; create only if absent.
3. Backfill the `$app:bundle/config` metafield for every bundle (worker job).
4. Verify on the dev store with a real cart, then enable the app block.

**Rollback plan**: `cartTransformDelete` disables expansion without uninstalling;
carts revert to selling the bundle product at its own price. Document that state
for the merchant before rollback.

## Validation Criteria

- [ ] A 10-component bundle expands in < 5 ms on the dev store.
- [ ] Fixed-price bundle: sum of expanded prices equals the configured price to
      the minor unit, on three currency shapes.
- [ ] Removing the parent line removes every component line.
- [ ] Out-of-stock component leaves the cart unchanged and the admin shows the
      bundle as disabled.
- [ ] Component inventory decrements correctly on order creation.

## App Requirements Addressed

| Requirement | Requirement text | How this ADR satisfies it |
|-------------|------------------|---------------------------|
| REQ-BUNDLE-003 | One line item expanding into component lines | `expand` operation returns one ExpandedItem per component |
| REQ-BUNDLE-004 | Fixed price allocated across components | Integer-minor-unit proportional allocation with exact remainder |
| REQ-BUNDLE-007 | Only `read_products`/`write_products` | Function reads catalog data from input; no extra scopes |
| REQ-BUNDLE-009 | Function inside execution budget | Input query limited to bundle lines; measured fixture in tests |

## Related

- ADR-0002 — catalogue reconciliation writes the metafield this function reads,
  and disables bundles whose components disappear.
- shared `docs/architecture/ADR-0001-admin-api-version-policy.md` — the version pin.
- `docs/registry/architecture.yaml` — interface contract `bundle_expansion`.
