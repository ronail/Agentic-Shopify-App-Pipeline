# Risk: [Short Title]

## Identification

- **ID**: RISK-[NNNN]
- **App**: [apps/<app>]
- **Identified By**: [Agent or person]
- **Date Identified**: [Date]
- **Category**: [Technical | Product | Schedule | Resource | External | Quality | Shopify Platform]

## Assessment

- **Probability**: [Very Low | Low | Medium | High | Very High]
- **Impact**: [Minimal | Minor | Moderate | Major | Critical]
- **Risk Score**: [Probability x Impact = Low / Medium / High / Critical]

## Description

[Detailed description of the risk. What could break — the Admin GraphQL API
contract, a webhook pipeline, billing, app review, the dev store — and under
what conditions?]

## Trigger Conditions

[What observable conditions would indicate this risk is materializing?]

- [Condition 1 — e.g. a deprecation warning in the Partner dashboard]
- [Condition 2 — e.g. webhook delivery failures above 1% in the logs]

## Impact Analysis

### If This Risk Materializes

- **Merchant Impact**: [Broken install, lost orders sync, billing failure]
- **Schedule Impact**: [How many days/weeks of delay]
- **Quality Impact**: [What quality degradation]
- **Scope Impact**: [What features affected]
- **Cost Impact**: [Resource cost of dealing with it]

### Affected Systems/Features

- [System 1 — e.g. order webhook consumer]
- [System 2 — e.g. Polaris admin UI]

## Mitigation Strategy

### Prevention (reduce probability)

- [Action to prevent this risk from occurring]
- [Owner and deadline for prevention action]

### Contingency (reduce impact if it occurs)

- [Action to take if this risk materializes — e.g. fall back to REST Admin API,
  replay webhooks from the event log, switch to a backup dev store]
- [Owner responsible for contingency execution]

## Current Status

- **Status**: [Open | Mitigating | Occurred | Closed]
- **Last Reviewed**: [Date]
- **Trend**: [Increasing | Stable | Decreasing]
- **Notes**: [Any updates]
