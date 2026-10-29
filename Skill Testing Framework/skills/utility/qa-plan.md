# Skill Test Spec: /qa-plan

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Use before a sprint or feature starts. Builds that app's QA plan: classifies each story by test type, specifies the automated tests, GraphQL and webhook fixtures, manual dev-store checks, accessibility and performance verification, and the smoke scope — then writes it under production/apps/<app>/qa/.

- **Invocation**: `/qa-plan` [app] [sprint | feature: area | story: path | app]
- **Owner**: `qa-lead`
- **Write access**: yes (`Read, Glob, Grep, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “Phase 1: Parse Scope”, “Phase 2: Load Inputs”, “Phase 3: Classify Each Story”, “Phase 4: Generate the Plan”, “Phase 5: Write”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Never write without approval — Phase 5 requires it.” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `qa-lead`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Phase 1: Parse Scope — Report: "Building the QA plan for [N] stories…

**Fixture** (assumed project state):
- `production/apps/<app>/qa/qa-plan-<scope-slug>-<date>.md`
- `docs/registry/apps.json`
- `request.md`

**Input:** `/qa-plan` [app] [sprint | feature: area | story: path | app]

**Expected behavior**:
1. Phase 1: Parse Scope — Report: "Building the QA plan for [N] stories — app [app], scope [scope]."
2. Phase 2: Load Inputs — Requirement IDs (`REQ-<AREA>-NNN`) and ADR references
3. Phase 3: Classify Each Story — If the story declares `Type:`, take it as authoritative — do not re-classify.
4. Phase 4: Generate the Plan — Use the real story titles, acceptance criteria, and requirement text from Phase 2.
5. Phase 5: Write — Show the plan (or a summary if very long), then ask with `AskUserQuestion`,

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — required input missing

**Fixture**:
- A `yes`-required input from the Inputs table is absent
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

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/qa-plan`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

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
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `qa-lead`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Never write without approval — Phase 5 requires it.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 0 rules, 0 declared inputs, 6 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
