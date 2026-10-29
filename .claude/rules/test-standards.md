---
paths:
  - "apps/**"
---

# Test Standards (Vitest)

- Framework is Vitest, tests live beside the source they cover in `apps/<app>/` — `discount.ts` and `discount.test.ts` in the same folder
- Test names read as behaviour: `it('returns the tiered discount for a 3-item cart')`
- Deterministic: no live network, no wall-clock assertions, no unseeded randomness; GraphQL responses are replayed fixtures
- Unit tests inject the API client and repository — never touch the Admin API, a database, or the filesystem directly
- Fixtures come from factories or checked-in JSON, not inline magic values (exact numbers only in boundary tests)
- Coverage gate: 80% lines on shared modules, 100% on billing plan gating and webhook HMAC verification
- Every test sets up and tears down its own state and passes in isolation and in random order
- CI runs `npm run test` on every PR; never skip or disable a failing test to make the gate green
