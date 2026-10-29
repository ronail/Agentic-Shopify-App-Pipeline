---
name: architecture-decision
description: "Author an Architecture Decision Record for one Shopify app — context, the decision, alternatives, consequences, and the exact Shopify API surface it commits to. Uses the ADR template, tracks Proposed to Accepted to Superseded, and registers cross-app stances."
argument-hint: "[app] \"[title]\" [--supersedes ADR-NNNN] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, request_user_input, clarify, Bash
model: sonnet
---

# Architecture Decision Record

One ADR per decision that constrains future work. An ADR is not a tutorial and
not a design doc: it records why one option won, what it costs, and what it
forbids.

Output: `docs/architecture/apps/<app>/ADR-NNNN-<slug>.md`, from
`.claude/docs/templates/architecture-decision-record.md`.

## Phase 0 — Parse

1. **App** — required; validate against `docs/registry/apps.json`.
2. **Title** — quoted, short, decision-shaped: "Use token exchange instead of
   OAuth callback for embedded sessions", not "Auth".
3. **`--supersedes ADR-NNNN`** — the ADR this one replaces, if any.
4. **Review mode** — `--review` override, else `production/review-mode.txt`,
   else `lean`.
5. **Retrofit check** — if the decision is already implemented in `apps/<app>/`,
   say so: this ADR will document reality, and every claim must be verified
   against the code, not assumed.

## Phase 1 — Number and locate

```bash
ls docs/architecture/apps/<app>/ADR-*.md 2>/dev/null | sed 's/.*ADR-//' | cut -d- -f1 | sort -n | tail -1
```

Next number is that value + 1, zero-padded to four digits. If the app directory
does not exist, create `docs/architecture/apps/<app>/`. Never renumber or delete
an existing ADR.

## Phase 2 — Conflict check before writing

Read, in this order:

1. `docs/registry/architecture.yaml` — stances other apps already depend on.
   A decision that contradicts a registered stance needs either a superseding ADR
   for the stance or a narrower scope.
2. Every `ADR-*.md` in this app's directory — especially ones marked Accepted.
3. `docs/architecture/apps/<app>/architecture.md` — the section this decision
   changes.
4. `docs/architecture/apps/<app>/requirements.yaml` — the requirement IDs this
   decision serves. An ADR serving no requirement is either misplaced or the
   requirements are incomplete; say which.

Report conflicts before drafting. A conflict found now costs one conversation; a
conflict found in implementation costs a sprint.

## Phase 3 — Draft, section by section

Follow the template, with the Shopify adaptations below. Confirm each section
with the user; an ADR the team has not read is not accepted.

### Header and status

```yaml
ADR-NNNN: <title>
Status: Proposed
Date: <YYYY-MM-DD>
Last verified: <YYYY-MM-DD>
Decision makers: <roles from .claude/agents/>
App: <app>
```

Status lifecycle, enforced:

- **Proposed** — drafted, not yet approved. Stories may not depend on it.
- **Accepted** — approved by the app's technical owner. Binding.
- **Superseded by ADR-NNNN** — replaced. The body stays; only the status and a
  link change.
- **Deprecated** — no longer relevant (feature removed), not replaced.

Never flip an ADR straight from Proposed to Superseded. Never edit an Accepted
decision's substance — write a new ADR and link both ways.

### Summary

Two sentences: the problem, the chosen approach. A reader scanning twenty ADRs
decides from this line whether to open the file.

### Shopify Platform Compatibility

Replaces the generic compatibility block with platform facts:

| Field | Value |
|-------|-------|
| **API version** | `<version>` — pinned in `docs/shopify-api-reference/<version>/` |
| **Surface** | Admin GraphQL / Admin REST / Webhooks / Admin extension / Theme extension / Checkout extension / Function / Storefront API |
| **Knowledge risk** | LOW (stable, well documented) / MEDIUM (recent change, verify) / HIGH (new or changed surface, must verify on a dev store) |
| **References consulted** | Exact files under `docs/shopify-api-reference/<version>/` and the Shopify changelog entries used |
| **Version-dependent behaviour** | Named behaviour that differs by API version, or `None` |
| **Verification required** | Concrete checks on a dev store before this ships, or `None` |

If knowledge risk is MEDIUM or HIGH, the ADR must name a re-validation trigger —
an API version bump, a scope change, or a platform deprecation.

### Shopify API Surface

Required. This is what makes the ADR implementable:

| Operation / topic | Type | Scopes | Notes |
|-------------------|------|--------|-------|
| `query order(id:)` | Admin GraphQL | `read_orders` | protected customer fields |
| `orders/create` | Webhook | none | idempotent on order id |

Include cost and pagination notes for anything list-shaped. Mark anything you
could not verify in the pinned reference as `UNVERIFIED` and carry it into Risks.

### App Requirements Addressed

Required. List the requirement IDs from `requirements.yaml` this decision
serves, one line each with the outcome:

| Requirement | What this decision settles |
|-------------|---------------------------|
| `REQ-BUNDLE-004` | Discount stacking order for mixed bundles |

If a requirement is only partly served, say which part is still open.

### ADR dependencies

- **Depends on** — ADRs that must be Accepted first.
- **Enables** — decisions this unblocks.
- **Blocks** — the epic or story that cannot start until this is Accepted.
- **Ordering note** — anything else about sequence.

### Context

Problem statement, current state, constraints, requirements. Constraints include
the real ones: API rate and cost budgets, extension surface limits, App Store
review rules, plan tiers, team size. A constraint list without a number is a wish
list.

### Decision

The specific choice, detailed enough to implement without asking. Include:

- the chosen approach and its boundary (what it does not cover)
- an ASCII diagram of the resulting flow
- key interfaces: function signatures, route shapes, GraphQL documents, webhook
  handler contract, data schema deltas
- implementation guidelines: where the code goes, what must be tested, what must
  not be done

### Alternatives considered

At least two, each with description, pros, cons, relative effort, and the precise
rejection reason. "Too complex" is not a reason; "adds a second session store and
a migration for 40k shops to save one API call" is.

### Consequences

Positive, negative, neutral — honestly. Name the merchant-visible cost, the
operational cost (on-call, migrations), and the reversibility.

### Risks

| Risk | Probability | Impact | Mitigation |

Include platform risk (API deprecation, scope review rejection, rate-limit
changes) and the mitigation that would actually run.

### Performance implications

Real backend metrics, not frame times:

| Metric | Before | Expected after | Budget |
|--------|--------|----------------|--------|
| Admin route payload | | | 250 KB gzipped |
| p75 route load | | | 1.5 s |
| Admin API cost per merchant action | | | within the shop budget |
| Webhook handling time | | | respond < 500 ms |

### Migration plan and rollback

Steps, what breaks at each step, how it is verified, and the rollback. For a
schema change: forward migration, backfill, and the read path during backfill. If
the app is not yet live, say so — "no merchants affected" is a valid migration
plan.

### Validation criteria

Checkboxes that prove the decision was right after implementation. Tie each to a
test type from the architecture's testing strategy.

## Phase 4 — Write

Write the file with the template's structure and the adaptations above, under
roughly 300 lines. Set `Status: Proposed` unless the user says the decision is
already approved.

Then update, if the decision constrains other work:

- `docs/architecture/apps/<app>/architecture.md` — the affected section, plus the
  ADR index row.
- `docs/registry/architecture.yaml` — a stance entry, only when other apps must
  agree with it (data ownership, API convention, extension strategy). Internal
  detail stays in the ADR.

## Phase 5 — Review gate

Unless `solo`, and matching review mode:

- `technical-director` — is this the right call for this app, at this stage?
- `app-architect` — boundaries, data model, surface choice.
- `security-specialist` — required whenever the decision touches customer data,
  auth, secrets, or webhooks.
- `api-lead` / `graphql-specialist` — API cost, pagination, scope minimality.
- `billing-specialist` — charge type, plan gating.
- `performance-analyst` — when the decision moves a budget.

`lean` runs technical-director only, plus security-specialist when the decision is
security-relevant. Pass the ADR path and the conflict check result.

Verdict handling: **APPROVED** → set `Status: Accepted`, update `Last verified`;
**NEEDS REVISION** → apply and re-review; **REJECTED** → keep the ADR as Proposed
with the rejection reason in Consequences, or delete it if it was only a draft —
never leave a rejected decision marked Accepted.

## Phase 6 — Superseding an existing decision

1. Write `ADR-<new>-<slug>.md` that states the new decision and names the old one.
2. In the old ADR, change only `Status: Superseded by ADR-<new>` and add the
   date.
3. In the new ADR, list the old one under Context with the reason it failed.
4. Update `docs/registry/architecture.yaml`: if a stance changed, set
   `superseded_by: ADR-<new>` and keep the old value in a comment.
5. Check `architecture.md` and any story that encoded the old decision; list them
   as follow-up work.

Never rewrite history by editing the old body.

## Hand off

- Another open decision → `/architecture-decision <app> "<next title>"`.
- Decisions settled → `/architecture-review <app>` to catch cross-ADR conflicts.
- ADR accepted and stories blocked on it → `/create-stories <app>`.
- Decision affects code already written → `/tech-debt` to log the gap.

Verdict: **COMPLETE** — ADR written, status set, conflicts reported, stances
updated where the decision binds other apps.
