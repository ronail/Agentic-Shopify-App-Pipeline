# Skill Test Spec: /gate-check

> **Category**: gate  
> **Priority**: critical  
> **Spec written**: 2026-10-29

## Skill Summary

Check a pipeline gate (gate-1-research, gate-2-prototype, gate-3-scope, gate-4-release, gate-5-update) against one app's approvals.json and the evidence on disk. Reports READY / NOT READY / BLOCKED, and only on explicit approval records the gate and updates the app's stage.

- **Invocation**: `/gate-check` <gate-id> <app> [--force-reason <text>]
- **Owner**: `producer`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `READY / NOT READY / PASS WITH QUARANTINE / PASS WITH / BLOCKED / PASS / FAIL`
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “1. Preconditions — Check Before Judging”, “2. Criteria Per Gate”, “3. Verdict”, “4. Waivers”, “5. Recording the Gate (only after explicit approval)”…)
- [ ] At least one verdict keyword present (`READY` is the terminal state)
- [ ] Write approval gate present — the skill requires “May I record this approval and advance the app's stage?"” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It is the **only** skill that records a gate: on explicit approval it writes `approvals.json`, `status.md`, and the app's `stage`/`last_approved_gate` in `docs/registry/apps.json` — nothing else, and a failed edit rolls back the rest.

- **Full mode**: review depth routed through `producer`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Resolve the app from docs/registry/apps.json. Not found → BLOCKED,…

**Fixture** (assumed project state):
- `apps/<app>/approvals.json`
- `apps/<app>/status.md`
- `docs/registry/apps.json`

**Input:** `/gate-check` <gate-id> <app> [--force-reason <text>]

**Expected behavior**:
1. Resolve the app from `docs/registry/apps.json`. Not found → **BLOCKED**, "app is not registered; no gate can be recorded for it".
2. Read `apps/<app>/approvals.json` and `apps/<app>/status.md`.
3. Verify order: every earlier gate must already be recorded. `gate-3-scope` with no `gate-2-prototype` → **BLOCKED**, not "not ready".
4. Idempotency: if this gate is already recorded, report when and by whom, and stop. Re-approving corrupts the record.
5. Read `apps/<app>/status.md` blockers — an open blocker is **BLOCKED** unless the approver explicitly waives it in writing.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`READY`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Any other id is a typo — refuse and list the five.

**Fixture**:
- Precondition violated: Any other id is a typo — refuse and list the five.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `READY` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--force-reason` changes the depth of the run

**Fixture**:
- Standard project state for `/gate-check`
- Invocation adds `--force-reason`

**Expected behavior**:
1. `--force-reason` is parsed before any work and the resulting mode is stated in the output header.
2. Check depth widens or narrows consistently with the flag — never silently ignored.
3. Output differs from Case 1 only in the documented way.

**Assertions**:
- [ ] Flag honoured: the run's depth matches what the flag documents
- [ ] Invalid flag values are rejected instead of silently defaulting
- [ ] Mode recorded in the output header so the run is reproducible

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Idempotency: if this gate is already recorded, report when…

**Fixture**:
- Boundary condition from the skill's own rules: Idempotency: if this gate is already recorded, report when and by whom, and stop.

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
- A run that reaches the terminal state `READY`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate criteria are reported with evidence paths; the gate is binary — READY, NOT READY, or BLOCKED.
2. The approval is recorded only after the verbatim question “May I record this approval and advance the app's stage?” is answered yes.
3. The three writes land together or are rolled back together.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “May I record this approval and advance the app's stage?"”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 5 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
