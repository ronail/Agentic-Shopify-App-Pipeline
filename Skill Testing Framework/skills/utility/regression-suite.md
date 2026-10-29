# Skill Test Spec: /regression-suite

> **Category**: utility  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Run the full Vitest regression suite across one app and shared code, with coverage gates on billing and webhook verification. Selects tests by changed surface, triages flakes instead of retrying blindly, and produces a PASS/FAIL report suitable as release evidence.

- **Invocation**: `/regression-suite` [app: <slug> | all] [--changed | --full] [--coverage]
- **Owner**: `qa-lead`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS WITH QUARANTINE / PASS WITH / PASS / FAIL`
- **Gates referenced**: `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “1. Parse Arguments”, “2. Build the Target Set”, “3. Execute”, “4. Triage Failures — Do Not Retry to Green”, “5. Report”…)
- [ ] At least one verdict keyword present (`PASS WITH QUARANTINE` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write this regression report to `production/apps/<app>/sprints/regression-<date>.md`?"” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

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

### Case 1: Happy Path — Read docs/registry/apps.json for the app list; read each…

**Fixture** (assumed project state):
- `production/apps/<app>/sprints/regression-<date>.md`
- `production/session-state/regression-<date>.md`
- `apps/<app>/`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/regression-suite` [app: <slug> | all] [--changed | --full] [--coverage]

**Expected behavior**:
1. Read `docs/registry/apps.json` for the app list; read each `apps/<app>/status.md` for stage. An app still in `research` with no code has nothing to regress — record it as `N/A — no implementation` rather than failing.
2. Determine the changed set: - `git diff --name-only <base>...HEAD` - `git status --porcelain` for uncommitted work, if the run is pre-commit.
3. Map changed files to tests: - A changed `*.ts`/`*.tsx` → its sibling `*.test.ts(x)`. - A changed GraphQL document → the module that shapes its variables and the tests for that module. - A changed webhook route → the handler test **and** the signature…
4. Widen to `--full` automatically if the diff touches: `package.json`, lockfile, `tsconfig*`, Vitest config, auth/session modules, billing modules, webhook signature verification, or a pinned API version in `shopify.app.toml`.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`PASS WITH QUARANTINE`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — required input missing

**Fixture**:
- A `yes`-required input from the Inputs table is absent
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `PASS WITH QUARANTINE` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--changed` changes the depth of the run

**Fixture**:
- Standard project state for `/regression-suite`
- Invocation adds `--changed`

**Expected behavior**:
1. `--changed` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `PASS WITH QUARANTINE`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/regression-suite` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write this regression report to `production/apps/<app>/sprints/regression-<date>.md`?"”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
