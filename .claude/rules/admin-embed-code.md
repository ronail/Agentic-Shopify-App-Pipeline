---
paths:
  - "apps/**"
---

# Embedded Admin App Rules

- Owner agent: `lead-engineer` — route structure, embedding, and state ownership for the admin app
- Stack is Remix on Node 20 with `@shopify/shopify-app-remix`; auth and session storage come from the package, not hand-rolled
- Every admin page is embedded and renders inside the Shopify admin frame; no full-page redirects out of the frame
- Route modules split loader (read) from action (mutate); a GET never mutates merchant data
- Server data enters through the loader and is typed at the boundary; the browser gets only what the view renders
- Shared types live in `apps/<app>/types/`, never duplicated per route
- Server-side session token check on every mutation; the shop is resolved from the session, never from a client-supplied parameter
- Delegate UI fidelity to `polaris-specialist`, GraphQL operations to `graphql-specialist`, webhooks to `webhooks-specialist`
