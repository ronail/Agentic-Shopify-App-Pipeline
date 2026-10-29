# Incident Response: [Incident Title]

> **Incident ID**: INC-[NNNN] · **App**: `apps/<app>`
> **Severity**: [S1 — all merchants down / S2 — major function broken /
> S3 — degraded / S4 — minor]
> **Status**: [Investigating | Identified | Mitigating | Resolved | Closed]
> **Start**: [timestamp + timezone] · **Detected**: [timestamp] · **Resolved**: [timestamp]

## Impact Summary

| Field | Value |
|-------|-------|
| **Merchants affected** | [N shops / N% of installs] |
| **Merchant-visible symptom** | [What they saw — e.g. "orders stopped reaching the warehouse"] |
| **Data impact** | [None | Delayed | Lost — scope] |
| **Billing impact** | [None | Charged for a broken feature] |
| **Detection source** | [Merchant report | Partner dashboard alert | Log alert] |
| **Time to detect** | [N minutes] |
| **Time to resolve** | [N minutes] |

## Timeline

| Time | Event | Actor |
|------|-------|-------|
| [HH:MM] | First merchant report / alert fired | |
| [HH:MM] | Acknowledged, incident opened | |
| [HH:MM] | Root cause hypothesis formed | |
| [HH:MM] | Mitigation applied | |
| [HH:MM] | Confirmed resolved | |

## Root Cause

### What Happened

[The mechanism, in plain language, as understood at resolution time.]

### Why It Happened

[The underlying cause — e.g. a webhook subscription was lost after a scope change
and the app treated 404 as success.]

### Contributing Factors

- [Factor 1 — e.g. no alert on webhook delivery failure]
- [Factor 2 — e.g. retry queue backed off to 6h and nobody noticed]

## Mitigation and Resolution

### Immediate Actions (during incident)

- [Action taken to stop the bleeding — e.g. re-registered webhooks, replayed the
  queue, rolled back the deploy]

### Follow-Up Actions (after resolution)

- [Action with owner and date]

## Merchant Communication

### Initial Acknowledgment

> [Short, factual, no speculation. Name the impact and what you're doing.]

### Status Updates

> [Cadence committed — e.g. every 60 minutes for S1.]

### Resolution Notice

> [What happened, what was fixed, what merchants should do if they still see
> problems.]

### Compensation (if applicable)

> [Credit, extended trial, or explanation of why none is due. Billing changes must
> go through the Billing API, never manually.]

## Prevention

### What We Are Changing

- [Code change — with ticket]
- [Alert added — with threshold]

### Process Improvements

- [Process change — e.g. scope changes now require a webhook re-registration check]

## Lessons Learned

### What Went Well

- [Observation]

### What Went Poorly

- [Observation]

### Where We Got Lucky

- [Observation — e.g. it happened during a low-volume hour]

## Sign-Offs

| Role | Name | Date |
|------|------|------|
| Incident commander | | |
| App lead | | |
| Release manager | | |
