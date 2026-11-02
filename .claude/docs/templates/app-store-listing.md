# App Store Listing: [App Name]

> **App**: `apps/<app>` · **Partner app**: [name/id] · **Gate**: gate-4-release
> **Authored by**: `/app-page-materials` → `production/apps/<app>/app-store-listing.md`
> **Verified by**: `/app-store-checklist` → `production/apps/<app>/app-store-checklist.md`

## Identity

| Field | Value | Checked |
|-------|-------|---------|
| App name | [≤30 chars, no Shopify trademark misuse] | [ ] |
| Tagline | [One line: what it does for whom] | [ ] |
| Categories | [Primary + secondary from the allowed list] | [ ] |
| Languages | [Listing languages] | [ ] |
| Support email | [address that a human monitors] | [ ] |
| Support URL | [help centre or docs] | [ ] |
| Privacy policy URL | [URL — must load without login] | [ ] |
| Demo store URL | [working demo, no install required] | [ ] |

## Listing Copy

### Short description
[1-2 sentences. Merchant outcome, not feature list.]

### Long description
[3-5 short paragraphs or a bulleted benefit list: the problem, what the app does,
who it is for, what makes it different, what it costs. Name concrete Shopify
surfaces ("works on orders, products and inventory in your admin").]

### Feature bullets
- [Benefit — verb first]
- [Benefit]
- [Benefit]

## Media

Media are separate materials with separate specs. A screenshot cannot stand in
for a video, and the review screencast is not the public promo video — generate
and verify each one independently.

### App icon

| Requirement | Status | Notes |
|-------------|--------|-------|
| 1200×1200 JPEG or PNG, square with padding (Shopify rounds the corners), no text, no screenshots, no Shopify trademarks | [ ] | |

### Screenshots (static, 3–6 images)

| # | Screen shown | Status | Notes |
|---|--------------|--------|-------|
| 1 | [Core payoff screen] | [ ] | 1600×900 (16:9) |
| 2 | [A workflow step] | [ ] | Unique image, not a variant of #1 |
| 3 | [Settings / configuration] | [ ] | |
| 4–6 | [Optional additional views] | [ ] | Only if they add information |

**Screenshot rule**: 3–6 unique 1600×900 (16:9) images, at least one showing real
merchant UI; no browser chrome, no PII, no pricing, no Shopify logos. Every image
shows a real screen a merchant reaches, with realistic data.

### Promo / feature video (public listing)

| Requirement | Status | Notes |
|-------------|--------|-------|
| 2–3 min, promotional rather than instructional, screencasts ≤25%, captioned | [ ] | |
| Hosted on a stable URL | [ ] | |

### Feature image (static alternative — only if there is no video)

| Requirement | Status | Notes |
|-------------|--------|-------|
| 1600×900 (16:9), one focal point, alt text supplied | [ ] | Not a screenshot; conveys the benefit |

### Demo screencast (required for review)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Step-by-step install → onboarding → primary action | [ ] | Referenced from Review Notes, not the public listing |
| English audio or English subtitles | [ ] | Required by App Review |

## Pricing Presentation

| Plan | Price | Trial | Listing text |
|------|-------|-------|--------------|
| [Free] | $0 | — | [What it includes] |
| [Growth] | $X/mo | [N days] | [What it includes] |
| [Pro] | $Y/mo | [N days] | [What it includes] |

Must match the plans configured in the Partner dashboard and billing code
(`pricing-plan.md`).

## Permissions & Scopes

| Scope | Why the app needs it (listing-facing wording) | Used by |
|-------|-----------------------------------------------|---------|
| `read_orders` | [Read order data to build the sync report] | [FR-1] |

**Rule**: no scope is listed that no requirement uses; the reviewer will ask.

## Data Handling Disclosure

- **Data stored**: [list]
- **Where stored**: [region/provider]
- **Retention after uninstall**: [N days]
- **Protected customer data**: [declared / not requested — and why]
- **Third parties receiving data**: [none / list with purpose]

## Review Notes For Shopify

[Anything a reviewer needs to test: test credentials for the demo store,
feature flags to enable, why a scope is needed, known limitations. Reviewers read
this — make it operationally useful, not marketing.]

## Compliance Checklist

- [ ] No unsupported claims ("#1 app", guaranteed results)
- [ ] No Shopify logos used as the app's own branding
- [ ] Install → value path works without contacting support
- [ ] Uninstall cleanly revokes access and stops charges
- [ ] Billing disclosure visible before the charge
- [ ] Screenshots match the shipped UI
- [ ] Screenshots and video are distinct materials, not reused for each other
- [ ] No pricing rendered inside the icon, screenshots, or video
- [ ] Demo screencast recorded and referenced from Review Notes
- [ ] Support link monitored (response within [N] hours)

## Submission Record

| Attempt | Date | Outcome | Reviewer feedback | Fix |
|---------|------|---------|-------------------|-----|
| 1 | [Date] | [Approved / Rejected] | [Reason] | [Change made] |
