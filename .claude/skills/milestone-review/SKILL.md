---
name: milestone-review
description: "Review a milestone in production/apps/<app>/milestones/: what was promised, what shipped, what the evidence actually supports, and whether the app can advance. Produces a SHIP / HOLD verdict with per-criterion evidence and named owners for anything short."
argument-hint: "<app> <milestone-id | latest> [--strict]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: producer
---

# Milestone Review

A milestone review is not a status update. It answers: **did this milestone
deliver what it claimed, is the evidence real, and may the app move on?**

It reviews *one* app's milestone. Portfolio-level sequencing is
`project-stage-detect`; gate authority is `gate-check`.

**Output:** `production/apps/<app>/milestones/<milestone-id>/review-<date>.md`

---

## 1. Load the Milestone

- `production/apps/<app>/milestones/<milestone-id>/` — the milestone definition
  and any artefacts attached to it (perf profile, security audit, soak,
  regression reports, demo notes).
- `production/apps/<app>/sprints/` — every sprint whose dates or ids fall inside
  the milestone window.
- `apps/<app>/status.md`, `apps/<app>/approvals.json` — stage and recorded gates.
- `docs/architecture/apps/<app>/requirements.yaml` — the requirements the
  milestone was supposed to advance.
- `request.md` — the merchant problem the milestone serves, in the requester's
  words.

`latest` resolves to the milestone directory with the most recent modification.
Verify the id matches a real directory; do not review a milestone that only
exists in a conversation.

---

## 2. Build the Promise List

Extract, with citations to the milestone file:

| # | Promised outcome | Type (merchant value / technical / compliance) | Success criterion | Promised in |

A promise is any of: a named feature, a metric target, a surface shipped, a
requirement id claimed, a document produced. Ambiguous promises get flagged as
ambiguous — "improve performance" with no number cannot be reviewed, and that
is a finding about the milestone, not the code.

If the milestone file has no explicit criteria, reconstruct them from the sprint
plans and say so clearly in the report. Reconstruction is a yellow flag: it means
the milestone was never falsifiable.

---

## 3. Check the Evidence, Not the Claim

For every promise, find the artefact that proves it. Rank evidence by strength:

| Strength | Evidence |
|----------|----------|
| Strong | A report on this commit: regression PASS, smoke PASS, perf numbers, security audit, test output; a verified store walkthrough with steps |
| Medium | Code merged with tests beside it, review approved, but no runtime verification |
| Weak | A sprint marked done, a status line, a chat summary |
| None | Nothing on disk |

Rules:
- A promise proved only by a Weak source is **NOT VERIFIED**, not done. Say what
  evidence would settle it.
- "Tests pass" without a report path and commit hash is Weak.
- A feature is not shipped because code exists; it is shipped because a merchant
  flow on a dev store works and a webhook/API effect is observable.
- Check the commit: evidence from a commit that is not an ancestor of the
  milestone's head is stale. Record both shas.

Also check for **silent scope change**: promises dropped from the milestone
without a recorded decision. A dropped promise with no decision is worse than a
missed one — say so.

---

## 4. Assess Each Area

- **Merchant value** — does the milestone move the merchant problem in
  `request.md`? Is the value observable in the admin, or only in logs?
- **Scope discipline** — anything shipped that was not promised (scope creep)
  and anything promised that vanished (silent cut). Cross-check with
  `/scope-check`.
- **Quality** — test evidence, review coverage, bug count by severity, any
  open S1/S2 in the app's sprints.
- **Security** — a security audit on this milestone? Any open Critical/High?
  Missing audit before a release milestone is a HOLD.
- **Performance** — budgets met on the primary path? Waiver recorded by
  `technical-director` if not.
- **Operability** — can the app be deployed, observed, and rolled back? Are
  migrations reversible? Is there a runbook for the failure modes the milestone
  introduces?
- **Documentation** — ADRs updated for decisions made, control manifest current,
  requirements registry reflects what shipped.
- **Pipeline hygiene** — sprint records closed, gate records consistent, no
  orphaned work.

---

## 5. Verdict

```markdown
# Milestone Review — <app> / <milestone>

> Date: <date> | Milestone head: <sha> | Evidence commits: <sha list>
> Reviewer: producer | Mode: standard | strict

## Promises vs outcome

| # | Promised | Criterion | Status (met/partial/missed/ambiguous) | Evidence | Strength |
|---|----------|-----------|---------------------------------------|----------|----------|

## Scope delta
- Added without a decision: <list>
- Dropped without a decision: <list>
- Decision recorded: <list with link>

## Area assessment
| Area | Verdict | Basis |
|------|---------|-------|
| Merchant value | | |
| Scope discipline | | |
| Quality | | |
| Security | | |
| Performance | | |
| Operability | | |
| Documentation | | |

## Open issues
| ID | Severity | Issue | Owner | Blocks advance? |

## Verdict: SHIP / SHIP WITH CONDITIONS / HOLD

**Conditions (if any):** <numbered, each with an owner and a due date>

## Carried into next milestone
| Item | Why it slipped | Owner |
```

Verdict rules:
- **SHIP** — every promise met with strong evidence, no open S1/S2, security and
  perf evidenced on this commit.
- **SHIP WITH CONDITIONS** — minor gaps with owners and dates, nothing that
  changes merchant behaviour badly, no security Critical/High.
- **HOLD** — a core promise missed, evidence absent for a claimed outcome,
  open S1/S2, missing security audit on a release milestone, or an undocumented
  scope change.

`--strict` treats Medium evidence as NOT VERIFIED and ambiguity as HOLD. Use it
for the milestone that precedes a release gate.

---

## 6. Write and Route

Ask: *"May I write this review to
`production/apps/<app>/milestones/<milestone-id>/review-<date>.md`?"*

Then:
- HOLD on security → `security-specialist`; on performance →
  `performance-analyst`; on test evidence → `qa-lead`; on scope → `product-director`.
- A SHIP verdict does not approve a gate. Gates are recorded by
  `/gate-check <gate-id> <app>` with the evidence paths from this review.
- Carry every condition into the next milestone's definition with an owner; a
  condition with no owner is a wish.
