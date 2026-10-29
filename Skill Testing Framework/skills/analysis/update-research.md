# Skill Test Spec: /update-research

> **Category**: analysis  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Refreshes existing market and competitor research for a Shopify app without losing prior findings: re-checks competitor listings, pricing and complaints, appends a dated delta, and records what changed in the recommendation. Use when research is stale, a competitor shipped, or gate-5-update needs current evidence.

- **Invocation**: `/update-research` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] **GAP** — `allowed-tools` grants Write/Edit but the body documents no "May I write"-style approval gate
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Read the prior research in full before searching. The delta is only…

**Fixture** (assumed project state):
- production/research/<app>/ — Existing `research.md`, `competitors.md`, `sources.md`, `recommendation.md
- docs/registry/apps.json — The app slug and its current stage
- request.md — Whether the app's purpose changed since the research
- present but optional: apps/<app>/status.md

**Input:** `/update-research` [app-slug]

**Expected behavior**:
1. **Read the prior research in full** before searching. The delta is only meaningful against a baseline you can quote.
2. **List the claims to re-verify** — one line each, pulled from `competitors.md` and `recommendation.md`: each competitor's price, rating, feature claim, and the differentiation hook. These are the only things worth re-checking.
3. **Re-check each listing** and record for each claim: `unchanged`, `changed` (with old and new value), `gone` (listing removed), or `new` (a competitor not in the original scan). Note the date checked.
4. **Search for the new entrant case** — the same problem keywords as the original research, sorted by newest. A new listing that solves the differentiation hook is the finding that matters.
5. **Re-test the kill conditions** from the prior recommendation. If any now holds, the app's premise changed and that must be stated plainly.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`research.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Append only. Never delete or rewrite a prior finding.

**Fixture**:
- The skill's unconditional rule is violated: **Append only.** Never delete or rewrite a prior finding.
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
- Invocation omits the argument (`/update-research`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Append only. Never delete or rewrite a prior finding.

**Fixture**:
- Boundary condition from the skill's own rules: **Append only.** Never delete or rewrite a prior finding.

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
1. Gate-relevant evidence is reported for `gate-5-update`; the skill writes no gate record.
2. Handoff names the owning gate: `/update-research` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
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

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 4 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
