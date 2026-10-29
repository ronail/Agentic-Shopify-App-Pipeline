---
name: brainstorm
description: "Guided Shopify app concept ideation — from a raw merchant pain to a structured app concept document, framed as either an Original or a Competitor-Killer. Produces apps/<app>/design/concept.md and registers the app."
argument-hint: "[pain point, merchant niche, or 'open'] [--framing original|competitor-killer] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, WebSearch, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Shopify App Concept Ideation

Turns a vague merchant pain into one app concept that can survive
`/research` and the gate-1 approval.

Output: `apps/<app>/design/concept.md`, plus an appended entry in
`docs/registry/apps.json` when the app is new. Nothing else in the repo is
written — no code, no prototype, no architecture.

Follow `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`: present choices, let the user
decide, never invent merchant evidence.

## Phase 0 — Parse arguments and resolve review mode

1. **Seed**: everything before the flags is the seed — a merchant pain
   (`"refund reconciliation is manual"`), a niche (`"subscription coffee"`), or
   `open`.
2. **Framing**: `--framing original` or `--framing competitor-killer`. If
   absent, defer to Phase 3 (do not pick for the user).
3. **Review mode**: `--review full|lean|solo` overrides
   `production/review-mode.txt` for this run. Read the file if the flag is
   missing; `lean` if the file is missing too. Gate rules:
   `.claude/docs/director-gates.md`.

## Phase 1 — Context read

- `request.md` — goal, success criteria, `## Apps in scope`. An idea that
  duplicates a listed app is a scope change, not a new app: say so and offer
  `/update-request` instead.
- `docs/registry/apps.json` — apps already in the pipeline. Avoid overlap; if
  two apps would share a surface, note the boundary now.
- `docs/shopify-api-reference/` — what the pinned API version can actually do.
- Existing concepts: `apps/*/design/concept.md`.

Report in three lines: what exists, what the seed is, what is missing.

## Phase 2 — Merchant pain discovery

Ask one question at a time; stop as soon as the pain is concrete.

| Probe | Question | Why it matters |
|-------|----------|----------------|
| Moment | When in the merchant's day does this hurt? | Anchors the app to a real admin screen |
| Frequency | Daily, weekly, or seasonal? | Decides whether the app is a workflow or a one-off tool |
| Cost | Minutes per occurrence, orders affected, revenue at risk | Justifies a paid plan |
| Workaround | What do they do today — spreadsheet, manual edit, another app? | Defines the thing you must beat |
| Trigger | What changed — new API, new store scale, policy change? | Timing for the pitch |

Then a short evidence pass (optional, `research-specialist` via Task when the
user wants it): merchant forum threads, app store review complaints on
incumbents, Shopify changelog entries that unlock the job. Cite what you find;
never present a guess as evidence.

If the pain cannot be stated in one sentence with a number in it, say so and
propose two narrower seeds.

## Phase 3 — Choose the framing

Two framings, different burdens of proof:

| Framing | Definition | Required evidence | When it wins |
|---------|------------|-------------------|--------------|
| **Original** | No installed app does this job today | Named manual workaround, and a reason incumbents have not covered it | Unserved job, new API surface, a niche too small for a category leader |
| **Competitor-Killer** | A named app does this and you displace it | Two or more named competitors, the specific gap (pricing, API coverage, admin UX, review pain), and a wedge that survives a copy attempt | Crowded category where the leader is visibly weak |

Ask: "Is this an Original or a Competitor-Killer?"

- **Original** → write down why the job is unserved: missing API, wrong
  economics, or a workflow merchants do not know they can automate.
- **Competitor-Killer** → complete the table below before any concept prose:

| Competitor | Installs / rating | Their gap | Our wedge | Copy risk |
|------------|-------------------|-----------|-----------|-----------|

A Competitor-Killer with one competitor, or a wedge that is "cheaper", is a weak
concept — say so plainly and offer to reframe as an Original with a narrower job.

## Phase 4 — Shape the concept

Fill these, confirming each with the user:

1. **Slug and name** — lowercase-hyphen slug, <= 30 chars, unique in the
   registry. `apps/<slug>/` is the only home for the app's work.
2. **Merchant job** — `When <situation>, I want <motivation>, so I can <outcome>`.
3. **Pain evidence** — the numbers from Phase 2, with sources.
4. **Wedge** — the one thing this app does better; one sentence.
5. **Shopify surface map** — which surfaces the app needs:

| Surface | Use it when | Notes |
|---------|-------------|-------|
| Embedded Admin app (Polaris + App Bridge) | Merchants configure or monitor | Default surface for most apps |
| Admin action / block extension | A task belongs on an existing admin page | Cheaper than a full page; needs a reason not to build a page |
| Theme app extension | Storefront rendering | Needs theme support and app-block adoption |
| Checkout UI extension | Post-purchase or checkout steps | Only Plus plans can customise checkout fully |
| Shopify Functions | Discount, delivery, payment, cart validation logic | Runs in a sandbox; no network calls |
| Webhooks | Reacting to orders, products, app uninstalls | Needs idempotency and a retry story |
| Storefront API / GraphQL Admin API | Data reads and writes | Pin the version; note protected customer data |

6. **Monetisation** — free, flat monthly, usage-based, or a free tier with a
   paid upgrade. Name the Billing API shape (recurring charge, usage charge) and
   the line the merchant crosses to pay.
7. **MVP scope** — at most three merchant flows. Anything else goes to
   `Out of scope`.
8. **Out of scope** — explicit, so `/scope-check` has something to hold.
9. **Risks** — App Store category review, protected customer data approval,
   API rate limits, a platform feature that could absorb the job.
10. **Success metric** — one number that proves the app works
    (for example: "setup completed by 60% of installs within 10 minutes").

## Phase 5 — Write the concept

Write `apps/<app>/design/concept.md`:

```markdown
# <App name> — Concept

Slug: <slug>
Framing: Original | Competitor-Killer
Date: <YYYY-MM-DD>
Status: draft | approved

## Merchant Job
## Pain Evidence
## Wedge
## Shopify Surface Map
## Monetisation
## MVP Scope (<= 3 flows)
## Out of Scope
## Risks
## Success Metric
## Open Questions
```

Then, only if the app is new:

1. Append one entry to `docs/registry/apps.json` — `slug`, `name`, `purpose`,
   `stage: "research"`, `last_approved_gate: null`, `created`. Append-only: never
   reorder or rewrite other entries.
2. Create `apps/<slug>/status.md` (`Stage: research`,
   `Last approved gate: none`, `Blockers: none`), `apps/<slug>/README.md`, and
   `apps/<slug>/approvals.json` (`{}`).
3. Create `production/apps/<slug>/{sprints,milestones,session-state}/` with
   `.gitkeep` files.
4. Mirror the app into `request.md` `## Apps in scope` and add a matching row to
   `request-history.md`. `.claude/hooks/track-request-changes.sh` enforces the
   pair; a missing history row fails the hook.

Show the diff of every file written and let the user object before moving on.

## Phase 6 — Review gate

Resolve review mode, then (unless `solo`):

- **`product-director`** — is the job real, is the framing honest, is the MVP
  small enough? Use the product-director gate and verdict format defined in
  `.claude/docs/director-gates.md`.
- **`growth-lead`** — is there a wedge a merchant would install today?
- **`app-store-reviewer`** — does the concept risk a rejection (misleading
  listing, unsupported surface, policy-adjacent claims)?

`lean` runs the product-director gate only. Pass the concept path, the framing
table, and the surface map as context. Handle the verdict:

- **APPROVED** → set `Status: approved` in the concept.
- **NEEDS REVISION** → apply the specific fixes, re-run once.
- **MAJOR REVISION NEEDED** → return to Phase 2 or 3 with the objection quoted.

## Phase 7 — Hand off

Say what is next and why, in one line each:

- `/research <app>` — validate demand, competitor installs, and API access.
- `/mmmvp-proposals <app>` — turn the concept into MMMVP options for gate-1.
- `/design-review <path>` — if the concept is going straight into specs.

Do not run the next skill unasked. Verdict: **COMPLETE** once the concept is
written, registered, and either approved or explicitly parked as draft.
