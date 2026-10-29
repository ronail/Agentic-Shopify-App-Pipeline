# Skill Test Spec: /scope-check

> **Category**: analysis  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Guard against scope creep: compare planned and in-flight work for one app against request.md and its request history, classify every delta as in-scope, adjacent, or creep, and require a recorded change request before creep is built. Run before gate-3-scope and at every sprint boundary.

- **Invocation**: `/scope-check` [app: <slug>] [--sprint | --gate | --release]
- **Owner**: `product-director`
- **Write access**: read-only
- **Terminal state**: verdict token `IN SCOPE / DRIFT / OUT OF CONTROL`
- **Gates referenced**: `gate-3-scope`, `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “1. Load the Baseline”, “2. Build the Comparison Table”, “3. Detect the Specific Failure Modes”, “4. Report”, “5. Resolution Paths”…)
- [ ] At least one verdict keyword present (`IN SCOPE` is the terminal state)
- [ ] Read-only skill: no `Write`/`Edit` in `allowed-tools`
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-3-scope`, `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `product-director`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Cut it — remove the code before it reaches a merchant. Cheapest, and…

**Fixture** (assumed project state):
- `production/apps/<app>/milestones/scope-check-<date>.md`
- `request.md`
- `request-history.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/scope-check` [app: <slug>] [--sprint | --gate | --release]

**Expected behavior**:
1. **Cut it** — remove the code before it reaches a merchant. Cheapest, and the default for anything already classified creep.
2. **Absorb with a change request** — append the request to `request.md`, append the entry to `request-history.md` (the request-tracking hook enforces this), then derive a requirement id in `requirements.yaml`. Only then does it become in-scope.
3. **Defer** — record it in the app's request history as a future candidate with the reason. Not built now, not forgotten.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`IN SCOPE`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If request.md does not name this app or this behaviour,…

**Fixture**:
- Precondition violated: If `request.md` does not name this app or this behaviour, stop: the work has no baseline, and that is the finding.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `IN SCOPE` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--sprint` changes the depth of the run

**Fixture**:
- Standard project state for `/scope-check`
- Invocation adds `--sprint`

**Expected behavior**:
1. `--sprint` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `IN SCOPE`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-3-scope`, `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/scope-check` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing a report file.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (3 numbered steps, 0 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
