---
name: ux-review
description: "Validates a Shopify admin UX spec against Polaris component reality, App Bridge context rules, state coverage, and WCAG 2.1 AA. Returns APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED with file and line references."
argument-hint: "[file path | app slug | 'all'] [--depth full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: ux-lead
---

# UX Spec Review

Read-only gate between `/ux-design` and implementation. It reports; it never
edits. Output is a verdict plus a numbered fix list with `file:line` references.

## Phase 0 — Parse

- `path` → review that file.
- `app slug` → review every file under `apps/<app>/design/ux/`.
- `all` → every app in `docs/registry/apps.json`, ordered by stage.
- Nothing → ask, offering apps and their UX spec counts.
- `--depth full|lean|solo` — how many agents this run spawns; default `full`.
  Separate from `production/review-mode.txt`.

If the target file does not exist, list the closest matches and stop.

## Phase 1 — Read with context

- The spec under review.
- `apps/<app>/design/concept.md` — merchant job and out-of-scope.
- `docs/architecture/apps/<app>/requirements.yaml` — requirement IDs, edge cases,
  acceptance criteria.
- `docs/architecture/apps/<app>/control-manifest.md` — error shape and limits.
- Other specs in the same directory — for duplicated or conflicting patterns.
- `.claude/rules/ui-code.md` — the app-level UI rules this spec must honour.

## Phase 2 — Polaris reality check

1. **Component names** — every named component exists in Polaris. Invented
   components are **BLOCKER**. Map the intent to the closest real component.
2. **Layout primitives** — `Page`, `Layout`, `Card`, `BlockStack`, `InlineStack`,
   `Box` used before custom containers.
3. **Table choice** — `IndexTable` for admin tables with bulk actions,
   `ResourceList` for record browsing, `DataTable` for static figures. Using the
   wrong one is **MAJOR**.
4. **Form controls** — `FormLayout` with labels and inline help; tooltips alone
   are **MAJOR**.
5. **Feedback** — App Bridge `toast` for success, `Banner` for errors and
   warnings, `Modal` for destructive confirmation. `window.alert` or
   `window.confirm` anywhere is **BLOCKER**.
6. **Styling** — design tokens only. Raw hex, hardcoded spacing, or custom CSS
   without a stated reason is **MAJOR**.
7. **Navigation** — nav menu defined through App Bridge; no links that leave the
   embedded frame or target `window.top`.
8. **Copy source** — merchant strings come from a translation source, not
   literals buried in components.

## Phase 3 — App Bridge and embedded context

- Shop, host, and locale read from the App Bridge context (`useAppBridge`), never
  parsed from the URL by hand. Hand parsing is **BLOCKER**.
- Every Admin API call is made from a route loader or action with a session
  token; browser-side API calls are **BLOCKER**.
- Expired session has a path back: re-auth prompt or reload, not a silent empty
  screen.
- Modal sizing and page titles follow App Bridge conventions; page title set per
  route.
- Deep links from admin pages (order, product, customer detail) are declared,
  with the parameters they accept.
- Scopes in the spec match the operations the screen performs. A missing scope is
  **BLOCKER**; an unused scope is **MAJOR** (it costs a review question and
  merchant trust).

## Phase 4 — State coverage

Every data surface needs all of these, expressed with the right component:

| State | Required | Component |
|-------|----------|-----------|
| Loading | yes | `SkeletonPage` / `SkeletonBodyText` |
| Empty, first run | yes | `EmptyState` with a primary action |
| Empty, filtered | yes | `EmptyState` with clear-filters action |
| Error | yes | `Banner tone="critical"` plus retry |
| Partial failure | when work is chunked | `Banner tone="warning"` with per-chunk status |
| Permission denied | when scopes or roles differ | explanatory copy, no dead controls |
| Plan-gated | when monetised | upgrade path naming plan and price |
| Saving | when there is a write | disabled primary plus progress |
| Success | after every write | App Bridge toast |

Missing loading, empty, or error is **BLOCKER** — those three are the merchant's
most common experience. A blocking spinner over the whole page is **MAJOR**.

## Phase 5 — Accessibility, WCAG 2.1 AA

Verify each is stated and satisfied by the described components:

1. Text contrast 4.5:1; large text and UI boundaries 3:1.
2. Visible focus indicator; logical order; no keyboard traps.
3. Focus moved to new content on navigation or modal open, returned on close.
4. Every control has an accessible name; icon-only buttons labelled.
5. Errors identified in text and programmatically associated with the field.
6. Headings in order; tables expose headers; landmarks present.
7. Status not conveyed by colour alone.
8. `prefers-reduced-motion` respected for animation.
9. 200% text scaling without loss of content or function.
10. Touch and pointer targets large enough, with spacing between adjacent ones.

Cite the section and line for each failure. "Accessibility: good" is not a
finding.

## Phase 6 — Content and performance

- Copy is plain, short, and free of internal vocabulary (no "webhook",
  "mutation", "scope"). Merchant-visible numbers carry units and currency.
- Dates, numbers, currency follow the shop locale, not the browser default.
- Empty and error copy tells the merchant what to do next; apology-only copy is
  **MINOR** but should be fixed.
- Initial route payload target under 250 KB gzipped, heavy panels lazy-loaded,
  perceived load under 1.5 s p75. No target stated is **MAJOR**.
- Analytics events carry no customer personal data; any event with an email,
  phone, or address property is **BLOCKER**.

## Phase 7 — Cross-spec consistency (app-wide runs)

For a whole app or `all`:

- The same interaction (bulk edit, save bar, filter persistence) behaves the same
  way on every screen, or the difference is justified in `patterns` mode.
- Navigation order in `flows.md` matches the nav entries declared per screen.
- No two specs name different Polaris components for the same job.
- Every requirement with a merchant-facing outcome has at least one screen.

## Phase 8 — Verdict

```text
UX REVIEW — <path or app> (<n> specs)
Depth: <full|lean|solo> | Review mode: <full|lean|solo>

VERDICT: APPROVED | NEEDS REVISION | MAJOR REVISION NEEDED

BLOCKERS (n)
1. <finding> — <file>:<line> — <fix>

MAJOR (n)
MINOR (n)

COVERAGE
- Polaris components named: n | unknown: n
- States covered: n/9 per screen
- AA checks passed: n/10
- Requirements with a screen: n/m
```

Verdict rules:

- **APPROVED** — no blockers, no majors, all three core states per screen, all AA
  items addressed.
- **NEEDS REVISION** — local fixes; the screen's design intent survives.
- **MAJOR REVISION NEEDED** — invented Polaris components, unmapped requirements,
  browser-side API calls, or a missing accessibility section.

Agents, honouring `--depth`:

| `--depth` | Who runs |
|-----------|----------|
| `full` | `polaris-specialist`, `accessibility-specialist`, `ux-lead`, plus `app-bridge-specialist` when navigation or extensions are involved |
| `lean` | `polaris-specialist` and `accessibility-specialist` |
| `solo` | No agents; the checklist above is the review |

Merge their findings, deduplicate, keep the highest severity.

## Hand off

- APPROVED → `/create-stories <app>` or `/dev-story` for the screen.
- NEEDS REVISION → back to `/ux-design <screen>` with this list.
- MAJOR → `/ux-design flows` first if navigation is the root cause.
- Repeated accessibility findings across screens → raise once in
  `apps/<app>/design/ux/accessibility.md` instead of re-litigating per screen.
