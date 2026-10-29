# Test Evidence: [Story Title]

> **Story**: `[path to story file]`
> **Story Type**: [UI | Integration | Visual/Feel]
> **Date**: [date]
> **Tester**: [who performed the test]
> **Build / Commit**: [version or git hash]
> **Dev store**: [store handle] · **API version**: [e.g. 2025-10]

---

## What Was Tested

[One paragraph describing the feature or behaviour that was validated. Include
the acceptance criteria numbers from the story that this evidence covers.]

**Acceptance criteria covered**: [AC-1, AC-2, AC-3]

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | [exact criterion text] | PASS / FAIL | [any observations] |
| AC-2 | [exact criterion text] | PASS / FAIL | |
| AC-3 | [exact criterion text] | PASS / FAIL | |

---

## Screenshots / Video

List all captured evidence below. Store files in the same directory as this
document or in `production/apps/<app>/qa/evidence/[story-slug]/`.

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `[filename.png]` | [brief description of what is visible — admin embedded app surface] | AC-1 |
| 2 | `[filename.png]` | | AC-2 |

*If video: note the timestamp and what it demonstrates.*

---

## Test Conditions

- **Store state at start**: [e.g. "fresh dev store, no orders, one test product"]
- **Install path**: [e.g. "clean install → OAuth grant → embedded admin load"]
- **Scopes granted**: [list the access scopes exercised]
- **Webhook delivery**: [e.g. "orders/create fired via CLI trigger, received in 1.2s"]
- **Any special setup required**: [e.g. "seeded 50 orders; checkouts in Bogus Gateway"]

---

## Observations

[Anything noteworthy that didn't cause a FAIL but should be recorded. Examples:
slow GraphQL query under bulk load, Polaris layout jitter on narrow admin widths,
behaviour that technically passes but felt slightly off. These become tech-debt
candidates.]

- [Observation 1]
- [Observation 2]

If nothing notable: *No significant observations.*

---

## Sign-Off

All roles must sign off before the story can be marked COMPLETE via `/story-done`.
UI stories require the ux-lead or polaris-specialist sign-off. Integration
stories require the api-lead or webhooks-specialist sign-off.

**Solo developers**: all sign-offs may be by the same person in each role. The
intent is that someone deliberately reviews the evidence before marking complete —
not that three separate people must participate.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer (implemented) | | | [ ] Approved |
| UX Lead / Polaris Specialist | | | [ ] Approved |
| QA Lead | | | [ ] Approved |

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances
past the sprint review.

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: UI and Integration story type evidence records*
*Location: `production/apps/<app>/qa/evidence/[story-slug]-evidence.md`*
