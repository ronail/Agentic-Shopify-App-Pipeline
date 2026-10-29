# Docs Directory

When authoring or editing files in this directory, follow these standards.

## Architecture Decision Records (`docs/architecture/apps/<app>/`)

ADRs are **per app**. Each app keeps its own ADR set beside its requirements
registry so an app can be read, reviewed and shipped on its own.

Use the ADR template: `.claude/docs/templates/architecture-decision-record.md`

**Required sections:** Title, Status, Context, Decision, Consequences,
ADR Dependencies, Shopify API Surface, App Requirements Addressed

- **Shopify API Surface** records the pinned Admin API version, the access
  scopes the decision depends on, and the webhook topics it consumes.
- **App Requirements Addressed** lists requirement IDs from that app's registry
  (see below). An ADR that addresses no requirement needs a justification line
  saying why the work exists.

**Status lifecycle:** `Proposed` → `Accepted` → `Superseded`
- Never skip `Accepted` — stories referencing a `Proposed` ADR are auto-blocked
- Use `/architecture-decision` to create ADRs through the guided flow

**Per-app requirements registry:** `docs/architecture/apps/<app>/requirements.yaml`
- Stable requirement IDs (e.g. `REQ-BILL-001`) that link app requirements to stories
- Never renumber existing IDs — only append new ones
- Updated by `/architecture-review` Phase 8

**Per-app control manifest:** `docs/architecture/apps/<app>/control-manifest.md`
- Flat programmer rules sheet: Required / Forbidden / Guardrails per layer
  (admin UI, app server, webhooks, theme app extensions, checkout extensions, data)
- Date-stamped `Manifest Version:` in header
- Stories embed this version; `/story-done` checks for staleness

**Validation:** Run `/architecture-review` after completing a set of ADRs.

## Shopify API Reference (`docs/shopify-api-reference/`)

Version-pinned Shopify API snapshots: the Admin GraphQL schema, changelog notes
for the pinned version, deprecated-field lists, and per-surface notes (webhooks,
billing, checkout extensions).

**Always check here before using any Shopify API** — the LLM's training data
predates the pinned API version, and Shopify deprecates on a quarterly cadence.

- Snapshots are stored per API version: `docs/shopify-api-reference/<version>/`
- Each app pins its version in `apps/<app>/shopify.app.toml`; the ADR
  **Shopify API Surface** section repeats it
- Do not rely on memory for field names, mutation arguments, or webhook payload
  shapes — read the pinned snapshot first
- Adding a new API version means adding a new snapshot directory; never edit an
  older snapshot in place
