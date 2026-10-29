# Skill Test Spec: /soak-test

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Design an extended stability soak for one Shopify app on a dev store — sustained webhook throughput, GraphQL rate-limit pressure, and memory growth over time. Produces the run protocol and analysis harness; the run itself is executed by a person or a load script. Run before gate-4-release and after any leak, throttle, or timeout fix.

- **Invocation**: `/soak-test` [duration: 30m | 1h | 2h | 4h] [focus: memory | webhooks | rate-limits | all] [app: <slug>]
- **Owner**: `devops-engineer`
- **Write access**: yes (`Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS WITH / CONCERNS / PASS / FAIL`
- **Gates referenced**: `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “1. Parse Arguments”, “2. Load Context”, “3. Build the Load Profile”, “4. Define Checkpoints”, “5. Protocol Template”…)
- [ ] At least one verdict keyword present (`PASS WITH` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write this soak protocol to `production/apps/<app>/sprints/soak-<date>-<duration>.md`?" Write only after…” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `devops-engineer`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Run the protocol top to bottom; fill each checkpoint as you go.

**Fixture** (assumed project state):
- `production/apps/<app>/sprints/soak-<date>-<duration>.md`
- `production/apps/<app>/milestones/<milestone>/soak-<date>.md`
- `docs/registry/apps.json`

**Input:** `/soak-test` [duration: 30m | 1h | 2h | 4h] [focus: memory | webhooks | rate-limits

**Expected behavior**:
1. Run the protocol top to bottom; fill each checkpoint as you go.
2. File every issue found as a row in the report and, if S1/S2, as a ticket in the app's sprint record.
3. If the verdict is FAIL, the app is **not** eligible for `gate-4-release` — run `/gate-check gate-4-release <app>` again only after the fix and a re-soak of the affected focus area.
4. Attach the report path to the release milestone when the verdict is PASS.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`PASS WITH`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If the snapshot directory is missing, stop and report the…

**Fixture**:
- Precondition violated: If the snapshot directory is missing, stop and report the mismatch instead of guessing costs.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `PASS WITH` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/soak-test`)

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
- A run that reaches the terminal state `PASS WITH`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/soak-test` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write this soak protocol to `production/apps/<app>/sprints/soak-<date>-<duration>.md`?" Write only after approval.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
