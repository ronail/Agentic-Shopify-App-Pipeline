# Technical Design: [System / Service Name]

## Document Status
- **Version**: 1.0
- **Last Updated**: [Date]
- **App**: `apps/<app>`
- **Author**: [Agent/Person]
- **Reviewer**: lead-engineer
- **Related ADR**: [ADR-XXXX if applicable]
- **Related PRD**: [Link to `docs/prd/<app>.md` section this implements]

## Platform API Surface

| Field | Value |
|-------|-------|
| **Admin API version** | [e.g. `2025-10` — pinned; upgrade reviewed quarterly] |
| **API design** | [Admin GraphQL (default) / REST only where GraphQL has no equivalent] |
| **APIs depended on** | [Specific queries/mutations, version-pinned — e.g. `orderUpdate` mutation (2025-10)] |
| **References consulted** | [Shopify docs pages read before writing — e.g. `shopify.dev/docs/api/admin-graphql/2025-10`] |
| **App Bridge / Polaris versions** | [e.g. App Bridge 4.x, Polaris 13.x] |
| **Post-deprecation features used** | [Fields/flags newer than the team's baseline knowledge, or "None"] |
| **Unverified assumptions** | [API behaviour assumed but not yet exercised on a dev store, or "None"] |
| **Deprecation risk** | [LOW / MEDIUM / HIGH — how fragile is this design if the API version moves?] |

> **Rule**: If any **Unverified assumptions** are listed, this document cannot be
> marked Accepted until those assumptions are exercised against a dev store on
> the pinned API version.

## Overview
[2-3 sentence summary of what this system does and why it exists]

## Requirements
### Functional Requirements
- [FR-1]: [Description]
- [FR-2]: [Description]

### Non-Functional Requirements
- **Latency**: [Budget — e.g. "p95 admin request < 400ms"]
- **Throughput**: [e.g. "5,000 webhook events/min without backlog"]
- **Memory / storage**: [Budget — e.g. "row store < 5GB for a 100k-order shop"]
- **Rate limits**: [GraphQL cost budget per shop — leaky bucket points restored/s]
- **Idempotency**: [Requirements for retried mutations and webhooks]
- **Data retention**: [How long merchant data is kept after uninstall]

## Architecture

### System Diagram
```
[ASCII diagram showing components and data flow: admin frontend (App Bridge),
app server, queues, database, Shopify Admin API, webhook ingress]
```

### Component Breakdown
| Component | Responsibility | Owns |
| --------- | -------------- | ---- |
| [Name] | [What it does] | [What data it owns] |

### Public API
```
[Internal API / tRPC / REST contract in pseudocode or target language]
```

### Data Structures
```
[Key models with field descriptions and indexes]
```

### Data Flow
[Step by step for the primary path: admin request → auth (session token) →
GraphQL query → cache → response. Then the webhook path: verify HMAC → enqueue →
worker → Admin API write.]

## Implementation Plan

### Phase 1: [Core Functionality]
- [ ] [Task 1]
- [ ] [Task 2]

### Phase 2: [Extended Features]
- [ ] [Task 3]
- [ ] [Task 4]

### Phase 3: [Hardening]
- [ ] [Task 5 — rate-limit backoff, webhook replay, observability]

## Dependencies
| Depends On | For What |
| ---------- | -------- |
| [System] | [Reason] |

| Depended On By | For What |
| -------------- | -------- |
| [System] | [Reason] |

## Testing Strategy
- **Unit tests**: [Pure logic — mappers, validators, cost calculators]
- **Integration tests**: [Against a dev store or a recorded GraphQL contract]
- **Webhook tests**: [HMAC verification, replay, ordering]
- **Performance tests**: [Rate-limit behaviour under a 10k-order backfill]

## Known Limitations
[What this design intentionally does NOT support and why — e.g. multi-currency
only on Plus, no bulk operations above 10k records]

## Future Considerations
[What might need to change if requirements evolve — but do NOT build for this now]
