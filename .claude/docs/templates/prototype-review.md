# Prototype Review: [Prototype Name]

> **App**: `apps/<app>` · **Prototype**: `apps/<app>/prototype/`
> **Reviewer(s)**: [ux-lead, lead-engineer, producer] · **Date**: [YYYY-MM-DD]
> **Gate**: gate-2-prototype · **Report under review**: `prototype-report.md`

## What Was Reviewed

| Field | Value |
|-------|-------|
| Prototype type | [Clickable HTML / Running app on dev store] |
| Flow covered | [End-to-end path, named] |
| Flows not covered | [List] |
| Dev store / API version | [handle / YYYY-MM] |
| How the reviewer ran it | [command + prerequisites] |
| Time spent | [N minutes] |

## Hypothesis Check

| Claim from the concept | Evidence in the prototype | Verdict |
|------------------------|---------------------------|---------|
| [Claim] | [What the reviewer observed] | [Supported / Contradicted / Untested] |

## Findings

### Blocking (must change before PRD or architecture)

| # | Finding | Evidence | Owner |
|---|---------|----------|-------|
| B1 | [What is wrong] | [Screenshot / step / log] | [Role] |

### Important (fix during build)

| # | Finding | Evidence | Owner |
|---|---------|----------|-------|
| I1 | [What is rough] | [Evidence] | [Role] |

### Minor / Notes

| # | Note |
|---|------|
| N1 | [Observation worth keeping] |

## Merchant-Facing Quality

| Dimension | Assessment | Notes |
|-----------|------------|-------|
| Clarity of first screen | [Pass / Needs work] | |
| Time to first value | [N minutes observed] | |
| Polaris consistency | [Pass / Fails] | [Hand-rolled components found] |
| Empty / error / loading states | [Present / Missing] | |
| Keyboard operability | [Pass / Fail] | |
| Mobile admin behaviour | [Pass / Fail / Untested] | |
| Copy quality (merchant language) | [Pass / Needs work] | |

## Technical Findings

| Area | Finding | Risk |
|------|---------|------|
| Admin API usage | [Query shape, pagination, cost] | [H/M/L] |
| Auth / session tokens | [Handled correctly?] | |
| Webhooks | [Any subscription or HMAC issue] | |
| Data model | [Will it survive real volume?] | |
| Billing | [Stubbed / real] | |

## Verdict

- [ ] **PASS** — proceed to PRD / architecture with the blocking findings fixed
- [ ] **CONDITIONAL PASS** — proceed, provided B1..Bn are addressed in the PRD
- [ ] **FAIL** — another prototype iteration required; reason below
- [ ] **KILL** — the concept does not survive contact with the prototype

**Reasoning**: [Two or three sentences tying the verdict to the findings above.]

## Next Steps

| # | Action | Owner | By when |
|---|--------|-------|---------|
| 1 | [Action] | [Role] | [Date] |

## Sign-Off

| Role | Name | Verdict |
|------|------|---------|
| UX | | [Pass / Fail] |
| Engineering | | [Pass / Fail] |
| Product | | [Pass / Fail] |
