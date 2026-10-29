# ADR-0001: Cross-App Admin API Version Pinning and Upgrade Policy

## Status

Accepted

## Date

2026-10-29

## Last Verified

2026-10-29

## Decision Makers

`technical-director` (owner), `api-lead`, `producer`

## Summary

Every app in this pipeline builds against one pinned Admin API version declared
per app in `apps/<app>/shopify.app.toml` and mirrored in a version-pinned
snapshot under `docs/shopify-api-reference/<version>/`. Upgrades happen on a
scheduled quarterly review, never opportunistically mid-story, so an app cannot
half-migrate a surface.

## Shopify API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | `2026-10` |
| **Surface** | Admin GraphQL, Webhooks, App Bridge, Polaris, theme app extensions, checkout extensions |
| **Knowledge risk** | MEDIUM — the pin is newer than model training data; field names and mutation arguments must be read from the snapshot, not recalled |
| **References consulted** | `docs/shopify-api-reference/2026-10/`, `docs/shopify-api-reference/VERSION.md`, `shopify.dev/docs/api/admin-graphql` release notes |
| **Recently introduced APIs used** | Fields and mutations used by the apps in this repo must resolve in `docs/shopify-api-reference/2026-10/` before use |
| **Verification required** | After each version bump: app installs on a dev store, every registered webhook receives one real delivery, and the cart transform runs on a test cart |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Every per-app ADR — each one cites the version this decision pins |
| **Blocks** | `/architecture-decision` authoring for any app whose `shopify.app.toml` has no pinned version |
| **Ordering note** | Must be Accepted before any app ADR claims a surface behaviour |

## Context

### Problem Statement

Shopify retires Admin API versions on a quarterly cadence. An app that reads
field names from model memory drifts silently: the code compiles, the test suite
passes against a mock, and the first real store call returns `Field doesn't
exist`. The decision is *how* a version is pinned and *when* it moves, before any
app commits to a surface.

### Current State

Both apps are at the research stage. No `shopify.app.toml` exists yet; the
scaffold step creates it. `docs/shopify-api-reference/2026-10/` already holds the
snapshot the apps must build against.

### Constraints

- One version per app, declared once. A second hardcoded version string is a bug.
- Extensions (theme app extension, checkout UI extension, functions) carry their
  own API version field; it must match the app's pin.
- Webhook payload shapes are versioned with the API; a subscription registered
  under one version does not silently adopt the next.
- Apps install on merchant stores that cannot be migrated in a coordinated
  window — a bump has to be backward compatible for at least one release.

### Requirements

- No app may ship a hardcoded API version string outside `shopify.app.toml`.
- A version bump is a single reviewed change with its own branch and story.
- The snapshot for the pinned version must exist before architecture is written.

## Decision

1. The pin lives in `apps/<app>/shopify.app.toml` as
   `[access_scopes]`-adjacent config: `api_version = "2026-10"`.
2. Code reads the version from config only. No literal appears in `app/**` or
   `extensions/**`.
3. `docs/shopify-api-reference/<version>/` is an immutable snapshot. A bump adds
   a new directory; it never edits the old one.
4. The review trigger is the quarterly Shopify release note. `api-lead` opens a
   `chore: bump admin api to <version>` story, runs `/architecture-review api`
   for each app, and only then updates the pin.
5. Deprecated fields found in the new snapshot become Forbidden entries in each
   app's control manifest at the same time as the bump — the manifest and the
   pin move together.

### Architecture

```
apps/<app>/shopify.app.toml        api_version = "2026-10"   (single source)
        │
        ├── app/**            reads version from config / platform context
        ├── extensions/**     api_version repeated, must equal the pin
        └── webhook subs      registered under the pinned version

docs/shopify-api-reference/
  2026-10/    immutable snapshot: admin-graphql, webhooks, billing,
              checkout-extensions, storefront
  VERSION.md  the repo-wide current pin
```

### Key Interfaces

```
// the version is generated from shopify.app.toml at build time — no literal
import { apiVersion } from "../shopify.server";

// a GraphQL call always goes through the app's authenticated admin client,
// which carries the session shop + pinned version
const client = await adminClient(shop);
await client.request(GetBundleQuery);
```

### Implementation Guidelines

- Assert at boot that the extension manifests' `api_version` equals the app pin;
  fail fast rather than degrade.
- `SHOPIFY_API_VERSION` exists so a canary deploy can be tested against the next
  version without a code change. It is never set differently in production.
- Record the version in every ADR's **Shopify API Surface** table, so a stale ADR
  is visible at review time.

## Alternatives Considered

### Alternative 1: Always track the latest version

- **Description**: Pin to `unstable`/latest and upgrade continuously.
- **Pros**: Never carries deprecation debt.
- **Cons**: Behaviour changes land without review; extension schemas shift under
  a live merchant mid-week.
- **Estimated Effort**: Lower day one, higher forever.
- **Rejection Reason**: No controlled window to verify a surface change on a real
  store before merchants see it.

### Alternative 2: Per-surface version pins

- **Description**: Admin GraphQL on one version, webhooks on another.
- **Pros**: Allows partial migration.
- **Cons**: Payload shapes diverge from what the client expects; debugging
  requires tracking two pins per app.
- **Estimated Effort**: Same.
- **Rejection Reason**: Cross-surface consistency is worth more than migration
  granularity for apps of this size.

## Consequences

### Positive

- A stale field is caught by a review step, not by a merchant's 500.
- Every ADR states the version it was verified against.
- Bumping is a scheduled, reversible story instead of an emergency.

### Negative

- A bump is a deliberate multi-file change (toml + extension manifests +
  snapshot + manifest regeneration).
- The app may sit one quarter behind a newly released surface.

### Neutral

- The pinned version is repeated in the app ADRs by design — repetition here is
  the traceability mechanism.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Bump lands without re-running `/architecture-review` | Medium | Medium | `/gate-check` requires an architecture-review report newer than the pin |
| Extension manifest version drifts from app pin | Medium | High | Boot-time equality assertion; `/consistency-check` flags mismatch |
| Snapshot edited in place, losing the old contract | Low | High | Directory-per-version rule; snapshots are review-protected |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | n/a | unchanged by pinning | 1.5 s admin route p75 |
| GraphQL cost per request | n/a | unchanged | ≤ 500 without a bulk operation |
| Webhook processing lag | n/a | unchanged | p95 < 500 ms |
| DB query time (p95) | n/a | n/a | 50 ms |

## Migration Plan

Both apps are pre-scaffold, so the first pin is created by `/scaffold`. For a
future bump:

1. Add `docs/shopify-api-reference/<new>/` from the release notes.
2. Update `VERSION.md`; leave the old directory untouched.
3. Bump `apps/<app>/shopify.app.toml` and the extension manifests in one commit.
4. Run `/architecture-review <app> api`, fix deprecated-field findings.
5. Regenerate `control-manifest.md`, deploy to the dev store, replay one webhook
   per registered topic.

**Rollback plan**: revert the pin commit. The old snapshot still exists, so no
data migration is required.

## Validation Criteria

- [ ] `grep -r "2026-10" apps/<app>/app apps/<app>/extensions` returns manifest
      declarations only — no literal in source.
- [ ] Boot assertion fails when an extension manifest disagrees with the pin.
- [ ] Every app ADR's **Shopify API Surface** table names `2026-10`.
- [ ] A bump story has a passing `/architecture-review` report before merge.

## App Requirements Addressed

This is a cross-app foundational decision; it addresses no single app's
requirement directly. It constrains how every app satisfies its own
`REQ-API-*` entries: each app's requirements registry must cite this ADR from
its API-surface requirements, and no app requirement may demand an unpinned
version.

## Related

- `docs/registry/architecture.yaml` — stance `admin_api_version_policy`
- Per-app ADRs: `apps/discount-bundles/ADR-0001-*`, `apps/order-tags/ADR-0001-*`
- `docs/shopify-api-reference/VERSION.md` — the repo-wide pin
