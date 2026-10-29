# Skill Test Spec: /apply-updates

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Applies ratified update proposals to agents, skills, rules or hooks: verifies approval, applies the minimal diff, updates references in the affected files, and records what changed. Use only after a proposal is ratified; never for unratified ideas.

- **Invocation**: `/apply-updates` [proposal-id, e.g. P-20261029-01, or blank to list open proposals]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] **GAP** — `allowed-tools` grants Write/Edit but the body documents no "May I write"-style approval gate
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Confirm ratification. The proposal file must show Status: ratified…

**Fixture** (assumed project state):
- [proposal-id] — Which proposal to apply
- production/proposals/<id>.md — The exact change, target, and risk
- `docs/registry/apps.json` resolves the app slug
- present but optional: .claude/skills/*/SKILL.md, .claude/agents/*.md

**Input:** `/apply-updates` [proposal-id, e.g. P-20261029-01, or blank to list open proposals]

**Expected behavior**:
1. **Confirm ratification.** The proposal file must show `Status: ratified` plus a ratifier name and date. No ratification → stop, and say which field is missing. A verbal go-ahead quoted in chat is not enough for a `high` risk proposal.
2. **Re-read the proposal and the target file.** If the "before" text in the proposal no longer matches the file, the proposal is stale — stop and send it back for a refresh. Applying a stale diff is how two changes silently collide.
3. **Check for overlap.** Glob the area for another `open` or `ratified` proposal touching the same target. Two pending changes to one file must be applied in a known order, or one is deferred.
4. **Apply the minimal diff.** Only the lines the proposal names. Do not tidy adjacent wording, do not reformat, do not take the chance to fix something else you noticed — write a new proposal for that instead.
5. **Update references.** If the change renames a path, a skill name, an agent, or a frontmatter field, Grep the whole of `.claude/` and `docs/` for the old value and confirm every reference is either updated or deliberately left. Report any reference you left…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/proposals/<id>.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — No ratification → stop, and say which field is missing.

**Fixture**:
- Precondition violated: No ratification → stop, and say which field is missing.
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

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/apply-updates`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Re-read the proposal and the target file. If the "before"…

**Fixture**:
- Boundary condition from the skill's own rules: **Re-read the proposal and the target file.** If the "before" text in the proposal no longer matches the file, the proposal is stale — stop and send it back for a refresh.

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

- [ ] **GAP**: writes are granted but no approval gate is documented — route to `/skill-improve`
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 5 rules, 4 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
