# Shopify App Architecture: [App Name]

> **App**: `apps/<app>` · **Version**: [n] · **Date**: [YYYY-MM-DD]
> **API version**: [YYYY-MM] · **Maintained by**: app-architect
> **Companions**: `architecture-decision-record.md` (per decision),
> `architecture-traceability.md` (PRD → ADR coverage)

## 1. Summary

[Three sentences: what the app does, how it is hosted, and the two or three
architecture choices that shape everything else.]

## 2. Shopify Surface

| Surface | Used | Notes |
|---------|------|-------|
| Embedded admin app | [Yes/No] | App Bridge session tokens; Polaris |
| Admin actions / blocks | [Yes/No] | [Where they appear] |
| Checkout UI extension | [Yes/No] | [Limits that apply] |
| Theme app extension | [Yes/No] | |
| POS UI extension | [Yes/No] | |
| Webhooks | [Topics] | |

## 3. Request Path

```
Merchant browser (admin iframe)
  → App Bridge session token
  → App server (verify JWT, resolve shop)
  → Service layer (business rules)
  → Admin GraphQL API (pinned version)
  → Postgres (app-owned state)
```

| Layer | Responsibility | Must not |
|-------|----------------|----------|
| Iframe UI | Render Polaris, fire mutations | Hold secrets or call Shopify directly |
| API routes | Auth, validation, orchestration | Contain business rules |
| Services | Business rules, retries, mapping | Touch the request object |
| Data layer | Persistence, migrations | Call Shopify |

## 4. Authentication & Authorization

| Concern | Approach |
|---------|----------|
| Install | OAuth grant, verify HMAC, exchange for offline + online tokens |
| Session | App Bridge JWT verified per request (`aud`, `exp`, `dest`) |
| Shop identity | Resolve from `dest` claim; never from a request body |
| Scope changes | Detect missing scope → `Banner` + re-auth path; never silent retry |
| Uninstall | `app/uninstalled` → mark shop uninstalled, stop jobs, purge per policy |
| Secrets | Env vars per environment; never committed |

## 5. Admin API Usage

| Operation | Query / mutation | Cost profile | Frequency |
|-----------|------------------|--------------|-----------|
| [Order read] | [`orders(first: 50)`] | [points] | [per sync] |
| [Bulk import] | [`bulkOperationRunQuery`] | [async] | [nightly] |

- **Pagination**: cursor-based only; never page by offset.
- **Rate limits**: back off on `THROTTLED`, respect the leaky bucket, cap parallel
  requests per shop.
- **Bulk operations**: use for >[1,000] records; poll the operation, handle failure
  with a resumable checkpoint.
- **Versioning**: version pinned in config; upgrade is an ADR, not an edit.

## 6. Webhooks

| Topic | Handler responsibility | Idempotency key |
|-------|-----------------------|-----------------|
| `orders/create` | [Create sync record] | `X-Shopify-Webhook-Id` |
| `orders/updated` | [Update record] | |
| `app/uninstalled` | [Stop jobs, mark uninstalled] | shop domain |
| `app_subscriptions/update` | [Sync plan entitlement] | subscription GID |
| `customers/data_request`, `customers/redact`, `shop/redact` | Compliance responses | payload id |

Rules: verify HMAC before parsing, respond 200 fast, process asynchronously,
deduplicate by webhook id, replay from a persisted event log on failure.

## 7. Data Model

| Entity | Key fields | Indexes | Retention |
|--------|-----------|---------|-----------|
| `Shop` | `shop_domain`, `access_token_ref`, `plan`, `uninstalled_at` | unique(shop_domain) | purge [N] days after uninstall |
| `SyncRecord` | `shop_id`, `order_gid`, `status`, `attempts` | (shop_id, status), (shop_id, order_gid) | [N] days |

Rules: store Shopify GIDs, not numeric ids; never store customer PII unless the
PRD requires it and protected-customer-data access is approved.

## 8. Hosting & Operations

| Concern | Choice |
|---------|--------|
| Hosting | [platform] |
| Runtime | [Node version] |
| Database | [Postgres version + provider] |
| Background jobs | [queue] |
| Observability | [logs, metrics, alerts — include webhook failure alert] |
| Backups | [frequency, restore test cadence] |
| Environments | [dev / staging / production] |

## 9. Billing Architecture

[Recurring app subscription vs usage; where entitlement is cached; how
`app_subscriptions/update` reconciles state; what a downgraded merchant loses.]

## 10. Security & Compliance

- [ ] Protected customer data declared and approved (if applicable)
- [ ] Least-privilege scopes, each traced to a requirement
- [ ] HMAC verification on every webhook
- [ ] Input validation at the API boundary
- [ ] Secrets in the platform's secret store
- [ ] Audit log for destructive operations

## 11. Decision Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-0001] | [Title] | [Accepted] |

## 12. Known Constraints

[What this architecture deliberately does not do — e.g. no multi-tenant
cross-shop analytics, no real-time sync below 60s, no EU data residency yet.]
