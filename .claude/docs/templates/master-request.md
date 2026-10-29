# Master Request

> **File**: `request.md` (repo root) · **History**: `request-history.md` (append-only)
> **Owner**: the requester · **Enforced by**: `track-request-changes.sh`

## What We Are Building

[One paragraph. The portfolio-level goal: which Shopify apps, for which
merchants, to what end. Written so a new agent can read this file alone and know
what the repo is for.]

## Why

[The market gap or operational pain. Evidence: `/research` note links, merchant
quotes, competitor gaps.]

## Apps In Scope

| App | Directory | One-line purpose | Stage | Registry entry |
|-----|-----------|------------------|-------|----------------|
| [Name] | `apps/<app>` | [Purpose] | [research / concept / prototype / build / submission / live] | `docs/registry/apps.json` |

> Adding an app means: append to `docs/registry/apps.json`, run
> `/scaffold --app <name>`, then add the row here. Never rewrite an existing
> registry entry.

## Constraints (Non-Negotiable)

- **Platform**: [Admin API version, App Bridge, Polaris versions]
- **Hosting**: [Where the app runs; where data lives]
- **Isolation**: each app owns `apps/<app>/`; no shared mutable file except
  `docs/registry/apps.json`
- **Scopes**: minimum necessary; every scope justified in the listing
- **Data**: [retention, protected customer data policy]
- **Budget**: [time / money / review cycles]

## What Is Explicitly Out Of Scope

- [Thing we will not build, and why — prevents scope drift]

## Definition of Done For The Portfolio

- [ ] Each app reaches its gate sequence with approvals recorded in `apps/<app>/approvals.json`
- [ ] Each app passes `/app-store-checklist` before submission
- [ ] Each app has a test store plan and recorded evidence
- [ ] Every app is listed in the registry and in the dashboard `/start` renders

## How Requests Change

1. Propose the change to the requester.
2. On approval, append an entry to `request-history.md` (date, change, reason,
   affected apps, approver).
3. Update this file to match.
4. Only then update PRDs / stories downstream.

> An edit to `request.md` without a `request-history.md` entry is rejected by the
> hook. There is no exception for "small" edits.

## Open Questions

| # | Question | Owner | Blocks |
|---|----------|-------|--------|
| 1 | [Question] | [Who] | [Which app / gate] |
