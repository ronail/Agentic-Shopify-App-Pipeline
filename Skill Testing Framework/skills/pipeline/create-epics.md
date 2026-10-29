# Skill Test Spec: /create-epics

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Translate approved app requirements + architecture into epics — one epic per architectural module. Defines scope, governing ADRs, platform risk, and untraced requirements. Does NOT break into stories — run /create-stories [epic-slug] after each epic is created.

- **Invocation**: `/create-epics` [module-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]
- **Owner**: `technical-director`
- **Write access**: yes (`Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED / CONCERNS / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “1. Parse Arguments”, “2. Load Inputs”, “3. Processing Order”, “4. Define Each Epic”, “4b. Producer Epic Structure Gate”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Present to user before writing anything:” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `technical-director`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Foundation (no dependencies)

**Fixture** (assumed project state):
- `production/epics/<epic>/`
- `production/epics/[epic-slug]/EPIC.md`
- `production/epics/index.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/create-epics` [module-name | layer: foundation|core|feature|presentation | all] [--r

**Expected behavior**:
1. **Foundation** (no dependencies)
2. **Core** (depends on Foundation)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — How do you want to proceed?" Options: [A] Proceed as…

**Fixture**:
- Precondition violated: How do you want to proceed?" Options: `[A] Proceed as planned — I accept the producer's concerns` `[B] Revise epic boundaries — split or merge as recommended` `[C] Stop — I want to reconsider the…
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

### Case 3: Mode Variant — `--review` changes the depth of the run

**Fixture**:
- Standard project state for `/create-epics`
- Invocation adds `--review`

**Expected behavior**:
1. `--review` is parsed before any work and the resulting mode is stated in the output header.
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
2. The handoff names the next skill/agent explicitly (owning agent: `technical-director`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Present to user before writing anything:”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
