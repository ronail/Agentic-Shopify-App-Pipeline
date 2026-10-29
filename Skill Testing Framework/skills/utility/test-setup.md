# Skill Test Spec: /test-setup

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Scaffold the test framework and CI/CD pipeline for the project's stack. Creates the tests/ directory structure, test runner configuration, and GitHub Actions workflow. Run once during Technical Setup phase before the first sprint begins.

- **Invocation**: `/test-setup` [force]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Bash, Write`) — every write needs explicit approval
- **Terminal state**: verdict token `COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Phase 1: Detect Stack and Existing State”, “Phase 2: Present Plan”, “Phase 3: Create Directory Structure”, “Phase 4: Create CI/CD Workflow”, “Phase 5: Create Smoke Test Seed”…)
- [ ] At least one verdict keyword present (`COMPLETE` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I create these files?” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Read stack config: - Read .claude/docs/technical-preferences.md and…

**Fixture** (assumed project state):
- `tests/`
- `.github/workflows/tests.yml`
- `.claude/docs/technical-preferences.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/test-setup` [force]

**Expected behavior**:
1. **Read stack config**: - Read `.claude/docs/technical-preferences.md` and extract the `Stack:` and `Language:` values. - If the stack is not configured (`[TO BE CONFIGURED]`), stop: "Stack not configured. Run `/start` first, then re-run `/test-setup`."
2. **Check for existing test infrastructure**: - Glob `tests/` — does the directory exist? - Glob `tests/unit/` and `tests/integration/` — do subdirectories exist? - Glob `.github/workflows/` — does a CI workflow file exist? - Glob `vitest.config.*`,…
3. **Report findings**: - "Stack: [stack]. Test directory: [found / not found]. CI workflow: [found / not found]." - If everything already exists AND `force` argument was not passed: "Test infrastructure appears to be in place. Re-run with `/test-setup force`…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`COMPLETE`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If the stack is not configured ([TO BE CONFIGURED]), stop:…

**Fixture**:
- Precondition violated: If the stack is not configured (`[TO BE CONFIGURED]`), stop: "Stack not configured.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `COMPLETE` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/test-setup`)

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
- A run that reaches the terminal state `COMPLETE`
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

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I create these files?”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (3 numbered steps, 0 rules, 0 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
