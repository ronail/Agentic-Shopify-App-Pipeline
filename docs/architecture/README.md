# Architecture — Index

Architecture records for the apps in this pipeline. Everything is per app;
nothing here is shared runtime code.

```
docs/architecture/
  README.md                     this index
  ADR-NNNN-*.md                 cross-app decisions (API version policy, tenancy)
  apps/
    <app>/
      requirements.yaml         stable REQ-<AREA>-NNN registry (append-only)
      control-manifest.md       flat Required / Forbidden / Guardrails per layer
      ADR-NNNN-*.md             that app's decisions
```

## Rules

- **ADRs are per app.** An app is read, reviewed and shipped on its own; its ADRs
  live beside its requirements, never in a shared bucket.
- **Root-level ADRs** are only for stances that bind every app (currently the
  pinned Admin API version policy). An app whose design depends on a root ADR
  lists it under `Depends On` in its own ADR.
- **Requirement IDs are append-only.** `REQ-<AREA>-NNN` never renumbers; a
  withdrawn requirement becomes `status: deprecated`.
- **The control manifest is derived, never authored freehand.** Regenerate it
  with `/create-control-manifest <app> update` after any ADR is accepted.

## Where the cross-app view lives

`docs/registry/architecture.yaml` indexes every app's ADR set, requirements,
control-manifest version, surfaces, scopes and webhook topics, plus the stances
and forbidden patterns that all apps must agree on. Skills read it before
authoring a new ADR so they cannot contradict an accepted decision.

## Apps

| App | Purpose | Architecture |
|-----|---------|--------------|
| `discount-bundles` | Create and manage product bundle discounts | [apps/discount-bundles/](apps/discount-bundles/) |
| `order-tags` | Apply and manage tags on orders in bulk | [apps/order-tags/](apps/order-tags/) |

Pinned Admin API version for both apps: **2026-10** —
[ADR-0001-admin-api-version-policy.md](ADR-0001-admin-api-version-policy.md).
