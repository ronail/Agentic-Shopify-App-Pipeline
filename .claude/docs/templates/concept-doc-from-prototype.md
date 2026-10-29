# [Prototype Name] — Concept Document

> **App**: `apps/<app>` · **Prototype path**: `apps/<app>/prototype/`
> **Source**: reverse-documented from a working prototype
> **Date**: [YYYY-MM-DD] · **Gate**: gate-2-prototype

---

## 1. Prototype Overview

- **What it is**: [One paragraph — the merchant workflow the prototype demonstrates]
- **Surface**: [Embedded admin page / admin action / extension]
- **Fidelity**: [Clickable HTML / Running app on dev store]
- **Scope covered**: [Which flow end to end]
- **Scope deliberately excluded**: [Auth edge cases, billing, multi-location, etc.]
- **How to run**: [Command and prerequisites]

---

## 2. Core Workflow

[The primary path, step by step, in merchant language. Include the Shopify data
each step reads or writes and where the state lives.]

1. [Step — trigger, data touched, visible result]
2. [Step]
3. [Step — the payoff moment where the merchant sees value]

**Data touched**: [Resources — orders, products, inventory levels, metafields]

---

## 3. What Worked

### Workflow Successes

- [What clicked for testers and why]

### Technical Successes

- [API approach that held up — e.g. paginated GraphQL with cursor + cache]

---

## 4. What Didn't Work

### Workflow Failures

- [Where testers stalled, and what they expected instead]

### Technical Failures

- [What broke — rate limits, webhook ordering, App Bridge quirks]

---

## 5. What Needs Refinement

- [Refinement with the specific change proposed — not "improve UX"]

---

## 6. Key Learnings

### Product Insights

- [Insight]

### Technical Insights

- [Insight — e.g. cost of a query at scale]

### Merchant Psychology Insights

- [Insight — what made merchants trust or distrust the screen]

---

## 7. Production Readiness Assessment

| Area | Ready? | Blocking Work |
|------|--------|---------------|
| Auth / install | [Y/N] | [What's needed] |
| Core workflow | [Y/N] | |
| Error handling | [Y/N] | |
| Billing | [Y/N] | |
| Data model | [Y/N] | |
| Tests | [Y/N] | |
| Accessibility | [Y/N] | |

**Verdict**: [Ready for PRD | Needs another prototype | Kill]

---

## 8. Value Proposition Alignment

[How the prototype supports the pitch's promise. Name anything the prototype
proved that the pitch claimed without evidence, and anything it contradicted.]

---

## 9. Next Steps

### Immediate (If Moving Forward)

1. [Action]

### Before Production (If Needs More Work)

1. [Action]

### If Abandoning

1. [What to salvage — code, learnings, merchant contacts]

---

## 10. Technical Notes

- **Stack**: [Framework, Polaris version, App Bridge version]
- **API version**: [YYYY-MM]
- **Data storage**: [Where prototype data lives; how to reset]
- **Known hacks**: [Shortcuts that must not survive into production]
- **Reusable pieces**: [What can be lifted into the real app]

---

## 11. Merchant Feedback

| Tester | Role / store size | Tried | Outcome | Quote |
|--------|-------------------|-------|---------|-------|
| [Name] | [e.g. 800 orders/mo] | [Flow] | [Completed / Stalled at step N] | "[quote]" |

---

## 12. Related Work

- **Related PRD**: [link or "not written yet"]
- **Related ADRs**: [links]
- **Related prototypes**: [links]

---

## 13. Open Questions

| # | Question | Owner | Needed By |
|---|----------|-------|-----------|
| 1 | [Question] | [Who] | [Date] |

---

## 14. Appendix: Prototype Assets

| Asset | Path | Notes |
|-------|------|-------|
| Prototype source | `apps/<app>/prototype/` | Throwaway |
| Screenshots | `production/apps/<app>/qa/evidence/` | |
| Seed data script | [path] | |

## Version History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | [Date] | Initial reverse-documented concept |
