---
name: architecture-review
description: "Use when reviewing one app's architecture. Validates the per-app ADR set against that app's requirement registry, builds a REQ -> ADR traceability matrix, detects conflicting decisions, cross-checks every decision against the pinned Shopify API snapshot, and returns a PASS/CONCERNS/FAIL verdict."
argument-hint: "[app] [focus: full | coverage | consistency | api | rtm]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify
agent: technical-director
model: opus
---

# Architecture Review

The architecture review validates that one app's body of architecture decisions
covers that app's requirements, is internally consistent, and matches the Shopify
API version the app actually pins. It is the quality gate between technical setup
and story creation for that app.

**Scope: one app.** Every app owns its ADR set, requirement registry, and control
manifest under `docs/architecture/apps/<app>/`. There is no cross-app architecture
document, and a review never mixes two apps' decisions.

**Argument modes:**

- **No argument / `full`**: full review — all phases
- **`coverage`**: traceability only — which requirement IDs have no ADR
- **`consistency`**: cross-ADR conflict detection only
- **`api`**: Shopify API surface audit only (version, scopes, topics, deprecated fields)
- **`rtm`**: Requirements Traceability Matrix — extends the matrix to story and
  test paths and writes `docs/architecture/apps/<app>/requirements-traceability.md`

Report after loading: `Loaded [N] ADRs, [M] requirements — app: [app], API version: [version].`

---

## Phase 1: Resolve the App and Load Inputs

### 1a — Resolve the app

Read `docs/registry/apps.json`. The first argument token is the app slug.

- Slug found in the registry → use it.
- No argument → take the app named in `request.md`, else the app whose
  `production/apps/<app>/session-state/active.md` is most recently modified.
- Slug not in the registry → stop and list the registered slugs. Never invent one.

Every path below is relative to that app. Never read another app's directory.

### 1b — L0 summary scan

Before full reads, Grep the app's ADR summaries:

```
Grep pattern="## Summary" path="docs/architecture/apps/<app>" glob="adr-*.md" output_mode="content" -A 3
```

In `coverage` mode this scan plus `requirements.yaml` is usually enough to name the
gaps; full-read only the ADRs whose summaries touch the same area.

### 1c — Full load

**Architecture records**

- `docs/architecture/apps/<app>/adr-*.md` — read every file completely in `full`,
  `consistency`, `api`, and `rtm` modes
- `docs/architecture/apps/<app>/requirements.yaml` — the requirement registry
- `docs/architecture/apps/<app>/control-manifest.md` — for the staleness check only
- `docs/architecture/apps/<app>/architecture.md` — if it exists

**App configuration**

- `apps/<app>/shopify.app.toml` — pinned `api_version`, `access_scopes`, webhook
  subscription list, extension registrations
- `apps/<app>/README.md`, `apps/<app>/status.md` — purpose, stage, known blockers

**Pinned API reference**

- `docs/shopify-api-reference/<version>/` — schema snapshot, changelog notes,
  deprecated-field list, per-surface notes for the version in `shopify.app.toml`

**Project standards**

- `.claude/docs/technical-preferences.md` — stack, budgets, forbidden patterns,
  specialist routing

**Requirement sources** (whatever exists)

- `apps/<app>/docs/*.md`, that app's `request-history.md`, and `request.md`
- `design/` documents that name this app

If the snapshot directory for the pinned version is missing, record a blocking
finding and continue with the phases that do not need it.

---

## Phase 2: Extract Requirements

### 2a — Pre-load the requirement registry

Read `docs/architecture/apps/<app>/requirements.yaml` before extracting anything.
Index entries by `id` and by normalized `requirement` text.

The registry is **append-only**:

1. **Match to an existing entry in the same area** → reuse that `REQ-<AREA>-NNN`
   unchanged. If the wording changed but the intent did not, update the
   `requirement` text and add `revised: [date]`.
2. **No match** → assign the next free sequence for that area (`REQ-BILL-002`).
   Never renumber to tidy the file.
3. **Ambiguous** → ask: "Does '[new text]' restate `REQ-[AREA]-NNN: [existing text]`,
   or is it a new requirement?"
4. **`status: deprecated`** entries → skip; they were removed deliberately.

### 2b — Extract from requirement sources

A requirement is any statement the architecture must satisfy for the app to work on
Shopify. Extract by area:

| Area | Example |
|------|---------|
| **Data model** | "Bundle rules persist per shop and survive reinstall" → schema and migration decision |
| **API surface** | "Create discounts with `discountCodeBasicCreate`" → version and mutation choice |
| **Scopes** | "Read orders to tag them" → scope justification and review risk |
| **Webhooks** | "React to order cancellation" → topic registration and handler contract |
| **Billing** | "Charge per bundle tier" → plan model and gating decision |
| **Admin UI** | "Rule editor in the embedded admin" → Polaris and App Bridge decision |
| **Theme extension** | "Render bundle price on the product page" → app block contract |
| **Checkout extension** | "Show bundle contents at checkout" → extension target and limits |
| **Auth/sessions** | "Session tokens only, no cookie session" → auth decision |
| **Jobs** | "Sync 50k variants without timing out" → queue and bulk-operation decision |
| **Performance** | "Admin route under 1.5 s p75" → budget allocation decision |
| **Isolation/compliance** | "Never mix two shops' data in one query" → tenancy decision |

Output per source document:

```
Source: apps/<app>/docs/pricing-rules.md
Requirements:
  REQ-BILL-001: Tiered monthly plans, gated per feature -> Area: Billing
  REQ-DATA-002: Shop-scoped rows keyed by shop domain  -> Area: Data model
```

The union of these is the **requirements baseline**.

---

## Phase 3: Build the Traceability Matrix

For each requirement, determine coverage from the ADRs:

1. Read each ADR's **App Requirements Addressed** section (required by the ADR template).
2. Check whether the decision text implicitly covers the requirement.
3. Assign status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An Accepted ADR addresses it explicitly |
| ⚠️ **Partial** | An ADR touches it but leaves the contract ambiguous, or the ADR is still `Proposed` |
| ❌ **Gap** | No ADR addresses it |

```
## Traceability Matrix

| Requirement | Area | Requirement text | ADR | Status |
|-------------|------|------------------|-----|--------|
| REQ-BILL-001 | Billing | Tiered plans gated per feature | ADR-0004 | ✅ |
| REQ-WHK-002 | Webhooks | Handle order cancellation idempotently | — | ❌ GAP |
| REQ-DATA-002 | Data model | Shop-scoped tenancy | ADR-0002 | ⚠️ Partial |
```

Totals: X covered, Y partial, Z gaps.

---

## Phase 3b: Story and Test Linkage (`rtm` mode)

Skip unless the argument includes `rtm`.

1. Glob `production/epics/**/story-*.md` and keep only stories whose header names
   this app (`App: <app>`). Another app's stories are out of scope — they never count
   as linkage for this app's requirements.
2. Per kept story, extract its `REQ-` reference from the Context section, its Status,
   and the test path stated under `## Test Evidence`.
3. Confirm via Glob that each stated test path exists; tests live beside the source
   they cover inside `apps/<app>/`.
4. Extend the matrix with Story, Test File, and Test Status:

| Status | Meaning |
|---|---|
| COVERED | Test file exists at the stated path |
| MISSING | Path stated but the file is absent |
| NONE | No test stated (expected for Admin UI / Extension stories carrying walkthrough evidence) |
| NO STORY | Requirement has no story yet |

```
## Requirements Traceability Matrix (RTM)

| REQ | Requirement | ADR | Story | Test File | Status |
|-----|-------------|-----|-------|-----------|--------|
| REQ-BILL-001 | Tiered plan gating | ADR-0004 | story-012-plan-gating.md | apps/<app>/billing/plans.test.ts | COVERED |
| REQ-WHK-002 | Order cancellation | ADR-0006 | story-014-order-cancel.md | — | MISSING |
| REQ-DATA-002 | Shop-scoped tenancy | ADR-0002 | — | — | NO STORY |
```

Report `full chain complete: N/total (%)`.

---

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR pair. A conflict exists when two accepted decisions cannot both
be implemented:

- **Scope ownership** — two ADRs both claim an access scope, or both mutate the same
  resource family with incompatible contracts
- **Data ownership** — two ADRs claim to be the writer of the same table, session
  store, or merchant setting
- **API version** — ADRs pin different Admin API versions, or one relies on a field
  removed in the app's pinned version
- **Webhook overlap** — two decisions define handlers for the same topic, or a topic
  is subscribed twice
- **Billing** — two plan models, or gating enforced in two places that disagree
- **Performance budget** — allocated costs exceed the route budget (`p75 < 1.5 s`),
  the webhook budget (`p95 < 500 ms`), or the GraphQL cost ceiling
- **Pattern** — one ADR routes Admin API calls through the app server while another
  calls the API from the browser; one uses App Bridge navigation, another bypasses it
- **Tenancy** — one ADR scopes queries by shop domain, another queries by shop ID with
  no mapping between them

For each conflict:

```
## Conflict: ADR-NNNN vs ADR-MMMM
Type: [Scope / Data ownership / API version / Webhook / Billing / Performance / Pattern / Tenancy]
ADR-NNNN states: [...]
ADR-MMMM states: [...]
Impact: [what breaks if both ship — duplicated webhook processing, scope review rejection, cross-shop leak]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR dependency ordering

1. Collect every `Depends On` entry from each ADR's **ADR Dependencies** section.
2. Topologically sort into implementation order: data model and auth first, then API
   surface, then admin UI and extensions.
3. Flag dependencies on a `Proposed` or missing ADR:
   `⚠️ ADR-0005 depends on ADR-0002, still Proposed — downstream work is blocked.`
4. Flag cycles: `🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003`.
5. Output the sorted order grouped by dependency level.

---

## Phase 5: Shopify API Surface Audit

Cross-check each ADR's **Shopify API Surface** section against reality. Model
training data predates the pinned version — the snapshot under
`docs/shopify-api-reference/<version>/` is the only authority.

### Version consistency

- Does every ADR name the same version as `apps/<app>/shopify.app.toml`?
- Any ADR written against an older version → flag as stale.

### Deprecated and removed fields

- Grep the ADRs for every field, mutation, and topic on the snapshot's deprecated and
  removed lists.
- Flag each hit with the replacement the snapshot names.

### Scopes

- Collect every scope the ADRs reference.
- Compare against `access_scopes` in `shopify.app.toml`: a decision needing a scope the
  app does not request is unimplementable; a requested scope no decision needs is a
  review risk and must be justified or dropped.
- Flag scopes that require Shopify review (protected customer data, for example) as
  schedule risks, not only technical ones.

### Webhooks

- Every topic an ADR depends on must exist in the pinned version and be listed in the
  app's subscription config.
- The mandatory compliance topics — `customers/data_request`, `customers/redact`,
  `shop/redact` — must appear in some decision. Their absence is a submission blocker.

### Beyond-cutoff usage

- Anything the model cannot verify from memory must appear in the snapshot. If an ADR
  uses a field, argument, or target absent from the snapshot, flag it as unverified
  instead of assuming it exists.

### Missing sections

- List ADRs with no **Shopify API Surface** section. Their API assumptions are unknown
  and cannot be audited.

```
### API Audit Results
App: [app]   Pinned version: [version]   Snapshot present: [yes/no]
ADRs with a Shopify API Surface section: X / Y

Deprecated usage:
  - ADR-0003: [field] removed in [version] — use [replacement]
Scope mismatches:
  - ADR-0004 needs `read_all_orders`; absent from shopify.app.toml
Missing compliance topics:
  - no decision registers `customers/redact`
Unverified usage:
  - ADR-0006: [argument] not found in the pinned snapshot
```

### Specialist consultation (`full` and `api` modes)

Spawn via Task, in parallel, only for surfaces the ADR set actually touches:

- `api-lead` — confirm or challenge the version, scope, and mutation findings; name
  anything the audit missed
- `webhooks-specialist` — subscription, verification, and idempotency decisions
- `billing-specialist` — plan model, gating, and test-charge decisions
- `polaris-specialist` — admin UI and App Bridge decisions
- `checkout-specialist` — checkout extension decisions

Pass each the relevant ADRs, the snapshot paths, and the Phase 5 findings. Record their
conclusions under `### Specialist Findings`; they weigh the same as audit findings.
A specialist returning BLOCKED follows the Error Recovery Protocol.

---

## Phase 5b: Requirement Revision Flags

For each HIGH-risk API finding, check whether a requirement source assumes behaviour
the snapshot contradicts:

1. A field the requirement is built on is deprecated or removed.
2. A scope the requirement needs is gated behind review or unavailable to the app type.
3. An extension target cannot do what the design assumes (checkout extensibility
   limits, app block placement limits).
4. A cost or rate limit makes the described flow impossible in one request.

```
### Requirement Revision Flags
| Source | Assumption | Reality (ADR / snapshot) | Action |
|--------|-----------|--------------------------|--------|
| apps/<app>/docs/pricing-rules.md | "Bulk-price 50k variants in one call" | per-request cost ceiling — ADR-0007 | Revise requirement |
```

Offer `/update-request` for each flag; do not edit `request.md` from this skill.
If none: `No revision flags — requirement sources agree with verified API behaviour.`

---

## Phase 6: Architecture Document Coverage

If `docs/architecture/apps/<app>/architecture.md` exists, validate it:

- Does every area in the requirement registry appear in the document?
- Does the data-flow section cover every cross-surface call the ADRs define?
- Do module boundaries match the ADR decisions?
- Are there modules with no ADR and no requirement (orphaned design)?

---

## Phase 7: Report

```
## Architecture Review — [app]
Date: [date]
API version: [version]   ADRs reviewed: [M]   Requirements: [N]

### Traceability Summary
Covered: [X]   Partial: [Y]   Gaps: [Z]

### Coverage Gaps (no ADR)
❌ REQ-[AREA]-NNN: [requirement]
   Suggested ADR: "/architecture-decision [title]"
   Risk: [LOW / MEDIUM / HIGH]

### Cross-ADR Conflicts
[Phase 4 conflicts, or "None"]

### ADR Dependency Order
[Topologically sorted list; unresolved dependencies and cycles]

### Requirement Revision Flags
[Phase 5b table, or "None"]

### Shopify API Issues
[Phase 5 findings]

### Architecture Document Coverage
[Phase 6 findings, or "No architecture.md — skipped"]

### Verdict: [PASS / CONCERNS / FAIL]

PASS: every requirement covered by an Accepted ADR, no conflicts, API surface verified
CONCERNS: partial coverage or stale ADRs, no blocking conflict
FAIL: a data-model, auth, billing, or compliance requirement has no ADR, or two
      accepted ADRs cannot both be implemented

### Blocking Issues
[FAIL only]

### Required ADRs
[Prioritised; data model and auth first]
```

---

## Phase 8: Write

Ask once, listing every file and what changes:

- `[A]` write all approved files (report + registry updates + RTM)
- `[B]` write the review report only
- `[C]` write nothing yet

Approved writes:

1. **Review report** → `docs/architecture/apps/<app>/architecture-review-<date>.md`
2. **Requirement registry** → `docs/architecture/apps/<app>/requirements.yaml`: append
   new IDs, update reworded entries with `revised`, mark removed entries
   `status: deprecated` after confirmation, update `last_updated`. Never renumber or
   delete.
3. **RTM** (`rtm` mode) → `docs/architecture/apps/<app>/requirements-traceability.md`
   with the matrix, coverage summary, and a History table (date, full-chain %).
4. **Session state** → append to `production/apps/<app>/session-state/active.md`
   (create if absent):

```
## Session Extract — /architecture-review [date]
- Verdict: [PASS / CONCERNS / FAIL]
- Requirements: [N] — [X] covered, [Y] partial, [Z] gaps
- New REQ IDs: [N, or "None"]
- Revision flags: [sources, or "None"]
- Top gaps: [top 3]
```

If the control manifest's `Manifest Version:` predates the newest accepted ADR, say the
manifest is stale and that `/create-control-manifest update` regenerates it. Do not edit
it here.

---

## Phase 9: Handoff

1. **Top 3 actions** — highest-impact gaps first, data model and auth before UI.
2. **Pre-gate checklist** — Glob and mark each:
   - `apps/<app>/shopify.app.toml` with a pinned `api_version` — else `/scaffold`
   - test runner configured inside the app — else `/test-setup`
   - `docs/architecture/apps/<app>/control-manifest.md` — else `/create-control-manifest`
   - a dev store recorded for the app — else `/create-test-store`
   Do not offer `/gate-check` while any item is ❌; offer the missing skill instead.
3. **Rerun trigger**: "Re-run `/architecture-review <app>` after each new ADR is
   accepted; coverage should only move up."

Close with `AskUserQuestion`, `request_user_input` or `clarify`:

- Gaps or ❌ items: `[A]` write the next ADR with `/architecture-decision` ·
  `[B]` regenerate the control manifest · `[C]` run the missing pre-gate skill ·
  `[D]` stop here
- Clean: `[A]` `/create-control-manifest update` · `[B]` `/create-stories` ·
  `[C]` `/qa-plan` · `[D]` stop here

---

## Error Recovery Protocol

If a spawned specialist returns BLOCKED or errors:

1. Surface it immediately: `[agent]: BLOCKED — [reason]`.
2. If a later phase depends on that output, do not pass that phase without user input.
3. Offer: skip and record the gap · retry with a narrower scope (one surface, one ADR) ·
   stop and resolve the blocker.
4. Always produce a partial report; never discard completed findings.

---

## Collaborative Protocol

1. **Read silently** — do not narrate every file read.
2. **Show the matrix before asking anything** — the user should see the state first.
3. **Do not guess** — if a statement is ambiguous, ask whether it is a requirement or a
   preference.
4. **Draft before approval** — show the exact content that will be written.
5. **One approval per changeset** — list every file and what changes, then ask once with
   `AskUserQuestion`, `request_user_input` or `clarify` (labeled options, never a
   plain-text "May I?").
6. **Advisory verdict** — CONCERNS and FAIL inform the decision; the user decides
   whether to proceed.
