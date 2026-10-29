# Skill Test Spec: /deploy-to-test-store

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Deploys a build of a Shopify app to its test store: pins the version, applies pending migrations, releases the app extension and config, updates the install, and verifies the deployed version on the store. Use when a build needs to be exercised on a real store.

- **Invocation**: `/deploy-to-test-store` <app-slug> [version-tag]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-4-release`

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

This skill works against the approval record and names `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Remove ambiguity about the build. Record the exact commit and, if…

**Fixture** (assumed project state):
- <app-slug>` + optional version tag — What to deploy; default is the current commit
- production/apps/<app>/session-state/test-store.md — Store domain, credential reference, pinned API version
- apps/<app>/ — The built app, extension and config
- apps/<app>/shopify.app.toml — Extension and scope declarations to push
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/apps/<app>/sprints/

**Input:** `/deploy-to-test-store` <app-slug> [version-tag]

**Expected behavior**:
1. **Remove ambiguity about the build.** Record the exact commit and, if given, the version tag. "Latest" is not a deployable identity — write the commit hash down in the deploy record.
2. **Confirm the test store record exists** at `production/apps/<app>/session-state/test-store.md`. If it does not, stop and run `/create-test-store <app>` first.
3. **Check the config diff** — scopes, extension registrations, webhook topics, redirect URLs. Any added scope means the merchant must re-consent, so the deploy must be followed by a reinstall step. Call this out before deploying.
4. **Apply pending migrations** to the app's own data store against the test environment, after taking a snapshot. A migration applied to the wrong environment is the most expensive mistake in this skill.
5. **Deploy** the app and release the extension and config. If the deploy tool reports a warning, treat it as a failure until proven otherwise — report the warning text verbatim.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/session-state/deploy-log.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If it does not, stop and run /create-test-store <app> first.

**Fixture**:
- Precondition violated: If it does not, stop and run `/create-test-store <app>` first.
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
- Invocation omits the argument (`/deploy-to-test-store`)

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
1. Gate-relevant evidence is reported for `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/deploy-to-test-store` → evidence → `gate-check`.
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

- Cases are written against the current `SKILL.md` (9 numbered steps, 5 rules, 5 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
