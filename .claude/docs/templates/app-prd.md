# App PRD: [App Name]

> **File**: `docs/prd/<app>.md` · **App**: `apps/<app>` · **Version**: [n]
> **Gate**: gate-3-scope must be approved in `apps/<app>/approvals.json` before stories are cut.
> **Source**: `app-concept.md`, `mmmvp-proposal.md`, `docs/research/<app>-research.md`

## 1. Problem

[The merchant pain, with the number attached. Who feels it, how often, what it
costs them today.]

## 2. Users

| User | What they do in the app | Permissions needed |
|------|------------------------|--------------------|
| [Store owner] | [Install, choose plan, configure] | [org admin] |
| [Ops manager] | [Daily workflow] | [staff with orders access] |

## 3. Scope

### In Scope (this release)

- [Workflow 1 — named in merchant terms]

### Out Of Scope (documented, not implied)

| Excluded | Reason | Revisit when |
|----------|--------|--------------|
| [Feature] | [Reason] | [Trigger] |

## 4. Functional Requirements

Each requirement is testable and traceable to an ADR via `architecture-traceability.md`.

| ID | Requirement | Priority | Acceptance signal |
|----|-------------|----------|-------------------|
| FR-1 | [The system must ...] | Must | [Observable result] |
| FR-2 | [ ... ] | Must | |
| FR-3 | [ ... ] | Should | |
| FR-4 | [ ... ] | Could | |

## 5. User Workflows

### 5.1 Install and first value

1. Merchant finds the app → [listing claim]
2. OAuth grant → scopes: [list]
3. First screen → [what they see, empty or seeded]
4. First value → [the moment the app proves itself]

### 5.2 [Core recurring workflow]

| Step | Merchant action | System behaviour | Failure handling |
|------|-----------------|------------------|------------------|
| 1 | | | |

## 6. Shopify Integration Requirements

| Field | Requirement |
|-------|-------------|
| Admin API version | [YYYY-MM] — pinned |
| Scopes | [scope — why it is needed] |
| Webhooks | [topic — handler responsibility] |
| Mandatory webhooks | `app/uninstalled`, `shop/redact`, `customers/redact`, `customers/data_request` |
| App Bridge | [session tokens required on every request] |
| Polaris | [version; no hand-rolled primitives] |
| Billing | [plan ids, trial length, usage charges] |
| Extensions | [none / which] |

## 7. Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Admin page p95 | < [400] ms |
| Webhook processing | < [5] s p95; retries with backoff |
| Error rate | < [0.5]% of requests |
| Availability | [99.9]% |
| Data retention after uninstall | [N days, then purge] |
| Accessibility | WCAG 2.2 AA (see `accessibility-requirements.md`) |
| Localization | [Languages at launch] |

## 8. Data And Privacy

| Data | Source | Stored | Retention | Legal basis |
|------|--------|--------|-----------|-------------|
| [Order ids] | Admin API | [DB table] | [N days] | [Contract] |
| [Customer email] | Admin API | [Encrypted column] | [N days] | [Contract, protected customer data approval] |

## 9. Success Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| Activation | Installs reaching first value | [X]% |
| Retention | Still installed + used at day 30 | [X]% |
| Paid conversion | Trials converting | [X]% |
| Support load | Tickets per 100 installs | < [X] |

## 10. Acceptance For This Release

- [ ] All Must requirements implemented and evidenced
- [ ] `/app-store-checklist` passes with zero fails
- [ ] Onboarding completes on a clean dev store in < [5] minutes
- [ ] Uninstall and reinstall behave per §8
- [ ] No scope exists that is not used by a requirement above

## 11. Open Questions

| # | Question | Owner | Blocks |
|---|----------|-------|--------|
| 1 | [Question] | [Who] | [FR / gate] |

## 12. Change Log

| Version | Date | Change | Request-history entry |
|---------|------|--------|-----------------------|
| 1.0 | [Date] | Initial PRD | [link] |
