---
paths:
  - "apps/**"
---

# Billing Rules

- Owner agent: `billing-specialist` — Billing API, plan gating, and subscription/usage charges
- Plans and prices come from config, not literals in a route; the shop's active subscription is the single source of gate truth
- Gate at the server boundary (loader/action and queue worker), not in React — a hidden button is not a gate
- Handle the full lifecycle: create, confirm redirect, active, frozen/cancelled, and expired; re-check on app load rather than trusting a cached flag
- Usage charges are reported idempotently with a stable idempotency key and capped by the plan's limit
- Trial and test charges follow the `test` flag of the environment — never charge a dev store
- Every gate path has a test: 100% coverage on plan gating, including the downgrade and cancellation cases
- A merchant who declines must still reach a usable free state, with the paywall showing the exact upgrade action
