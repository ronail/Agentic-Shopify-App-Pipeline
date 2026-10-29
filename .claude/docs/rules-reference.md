# Path-Specific Rules

Thirteen rule files live in `.claude/rules/`. A rule is applied when the file
being edited matches the `paths:` glob in its frontmatter — the rules are not
loaded all at once, so a rule and its path pattern must stay in step.

The owner agent is the reviewer of record for that concern: route the review of
a change in that path to them. Where the rule body names an owner, the body is
authoritative; where it does not, the owner below is the designated reviewer.

| Rule file | Path pattern | Owner agent | Enforces |
| ---- | ---- | ---- | ---- |
| `admin-embed-code.md` | `apps/**` | `lead-engineer` | Embedded admin frame, loader/action split (a GET never mutates), session token on mutations, typed server data |
| `auth-code.md` | `apps/**` | `auth-specialist` | Package OAuth (no hand-rolled state/nonce), HMAC + state on callback, encrypted tokens, session-token verification |
| `billing-code.md` | `apps/**` | `billing-specialist` | Plans from config, server-side gating, full subscription lifecycle, idempotent capped usage charges |
| `data-files.md` | `apps/**/*.json` | `app-architect` | JSON parses, one API-version pin per app, scopes/webhooks declared in app config, camelCase keys, zod validation at load |
| `design-docs.md` | `design/**` | `product-director` | ADR per subsystem, `REQ-<AREA>-<NNN>` ids, 8 mandatory sections, formulas with worked examples, named edge cases |
| `functions-code.md` | `apps/**` | `checkout-specialist` | Function only for checkout-time logic, minimal pinned input query, pure logic, structured errors that never block checkout |
| `graphql-code.md` | `apps/**` | `graphql-specialist` | One operation per file, fields you consume only, `extensions.cost` awareness, cursor pagination, `userErrors` handled |
| `network-code.md` | `apps/**` | `lead-engineer` | One typed Admin API client, API version from config, backoff on idempotent calls only, `Retry-After` honoured |
| `prototype-code.md` | `apps/**/prototype/**` | `technical-director` | Throwaway and never imported, README with the question/verdict, dev store only, no secrets or live merchant data |
| `test-standards.md` | `apps/**` | `qa-lead` | Vitest beside source, behaviour-named tests, deterministic fixtures, injected client/repository, no live dependencies |
| `theme-extension-code.md` | `apps/**` | `liquid-specialist` | Extensions registered in app config, app blocks with schema defaults, presentation-only Liquid, no API calls or business math |
| `ui-code.md` | `apps/**` | `polaris-specialist` | Polaris first, tokens over raw hex, App Bridge context, no browser→Shopify calls, loading/empty/error states |
| `webhook-code.md` | `apps/**` | `webhooks-specialist` | HMAC over the raw body before side effects, idempotent handlers, 500 ms ack then queue, one module per topic |

## Adding a rule

One file per concern, frontmatter `paths:` scoped as tightly as the rule
actually needs (`apps/**` is the last resort), an `Owner agent:` line in the
body, then a row here. A rule with no row here, or a row with no file, is drift —
`/consistency-check` reports it.
