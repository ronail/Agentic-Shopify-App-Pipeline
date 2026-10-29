# Skill Test Spec: /project-stage-detect

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Detect each Shopify app's pipeline stage from the registry, its status.md, gate approvals, and the artefacts actually present on disk — then name the single next action per app. Read-only. Use when the stage is unclear, after a merge, or at the start of a session you did not begin.

- **Invocation**: `/project-stage-detect` [app: <slug>] [--verbose]
- **Owner**: `producer`
- **Write access**: read-only
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “1. Read the Record”, “2. Inspect the Artefacts”, “3. Reconcile”, “4. Report”, “5. Next-Action Rules”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Read-only claim holds: the body states it writes nothing, and no file mutation appears despite the tool grant
- [ ] Next-step handoff section present at end
- [ ] Read-only claim holds: no file-mutation path exists in the body

---

## Director Gate Checks

This skill works against the approval record and names `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `producer`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — docs/registry/apps.json — the app list, each app's stage,…

**Fixture** (assumed project state):
- `apps/<app>/prototype/`
- `request.md`
- `docs/registry/apps.json`

**Input:** `/project-stage-detect` [app: <slug>] [--verbose]

**Expected behavior**:
1. `docs/registry/apps.json` — the app list, each app's `stage`, `last_approved_gate`, `created`, `purpose`. This is the claimed truth.
2. `apps/<app>/status.md` — `Stage:`, `Last approved gate:`, `Blockers:`.
3. `apps/<app>/approvals.json` — the actual approvals, keyed by gate id.
4. `apps/<app>/README.md` — purpose, for a sanity check against the registry.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Blocked → resolve the blocker; name the owner.

**Fixture**:
- Precondition violated: **Blocked** → resolve the blocker; name the owner.
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

### Case 3: Mode Variant — `--verbose` changes the depth of the run

**Fixture**:
- Standard project state for `/project-stage-detect`
- Invocation adds `--verbose`

**Expected behavior**:
1. `--verbose` is parsed before any work and the resulting mode is stated in the output header.
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
1. Gate-relevant evidence is reported for `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`; the skill writes no gate record.
2. Handoff names the owning gate: `/project-stage-detect` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 6 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
