# Skill Test Spec: /dev-story

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Read a story file and implement it. Loads the full context (story, requirement, ADR guidelines, control manifest), routes to the right specialist agent for the module and platform surface, implements the code and test, and confirms each acceptance criterion. The core implementation skill — run after /story-readiness, before /code-review and /story-done.

- **Invocation**: `/dev-story` [story-path]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Bash, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 10 `##` sections: “Phase 1: Find the Story”, “Phase 2: Load Full Context”, “Phase 3: Route to the Right Specialist”, “Phase 4: Implement”, “Phase 5: Test Evidence Requirements”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Glob production/epics//.md to find each dependency story file.

**Fixture** (assumed project state):
- `apps/[app]/`
- `tests/`
- `production/session-state/active.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/dev-story` [story-path]

**Expected behavior**:
1. Glob `production/epics/**/*.md` to find each dependency story file.
2. Read its `Status:` field.
3. If any dependency has Status other than `Complete` or `Done`: - Use `AskUserQuestion`, `request_user_input` or `clarify`: - Prompt: "Story '[current story]' depends on '[dependency title]' which is currently [status], not Complete. How do you want to…
4. **`production/sprints/sprint-status.yaml`** (if it exists): find the entry matching this story's file path and set `status: in_progress`. Update the top-level `updated` field to today's date. If the file does not exist, skip silently.
5. **The story file itself**: edit the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist in the story header, add it after the `Status:` line. This enables sprint-status staleness detection for this…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If the requirements file or governing ADR is missing, set…

**Fixture**:
- Precondition violated: If the requirements file or governing ADR is missing, set the story status to **BLOCKED** in the session state and do not spawn any specialist agent.
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
- Invocation omits the argument (`/dev-story`)

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

- [ ] Uses the skill's documented approval gate before writes: “If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 0 rules, 0 declared inputs, 10 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
