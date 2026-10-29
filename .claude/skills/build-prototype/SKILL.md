---
name: build-prototype
description: "Builds a throwaway merchant-facing prototype for a Shopify app under apps/<app>/prototype/, with real Polaris-styled admin screens and the intended workflow, so the flow can be judged before any production build. Use after gate-1-research, before gate-2-prototype."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Build Prototype — Throwaway, Merchant-Facing

## Purpose

A merchant cannot react to an architecture document. They can react to a screen
that shows their own products and a button that would do the thing. This skill
produces that screen: a low-cost, disposable prototype in
`apps/<app>/prototype/` that demonstrates the workflow end to end and is
explicitly allowed to be thrown away.

**The prototype is not the app.** Nothing in `apps/<app>/prototype/` is promoted
into the production build. If a prototype file starts feeling reusable, that is
a signal the flow is settled — not a reason to keep the code.

## When to use

- `gate-1-research` is approved and `gate-2-prototype` has not run.
- A flow is contested and needs to be shown, not argued.
- An update's UX needs a merchant reaction before it is scoped.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `apps/<app>/README.md` | yes | Purpose and current gate |
| `production/research/<app>/recommendation.md` | yes | The problem the flow must solve |
| `production/apps/<app>/mmmvp-proposals.md` | optional | Which slice the prototype demonstrates |
| `docs/shopify-api-reference/` | yes | Real field names, real limits, real errors |
| `apps/<app>/prototype/` | yes | Created by `/scaffold`; the only write target |

## Steps

1. **Confirm the shell exists.** `apps/<app>/prototype/` must already be there
   from `/scaffold`. If it is missing, stop and say so — do not create app
   directories from here.
2. **Write the flow script first.** Numbered steps of what the merchant does and
   what they see, in their language: "opens the app, sees a list of products with
   no bundle, clicks Create bundle, picks products, sees the price the shopper
   will see". Then build exactly that. Anything not in the script does not get
   built.
3. **Build the screens** as static or lightly scripted pages under
   `apps/<app>/prototype/` — an entry page, the main list, the create/edit form,
   and the confirmation state. Match the Shopify admin visual language: admin
   layout, page header with primary action, an index table, a card for the form.
   Copy, spacing and empty states matter more than interactivity.
4. **Use real data shapes.** Field names, limits and error text come from
   `docs/shopify-api-reference/`. A prototype that shows a field the API does not
   have teaches the reviewer the wrong thing.
5. **Include the ugly states** — empty, loading, error, and the permission-denied
   case. Prototypes that only show the happy path get approved and then surprise
   everyone in build.
6. **Add a `README.md` inside the prototype folder** with: how to open it, the
   flow script, what is faked versus real, and one line reading "throwaway — not
   to be promoted into the app".
7. **Verify it opens.** Run it locally (a static server or a direct file open)
   and confirm every screen in the flow script renders without a console error.
   Report the command you used.
8. **Hand off** to `/prototype-review <app>` — do not ask for gate approval
   yourself.

## Outputs

Under `apps/<app>/prototype/`:

- `index.html` (entry) plus one file per screen
- `styles.css` if shared
- `README.md` — flow script, what is faked, how to open

## Ownership

Owned by **prototype-builder**. `ux-lead` reviews the result against the request
in `/prototype-review`; `polaris-specialist` is consulted on admin look and
component choice; `product-director` owns the `gate-2-prototype` decision.

## Rules

- **Throwaway by contract.** No prototype code enters the app source, ever.
- **Flow before pixels.** A beautiful screen for the wrong flow is a wasted
  review.
- **No production credentials.** The prototype runs on fixtures. If it needs a
  real store, that is `/create-test-store`, and the prototype still uses fake
  data.
- **Scope guard.** If the demo needs a capability outside the approved slice,
  stop and raise it — do not quietly expand the flow.
