# Skill Test Spec: /patch-notes

> **Category**: sprint  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Use when writing merchant-facing release notes. Translates an app's changelog entry into plain-language notes a Shopify merchant understands — what changed, what it means for their store, and what they must do — with no internal jargon.

- **Invocation**: `/patch-notes` [app] [version] [--style brief|detailed|full]
- **Owner**: `merchant-comms agent`
- **Write access**: yes (`Read, Glob, Grep, Write, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 9 `##` sections: “Phase 1: Parse Arguments”, “Phase 2: Gather Source Material”, “Phase 2b: Detect Tone and Template”, “Phase 3: Categorize and Translate”, “Phase 4: Generate the Notes”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write these to `production/apps/<app>/patch-notes-<version>.md`?" On approval, write the file, creating…” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `merchant-comms agent`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — apps/<app>/docs/tone-guide.md

**Fixture** (assumed project state):
- `apps/<app>/CHANGELOG.md`
- `docs/registry/apps.json`
- `request.md`

**Input:** `/patch-notes` [app] [version] [--style brief|detailed|full]

**Expected behavior**:
1. `apps/<app>/docs/tone-guide.md`
2. Any tone/voice/style section in `.claude/docs/technical-preferences.md`
3. `docs/PATCH-NOTES-STYLE.md`
4. Default: plain, calm, specific. No exclamation marks, no marketing adjectives, no "we're thrilled".

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Verdict: BLOCKED — stop without generating notes.

**Fixture**:
- Precondition violated: Verdict: **BLOCKED** — stop without generating notes.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `BLOCKED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--style` changes the depth of the run

**Fixture**:
- Standard project state for `/patch-notes`
- Invocation adds `--style`

**Expected behavior**:
1. `--style` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `BLOCKED`
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `merchant-comms agent`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write these to `production/apps/<app>/patch-notes-<version>.md`?" On approval, write the file, creating the…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 4 rules, 0 declared inputs, 9 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
