# Skill Test Spec: /release

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Cuts a versioned release of a Shopify app for App Store submission: verifies the readiness gate, freezes the version, writes release notes and the rollback plan, tags the build, and records the gate-4-release approval. Use when an app is ready to submit or a fix must ship as a new version.

- **Invocation**: `/release` <app-slug> <version>
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-2-prototype`, `gate-3-scope`, `gate-4-release`

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

This skill works against the approval record and names `gate-2-prototype`, `gate-3-scope`, `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Gate check, before anything else. All of these must hold:…

**Fixture** (assumed project state):
- <app-slug> <version> — Semantic version; never reuse a published one
- production/apps/<app>/app-store-checklist.md — The readiness verdict
- apps/<app>/approvals.json — gate-2-prototype`, `gate-3-scope` states
- production/apps/<app>/session-state/deploy-log.md — Proof the build ran on a real store
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/apps/<app>/sprints/

**Input:** `/release` <app-slug> <version>

**Expected behavior**:
1. **Gate check, before anything else.** All of these must hold: `app-store-checklist.md` verdict is `ready` with zero fails; `gate-2-prototype` and `gate-3-scope` are `approved`; the deploy log has a green test-store deploy at this commit. Any gap → stop, name…
2. **Fix the version.** Semantic: `MAJOR.MINOR.PATCH`. A scope addition or a breaking behaviour change is `MAJOR` or `MINOR`, a fix is `PATCH`. Confirm the version is not already tagged; reject a reused tag.
3. **Assemble the diff.** What changed since the last release, from the commit range and the sprint records — merchant-visible changes first, internal changes second.
4. **Write the release notes** in merchant language: what they can now do, what was fixed, what changed in behaviour they should know about. No internal identifiers, no table names, no ticket numbers as the headline.
5. **Write the rollback plan**: the previous version, how to re-deploy it, what app-side data the new version wrote that the old one must tolerate, and who decides to roll back.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/releases/<version>.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Any gap → stop, name the gap, do not continue.

**Fixture**:
- Precondition violated: Any gap → stop, name the gap, do not continue.
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
- Invocation omits the argument (`/release`)

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
1. Gate-relevant evidence is reported for `gate-2-prototype`, `gate-3-scope`, `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/release` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (9 numbered steps, 4 rules, 6 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
