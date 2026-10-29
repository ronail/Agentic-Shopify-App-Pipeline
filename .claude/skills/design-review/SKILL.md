---
name: design-review
description: "Reviews a Shopify app spec — requirements, feature spec, UX spec, or architecture doc — for completeness, internal consistency, implementability, Polaris and accessibility compliance. Run before handing specs to implementation."
argument-hint: "[path to spec | app slug] [--depth full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Design Review

The quality gate between specification and implementation. It reads one spec in
the context of the app it belongs to, then returns a verdict plus a fix list.
It does not rewrite the spec unless the user asks.

## Phase 0 — Parse arguments

- **Target**: a file path, an app slug, or nothing.
  - Path → review that file.
  - Slug → review the app's spec set: `requirements.yaml`,
    `control-manifest.md`, `architecture.md`, ADRs, and every file under
    `apps/<app>/design/ux/`.
  - Nothing → ask which, offering the apps in `docs/registry/apps.json`.
- **`--depth full|lean|solo`** — how many specialist agents this run spawns.
  Default `full`. This is independent of `production/review-mode.txt`, which
  governs director gates elsewhere. State both when reporting.

Confirm the resolved target in one line before reading.

## Phase 1 — Build the context set

Never review a spec in isolation. Read:

| File | Why |
|------|-----|
| `docs/architecture/apps/<app>/requirements.yaml` | Requirement IDs and their 8 sections |
| `docs/architecture/apps/<app>/control-manifest.md` | Conventions the implementation must follow |
| `docs/architecture/apps/<app>/architecture.md` | Stack, API surface, data model |
| `docs/architecture/apps/<app>/ADR-*.md` | Decisions the spec must not contradict |
| `apps/<app>/design/concept.md` | Merchant job and MVP scope |
| `apps/<app>/design/ux/*.md` | Screens, states, copy |
| `docs/shopify-api-reference/<version>/` | Whether the API calls in the spec exist |
| `apps/<app>/status.md` | Stage and approved gate — a spec reviewed too early wastes a pass |

If the target spec cites a requirement ID that does not exist, that is finding
number one; stop and report rather than guess the intent.

## Phase 2 — Structural completeness

Check the document type against its required shape.

### Requirements (`requirements.yaml`)

Every requirement carries all 8 sections, in order:

1. Overview
2. Merchant Job
3. Detailed Rules
4. Calculations
5. Edge Cases
6. Dependencies
7. Configuration
8. Acceptance Criteria

Per `.claude/rules/design-docs.md`, also verify:

- IDs follow `REQ-<AREA>-<NNN>` and are unique.
- Calculations are formulas with variable definitions and at least one worked
  example (bundle discount stacking, prorated usage, currency rounding).
- Edge cases cover empty stores, huge catalogs, multi-currency, and partial
  failures.
- Every value with a default states its rationale or its source.

### UX spec

Required sections: screen purpose and entry point, merchant job, layout with
named Polaris components, data and Admin API calls, every state, interactions,
copy, accessibility, responsive behaviour, analytics, acceptance criteria.

### Architecture doc

Required sections: boundaries, stack and runtime, Shopify API surface matrix,
auth and session model, data model and retention, request and data flow, billing
and plan gating, webhook processing and idempotency, performance budgets,
security and compliance, observability, testing strategy, ADR index, open
questions.

### Quick spec

Required: change, merchant job, rules, API surface delta, UI delta, edge cases,
acceptance criteria, rollback. A quick spec that needs a migration or a new
scope belongs in the full path — flag it.

Any missing section is a **BLOCKER**, not a suggestion.

## Phase 3 — Internal consistency

Cross-check, not just read:

1. Every `REQ-<AREA>-<NNN>` in the spec appears in `requirements.yaml` and is
   referenced by at least one acceptance criterion.
2. Every screen named in a requirement exists as a UX spec, and every UX spec
   maps back to a requirement. Orphans in either direction are **MAJOR**.
3. Numbers agree across documents: batch sizes, limits, currency handling,
   retention windows, plan gates. Two different values for one limit is a
   **BLOCKER**.
4. The API surface in the spec matches the architecture matrix; a new scope,
   mutation, or webhook topic that the architecture does not list is **MAJOR**.
5. ADRs win over prose. If the spec contradicts an Accepted ADR, the spec is
   wrong unless a superseding ADR exists.
6. Merchant-facing copy matches the monetisation section — a feature described
   as included but gated behind a paid plan is a **BLOCKER**.

## Phase 4 — Implementability

A spec a programmer cannot implement without asking questions is not done.

- **API version** — pinned and stated (`docs/shopify-api-reference/<version>/`).
  Unpinned is **MAJOR**.
- **Scopes** — every access scope listed, with a reason. A write the spec needs
  but does not scope is **BLOCKER**.
- **Queries and mutations** — named, with the fields and arguments they use.
  "Fetch the order" is not implementable.
- **Webhooks** — topic list, verification method, idempotency key, retry and
  failure behaviour. Missing idempotency is **MAJOR** (duplicate order handling
  is a real merchant-visible bug).
- **Data model** — shop-scoped keys, migrations, retention, and the GDPR
  webhook obligations for the data held.
- **Billing** — charge type, plan gates, what happens on downgrade or uninstall.
- **Errors** — one error shape, user-visible messages, and what the merchant can
  do next.
- **Rate limits** — how the spec behaves near the Admin API cost budget, and
  whether work is queued.
- **Every state** — loading, empty, error, partial, permission-denied,
  plan-gated. A data surface without all six is **MAJOR**.

## Phase 5 — Polaris and accessibility

- **Polaris**: every component named exists in Polaris (no invented primitives).
  Custom markup needs a stated reason and design tokens, never raw hex.
- **App Bridge**: shop, host, and locale come from the App Bridge context, never
  from parsing the query string. Navigation uses the App Bridge nav menu; toasts
  and modals use App Bridge, not browser dialogs.
- **WCAG 2.1 AA**, checked item by item:
  - text contrast 4.5:1, large text and UI boundaries 3:1
  - visible focus, logical focus order, no keyboard traps
  - every control has an accessible name; icon-only buttons have labels
  - errors are identified in text and tied to the field
  - state is never conveyed by colour alone
  - tables and index views expose headers to assistive tech
  - motion respects reduced-motion preference
  - interactive targets are large enough for touch and pointer
- **Embedded constraints**: no top-level browser navigation inside the iframe,
  no reliance on `window.top`, session tokens for every Admin API call, and a
  re-auth path when the session expires.

## Phase 6 — Specialist panel

Spawn with `Task`, passing the target path and the relevant context files.
Honour `--depth`:

| `--depth` | Who runs |
|-----------|----------|
| `full` | Every specialist the doc type needs, plus `qa-lead` for testability |
| `lean` | Two: the primary owner of the doc type plus `accessibility-specialist` |
| `solo` | No agents; this skill's own checklist is the review |

Pick specialists by document content:

| Spec touches | Specialist |
|--------------|-----------|
| Layout, components, copy | `polaris-specialist` |
| Contrast, keyboard, screen readers | `accessibility-specialist` |
| Queries, mutations, pagination, cost | `graphql-specialist`, `api-lead` |
| Auth, scopes, session tokens | `auth-specialist` |
| Charges, plan gates, trials | `billing-specialist` |
| Webhooks, idempotency, retries | `webhooks-specialist` |
| Extensions, theme blocks, checkout | `app-bridge-specialist`, `checkout-specialist`, `liquid-specialist` |
| Customer data, secrets, HMAC | `security-specialist` |
| Load budgets, bundle size | `performance-analyst` |
| Testability and acceptance criteria | `qa-lead` |
| Overall shape and boundaries | `app-architect`, `technical-director` |

Collect their findings; do not let one specialist's opinion override a
contradiction found in Phase 3.

## Phase 7 — Report the verdict

Output in this order, nothing else:

```text
DESIGN REVIEW — <path> (<app>, <doc type>)
Depth: <full|lean|solo> | Review mode: <full|lean|solo>

VERDICT: APPROVED | NEEDS REVISION | MAJOR REVISION NEEDED

BLOCKERS (n)
1. <finding> — <file>:<line> — <what to change>

MAJOR (n)
MINOR (n)

COVERAGE
- Requirements found: n | with all 8 sections: n
- Screens in requirements: n | with UX specs: n
- API operations cited: n | present in pinned reference: n
- Accessibility checks passed: n/9
```

Verdict rules:

- **APPROVED** — no blockers, no majors, and every cited API operation exists in
  the pinned reference.
- **NEEDS REVISION** — blockers or majors with local fixes only; the spec's
  intent stands.
- **MAJOR REVISION NEEDED** — the spec contradicts an Accepted ADR, misses a
  whole requirement area, or its merchant job does not match the concept.

Then offer exactly one next action: fix the listed items and re-run
`/design-review`, or escalate with `/architecture-decision` when the finding is
really an unmade decision.

## Editing rules

- Default is report-only.
- With explicit permission: fix typos, broken links, and missing IDs. Do not
  rewrite behaviour, numbers, or scope — those go back to the author.
- Never edit `requirements.yaml` in a review pass; a requirement change needs an
  owning story or a proposal.

## Hand off

- Spec passes and is a UX doc → `/ux-review <path>` for the Polaris and
  accessibility deep pass.
- Spec passes and is architecture → `/architecture-review <app>`.
- Spec passes and is requirements → `/create-stories <app>`.
- Verdict is MAJOR → back to `/brainstorm` or the requirements author with the
  quoted objection.
