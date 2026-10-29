# Skill Test Spec: /build-prototype

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Builds a throwaway merchant-facing prototype for a Shopify app under apps/<app>/prototype/, with real Polaris-styled admin screens and the intended workflow, so the flow can be judged before any production build. Use after gate-1-research, before gate-2-prototype.

- **Invocation**: `/build-prototype` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-1-research`, `gate-2-prototype`

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

This skill works against the approval record and names `gate-1-research`, `gate-2-prototype`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Confirm the shell exists. apps/<app>/prototype/ must already be…

**Fixture** (assumed project state):
- apps/<app>/README.md — Purpose and current gate
- production/research/<app>/recommendation.md — The problem the flow must solve
- docs/shopify-api-reference/ — Real field names, real limits, real errors
- apps/<app>/prototype/ — Created by `/scaffold`; the only write target
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/apps/<app>/mmmvp-proposals.md

**Input:** `/build-prototype` [app-slug]

**Expected behavior**:
1. **Confirm the shell exists.** `apps/<app>/prototype/` must already be there from `/scaffold`. If it is missing, stop and say so — do not create app directories from here.
2. **Write the flow script first.** Numbered steps of what the merchant does and what they see, in their language: "opens the app, sees a list of products with no bundle, clicks Create bundle, picks products, sees the price the shopper will see". Then build…
3. **Build the screens** as static or lightly scripted pages under `apps/<app>/prototype/` — an entry page, the main list, the create/edit form, and the confirmation state. Match the Shopify admin visual language: admin layout, page header with primary action,…
4. **Use real data shapes.** Field names, limits and error text come from `docs/shopify-api-reference/`. A prototype that shows a field the API does not have teaches the reviewer the wrong thing.
5. **Include the ugly states** — empty, loading, error, and the permission-denied case. Prototypes that only show the happy path get approved and then surprise everyone in build.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`README.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If it is missing, stop and say so — do not create app…

**Fixture**:
- Precondition violated: If it is missing, stop and say so — do not create app directories from here.
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
- Invocation omits the argument (`/build-prototype`)

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
- A run that reaches the terminal state
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-1-research`, `gate-2-prototype`; the skill writes no gate record.
2. Handoff names the owning gate: `/build-prototype` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
