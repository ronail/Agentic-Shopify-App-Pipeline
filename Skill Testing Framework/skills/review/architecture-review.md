# Skill Test Spec: /architecture-review

> **Category**: review  
> **Priority**: critical  
> **Spec written**: 2026-10-29

## Skill Summary

Use when reviewing one app's architecture. Validates the per-app ADR set against that app's requirement registry, builds a REQ -> ADR traceability matrix, detects conflicting decisions, cross-checks every decision against the pinned Shopify API snapshot, and returns a PASS/CONCERNS/FAIL verdict.

- **Invocation**: `/architecture-review` [app] [focus: full | coverage | consistency | api | rtm]
- **Owner**: `technical-director`
- **Write access**: yes (`Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED / CONCERNS / PASS / FAIL`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 13 `##` sections: “Phase 1: Resolve the App and Load Inputs”, “Phase 2: Extract Requirements”, “Phase 3: Build the Traceability Matrix”, “Phase 3b: Story and Test Linkage (`rtm` mode)”, “Phase 4: Cross-ADR Conflict Detection”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Approved writes:” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `technical-director`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Match to an existing entry in the same area → reuse that…

**Fixture** (assumed project state):
- `docs/architecture/apps/<app>/`
- `docs/architecture/apps/<app>/requirements-traceability.md`
- `docs/registry/apps.json`

**Input:** `/architecture-review` [app] [focus: full | coverage | consistency | api | rtm]

**Expected behavior**:
1. **Match to an existing entry in the same area** → reuse that `REQ-<AREA>-NNN` unchanged. If the wording changed but the intent did not, update the `requirement` text and add `revised: [date]`.
2. **No match** → assign the next free sequence for that area (`REQ-BILL-002`). Never renumber to tidy the file.
3. **Ambiguous** → ask: "Does '[new text]' restate `REQ-[AREA]-NNN: [existing text]`, or is it a new requirement?"
4. **`status: deprecated`** entries → skip; they were removed deliberately.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Slug not in the registry → stop and list the registered…

**Fixture**:
- Precondition violated: Slug not in the registry → stop and list the registered slugs.
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

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/architecture-review`)

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

- [ ] Uses the skill's documented approval gate before writes: “Approved writes:”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 13 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
