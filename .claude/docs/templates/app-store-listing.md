# App Store Listing: [App Name]

> **App**: `apps/<app>` · **Partner app**: [name/id] · **Gate**: gate-4-release
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

| Asset | Requirement | Status | Notes |
|-------|-------------|--------|-------|
| App icon | [1024×1024, no text] | [ ] | |
| Screenshot 1 | Real UI, no mock data that misleads | [ ] | Shows the core payoff screen |
| Screenshot 2 | Second workflow step | [ ] | |
| Screenshot 3 | Settings / configuration | [ ] | |
| Video (optional) | ≤60s, captioned | [ ] | |

**Screenshot rule**: every screenshot shows a real screen a merchant will reach,
with realistic data and no feature the app doesn't have.

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
- [ ] Support link monitored (response within [N] hours)

## Submission Record

| Attempt | Date | Outcome | Reviewer feedback | Fix |
|---------|------|---------|-------------------|-----|
| 1 | [Date] | [Approved / Rejected] | [Reason] | [Change made] |
