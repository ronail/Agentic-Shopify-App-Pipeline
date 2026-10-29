# Skill Test Spec: /release-checklist

> **Category**: utility  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Use before submitting an app to the Shopify App Store. Generates the submission-readiness checklist for one app — scopes, billing, webhooks and compliance topics, privacy, Polaris and performance budgets, extension surfaces — and returns a READY / NOT READY verdict that feeds /release.

- **Invocation**: `/release-checklist` [app] [--version x.y.z] [--scope admin|extension|checkout|all]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write`) — every write needs explicit approval
- **Terminal state**: verdict token `READY / NOT READY / BLOCKED / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “Phase 1: Parse Arguments”, “Phase 2: Load App Context”, “Phase 3: Scan the App”, “Phase 4: Generate the Checklist”, “Phase 5: Verdict and Write”…)
- [ ] At least one verdict keyword present (`READY` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write this to `production/apps/<app>/release-checklist-<version>.md`?" Write on approval, creating the…” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Phase 1: Parse Arguments

**Fixture** (assumed project state):
- `docs/registry/apps.json`
- `request.md`
- `production/apps/<app>/session-state/active.md`

**Input:** `/release-checklist` [app] [--version x.y.z] [--scope admin|extension|checkout|all]

**Expected behavior**:
1. Phase 1: Parse Arguments
2. Phase 2: Load App Context — Latest sprint record in `production/apps/<app>/sprints/` — what this release contains
3. Phase 3: Scan the App — Hardcoded API version strings outside `shopify.app.toml` and the ADR
4. Phase 4: Generate the Checklist — Add the `### Theme App Extension` and `### Checkout Extension` sections only when the
5. Phase 5: Verdict and Write — Blocking by default: any install, auth, scope, billing, webhook-HMAC, compliance-topic,

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`READY`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If shopify.app.toml is missing, stop.

**Fixture**:
- Precondition violated: If `shopify.app.toml` is missing, stop.
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

### Case 3: Mode Variant — `--version` changes the depth of the run

**Fixture**:
- Standard project state for `/release-checklist`
- Invocation adds `--version`

**Expected behavior**:
1. `--version` is parsed before any work and the resulting mode is stated in the output header.
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

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write this to `production/apps/<app>/release-checklist-<version>.md`?" Write on approval, creating the directory if…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (6 numbered steps, 0 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
