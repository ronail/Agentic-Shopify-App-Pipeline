# Skill Test Spec: /kanban-status

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Renders the pipeline board across every app from docs/registry/apps.json and production/apps/<app>/: stage, gate state, open sprints, and what is blocked. Read-only. Use when asking where an app stands, what is in flight, or what to work on next.

- **Invocation**: `/kanban-status` [app-slug, or blank for all apps]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED`
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Output”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Read-only claim holds: the body states it writes nothing, and no file mutation appears despite the tool grant
- [ ] Next-step handoff section present at end
- [ ] Read-only claim holds: no file-mutation path exists in the body

---

## Director Gate Checks

This skill works against the approval record and names `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Read docs/registry/apps.json. If it does not parse, report the parse…

**Fixture** (assumed project state):
- docs/registry/apps.json — Slug, name, stage, last approved gate
- apps/<app>/approvals.json — Per-gate status, date, approver
- present but optional: apps/<app>/status.md, production/apps/<app>/sprints/

**Input:** `/kanban-status` [app-slug, or blank for all apps]

**Expected behavior**:
1. **Read `docs/registry/apps.json`.** If it does not parse, report the parse error and stop — every number below would be wrong.
2. **For each app**, collect: - `stage` from the registry; `last_approved_gate` from the registry - the five gate statuses from `apps/<app>/approvals.json` - whether `apps/<app>/` exists, and whether `apps/<app>/prototype/` has more than a `.gitkeep` - the…
3. **Check registry against disk.** An app in the registry with no `apps/<app>/` directory is a `missing-scaffold` flag. An `apps/<app>/` directory not in the registry is an `unregistered` flag. Report both — they are the two ways the board lies.
4. **Derive the blocking step** for each app: the first gate that is not `approved`, mapped to its skill — `gate-1-research` → `/research`, `gate-2-prototype` → `/build-prototype`, `gate-3-scope` → `/mmmvp-proposals`, `gate-4-release` → `/release`,…
5. **Render the board** using the format below. Group by stage, newest activity last. Do not print an app twice.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Read docs/registry/apps.json. If it does not parse, report…

**Fixture**:
- Precondition violated: **Read `docs/registry/apps.json`.** If it does not parse, report the parse error and stop — every number below would be wrong.
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
- Invocation omits the argument (`/kanban-status`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Read docs/registry/apps.json. If it does not parse, report…

**Fixture**:
- Boundary condition from the skill's own rules: **Read `docs/registry/apps.json`.** If it does not parse, report the parse error and stop — every number below would be wrong.

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
1. Gate-relevant evidence is reported for `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`; the skill writes no gate record.
2. Handoff names the owning gate: `/kanban-status` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Read-only: no write gate required, and the skill mutates nothing
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (6 numbered steps, 4 rules, 6 declared inputs, 7 `##` sections).
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
