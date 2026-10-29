# QA Plan: [Sprint/Feature Name]

> **App**: `apps/<app>` · **API version**: [YYYY-MM] · **Dev store**: [handle]
> **Sprint**: [N] · **Gate**: [gate id this plan supports]

## Story Coverage Summary

| Story | Type | Automated | Manual | Owner | Status |
|-------|------|-----------|--------|-------|--------|
| [Story title] | [Logic / Integration / UI] | [Unit / Integration / None] | [Checklist ref] | [qa-tester] | [Planned / In progress / Passed] |

## Automated Tests Required

### [Story Title] — Logic

- [ ] [Pure function or mapper under test — e.g. order → sync record]
- [ ] [Edge case — e.g. order with a null customer]
- [ ] [Rate-limit budget calculation]

### [Story Title] — Integration

- [ ] [GraphQL query/mutation executed against a dev store, response asserted]
- [ ] [Webhook handler: valid HMAC → 200 and enqueued; invalid HMAC → 401]
- [ ] [Idempotency: duplicate webhook delivery produces one record]
- [ ] [Billing: subscription created, trial applied, cancellation downgrades]

## Manual QA Checklist

### [Story Title] — Admin UI

- [ ] Screen renders in Polaris with no layout breaks at 320px and 1440px
- [ ] All states from the UX spec visible (loading, empty, error, populated)
- [ ] Keyboard-only path completes the primary task
- [ ] Error banner appears for a forced GraphQL failure and is recoverable

### [Story Title] — Install / Onboarding

- [ ] Clean install on a fresh dev store completes OAuth with the exact scope set
- [ ] Re-install after uninstall preserves or cleanly resets merchant data per policy
- [ ] Merchant reaches first value without reading docs

## Smoke Test Scope

| Check | Command / Method | Pass Condition |
|-------|------------------|----------------|
| App boots | `shopify app dev` | No build errors, tunnel up |
| Auth | Load embedded app | Session token issued, no redirect loop |
| Core query | [query name] | 200 with expected shape |
| Webhook ingress | Trigger via CLI | Delivered, verified, processed |
| Billing | Plan page | Subscription record readable |

## Merchant Acceptance Requirements

[If this sprint touches a merchant-visible flow, one real (or stand-in) merchant
must attempt the flow unassisted. Record: who, what they tried, where they
hesitated, whether they completed it.]

- [ ] [Merchant/stand-in] completed [flow] without prompting
- [ ] Observations recorded in `production/apps/<app>/qa/`

## Definition of Done — This Sprint

- [ ] All stories have automated or documented manual coverage as listed above
- [ ] Smoke scope green on the dev store
- [ ] No S1/S2 defects open in delivered features
- [ ] Evidence recorded via `test-evidence.md` for each UI story
- [ ] Test gaps named explicitly (deferred + reason + ticket)
