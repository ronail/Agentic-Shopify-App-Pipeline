---
paths:
  - "apps/**"
---

# Shopify Functions & Checkout Extension Rules

- Owner agent: `checkout-specialist` — Shopify Functions and checkout UI extensions
- Add a Function only when the merchant problem genuinely requires checkout-time evaluation; admin-side logic stays in the app server
- Function input comes through the function's input query — request only the fields the logic uses, and keep the query version pinned to the app's API version
- Function logic is pure: no network, no clock, no randomness; the same input always yields the same output
- Return structured errors/operations the checkout can render; never fail silently and never block checkout on an internal error
- State the runtime limits the function works within (instruction count, output size) and test at the boundary
- Config from merchant settings is validated in the Function and mirrored by a server-side gate the admin shows
- Verify on a real dev-store checkout and record the walkthrough under `production/apps/<app>/qa/evidence/`
