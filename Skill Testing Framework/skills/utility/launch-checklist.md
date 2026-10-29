# Skill Test Spec: /launch-checklist

> **Category**: utility  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Use after an app is approved and before it goes live. Validates production deployment, live billing, monitoring, merchant communication, support readiness, and rollback, then records go/no-go sign-offs for that app.

- **Invocation**: `/launch-checklist` [app] [launch-date | dry-run]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write`) — every write needs explicit approval
- **Terminal state**: verdict token `READY / NOT READY / BLOCKED`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “Phase 1: Parse Arguments”, “Phase 2: Gather Context”, “Phase 3: Scan Production Risk”, “Phase 4: Generate the Checklist”, “Go / No-Go Decision”…)
- [ ] At least one verdict keyword present (`READY` is the terminal state)
- [ ] Write approval gate present — the skill requires “Otherwise ask: "May I write this to `production/apps/<app>/launch-checklist-<date>.md`?" Write on approval.” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Phase 1: Parse Arguments — This skill covers go-live after approval.

**Fixture** (assumed project state):
- `docs/registry/apps.json`
- `request.md`
- `apps/<app>/status.md`

**Input:** `/launch-checklist` [app] [launch-date | dry-run]

**Expected behavior**:
1. Phase 1: Parse Arguments — This skill covers **go-live after approval**.
2. Phase 2: Gather Context — Latest sprint and milestone records in `production/apps/<app>/`
3. Phase 3: Scan Production Risk — Debug output, test shop domains, tunnel URLs, or sandbox API keys in the production
4. Phase 4: Generate the Checklist

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`READY`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If no READY release checklist exists, stop.

**Fixture**:
- Precondition violated: If no READY release checklist exists, stop.
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

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/launch-checklist`)

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
- A run that reaches the terminal state `READY`
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

- [ ] Uses the skill's documented approval gate before writes: “Otherwise ask: "May I write this to `production/apps/<app>/launch-checklist-<date>.md`?" Write on approval.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 4 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
