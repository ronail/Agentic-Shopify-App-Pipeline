# MMMVP Proposal: [App / Feature Name]

> **MMMVP** = the **minimum merchant-viable product**: the smallest thing a real
> merchant will install, pay for, and keep. Not a demo, not a thin slice of ten
> features — one workflow, finished.
> **App**: `apps/<app>` · **Date**: [YYYY-MM-DD] · **Gate**: gate-3-scope

## The Merchant And The Pain

- **Merchant**: [specific segment — order volume, tooling, team size]
- **Pain today**: [what they do manually, how long it takes, what it costs them]
- **Cost of the pain**: [hours/week or currency — a number, even a rough one]
- **What they use now**: [spreadsheet / another app / nothing]

## The One Workflow

[Name the single workflow this MMMVP completes end to end. If you need the word
"and" twice, it is too big.]

1. Merchant installs → [what they see]
2. Merchant grants → [exact scopes]
3. Merchant configures → [how many inputs? ≤3 is the target]
4. System does → [the automatic work, with Shopify resources named]
5. Merchant sees → [the payoff screen]

## Proof Of Value

| Question | Answer |
|----------|--------|
| Time to first value | [target: < 5 minutes from install] |
| What the merchant sees that proves it worked | [concrete screen/email/report] |
| What they would lose by uninstalling | [the switching cost we are earning] |
| Willingness to pay | [evidence — pilot quotes, comparable app pricing] |

## Shopify Surface

| Field | Value |
|-------|-------|
| Surface | [Embedded admin page / admin action / extension] |
| Admin API version | [YYYY-MM] |
| Scopes | [list — each justified] |
| Webhooks | [topics required for the workflow to stay correct] |
| Billing | [plan name + price, or "free while in beta"] |

## Explicitly Excluded (And Why That's Fine)

| Excluded | Why it can wait | What breaks without it |
|----------|-----------------|------------------------|
| [Feature] | [Reason] | [Nothing / a documented limitation] |
| [Feature] | [Reason] | [Workaround] |

## Effort

| Work | Estimate | Confidence |
|------|----------|-----------|
| Scaffold + auth + App Bridge | [days] | [H/M/L] |
| Core workflow | [days] | |
| Billing | [days] | |
| Onboarding + empty states | [days] | |
| Listing + review prep | [days] | |
| **Total** | **[days]** | |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Scope creep during build | High | High | This table is the scope contract; changes need a request-history entry |
| App review rejection | [H/M/L] | High | Run `/app-store-checklist` before submission |
| Merchant does not return after first use | [H/M/L] | Critical | Define the retention hook now, not later |

## Decision

- [ ] **APPROVED** — build the MMMVP as scoped; gate-3 recorded in `approvals.json`
- [ ] **REVISE** — scope adjusted as noted, re-propose
- [ ] **REJECTED** — reason recorded

**Approver**: [name] · **Date**: [date]
