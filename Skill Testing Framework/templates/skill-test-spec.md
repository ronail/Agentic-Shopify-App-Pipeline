# Skill Spec: /[skill-name]

> **Category**: [gate | review | authoring | readiness | pipeline | analysis | sprint | utility]
> **Priority**: [critical | high | medium | low]
> **Spec written**: [YYYY-MM-DD]

## Skill Summary

[One paragraph describing what this skill does, what inputs it takes, and what outputs it produces.]

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `READY`, `COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Gate Checks

[Describe which pipeline gates this skill touches (if any), and under what conditions.
Valid gate ids are the keys in `apps/<app>/approvals.json`:
`gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`.]

- **Gate implied by this skill**: [e.g. `gate-2-prototype` closes the prototype stage — name the approver]
- **Reads**: [`apps/<app>/approvals.json`, `apps/<app>/status.md`, `docs/registry/apps.json`]
- **Never auto-advances**: [state that stage changes require an explicit approval record]
- **N/A**: [if this skill never touches a gate, explain why]

---

## Test Cases

### Case 1: Happy Path — [brief name]

**Fixture** (assumed project state):
- `apps/<app>/status.md` at stage `[prototype | scope | release]`
- [file/condition 2]

**Expected behavior**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Assertions**:
- [ ] [Assertion 1]
- [ ] [Assertion 2]
- [ ] [Assertion 3]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — [brief name]

**Fixture**:
- [missing or invalid condition, e.g. app not in `docs/registry/apps.json`, earlier gate unrecorded]

**Expected behavior**:
1. [Skill detects the problem]
2. [Skill reports FAIL/BLOCKED]
3. [Skill does NOT proceed]

**Assertions**:
- [ ] Skill stops early and does not produce output
- [ ] Correct error/block message displayed
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — [brief name]

**Fixture**:
- [standard project state]
- [specific flag or argument set, e.g. `--force-reason` given vs. omitted]

**Expected behavior**:
1. [Behavior differs from happy path because of the flag]

**Assertions**:
- [ ] [Flag-specific assertion]
- [ ] [Output differs correctly from Case 1]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — [brief name]

**Fixture**:
- [unusual or boundary condition, e.g. two apps mid-stage, a stale `status.md`, a deprecated API version pinned]

**Expected behavior**:
1. [Skill handles gracefully]

**Assertions**:
- [ ] [Edge case handled without crash or silent failure]
- [ ] [Correct output or message]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Write Approval — [brief name]

**Fixture**:
- [project state where the skill's output implies a file change]
- [files at risk: `apps/<app>/status.md`, `docs/registry/apps.json`, …]

**Expected behavior**:
1. [Skill presents the draft/findings first]
2. [Skill asks "May I write …" naming each file]
3. [On refusal, no file changes]

**Assertions**:
- [ ] `"May I write"` precedes every write
- [ ] Each target file is named individually, not batch-approved
- [ ] Declining leaves the tree unchanged
- [ ] Skill never advances a stage or records a gate without an approval record

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

[Any gaps in coverage, known edge cases not tested, or conditions that would require
a live skill run to verify.]
