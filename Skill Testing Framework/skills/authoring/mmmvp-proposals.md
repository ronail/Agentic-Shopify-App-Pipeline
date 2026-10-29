# Skill Test Spec: /mmmvp-proposals

> **Category**: authoring  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Proposes minimal-market-viable slices for the current request: the smallest shippable version of a Shopify app that a merchant would pay for, with explicit cuts and the gate-3-scope decision each slice forces. Use when scope is unclear, when a build is drifting large, or before gate-3-scope.

- **Invocation**: `/mmmvp-proposals` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-1-research`, `gate-3-scope`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Ask before writing to `production/apps/<app>/`.” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-1-research`, `gate-3-scope`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Extract the job. Write the merchant's job-to-be-done as one…

**Fixture** (assumed project state):
- request.md — Goal, success criteria, the app's purpose
- production/research/<app>/recommendation.md — The problem being solved and the differentiation hook
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/research/<app>/competitors.md, apps/<app>/status.md

**Input:** `/mmmvp-proposals` [app-slug]

**Expected behavior**:
1. **Extract the job.** Write the merchant's job-to-be-done as one sentence: "When a merchant ___, they want ___, so they can ___." If you cannot fill all three blanks from the research, stop — the slice would be a guess.
2. **List every candidate capability** mentioned anywhere in the request and research, one line each, no grouping yet. This is the raw scope.
3. **Classify each capability** as: `core` (the job cannot be done without it), `thin` (needed to be credible but can be minimal), or `later` (real value, not needed to be paid for once).
4. **Build three slices**, each independently shippable: - **S1 — Thinnest**: `core` only, one workflow, one screen, no settings. - **S2 — Credible**: S1 plus the `thin` items a reviewer or merchant would notice missing in the first ten minutes. - **S3 —…
5. **For each slice record**: what a merchant can do that they could not before, what is explicitly excluded, the Shopify surfaces it touches (admin API, webhooks, theme app extension, checkout extension), and a build size band (S / M / L) with one sentence of…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/mmmvp-proposals.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Extract the job. Write the merchant's job-to-be-done as…

**Fixture**:
- Precondition violated: **Extract the job.** Write the merchant's job-to-be-done as one sentence: "When a merchant ___, they want ___, so they can ___." If you cannot fill all three blanks from the research, stop — the…
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
- Invocation omits the argument (`/mmmvp-proposals`)

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
1. Gate-relevant evidence is reported for `gate-1-research`, `gate-3-scope`; the skill writes no gate record.
2. Handoff names the owning gate: `/mmmvp-proposals` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing to `production/apps/<app>/`.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
