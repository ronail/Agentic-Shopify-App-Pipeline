# Session: Research to Scaffold for `discount-bundles`

**Skills:** `/research` → `/ux-design` → `/ux-review` → `/gate-check gate-1-research` → `/scaffold`
**Agents:** `research-specialist`, `ux-lead`, `polaris-specialist`, `devops-engineer`
**Duration:** ~90 minutes across two sessions
**Complexity:** Medium

A solo founder has written `request.md` with two apps in scope and wants to know
whether `discount-bundles` is worth building. The session does not start with a
plan; it starts with a question about the merchant.

---

## Turn 1 — `/start`

```
User: /start

producer: "Two apps in the registry, both at stage `research`, both with
           gate-1-research recorded as approved on 2026-10-29.

           discount-bundles — research says approved, but I don't see a
           research brief or a single UX spec on disk. That's a claim ahead of
           evidence.

           I'd start with `/research discount-bundles`. Do you want me to
           re-run research properly, or is there a brief somewhere I'm missing?"
```

> **What to notice:** `/start` reads `docs/registry/apps.json`, each app's
> `status.md`, and `approvals.json`, and reports the mismatch instead of
> trusting the registry.

---

## Turn 2 — `/research discount-bundles`

```
User: Research it properly. The bundles idea came from my own store — I sell
      3-packs and the workaround is painful.

research-specialist: "Good, that's a real starting point. Four questions before
                     I scan anything:

                     1. What does the workaround cost you today — duplicated
                        products, discount codes, or manual edits?
                     2. Who else has this problem: solo merchants, SMB, or Plus?
                     3. Which bundle shapes matter: fixed sets, mix-and-match,
                        or buy-X-get-Y?
                     4. Are you willing to ship a cart transform function, or
                        does the app have to work without one?

                     Answers change whether this is a $19/mo utility or a
                     $99/mo merchandising tool."
```

**User:** duplicated products; SMB; fixed sets and mix-and-match; function OK.

```
research-specialist: "Running Original or Competitor-Killer. The distinction
                     matters: if two well-reviewed apps already do fixed sets,
                     the wedge has to be somewhere else — mix-and-match pricing,
                     or component-level inventory.

                     Scanning the App Store for 'bundle' and 'product bundle',
                     plus Shopify changelog for cart transform support."
```

---

## Turn 3 — Findings

```
research-specialist: "Findings, in order of how much they change the plan:

  COMPETITOR MAP (4 apps with >100 reviews)
  - Two are 'duplicate the product' apps. Their reviews are full of the exact
    complaint you have: inventory desyncs when a component sells out.
  - One is fixed-sets only via cart transform, priced at $19–$49/mo.
  - One does mix-and-match but only with draft orders; slow checkout, and its
    recent reviews are about checkout errors.

  WEDGE (three candidates)
  A. Component-accurate inventory for fixed sets — table stakes, competitors
     are vulnerable here, but it is a fix, not a product.
  B. Mix-and-match bundles with fixed total price and per-component allocation —
     nobody does this well; hardest to build.
  C. "Bundle once, sell everywhere" — one config drives product page block and
     cart. Cheap to build, weak differentiation.

  I'd take A as the entry point and B as the retention hook. C is a feature,
  not a wedge.

  Which framing do you want the brief to defend?"
```

**User:** "A then B."

```
research-specialist: "Taking A as the wedge, B as the moat. Writing
                     apps/discount-bundles/docs/research.md with:
                     merchant job, competitor map, wedge, three killed features
                     (subscription bundles, bundle analytics, B2B price lists),
                     and the pricing hypothesis.

                     May I write that file?"
```

**User:** "Yes."

> **What to notice:** the research ends in a decision with a named trade-off, not
> a feature list. Three features are explicitly killed so scope has something to
> point at later.

---

## Turn 4 — `/ux-design`

```
User: /ux-design

ux-lead: "Three screens carry this app: the bundle list, the bundle editor, and
         the 'bundle is broken' state. Before I spec them:

         1. Does the merchant create a bundle from a product page, or from the
            app's own list? (Product page = discoverable; app list = faster.)
         2. 50 variants in one bundle — one picker with search, or a table you
            paste into?
         3. When a component is deleted, does the bundle page explain the fix,
            or just show an error?

         For (3) I would always explain the fix — this is the state merchants
         hit at 2am on Black Friday."
```

**User:** app list; picker with search; explain the fix.

```
ux-lead: "Drafting three specs under apps/discount-bundles/design/ux/:
         bundles-list.md, bundle-editor.md, bundle-broken-state.md.

         Each covers states (loading, empty, error, no-permission), Polaris
         components, keyboard path, and the copy for the broken state.
         May I write all three, or do you want to review the editor first?"
```

**User:** "Review the editor first."

> **What to notice:** the agent offers a write strategy instead of dumping three
> files. `gate-1-research` requires at least three UX specs, so the ordering is
> visible in the workflow catalog.

---

## Turn 5 — `/gate-check gate-1-research`

```
User: /gate-check gate-1-research

producer: "Gate 1 — research, for discount-bundles.

  Research brief ......... present (apps/discount-bundles/docs/research.md)
  UX specs ............... 3 present (list, editor, broken state)
  UX review .............. no report
  Approval record ........ gate-1-research entry exists, timestamped
                           2026-10-29T00:00:00Z, approver product-director

  Verdict: CONCERNS — the approval is recorded but /ux-review has never run,
  so the specs have had no accessibility or Polaris pass. CONCERNS is
  passable; your call.

  [A] run /ux-review, then re-gate
  [B] accept CONCERNS and move to /scaffold
  [C] stop here"
```

**User:** "A."

After `/ux-review` raises one BLOCKING gap (the variant picker has no keyboard
alternative) and it is fixed:

```
producer: "Gate 1 re-run: PASS. Gate verdicts are advisory — nothing is
           hard-blocked — but the record now matches the evidence.
           Next: /scaffold discount-bundles."
```

---

## Turn 6 — `/scaffold discount-bundles`

```
User: /scaffold discount-bundles

devops-engineer: "Scaffolding creates a real app, so here is exactly what
                  changes before I touch anything:

                  apps/discount-bundles/
                    package.json, tsconfig.json, vite/vitest config
                    shopify.app.toml        api_version = 2026-10
                                            scopes = read_products, write_products
                    app/                    embedded admin routes (Polaris, App Bridge)
                    app/routes/webhooks.*.ts
                    db/migrations/
                    extensions/             theme app extension + cart transform
                    tests/

                  Also: apps/discount-bundles/README.md gets the run command,
                  and docs/registry/apps.json keeps stage `research` until
                  gate-2 passes — I will not bump it.

                  Two choices:
                  [A] scaffold minimal (list + editor routes only)
                  [B] scaffold with the cart transform function stub included

                  B costs 20 more minutes and proves the function deploys early.
                  I recommend B — the function is the highest-risk piece."
```

**User:** "B."

```
devops-engineer: "Writing to apps/discount-bundles/. After it lands:
                  - `shopify app dev` boots it on the dev store
                  - the function stub deploys and registers
                  - `npm test` runs one smoke test against the health route

                  May I write the tree?"
```

**User:** "Yes."

```
devops-engineer: "Scaffolded. Verified: dev server boots, app loads embedded in
                  the dev store, function deploys.

                  Next: /create-architecture for discount-bundles — the app
                  now exists, so the architecture document has something to
                  describe."
```

---

## What this example demonstrates

- **Gates read evidence, not claims.** `/start` and `/gate-check` both reported
  "approval recorded, no artefacts", and gate 1 was re-run rather than trusted.
- **Research ends in a wedge and three killed features.** Scope conversations
  later have something concrete to reference.
- **UX specs come before scaffolding** because the gate requires them, and the
  accessibility gap was cheaper to fix in a spec than in a component.
- **The scaffold list is shown before writing**, including what it will *not*
  change (the registry stage).
