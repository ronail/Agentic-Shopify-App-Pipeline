---
name: ux-design
description: "Section-by-section UX spec authoring for one Shopify admin screen or flow — Polaris components, App Bridge context, every state, WCAG 2.1 AA. Writes apps/<app>/design/ux/<screen>.md and hands off to /ux-review."
argument-hint: "[screen name | 'flows' | 'patterns' | 'accessibility'] [--app slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, request_user_input, clarify, Task
model: sonnet
agent: ux-lead
---

# Admin UX Spec Authoring

Produces one spec per merchant-facing screen, for the embedded admin app built
with Polaris and App Bridge. Follow
`docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`: propose, confirm, then write.

Modes:

| Argument | Output |
|----------|--------|
| `<screen name>` | `apps/<app>/design/ux/<screen-slug>.md` |
| `flows` | `apps/<app>/design/ux/flows.md` — entry points, navigation, cross-screen journeys |
| `patterns` | `apps/<app>/design/ux/interaction-patterns.md` — reusable behaviours (bulk edit, save bar, optimistic update) |
| `accessibility` | `apps/<app>/design/ux/accessibility.md` — the app-level AA commitment |

## Phase 0 — Parse and confirm scope

1. **App** — from `--app`, or ask with the list from `docs/registry/apps.json`.
   Reject an app that is not registered.
2. **Mode** — as above. Unknown argument → ask which of the four.
3. **Screen slug** — kebab case, unique under `apps/<app>/design/ux/`.
4. Check that `docs/architecture/apps/<app>/requirements.yaml` exists. Without
   requirements, warn: the spec will drift from acceptance criteria. Offer to run
   with the concept only, but say the risk out loud.

## Phase 1 — Context read

| File | What it gives you |
|------|-------------------|
| `apps/<app>/design/concept.md` | Merchant job, MVP scope, out of scope |
| `docs/architecture/apps/<app>/requirements.yaml` | `REQ-<AREA>-<NNN>` IDs, rules, edge cases |
| `docs/architecture/apps/<app>/control-manifest.md` | Error shape, naming, limits |
| `apps/<app>/design/ux/flows.md` | Where this screen sits |
| `docs/shopify-api-reference/<version>/` | Fields the screen can show |
| `.claude/rules/ui-code.md` | Polaris, App Bridge, states, performance rules |

Then state, in three lines: the screen's job, the requirement IDs it serves, and
what the data source is.

## Phase 2 — The nine sections, one at a time

Write the file incrementally, one section per exchange. Confirm before moving on;
a section the user has not seen is not agreed.

### 1. Purpose and entry point

- One sentence: what the merchant comes here to do.
- Requirement IDs served.
- Where it is reached from: app nav item, a card on the app home, a deep link
  from an order or product page, an admin action extension.
- Does it need a nav menu entry? The embedded app's nav is set once via App
  Bridge; name the placement (first, or after which item).

### 2. Merchant job and success

`When <situation>, I want <motivation>, so I can <outcome>`.

One primary success action, stated as an observable outcome ("bundle created and
active on the storefront"), not a click ("presses Save"). Then the failure case
the merchant must be able to recover from.

### 3. Layout — Polaris components

Describe the layout as a component tree, not as pixels:

```text
Page (title, primaryAction, secondaryActions)
├── Layout
│   ├── Layout.Section
│   │   ├── Card
│   │   │   ├── IndexTable (rows, bulkActions, sort, pagination)
│   │   │   └── EmptyState (heading, body, action)
│   │   └── Banner (tone: warning, dismissible)
│   └── Layout.Section variant="oneThird"
│       ├── Card (summary)
│       └── Card (tips)
```

Rules:

- Name only real Polaris components. If the idea needs something Polaris lacks,
  say which component comes closest and what the gap costs.
- Use Polaris layout primitives (`Page`, `Layout`, `Card`, `BlockStack`,
  `InlineStack`, `Box`) before any custom CSS.
- Custom CSS needs a written reason and design tokens; raw hex is rejected.
- Data-heavy lists: `IndexTable` for admin tables, `ResourceList` for records
  with a primary field, `DataTable` for read-only figures.
- Destructive work: `Modal` with an explicit confirm label naming the object.
- Forms: `FormLayout`, `TextField`, `Select`, `Checkbox`, `ChoiceList`,
  `RangeSlider` — with inline help text, not tooltips alone.

State the UI regions and what each one owns, so a builder knows where new
controls go.

### 4. Data and Admin API calls

- Route modules: `app/routes/app.<page>.tsx` (one module per page).
- Every read and write goes through a loader or action; components never call
  Shopify APIs from the browser.
- GraphQL documents named in the spec: operation name, fields, pagination
  (cursor-based, page size), and the cost estimate for a large store.
- Scopes required by this screen, with a reason per scope.
- Caching: what may be cached per shop, and for how long.

### 5. States — all of them

A screen is not specified until every row is filled:

| State | Polaris expression | Merchant sees |
|-------|--------------------|---------------|
| Loading | `SkeletonPage`, `SkeletonBodyText` | Structure, no spinner-only screens |
| Empty (first run) | `EmptyState` with a primary action | What to do next |
| Empty (filtered) | `EmptyState` with "clear filters" | Why nothing matched |
| Error | `Banner tone="critical"` plus retry | What failed and what to do |
| Partial | `Banner tone="warning"` per failed chunk | What loaded, what did not |
| Permission denied | Explanation, no dead controls | Which scope or role is missing |
| Plan-gated | Upgrade path with the plan name and price | What they get by upgrading |
| Saving | Disabled primary + inline progress | The save is in flight |
| Success | App Bridge toast | Confirmation without a page reload |

Explicitly forbid: toast-only errors, silent failures, and blocking spinners
over the whole page.

### 6. Interactions

- Primary action and its keyboard shortcut, if any.
- Bulk actions: how rows are selected, what the confirmation says, what happens
  to partially valid selections.
- Filters and saved views: which are persisted, and where (URL, shop config).
- Optimistic updates: which fields, and how a failure rolls back visibly.
- Unsaved-changes guard (`Form` with a save bar), and what happens on nav away.
- Long-running work: what queues, what the merchant sees while it runs, and how
  they find the result later.

### 7. Copy

- Title, subtitle, primary action label, empty-state heading and body.
- Error messages: what happened, why, what to do. No apology-only messages.
- Merchant-facing copy is short, plain, and free of internal vocabulary
  (no "webhook", "mutation", "scope" in the UI).
- Mark every string that needs translation; locale comes from App Bridge, and
  dates, numbers, and currency follow the shop locale.

### 8. Accessibility — WCAG 2.1 AA

Commit to each, and note how the screen satisfies it:

- Contrast 4.5:1 for text, 3:1 for UI boundaries and focus rings.
- Visible focus on every interactive element; focus moves to the new content
  after navigation or modal open, and returns on close.
- Full keyboard operability, including bulk selection and menus; no traps.
- Accessible names on all controls; icon-only buttons labelled.
- Errors announced and associated with their field.
- Headings in order; tables expose header cells; landmark regions present.
- Status is not conveyed by colour alone (icon or text as well).
- Motion respects `prefers-reduced-motion`.
- Text scales to 200% without loss of content or function.

### 9. Responsive, performance, analytics

- Behaviour at narrow widths (embedded admin is often a narrow column): which
  columns drop, what collapses, what stays.
- Initial route payload target: under 250 KB gzipped; heavy panels lazy-loaded;
  perceived load under 1.5 s p75.
- Analytics events: name, trigger, properties. No customer personal data in
  properties.

### 10. Acceptance criteria

Checklist a `qa-tester` can run without asking:

- [ ] Every state reachable and rendered with the named component
- [ ] Every Admin API call traced to a loader or action
- [ ] Keyboard-only pass completes the primary job
- [ ] Contrast verified on every text/background pair
- [ ] Empty state offers a next action
- [ ] Plan-gated path shows the upgrade option
- [ ] No customer personal data in analytics

## Phase 3 — Write the file

Use the template in `.claude/docs/templates/ux-spec.md` where a section matches;
otherwise use the section order above. Header block:

```markdown
# <Screen name> — UX Spec

App: <app>
Screen: app/routes/app.<page>.tsx (planned)
Requirements: REQ-<AREA>-<NNN>, ...
Polaris surfaces: Page, IndexTable, EmptyState, Banner, Modal
Status: draft | reviewed
Date: <YYYY-MM-DD>
```

Cross-check the finished spec against the requirements' edge cases — empty
store, huge catalog, multi-currency, partial failure. A UX spec that ignores
them will fail `/ux-review`.

## Phase 4 — Specialist pass (optional)

- `full` review mode → `polaris-specialist` on component choices and
  `accessibility-specialist` on section 8. Pass the file path only; they read the
  spec themselves.
- `lean` → one accessibility read.
- `solo` → skip; `/ux-review` will catch it.

## Phase 5 — Hand off

- `/ux-review apps/<app>/design/ux/<screen>.md` — the gate before implementation.
- `/ux-design flows` when the screen changes navigation.
- `/design-review <app>` when several screens changed at once.

Verdict: **COMPLETE** — spec written, every state filled, requirement IDs
attached, accessibility section explicit.
