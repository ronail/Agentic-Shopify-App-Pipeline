# Skill Test Spec: /hotfix

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Use when a shipped app is broken in production. Runs the emergency path: assess severity, mitigate, branch from the released tag, make the minimum fix with a reproducing test, verify on a test store, get sign-offs, deploy with a rollback plan, and record the incident.

- **Invocation**: `/hotfix` [app] [incident description or bug id]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `CONCERNS / PASS`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 10 `##` sections: “Phase 1: Assess Severity”, “Phase 2: Mitigate Before You Fix”, “Phase 3: Open the Incident Record”, “Phase 4: Branch from the Release”, “Phase 5: Reproduce, Then Fix”…)
- [ ] At least one verdict keyword present (`CONCERNS` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask one question before writing any code: can the damage be stopped without a deploy?” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Turn the feature off behind its flag

**Fixture** (assumed project state):
- `docs/registry/apps.json`
- `production/apps/<app>/incidents/hotfix-<date>-<slug>.md`
- `hotfix/<app>-<slug>`

**Input:** `/hotfix` [app] [incident description or bug id]

**Expected behavior**:
1. Turn the feature off behind its flag
2. Revert to the previous deployed version
3. Pause the affected webhook subscription or background job
4. Rate-limit or disable the failing endpoint
5. Only then: ship a code fix

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`CONCERNS`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — A mitigation that stops merchant harm in two minutes beats…

**Fixture**:
- Precondition violated: A mitigation that stops merchant harm in two minutes beats a correct fix in two hours, and the fix still happens afterwards.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `CONCERNS` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/hotfix`)

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
- A run that reaches the terminal state `CONCERNS`
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

- [ ] Uses the skill's documented approval gate before writes: “Ask one question before writing any code: can the damage be stopped without a deploy?”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 5 rules, 0 declared inputs, 10 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
