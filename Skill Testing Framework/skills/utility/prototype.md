# Skill Test Spec: /prototype

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Build a throwaway prototype of an app's merchant-facing flow under apps/<app>/prototype/ — real Polaris screens, mock data, no tests, no coverage requirement, and structurally unimportable by production code. Timeboxed to answer one question. Promote via build-prototype, review via prototype-review.

- **Invocation**: `/prototype` [app: <slug>] [question: <what the prototype must answer>] [--timebox 2h|4h|1d]
- **Owner**: `prototype-builder`
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-2-prototype`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “1. State the Question”, “2. Read the Constraints”, “3. Choose the Smallest Viable Build”, “4. Build”, “5. Stop at the Timebox”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Before writing code, write down one sentence:” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-2-prototype`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `prototype-builder`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — 1. State the Question — A prototype without a question is a…

**Fixture** (assumed project state):
- `apps/<app>/prototype/`
- `apps/<app>/`
- `src/`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/prototype` [app: <slug>] [question: <what the prototype must answer>] [--timebox 

**Expected behavior**:
1. 1. State the Question — A prototype without a question is a half-built app.
2. 2. Read the Constraints
3. 3. Choose the Smallest Viable Build — If the question genuinely requires real store data, say so — that is a
4. 4. Build — TypeScript, React, Polaris — same stack as production, so the prototype's
5. 5. Stop at the Timebox — Default `2h`.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — apps/<app>/status.md — the stage. A prototype is normally…

**Fixture**:
- The skill's unconditional rule is violated: `apps/<app>/status.md` — the stage. A prototype is normally built between research and the `gate-2-prototype` review.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Skill reports the block explicitly instead of producing a partial recommendation
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--timebox` changes the depth of the run

**Fixture**:
- Standard project state for `/prototype`
- Invocation adds `--timebox`

**Expected behavior**:
1. `--timebox` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-2-prototype`; the skill writes no gate record.
2. Handoff names the owning gate: `/prototype` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Before writing code, write down one sentence:”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (7 numbered steps, 5 rules, 0 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
