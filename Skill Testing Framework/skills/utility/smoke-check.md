# Skill Test Spec: /smoke-check

> **Category**: utility  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Post-deploy smoke test on the dev store: walk the critical merchant flows of one Shopify app — install, embedded admin load, primary action, billing, webhook ack, uninstall — and produce a PASS/FAIL report. A failed smoke check blocks release and blocks handing the app to anyone else.

- **Invocation**: `/smoke-check` [app: <slug>] [quick | full] [--after-deploy]
- **Owner**: `qa-lead`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS / FAIL`
- **Gates referenced**: `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “1. Parse Arguments”, “2. Establish the Environment”, “3. Test Groups”, “4. Produce the Report”, “5. Write and Close Out”…)
- [ ] At least one verdict keyword present (`PASS` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask before writing: "May I write this smoke report to `production/apps/<app>/sprints/smoke-<date>.md`?"” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `qa-lead`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Read apps/<app>/status.md and apps/<app>/approvals.json — know the…

**Fixture** (assumed project state):
- `production/apps/<app>/sprints/smoke-<date>.md`
- `docs/registry/apps.json`
- `apps/<app>/status.md`

**Input:** `/smoke-check` [app: <slug>] [quick | full] [--after-deploy]

**Expected behavior**:
1. Read `apps/<app>/status.md` and `apps/<app>/approvals.json` — know the stage before testing, so a research-stage app is not judged on release criteria.
2. Read `apps/<app>/shopify.app.toml` — record the app handle, embedded setting, `application_url`, redirect URLs, scopes, and webhook subscriptions. Every one of these is something the smoke run verifies against reality.
3. Read `.claude/docs/technical-preferences.md` for the environment ladder: local (CLI tunnel) → dev store → production.
4. Confirm the dev store: it must be a development store that the app is installed on, or one where installation can be performed. If no store exists, stop and point at `/create-test-store` rather than improvising credentials.
5. Record the commit under test (`git rev-parse --short HEAD`) and the deploy target. A smoke report without a commit hash is not evidence.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`PASS`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If no store exists, stop and point at /create-test-store…

**Fixture**:
- Precondition violated: If no store exists, stop and point at `/create-test-store` rather than improvising credentials.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `PASS` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--after-deploy` changes the depth of the run

**Fixture**:
- Standard project state for `/smoke-check`
- Invocation adds `--after-deploy`

**Expected behavior**:
1. `--after-deploy` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `PASS`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/smoke-check` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing: "May I write this smoke report to `production/apps/<app>/sprints/smoke-<date>.md`?"”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 4 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
