# Test Store Plan: [App Name]

> **App**: `apps/<app>` · **Plan owner**: test-store-manager
> **Credentials**: `apps/<app>/credentials.<store>.json` (git-ignored)
> **Produced by**: `/create-test-store` · **Deployed by**: `/deploy-to-test-store`

## Stores

| Purpose | Store handle | Type | Plan | Owner | Reset cadence |
|---------|--------------|------|------|-------|---------------|
| Primary dev | [handle.myshopify.com] | Development store | [plan] | [who] | [on demand] |
| Clean install test | [handle-2.myshopify.com] | Development store | [plan] | [who] | [before each release] |
| Edge-case store | [handle-3.myshopify.com] | Development store | [plan — e.g. Plus trial features] | [who] | [rarely] |

**Rule**: never install a production build on a test store without labelling it in
the store's notes. Never use a merchant's real store for destructive tests.

## Seed Data

| Data | Quantity | How created | Script / path |
|------|----------|-------------|---------------|
| Products | [50] | Admin API mutation or CSV import | [path] |
| Variants per product | [3] | | |
| Orders | [200 across 30 days] | [Draft orders → paid, or seed script] | [path] |
| Customers | [40] | | |
| Locations | [2] | | |
| Metafields | [as required by the PRD] | | |

**Determinism**: seed data must be reproducible — same script, same ids where
possible, so test assertions are stable.

## Store Configuration

| Setting | Value | Why |
|---------|-------|-----|
| Currency | [USD] | Baseline tests |
| Second currency | [EUR] | Multi-currency path |
| Markets | [2] | Localization path |
| Tax settings | [included / excluded] | Money rounding tests |
| Payment | Bogus Gateway | Never real charges |
| Shipping | [2 rates] | Fulfilment path |
| Theme | [Dawn, current version] | Extension tests |

## App Installation

| Step | Command / action | Verified |
|------|------------------|----------|
| Install | `shopify app dev` against the dev store | [ ] |
| Scopes granted | [list — must equal the PRD scope set exactly] | [ ] |
| Webhooks registered | [topics] | [ ] |
| Billing test plan | [test charge created and cancelled] | [ ] |
| Uninstall | Removes access, stops jobs, purges per policy | [ ] |
| Reinstall | Behaviour matches the PRD (restore or reset) | [ ] |

## Test Scenarios This Store Supports

| Scenario | Store | Preconditions |
|----------|-------|---------------|
| Clean install → first value | Clean install test | No prior app data |
| High order volume | Primary dev | 200 seeded orders |
| Webhook replay | Primary dev | Event log enabled |
| Multi-currency | Edge-case store | EUR enabled |
| Uninstall / reinstall | Clean install test | Snapshot before |

## Reset Procedure

1. [How to wipe app data — script or SQL, not manual clicking]
2. [How to reseed]
3. [How to reinstall the app]
4. [Expected total time: N minutes]

## Access & Secrets

| Secret | Where stored | Rotated |
|--------|--------------|---------|
| Admin API access token | `apps/<app>/.env.local` (git-ignored) | [on suspicion of leak] |
| App secret | Platform secret store | [quarterly] |
| Test store login | Password manager, not in repo | [n/a] |

## Known Limitations Of These Stores

- [e.g. development stores cannot test real payment capture]
- [e.g. Plus-only features unavailable — covered by [store]]

## Checklist Before Declaring The Store Ready

- [ ] App installs from the CLI with the exact scope set
- [ ] Seed data matches the quantities above
- [ ] Webhooks verified end to end
- [ ] Reset procedure rehearsed once
- [ ] Credentials recorded and git-ignored
- [ ] Store documented in `apps/<app>/README.md`
