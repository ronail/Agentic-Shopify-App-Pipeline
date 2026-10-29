# App Pitch: [App Name]

*Version: [Draft Number]*
*Date: [Date]*
*App directory: `apps/<app>` (created by `/scaffold --app <app>`)*

---

## The Hook

> [One sentence a merchant would repeat to their ops manager. If someone reads
> nothing else, this should make them ask "does it handle my store?"]

---

## What Is It?

[2-3 sentences expanding the hook: the merchant problem, the workflow it
replaces, and the Shopify surface it lives on (embedded admin page, admin
action, checkout extension, POS extension).]

---

## Why Now?

[Why this app at this API version? Shopify platform changes that enable it,
merchant behaviour shifts, gaps left by existing apps, deprecations that open a
window.]

---

## Target Merchant

**Primary**: [Who is the core merchant? Be specific — not "e-commerce stores"
but "Shopify stores doing 200-2,000 orders/month with an in-house 3PL"]

**Secondary**: [Adjacent merchant who would also buy]

**Market Size**: [Number of Shopify stores in the segment; how you estimated it]

---

## Comparable Apps

| App | Similarity | Our Differentiation | Commercial Signal |
| ---- | ---- | ---- | ---- |
| [App 1] | [What's similar] | [What's different/better] | [Pricing, rating, review count] |
| [App 2] | [What's similar] | [What's different/better] | [Signal] |
| [App 3] | [What's similar] | [What's different/better] | [Signal] |

> Evidence for this table comes from `/research`; link the research note.

---

## Core Merchant Experience

### The Promise
[What does the merchant get to BE or DO? The operational outcome and the
emotion attached to it — confidence, not features.]

### Core Loop (30 seconds)
[The primary action: what they click, what Shopify data it touches, what they
see change in the admin.]

### Daily Flow (30 minutes)
[What a typical working session looks like start to finish.]

### Retention Hook
[Why the merchant opens it again tomorrow — a daily number they need, an alert
they can't miss, a report they forward.]

---

## Key Features

1. **[Feature Name]**: [1-2 sentences — what it does and why the merchant cares]
2. **[Feature Name]**: [Description]
3. **[Feature Name]**: [Description]
4. **[Feature Name]**: [Description]
5. **[Feature Name]**: [Description]

---

## Shopify Surface & Integration

| Field | Value |
|-------|-------|
| **App type** | [Embedded admin app / Admin action / Checkout UI extension / POS UI extension / Theme app extension] |
| **Admin API** | [Admin GraphQL API, target version e.g. 2025-10] |
| **Required scopes** | [read_orders, write_products, ...] |
| **Webhooks** | [orders/create, products/update, app/uninstalled, ...] |
| **App Bridge** | [Session tokens, NavMenu, Toast, Modal — versions] |
| **Polaris** | [Polaris version / web components vs React] |
| **Data residency** | [Where merchant data is stored; retention policy] |
| **Protected customer data** | [Yes/No — if yes, which level and why] |

---

## Visual Identity

[Polaris-native by default: the app should feel like part of the admin, not a
microsite. Note any deliberate deviation and why.]

**Design system**: [Polaris components used; custom components to build]

---

## Business Model

| Aspect | Plan |
| ---- | ---- |
| **Model** | [Recurring app subscription / usage-based / free with paid tier] |
| **Plans** | [Free / Growth $X / Pro $Y] |
| **Billing API** | [appSubscriptionCreate, trial days, usage records] |
| **Distribution** | [App Store listing / unlisted / custom app for one merchant] |
| **Monetization ethics** | [What we will and won't do — no dark patterns, no scope overreach] |

---

## Development Plan

| Milestone | Duration | Deliverable |
| ---- | ---- | ---- |
| Concept & Research | [X weeks] | App concept, PRD, competitive research |
| Prototype | [X weeks] | Clickable prototype on a dev store |
| MVP | [X weeks] | Install → OAuth → core loop on a dev store |
| Beta | [X weeks] | Billing, onboarding, support docs |
| App Store submission | [Date] | Listing, review-ready build |

**Team Size**: [X people, roles]
**Stack**: [Remix / Node / Polaris / Prisma — whatever the repo standard is]
**Estimated Budget**: [Range if applicable]

---

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation |
| ---- | ---- | ---- | ---- |
| [App review rejection] | [H/M/L] | [H/M/L] | [Checklist run before submission] |
| [API deprecation] | [H/M/L] | [H/M/L] | [Pin version, watch changelog] |
| [Scope creep] | [H/M/L] | [H/M/L] | [Feature list frozen at gate-3] |

---

## The Ask

[What do you need? Approval to prototype, budget, a dev store, a merchant
interview? Be specific about what you're asking for and what happens next.]
