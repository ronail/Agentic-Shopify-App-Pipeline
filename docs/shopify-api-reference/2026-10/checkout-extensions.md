# Checkout Extensions — 2026-10

Checkout UI extensions are UI extension targets rendered inside Shopify
Checkout, configured through the app's `shopify.extension.toml` and built with
the checkout UI extension component library.

## Targets

- `purchase.checkout.block.render` — the general-purpose extension point; the
  default choice when nothing more specific is needed.
- Placement-specific targets exist for narrow slots (delivery options, payment
  methods, order summary, contact/shipping steps). The set changes between
  releases; take the current target list from
  https://shopify.dev/docs/api/checkout-extensions/checkout/2026-10 rather than
  copying a target name from older samples.
- Targets that must statically render during checkout performance work are
  classified as "static" vs "dynamic" targets — a static target cannot call a
  network API during render. Check the classification for the target you pick.

## Extension config

`shopify.extension.toml` in the extension directory declares `api_version`,
`type = "ui_extension"`, and the extension's targets. The `api_version` must
match the app's pin (`2026-10`); a mismatch is the most common cause of an
extension failing to build or silently using older render semantics.

## Capabilities and API access

- Extension code runs sandboxed: no DOM access, no arbitrary `fetch` to your
  server. Network access goes through the provided API module and only to
  endpoints you configured (allowed network access in the toml).
- Reading buyer/cart data uses the extension API's typed hooks; writing cart
  state uses the extension's cart mutation API. Don't guess field names — the
  component and API surface is versioned, see
  https://shopify.dev/docs/api/checkout-extensions/checkout/2026-10.
- Some surfaces (network access, certain buyer data) require declaring the
  capability and passing app review.

## Practical rules

- Keep extensions thin: render state passed in by the checkout, call your
  backend for anything business-logic heavy, and degrade to "render nothing" on
  failure — a thrown error in checkout extension code can block checkout.
- Test with `shopify app dev` against a development store; the extension
  behaves differently in a preview vs a real checkout.
- TypeScript type packages are versioned with the API version; pin the package
  version that matches `2026-10`.
