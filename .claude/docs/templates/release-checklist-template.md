# Release Checklist: [Version] -- [Distribution: App Store | Unlisted | Backend]

> **App**: `apps/<app>` · **API version**: [YYYY-MM] · **Gate**: gate-4-release
> **Approver recorded in** `apps/<app>/approvals.json` before this checklist runs.

## Build Verification

- [ ] `npm run build` (or repo equivalent) passes clean
- [ ] `shopify app deploy` succeeds; extension versions published
- [ ] Production secrets set in the hosting environment (not committed)
- [ ] `SHOPIFY_API_KEY` / `SHOPIFY_API_SECRET` match the production Partner app
- [ ] App URL and allowed redirect URLs match production exactly
- [ ] Database migrations applied and reversible
- [ ] Version tag created; changelog entry written

## Quality Gates

### Critical Bugs

- [ ] Zero open S1 defects
- [ ] Zero open S2 defects in shipped features
- [ ] Known issues documented in release notes

### Test Coverage

- [ ] Unit tests green in CI
- [ ] Integration tests green against a dev store on the pinned API version
- [ ] Manual QA plan executed with evidence attached
- [ ] Regression suite green (`/regression-suite`)

### Performance

- [ ] Admin page p95 under budget on a 50k-order store
- [ ] Webhook processing lag under budget at peak
- [ ] GraphQL cost per request within limits; no retry storms observed
- [ ] Bulk/backfill paths throttled and resumable

## Content Complete

- [ ] All merchant-facing strings translated (or fallback verified)
- [ ] In-app help / docs links resolve
- [ ] Onboarding copy reviewed by a non-author
- [ ] Support email and help-centre URL set in the Partner dashboard
- [ ] Pricing page copy matches the plans configured in billing

## Platform: Embedded Admin App

- [ ] Session token auth works from a cold load and after long idle
- [ ] App Bridge nav menu, title bar and back button behave
- [ ] Polaris components at supported versions; no deprecated props
- [ ] Works in the Shopify mobile admin
- [ ] Scope set is minimal and every scope is justified in the listing

## Platform: Extensions (Storefront / Checkout / POS, if applicable)

- [ ] Extension renders on a clean theme / POS device
- [ ] No console errors in the extension surface
- [ ] Checkout extension respects checkout UI extension limits
- [ ] Theme app extension blocks survive theme duplicate and publish

## Store and Distribution

- [ ] App Store listing complete (`app-store-listing.md`): name, tagline,
  screenshots, demo store, pricing, privacy policy, support links
- [ ] Required webhooks registered: `app/uninstalled`, `app_subscriptions/update`
- [ ] GDPR mandatory webhooks implemented and verified
- [ ] Protected customer data access justified and declared
- [ ] Billing plans created and testable in the dev store
- [ ] Uninstall path cleans up merchant data per the retention policy

## Launch Readiness

- [ ] Rollback plan written and rehearsed (previous version deployable)
- [ ] Monitoring/alerts live: error rate, webhook failures, install failures
- [ ] On-call owner named for the first 72 hours
- [ ] App review submitted (if listing changed) and merchant comms drafted
- [ ] Support macros prepared for anticipated questions

## Sign-offs

| Role | Name | Date | Approved |
|------|------|------|----------|
| QA lead | | | [ ] |
| App architect / lead engineer | | | [ ] |
| App Store reviewer | | | [ ] |
| Producer | | | [ ] |

## Final Decision

- [ ] **SHIP** — all gates green
- [ ] **SHIP WITH CONDITIONS** — conditions listed below and accepted by producer
- [ ] **HOLD** — blockers listed below

**Conditions / blockers**:
- [Blocker with owner and date]
