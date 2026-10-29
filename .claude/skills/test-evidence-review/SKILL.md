---
name: test-evidence-review
description: "Quality review of test files and manual evidence documents. Goes beyond existence checks — evaluates assertion coverage, edge case handling, naming conventions, and evidence completeness. Produces ADEQUATE/INCOMPLETE/MISSING verdict per story. Run before QA sign-off or on demand."
argument-hint: "[story-path | sprint | module-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
---

# Test Evidence Review

`/smoke-check` verifies that test files **exist** and **pass**. This skill
goes further — it reviews the **quality** of those tests and evidence documents.
A test file that exists and passes may still leave critical behaviour uncovered.
A manual evidence doc that exists may lack the sign-offs required for closure.

**Output:** Summary report (in conversation) + optional `production/qa/evidence-review-[date].md`

**When to run:**
- Before sprint close-out and QA sign-off
- On any story where test quality is in question
- As part of milestone review for Logic and Integration story quality audit

---

## 1. Parse Arguments

**Modes:**
- `/test-evidence-review [story-path]` — review a single story's evidence
- `/test-evidence-review sprint` — review all stories in the current sprint
- `/test-evidence-review [module-name]` — review all stories in an epic's module
- No argument — ask which scope: "Single story", "Current sprint", "A module"

---

## 2. Load Stories in Scope

Based on the argument:

**Single story**: Read the story file directly. Extract: Story Type, Test
Evidence section, story slug, module name.

**Sprint**: Read the most recently modified file in `production/sprints/`.
Extract the list of story file paths from the sprint plan. Read each story file.

**Module**: Glob `production/epics/[module-name]/story-*.md`. Read each.

For each story, collect:
- `Type:` field (Logic / Integration / UX/Visual / UI / Config/Data)
- `## Test Evidence` section — the stated expected test file path or evidence doc
- Story slug (from file name)
- Module name (from directory path)
- App root `apps/[app]/` (from the story's `App:` field)
- Acceptance Criteria list (all checkbox items)

---

## 3. Locate Evidence Files

For each story, find the evidence:

**Logic stories**: Glob `tests/unit/[module]/[story-slug]_test.*`
  - If not found, also try: Grep in `tests/unit/[module]/` for files
    containing the story slug

**Integration stories**: Glob `tests/integration/[module]/[story-slug]_test.*`
  - Also check `production/session-logs/` for a recorded manual verification
    mentioning the story

**UX/Visual and UI stories**: Glob `production/qa/evidence/[story-slug]-evidence.*`

**Config/Data stories**: Glob `production/qa/smoke-*.md` (any smoke check report)

Note what was found (path) or not found (gap) for each story.

---

## 4. Review Automated Test Quality (Logic / Integration)

For each test file found, read it and evaluate:

### Assertion coverage

Count the number of distinct assertions (lines containing assert, expect,
should, check, verify, or framework-specific assertion patterns). Low assertion
count is a quality signal — a test that makes only 1 assertion per test function
may not cover the range of expected behaviour.

Thresholds:
- **3+ assertions per test function** → normal
- **1-2 assertions per test function** → note as potentially thin
- **0 assertions** (test exists but no asserts) → flag as BLOCKING — the
  test passes vacuously and proves nothing

### Edge case coverage

For each acceptance criterion in the story that contains a number, threshold,
or "when X happens" conditional: check whether a test function name or
test body references that specific case.

Heuristics:
- Grep test file for "zero", "max", "null", "empty", "min", "invalid",
  "boundary", "edge", "timeout", "error" — presence of any is a positive signal
- If the requirement states explicit bounds or limits: check whether tests
  exercise the minimum and maximum values, and at least one rejection case

### Naming quality

Test function names should describe: the scenario + the expected result.
Pattern: `test_[scenario]_[expected_outcome]`

Flag functions named generically (`test_1`, `test_run`, `testBasic`) as
**naming issues** — they make failures harder to diagnose.

### Rule traceability

For Logic stories whose requirement defines a rule, formula, or threshold: check
that the test file contains at least one test whose name or comment references
that rule or threshold. A test that exercises a rule without naming it is harder
to maintain when the rule changes.

---

## 5. Review Manual Evidence Quality (UX/Visual / UI)

For each evidence document found, read it and evaluate:

### Criterion linkage

The evidence doc should reference each acceptance criterion from the story.
Check: does the evidence doc contain each criterion (or a clear rephrasing)?
Missing criteria mean a criterion was never verified.

### Sign-off completeness

Check for three sign-off lines (or equivalent fields):
- Developer sign-off
- Design/UX sign-off (for UX/Visual)
- QA lead sign-off

If any are missing or blank: flag as INCOMPLETE — the story cannot be fully
closed without all required sign-offs.

### Screenshot / artefact completeness

For UX/Visual stories: check whether screenshot or recording paths are referenced
in the evidence doc. If referenced, Glob for them to confirm they exist.

For UI stories: check whether a walkthrough sequence (step-by-step interaction
log) is present.

### Date coverage

Evidence doc should have a date. If the date is earlier than the story's
last major change (heuristic: compare against sprint start date from the sprint
plan), flag as POTENTIALLY STALE — the evidence may not cover the final
implementation.

---

## 6. Build the Review Report

For each story, assign a verdict:

| Verdict | Meaning |
|---------|---------|
| **ADEQUATE** | Test/evidence exists, passes quality checks, all criteria covered |
| **INCOMPLETE** | Test/evidence exists but has quality gaps (thin assertions, missing sign-offs) |
| **MISSING** | No test or evidence found for a story type that requires it |

The overall sprint/module verdict is the worst story verdict present.

```markdown
## Test Evidence Review

> **Date**: [date]
> **Scope**: [single story path | Sprint [N] | [module name]]
> **Stories reviewed**: [N]
> **Overall verdict**: ADEQUATE / INCOMPLETE / MISSING

---

### Story-by-Story Results

#### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration only)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Rule traceability: [yes / no — rule names not referenced in tests]

**Manual evidence quality** *(UX/Visual/UI only)*:
- Criterion linkage: [N/M criteria referenced]
- Sign-offs: [Developer ✓ | Design/UX ✗ | QA Lead ✗]
- Artefacts: [screenshots present / missing / N/A]
- Freshness: [dated [date] — current / potentially stale]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

### Summary

| Story | Type | Verdict | Issues |
|-------|------|---------|--------|
| [title] | Logic | ADEQUATE | None |
| [title] | Integration | INCOMPLETE | Thin assertions (avg 1.2/function) |
| [title] | UX/Visual | INCOMPLETE | QA lead sign-off missing |
| [title] | Logic | MISSING | No test file found |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]
```

---

## 7. Write Output (Optional)

Present the report in conversation.

Ask: "May I write this test evidence review to
`production/qa/evidence-review-[date].md`?"

This is optional — the report is useful standalone. Write only if the user
wants a persistent record.

After the report:

- For BLOCKING items: "These must be resolved before `/story-done` can mark the
  story Complete. Would you like to address any of them now?"
- For thin assertions: "Consider running `/test-helpers [module]` to see
  scaffolded assertion patterns for common cases."
- For missing sign-offs: "Manual sign-off is required from [role]. Share
  `[evidence-path]` with them to complete sign-off."

Verdict: **COMPLETE** — evidence review finished. Use CONCERNS if BLOCKING items were found.

---

## Collaborative Protocol

- **Report quality issues, do not fix them** — this skill reads and evaluates;
  it does not modify test files or evidence documents
- **ADEQUATE means adequate for shipping, not perfect** — avoid nitpicking
  tests that are functioning and comprehensive enough to give confidence
- **BLOCKING vs. ADVISORY distinction is important** — only flag BLOCKING when
  the gap leaves a story criterion genuinely unverified
- **Ask before writing** — the report file is optional; always confirm before writing
