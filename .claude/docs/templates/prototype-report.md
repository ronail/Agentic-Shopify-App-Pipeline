# Prototype Report: [Prototype Name]

> **Date**: [YYYY-MM-DD]
> **App**: `apps/<app>`
> **Prototype Path**: [Clickable HTML / Running app on dev store / Paper]
> **Concept File**: `apps/<app>/concept.md` (if it exists)
> **Gate**: gate-2-prototype evidence

---

## Hypothesis

[The falsifiable hypothesis this prototype set out to test:
"If the merchant [does X in the admin], they will [achieve Y] — evidenced by
[measurable signal Z, e.g. task completed without support, time on task]."]

---

## Riskiest Assumption Tested

[What was identified as the biggest risk in the concept — an Admin API limit, a
scope rejection, an onboarding drop-off — and whether it proved out.]

---

## Approach

[What was built, how long it took, what shortcuts were taken deliberately.]

**Path chosen:** [Clickable HTML / Running app on dev store / Paper]
**Reason for path:** [Why this path was appropriate for this hypothesis]

**Shortcuts taken (intentional):**
- [e.g. seeded fixtures instead of live orders, stub billing, no multi-currency,
  hardcoded shop domain]

---

## Result

[What actually happened — specific observations, not opinions. Quote merchant
or internal testers directly where possible. Note the exact dev store and API
version used.]

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | [Clickable HTML / Running app / Paper] |
| Dev store | [store handle] — API version [YYYY-MM] |
| Iterations to usable | [N] |
| Prototype duration | [e.g. 6 hours] |
| Testers | [N internal / N merchants] |
| Task completion | [e.g. "4/5 testers completed install → first sync unprompted"] |
| Time to first value | [e.g. "median 3m 20s"] |
| Hypothesis verdict | [CONFIRMED / PARTIALLY CONFIRMED / REFUTED] |

---

## Recommendation: [PROCEED / PIVOT / KILL]

[One paragraph explaining the recommendation with evidence from the result above.]

---

## If Proceeding

[What the prototype revealed that should directly inform the PRD:]

- **Values discovered:** [e.g. "sync interval of 5 minutes satisfied every tester;
  1 minute added cost with no perceived benefit"]
- **Assumptions confirmed:** [What the concept doc assumed that proved true]
- **Assumptions disproved:** [What the concept doc assumed that proved wrong]
- **Emergent behaviour:** [Workflows testers invented that we should formalize]

> Note: if the prototype was clickable HTML and the flow depends on real Shopify
> data, run an app prototype against a dev store before committing to the PRD.

**Next steps:**
1. `/prototype-review apps/<app>/prototype`
2. `/gate-check` (gate-2-prototype)
3. `/research` to close any market gaps
4. `/create-architecture` for the validated scope

---

## If Pivoting

[What alternative direction the results suggest — what felt almost right and what
to adjust. Be specific about what to change, not just that something needs changing.]

**Pivot direction**: [What to try differently]
**What to keep**: [What worked and should be preserved]
**Next step**: `/build-prototype [revised concept]`

---

## If Killing

[Why this concept does not work — what specific signal led to the verdict.
This report is the deliverable; no further action needed on this concept.]

**Next step:** `/brainstorm [new-direction]`

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  [...]

- **What surprised us that didn't show up in the brainstorm?**
  [...]

- **What would we test differently next time?**
  [...]

---

> *Prototype location: `apps/<app>/prototype/`*
> *This code is throwaway. Never refactor into production.*
