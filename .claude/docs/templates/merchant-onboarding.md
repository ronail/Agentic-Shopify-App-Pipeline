# Merchant Onboarding: [App Name]

> **App**: `apps/<app>` · **Owner**: ux-lead + growth-lead
> **Produced at**: `/scaffold --app <app>` · **Verified before**: gate-4-release

## The First Five Minutes

| Minute | Merchant state | What they see | What we need them to do |
|--------|----------------|---------------|------------------------|
| 0:00 | Just clicked Install | OAuth consent with the exact scopes | Grant access |
| 0:20 | Installed, empty app | [First screen — not a blank dashboard] | [One decision, ≤3 inputs] |
| 1:00 | Configured | [First data appears] | Nothing — the app works |
| 3:00 | Saw the payoff | [The value moment] | Bookmark / enable notifications |
| 5:00 | Ready to return | [What brings them back tomorrow] | — |

**Rule**: the merchant must reach first value without reading documentation,
without contacting support, and without granting a scope that isn't used on that path.

## Install Path

| Step | Behaviour | Failure handling |
|------|-----------|------------------|
| Install click | OAuth with minimal scopes | Scope denial → explanatory screen, not a dead end |
| Grant | Verify HMAC, store offline token, create shop record | Token exchange failure → retry with message |
| Redirect | Land on the first-run screen, not a generic home | If existing data → land on the dashboard |
| Webhooks | Register topics; verify with a test delivery | Registration failure → banner + retry |

## First-Run Checklist (In-App)

- [ ] Empty state explains what the app does in one sentence
- [ ] Exactly one primary action on the first screen
- [ ] Configuration has ≤3 inputs, with sensible defaults pre-filled
- [ ] A "use sample data" option exists so the merchant sees value before importing
- [ ] Progress is visible while initial data loads (no blank 30-second wait)
- [ ] Success state names what just happened in merchant terms
- [ ] Next step is explicit ("We'll sync every 15 minutes — here's today's first run")

## Emails

| Email | Trigger | Subject | Purpose | Opt-out |
|-------|---------|---------|---------|---------|
| Welcome | Install | [Subject] | One action to take | Transactional |
| Nudge | Installed, no config in 24h | [Subject] | Offer help / sample data | Marketing opt-out |
| First value | First successful run | [Subject] | Reinforce the outcome | Transactional |
| Trial ending | [N days before] | [Subject] | Explain what changes | Transactional |

Rules: no more than [3] emails in the first 14 days; every marketing email has an
unsubscribe that works; never email a merchant who uninstalled.

## Sample / Demo Data

| Option | What it does | Cleanup |
|--------|--------------|---------|
| Sample data | Populates the app with synthetic records so the merchant sees the payoff | One-click clear, no Shopify writes |
| Real import | Reads the merchant's orders/products | Read-only until they confirm |

## Support Surfaces

| Surface | Content |
|---------|---------|
| In-app help link | [Where it goes] |
| Help centre article | [First-run article URL] |
| Support email | [address] |
| Response commitment | [N business hours] |

## Offboarding

- [ ] Uninstall stops all jobs and revokes tokens
- [ ] Data purged per `docs/prd/<app>.md` §8
- [ ] Merchant can export their app data before uninstalling
- [ ] Reinstall behaviour documented (restore vs. reset)

## Verification

| Check | Method | Result |
|-------|--------|--------|
| Clean install to first value | Timed run on the clean test store | [N minutes] |
| Scope set matches PRD | Compare OAuth screen to scope list | [Pass/Fail] |
| Empty states render | Screenshot each | [Pass/Fail] |
| Emails fire | Trigger each in staging | [Pass/Fail] |
| Uninstall clean | Uninstall and inspect logs | [Pass/Fail] |
