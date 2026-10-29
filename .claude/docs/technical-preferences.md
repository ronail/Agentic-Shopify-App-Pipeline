# Technical Preferences

<!-- Written by /start during onboarding. Updated as the user makes decisions. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Stack & Language

- **Language**: TypeScript (strict mode; no `any` in exported signatures)
- **Framework**: Remix route modules (`loader` for reads, `action` for writes)
- **UI**: React with Polaris components (function components and hooks only)
- **Embedding**: App Bridge (embedded admin, session tokens, navigation)
- **Shopify API**: GraphQL Admin API, pinned to **2026-10** per app
- **Runtime**: Node LTS (ES modules)
- **Local Dev**: Shopify CLI — `shopify app dev` (tunnel + install) and
  `shopify app deploy` (config, scopes, extensions)
- **Package Manager**: npm
- **Test Runner**: Vitest

## Hosting & Data

<!-- Read by /scaffold, /devops-engineer work, and /release-checklist -->

- **Hosting**: Node service on Fly.io (default). Alternatives on the same
  contract: Render or Vercel. Requirement is a long-lived Node process with
  HTTP access, because webhook delivery and OAuth callbacks need it.
- **Environments**: local (Shopify CLI tunnel) → dev store → production
- **Database**: Postgres 16 (managed by the host). Sessions, install records,
  merchant settings, and job state.
- **Data Access**: SQL migrations checked into `apps/<app>/db/migrations/`;
  query layer behind a repository module, never inline in route handlers
- **Background Jobs**: queue table in Postgres, drained by a worker process
- **File/Object Storage**: host object storage for exports; never the app
  filesystem

## Merchant & Store Targeting

<!-- Read by /research, /ux-design, /ux-review, /qa-plan, and /localize -->

- **Primary Market**: [TO BE CONFIGURED — e.g., US/CA, EU, APAC]
- **Store Sizes Served**: [TO BE CONFIGURED — e.g., solo merchant, SMB, Plus]
- **Admin Surfaces**: embedded admin page, theme app extension, checkout
  extension (only if the app genuinely needs checkout)
- **Supported Languages**: English first; add locales only with a translation
  path (see `localization-lead`)
- **Accessibility Target**: WCAG 2.1 AA on every admin surface

## Naming Conventions

- **Types/Components**: `PascalCase` (`DiscountRuleCard`)
- **Functions/Variables**: `camelCase`
- **Files**: `kebab-case.ts` / `kebab-case.tsx` (`discount-rule-card.tsx`)
- **Hooks**: `use` prefix, file matches hook name (`use-shop-context.ts`)
- **Constants**: `SCREAMING_SNAKE_CASE`
- **GraphQL Operations**: `PascalCase` operation names, one operation per file,
  file named after the operation (`DiscountCreate.graphql`)
- **Webhook Handlers**: topic in kebab-case (`orders-create.ts`)
- **Requirement IDs**: `REQ-<AREA>-<NNN>` (`REQ-BILL-001`)

## Performance Budgets

- **Admin Route Load (p75)**: under 1.5 s on a warm session
- **GraphQL Cost**: stay under 50% of the leaky-bucket capacity per request
  burst; no query above 500 requested cost without a bulk operation
- **Webhook Handler p95**: under 500 ms, acknowledged before slow work is queued
- **Bundle**: initial admin route under 250 KB gzipped
- **Install Flow**: OAuth round trip completes in under 5 s on a dev store

## Testing

- **Framework**: Vitest (unit + integration), Testing Library for components
- **Location**: tests beside the source they cover, inside `apps/<app>/`
  (`discount.ts` and `discount.test.ts` in the same folder)
- **Minimum Coverage**: 80% lines on shared modules; 100% on billing and
  webhook signature verification
- **Required Tests**: discount/price calculations, GraphQL variable shaping,
  webhook HMAC verification, billing plan gating, OAuth callback handling
- **Not Automated**: Polaris visual fidelity, App Store listing copy, real
  merchant install flows (covered by dev-store walkthroughs)

## Forbidden Patterns

<!-- Patterns that must never appear in this project's codebase -->
- Calling the Admin API from the browser — every call goes through the app
  server with a session token check
- Storing access tokens in plaintext columns or logs
- Hardcoding an API version string in more than one place per app; it lives in
  `shopify.app.toml` and the ADR, and is read from config
- Unverified webhook payloads — HMAC check before any parsing side effect
- `any` in exported TypeScript signatures
- Mutating a merchant's data inside a GET route

## Allowed Libraries / Addons

<!-- Approved third-party dependencies -->
- `@shopify/shopify-app-remix` — auth, session storage, webhook registration
- `@shopify/polaris` — admin UI components
- `@shopify/app-bridge-react` — embedded navigation and context
- `zod` — runtime validation at API and webhook boundaries
- `vitest` + `@testing-library/react` — tests
- [Add further dependencies only after `technical-director` review]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/apps/<app>/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Shopify Specialists

<!-- Read by /code-review, /architecture-decision, /architecture-review -->
<!-- to know which specialist to spawn for domain-specific validation. -->

- **Primary / Review Gate**: `lead-engineer`
- **Architecture**: `app-architect`
- **API Surface & Versioning**: `api-lead`
- **Admin UI**: `polaris-specialist`
- **GraphQL Operations**: `graphql-specialist`
- **Webhooks**: `webhooks-specialist`
- **Billing**: `billing-specialist`
- **Auth / Sessions**: `auth-specialist`
- **Embedded Context**: `app-bridge-specialist`
- **Liquid / Theme Extensions**: `liquid-specialist`
- **Checkout Extensions**: `checkout-specialist`
- **Security Audit**: `security-specialist`

### File Type Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row is blank, fall back to `lead-engineer` for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `*.ts`, `*.tsx` (app logic) | `lead-engineer` |
| `*.tsx` (Polaris components, routes) | `polaris-specialist` |
| `*.graphql`, query/mutation modules | `graphql-specialist` |
| Webhook route handlers | `webhooks-specialist` |
| Billing / plan gating modules | `billing-specialist` |
| OAuth, session, token modules | `auth-specialist` |
| `shopify.app.toml`, App Bridge setup | `app-bridge-specialist` |
| `*.liquid`, theme app extension blocks | `liquid-specialist` |
| Checkout extension files | `checkout-specialist` |
| Migrations, schema, infra config | `devops-engineer` |
| General architecture review | `app-architect` |
