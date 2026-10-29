# Skill Test Spec: /scaffold

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Creates the per-app directory skeleton for a Shopify app: apps/<app>/ with README, status, approvals and prototype, the production/apps/<app> work folders, and the docs/registry/apps.json entry. Use when an approved app has no directory yet, or before any per-app work can run.

- **Invocation**: `/scaffold` --app <app-slug>
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`

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

This skill works against the approval record and names `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Validate the slug. Lowercase, hyphen-separated, no spaces or…

**Fixture** (assumed project state):
- --app <app-slug> — The directory name; must match the registry slug exactly
- request.md — The app's purpose sentence, for README and status
- docs/registry/apps.json — Whether the slug already exists
- present but optional: production/research/<app>/recommendation.md

**Input:** `/scaffold` --app <app-slug>

**Expected behavior**:
1. **Validate the slug.** Lowercase, hyphen-separated, no spaces or underscores. Reject `--app "Discount Bundles"` and ask for `discount-bundles`. If the slug is in neither `request.md` nor the registry, stop and say so — scaffolding an unrequested app is how…
2. **Check for an existing directory.** If `apps/<app>/` exists, do not overwrite. Diff what is present against the required list and create only the missing entries. Report what was already there.
3. **Create the source shell** `apps/<app>/`: - `README.md` — app name, one-paragraph purpose from `request.md`, the current gate, and the owner agents. - `status.md` — a header with `Stage:`, `Last Updated:`, `Owner:` and an empty `## Notes` section. -…
4. **Create the work shell** `production/apps/<app>/`: - `sprints/.gitkeep` - `milestones/.gitkeep` - `session-state/.gitkeep`
5. **Register the app** in `docs/registry/apps.json`. Append an entry with `slug`, `name`, `purpose`, `stage: "research"`, `last_approved_gate: null`, `created` (today, `YYYY-MM-DD`). Keep the file's existing key order and two-space indentation; append, never…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`docs/registry/apps.json`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If the slug is in neither request.md nor the registry,…

**Fixture**:
- Precondition violated: If the slug is in neither `request.md` nor the registry, stop and say so — scaffolding an unrequested app is how phantom directories appear.
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

### Case 3: Mode Variant — `--app` changes the depth of the run

**Fixture**:
- Standard project state for `/scaffold`
- Invocation adds `--app`

**Expected behavior**:
1. `--app` is parsed before any work and the resulting mode is stated in the output header.
2. Check depth widens or narrows consistently with the flag — never silently ignored.
3. Output differs from Case 1 only in the documented way.

**Assertions**:
- [ ] Flag honoured: the run's depth matches what the flag documents
- [ ] Invalid flag values are rejected instead of silently defaulting
- [ ] Mode recorded in the output header so the run is reproducible

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Idempotent. Running it twice on the same slug must change…

**Fixture**:
- Boundary condition from the skill's own rules: **Idempotent.** Running it twice on the same slug must change nothing and report "already complete".

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
2. Handoff names the owning gate: `/scaffold` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (7 numbered steps, 4 rules, 4 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
