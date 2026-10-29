# Interaction Pattern Library: [App Name]

> **Applies to**: all apps in this repo — patterns are shared, do not fork them per app.
> **Polaris version**: [e.g. 13.x] · **App Bridge**: [e.g. 4.x]
> **Status**: Living document — add a pattern when you build one that others will repeat.

---

## How to Use This Library

1. Before designing a screen, check the catalog index. If a pattern exists, use it.
2. If a pattern does not exist and you need it twice, add it here first, then build.
3. Every pattern entry states: purpose, states, behaviour, accessibility, and the
   one mistake people make with it.
4. Deviations are allowed only with a note in the screen's UX spec explaining why.
5. Polaris is the default. A hand-rolled component that duplicates a Polaris
   component is a defect, not a preference.

---

## Pattern Catalog Index

| Pattern | Category | Polaris component | Used on |
|---------|----------|-------------------|---------|
| [Primary button](#primary-button) | Control | `Button` variant primary | Every screen's main action |
| [Secondary button](#secondary-button) | Control | `Button` | Secondary actions |
| [Destructive button](#destructive-button) | Control | `Button` tone critical | Delete, disconnect, revoke |
| [Toggle](#toggle) | Control | `SettingToggle` / `Switch` | Feature on/off |
| [Slider](#slider) | Control | `RangeSlider` | Numeric thresholds |
| [Dropdown / Select](#dropdown--select) | Control | `Select` | 3+ mutually exclusive options |
| [List row](#list-row) | Control | `ResourceList` / `IndexTable` | Index pages |
| [Resource picker cell](#resource-picker-cell) | Admin | `Thumbnail` + `ResourceItem` | Selecting products/orders |
| [Status badge](#status-badge) | Admin | `Badge` | Row state |
| [Modal dialog](#modal-dialog) | Control | `Modal` (App Bridge) | Focused task, form |
| [Confirmation dialog](#confirmation-dialog) | Control | `Modal` + critical action | Destructive confirmation |
| [Toast](#toast) | Feedback | App Bridge `Toast` | Save confirmation |
| [Banner](#banner) | Admin | `Banner` | Page-level state |
| [Tooltip](#tooltip) | Control | `Tooltip` | Icon-only controls |
| [Progress bar](#progress-bar) | Feedback | `ProgressBar` | Long jobs, backfills |
| [Input field](#input-field) | Control | `TextField` | Text entry |
| [Tabs](#tabs) | Navigation | `Tabs` | Sections of one resource |
| [Empty state](#empty-state) | Feedback | `EmptyState` | No data yet |
| [Loading state](#loading-state) | Feedback | `SkeletonBodyText` / `Spinner` | Fetching |
| [Error state](#error-state) | Feedback | `Banner` + retry | Failed fetch/mutation |
| [Navigation: push/pop](#navigation-push--pop) | Navigation | App Bridge nav | Moving between pages |
| [Focus management](#focus-management) | Navigation | — | Modals, route changes |
| [Escape / cancel](#escape--cancel) | Navigation | — | Any modal or dirty form |
| [Bulk action bar](#bulk-action-bar) | Admin | `BulkActions` | Multi-row operations |
| [Plan gate](#plan-gate) | Admin | `Banner` + `Button` | Locked features |
| [Scope re-auth prompt](#scope-re-auth-prompt) | Admin | `Banner` | Missing permission |

---

## Standard Control Patterns

Each entry: **Purpose** · **States** · **Rules** · **Accessibility** · **Common mistake**.

### Primary button

- **Purpose**: the single most valuable action on the screen.
- **States**: default, hover, focus, active, loading (spinner, label retained), disabled.
- **Rules**: one per screen region; label is a verb ("Save changes", not "OK");
  disabled state must have a visible reason nearby, never a bare disabled button.
- **Accessibility**: `type="button"` unless submitting a form; accessible name is
  the visible label; loading announced via `aria-busy`.
- **Common mistake**: disabling the primary action while keeping the reason invisible.

### Secondary button

- **Purpose**: supporting actions of equal legitimacy but lower priority.
- **States**: default, hover, focus, active, loading, disabled.
- **Rules**: never use a secondary button as the only path to a required action;
  group destructive actions away from the primary.
- **Accessibility**: same naming rules as primary; icon-only requires a tooltip
  and an `aria-label`.
- **Common mistake**: two primaries side by side — merchants cannot tell what to do.

### Destructive button

- **Purpose**: irreversible actions (delete data, disconnect a store, cancel billing).
- **States**: default (critical tone), hover, focus, active, loading, disabled.
- **Rules**: always behind a confirmation dialog naming the object and the
  consequence; never the default focus in the dialog; never in a bulk bar without
  a count ("Delete 12 records").
- **Accessibility**: label states the object ("Delete sync rule"), not "Delete".
- **Common mistake**: a soft confirmation with a pre-focused destructive button.

### Toggle

- **Purpose**: an immediate on/off setting with instant effect.
- **States**: on, off, saving, error (revert with an explanatory toast).
- **Rules**: apply immediately — do not pair a toggle with a Save button; write
  optimistically and revert on failure; never use a toggle for two-way choices
  that both need explaining (use radio buttons).
- **Accessibility**: label is the setting name; state is exposed via the switch role;
  the change is announced.
- **Common mistake**: toggle plus Save, which leaves the merchant unsure whether it took.

### Slider

- **Purpose**: adjusting a value where relative position matters more than the number.
- **States**: default, dragging, focus, disabled; committed vs uncommitted value.
- **Rules**: always pair with a numeric input; show units; clamp and explain bounds;
  never use for values needing precision (money, percentages with cents).
- **Accessibility**: keyboard arrows change value; Home/End jump to bounds; value
  text is announced on change (debounced).
- **Common mistake**: announcing every intermediate value during a drag.

### Dropdown / Select

- **Purpose**: choose one option from 3-10 known values.
- **States**: closed, open, focused option, selected, disabled, error.
- **Rules**: placeholder is never a valid value; for 2 options use radio buttons;
  for >10 use a searchable combobox; option labels are nouns.
- **Accessibility**: native `select` when possible; combobox otherwise with
  `aria-expanded`, `aria-controls`, and type-ahead.
- **Common mistake**: a select whose default silently means "all".

### List row

- **Purpose**: one record in a scannable list, with actions.
- **States**: default, hover, focus, selected, disabled, bulk-selected, error.
- **Rules**: the row's primary field is a link to detail; row actions live in an
  overflow menu beyond two actions; each row shows its own failure state rather
  than failing the whole page.
- **Accessibility**: row is reachable by Tab; selection checkboxes are labelled
  with the record name; sortable headers expose `aria-sort`.
- **Common mistake**: making the whole row clickable and the checkbox click a trap.

### Resource picker cell

- **Purpose**: reference a Shopify resource (product, order, collection) from a
  record the merchant is editing.
- **States**: empty, selected, loading, missing (resource deleted in Shopify),
  access denied (scope missing).
- **Rules**: use the App Bridge resource picker rather than a hand-built search;
  store the GID, not the display name; re-resolve on load and show a "no longer
  available" state instead of a blank cell.
- **Accessibility**: the cell is a button labelled "Change product"; the current
  value is read as part of the label.
- **Common mistake**: caching the title and rendering a stale name after a rename.

### Status badge

- **Purpose**: communicate the state of a record at a glance.
- **States**: success, warning, critical, info, neutral.
- **Rules**: never colour-only — pair with text; keep the vocabulary closed
  (a fixed set of statuses); a badge never changes meaning between screens.
- **Accessibility**: text content carries the meaning; `aria-label` if the visible
  text is abbreviated.
- **Common mistake**: inventing a new status word per screen.

### Modal dialog

- **Purpose**: a focused task that must not be lost among page content.
- **States**: opening, idle, submitting, error, closing.
- **Rules**: use App Bridge modal for full-page tasks and Polaris `Modal` for
  in-page confirmation; title states the task; footer holds primary + cancel;
  never nest modals; a modal with unsaved input must intercept close.
- **Accessibility**: focus moves into the dialog, is trapped, and returns to the
  opener; `role="dialog"` + `aria-modal`; Esc closes unless submitting.
- **Common mistake**: a modal that discards a half-filled form on backdrop click.

### Confirmation dialog

- **Purpose**: prevent an irreversible mistake.
- **States**: default, submitting, error.
- **Rules**: name the object and the consequence in the body; the confirm button's
  label repeats the verb; default focus on cancel; no "don't ask again" for
  destructive actions.
- **Accessibility**: the consequence text is part of the dialog's accessible
  description, not a separate tooltip.
- **Common mistake**: "Are you sure?" with no object named.

### Toast

- **Purpose**: confirm an action without stealing focus.
- **States**: entering, visible (auto-dismiss ~5s), action-available, dismissed.
- **Rules**: one toast per action; the message states what happened ("Saved 3
  rules"); include Undo only when undo is real; never use a toast for errors that
  need action (use a banner).
- **Accessibility**: `role="status"` with `aria-live="polite"`; errors use
  `assertive` sparingly; the toast is dismissible by keyboard.
- **Common mistake**: toasting a failure and losing the retry affordance.

### Banner

- **Purpose**: page- or section-level state that must persist until resolved.
- **States**: info, success, warning, critical, with/without action.
- **Rules**: at most one banner per severity per page; place above the content it
  describes; the action is a single clear next step.
- **Accessibility**: banner content is in the tab order; the action is a real button.
- **Common mistake**: using a banner for transient success (that is a toast).

### Tooltip

- **Purpose**: explain an icon-only control or a truncated value.
- **States**: hidden, visible on hover/focus, dismissed on Esc.
- **Rules**: never the only place critical information lives; ≤1 short sentence;
  appears after ~300ms and does not block the pointer.
- **Accessibility**: `aria-describedby` links the trigger to the text; touch users
  must have another path to the information.
- **Common mistake**: tooltips on touch-only surfaces.

### Progress bar

- **Purpose**: show progress of a bounded job (backfill, bulk import).
- **States**: indeterminate, determinate, paused, failed, complete.
- **Rules**: show counts ("1,240 of 5,000"), not just a percentage; determinate
  only when the total is known; failure keeps the bar with an error and a retry.
- **Accessibility**: `role="progressbar"` with `aria-valuenow/min/max`, updated at
  a human pace not per record.
- **Common mistake**: indeterminate spinners on a 20-minute job.

### Input field

- **Purpose**: text, number, or money entry.
- **States**: default, focus, filled, error, disabled, read-only, help-visible.
- **Rules**: label above the field, always visible; help text below; errors below
  the field and summarised at the top of long forms; money fields use the shop's
  currency and never round silently.
- **Accessibility**: label is programmatically associated; error text linked via
  `aria-describedby`; `aria-invalid` set on error.
- **Common mistake**: placeholder-as-label.

### Tabs

- **Purpose**: split one resource into related sections.
- **States**: selected, unselected, disabled, loading (per-tab).
- **Rules**: 2-6 tabs; tab order is stable; tab state is reflected in the URL;
  never use tabs for a linear process (use steps).
- **Accessibility**: arrow-key navigation within the tab list, `role="tablist"`,
  `aria-selected`, and the panel labelled by its tab.
- **Common mistake**: tabs that lose unsaved edits when switched.

---

## Admin-Specific Patterns

### Bulk action bar

- **Purpose**: act on many rows at once.
- **States**: hidden, visible with count, running, partial success, failed.
- **Rules**: state the count and the scope ("12 selected, all pages"); actions are
  capped and show a pre-flight estimate; results are reported per row, not as one
  success toast.
- **Accessibility**: the bar announces its appearance; count updates are polite
  live-region updates.

### Plan gate

- **Purpose**: show the value of an unentitled feature without hiding it.
- **States**: locked, upgrading, unlocked.
- **Rules**: never 404 a gated feature; explain what it does, what plan unlocks it,
  and offer the billing upgrade path; enforce the entitlement server-side as well.
- **Accessibility**: the lock is conveyed in text, not only an icon.

### Scope re-auth prompt

- **Purpose**: recover when the merchant's grant lacks a required scope.
- **States**: detected, re-auth in flight, resolved, failed.
- **Rules**: name the missing scope in merchant terms, explain why it is needed,
  and route through the OAuth re-grant; never silently retry forever.
- **Accessibility**: the prompt is a banner with a real button, not a modal that
  blocks navigation.

---

## Navigation Patterns

### Navigation: push / pop

- **Purpose**: move between the app's pages without breaking App Bridge history.
- **Rules**: use App Bridge navigation so the admin's back button and deep links
  work; URL carries the filter/page state; leaving a dirty form prompts before pop.
- **Accessibility**: route changes move focus to the page `h1` and announce the
  page title.

### Focus management

- **Rules**: on route change, focus the main heading; on modal open, focus the first
  control or the title; on close, return focus to the opener; never leave focus on
  `<body>`.

### Escape / cancel

- **Rules**: Esc closes modals and popovers; on a dirty form, Esc opens a discard
  confirmation; Esc never submits.

---

## Feedback and Loading Patterns

### Loading state

- **Threshold**: show nothing for <200ms, skeletons for 200ms-2s, a labelled
  spinner with copy beyond 2s.
- **Rules**: skeleton mirrors the final layout; never blank-flash; disable
  mutating actions while loading.

### Empty state

- **Rules**: `EmptyState` with one primary action; distinguish "no data yet" from
  "no results for this filter" — the second offers clearing the filter.

### Error state

- **Rules**: state what failed in merchant language, keep what they typed, offer
  Retry, and log a correlation id; never surface raw GraphQL errors.

---

## Animation Standards

| Motion | Duration | Easing | Notes |
|--------|----------|--------|-------|
| Micro (hover/press) | 60-120ms | ease-out | Must not delay interaction |
| Panel/dialog open | 150-200ms | ease-out | Skipped under reduced motion |
| Content swap | 120-180ms | linear | Interruptible |
| Page transition | 150ms | ease-out | Never block input |

All motion respects `prefers-reduced-motion: reduce` → instant.

## Motion and Feedback Standards (no audio)

Admin apps do not play sound. Feedback is visual and haptic-free:

- Success → toast (polite live region)
- Failure → banner with a next step, plus inline field errors
- Progress → determinate bar with counts
- Long-running destructive operations → dialog with explicit confirmation, then a
  progress surface that survives navigation

---

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | [Pattern question — e.g. do we need a compact table density?] | [ux-lead] | Open |
