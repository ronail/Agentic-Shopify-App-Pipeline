# Agent Roster

This is the single source of truth for the agent roster (49 → 31 roles, after
retargeting the framework at Shopify apps). Every agent has a dedicated definition
file in `.claude/agents/`. Delegate to the agent best suited to the task; when a
task spans domains, the coordinating agent (usually `producer` or a domain
lead) delegates to the matching specialist.

When using Hermes as the harness, subagent models come from the `delegation`
section of the active Hermes profile, not from agent frontmatter (the
`model:` frontmatter field is advisory). Run `/start hermes` to configure
per-task routing through a delegation backend plugin.

**Column notes**
- **Owning Rule** — the R3 rule file (`.claude/rules/`) that invokes or owns the
  agent's domain. These rule files are created in R3; this column is a
  forward reference resolved as R3 lands. `check-references.py` validates only
  that agent names resolve to files, not that rule files exist.
- **Owning Skill** — the Hermes skill slug most associated with invoking this
  agent. Many domain specialists (GraphQL, Billing, Webhooks, etc.) are invoked
  by *rules* rather than a skill, marked `-` (no dedicated skill). Skill slugs
  are provisional and finalized in R4.
- **Output paths** — each agent writes only under `apps/<app>/`, `docs/`,
  `production/`, `src/`, `scripts/`. None reference game/engine paths.

## Tier 1 — Leadership Agents (Opus)

| Agent | Domain | Owning Rule | Owning Skill |
|-------|--------|-------------|--------------|
| `product-director` | Product vision; owns the master `request.md` | `design-docs` | `start` |
| `technical-director` | Architecture, tech debt, Shopify API version policy | `design-docs` | `start` |
| `producer` | Pipeline, kanban, milestones, scope gates | `design-docs` | `kanban-status` |
| `lead-engineer` | Implementation lead; owns the code-review gate | `admin-embed-code` | `code-review` |

## Tier 2 — Leads & Specialists (Sonnet)

| Agent | Domain | Owning Rule | Owning Skill |
|-------|--------|-------------|--------------|
| `prototype-builder` | Throwaway merchant-facing prototypes in `apps/<app>/prototype/` | `prototype-code` | `build-prototype` |
| `ux-lead` | Merchant UX in the embedded Polaris admin | `ui-code` | `ux-design` |
| `polaris-specialist` | Polaris components + admin UX implementation | `admin-embed-code` | `ux-design` |
| `qa-lead` | Test strategy + quality gates | `test-standards` | `qa-plan` |
| `release-manager` | App Store submission, versioning, release gates | `design-docs` | `release` |
| `devops-engineer` | Hosting, CI/CD, environments, deploy to dev store | `data-files` | `create-test-store` |
| `research-specialist` | Market, competitor and app-ecosystem research | `design-docs` | `research` |
| `app-architect` | Per-app architecture inside `apps/<app>/` | `admin-embed-code` | `-` |
| `api-lead` | Admin/Storefront API surface, versioning, deprecations | `graphql-code` | `-` |
| `growth-lead` | Install funnel, pricing/packaging, merchant acquisition | `data-files` | `-` |
| `analytics-engineer` | Install funnel, usage events, merchant metrics | `data-files` | `-` |
| `performance-analyst` | Admin load time, API/webhook latency, rate limits | `network-code` | `-` |

## Tier 3 — Specialists (Sonnet)

| Agent | Domain | Owning Rule | Owning Skill |
|-------|--------|-------------|--------------|
| `graphql-specialist` | Admin GraphQL, cost-based throttling, bulk operations | `graphql-code` | `-` |
| `webhooks-specialist` | Subscription lifecycle, HMAC verification, retries/backfill | `webhook-code` | `-` |
| `billing-specialist` | Billing API, subscription/usage charges, plan gating | `billing-code` | `-` |
| `auth-specialist` | OAuth, session tokens, token exchange, embedded-app security | `auth-code` | `-` |
| `app-bridge-specialist` | App Bridge, embedded admin navigation, session/context | `ui-code` | `-` |
| `liquid-specialist` | Liquid templates, theme app extensions, app blocks | `theme-extension-code` | `-` |
| `checkout-specialist` | Checkout UI extensions and checkout-surface constraints | `functions-code` | `-` |
| `security-specialist` | OAuth, session tokens, data handling, audits | `auth-code` | `-` |
| `tools-engineer` | Shopify CLI, scripts, dev-store automation | `data-files` | `-` |
| `localization-lead` | Storefront/extension i18n, market coverage | `theme-extension-code` | `-` |
| `app-store-reviewer` | App Store requirements, listing review, submission blockers | `design-docs` | `app-store-checklist` |
| `test-store-manager` | Dev/test store provisioning, seed data, store lifecycle | `data-files` | `create-test-store` |

## Tier 3 — Execution Agents (Haiku)

| Agent | Domain | Owning Rule | Owning Skill |
|-------|--------|-------------|--------------|
| `qa-tester` | Manual + regression passes on dev stores | `test-standards` | `test-setup` |
| `accessibility-specialist` | Admin UI accessibility, keyboard/screen-reader | `ui-code` | `-` |
| `community-manager` | Merchant support, App Store review responses, changelog comms | `design-docs` | `-` |
