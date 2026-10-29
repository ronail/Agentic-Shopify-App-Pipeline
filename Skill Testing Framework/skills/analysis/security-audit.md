# Skill Test Spec: /security-audit

> **Category**: analysis  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Audit one Shopify app's security posture: OAuth install flow, session-token verification, access-token storage, webhook HMAC, scope minimisation, protected customer data handling, and compliance webhooks. Produces severity-ranked findings with concrete exploit paths. Run before gate-4-release and after any auth, billing, or webhook change.

- **Invocation**: `/security-audit` [app: <slug>] [focus: auth | webhooks | data | scopes | all]
- **Owner**: `security-specialist`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS WITH / PASS / FAIL`
- **Gates referenced**: `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “1. Load Context”, “2. Attack Surface Checklist”, “3. Verify, Do Not Assume”, “4. Report”, “5. Write and Route”…)
- [ ] At least one verdict keyword present (`PASS WITH` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write this audit to `production/apps/<app>/milestones/security-audit-<date>.md`?"” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: review depth routed through `security-specialist`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — 1. Load Context — The app's OAuth/session modules, webhook routes,…

**Fixture** (assumed project state):
- `production/apps/<app>/milestones/security-audit-<date>.md`
- `production/apps/<app>/sprints/security-audit-<date>.md`
- `apps/<app>/shopify.app.toml`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/security-audit` [app: <slug>] [focus: auth | webhooks | data | scopes | all]

**Expected behavior**:
1. 1. Load Context — The app's OAuth/session modules, webhook routes, repository layer, and any
2. 2. Attack Surface Checklist
3. 3. Verify, Do Not Assume — For each checklist item, record how it was confirmed:
4. 4. Report
5. 5. Write and Route — OAuth, session token, token storage → `auth-specialist`

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`PASS WITH`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Do not fix code in this skill. Findings go to the owning…

**Fixture**:
- The skill's unconditional rule is violated: Do not fix code in this skill. Findings go to the owning specialist.
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
- Invocation omits the argument (`/security-audit`)

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
2. Handoff names the owning gate: `/security-audit` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write this audit to `production/apps/<app>/milestones/security-audit-<date>.md`?"”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 3 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
