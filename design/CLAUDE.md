# Design Directory

`design/` holds **shared design assets only** — material more than one app
depends on. Anything that belongs to a single app lives under
`apps/<app>/design/`, per `.claude/docs/directory-structure.md`.

## UX specs — per app

| Document | Path | Authored by |
|---|---|---|
| Screen spec | `apps/<app>/design/ux/<screen-slug>.md` | `/ux-design` |
| Flows and navigation | `apps/<app>/design/ux/flows.md` | `/ux-design flows` |
| Interaction patterns | `apps/<app>/design/ux/interaction-patterns.md` | `/ux-design patterns` |
| Accessibility commitment | `apps/<app>/design/ux/accessibility.md` | `/ux-design accessibility` |

Every screen spec names the Polaris components it uses, the App Bridge context
it runs in, all states (loading, empty, error, partial, success), the merchant
copy, and its WCAG 2.1 AA obligations. A spec without states is not reviewable.

**Validation:** run `/ux-review <path>` before the screen enters a story. A spec
that fails review blocks implementation — it is not a style suggestion.

## Quick specs — per app

`apps/<app>/design/quick-specs/<slug>.md` — short, focused specs for a copy
change, a tuning value, or a bounded behaviour tweak that does not warrant a full
screen spec. Author with `/quick-design`; reference the affected screen spec so
the two do not drift.

## Shared design assets

| Path | Holds |
|---|---|
| `design/registry/entities.yaml` | Cross-doc facts: domain objects, API surfaces, formulas and limits that more than one document states |
| other `design/*` files | Assets genuinely shared by multiple apps; each file states which apps read it |

Register a fact in `design/registry/entities.yaml` when a second document has to
agree with it — a metafield namespace, a webhook topic set, a pricing formula, a
platform limit. Never duplicate a fact into two app specs; register it once and
reference it.

## Rules

- **One app, one owner.** An app's UX specs are written and edited by that app's
  own agents. Cross-app design edits require an explicit request change.
- **No app-specific content here.** If only one app reads it, it belongs in
  `apps/<app>/design/`.
- **API facts come from the pinned snapshot.** Any Shopify field, scope, mutation
  or webhook topic named in a design doc must exist in
  `docs/shopify-api-reference/<version>/` for the version the app pins in
  `apps/<app>/shopify.app.toml`.
- **Validation is a gate, not advice.** `/ux-review` for screens,
  `/consistency-check` when a shared fact changes.
