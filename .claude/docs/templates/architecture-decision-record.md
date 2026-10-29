# ADR-[NNNN]: [Title]

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Date

[YYYY-MM-DD — when this ADR was written]

## Last Verified

[YYYY-MM-DD — when this ADR was last confirmed accurate against the current
pinned Admin API version and PRD. Update this date when you re-read and confirm
it is still correct, even if nothing changed.]

## Decision Makers

[Who was involved in this decision]

## Summary

[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether to
read the full decision. Be specific: name the system, the problem, and the
chosen approach.]

## Platform Compatibility

| Field | Value |
|-------|-------|
| **Admin API version** | [e.g. `2025-10`] |
| **Surface** | [Admin GraphQL / REST / Webhooks / App Bridge / Polaris / Checkout extension / Billing / POS] |
| **Knowledge risk** | [LOW — well documented / MEDIUM — recently changed, verify / HIGH — new surface, must verify] |
| **References consulted** | [e.g. `shopify.dev/docs/api/admin-graphql/2025-10`, changelog entry] |
| **Recently introduced APIs used** | [Fields or mutations this decision depends on, or "None"] |
| **Verification required** | [Concrete behaviours to exercise on a dev store before shipping, or "None"] |

> **Note**: If knowledge risk is MEDIUM or HIGH, this ADR must be re-validated at
> each API version bump. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering note** | [Any sequencing constraint that isn't captured above] |

## Context

### Problem Statement

[What problem are we solving? Why must this decision be made now? What is the
cost of not deciding?]

### Current State

[How does the system work today? What is wrong with the current approach?]

### Constraints

- [Technical constraints — Admin API limits, rate limits, App Bridge capabilities]
- [Platform constraints — access scopes, protected customer data rules, app review]
- [Timeline constraints — deadline pressures, dependencies]
- [Compatibility requirements — must work with existing apps and shared `src/`]

### Requirements

- [Functional requirement 1]
- [Functional requirement 2]
- [Performance requirement — specific, measurable]
- [Scale requirement — shops, orders/day, webhook volume]

## Decision

[The specific technical decision, described in enough detail for someone to
implement it without further clarification.]

### Architecture

```
[ASCII diagram showing the system architecture this decision creates.
Show components, data flow direction, and key interfaces.]
```

### Key Interfaces

```
[Pseudocode or language-specific interface definitions that this decision
creates. These become the contracts that implementers must respect.]
```

### Implementation Guidelines

[Specific guidance for the engineer implementing this decision — error handling,
retry policy, idempotency keys, logging fields.]

## Alternatives Considered

### Alternative 1: [Name]

- **Description**: [How this approach would work]
- **Pros**: [What is good about this approach]
- **Cons**: [What is bad about this approach]
- **Estimated Effort**: [Relative effort compared to chosen approach]
- **Rejection Reason**: [Why this was not chosen]

### Alternative 2: [Name]

[Same structure as above]

## Consequences

### Positive

- [Good outcomes of this decision]

### Negative

- [Trade-offs and costs we are accepting]

### Neutral

- [Changes that are neither good nor bad, just different]

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Admin API latency (p95) | [X]ms | [Y]ms | [Z]ms |
| GraphQL cost per request | [X] points | [Y] points | [Z] points |
| Webhook processing lag | [X]s | [Y]s | [Z]s |
| DB query time (p95) | [X]ms | [Y]ms | [Z]ms |

## Migration Plan

[If this changes existing systems, the step-by-step plan to migrate — including
the data backfill and its rate-limit budget.]

1. [Step 1 — what changes, what breaks, how to verify]
2. [Step 2]
3. [Step 3]

**Rollback plan**: [How to revert if this decision proves wrong]

## Validation Criteria

[How we will know this decision was correct after implementation.]

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Performance criterion]

## PRD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one PRD
     requirement, or explicitly state it is a foundational decision with no PRD
     dependency. Traceability is audited by /architecture-review. -->

| PRD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| [e.g. `docs/prd/sync.md`] | [e.g. Order Sync] | [e.g. "Failed orders must be retryable from the admin"] | [e.g. "Retry queue keyed by (shop, order id) with exponential backoff"] |

> If this is a foundational decision with no direct PRD dependency, write:
> "Foundational — no PRD requirement. Enables: [list what PRD systems this
> decision unlocks or constrains]"

## Related

- [Link to related ADRs — note if supersedes, contradicts, or depends on]
- [Link to relevant code files once implemented]
