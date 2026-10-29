# Session: One Story From Backlog to Done

**Skills:** `/create-stories` → `/story-readiness` → `/dev-story` → `/code-review` → `/story-done`
**Agents:** `lead-engineer`, `graphql-specialist`, `qa-lead`
**Duration:** ~60 minutes
**Complexity:** Medium

`order-tags` has Accepted ADRs, a control manifest, and epics. This session takes
a single story — "add a tag when an order matches a total rule" — through the
whole build loop.

---

## Turn 1 — `/create-stories`

```
User: /create-stories order-tags epic-1-rule-engine

lead-engineer: "Reading the epic, both ADRs, the control manifest (version
                2026-10-29) and requirements.yaml.

                Proposed decomposition — 4 stories, in dependency order:

                1. `story-001-rule-model.md`      REQ-TAG-001, REQ-TAG-005
                   rule + condition tables, repository module, migrations
                2. `story-002-rule-evaluation.md` REQ-TAG-001
                   pure evaluation function, no I/O, unit tested
                3. `story-003-tag-write-queue.md` REQ-TAG-003, REQ-TAG-008
                   per-order queue, tagsAdd/tagsRemove, no-op pre-check
                4. `story-004-orders-webhook.md`  REQ-TAG-002
                   HMAC verify, dedupe, enqueue — no Admin API work inline

                Why this order: the write path (3) must exist before the webhook
                (4) can queue anything, and evaluation (2) is a pure function so
                it can be tested without a store.

                One flag before I write them: REQ-TAG-009 (plan gating) has no
                ADR. It stays out of this epic — untraced stories get blocked at
                readiness anyway.

                May I write the four story files under
                production/epics/order-tags/epic-1-rule-engine/?"
```

**User:** "Yes."

Each story carries: Requirement ID, Governing ADR, Control Manifest rules for its
layer, and acceptance criteria copied from `requirements.yaml`.

---

## Turn 2 — `/story-readiness`

```
User: /story-readiness story-003

qa-lead: "Readiness check — story-003-tag-write-queue.

  Requirement .......... REQ-TAG-003 present in requirements.yaml ✅
  Governing ADR ........ ADR-0001 Accepted ✅
  Manifest version ..... story embeds 2026-10-27; manifest is 2026-10-29 ❌
  Acceptance criteria .. 4 present, all measurable ✅
  Dependencies ......... story-001 merged ✅, story-002 not started ⚠️
  Test plan ............ present ✅

  BLOCKED — one reason: the story was written against a control manifest that
  has since changed. Two rules were added on 2026-10-29 (no-op pre-check and
  the per-order write cap), and this story implements exactly that area.

  [A] regenerate the story's Context block from the current manifest
  [B] show me the diff between the two manifest versions
  [C] proceed anyway (not recommended — /story-done will re-check and fail)"
```

**User:** "A."

```
qa-lead: "Context block updated; manifest version now 2026-10-29. Re-check:
          READY. Note that story-002 is not started but is not a hard
          dependency — story-003 takes the tags to write as input, so it can be
          built and tested with a fixed list."
```

> **What to notice:** the stale manifest version blocked the story *before* code
> was written. That check exists because a story written against old rules
> produces code that violates the new ones.

---

## Turn 3 — `/dev-story story-003`

```
User: /dev-story story-003

lead-engineer: "Reading: story, ADR-0001 (Decision + Implementation Guidelines),
                control manifest App server + Data layers, and
                docs/shopify-api-reference/2026-10/admin-graphql.md for the
                tagsAdd/tagsRemove signatures.

                Plan, test-first:

                1. `queue/tag-write.ts`          enqueue with unique
                                                 (shop, order) — test: duplicate
                                                 enqueue collapses
                2. `queue/drain.ts`              claim, read order tags, no-op
                                                 filter, mutate — tests: tag
                                                 already present → no write;
                                                 absent removal → no-op
                3. `queue/throttle.ts`           THROTTLED → backoff, retry same
                                                 batch — test: fake throttle
                                                 response, assert 5 attempts
                4. `queue/accounting.ts`         usage_counter + tag_event rows

                Every test is written before the module. Two questions:

                1. The no-op pre-check needs the order's current tags. One
                   query per batch, or cache per order for the batch lifetime?
                   ADR says one cheap query — I'd do one per order per drain,
                   no cache, to avoid stale reads.
                2. Tag comparison: case-insensitive match, write the rule's
                   casing (per ADR). Confirm?"
```

**User:** "One query per drain. Case-insensitive match, rule's casing. And keep the evaluation module pure — no imports from queue code."

```
lead-engineer: "Noted — evaluation stays pure, queue imports it, never the
                reverse. Writing tests first, then modules."
```

---

## Turn 4 — `/code-review`

```
User: /code-review

lead-engineer: "Reviewing the diff against the control manifest, ADR and the
                pinned snapshot.

  BLOCKING
  - `queue/accounting.ts` derives the billable count with
    `Math.round(totalCost * 0.25)` — float arithmetic on a counter that is
    incremented across batches, so rounding drift accumulates. Use integer
    arithmetic.
    Rule: floating_point_money (forbidden pattern, registry) and control
    manifest Data layer.

  ADVISORY
  - `drain.ts` reads order tags with `first: 1` on a connection that returns
    tags as a list — the `first` argument is meaningless there and misleads the
    next reader. Remove it.
  - Throttle backoff uses a fixed 2 s. ADR-0001 says use the returned cost and
    throttle status. Fixed sleep will either over-wait or hammer.

  GOOD
  - Duplicate enqueue collapses on the unique index — test proves it.
  - No mutation of the full tag array anywhere. ✅ REQ-TAG-003
  - Handler has no Admin API call in the webhook path. ✅ REQ-TAG-002
"

lead-engineer: "Fixing all four. The throttle fix actually uses the platform's
                advice instead of a guess — same line count, better behaviour.
                May I apply?"
```

**User:** "Yes."

---

## Turn 5 — `/story-done`

```
User: /story-done story-003

qa-lead: "Verifying acceptance criteria for story-003 (REQ-TAG-003, REQ-TAG-008).

  ✅ Tags added with tagsAdd; pre-existing merchant tags survive (test)
  ✅ Removing an absent tag is a no-op (test)
  ✅ Tag already present → no write (test, asserts zero mutation calls)
  ✅ THROTTLED → same batch retried, 5 attempts, no dropped work (test)
  ✅ GraphQL requested cost ≤ 250 per batch (asserted in the request builder)
  ⚠️ DEFERRED — "write visible within 60 s p95" needs the live webhook path
     (story-004). Tracked, not dropped.

  Manifest version re-check: story embeds 2026-10-29, manifest is 2026-10-29 ✅
  Tests: 14 passed, 0 failed, 0 skipped.

  Verdict: COMPLETE WITH NOTES — one criterion deferred with a named owner
  (story-004).

  Next: story-004-orders-webhook, which closes the deferred criterion. Want me
  to update the sprint status and mark story-004 ready?"
```

**User:** "Yes, and note the deferred item in the epic."

```
qa-lead: "Sprint status updated; epic note added:
          'REQ-TAG-002 latency criterion verified in story-004.'

          Stage stays `build` until the epic's stories are all closed.
          /gate-check gate-3-scope was recorded before this epic started, so
          nothing blocks continuing."
```

---

## What this example demonstrates

- **Readiness blocked the story on a stale manifest version**, before a line of
  code, because the two rules added that day governed exactly the code about to
  be written.
- **Test-first was not ceremony.** The no-op and duplicate-delivery tests are the
  behaviours the ADR exists to guarantee.
- **The review cited rules, not taste.** "Forbidden pattern: floating point money"
  is a checkable objection; "I prefer integers" is not.
- **Deferred criteria are tracked, not hidden.** COMPLETE WITH NOTES with a named
  owner beats a silent ✅.
- **Requirement IDs go all the way through** — story, tests, commit message.
