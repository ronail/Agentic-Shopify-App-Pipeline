# Skill Test Spec: /start

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Pipeline dashboard — reads docs/registry/apps.json, request.md, and every app status file, prints where each app stands, then routes to the right next skill. Also configures model routing via /start claude|codex|hermes.

- **Invocation**: `/start` [claude|codex|hermes]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `COMPLETE`
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 10 `##` sections: “Phase 0 — Parse the argument”, “Phase 1 — Read pipeline state”, “Phase 2 — Print the dashboard”, “Phase 3 — Route”, “Phase 4 — Set review mode”…)
- [ ] At least one verdict keyword present (`COMPLETE` is the terminal state)
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

### Case 1: Happy Path — docs/registry/apps.json — the ONE shared mutable registry. Shape:…

**Fixture** (assumed project state):
- `request.md`
- `docs/registry/apps.json`
- `apps/<app>/status.md`

**Input:** `/start` [claude|codex|hermes]

**Expected behavior**:
1. `docs/registry/apps.json` — the ONE shared mutable registry. Shape: `{"apps": [{"slug","name","purpose","stage","last_approved_gate","created"}]}`. Tolerate a bare top-level array, slug-only strings, and missing keys; normalise in memory before printing.
2. `request.md` — `Version`, `Status`, `## Goal`, `## Gates`, `## Apps in scope`.
3. `request-history.md` — the last 3 table rows, sorted by timestamp.
4. For each registry slug: - `apps/<slug>/status.md` — `Stage`, `Last approved gate`, `Blockers` - `apps/<slug>/approvals.json` — approved gate ids and timestamps - `apps/<slug>/prototype/` — any entry besides `.gitkeep`? -…
5. `production/review-mode.txt` — report only; set in Phase 4 only if missing.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`COMPLETE`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — reasoningeffort and servicetier are optional per route; a…

**Fixture**:
- Precondition violated: `reasoning_effort` and `service_tier` are optional per route; a `service_tier` the route does not offer refuses that task rather than running it anyway.
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
- Invocation omits the argument (`/start`)

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
1. Gate-relevant evidence is reported for `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`; the skill writes no gate record.
2. Handoff names the owning gate: `/start` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (5 numbered steps, 0 rules, 0 declared inputs, 10 `##` sections).
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
