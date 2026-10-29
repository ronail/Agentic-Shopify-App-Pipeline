---
paths:
  - "apps/**"
---

# Auth & Session Rules

- Owner agent: `auth-specialist` — OAuth, session tokens, and token exchange
- Install uses the OAuth flow from `@shopify/shopify-app-remix`; no hand-rolled redirect, state, or nonce handling
- Verify the `hmac` and `state` on the OAuth callback before exchanging the code; reject anything that fails
- Access tokens are stored encrypted in Postgres and never written to logs, errors, or client payloads
- Every admin request carries a session token; verify signature, audience, and expiry server-side and derive the shop from it
- Token exchange for embedded/extension surfaces follows the documented exchange endpoint — no token in the URL
- Handle uninstall (`app/uninstalled`) and scope changes by clearing sessions and re-prompting, not by assuming the token still works
- OAuth round trip completes under 5 s on a dev store; the callback is idempotent on replay
