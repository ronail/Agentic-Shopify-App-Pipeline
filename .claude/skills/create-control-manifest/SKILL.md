---
name: create-control-manifest
description: "Use after an app's ADRs are accepted. Produces that app's flat programmer rules sheet — what you must do, must never do, and the guardrail limits, per layer (admin UI, app server, webhooks, extensions, data) — extracted from Accepted ADRs, technical preferences, and the pinned Shopify API snapshot."
argument-hint: "[app] [update]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Create Control Manifest

The control manifest is a flat, actionable rules sheet for programmers. It answers
"what do I do?" and "what must I never do?" for one app, organized by layer,
extracted from that app's Accepted ADRs, the project's technical preferences, and
the pinned Shopify API snapshot. ADRs explain *why*; the manifest states *what*.

**Output:** `docs/architecture/apps/<app>/control-manifest.md`

**When to run:** after `/architecture-review <app>` passes and ADRs are `Accepted`.
Re-run with `update` whenever an ADR is accepted or revised, an access scope or API
version changes, or a file in `.claude/rules/` changes.

---

## 1. Load Inputs

**App** — resolve the slug from the argument, else `docs/registry/apps.json`.

### ADRs

- Glob `docs/architecture/apps/<app>/adr-*.md` and read every file
- Keep only `Status: Accepted` — skip `Proposed`, `Superseded`, `Deprecated`
- Record the ADR number and title behind every rule

### Project standards

- `.claude/docs/technical-preferences.md` — naming, performance budgets, approved
  libraries, forbidden patterns
- `.claude/rules/` — one file per layer; these are already-extracted rules and take
  precedence when an ADR is silent:
  `admin-embed-code.md`, `graphql-code.md`, `webhook-code.md`, `billing-code.md`,
  `auth-code.md`, `network-code.md`, `ui-code.md`, `theme-extension-code.md`,
  `functions-code.md`, `data-files.md`, `test-standards.md`

### Pinned API reference

- Read `apps/<app>/shopify.app.toml` for the pinned `api_version` and `access_scopes`
- Read `docs/shopify-api-reference/<version>/` — deprecated and removed fields become
  Forbidden entries; per-surface notes become Required or Guardrail entries

Report: `Loaded [N] Accepted ADRs, app: [app], API version: [version].`

---

## 2. Extract Rules from Each ADR

For each Accepted ADR, pull rules from its sections:

### Required patterns (Decision, Implementation Notes)

- Every "must", "always", "required to" statement
- Every mandated approach: session-token auth on every admin request, server-side
  Admin GraphQL calls, shop-scoped queries, idempotent webhook handlers

### Forbidden approaches (Alternatives Considered, Consequences)

- Every rejected alternative — the reason it was rejected is the rule
  ("never X because Y")
- Every anti-pattern the ADR calls out

### Guardrails (Performance, Limits)

- Cost, latency, and size limits: admin route `p75 < 1.5 s`, webhook `p95 < 500 ms`,
  GraphQL requested cost ≤ 500 without a bulk operation, bundle < 250 KB gzipped
- Data limits: rows per shop, retention windows, pagination page size

### API constraints (Shopify API Surface)

- Deprecated or removed fields the app must not use
- Fields, arguments, or extension targets that exist only in the pinned version and
  must never be assumed from memory
- Scopes the decision depends on, and scopes it explicitly must not request

### Layer classification

Classify each rule by the layer it governs. Duplicate a rule into every layer it
binds.

| Layer | What it governs | Paths | Owner agent |
|-------|-----------------|-------|-------------|
| **Admin UI** | embedded routes, Polaris components, App Bridge navigation | `apps/<app>/app/routes/**`, components | `polaris-specialist` |
| **App server** | loaders/actions, Admin GraphQL client, auth, billing, jobs | `apps/<app>/app/**`, `apps/<app>/src/**` | `lead-engineer` |
| **Webhooks** | subscription config, verification, idempotency | `apps/<app>/app/routes/webhooks.*`, `shopify.app.toml` | `webhooks-specialist` |
| **Theme app extensions** | app blocks, Liquid output, merchant settings | `apps/<app>/extensions/<ext>/blocks/**` | `liquid-specialist` |
| **Checkout extensions** | extension targets, UI extensions, limits | `apps/<app>/extensions/<ext>/src/**` | `checkout-specialist` |
| **Data** | schema, migrations, sessions, merchant settings, job queue | `apps/<app>/db/**` | `devops-engineer` |

---

## 3. Add Global Rules

Rules that bind every layer, assembled from the sources above:

- **Naming** — types `PascalCase`, functions `camelCase`, files `kebab-case`,
  GraphQL operations one per file, webhook handlers named for the topic
  (`orders-create.ts`), requirement IDs `REQ-<AREA>-<NNN>`
- **API version** — declared once in `shopify.app.toml` and read from config; never a
  second hardcoded string
- **Approved libraries** — the list in `technical-preferences.md`; anything else needs
  `technical-director` review
- **Forbidden APIs** — deprecated or removed fields from the pinned snapshot
- **Cross-cutting constraints** — server-only Admin API access, shop-scoped queries,
  secrets never in logs, no merchant data write in a GET side effect

---

## 4. Present the Rule Summary Before Writing

```
## Control Manifest Preview — [app]
API version: [version]
ADRs covered: [ADR-NNNN, ...]
Rules extracted:
  Admin UI:            [N] required, [M] forbidden, [P] guardrails
  App server:          [N] required, [M] forbidden, [P] guardrails
  Webhooks:            [N] required, [M] forbidden, [P] guardrails
  Theme extensions:    [N] required, [M] forbidden, [P] guardrails
  Checkout extensions: [N] required, [M] forbidden, [P] guardrails
  Data:                [N] required, [M] forbidden, [P] guardrails
  Global:              [N] naming, [M] forbidden APIs, [P] approved libraries
```

Use `AskUserQuestion`, `request_user_input` or `clarify`:

- `[A]` yes — run the director review and write
- `[B]` add rules — I have more to include
- `[C]` remove rules — some extracted rules should be dropped
- `[D]` stop — I need to review the ADRs first

---

## 4b. Director Gate

Resolve review mode first (`.claude/docs/director-gates.md`; `--review [full|lean|solo]`
overrides, else `production/review-mode.txt`, else `lean`):

- `solo` → skip: `TD-ARCHITECTURE skipped — Solo mode.`
- `lean` → skip: `TD-ARCHITECTURE skipped — Lean mode.`
- `full` → spawn `technical-director` via Task using gate **TD-ARCHITECTURE**

Pass the preview, the ADR list, the pinned API version, and every rule sourced from
`.claude/rules/` or `technical-preferences.md`.

The director checks that:

- mandatory ADR patterns are captured and accurately worded
- forbidden approaches are complete and correctly attributed
- no rule lacks a source ADR, rules file, or preference entry
- guardrails match the ADR limits and the app's actual scope list

Verdict handling:

- **APPROVE** → Phase 5
- **CONCERNS** → surface via `AskUserQuestion`, `request_user_input` or `clarify`:
  revise flagged rules · accept and proceed · discuss further
- **REJECT** → do not write; fix the flagged rules and re-present the summary

---

## 5. Write the Manifest

Ask: `[A]` write to `docs/architecture/apps/<app>/control-manifest.md` ·
`[B]` show the full draft first · `[C]` not yet

Format:

```markdown
# Control Manifest — [app]

> **API Version**: [version]
> **Manifest Version**: [YYYY-MM-DD]
> **Last Updated**: [YYYY-MM-DD]
> **ADRs Covered**: [ADR-NNNN, ...]
> **Access Scopes**: [from shopify.app.toml]
> **Status**: Active — regenerate with `/create-control-manifest [app] update`

`Manifest Version` is the date this manifest was generated; it always matches
`Last Updated` and serves a different consumer. Story files embed this value in
their Context block when created. `/story-readiness` refuses a story whose embedded
version is older than this one, and `/story-done` re-checks it at close — a stale
embed means the story was written against rules that have since changed.

This manifest is the quick reference for every programmer on this app, extracted
from Accepted ADRs, `.claude/rules/`, technical preferences, and the pinned API
snapshot. For the reasoning behind a rule, read the cited ADR.

---

## Admin UI

*Applies to: embedded admin routes, Polaris components, App Bridge navigation*

### Required Patterns
- [rule] — source: [ADR-NNNN | rule file]

### Forbidden Approaches
- Never [anti-pattern] — [reason] — source: [ADR-NNNN]

### Guardrails
- Route load: p75 < 1.5 s; bundle < 250 KB gzipped — source: technical-preferences

---

## App Server

*Applies to: loaders and actions, Admin GraphQL client, auth, billing, jobs*

### Required Patterns
### Forbidden Approaches
### Guardrails

---

## Webhooks

*Applies to: subscription config, HMAC verification, idempotent handlers, retries*

### Required Patterns
### Forbidden Approaches
### Guardrails

---

## Theme App Extensions

*Applies to: app blocks, Liquid output, merchant-facing settings*

### Required Patterns
### Forbidden Approaches
### Guardrails

---

## Checkout Extensions

*Applies to: extension targets, UI extension components, checkout limits*

### Required Patterns
### Forbidden Approaches
### Guardrails

---

## Data

*Applies to: schema, migrations, session storage, merchant settings, job queue*

### Required Patterns
### Forbidden Approaches
### Guardrails

---

## Global Rules (All Layers)

### Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Types / components | PascalCase | DiscountRuleCard |
| Files | kebab-case | discount-rule-card.tsx |
| GraphQL operations | PascalCase, one per file | DiscountCreate.graphql |
| Webhook handlers | topic in kebab-case | orders-create.ts |
| Requirement IDs | REQ-<AREA>-<NNN> | REQ-BILL-001 |

### Approved Libraries
- [library] — approved for [purpose]

### Forbidden APIs ([version])
- `[field or mutation]` — deprecated/removed in [version] — use [replacement]
- Source: `docs/shopify-api-reference/[version]/`

### Cross-Cutting Constraints
- [constraint that binds every layer]
```

---

## 6. Next Steps

- No epics yet: "Run `/create-epics` then `/create-stories` — stories embed this
  manifest version and cite the rule they implement."
- Regeneration: "Updated. Announce the changed rules — new Forbidden entries matter
  most, because they invalidate code already written."

---

## Collaborative Protocol

1. **Load silently** — read every input before presenting anything.
2. **Show the summary first** — counts per layer before writing.
3. **Ask before writing** — confirm before creating or overwriting. On write:
   Verdict **COMPLETE**. On decline: Verdict **BLOCKED** — user declined write.
4. **Source every rule** — a rule with no ADR, rule file, or preference behind it does
   not go in.
5. **No interpretation** — extract rules as written; do not paraphrase in a way that
   changes meaning.
