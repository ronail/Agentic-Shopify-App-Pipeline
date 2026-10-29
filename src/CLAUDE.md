# Source Directory

When writing or editing app code in this directory, follow these standards.

## Shopify API Version Warning

The LLM's training data predates the pinned Shopify API version.
**Always check `docs/shopify-api-reference/` before using any Admin GraphQL
query, mutation, or webhook payload.**
Do not guess at field names, mutation arguments, or deprecation status — look
them up in the pinned snapshot first.

## Coding Standards

- TypeScript everywhere; React components for the embedded admin surface
- All public APIs require doc comments (exported functions, types, hooks)
- Merchant-visible values must be **data-driven** (external config), never
  hardcoded in components
- Prefer dependency injection over module-level singletons for testability
- Every new subsystem needs a corresponding ADR in `docs/architecture/apps/<app>/`
- Commits must reference the relevant story ID or requirement ID

## File Routing

Match the specialist to the file type being written:

| File type | Specialist |
|-----------|-----------|
| React / Polaris admin UI | `polaris-specialist` |
| GraphQL queries, mutations, bulk ops | `graphql-specialist` |
| Webhook handlers and subscriptions | `webhooks-specialist` |
| Billing and plan gating | `billing-specialist` |
| OAuth, session tokens, App Bridge | `auth-specialist` |
| Liquid, theme app extensions, app blocks | `liquid-specialist` |
| Checkout UI extensions | `checkout-specialist` |

When in doubt, use `lead-engineer`, which owns the code review gate.

## Layout

App code lives under `apps/<app-name>/`. Shared libraries stay in `src/`.
There is no top-level `tests/` directory.

## Tests

Tests live **beside the source they cover**, inside `apps/<app-name>/`:
`discount.ts` and `discount.test.ts` in the same folder. Vitest picks them up by
glob; there is no separate test tree to keep in sync.

Every non-trivial module needs unit tests covering its calculations, edge cases,
and error paths. GraphQL calls and webhook handlers are tested against recorded
fixtures, not a live store.

## Verification-Driven Development

Write tests first when adding a subsystem.
For admin UI changes, verify with Polaris screenshots or an interaction test.
Compare expected output to actual output before marking work complete.
