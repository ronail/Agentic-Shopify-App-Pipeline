# ADR: [Decision Name] (reverse-documented from code)

> **Source**: reverse-documented by `/reverse-document` from the current
> implementation — [primary file paths]
> **App**: `apps/<app>` · **Date**: [YYYY-MM-DD] · **API version**: [YYYY-MM]
> **Confidence**: [High — code is unambiguous | Medium — intent inferred | Low — needs author confirmation]

## Context

[What problem the code solves, reconstructed from behaviour and commit history.
State the forces: Admin API constraints, rate limits, scope set, performance
budget, merchant expectations. Say plainly which parts are inference.]

## Decision

[What was actually built. Describe the approach as the code implements it —
components, data flow, and the contract other modules rely on.]

```
[ASCII diagram of what the code does today]
```

**Key code locations**

| Concern | File | Notes |
|---------|------|-------|
| Entry point | [path] | |
| Data access | [path] | |
| Error handling | [path] | |

## Alternatives Considered

### Alternative 1: [Approach Name]

- **Description**: [How this would have worked]
- **Pros**: [Why it was plausible]
- **Cons**: [Why it likely lost]
- **Evidence in code that it was rejected**: [Absent dependency, commented-out path, commit message]

### Alternative 2: [Approach Name]

[Same structure]

### Alternative 3: [Status Quo / No Change]

- **Description**: [Keep the previous behaviour]
- **Pros**: [No migration]
- **Cons**: [The problem that forced the change]
- **Rejection reason**: [Observed]

## Consequences

### Positive Consequences (Benefits Realized)

- [Benefit visible in the code — e.g. one batched GraphQL query instead of N calls]

### Negative Consequences (Trade-offs Accepted)

- [Cost being paid — e.g. no incremental sync; full refresh each run]

### Neutral Consequences (Observations)

- [Difference that is neither good nor bad]

## Implementation Notes

- [Non-obvious detail a maintainer must know]
- [Ordering constraint]
- [Magic constant and where it comes from]

## Validation

How the current implementation is proven correct:

| Check | Method | Status |
|-------|--------|--------|
| [Behaviour] | [unit test path] | [Passing / Missing] |
| [Integration] | [dev-store test] | [Passing / Manual only] |

**Unvalidated behaviour**: [What the code does that nothing tests]

## Open Questions

| # | Question | Why it matters | Owner |
|---|----------|----------------|-------|
| 1 | [Question] | [Risk if wrong] | [Who can answer] |

## Follow-Up Work

- [ ] [Refactor or test to add] — [reason] — [ticket]

## Related Decisions

- [ADR-NNNN] — [relationship: depends on / supersedes / contradicts]

## References

- [Shopify docs page read]
- [Commit hashes reviewed]
- [Related PRD section]

## Version History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | [Date] | Reverse-documented from [commit] |

## Status Legend

| Status | Meaning |
|--------|---------|
| Proposed | Written before implementation; not yet accepted |
| Accepted | Implementation matches this document |
| Deprecated | Still in code, no longer the intended approach |
| Superseded by ADR-XXXX | Replaced by a newer decision |

## Appendix: Code Snippets

```[language]
// [what this snippet proves about the decision]
```

```[language]
// [second snippet]
```
