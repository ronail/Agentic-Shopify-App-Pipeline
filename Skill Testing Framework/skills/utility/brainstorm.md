# Skill Test Spec: /brainstorm

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Guided Shopify app concept ideation — from a raw merchant pain to a structured app concept document, framed as either an Original or a Competitor-Killer. Produces apps/<app>/design/concept.md and registers the app.

- **Invocation**: `/brainstorm` [pain point, merchant niche, or 'open'] [--framing original|competitor-killer] [--review full|lean|solo]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, WebSearch, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `APPROVED / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “Phase 0 — Parse arguments and resolve review mode”, “Phase 1 — Context read”, “Phase 2 — Merchant pain discovery”, “Phase 3 — Choose the framing”, “Phase 4 — Shape the concept”…)
- [ ] At least one verdict keyword present (`APPROVED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Fill these, confirming each with the user:” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Seed: everything before the flags is the seed — a merchant pain…

**Fixture** (assumed project state):
- `apps/<app>/design/concept.md`
- `docs/registry/apps.json`
- `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`

**Input:** `/brainstorm` [pain point, merchant niche, or 'open'] [--framing original|competitor

**Expected behavior**:
1. **Seed**: everything before the flags is the seed — a merchant pain (`"refund reconciliation is manual"`), a niche (`"subscription coffee"`), or `open`.
2. **Framing**: `--framing original` or `--framing competitor-killer`. If absent, defer to Phase 3 (do not pick for the user).
3. **Review mode**: `--review full|lean|solo` overrides `production/review-mode.txt` for this run. Read the file if the flag is missing; `lean` if the file is missing too. Gate rules: `.claude/docs/director-gates.md`.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`APPROVED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Ask one question at a time; stop as soon as the pain is…

**Fixture**:
- Precondition violated: Ask one question at a time; stop as soon as the pain is concrete.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `APPROVED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--framing` changes the depth of the run

**Fixture**:
- Standard project state for `/brainstorm`
- Invocation adds `--framing`

**Expected behavior**:
1. `--framing` is parsed before any work and the resulting mode is stated in the output header.
2. Check depth widens or narrows consistently with the flag — never silently ignored.
3. Output differs from Case 1 only in the documented way.

**Assertions**:
- [ ] Flag honoured: the run's depth matches what the flag documents
- [ ] Invalid flag values are rejected instead of silently defaulting
- [ ] Mode recorded in the output header so the run is reproducible

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — partially complete state

**Fixture**:
- Boundary condition from the skill's own rules: an artifact exists but is incomplete or left over from an earlier run

**Expected behavior**:
1. The skill applies its documented rule instead of overwriting or repeating work.
2. The conflict is surfaced to the user with what was found and what the skill did.

**Assertions**:
- [ ] Prior state is either preserved or explicitly superseded with a reason — never silently rewritten
- [ ] Edge case handled without crash or silent failure
- [ ] Output states the resolution so a later reader can reproduce it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — approval boundary

**Fixture**:
- A run that reaches the terminal state `APPROVED`
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly.
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Fill these, confirming each with the user:”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (3 numbered steps, 0 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
