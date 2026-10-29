# Session: Prototype Review and the Scope Gate

**Skills:** `/build-prototype` → `/prototype-review` → `/gate-check gate-2-prototype` → `/scope-check`
**Agents:** `prototype-builder`, `ux-lead`, `product-director`, `producer`
**Duration:** ~2 days of builder time, ~25 minutes of review
**Complexity:** Medium

`discount-bundles` has research, UX specs, an architecture and two Accepted ADRs.
Before epics are written, the prototype has to prove the risky parts on a real dev
store — not on a mockup.

---

## Turn 1 — what the prototype must prove

```
User: /build-prototype discount-bundles

prototype-builder: "A prototype is throwaway code that answers questions. So
                    first: which questions?

                    From the ADRs, the risky parts are:
                    1. Does the cart transform actually expand a bundle on a
                       real cart? (ADR-0001, knowledge risk HIGH)
                    2. Is the variant picker usable at 50 components? (REQ-BUNDLE-001)
                    3. Does the broken-bundle state make sense to a merchant?

                    (2) and (3) are UX questions I can answer in a day.
                    (1) is a platform question — it needs a real store, a real
                    product, and a real cart.

                    Proposal: build (1) first as a bare route with a JSON editor
                    for the config. No Polaris, no list view. If the function
                    does not expand, everything else is wasted motion."
```

**User:** "Function first. Then the picker."

```
prototype-builder: "Agreed. apps/discount-bundles/prototype/ — explicitly
                    throwaway, excluded from the app's build. It runs under
                    `shopify app dev` against the dev store.

                    May I write it?"
```

**User:** "Yes."

---

## Turn 2 — the function works, the picker does not

```
prototype-builder: "Day 1 result, in one sentence each:

  ✅ The transform expands: adding the bundle product yields 5 component lines,
     component inventory decrements, removing the parent removes all five.
  ⚠️ Fixed-price allocation: my test bundle came out 1 cent over. The
     remainder went to the wrong component because I sorted by price and the
     last element was the cheapest. Fixable in the function, but it means
     ADR-0001's 'remainder on the last component' needs to say 'last component
     in input order', not 'last after sorting'.
  ❌ The picker: at 40 components the list is unusable. Scrolling to find a
     variant is slower than typing the SKU. I built both a search-first and a
     paste-a-list variant; the paste-a-list won by a wide margin in my own
     testing (n=1, so treat that as a hint, not evidence).

  The ADR correction is a supersede-or-amend decision. I'd amend — same
  decision, clarified detail."
```

**User:** "Amend the ADR. And show me both pickers."

> **What to notice:** the prototype produced a concrete correction to an Accepted
> ADR. The builder proposed the governance path (amend, don't silently diverge).

---

## Turn 3 — `/prototype-review`

```
User: /prototype-review apps/discount-bundles/prototype

ux-lead: "Reviewing against the research wedge and the UX specs — not against
          the eventual product.

  PASS  — cart expansion provable end-to-end on a dev store
  PASS  — broken-bundle state: 'Component "Blue tee / L" was deleted. Remove it
          or replace it.' Merchant can act without reading docs.
  CONCERN — picker: paste-a-list beats search. That contradicts
          design/ux/bundle-editor.md, which specs a search picker.
  CONCERN — no empty state; a fresh install shows a blank list with no CTA.

  On the picker: the prototype is right and the spec is wrong. A merchant
  building a 30-SKU bundle has the SKUs in a spreadsheet. Rewriting the spec is
  cheaper now than after implementation.

  Recommendation: update the UX spec, keep both entry points (paste + search),
  and re-review."

product-director: "One question before we accept any of that — does the wedge
                   survive? The wedge is component-accurate inventory, and it
                   does. Scope is not at risk; the picker is a UI change, not a
                   feature change.

                   I'm fine with CONCERNS here."
```

---

## Turn 4 — `/gate-check gate-2-prototype`

```
User: /gate-check gate-2-prototype

producer: "Gate 2 — prototype, for discount-bundles.

  Prototype on dev store ......... present, expandable cart demonstrated
  Prototype review report ........ present, verdict CONCERNS
  Architecture (2 ADRs) .......... Accepted
  Control manifest ............... present, version 2026-10-29
  UX spec drift .................. 1 known (picker), fix identified

  Verdict: CONCERNS — passable. The known concern is a spec update, not an open
  product question.

  Two things worth saying plainly:
  - Gate verdicts are advisory in this pipeline. Nothing is hard-blocked; you
    decide. But the record is what /project-stage-detect and /help will read.
  - Recording the gate in apps/discount-bundles/approvals.json is a separate,
    explicit step. An unrecorded gate is not an approved gate.

  [A] record gate-2-prototype, update the UX spec, then /scope-check
  [B] record gate-2-prototype and go straight to /scope-check
  [C] don't record yet"
```

**User:** "A."

```
producer: "Recorded gate-2-prototype with approver product-director and today's
           timestamp. UX spec updated. Stage in docs/registry/apps.json moves
           from `research` to `scope` in the same change — one file, one edit,
           append-only elsewhere."
```

---

## Turn 5 — `/scope-check` right after the gate

```
User: /scope-check discount-bundles

producer: "Scope check against request.md and the research brief:

  IN SCOPE, traced to requirements
  - fixed-price and percentage-off bundles .... REQ-BUNDLE-004
  - component-level inventory ................ REQ-BUNDLE-003
  - variant picker (paste + search) .......... REQ-BUNDLE-001
  - broken-bundle state ...................... REQ-BUNDLE-006

  NOT YET TRACED
  - theme app extension block ................ REQ-BUNDLE-005 exists, no ADR
                                                covers rendering — gap
  - plan-gated bundle count .................. no requirement, no ADR

  OUT OF SCOPE, and stays out
  - subscription bundles, bundle analytics, B2B price lists
    (killed in research; the brief names them)

  Recommendation: leave the theme block as a known gap for now — the app works
  without it, and ADR-0002 already covers what it renders. Do NOT start on
  plan gating; it has no requirement yet, and untraced work becomes scope creep
  with a story attached.

  Next: /create-epics discount-bundles, covering the four traced requirements
  only."
```

**User:** "Agreed. Epics next."

---

## What this example demonstrates

- **The prototype answers questions, in priority order.** The platform question
  came before the UX question because it could invalidate everything else.
- **A prototype finding corrected an Accepted ADR** through the documented route
  (amend), not by drifting.
- **The review judged the prototype, not the product.** "This is a fix, not a
  product question" is the distinction that makes CONCERNS passable.
- **The gate is recorded explicitly.** Claims without an `approvals.json` entry
  are treated as unapproved by `/project-stage-detect`.
- **`/scope-check` names gaps without filling them.** Untraced work is flagged,
  not quietly scheduled.
