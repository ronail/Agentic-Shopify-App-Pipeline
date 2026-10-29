# Sprint [N] — [Start Date] to [End Date]

> **App**: `apps/<app>` · **Kanban**: `production/apps/<app>/kanban.md`
> **Gate context**: required gate for the next phase is recorded in
> `apps/<app>/approvals.json` before the sprint closes (see `approval-gate.sh`).

## Sprint Goal

[One sentence: what does this sprint achieve toward the current milestone?]

## Milestone Context

- **Current Milestone**: [Name]
- **Milestone Deadline**: [Date]
- **Sprints Remaining**: [N]

## Capacity

- **Total days**: [X]
- **Buffer (20%)**: [Y days reserved for unplanned work — webhook debugging,
  app review feedback, Partner dashboard outages]
- **Available**: [Z days]

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S[N]-001 | | | | None | | Not Started |
| S[N]-002 | | | | S[N]-001 | | Not Started |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S[N]-010 | | | | | | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S[N]-020 | | | | | | Not Started |

## Carryover from Sprint [N-1]

| Original ID | Task | Reason for Carryover | New Estimate | Priority Change |
|------------|------|---------------------|-------------|----------------|

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| Shopify API version deprecation | | | Pin to a supported version | |
| App review queue | | | Ship behind a feature flag | |
| Dev store provisioning | | | Use an existing dev store | |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] Every task reflected in the app kanban (`production/apps/<app>/kanban.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] `shopify app dev` boots clean against the dev store; no GraphQL errors in logs
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/qa-plan` evidence)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Technical design / ADR updated for any deviation (`/architecture-decision`)
- [ ] Code reviewed and merged
