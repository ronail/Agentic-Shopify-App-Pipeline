# UX Specification: [Screen / Flow Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g., ux-lead, polaris-specialist]
> **Last Updated**: [Date]
> **Screen / Flow Name**: [Short identifier used in code and tickets — e.g., `OrderSyncSettings`, `BulkImportFlow`]
> **Surface**: [Embedded admin page (App Bridge) | Admin action/block | POS UI extension | Admin link-out]
> **Related PRD**: [Link to `docs/prd/<app>.md` § UX requirements]
> **Related ADRs**: [Any architectural decisions that constrain this screen — e.g., `ADR-0007: App Bridge session tokens`]
> **Related UX Specs**: [Sibling and parent screens — e.g., `ux-spec-settings.md`]
> **Accessibility Tier**: Basic | Standard | Comprehensive | Exemplary

> **Note — Scope boundary**: This template covers discrete screens and flows
> (index pages, settings dialogs, resource detail cards, onboarding wizards).
> For cross-screen interaction conventions (buttons, tables, toasts, empty
> states) use `interaction-pattern-library.md`. For the merchant-facing
> marketing surface, use `app-store-listing.md`.

---

## 1. Purpose & Merchant Need

> **Why this section exists**: Every screen must justify itself from the
> merchant's perspective. A screen designed from the implementation's point of
> view ("display the sync rows") ships cluttered. A screen designed from the
> merchant's point of view ("prove at a glance that today's orders reached the
> warehouse") ships purposeful. Write this before any layout decision.

**What merchant need does this screen serve?**

[One paragraph. Name the real operational need, not the data function.

Example — bad: "Displays the sync log."
Example — good: "Lets the merchant confirm within five seconds that today's
orders reached their warehouse, and shows exactly which orders did not — so they
can decide whether to re-sync or contact support without leaving the admin."]

**The merchant goal** (what they want to accomplish):

[One sentence, specific enough to become an acceptance criterion.]

**Success signal** (how we know the screen works):

[e.g., "Merchant resolves a failed sync from this screen in under 60 seconds,
without opening a support ticket."]

---

## 2. Merchant Context on Arrival

| Field | Value |
|-------|-------|
| **Where they came from** | [Admin nav item / deep link from an order / email link / onboarding step] |
| **What they already know** | [Prior state — e.g., "saw the failure count in the admin card"] |
| **Emotional state** | [Calm / time-pressured / worried about data loss] |
| **Available time** | [Seconds for a check, minutes for a fix] |
| **Store scale** | [e.g., 50 orders/day vs 5,000 — drives pagination and bulk actions] |
| **Plan / entitlement** | [Which billing plan unlocks this screen; what a downgraded merchant sees] |

---

## 3. Navigation Position

| Field | Value |
|-------|-------|
| **Parent** | [Where this screen sits in the admin app's information architecture] |
| **Siblings** | [Adjacent screens] |
| **Depth from app home** | [e.g., 2 clicks] |
| **App Bridge nav** | [NavMenu item id or `ui-nav-menu` entry that points here] |
| **Back behaviour** | [App Bridge back button (`app-bridge-actions`) vs in-page breadcrumb] |

---

## 4. Entry & Exit Points

| Direction | Trigger | Notes |
|-----------|---------|-------|
| **Entry** | [Admin nav click] | |
| **Entry** | [Deep link from order detail — must handle a missing/forbidden resource] | |
| **Entry** | [Post-install redirect after OAuth] | [First-run state applies] |
| **Exit** | [Save → return to index with toast] | |
| **Exit** | [Cancel → discard confirm if dirty] | |
| **Exit** | [Session token expiry → re-auth via App Bridge, do not lose form state] | |

---

## 5. Layout Specification

> The handoff artifact between UX and UI. It need not be pixel-perfect; it must
> communicate hierarchy, proximity and proportion. Build with Polaris
> components (`Page`, `Layout`, `Card`, `IndexTable`, `Banner`) — do not
> hand-roll primitives.

### 5.1 Wireframe

```
┌──────────────────────────────────────────────┐
│  [← Back]        ORDER SYNC          [Save]  │  ← PAGE HEADER (Page + actions)
├──────────────────────────────────────────────┤
│  [!] 3 orders failed to sync   [Retry all]   │  ← BANNER ZONE (Banner, critical)
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │  FILTERS  [Status ▾] [Date ▾]  {search}  │ │  ← FILTER ZONE (Filters)
│ ├──────────────────────────────────────────┤ │
│ │  { IndexTable rows ... }                 │ │  ← CONTENT ZONE (IndexTable)
│ │  ...                                     │ │
│ │  [< Prev]  Page 1 of N   [Next >]        │ │  ← PAGINATION ZONE
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### 5.2 Zone Definitions

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| [Page header] | Title, breadcrumb, primary action | Full width, ~10% height | No | Title truncates; actions collapse into an overflow menu |
| [Banner zone] | Critical/warning state summaries | Full width, content height | No | One banner per severity — never stack three |
| [Filter zone] | Status/date filters and search | Full width, ~10% height | No | Search collapses into an icon on narrow widths |
| [Content zone] | IndexTable of records | ~70% height | Yes — table body | Paginate at 50 rows; never infinite-scroll the admin |
| [Pagination] | Page controls | ~5% height | No | Disabled at bounds with visible reasoning |

### 5.3 Component Inventory

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [Back link] | Polaris `Page` backAction | Header | Return to app home | Yes | Yes — Page |
| [Primary action] | `Button` variant primary | Header | Save and return | Yes | Yes — Polaris Button |
| [Failure banner] | `Banner` tone critical | Banner | Surface failed rows | Conditional | Yes — Banner |
| [Status badge] | `Badge` | Content | Row state | Yes | Yes — Badge |
| [Row action menu] | `IndexTable` row action | Content | Retry / view detail | Yes | Yes — IndexTable |
| [Empty state] | `EmptyState` | Content | No records yet | Yes | Yes — EmptyState |
| [Skeleton] | `SkeletonBodyText` | Content | Loading rows | Yes | Yes — SkeletonBodyText |

**Primary focus element on open**: [e.g., the first row of the IndexTable, or the
search field when arriving from a deep link with a pre-filled query.]

---

## 6. States & Variants

> A screen is a set of states, not one picture. Undesigned empty/loading/error
> states ship broken. This table is also QA's test matrix.

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| [Loading] | Screen opening, data fetching | Skeleton rows; actions disabled | Only navigation is interactive | Must resolve <500ms p95; if not, page the query |
| [Empty — no records] | Merchant has no data yet | `EmptyState` with one primary CTA | No row actions | Never show a disabled toolbar above an empty table |
| [Populated] | Records exist | IndexTable fills | Row + bulk actions available | Default state |
| [Error — load failed] | Query or network failure | `Banner` critical + Retry | Only Retry and nav are active | Log the request id; do not expose GraphQL internals |
| [Partial — some rows failed] | Mixed success | Per-row `Badge` + summary banner | Retry applies per row or to the selection | Bulk retry is capped; show progress |
| [Plan-gated] | Merchant on a lower plan | Feature visible, locked, with upgrade CTA | Actions open the billing upgrade flow | Do not 404 — show the value being gated |
| [Permission-denied] | Missing access scope | `Banner` explaining the missing scope and how to re-authorize | Only re-authorize is active | Occurs after scope changes — must not dead-end |
| [Dirty / unsaved] | Merchant changed a field | Save enabled; unsaved indicator | Leaving prompts a discard confirm | App Bridge navigation interception |

---

## 7. Interaction Map

> Source of truth for what every input does. Gaps here are accessibility bugs.

### 7.1 Navigation Inputs

| Input | Platform | Action | Visual Response | Notes |
|-------|----------|--------|-----------------|-------|
| [Tab / Shift+Tab] | Keyboard | Move focus through interactive elements in DOM order | Polaris focus ring | Focus order follows visual order; never trap focus outside modals |
| [Arrow keys] | Keyboard | Move within table rows/cells | Row highlight | Rows are reachable by Tab, not arrows alone |
| [Pointer click] | Mouse | Activate the clicked control | Hover → active → result | Hover never changes selection |
| [Touch tap] | Shopify mobile admin | Activate in one gesture | Press ripple | Destructive actions require an explicit confirm |
| [Browser back] | All | Navigate back in admin history | — | Intercept when the form is dirty |

### 7.2 Action Inputs

| Input | Context (What must be focused) | Action | Response | Notes |
|-------|-------------------------------|--------|----------|-------|
| [Enter] | Primary button focused | Submit | Button spinner, then toast | Disabled while the mutation is in flight |
| [Enter] | Search field | Apply filter | Table reloads, URL params update | Filters must be linkable/bookmarkable |
| [Space] | Checkbox | Toggle row selection | Bulk bar appears | Selection survives pagination within the filter |
| [Esc] | Modal open | Close modal | Focus returns to the opener | Never close a modal with unsaved input silently |
| [Cmd/Ctrl+Z] | Editable cell | Undo last edit | Field reverts | Only within the current session |

### 7.3 State-Specific Behaviors

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [Loading] | Mutating actions disabled | Prevent duplicate submissions |
| [Modal open] | Only modal controls active | Background inert |
| [Plan-gated] | Mutations disabled; upgrade CTA active | Entitlement boundary enforced server-side too |
| [Permission-denied] | Only re-authorize active | Cannot act without a scope |

---

## 8. Data Requirements

> UI reads data; it does not own it. UI fires mutations; it does not write state
> directly. Filling this table first prevents the two classic failures: UI
> reaching into modules it shouldn't, and data layers not exposing what the UI
> needs until it is half-built.

| Data Element | Source | Update Frequency | Owner | Format | Null / Missing Handling |
|--------------|--------|-----------------|-------|--------|------------------------|
| [Sync records] | Admin GraphQL API, paginated (`first`/`after`) | On open; on refresh; on mutation result | app server | `OrderSync[]` | Empty array → empty state; never null |
| [Shop plan] | Billing API / app subscription record | On open | billing service | enum | Unknown → treat as lowest plan, log |
| [Access scopes] | Session token claims | On open | auth service | string[] | Missing scope → permission-denied state |
| [Counts / aggregates] | Server-side computed | On open | app server | int | Show an em dash rather than 0 when unknown |

> **Rule**: this screen never writes another module's data. It calls the API and
> re-reads. Optimistic updates must be reverted on mutation failure.

---

## 9. Events Fired

| Merchant Action | Event | Payload | Receiver | Notes |
|-----------------|-------|---------|----------|-------|
| [Retry a failed row] | `sync.retry_requested` | `{row_id, shop}` | sync worker | Idempotent; dedupe by row + attempt |
| [Bulk retry] | `sync.bulk_retry_requested` | `{row_ids[], shop}` | sync worker | Capped batch size |
| [Change filter] | `ui.filter_changed` | `{filter, value}` | analytics | No server write |
| [Open screen] | `ui.screen_viewed` | `{screen, surface}` | analytics | No PII |
| [Upgrade CTA click] | `billing.upgrade_clicked` | `{from_plan, to_plan}` | analytics + billing | Must not auto-charge |

---

## 10. Transition & Animation

> Transitions communicate hierarchy. Respect `prefers-reduced-motion`.

| Transition | Trigger | Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|------|--------------|--------|----------------|---------------------------|
| [Screen enter] | Navigation | Fade in | 150 | ease-out | No | Yes — instant |
| [Row update] | Mutation resolves | Highlight flash, then settle | 200 | linear | Yes | Yes — instant |
| [Modal open] | Destructive action initiated | Scale from 95%, backdrop fade | 150 | ease-out | No | Yes — instant |
| [Toast appear] | Save success | Slide up + fade | 120 | ease-out | Yes | Yes — instant |
| [Skeleton to content] | Data arrives | Skeleton fades, content fades | 180 | ease-out | No | Yes — instant |

---

## 11. Input Method Completeness Checklist

- [ ] Every action reachable by keyboard alone (Tab/Enter/Space/Esc)
- [ ] Focus order matches visual order; no focus traps outside modals
- [ ] Focus is visible at all times (Polaris focus ring, never `outline: none`)
- [ ] Visible focus returns to the trigger when a dialog closes
- [ ] Pointer targets at least 32px; destructive controls separated from primary ones
- [ ] Touch works in the Shopify mobile admin without hover affordances
- [ ] No keyboard shortcut conflicts with admin chrome shortcuts
- [ ] Text scalable to 200% without clipping or overlap
- [ ] Works at 320px width and at 1920px

---

## 12. Screen-Level Accessibility Requirements

| Requirement | Applies | Implementation |
|-------------|---------|----------------|
| Semantic headings | Yes | Polaris `Page` title is the h1; sections use h2/h3 in order |
| Landmarks | Yes | `Page`, `Layout.Section` provide regions |
| Live regions | Yes | Toasts and banner updates announce via `role="status"` |
| Table semantics | Yes | `IndexTable` headers with `scope`; bulk checkboxes labelled |
| Contrast | Yes | Polaris tokens only; do not hand-pick colours |
| Colour independence | Yes | Status uses icon + text, never colour alone |
| Error identification | Yes | Field errors linked with `aria-describedby`; summary banner for form-level errors |
| Reduced motion | Yes | All non-essential motion disabled |
| Zoom / reflow | Yes | No fixed pixel heights on text containers |

---

## 13. Localization Considerations

| Element | Concern | Rule |
|---------|---------|------|
| UI strings | Expansion ~35% in de/fr | No text baked into images; Polaris layout reflows |
| Dates / numbers | Locale format | Use the shop's locale, not the browser's |
| Currency | Shop currency vs plan currency | Show the currency Shopify returns; never convert client-side |
| Names / addresses | RTL shops | Mirror layout for `ar`/`he`; Polaris handles direction via `dir` |
| Pluralization | Multiple CLDR categories | Use ICU message format, no string concatenation |
| Support links | Regional support hours | Locale-aware support URL |

---

## 14. Acceptance Criteria

- [ ] Renders correctly in all states listed in §6 (screenshot evidence attached)
- [ ] Keyboard-only completion of the primary task verified
- [ ] Screen-reader pass on the primary task (VoiceOver or NVDA) recorded
- [ ] No Polaris component reimplemented by hand
- [ ] No console errors; no unhandled GraphQL error surfaces to the merchant
- [ ] Loads under 500ms p95 with 50 rows on a dev store
- [ ] All strings externalized for translation
- [ ] Deep link with an invalid id shows a recoverable error, not a blank screen
- [ ] App Bridge session-token refresh handled mid-session without data loss

---

## 15. Open Questions

| # | Question | Owner | Needed By | Resolution |
|---|----------|-------|-----------|-----------|
| 1 | [Question] | [Who decides] | [Date] | [Answer once resolved] |
