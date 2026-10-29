---
name: quick-design
description: "Lightweight feature spec for a small change to an existing Shopify app — a settings tweak, an extra filter, a copy or pricing change. Skips full requirements authoring when docs/architecture/apps/<app>/requirements.yaml already covers the area. Produces a quick spec that embeds into a story."
argument-hint: "[app] [brief description of the change]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Quick Design

The lightweight path for a change that fits one story and does not move an
approved requirement. The heavyweight path is a requirements update in
`docs/architecture/apps/<app>/requirements.yaml` plus `/design-review`.

Output: `apps/<app>/design/quick-specs/<slug>.md`, ready to paste into a story.

## Phase 0 — Parse

1. `app` — must exist in `docs/registry/apps.json` and have
   `docs/architecture/apps/<app>/requirements.yaml`. If either is missing, say
   so and route: no app → `/brainstorm` or `/scaffold`; no requirements →
   `/create-control-manifest` or the full requirements path.
2. `change` — free text. If it is empty, ask for it in one sentence.
3. Resolve review mode (`--review` override, else
   `production/review-mode.txt`, else `lean`).

## Phase 1 — Decide the path (say the answer out loud)

| Signal | Quick spec | Full path instead |
|--------|-----------|-------------------|
| Effort | Under one day of implementation | More than one day |
| Requirements | Covered by an existing `REQ-<AREA>-<NNN>` | Needs a new or changed requirement |
| API surface | Same scopes, same queries | New scope, new webhook topic, new extension |
| Data model | No migration | New table, column, or index |
| Billing | Same plan gating | New plan, new charge type |
| Merchant surface | Same screen, same flow | New screen, new nav entry |
| Reversibility | Flip a config or revert one PR | Merchant data must be migrated |

Any "full path" cell → stop, and hand off to the requirements update or
`/create-stories`. Do not stretch a quick spec over a structural change.

## Phase 2 — Read the neighbourhood

- `docs/architecture/apps/<app>/requirements.yaml` — the requirement IDs this
  change sits under.
- `docs/architecture/apps/<app>/control-manifest.md` — conventions the change
  must respect (naming, error shape, rate-limit handling).
- The UX spec for the affected screen under `apps/<app>/design/ux/`.
- The relevant rule in `.claude/rules/` (`ui-code.md`, `graphql-code.md`,
  `webhook-code.md`, `billing-code.md`, `auth-code.md`, `data-files.md`).
- `docs/shopify-api-reference/<version>/` — confirm the fields and arguments
  already exist in the pinned version.

Quote the requirement IDs you found. A quick spec that cites nothing is a guess.

## Phase 3 — Fill the spec

Confirm each section with the user; keep the whole file under one screen where
possible.

```markdown
# Quick Spec — <change>

App: <app>
Date: <YYYY-MM-DD>
Requirement: REQ-<AREA>-<NNN> (unchanged | extended)
Size: <S | M>

## Change
<two sentences: what changes for the merchant>

## Merchant Job
When <situation>, I want <motivation>, so I can <outcome>.

## Rules
- <precise behaviour, including defaults>

## API Surface Delta
- Queries / mutations: <names, or None>
- Scopes added: <list, or None>
- Webhooks: <topics, or None>
- API version: <pinned version>

## UI Delta
- Screen: <route or screen name>
- Polaris components: <Page, Card, IndexTable, Banner, ...>
- States: loading | empty | error | plan-gated
- Copy: <merchant-facing strings>

## Edge Cases
- Empty store, huge catalog (100k+ variants), multi-currency, partial failure,
  expired session, uninstalled mid-flow

## Acceptance Criteria
- [ ] <observable, testable condition>
- [ ] <observable, testable condition>

## Rollback
<config flag, revert commit, or data fix>

## Out of Scope
<what this deliberately does not change>
```

Rules for the content:

- Numbers get a default and a reason. "Batch size 50 — stays under the Admin API
  cost budget for a 100k-variant store" beats "batch size 50".
- Every UI state names its Polaris component. An empty state without a next
  action is a failed spec.
- Acceptance criteria are things a `qa-tester` can check without asking you.

## Phase 4 — Write and attach

Write `apps/<app>/design/quick-specs/<slug>.md` (slug from the change, kebab
case, unique in that directory). If a matching story already exists under
`production/apps/<app>/sprints/`, offer to embed the spec into the story body
instead of leaving two sources of truth — one copy only.

Do not touch `requirements.yaml` unless Phase 1 said "extended"; if it did, add
the requirement delta and note it in the spec header.

## Phase 5 — Optional review

`full` mode: spawn `app-architect` for a one-pass check that the API surface
delta and edge cases hold. `lean` and `solo`: skip. A quick spec never needs a
director gate.

## Phase 6 — Hand off

- `/create-stories <app>` when the change is not yet a story.
- `/dev-story` when the story exists and is ready.
- `/ux-design <screen>` when the UI delta is bigger than one component swap.

Verdict: **COMPLETE** — spec written, path decision stated, requirement link
recorded.
