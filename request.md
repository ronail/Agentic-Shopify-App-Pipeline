# Master Request — Agentic Shopify App Pipeline

Version: v1
Status: active
Owner: product-director
Last updated: 2026-10-29

## Goal

Ship a repeatable pipeline for building, reviewing, releasing, and maintaining
Shopify apps. Each app moves through five approval gates and is produced from a
real store-facing prototype, not a mockup.

## Success criteria

- Every app lives in its own directory (`apps/<app>/`) with isolated config,
  credentials, and request history.
- Every app records approvals for the five gates:
  `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`,
  `gate-5-update`.
- Build and pipeline artefacts live under `production/apps/<app>/`, never mixed
  with source.
- `docs/registry/apps.json` is the single shared mutable registry and lists every
  app directory.
- Changes to this document are mirrored in `request-history.md`.

## Non-goals

- Building a shared runtime framework across apps.
- Multi-tenant hosting infrastructure.
- Marketing site or brand work.

## Apps in scope

| Slug | Purpose | Stage |
|------|---------|-------|
| `discount-bundles` | Create and manage product bundle discounts. | research |
| `order-tags` | Apply and manage tags on orders in bulk. | research |

## Gates

1. `gate-1-research` — research and MMMVP selection approved.
2. `gate-2-prototype` — prototype reviewed and approved.
3. `gate-3-scope` — production scope (epics and stories) approved.
4. `gate-4-release` — release approved.
5. `gate-5-update` — ongoing update / apply-updates approved.

## Change protocol

Any edit to this file must be accompanied by a new entry in
`request-history.md` in the same working tree. The hook
`.claude/hooks/track-request-changes.sh` enforces this.
