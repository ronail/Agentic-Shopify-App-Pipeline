# Session: Deciding How a Bundle Becomes One Cart Line

**Skill:** `/architecture-decision` (then `/create-control-manifest`)
**Agents:** `app-architect` (author), `checkout-specialist`, `api-lead`, `technical-director`
**Duration:** ~45 minutes
**Complexity:** High

`discount-bundles` has a bundle editor and a data model, but nothing decides what
a buyer sees in the cart. Three viable approaches exist, each with a different
failure mode.

---

## Turn 1 — the question

```
User: /architecture-decision "how bundles appear in the cart"

app-architect: "Before I write anything, let me confirm the shape of the problem.

               A bundle is a set of variants sold for one price. Shopify has no
               native bundle line. The three options I would consider:

               **A. Cart transform function (expand)**
               One bundle product; the function expands the line into components.
               - ✅ component inventory and per-component fulfilment are real
               - ✅ one line, one price, shown before any code is entered
               - ❌ a function deployment in every release; sandbox limits
               - Knowledge risk: HIGH — function input/output shape moves

               **B. Duplicated product with derived inventory**
               A synthetic bundle variant; quantity tracked as min(components).
               - ✅ no function, works anywhere
               - ❌ inventory is a fiction when components sell independently
               - ❌ fulfilment has to be split by hand

               **C. Discount code over the components**
               Buyer adds N products; a code applies the bundle price.
               - ✅ Discount API only, no deployment
               - ❌ cart total is wrong before the code is entered
               - ❌ collides with the merchant's own codes

               I recommend A. The merchant's reason to install is
               component-accurate inventory, and B cannot provide it.

               Two things I need from you before the ADR:
               1. Fixed price only, or fixed price plus percentage-off?
               2. Is a bundle allowed to contain another bundle?"
```

**User:** "Both pricing modes. No nested bundles."

---

## Turn 2 — reading the constraints first

```
app-architect: [reads apps/discount-bundles/docs/research.md,
                apps/discount-bundles/design/ux/bundle-editor.md,
                docs/shopify-api-reference/2026-10/admin-graphql.md,
                docs/registry/architecture.yaml]

               "Two constraints I found before drafting:

               - `docs/registry/architecture.yaml` already pins the API version
                 stance via shared/ADR-0001. This ADR must depend on it, not
                 restate it.
               - The research brief promises component-level inventory, which
                 eliminates B on its own.

               Also flagging a scope question: the function needs a config blob
               at cart time. Somebody has to write that blob. That is a second
               decision — catalogue reconciliation — and I'd keep it in ADR-0002
               rather than growing this one."
```

> **What to notice:** the agent reads the registry before authoring so it cannot
> contradict an accepted stance, and it splits a decision instead of letting one
> ADR sprawl.

---

## Turn 3 — the draft

```
app-architect: "Draft of ADR-0001-bundle-cart-transform.md. Sections:

  Status: Accepted (after your approval)
  Summary: one line expands into its component lines via a cart transform
           function; fixed-price modes allocate the total across components.

  Shopify API Surface
    Admin API version    2026-10
    Surface              Admin GraphQL (cartTransformCreate), cart transform
                         function, storefront cart
    Knowledge risk       HIGH — verify input shape against the snapshot
    Verification         real cart on the dev store: 1 line → N lines,
                         fixed price sums exactly, inventory per component

  Decision
    1. one bundle product per definition, price mirrors the bundle price
    2. function `expand`, reads $app:bundle/config metafield
    3. fixed price allocated proportionally, integer minor units, remainder on
       the last component
    4. any component unavailable → return cart unchanged; the admin disables
       the bundle instead of relying on a checkout error

  App Requirements Addressed
    REQ-BUNDLE-003, REQ-BUNDLE-004, REQ-BUNDLE-007, REQ-BUNDLE-009

  Alternatives: B and C above, with rejection reasons.

  One open question: REQ-BUNDLE-009 says 'under the 5 ms platform budget'. Do
  you want that as a hard acceptance criterion, or a measured target with a
  warning?"
```

**User:** "Acceptance criterion. I'd rather find out in review than in production."

```
app-architect: "Agreed. Hard criterion, with a 10-component fixture as the
               measurement.

               Review gates before writing, unless you use solo mode:
               - checkout-specialist: does the function input/output approach
                 hold at checkout?
               - api-lead: is cartTransformCreate idempotent as we use it?
               - technical-director: is this buildable and reversible?

               Run all three, or lean?"
```

**User:** "All three."

---

## Turn 4 — review findings

```
checkout-specialist: "APPROVE with one correction. Section 3 says 'return the
                      cart unchanged' when a component is unavailable. Be
                      explicit that this is not an error path — the function must
                      never throw, because a thrown error surfaces as a broken
                      checkout, not a broken bundle."

api-lead: "CONCERNS. `cartTransformCreate` is not idempotent. The ADR must say:
           check existing transforms on install and create only if absent,
           otherwise every install adds another transform and the cart expands
           twice. That check belongs in Implementation Guidelines."

technical-director: "APPROVE pending the two fixes. Rollback via
                     cartTransformDelete is fine and leaves a clear merchant-
                     facing state; document that state so support can explain it."
```

```
app-architect: "Updated:
               - 'do not throw; return the cart unchanged' added to Decision and
                 to Implementation Guidelines
               - install-time idempotency check added, with the failure mode
                 (double expansion) named
               - rollback section now states carts revert to selling the bundle
                 product at its own price

               May I write docs/architecture/apps/discount-bundles/
               ADR-0001-bundle-cart-transform.md, and append the stance to
               docs/registry/architecture.yaml?"
```

**User:** "Yes."

> **What to notice:** the director review produced two concrete corrections that
> would otherwise have shipped as bugs — a throwing function and a duplicated
> cart transform. Neither was visible in the draft's prose.

---

## Turn 5 — `ADR-0002` is opened, not merged in

```
app-architect: "ADR-0001 is Accepted. It assumes a metafield that nothing writes.

               That is ADR-0002: catalogue reconciliation. Scope:
               - products/* webhooks → idempotent sync_job → reconcile pass
               - a deleted component disables the bundle (REQ-BUNDLE-006)
               - shop/redact hard-deletes (REQ-BUNDLE-008)

               Shall I draft it now, or wait until the function is proven on a
               dev store?"
```

**User:** "Now — I want the metafield contract fixed before anyone writes the function."

---

## Turn 6 — `/create-control-manifest discount-bundles`

```
User: /create-control-manifest discount-bundles

technical-director: "Loaded 2 Accepted ADRs, app discount-bundles, API 2026-10.
                     Rules extracted:
                       Admin UI            4 required, 3 forbidden, 3 guardrails
                       App server          4 required, 4 forbidden, 3 guardrails
                       Webhooks            4 required, 3 forbidden, 3 guardrails
                       Theme extensions    3 required, 3 forbidden, 2 guardrails
                       Checkout extensions 3 required, 3 forbidden, 2 guardrails
                       Data                4 required, 3 forbidden, 3 guardrails

                     Two rules worth your attention because they came from
                     rejected alternatives:
                     - Forbidden: draft orders / script tags / cart mutation for
                       bundles (from ADR-0001 Alternative B and C)
                     - Forbidden: floating-point money (from the allocation
                       section; a float total drifts by a cent)

                     Manifest Version will be 2026-10-29. Stories embed it, and
                     /story-readiness refuses a story whose embedded version is
                     older.

                     [A] write it  [B] show the full draft  [C] adjust rules"
```

**User:** "B."

...draft shown, one rule reworded, then:

```
technical-director: "Writing docs/architecture/apps/discount-bundles/
                     control-manifest.md.

                     Next: /architecture-review discount-bundles to check
                     requirement coverage — REQ-BUNDLE-001 and 002 are owned by
                     ADR-0002, so run it after that ADR lands."
```

---

## What this example demonstrates

- **One decision per ADR.** The metafield writer became ADR-0002 instead of a
  section in ADR-0001.
- **The registry is read before authoring**, so the API-version stance is a
  dependency, not a duplicated opinion.
- **Knowledge risk drove verification.** A HIGH rating forced a real cart test on
  a dev store rather than a unit test against a mock.
- **Rejected alternatives became Forbidden rules.** The control manifest carries
  the reasoning forward to whoever writes the code.
- **Requirement IDs are cited, not invented.** Every entry came from
  `requirements.yaml`.
