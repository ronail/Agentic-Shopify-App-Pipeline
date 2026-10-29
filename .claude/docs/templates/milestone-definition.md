# Milestone: [Name]

## Overview

- **App**: `apps/<app>`
- **Target Date**: [Date]
- **Type**: [Prototype | MVP | Beta | App Store Submission | Launch | Post-Launch]
- **Duration**: [N weeks]
- **Number of Sprints**: [N]

## Milestone Goal

[2-3 sentences describing what this milestone achieves and why it matters.
What can we demonstrate or evaluate at the end of this milestone?]

## Success Criteria

[Specific, measurable criteria. The milestone is complete ONLY when all of
these are met.]

- [ ] [Criterion 1 -- specific and testable]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] All S1 and S2 bugs resolved
- [ ] Install → OAuth → first value path completes on a clean dev store in < [X] minutes
- [ ] App review checklist passes (`/app-store-checklist`) with zero blocking items

## Feature List

### Must Ship (Milestone Fails Without These)

| Feature | PRD / Design Doc | Owner | Sprint Target | Status |
|---------|-----------|-------|--------------|--------|

### Should Ship (Planned but Cuttable)

| Feature | PRD / Design Doc | Owner | Sprint Target | Cut Impact | Status |
|---------|-----------|-------|--------------|-----------|--------|

### Stretch Goals (Only if Ahead of Schedule)

| Feature | PRD / Design Doc | Owner | Value Add |
|---------|-----------|-------|----------|

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Error rate (5xx) | < [X]% of requests | App logs / Partner dashboard |
| Webhook failure rate | < [X]% | Delivery log + retry queue depth |
| Admin API latency (p95) | < [X] ms | Instrumented request timing |
| Install success rate | > [X]% | OAuth funnel logs |
| Critical bugs | 0 open S1 | Bug tracker |
| Major bugs | < [X] open S2 | Bug tracker |
| Test coverage | > [X]% | Test framework report |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| Admin API version | Shopify | | Deprecation breaks queries |
| App review slot | Shopify | | Launch slips a review cycle |
| Billing approval | Shopify | | Cannot charge merchants |

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| [Week 2] | Early progress check | Producer, Directors |
| [Midpoint] | Mid-milestone review | Full team |
| [Week N-1] | Pre-milestone review | Full team |
| [Target Date] | Milestone review | Full team |
