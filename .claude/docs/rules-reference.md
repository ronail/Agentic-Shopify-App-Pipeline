# Path-Specific Rules

Rules in `.claude/rules/` are automatically enforced when editing files in matching paths.
One rule file per concern; the owner agent named in the body is the reviewer of record.

| Rule File | Path Pattern | Owner | Enforces |
| ---- | ---- | ---- | ---- |
| `admin-embed-code.md` | `apps/**` | `lead-engineer` | Embedding, loader/action split, session token on mutations |
| `ui-code.md` | `apps/**` | `polaris-specialist` | Polaris-first markup, App Bridge context, loading/empty/error states |
| `theme-extension-code.md` | `apps/**` | `liquid-specialist` | App blocks, block schema defaults, escaped presentation-only Liquid |
| `graphql-code.md` | `apps/**` | `graphql-specialist` | One operation per file, cost budgets, cursor pagination, userErrors |
| `webhook-code.md` | `apps/**` | `webhooks-specialist` | HMAC before side effects, idempotency, fast ack, retries and backfill |
| `billing-code.md` | `apps/**` | `billing-specialist` | Plan gating server-side, lifecycle handling, idempotent usage charges |
| `auth-code.md` | `apps/**` | `auth-specialist` | OAuth state/HMAC checks, encrypted tokens, session token verification |
| `functions-code.md` | `apps/**` | `checkout-specialist` | Pure Function logic, pinned input query, checkout-time limits |
| `network-code.md` | `apps/**` | `lead-engineer` | Typed Admin API client, version from config, bounded retries |
| `data-files.md` | `apps/**/*.json` | `app-architect` | Config schema validation, single API-version pin, no orphan keys |
| `design-docs.md` | `design/**` | `product-director` | ADRs, requirement IDs, 8 mandatory sections, supersession |
| `prototype-code.md` | `apps/**/prototype/**` | `technical-director` | Throwaway scope, dev-store only, verdict README |
| `test-standards.md` | `apps/**` | `qa-lead` | Vitest beside source, determinism, injection, coverage gates |
