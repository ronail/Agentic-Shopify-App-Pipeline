# Session: Release and Submission

**Skills:** `/release-checklist` → `/app-store-checklist` → `/security-audit` → `/release` → `/changelog`
**Agents:** `release-manager`, `app-store-reviewer`, `security-specialist`, `community-manager`
**Duration:** ~90 minutes
**Complexity:** Medium-High

`discount-bundles` has passed `gate-3-scope` and its build stage is complete. This
session is the submission gate: everything claimed must be provable on a dev
store.

---

## Turn 1 — `/release-checklist`

```
User: /release-checklist discount-bundles

release-manager: "Walking the checklist against the repo, not against memory.

  Build & tests
  ✅ `npm test` — 87 passing, 0 skipped
  ✅ cart transform function builds and deploys
  ⚠️ No smoke test recorded for this version

  Architecture alignment
  ✅ ADR-0001, ADR-0002 Accepted; control manifest version 2026-10-29
  ✅ `docs/registry/architecture.yaml` lists both ADRs and the correct pin

  Compliance (mandatory for App Store)
  ✅ `shop/redact` implemented and tested
  ✅ `customers/data_request` implemented
  ❌ `customers/redact` handler returns 200 but has no test proving deletion
     — this is a submission blocker, not a note

  Scopes
  ✅ shopify.app.toml declares `read_products`, `write_products` only
  ⚠️ Listing copy must justify both; the current draft does not mention write

  Store readiness
  ❌ No smoke test on a fresh dev store install of this exact version
  ✅ Uninstall/reinstall within 30 days restores bundles (tested)

  Verdict: 2 blocking, 3 advisory.

  Recommended order: fix the customers/redact test (30 min), run the smoke test
  on a clean store (20 min), then rewrite the scope justification. The listing
  copy is the slow part — it depends on what the smoke test proves.

  [A] work the blockers now, in that order
  [B] show me the full checklist first
  [C] I'll fix them myself and come back"
```

**User:** "A."

> **What to notice:** a handler that *returns* 200 is not evidence that redaction
> works. The checklist distinguishes "implemented" from "proven".

---

## Turn 2 — `security-specialist` review

```
User: run a security audit before we submit

security-specialist: "Auditing against `.claude/rules/auth-code.md`,
                      `webhook-code.md`, and the control manifest's Forbidden
                      list.

  PASS — session tokens on every admin request; no cookie session anywhere
  PASS — webhook HMAC verified on the raw body, before JSON parse
  PASS — no Admin API call in a webhook handler path
  PASS — no secrets in logs; token access confined to the session module
  PASS — every query shop-scoped by session shop domain
  CONCERN — `shopify.app.toml` registers seven webhook topics; the boot
            assertion checks four. A topic dropped during a version bump would
            not fail at boot.
  CONCERN — the metafield writer takes a bundle id from the request body and
            queries by it without also filtering by shop. The repository layer
            does filter, but the route should not pass an unfiltered id at all.

  Neither is exploitable today. Both are one-line hardening changes and both
  protect against a future edit. Fix now, or log as tech debt?"
```

**User:** "Fix the boot assertion. Tech-debt the route argument with a note."

```
security-specialist: "Recorded. Tech-debt entry names the risk: 'route passes
                      bundle id before shop scoping — repository filters today,
                      a future direct query would not'."
```

---

## Turn 3 — `/app-store-checklist`

```
User: /app-store-checklist discount-bundles

app-store-reviewer: "Submission requirements, checked against the actual build:

  Listing
  ⚠️ Title/description: says "bundle discounts" — reviewers reject apps whose
     name implies a discount app when the mechanism is a cart transform. Reword
     to "product bundles" and describe the discount as a pricing mode.
  ❌ Scope justification missing for `write_products` — required, reviewers
     look for it explicitly.
  ✅ Screenshots: 4 required, 4 present, all from the current build
  ✅ Privacy policy URL present and matches the schema (no PII)

  Functionality
  ✅ App works immediately after install (no manual setup wall)
  ✅ No broken links, no "coming soon" surfaces
  ⚠️ Theme app extension is optional but the listing shows it enabled in the
     screenshots — either ship it enabled by default or reshoot

  Billing (if charging)
  ✅ Managed pricing configured; no external payment links anywhere

  My honest read: the listing copy is the risk, not the code. Reviewers spend
  minutes, not hours, and the first thing they check is whether the description
  matches what the app does.

  [A] rewrite the listing copy now with you
  [B] you rewrite, I re-review
  [C] submit as-is and accept the rejection risk"
```

**User:** "A."

```
app-store-reviewer: "Drafting, in three parts:

  Title:      Product Bundles — build and price bundle offers
  Subtitle:   Fixed-price and percentage-off bundles with real component
              inventory
  First para: what the merchant does in three steps (create, add components,
              publish) and what changes for the buyer (one line, one price)

  Also drafting the scope justification:
    read_products  — list and search the merchant's catalogue for components
    write_products — create the single bundle product each bundle sells as,
                     and keep its title and price aligned

  May I write these to apps/discount-bundles/docs/listing.md?"
```

**User:** "Yes."

---

## Turn 4 — `/release`

```
User: /release discount-bundles 1.0.0

release-manager: "Release 1.0.0. Pre-flight:

  Blockers from the checklist ......... 0 (redact test added, smoke passed)
  Security findings ................... 0 open, 1 tech-debt logged
  Version in package.json ............ 1.0.0 ✅
  CHANGELOG entry .................... missing — I'll write it as part of this
  Tag name ........................... discount-bundles-v1.0.0 (repo convention)

  What the release does:
  1. `shopify app deploy` — creates an app version with the function and
     extension bundles
  2. Tag the commit
  3. Record gate-4-release in approvals.json with approver and timestamp
  4. Submit for review (this step is yours, not mine — I will not submit
     without you saying so)

  May I run 1–3?"
```

**User:** "Run 1–3. I'll submit from the Partner Dashboard."

```
release-manager: "Deployed version 1.0.0 (function + theme extension bundled).
                  Tagged `discount-bundles-v1.0.0`.
                  Recorded gate-4-release, approver product-director,
                  2026-10-29T09:14:00Z.

                  One thing to watch after submission: the cart transform is a
                  new deployment, so merchant carts are exercising it for the
                  first time. /smoke-check a real cart within an hour of
                  approval — not the next morning."
```

---

## Turn 5 — `/changelog`

```
User: /changelog discount-bundles 1.0.0

community-manager: "Drafting merchant-facing notes. Each line traces to a
                    requirement, so support can answer 'why did this change?':

  1.0.0 — 2026-10-29
  - Create fixed-price and percentage-off bundles from the embedded admin.
    (REQ-BUNDLE-001, REQ-BUNDLE-004)
  - Bundles sell as one line at checkout while inventory is tracked per
    component. (REQ-BUNDLE-003)
  - If a component is deleted in your catalogue, the bundle is paused and the
    admin tells you which component to fix. (REQ-BUNDLE-006)
  - Uninstalling removes app data after 30 days; reinstalling within 30 days
    restores your bundles. (REQ-BUNDLE-002)

  I left out the transform internals — merchants do not care, and naming the
  mechanism invites support questions about Shopify's cart.

  May I write CHANGELOG.md and append to apps/discount-bundles/changelog.md?"
```

**User:** "Yes."

---

## What this example demonstrates

- **Release is evidence, not confidence.** Two blockers came from *missing
  proofs* (redact behaviour, smoke on a clean store), not from failing code.
- **Security findings were triaged by exploitability, not by severity label.**
  One fixed now, one logged with its concrete future risk.
- **The listing copy is treated as a submission risk.** Description that
  disagrees with the mechanism is the most common rejection reason for apps like
  this.
- **The agent does not submit.** Deploy, tag and record are reversible; submission
  is the human's call.
- **Changelog lines carry requirement IDs**, so support and the changelog skill
  can both trace a claim.
