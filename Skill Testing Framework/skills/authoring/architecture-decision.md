# Skill Test Spec: /architecture-decision

> **Category**: authoring  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Author an Architecture Decision Record for one Shopify app — context, the decision, alternatives, consequences, and the exact Shopify API surface it commits to. Uses the ADR template, tracks Proposed to Accepted to Superseded, and registers cross-app stances.

- **Invocation**: `/architecture-decision` [app] \"[title]\" [--supersedes ADR-NNNN] [--review full|lean|solo]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, request_user_input, clarify, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `APPROVED / REJECTED / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “Phase 0 — Parse”, “Phase 1 — Number and locate”, “Phase 2 — Conflict check before writing”, “Phase 3 — Draft, section by section”, “Phase 4 — Write”…)
- [ ] At least one verdict keyword present (`APPROVED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Phase 2 — Conflict check before writing” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — App — required; validate against docs/registry/apps.json.

**Fixture** (assumed project state):
- `docs/architecture/apps/<app>/ADR-NNNN-<slug>.md`
- `.claude/docs/templates/architecture-decision-record.md`
- `docs/registry/apps.json`

**Input:** `/architecture-decision` [app] \"[title]\" [--supersedes ADR-NNNN] [--review full|lean|solo]

**Expected behavior**:
1. **App** — required; validate against `docs/registry/apps.json`.
2. **Title** — quoted, short, decision-shaped: "Use token exchange instead of OAuth callback for embedded sessions", not "Auth".
3. **`--supersedes ADR-NNNN`** — the ADR this one replaces, if any.
4. **Review mode** — `--review` override, else `production/review-mode.txt`, else `lean`.
5. **Retrofit check** — if the decision is already implemented in `apps/<app>/`, say so: this ADR will document reality, and every claim must be verified against the code, not assumed.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`APPROVED`), not free prose
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
- [ ] Verdict is `APPROVED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--supersedes` changes the depth of the run

**Fixture**:
- Standard project state for `/architecture-decision`
- Invocation adds `--supersedes`

**Expected behavior**:
1. `--supersedes` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `APPROVED`
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

- [ ] Uses the skill's documented approval gate before writes: “Phase 2 — Conflict check before writing”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 0 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
