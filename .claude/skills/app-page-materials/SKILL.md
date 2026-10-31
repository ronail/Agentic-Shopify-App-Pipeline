---
name: app-page-materials
description: "Author the Shopify App Store listing page materials for an app: identity, listing copy, screenshots, app icon, promotional video, pricing presentation, permissions and scopes, and data-handling disclosure. Produces a completed app-store-listing.md that the /app-store-checklist gate verifies before /release."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for `/app-page-materials`.
> Do not auto-invoke it from context matching.

## Phase 1: Parse Arguments

- `app` — the slug from `docs/registry/apps.json`; default to the app named in
  `request.md` or the most recently modified `production/apps/<app>/session-state/active.md`

---

## Phase 2: Gather Context

Read the sources that define what the listing must promise:

- `apps/<app>/README.md` — the merchant value proposition this listing must match
- `apps/<app>/shopify.app.toml` — pinned `api_version`, `access_scopes`, webhook
  subscriptions, pricing configuration
- `docs/architecture/apps/<app>/requirements.yaml` — requirement IDs backing each
  claim in the listing
- `docs/architecture/apps/<app>/control-manifest.md` — what data is stored and
  how each surface behaves
- `production/apps/<app>/release-checklist-<version>.md` — must be READY (run
  `/release-checklist` first); listing assets and screenshots are verified here
- `docs/architecture/apps/<app>/ADR-*.md` — API surface, billing model, data
  handling decisions the listing must disclose
- `.claude/docs/templates/app-store-listing.md` — the listing template to fill in

If `release-checklist` is not READY, stop. Verdict: **BLOCKED** — the listing
must describe behaviour that is already signed off, not promise untested paths.

---

## Phase 3: Author the Listing

Follow the template `.claude/docs/templates/app-store-listing.md` and fill in
every blank. The materials fall into three groups:

### 3.1 Identity & Copy

| Field | Source |
|-------|--------|
| App name | `apps/<app>/README.md` (must match the Partner dashboard) |
| Tagline | One line: what it does for whom |
| Short description | 1-2 sentences, merchant outcome |
| Long description | The problem, what the app does, who it is for, what makes it different, pricing |
| Feature bullets | Benefit-first, verb-led; each tied to a requirement ID |

### 3.2 Media

- **App icon** — 1024×1024, no text, no borders (Shopify crops to a circle)
- **Screenshots** — minimum three, showing real UI with realistic data:
  1. The core payoff screen
  2. A workflow step (onboarding, a key action, a result)
  3. Settings or configuration
- **Promotional video** (optional) — ≤60s, captioned, hosted on a stable URL

**Screenshot rule**: every screenshot shows a real screen a merchant will reach,
with realistic data and no feature the app doesn't have.

### 3.3 Pricing & Compliance

- **Pricing table** — every plan must match `shopify.app.toml` billing config and
  `pricing-plan.md`
- **Permissions & Scopes** — every `access_scopes` entry gets a line: the scope,
  the listing-facing wording for why it's needed, and the requirement ID that
  consumes it
- **Data Handling Disclosure** — what is stored, where, retention after uninstall,
  protected customer data declared, and any third parties receiving data
- **Review Notes** — credentials for the demo store, feature flags to enable,
  any unusual install or permission requirement

---

## Phase 4: Write

Fill the template fields and write the completed listing to:

```
production/apps/<app>/app-store-listing.md
```

Add a header line with the verdict so `/help` can detect completion:

```markdown
## Submission Record
Verdict: complete
```

Then verify:
- Every scope in `shopify.app.toml` appears in the listing's Permissions & Scopes table
- Every plan in the pricing table matches the billing configuration
- Every screenshot caption names a screen a merchant actually reaches
- No claim in the listing that the app does not (or does not yet) do

Ask: "May I write this to `production/apps/<app>/app-store-listing.md`?"
Write on approval, creating the directory if needed.

---

## Ownership

Owned by **app-store-reviewer** — listing copy, visual assets, and App Store
policy alignment. Signs off with input from:

- `growth-lead` — pricing presentation and plan tiers
- `api-lead` — scope justification against the pinned API version
- `security-specialist` — data handling disclosure
- `ux-lead` — screenshot fidelity and the install→value path

---

## Rules

- **The listing must describe what the app ships today.** A feature in the listing
  that is not in `shopify.app.toml` or the built code is a misrepresentation.
- **Screenshots show real data.** No mock dashboards, no placeholder values that
  mislead a reviewer about what the app does.
- **Scope wording must be merchant-readable.** "Access your products" not
  "Read products."
- **Price must match.** The listing price table must match the billing
  configuration exactly; a mismatch is an automatic rejection.

---

## Next Steps

- `/app-store-checklist [app]` — the verification gate that checks this listing
  against App Store requirements (every line must PASS before gate-4-release)
- `/release [app] [version]` — files the listing with the App Store submission
- `/deploy-to-test-store [app]` — if any listing claim cannot be reproduced on a
  clean dev store

---

Template: `.claude/docs/templates/app-store-listing.md`
